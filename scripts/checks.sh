#!/usr/bin/env bash
# Shared by the pre-push hook, manual runs and GitHub Actions.
set -euo pipefail
cd "$(dirname "$0")/.."
shopt -s nullglob

gdlint game ontology
gdformat --check game ontology
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export PIXLND_TEST_DIR="$scratch"

run_godot() {
  local seconds=$1 status
  shift
  printf '\nChecking: godot --headless %s\n' "$*"
  if timeout "$seconds" godot --headless "$@" > "$scratch/godot.log" 2>&1; then
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

for script in ontology/validate.gd ontology/test_*.gd game/*/test_*.gd; do
  seconds=300
  # Real-time capsule traversals cover many routes/lands and need a longer deadline.
  case "$script" in
    game/world/test_local_frame_routes.gd|game/world/test_local_frame_runtime.gd) seconds=450 ;;
  esac
  run_godot "$seconds" -s "$script"
  if [[ "$script" == game/meta/test_world_map.gd ]]; then
    # Many render ticks per physics tick expose fixture/input ordering races.
    run_godot 300 --fixed-fps 1000 -s "$script"
  fi
done
run_godot 150 --quit -- --save-path="$scratch/boot.json"
printf '\nAll quality checks passed.\n'
