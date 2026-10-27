#!/usr/bin/env bash
# Catch a gate that ignores formatting, lint, failed tests, or Godot errors with exit 0.
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/scripts" "$scratch/ontology" "$scratch/game/tests"
cp scripts/checks.sh "$scratch/scripts/"
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
if [[ $(grep -Ec '^Elapsed: [0-9]+\.[0-9]{3} s$' "$scratch/output.log") != 4 ]]; then
  printf 'FAIL: missing per-invocation timings\n' >&2
  cat "$scratch/output.log"
  exit 1
fi
# An unrelated working directory must not change the checked project.
(cd / && bash "$scratch/scripts/checks.sh") > "$scratch/output.log" 2>&1
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
