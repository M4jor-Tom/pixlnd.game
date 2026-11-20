"""Source-backed S1 projections; native generation is not runtime admission."""

from copy import deepcopy
from functools import lru_cache
import json
from pathlib import Path
import shutil
import tempfile
import unittest

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView

from test_ontology_schema import ROOT, SCHEMA, generated


generated = lru_cache(maxsize=None)(generated)


def catalog(name):
    return json.loads((ROOT / f"ontology/instances/{name}.json").read_text())


@lru_cache(maxsize=None)
def validator(name):
    schema = generated(name)
    jsonschema.Draft201909Validator.check_schema(schema)
    return jsonschema.Draft201909Validator(schema)


def validate(name, row):
    validator(name).validate(row)


def verify_projection_rows(name, key, fields):
    rows = catalog(key)
    if name == "building":
        rows = rows["buildings"]
    for identifier, row in rows.items():
        if isinstance(row, dict) and "name" in row:
            projection = {k: row[k] for k in fields if k in row}
            projection["id"] = identifier
            validate(name, projection)


class AuthoringTests(unittest.TestCase):
    def test_source_qualified_appearance_and_entity_state(self):
        from ontology_source_contracts import assert_declared_root

        model_fields = {"head-model", "hair-model", "hand-model", "foot-model", "body-model",
                        "tail-model", "shoulder2-model", "wing-model"}
        scale_fields = {"head-scale", "body-scale", "hand-scale", "foot-scale", "shoulder2-scale",
                        "weapon-scale", "tail-scale", "shoulder-scale", "wing-scale"}
        offset_fields = {"body-offset", "head-offset", "hand-offset", "foot-offset", "tail-offset", "wing-offset"}
        angle_fields = {"body-pitch", "arm-pitch", "arm-roll", "arm-yaw", "feet-pitch", "wing-pitch", "back-pitch"}
        appearance_fields = {"id", "hair-rgb", "scale", "flags", "expression"} | model_fields | scale_fields | offset_fields | angle_fields
        assert_declared_root("appearance", appearance_fields, {"id"})
        appearance = {"id": "appearance-a", "hair-rgb": [0, 127, 255], "scale": [1, 1, 1]}
        appearance.update({name: 1 for name in model_fields | scale_fields | angle_fields})
        appearance.update({name: [0, 0, 0] for name in offset_fields})
        validate("appearance", appearance)
        for name in model_fields:
            for value in (-32769, 32768, "model-name", True):
                with self.subTest(model=name, value=value), self.assertRaises(jsonschema.ValidationError):
                    validate("appearance", dict(appearance, **{name: value}))
        for name in scale_fields:
            with self.subTest(scale=name), self.assertRaises(jsonschema.ValidationError):
                validate("appearance", dict(appearance, **{name: [1, 1, 1]}))
        for name in offset_fields | {"scale", "hair-rgb"}:
            with self.subTest(vector=name), self.assertRaises(jsonschema.ValidationError):
                validate("appearance", dict(appearance, **{name: [0, 0]}))
        for name in ("hair-scale", "weapon-model", "shoulder-offset"):
            with self.subTest(uninvented=name), self.assertRaises(jsonschema.ValidationError):
                validate("appearance", dict(appearance, **{name: 1}))
        fields = {"id", "hostility", "species", "level", "xp", "power-base", "appearance", "mana-cubes", "skills",
                  "parent-owner", "pos", "velocity", "accel", "body-roll", "body-pitch", "body-yaw", "class",
                  "specialization", "hp", "mp", "stamina", "block-power", "stealth", "hp-multiplier", "damage-multiplier",
                  "armor-multiplier", "resi-multiplier", "hit-counter", "last-hit-time", "stun-time", "slowed-time",
                  "blue-time", "speed-up-time", "flags", "equipment", "name", "equips", "threat", "current-target", "status-applications"}
        required = {"id", "hostility", "species", "level", "xp", "power-base", "appearance", "mana-cubes", "skills"}
        assert_declared_root("entity", fields, required)
        row = {"id": "mob-a", "hostility": "hostile", "species": "not-a-defined-species", "level": 1, "xp": 0,
               "power-base": 0, "appearance": appearance, "mana-cubes": 0, "skills": [0] * 11,
               "pos": [0, 0, 0], "last-hit-time": 4294967295, "equipment": ["item-a"] * 13,
               "status-applications": [{"effect": "burning", "damage": 10}, {"effect": "burning", "damage": 5}]}
        validate("entity", row)
        for field, value in (("last-hit-time", -1), ("last-hit-time", 4294967296), ("last-hit-time", "5 ms"),
                             ("pos", [0, 0, 9223372036854775808]), ("mp", 101), ("equipment", ["item-a"] * 12),
                             ("flags", ["unknown"]), ("status-applications", [{"effect": "burning", "damage": -1}])):
            with self.subTest(field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                validate("entity", dict(row, **{field: value}))
        view = SchemaView(str(SCHEMA))
        slot = view.get_slot("entity-last-hit-time")
        self.assertEqual(slot.range, "uint32")
        self.assertIn("units, epoch, reset, wrap", slot.description)
        self.assertIsNone(slot.unit)
        self.assertEqual(view.get_class("player-character").is_a, "entity")
        self.assertEqual(view.get_class("pet").is_a, "entity")
        self.assertIsNone(view.get_class("creature").is_a)

    def test_character_world_travel_slot_placement(self):
        from ontology_source_contracts import assert_declared_root

        fields = {"character", "world", "position", "respawn", "discovered-lands", "discovered-portals", "discovered-shrines", "discovered-flight-points"}
        assert_declared_root("character-world-state", fields, {"character", "world"})
        view = SchemaView(str(SCHEMA))
        for suffix, target in (("lands", "land"), ("portals", "poi"), ("shrines", "poi"), ("flight-points", "poi")):
            name = "character-world-state-discovered-" + suffix
            slot = view.induced_slot(name, "character-world-state")
            self.assertEqual((slot.alias, slot.domain, slot.range), ("discovered-" + suffix, "character-world-state", target))
            self.assertEqual(slot.slot_uri, "pixlnd:character-world-state/discovered-" + suffix)
            self.assertTrue(slot.multivalued)
            self.assertTrue(slot.list_elements_unique)
            self.assertNotIn(name, view.class_slots("player-character"))
            self.assertNotIn("player-character-discovered-" + suffix, view.all_slots())
        slot = view.get_slot("player-character-world-states")
        self.assertEqual((slot.alias, slot.range, slot.domain), ("world-states", "character-world-state", "player-character"))
        row = {"character": "hero", "world": "saved-world", "position": [1, 2, 3], "discovered-lands": ["land-a"]}
        validate("character-world-state", row)
        with self.assertRaises(jsonschema.ValidationError):
            validate("character-world-state", dict(row, position=[1, 2]))

    def test_identity_combat_logical_facets(self):
        view = SchemaView(str(SCHEMA))
        for owner, fields in (
            ("race", {"alpha-entity-ids", "quirks", "voice"}),
            ("character-class", {"mp-generation"}),
            ("specialization", {"passives", "kit"}),
            ("creature", {"name", "habitats", "abilities", "signature-ability", "versions"}),
            ("creature-family", {"traits"}),
            ("ability", {"owner", "cost-records", "cooldown-s", "duration-s", "effect", "versions"}),
            ("resource", {"name", "range", "gain", "spend", "regen"}),
            ("stat", {"name", "source", "formula", "effect"}),
            ("weapon-type", {"name", "material", "m1", "m2"}),
            ("status-effect", {"name", "kind", "visual", "effect", "duration-s"}),
            ("pet", {"hydration", "boss-origin"}),
            ("player-character", {"active-pet", "pet-slot", "banked-skill-points", "world-states", "known-recipes"}),
        ):
            aliases = {slot.alias for slot in view.class_induced_slots(owner)}
            with self.subTest(owner=owner):
                self.assertTrue(fields <= aliases)
        self.assertEqual(view.get_slot("has-specialization").inverse, "specialization-class")
        self.assertEqual(view.get_slot("specialization-class").inverse, "has-specialization")
        self.assertEqual(view.get_class("character-world-state").unique_keys["character-world"].unique_key_slots,
                         ["character-world-state-character", "character-world-state-world"])
        self.assertEqual(view.get_slot("costs").annotations["association-class"].value, "resource-cost")
        self.assertEqual(view.get_slot("equips").maximum_cardinality, 12)

    def test_ability_tree_unchanged_projections(self):
        rows = catalog("abilities")
        for row in rows.values():
            if isinstance(row, dict) and "alpha-tree" in row:
                validate("ability-tree-position", row["alpha-tree"])
        row = deepcopy(rows["camouflage"]["alpha-tree"])
        for field, value in [("column", "fifth"), ("needs", None), ("needs", True),
                             ("rank", 0), ("rank", 4), ("also-ultimate", 1)]:
            bad = dict(row, **{field: value})
            with self.subTest(field=field), self.assertRaises(jsonschema.ValidationError):
                validate("ability-tree-position", bad)
        del row["needs"]
        with self.assertRaises(jsonschema.ValidationError):
            validate("ability-tree-position", row)
        view = SchemaView(str(SCHEMA))
        slot = view.induced_slot("ability-alpha-tree", "ability")
        self.assertEqual((slot.alias, slot.range, slot.inlined),
                         ("alpha-tree", "ability-tree-position", True))

    def test_payloads_and_compound_metadata(self):
        validate("resource-cost", {"resource": "stamina", "amount": 25, "ruleset": "ruleset-hybrid"})
        validate("resource-cost", {"resource": "mp", "amount": "all", "ruleset": "ruleset-hybrid"})
        for value in (None, True, -1, "unknown", [], {}):
            with self.subTest(value=value), self.assertRaises(jsonschema.ValidationError):
                validate("resource-cost", {"resource": "mp", "amount": value, "ruleset": "ruleset-hybrid"})
        validate("ingredient-yield", {"ingredient": "wood-log", "minimum": 1, "maximum": 3})
        validate("recipe-consumption", {"input": "iron-cube", "count": 1})
        for name, row, field in [("ingredient-yield", {"ingredient": "wood-log", "minimum": 1, "maximum": 3}, "minimum"),
                                 ("recipe-consumption", {"input": "iron-cube", "count": 1}, "count")]:
            for value in (None, True, "1", -1):
                with self.subTest(name=name, value=value), self.assertRaises(jsonschema.ValidationError):
                    validate(name, dict(row, **{field: value}))
        view = SchemaView(str(SCHEMA))
        self.assertEqual(view.get_class("resource-cost").unique_keys["resource-ruleset"].unique_key_slots,
                         ["resource-cost-resource", "resource-cost-ruleset"])
        self.assertEqual(view.get_slot("resource-cost-amount").any_of[1].range, "all-resource")

    def test_lore_scope_is_logical_not_a_save_field(self):
        row = {"character": "hero", "realm": "realm-a", "world": "world-a", "percent": 10}
        validate("realm-knowledge", row)
        for value in (-1, 101, True, None):
            with self.assertRaises(jsonschema.ValidationError):
                validate("realm-knowledge", dict(row, percent=value))
        view = SchemaView(str(SCHEMA))
        keys = view.get_class("realm-knowledge").unique_keys["character-realm-world"].unique_key_slots
        self.assertEqual(keys, ["realm-knowledge-character", "realm-knowledge-realm", "realm-knowledge-world"])
        self.assertEqual(view.get_slot("realm-knowledge-world").range, "world")
        self.assertNotIn("lore", generated("character-state")["$defs"]["character-state"]["properties"])

    def test_current_character_and_item_wire(self):
        item = {"type": "weapon", "subtype": "sword", "material": "iron", "rarity": 0,
                "level": 1, "upgrade_count": 0, "modifier": 0, "minus_modifier": 0, "count": 1}
        row = {"id": "player-you", "class_id": "warrior", "spec": "berserker", "level": 1,
               "xp": 0, "banked": 0, "points": {}, "coins": 0, "bag": [item], "equipment": {}}
        validate("character-state", row)
        row["points"] = {"smash": 1}
        row["equipment"] = {"main-hand": item}
        validate("character-state", row)
        for field in item:
            bad = deepcopy(row)
            bad["bag"][0][field] = None
            with self.subTest(field=field), self.assertRaises(jsonschema.ValidationError):
                validate("character-state", bad)
        for field in row:
            bad = deepcopy(row)
            del bad[field]
            with self.subTest(missing=field), self.assertRaises(jsonschema.ValidationError):
                validate("character-state", bad)
        for points in ({"smash": True}, {"smash": 0}, {"smash": "1"}, {"smash": None}):
            with self.subTest(points=points), self.assertRaises(jsonschema.ValidationError):
                validate("character-state", dict(row, points=points))
        view = SchemaView(str(SCHEMA))
        self.assertTrue(view.get_slot("skill-investment-ability").key)
        self.assertFalse(view.get_slot("skill-investment-ability").identifier)
        self.assertEqual(view.get_slot("character-state-class-id").alias, "class_id")
        self.assertEqual(view.get_slot("saved-item-upgrade-count").alias, "upgrade_count")
        # Native keyed inlining also accepts this alternate, not written by capture().
        validate("character-state", dict(row, points={"smash": {"points": 1}}))
        # Key/body agreement is metadata, NOT checked by JSON Schema.
        validate("character-state", dict(row, points={"smash": {"ability": "cyclone", "points": 1}}))

    def test_current_combat_and_content_payloads(self):
        combat = {"threat": {"player-you": 20}, "order": {"player-you": 0},
                  "provoked": {"player-you": True}, "next_order": 1,
                  "current": "player-you", "taunt": "", "taunt_left": 0, "returning": False}
        validate("saved-combat", combat)
        for field, value in [("threat", {"player-you": -1}), ("order", {"player-you": True}),
                             ("taunt_left", None), ("returning", 1)]:
            with self.subTest(field=field), self.assertRaises(jsonschema.ValidationError):
                validate("saved-combat", dict(combat, **{field: value}))
        validate("saved-rubble", {"broken": False, "restore_at": 0})
        validate("saved-prop", {"hp": 10})
        row = {"phase": "warning", "left": 1, "hit": []}
        validate("saved-trap", row)
        for field, value in [("phase", "missing"), ("left", -1), ("hit", [1])]:
            with self.subTest(field=field), self.assertRaises(jsonschema.ValidationError):
                validate("saved-trap", dict(row, **{field: value}))
        view = SchemaView(str(SCHEMA))
        self.assertNotEqual(view.get_slot("saved-mob-species").range, "entity")
        self.assertEqual(view.get_slot("saved-mob-species").range, "creature")

    def test_saved_special_empty_or_three_coordinates(self):
        schema = generated("saved-special")
        cls = jsonschema.validators.validator_for(schema)
        cls.check_schema(schema)
        check = cls(schema)
        row = {"phase": "ready", "left": 0, "recovery": 0, "engaged": False,
               "target": "", "origin": [], "endpoint": []}
        for field in ("origin", "endpoint"):
            branches = schema["$defs"]["saved-special"]["properties"][field]["anyOf"]
            self.assertEqual([(b.get("minItems", 0), b["maxItems"]) for b in branches],
                             [(0, 0), (3, 3)])
            self.assertTrue(all(b["type"] == "array" and b["items"]["type"] == "number"
                                for b in branches))
            for value in ([], [0, 1.5, -2]):
                check.validate(dict(row, **{field: value}))
            for value in ([0], [0, 1], [0, 1, 2, 3], [True, 0, 0],
                          ["0", 0, 0], [[0], 0, 0], None, {}, "", 1):
                with self.subTest(field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                    check.validate(dict(row, **{field: value}))
            missing = dict(row)
            del missing[field]
            with self.subTest(missing=field), self.assertRaises(jsonschema.ValidationError):
                check.validate(missing)

    def test_saved_special_coordinate_bound_mutations(self):
        row = {"phase": "ready", "left": 0, "recovery": 0, "engaged": False,
               "target": "", "origin": [], "endpoint": []}
        for field in ("origin", "endpoint"):
            with self.subTest(field=field), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                shutil.copytree(SCHEMA.parent, target)
                module = target / "save-content.yaml"
                data = yaml.safe_load(module.read_text())
                data["slots"]["saved-special-" + field]["any_of"][1]["minimum_cardinality"] = 1
                module.write_text(yaml.safe_dump(data, sort_keys=False))
                schema = json.loads(JsonSchemaGenerator(
                    str(target / "pixlnd.yaml"), top_class="saved-special", preserve_names=True,
                    not_closed=False).serialize())
                cls = jsonschema.validators.validator_for(schema)
                cls.check_schema(schema)
                check = cls(schema)
                # The original rejection contract fails under this actual YAML mutation.
                with self.assertRaises(AssertionError):
                    self.assertFalse(check.is_valid(dict(row, **{field: [0]})))

    def test_synthetic_current_save_and_native_limits(self):
        # Writer-shaped only: tiny arbitrary stats/rosters deliberately do NOT prove
        # deterministic geography, local curves, earned progression or save admission.
        row = json.loads((ROOT / "tests/fixtures/ontology-schema/current-save.json").read_text())
        validate("save-data", row)
        for path in [("world", "clock"), ("character", "equipment"), ("version",)]:
            bad = deepcopy(row)
            parent = bad
            for key in path[:-1]:
                parent = parent[key]
            parent[path[-1]] = None
            with self.subTest(path=path), self.assertRaises(jsonschema.ValidationError):
                validate("save-data", bad)
        # Foreign-key membership, seed-plan closure, current class/spec agreement and
        # key/body equality are NOT native JSON Schema enforcement.
        bad = deepcopy(row)
        bad["character"]["spec"] = "not-a-defined-spec"
        validate("save-data", bad)
        # Native generation permits null on an optional slot; source omission does
        # not itself authorize this alternate wire form. Qualification remains open.
        validate("ability-tree-position", {"column": "class", "needs": 0, "rank": None})

    def test_new_load_bearing_declaration_mutations(self):
        cases = [
            ("catalog-properties.yaml", "slot-acceptance-condition-item-type", "key", False,
             "equipment-slot", {"id": "pet", "index": 12, "accepts": ["pet-food"],
                                "accepts-conditions": {"pet-food": "during-taming"}}),
            ("associations.yaml", "resource-cost-amount", "any_of", [{"range": "all-resource"}],
             "resource-cost", {"resource": "mp", "amount": 25, "ruleset": "ruleset-hybrid"}),
            ("combat.yaml", "ability-tree-needs", "alias", "wrong-needs",
             "ability-tree-position", {"column": "class", "needs": 0}),
            ("save-character.yaml", "skill-investment-ability", "key", False,
             "character-state", {"id": "hero", "class_id": "warrior", "spec": "berserker",
                                 "level": 1, "xp": 0, "banked": 0, "points": {"smash": 1},
                                 "coins": 0, "bag": [], "equipment": {}}),
        ]
        for module, slot, field, value, top, row in cases:
            with self.subTest(slot=slot), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                shutil.copytree(SCHEMA.parent, target)
                data = yaml.safe_load((target / module).read_text())
                data["slots"][slot][field] = value
                (target / module).write_text(yaml.safe_dump(data, sort_keys=False))
                mutant = json.loads(JsonSchemaGenerator(
                    str(target / "pixlnd.yaml"), top_class=top, preserve_names=True,
                    not_closed=False).serialize())
                with self.assertRaises(jsonschema.ValidationError):
                    jsonschema.validate(row, mutant)

    def test_current_world_envelope_and_nested_geometry(self):
        # Minimal writer-shaped current snapshot, not a claim to generated six-site validity.
        world = {"world_id": "world-a", "seed": -1, "clock": 25200, "elapsed": 0,
                 "lands": {}, "vendors": {}, "sites": {}, "mobs": {},
                 "characters": {"player-you": {"position": [0, 1, 0], "respawn": [0, 1, 0]}}}
        validate("world-state", world)
        for field in world:
            bad = deepcopy(world)
            del bad[field]
            with self.subTest(missing=field), self.assertRaises(jsonschema.ValidationError):
                validate("world-state", bad)
        # Snapshot keeps world ID independently of the generation seed.
        validate("world-state", dict(world, world_id="independent-same-seed"))
        row = {"family": "camp", "ordinal": 0, "centre": [200, 0], "turn": 0,
               "floor": 1, "components": [[-5, -5, 5, 5]],
               "volumes": [[195, 0, -5, 205, 5, 5]], "assignments": [],
               "entry": [0, -5], "tier": 0}
        validate("saved-site-layout", row)
        for field, size in [("components", 4), ("volumes", 6)]:
            definition = generated("saved-site-layout")["$defs"]["saved-site-layout"]["properties"][field]
            self.assertEqual(definition["minItems"], 1)
            self.assertEqual(definition["items"]["minItems"], size)
            self.assertEqual(definition["items"]["maxItems"], size)
            validate("saved-site-layout", dict(row, **{field: [[0] * size, [1] * size]}))
            for bad in ([], [[0] * (size - 1)], [[0] * (size + 1)], [[0] * size, [0]],
                        [[0] * (size - 1) + [True]], ["bad"], [[[[0]]]], {}):
                with self.subTest(field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    validate("saved-site-layout", dict(row, **{field: bad}))
        bad = deepcopy(world)
        bad["characters"]["player-you"]["position"] = [0, 1]
        with self.assertRaises(jsonschema.ValidationError):
            validate("world-state", bad)

    def test_current_design_ability_and_progression_projections(self):
        design = catalog("generators")["design"]
        for key, row in design["abilities"].items():
            if isinstance(row, dict):
                validate("ability-runtime", row)
        for name, key in [("progression-design", "progression"),
                          ("gear-hp-design", "gear-hp"), ("artifact-design", "artifact")]:
            row = {k: v for k, v in design[key].items() if k != "_doc"}
            validate(name, row)
        row = deepcopy(design["abilities"]["cyclone"])
        for field, value in [("runtime", 99), ("runtime", "missing"), ("cost", {"mp": 101}),
                             ("cost", {"stamina": "unknown"}), ("cooldown-s", None),
                             ("drain-per-s", -1), ("turns-per-s", "1")]:
            with self.subTest(field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                validate("ability-runtime", dict(row, **{field: value}))
        for field in ("runtime", "cost", "cooldown-s"):
            bad = dict(row)
            del bad[field]
            with self.assertRaises(jsonschema.ValidationError):
                validate("ability-runtime", bad)
        validate("ability-runtime", dict(row, **{"drain-per-s": 0}))
        validate("artifact-design", design["artifact"])
        for field in ("first", "z", "total-bonus", "stats"):
            bad = dict(design["artifact"])
            bad[field] = None
            with self.assertRaises(jsonschema.ValidationError):
                validate("artifact-design", bad)

    def test_catalog_property_projections(self):
        for identifier, row in catalog("races").items():
            if not identifier.startswith(("_", "$")):
                for key in ("hair", "heads"):
                    validate("gender-option-counts", row[key])
        for counts in ({"m": -1, "f": 0}, {"m": True, "f": 1}, {"m": 1}, {"m": 1, "f": None}):
            with self.assertRaises(jsonschema.ValidationError):
                validate("gender-option-counts", counts)
        view = SchemaView(str(SCHEMA))
        for name, key, fields in [
            ("rarity", "rarities", ("index", "name", "color", "hex", "stars", "gem", "named")),
            ("building", "buildings", ("name", "roles", "stations", "sign", "map-icon")),
        ]:
            verify_projection_rows(name, key, fields)
        self.assertEqual(view.get_slot("building-roles").range, "npc-role")
        self.assertEqual(view.get_slot("rarity-gem").range, "material")
        self.assertEqual(view.get_slot("race-hair").range, "gender-option-counts")
        self.assertEqual(view.get_slot("race-heads").alias, "heads")

    def test_equipment_slot_conditional_acceptance_projections(self):
        fields = ("id", "index", "accepts", "hp-mult", "accepts-conditions")
        for row in catalog("equipment-slots")["slots"]:
            projection = {key: row[key] for key in fields if key in row}
            validate("equipment-slot", projection)
        pet = {"id": "pet", "index": 12, "accepts": ["pet-cage", "pet-food"],
               "accepts-conditions": {"pet-food": "during-taming"}}
        for value in ("always", 1, True, None, []):
            bad = deepcopy(pet)
            bad["accepts-conditions"]["pet-food"] = value
            with self.subTest(value=value), self.assertRaises(jsonschema.ValidationError):
                validate("equipment-slot", bad)
        for value in (True, "0.5", [], {}):
            with self.subTest(hp_mult=value), self.assertRaises(jsonschema.ValidationError):
                validate("equipment-slot", dict(pet, **{"hp-mult": value}))
        view = SchemaView(str(SCHEMA))
        self.assertTrue(view.get_slot("slot-acceptance-condition-item-type").key)
        self.assertEqual(view.get_slot("slot-acceptance-condition-item-type").range, "item-type")
        # Native inlining also accepts object values; the writer's scalar wire is
        # retained, but key/body agreement and actual taming eligibility are not checked.
        alternate = deepcopy(pet)
        alternate["accepts-conditions"] = {"pet-food": {"condition": "during-taming"}}
        validate("equipment-slot", alternate)
        alternate["accepts-conditions"]["pet-food"]["item-type"] = "weapon"
        validate("equipment-slot", alternate)

    def test_selected_catalog_fields_and_native_limits(self):
        view = SchemaView(str(SCHEMA))
        for owner, field, range_, multiple, valid, malformed in [
            ("ingredient", "alpha-subtype", "integer", False, 0, (True, "0", 1.5, [], {})),
            ("material", "kind", "string", False, "metal", (True, 1, [], {})),
            ("faction", "name", "string", False, "Order of the Light", (True, 1, [], {})),
            ("npc-role", "name", "string", False, "Villager", (True, 1, [], {})),
            ("npc-role", "dialogue", "string", True, ["banter"],
             (True, 1, "banter", {}, [1], [True], [None], [["banter"]], [{}])),
            ("npc-role", "sign", "string", False, "crown", (True, 1, [], {})),
        ]:
            with self.subTest(owner=owner, field=field):
                name = owner + "-" + field
                self.assertIn(name, view.class_slots(owner))
                slot = view.induced_slot(name, owner)
                self.assertEqual((slot.alias, slot.domain, slot.range), (field, owner, range_))
                self.assertEqual(bool(slot.multivalued), multiple)
                self.assertFalse(slot.required)
                self.assertFalse(slot.identifier or slot.key)
                self.assertIn("../domain/3_Classes.md#" + owner, slot.see_also)
                validate(owner, {"id": "example", field: valid})
                validate(owner, {"id": "example"})
                for value in malformed:
                    with self.subTest(value=value), self.assertRaises(jsonschema.ValidationError):
                        validate(owner, {"id": "example", field: value})
                # Native optional slots also admit null. No source-null equivalence
                # or whole-family admission is claimed by these projections.
                validate(owner, {"id": "example", field: None})
        validate("material", {"id": "example", "kind": "not-a-closed-vocabulary"})
        validate("npc-role", {"id": "example", "dialogue": []})
        for owner in ("ingredient", "material", "faction", "npc-role"):
            with self.subTest(missing_id=owner), self.assertRaises(jsonschema.ValidationError):
                validate(owner, {})
            with self.subTest(null_id=owner), self.assertRaises(jsonschema.ValidationError):
                validate(owner, {"id": None})

    def test_selected_catalog_unchanged_projections(self):
        for owner, file, fields, excluded, count in [
            ("ingredient", "ingredients", ("name", "alpha-subtype"),
             {"$schema", "_doc", "_unused-data"}, 44),
            ("material", "materials", ("name", "kind"), {"$schema", "_doc"}, 27),
            ("faction", "factions", ("name",), {"$schema", "_doc", "realm-name-examples"}, 10),
            ("npc-role", "npc-roles", ("name", "dialogue", "sign"),
             {"$schema", "dialogue-corpus"}, 22),
        ]:
            rows = catalog(file)
            self.assertTrue(excluded <= rows.keys())
            selected = rows.keys() - excluded
            self.assertEqual(len(selected), count)
            for identifier in sorted(selected):
                projection = {field: rows[identifier][field] for field in fields if field in rows[identifier]}
                # Existing stable ID is the outer key, not material's numeric/null id.
                validate(owner, dict(projection, id=identifier))
        ingredients = catalog("ingredients")
        self.assertEqual(ingredients["iron-nugget"]["alpha-subtype"], 0)
        for family, value in [("yarn", 9), ("cube", 10)]:
            ids = [key for key in ingredients if key.endswith("-" + family)
                   and "alpha-subtype" in ingredients[key]]
            self.assertGreater(len(ids), 1)
            for identifier in ids:
                self.assertEqual(ingredients[identifier]["alpha-subtype"], value)
                validate("ingredient", {"id": identifier, "alpha-subtype": value})
        self.assertNotIn("alpha-subtype", ingredients["apple"])
        self.assertIsNone(catalog("materials")["bronze"]["id"])
        self.assertNotIn("dialogue", catalog("npc-roles")["weapon-vendor"])
        self.assertNotIn("sign", catalog("npc-roles")["villager"])

    def test_selected_catalog_declaration_mutations(self):
        cases = [
            ("ingredient-alpha-subtype", "range", "string", "ingredient", {"alpha-subtype": 0}),
            ("ingredient-alpha-subtype", "required", True, "ingredient", {}),
            ("material-kind", "alias", "wrong-kind", "material", {"kind": "metal"}),
            ("faction-name", "range", "integer", "faction", {"name": "Bandits"}),
            ("npc-role-name", "range", "integer", "npc-role", {"name": "Villager"}),
            ("npc-role-dialogue", "multivalued", False, "npc-role", {"dialogue": ["banter"]}),
            ("npc-role-sign", "required", True, "npc-role", {}),
        ]
        for slot, facet, value, owner, row in cases:
            row = dict(row, id="example")
            validate(owner, row)
            with self.subTest(slot=slot, facet=facet), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                shutil.copytree(SCHEMA.parent, target)
                path = target / "catalog-properties.yaml"
                data = yaml.safe_load(path.read_text())
                data["slots"][slot][facet] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                schema = json.loads(JsonSchemaGenerator(
                    str(target / "pixlnd.yaml"), top_class=owner, preserve_names=True,
                    not_closed=False).serialize())
                cls = jsonschema.validators.validator_for(schema)
                cls.check_schema(schema)
                with self.assertRaises(jsonschema.ValidationError):
                    cls(schema).validate(row)

    def test_district_heterogeneous_buildings(self):
        data = catalog("buildings")["districts"]
        for row in data.values():
            projection = {k: row[k] for k in ("name", "buildings") if k in row}
            validate("district", dict(projection, id="quarter"))
        row = {"id": "quarter", "buildings": [{"id": "class-trainer", "class": "warrior"}]}
        validate("district", row)
        for bad in (1, None, {"id": "class-trainer", "class": 1}):
            with self.subTest(value=bad), self.assertRaises(jsonschema.ValidationError):
                validate("district", dict(row, buildings=[bad]))


if __name__ == "__main__":
    unittest.main()
