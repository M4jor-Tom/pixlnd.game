"""Current-save wire contracts, not geography or runtime save admission."""

import json
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
from ontology_source_contracts import assert_declared_root
from test_ontology_schema import ROOT, SCHEMA, copy_schema, generated

# Literal inventories are independent of the generated schema and fixture.
FIELDS = {
    "save-data": "version world character",
    "world-state": "world_id seed clock elapsed lands vendors sites mobs characters",
    "character-state": "id class_id spec level xp banked coins points bag equipment",
    "saved-item": "type subtype material rarity level upgrade_count modifier minus_modifier count",
    "saved-equipment-entry": "slot item",
    "skill-investment": "ability points",
    "character-world-position": "character position respawn",
    "saved-threat": "player amount",
    "saved-order": "player order",
    "saved-provocation": "player provoked",
    "saved-combat": "threat order provoked next_order current taunt taunt_left returning",
    "saved-mob": "species hostility role level seed cycle hp max_hp damage power_base pack home position dead eligible combat room_cycle special",
    "saved-special": "phase left recovery engaged target origin endpoint",
    "saved-rubble": "broken restore_at",
    "saved-prop": "hp",
    "saved-trap": "phase left hit",
    "saved-vendor": "day level ceiling items",
    "saved-assignment": "key pack special spirit home role tier boss seed",
    "saved-site-layout": "family ordinal centre turn floor components volumes assignments entry tier captive",
    "saved-village": "centre height gate_width gate_offset name style hub gate_index",
    "saved-land-plan": "village sites",
    "saved-mob-entry": "mob value",
    "saved-land-entry": "land value",
    "saved-vendor-entry": "vendor value",
    "saved-rubble-entry": "rubble value",
    "saved-prop-entry": "prop value",
    "saved-contents": "rubble props traps",
    "saved-reward": "source delivered level payload position classes class_id",
    "saved-spirit-level": "assignment level",
    "saved-site": "id family volumes pending cleared completed cycle mobs rewards spirit_levels room_levels contents",
}
OPTIONAL = {
    "saved-mob": {"room_cycle", "special"},
    "saved-site-layout": {"tier", "captive"},
    "saved-reward": {"position", "classes", "class_id"},
}


def specimen():
    """Expand the preserved synthetic fixture in memory; no generated-world validity claim."""
    row = json.loads((ROOT / "tests/fixtures/ontology-schema/current-save.json").read_text())
    world = row["world"]
    site = next(iter(world["sites"].values()))
    item = deepcopy(row["character"]["bag"][0])
    row["character"]["points"] = {"smash": 1}
    row["character"]["equipment"] = {"main-hand": dict(item, type="weapon", subtype="sword", count=1)}
    mob = deepcopy(next(iter(world["mobs"].values())))
    mob["room_cycle"] = 0
    mob["special"] = {"phase": "ready", "left": 0, "recovery": 0, "engaged": False,
                      "target": "", "origin": [], "endpoint": []}
    mob["combat"].update(threat={"player-you": 1.5}, order={"player-you": 0},
                         provoked={"player-you": True}, next_order=1)
    site["mobs"] = {"site-mob": mob}
    site["spirit_levels"] = {"boss/0": 1}
    site["contents"] = {"rubble": {"block": {"broken": False, "restore_at": 0}},
                        "props": {"vase": {"hp": 1}},
                        "traps": [{"phase": "idle", "left": 0, "hit": []}]}
    site["rewards"].update({
        "kill/0/boss/0": {"delivered": True, "level": 1, "payload": [item], "position": [0, 1, 0]},
        "furnishing/0/room/0/table/0": {"delivered": False, "level": 1, "payload": [item]},
    })
    layout = {"family": "supplier", "ordinal": 0, "centre": [200, 0], "turn": 0,
              "floor": 1, "components": [[-5, -5, 5, 5]], "volumes": [[195, 0, -5, 205, 5, 5]],
              "entry": [0, -5], "tier": 0, "captive": [200, 1, 0],
              "assignments": [{"key": "boss/0", "pack": "boss", "special": "charge", "spirit": "",
                               "home": [200, 1, 0], "role": "melee", "tier": 0, "boss": True, "seed": 1}]}
    world["lands"] = {"0,0": {"village": {"centre": [0, 0], "height": 1, "gate_width": 4,
                                         "gate_offset": 0, "name": "Test", "style": "stone",
                                         "hub": True, "gate_index": 0}, "sites": [deepcopy(layout) for _ in range(6)]}}
    return row


def objects(value, path=()):
    if isinstance(value, dict):
        yield path, value
        for key, child in value.items():
            yield from objects(child, (*path, key))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from objects(child, (*path, index))


def replace(row, path, value, *, delete=False):
    result = deepcopy(row)
    parent = result
    for key in path[:-1]:
        parent = parent[key]
    if delete:
        del parent[path[-1]]
    else:
        parent[path[-1]] = value
    return result


def assert_room_rule(test, view):
    for cls in (view.get_class("saved-site"), view.induced_class("saved-site")):
        rule = cls.rules[0]
        condition = rule.preconditions.slot_conditions["saved-site-family"]
        test.assertEqual((condition.alias, condition.equals_string), ("family", "ruins"))
        positive = rule.postconditions.slot_conditions["saved-site-room-levels"]
        negative = rule.elseconditions.slot_conditions["saved-site-room-levels"]
        test.assertEqual((positive.alias, positive.minimum_cardinality, positive.maximum_cardinality),
                         ("room_levels", 3, 3))
        test.assertEqual((negative.alias, negative.maximum_cardinality), ("room_levels", 0))


def required_payload_keys(path, value):
    optional = set()
    if "mobs" in path:
        optional |= {"room_cycle", "special"}
    if "lands" in path and "assignments" not in path:
        optional |= {"tier", "captive"}
    if "rewards" in path:
        optional |= {"position", "classes", "class_id"}
    if len(path) == 3 and path[:2] == ("world", "sites"):
        optional.add("id")  # Native keyed bodies make the supplied identity optional.
    return value.keys() - optional


class CurrentSaveContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.schema = generated("save-data")
        cls.check = jsonschema.Draft201909Validator(cls.schema)
        cls.row = specimen()

    def test_literal_fields_required_and_closed_definitions(self):
        assert_declared_root("save-data", {"version", "world", "character"},
                             {"version", "world", "character"}, schema=self.schema)
        for owner, words in FIELDS.items():
            fields = set(words.split())
            definition = self.schema["$defs"][owner]
            with self.subTest(owner=owner):
                self.assertEqual(set(definition["properties"]), fields)
                self.assertEqual(set(definition["required"]), fields - OPTIONAL.get(owner, set()))
                self.assertIs(definition["additionalProperties"], False)
        self.check.validate(self.row)

    def test_nested_required_deletions_and_wrong_shapes(self):
        self.check.validate(self.row)
        # Map entries are allowed to be absent; keys inside every represented payload are not.
        maps = {"lands", "vendors", "sites", "mobs", "characters", "points", "equipment", "rewards",
                "spirit_levels", "rubble", "props", "threat", "order", "provoked"}
        for path, value in objects(self.row):
            if path and path[-1] in maps:
                continue
            for key in required_payload_keys(path, value):
                with self.subTest(missing=(*path, key)), self.assertRaises(jsonschema.ValidationError):
                    self.check.validate(replace(self.row, (*path, key), None, delete=True))
            with self.subTest(unknown=path), self.assertRaises(jsonschema.ValidationError):
                self.check.validate(replace(self.row, (*path, "unexpected-field"), True))
        for path, value in objects(self.row):
            if not path:
                continue
            for malformed in (None, [], "not-an-object", 1, True):
                with self.subTest(path=path, malformed=malformed), self.assertRaises(jsonschema.ValidationError):
                    self.check.validate(replace(self.row, path, malformed))

    def test_optional_fields_are_omittable_not_nullable(self):
        cases = [(("world", "sites", "world-a/site/0,0/camp/0", "mobs", "site-mob"), ("room_cycle", "special")),
                 (("world", "lands", "0,0", "sites", 0), ("tier", "captive")),
                 (("world", "sites", "world-a/site/0,0/camp/0", "rewards", "kill/0/boss/0"), ("position",)),
                 (("world", "sites", "world-a/site/0,0/camp/0", "rewards", "mission/0"), ("classes", "class_id"))]
        self.check.validate(self.row)
        ruins = deepcopy(self.row)
        layout = ruins["world"]["lands"]["0,0"]["sites"][0]
        layout.update(family="ruins")
        del layout["tier"], layout["captive"]
        self.check.validate(ruins)
        for path, fields in cases:
            for field in fields:
                if "lands" not in path:
                    self.check.validate(replace(self.row, (*path, field), None, delete=True))
                with self.subTest(path=path, field=field), self.assertRaises(jsonschema.ValidationError):
                    self.check.validate(replace(self.row, (*path, field), None))

    def test_positive_health_and_threat(self):
        paths = [("world", "mobs", "world-a/ambient/0,0/0/0", "max_hp"),
                 ("world", "sites", "world-a/site/0,0/camp/0", "mobs", "site-mob", "combat", "threat", "player-you")]
        for path in paths:
            self.check.validate(replace(self.row, path, 0.5))
            for value in (0, -1, True, "1", None, [], {}):
                with self.subTest(path=path, value=value), self.assertRaises(jsonschema.ValidationError):
                    self.check.validate(replace(self.row, path, value))

    def test_existing_item_and_conditional_wire_facets(self):
        view = SchemaView(str(SCHEMA))
        kinds = {"weapon", "chest-armor", "gloves", "boots", "shoulder-armor", "ring", "amulet",
                 "consumable", "ingredient", "coin", "pet-food"}
        for slot in (view.get_slot("saved-item-type"), view.induced_slot("saved-item-type", "saved-item")):
            self.assertEqual(set(slot.equals_string_in), kinds)
        for cls in (view.get_class("saved-site-layout"), view.induced_class("saved-site-layout")):
            self.assertEqual(len(cls.rules), 2)
            tier, captive = cls.rules
            self.assertEqual(tier.preconditions.slot_conditions["saved-site-layout-family"].equals_string_in,
                             ["camp", "supplier"])
            self.assertTrue(tier.postconditions.slot_conditions["saved-site-layout-tier"].required)
            self.assertEqual(str(tier.elseconditions.slot_conditions["saved-site-layout-tier"].value_presence), "ABSENT")
            self.assertEqual(captive.preconditions.slot_conditions["saved-site-layout-family"].equals_string, "supplier")
            self.assertTrue(captive.postconditions.slot_conditions["saved-site-layout-captive"].required)
            self.assertEqual(str(captive.elseconditions.slot_conditions["saved-site-layout-captive"].value_presence), "ABSENT")
        for cls in (view.get_class("saved-reward"), view.induced_class("saved-reward")):
            self.assertEqual(len(cls.rules), 3)
            for rule, kind, present in zip(cls.rules, ("kill", "mission", "furnishing"),
                                           ({"position"}, {"classes", "class_id"}, set()), strict=True):
                self.assertEqual(rule.preconditions.slot_conditions["saved-reward-source"].pattern, "^" + kind + "/")
                fields = rule.postconditions.slot_conditions
                self.assertEqual({slot.alias for slot in fields.values() if slot.required}, present)
                self.assertEqual({slot.alias for slot in fields.values() if str(slot.value_presence) == "ABSENT"},
                                 {"position", "classes", "class_id"} - present)
        for value in ("unimplemented", None, 1):
            with self.subTest(kind=value), self.assertRaises(jsonschema.ValidationError):
                self.check.validate(replace(self.row, ("character", "bag", 0, "type"), value))
        with self.assertRaises(jsonschema.ValidationError):
            self.check.validate(replace(self.row, ("character", "bag", 0, "level"), 101))
        ingredient = dict(self.row["character"]["bag"][0], type="ingredient", subtype="wood-cube", level=101)
        self.check.validate(replace(self.row, ("character", "bag"), [ingredient]))

    def test_conditional_payloads_and_native_provocation_limit(self):
        layout_path = ("world", "lands", "0,0", "sites", 0)
        for field in ("tier", "captive"):
            with self.subTest(required=field), self.assertRaises(jsonschema.ValidationError):
                self.check.validate(replace(self.row, (*layout_path, field), None, delete=True))
        view = SchemaView(str(SCHEMA))
        for slot in (view.get_slot("saved-provocation-provoked"),
                     view.induced_slot("saved-provocation-provoked", "saved-provocation")):
            self.assertEqual(slot.equals_expression, "True")
        path = ("world", "sites", "world-a/site/0,0/camp/0")
        self.check.validate(replace(self.row, (*path, "mobs", "site-mob", "combat", "provoked", "player-you"), False))
        # The supplied source key enables native conditional presence checks; the compact body omits it.
        rewards = self.row["world"]["sites"][path[-1]]["rewards"]
        check = self.check.evolve(schema={"$ref": "#/$defs/saved-reward"})
        for key, required in (("kill/0/boss/0", ("position",)), ("mission/0", ("classes", "class_id")),
                              ("furnishing/0/room/0/table/0", ())):
            row = dict(rewards[key], source=key)
            check.validate(row)
            for field in required:
                with self.subTest(source=key, missing=field), self.assertRaises(jsonschema.ValidationError):
                    check.validate({name: value for name, value in row.items() if name != field})
            forbidden = {"position", "classes", "class_id"} - set(required)
            # Retain invalid-shape checks separately; these are not absence evidence.
            for field in forbidden - {"classes"}:
                with self.subTest(source=key, malformed=field), self.assertRaises(jsonschema.ValidationError):
                    check.validate(dict(row, **{field: []}))
            values = {"position": [0, 1, 0], "classes": ["warrior"], "class_id": "warrior"}
            for field in forbidden:
                if len(forbidden) == 1:
                    with self.subTest(source=key, absent=field), self.assertRaises(jsonschema.ValidationError):
                        check.validate(dict(row, **{field: values[field]}))
                else:
                    check.validate(dict(row, **{field: values[field]}))
            if "classes" in forbidden:
                check.validate(dict(row, classes=[]))
            # Native emits one not/required group: forbids co-presence, not each absent field.
            with self.subTest(source=key, all_forbidden=True), self.assertRaises(jsonschema.ValidationError):
                check.validate(dict(row, **{field: values[field] for field in forbidden}))

    def test_scalar_list_and_coordinate_boundaries(self):
        site = ("world", "sites", "world-a/site/0,0/camp/0")
        layout = ("world", "lands", "0,0", "sites", 0)
        cases = [(("version",), [0, 2, True, None, "1"]),
                 (("character", "bag", 0, "count"), [0, -1, True, "1", 1.5]),
                 (("character", "points", "smash"), [0, -1, True, "1", None, []]),
                 (("character", "equipment", "main-hand"), [None, [], 1]),
                 (("world", "characters", "player-you", "position"), [[0], [0, 1], [0, 1, 2, 3], [True, 0, 0]]),
                 ((*layout, "components"), [[], [[0, 0, 0]], [[0, 0, 0, True]], {}]),
                 ((*layout, "volumes"), [[], [[0] * 5], [[0] * 7], [[0] * 6, [0]]]),
                 ((*layout, "turn"), [-1, 4, True, "0"]),
                 (("world", "lands", "0,0", "sites"), [[], [self.row["world"]["lands"]["0,0"]["sites"][0]]]),
                 ((*site, "contents", "traps", 0, "phase"), ["missing", 0, None]),
                 ((*site, "contents", "traps", 0, "hit"), [[True], [None], {}, "hero"]),
                 ((*site, "spirit_levels", "boss/0"), [0, True, "1", None]),
                 ((*site, "room_levels"), [[1], [1, 2], [1, 2, 3, 4], [True, 1, 1], [0, 1, 1]]),
                 ((*site, "mobs", "site-mob", "special", "origin"), [[0], [0, 1], [0, 1, 2, 3], [True, 1, 1]])]
        self.check.validate(self.row)
        for path, values in cases:
            for value in values:
                with self.subTest(path=path, value=value), self.assertRaises(jsonschema.ValidationError):
                    self.check.validate(replace(self.row, path, value))
        view = SchemaView(str(SCHEMA))
        for slot in (view.get_slot("saved-reward-classes"), view.induced_slot("saved-reward-classes", "saved-reward")):
            self.assertTrue(slot.list_elements_unique)
        # Uniqueness is declared; the pinned native generator does not enforce this facet.
        self.check.validate(replace(self.row, (*site, "rewards", "mission/0", "classes"), ["warrior", "warrior"]))

    def test_empty_hands_spirits_and_keyed_alternatives(self):
        character = self.row["character"]
        for equipment in ({}, {"off-hand": character["equipment"]["main-hand"]},
                          {"main-hand": {"item": character["equipment"]["main-hand"]}}):
            self.check.validate(replace(self.row, ("character", "equipment"), equipment))
        spirit = dict(character["bag"][0], type="ingredient", subtype="spirit-fire", count=1)
        self.check.validate(replace(self.row, ("character", "bag"), [spirit]))
        for path, value in ((("character", "points"), {"smash": {"ability": "cyclone", "points": 1}}),
                            (("world", "mobs"), {"arbitrary": {"mob": "mismatch", "value": next(iter(self.row["world"]["mobs"].values()))}}),
                            (("world", "characters"), {"arbitrary": {"character": "mismatch", "position": [0, 1, 0], "respawn": [0, 1, 0]}})):
            self.check.validate(replace(self.row, path, value))
        # Referential closure, progression, generated geography and receipt lifecycle are not native admission.
        for path, value in ((("character", "spec"), "not-a-spec"),
                            (("character", "level"), 50), (("world", "lands"), {}),
                            (("world", "sites", "world-a/site/0,0/camp/0", "rewards"), {})):
            self.check.validate(replace(self.row, path, value))

    def test_room_length_mutation_uses_same_rejection_oracle(self):
        bad = replace(self.row, ("world", "sites", "world-a/site/0,0/camp/0", "room_levels"), [1])
        self.assertFalse(self.check.is_valid(bad))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "save-world.yaml"
            data = yaml.safe_load(path.read_text())
            data["slots"]["saved-site-room-levels"]["any_of"][1]["minimum_cardinality"] = 1
            path.write_text(yaml.safe_dump(data, sort_keys=False))
            mutant = json.loads(JsonSchemaGenerator(str(target / "pixlnd.yaml"), top_class="save-data",
                                                   preserve_names=True, not_closed=False).serialize())
            check = jsonschema.Draft201909Validator(mutant)
            check.validate(self.row)
            with self.assertRaises(AssertionError):
                self.assertFalse(check.is_valid(bad))

    def test_conditional_room_rule_mutation_is_native_no_effect(self):
        assert_room_rule(self, SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "save-world.yaml"
            data = yaml.safe_load(path.read_text())
            rule = data["classes"]["saved-site"]["rules"][0]
            rule["postconditions"]["slot_conditions"]["saved-site-room-levels"]["minimum_cardinality"] = 1
            path.write_text(yaml.safe_dump(data, sort_keys=False))
            with self.assertRaises(AssertionError):
                assert_room_rule(self, SchemaView(str(target / "pixlnd.yaml")))
            mutant = json.loads(JsonSchemaGenerator(str(target / "pixlnd.yaml"), top_class="save-data",
                                                   preserve_names=True, not_closed=False).serialize())
            self.assertEqual(mutant, self.schema)

    def test_site_keyed_body_identity_limits(self):
        view = SchemaView(str(SCHEMA))
        for slot in (view.get_slot("saved-site-id"), view.induced_slot("saved-site-id", "saved-site")):
            self.assertEqual((slot.alias, slot.required, slot.key), ("id", True, True))
        path = ("world", "sites", "world-a/site/0,0/camp/0")
        self.check.validate(replace(self.row, (*path, "id"), None, delete=True))
        self.check.validate(replace(self.row, (*path, "id"), "different-site"))
        standalone = self.check.evolve(schema={"$ref": "#/$defs/saved-site"})
        site = self.row["world"]["sites"][path[-1]]
        standalone.validate(site)
        with self.assertRaises(jsonschema.ValidationError):
            standalone.validate({key: value for key, value in site.items() if key != "id"})

    def test_key_required_mutation_is_native_no_effect(self):
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "save-world.yaml"
            data = yaml.safe_load(path.read_text())
            self.assertTrue(data["slots"]["saved-site-id"]["required"])
            data["slots"]["saved-site-id"]["required"] = False
            path.write_text(yaml.safe_dump(data, sort_keys=False))
            view = SchemaView(str(target / "pixlnd.yaml"))
            self.assertFalse(view.get_slot("saved-site-id").required)
            self.assertTrue(view.get_slot("saved-site-id").key)
            mutant = json.loads(JsonSchemaGenerator(str(target / "pixlnd.yaml"), top_class="save-data",
                                                   preserve_names=True, not_closed=False).serialize())
            self.assertEqual(mutant, self.schema)


if __name__ == "__main__":
    unittest.main()
