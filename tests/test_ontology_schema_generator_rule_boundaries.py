"""Full-source runtime/type boundaries and real-YAML loss sensitivity."""
import json
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
from ontology_generator_expectations import (
    NUMERIC_DOMAIN_FIELDS,
    RUNTIME_FIELDS,
    RUNTIME_NONNULL_FIELDS,
    SOURCE_FIELDS,
)
from ontology_source_contracts import (
    assert_declared_root,
    bind_source,
    source_view,
    unbind_source,
)
from test_ontology_schema import copy_schema
from test_ontology_schema_authoring import catalog, validator
from test_ontology_schema_generator_declarations import declaration_oracle
from test_ontology_schema_generator_values import changed

RUNTIME_ROWS = (
    ("dash", "smash"), ("channel", "cyclone"), ("buff", "war-frenzy"),
    ("heal", "healing-stream"), ("burst", "heroic-shout"),
    ("projectile", "fire-missiles"), ("projectile", "bubbles"),
)
FRACTIONS = (80.5, 12.5, 30.5, 24.5, 8.5, 15.5, 40.5, 4.5, 100.5, 25.5, 0.5, 1.5, 1.5)


def full_case(test):
    source = catalog("generators")
    bound = bind_source("generators", source)
    test.assertEqual(unbind_source("generators", bound), source)
    native = validator("generators-source")
    assert_declared_root("generators-source", SOURCE_FIELDS, SOURCE_FIELDS,
                         schema=native.schema, view=source_view())
    native.validate(bound)
    return source, bound, native


def ability(test, bound, key):
    rows = [e for e in bound["design"]["abilities"]["entries"] if e["key"] == key]
    test.assertEqual(len(rows), 1, key)
    return rows[0]["value"]


def tiny_settlement(bound):
    fixture = deepcopy(bound)
    fixture["design"]["settlement"].update({"radius": 0.5, "blend": 0,
                                            "ring-radius": 0, "no-hostiles-within": 0.5})
    return fixture


def runtime_rule(test, data, kind):
    rows = [r for r in data["classes"]["ability-runtime"]["rules"]
            if r["preconditions"]["slot_conditions"]["ability-runtime-runtime"]["equals_string"] == kind]
    test.assertEqual(len(rows), 1, kind)
    return rows[0]


def copied_native(target):
    view = SchemaView(str(target / "pixlnd.yaml"))
    full = json.loads(JsonSchemaGenerator(str(target / "pixlnd.yaml"), top_class="generators-source",
                      preserve_names=True, not_closed=False).serialize())
    assert_declared_root("generators-source", SOURCE_FIELDS, SOURCE_FIELDS, schema=full, view=view)
    return jsonschema.Draft201909Validator(full)


class GeneratorRuleBoundaryTests(unittest.TestCase):
    def test_full_source_runtime_required_numeric_boundaries(self):
        _, bound, native = full_case(self)
        for kind, key in RUNTIME_ROWS:
            self.assertEqual(ability(self, bound, key)["runtime"], kind)
            for field in RUNTIME_FIELDS[kind]:
                fixture = deepcopy(bound)
                ability(self, fixture, key).pop(field)
                with self.subTest(kind=kind, key=key, missing=field), self.assertRaises(jsonschema.ValidationError):
                    native.validate(fixture)
                for bad in (None, True, False):
                    fixture = deepcopy(bound)
                    ability(self, fixture, key)[field] = bad
                    with self.subTest(kind=kind, key=key, field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                        native.validate(fixture)
        for key, values in (("smash", {"speed": 0, "life-s": 0}),
                            ("cyclone", {"drain-per-s": 0, "damage-mult": 0}),
                            ("heroic-shout", {"damage-mult": 0}), ("healing-stream", {"cast-s": 0})):
            fixture = deepcopy(bound)
            ability(self, fixture, key).update(values)
            native.validate(fixture)
        fixture = deepcopy(bound)
        self.assertEqual(ability(self, fixture, "shuriken-attack")["throw"]["damage-mult"], 0.6)
        del ability(self, fixture, "shuriken-attack")["throw"]["damage-mult"]
        native.validate(fixture)
        print("RUNTIME full-context:18omissions/18nulls/36Booleans;zero/scope/nested omission controls retained.")

    def test_full_source_numeric_tuning_domains(self):
        _, bound, native = full_case(self)
        self.assertEqual(len(NUMERIC_DOMAIN_FIELDS), len(FRACTIONS))
        for (_, _, field, path, lower, nonzero), fraction in zip(NUMERIC_DOMAIN_FIELDS, FRACTIONS):
            with self.subTest(fractional_positive=path, value=fraction):
                errors = [(e.validator, list(e.absolute_path), list(e.absolute_schema_path))
                          for e in native.iter_errors(changed(bound, ("design",) + path, fraction))]
                self.assertEqual(errors, [])
            for bad in (True, False, None):
                with self.subTest(numeric_type=path, value=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(changed(bound, ("design",) + path, bad))
            if lower is not None:
                with self.subTest(numeric_lower=path), self.assertRaises(jsonschema.ValidationError):
                    native.validate(changed(bound, ("design",) + path, lower - 0.5))
            if nonzero:
                with self.subTest(numeric_zero=path), self.assertRaises(jsonschema.ValidationError):
                    native.validate(changed(bound, ("design",) + path, 0))
        for label, fixture in (("tiny-coherent-geometry", tiny_settlement(bound)),
                               ("negative-ring-legal", changed(bound, ("design", "settlement", "ring-radius"), -0.5))):
            with self.subTest(positive=label):
                errors = [(e.validator, list(e.absolute_path), list(e.absolute_schema_path)) for e in native.iter_errors(fixture)]
                self.assertEqual(errors, [])
        for path, good, bad in ((('settlement', 'per-land'), 1, 1.5),
                                (('defence', 'dodge', 'stamina'), 25, 25.5)):
            native.validate(changed(bound, ("design",) + path, good))
            with self.assertRaises(jsonschema.ValidationError):
                native.validate(changed(bound, ("design",) + path, bad))
        print("NUMERIC full-context:13fractions,tiny radius.5,negative ring;typed/bound/nonzero/count controls.")

    def test_actual_yaml_runtime_wire_alias_losses(self):
        _, bound, native = full_case(self)
        declaration_oracle(self)
        for kind, key in RUNTIME_ROWS[:5]:
            first = RUNTIME_FIELDS[kind][0]
            omitted = deepcopy(bound)
            ability(self, omitted, key).pop(first)
            with self.assertRaises(jsonschema.ValidationError):
                native.validate(omitted)
            for section, field in (("preconditions", "runtime"), ("postconditions", first)):
                with self.subTest(kind=kind, section=section), tempfile.TemporaryDirectory() as scratch:
                    target = Path(scratch) / "schema"
                    copy_schema(target)
                    path = target / "design-combat.yaml"
                    before = path.read_text()
                    data = yaml.safe_load(before)
                    runtime_rule(self, data, kind)[section]["slot_conditions"]["ability-runtime-" + field].pop("alias")
                    path.write_text(yaml.safe_dump(data, sort_keys=False))
                    self.assertNotEqual(path.read_text(), before)
                    with self.assertRaises(AssertionError):
                        declaration_oracle(self, target)
                    mutant = copied_native(target)
                    if section == "preconditions":
                        mutant.validate(omitted)
                    else:
                        with self.assertRaises(jsonschema.ValidationError):
                            mutant.validate(bound)
                    print("WIRE loss SAME-oracle/native effect:", kind, section, field)

    def test_actual_yaml_runtime_nonnull_losses(self):
        _, bound, native = full_case(self)
        declaration_oracle(self)
        keys = dict(RUNTIME_ROWS)
        keys["projectile"] = "fire-missiles"
        for kind, field in sorted(RUNTIME_NONNULL_FIELDS):
            fixture = deepcopy(bound)
            ability(self, fixture, keys[kind])[field] = None
            with self.assertRaises(jsonschema.ValidationError):
                native.validate(fixture)
            with self.subTest(kind=kind, field=field), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                copy_schema(target)
                path = target / "design-combat.yaml"
                before = path.read_text()
                data = yaml.safe_load(before)
                runtime_rule(self, data, kind)["postconditions"]["slot_conditions"]["ability-runtime-" + field].pop("all_of")
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                self.assertNotEqual(path.read_text(), before)
                with self.assertRaises(AssertionError):
                    declaration_oracle(self, target)
                copied_native(target).validate(fixture)
                print("NONNULL loss SAME-oracle/native null admission:", kind, field)

    def test_actual_yaml_numeric_domain_losses(self):
        _, bound, native = full_case(self)
        declaration_oracle(self)
        cases = [(module, owner, field, "range", "integer", changed(bound, ("design",) + path, fraction))
                 for (module, owner, field, path, _, _), fraction in zip(NUMERIC_DOMAIN_FIELDS, FRACTIONS)]
        cases += [("design-items", "generator-design-settlement", "radius", "minimum_value", 1, tiny_settlement(bound)),
                  ("design-items", "generator-design-settlement", "ring-radius", "minimum_value", 0,
                   changed(bound, ("design", "settlement", "ring-radius"), -0.5))]
        self.assertEqual(len(cases), 15)
        for module, owner, field, facet, value, fixture in cases:
            native.validate(fixture)
            with self.subTest(owner=owner, field=field, facet=facet), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                copy_schema(target)
                path = target / (module + ".yaml")
                before = path.read_text()
                data = yaml.safe_load(before)
                data["classes"][owner]["attributes"][field][facet] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                self.assertNotEqual(path.read_text(), before)
                with self.assertRaises(AssertionError):
                    declaration_oracle(self, target)
                with self.assertRaises(jsonschema.ValidationError):
                    copied_native(target).validate(fixture)
                print("DOMAIN loss SAME-oracle/native fraction rejection:", owner, field, facet)


if __name__ == "__main__":
    unittest.main()
