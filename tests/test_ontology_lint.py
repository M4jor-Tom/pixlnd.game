"""Native per-physical-root lint equivalence and fail-closed scheduling."""

import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path
from unittest.mock import patch

import yaml
from linkml.linter.cli import get_yaml_files
from linkml.linter.formatters import TerminalFormatter
from linkml.linter.linter import Linter

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import ontology_lint  # noqa: E402


def write_schema(root, name, **updates):
    schema = {
        "id": "https://example.org/" + name, "name": name,
        "description": "Native lint scheduling fixture.",
        "prefixes": {"fixture": "https://example.org/fixture/", "linkml": "https://w3id.org/linkml/"},
        "default_prefix": "fixture", "default_range": "string", "imports": ["linkml:types"],
        "classes": {"fixture-row": {"description": "Fixture row.", "class_uri": "fixture:row",
                                    "attributes": {"value": {"description": "Value.", "slot_uri": "fixture:value", "range": "string"}}}},
    }
    schema.update(updates)
    path = root / (name + ".yaml")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump(schema, sort_keys=False))
    return path


def worker_exception(path):
    raise RuntimeError("fixture worker exception")


def worker_crash(path):
    os._exit(17)


def worker_mismatch(path):
    return path + ".wrong", os.getpid(), []


class OntologyLintTests(unittest.TestCase):
    def run_driver(self, root):
        records = []

        class RecordingFormatter(TerminalFormatter):
            def handle_problem(self, problem):
                records.append((str(Path(self.current_schema).relative_to(root)), problem.rule_name,
                                str(problem.level), problem.message))
                super().handle_problem(problem)

        output = io.StringIO()
        with patch.object(ontology_lint, "TerminalFormatter", RecordingFormatter):
            status = ontology_lint.lint_directory(root, ROOT / ".linkmllint.yaml", output)
        return status, Counter(records), output.getvalue()

    def test_native_counter_and_complete_physical_discovery(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch).resolve()
            write_schema(root, "aa-undefined", classes={"fixture-row": {"description": "Row.", "class_uri": "fixture:row",
                         "attributes": {"value": {"description": "Value.", "slot_uri": "fixture:value", "range": "missing"}}}})
            write_schema(root, "local-warning", classes={"fixture-row": {"class_uri": "fixture:row"}})
            write_schema(root, "local-pv", enums={"FixtureChoice": {"description": "Choice.", "enum_uri": "fixture:Choice",
                                                                 "permissible_values": {"bad-token": {}}}})
            write_schema(root, "malformed-root", unexpected_field=True)
            write_schema(root, "imported", classes={"fixture-row": {"description": "Row.", "class_uri": "fixture:row",
                         "attributes": {"value": {"description": "Value.", "slot_uri": "fixture:value", "range": "string", "required": "true"}}}})
            write_schema(root, "imports-malformed", imports=["linkml:types", "imported"])
            write_schema(root, "entry")  # Local warnings/PV errors are deliberately not imported.
            nested = root / ".nested"
            write_schema(nested, "nested").rename(nested / "nested.yml")
            write_schema(root, "hidden").rename(root / ".hidden.yaml")
            (root / ".linkmllint.yaml").write_text("not a schema")
            (root / ".linkmllint.yml").write_text("not a schema")
            (root / "ignored.txt").write_text("not a schema")
            paths = list(get_yaml_files(root, False))
            self.assertEqual(len(paths), 8)
            self.assertIn(str(nested / "nested.yml"), paths)
            policy = yaml.safe_load((ROOT / ".linkmllint.yaml").read_text())
            linter = Linter(policy)
            sequential = Counter((str(Path(path).relative_to(root)), problem.rule_name, str(problem.level), problem.message)
                                 for path in paths for problem in linter.lint(path, fix=False))
            with patch.object(ontology_lint, "ProcessPoolExecutor", wraps=ontology_lint.ProcessPoolExecutor) as pool:
                status, parallel, output = self.run_driver(root)
            self.assertEqual(pool.call_args.kwargs["max_workers"], 2)
            self.assertEqual(pool.call_args.kwargs["mp_context"].get_start_method(), "spawn")
            self.assertEqual(status, 2)
            self.assertEqual(parallel, sequential)
            self.assertTrue(any(row[:3] == ("local-warning.yaml", "recommended", "warning") for row in parallel))
            self.assertTrue(any(row[:3] == ("local-pv.yaml", "standard_naming", "error") for row in parallel))
            self.assertTrue(any(row[:3] == ("aa-undefined.yaml", "no_undeclared_ranges", "error") for row in parallel))
            for name in ("malformed-root.yaml", "imported.yaml", "imports-malformed.yaml"):
                self.assertTrue(any(row[0] == name and row[1] == "valid-schema" for row in parallel), name)
            completed = [line.split(" worker_pid=", 1)[0].removeprefix("Completed native lint: ")
                         for line in output.splitlines() if line.startswith("Completed native lint: ")]
            self.assertEqual(Counter(completed), Counter(paths))
            workers = {line.rsplit("worker_pid=", 1)[1] for line in output.splitlines() if line.startswith("Completed native lint: ")}
            self.assertIn(len(workers), (1, 2))
            print("NATIVE-LINT-COUNTER", json.dumps([[*row, count] for row, count in sorted(parallel.items())]))
            print("NATIVE-LINT-COMPLETED", len(completed), "workers", len(workers))

    def test_zero_diagnostics_and_warning_exit_policy(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch).resolve()
            path = write_schema(root, "clean")
            status, problems, _ = self.run_driver(root)
            self.assertEqual((status, problems), (0, Counter()))
            data = yaml.safe_load(path.read_text())
            data["classes"]["fixture-row"].pop("description")
            path.write_text(yaml.safe_dump(data, sort_keys=False))
            status, problems, _ = self.run_driver(root)
            self.assertEqual(status, 1)
            self.assertTrue(problems)
            self.assertEqual({row[2] for row in problems}, {"warning"})

    def test_missing_empty_and_duplicate_discovery_fail_closed(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch).resolve()
            for path in (root, root / "missing"):
                with self.subTest(path=path):
                    self.assertEqual(self.run_driver(path)[0], 2)
            path = write_schema(root, "clean")
            with patch.object(ontology_lint, "get_yaml_files", return_value=[str(path), str(path)]):
                self.assertEqual(self.run_driver(root)[0], 2)

    def test_worker_exception_crash_and_mismatched_result_fail_closed(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch).resolve()
            write_schema(root, "clean")
            for worker in (worker_exception, worker_crash, worker_mismatch):
                with self.subTest(worker=worker.__name__), patch.object(ontology_lint, "lint_file", worker):
                    status, _, output = self.run_driver(root)
                    self.assertEqual(status, 2)
                    self.assertIn("Native lint incomplete", output)

    def test_cli_propagates_zero_and_nonzero_status(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch).resolve()
            write_schema(root, "clean")
            command = [sys.executable, "-B", str(ROOT / "scripts/ontology_lint.py"), str(root)]
            clean = subprocess.run(command, capture_output=True, text=True, check=False)
            self.assertEqual(clean.returncode, 0, clean.stdout + clean.stderr)
            write_schema(root, "bad", unexpected_field=True)
            bad = subprocess.run(command, capture_output=True, text=True, check=False)
            self.assertEqual(bad.returncode, 2, bad.stdout + bad.stderr)
            self.assertIn("valid-schema", bad.stdout)
            self.assertEqual(bad.stdout.count("Completed native lint:"), 2)

    def test_incomplete_results_fail_closed(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch).resolve()
            write_schema(root, "clean")
            with patch.object(ontology_lint, "as_completed", return_value=iter(())):
                status, _, output = self.run_driver(root)
            self.assertEqual(status, 2)
            self.assertIn("Native lint incomplete", output)


if __name__ == "__main__":
    unittest.main()
