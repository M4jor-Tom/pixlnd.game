"""Candidate schema checks; run with the pinned LinkML Python environment.

No runtime admission claim: JSON Schema does not resolve foreign keys, inverses,
compound keys, or conditional gameplay rules. Real data below is projected to
selected structural properties, never rewritten on disk.
"""

import json
from pathlib import Path
import unittest

import jsonschema
import linkml_runtime
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = ROOT / "ontology/schema/pixlnd.yaml"


def generated(class_name):
    return json.loads(JsonSchemaGenerator(
        str(SCHEMA), top_class=class_name, preserve_names=True, not_closed=False
    ).serialize())


class OntologySchemaTests(unittest.TestCase):
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
        for path in SCHEMA.parent.glob("*.yaml"):
            with self.subTest(module=path.name):
                jsonschema.validate(yaml.safe_load(path.read_text()), schema)

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
                    self.assertIn(slot.range, classes | types | enums)
                    self.assertTrue(slot.slot_uri)
                    self.assertTrue(slot.alias)
        for slot in slots.values():
            self.assertIn(slot.range, classes | types | enums)
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
