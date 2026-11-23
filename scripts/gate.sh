#!/usr/bin/env bash
# Detached exact-tree gates. start acknowledges a claim, never a pass.
set -euo pipefail
cd "$(dirname "$0")/.."
repo=$PWD
gate_root="$(git rev-parse --path-format=absolute --git-common-dir)/pixlnd-gate"
# Never read or change historical markers (including v2/v3).
receipts="$gate_root/v4"
mkdir -p "$receipts"
boot_id=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null) || boot_id=

require_python() {
  command -v python3 >/dev/null && [[ -r $repo/scripts/gate_lifetime.py ]] || {
    printf 'Quality gate requires host python3 on PATH and scripts/gate_lifetime.py.\n' >&2
    return 2
  }
}
lifetime() { python3 "$repo/scripts/gate_lifetime.py" "$@"; }
identity() {
  local stat
  [[ $1 =~ ^[1-9][0-9]*$ ]] || return 2
  [[ -d /proc/$1 ]] || return 1
  { IFS= read -r stat <"/proc/$1/stat"; } 2>/dev/null || return 2
  # comm is parenthesized and may itself contain spaces or ')'. starttime is field 22.
  read -ra proc_fields <<<"${stat##*) }"
  [[ ${#proc_fields[@]} -ge 20 ]] || return 2
  proc_state=${proc_fields[0]}
  proc_ticks=${proc_fields[19]}
  [[ -n $boot_id ]] || return 2
  proc_boot=$boot_id
}
owner_alive() {
  local rc=0
  identity "$r_pid" || rc=$?
  ((rc == 0)) || return "$rc"
  [[ $proc_boot == "$r_boot" && $proc_ticks == "$r_ticks" ]] || return 1
  [[ $proc_state != Z && $proc_state != X ]]
}
claim_lock() {
  mkdir -p "$receipts/$tree"
  exec 7>"$receipts/$tree/claim.lock"
  flock -w 2 7
}
load_state() {
  local key value
  r_protocol= r_tree= r_attempt= r_outcome=none r_pid= r_boot= r_ticks=
  r_started= r_ended= r_command_exit= r_worker_exit= r_cleanup= r_log=
  [[ -f $receipts/$tree/state ]] || return 0
  while IFS='=' read -r key value; do
    case "$key" in
      protocol | tree | attempt | outcome | pid | boot | ticks | started | ended | command_exit | worker_exit | cleanup | log)
        printf -v "r_$key" '%s' "$value" ;;
    esac
  done <"$receipts/$tree/state"
  if [[ $r_protocol != 4 || $r_tree != "$tree" ]]; then r_outcome=unknown; fi
}
valid_attempt() {
  [[ $r_attempt == "$receipts/$tree/attempt."* ]] || return 1
  [[ ${r_attempt#"$receipts/$tree/"} =~ ^attempt\.[a-zA-Z0-9]+$ ]] || return 1
  [[ -d $r_attempt && ! -L $r_attempt ]]
}
publish() {
  local tmp
  valid_attempt || return 1
  tmp=$(mktemp "$r_attempt/.status.XXXXXX")
  printf '%s\n' "protocol=4" "tree=$tree" "attempt=$r_attempt" "outcome=$r_outcome" \
    "pid=$r_pid" "boot=$r_boot" "ticks=$r_ticks" "started=$r_started" "ended=$r_ended" \
    "command_exit=$r_command_exit" "worker_exit=$r_worker_exit" "cleanup=$r_cleanup" \
    "log=$r_attempt/gate.log" >"$tmp"
  mv "$tmp" "$r_attempt/status"
  tmp=$(mktemp "$receipts/$tree/.state.XXXXXX")
  cat "$r_attempt/status" >"$tmp"
  mv "$tmp" "$receipts/$tree/state"
}
reconcile() {
  local rc=0
  case $r_outcome in queued | running) ;; *) return 0 ;; esac
  owner_alive || rc=$?
  case $rc in
    0) return 0 ;;
    1)
      r_outcome=interrupted r_ended=$(date -u +%FT%TZ) r_cleanup=pending
      # No terminal wait was observed: do not manufacture an exit/signal code.
      r_worker_exit=
      publish || r_outcome=unknown ;;
    *) r_outcome=unknown ;;
  esac
}
validated_pass() {
  [[ $r_outcome == pass && $r_command_exit == 0 && $r_worker_exit == 0 && $r_cleanup == ok ]] || return 1
  [[ -n $r_started && -n $r_ended && $r_log == "$r_attempt/gate.log" ]] || return 1
  valid_attempt || return 1
  lifetime drained "$r_attempt" || return 1
  cmp -s "$receipts/$tree/state" "$r_attempt/status"
}
check() {
  local rev=${1:-${PRE_COMMIT_TO_REF:-HEAD}}
  require_python
  tree=$(git rev-parse --verify "$rev^{tree}")
  claim_lock
  load_state
  reconcile
  if validated_pass; then return 0; fi
  printf 'Quality gate %s for %s (tree %s); log: %s\n' "$r_outcome" "$rev" "$tree" "${r_log:-unknown}"
  return 1
}
retry_safe() {
  [[ $r_cleanup == pending || $r_cleanup == blocked ]] || return 0
  valid_attempt
  exec 6>"$gate_root/lock"
  flock -n 6 || { printf 'Previous lifetime may still be active; retry refused.\n' >&2; return 1; }
  lifetime safe "$gate_root"
  lifetime idle "$r_attempt"
  exec 6>&-
}
start() {
  local commit attempt previous= i
  require_python
  [[ -z ${SKIP:-} ]] || { printf 'The complete quality gate rejects nonempty SKIP.\n' >&2; return 2; }
  commit=$(git rev-parse --verify "${1:-HEAD}^{commit}")
  tree=$(git rev-parse "$commit^{tree}")
  claim_lock
  load_state
  reconcile
  if validated_pass; then return 0; fi
  case $r_outcome in
    queued | running) return 0 ;;
    unknown) printf 'Unknown attempt ownership; refusing automatic retry.\n' >&2; return 1 ;;
  esac
  retry_safe
  if [[ $r_cleanup == pending || $r_cleanup == blocked ]]; then previous=$r_attempt; fi
  attempt=$(mktemp -d "$receipts/$tree/attempt.XXXXXX")
  printf '%s\n' "$previous" >"$attempt/previous"
  # fd 7 crosses launch: the child publishes its full identity before releasing the claim.
  setsid nohup bash "$repo/scripts/gate.sh" run "$commit" "$tree" "$attempt" "$previous" \
    >"$attempt/gate.log" 2>&1 </dev/null &
  for ((i = 0; i < 100; i++)); do
    if [[ -f $attempt/ready ]]; then
      printf 'Quality gate queued; progress: %s\n' "$attempt/gate.log"
      return 0
    fi
    sleep 0.05
  done
  printf 'Worker launch unconfirmed; inspect %s\n' "$attempt/gate.log" >&2
  return 1
}
owned() {
  load_state
  [[ $r_attempt == "$attempt" && $r_pid == "$$" && $r_boot == "$own_boot" && $r_ticks == "$own_ticks" ]]
}
update_running() {
  claim_lock
  owned
  r_outcome=running
  publish
  exec 7>&-
}
command_idle() {
  lifetime idle "$attempt"
}
remove_work() {
  local path=$1
  [[ -e $path ]] || return 0
  [[ -d $path && ! -L $path && $(git -C "$path" rev-parse --path-format=absolute --git-common-dir) == "${gate_root%/pixlnd-gate}" ]] || return 1
  git -C "$repo" worktree remove --force "$path"
}
cleanup_work() {
  claim_lock
  if ! owned; then exec 7>&-; return 1; fi
  exec 7>&-
  command_idle || return 1
  remove_work "$attempt/work"
}
cleanup_previous() {
  local previous=$1 count=0 name
  while [[ -n $previous ]]; do
    name=${previous#"$receipts/$tree/"}
    [[ $name =~ ^attempt\.[a-zA-Z0-9]+$ && ! -L $previous ]] || return 1
    ((count += 1))
    ((count <= 100)) || return 1
    lifetime idle "$previous" || return 1
    remove_work "$previous/work" || return 1
    IFS= read -r previous <"$previous/previous" || return 1
  done
}
stop_command() {
  local i
  [[ -d $attempt/lifetime ]] || return 0
  touch "$attempt/lifetime/stop"
  for ((i = 0; i < 40; i++)); do
    [[ -f $attempt/lifetime/drained.json ]] && break
    sleep 0.025
  done
  command_rc=$(lifetime status "$attempt")
  command_idle
}
write_worker_footer() {
  local status=$1 cleanup=$2
  printf 'worker_exited_utc=%s command_exit=%s worker_exit=%s cleanup=%s\n' "$(date -u +%FT%TZ)" "${command_rc:-unknown}" "$status" "$cleanup" || {
    ((status != 0)) || status=1
  }
  return "$status"
}
terminal_outcome() {
  if [[ ${aborted:-no} == yes ]]; then printf interrupted
  elif [[ ${command_rc:-} == 124 ]]; then printf timeout
  elif [[ $1 == 0 && ${command_rc:-} == 0 && ${verified:-no} == yes ]]; then printf pass
  else printf fail
  fi
}
finish() {
  local status=$? cleanup=pending
  trap - EXIT TERM INT HUP
  if [[ ${aborted:-no} == yes ]]; then
    stop_command || true
  fi
  if [[ ${execution_locked:-no} == yes ]]; then
    if cleanup_work && [[ ${previous_cleaned:-no} == yes ]]; then cleanup=ok; else cleanup=blocked; fi
  fi
  if [[ $cleanup != ok && $status == 0 ]]; then status=1; fi
  write_worker_footer "$status" "$cleanup" || status=$?
  claim_lock
  if owned; then
    r_command_exit=${command_rc:-} r_worker_exit=$status r_cleanup=$cleanup r_ended=$(date -u +%FT%TZ)
    r_outcome=$(terminal_outcome "$status")
    publish
  fi
  exit "$status"
}
record_command_exit() {
  claim_lock
  owned
  r_command_exit=$command_rc
  publish
  exec 7>&-
}
run_command() {
  lifetime register "$gate_root" "$attempt"
  python3 "$repo/scripts/gate_lifetime.py" run "$gate_root" "$attempt" 7>&- &
  guardian_pid=$!
  if wait "$guardian_pid"; then guardian_rc=0; else guardian_rc=$?; fi
  # A lost guardian's exit is not the command's exit and cannot prove drain.
  command_rc=$(lifetime status "$attempt")
}
run() {
  local commit=$1 previous=$4
  tree=$2 attempt=$3
  [[ $(readlink "/proc/$$/fd/7") == "$receipts/$tree/claim.lock" ]]
  # The inherited claim lock is still held until queued + identity are durable.
  identity "$$"
  own_boot=$proc_boot own_ticks=$proc_ticks
  r_attempt=$attempt r_pid=$$ r_boot=$own_boot r_ticks=$own_ticks r_outcome=queued
  r_started=$(date -u +%FT%TZ) r_ended= r_command_exit= r_worker_exit= r_cleanup=pending
  trap finish EXIT
  trap 'aborted=yes; exit 143' TERM
  trap 'aborted=yes; exit 130' INT
  trap 'aborted=yes; exit 129' HUP
  publish
  touch "$attempt/ready"
  exec 7>&-
  [[ -z ${SKIP:-} ]]
  mapfile -t git_env < <(git rev-parse --local-env-vars)
  unset "${git_env[@]}"
  [[ "$(git rev-parse --path-format=absolute --git-common-dir)/pixlnd-gate" == "$gate_root" ]]
  exec 9>"$gate_root/lock"
  # ponytail: one expensive gate globally; parallel gates would starve Godot of memory.
  flock 9
  execution_locked=yes
  lifetime safe "$gate_root"
  update_running
  cleanup_previous "$previous"
  previous_cleaned=yes
  [[ $(git rev-parse --verify "$commit^{commit}") == "$commit" ]]
  [[ $(git rev-parse "$commit^{tree}") == "$tree" ]]
  git worktree add --detach "$attempt/work" "$commit"
  [[ $(git -C "$attempt/work" rev-parse HEAD^{tree}) == "$tree" ]]
  export QUALITY_GATE_LOG_ROOT="$attempt"
  run_command
  record_command_exit
  [[ $(git -C "$attempt/work" rev-parse HEAD^{tree}) == "$tree" ]]
  verified=yes
  exit "$guardian_rc"
}
case "${1:-}" in
  start | check) "$@" ;;
  run) run "${2:?}" "${3:?}" "${4:?}" "${5:-}" ;;
  *) printf 'usage: %s start|check [rev]\n' "$0" >&2; exit 2 ;;
esac
