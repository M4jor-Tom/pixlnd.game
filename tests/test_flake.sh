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

root="$PWD"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
boot() {
  local app=$1
  shift
  mkdir "$scratch/$app"
  if ! (cd "$scratch/$app" && timeout 600 nix run "$@" "$root#$app" -- \
      --headless --quit-after 1 -- --class=ranger --save-path="$PWD/world.json") >"$scratch/$app.log" 2>&1 ||
      grep -Eq '^(SCRIPT ERROR:|ERROR:)' "$scratch/$app.log" ||
      ! grep -Eq "^pixlnd:.*land '[^']+'.*; bow dmg " "$scratch/$app.log"; then
    cat "$scratch/$app.log" >&2
    exit 1
  fi
}

boot default
if [[ "$(uname -m)" == x86_64 && -r /proc/driver/nvidia/version ]]; then
  boot nvidia --impure
else
  printf 'NVIDIA boot skipped: requires x86-64 Linux with a loaded NVIDIA kernel module.\n'
fi

printf 'Flake launcher checks passed.\n'
