#!/usr/bin/env bash
# Background quality gate. post-commit starts it; pre-push only checks its receipt, so a push
# never holds a connection open for the tens of minutes the full gate takes.
#   gate.sh start [rev]  run the gate detached on rev's committed tree (default HEAD)
#   gate.sh check [rev]  succeed only if rev's tree passed (pre-push passes PRE_COMMIT_TO_REF)
#   gate.sh run <tree>   the gate itself (quality runner, then scripts/checks.sh)
# Receipts are keyed by tree, so a squash or rebase with an identical tree reuses its pass.
set -euo pipefail
cd "$(dirname "$0")/.."
receipts="$(git rev-parse --path-format=absolute --git-common-dir)/pixlnd-gate"
mkdir -p "$receipts"

state() { # pass | fail | running | none
  local s
  for s in pass fail running; do
    if [[ -e "$receipts/$1.$s" ]]; then
      printf '%s' "$s"
      return
    fi
  done
  printf none
}

start() {
  local tree
  tree=$(git rev-parse "${1:-HEAD}^{tree}")
  if [[ $(state "$tree") == pass || $(state "$tree") == running ]]; then
    return
  fi
  rm -f "$receipts/$tree.fail"
  : > "$receipts/$tree.running"
  setsid nohup bash scripts/gate.sh run "$tree" > "$receipts/$tree.log" 2>&1 < /dev/null &
  printf 'Quality gate started in the background; log: %s\n' "$receipts/$tree.log"
}

check() {
  local rev=${1:-${PRE_COMMIT_TO_REF:-HEAD}} tree
  tree=$(git rev-parse "$rev^{tree}")
  case $(state "$tree") in
    pass) return 0 ;;
    running) printf 'Quality gate still running for %s; log: %s\n' "$rev" "$receipts/$tree.log" ;;
    fail) printf 'Quality gate FAILED for %s; log: %s\n' "$rev" "$receipts/$tree.log" ;;
    none) printf 'No quality gate run for %s: run `bash scripts/gate.sh start %s`\n' "$rev" "$rev" ;;
  esac
  return 1
}

run() {
  local tree=$1
  exec 9> "$receipts/lock"
  flock 9 # ponytail: one gate at a time, queued; parallel gates would starve Godot of memory
  work=$(mktemp -d) # global: the EXIT trap runs after this function returns
  trap 'rm -rf "$work"' EXIT
  git archive "$tree" | tar -x -C "$work"
  # The session's LD_LIBRARY_PATH may point at host libraries that break the pinned Godot.
  if (cd "$work" && env -u LD_LIBRARY_PATH nix develop --no-update-lock-file \
    -c bash -c 'bash tests/test_checks.sh && bash scripts/checks.sh'); then
    mv "$receipts/$tree.running" "$receipts/$tree.pass"
  else
    mv "$receipts/$tree.running" "$receipts/$tree.fail"
  fi
}

case "${1:-}" in
  start | check | run) "$@" ;;
  *)
    printf 'usage: %s start|check [rev] | run <tree>\n' "$0" >&2
    exit 2
    ;;
esac
