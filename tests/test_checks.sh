#!/usr/bin/env bash
# Catch ignored format/lint/size/complexity failures, failed tests, and Godot errors with exit 0.
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/scripts" "$scratch/ontology" "$scratch/game/tests" "$scratch/tests" "$scratch/skills" "$scratch/monitors" "$scratch/tools"
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

limit_fixture() {
  local lang=$1 kind=$2 n=$3 i
  case "$lang:$kind" in
    py:file) for ((i = 0; i < n; i++)); do printf 'x = 1\n'; done ;;
    py:length) printf 'def check():\n'; for ((i = 1; i < n; i++)); do printf '    x = 1\n'; done ;;
    py:cognitive) printf 'def check(a):\n'; for ((i = 0; i < n; i++)); do printf '    if a:\n        pass\n'; done ;;
    sh:file) for ((i = 0; i < n; i++)); do printf ':\n'; done ;;
    sh:length) printf 'check() {\n'; for ((i = 2; i < n; i++)); do printf '  :\n'; done; printf '}\n' ;;
    sh:cognitive) printf 'check() {\n'; for ((i = 0; i < n; i++)); do printf '  if a; then :; fi\n'; done; printf '}\n' ;;
  esac
}
declare -A limit=([file]=600 [length]=100 [cognitive]=15)
# At-limit fixtures (and an ignored over-limit .venv) must pass the first run.
for lang in py sh; do
  for kind in file length cognitive; do
    limit_fixture "$lang" "$kind" "${limit[$kind]}" > "$scratch/tests/limit_$kind.$lang"
  done
done
mkdir -p "$scratch/tools/.venv"
limit_fixture py file 700 > "$scratch/tools/.venv/ignored.py"
format_fixture
run_checks || { cat "$scratch/output.log"; exit 1; }
# Every completed Godot invocation reports its own wall-clock duration.
if [[ $(grep -Ec '^Elapsed: [0-9]+\.[0-9]{3} s$' "$scratch/output.log") != 6 ]]; then
  printf 'FAIL: missing per-invocation timings\n' >&2
  cat "$scratch/output.log"
  exit 1
fi
# An unrelated working directory must not change the checked project.
(cd / && bash "$scratch/scripts/checks.sh") > "$scratch/output.log" 2>&1
# File caps count comments too, including hidden paths and the tooling itself.
for fixture in game/size.gd ontology/size.gd scripts/size.gd game/.size..gd; do
  printf 'extends Node\n' > "$scratch/$fixture"
  for ((i = 1; i < 600; i++)); do
    printf '# padding\n' >> "$scratch/$fixture"
  done
  gdformat "$scratch/$fixture" > /dev/null
  run_checks || { cat "$scratch/output.log"; exit 1; }
  printf '# padding\n' >> "$scratch/$fixture"
  expect_failure "601-line file $fixture" 'file length 601 exceeds 600'
  rm "$scratch/$fixture"
done
method_fixture() {
  local kind=$1 length=$2 i indent=$'\t'
  printf 'extends Node\n'
  case "$kind" in
    function) printf 'func check() -> void:\n' ;;
    static) printf 'static func check() -> void:\n' ;;
    method) printf 'class Nested:\n\tfunc check() -> void:\n'; indent=$'\t\t' ;;
    getter) printf 'var value:\n\tget:\n'; indent=$'\t\t' ;;
    setter) printf 'var value:\n\tset(_value):\n'; indent=$'\t\t' ;;
    lambda) printf 'var callback = func():\n' ;;
  esac
  for ((i = 1; i < length; i++)); do
    case "$i" in
      50) printf '%s# internal comment\n' "$indent" ;;
      60) printf '\n' ;;
      *) printf '%sprint()\n' "$indent" ;;
    esac
  done
}
for kind in function static method getter setter lambda; do
  method_fixture "$kind" 100 > "$scratch/game/size.gd"
  printf '\n# Unrelated separator: not part of the previous function.\nfunc other() -> void:\n\tpass\n' >> "$scratch/game/size.gd"
  format_fixture
  run_checks || { cat "$scratch/output.log"; exit 1; }
  method_fixture "$kind" 101 > "$scratch/game/size.gd"
  format_fixture
  expect_failure "101-line $kind" 'function length 101 exceeds 100'
  rm "$scratch/game/size.gd"
done
# Last-statement spans must include compound bodies and multiline literals,
# but not the following comment/separator or the next function.
for tail in branch match string; do
  for length in 100 101; do
    case "$tail" in
      branch)
        method_fixture function "$((length - 2))" > "$scratch/game/size.gd"
        printf '\tif true:\n\t\tpass\n' >> "$scratch/game/size.gd"
        ;;
      match)
        method_fixture function "$((length - 3))" > "$scratch/game/size.gd"
        printf '\tmatch 0:\n\t\t_:\n\t\t\tpass\n' >> "$scratch/game/size.gd"
        ;;
      string)
        method_fixture function "$((length - 5))" > "$scratch/game/size.gd"
        printf '\tprint(\n\t\t"""first\nsecond\nthird"""\n\t)\n' >> "$scratch/game/size.gd"
        ;;
    esac
    printf '\n# separator\nfunc other() -> void:\n\tpass\n' >> "$scratch/game/size.gd"
    format_fixture
    if ((length == 100)); then
      run_checks || { cat "$scratch/output.log"; exit 1; }
    else
      expect_failure "101-line function ending with $tail" 'function length 101 exceeds 100'
    fi
    rm "$scratch/game/size.gd"
  done
done
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
# Python/Bash limits: 601/101/16 each fail with exact messages (600/100/15 pass in the first run above).
for lang in py sh; do
  for spec in file:601:'file length 601 exceeds 600' length:101:'function length 101 exceeds 100' \
      cognitive:16:'cognitive complexity 16 exceeds 15'; do
    IFS=: read -r kind n message <<< "$spec"
    fixture="$scratch/tests/limit_$kind.$lang"
    limit_fixture "$lang" "$kind" "$n" > "$fixture"
    expect_failure "$n-limit $kind $lang fixture" "$message"
    limit_fixture "$lang" "$kind" "${limit[$kind]}" > "$fixture"
  done
done
rm -r "$scratch/tests/limit_"* "$scratch/tools/.venv"
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
python3 tests/test_check_python_bash.py
bash tests/test_cognitive_defer.sh
printf 'Quality runner checks passed.\n'
