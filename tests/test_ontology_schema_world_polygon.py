"""Canonical logical land-border polygon declaration tests."""
import shutil
import tempfile
import unittest
from pathlib import Path

import yaml
from linkml_runtime.utils.schemaview import SchemaView

from test_ontology_schema import SCHEMA


def assert_land_border_declaration(test, path):
    raw = yaml.safe_load(path.with_name("world.yaml").read_text())
    test.assertIn("polygon", raw["classes"])
    polygon = raw["classes"]["polygon"]
    test.assertEqual(polygon["class_uri"], "pixlnd:polygon")
    test.assertEqual(polygon["description"], (
        "Logical polygon geometry kind only; no vertex representation, coordinate units, "
        "identity, topology, or concrete serialization is selected."
    ))
    test.assertEqual(set(polygon), {"class_uri", "description", "see_also"})
    test.assertEqual(polygon["see_also"], ["../domain/3_Classes.md#land"])

    land = raw["classes"]["land"]
    test.assertIn("land-border", land["slots"])
    border = raw["slots"]["land-border"]
    test.assertEqual(border, {
        "slot_uri": "pixlnd:land/border",
        "alias": "border",
        "range": "polygon",
        "required": False,
        "domain": "land",
        "see_also": ["../domain/3_Classes.md#land"],
        "description": "Internal land border is a dotted map line, not a physical wall; "
                       "the outer-world travel boundary is defined separately.",
    })

    view = SchemaView(str(path))
    induced = view.induced_slot("land-border", "land")
    test.assertEqual((induced.alias, induced.range, induced.required, induced.domain),
                     ("border", "polygon", False, "land"))
    test.assertEqual(str(induced.slot_uri), "pixlnd:land/border")
    test.assertEqual(view.get_class("polygon").attributes, {})


class LandBorderPolygonTests(unittest.TestCase):
    def test_land_border_logical_declaration(self):
        assert_land_border_declaration(self, SCHEMA)

    def test_land_border_yaml_mutations_are_detected(self):
        original = SCHEMA.with_name("world.yaml").read_bytes()
        with tempfile.TemporaryDirectory(prefix="land-border-polygon-") as directory:
            target = Path(directory) / "schema"
            shutil.copytree(SCHEMA.parent, target)
            schema = target / SCHEMA.name
            module = target / "world.yaml"
            for label, mutate in (
                ("missing logical kind", lambda data: data["classes"].pop("polygon")),
                ("wrong border range", lambda data: data["slots"]["land-border"].update(range="string")),
                ("wall semantics", lambda data: data["slots"]["land-border"].update(description="A physical wall.")),
            ):
                with self.subTest(mutation=label):
                    changed = yaml.safe_load(original)
                    mutate(changed)
                    module.write_text(yaml.safe_dump(changed, sort_keys=False))
                    with self.assertRaises(AssertionError):
                        assert_land_border_declaration(self, schema)
            self.assertEqual(SCHEMA.with_name("world.yaml").read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
