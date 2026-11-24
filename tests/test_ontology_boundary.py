"""Check the ontology's path boundary, including statically named script helpers."""
import re
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = re.compile(r'''["'](res://[^"'\n]+\.gd)["']|(?:extends\s+|(?:preload|load)\(\s*)["']([^"'\n]+\.gd)["']''')


def game_dependency(root, script):
    pending = [(script,)]
    visited = set()
    while pending:
        chain = pending.pop()
        path = chain[-1]
        if path.is_relative_to(root / "game"):
            return chain
        if path in visited:
            continue
        visited.add(path)
        for resource, relative in SCRIPT.findall(path.read_text()):
            name = resource or relative
            child = root / name[6:] if name.startswith("res://") else path.parent / name
            pending.append((*chain, child.resolve()))
    return ()


class OntologyBoundaryTests(unittest.TestCase):
    def test_no_consumer_paths(self):
        for path in sorted((ROOT / "ontology").rglob("*")):
            if path.is_file() and path.suffix in {".gd", ".md", ".yaml", ".json"}:
                with self.subTest(path=path.relative_to(ROOT)):
                    hits = [n for n, line in enumerate(path.read_text().splitlines(), 1) if "game/" in line]
                    self.assertFalse(hits, f"consumer path on lines {hits}")

    def test_no_consumer_script_dependencies(self):
        for script in sorted((ROOT / "ontology").rglob("*.gd")):
            with self.subTest(script=script.relative_to(ROOT)):
                chain = game_dependency(ROOT, script)
                self.assertFalse(chain, " -> ".join(str(p.relative_to(ROOT)) for p in chain))

    def test_indirect_helper_and_cycle(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            entry = root / "entry.gd"
            helper = root / "helper.gd"
            entry.write_text('extends "res://helper.gd"')
            helper.write_text('const Entry = preload("entry.gd")')
            self.assertEqual(game_dependency(root, entry), ())
            helper.write_text('extends "game/consumer.gd"')
            self.assertEqual(game_dependency(root, entry), (entry, helper, root / "game/consumer.gd"))
