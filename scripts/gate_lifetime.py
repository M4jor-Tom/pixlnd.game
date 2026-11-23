"""Kernel-owned quality-command lifetime, including fd-closing/session-changing descendants."""

import ctypes
import fcntl
import json
import os
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path


def read_record(path):
    return json.loads(path.read_text())


def atomic_record(path, record):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".record-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(record, stream, sort_keys=True)
            stream.write("\n")
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def boot_id():
    return Path("/proc/sys/kernel/random/boot_id").read_text().strip()


def active_path(root):
    return root / "lifetime-v1.json"


def bound_attempt(root, value):
    attempt = Path(value)
    relative = attempt.relative_to(root / "v4")
    if len(relative.parts) != 2 or not relative.name.startswith("attempt."):
        raise ValueError("Invalid lifetime attempt")
    if attempt.resolve() != attempt or not attempt.is_dir():
        raise ValueError("Lifetime attempt is not an owned directory")
    return attempt


def drained(attempt):
    registered = read_record(attempt / "lifetime/registered.json")
    proof = read_record(attempt / "lifetime/drained.json")
    return registered == proof and proof == {"protocol": 1, "attempt": str(attempt), "boot": proof["boot"]}


def idle(attempt):
    return not (attempt / "lifetime").exists() or drained(attempt)


def safe(root):
    pointer = active_path(root)
    if not pointer.exists():
        return True
    active = read_record(pointer)
    attempt = bound_attempt(root, active["attempt"])
    return active == read_record(attempt / "lifetime/registered.json") and drained(attempt)


def register(root, attempt):
    if not safe(root):
        raise ValueError("Previous lifetime unresolved; refusing new work")
    record = {"protocol": 1, "attempt": str(attempt), "boot": boot_id()}
    atomic_record(attempt / "lifetime/registered.json", record)
    atomic_record(active_path(root), record)


def enable_subreaper():
    if ctypes.CDLL(None, use_errno=True).prctl(36, 1, 0, 0, 0) != 0:
        raise OSError(ctypes.get_errno(), "PR_SET_CHILD_SUBREAPER")


def wait_command(command, pidfd, attempt):
    stopped = False
    while command.poll() is None:
        if (attempt / "lifetime/stop").exists() and not stopped:
            # The pidfd names our direct child, not a reusable numeric PID.
            try:
                signal.pidfd_send_signal(pidfd, signal.SIGTERM)
            except ProcessLookupError:
                pass
            stopped = True
        time.sleep(0.025)
    return command.returncode if command.returncode >= 0 else 128 - command.returncode


def reap_descendants(attempt):
    count = 0
    while True:
        try:
            pid, status = os.waitpid(-1, os.WNOHANG)
        except ChildProcessError:
            print(f"kernel_drain=ECHILD adopted_children_reaped={count}", flush=True)
            return
        if pid:
            count += 1
            with (attempt / "lifetime/reaped.log").open("a") as stream:
                stream.write(f"pid={pid} wait_status={status}\n")
        else:
            time.sleep(0.025)


def run(root, attempt):
    # Keep this fd in the guardian itself; descendants need not inherit any fd or SID.
    fcntl.flock(9, fcntl.LOCK_EX | fcntl.LOCK_NB)
    registered = read_record(attempt / "lifetime/registered.json")
    if read_record(active_path(root)) != registered or registered != {"protocol": 1, "attempt": str(attempt), "boot": boot_id()}:
        raise ValueError("Lifetime registration lost")
    enable_subreaper()
    ticks = Path(f"/proc/{os.getpid()}/stat").read_text().rsplit(") ", 1)[1].split()[19]
    atomic_record(attempt / "lifetime/guardian.json", {**registered, "pid": os.getpid(), "ticks": ticks})
    command = subprocess.Popen(["bash", "scripts/quality_gate.sh"], cwd=attempt / "work", close_fds=True)
    pidfd = os.pidfd_open(command.pid)
    try:
        rc = wait_command(command, pidfd, attempt)
    finally:
        os.close(pidfd)
    atomic_record(attempt / "lifetime/command.json", {**registered, "command_exit": rc})
    print(f"direct_command_exit={rc}", flush=True)
    reap_descendants(attempt)
    # Positive kernel drain is separate from, and says nothing about, command success.
    atomic_record(attempt / "lifetime/drained.json", registered)
    return rc


def print_command_status(attempt):
    status = attempt / "lifetime/command.json"
    if status.exists():
        record = read_record(status)
        registered = read_record(attempt / "lifetime/registered.json")
        if {key: record[key] for key in registered} != registered:
            raise ValueError("Command status ownership mismatch")
        print(record["command_exit"])


def main(args):
    mode = args[0]
    if mode in {"idle", "drained", "status"}:
        attempt = Path(args[1])
        if mode == "status":
            print_command_status(attempt)
            return 0
        return 0 if (idle if mode == "idle" else drained)(attempt) else 1
    root = Path(args[1])
    if mode == "safe":
        return 0 if safe(root) else 1
    attempt = bound_attempt(root, args[2])
    if mode == "register":
        register(root, attempt)
        return 0
    if mode == "run":
        return run(root, attempt)
    raise ValueError("Unknown lifetime operation")


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except (OSError, ValueError, KeyError) as error:
        print(f"Quality lifetime unknown: {error}", file=sys.stderr)
        sys.exit(2)
