"""Immutable validation reuse must not replace native selected-root proofs."""

import json
import tempfile
import unittest
from copy import deepcopy
from functools import lru_cache
from pathlib import Path
from unittest.mock import patch

import jsonschema
import test_ontology_schema_authoring as authoring
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from ontology_source_contracts import assert_declared_root
from test_ontology_schema import (
    ROOT,
    SCHEMA,
    _generate_baseline,
    generated,
    validate_modules,
)
from test_ontology_schema_authoring import validate, validator


class GateBaselineTests(unittest.TestCase):
    def test_metamodel_checked_once_with_module_subtests(self):
        schema = {"type": "object", "required": ["name"],
                  "properties": {"name": {"type": "string"}}}
        cls = jsonschema.validators.validator_for(schema)
        with tempfile.TemporaryDirectory() as tmp:
            paths = [Path(tmp) / name for name in ("valid.yaml", "invalid.yaml")]
            paths[0].write_text("name: valid\n")
            paths[1].write_text("name: 17\n")

            class Batch(unittest.TestCase):
                def runTest(self):
                    validate_modules(self, paths, schema)

            result = unittest.TestResult()
            with patch.object(cls, "check_schema", wraps=cls.check_schema) as check:
                Batch().run(result)
            self.assertEqual(result.testsRun, 1)
            self.assertEqual(result.failures, [])
            self.assertEqual(len(result.errors), 1)
            subtest, error = result.errors[0]
            self.assertEqual(subtest.params["module"], "invalid.yaml")
            self.assertIn("ValidationError", error)
            self.assertEqual(check.call_count, 1)

            with patch.object(cls, "check_schema", wraps=cls.check_schema) as old_check:
                for path in paths:
                    try:
                        jsonschema.validate(yaml.safe_load(path.read_text()), schema)
                    except jsonschema.ValidationError:
                        pass
            self.assertEqual(old_check.call_count, 2)

    def test_definition_batch_checks_baseline_once(self):
        fresh = lru_cache(maxsize=1)(authoring._validated_definitions.__wrapped__)
        cls = jsonschema.Draft201909Validator
        with (patch.object(authoring, "_validated_definitions", fresh),
              patch.object(authoring, "_generate_baseline", wraps=_generate_baseline) as emit,
              patch.object(cls, "check_schema", wraps=cls.check_schema) as check):
            validate("appearance", {"id": "first"})
            validate("appearance", {"id": "second"})
            with self.assertRaises(jsonschema.ValidationError):
                validate("appearance", {})
        self.assertEqual(emit.call_count, 1)
        self.assertEqual(check.call_count, 1)

    def test_native_roots_and_definition_admission(self):
        entity = {"id": "mob-a", "hostility": "hostile", "species": "collie", "level": 1,
                  "xp": 0, "power-base": 0, "appearance": {"id": "appearance-a"},
                  "mana-cubes": 0, "skills": [0] * 11}
        save = json.loads((ROOT / "tests/fixtures/ontology-schema/current-save.json").read_text())
        generators = json.loads((ROOT / "game/generated/instances/generators.json").read_text())
        for name, good, missing in (("entity", entity, "skills"), ("save-data", save, "world"),
                                    ("generators-source", generators, "design"),
                                    ("entity", entity, "skills")):
            with self.subTest(root=name):
                native = json.loads(JsonSchemaGenerator(
                    str(SCHEMA), top_class=name, preserve_names=True, not_closed=False
                ).serialize())
                self.assertEqual(_generate_baseline(name), native)
                self.assertEqual(generated(name), native)
                self.assertEqual(validator(name).schema, native)
                direct = jsonschema.Draft201909Validator(native)
                bad = deepcopy(good)
                del bad[missing]
                for row, admitted in ((good, True), (bad, False), (dict(good, unexpected=True), False)):
                    self.assertEqual(direct.is_valid(row), admitted)
                    with patch("test_ontology_schema_authoring.validator",
                               side_effect=AssertionError("admission used an inspected root")):
                        if admitted:
                            validate(name, row)
                        else:
                            with self.assertRaises(jsonschema.ValidationError):
                                validate(name, row)

    def test_repeated_native_validator_checks_once(self):
        cls = jsonschema.Draft201909Validator
        with (patch("test_ontology_schema._generate_baseline",
                    new=lambda name: {"type": "object"}),
              patch.object(cls, "check_schema", wraps=cls.check_schema) as check):
            document = generated("repeated-validator-regression")
            self.assertEqual(check.call_count, 0)
            first = validator("repeated-validator-regression")
            second = validator("repeated-validator-regression")
            self.assertIs(first.schema, document)
            self.assertIs(second.schema, document)
            self.assertEqual(check.call_count, 1)
            self.assertIs(second, first)

    def test_failed_native_schema_check_is_not_cached(self):
        cls = jsonschema.Draft201909Validator
        document = {"type": 17}
        with (patch("test_ontology_schema._generate_baseline", new=lambda name: document),
              patch.object(cls, "check_schema", wraps=cls.check_schema) as check):
            generated("failed-validator-regression")
            self.assertEqual(check.call_count, 0)
            for attempt in range(2):
                with self.subTest(attempt=attempt), self.assertRaises(jsonschema.SchemaError):
                    validator("failed-validator-regression")
            self.assertEqual(check.call_count, 2)
            document["type"] = "object"
            first = validator("failed-validator-regression")
            self.assertIs(validator("failed-validator-regression"), first)
            self.assertEqual(check.call_count, 3)

    def test_unknown_definition_fails_closed(self):
        with self.assertRaises(ValueError):
            validate("not-a-declared-class", {})
        with self.assertRaises(AssertionError):
            assert_declared_root("not-a-declared-class", set(), set())

    def test_supplied_schemas_always_checked_and_root_required_guarded(self):
        validate("save-data", json.loads(
            (ROOT / "tests/fixtures/ontology-schema/current-save.json").read_text()))
        original = deepcopy(generated("save-data"))
        fields = {"version", "world", "character"}
        bad = deepcopy(original)
        bad["required"] = []
        with self.assertRaises(AssertionError):
            assert_declared_root("save-data", fields, fields, schema=bad)
        bad = deepcopy(original)
        bad["$defs"]["save-data"]["properties"]["version"]["type"] = 17
        with self.assertRaises(jsonschema.SchemaError):
            assert_declared_root("save-data", fields, fields, schema=bad)
        self.assertEqual(generated("save-data"), original)
        assert_declared_root("save-data", fields, fields, schema=original)
        validate("save-data", json.loads(
            (ROOT / "tests/fixtures/ontology-schema/current-save.json").read_text()))

    def test_unrelated_generator_options_do_not_leak(self):
        _generate_baseline("entity")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "unrelated.yaml"
            path.write_text("id: https://example.org/unrelated\nname: unrelated\n"
                            "classes:\n  unrelated: {}\n")
            JsonSchemaGenerator(str(path), preserve_names=False, use_curies=True).serialize()
            candidate = _generate_baseline("save-data")
        native = json.loads(JsonSchemaGenerator(
            str(SCHEMA), top_class="save-data", preserve_names=True, not_closed=False
        ).serialize())
        self.assertEqual(candidate, native)


if __name__ == "__main__":
    unittest.main()
