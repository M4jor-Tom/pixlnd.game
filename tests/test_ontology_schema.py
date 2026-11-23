"""Candidate schema checks; run with the pinned LinkML Python environment.

No runtime admission claim: JSON Schema does not resolve foreign keys, inverses,
compound keys, or conditional gameplay rules. Real data below is projected to
selected structural properties, never rewritten on disk.
"""

import json
import shutil
import unittest
from copy import deepcopy
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

import jsonschema
import linkml_runtime
import yaml
from linkml.generators.jsonschemagen import JsonSchema, JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = ROOT / "ontology/schema/pixlnd.yaml"


def load_module(path):
    """A schema module as one document: the parts it imports (ids nested under its own id) are
    merged back and dropped from its imports. A module without parts loads unchanged."""
    path = Path(path)
    data = yaml.safe_load(path.read_text())
    for name in list(data.get("imports", [])):
        part_path = path.with_name(name + ".yaml")
        part = yaml.safe_load(part_path.read_text()) if part_path.exists() else {}
        if part.get("id", "").startswith(data["id"] + "/"):
            data["imports"].remove(name)
            for section in ("classes", "slots", "enums", "types"):
                if section in part:
                    data.setdefault(section, {}).update(part[section])
    return data


@lru_cache(maxsize=None)
def _merged_modules():
    merged = {}
    for path in SCHEMA.parent.glob("*.yaml"):
        data = load_module(path)
        if data != yaml.safe_load(path.read_text()):
            merged[path.name] = yaml.safe_dump(data, sort_keys=False)
    return merged


def copy_schema(target, **kwargs):
    """Copy the schema directory for a mutation test, each split module rewritten as the single
    document `load_module` returns, so it can be edited by module name. Part files are copied
    too but no longer imported; restoring a module's original bytes re-links them."""
    shutil.copytree(SCHEMA.parent, target, **kwargs)
    for name, text in _merged_modules().items():
        (Path(target) / name).write_text(text)


_BASELINE_GENERATOR = None


def _generate_baseline(class_name=None):
    # Only immutable repository YAML and these fixed options may use this generator.
    # LinkML resets emission state in start_schema, but naming flags are process-wide.
    global _BASELINE_GENERATOR
    if (_BASELINE_GENERATOR is None
            or (JsonSchema.PRESERVE_NAMES, JsonSchema.USE_CURIES) != (True, False)):
        _BASELINE_GENERATOR = JsonSchemaGenerator(
            str(SCHEMA), preserve_names=True, not_closed=False
        )
    _BASELINE_GENERATOR.top_class = class_name
    return json.loads(_BASELINE_GENERATOR.serialize())


@dataclass
class _NativeSchema:
    schema: dict
    checked_validator: jsonschema.Draft201909Validator | None = None


@lru_cache(maxsize=4)
def _native_schema(class_name):
    return _NativeSchema(_generate_baseline(class_name))


def generated(class_name):
    return _native_schema(class_name).schema


def validate_modules(test, paths, schema):
    cls = jsonschema.validators.validator_for(schema)
    cls.check_schema(schema)
    validator = cls(schema)
    for path in paths:
        with test.subTest(module=path.name):
            validator.validate(yaml.safe_load(path.read_text()))


def assert_ranges(test, slot, known, enclosing_range=None):
    # Unions may omit range; predicate-only operands constrain the enclosing type.
    branches = slot.any_of + slot.exactly_one_of + slot.all_of + slot.none_of
    effective_range = slot.range or enclosing_range
    test.assertTrue(effective_range or branches)
    if slot.range:
        test.assertIn(slot.range, known)
    for expression in branches:
        assert_ranges(test, expression, known, effective_range)


class OntologySchemaTests(unittest.TestCase):
    def test_aggregate_default_aligns_imported_boolean_ranges(self):
        view = SchemaView(str(SCHEMA))
        district_buildings = view.induced_slot("buildings", "district-source-row")
        self.assertEqual((view.schema.default_range, district_buildings.range), ("string", "string"))
        structured_view = SchemaView(str(SCHEMA.parent / "structured-world.yaml"))
        self.assertEqual(structured_view.schema.default_range, "string")

    def verify_required(self, owner, required, slots, aliases, definition, full, view):
        self.assertEqual(len(definition["required"]), len(set(definition["required"])))
        self.assertTrue(required <= set(definition["required"]))
        from ontology_source_contracts import assert_declared_root

        induced_required = {slot.alias or slot.name for slot in slots
                            if slot.required or slot.key or slot.identifier or str(slot.value_presence) == "PRESENT"}
        assert_declared_root(owner, set(aliases), induced_required, schema=full, view=view)

    def verify_refinements(self, owner, required, slots, by_alias, aliases, definition, full, view):
        self.assertEqual(view.get_class(owner).is_a, "entity")
        for alias in required:
            self.assertTrue(by_alias[alias].required, alias)
        self.assertEqual(by_alias["level"].range, "integer")
        self.assertEqual(by_alias["xp"].range, "integer")
        self.assertEqual(by_alias["appearance"].range, "appearance")
        self.assertTrue(by_alias["appearance"].inlined)
        self.assertEqual(by_alias["skills"].range, "uint32")
        self.assertTrue(by_alias["skills"].multivalued)
        self.assertEqual((by_alias["skills"].minimum_cardinality, by_alias["skills"].maximum_cardinality), (11, 11))
        if owner == "player-character":
            self.verify_player_character_refinements(slots, by_alias, aliases, definition, full, view)
        else:
            self.assertEqual(by_alias["species"].range, "creature")
            self.assertEqual(by_alias["cage"].range, "item")

    def verify_player_character_refinements(self, slots, by_alias, aliases, definition, full, view):
        self.assertEqual(by_alias["name"].pattern, r"^[\x20-\x7e]{2,16}$")
        self.assertEqual(by_alias["class"].range, "character-class")
        for alias, inherited, detached, target in (
            ("race", "entity-species", "player-character-race", "race"),
            ("spec", "entity-specialization", "player-character-spec", "specialization"),
        ):
            self.assertEqual([slot.name for slot in slots if slot.name in (inherited, detached)], [inherited])
            self.assertEqual((by_alias[alias].name, by_alias[alias].range), (inherited, target))
            self.assertTrue(view.get_slot(detached).required)
            self.assertEqual(view.get_slot(detached).range, target)
            self.assertIn(alias, definition["properties"])
        self.assertEqual(by_alias["inventory"].range, "inventory")
        for redundant in ("species", "specialization"):
            self.assertNotIn(redundant, aliases)
            self.assertNotIn(redundant, definition["properties"])
        self.assertIs(definition["additionalProperties"], False)
        # Isolate closed-property rejection from the fixture's missing required fields.
        native = jsonschema.Draft201909Validator(full)
        for supplied, rejected in (({"race": "human", "spec": "guardian"}, False),
                                   ({"species": "human"}, True),
                                   ({"specialization": "guardian"}, True)):
            with self.subTest(supplied=supplied):
                self.assertEqual(any(error.validator == "additionalProperties"
                                     for error in native.iter_errors(supplied)), rejected)

    def test_inherited_entity_aliases_and_roots(self):
        view = SchemaView(str(SCHEMA))
        for owner, species_range in (("entity", "race-or-creature"), ("pet", "creature")):
            species = view.induced_slot("entity-species", owner)
            spec = view.induced_slot("entity-specialization", owner)
            self.assertEqual((species.alias, species.range, species.required), ("species", species_range, True))
            self.assertEqual((spec.alias, spec.range), ("specialization", "specialization"))
            self.assertFalse(spec.required)
        expected_required = {
            "player-character": {"id", "appearance", "race", "gender", "class", "spec", "name", "level", "xp", "coins", "inventory", "skills", "artifacts"},
            "pet": {"id", "species", "name", "cage", "level", "xp"},
        }
        for owner, required in expected_required.items():
            slots = view.class_induced_slots(owner)
            aliases = [slot.alias or slot.name for slot in slots]
            with self.subTest(owner=owner, facet="induced aliases"):
                self.assertEqual(len(aliases), len(set(aliases)))
            full = generated(owner)
            definition = full["$defs"][owner]
            with self.subTest(owner=owner, facet="native schema"):
                jsonschema.Draft201909Validator.check_schema(full)
            with self.subTest(owner=owner, facet="required"):
                self.verify_required(owner, required, slots, aliases, definition, full, view)
            by_alias = {slot.alias or slot.name: slot for slot in slots}
            with self.subTest(owner=owner, facet="refinements"):
                self.verify_refinements(owner, required, slots, by_alias, aliases, definition, full, view)

    def test_union_range_checker_rejects_untyped_and_unknown_branches(self):
        view = SchemaView(str(SCHEMA))
        known = view.all_classes() | view.all_types() | view.all_enums()
        slot = view.get_slot("resource-cost-amount")
        assert_ranges(self, slot, known)
        for value in (None, "not-a-defined-range"):
            bad = deepcopy(slot)
            bad.any_of[0].range = value
            with self.subTest(range=value), self.assertRaises(AssertionError):
                assert_ranges(self, bad, known)

    def test_boolean_branch_ranges_and_dynamic_values(self):
        from linkml_runtime.linkml_model.meta import SlotDefinition

        view = SchemaView(str(SCHEMA))
        known = view.all_classes() | view.all_types() | view.all_enums()
        for operator in ("any_of", "exactly_one_of", "all_of", "none_of"):
            slot = SlotDefinition(name="probe", **{operator: [{"range": "integer"}]})
            assert_ranges(self, slot, known)
            for value in (None, "not-a-defined-range"):
                bad = deepcopy(slot)
                getattr(bad, operator)[0].range = value
                with self.subTest(operator=operator, value=value), self.assertRaises(AssertionError):
                    assert_ranges(self, bad, known)
        for owner in view.all_classes().values():
            if owner.extra_slots and owner.extra_slots.range_expression:
                assert_ranges(self, owner.extra_slots.range_expression, known)

    def test_boolean_predicates_use_enclosing_range(self):
        from linkml_runtime.linkml_model.meta import SlotDefinition

        for operator in ("any_of", "exactly_one_of", "all_of", "none_of"):
            slot = SlotDefinition(name="probe", range="double",
                                  **{operator: [{"equals_number": 0}]})
            with self.subTest(operator=operator):
                assert_ranges(self, slot, {"double"})
                untyped = deepcopy(slot)
                untyped.range = None
                with self.assertRaises(AssertionError):
                    assert_ranges(self, untyped, {"double"})
                unknown = deepcopy(slot)
                getattr(unknown, operator)[0].range = "not-a-defined-range"
                with self.assertRaises(AssertionError):
                    assert_ranges(self, unknown, {"double"})
        nested = SlotDefinition(name="probe", range="double",
                                all_of=[{"none_of": [{"equals_number": 0}]}])
        assert_ranges(self, nested, {"double"})

    def test_actual_species_yaml_mutation_uses_same_oracle(self):
        import tempfile
        from unittest.mock import patch

        self.test_entity_species_reference()
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "entities.yaml"
            data = yaml.safe_load(path.read_text())
            data["slots"]["entity-species"]["range"] = "string"
            path.write_text(yaml.safe_dump(data, sort_keys=False))
            mutated_view = SchemaView(str(target / "pixlnd.yaml"))
            with patch("test_ontology_schema.SchemaView", return_value=mutated_view):
                with self.assertRaises(AssertionError):
                    self.test_entity_species_reference()
            mutated = json.loads(JsonSchemaGenerator(
                str(target / "pixlnd.yaml"), top_class="entity", preserve_names=True,
                not_closed=False).serialize())
            # FK target typing disappears while native scalar shape can remain unchanged.
            jsonschema.validate("not-a-defined-species",
                                mutated["$defs"]["entity"]["properties"]["species"])

    def test_entity_species_reference(self):
        view = SchemaView(str(SCHEMA))
        self.assertIn("entity-species", view.class_slots("entity"))
        slot = view.induced_slot("entity-species", "entity")
        self.assertEqual(slot.alias, "species")
        self.assertEqual(slot.slot_uri, "pixlnd:entity/species")
        self.assertIn("../domain/3_Classes.md#entity", slot.see_also)
        self.assertTrue(slot.required)
        self.assertFalse(slot.multivalued)
        self.assertFalse(slot.inlined)
        self.assertIn(slot.range, view.all_classes())
        self.assertEqual(view.get_class(slot.range).union_of, ["race", "creature"])
        full = generated("entity")
        definition = full["$defs"]["entity"]
        fragment = {"$defs": full["$defs"], "type": "object",
                    "properties": {"species": definition["properties"]["species"]},
                    "required": ["species"] if "species" in definition["required"] else []}
        for identifier in ("human", "collie"):
            jsonschema.validate({"species": identifier}, fragment)
        for value in (None, 19, ["human"], {"id": "human"}):
            with self.subTest(value=value), self.assertRaises(jsonschema.ValidationError):
                jsonschema.validate({"species": value}, fragment)
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.validate({}, fragment)
        # Scalar shape is not proof of target membership or foreign-key existence.
        jsonschema.validate({"species": "not-a-defined-species"}, fragment)

    def test_selected_descriptions_exclude_source_attribution(self):
        view = SchemaView(str(SCHEMA))
        # Exact reviewed attribution fragments, not a ban on legitimate stable names.
        for name, attribution in [
            ("owned-by-realm", "Cardinality n→1. S"),
            ("reveals", "Cardinality 1→n. S"),
            ("bound-to-land", "Cardinality n→1. S"),
            ("works-in-adjacent", "Cardinality n→n. S"),
            ("in-district", "Cardinality n→1. A"),
            ("possesses", "Cardinality 1→n. S"),
            ("petrifies", "Cardinality 1→1. S"),
            ("scales-with", "Cardinality 1→2. S"),
            ("mounts", "A skill-only / S land Reins are reference"),
            ("unlocks-next", "alpha tree"),
            ("grants-ability", "versioned"),
            ("sells", "versioned"),
            ("bound-to-input", "versioned ability identity"),
            ("settlement-petrified", "Historical curse state"),
            ("settlement-possessed", "Historical curse state"),
        ]:
            with self.subTest(slot=name):
                slot = view.get_slot(name)
                self.assertNotIn(attribution, slot.description)
                self.assertTrue(slot.see_also)
        self.assertEqual(view.get_slot("ability-alpha-ability-id").alias, "alpha-ability-id")
        self.assertEqual(view.get_slot("creature-alpha-entity-id").alias, "aid")

    def test_linkml_metamodel(self):
        metamodel = Path(linkml_runtime.__file__).parent / "linkml_model/jsonschema/meta.schema.json"
        schema = json.loads(metamodel.read_text())
        validate_modules(self, SCHEMA.parent.glob("*.yaml"), schema)

    def test_exact_count_boundaries(self):
        # Literal oracles from §3, not a second field/type registry.
        for class_name, key, values, count in [
            ("character-class", "specializations", ["berserker", "guardian"], 2),
            ("entity", "skills", [0] * 11, 11),
            ("player-character", "skills", [0] * 11, 11),
            ("block", "rgb", [20, 30, 40], 3),
            ("land", "coords", [0, 1], 2),
            ("land", "settlements", ["village"], 1),
            ("creature", "group", [3, 5], 2),
        ]:
            full = generated(class_name)
            definition = full["$defs"][class_name]
            fragment = {"$schema": full["$schema"], "$defs": full["$defs"],
                        "type": "object", "properties": {key: definition["properties"][key]},
                        "required": [key] if key in definition["required"] else []}
            with self.subTest(class_name=class_name, key=key):
                self.assertEqual(len(values), count)
                jsonschema.validate({key: values}, fragment)
                for bad in (values[:-1], values + [values[0]]):
                    with self.assertRaises(jsonschema.ValidationError):
                        jsonschema.validate({key: bad}, fragment)
                with self.assertRaises(jsonschema.ValidationError):
                    jsonschema.validate({}, fragment)

    def test_imports_ranges_aliases_and_compound_keys(self):
        view = SchemaView(str(SCHEMA))
        classes, slots, types, enums = (
            view.all_classes(), view.all_slots(), view.all_types(), view.all_enums()
        )
        for name in classes:
            for slot in view.class_induced_slots(name):
                with self.subTest(class_name=name, slot=slot.name):
                    assert_ranges(self, slot, classes | types | enums)
                    self.assertTrue(slot.slot_uri)
                    self.assertTrue(slot.alias)
        for slot in slots.values():
            assert_ranges(self, slot, classes | types | enums)
            if slot.domain:
                self.assertIn(slot.domain, classes)
        self.assertEqual(view.induced_slot("member-of-family", "creature").range,
                         "creature-family")
        self.assertEqual(view.induced_slot("member-of-family", "creature").alias, "family")
        self.assertEqual(view.induced_slot("tamed-by", "creature").range, "pet-food")
        self.assertEqual(classes["specialization"].unique_keys["class-index"].unique_key_slots,
                         ["specialization-class", "specialization-index"])
        self.assertEqual(classes["threat-pair"].unique_keys["mob-player"].unique_key_slots,
                         ["threat-mob", "threat-player"])
        self.assertEqual(slots["current-target"].range, "player-character")
        self.assertEqual(slots["has-specialization"].minimum_cardinality, 2)
        self.assertEqual(slots["has-specialization"].maximum_cardinality, 2)
        self.assertEqual(slots["equips"].maximum_cardinality, 12)
        self.assertEqual(slots["threat"].range, "player-character")
        self.assertTrue(slots["descriptive-member-of-family"].list_elements_unique)
        self.assertEqual(classes["creature"].class_uri, "pixlnd:creature")
        self.assertEqual(slots["member-of-family"].slot_uri, "pixlnd:member-of-family")
        self.assertEqual(classes[slots["produces"].range].union_of, ["item-type", "consumable"])
        self.assertEqual(classes[slots["grants-ability"].domain].union_of,
                         ["specialization", "character-class"])
        for name, definition in classes.items():
            for target in definition.union_of:
                self.assertIn(target, classes, (name, target))
            for key in definition.unique_keys.values():
                for slot_name in key.unique_key_slots:
                    self.assertIn(slot_name, view.class_slots(name), (name, slot_name))

    def test_real_identity_projections_and_negative_controls(self):
        classes = json.loads((ROOT / "ontology/instances/classes.json").read_text())
        schema = generated("character-class")
        jsonschema.Draft201909Validator.check_schema(schema)
        fields = ("name", "id-number", "weapon-types", "armor-material",
                  "special-attack-mode", "hp-mult", "specializations")
        for identifier in ("warrior", "ranger", "mage", "rogue"):
            row = {key: classes[identifier][key] for key in fields}
            row["id"] = identifier
            jsonschema.validate(row, schema)
        row = {key: classes["warrior"][key] for key in fields}
        row["id"] = "warrior"
        mutations = [("name", None), ("id-number", True), ("id-number", 5),
                     ("special-attack-mode", "unknown"), ("special-attack-mode", 99),
                     ("specializations", ["berserker"]), ("specializations", "berserker")]
        for key, value in mutations:
            bad = dict(row)
            bad[key] = value
            with self.subTest(key=key, value=value), self.assertRaises(jsonschema.ValidationError):
                jsonschema.validate(bad, schema)
        for key in fields:
            bad = dict(row)
            del bad[key]
            with self.subTest(missing=key), self.assertRaises(jsonschema.ValidationError):
                jsonschema.validate(bad, schema)

    def test_real_specializations_and_landscape_configuration(self):
        data = json.loads((ROOT / "ontology/instances/specializations.json").read_text())
        schema = generated("specialization")
        for identifier, row in data.items():
            if not identifier.startswith(("_", "$")):
                projection = {key: row[key] for key in ("name", "class", "index")}
                projection["id"] = identifier
                jsonschema.validate(projection, schema)
        data = json.loads((ROOT / "ontology/instances/landscapes.json").read_text())
        schema = generated("landscape-generation")
        for row in data.values():
            if isinstance(row, dict) and "gen" in row:
                jsonschema.validate(row["gen"], schema)
        bad = dict(data["greenlands"]["gen"])
        bad["top"] = "not-rgb"
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.validate(bad, schema)

    def test_threat_association_numeric_contract(self):
        schema = generated("threat-pair")
        row = {"mob": "mob-a", "player": "player-you", "aggro-points": 20}
        jsonschema.validate(row, schema)
        for value in (-1, True, "20", None):
            bad = dict(row, **{"aggro-points": value})
            with self.subTest(value=value), self.assertRaises(jsonschema.ValidationError):
                jsonschema.validate(bad, schema)
        del row["aggro-points"]
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.validate(row, schema)

    def test_optional_nullable_source_id_and_typed_references(self):
        schema = generated("creature")
        # This species-only projection excludes unresolved prose-shaped fields.
        creatures = json.loads((ROOT / "ontology/instances/creatures.json").read_text())
        row = {"id": "collie"}
        # A bounded property projection of the actual generated class schema,
        # not a hand-maintained field/type registry or a full creature admission.
        properties = schema["$defs"]["creature"]["properties"]
        fragment = {"$schema": schema["$schema"], "$defs": schema["$defs"],
                    "type": "object", "properties": properties}
        for value in (creatures["collie"]["aid"], None):
            row["aid"] = value
            jsonschema.validate(row, fragment)
        del row["aid"]
        jsonschema.validate(row, fragment)
        row["aid"] = "not-an-integer"
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.validate(row, fragment)
        # Native JSON Schema checks scalar shape, NOT reference existence/target.
        row = {"family": "warrior"}
        jsonschema.validate(row, fragment)
        view = SchemaView(str(SCHEMA))
        self.assertEqual(view.induced_slot("member-of-family", "creature").range,
                         "creature-family")


if __name__ == "__main__":
    unittest.main()
