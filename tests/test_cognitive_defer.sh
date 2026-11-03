#!/usr/bin/env bash
# One owner-approved test case; every other marker/identity/limit stays fail-closed.
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/game/entities" "$scratch/ontology"
ln -s "${GDMETRICS_G4:?}/addons" "$scratch/addons"
cp scripts/check_complexity.gd "$scratch/"
printf 'config_version=5\n' > "$scratch/project.godot"
fixture=game/entities/test_android_controls.gd
marker='# @cognitive-defer arrival-resource-recheck'
make_case() {
  local flag=$1 name=${2:-_competing_request} count=${3:-7} i
  printf 'extends Node\n\n'
  [[ -z "$flag" ]] || printf '%s\n' "$flag"
  printf 'func %s(value: int) -> void:\n' "$name"
  for ((i=0;i<count;i++)); do
    printf '\tif value == %s:\n' "$i"
    if ((i<2)); then printf '\t\treturn\n'; else printf '\t\tpass\n'; fi
  done
}
run_analyzer() {
  (cd "$scratch" && find -L game ontology -type f -name '*.gd' -print0) |
    jq -Rs 'split("\u0000")[:-1]' > "$scratch/files.json"
  timeout 681 godot --headless --path "$scratch" -s check_complexity.gd > "$scratch/output.log" 2>&1
}
reject() {
  if run_analyzer; then cat "$scratch/output.log"; echo "FAIL: accepted $1" >&2; exit 1; fi
  grep -q "$2" "$scratch/output.log" || { cat "$scratch/output.log"; exit 1; }
}
make_case "$marker" > "$scratch/$fixture"
gdformat "$scratch/$fixture" >/dev/null
run_analyzer || { cat "$scratch/output.log"; echo 'FAIL: rejected exact permitted deferral' >&2; exit 1; }
grep -q 'DEFERRED .*_competing_request: cognitive complexity 16 exceeds 15' "$scratch/output.log"
grep -q '1 owner-approved deferral' "$scratch/output.log"
printf '\nvar literal = "# @cognitive-defer arrival-resource-recheck"\n' >> "$scratch/$fixture"
run_analyzer || { cat "$scratch/output.log"; exit 1; }
make_case '' > "$scratch/$fixture"
reject 'unflagged approved name' 'cognitive complexity 16 exceeds 15'
for flag in '# @cognitive-ignore arrival-resource-recheck' '# @COGNITIVE-DEFER arrival-resource-recheck' '# @cognitive_defer arrival-resource-recheck' '# @cognitive-defer unknown' '# @cognitive-defer' '# @cognitive-defer arrival-resource-recheck extra' " $marker"; do
  make_case "$flag" > "$scratch/$fixture"
  reject "unknown/malformed marker: $flag" 'Invalid cognitive deferral'
done
make_case "$marker" > "$scratch/$fixture"
sed -i 's/^func /static func /' "$scratch/$fixture"
reject 'wrong static identity' 'Invalid cognitive deferral'
make_case "$marker" wrong_function > "$scratch/$fixture"
reject 'wrong function' 'Invalid cognitive deferral'
make_case "$marker" > "$scratch/game/wrong.gd"
rm "$scratch/$fixture"
reject 'wrong file' 'Invalid cognitive deferral'
rm "$scratch/game/wrong.gd"
make_case "$marker" | sed $'s/^/\t/' > "$scratch/$fixture"
sed -i '1i extends Node\nclass Nested:' "$scratch/$fixture"
reject 'nested same-name function' 'Invalid cognitive deferral'
make_case "$marker" > "$scratch/$fixture"
sed -i "/^func/i # intervening comment" "$scratch/$fixture"
reject 'nonadjacent marker' 'Invalid cognitive deferral'
make_case "$marker" > "$scratch/$fixture"
printf '\n%s\n' "$marker" >> "$scratch/$fixture"
reject 'duplicate marker' 'Invalid cognitive deferral'
printf 'extends Node\n%s\n' "$marker" > "$scratch/$fixture"
reject 'marker without callable' 'Invalid cognitive deferral'
make_case "$marker" _competing_request 1 > "$scratch/$fixture"
reject 'stale under-limit marker' 'Invalid cognitive deferral'
make_case "$marker" > "$scratch/$fixture"
make_case '' unrelated > "$scratch/game/unrelated.gd"
reject 'another over-limit function' 'unrelated: cognitive complexity 16 exceeds 15'
rm "$scratch/game/unrelated.gd"
# Literal marker text is not a live annotation (including multiline strings).
printf 'extends Node\nvar text = """\n%s\n"""\n' "$marker" > "$scratch/$fixture"
run_analyzer || { cat "$scratch/output.log"; exit 1; }
# Deferral cannot suppress either independent size cap.
make_case "$marker" > "$scratch/$fixture"
while [[ $(wc -l < "$scratch/$fixture") -lt 601 ]]; do printf '# padding\n' >> "$scratch/$fixture"; done
if python3 scripts/check_sizes.py "$scratch/$fixture" > "$scratch/size.log" 2>&1; then exit 1; fi
grep -q 'file length 601 exceeds 600' "$scratch/size.log"
printf 'extends Node\n%s\nfunc _competing_request() -> void:\n' "$marker" > "$scratch/$fixture"
for ((i=0;i<100;i++)); do printf '\tprint()\n' >> "$scratch/$fixture"; done
if python3 scripts/check_sizes.py "$scratch/$fixture" > "$scratch/size.log" 2>&1; then exit 1; fi
grep -q 'function length 101 exceeds 100' "$scratch/size.log"
printf 'Cognitive deferral checks passed.\n'
