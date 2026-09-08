#!/usr/bin/env bash
# Per-thread CPU of the running Godot game, with a verdict for the low-FPS issue: the main thread
# (tid == pid) pegged above THRESHOLD % = physics death spiral reproduced. On an 8-core box that
# shows as only ~12 % total CPU in a system monitor, which is why it looks "fine" there.
# Usage: run the game, then  ./monitors/godot_threads.sh [interval_s] [threshold_pct]
set -euo pipefail
interval=${1:-1}; threshold=${2:-90}
pid=$(pgrep -n -x godot 2>/dev/null || pgrep -n -f 'godot.*--path' || true)
[[ -z "$pid" ]] && { echo "no godot process running"; exit 1; }
cores=$(nproc)
while kill -0 "$pid" 2>/dev/null; do
  main=$(top -H -b -n 2 -d "$interval" -p "$pid" | awk -v p="$pid" '$1 == p {v=$9} END {print v+0}')
  clear
  echo "godot pid $pid | $cores cores → one saturated thread = ~$((100 / cores)) % total CPU"
  echo "main thread: ${main} %   (threshold ${threshold} %)"
  if (( ${main%.*} >= threshold )); then
    printf '\e[1;31mISSUE REPRODUCED\e[0m — main thread saturated (physics catch-up spiral)\n'
  else
    printf '\e[1;32missue not reproduced\e[0m — main thread has headroom\n'
  fi
  echo "--- threads > 0.5 %:"
  top -H -b -n 1 -p "$pid" | awk '$1 ~ /^[0-9]+$/ && $9+0 > 0.5 {printf "%-8s %6s%%  %s\n", $1, $9, $NF}' | sort -k2 -rn | head -12
done
echo "godot exited"
