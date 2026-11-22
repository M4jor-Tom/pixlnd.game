"""Review-selected save scalar/state facets; native checks are not runtime admission."""

import json
import tempfile
import unittest
from pathlib import Path

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.dumpers import json_dumper
from linkml_runtime.utils.eval_utils import eval_expr
from linkml_runtime.utils.schemaview import SchemaView
from ontology_save_facet_expectations import (
    COIN_RULE,
    INTEGER_SLOTS,
    LAST_FLOAT_BELOW_LIMIT,
    NONEMPTY,
    RAW_INTEGER_MAX,
    rubble_rules,
    special_rules,
    trap_rules,
)
from ontology_source_contracts import assert_declared_root
from test_ontology_schema import SCHEMA, copy_schema, generated


def upper_expressions(slot):
    if isinstance(slot, dict):
        return slot.get("any_of") or slot.get("exactly_one_of") or [slot]
    return slot.any_of or slot.exactly_one_of or [slot]


def assert_exact_upper(test, value):
    test.assertIsInstance(value, int)
    test.assertNotIsInstance(value, bool)
    test.assertEqual(value, RAW_INTEGER_MAX)


def assert_upper_declarations(test, root):
    view = SchemaView(str(root / "pixlnd.yaml"))
    for module, names in INTEGER_SLOTS.items():
        slots = yaml.safe_load((root / module).read_text())["slots"]
        for name in names:
            raw = slots[name]
            candidates = [raw, view.get_slot(name), view.induced_slot(name, raw["domain"])]
            for candidate in candidates:
                for branch in upper_expressions(candidate):
                    value = branch.get("maximum_value") if isinstance(branch, dict) else branch.maximum_value
                    assert_exact_upper(test, value)


def sdk_rule_names(value):
    if isinstance(value, list):
        return [sdk_rule_names(item) for item in value]
    if not isinstance(value, dict):
        return value
    result = {key: sdk_rule_names(item) for key, item in value.items()}
    if "slot_conditions" in result:
        for name, slot in result["slot_conditions"].items():
            slot["name"] = name
    return result


def assert_rules(test, view, root, owner, module, expected):
    raw = yaml.safe_load((root / module).read_text())["classes"][owner]
    test.assertEqual(raw.get("rules"), expected)
    for cls in (view.get_class(owner), view.induced_class(owner)):
        test.assertEqual([json_dumper.to_dict(rule) for rule in cls.rules], sdk_rule_names(expected))


class CurrentSaveFacetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.schema = generated("save-data")
        assert_declared_root("save-data", {"version", "world", "character"},
                             {"version", "world", "character"}, schema=cls.schema)
        cls.check = jsonschema.Draft201909Validator(cls.schema)

    def check_class(self, owner):
        return self.check.evolve(schema={"$ref": "#/$defs/" + owner})

    def test_integer_upper_raw_sdk_and_native(self):
        assert_upper_declarations(self, SCHEMA.parent)
        for module, names in INTEGER_SLOTS.items():
            raw = yaml.safe_load((SCHEMA.parent / module).read_text())["slots"]
            for name in names:
                slot = raw[name]
                prop = self.schema["$defs"][slot["domain"]]["properties"][slot["alias"]]
                branches = prop.get("anyOf") or prop.get("oneOf") or [prop]
                for branch in branches:
                    scalar = branch.get("items", branch)
                    with self.subTest(emitted=name):
                        assert_exact_upper(self, scalar.get("maximum"))
        coins = self.schema["$defs"]["character-state"]["properties"]["coins"]
        # Native numeric branch, retaining the original resolver, not alternate admission logic.
        check = self.check.evolve(schema=coins)
        for value in (0, 1, RAW_INTEGER_MAX, LAST_FLOAT_BELOW_LIMIT):
            check.validate(value)
        for value in (-1, True, 1.5, RAW_INTEGER_MAX + 1, 2**63 - 1, float(2**63)):
            with self.subTest(value=value), self.assertRaises(jsonschema.ValidationError):
                check.validate(value)
        # Observed Godot JSON successor token becomes this admitted FLOAT, unlike raw INT successor.
        self.assertNotEqual(LAST_FLOAT_BELOW_LIMIT, RAW_INTEGER_MAX + 1)
        check.validate(LAST_FLOAT_BELOW_LIMIT)
        seed = self.schema["$defs"]["world-state"]["properties"]["seed"]
        self.assertNotIn("maximum", seed)
        self.assertNotIn("minimum", seed)
        for value in (-1, 2**63):
            self.check.evolve(schema=seed).validate(value)
        self.assertEqual(self.schema["$defs"]["saved-item"]["properties"]["rarity"]["maximum"], 4)
        self.assertEqual(self.schema["$defs"]["save-data"]["properties"]["version"]["maximum"], 1)

    def test_integer_upper_actual_yaml_mutation(self):
        assert_upper_declarations(self, SCHEMA.parent)
        check = self.check.evolve(schema=self.schema["$defs"]["character-state"]["properties"]["coins"])
        self.assertFalse(check.is_valid(RAW_INTEGER_MAX + 1))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "save-character.yaml"
            data = yaml.safe_load(path.read_text())
            data["slots"]["character-state-coins"]["maximum_value"] = RAW_INTEGER_MAX + 1
            path.write_text(yaml.safe_dump(data, sort_keys=False))
            with self.assertRaises(AssertionError):
                assert_upper_declarations(self, target)
            mutant = json.loads(JsonSchemaGenerator(str(target / "pixlnd.yaml"), top_class="save-data",
                                                   preserve_names=True, not_closed=False).serialize())
            prop = mutant["$defs"]["character-state"]["properties"]["coins"]
            native = jsonschema.Draft201909Validator(prop)
            native.validate(RAW_INTEGER_MAX)
            with self.assertRaises(AssertionError):
                self.assertFalse(native.is_valid(RAW_INTEGER_MAX + 1))

    def test_scalar_facts(self):
        view = SchemaView(str(SCHEMA))
        for name, owner in (("saved-mob-pack", "saved-mob"), ("saved-trap-hit", "saved-trap")):
            for slot in (view.get_slot(name), view.induced_slot(name, owner)):
                self.assertEqual(slot.pattern, NONEMPTY)
        item = {"type": "coin", "subtype": "", "material": "", "rarity": 0, "level": 1,
                "upgrade_count": 0, "modifier": 0, "minus_modifier": 0, "count": 1}
        check = self.check_class("saved-item")
        check.validate(item)
        for field in ("subtype", "material"):
            with self.subTest(field=field), self.assertRaises(jsonschema.ValidationError):
                check.validate(dict(item, **{field: "not-empty"}))
        for cls in (view.get_class("saved-item"), view.induced_class("saved-item")):
            self.assertEqual(json_dumper.to_dict(cls.rules[1]), sdk_rule_names(COIN_RULE))
        for owner, field, row in (("saved-trap", "hit", {"phase": "active", "left": 0, "hit": []}),):
            check = self.check_class(owner)
            check.validate(dict(row, **{field: ["\n"]}))
            with self.assertRaises(jsonschema.ValidationError):
                check.validate(dict(row, **{field: [""]}))
        pack = self.schema["$defs"]["saved-mob"]["properties"]["pack"]
        self.check.evolve(schema=pack).validate("\n")
        with self.assertRaises(jsonschema.ValidationError):
            self.check.evolve(schema=pack).validate("")

    def test_snapshot_rules_authored_and_induced(self):
        view = SchemaView(str(SCHEMA))
        assert_rules(self, view, SCHEMA.parent, "saved-special", "save-content-saved-special.yaml", special_rules())
        assert_rules(self, view, SCHEMA.parent, "saved-rubble", "save-content-saved-props-traps.yaml", rubble_rules())
        assert_rules(self, view, SCHEMA.parent, "saved-trap", "save-content-saved-props-traps.yaml", trap_rules())
        expression = "min({recovery}, {left})"
        for recovery, left in ((0, 0), (0, 1), (0.5, 1), (1, 1), (2, 1)):
            self.assertEqual(eval_expr(expression, recovery=recovery, left=left) == recovery, recovery <= left)

    def test_snapshot_native_effects_and_limits(self):
        special = {"phase": "ready", "left": 0, "recovery": 0, "engaged": False,
                   "target": "", "origin": [], "endpoint": []}
        check = self.check_class("saved-special")
        check.validate(special)
        active = dict(special, phase="warning", target="\n", origin=[0, 1, 0], endpoint=[1, 1, 0], engaged=True)
        check.validate(active)
        for row in (dict(active, target=""), dict(special, target="hero"), dict(active, recovery=1),
                    dict(active, phase="charge", left=1)):
            with self.subTest(row=row), self.assertRaises(jsonschema.ValidationError):
                check.validate(row)
        # Exact canonical cardinalities and boolean/expression predicates are declared above.
        for row in (dict(active, origin=[]), dict(special, origin=[0, 1, 0]), dict(active, engaged=False),
                    dict(special, phase="cooldown", recovery=2, left=1)):
            check.validate(row)
        trap = self.check_class("saved-trap")
        for phase in ("idle", "warning"):
            trap.validate({"phase": phase, "left": 0, "hit": ["hero"]})
        rubble = self.check_class("saved-rubble")
        for row in ({"broken": False, "restore_at": 0}, {"broken": True, "restore_at": 1},
                    {"broken": True, "restore_at": 0}, {"broken": False, "restore_at": 1}):
            rubble.validate(row)


if __name__ == "__main__":
    unittest.main()
