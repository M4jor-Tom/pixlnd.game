"""Real-copy regressions for deferred metadata and fresh same-path emission."""
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import jsonschema
import test_ontology_schema_structured_world as world
import test_ontology_schema_ui_presentation as ui
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from test_ontology_schema import copy_schema


class MutationCostTests(unittest.TestCase):
    def test_same_path_branch_loss_and_restore(self):
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / world.MODULE
            original = path.read_bytes()
            data = yaml.safe_load(original)
            data["slots"]["flora-yield-entry-quantity"]["any_of"] = world.BRANCHES[1:]
            mutant = yaml.safe_dump(data, sort_keys=False).encode()
            admissions = []
            try:
                for contents in (original, mutant, original):
                    path.write_bytes(contents)
                    schema = json.loads(JsonSchemaGenerator(
                        str(target / "pixlnd.yaml"), top_class="flora",
                        preserve_names=True, not_closed=False).serialize())
                    cls = jsonschema.validators.validator_for(schema)
                    cls.check_schema(schema)
                    admissions.append(cls(schema).is_valid({"id": "x", "yields": {"apple": 1}}))
            finally:
                path.write_bytes(original)
            self.assertEqual(admissions, [True, False, True])

    def test_raw_attachment_loss_precedes_view_construction(self):
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            for module, oracle, filename, owner, slot in (
                (world, world.assert_config_contract, world.MODULE,
                 "block-cub-format", "block-cub-format-storage"),
                (ui, ui.assert_contract, "meta.yaml",
                 ui.CAMERA, ui.CAMERA + "-map"),
            ):
                path = target / filename
                original = path.read_bytes()
                with patch.object(module, "SchemaView", wraps=module.SchemaView) as factory:
                    oracle(self, target / "pixlnd.yaml")
                    self.assertEqual(factory.call_count, 1)
                    factory.reset_mock()
                    data = yaml.safe_load(original)
                    data["classes"][owner]["slots"].remove(slot)
                    try:
                        path.write_text(yaml.safe_dump(data, sort_keys=False))
                        with self.assertRaises(AssertionError):
                            oracle(self, target / "pixlnd.yaml")
                        factory.assert_not_called()
                    finally:
                        path.write_bytes(original)


if __name__ == "__main__":
    unittest.main()
