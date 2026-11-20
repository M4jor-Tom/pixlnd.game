"""22 source encodings, not complete catalogs or runtime relation enforcement."""
from pathlib import Path
import json
import shutil
import tempfile
import unittest

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView

from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import catalog, validate, validator


FIELDS = {
    "ingredient": [("kind", "string", False), ("from", "string", False),
                   ("sell", "integer", False), ("recipe", "string", False),
                   ("refines-to", "ingredient-refinement", True)],
    "material": [("class", "string", False), ("station", None, False),
                 ("raw", "string", False), ("alt-name", "string", False),
                 ("effect", "string", False), ("price-s", "integer", False),
                 ("sell-s", "integer", False)],
    "faction": [("alignment", "string", False), ("leader", "string", False),
                ("members", "creature", True), ("presence", "string", True)],
    "npc-role": [("building", "string", False), ("species", "race-or-creature", False),
                 ("service", "string", False), ("schedule", "string", False),
                 ("attackable", "string", False), ("behaviour", "string", False)],
}
FILES = {"ingredient": "ingredients", "material": "materials",
         "faction": "factions", "npc-role": "npc-roles"}
MODULE = "catalog-crafting-social.yaml"


def sample(range_, multiple):
    if range_ == "ingredient-refinement":
        return {"heartflower": "1-3 @campfire"}
    value = {"string": "qualified (text)", "integer": 0, None: "none",
             "creature": "paladin", "race-or-creature": "bloodaxe-orc"}[range_]
    return [value] if multiple else value


def mutated(module, name, facet, value, owner, row):
    """Regenerate from real temporary YAML, never a hand-edited emitted schema."""
    with tempfile.TemporaryDirectory() as scratch:
        target = Path(scratch) / "schema"
        shutil.copytree(SCHEMA.parent, target)
        path = target / module
        data = yaml.safe_load(path.read_text())
        data["slots"][name][facet] = value
        path.write_text(yaml.safe_dump(data, sort_keys=False))
        schema = json.loads(JsonSchemaGenerator(
            str(target / "pixlnd.yaml"), top_class=owner, preserve_names=True,
            not_closed=False).serialize())
        cls = jsonschema.validators.validator_for(schema)
        cls.check_schema(schema)
        return cls(schema).is_valid(row)


def assert_selected_facets(self, view):
    self.assertEqual(sum(map(len, FIELDS.values())), 22)
    self.assertIsNone(view.get_slot("material-station").range)
    for owner, fields in FIELDS.items():
        for field, range_, multiple in fields:
            name = owner + "-" + field
            self.assertIn(name, view.class_slots(owner))
            slot = view.induced_slot(name, owner)
            # Native induction fills the declared default; the raw union has no range.
            induced_range = "string" if name == "material-station" else range_
            self.assertEqual((slot.alias, slot.domain, slot.range), (field, owner, induced_range))
            self.assertEqual(str(slot.slot_uri), "pixlnd:" + owner + "/" + field)
            self.assertEqual(bool(slot.multivalued), multiple)
            self.assertFalse(slot.required or slot.key or slot.identifier)
            self.assertEqual(bool(slot.inlined), range_ == "ingredient-refinement")
            self.assertFalse(slot.inlined_as_list or slot.list_elements_unique)
            for facet in ("minimum_value", "maximum_value", "minimum_cardinality", "maximum_cardinality"):
                self.assertIsNone(getattr(slot, facet))
            self.assertIn("../domain/3_Classes.md#" + owner, slot.see_also)
            self.assertIn("../instances/" + FILES[owner] + ".json", slot.see_also)
    station = view.get_slot("material-station")
    self.assertEqual([(b.range, b.equals_string) for b in station.any_of],
                     [("crafting-station", None), ("string", "none")])
    self.assertEqual(view.get_class("race-or-creature").union_of, ["race", "creature"])
    self.assertEqual(view.get_slot("entity-species").range,
                     view.get_slot("npc-role-species").range)
    association = view.get_class("ingredient-refinement")
    self.assertEqual(str(association.class_uri), "pixlnd:ingredient-refinement")
    self.assertEqual(association.slots, ["ingredient-refinement-target", "ingredient-refinement-process"])
    for name, alias, range_ in [("target", "target", "ingredient"), ("process", "process", "string")]:
        slot = view.get_slot("ingredient-refinement-" + name)
        self.assertEqual((slot.alias, slot.domain, slot.range), (alias, "ingredient-refinement", range_))
        self.assertEqual(str(slot.slot_uri), "pixlnd:ingredient-refinement/" + name)
        self.assertTrue(slot.required)
        self.assertEqual(bool(slot.key), name == "target")
        self.assertFalse(slot.identifier or slot.multivalued or slot.inlined)


def verify_native_field(self, owner, field, range_, multiple):
    row = {"id": "example", field: sample(range_, multiple)}
    validate(owner, row)
    validate(owner, {"id": "example"})
    validate(owner, {"id": "example", field: None})
    if range_ == "ingredient-refinement":
        bad_values = ["saw", [], True, 1, {"wood-cube": None}, {"wood-cube": 1},
                      {"wood-cube": True}, {"wood-cube": []}, {"wood-cube": {}},
                      {"wood-cube": {"process": None}}, {"wood-cube": {"process": 1}}]
    elif multiple:
        bad_values = ["paladin", {}, 1, True, [1], [True], [None], [[]], [{}]]
    elif range_ == "integer":
        bad_values = [True, "1", 1.5, [], {}]
    else:
        bad_values = [True, 1, [], {}, {"id": "anvil"}]
    for value in bad_values:
        with self.subTest(owner=owner, field=field, value=value), self.assertRaises(jsonschema.ValidationError):
            validate(owner, {"id": "example", field: value})
    if multiple:
        validate(owner, {"id": "example", field: {} if range_ == "ingredient-refinement" else []})
    if range_ == "integer":
        for value in (-1, 1000000):
            validate(owner, {"id": "example", field: value})


class CraftingSocialTests(unittest.TestCase):
    def test_selected_facets(self):
        assert_selected_facets(self, SchemaView(str(SCHEMA)))

    def test_native_values_and_limits(self):
        for owner, fields in FIELDS.items():
            for field, range_, multiple in fields:
                verify_native_field(self, owner, field, range_, multiple)
            for row in ({}, {"id": None}):
                with self.assertRaises(jsonschema.ValidationError):
                    validate(owner, row)
        for value in ("none", "anvil", "not-a-station", "NONE", ""):
            # The reference branch is string-shaped: membership/disjointness is NOT enforced.
            validate("material", {"id": "example", "station": value})
        station = validator("material").schema["$defs"]["material"]["properties"]["station"]["anyOf"]
        self.assertIn({"const": "none", "type": "string"}, station)
        self.assertIn({"type": "string"}, station)
        compact = validator("ingredient").schema["$defs"]["ingredient"]["properties"]["refines-to"]
        alternatives = compact["additionalProperties"]["anyOf"]
        self.assertIn({"type": "string"}, alternatives)
        self.assertFalse(any(b.get("type") == "null" for b in alternatives))
        validate("ingredient", {"id": "example", "refines-to": {"missing-ingredient": "saw"}})
        for body in ({"process": "saw"}, {"target": "iron-cube", "process": "saw"}):
            # Native lax object alternatives and mismatched key/body remain admitted.
            validate("ingredient", {"id": "example", "refines-to": {"wood-cube": body}})
        for owner, field, value in [("ingredient", "kind", "gather|vendor"),
                                     ("ingredient", "kind", "vendor|drop"),
                                     ("faction", "alignment", "not-hostility-enum"),
                                     ("faction", "members", ["paladin", "paladin"]),
                                     ("faction", "presence", ["same", "same"]),
                                     ("npc-role", "species", "human"),
                                     ("npc-role", "species", "missing-species")]:
            validate(owner, {"id": "example", field: value})

    def test_recipes_source_keeps_null_and_rejects_bad_gem(self):
        from ontology_source_contracts import validate_source

        row = catalog("recipes")
        validate_source("recipes", row)
        self.assertIsNone(row["gear-armor-quantities"]["common"]["gem"])
        bad = json.loads(json.dumps(row))
        bad["gear-armor-quantities"]["common"]["gem"] = []
        with self.assertRaises(jsonschema.ValidationError):
            validate_source("recipes", bad)

    def test_complete_ordinary_projections(self):
        for owner, excluded, count in [
            ("ingredient", {"$schema", "_doc", "_unused-data"}, 44),
            ("material", {"$schema", "_doc"}, 27),
            ("faction", {"$schema", "_doc", "realm-name-examples"}, 10),
            ("npc-role", {"$schema", "dialogue-corpus"}, 22),
        ]:
            rows = catalog(FILES[owner])
            self.assertTrue(excluded <= rows.keys())
            self.assertEqual(len(rows.keys() - excluded), count)
            for key in sorted(rows.keys() - excluded):
                projection = {field: rows[key][field] for field, _, _ in FIELDS[owner] if field in rows[key]}
                validate(owner, dict(projection, id=key))
        ingredients = catalog("ingredients")
        for key, process in [("iceflower", {"heartflower": "1-3 @campfire"}),
                             ("plant-fiber", {"linen-yarn": "spinning wheel"}),
                             ("wood-log", {"wood-cube": "saw"})]:
            self.assertEqual(ingredients[key]["refines-to"], process)
        targets = {target for row in ingredients.values() if isinstance(row, dict)
                   for target in row.get("refines-to", {})}
        self.assertTrue(targets <= ingredients.keys())
        materials = catalog("materials")
        self.assertIsNone(materials["bronze"]["id"])
        self.assertEqual(materials["mammoth"]["raw"], "mammoth-hide (0% drop)")
        self.assertEqual(materials["iron"]["class"], "warrior (armor); metal weapons all classes")
        stations = {row["station"] for row in materials.values() if isinstance(row, dict) and "station" in row}
        self.assertTrue(stations - {"none"} <= catalog("crafting-stations").keys())
        self.assertNotIn("none", catalog("crafting-stations"))
        members = [member for row in catalog("factions").values() if isinstance(row, dict)
                   for member in row.get("members", [])]
        self.assertEqual(len(members), 15)
        self.assertTrue(set(members) <= catalog("creatures").keys())
        self.assertFalse(set(members) & catalog("races").keys())
        roles = catalog("npc-roles")
        self.assertEqual({key for key, row in roles.items() if isinstance(row, dict)
                          and "building" in row and row["building"] is None},
                         {"gem-trader", "gnome-supplier", "adventurer"})
        self.assertEqual(roles["arena-master"]["species"], "bloodaxe-orc")
        self.assertIn("bloodaxe-orc", catalog("creatures"))
        self.assertNotIn("building", roles["captive"])

    def test_primitive_range_mutations(self):
        for owner, fields in FIELDS.items():
            for field, range_, multiple in fields:
                if range_ not in ("string", "integer", "creature", "race-or-creature"):
                    continue
                row = {"id": "example", field: sample(range_, multiple)}
                validate(owner, row)
                with self.subTest(owner=owner, field=field):
                    replacement = "string" if range_ == "integer" else "integer"
                    self.assertFalse(mutated(MODULE, owner + "-" + field, "range", replacement, owner, row))

    def test_union_and_compact_mutations(self):
        cases = [
            ("material-station", "any_of", [{"range": "string", "equals_string": "none"}],
             "material", {"station": "anvil"}, False),
            ("material-station", "any_of", [{"range": "crafting-station"}],
             "material", {"station": "none"}, True),
            ("material-station", "any_of", [{"range": "crafting-station"}, {"range": "string", "equals_string": "absent"}],
             "material", {"station": "none"}, True),
            ("ingredient-refines-to", "multivalued", False, "ingredient", {"refines-to": {"wood-cube": "saw"}}, False),
            # No global identifier: native generation forces inlining even if this flag is false.
            ("ingredient-refines-to", "inlined", False, "ingredient", {"refines-to": {"wood-cube": "saw"}}, True),
            ("ingredient-refines-to", "inlined_as_list", True, "ingredient", {"refines-to": {"wood-cube": "saw"}}, False),
            ("ingredient-refinement-target", "key", False, "ingredient", {"refines-to": {"wood-cube": "saw"}}, False),
            ("ingredient-refinement-process", "range", "integer", "ingredient", {"refines-to": {"wood-cube": "saw"}}, False),
            ("ingredient-refinement-process", "required", False, "ingredient", {"refines-to": {"wood-cube": None}}, True),
            ("ingredient-refinement-process", "alias", "wrong-process", "ingredient", {"refines-to": {"wood-cube": {"process": "saw"}}}, False),
            ("ingredient-refines-to", "required", True, "ingredient", {}, False),
            ("faction-members", "multivalued", False, "faction", {"members": ["paladin"]}, False),
            ("faction-presence", "multivalued", False, "faction", {"presence": ["exact text"]}, False),
        ]
        for name, facet, value, owner, properties, expected in cases:
            row = dict(properties, id="example")
            if name == "ingredient-refinement-process" and facet == "required":
                with self.assertRaises(jsonschema.ValidationError):
                    validate(owner, row)
            else:
                validate(owner, row)
            with self.subTest(name=name, facet=facet, value=value):
                self.assertEqual(mutated(MODULE, name, facet, value, owner, row), expected)

    def test_task4_logical_item_and_recipe_contracts(self):
        view = SchemaView(str(SCHEMA))
        upgrade = view.get_class("item-upgrade")
        self.assertIn("item-upgrade-level", upgrade.slots)
        level = view.induced_slot("item-upgrade-level", "item-upgrade")
        self.assertEqual((level.alias, level.domain, level.range, level.required),
                         ("level", "item-upgrade", "integer", True))
        self.assertEqual(view.get_slot("item-upgrades").maximum_cardinality, 32)
        inventory = view.get_class("inventory")
        self.assertEqual(set(inventory.slots), {"id", "inventory-entries", "inventory-coins", "inventory-equipment"})
        self.assertNotIn("inventory-start", view.class_slots("inventory"))
        self.assertEqual(view.get_slot("inventory-entry-count").minimum_value, 1)
        self.assertIsNone(view.get_slot("inventory-entry-count").maximum_value)
        self.assertEqual(view.get_slot("inventory-equipment").maximum_cardinality, 12)
        assignment = view.get_class("equipment-assignment")
        self.assertEqual(assignment.unique_keys["slot"].unique_key_slots, ["equipment-assignment-slot"])
        self.assertEqual(view.get_slot("holds").annotations["association-class"].value, "inventory-entry")
        self.assertEqual(view.get_slot("equips").range, "item")
        traversal = view.induced_slot("traversal-kind", "artifact")
        self.assertEqual((traversal.range, traversal.required), ("ArtifactTraversalKind", True))
        self.assertEqual({name: value.aliases for name, value in
                          view.get_enum("ArtifactTraversalKind").permissible_values.items()}, {
            "climb_speed": ["climb-speed"], "swim_speed": ["swim-speed"],
            "diving_skill": ["diving-skill"], "ride_speed": ["ride-speed"],
            "glide_speed": ["glide-speed"], "sail_speed": ["sail-speed"],
            "light_radius": ["light-radius"]})
        artifact_stats = view.induced_slot("raises-stat", "artifact")
        self.assertEqual((artifact_stats.range, artifact_stats.minimum_cardinality,
                          artifact_stats.maximum_cardinality), ("stat", 3, 3))
        self.assertIn("one traversal stat plus attack and maximum HP", artifact_stats.description)
        self.assertEqual(view.get_class("formula").is_a, "item")
        self.assertIn("item-level", view.class_slots("formula"))
        self.assertIsNone(view.get_class("book-of-crafting").is_a)
        self.assertNotIn("item-level", view.class_slots("book-of-crafting"))
        self.assertEqual(view.get_slot("item-level").range, "i16")
        self.assertEqual((view.get_slot("item-level").minimum_value,
                          view.get_slot("item-level").maximum_value), (1, 100))
        self.assertEqual(set(view.get_class("recipe").slots),
                         {"id", "crafted-at", "consumes", "produces", "recipe-required-power"})
        self.assertIn("knows-recipe", view.class_slots("player-character"))
        expected_relations = {
            "crafted-at": ("recipe", "crafting-station", False),
            "consumes": ("recipe", "ingredient-or-material", True),
            "produces": ("recipe", "item-type-or-consumable", False),
            "yields": ("flora-or-deposit-or-creature", "ingredient", True),
            "knows-recipe": ("player-character", "recipe", True),
        }
        for name, (domain, range_, multiple) in expected_relations.items():
            slot = view.get_slot(name)
            self.assertEqual((slot.domain, slot.range, bool(slot.multivalued)),
                             (domain, range_, multiple))
        consumption = view.get_class("recipe-consumption")
        self.assertEqual(consumption.slots, ["recipe-consumption-input", "recipe-consumption-count"])
        self.assertEqual(view.get_slot("recipe-consumption-input").range, "ingredient-or-material")
        self.assertEqual(view.get_slot("recipe-consumption-count").minimum_value, 1)
        yield_class = view.get_class("ingredient-yield")
        self.assertEqual(yield_class.slots, ["ingredient-yield-ingredient", "ingredient-yield-minimum",
                                             "ingredient-yield-maximum"])
        for name in ("ingredient-yield-minimum", "ingredient-yield-maximum"):
            self.assertEqual(view.get_slot(name).range, "integer")
            self.assertEqual(view.get_slot(name).minimum_value, 0)

    def test_task4_logical_yaml_mutations(self):
        def check(view):
            level = view.induced_slot("item-upgrade-level", "item-upgrade")
            self.assertEqual((level.alias, level.range, level.required), ("level", "integer", True))
            self.assertEqual(view.get_slot("produces").range, "item-type-or-consumable")
            self.assertEqual(view.get_slot("recipe-consumption-input").range, "ingredient-or-material")
            self.assertEqual(view.get_slot("ingredient-yield-ingredient").range, "ingredient")
            self.assertEqual(view.induced_slot("traversal-kind", "artifact").range, "ArtifactTraversalKind")
            self.assertEqual(view.induced_slot("raises-stat", "artifact").maximum_cardinality, 3)

        check(SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            shutil.copytree(SCHEMA.parent, target)
            for module, mutate in [
                ("items.yaml", lambda data: data["slots"]["item-upgrade-level"].update(range="float")),
                ("relations.yaml", lambda data: data["slots"]["produces"].update(range="item-type")),
                ("associations.yaml", lambda data: data["slots"]["recipe-consumption-input"].update(range="ingredient")),
                ("items.yaml", lambda data: data["classes"]["artifact"]["slot_usage"]["raises-stat"].update(maximum_cardinality=2)),
            ]:
                path = target / module
                original = yaml.safe_load(path.read_text())
                changed = yaml.safe_load(path.read_text())
                mutate(changed)
                path.write_text(yaml.safe_dump(changed, sort_keys=False))
                with self.subTest(module=module), self.assertRaises(AssertionError):
                    check(SchemaView(str(target / "pixlnd.yaml")))
                path.write_text(yaml.safe_dump(original, sort_keys=False))

    def test_actual_attachment_alias_and_target_metadata_mutations(self):
        # Apply the SAME baseline competency assertions to actual mutated source.
        # Reference-to-reference mutations are metadata-sensitive, not FK enforcement.
        assert_selected_facets(self, SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            shutil.copytree(SCHEMA.parent, target)
            for owner, fields in FIELDS.items():
                module = "items.yaml" if owner in ("ingredient", "material") else "identity.yaml"
                path = target / module
                original = path.read_text()
                for field, _, _ in fields:
                    name = owner + "-" + field
                    data = yaml.safe_load(original)
                    data["classes"][owner]["slots"].remove(name)
                    path.write_text(yaml.safe_dump(data, sort_keys=False))
                    with self.assertRaises(AssertionError):
                        assert_selected_facets(self, SchemaView(str(target / "pixlnd.yaml")))
                    path.write_text(original)
            path = target / MODULE
            original = path.read_text()
            cases = [(owner + "-" + field, "alias", "wrong-alias")
                     for owner, fields in FIELDS.items() for field, _, _ in fields]
            cases += [("ingredient-refines-to", "inlined", False),
                      ("faction-members", "range", "race"),
                      ("npc-role-species", "range", "creature"),
                      ("ingredient-refinement-target", "range", "material"),
                      ("ingredient-refinement-target", "identifier", True),
                      ("ingredient-refinement-target", "required", False),
                      ("ingredient-refinement-target", "alias", "wrong-target"),
                      ("ingredient-refinement-process", "multivalued", True),
                      ("ingredient-refinement-process", "domain", "ingredient"),
                      ("material-station", "any_of", [{"range": "crafting-station"}]),
                      ("material-station", "any_of", [{"range": "crafting-station"}, {"range": "string", "equals_string": "absent"}])]
            for name, facet, value in cases:
                data = yaml.safe_load(original)
                data["slots"][name][facet] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(name=name, facet=facet):
                    with self.assertRaises(AssertionError):
                        assert_selected_facets(self, SchemaView(str(target / "pixlnd.yaml")))
            path.write_text(original)


if __name__ == "__main__":
    unittest.main()
