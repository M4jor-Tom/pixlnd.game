"""Native JSON Schema characterization of profile and option input flags."""

import json
import shutil
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
from ontology_source_contracts import bind_source
from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import catalog
from test_ontology_schema_meta_inputs import (
    assert_android_profile_contract,
    assert_ui_option_contract,
)

CASES = (
    ("controller-profiles", "controller-profiles-source", "catalog-meta.yaml",
     ("classes", "controller-profile-source-entry", "attributes", "key", "required"),
     False, assert_android_profile_contract),
    ("controller-profiles", "controller-profiles-source", "catalog-meta.yaml",
     ("classes", "controller-profile-source-entry", "attributes", "value", "inlined"),
     False, assert_android_profile_contract),
    ("ui", "ui-source", "catalog-meta.yaml",
     ("classes", "ui-source-option-entry", "attributes", "key", "required"),
     False, assert_ui_option_contract),
    ("ui", "ui-source", "catalog-meta.yaml",
     ("classes", "ui-source-option-entry", "attributes", "value", "inlined"),
     False, assert_ui_option_contract),
    ("ui", "ui-source", "catalog-meta.yaml",
     ("classes", "ui-source-options", "attributes", "entries", "inlined"),
     False, assert_ui_option_contract),
)


def generated(schema_path, root_class):
    return json.loads(JsonSchemaGenerator(
        str(schema_path), top_class=root_class, preserve_names=True, not_closed=False
    ).serialize())


def mutate_yaml(path, parts, value):
    with open(path, encoding="utf-8") as source_file:
        document = yaml.safe_load(source_file)
    node = document
    for part in parts[:-1]:
        node = node[part]
    node[parts[-1]] = value
    with open(path, "w", encoding="utf-8") as target_file:
        yaml.safe_dump(document, target_file, sort_keys=False)


def source_witnesses(source_name, bound):
    missing_key = deepcopy(bound)
    missing_entry = missing_key["entries"][0] if source_name == "controller-profiles" \
        else missing_key["options"]["entries"][0]
    del missing_entry["key"]
    scalar_value = deepcopy(bound)
    scalar_entry = scalar_value["entries"][0] if source_name == "controller-profiles" \
        else scalar_value["options"]["entries"][0]
    scalar_entry["value"] = "not-an-object"
    return missing_key, scalar_value


class Task5NativeFlags(unittest.TestCase):
    def test_actual_yaml_native_schema_mutations_for_profile_and_option_records(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            baseline_dir = root / "baseline"
            shutil.copytree(SCHEMA.parent, baseline_dir)
            baseline_schemas = {}
            payloads = {}
            witnesses = {}
            for source_name, root_class in (("controller-profiles", "controller-profiles-source"),
                                            ("ui", "ui-source")):
                view = SchemaView(str(baseline_dir / "pixlnd.yaml"))
                if source_name == "controller-profiles":
                    assert_android_profile_contract(self, view, baseline_dir / "meta.yaml")
                else:
                    assert_ui_option_contract(self, view)
                payload = bind_source(source_name, catalog(source_name))
                schema = generated(baseline_dir / "pixlnd.yaml", root_class)
                jsonschema.validate(payload, schema)
                missing_key, scalar_value = source_witnesses(source_name, payload)
                for witness in (missing_key, scalar_value):
                    with self.assertRaises(jsonschema.ValidationError):
                        jsonschema.validate(witness, schema)
                baseline_schemas[source_name] = schema
                payloads[source_name] = payload
                witnesses[source_name] = (missing_key, scalar_value)

            for index, (source_name, root_class, module, parts, value, oracle) in enumerate(CASES):
                candidate_dir = root / f"candidate-{index}"
                shutil.copytree(SCHEMA.parent, candidate_dir)
                baseline_view = SchemaView(str(baseline_dir / "pixlnd.yaml"))
                if oracle is assert_android_profile_contract:
                    oracle(self, baseline_view, baseline_dir / "meta.yaml")
                else:
                    oracle(self, baseline_view)
                mutate_yaml(candidate_dir / module, parts, value)
                candidate_view = SchemaView(str(candidate_dir / "pixlnd.yaml"))
                with self.subTest(module=module, path=parts, mutated=True):
                    with self.assertRaises(AssertionError):
                        if oracle is assert_android_profile_contract:
                            oracle(self, candidate_view, candidate_dir / "meta.yaml")
                        else:
                            oracle(self, candidate_view)
                candidate_schema = generated(candidate_dir / "pixlnd.yaml", root_class)
                self.assertEqual(candidate_schema, baseline_schemas[source_name])
                jsonschema.validate(payloads[source_name], candidate_schema)
                for witness in witnesses[source_name]:
                    with self.assertRaises(jsonschema.ValidationError):
                        jsonschema.validate(witness, candidate_schema)


if __name__ == "__main__":
    unittest.main()
