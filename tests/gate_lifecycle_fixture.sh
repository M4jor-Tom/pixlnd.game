#!/usr/bin/env bash
# Disposable repositories only; invoked by test_gate.sh, or directly for lifecycle REDs.
set -euo pipefail
source_root=${1:?source root}
logs=${2:?evidence directory}
target=$0
if [[ $1 == supervise ]]; then
  target=$2 source_root=$2 logs=$3
fi
mkdir -p "$logs"
# Adopt detached fixture descendants so cleanup can actually reap them, even after SIGKILL.
if [[ ${3:-} != owned ]]; then
  exec python3 - "$target" "$source_root" "$logs" <<'PY'
import ctypes
import os
import signal
import subprocess
import sys
import time
from pathlib import Path

if ctypes.CDLL(None, use_errno=True).prctl(36, 1, 0, 0, 0) != 0:
    raise OSError(ctypes.get_errno(), "PR_SET_CHILD_SUBREAPER")
command = ["bash", *sys.argv[1:], "owned"]
if sys.argv[1] == sys.argv[2]:  # Full entry: source its body, never expose an owned CLI mode.
    command = ["bash", "-c", 'source "$1" "$2"', "gate-fixture", sys.argv[1], sys.argv[3]]
child = subprocess.Popen(command, start_new_session=True)

def forward(sig, _frame):
    try:
        os.killpg(child.pid, sig)
    except ProcessLookupError:
        pass

for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
    signal.signal(sig, forward)
rc = child.wait()
reaped = []
remaining = 0
boot = Path("/proc/sys/kernel/random/boot_id").read_text().strip()
# A failed assertion still owns all adopted descendants of this private subreaper.
# Verify their kernel identities and isolated groups, never the caller's process group.
if rc:
    for sig in (signal.SIGTERM, signal.SIGKILL):
        for stat in Path("/proc").glob("[0-9]*/stat"):
            try:
                before = stat.read_text().rsplit(") ", 1)[1].split()
                if int(before[1]) != os.getpid() or before[0] == "Z":
                    continue
                pid, group = int(stat.parent.name), int(before[2])
                assert group != os.getpgrp()
                after = stat.read_text().rsplit(") ", 1)[1].split()
                if after[19] == before[19] and after[2] == before[2]:
                    reaped.append((pid, f"signal={sig} boot={boot} ticks={after[19]} group={group}"))
                    os.killpg(group, sig)
            except (FileNotFoundError, ProcessLookupError):
                continue
        time.sleep(0.1)
deadline = time.monotonic() + 5
while True:
    try:
        pid, status = os.waitpid(-1, os.WNOHANG)
    except ChildProcessError:
        break
    if pid:
        reaped.append((pid, status))
    elif time.monotonic() >= deadline:
        rc = 1
        remaining = 1
        reaped.append(("ERROR", "descendants still alive"))
        break
    else:
        time.sleep(0.05)
with open(sys.argv[3] + "/reaped.log", "w") as log:
    for pid, status in reaped:
        log.write(f"reaped pid={pid} wait_status={status}\n")
    log.write(f"descendants_remaining={remaining}\n")
sys.exit(rc)
PY
fi
fixture=$(mktemp -d)
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export FIXTURE_CONTROL="$logs/control"
mkdir -p "$fixture/scripts" "$FIXTURE_CONTROL"
cp "$source_root/scripts/gate.sh" "$fixture/scripts/"
cp "$source_root/scripts/gate_lifetime.py" "$fixture/scripts/"
identity() {
  local stat
  stat=$(cat "/proc/$1/stat") || return 1
  read -ra fields <<<"${stat##*) }"
  printf '%s %s %s %s %s\n' "$1" "$(cat /proc/sys/kernel/random/boot_id)" "${fields[19]}" "${fields[2]}" "${fields[3]}"
}
# Recheck the boot/start identity before signaling only a fixture-created session.
stop_owned() {
  touch "$FIXTURE_CONTROL/nested-release"
  [[ ! -d $logs/guardian-control ]] || touch "$logs/guardian-control/nested-release"
  local file pid boot ticks group session current cmdline
  # Cover a launch failure before the fixture runner could register itself.
  for file in /proc/[0-9]*/cmdline; do
    cmdline=$(tr '\0' ' ' <"$file" 2>/dev/null) || continue
    [[ $cmdline == *"bash $fixture/scripts/gate.sh run "* ]] || continue
    pid=${file#/proc/}; pid=${pid%/cmdline}
    identity "$pid" >"$FIXTURE_CONTROL/$pid.identity" 2>/dev/null || true
  done
  for file in "$FIXTURE_CONTROL"/*.identity; do
    [[ -f $file ]] || continue
    read -r pid boot ticks group session <"$file"
    current=$(identity "$pid" 2>/dev/null) || continue
    [[ $current == "$pid $boot $ticks $group $session" ]] || continue
    [[ $session == "$group" && $session != "$(ps -o sid= -p $$ | tr -d ' ')" ]] || exit 1
    printf 'cleanup verified identity: %s\n' "$current" >>"$logs/cleanup.log"
    kill -KILL -- "-$group" 2>/dev/null || true
  done
}
cleanup() {
  local rc=$?
  trap - EXIT
  stop_owned
  sleep 0.2
  cp -R "$fixture/.git/pixlnd-gate" "$logs/receipts" 2>/dev/null || true
  if [[ -d $fixture/guardian-loss/.git ]]; then
    cp -R "$fixture/guardian-loss/.git/pixlnd-gate" "$logs/guardian-receipts"
    git -C "$fixture/guardian-loss" worktree list --porcelain >"$logs/guardian-worktrees-before-disposal"
  fi
  git -C "$fixture" worktree list --porcelain >"$logs/worktrees-before-disposal" 2>/dev/null || true
  rm -rf "$fixture"
  printf 'fixture removed=%s; exit=%s\n' "$fixture" "$rc" >>"$logs/cleanup.log"
  exit "$rc"
}
trap cleanup EXIT
cat >"$fixture/scripts/quality_gate.sh" <<'RUNNER'
#!/usr/bin/env bash
set -euo pipefail
stat=$(cat /proc/$$/stat); read -ra fields <<<"${stat##*) }"
printf '%s %s %s %s %s\n' "$$" "$(cat /proc/sys/kernel/random/boot_id)" "${fields[19]}" "${fields[2]}" "${fields[3]}" >"$FIXTURE_CONTROL/$$.identity"
owner=$(sed -n 's/^pid=//p' "$QUALITY_GATE_LOG_ROOT/../state")
stat=$(cat /proc/$owner/stat); read -ra fields <<<"${stat##*) }"
printf '%s %s %s %s %s\n' "$owner" "$(cat /proc/sys/kernel/random/boot_id)" "${fields[19]}" "${fields[2]}" "${fields[3]}" >"$FIXTURE_CONTROL/$owner.identity"
printf 'command_pid=%s owner=%s tree=%s\n' "$$" "$PPID" "$(git rev-parse HEAD^{tree})"
printf '%s\n' "$PPID" >"$FIXTURE_CONTROL/owner"
touch "$FIXTURE_CONTROL/started"
case "$(cat payload)" in
  nested*)
    python3 - <<'PY'
import os
import subprocess
from pathlib import Path

root = Path(os.environ["FIXTURE_CONTROL"])
code = '''import os, time
from pathlib import Path
root = Path(os.environ["FIXTURE_CONTROL"])
(root / "nested-started").write_text(str(os.getpid()))
for _ in range(200):
    if (root / "nested-release").exists():
        break
    time.sleep(0.05)
(root / "nested-done").write_text("done")
'''
subprocess.Popen(["python3", "-c", code], close_fds=True, start_new_session=True)
PY
    exit 0 ;;
  hold*)
    printf 'OK\n'
    for ((i=0; i<200; i++)); do
      [[ -e "$FIXTURE_CONTROL/release" ]] && exit 0
      printf 'late output\n'
      sleep 0.05
    done
    exit 19 ;;
  fail) exit 17 ;;
  timeout) exit 124 ;;
esac
RUNNER
cp "$fixture/scripts/quality_gate.sh" "$logs/tiny-quality_gate.sh"
cd "$fixture"
git init -q
git config user.name 'Lifecycle fixture'
git config user.email 'fixture@example.invalid'
git config core.hooksPath /dev/null
commit_payload() {
  printf '%s\n' "$1" >payload
  git add .
  git commit -qm "$1"
  tree=$(git rev-parse HEAD^{tree})
}
run_exit() {
  local expected=$1 label=$2 rc=0
  shift 2
  "$@" >"$logs/$label.log" 2>&1 || rc=$?
  printf '%s: exit=%s expected=%s\n' "$label" "$rc" "$expected"
  [[ $rc == "$expected" ]] || { cat "$logs/$label.log"; exit 1; }
}
state_file() { printf '.git/pixlnd-gate/v4/%s/state\n' "$tree"; }
field() { sed -n "s/^$1=//p" "${2:-$(state_file)}"; }
assert_terminal_footer() {
  local worker_exit command_exit
  worker_exit=$(field worker_exit)
  command_exit=$(field command_exit)
  command_exit=${command_exit:-unknown}
  # A reconciled SIGKILL has no worker footer or observed exit to assert.
  [[ -n $worker_exit ]] || return 0
  grep -Eq "^worker_exited_utc=.* command_exit=$command_exit worker_exit=$worker_exit cleanup=$(field cleanup)$" "$(field log)"
}
wait_state() {
  local expected=$1
  for ((i=0; i<100; i++)); do
    if [[ $(field outcome 2>/dev/null) == "$expected" ]]; then
      assert_terminal_footer
      return
    fi
    sleep 0.05
  done
  cat .git/pixlnd-gate/*/*/state .git/pixlnd-gate/*/*/*/gate.log 2>/dev/null || true
  printf 'missing state: %s\n' "$expected" >&2
  exit 1
}
wait_started() {
  for ((i=0; i<100; i++)); do
    [[ -e "$FIXTURE_CONTROL/started" ]] && return
    sleep 0.05
  done
  exit 1
}
signal_nested_guardian() {
  python3 - "$1/lifetime/guardian.json" "$logs/nested-signals.log" <<'PYTHON'
import json
import os
from pathlib import Path
import signal
import sys

record = json.loads(Path(sys.argv[1]).read_text())
fd = os.pidfd_open(record["pid"])
fields = Path(f'/proc/{record["pid"]}/stat').read_text().rsplit(") ", 1)[1].split()
assert fields[19] == record["ticks"]
assert Path("/proc/sys/kernel/random/boot_id").read_text().strip() == record["boot"]
with open(sys.argv[2], "a") as log:
    log.write(json.dumps(record) + "\n")
signal.pidfd_send_signal(fd, signal.SIGKILL)
os.close(fd)
PYTHON
}
release_nested() {
  python3 - "$FIXTURE_CONTROL" >>"$logs/nested-kernel-proof.log" <<'PYTHON'
import os
from pathlib import Path
import select
import sys

root = Path(sys.argv[1])
pid = int((root / "nested-started").read_text())
fd = os.pidfd_open(pid)
fields = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
assert fields[0] != "Z"
(root / "nested-release").touch()
assert select.select([fd], [], [], 5)[0], "fixture child did not exit"
print(f"fixture child pid={pid} start_ticks={fields[19]} pidfd confirms exit")
os.close(fd)
PYTHON
}
nested_queued() {
  local death=$1 old_attempt=$2 expected=queued
  [[ $death != guardian ]] || expected=fail
  commit_payload "queued-after-$death"
  run_exit 0 "nested-$death-queued" bash scripts/gate.sh start
  wait_state "$expected"
  sleep 0.2
  wait_state "$expected"
  [[ $(find .git/pixlnd-gate -path '*/work/payload' -exec grep -l "queued-after-$death" {} \; | wc -l) == 0 ]]
  test -d "$old_attempt/work"
}
nested_recovery() {
  local death=$1 old_tree=$2 old_attempt=$3 old_commit=$4 old_log
  [[ $(git rev-parse "$old_commit^{tree}") == "$old_tree" ]]
  release_nested
  if [[ $death == guardian ]]; then
    tree=$old_tree
    run_exit 2 lost-guardian-refuses-retry bash scripts/gate.sh start "$old_commit"
    grep -Fq "$old_attempt/lifetime/drained.json" "$logs/lost-guardian-refuses-retry.log"
    test -d "$old_attempt/work"
    test ! -e "$old_attempt/lifetime/drained.json"
    printf 'lost guardian: checkout retained; queued work and retry refused without kernel drain proof\n' >>"$logs/nested-proof.log"
    return
  fi
  wait_state pass
  tree=$old_tree
  if [[ $death == worker ]]; then
    old_log=$(sha256sum "$old_attempt/gate.log")
    run_exit 0 nested-recover bash scripts/gate.sh start "$old_commit"
    wait_state pass
    [[ $(sha256sum "$old_attempt/gate.log") == "$old_log" ]]
    [[ $(field attempt) != "$old_attempt" ]]
  else
    wait_state pass
  fi
  test ! -d "$old_attempt/work"
  test -e "$FIXTURE_CONTROL/nested-done"
  printf 'nested-%s retained checkout and excluded queued work until child drain\n' "$death" >>"$logs/nested-proof.log"
}
lifetime_prerequisites() {
  local restricted legacy tool
  restricted=$(mktemp -d "$logs/no-python-bin.XXXXXX")
  # Host bin directories may provide both git and python3.
  for tool in bash dirname git mkdir cat; do
    ln -s "$(type -P "$tool")" "$restricted/$tool"
  done
  run_exit 2 missing-python env PATH="$restricted" bash scripts/gate.sh start
  grep -q 'requires host python3' "$logs/missing-python.log"
  rm -rf "$restricted"
  commit_payload legacy-v3
  legacy="$fixture/.git/pixlnd-gate/v3/$tree/attempt.OLD"
  mkdir -p "$legacy"
  printf 'protocol=3\ntree=%s\nattempt=%s\noutcome=pass\npid=%s\nboot=old\nticks=1\nstarted=old\nended=old\ncommand_exit=0\nworker_exit=0\ncleanup=ok\nlog=%s/gate.log\n' "$tree" "$legacy" "$$" "$legacy" >"$legacy/status"
  cp "$legacy/status" "$legacy/../state"
  sha256sum "$legacy/status" "$legacy/../state" >"$logs/v3.sha256"
  run_exit 1 legacy-v3-ineligible bash scripts/gate.sh check
  sha256sum -c "$logs/v3.sha256"
}
nested_boundary() {
  local death=$1 old_tree old_commit old_attempt owner
  rm -f "$FIXTURE_CONTROL"/nested-{started,release,done}
  commit_payload "nested-$death"
  old_tree=$tree old_commit=$(git rev-parse HEAD)
  [[ $(git rev-parse "$old_commit^{tree}") == "$old_tree" ]]
  run_exit 0 "nested-$death-start" bash scripts/gate.sh start
  for ((i=0; i<100; i++)); do
    [[ -s $FIXTURE_CONTROL/nested-started ]] && break
    sleep 0.05
  done
  test -s "$FIXTURE_CONTROL/nested-started"
  old_attempt=$(field attempt)
  for ((i=0; i<100; i++)); do
    [[ -r $old_attempt/lifetime/command.json ]] && break
    sleep 0.05
  done
  grep -q '"command_exit": 0' "$old_attempt/lifetime/command.json"
  test ! -e "$old_attempt/lifetime/drained.json"
  if [[ $death == worker ]]; then
    owner=$(field pid)
    identity "$owner" >>"$logs/nested-signals.log"
    kill -KILL "$owner"
    run_exit 1 nested-dead-check bash scripts/gate.sh check
  fi
  if [[ $death == guardian ]]; then
    signal_nested_guardian "$old_attempt"
    wait_state fail
  fi
  test -d "$old_attempt/work"
  run_exit 1 "nested-$death-not-pass" bash scripts/gate.sh check
  nested_queued "$death" "$old_attempt"
  nested_recovery "$death" "$old_tree" "$old_attempt" "$old_commit"
}
lifetime_prerequisites
if [[ ${TASK5_LIFETIME_ONLY:-no} == yes ]]; then
  nested_boundary normal
  nested_boundary worker
  nested_boundary guardian
  printf 'Focused lifetime checks passed\n'
  exit 0
fi
if [[ ${TASK5_HOOKS_ONLY:-no} != yes ]]; then
commit_payload hold-first
first=$tree
mkdir -p .git/pixlnd-gate/v2
: >".git/pixlnd-gate/v2/$tree.running"
sha256sum ".git/pixlnd-gate/v2/$tree.running" >"$logs/legacy.sha256"
run_exit 1 legacy-running bash scripts/gate.sh check
run_exit 0 first-start bash scripts/gate.sh start &
first_launcher=$!
run_exit 0 duplicate-start bash scripts/gate.sh start &
second_launcher=$!
wait "$first_launcher"
wait "$second_launcher"
wait_started
wait_state running
run_exit 1 ok-still-alive bash scripts/gate.sh check
[[ $(find .git/pixlnd-gate/v4 -name gate.log | wc -l) == 1 ]]
first_attempt=$(field attempt)
commit_payload good-second
second=$tree
run_exit 0 queued-start bash scripts/gate.sh start
wait_state queued
run_exit 1 queued-check bash scripts/gate.sh check
sleep 0.2
wait_state queued
touch "$FIXTURE_CONTROL/release"
wait_state pass
run_exit 0 second-pass bash scripts/gate.sh check
tree=$first
wait_state pass
sha256sum -c "$logs/legacy.sha256"
for mode in fail timeout; do
  commit_payload "$mode"
  run_exit 0 "$mode-start" bash scripts/gate.sh start
  expected=fail; [[ $mode != timeout ]] || expected=timeout
  wait_state "$expected"
  run_exit 1 "$mode-check" bash scripts/gate.sh check
  expected=17; [[ $mode != timeout ]] || expected=124
  [[ $(field command_exit) == "$expected" ]]
done
# TERM and SIGKILL are directed only at a freshly observed fixture owner identity.
interrupt_case() {
  local signal=$1
  rm -f "$FIXTURE_CONTROL/started" "$FIXTURE_CONTROL/release"
  commit_payload "hold-$signal"
  run_exit 0 "$signal-start" bash scripts/gate.sh start
  wait_started
  wait_state running
  local owner old_attempt before
  owner=$(field pid); old_attempt=$(field attempt)
  [[ $(identity "$owner") == "$(cat "$FIXTURE_CONTROL/$owner.identity")" ]]
  cat "$FIXTURE_CONTROL/$owner.identity" >>"$logs/signaled-identities.log"
  kill -"$signal" "$owner"
  sleep 0.2
  run_exit 1 "$signal-check" bash scripts/gate.sh check
  wait_state interrupted
  if [[ $signal == KILL ]]; then
    [[ -z $(field command_exit) ]]
    run_exit 1 retry-refuses-live-command bash scripts/gate.sh start
    touch "$FIXTURE_CONTROL/release"
  fi
  for ((i=0; i<100; i++)); do
    if flock -n .git/pixlnd-gate/lock true; then break; fi
    sleep 0.05
  done
  flock -n .git/pixlnd-gate/lock true
  before=$(sha256sum "$old_attempt/gate.log")
  sleep 0.15
  [[ $(sha256sum "$old_attempt/gate.log") == "$before" ]]
  cp "$old_attempt/gate.log" "$logs/$signal-old.log"
  touch "$FIXTURE_CONTROL/release"
  run_exit 0 "$signal-restart" bash scripts/gate.sh start
  wait_state pass
  [[ $(field attempt) != "$old_attempt" ]]
  cmp "$old_attempt/gate.log" "$logs/$signal-old.log"
}
interrupt_case TERM
interrupt_case KILL
# A real zombie must not be considered alive just because /proc still exists.
setsid python3 - "$FIXTURE_CONTROL" <<'PY' &
import os
import sys
import time
from pathlib import Path

root = Path(sys.argv[1])
pid = os.fork()
if pid == 0:
    os._exit(0)
(root / "zombie").write_text(str(pid))
fields = Path(f"/proc/{os.getpid()}/stat").read_text().rsplit(") ", 1)[1].split()
boot = Path("/proc/sys/kernel/random/boot_id").read_text().strip()
(root / f"{os.getpid()}.identity").write_text(
    f"{os.getpid()} {boot} {fields[19]} {fields[2]} {fields[3]}\n"
)
for _ in range(200):
    if (root / "reap-zombie").exists():
        break
    time.sleep(0.05)
os.waitpid(pid, 0)
PY
zombie_parent=$!
for ((i=0; i<100; i++)); do
  [[ -s "$FIXTURE_CONTROL/zombie" ]] && break
  sleep 0.05
done
# Inject stale identities only into a disposable receipt; never source it as shell.
for mismatch in boot ticks unreadable dead zombie; do
  commit_payload "identity-$mismatch"
  mkdir -p ".git/pixlnd-gate/v4/$tree"
  own=$(identity $$); read -r pid boot ticks group session <<<"$own"
  case $mismatch in
    boot) boot=previous-boot ;;
    ticks) ticks=0 ;;
    unreadable) pid=not-a-pid ;;
    dead) pid=999999999 ;;
    zombie) read -r pid boot ticks group session <<<"$(identity "$(cat "$FIXTURE_CONTROL/zombie")")" ;;
  esac
  injected="$fixture/.git/pixlnd-gate/v4/$tree/attempt.INJECT"
  mkdir "$injected"
  printf '\n' >"$injected/previous"
  printf 'protocol=4\ntree=%s\nattempt=%s\noutcome=running\npid=%s\nboot=%s\nticks=%s\n' "$tree" "$injected" "$pid" "$boot" "$ticks" >"$(state_file)"
  run_exit 1 "identity-$mismatch" bash scripts/gate.sh check
  expected=interrupted; [[ $mismatch != unreadable ]] || expected=unknown
  # Unknown is reported but not persisted as a fabricated terminal result.
  grep -q "Quality gate $expected" "$logs/identity-$mismatch.log"
  [[ -z $(field command_exit) ]]
done
touch "$FIXTURE_CONTROL/reap-zombie"
wait "$zombie_parent"
kill -0 $$
[[ $(git worktree list --porcelain | grep -c '^worktree ') == 1 ]]
flock -n .git/pixlnd-gate/lock true
printf 'execution lock free; only primary fixture worktree remains\n' >>"$logs/cleanup.log"
fi
installed_hooks() {
  cp "$source_root/scripts/quality_gate.sh" scripts/quality_gate.sh
  cp "$TASK5_FIXTURE_TEMPLATE"/flake.{nix,lock} .
  cat >.pre-commit-config.yaml <<'YAML'
default_install_hook_types: [post-commit, pre-push]
default_stages: [manual]
repos:
  - repo: local
    hooks:
      - id: fixture
        name: disposable manual fixture
        entry: bash fixture-hook.sh
        language: system
        pass_filenames: false
        always_run: true
        verbose: true
YAML
  awk '/      - id: gate-background/ {copy=1} copy' "$source_root/.pre-commit-config.yaml" >>.pre-commit-config.yaml
  printf '#!/usr/bin/env bash\n[[ $(cat payload) != fail ]] || exit 17\n' >fixture-hook.sh
  export PRE_COMMIT_HOME="$logs/hook-cache"
  # Nix ignores untracked flakes: record setup before installing the real hooks.
  commit_payload hook-setup
  git config --unset core.hooksPath
  nix develop --no-update-lock-file -c pre-commit install >"$logs/hooks-install.log" 2>&1
  bare="$logs/remote.git"
  git init --bare -q "$bare"
  [[ $(git --git-dir="$bare" rev-parse --is-bare-repository) == true ]]
  git remote add local "$bare"
  nix_path=$(dirname "$(command -v nix)")
  git_path=$(dirname "$(command -v git)")
  python_path=$(dirname "$(command -v python3)")
  outside_path="$python_path:$git_path:$nix_path:/usr/bin:/bin:/run/current-system/sw/bin"
  env -u IN_NIX_SHELL -u LD_LIBRARY_PATH PATH="$outside_path" bash -c \
    'command -v git nix bash flock python3; test -z "${IN_NIX_SHELL:-}"; test -z "${LD_LIBRARY_PATH:-}"' >"$logs/outside-path.log"
  printf 'hook-good\n' >payload
  git add .
  run_exit 0 outside-post-commit env -u IN_NIX_SHELL -u LD_LIBRARY_PATH PATH="$outside_path" git commit -qm hook-good
  tree=$(git rev-parse HEAD^{tree})
  wait_state pass
  run_exit 0 hook-good-check bash scripts/gate.sh check
  local attempts_count
  attempts_count=$(find .git/pixlnd-gate/v4 -name gate.log | wc -l)
  git commit --allow-empty -qm same-tree
  [[ $(git rev-parse HEAD^{tree}) == "$tree" ]]
  run_exit 0 same-tree-reuse bash scripts/gate.sh check
  [[ $(find .git/pixlnd-gate/v4 -name gate.log | wc -l) == "$attempts_count" ]]
  run_exit 0 valid-push env -u IN_NIX_SHELL -u LD_LIBRARY_PATH PATH="$outside_path" git push local HEAD:refs/heads/fixture
  before_ref=$(git --git-dir="$bare" rev-parse refs/heads/fixture)
  [[ $before_ref == "$(git rev-parse HEAD)" ]]
  commit_payload fail
  wait_state fail
  run_exit 1 different-tree-check bash scripts/gate.sh check
  run_exit 1 invalid-push env -u IN_NIX_SHELL -u LD_LIBRARY_PATH PATH="$outside_path" git push local HEAD:refs/heads/fixture
  [[ $(git --git-dir="$bare" rev-parse refs/heads/fixture) == "$before_ref" ]]
  grep -q 'gate-receipt' "$logs/invalid-push.log"
  grep -q 'Quality gate fail' "$logs/invalid-push.log"
  grep -q 'Failed' "$logs/invalid-push.log"
  printf 'accepted push advanced bare ref to intended HEAD; rejected push retained %s\n' "$before_ref" >"$logs/push-proof.log"
  grep -qx 'command_exit=1' "$(state_file)"
  grep -q 'exit code: 17' "$(field log)"
  [[ $(git worktree list --porcelain | grep -c '^worktree ') == 1 ]]
}
nested_boundary normal
nested_boundary worker
if [[ -n ${TASK5_FIXTURE_TEMPLATE:-} ]]; then
  installed_hooks
else
  printf 'Focused lifecycle run only; installed hooks run in test_gate.sh.\n'
fi
guardian_fixture() (
  mkdir -p "$fixture/guardian-loss/scripts" "$logs/guardian-control"
  cp "$source_root/scripts/gate.sh" "$source_root/scripts/gate_lifetime.py" "$fixture/guardian-loss/scripts/"
  cp "$logs/tiny-quality_gate.sh" "$fixture/guardian-loss/scripts/quality_gate.sh"
  cd "$fixture/guardian-loss"
  export FIXTURE_CONTROL="$logs/guardian-control"
  git init -q
  git config user.name 'Guardian-loss fixture'
  git config user.email 'fixture@example.invalid'
  git config core.hooksPath /dev/null
  nested_boundary guardian
)
guardian_fixture
printf 'Lifecycle fixture checks passed. Evidence: %s\n' "$logs"
