#!/usr/bin/env bash
# Catch ignored format/lint/complexity failures, failed tests, and Godot errors with exit 0.
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/scripts" "$scratch/ontology" "$scratch/game/tests"
cp scripts/check* "$scratch/scripts/"
cp gdlintrc gdformatrc "$scratch/"
printf 'config_version=5\n[application]\nrun/main_scene="res://game/main.tscn"\n' > "$scratch/project.godot"
printf '[gd_scene format=3]\n[node name="Main" type="Node"]\n' > "$scratch/game/main.tscn"
printf 'extends SceneTree\nfunc _init() -> void:\n\tprint("ontology valid")\n\tquit(0)\n' > "$scratch/ontology/validate.gd"
printf 'extends SceneTree\nfunc _init() -> void:\n\tquit(0)\n' > "$scratch/game/tests/test_fixture.gd"
cp "$scratch/game/tests/test_fixture.gd" "$scratch/ontology/test_fixture.gd"

format_fixture() {
  gdformat "$scratch/game" "$scratch/ontology" > /dev/null
}
run_checks() {
  bash "$scratch/scripts/checks.sh" > "$scratch/output.log" 2>&1
}
expect_failure() {
  if run_checks; then
    printf 'FAIL: accepted %s\n' "$1" >&2
    exit 1
  fi
  grep -q "$2" "$scratch/output.log" || { cat "$scratch/output.log"; exit 1; }
}

format_fixture
run_checks || { cat "$scratch/output.log"; exit 1; }
# Every completed Godot invocation reports its own wall-clock duration.
if [[ $(grep -Ec '^Elapsed: [0-9]+\.[0-9]{3} s$' "$scratch/output.log") != 5 ]]; then
  printf 'FAIL: missing per-invocation timings\n' >&2
  cat "$scratch/output.log"
  exit 1
fi
# An unrelated working directory must not change the checked project.
(cd / && bash "$scratch/scripts/checks.sh") > "$scratch/output.log" 2>&1
# gdmetrics-g4 counts each of these seven root-level ifs as 2 and each
# conditional return as 1: 15 must pass, 16 must fail (including in tests).
complexity_fixture() {
  local returns=$1 i
  # Native inline ignores must not bypass the repository's hard cap.
  printf 'extends SceneTree\nfunc _init() -> void:\n\tquit(0)\n# gdmetrics:ignore-next\nfunc check(value: int) -> void:\n'
  for ((i = 0; i < 7; i++)); do
    printf '\tif value == %s:\n' "$i"
    if ((i < returns)); then
      printf '\t\treturn\n'
    else
      printf '\t\tpass\n'
    fi
  done
}
complexity_fixture 1 > "$scratch/game/complexity.gd"
format_fixture
run_checks || { cat "$scratch/output.log"; exit 1; }
rm "$scratch/game/complexity.gd"
for fixture in game/tests/test_complexity.gd ontology/test_complexity.gd \
    game/complexity..gd game/.complexity.gd \
    game/more..tests/test_complexity.gd game/.hidden/test_complexity.gd; do
  mkdir -p "$(dirname "$scratch/$fixture")"
  complexity_fixture 2 > "$scratch/$fixture"
  gdformat "$scratch/$fixture" > /dev/null
  expect_failure "cognitive complexity above 15 in $fixture" 'cognitive complexity 16 exceeds 15'
  rm "$scratch/$fixture"
done
complexity_fixture 2 > "$scratch/game/complexity.gd"
printf '\nclass Harmless:\n\tfunc check() -> void:\n\t\tpass\n' >> "$scratch/game/complexity.gd"
format_fixture
expect_failure 'over-limit method hidden by an equally named method' 'cognitive complexity 16 exceeds 15'
rm "$scratch/game/complexity.gd"
printf 'extends SceneTree\nfunc _init() -> void:\n\tquit(0)\nclass OverLimit:\n' > "$scratch/game/complexity.gd"
complexity_fixture 2 | sed $'s/^/\t/' >> "$scratch/game/complexity.gd"
format_fixture
expect_failure 'class method incorrectly treated as an empty body' 'cognitive complexity 23 exceeds 15'
rm "$scratch/game/complexity.gd"
printf 'extends Node\nvar value=1\n' > "$scratch/game/unformatted.gd"
expect_failure 'unformatted GDScript' 'unformatted.gd'
rm "$scratch/game/unformatted.gd"
printf 'extends Node\nfunc broken(\n' > "$scratch/game/broken.gd"
expect_failure 'invalid GDScript' 'broken.gd'
rm "$scratch/game/broken.gd"
printf 'extends SceneTree\nfunc _init() -> void:\n\tprint("fixture test failed")\n\tquit(1)\n' > "$scratch/game/tests/test_fixture.gd"
format_fixture
expect_failure 'failing gameplay test' 'fixture test failed'
cp "$scratch/ontology/test_fixture.gd" "$scratch/game/tests/test_fixture.gd"
printf 'extends SceneTree\nfunc _init() -> void:\n\tpush_error("fixture engine error")\n\tquit(0)\n' > "$scratch/ontology/test_fixture.gd"
format_fixture
expect_failure 'engine error with exit 0' 'fixture engine error'
printf 'extends SceneTree\nfunc _init() -> void:\n\tcall_deferred("run")\nfunc broken() -> void:\n\tassert(false, "fixture script error")\nfunc run() -> void:\n\tbroken()\n\tquit(0)\n' > "$scratch/ontology/test_fixture.gd"
format_fixture
expect_failure 'script error with exit 0' 'fixture script error'
printf 'extends SceneTree\nfunc _init() -> void:\n\tprint("ontology INVALID (0 errors)")\n\tquit(0)\n' > "$scratch/ontology/validate.gd"
printf 'extends SceneTree\nfunc _init() -> void:\n\tquit(0)\n' > "$scratch/ontology/test_fixture.gd"
format_fixture
expect_failure 'invalid ontology with exit 0' 'ontology INVALID'
printf 'Quality runner checks passed.\n'
