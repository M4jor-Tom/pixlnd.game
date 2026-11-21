"""Gear loot profile and shared reward world schema tests."""
import unittest

import jsonschema
import yaml
from linkml_runtime.utils.schemaview import SchemaView
from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import catalog, validate, validator


class LogicalWorldTests(unittest.TestCase):
    def test_gear_loot_profiles(self):
        from ontology_source_contracts import assert_declared_root

        ordinary = "ordinary-site-kill-loot-profile"
        boss = "guaranteed-boss-gear-profile"
        anchors = {ordinary: "../domain/encounter-contracts.md#ordinary-kill-loot",
                   boss: "../domain/encounter-contracts.md#guaranteed-boss-gear-and-spirits"}
        item_anchor = "../domain/3_Classes.md#item"
        pool_anchor = "../instances/generators.json#design.loot"
        class_anchor = "../domain/3_Classes.md#character-class"
        profiles = {
            ordinary: {"coin-probability": 0.6, "gear-probability": 0.2, "consumable-probability": 0.15,
                       "each-species-ingredient-probability": 0.5, "copper-base": 1,
                       "copper-per-enemy-level": 2, "gear-count-per-success": 1, "consumable-count-per-success": 1,
                       "power-offset-low": -1, "power-offset-zero": 0, "power-offset-high": 1,
                       "power-offset-low-relative-weight": 1, "power-offset-zero-relative-weight": 1,
                       "power-offset-high-relative-weight": 1, "minimum-item-power": 1, "maximum-item-power": 100},
            boss: {"additional-gear-count-per-boss": 1, "minimum-current-defeated-boss-level": 1,
                   "power-spread": 0, "upgrades": 0, "rarity-tier-increment": 1, "maximum-rarity-index": 4,
                   "minimum-item-power": 1, "maximum-item-power": 100, "weapon-relative-weight": 4,
                   "chest-relative-weight": 2, "gloves-relative-weight": 2, "boots-relative-weight": 2,
                   "shoulders-relative-weight": 2, "warrior-class-relative-weight": 1,
                   "ranger-class-relative-weight": 1, "mage-class-relative-weight": 1, "rogue-class-relative-weight": 1},
        }
        view = SchemaView(str(SCHEMA))
        for owner, row in profiles.items():
            # Missing top_class must fail before a permissive generated root can validate.
            assert_declared_root(owner, set(row), set(row), view=view)
        raw = yaml.safe_load((SCHEMA.parent / "world.yaml").read_text())["classes"]
        for owner, row in profiles.items():
            declaration = raw[owner]
            expected_anchors = [anchors[owner], "../domain/3_Classes.md#loot-rule", item_anchor, pool_anchor]
            self.assertEqual(declaration["see_also"], expected_anchors)
            self.assertEqual(view.get_class(owner).see_also, expected_anchors)
            self.assertEqual(declaration["class_uri"], "pixlnd:" + owner)
            self.assertEqual(str(view.get_class(owner).class_uri), "pixlnd:" + owner)
            self.assertEqual(view.get_class(owner).description, declaration["description"])
            self.assertFalse(declaration.get("is_a") or declaration.get("mixins") or
                             declaration.get("slots") or declaration.get("slot_usage"))
            self.assertEqual(set(declaration["attributes"]), set(row))
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
                verify_gear_loot_field(self, view, declaration, owner, field, value, row, anchors, item_anchor, pool_anchor, class_anchor, boss, definition)
            for bad in (None, [], [row], 0, False, "profile", {owner: row}):
                with self.subTest(owner=owner, root=bad), self.assertRaises(jsonschema.ValidationError):
                    validate(owner, bad)
            for field in ("id", "tier", "source-level", "enemy-level", "current-boss-level", "initial-boss-level",
                          "spirit-level", "hp", "item-power", "payload", "receipt", "cycle", "delivered",
                          "per-player", "replace-normal-rolls", "independent", "rng", "rarity-roll", "pool"):
                errors = list(validator(owner).iter_errors(dict(row, **{field: True})))
                self.assertEqual([error.validator for error in errors], ["additionalProperties"])
        for owner, fragments in (
            (ordinary, ("independent", "not mutually exclusive", "power(enemy level)", "first", "then", "clamp",
                        "each defined species ingredient", "kill XP", "enemy level", "not item power")),
            (boss, ("All seven", "additional", "current saved level", "not the initial spirit level",
                    "power(L)", "tier + 1", "legendary", "not a random rarity roll", "Reloads cannot reroll")),
        ):
            for text in fragments:
                self.assertIn(text, raw[owner]["description"])
        for field in ("power-offset-low", "power-offset-zero", "power-offset-high"):
            self.assertIn("integer power-point offset", raw[ordinary]["attributes"][field]["description"])
            self.assertIn("after conversion", raw[ordinary]["attributes"][field]["description"])
            self.assertIn("equal relative weight", raw[ordinary]["attributes"][field + "-relative-weight"]["description"])
        for field in ("weapon", "chest", "gloves", "boots", "shoulders"):
            self.assertIn("relative integer weight, not a percentage", raw[boss]["attributes"][field + "-relative-weight"]["description"])
        for name in ("warrior", "ranger", "mage", "rogue"):
            self.assertIn(name, catalog("classes"))
            self.assertIn("equal relative integer weight", raw[boss]["attributes"][name + "-class-relative-weight"]["description"])
        self.assertEqual(catalog("rarities")["legendary"]["index"], 4)

    def test_encounter_assignments_and_shared_reward_contract(self):
        from ontology_source_contracts import assert_declared_root

        assert_declared_root("encounter-assignment", {"role", "tier", "boss", "special", "spirit"}, {"role", "tier", "boss"})
        row = {"role": "mage", "tier": 3, "boss": True, "special": "charge", "spirit": "spirit-fire"}
        validate("encounter-assignment", row)
        for field, value in (("role", "any-class"), ("tier", 5), ("boss", 1), ("special", "fireball"), ("spirit", "sandstone"), ("special", None)):
            with self.subTest(field=field), self.assertRaises(jsonschema.ValidationError):
                validate("encounter-assignment", dict(row, **{field: value}))
        assignment = yaml.safe_load((SCHEMA.parent / "world.yaml").read_text())["classes"]["encounter-assignment"]
        self.assertEqual(assignment.get("exactly_one_of"), [
            {"slot_conditions": {"boss": {"equals_expression": "True"}, "special": {"value_presence": "PRESENT"}}},
            {"slot_conditions": {"boss": {"equals_expression": "False"}, "special": {"value_presence": "ABSENT"}}},
        ])
        assignment_view = SchemaView(str(SCHEMA))
        for declaration in (assignment_view.get_class("encounter-assignment"),
                            assignment_view.induced_class("encounter-assignment")):
            verify_assignment_declaration(self, declaration)
        for field, range_ in (("role", "string"), ("tier", "integer"), ("boss", "boolean"), ("special", None), ("spirit", None)):
            verify_assignment_slot(self, assignment_view, field, range_)
        self.assertEqual(assignment_view.induced_slot("role", "encounter-assignment").equals_string_in, ["melee", "ranged", "mage"])
        tier_slot = assignment_view.induced_slot("tier", "encounter-assignment")
        self.assertEqual((tier_slot.minimum_value, tier_slot.maximum_value), (0, 4))
        for field, range_, values in (("special", "string", ["stomp", "charge"]),
                                      ("spirit", "material", ["spirit-fire", "spirit-unholy", "spirit-ice", "spirit-wind"])):
            alternatives = assignment_view.induced_slot(field, "encounter-assignment").exactly_one_of
            self.assertEqual(len(alternatives), 1)
            self.assertEqual((alternatives[0].range, alternatives[0].equals_string_in), (range_, values))
        native_assignment = validator("encounter-assignment").schema["$defs"]["encounter-assignment"]
        self.assertEqual(native_assignment["properties"]["boss"]["type"], "boolean")
        self.assertEqual(native_assignment["oneOf"], [
            {"properties": {"boss": {}, "special": {}}, "required": ["special"]},
            {"properties": {"boss": {}, "special": {}}, "not": {"required": ["special"]}},
        ])
        # LinkML 1.12.1 omits equals_expression: native admission is NOT boss/special policy enforcement.
        # In particular true+omitted and false+stomp/charge remain admitted despite the exact declaration.
        for boss in (True, False):
            verify_assignment_boss_special(self, row, boss)
        for boss in (None, 0, 1, "true", "false", "True", "False", [], {}):
            with self.subTest(boss=boss), self.assertRaises(jsonschema.ValidationError):
                validate("encounter-assignment", dict(row, boss=boss))
        for field in ("role", "tier", "boss"):
            with self.subTest(missing=field), self.assertRaises(jsonschema.ValidationError):
                validate("encounter-assignment", {k: v for k, v in row.items() if k != field})
        with self.assertRaises(jsonschema.ValidationError):
            validate("encounter-assignment", dict(row, extra=True))
        package = {"tier": 0, "gear-count": 1, "gear-rarity-index": 1, "gear-upgrades": 0, "copper": 20,
                   "life-potion-count": 1, "life-potion-rarity-index": 0,
                   "gem-count": 1, "gem": "emerald", "source-level": 1}
        self.assertEqual(set(package), {"tier", "gear-count", "gear-rarity-index", "gear-upgrades", "copper",
                                       "life-potion-count", "life-potion-rarity-index", "gem-count", "gem", "source-level"})
        assert_declared_root("encounter-shared-package", set(package) | {"selected-class"}, set(package))
        validate("encounter-shared-package", package)
        view = SchemaView(str(SCHEMA))
        for field in ("life-potion-rarity-index", "gear-upgrades"):
            verify_shared_package_pinned_zero(self, view, package, field)
        self.assertIn("../instances/rarities.json#common", view.induced_slot("life-potion-rarity-index", "encounter-shared-package").see_also)
        for bad in (None, [], [package], 0, False, "package", {"package": package}):
            with self.subTest(root=bad), self.assertRaises(jsonschema.ValidationError):
                validate("encounter-shared-package", bad)
        for field in ("shared", "per-player", "additional", "spread", "power", "default-class"):
            with self.subTest(unknown=field), self.assertRaises(jsonschema.ValidationError):
                validate("encounter-shared-package", dict(package, **{field: True}))
        rules = view.get_class("encounter-shared-package").rules
        self.assertEqual(len(rules), 4)
        for tier, gem in enumerate(("emerald", "sapphire", "ruby", "diamond")):
            verify_shared_package_rule(self, rules, tier, gem)
        for field, value in (("tier", 4), ("gear-count", 2), ("gear-rarity-index", 5), ("copper", 0),
                             ("life-potion-count", 0), ("gem-count", 5), ("source-level", 0), ("gem", {})):
            with self.subTest(field=field), self.assertRaises(jsonschema.ValidationError):
                validate("encounter-shared-package", dict(package, **{field: value}))
        for tier, gem in enumerate(("emerald", "sapphire", "ruby", "diamond")):
            verify_shared_package_tier(self, package, tier, gem)


def verify_shared_package_tier(self, package, tier, gem):
    good = dict(package, tier=tier, gem=gem, **{"gear-rarity-index": tier + 1,
                "gem-count": tier + 1, "copper": 20 * (tier + 1)})
    validate("encounter-shared-package", good)
    validate("encounter-shared-package", dict(good, **{"selected-class": "warrior"}))
    for field, value in (("copper", 20 if tier else 80), ("gem", "diamond" if tier != 3 else "emerald")):
        with self.subTest(tier=tier, field=field), self.assertRaises(jsonschema.ValidationError):
            validate("encounter-shared-package", dict(good, **{field: value}))


def verify_shared_package_rule(self, rules, tier, gem):
    rule = rules[tier]
    self.assertEqual(rule.preconditions.slot_conditions["tier"].equals_number, tier)
    post = rule.postconditions.slot_conditions
    self.assertEqual(post["copper"].equals_number, 20 * (tier + 1))
    self.assertEqual(post["gear-rarity-index"].equals_number, tier + 1)
    self.assertEqual(post["gem-count"].equals_number, tier + 1)
    self.assertEqual(post["gem"].equals_string, gem)


def verify_shared_package_pinned_zero(self, view, package, field):
    slot = view.induced_slot(field, "encounter-shared-package")
    self.assertEqual((slot.alias, slot.range, slot.equals_number), (field, "integer", 0))
    self.assertTrue(slot.required)
    self.assertEqual(str(slot.slot_uri), "pixlnd:encounter-shared-package/" + field)
    self.assertIn("../domain/encounter-contracts.md#shared-mission-packages-and-supplier-shops", slot.see_also)
    with self.subTest(missing=field), self.assertRaises(jsonschema.ValidationError):
        validate("encounter-shared-package", {k: v for k, v in package.items() if k != field})
    for value in (1, -1, "0", False, True, 0.5, [], {}, None):
        with self.subTest(field=field, value=value), self.assertRaises(jsonschema.ValidationError):
            validate("encounter-shared-package", dict(package, **{field: value}))


def verify_assignment_slot(self, assignment_view, field, range_):
    slot = assignment_view.induced_slot(field, "encounter-assignment")
    expected_range = "string" if field in {"special", "spirit"} else range_
    if field in {"special", "spirit"}:
        authored = yaml.safe_load((SCHEMA.parent / "world.yaml").read_text())
        declaration = authored["classes"]["encounter-assignment"]["attributes"][field]
        self.assertNotIn("range", declaration)
    self.assertEqual((slot.alias, slot.range), (field, expected_range))
    self.assertEqual(str(slot.slot_uri), "pixlnd:encounter-assignment/" + field)
    self.assertEqual(bool(slot.required), field in {"role", "tier", "boss"})
    self.assertFalse(slot.multivalued or slot.key or slot.identifier)


def verify_assignment_declaration(self, declaration):
    self.assertEqual(str(declaration.class_uri), "pixlnd:encounter-assignment")
    self.assertEqual(declaration.see_also, ["../domain/encounter-contracts.md#boss-specials-and-breakable-rubble"])
    self.assertEqual(len(declaration.exactly_one_of), 2)
    for branch, expression, presence in zip(declaration.exactly_one_of, ("True", "False"), ("PRESENT", "ABSENT")):
        self.assertEqual(set(branch.slot_conditions), {"boss", "special"})
        boss = branch.slot_conditions["boss"]
        self.assertEqual(boss.equals_expression, expression)
        self.assertIsNone(boss.equals_number)
        self.assertIsNone(boss.equals_string)
        self.assertEqual(str(branch.slot_conditions["special"].value_presence), presence)


def verify_gear_loot_field(self, view, declaration, owner, field, value, row, anchors, item_anchor, pool_anchor, class_anchor, boss, definition):
    with self.subTest(owner=owner, field=field):
        authored = declaration["attributes"][field]
        slot = view.induced_slot(field, owner)
        probability = field.endswith("-probability")
        range_ = "double" if probability else "integer"
        uri = "pixlnd:" + owner + "/" + field
        sources = [anchors[owner]]
        if "power" in field:
            sources.append(item_anchor)
        if field.endswith("class-relative-weight"):
            sources.append(class_anchor)
        elif field.endswith("-relative-weight") and owner == boss:
            sources.append(pool_anchor)
        if field == "maximum-rarity-index":
            sources.append("../instances/rarities.json#legendary")
        self.assertEqual((authored["alias"], authored["range"], authored["required"]), (field, range_, True))
        self.assertEqual((authored["slot_uri"], authored["see_also"]), (uri, sources))
        self.assertEqual((slot.alias, slot.range, slot.required), (field, range_, True))
        self.assertEqual((str(slot.slot_uri), slot.see_also), (uri, sources))
        self.assertEqual(slot.description, authored["description"])
        self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined)
        self.assertIsNone(slot.ifabsent)
        self.assertFalse({"identifier", "key", "multivalued", "inlined", "ifabsent"} & set(authored))
        emitted = definition["properties"][field]
        self.assertEqual(emitted["type"], "number" if probability else "integer")
        self.assertEqual(emitted["description"], authored["description"])
        self.assertNotIn("default", emitted)
        if probability:
            self.assertEqual((authored["minimum_value"], authored["maximum_value"]), (value, value))
            self.assertEqual((slot.minimum_value, slot.maximum_value), (value, value))
            self.assertIsNone(slot.equals_number)
            self.assertEqual((emitted["minimum"], emitted["maximum"]), (value, value))
            self.assertIn("independent", authored["description"])
        else:
            self.assertEqual((authored["equals_number"], slot.equals_number, emitted["const"]), (value, value, value))
        with self.assertRaises(jsonschema.ValidationError):
            validate(owner, {k: v for k, v in row.items() if k != field})
        for bad in (value - 1, value + 1, value + 0.5, str(value), True, False, None, [], {}, [value]):
            with self.subTest(bad=bad), self.assertRaises(jsonschema.ValidationError):
                validate(owner, dict(row, **{field: bad}))


def verify_assignment_boss_special(self, row, boss):
    for supplied in ({}, {"special": "stomp"}, {"special": "charge"}):
        validate("encounter-assignment", {"role": "mage", "tier": 3, "boss": boss, **supplied})
    for special in (None, "fireball", True, 1, [], {}):
        with self.subTest(boss=boss, special=special), self.assertRaises(jsonschema.ValidationError):
            validate("encounter-assignment", dict(row, boss=boss, special=special))


if __name__ == "__main__":
    unittest.main()
