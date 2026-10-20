#!/usr/bin/env bash
# Keep the host-dependent NVIDIA launcher off unsupported platforms and the default pure.
set -euo pipefail
cd "$(dirname "$0")/.."

nix eval --json .#apps --apply \
  'apps: builtins.mapAttrs (_: value: builtins.attrNames value) apps' |
  jq -e '
    .["x86_64-linux"] == ["default", "nvidia"] and
    .["aarch64-linux"] == ["default"] and
    .["x86_64-darwin"] == ["default"] and
    .["aarch64-darwin"] == ["default"]
  ' >/dev/null

for system in x86_64-linux aarch64-linux aarch64-darwin; do
  nix eval --raw ".#apps.$system.default.program" >/dev/null
done

if [[ "$(uname -m)" == x86_64 && -r /proc/driver/nvidia/version ]]; then
  root="$PWD"
  scratch=$(mktemp -d)
  trap 'rm -rf "$scratch"' EXIT
  if ! (cd "$scratch" && timeout 600 nix run --impure "$root#nvidia" -- \
      --headless --quit-after 1 -- --class=ranger) >"$scratch/boot.log" 2>&1 ||
      ! grep -q '^pixlnd:.*; bow dmg ' "$scratch/boot.log"; then
    cat "$scratch/boot.log"
    exit 1
  fi
else
  printf 'NVIDIA boot skipped: requires x86-64 Linux with a loaded NVIDIA kernel module.\n'
fi

printf 'Flake launcher checks passed.\n'
