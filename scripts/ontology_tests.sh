#!/usr/bin/env bash
# Called inside the pinned shell; tee makes Python progress visible before pre-commit releases it.
set -uo pipefail
cd "$(dirname "$0")/.." || exit
run_tests() {
  uv run --locked --project tools/ontology python -u -m unittest discover -v -s tests -p 'test_ontology*.py'
}
if [[ -z ${QUALITY_GATE_LOG_DIR:-} ]]; then
  run_tests
  exit $?
fi
log="$QUALITY_GATE_LOG_DIR/ontology-tests.log"
summary="$QUALITY_GATE_LOG_DIR/ontology-tests.status"
printf 'started_utc=%s\n' "$(date -u +%FT%TZ)" >"$summary" || exit
record_output() {
  local line
  while IFS= read -r line || [[ -n $line ]]; do
    printf '%s\n' "$line" || return
    case "$line" in
      'Ran '* | OK | FAILED*) printf 'last_summary_utc=%s\n' "$(date -u +%FT%TZ)" >>"$summary" || return ;;
    esac
  done
}
run_tests 2>&1 | tee "$log" | record_output
statuses=("${PIPESTATUS[@]}")
status=0
# Keep the first failing boundary, especially uv/Python even if a later pipe also fails.
for code in "${statuses[@]}"; do
  if ((code != 0)); then
    status=$code
    break
  fi
done
printf 'exited_utc=%s\nexit_status=%s\n' "$(date -u +%FT%TZ)" "$status" >>"$summary" || {
  log_status=$?
  ((status != 0)) || status=$log_status
}
exit "$status"
