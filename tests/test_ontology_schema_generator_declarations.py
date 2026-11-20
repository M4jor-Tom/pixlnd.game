"""Authored and induced contracts are distinct from emitted-schema admission."""

from copy import deepcopy
import hashlib
import tempfile
import json
from pathlib import Path
import unittest

import jsonschema
import linkml_runtime
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
import yaml

from ontology_generator_expectations import (
    DESIGN_FIELDS, SOURCE_FIELDS, FIXED, REQUIRED_WEAPONS, aliases, assert_literal_contract,
    OBJECT_EXPRESSIONS, SETTLEMENT_CONJUNCTS, NO_EQUALITY_FIELDS, STATUS_KEYS, POOL_FACTS,
    EVENT_IDS, RUNTIME_FIELDS, RUNTIME_NONNULL_FIELDS, NUMERIC_DOMAIN_FIELDS,
)
from ontology_source_contracts import assert_declared_root
from test_ontology_schema import SCHEMA, generated
from test_ontology_schema_authoring import catalog


MODULE_NAMES = ("design-combat", "design-progression", "design-world", "design-items")


def modules_at(directory):
    return {name: yaml.safe_load((directory / (name + ".yaml")).read_text()) for name in MODULE_NAMES}


def assert_induced_owner(test, name, owner, view):
    test.assertIn(name, view.all_classes())
    induced = {str(slot.alias or slot.name): slot for slot in view.class_induced_slots(name)}
    test.assertEqual(set(induced), set(aliases(owner)), name)
    for alias, raw in aliases(owner).items():
        slot = induced[alias]
        test.assertEqual(slot.slot_uri, raw["slot_uri"])
        test.assertEqual(bool(slot.required), raw.get("required", False))
        test.assertEqual(bool(slot.multivalued), raw.get("multivalued", False))
        for facet in ("range", "minimum_value", "maximum_value", "minimum_cardinality",
                      "maximum_cardinality", "equals_expression", "equals_string", "pattern"):
            if facet in raw:
                test.assertEqual(getattr(slot, facet), raw[facet], (name, alias, facet))


def assert_map_batch_induced(test, view):
    rgb = view.get_class("generator-design-feel-numbers-colours").attributes["entries"]
    rgb_induced = next(s for s in view.class_induced_slots("generator-design-feel-numbers-colours") if s.alias == "entries")
    for slot in (rgb, rgb_induced):
        test.assertEqual(slot.has_member.range_expression.slot_conditions["key"].equals_string, "hit")
        test.assertEqual(slot.range, "generator-rgb-entry")
    for owner in (view.get_class("generator-design-status-effects"), view.induced_class("generator-design-status-effects")):
        test.assertEqual([c.slot_conditions["entries"].has_member.range_expression.slot_conditions["key"].equals_string
                          for c in owner.all_of], ["burning", "poison"])
    expected = [(key, "generator-design-status-effects-" + key) for key in STATUS_KEYS]
    for owner in (view.get_class("generator-status-entry"), view.induced_class("generator-status-entry")):
        test.assertEqual([(r.preconditions.slot_conditions["key"].equals_string,
                           r.postconditions.slot_conditions["value"].range) for r in owner.rules], expected)
    value = view.get_class("generator-status-entry").attributes["value"]
    induced_value = next(s for s in view.class_induced_slots("generator-status-entry") if s.alias == "value")
    variants = ["generator-design-status-effects-" + key for key in ("stun", "knockdown", "knockback", "burning", "slow", "poison")]
    for slot in (value, induced_value):
        test.assertEqual([branch.range for branch in slot.exactly_one_of], variants)
        test.assertTrue(all(branch.inlined and branch.required for branch in slot.exactly_one_of))
    building = next(s for s in view.class_induced_slots("generator-design-settlement") if s.alias == "buildings")
    test.assertEqual(building.range, "building")
    test.assertFalse(view.is_inlined(building))

    for (owner, alias), expression in OBJECT_EXPRESSIONS.items():
        declared = next(s for s in view.get_class(owner).attributes.values() if s.alias == alias)
        induced = next(s for s in view.class_induced_slots(owner) if s.alias == alias)
        for slot in (declared, induced):
            test.assertEqual(slot.equals_expression, expression)
            test.assertTrue(slot.required)
            test.assertTrue(slot.inlined)
            test.assertEqual(str(slot.alias), alias)
            test.assertTrue(alias.isidentifier())
    for owner, alias in NO_EQUALITY_FIELDS:
        for slots in (view.get_class(owner).attributes.values(), view.class_induced_slots(owner)):
            test.assertIsNone(next(s for s in slots if s.alias == alias).equals_expression)
    for slots in (view.get_class("generator-design").attributes.values(),
                  view.class_induced_slots("generator-design")):
        settlement = next(s for s in slots if s.alias == "settlement")
        test.assertEqual([(str(s.range), s.inlined, s.required, s.equals_expression) for s in settlement.all_of],
            [(s["range"], True, True, s["equals_expression"]) for s in SETTLEMENT_CONJUNCTS])
    for slots in (view.get_class("generator-design-loot").attributes.values(),
                  view.class_induced_slots("generator-design-loot")):
        pool = next(s for s in slots if s.alias == "consumable-pool")
        test.assertTrue(pool.list_elements_unique)
        test.assertEqual(pool.equals_expression, POOL_FACTS["equals_expression"])
        test.assertEqual(list(pool.all_members.equals_string_in), POOL_FACTS["all_members"]["equals_string_in"])
    for owner in (view.get_class("generator-ability-entry"), view.induced_class("generator-ability-entry")):
        rule = owner.rules[0]
        test.assertEqual(rule.preconditions.slot_conditions["key"].equals_string, "heroic-shout")
        taunt = rule.postconditions.slot_conditions["value"].range_expression.slot_conditions["ability-runtime-taunt-s"]
        test.assertEqual((taunt.alias, taunt.required, taunt.minimum_value, taunt.maximum_value),
                         ("taunt-s", True, 3.0, 3.0))
    for slot in (view.get_slot("runtime-projectile-damage-mult"),
                 view.induced_slot("runtime-projectile-damage-mult", "runtime-projectile")):
        test.assertFalse(slot.required)
        test.assertEqual(slot.minimum_value, 0)
        test.assertEqual([(str(s.range), s.equals_number) for s in slot.none_of], [("double", 0)])

    assert_reviewed_induced(test, view)


def assert_round_two_induced(test, view):
    for owner in (view.get_class("ability-runtime"), view.induced_class("ability-runtime")):
        rules = {r.preconditions.slot_conditions["ability-runtime-runtime"].equals_string: r for r in owner.rules}
        test.assertEqual(set(rules), set(RUNTIME_FIELDS))
        for kind, fields in RUNTIME_FIELDS.items():
            rule = rules[kind]
            test.assertEqual(rule.preconditions.slot_conditions["ability-runtime-runtime"].alias, "runtime")
            test.assertEqual(set(rule.postconditions.slot_conditions), {"ability-runtime-" + f for f in fields})
            for field in fields:
                slot = rule.postconditions.slot_conditions["ability-runtime-" + field]
                test.assertEqual((slot.alias, slot.required), (field, True))
                test.assertEqual([str(s.range) for s in slot.all_of],
                                 ["double"] if (kind, field) in RUNTIME_NONNULL_FIELDS else [])
    for _, owner, field, _, lower, _ in NUMERIC_DOMAIN_FIELDS:
        induced = next(s for s in view.class_induced_slots(owner) if s.alias == field)
        for slot in (view.get_class(owner).attributes[field], induced):
            test.assertEqual((str(slot.range), slot.required, slot.minimum_value, slot.alias, str(slot.slot_uri)),
                             ("double", True, lower, field, "pixlnd:" + owner + "/" + field))


def assert_reviewed_induced(test, view):
    assert_round_two_induced(test, view)
    for owner in (view.get_class("ability-runtime"), view.induced_class("ability-runtime")):
        rule = next(r for r in owner.rules if r.preconditions.slot_conditions["ability-runtime-runtime"].equals_string == "projectile")
        test.assertEqual(rule.preconditions.slot_conditions["ability-runtime-runtime"].alias, "runtime")
        test.assertEqual({key: slot.alias for key, slot in rule.postconditions.slot_conditions.items()},
                         {"ability-runtime-speed": "speed", "ability-runtime-radius": "radius", "ability-runtime-life-s": "life-s"})
        for name in ("ability-runtime-speed", "ability-runtime-life-s"):
            slot = rule.postconditions.slot_conditions[name]
            test.assertEqual((str(slot.range), slot.required, slot.minimum_value), ("double", True, 0))
            test.assertEqual([(str(s.range), s.equals_number) for s in slot.none_of], [("double", 0)])
    for slots in (view.get_class("generator-design-feel-events").attributes.values(),
                  view.class_induced_slots("generator-design-feel-events")):
        test.assertEqual({str(s.alias) for s in slots}, set(EVENT_IDS))
        test.assertTrue(all(str(s.range) == "generator-feel-event" and s.required and s.inlined for s in slots))
    for slots in (view.get_class("generator-feel-event").attributes.values(), view.class_induced_slots("generator-feel-event")):
        test.assertEqual({str(s.alias): (str(s.range), bool(s.required)) for s in slots},
                         {"hit-stop-s": ("double", True), "trauma": ("double", True), "sfx": ("string", True)})
    for slots in (view.get_class("generator-design-feel-level-up").attributes.values(),
                  view.class_induced_slots("generator-design-feel-level-up")):
        test.assertEqual(next(s for s in slots if s.alias == "text").pattern, r"[\s\S]+")


def assert_runtime_wire_keys(test, full):
    rules = full["$defs"]["ability-runtime"]["allOf"]
    test.assertEqual(len(rules), len(RUNTIME_FIELDS))
    by_kind = {rule["if"]["properties"].get("runtime", {}).get("const"): rule for rule in rules}
    test.assertEqual(set(by_kind), set(RUNTIME_FIELDS))
    for kind, fields in RUNTIME_FIELDS.items():
        rule = by_kind[kind]
        test.assertEqual(rule["if"], {"properties": {"runtime": {"const": kind}}, "required": ["runtime"]})
        test.assertEqual(set(rule["then"]["properties"]), set(fields))
        test.assertEqual(set(rule["then"]["required"]), set(fields))
        for field in fields:
            expected = [{"type": "number"}] if (kind, field) in RUNTIME_NONNULL_FIELDS else []
            test.assertEqual(rule["then"]["properties"][field].get("allOf", []), expected)
    for field in ("speed", "life-s"):
        test.assertEqual(by_kind["projectile"]["then"]["properties"][field],
                         {"minimum": 0, "not": {"anyOf": [{"const": 0, "type": "number"}]},
                          "allOf": [{"type": "number"}]})
    for _, owner, field, _, lower, _ in NUMERIC_DOMAIN_FIELDS:
        definition = full["$defs"][owner]
        test.assertIn(field, definition["required"])
        test.assertEqual(definition["properties"][field]["type"], "number")
        test.assertEqual(definition["properties"][field].get("minimum"), lower)


def declaration_oracle(test, directory=SCHEMA.parent):
    modules = modules_at(directory)
    assert_literal_contract(test, modules)
    view = SchemaView(str(directory / "pixlnd.yaml"))
    assert_map_batch_induced(test, view)
    for module in modules.values():
        for name, owner in module["classes"].items():
            if not name.startswith("generator"):
                continue
            assert_induced_owner(test, name, owner, view)
    override = view.get_class("generator-role-override").attributes["color"]
    induced_override = next(slot for slot in view.class_induced_slots("generator-role-override") if slot.alias == "color")
    for slot in (override, induced_override):
        test.assertEqual(slot.range, "string")
        test.assertFalse(slot.required)
        test.assertEqual([branch.range for branch in slot.all_of], ["string"])
    for owner in (view.get_class("generator-design-movesets"), view.induced_class("generator-design-movesets")):
        test.assertEqual([condition.slot_conditions["entries"].has_member.range_expression.slot_conditions["key"].equals_string
                          for condition in owner.all_of], list(REQUIRED_WEAPONS))
    for name, fields in (("generators-source", SOURCE_FIELDS), ("generator-design", DESIGN_FIELDS)):
        full = (generated(name) if directory == SCHEMA.parent else json.loads(JsonSchemaGenerator(
            str(directory / "pixlnd.yaml"), top_class=name, preserve_names=True,
            not_closed=False).serialize()))
        assert_declared_root(name, fields, fields, schema=full, view=view)
        assert_runtime_wire_keys(test, full)
    return view


def assert_integer_equalities(test, modules):
    for module in modules.values():
        for owner in module.get("classes", {}).values():
            for field in aliases(owner).values():
                if "equals_number" in field:
                    test.assertIsInstance(field["equals_number"], int)
                    test.assertNotIsInstance(field["equals_number"], bool)


class GeneratorDeclarationTests(unittest.TestCase):
    def test_native_naming_policy_preserves_exact_literal_exception(self):
        from linkml.linter.linter import Linter

        policy = yaml.safe_load((SCHEMA.parents[2] / ".linkmllint.yaml").read_text())
        naming = policy["rules"]["standard_naming"]
        self.assertEqual((naming["level"], naming["class_pattern"], naming["slot_pattern"]),
                         ("error", "kebab", "kebab"))
        self.assertNotIn("exclude_type", naming)
        self.assertEqual(naming["exclude"].count("at-cursor"), 1)
        fixture = {
            "id": "https://w3id.org/pixlnd/policy-fixture", "name": "policy-fixture",
            "description": "Native naming-policy witness.",
            "prefixes": {"fixture": "https://w3id.org/pixlnd/policy-fixture/",
                         "linkml": "https://w3id.org/linkml/"},
            "default_prefix": "fixture", "default_range": "string", "imports": ["linkml:types"],
            "classes": {"policy-row": {"description": "Policy row.", "class_uri": "fixture:policy-row",
                "attributes": {"move-kind": {"description": "Move kind.", "slot_uri": "fixture:policy-row/move-kind",
                                             "range": "PolicyMoveKind"}}}},
            "enums": {"PolicyMoveKind": {"description": "Literal move kinds.", "enum_uri": "fixture:PolicyMoveKind",
                                         "permissible_values": {"at-cursor": {}}}},
        }
        with tempfile.TemporaryDirectory() as scratch:
            path = Path(scratch) / "policy.yaml"
            path.write_text(yaml.safe_dump(fixture, sort_keys=False))
            print("POLICY clean fixture", hashlib.sha256(path.read_bytes()).hexdigest(), path.read_text())
            self.assertEqual(list(Linter(policy).lint(str(path))), [])
            without_literal = deepcopy(policy)
            without_literal["rules"]["standard_naming"]["exclude"].remove("at-cursor")
            problems = list(Linter(without_literal).lint(str(path)))
            self.assertEqual([p.rule_name for p in problems], ["standard_naming"])
            self.assertIn("'at-cursor'", problems[0].message)
            for kind in ("class", "slot", "enum", "value", "range"):
                bad = deepcopy(fixture)
                if kind == "class":
                    bad["classes"]["PolicyRow"] = bad["classes"].pop("policy-row")
                elif kind == "slot":
                    attrs = bad["classes"]["policy-row"]["attributes"]
                    attrs["bad_slot"] = attrs.pop("move-kind")
                elif kind == "enum":
                    bad["enums"]["wrong_enum"] = bad["enums"].pop("PolicyMoveKind")
                    bad["classes"]["policy-row"]["attributes"]["move-kind"]["range"] = "wrong_enum"
                elif kind == "value":
                    bad["enums"]["PolicyMoveKind"]["permissible_values"] = {"not-allowlisted": {}}
                else:
                    bad["classes"]["policy-row"]["attributes"]["move-kind"]["range"] = "MissingRange"
                path.write_text(yaml.safe_dump(bad, sort_keys=False))
                print("POLICY negative fixture", kind, hashlib.sha256(path.read_bytes()).hexdigest(), path.read_text())
                problems = list(Linter(policy).lint(str(path)))
                expected = "no_undeclared_ranges" if kind == "range" else "standard_naming"
                with self.subTest(policy_negative=kind):
                    self.assertEqual([p.rule_name for p in problems], [expected])
                print("POLICY", kind, [(p.rule_name, p.message) for p in problems])

    def test_native_required_weapon_membership_qualification(self):
        from ontology_source_contracts import _walk

        modules = modules_at(SCHEMA.parent)
        assert_literal_contract(self, modules)
        view = SchemaView(str(SCHEMA))
        for owner in (view.get_class("generator-design-movesets"), view.induced_class("generator-design-movesets")):
            self.assertEqual([condition.slot_conditions["entries"].has_member.range_expression.slot_conditions["key"].equals_string
                              for condition in owner.all_of], list(REQUIRED_WEAPONS))
        classes, weapons = catalog("classes"), catalog("weapon-types")
        derived = {key for row in classes.values() if isinstance(row, dict) and "weapon-types" in row
                   for key in row["weapon-types"] if weapons[key]["hands"] != "offhand"}
        self.assertEqual(derived, set(REQUIRED_WEAPONS))
        full = generated("generator-design-movesets")
        fields = {"_doc", "kinds", "default", "entries"}
        assert_declared_root("generator-design-movesets", fields, fields, schema=full, view=view)
        source = catalog("generators")["design"]["movesets"]
        bound = _walk("generator-design-movesets", source, False)
        self.assertEqual(_walk("generator-design-movesets", bound, True), source)
        validator = jsonschema.Draft201909Validator(full)
        validator.validate(bound)
        admitted, rejected = [], []
        for key in REQUIRED_WEAPONS:
            bad = deepcopy(bound)
            bad["entries"] = [entry for entry in bad["entries"] if entry["key"] != key]
            (rejected if list(validator.iter_errors(bad)) else admitted).append(key)
        self.assertEqual(rejected, [])
        self.assertEqual(admitted, list(REQUIRED_WEAPONS))
        self.assertEqual(full["$defs"]["generator-design-movesets"]["allOf"],
                         [{"properties": {"entries": {}}, "required": ["entries"]}] * 15)
        print("REQUIRED membership native rejected:", rejected, "admitted:", admitted)
        print("REQUIRED membership emitted allOf:", json.dumps(
            full["$defs"]["generator-design-movesets"].get("allOf"), sort_keys=True))

    def test_coupling_declarations_and_static_contexts(self):
        """Literal raw/get/induced contexts only; NO native expression execution."""
        declaration_oracle(self)

    def test_complete_authored_and_induced_declarations(self):
        declaration_oracle(self)

    def test_numeric_metamodel_and_selected_fractional_facets(self):
        meta = Path(linkml_runtime.__file__).parent / "linkml_model/jsonschema/meta.schema.json"
        official = json.loads(meta.read_text())
        self.assertEqual(official["$defs"]["SlotDefinition"]["properties"]["equals_number"]["type"], ["integer", "null"])
        modules = modules_at(SCHEMA.parent)
        assert_literal_contract(self, modules)
        assert_integer_equalities(self, modules)
        view = SchemaView(str(SCHEMA))
        for (owner, alias), (kind, value) in FIXED.items():
            slot = next(s for s in view.class_induced_slots(owner) if s.alias == alias)
            for actual in (slot.minimum_value, slot.maximum_value):
                self.assertEqual(actual, value)
                self.assertNotIsInstance(actual, bool)
                self.assertIsInstance(actual, int if kind == "integer" else float)


if __name__ == "__main__":
    unittest.main()
