#!/usr/bin/env bash
# Shared by the background post-commit gate (scripts/gate.sh), manual runs and GitHub Actions.
set -euo pipefail
cd "$(dirname "$0")/.."
shopt -s nullglob

# game/generated/ is generator output (linkml-gdscript): checked by its own golden tests, not here.
gd_sources() { find -L game ontology scripts tests/ontology -path game/generated -prune -o -type f -name '*.gd' -print0; }
gd_sources | xargs -0 gdlint
gd_sources | xargs -0 gdformat --check
gd_sources | xargs -0 python3 scripts/check_sizes.py
find -L scripts tests skills monitors tools -name .venv -prune -o -type f \( -name '*.py' -o -name '*.sh' \) -print0 |
  xargs -0 python3 scripts/check_python_bash.py
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export PIXLND_TEST_DIR="$scratch"

run_godot() {
  local seconds=$1 status TIMEFORMAT='Elapsed: %3R s'
  shift
  printf '\nChecking: godot --headless %s\n' "$*"
  if time timeout "$seconds" godot --headless "$@" > "$scratch/godot.log" 2>&1; then
    cat "$scratch/godot.log"
    # Godot can report script/engine errors yet exit 0; the validator can too.
    ! grep -Eq '^(SCRIPT ERROR:|ERROR:|ontology INVALID)' "$scratch/godot.log"
  else
    status=$?
    cat "$scratch/godot.log"
    printf 'Godot failed or timed out (exit %s).\n' "$status" >&2
    return "$status"
  fi
}

# Run the analyzer without this project's autoloads, saves, caches or runtime.
metrics="$scratch/metrics"
mkdir "$metrics"
ln -s "${GDMETRICS_G4:?run the gate inside nix develop}/addons" "$metrics/addons"
cp -R game ontology "$metrics/"
mkdir "$metrics/tests"
cp -R tests/ontology "$metrics/tests/"
cp scripts/check_complexity.gd "$metrics/"
# Enumerate independently: gdmetrics discovery silently skips hidden and '..' names.
(cd "$metrics" && find -L game ontology tests/ontology -path game/generated -prune -o -type f -name '*.gd' -print0) |
  jq -Rs 'split("\u0000")[:-1]' > "$metrics/files.json"
printf 'config_version=5\n' > "$metrics/project.godot"
run_godot 1719 --path "$metrics" -s check_complexity.gd

# Generated domain classes resolve each other by class_name: build the global class cache first.
run_godot 300 --import
for script in ontology/validate.gd ontology/test_*.gd tests/ontology/test_*.gd game/*/test_*.gd; do
  seconds=1719
  # Capsule traversals retain their separately calibrated deadline.
  case "$script" in
    game/world/test_local_frame_routes.gd|game/world/test_local_frame_runtime.gd) seconds=1263 ;;
  esac
  run_godot "$seconds" -s "$script"
  if [[ "$script" == game/meta/test_world_map.gd ]]; then
    # Many render ticks per physics tick expose fixture/input ordering races.
    run_godot 1719 --fixed-fps 1000 -s "$script"
  fi
done
run_godot 12 --quit -- --save-path="$scratch/boot.json"
printf '\nAll quality checks passed.\n'
