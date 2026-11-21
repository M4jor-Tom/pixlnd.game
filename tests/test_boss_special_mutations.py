#!/usr/bin/env python3
"""Real boss regression mutations; production writes occur only in an owned copy.

Run: python3 tests/test_boss_special_mutations.py --evidence /absolute/new/output
The evidence directory must not already exist; retained results are never reused.
Use --list to inspect exact mutations without launching Godot.
"""
import argparse
import hashlib
import json
import os
import shutil
import signal
import stat
import subprocess
import tempfile
import time
from pathlib import Path

BOSS = "game/combat/boss_special.gd"
CREATURE = "game/entities/creature.gd"
MUTATIONS = [
    ("readiness", BOSS,
     'saved.engaged = true\n\tvar step := minf(remaining, float(saved.left))',
     'saved.engaged = true\n\tvar step := minf(remaining * 0.5, float(saved.left))',
     "readiness enters visible warning"),
    ("warning", BOSS,
     'saved.left = float(cfg["warning-s"])',
     'saved.left = float(cfg["warning-s"]) * 0.5',
     "warning lasts 1.2 seconds"),
    ("recovery", BOSS,
     'saved.recovery = float(cfg["recovery-s"])',
     'saved.recovery = float(cfg["recovery-s"]) * 0.5',
     "recovery suppresses basic attacks"),
    ("physical-defence", BOSS,
     'Combat.PHYSICAL,', 'Combat.MAGICAL,',
     "physical armor subtracts ten; Resistance ignored"),
    ("charge-speed", BOSS,
     'var distance := minf(delta.length(), float(rules.speed) * dt)',
     'var distance := minf(delta.length(), float(rules.speed) * dt * 0.5)',
     "charge travels three blocks in quarter second"),
    ("first-player", BOSS,
     '\t\thit_player(body, float(rules["damage-mult"]))',
     '\t\tif body == boss.target:\n\t\t\thit_player(body, float(rules["damage-mult"]))',
     "swept charge stops at first of two players, not selected far target"),
    ("interrupted-push", CREATURE,
     '_stun_push += Vector3(velocity.x - before.x, 0, velocity.z - before.z)',
     '_stun_push += Vector3(velocity.x - before.x, 0, velocity.z - before.z) * 0.0',
     "cancelled special still carries external push stomp-warning/true/wall=false"),
    ("rubble", BOSS,
     'contents.break_rubble(body.get_meta("rubble"))',
     'contents.sync_views()',
     "charge shatters real crossed rubble and continues into player"),
    ("inactive", CREATURE,
     'if not _simulation_active():', 'if false and not _simulation_active():',
     "inactive simulation pauses special timer"),
    ("unload-restart", BOSS,
     'if record.phase in ["warning", "charge"]:',
     'if false and record.phase in ["warning", "charge"]:',
     "cold restart cancels saved warning, never replaying impact"),
    ("malformed-save", "game/world/save_site_rules.gd",
     'value.get("engaged") is bool and value.get("target") is String',
     'value.get("target") is String',
     "malformed saved special engaged<null> rejected"),
]
ERRORS = ("SCRIPT ERROR:", "ERROR:", "ontology INVALID")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def copy_project(source, destination):
    """Materialize regular independent bytes, never preserve live links/inodes."""
    paths = subprocess.check_output(
        ["git", "ls-files", "-co", "--exclude-standard", "-z"], cwd=source
    ).decode().split("\0")
    for name in sorted(set(filter(None, paths))):
        original = source / name
        if original.is_dir():  # repository skill-directory aliases are not runtime inputs
            continue
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(original, target)
        target.chmod(stat.S_IMODE(original.stat().st_mode))
        assert not target.is_symlink() and not os.path.samefile(original, target)
    assert not (destination / ".git").exists()


def owned_target(project, source, relative):
    target = project / relative
    assert project.resolve() in target.resolve().parents
    assert source.resolve() not in target.resolve().parents
    assert not target.is_symlink() and target.stat().st_nlink == 1
    assert not os.path.samefile(target, source / relative)
    return target


def launch(project, evidence, name):
    scratch = evidence / name
    scratch.mkdir()
    command = ["nix", "develop", "path:" + str(project), "--no-update-lock-file", "-c", "timeout", "681",
               "godot", "--headless", "-s", "game/combat/test_boss_special.gd"]
    record = {"name": name, "cwd": str(project), "command": command,
              "PIXLND_TEST_DIR": str(scratch), "log": str(scratch / "run.log"),
              "started_unix": time.time()}
    with (evidence / "launches.jsonl").open("a") as ledger:
        ledger.write(json.dumps({**record, "event": "start"}) + "\n")
    with (scratch / "run.log").open("w") as log:
        result = subprocess.run(command, cwd=project,
                                env={**os.environ, "PIXLND_TEST_DIR": str(scratch)},
                                stdout=log, stderr=subprocess.STDOUT, check=False)
    text = (scratch / "run.log").read_text()
    record.update(exit=result.returncode, seconds=time.time() - record["started_unix"],
                  assertions=[line[6:] for line in text.splitlines() if line.startswith("FAIL: ")])
    with (evidence / "launches.jsonl").open("a") as ledger:
        ledger.write(json.dumps({**record, "event": "exit"}) + "\n")
    invalid = any(line.startswith(ERRORS) for line in text.splitlines())
    return record, text, invalid


def green(project, evidence, name):
    record, text, invalid = launch(project, evidence, name)
    assert record["exit"] == 0 and not invalid and not record["assertions"], record
    assert "boss special ok" in text, record
    return record


def run(source, evidence, only=None):
    assert source not in evidence.resolve().parents and source != evidence.resolve()
    evidence.mkdir(parents=True, exist_ok=False)
    project = Path(tempfile.mkdtemp(prefix="project-", dir=evidence)).resolve()
    copy_project(source, project)
    for pin in ["flake.nix", "flake.lock"]:
        assert (project / pin).read_bytes() == (source / pin).read_bytes()
    plan = [dict(zip(("name", "path", "old", "new", "expected_assertion"), row))
            for row in MUTATIONS if only is None or row[0] == only]
    (evidence / "plan.json").write_text(json.dumps(plan, indent=2))
    results = {"source": str(source), "project": str(project), "mutations": []}
    results["pristine"] = green(project, evidence, "pristine")
    for mutation in plan:
        target = owned_target(project, source, mutation["path"])
        original, mode = target.read_bytes(), stat.S_IMODE(target.stat().st_mode)
        old, new = mutation["old"].encode(), mutation["new"].encode()
        assert original.count(old) == 1, mutation
        row = {**mutation, "original_sha256": digest(original)}
        try:
            target.write_bytes(original.replace(old, new))
            row["mutated_sha256"] = digest(target.read_bytes())
            row["red"], text, invalid = launch(project, evidence, mutation["name"] + "-red")
        finally:
            owned_target(project, source, mutation["path"])
            target.write_bytes(original)
            target.chmod(mode)
            row["restored_sha256"] = digest(target.read_bytes())
            assert target.read_bytes() == original and stat.S_IMODE(target.stat().st_mode) == mode
            results["mutations"].append(row)
            (evidence / "results.json").write_text(json.dumps(results, indent=2))
        # Invalid REDs stop after byte restoration, before any dependent launch.
        assert row["red"]["exit"] == 1 and not invalid, row
        assert mutation["expected_assertion"] in row["red"]["assertions"], row
        row["green"] = green(project, evidence, mutation["name"] + "-restored")
        (evidence / "results.json").write_text(json.dumps(results, indent=2))
        print(mutation["name"] + ": named RED(1), byte-restored GREEN(0)", flush=True)
    return results


def interrupted(_signum, _frame):
    raise KeyboardInterrupt("interrupted; mutation finally restores owned bytes")


def main():
    signal.signal(signal.SIGTERM, interrupted)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path)
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--only", choices=[row[0] for row in MUTATIONS])
    args = parser.parse_args()
    if args.list:
        print(json.dumps(MUTATIONS, indent=2))
        return
    if not args.evidence or not args.evidence.is_absolute():
        parser.error("--evidence must be an absolute owned directory")
    run(Path(__file__).resolve().parents[1], args.evidence.resolve(), args.only)


if __name__ == "__main__":
    main()
