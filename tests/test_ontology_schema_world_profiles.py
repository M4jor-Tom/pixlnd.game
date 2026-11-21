"""Boss, rubble trap and furnishing profile world schema tests."""
import unittest

import jsonschema
import yaml
from linkml_runtime.utils.schemaview import SchemaView
from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import catalog, validate, validator


class LogicalWorldTests(unittest.TestCase):
    def test_boss_special_profiles(self):
        from ontology_source_contracts import assert_declared_root

        anchor = "../domain/encounter-contracts.md#boss-specials-and-breakable-rubble"
        shared = {"assignment-probability": 0.5, "warning-seconds": 1.2,
                  "first-ready-after-engagement-seconds": 3,
                  "cooldown-after-completion-or-cancellation-seconds": 10,
                  "recovery-within-cooldown-seconds": 0.8}
        concepts = {"start-max-horizontal-distance-blocks", "start-max-feet-height-difference-blocks",
                    "direct-damage-multiplier"}
        profiles = [
            ("boss-stomp-profile", {"start-max-horizontal-distance-blocks": 4,
                                    "start-max-feet-height-difference-blocks": 2,
                                    "direct-damage-multiplier": 1},
             {"strike-radius-blocks": 4, "victim-min-feet-above-floor-blocks": 0,
              "victim-max-feet-above-floor-blocks": 1}),
            ("boss-charge-profile", {"start-max-horizontal-distance-blocks": 10,
                                     "start-max-feet-height-difference-blocks": 1,
                                     "direct-damage-multiplier": 1.25},
             {"start-exclusive-min-horizontal-distance-blocks": 4, "warning-lane-width-blocks": 2,
              "speed-blocks-per-second": 12, "swept-capsule-radius-blocks": 1}),
        ]
        view = SchemaView(str(SCHEMA))
        # Guard real declarations before generating: missing top_class is not admission.
        for owner, refined, local in profiles:
            assert_declared_root(owner, set(shared) | concepts | set(local),
                                 set(shared) | concepts | set(local), view=view)
        raw = yaml.safe_load((SCHEMA.parent / "world.yaml").read_text())["classes"]
        base = raw["boss-special-profile"]
        self.assertEqual(set(base["attributes"]), set(shared) | concepts)
        self.assertFalse(base.get("slots") or base.get("is_a") or base.get("mixins"))
        for field in concepts:
            self.assertNotIn("minimum_value", base["attributes"][field])
            self.assertNotIn("maximum_value", base["attributes"][field])
        for owner, refined, local in profiles:
            declaration = raw[owner]
            self.assertEqual(declaration["is_a"], "boss-special-profile")
            self.assertEqual(set(declaration["attributes"]), set(local))
            self.assertEqual(set(declaration["slot_usage"]), concepts)
            self.assertFalse(declaration.get("slots") or declaration.get("mixins"))
            for field, value in refined.items():
                self.assertEqual(declaration["slot_usage"][field],
                                 {"minimum_value": value, "maximum_value": value})
            row = dict(shared, **refined, **local)
            validate(owner, row)
            slots = view.class_induced_slots(owner)
            self.assertEqual(len(slots), len(row))
            self.assertEqual({slot.name for slot in slots}, set(row))
            self.assertEqual({slot.alias for slot in slots}, set(row))
            schema = validator(owner).schema
            definition = schema["$defs"][owner]
            self.assertEqual(len(definition["required"]), len(row))
            for field, value in row.items():
                with self.subTest(owner=owner, field=field):
                    verify_boss_field(self, view, raw, owner, field, value, row, shared, concepts, anchor, definition)
            for bad in (None, [], [row], 0, False, "profile", {owner: row}):
                with self.subTest(owner=owner, root=bad), self.assertRaises(jsonschema.ValidationError):
                    validate(owner, bad)
            for field in ("id", "special", "target", "clear-sight", "friendly-fire", "crit", "capsule-height-blocks"):
                errors = list(validator(owner).iter_errors(dict(row, **{field: True})))
                self.assertEqual([error.validator for error in errors], ["additionalProperties"])
        for owner in ("boss-special-profile", "boss-stomp-profile", "boss-charge-profile"):
            self.assertEqual(str(view.get_class(owner).class_uri), "pixlnd:" + owner)
            self.assertIn(anchor, view.get_class(owner).see_also)
        verify_boss_descriptions(self, raw, base)

    def test_rubble_trap_profiles(self):
        from ontology_source_contracts import assert_declared_root

        rubble_anchor = "../domain/encounter-contracts.md#boss-specials-and-breakable-rubble"
        trap_anchor = "../domain/encounter-contracts.md#spike-traps-and-furnishing-contents"
        geometry_anchor = "../domain/encounter-contracts.md#geometry-and-occupancy"
        profiles = [
            ("rubble-profile", rubble_anchor,
             {"count-per-boss-arena": 8, "cube-edge-blocks": 1, "material": "stone",
              "restoration-delay-world-hours": 72, "breakable": True}),
            ("spike-trap-profile", trap_anchor,
             {"count-per-ruins-site": 2, "footprint-width-blocks": 2, "footprint-depth-blocks": 2,
              "trigger-min-feet-above-floor-blocks": 0, "trigger-max-feet-above-floor-blocks": 1,
              "warning-seconds": 0.8, "active-seconds": 0.25, "cooldown-seconds": 2,
              "physical-damage": 30}),
        ]
        view = SchemaView(str(SCHEMA))
        for owner, anchor, row in profiles:
            assert_declared_root(owner, set(row), set(row), view=view)
        raw = yaml.safe_load((SCHEMA.parent / "world.yaml").read_text())
        rubble = raw["classes"]["rubble-profile"]
        self.assertEqual(rubble["slots"], ["block-breakable"])
        self.assertEqual(rubble["slot_usage"], {"block-breakable": {
            "required": True, "equals_expression": "True", "see_also": [rubble_anchor]}})
        global_breakable = raw["slots"]["block-breakable"]
        self.assertEqual((global_breakable["alias"], global_breakable["range"], global_breakable["slot_uri"]),
                         ("breakable", "boolean", "pixlnd:block/breakable"))
        self.assertNotIn("equals_expression", global_breakable)
        self.assertIsNone(view.induced_slot("block-breakable", "block").equals_expression)
        for owner, anchor, row in profiles:
            declaration = raw["classes"][owner]
            self.assertEqual(declaration["class_uri"], "pixlnd:" + owner)
            self.assertIn(anchor, declaration["see_also"])
            self.assertEqual(str(view.get_class(owner).class_uri), "pixlnd:" + owner)
            self.assertIn(anchor, view.get_class(owner).see_also)
            self.assertFalse(declaration.get("is_a") or declaration.get("mixins"))
            self.assertEqual(set(declaration["attributes"]), set(row) - {"breakable"})
            if owner == "spike-trap-profile":
                self.assertFalse(declaration.get("slots") or declaration.get("slot_usage"))
                self.assertIn(geometry_anchor, declaration["see_also"])
            slots = view.class_induced_slots(owner)
            self.assertEqual(len(slots), len(row))
            self.assertEqual({slot.alias for slot in slots}, set(row))
            definition = validator(owner).schema["$defs"][owner]
            self.assertEqual(len(definition["required"]), len(row))
            validate(owner, row)
            for field, value in row.items():
                with self.subTest(owner=owner, field=field):
                    verify_rubble_trap_field(self, view, owner, field, value, row, anchor, definition, declaration)
            for bad in (None, [], [row], 0, False, "profile", {owner: row}):
                with self.subTest(owner=owner, root=bad), self.assertRaises(jsonschema.ValidationError):
                    validate(owner, bad)
            for field in ("id", "site-id", "restore-at", "broken", "phase", "remainder", "hit-set",
                          "players-only", "defence-policy", "safe-lane-width-blocks", "boss-damage-multiplier"):
                errors = list(validator(owner).iter_errors(dict(row, **{field: True})))
                self.assertEqual([error.validator for error in errors], ["additionalProperties"])
        for owner, field, text in (
            ("rubble-profile", "count-per-boss-arena", "per boss arena"),
            ("rubble-profile", "cube-edge-blocks", "cube"),
            ("rubble-profile", "material", "logical material token"),
            ("rubble-profile", "restoration-delay-world-hours", "world-clock hours"),
            ("spike-trap-profile", "count-per-ruins-site", "per ruins site"),
            ("spike-trap-profile", "footprint-width-blocks", "closed"),
            ("spike-trap-profile", "footprint-depth-blocks", "closed"),
            ("spike-trap-profile", "trigger-min-feet-above-floor-blocks", "inclusive"),
            ("spike-trap-profile", "trigger-max-feet-above-floor-blocks", "inclusive"),
            ("spike-trap-profile", "warning-seconds", "simulation seconds"),
            ("spike-trap-profile", "active-seconds", "simulation seconds"),
            ("spike-trap-profile", "cooldown-seconds", "simulation seconds"),
            ("spike-trap-profile", "physical-damage", "physical damage"),
        ):
            self.assertIn(text, raw["classes"][owner]["attributes"][field]["description"])

    def test_furnishing_profiles(self):
        from ontology_source_contracts import assert_declared_root

        anchor = "../domain/encounter-contracts.md#spike-traps-and-furnishing-contents"
        item_anchor = "../domain/3_Classes.md#item"
        rarity_anchor = "../instances/rarities.json#common"
        shared = {"armor": 0, "minimum-room-guard-level": 1}
        concepts = {"count-per-ruins-room", "full-health"}
        profiles = [
            ("vase-profile", {"count-per-ruins-room": 2, "full-health": 10},
             {"copper-base": 1, "copper-per-room-guard-level": 2}),
            ("table-profile", {"count-per-ruins-room": 1, "full-health": 20},
             {"glass-flask-count-per-renewal": 1, "life-potion-count-per-renewal": 1,
              "life-potion-rarity-index": 0, "life-potion-power-spread": 0}),
        ]
        view = SchemaView(str(SCHEMA))
        for owner, refined, local in profiles:
            fields = set(shared) | concepts | set(local)
            assert_declared_root(owner, fields, fields, view=view)
        raw = yaml.safe_load((SCHEMA.parent / "world.yaml").read_text())["classes"]
        base = raw["furnishing-profile"]
        self.assertEqual(set(base["attributes"]), set(shared) | concepts)
        self.assertFalse(base.get("slots") or base.get("is_a") or base.get("mixins") or base.get("slot_usage"))
        for field in concepts:
            self.assertFalse({"equals_number", "minimum_value", "maximum_value"} & set(base["attributes"][field]))
        for owner in ("furnishing-profile", "vase-profile", "table-profile"):
            self.assertEqual(raw[owner]["class_uri"], "pixlnd:" + owner)
            self.assertEqual(str(view.get_class(owner).class_uri), "pixlnd:" + owner)
            self.assertEqual(raw[owner]["see_also"], [anchor])
            self.assertEqual(view.get_class(owner).see_also, [anchor])
            self.assertEqual(view.get_class(owner).description, raw[owner]["description"])
        for owner, refined, local in profiles:
            declaration = raw[owner]
            self.assertEqual(declaration["is_a"], "furnishing-profile")
            self.assertEqual(set(declaration["attributes"]), set(local))
            self.assertEqual(declaration["slot_usage"], {
                "count-per-ruins-room": {"equals_number": refined["count-per-ruins-room"]},
                "full-health": {"minimum_value": refined["full-health"], "maximum_value": refined["full-health"]},
            })
            self.assertFalse(declaration.get("slots") or declaration.get("mixins"))
            row = dict(shared, **refined, **local)
            slots = view.class_induced_slots(owner)
            self.assertEqual(len(slots), len(row))
            self.assertEqual({slot.name for slot in slots}, set(row))
            self.assertEqual({slot.alias for slot in slots}, set(row))
            schema = validator(owner).schema
            assert_declared_root(owner, set(row), set(row), view=view, schema=schema)
            definition = schema["$defs"][owner]
            self.assertEqual(set(definition["properties"]), set(row))
            self.assertEqual(set(definition["required"]), set(row))
            self.assertEqual(len(definition["required"]), len(row))
            self.assertIs(definition["additionalProperties"], False)
            self.assertEqual(definition["description"], declaration["description"])
            validate(owner, row)
            for field, value in row.items():
                with self.subTest(owner=owner, field=field):
                    verify_furnishing_field(self, view, raw, owner, field, value, row, shared, concepts, anchor, rarity_anchor, item_anchor, definition, declaration)
            for bad in (None, [], [row], 0, False, "profile", {owner: row}):
                with self.subTest(owner=owner, root=bad), self.assertRaises(jsonschema.ValidationError):
                    validate(owner, bad)
            for field in ("id", "hp", "room_levels", "source-level", "boss-level", "item-power", "flask-power",
                          "contents", "payload", "delivered", "cycle", "direct-only", "coin-rng", "refill"):
                errors = list(validator(owner).iter_errors(dict(row, **{field: True})))
                self.assertEqual([error.validator for error in errors], ["additionalProperties"])
        for owner, field, fragments in (
            ("furnishing-profile", "count-per-ruins-room", ("per ruins room",)),
            ("furnishing-profile", "full-health", ("Initial/full", "current damaged HP")),
            ("furnishing-profile", "armor", ("armor",)),
            ("furnishing-profile", "minimum-room-guard-level", ("saved room guard-pack level", "not an actual saved level")),
            ("vase-profile", "copper-base", ("1 + 2L", "stored room guard-pack level", "not boss level or item power")),
            ("vase-profile", "copper-per-room-guard-level", ("copper per room guard-pack level", "actual safe renewal")),
            ("table-profile", "glass-flask-count-per-renewal", ("one table", "per actual renewal", "no flask power")),
            ("table-profile", "life-potion-count-per-renewal", ("one table", "per actual renewal", "saved room guard-pack level")),
            ("table-profile", "life-potion-rarity-index", ("common",)),
            ("table-profile", "life-potion-power-spread", ("power points", "power(L)", "not a flask")),
        ):
            for text in fragments:
                self.assertIn(text, raw[owner]["attributes"][field]["description"])
        self.assertEqual(catalog("rarities")["common"]["index"], 0)


def verify_furnishing_field(self, view, raw, owner, field, value, row, shared, concepts, anchor, rarity_anchor, item_anchor, definition, declaration):
    scope = "furnishing-profile" if field in shared or field in concepts else owner
    authored = raw[scope]["attributes"][field]
    range_ = "double" if field in {"armor", "full-health"} else "integer"
    anchors = [anchor] + ([rarity_anchor] if field == "life-potion-rarity-index" else
                          [item_anchor] if field == "life-potion-power-spread" else [])
    uri = "pixlnd:" + scope + "/" + field
    slot = view.induced_slot(field, owner)
    self.assertEqual((authored["alias"], authored["range"], authored["required"]), (field, range_, True))
    self.assertEqual((authored["slot_uri"], authored["see_also"]), (uri, anchors))
    self.assertEqual((slot.alias, slot.range, slot.required), (field, range_, True))
    self.assertEqual((str(slot.slot_uri), slot.see_also), (uri, anchors))
    self.assertEqual(slot.description, authored["description"])
    self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined)
    self.assertIsNone(slot.ifabsent)
    self.assertFalse({"identifier", "key", "multivalued", "inlined", "ifabsent"} & set(authored))
    emitted = definition["properties"][field]
    self.assertEqual(emitted["type"], "number" if range_ == "double" else "integer")
    self.assertEqual(emitted["description"], authored["description"])
    self.assertNotIn("default", emitted)
    if range_ == "double":
        self.assertEqual((slot.minimum_value, slot.maximum_value), (value, value))
        self.assertIsNone(slot.equals_number)
        self.assertEqual((emitted["minimum"], emitted["maximum"]), (value, value))
        if field not in concepts:
            self.assertEqual((authored["minimum_value"], authored["maximum_value"]), (value, value))
    else:
        self.assertEqual((slot.equals_number, emitted["const"]), (value, value))
        if field not in concepts:
            self.assertEqual(authored["equals_number"], value)
    with self.assertRaises(jsonschema.ValidationError):
        validate(owner, {k: v for k, v in row.items() if k != field})
    for bad in (value - 1, value + 1, value + 0.5, str(value), True, False, None, [], {}, [value]):
        with self.subTest(bad=bad), self.assertRaises(jsonschema.ValidationError):
            validate(owner, dict(row, **{field: bad}))


def verify_rubble_trap_field(self, view, owner, field, value, row, anchor, definition, declaration):
    name = "block-breakable" if field == "breakable" else field
    slot = view.induced_slot(name, owner)
    range_ = ("boolean" if field == "breakable" else "string" if field == "material"
              else "integer" if field.startswith("count-per-") else "double")
    uri = "pixlnd:block/breakable" if field == "breakable" else "pixlnd:" + owner + "/" + field
    self.assertEqual((slot.alias, slot.range, slot.required), (field, range_, True))
    self.assertEqual(str(slot.slot_uri), uri)
    self.assertIn(anchor, slot.see_also)
    self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined)
    self.assertIsNone(slot.ifabsent)
    emitted = definition["properties"][field]
    self.assertEqual(emitted["type"], {"double": "number"}.get(range_, range_))
    self.assertNotIn("default", emitted)
    if field == "breakable":
        self.assertEqual(slot.equals_expression, "True")
        self.assertIsNone(slot.equals_number)
        self.assertIsNone(slot.equals_string)
        self.assertNotIn("const", emitted)
        self.assertNotIn("enum", emitted)
        # Known LinkML 1.12.1 omission, NOT logical permission for unbreakable rubble.
        validate(owner, dict(row, breakable=False))
        malformed = (0, 1, "true", "false", "True", "False", None, [], {}, [True])
    else:
        authored = declaration["attributes"][field]
        self.assertEqual((authored["alias"], authored["range"], authored["required"]),
                         (field, range_, True))
        self.assertEqual(authored["slot_uri"], uri)
        self.assertEqual(authored["see_also"], [anchor])
        malformed = rubble_value_facets(self, slot, emitted, authored, range_, value)
    with self.assertRaises(jsonschema.ValidationError):
        validate(owner, {k: v for k, v in row.items() if k != field})
    for bad in malformed:
        with self.subTest(bad=bad), self.assertRaises(jsonschema.ValidationError):
            validate(owner, dict(row, **{field: bad}))


def rubble_value_facets(self, slot, emitted, authored, range_, value):
    if range_ == "string":
        self.assertEqual((authored["equals_string"], slot.equals_string, emitted["const"]),
                         ("stone", "stone", "stone"))
        malformed = ("STONE", "solid", "rock-building", "6", "iron", 6, True, False, None, [], {})
    elif range_ == "integer":
        self.assertEqual((authored["equals_number"], slot.equals_number, emitted["const"]),
                         (value, value, value))
        malformed = (value - 1, value + 1, value + 0.5, str(value), True, False, None, [], {})
    else:
        self.assertEqual((authored["minimum_value"], authored["maximum_value"]), (value, value))
        self.assertEqual((slot.minimum_value, slot.maximum_value), (value, value))
        self.assertEqual((emitted["minimum"], emitted["maximum"]), (value, value))
        malformed = (value - 0.25, value + 0.25, str(value), True, False, None, [], {}, [value])
    return malformed


def verify_boss_field(self, view, raw, owner, field, value, row, shared, concepts, anchor, definition):
    slot = view.induced_slot(field, owner)
    scope = "boss-special-profile" if field in shared or field in concepts else owner
    authored = raw[scope]["attributes"][field]
    self.assertEqual((authored["alias"], authored["range"], authored["required"]),
                     (field, "double", True))
    self.assertEqual(authored["slot_uri"], "pixlnd:" + scope + "/" + field)
    self.assertEqual(authored["see_also"], [anchor])
    self.assertEqual((slot.alias, slot.range, slot.required), (field, "double", True))
    self.assertEqual(str(slot.slot_uri), "pixlnd:" + scope + "/" + field)
    self.assertIn(anchor, slot.see_also)
    self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined)
    self.assertIsNone(slot.ifabsent)
    self.assertIsNone(slot.equals_number)
    self.assertEqual((slot.minimum_value, slot.maximum_value), (value, value))
    if field not in concepts:
        self.assertEqual((authored["minimum_value"], authored["maximum_value"]), (value, value))
    emitted = definition["properties"][field]
    # Inspect facets without erasing legitimate native description metadata.
    self.assertEqual(emitted["type"], "number")
    self.assertEqual((emitted["minimum"], emitted["maximum"]), (value, value))
    self.assertEqual(emitted["description"], slot.description)
    self.assertNotIn("default", emitted)
    with self.assertRaises(jsonschema.ValidationError):
        validate(owner, {k: v for k, v in row.items() if k != field})
    for bad in (value - 0.25, value + 0.25, str(value), True, False, None, [], {}, [value]):
        with self.subTest(bad=bad), self.assertRaises(jsonschema.ValidationError):
            validate(owner, dict(row, **{field: bad}))


def verify_boss_descriptions(self, raw, base):
    descriptions = base["attributes"]
    for field, text in (("assignment-probability", "permanent"), ("warning-seconds", "simulation seconds"),
                        ("first-ready-after-engagement-seconds", "engagement"),
                        ("cooldown-after-completion-or-cancellation-seconds", "completion or cancellation"),
                        ("recovery-within-cooldown-seconds", "first"),
                        ("start-max-horizontal-distance-blocks", "inclusive"),
                        ("start-max-feet-height-difference-blocks", "inclusive"),
                        ("direct-damage-multiplier", "boss damage")):
        self.assertIn(text, descriptions[field]["description"])
    for field in ("strike-radius-blocks", "victim-min-feet-above-floor-blocks", "victim-max-feet-above-floor-blocks"):
        self.assertIn("inclusive", raw["boss-stomp-profile"]["attributes"][field]["description"])
    charge = raw["boss-charge-profile"]
    self.assertIn("exclusive", charge["attributes"]["start-exclusive-min-horizontal-distance-blocks"]["description"])
    self.assertIn("../domain/encounter-contracts.md#local-difficulty-and-boss-size", charge["see_also"])


if __name__ == "__main__":
    unittest.main()
