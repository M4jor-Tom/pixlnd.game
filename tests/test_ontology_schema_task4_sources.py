"""Complete Task4 source contracts; source values are not executable recipes."""
import shutil
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml_runtime.utils.schemaview import SchemaView
from ontology_source_contracts import (
    assert_declared_root,
    bind_source,
    unbind_source,
    validate_source,
)
from test_ontology_schema import SCHEMA, generated
from test_ontology_schema_authoring import catalog


class CraftingSourcesTests(unittest.TestCase):
    def test_complete_crafting_sources_roundtrip(self):
        from ontology_source_contracts import assert_declared_root

        for name in ("materials", "ingredients", "crafting-stations"):
            row = catalog(name)
            fields = {"$schema", "_doc", "entries"}
            if name == "ingredients":
                fields.add("_unused-data")
            assert_declared_root(name + "-source", fields, fields,
                                 schema=generated(name + "-source"))
            validate_source(name, row)
            bound = bind_source(name, row)
            self.assertEqual(unbind_source(name, bound), row)
        self.assertIsNone(catalog("materials")["bronze"]["id"])
        self.assertEqual(catalog("materials")["iron"]["class"],
                         "warrior (armor); metal weapons all classes")
        self.assertEqual(catalog("materials")["mammoth"]["raw"], "mammoth-hide (0% drop)")
        self.assertEqual(catalog("ingredients")["iceflower"]["refines-to"],
                         {"heartflower": "1-3 @campfire"})
        self.assertEqual(catalog("ingredients")["_unused-data"],
                         {"horn": 3, "claw": 4, "hair": 7, "crystal": 8,
                          "orb": 13, "spirit": 14, "capsule": 11})
        self.assertEqual(catalog("crafting-stations")["customization-bench"]["does"],
                         "attach material cubes (A+S) and spirit cubes (A) to weapons; bench-rotate / bench-place / bench-remove (../domain/controls.md#bench-rotate)")

    def test_crafting_sources_reject_missing_roots_and_malformed_rows(self):
        for name in ("materials", "ingredients", "crafting-stations"):
            source = catalog(name)
            for mutation, bad in (
                    ("missing-schema", {key: value for key, value in source.items() if key != "$schema"}),
                    ("unknown-root", dict(source, invented={})),):
                with self.subTest(source=name, mutation=mutation), self.assertRaises(
                        jsonschema.ValidationError):
                    validate_source(name, bad)
        for name, path, replacement in (
                ("materials", ("iron", "name"), True),
                ("materials", ("iron", "versions"), "A"),
                ("materials", ("iron", "id"), []),
                ("materials", ("bronze", "id"), {}),
                ("ingredients", ("apple", "alpha-subtype"), True),
                ("ingredients", ("apple", "versions"), ["A", 1]),
                ("ingredients", ("iceflower", "refines-to"), {"heartflower": []}),
                ("ingredients", ("_unused-data", "horn"), True),
                ("crafting-stations", ("furnace", "static-id"), False),
                ("crafting-stations", ("furnace", "does"), []),
                ("crafting-stations", ("furnace", "static-id"), True)):
            bad = deepcopy(catalog(name))
            row = bad
            for key in path[:-1]:
                row = row[key]
            row[path[-1]] = replacement
            with self.subTest(source=name, path=path), self.assertRaises(
                    jsonschema.ValidationError):
                validate_source(name, bad)
        for name in ("materials", "ingredients", "crafting-stations"):
            bad = deepcopy(catalog(name))
            key = next(key for key in bad if key not in {"$schema", "_doc", "_unused-data"})
            del bad[key]["name"]
            with self.subTest(source=name, missing="name"), self.assertRaises(
                    jsonschema.ValidationError):
                validate_source(name, bad)


class ItemSourcesTests(unittest.TestCase):
    def test_complete_item_sources_roundtrip(self):
        roots = {
            "item-types": {"$schema", "_doc", "_s-additions", "entries"},
            "equipment-slots": {"$schema", "_doc", "slots", "extra", "rules"},
            "consumables": {"$schema", "_doc", "rules", "entries"},
            "pet-food": {"$schema", "_doc", "rules", "shop-set", "foods", "cut"},
            "affixes": {"$schema", "_doc", "common", "uncommon", "rare", "epic", "legendary", "name-forms", "plus-suffix", "examples"},
        }
        for name, fields in roots.items():
            with self.subTest(source=name):
                row = catalog(name)
                assert_declared_root(name + "-source", fields, fields,
                                     schema=generated(name + "-source"))
                validate_source(name, row)
                self.assertEqual(unbind_source(name, bind_source(name, row)), row)
        self.assertEqual(catalog("equipment-slots")["slots"][0]["accepts"], [])
        self.assertEqual(catalog("equipment-slots")["extra"]["pet-food"]["accepts"], ["pet-food"])
        self.assertEqual(catalog("equipment-slots")["slots"][12]["accepts-conditions"],
                         {"pet-food": "during-taming"})
        self.assertEqual(catalog("item-types")["_s-additions"]["key-item-s"],
                         ["reins", "climbing-spikes", "divine-harp", "sky-whistle", "spirit-bell", "treasure-spirit", "eternal-ember", "dungeon-keys"])
        unseen = deepcopy(catalog("item-types"))
        unseen["future-item-type"] = {"type": 26, "name": "Future Item"}
        self.assertEqual(unbind_source("item-types", bind_source("item-types", unseen)), unseen)
        validate_source("item-types", unseen)
        self.assertEqual(catalog("pet-food")["foods"]["bubble-gum"]["id"], 19)
        self.assertEqual(catalog("pet-food")["foods"]["bubble-gum"]["tames"], "collie")
        source = deepcopy(catalog("pet-food"))
        source["foods"]["bubble-gum"]["tames"] = "not-a-creature"
        validate_source("pet-food", source)  # Scalar typing is not foreign-key enforcement.
        self.assertEqual(catalog("consumables")["elixir-of-sanity"]["recipe"]["manaorchid"], "1-2")
        self.assertEqual(catalog("affixes")["plus-suffix"], "+")

    def assert_item_subtype_map_contract(self, view):
        slot = next(slot for slot in view.class_induced_slots("item-type-source-row")
                    if (slot.alias or slot.name) == "subtypes")
        self.assertEqual([expression.range for expression in slot.exactly_one_of],
                         ["string", "item-type-subtype-map"])
        self.assertIn("source-map-union-range", slot.annotations)
        self.assertEqual(slot.annotations["source-map-union-range"].value,
                         "item-type-subtype-map")
        self.assertEqual(view.get_class("item-type-subtype-map").annotations[
            "source-map-entries"].value, "entries")
        self.assertEqual(view.get_slot("item-type-subtype-key").pattern, "^[0-9]+$")

    def test_item_type_map_union_yaml_guards(self):
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            shutil.copytree(SCHEMA.parent, target)
            path = target / "items.yaml"
            original = yaml.safe_load(path.read_text())
            self.assert_item_subtype_map_contract(SchemaView(str(target / "pixlnd.yaml")))
            mutations = []
            missing_annotation = deepcopy(original)
            missing_annotation["classes"]["item-type-source-row"]["attributes"][
                "subtypes"].pop("annotations")
            mutations.append(("branch-annotation", missing_annotation))
            changed_union = deepcopy(original)
            changed_union["classes"]["item-type-source-row"]["attributes"][
                "subtypes"]["exactly_one_of"][1]["range"] = "string"
            mutations.append(("map-branch", changed_union))
            changed_key = deepcopy(original)
            changed_key["slots"]["item-type-subtype-key"]["pattern"] = ".*"
            mutations.append(("key-pattern", changed_key))
            for name, mutated in mutations:
                path.write_text(yaml.safe_dump(mutated, sort_keys=False))
                with self.subTest(mutation=name), self.assertRaises(AssertionError):
                    self.assert_item_subtype_map_contract(SchemaView(str(target / "pixlnd.yaml")))

    def test_item_sources_reject_missing_roots_and_malformed_shapes(self):
        for name in ("item-types", "equipment-slots", "consumables", "pet-food", "affixes"):
            source = catalog(name)
            for key in ("$schema", next(key for key in source if key != "$schema")):
                bad = {field: value for field, value in source.items() if field != key}
                with self.subTest(source=name, missing=key), self.assertRaises(jsonschema.ValidationError):
                    validate_source(name, bad)
            bad = dict(source, invented={})
            with self.subTest(source=name, extra="root"), self.assertRaises(jsonschema.ValidationError):
                validate_source(name, bad)
        cases = (
            ("item-types", ("consumable", "type"), True),
            ("item-types", ("candle", "subtypes"), None),
            ("item-types", ("candle", "subtypes"), []),
            ("item-types", ("candle", "subtypes"), {"non-numeric": "candle-a"}),
            ("item-types", ("candle", "subtypes"), {"0": 4}),
            ("item-types", ("ingredient", "subtypes", "0"), 3),
            ("item-types", ("_s-additions", "key-item-s"), "reins"),
            ("equipment-slots", ("slots",), {}),
            ("equipment-slots", ("slots", 0, "index"), True),
            ("equipment-slots", ("slots", 0, "accepts"), ["consumable", 4]),
            ("equipment-slots", ("slots", 10, "accepts-subtypes"), ["lamp", 4]),
            ("equipment-slots", ("slots", 12, "accepts-conditions"), []),
            ("equipment-slots", ("extra", "pet-food", "accepts"), "pet-food"),
            ("consumables", ("apple", "heal-mult"), True),
            ("consumables", ("apple", "source"), None),
            ("consumables", ("bomb", "source"), []),
            ("consumables", ("bomb", "source"), ["item vendor", 2]),
            ("consumables", ("elixir-of-sanity", "recipe", "manaorchid"), False),
            ("consumables", ("rules",), {}),
            ("pet-food", ("foods", "bubble-gum", "id"), False),
            ("pet-food", ("foods", "bubble-gum", "rideable"), 1),
            ("pet-food", ("foods", "bubble-gum", "tames"), []),
            ("pet-food", ("foods", "bubble-gum", "tames"), ["collie", "skeleton-dog"]),
            ("pet-food", ("foods", "bubble-gum", "tames"), {"values": ["collie", "skeleton-dog"]}),
            ("pet-food", ("foods", "bubble-gum", "tames"), {}),
            ("pet-food", ("foods", "bubble-gum", "tames"), None),
            ("pet-food", ("foods", "bubble-gum", "tames"), 1),
            ("pet-food", ("foods", "bubble-gum", "tames"), True),
            ("pet-food", ("cut", "apple-pie", "versions"), "X"),
            ("pet-food", ("shop-set",), {}),
            ("affixes", ("common",), "Plain"),
            ("affixes", ("name-forms",), []),
            ("affixes", ("plus-suffix",), None),
            ("affixes", ("examples", 0), 4),
        )
        for name, path, replacement in cases:
            bad = deepcopy(catalog(name))
            target = bad
            for segment in path[:-1]:
                target = target[segment]
            target[path[-1]] = replacement
            with self.subTest(source=name, path=path), self.assertRaises(jsonschema.ValidationError):
                validate_source(name, bad)


class SocialSourcesTests(unittest.TestCase):
    def test_complete_social_sources_roundtrip(self):
        roots = {
            "key-items": {"$schema", "_doc", "counts-per-land-s", "special-accessories-x", "entries"},
            "economy": {"$schema", "currency", "incomes", "prices", "shops",
                        "rules", "loot", "gaps", "gaps-decided"},
            "npc-roles": {"$schema", "dialogue-corpus", "entries"},
            "mission-types": {"$schema", "alpha", "steam"},
        }
        for name, fields in roots.items():
            with self.subTest(source=name):
                row = catalog(name)
                assert_declared_root(name + "-source", fields, fields,
                                     schema=generated(name + "-source"))
                validate_source(name, row)
                self.assertEqual(unbind_source(name, bind_source(name, row)), row)
        keys = catalog("key-items")
        self.assertEqual(keys["artifact"]["name-forms"], ["<Ring|Stone|Gem…> of <Name>", "<Name> Stone"])
        self.assertEqual(keys["artifact"]["count-per-land"], "1-3, generators.json#design.artifacts-per-land (D11)")
        self.assertEqual(keys["hang-glider"]["acquire"]["A"], "item vendor; needs Climbing 5 (Hang Gliding point); ~lvl 10")
        economy = catalog("economy")
        self.assertEqual(economy["currency"]["A"]["coins"], {"copper": 1, "silver": 100, "gold": 10000})
        self.assertEqual(economy["prices"]["S"]["gems"], {"emerald": 100, "sapphire": 200, "ruby": 400, "diamond": 800})
        self.assertEqual(economy["shops"]["item-shop"]["sells"]["S"], ["glass flasks", "bombs", "sugar cubes", "1 pet food/day", "legendary rings/amulets after 4 gnomes"])
        roles = catalog("npc-roles")
        self.assertIsNone(roles["gem-trader"]["building"])
        self.assertNotIn("building", roles["captive"])
        self.assertEqual(roles["villager"]["attackable"], "no (unless possessed)")
        self.assertEqual(roles["dialogue-corpus"]["known-lines"][1], "PLAY THE DIVINE TUNE TO UNLOCK SEALED AREAS IN THE <land>")
        missions = catalog("mission-types")
        self.assertEqual(missions["steam"]["_shared"]["tiers"], ["white", "green", "blue", "purple", "yellow"])
        self.assertEqual(missions["steam"]["region-completion-order"], ["activate shrines", "white quests (gnomes first)", "green", "blue", "purple", "get + gear before leaving"])
        self.assertIsNone(missions["steam"]["mana-inductor"]["icon"])
        self.assertIsNone(missions["steam"]["captured-npc"]["icon"])

    def test_social_sources_reject_malformed_roots_and_values(self):
        for name in ("key-items", "economy", "npc-roles", "mission-types"):
            source = catalog(name)
            missing_keys = ("$schema",) if name == "npc-roles" else (
                "$schema", next(key for key in source if key != "$schema"))
            for key in missing_keys:
                bad = {field: value for field, value in source.items() if field != key}
                with self.subTest(source=name, missing=key), self.assertRaises(jsonschema.ValidationError):
                    validate_source(name, bad)
            with self.subTest(source=name, extra="root"), self.assertRaises(jsonschema.ValidationError):
                validate_source(name, dict(source, invented={}))
        with self.assertRaises(jsonschema.ValidationError):
            validate_source("npc-roles", {"$schema": "npc-role"})
        cases = (
            ("key-items", ("hang-glider", "name"), True),
            ("key-items", ("hang-glider", "versions"), "S"),
            ("key-items", ("artifact", "stat-kinds"), "climb-speed"),
            ("key-items", ("artifact", "alpha-static-entity"), False),
            ("economy", ("currency", "A", "coins", "gold"), True),
            ("economy", ("incomes", "S", "monster"), [1, True]),
            ("economy", ("prices", "S", "gems", "ruby"), "400"),
            ("economy", ("shops", "item-shop", "sells"), []),
            ("economy", ("shops", "item-shop", "sells"), {}),
            ("economy", ("rules", "buy-back", "A"), "false"),
            ("economy", ("loot", "species-drops"), {}),
            ("npc-roles", ("villager", "name"), None),
            ("npc-roles", ("villager", "attackable"), True),
            ("npc-roles", ("dialogue-corpus", "known-lines"), "one line"),
            ("mission-types", ("alpha", "boss-kill", "sites"), {}),
            ("mission-types", ("steam", "_shared", "tiers"), "white"),
            ("mission-types", ("steam", "region-completion-order"), {}),
            ("mission-types", ("steam", "wizard-tower", "count"), False),
        )
        for name, path, replacement in cases:
            bad = deepcopy(catalog(name))
            target = bad
            for segment in path[:-1]:
                target = target[segment]
            target[path[-1]] = replacement
            with self.subTest(source=name, path=path), self.assertRaises(jsonschema.ValidationError):
                validate_source(name, bad)


class RecipesSourceTests(unittest.TestCase):
    def assert_literal_null_marker(self, view):
        gem = next(slot for slot in view.class_induced_slots("recipe-armor-common")
                   if (slot.alias or slot.name) == "gem")
        self.assertTrue(gem.required)
        self.assertTrue(gem.inlined)
        self.assertEqual(gem.range, "recipe-null-marker")
        self.assertIn("source-literal-null", gem.annotations)
        self.assertTrue(bool(gem.annotations["source-literal-null"].value))
        self.assertEqual(view.class_induced_slots("recipe-null-marker"), [])

    def test_complete_recipes_source_roundtrips(self):
        row = catalog("recipes")
        fields = {
            "$schema", "_doc", "gear-armor-quantities", "gear-weapons", "refining",
            "cooking", "alchemy", "crafting-tabs-a", "recipe-sources", "customization",
        }
        assert_declared_root("recipes-source", fields, fields, schema=generated("recipes-source"))
        self.assert_literal_null_marker(SchemaView(str(SCHEMA)))
        self.assertEqual(row["$schema"], "recipe")
        self.assertIsNone(row["gear-armor-quantities"]["common"]["gem"])
        self.assertEqual(row["gear-weapons"]["bow|crossbow"]["inputs"]["yarn"], 4)
        self.assertEqual(row["gear-weapons"]["bracelet|ring|amulet"]["inputs"]["gem"],
                         "by rarity (legendary ring may need rubies)")
        self.assertEqual(row["refining"]["heartflower-from-iceflower"]["outputs"]["heartflower"], "1-3")
        bound = bind_source("recipes", row)
        self.assertEqual(bound["gear-armor-quantities"]["common"]["gem"], {})
        self.assertEqual(unbind_source("recipes", bound), row)
        validate_source("recipes", row)

    def test_actual_yaml_marker_requiredness_annotation_and_shape_guards(self):
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            shutil.copytree(SCHEMA.parent, target)
            path = target / "items.yaml"
            original = yaml.safe_load(path.read_text())
            mutations = []
            missing_annotation = deepcopy(original)
            missing_annotation["classes"]["recipe-armor-common"]["attributes"]["gem"].pop("annotations")
            mutations.append(("annotation", missing_annotation))
            optional_marker = deepcopy(original)
            optional_marker["classes"]["recipe-armor-common"]["attributes"]["gem"]["required"] = False
            mutations.append(("required", optional_marker))
            nonempty_marker = deepcopy(original)
            nonempty_marker["classes"]["recipe-null-marker"]["attributes"] = {
                "invented": {"alias": "invented", "range": "string"}
            }
            mutations.append(("marker-shape", nonempty_marker))
            for name, mutated in mutations:
                path.write_text(yaml.safe_dump(mutated, sort_keys=False))
                with self.subTest(mutation=name), self.assertRaises(AssertionError):
                    self.assert_literal_null_marker(SchemaView(str(target / "pixlnd.yaml")))

    def test_literal_null_binding_requires_exact_empty_marker(self):
        row = catalog("recipes")
        marker_path = ("gear-armor-quantities", "common", "gem")
        for value in ([], "", 0, 1, False, True, {}, {"unexpected": True}):
            bad = deepcopy(row)
            node = bad[marker_path[0]][marker_path[1]]
            node[marker_path[2]] = value
            with self.subTest(raw=value), self.assertRaises(jsonschema.ValidationError):
                bind_source("recipes", bad)
        for value in (None, [], "", 0, 1, False, True, {"unexpected": True}):
            bound = bind_source("recipes", row)
            node = bound[marker_path[0]][marker_path[1]]
            node[marker_path[2]] = value
            with self.subTest(bound=value), self.assertRaises(jsonschema.ValidationError):
                unbind_source("recipes", bound)

    def test_recipes_source_rejects_incomplete_or_malformed_shapes(self):
        row = catalog("recipes")
        mutations = [
            ((), {**row, "unexpected": {}}),
            ((), {key: value for key, value in row.items() if key != "refining"}),
            (("gear-armor-quantities",), []),
            (("gear-weapons",), []),
            (("refining",), []),
            (("gear-armor-quantities", "common", "gem"), []),
            (("gear-armor-quantities", "common", "gem"), {}),
            (("gear-armor-quantities", "common", "gem"), ""),
            (("gear-armor-quantities", "common", "gem"), 0),
            (("gear-armor-quantities", "common", "gem"), False),
            (("gear-armor-quantities", "uncommon", "chest", "base"), True),
            (("gear-weapons", "fist", "inputs", "iron-cube"), True),
            (("gear-weapons", "bracelet|ring|amulet", "inputs", "gem"), []),
            (("gear-weapons", "bow|crossbow", "inputs", "yarn"), True),
            (("gear-weapons", "bow|crossbow", "inputs", "yarn"), []),
            (("refining", "iron-cube", "inputs", "iron-nugget"), False),
            (("refining", "iron-cube", "inputs", "iron-nugget"), 0),
            (("refining", "iron-cube", "inputs", "iron-nugget"), 1.5),
            (("refining", "heartflower-from-iceflower", "outputs", "heartflower"), []),
            (("crafting-tabs-a",), {"weapon": "own class"}),
            (("recipe-sources", "A"), []),
            (("customization", "material-cubes"), None),
        ]
        for path, replacement in mutations:
            bad = deepcopy(row)
            if not path:
                bad = replacement
            else:
                target = bad
                for segment in path[:-1]:
                    target = target[segment]
                target[path[-1]] = replacement
            with self.subTest(path=path), self.assertRaises(jsonschema.ValidationError):
                validate_source("recipes", bad)
        omitted = deepcopy(row)
        del omitted["gear-armor-quantities"]["common"]["gem"]
        with self.assertRaises(jsonschema.ValidationError):
            validate_source("recipes", omitted)

        unseen = deepcopy(row)
        unseen["refining"]["future-product"] = {
            "inputs": {"not-in-catalog": 3}, "station": "unresolved source text"
        }
        unseen["gear-weapons"]["future-group"] = {
            "inputs": {"not-in-catalog": "symbolic count"}, "station": "unresolved"
        }
        self.assertEqual(unbind_source("recipes", bind_source("recipes", unseen)), unseen)
        validate_source("recipes", unseen)


class LogicalMissionTests(unittest.TestCase):
    def assert_mission_arena_contracts(self, view):
        mission = view.get_class("mission-type")
        self.assertTrue({"id", "rewards"} <= set(mission.slots))
        for name, range_ in (("icon", "string"), ("tier", "MissionTier"), ("repeat", "string"),
                             ("structures", "dungeon-type-or-poi-type")):
            slot = view.induced_slot(name, "mission-type")
            self.assertEqual(slot.range, range_)
        self.assertTrue(view.induced_slot("structures", "mission-type").multivalued)
        arena = view.get_class("arena")
        self.assertTrue({"id", "rewards"} <= set(arena.slots))
        waves = view.induced_slot("waves", "arena")
        self.assertEqual((waves.range, waves.multivalued, waves.minimum_cardinality,
                          waves.maximum_cardinality), ("arena-wave", True, 5, 5))
        self.assertEqual(view.induced_slot("host", "arena").range, "npc-role")
        self.assertEqual(view.induced_slot("repeat", "arena").range, "string")
        coins = view.induced_slot("reward-coins", "arena")
        self.assertEqual((coins.range, coins.minimum_cardinality, coins.maximum_cardinality),
                         ("integer", 2, 2))
        tiers = view.induced_slot("tiers", "arena-wave")
        self.assertEqual((tiers.range, tiers.minimum_cardinality, tiers.maximum_cardinality),
                         ("MissionTier", 2, 2))
        self.assertEqual(set(view.get_enum("MissionTier").permissible_values),
                         {"common", "uncommon", "rare", "epic", "legendary"})

    def test_mission_arena_and_artifact_native_boundaries(self):
        def check(name, good, bad_rows):
            schema = generated(name)
            validator = jsonschema.validators.validator_for(schema)(schema)
            self.assertTrue(validator.is_valid(good))
            for bad in bad_rows:
                with self.subTest(class_name=name, value=bad):
                    self.assertFalse(validator.is_valid(bad))

        check("mission-type", {"id": "daily-quest", "icon": "swords", "tier": "common",
                               "repeat": "daily", "structures": ["ruins"], "rewards": ["coins"]},
              [{}, {"id": "bad-tier", "tier": "worn"}, {"id": "bad-structures", "structures": [1]}])
        waves = [{"tiers": ["common", "uncommon"]}] * 5
        arena = {"id": "arena", "host": "arena-master", "repeat": "daily",
                 "reward-coins": [18, 50], "waves": waves, "rewards": ["gear"]}
        check("arena", arena, [
            {**arena, "waves": waves[:4]},
            {**arena, "waves": [{"tiers": ["common"]}] + waves[1:]},
            {**arena, "waves": [{"tiers": ["worn", "common"]}] + waves[1:]},
            {**arena, "reward-coins": [18]},
        ])
        # Standard aliases describe canonical concepts, not alternate admitted tokens.
        artifact_schema = generated("artifact")
        artifact_validator = jsonschema.validators.validator_for(artifact_schema)(artifact_schema)
        for token, canonical in (
                ("climb_speed", "climb-speed"), ("swim_speed", "swim-speed"),
                ("diving_skill", "diving-skill"), ("ride_speed", "ride-speed"),
                ("glide_speed", "glide-speed"), ("sail_speed", "sail-speed"),
                ("light_radius", "light-radius")):
            row = {"id": "ring", "origin-realm": "realm-a", "traversal-kind": token,
                   "raises-stat": [canonical, "attack-power", "hp"]}
            self.assertTrue(artifact_validator.is_valid(row))
            self.assertFalse(artifact_validator.is_valid({**row, "traversal-kind": canonical}))
        check("artifact", {"id": "ring", "origin-realm": "realm-a", "traversal-kind": "climb_speed",
                            "raises-stat": ["climb-speed", "attack-power", "hp"]}, [
            {"id": "ring", "origin-realm": "realm-a", "traversal-kind": "movement", "raises-stat": ["climb-speed", "attack-power", "hp"]},
            {"id": "ring", "origin-realm": "realm-a", "traversal-kind": "climb_speed", "raises-stat": ["climb-speed", "attack-power"]},
            {"id": "ring", "origin-realm": "realm-a", "traversal-kind": "climb_speed", "raises-stat": ["climb-speed", "attack-power", "hp", "armor"]},
        ])

    def test_mission_and_arena_logical_structures(self):
        self.assert_mission_arena_contracts(SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            shutil.copytree(SCHEMA.parent, target)
            path = target / "meta.yaml"
            original = yaml.safe_load(path.read_text())
            mutations = [
                ("mission icon", lambda data: data["classes"]["mission-type"]["attributes"]["icon"].update(range="integer")),
                ("mission structures", lambda data: data["classes"]["mission-type"]["attributes"]["structures"].update(multivalued=False)),
                ("arena wave count", lambda data: data["classes"]["arena"]["attributes"]["waves"].update(maximum_cardinality=4)),
                ("arena tiers", lambda data: data["classes"]["arena-wave"]["attributes"]["tiers"].update(range="string")),
                ("mission tier values", lambda data: data["enums"]["MissionTier"]["permissible_values"].pop("legendary")),
            ]
            for name, mutate in mutations:
                changed = deepcopy(original)
                mutate(changed)
                path.write_text(yaml.safe_dump(changed, sort_keys=False))
                with self.subTest(mutation=name), self.assertRaises(AssertionError):
                    self.assert_mission_arena_contracts(SchemaView(str(target / "pixlnd.yaml")))


if __name__ == "__main__":
    unittest.main()
