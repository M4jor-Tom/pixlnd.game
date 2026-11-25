#!/usr/bin/env bash
# Real Git/pre-commit, tiny pinned shell and local hooks only: never recurse into the product gate.
set -euo pipefail
if [[ -n ${TASK5_LIFETIME_ONLY:-} || -n ${TASK5_HOOKS_ONLY:-} ]]; then
  printf 'Full gate fixture refuses focused selectors.\n' >&2
  exit 2
fi
if [[ ${BASH_SOURCE[0]} == "$0" && $# != 0 ]]; then
  printf 'Full gate fixture accepts no arguments.\n' >&2
  exit 2
fi
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source_root=$PWD
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  logs=$(mktemp -d "${TASK4_TEST_LOG_ROOT:-/tmp}/gate-fixture.XXXXXX")
  exec bash tests/gate_lifecycle_fixture.sh supervise "$source_root/tests/test_gate.sh" "$logs"
fi
# Only the private supervisor sources this body; scratch is always invocation-owned.
logs=${1:?private evidence directory}
scratch=$(mktemp -d)
# A quality-runner hook can supply its parent's index and artifact paths.
mapfile -t git_env < <(git rev-parse --local-env-vars)
unset "${git_env[@]}"
unset SKIP QUALITY_GATE_LOG_DIR QUALITY_GATE_LOG_ROOT PRE_COMMIT_HOME UV_CACHE_DIR
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
unset TASK5_SCRATCH TASK5_LOGS TASK5_SUPERVISED TASK5_FIXTURE_TEMPLATE
cleanup() {
  if [[ -n ${logger_pid:-} ]]; then
    touch "$logs/python-hold/release"
    wait "$logger_pid" || true
  fi
  if [[ -d "$scratch/.git/pixlnd-gate" ]]; then
    cp -R "$scratch/.git/pixlnd-gate" "$logs/host-receipts"
  fi
  rm -rf "$scratch"
  test ! -e "$scratch"
  printf 'scratch removed=%s\n' "$scratch" >"$logs/scratch-cleanup.log"
}
trap cleanup EXIT
printf 'Gate fixture evidence: %s\n' "$logs"
export QUALITY_GATE_LOG_ROOT="$logs/quality" FIXTURE_OBSERVATIONS="$logs/observations"
mkdir -p "$scratch/scripts" "$logs/quality"
# Missing implementation is an intentional RED, not a skipped dependency.
for script in gate quality_gate ontology_tests; do
  cp "$source_root/scripts/$script.sh" "$scratch/scripts/"
done
cp "$source_root/scripts/gate_lifetime.py" "$scratch/scripts/"
cp flake.lock "$scratch/"
cat >"$scratch/flake.nix" <<'NIX'
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixgl = {
    url = "github:KeeTraxx/nixGL/51471fb4760efda2defba73bc1c264b7ba5364c2";
    flake = false;
  };
  outputs = { nixpkgs, ... }: {
    devShells = nixpkgs.lib.genAttrs
      [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]
      (system: { default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = with nixpkgs.legacyPackages.${system}; [ pre-commit uv python3 bash ];
        UV_PYTHON_DOWNLOADS = "never";
      }; });
  };
}
NIX
cat >"$scratch/fixture-hook.sh" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s %s %s\n' "$(git rev-parse HEAD)" "$(git rev-parse HEAD^{tree})" "$(cat payload)" "$PWD" >> "$FIXTURE_OBSERVATIONS"
printf 'fixture content: %s\n' "$(cat payload)"
if [[ -n ${FIXTURE_HOLD:-} ]]; then
  touch "$FIXTURE_HOLD/started"
  for ((i = 0; i < 200; i++)); do
    [[ -e "$FIXTURE_HOLD/release" ]] && break
    sleep 0.05
  done
  test -e "$FIXTURE_HOLD/release"
fi
[[ ! -e bad ]] || exit 17
case "$(cat payload)" in
  generate) printf 'new generated file\n' > generated ;;
  modify) printf 'changed\n' >> payload ;;
esac
HOOK
{
  printf 'default_stages: [manual]\nrepos:\n  - repo: local\n    hooks:\n'
  # Derive the execution list from the production manifest, not a second list in the runner.
  awk '/- id:/ { if ($3 == "gate-background") exit; print $3 }' .pre-commit-config.yaml |
    while read -r id; do
      printf '      - id: %s\n        name: %s\n        entry: bash fixture-hook.sh\n        language: system\n        pass_filenames: false\n        always_run: true\n        verbose: true\n' "$id" "$id"
    done
} >"$scratch/.pre-commit-config.yaml"
cd "$scratch"
git init -q
git config user.name 'Gate fixture'
git config user.email 'gate-fixture@example.invalid'
git config core.hooksPath /dev/null
printf 'good\n' >payload
git add .
git commit -qm good
good=$(git rev-parse HEAD)
good_tree=$(git rev-parse HEAD^{tree})
printf 'bad\n' >bad
git add bad
git commit -qm bad
bad=$(git rev-parse HEAD)
bad_tree=$(git rev-parse HEAD^{tree})

expect_exit() {
  local expected=$1 name=$2 actual=0
  shift 2
  "$@" >"$logs/$name.log" 2>&1 || actual=$?
  printf '%s: exit %s (expected %s)\n' "$name" "$actual" "$expected"
  if [[ "$actual" != "$expected" ]]; then
    cat "$logs/$name.log"
    exit 1
  fi
}
assert_outer_buffered() {
  [[ -r $1 ]] || return 1
  if grep -Fq -e 'test_progress (' -e 'fixture stdout progress' -e 'fixture stderr progress' "$1"; then
    printf 'FAIL: pre-commit released fixture output before child release\n' >&2
    return 1
  fi
}
wait_receipt() {
  local tree=$1 expected=$2 i
  for ((i = 0; i < 400; i++)); do
    grep -qx "outcome=$expected" ".git/pixlnd-gate/v4/$tree/state" 2>/dev/null && return
    sleep 0.1
  done
  {
    cat .git/pixlnd-gate/v4/*/*/gate.log
    printf 'Missing %s receipt for %s\n' "$expected" "$tree" >&2
    exit 1
  }
}

# Full entry refuses focused diagnostics before allocating or running a fixture.
for selector in TASK5_LIFETIME_ONLY TASK5_HOOKS_ONLY; do
  for value in yes no; do
    expect_exit 2 "full-entry-$selector-$value" env "$selector=$value" bash "$source_root/tests/test_gate.sh"
    grep -qx 'Full gate fixture refuses focused selectors.' "$logs/full-entry-$selector-$value.log"
  done
done
expect_exit 2 full-entry-arguments bash "$source_root/tests/test_gate.sh" "$source_root/tests/test_gate.sh" "$logs" owned
grep -qx 'Full gate fixture accepts no arguments.' "$logs/full-entry-arguments.log"

# Legacy receipts certify a different execution list and must never authorize the new gate.
mkdir -p .git/pixlnd-gate
printf 'legacy marker bytes\n' >"$logs/legacy-marker"
printf 'legacy log bytes\n' >"$logs/legacy-log"
cp "$logs/legacy-marker" ".git/pixlnd-gate/$good_tree.pass"
cp "$logs/legacy-log" ".git/pixlnd-gate/$good_tree.log"
expect_exit 1 legacy-check bash scripts/gate.sh check "$good"

# The CI entry itself, on the exact checkout. Inspect real good-tree hook output.
git checkout -q "$good"
expect_exit 0 ci-good bash scripts/quality_gate.sh
for id in python-lint ontology-schema-size ontology-mermaid ontology-instances ontology-schema-tests quality-runner quality; do
  grep -Eq "^${id}\\.+Passed" "$logs/ci-good.log"
  grep -q "hook id: $id$" "$logs/ci-good.log"
done
[[ $(grep -c 'hook id:' "$logs/ci-good.log") == 7 ]]
expect_exit 2 selector bash scripts/quality_gate.sh quality
expect_exit 2 skip env SKIP=quality bash scripts/quality_gate.sh
printf 'dirty\n' >>payload
expect_exit 1 dirty-input bash scripts/quality_gate.sh
git checkout -- payload
printf 'dirty\n' >untracked
expect_exit 1 untracked-input bash scripts/quality_gate.sh
rm untracked
expect_exit 2 foreign-index env GIT_INDEX_FILE="$logs/foreign-index" bash scripts/quality_gate.sh

git checkout -q "$bad"
expect_exit 1 ci-bad bash scripts/quality_gate.sh
grep -q 'exit code: 17' "$logs/ci-bad.log"
# Both host and CI reject that same bad committed tree through quality_gate.sh.
expect_exit 0 host-bad-start bash scripts/gate.sh start "$bad"
wait_receipt "$bad_tree" fail
expect_exit 1 host-bad-check bash scripts/gate.sh check "$bad"
if ! grep -q 'exit code: 17' .git/pixlnd-gate/v4/"$bad_tree"/attempt.*/gate.log; then
  printf 'FAIL: host did not execute the same manual hook as CI\n' >&2
  exit 1
fi
bad_logs=(.git/pixlnd-gate/v4/"$bad_tree"/attempt.*/gate.log)
# pre-commit maps the hook's 17 to the real outer command status 1.
grep -qx 'command_exit=1' ".git/pixlnd-gate/v4/$bad_tree/state"
cp "${bad_logs[0]}" "$logs/first-bad-attempt.log"
expect_exit 0 host-bad-retry bash scripts/gate.sh start "$bad"
wait_receipt "$bad_tree" fail
cmp "${bad_logs[0]}" "$logs/first-bad-attempt.log"
[[ $(find ".git/pixlnd-gate/v4/$bad_tree" -maxdepth 1 -type d -name 'attempt.*' | wc -l) == 2 ]]

# Resolve before detaching. Move the branch and dirty the caller after the hook starts.
git checkout -q -B fixture "$good"
mkdir "$logs/hold"
export FIXTURE_HOLD="$logs/hold"
expect_exit 0 host-good-start env GIT_DIR="$scratch/.git" GIT_WORK_TREE="$scratch" GIT_INDEX_FILE="$scratch/.git/index" bash scripts/gate.sh start "$good"
for ((i = 0; i < 400; i++)); do
  [[ -e "$FIXTURE_HOLD/started" ]] && break
  sleep 0.1
done
test -e "$FIXTURE_HOLD/started"
git reset -q --hard "$bad"
printf 'caller dirt\n' >payload
touch "$FIXTURE_HOLD/release"
wait_receipt "$good_tree" pass
unset FIXTURE_HOLD
expect_exit 0 host-good-check bash scripts/gate.sh check "$good"
cmp "$logs/legacy-marker" ".git/pixlnd-gate/$good_tree.pass"
cmp "$logs/legacy-log" ".git/pixlnd-gate/$good_tree.log"
awk -v commit="$good" -v tree="$good_tree" -v caller="$scratch" \
  '$1 == commit && $2 == tree && $3 == "good" && $4 != caller { count++ } END { exit count != 7 }' "$FIXTURE_OBSERVATIONS"
[[ $(git rev-parse HEAD) == "$bad" ]]
[[ $(cat payload) == 'caller dirt' ]]
[[ $(git worktree list --porcelain | grep -c '^worktree ') == 1 ]]
# Old failure logs survive later attempts.
cmp "${bad_logs[0]}" "$logs/first-bad-attempt.log"

for mode in generate modify; do
  git reset -q --hard "$good"
  printf '%s\n' "$mode" >payload
  git add payload
  git commit -qm "$mode"
  tree=$(git rev-parse HEAD^{tree})
  expect_exit 1 "ci-$mode" bash scripts/quality_gate.sh
  grep -q 'Checkout changed' "$logs/ci-$mode.log"
  if [[ $mode == generate ]]; then
    [[ $(grep -c 'Passed$' "$logs/ci-$mode.log") == 7 ]]
  fi
  git reset -q --hard HEAD
  rm -f generated
  expect_exit 0 "host-$mode-start" bash scripts/gate.sh start HEAD
  wait_receipt "$tree" fail
  expect_exit 1 "host-$mode-check" bash scripts/gate.sh check HEAD
done

# Real uv + the wrapper's unchanged discovery command, through Nix and pre-commit buffering.
git reset -q --hard "$good"
mkdir -p tools/ontology tests
printf '__pycache__/\n' >.gitignore
printf '[project]\nname = "gate-fixture"\nversion = "0.0.0"\nrequires-python = ">=3.12"\n' >tools/ontology/pyproject.toml
uv lock --offline --project tools/ontology >"$logs/uv-lock.log" 2>&1
cat >tests/test_ontology_fixture.py <<'PY'
import os
import sys
import time
import unittest
from pathlib import Path


class LoggingFixture(unittest.TestCase):
    def test_progress(self):
        if "FIXTURE_PROGRESS_HOLD" in os.environ:
            hold = Path(os.environ["FIXTURE_PROGRESS_HOLD"])
            waiting = hold / "waiting"
            waiting.write_text(str(os.getpid()))
            for _ in range(400):
                if (hold / "release").exists():
                    break
                time.sleep(0.05)
            waiting.unlink()
            self.assertTrue((hold / "release").exists(), "fixture release timed out")
        print("fixture stdout progress", flush=True)
        print("fixture stderr progress", file=sys.stderr, flush=True)
        if "QUALITY_GATE_LOG_DIR" in os.environ:
            log_dir = Path(os.environ["QUALITY_GATE_LOG_DIR"])
            self.assertTrue(log_dir.is_absolute())
            self.assertFalse(log_dir.is_relative_to(Path.cwd()))
        time.sleep(3)


# Deliberately fail after the OK summary: text must never authorize a receipt.
if Path("late-failure").exists():
    import atexit

    atexit.register(lambda: os._exit(23))
PY
cat >.pre-commit-config.yaml <<'YAML'
default_stages: [manual]
repos:
  - repo: local
    hooks:
      - id: ontology-schema-tests
        name: Python logging fixture
        entry: nix develop --no-update-lock-file -c bash scripts/ontology_tests.sh
        language: system
        pass_filenames: false
        always_run: true
        verbose: true
YAML
git add .
git commit -qm logging
printf 'test_progress (test_ontology_fixture.LoggingFixture.test_progress) ... ' >"$logs/early-output.log"
expect_exit 1 logging-early-output assert_outer_buffered "$logs/early-output.log"
mkdir "$logs/python-hold"
export FIXTURE_PROGRESS_HOLD="$logs/python-hold"
bash scripts/quality_gate.sh >"$logs/logging-live.log" 2>&1 &
logger_pid=$!
# Cold Nix/pre-commit startup is not part of the live-output assertion.
while [[ ! -s "$FIXTURE_PROGRESS_HOLD/waiting" ]]; do
  if ! kill -0 "$logger_pid" 2>/dev/null; then
    cat "$logs/logging-live.log" >&2
    printf 'FAIL: logging fixture exited before reaching its hold\n' >&2
    exit 1
  fi
  sleep 0.05
done
visible=false
for ((i = 0; i < 200; i++)); do
  if grep -lF 'test_progress (test_ontology_fixture.LoggingFixture.test_progress) ... ' "$logs"/quality/*/ontology-tests.log >"$logs/visible-path" 2>/dev/null; then
    kill -0 "$logger_pid"
    test -s "$FIXTURE_PROGRESS_HOLD/waiting"
    kill -0 "$(cat "$FIXTURE_PROGRESS_HOLD/waiting")"
    test ! -e "$FIXTURE_PROGRESS_HOLD/release"
    assert_outer_buffered "$logs/logging-live.log"
    visible=true
    break
  fi
  sleep 0.05
done
test "$visible" == true || {
  printf 'FAIL: flushed unittest prefix missing while Python waits\n' >&2
  exit 1
}
python_log=$(cat "$logs/visible-path")
cp "$python_log" "$logs/logging-partial.snapshot"
[[ $(tail -c 1 "$logs/logging-partial.snapshot" | wc -l) == 0 ]]
touch "$FIXTURE_PROGRESS_HOLD/release"
wait "$logger_pid"
unset logger_pid FIXTURE_PROGRESS_HOLD
grep -q 'fixture stdout progress' "$python_log"
grep -q 'fixture stderr progress' "$python_log"
grep -q 'last_summary_utc=' "${python_log%.log}.status"
grep -q 'exit_status=0' "${python_log%.log}.status"
grep -q 'largest child RSS' "$(dirname "$python_log")/resources.log"
printf 'logging-live: progress visible before process exit and pre-commit output release\n'
touch late-failure
git add late-failure
git commit -qm late-failure
expect_exit 1 logging-late-failure bash scripts/quality_gate.sh
grep -q 'exit code: 23' "$logs/logging-late-failure.log"
grep -q '^OK$' "$logs/logging-late-failure.log"
# The original successful Python log is still present, not truncated by the next attempt.
grep -q 'exit_status=0' "${python_log%.log}.status"
# A later passing module must run without masking the first module's late exit.
printf 'import unittest\nclass Later(unittest.TestCase):\n    def test_later(self): pass\n' >tests/test_ontology_z_later.py
expect_exit 23 logging-no-dir env -u QUALITY_GATE_LOG_DIR bash scripts/ontology_tests.sh
grep -Fq 'test_later (test_ontology_z_later.Later.test_later) ... ok' "$logs/logging-no-dir.log"
rm late-failure
mkdir "$logs/full-output"
ln -s /dev/full "$logs/full-output/ontology-tests.log"
expect_exit 1 logging-output-error env QUALITY_GATE_LOG_DIR="$logs/full-output" bash scripts/ontology_tests.sh
grep -q 'exit_status=1' "$logs/full-output/ontology-tests.status"
mkdir "$logs/uv-error"
printf 'not valid TOML\n' >tools/ontology/uv.lock
expect_exit 2 logging-uv-error env QUALITY_GATE_LOG_DIR="$logs/uv-error" bash scripts/ontology_tests.sh
grep -q 'exit_status=2' "$logs/uv-error/ontology-tests.status"
TASK5_FIXTURE_TEMPLATE="$scratch" bash "$source_root/tests/gate_lifecycle_fixture.sh" "$source_root" "$logs/lifecycle"
printf 'Gate regression checks passed. Evidence retained: %s\n' "$logs"
