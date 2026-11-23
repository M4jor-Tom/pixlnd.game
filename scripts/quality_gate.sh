#!/usr/bin/env bash
# The sole synchronous host/CI entry: the manual manifest is the execution list.
set -euo pipefail
SECONDS=0
started_utc=$(date -u +%FT%TZ)
cd "$(dirname "$0")/.."
if (($#)) || [[ -n ${SKIP:-} ]]; then
  printf 'The complete quality gate accepts no selectors or nonempty SKIP.\n' >&2
  exit 2
fi
# Reject a foreign checkout/index rather than certifying what pre-commit did not inspect.
mapfile -t git_env < <(git rev-parse --local-env-vars)
for variable in "${git_env[@]}"; do
  if [[ -n ${!variable:-} ]]; then
    printf 'Quality gate rejects inherited Git override: %s\n' "$variable" >&2
    exit 2
  fi
done
if [[ $(git rev-parse --show-toplevel) != "$PWD" ]]; then
  printf 'Quality gate requires this checkout and its own Git index.\n' >&2
  exit 2
fi
root=$(realpath -m "${QUALITY_GATE_LOG_ROOT:-/tmp}")
case "$root/" in
  "$PWD/"*)
    printf 'Quality logs must be outside the checkout.\n' >&2
    exit 2
    ;;
esac
mkdir -p "$root"
export QUALITY_GATE_LOG_DIR
QUALITY_GATE_LOG_DIR=$(mktemp -d "$root/pixlnd-quality.XXXXXX")
export PRE_COMMIT_HOME="$QUALITY_GATE_LOG_DIR/pre-commit" UV_CACHE_DIR="$QUALITY_GATE_LOG_DIR/uv-cache"
printf 'Quality gate artifacts: %s\n' "$QUALITY_GATE_LOG_DIR"
finish() {
  local status=$?
  trap - EXIT
  printf 'exited_utc=%s\nouter_elapsed_seconds=%s\nexit_status=%s\n' \
    "$(date -u +%FT%TZ)" "$SECONDS" "$status" >>"$QUALITY_GATE_LOG_DIR/run.status"
  if [[ -f "$QUALITY_GATE_LOG_DIR/resources.log" ]]; then
    cat "$QUALITY_GATE_LOG_DIR/resources.log"
  fi
  cat "$QUALITY_GATE_LOG_DIR/run.status"
  exit "$status"
}
trap finish EXIT
printf 'started_utc=%s\ncommit=%s\ntree=%s\n' "$started_utc" \
  "$(git rev-parse HEAD)" "$(git rev-parse HEAD^{tree})" >"$QUALITY_GATE_LOG_DIR/run.status"
git status --porcelain=v1 --untracked-files=all >"$QUALITY_GATE_LOG_DIR/before.status"
if [[ -s "$QUALITY_GATE_LOG_DIR/before.status" ]]; then
  printf 'Quality gate requires clean inputs:\n' >&2
  cat "$QUALITY_GATE_LOG_DIR/before.status" >&2
  exit 1
fi
# GNU Time is external (Bash's reserved word cannot report child RSS), on PATH on host/CI.
time_command=$(type -P time)
status=0
"$time_command" -o "$QUALITY_GATE_LOG_DIR/resources.log" \
  -f 'bounded_command_elapsed_seconds=%e\nlargest child RSS=%M KiB (not summed process-tree RSS)' \
  timeout --kill-after=20s 80m env -u LD_LIBRARY_PATH \
  nix develop --no-update-lock-file -c pre-commit run --all-files --hook-stage manual || status=$?
git status --porcelain=v1 --untracked-files=all >"$QUALITY_GATE_LOG_DIR/after.status" || {
  git_status=$?
  ((status != 0)) || status=$git_status
}
if [[ -s "$QUALITY_GATE_LOG_DIR/after.status" ]]; then
  printf 'Checkout changed during quality gate:\n' >&2
  cat "$QUALITY_GATE_LOG_DIR/after.status" >&2
  ((status != 0)) || status=1
fi
exit "$status"
