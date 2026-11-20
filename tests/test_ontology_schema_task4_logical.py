"""Task4 logical projections; native typing is not learning or reference enforcement."""
from copy import deepcopy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
from linkml_runtime.utils.eval_utils import eval_expr

from test_ontology_schema import SCHEMA, generated
from test_ontology_schema_authoring import validate


def assert_logical_fields(test, view, items_path=SCHEMA.parent / "items.yaml"):
    raw = yaml.safe_load(items_path.read_text())
    for name in ("item-name", "artifact-name"):
        test.assertEqual(raw["slots"][name]["readonly"], "true")
    expected = {
        "item": {"item-name": ("name", "string", False),
                 "item-land": ("land", "land", False),
                 "item-plus": ("plus", "boolean", False)},
        "recipe": {"recipe-required-power": ("required-power", "integer", True)},
        "formula": {"formula-recipe": ("recipe", "recipe", True)},
        "book-of-crafting": {"book-recipes": ("recipes", "recipe", True)},
        "artifact": {"artifact-name": ("name", "string", False),
                     "artifact-origin-realm": ("origin-realm", "realm", True)},
    }
    for owner, slots in expected.items():
        for name, facets in slots.items():
            test.assertIn(name, view.class_slots(owner))
            slot = view.induced_slot(name, owner)
            test.assertEqual((slot.alias, slot.range, bool(slot.required)), facets)
            test.assertTrue(slot.see_also)
            test.assertIsNone(slot.ifabsent)
    for owner, name in (("item", "item-name"), ("artifact", "artifact-name")):
        slot = view.induced_slot(name, owner)
        # readonly is string metadata; JSON Schema readOnly remains annotation-only.
        test.assertEqual(view.get_slot(name).readonly, "true")
        test.assertEqual(slot.readonly, "true")
        test.assertFalse(slot.multivalued)
    power = view.induced_slot("recipe-required-power", "recipe")
    test.assertEqual((power.minimum_value, power.maximum_value), (1, 100))
    test.assertFalse(power.multivalued)
    test.assertFalse(view.induced_slot("formula-recipe", "formula").multivalued)
    content = view.induced_slot("book-recipes", "book-of-crafting")
    test.assertTrue(content.multivalued)
    test.assertEqual(content.minimum_cardinality, 1)
    test.assertIsNone(content.maximum_cardinality)
    test.assertIsNone(view.get_class("book-of-crafting").is_a)
    test.assertEqual(set(view.class_slots("book-of-crafting")), {"id", "book-recipes"})
    test.assertNotIn("item-level", view.class_slots("artifact"))
    test.assertEqual(view.get_class("formula").is_a, "item")
    for name in ("item-land", "item-plus"):
        test.assertTrue(view.get_slot(name).required)
        test.assertFalse(view.get_class("item").slot_usage[name].required)
        test.assertIn("historical S", view.induced_slot(name, "item").description)
        test.assertIn("inert", view.induced_slot(name, "item").description)
    test.assertIn("item-name", view.get_slot("item-name").description)
    test.assertIn("../domain/3_Classes.md#item", view.get_slot("item-name").see_also)
    test.assertIn("../domain/6_Generators.md", view.get_slot("item-name").see_also)
    test.assertIn("S", view.get_slot("artifact-origin-realm").description)
    test.assertIn("everywhere", view.get_slot("artifact-origin-realm").description)
    test.assertIn("<Name> Stone", view.get_slot("artifact-name").description)
    test.assertIn("3–4", view.get_slot("book-recipes").description)


TRAVERSAL_TARGETS = {
    "climb_speed": "climb-speed", "swim_speed": "swim-speed",
    "diving_skill": "diving-skill", "ride_speed": "ride-speed",
    "glide_speed": "glide-speed", "sail_speed": "sail-speed",
    "light_radius": "light-radius",
}
ARENA_WAVES = [
    {"tiers": ["common", "uncommon"]}, {"tiers": ["common", "uncommon"]},
    {"tiers": ["uncommon", "rare"]}, {"tiers": ["rare", "epic"]},
    {"tiers": ["epic", "legendary"]},
]


def assert_artifact_targets(test, view):
    slot = view.induced_slot("raises-stat", "artifact")
    test.assertEqual((slot.range, slot.multivalued, slot.required), ("stat", True, True))
    test.assertEqual((slot.minimum_cardinality, slot.maximum_cardinality), (3, 3))
    test.assertIs(slot.list_elements_unique, True)
    test.assertEqual(slot.has_member.equals_string, "attack-power")
    rules = view.get_class("artifact").rules
    test.assertEqual(len(rules), 8)
    test.assertIsNone(rules[0].preconditions)
    test.assertEqual(rules[0].postconditions.slot_conditions[
        "raises-stat"].has_member.equals_string, "hp")
    test.assertFalse(rules[0].deactivated)
    actual = {}
    for rule in rules[1:]:
        test.assertEqual(set(rule.preconditions.slot_conditions), {"traversal-kind"})
        test.assertEqual(set(rule.postconditions.slot_conditions), {"raises-stat"})
        test.assertFalse(rule.deactivated)
        selector = rule.preconditions.slot_conditions["traversal-kind"].equals_string
        actual[selector] = rule.postconditions.slot_conditions["raises-stat"].has_member.equals_string
    test.assertEqual(actual, TRAVERSAL_TARGETS)
    enum = view.get_enum("ArtifactTraversalKind").permissible_values
    test.assertEqual({name: value.aliases for name, value in enum.items()},
                     {name: [target] for name, target in TRAVERSAL_TARGETS.items()})


def assert_arena_constants(test, view):
    waves = view.induced_slot("waves", "arena")
    test.assertEqual((waves.range, waves.multivalued, waves.inlined, waves.inlined_as_list),
                     ("arena-wave", True, True, True))
    test.assertEqual((waves.minimum_cardinality, waves.maximum_cardinality), (5, 5))
    test.assertIs(waves.list_elements_ordered, True)
    # Existing SDK interpreter, not a new evaluator or runtime wave state machine.
    test.assertEqual(eval_expr(waves.equals_expression), ARENA_WAVES)
    test.assertEqual(waves.equals_expression,
                     "[{'tiers': ['common', 'uncommon']}, {'tiers': ['common', 'uncommon']}, "
                     "{'tiers': ['uncommon', 'rare']}, {'tiers': ['rare', 'epic']}, "
                     "{'tiers': ['epic', 'legendary']}]")
    tiers = view.induced_slot("tiers", "arena-wave")
    test.assertEqual((tiers.range, tiers.minimum_cardinality, tiers.maximum_cardinality),
                     ("MissionTier", 2, 2))
    test.assertIs(tiers.list_elements_ordered, True)
    host = view.induced_slot("host", "arena")
    test.assertEqual((host.range, host.equals_string), ("npc-role", "arena-master"))
    test.assertIn("bloodaxe-orc", host.description)
    test.assertIn("../instances/npc-roles.json#/arena-master", host.see_also)
    test.assertEqual(view.induced_slot("repeat", "arena").equals_string, "daily")
    coins = view.induced_slot("reward-coins", "arena")
    test.assertEqual((coins.range, coins.multivalued, coins.minimum_cardinality,
                      coins.maximum_cardinality), ("integer", True, 2, 2))
    test.assertIs(coins.list_elements_ordered, True)
    test.assertEqual(coins.equals_expression, "[18, 50]")
    test.assertEqual(eval_expr(coins.equals_expression), [18, 50])
    test.assertIn("Source-S", view.get_class("arena").description)
    test.assertIn("plus gear", view.get_class("arena").description)
    for slot in (waves, host, coins, view.induced_slot("repeat", "arena")):
        test.assertIsNone(slot.ifabsent)
        test.assertIn("source-s", slot.description.lower())


def item_row():
    return {"id": "scroll", "type": "formula", "sub-type": "formula",
            "modifier": 0, "minus-modifier": 0, "rarity": "common",
            "material": "wood", "flags": 0, "level": 1,
            "upgrade-count": 0, "upgrades": []}


class Task4LogicalTests(unittest.TestCase):
    def test_artifact_and_arena_exact_declarations(self):
        view = SchemaView(str(SCHEMA))
        assert_artifact_targets(self, view)
        assert_arena_constants(self, view)
        # Actual existing identities, not new stat IDs or an invented host species.
        from test_ontology_schema_authoring import catalog

        targets = {"attack-power", "hp", *TRAVERSAL_TARGETS.values()}
        self.assertTrue(targets <= set(catalog("stats")["stats"]))
        self.assertEqual(catalog("npc-roles")["arena-master"]["species"], "bloodaxe-orc")

    def test_artifact_native_membership_enforcement_limits(self):
        schema = generated("artifact")
        validator = jsonschema.Draft201909Validator(schema)
        for selector, target in TRAVERSAL_TARGETS.items():
            row = {"id": "a", "origin-realm": "realm-a", "traversal-kind": selector,
                   "raises-stat": ["attack-power", "hp", target]}
            validator.validate(row)
            # Set membership is unordered; permutation remains legal.
            validator.validate(dict(row, **{"raises-stat": [target, "hp", "attack-power"]}))
            for targets in (["hp", target, "armor"], ["attack-power", "hp"],
                            ["attack-power", "hp", target, "armor"]):
                with self.subTest(selector=selector, targets=targets), self.assertRaises(
                        jsonschema.ValidationError):
                    validator.validate(dict(row, **{"raises-stat": targets}))
            # Category2: declared rules and uniqueness are NOT native JSON Schema enforcement.
            for targets in (["attack-power", "hp", "armor"],
                            ["attack-power", "hp", "hp"],
                            ["attack-power", target, "armor"]):
                validator.validate(dict(row, **{"raises-stat": targets}))
        prop = schema["$defs"]["artifact"]["properties"]["raises-stat"]
        self.assertEqual(prop["contains"], {"const": "attack-power"})
        self.assertNotIn("uniqueItems", prop)

    def test_arena_native_constant_enforcement_limits(self):
        schema = generated("arena")
        validator = jsonschema.Draft201909Validator(schema)
        row = {"id": "arena", "host": "arena-master", "repeat": "daily",
               "waves": deepcopy(ARENA_WAVES), "reward-coins": [18, 50], "rewards": ["gear"]}
        validator.validate(row)
        for patch in ({"host": "bloodaxe-orc"}, {"repeat": "weekly"},
                      {"waves": ARENA_WAVES[:4]}, {"reward-coins": [18]},
                      {"waves": [{"tiers": ["worn", "common"]}] * 5}):
            with self.subTest(patch=patch), self.assertRaises(jsonschema.ValidationError):
                validator.validate(dict(row, **patch))
        wrong_pair_order = deepcopy(ARENA_WAVES)
        wrong_pair_order[0]["tiers"].reverse()
        # Category2: equals_expression declares exact values; native JSON Schema ignores it.
        for waves in (list(reversed(ARENA_WAVES)), wrong_pair_order,
                      [{"tiers": ["common", "uncommon"]}] * 5):
            self.assertNotEqual(waves, ARENA_WAVES)
            validator.validate(dict(row, waves=waves))
        for coins in ([50, 18], [0, 100], [18, 18]):
            self.assertNotEqual(coins, [18, 50])
            validator.validate(dict(row, **{"reward-coins": coins}))

    def test_artifact_arena_actual_yaml_rule_mutations(self):
        view = SchemaView(str(SCHEMA))
        assert_artifact_targets(self, view)
        assert_arena_constants(self, view)
        cases = [
            ("items", ("classes", "artifact", "slot_usage", "raises-stat", "list_elements_unique"), False),
            ("items", ("classes", "artifact", "slot_usage", "raises-stat", "has_member", "equals_string"), "hp"),
            ("items", ("classes", "artifact", "rules", 0, "postconditions", "slot_conditions", "raises-stat", "has_member", "equals_string"), "armor"),
            ("items", ("classes", "artifact", "rules", 1, "postconditions", "slot_conditions", "raises-stat", "has_member", "equals_string"), "swim-speed"),
            ("meta", ("classes", "arena", "attributes", "waves", "equals_expression"), repr(list(reversed(ARENA_WAVES)))),
            ("meta", ("classes", "arena", "attributes", "waves", "list_elements_ordered"), False),
            ("meta", ("classes", "arena-wave", "attributes", "tiers", "list_elements_ordered"), False),
            ("meta", ("classes", "arena", "attributes", "host", "equals_string"), "bloodaxe-orc"),
            ("meta", ("classes", "arena", "attributes", "repeat", "equals_string"), "weekly"),
            ("meta", ("classes", "arena", "attributes", "reward-coins", "equals_expression"), "[50, 18]"),
        ]
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            shutil.copytree(SCHEMA.parent, target)
            originals = {name: (target / (name + ".yaml")).read_text() for name in ("items", "meta")}
            for module, path, replacement in cases:
                for name, text in originals.items():
                    (target / (name + ".yaml")).write_text(text)
                data = yaml.safe_load(originals[module])
                node = data
                for key in path[:-1]:
                    node = node[key]
                node[path[-1]] = replacement
                (target / (module + ".yaml")).write_text(yaml.safe_dump(data, sort_keys=False))
                oracle = assert_artifact_targets if module == "items" else assert_arena_constants
                with self.subTest(path=path), self.assertRaises(AssertionError):
                    oracle(self, SchemaView(str(target / "pixlnd.yaml")))

    def test_attached_logical_fields(self):
        assert_logical_fields(self, SchemaView(str(SCHEMA)))

    def test_native_item_formula_and_book_boundaries(self):
        row = item_row()
        validate("item", row)  # Neither derived name nor historical S fields is mandatory.
        validate("item", dict(row, name="Wood Wand", land="land-a", plus=True))
        validate("formula", dict(row, recipe="unresolved-recipe"))
        for field, value in (("name", []), ("land", []), ("plus", "true")):
            with self.subTest(field=field), self.assertRaises(jsonschema.ValidationError):
                validate("item", dict(row, **{field: value}))
        for patch in ({}, {"recipe": []}, {"recipe": {"id": "r"}}, {"recipe": None}):
            with self.subTest(patch=patch), self.assertRaises(jsonschema.ValidationError):
                validate("formula", dict(row, **patch))
        for recipes in (["r"], ["a", "b", "c", "d", "e"]):
            validate("book-of-crafting", {"id": "book", "recipes": recipes})
        for patch in ({}, {"recipes": []}, {"recipes": "r"}, {"recipes": [True]},
                      {"recipes": None}, {"recipes": ["r"], "level": 1}):
            with self.subTest(patch=patch), self.assertRaises(jsonschema.ValidationError):
                validate("book-of-crafting", dict(id="book", **patch))
        # readonly is declarative: JSON Schema still accepts supplied derived strings.
        props = generated("item")["$defs"]["item"]["properties"]
        self.assertEqual(props["name"]["type"], ["string", "null"])
        self.assertIs(props["name"]["readOnly"], True)
        self.assertIs(generated("artifact")["$defs"]["artifact"]["properties"]["name"]["readOnly"], True)

    def test_native_recipe_power_and_artifact_boundaries(self):
        recipe = {"id": "r", "crafted-at": "anvil", "consumes": ["iron"],
                  "produces": "sword", "required-power": 1}
        for power in (1, 100):
            validate("recipe", dict(recipe, **{"required-power": power}))
        missing = deepcopy(recipe)
        del missing["required-power"]
        with self.assertRaises(jsonschema.ValidationError):
            validate("recipe", missing)
        for power in (0, 101, True, 1.5, "32", None):
            with self.subTest(power=power), self.assertRaises(jsonschema.ValidationError):
                validate("recipe", dict(recipe, **{"required-power": power}))
        artifact = {"id": "a", "traversal-kind": "glide_speed",
                    "raises-stat": ["attack-power", "hp", "glide-speed"],
                    "origin-realm": "unresolved-realm"}
        validate("artifact", artifact)
        validate("artifact", dict(artifact, name="Ring of Momuna"))
        missing = deepcopy(artifact)
        del missing["origin-realm"]
        with self.assertRaises(jsonschema.ValidationError):
            validate("artifact", missing)
        for patch in ({"origin-realm": []}, {"origin-realm": None}, {"name": True}, {"level": 1}):
            with self.subTest(patch=patch), self.assertRaises(jsonschema.ValidationError):
                validate("artifact", dict(artifact, **patch))

    def test_actual_yaml_added_facet_mutations(self):
        assert_logical_fields(self, SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            shutil.copytree(SCHEMA.parent, target)
            path = target / "items.yaml"
            original = path.read_text()
            cases = [("item-name", "readonly", "false"),
                     ("recipe-required-power", "maximum_value", 101),
                     ("formula-recipe", "range", "item"),
                     ("book-recipes", "multivalued", False),
                     ("artifact-origin-realm", "range", "land")]
            for name, facet, value in cases:
                data = yaml.safe_load(original)
                data["slots"][name][facet] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(slot=name), self.assertRaises(AssertionError):
                    assert_logical_fields(self, SchemaView(str(target / "pixlnd.yaml")), path)
            data = yaml.safe_load(original)
            data["slots"]["recipe-required-power"]["maximum_value"] = 101
            path.write_text(yaml.safe_dump(data, sort_keys=False))
            schema = json.loads(JsonSchemaGenerator(
                str(target / "pixlnd.yaml"), top_class="recipe", preserve_names=True,
                not_closed=False).serialize())
            row = {"id": "r", "crafted-at": "anvil", "consumes": ["iron"],
                   "produces": "sword", "required-power": 101}
            with self.assertRaises(jsonschema.ValidationError):
                validate("recipe", row)
            jsonschema.Draft201909Validator(schema).validate(row)
