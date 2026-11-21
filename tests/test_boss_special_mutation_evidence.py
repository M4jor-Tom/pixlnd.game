#!/usr/bin/env python3
"""Check evidence admission without launching Nix/Godot; run with python3 -B."""
import importlib.util
import shutil
import tempfile
from pathlib import Path


class NativeLaunchBlocked(Exception):
    pass


def verify_existing(runner, source, root, name, files, failures):
    evidence = root / name
    evidence.mkdir()
    for filename, content in files.items():
        (evidence / filename).write_bytes(content)
    try:
        runner.run(source, evidence, only="malformed-save")
    except FileExistsError:
        pass
    except NativeLaunchBlocked:
        failures.append(name + ": reused evidence reached native preflight")
    else:
        failures.append(name + ": existing evidence was accepted")
    actual = {str(p.relative_to(evidence)): p.read_bytes()
              for p in evidence.rglob("*") if p.is_file()}
    if actual != files or set(evidence.iterdir()) != {evidence / p for p in files}:
        failures.append(name + ": existing evidence changed")


def run():
    path = Path(__file__).with_name("test_boss_special_mutations.py")
    spec = importlib.util.spec_from_file_location("boss_mutation_runner", path)
    runner = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(runner)
    launches = []

    def copy_fixture(source, destination):
        for name in ("flake.nix", "flake.lock"):
            shutil.copyfile(source / name, destination / name)

    def no_native_launch(project, evidence, name):
        launches.append(evidence)
        raise NativeLaunchBlocked()

    # Keep real evidence-directory/plan writes; replace only downstream project/native work.
    runner.copy_project = copy_fixture
    runner.green = no_native_launch
    failures = []
    with tempfile.TemporaryDirectory(prefix="boss-evidence-guard-") as temporary:
        root = Path(temporary)
        source = root / "source"
        source.mkdir()
        for name in ("flake.nix", "flake.lock"):
            (source / name).write_bytes(b"fixture-only; never evaluated\n")
        for name, files in (
            ("existing-empty", {}),
            ("existing-results", {"plan.json": b"frozen-plan\n",
                                  "results.json": b"frozen-results\n",
                                  "run.log": b"frozen-log\n"}),
        ):
            verify_existing(runner, source, root, name, files, failures)
        nested = source / "forbidden-evidence"
        try:
            runner.run(source, nested, only="malformed-save")
        except AssertionError:
            pass
        else:
            failures.append("source-overlapping evidence was accepted")
        if nested.exists():
            failures.append("source-overlapping evidence was created before rejection")
        fresh = root / "fresh-results"
        try:
            runner.run(source, fresh, only="malformed-save")
        except NativeLaunchBlocked:
            pass
        else:
            failures.append("fresh evidence did not reach bounded native seam")
        if launches != [fresh] or not (fresh / "plan.json").is_file():
            failures.append("fresh-only admission/native-seam count is wrong")
    assert not failures, "\n".join(failures)
    print("Evidence guard: existing empty/nonempty roots preserved; fresh root admitted; Nix/Godot launches=0")


if __name__ == "__main__":
    run()
