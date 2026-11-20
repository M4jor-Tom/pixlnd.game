"""Source-qualified cuwo static-entity composition contracts."""
from copy import deepcopy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView

from ontology_source_contracts import assert_declared_root
from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import validator


CUWO_SOURCE = "https://github.com/matpow2/cuwo/blob/240bb61ec42abb10a73d750ce72f243e04e55509/cuwo/tgen_wrap.pxd"
CUWO_REFS = {
    "cuwo-item-with-header-components": [CUWO_SOURCE + "#L222-L235"],
    "cuwo-item-with-header-list-components": [CUWO_SOURCE + "#L234-L246"],
    "cuwo-item-with-header-lists-components": [CUWO_SOURCE + "#L247-L259"],
    "cuwo-static-entity-components": [
        "../domain/3_Classes.md#static-entity", "../instances/static-entities.json",
        CUWO_SOURCE + "#L260-L292",
    ],
}
COMPONENTS = {
    "cuwo-item-with-header-components": {
        "header": ("uint32", False, None), "item": ("item", False, None),
    },
    "cuwo-item-with-header-list-components": {
        "items": ("cuwo-item-with-header-components", True, True),
    },
    "cuwo-item-with-header-lists-components": {
        "lists": ("cuwo-item-with-header-list-components", True, True),
    },
    "cuwo-static-entity-components": {
        "header": ("cuwo-static-header-components", False, True),
        "item-with-header-lists": ("cuwo-item-with-header-lists-components", False, True),
        **{f"something{i}": ("uint32", False, None) for i in range(1, 8)},
        "item": ("item", False, None),
    },
}


def assert_static_composition(path):
    raw = yaml.safe_load(path.with_name("world.yaml").read_text())
    view = SchemaView(str(path))
    schemas = {}
    for name, fields in COMPONENTS.items():
        declaration = raw["classes"].get(name)
        assert declaration is not None, f"Missing {name}"
        assert declaration["class_uri"] == f"pixlnd:{name}"
        assert declaration["see_also"] == CUWO_REFS[name]
        assert set(declaration["attributes"]) == set(fields)
        assert not declaration.get("slots") and not declaration.get("mixins")
        for field, (range_, multiple, inline) in fields.items():
            slot = declaration["attributes"][field]
            assert slot["range"] == range_, (name, field, slot["range"])
            assert slot["required"] is True
            assert bool(slot.get("multivalued")) is multiple
            assert bool(slot.get("inlined")) is bool(inline)
            assert slot["domain"] == name
            assert slot["slot_uri"] == f"pixlnd:{name}/{field}"
            induced = view.induced_slot(field, name)
            assert (induced.range, bool(induced.required), bool(induced.multivalued), bool(induced.inlined)) == (
                range_, True, multiple, bool(inline)
            )
        schema = (validator(name).schema if path == SCHEMA else json.loads(
            JsonSchemaGenerator(str(path), top_class=name, preserve_names=True, not_closed=False).serialize()
        ))
        assert_declared_root(name, set(fields), set(fields), schema=schema, view=view)
        schemas[name] = schema
    return schemas


class StaticCompositionTests(unittest.TestCase):
    def test_metadata_and_native_roots(self):
        schemas = assert_static_composition(SCHEMA)
        for name, schema in schemas.items():
            jsonschema.Draft201909Validator.check_schema(schema)
            if "$ref" in schema:
                self.assertEqual(schema["$ref"], f"#/$defs/{name}")

    def test_component_values_and_nominal_item_references(self):
        schemas = assert_static_composition(SCHEMA)
        rows = {
            "cuwo-item-with-header-components": {"header": 0, "item": "nominal-item"},
            "cuwo-item-with-header-list-components": {"items": [{"header": 3, "item": "nominal-item"}]},
            "cuwo-item-with-header-lists-components": {"lists": [{"items": []}]},
            "cuwo-static-entity-components": {
                "header": {"entity-type": 1, "pos": [-1, 0, 1], "orientation": 3,
                            "size": [1.0, 2.0, 3.0], "closed": 1, "time-offset": 0,
                            "something8": 0, "user-id": 0},
                "item-with-header-lists": {"lists": [{"items": [{"header": 0, "item": "nominal-item"}]}]},
                **{f"something{i}": i for i in range(1, 8)},
                "item": "nominal-item",
            },
        }
        for name, row in rows.items():
            native = jsonschema.Draft201909Validator(schemas[name])
            native.validate(row)
            for field in row:
                with self.subTest(name=name, field=field), self.assertRaises(jsonschema.ValidationError):
                    native.validate({k: v for k, v in row.items() if k != field})
            with self.assertRaises(jsonschema.ValidationError):
                native.validate(dict(row, unexpected=True))
        for value in (-1, 4294967296, True, "1"):
            with self.assertRaises(jsonschema.ValidationError):
                jsonschema.Draft201909Validator(schemas["cuwo-static-entity-components"]).validate(
                    dict(rows["cuwo-static-entity-components"], something1=value)
                )

    def test_actual_yaml_mutation_rejected_by_same_metadata_oracle(self):
        assert_static_composition(SCHEMA)
        original = yaml.safe_load(SCHEMA.with_name("world.yaml").read_text())
        mutants = (("cuwo-static-entity-components", "item", "range", "string"),)
        for owner, field, facet, value in mutants:
            raw = deepcopy(original)
            raw["classes"][owner]["attributes"][field][facet] = value
            with self.subTest(owner=owner, field=field, facet=facet), tempfile.TemporaryDirectory() as directory:
                schema_dir = Path(directory) / "schema"
                shutil.copytree(SCHEMA.parent, schema_dir)
                (schema_dir / "world.yaml").write_text(yaml.safe_dump(raw, sort_keys=False))
                with self.assertRaises(AssertionError):
                    assert_static_composition(schema_dir / SCHEMA.name)


if __name__ == "__main__":
    unittest.main()
