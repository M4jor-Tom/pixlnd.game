"""Literal logical Item/inventory contracts; native admission is not gameplay validity."""
import ast
import unittest
from copy import deepcopy

import jsonschema
from linkml_runtime.utils.eval_utils import eval_expr
from linkml_runtime.utils.schemaview import SchemaView
from ontology_source_contracts import assert_declared_root
from test_ontology_schema import SCHEMA, generated, load_module
from test_ontology_schema_authoring import catalog, validator

ONE_HAND = ["sword", "axe", "mace", "dagger", "fist", "bracelet"]
METALS = ["iron", "copper", "gold", "silver", "bronze"]
# alias, range, required, multivalued, inlined, inlined_as_list, max cardinality
FIELDS = {
    "id": ("id", "string", True, False, False, False, None),
    "item-type": ("type", "item-type", True, False, False, False, None),
    "item-sub-type": ("sub-type", "item-type", True, False, False, False, None),
    "item-modifier": ("modifier", "uint32", True, False, False, False, None),
    "item-minus-modifier": ("minus-modifier", "uint32", True, False, False, False, None),
    "item-rarity": ("rarity", "rarity", True, False, False, False, None),
    "item-material": ("material", "material", True, False, False, False, None),
    "item-flags": ("flags", "u8", True, False, False, False, None),
    "item-level": ("level", "i16", True, False, False, False, None),
    "item-upgrade-count": ("upgrade-count", "uint32", True, False, False, False, None),
    "item-upgrades": ("upgrades", "item-upgrade", True, True, True, True, 32),
    "item-name": ("name", "string", False, False, False, False, None),
    "item-land": ("land", "land", False, False, False, False, None),
    "item-plus": ("plus", "boolean", False, False, False, False, None),
    "item-weapon-type": ("weapon-type", "weapon-type", False, False, False, False, None),
    "item-upgrade-x": ("x", "i8", True, False, False, False, None),
    "item-upgrade-y": ("y", "i8", True, False, False, False, None),
    "item-upgrade-z": ("z", "i8", True, False, False, False, None),
    "item-upgrade-material": ("material", "material", True, False, False, False, None),
    "item-upgrade-level": ("level", "integer", True, False, False, False, None),
    "inventory-entries": ("entries", "inventory-entry", True, True, True, True, None),
    "inventory-coins": ("coins", "uint32", True, False, False, False, None),
    "inventory-equipment": ("equipment", "equipment-assignment", True, True, True, True, 12),
    "inventory-entry-item": ("item", "item", True, False, True, False, None),
    "inventory-entry-count": ("count", "integer", True, False, False, False, None),
    "equipment-assignment-slot": ("slot", "equipment-slot", True, False, False, False, None),
    "equipment-assignment-item": ("item", "item", True, False, True, False, None),
    "player-character-inventory": ("inventory", "inventory", True, False, True, False, None),
}
OWNERS = {
    "item": ["id", "item-type", "item-sub-type", "item-modifier", "item-minus-modifier",
             "item-rarity", "item-material", "item-flags", "item-level", "item-upgrade-count",
             "item-upgrades", "item-name", "item-land", "item-plus", "item-weapon-type"],
    "item-upgrade": ["item-upgrade-x", "item-upgrade-y", "item-upgrade-z",
                     "item-upgrade-material", "item-upgrade-level"],
    "inventory": ["id", "inventory-entries", "inventory-coins", "inventory-equipment"],
    "inventory-entry": ["inventory-entry-item", "inventory-entry-count"],
    "equipment-assignment": ["equipment-assignment-slot", "equipment-assignment-item"],
}
BOUNDS = {"item-level": (1, 100), "item-upgrade-count": (None, 32),
          "inventory-entry-count": (1, None)}
WIDTHS = {"uint32": (0, 4294967295), "i8": (-128, 127),
          "i16": (-32768, 32767), "u8": (0, 255)}
RULES = [
    {"preconditions": {"slot_conditions": {"item-type": {"alias": "type", "equals_string": "weapon"}}},
     "postconditions": {"slot_conditions": {"item-weapon-type": {"alias": "weapon-type", "value_presence": "PRESENT"}}},
     "elseconditions": {"slot_conditions": {"item-weapon-type": {"alias": "weapon-type", "value_presence": "ABSENT"}}}},
    {"preconditions": {"slot_conditions": {"item-weapon-type": {"alias": "weapon-type", "equals_string_in": ONE_HAND}}},
     "postconditions": {"slot_conditions": {"item-upgrade-count": {"alias": "upgrade-count", "maximum_value": 16}}}},
]
BOOLEAN = [
    {"any_of": [
        {"none_of": [{"slot_conditions": {"item-weapon-type": {"alias": "weapon-type", "equals_string_in": ONE_HAND}}}]},
        {"slot_conditions": {"item-upgrades": {"alias": "upgrades", "multivalued": True, "maximum_cardinality": 16}}}]},
    # No wood cubes OR (weapon AND wood concrete material). Nonweapons are NOT exempt.
    {"any_of": [
        {"slot_conditions": {"item-upgrades": {"alias": "upgrades", "multivalued": True, "all_members": {
            "range_expression": {"slot_conditions": {"item-upgrade-material": {"alias": "material", "none_of": [{"equals_string": "wood"}]}}}}}}},
        {"slot_conditions": {"item-type": {"alias": "type", "equals_string": "weapon"},
                             "item-material": {"alias": "material", "equals_string_in": ["wood"]}}}]},
    {"any_of": [
        {"slot_conditions": {"item-upgrades": {"alias": "upgrades", "multivalued": True, "all_members": {
            "range_expression": {"slot_conditions": {"item-upgrade-material": {"alias": "material", "none_of": [{"equals_string": "iron"}]}}}}}}},
        {"slot_conditions": {"item-type": {"alias": "type", "equals_string": "weapon"},
                             "item-material": {"alias": "material", "equals_string_in": METALS}}}]},
]


def modules():
    return {name: load_module(SCHEMA.parent / (name + ".yaml"))
            for name in ("items", "identity", "entities", "relations")}


def raw_slot(data, owner, name):
    slots = {k: v for module in data.values() for k, v in module["slots"].items()}
    local = data["items"]["classes"].get(owner, {}).get("slot_usage", {}).get(name, {})
    return dict(slots[name], **local)


def raw_facets(slot):
    return (slot.get("alias"), slot.get("range"), bool(slot.get("required")),
            bool(slot.get("multivalued")), bool(slot.get("inlined")),
            bool(slot.get("inlined_as_list")), slot.get("maximum_cardinality"))


def assert_raw_fields(test, data):
    for owner, names in OWNERS.items():
        test.assertEqual(set(data["items"]["classes"][owner]["slots"]), set(names))
        for name in names:
            slot = raw_slot(data, owner, name)
            test.assertEqual(raw_facets(slot), FIELDS[name], (owner, name))
            test.assertIsNone(slot.get("minimum_cardinality"), name)
            test.assertIsNone(slot.get("ifabsent"), name)
            test.assertEqual((slot.get("minimum_value"), slot.get("maximum_value")),
                             BOUNDS.get(name, (None, None)), name)
    slot = data["entities"]["slots"]["player-character-inventory"]
    test.assertEqual(raw_facets(slot), FIELDS["player-character-inventory"])
    test.assertIn("player-character-inventory", data["entities"]["classes"]["player-character"]["slots"])
    for name, bounds in WIDTHS.items():
        scalar = data["identity"]["types"][name]
        test.assertEqual((scalar["typeof"], scalar["minimum_value"], scalar["maximum_value"]),
                         ("integer", *bounds))
    test.assertEqual(data["items"]["classes"]["equipment-assignment"]["unique_keys"],
                     {"slot": {"unique_key_slots": ["equipment-assignment-slot"]}})
    test.assertEqual(data["items"]["slots"]["item-name"]["readonly"], "true")
    test.assertIs(data["identity"]["slots"]["id"]["identifier"], True)
    test.assertEqual(data["identity"]["slots"]["id"]["slot_uri"], "pixlnd:id")
    for name in ("item-land", "item-plus"):
        test.assertIs(data["items"]["slots"][name]["required"], True)
    holds = data["relations"]["slots"]["holds"]
    test.assertEqual((holds["domain"], holds["range"], holds["annotations"]["association-class"]),
                     ("inventory", "item", "inventory-entry"))
    test.assertEqual((holds["required"], holds["multivalued"], holds["minimum_cardinality"]), (True, True, 1))


def assert_raw_predicates(test, data):
    item = data["items"]["classes"]["item"]
    test.assertEqual(item["rules"], RULES)
    test.assertEqual(item["all_of"], BOOLEAN)
    count = data["items"]["slots"]["item-upgrade-count"]
    test.assertEqual(count["equals_expression"], "len({upgrades})")
    test.assertEqual((count["alias"], count["slot_uri"], count["range"], count["required"], count["maximum_value"]),
                     ("upgrade-count", "pixlnd:item/upgrade-count", "uint32", True, 32))
    link = data["items"]["slots"]["item-weapon-type"]
    test.assertEqual(link["exactly_one_of"], [{"range": "weapon-type"}])
    test.assertEqual((link["domain"], link["slot_uri"]), ("item", "pixlnd:item/weapon-type"))
    test.assertIn("agreeing with existing type/sub-type", link["description"])
    test.assertIn("../domain/3_Classes.md#item", link["see_also"])


def assert_raw(test, data):
    assert_raw_fields(test, data)
    assert_raw_predicates(test, data)


def assert_induced(test, view):
    for owner, names in OWNERS.items():
        test.assertEqual(set(view.class_slots(owner)), set(names))
        for name in names:
            slot = view.induced_slot(name, owner)
            facets = (slot.alias, slot.range, bool(slot.required), bool(slot.multivalued),
                      bool(slot.inlined), bool(slot.inlined_as_list), slot.maximum_cardinality)
            test.assertEqual(facets, FIELDS[name], (owner, name))
            test.assertIsNone(slot.minimum_cardinality)
            test.assertIsNone(slot.ifabsent)
            test.assertEqual((slot.minimum_value, slot.maximum_value), BOUNDS.get(name, (None, None)))
    test.assertEqual(view.induced_slot("item-name", "item").readonly, "true")
    test.assertEqual(view.induced_slot("item-upgrade-count", "item").equals_expression, "len({upgrades})")
    test.assertEqual(view.induced_slot("player-character-inventory", "player-character").range, "inventory")
    test.assertTrue(view.induced_slot("player-character-inventory", "player-character").inlined)
    test.assertTrue(view.induced_slot("id", "item").identifier)
    test.assertEqual(view.get_class("equipment-assignment").unique_keys["slot"].unique_key_slots,
                     ["equipment-assignment-slot"])
    test.assertEqual((view.get_slot("holds").domain, view.get_slot("holds").range), ("inventory", "item"))
    test.assertEqual(view.get_slot("holds").annotations["association-class"].value, "inventory-entry")
    test.assertNotIn("inventory-start", view.class_slots("inventory"))


def cube(material="iron"):
    return {"x": 0, "y": 0, "z": 0, "material": material, "level": 40}


def item(family=None, material="wood", n=0, cube_material="iron"):
    row = {"id": "example-item", "type": "formula", "sub-type": "formula", "modifier": 0,
           "minus-modifier": 0, "rarity": "common", "material": material, "flags": 0,
           "level": 40, "upgrade-count": n, "upgrades": [cube(cube_material) for _ in range(n)]}
    if family is not None:
        row.update({"type": "weapon", "sub-type": family, "weapon-type": family})
    return row


def capacity_cases():
    # label, literal input, domain validity (None=unresolved FK), native admission
    cases = [("nonweapon-empty", item(), True, True),
             ("weapon-empty", item("sword", "iron"), True, True),
             ("1h16", item("sword", "iron", 16), True, True),
             ("1h17", item("sword", "iron", 17), False, False)]
    for family in ("longsword", "shield", "greatsword", "greataxe"):
        cases.append((family + "32", item(family, "iron", 32), True, True))
    for family in ("wand", "staff", "bow", "crossbow", "boomerang"):
        cases.append((family + "32", item(family, "wood", 32, "wood"), True, True))
    cases.extend([
        ("global33", item("shield", "iron", 33), False, False),
        ("wood-mace", item("mace", "wood", 1, "wood"), True, True),
        ("iron-mace", item("mace", "iron", 1), True, True),
        ("wood-greatmace", item("greatmace", "wood", 32, "wood"), True, True),
        ("bracelet16", item("bracelet", "gold", 16), True, True),
        ("spirit-on-wood", item("wand", "wood", 1, "spirit-fire"), True, True),
        ("gold-cube-not-whitelisted", item("bracelet", "gold", 1, "gold"), True, True),
        ("wood-on-iron", item("sword", "iron", 1, "wood"), False, True),
        ("iron-on-wood", item("wand", "wood", 1), False, True),
        ("iron-on-cloth", item("wand", "cotton", 1), False, True),
        ("nonweapon-wood", item(None, "wood", 1, "wood"), False, True),
        ("nonweapon-iron", item(None, "iron", 1), False, True),
        ("unknown-fk", item("missing-family", "iron", 1), None, True),
    ])
    for metal in METALS:
        cases.append(("iron-on-" + metal, item("bracelet", metal, 1), None, True))
    for count, length in ((16, 17), (0, 17), (0, 3), (17, 16), (32, 0), (33, 0)):
        row = item("sword", "iron", length)
        row["upgrade-count"] = count
        cases.append((f"count{count}-list{length}", row, False, count <= 16))
    return cases


def assert_native_cases(test, owner, cases):
    check = validator(owner)
    for label, row, domain_valid, admitted in cases:
        with test.subTest(owner=owner, case=label, domain_valid=domain_valid):
            test.assertEqual(check.is_valid(row), admitted)


def assert_required(test, owner, row, required):
    check = validator(owner)
    check.validate(row)
    for field in required:
        bad = deepcopy(row)
        del bad[field]
        with test.subTest(owner=owner, missing=field), test.assertRaises(jsonschema.ValidationError):
            check.validate(bad)


def assert_bad_values(test, owner, row, field, values):
    check = validator(owner)
    for value in values:
        with test.subTest(owner=owner, field=field, value=value), test.assertRaises(jsonschema.ValidationError):
            check.validate(dict(row, **{field: value}))


class ItemFacetsTests(unittest.TestCase):
    def test_declared_item_upgrade_inventory_facets(self):
        assert_raw(self, modules())  # Must fail before induction if a declaration disappears.
        assert_induced(self, SchemaView(str(SCHEMA)))
        weapons, materials = catalog("weapon-types"), catalog("materials")
        self.assertEqual({k for k, v in weapons.items() if isinstance(v, dict) and v.get("cube-capacity") == 16}, set(ONE_HAND))
        self.assertEqual({k for k, v in weapons.items() if isinstance(v, dict) and v.get("cube-capacity") == 32},
                         {"longsword", "bow", "crossbow", "boomerang", "staff", "wand", "shield", "greatsword", "greataxe", "greatmace"})
        self.assertEqual({k for k, v in materials.items() if isinstance(v, dict) and v.get("kind") == "metal"}, set(METALS))
        self.assertEqual({k for k, v in materials.items() if isinstance(v, dict) and v.get("kind") == "wood"}, {"wood"})

    def test_item_facet_mutations_fail_raw_oracle(self):
        data = modules()
        assert_raw(self, data)
        mutations = [
            ("items", ("slots", "item-upgrade-count", "equals_expression"), "32"),
            ("items", ("slots", "item-upgrade-count", "maximum_value"), 33),
            ("items", ("slots", "item-weapon-type", "range"), "item-type"),
            ("items", ("slots", "item-weapon-type", "multivalued"), True),
            ("items", ("slots", "item-weapon-type", "exactly_one_of"), []),
            ("items", ("slots", "item-upgrades", "maximum_cardinality"), 33),
            ("items", ("classes", "item", "all_of", 0), {}),
            ("items", ("classes", "item", "all_of", 1), {}),
            ("items", ("classes", "item", "all_of", 2), {}),
            ("items", ("classes", "item", "rules"), []),
            ("items", ("slots", "item-upgrade-x", "range"), "integer"),
            ("items", ("slots", "item-upgrade-level", "range"), "i16"),
            ("items", ("slots", "inventory-entry-count", "minimum_value"), 0),
            ("items", ("slots", "inventory-equipment", "maximum_cardinality"), 13),
            ("items", ("classes", "item", "slot_usage", "item-land", "required"), True),
            ("items", ("slots", "item-name", "readonly"), True),
            ("items", ("classes", "inventory", "slots"), ["id", "inventory-entries", "inventory-coins"]),
            ("entities", ("slots", "player-character-inventory", "range"), "item"),
            ("relations", ("slots", "holds", "annotations", "association-class"), "item"),
            ("identity", ("types", "uint32", "maximum_value"), 32),
        ]
        for module, path, value in mutations:
            changed = deepcopy(data)
            target = changed[module]
            for key in path[:-1]:
                target = target[key]
            target[path[-1]] = value
            with self.subTest(module=module, path=path), self.assertRaises(AssertionError):
                assert_raw(self, changed)  # No SchemaView/generator is invoked on mutants.

    def test_active_count_expression_sdk_semantics(self):
        expression = modules()["items"]["slots"]["item-upgrade-count"]["equals_expression"]
        self.assertEqual(expression, "len({upgrades})")
        self.assertEqual(ast.dump(ast.parse(expression, mode="eval")),
                         "Expression(body=Call(func=Name(id='len', ctx=Load()), args=[Set(elts=[Name(id='upgrades', ctx=Load())])], keywords=[]))")
        for n in (0, 1, 3, 16, 32):
            self.assertEqual(eval_expr(expression, upgrades=[cube()] * n), n)
        self.assertNotEqual(eval_expr(expression, upgrades=[cube()] * 3), 0)
        self.assertIsNone(eval_expr(expression, **{"item-upgrades": []}))
        with self.assertRaises(ValueError):
            eval_expr("len({item-upgrades})", upgrades=[])

    def test_native_item_capacity_and_material_limits(self):
        assert_raw(self, modules())
        assert_native_cases(self, "item", capacity_cases())
        row = item("sword", "iron")
        assert_bad_values(self, "item", row, "weapon-type", [None, [], ["sword"], {}, {"id": "sword"}, 3, True])
        absent = dict(row)
        del absent["weapon-type"]
        self.assertFalse(validator("item").is_valid(absent))
        self.assertFalse(validator("item").is_valid(dict(item(), **{"weapon-type": "sword"})))

    def test_native_upgrade_inventory_boundaries(self):
        row = item()
        assert_required(self, "item", row, {"id", "type", "sub-type", "modifier", "minus-modifier", "rarity", "material", "flags", "level", "upgrade-count", "upgrades"})
        assert_bad_values(self, "item", row, "id", [None, 1, True, [], {}, "Bad ID"])
        for field in ("type", "sub-type", "rarity", "material"):
            assert_bad_values(self, "item", row, field, [None, 1, True, [], {}, {"id": "wood"}])
        for field in ("modifier", "minus-modifier"):
            assert_bad_values(self, "item", row, field, [-1, 4294967296, True, 0.5, "0", None])
            validator("item").validate(dict(row, **{field: 4294967295}))
        assert_bad_values(self, "item", row, "flags", [-1, 256, True, "0", None])
        validator("item").validate(dict(row, flags=255))
        assert_bad_values(self, "item", row, "level", [0, 101, -32769, 32768, True, "1", None])
        for level in (1, 100):
            validator("item").validate(dict(row, level=level))
        assert_bad_values(self, "item", row, "upgrade-count", [-1, 33, 4294967295, 4294967296, True, "0", None])
        assert_bad_values(self, "item", row, "upgrades", [None, {}, 1, True, "", [None], [{}]])
        assert_required(self, "item-upgrade", cube(), {"x", "y", "z", "material", "level"})
        for axis in ("x", "y", "z"):
            for endpoint in (-128, 127):
                validator("item-upgrade").validate(dict(cube(), **{axis: endpoint}))
            assert_bad_values(self, "item-upgrade", cube(), axis, [-129, 128, True, 0.5, "0", None])
        assert_bad_values(self, "item-upgrade", cube(), "material", [None, True, 1, {}, []])
        assert_bad_values(self, "item-upgrade", cube(), "level", [None, True, "1", 0.5, [], {}])
        for level in (-100000, 0, 100000):
            validator("item-upgrade").validate(dict(cube(), level=level))
        self.verify_inventory()

    def verify_inventory(self):
        row = {"id": "bag", "entries": [{"item": item(), "count": 1}], "coins": 0, "equipment": []}
        assert_required(self, "inventory", row, {"id", "entries", "coins", "equipment"})
        assert_required(self, "inventory-entry", row["entries"][0], {"item", "count"})
        assignment = {"slot": "main-hand", "item": item("sword", "iron")}
        assert_required(self, "equipment-assignment", assignment, {"slot", "item"})
        assert_bad_values(self, "inventory-entry", row["entries"][0], "count", [0, -1, True, 0.5, "1", None])
        validator("inventory-entry").validate({"item": item(), "count": 1000000})
        assert_bad_values(self, "inventory", row, "coins", [-1, 4294967296, True, "0", None])
        validator("inventory").validate(dict(row, coins=4294967295))
        assert_bad_values(self, "inventory", row, "entries", [None, {}, 1, "", [{}]])
        assert_bad_values(self, "inventory", row, "equipment", [None, {}, 1, "", [{}]])
        assert_bad_values(self, "equipment-assignment", assignment, "slot", [None, {}, [], 1, True])
        assert_bad_values(self, "inventory-entry", row["entries"][0], "item", [None, "example-item", [], {}])
        assert_bad_values(self, "equipment-assignment", assignment, "item", [None, "example-item", [], {}])
        validator("inventory").validate(dict(row, entries=[], equipment=[]))
        validator("inventory").validate(dict(row, entries=row["entries"] * 1000))
        # Duplicate keys, slot legality and target existence are NOT native enforcement.
        validator("inventory").validate(dict(row, equipment=[assignment] * 12))
        assert_bad_values(self, "inventory", row, "equipment", [[assignment] * 13])
        validator("equipment-assignment").validate(dict(assignment, slot="missing-slot"))

    def test_item_roots_match_explicit_literal_fields(self):
        view = SchemaView(str(SCHEMA))
        for owner, names in OWNERS.items():
            properties = {FIELDS[name][0] for name in names}
            required = {FIELDS[name][0] for name in names if FIELDS[name][2]}
            assert_declared_root(owner, properties, required, schema=generated(owner), view=view)
        # Direct attachment, not inference from a native save subset.
        slot = view.induced_slot("player-character-inventory", "player-character")
        self.assertEqual((slot.alias, slot.range, slot.required, slot.inlined), ("inventory", "inventory", True, True))
        self.assertIn("player-character-inventory", view.class_slots("player-character"))


if __name__ == "__main__":
    unittest.main()
