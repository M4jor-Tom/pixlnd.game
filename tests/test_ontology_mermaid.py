"""Budget and intended core coverage of the actual generated Mermaid views."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class OntologyMermaidTests(unittest.TestCase):
    def test_generated_overview_and_core_details(self):
        directory = ROOT / "docs" / "ontology" / "mermaid"
        overview = (directory / "overview.mmd").read_text(encoding="utf-8")
        self.assertTrue(overview.strip())
        for core in ("World", "Entity", "Item", "Ability", "Generators-source"):
            with self.subTest(core=core):
                self.assertIn(f'"{core}" {{', overview.splitlines())
                detail = directory / "classes" / f"{core.lower()}.mmd"
                self.assertTrue(detail.is_file())
                self.assertTrue(detail.read_text(encoding="utf-8").strip())
        self.assertLessEqual(len(overview), 50000)


if __name__ == "__main__":
    unittest.main()
