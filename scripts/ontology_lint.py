"""Schedule unchanged native per-file lint in two processes; caller owns the total deadline."""

import argparse
import os
import sys
from collections import Counter
from concurrent.futures import ProcessPoolExecutor, as_completed
from multiprocessing import get_context
from pathlib import Path

import yaml
from linkml.linter.cli import get_yaml_files
from linkml.linter.formatters import TerminalFormatter
from linkml.linter.linter import Linter

ROOT = Path(__file__).resolve().parents[1]
_LINTER = None


def initialize_linter(config):
    global _LINTER
    _LINTER = Linter(config)


def lint_file(path):
    return path, os.getpid(), list(_LINTER.lint(path, fix=False))


def lint_directory(root, config_path, output=None):
    output = sys.stdout if output is None else output
    completed = set()
    paths = []
    try:
        root = Path(root).resolve(strict=True)
        paths = list(get_yaml_files(root, False))
        if not paths or len(paths) != len(set(paths)):
            raise ValueError("Empty or duplicate native YAML discovery")
        config = yaml.safe_load(Path(config_path).read_text())
        formatter = TerminalFormatter(output, verbose=True)
        counts = Counter()
        formatter.start_report()
        print(f"Native lint discovered {len(paths)} roots; workers=2", file=output, flush=True)
        with ProcessPoolExecutor(max_workers=2, mp_context=get_context("spawn"),
                                 initializer=initialize_linter, initargs=(config,)) as pool:
            pending = {}
            for path in paths:
                pending[pool.submit(lint_file, path)] = path
                print(f"Scheduled native lint: {path}", file=output, flush=True)
            for future in as_completed(pending):
                path, worker_pid, problems = future.result()
                if path != pending[future] or path in completed:
                    raise ValueError(f"Mismatched or duplicate native lint result: {path}")
                formatter.start_schema(path)
                for problem in problems:
                    counts[str(problem.level)] += 1
                    formatter.handle_problem(problem)
                formatter.end_schema()
                completed.add(path)
                print(f"Completed native lint: {path} worker_pid={worker_pid}", file=output, flush=True)
        if completed != set(paths):
            raise ValueError("Missing native lint results")
        formatter.end_report()
        return 2 if counts["error"] else int(counts["warning"] > 0)
    except Exception as error:
        print(f"Native lint incomplete ({len(completed)}/{len(paths)} roots): {error}", file=output, flush=True)
        return 2


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("schema", nargs="?", type=Path, default=ROOT / "ontology/schema")
    parser.add_argument("--config", type=Path, default=ROOT / ".linkmllint.yaml")
    args = parser.parse_args()
    return lint_directory(args.schema, args.config)


if __name__ == "__main__":
    sys.exit(main())
