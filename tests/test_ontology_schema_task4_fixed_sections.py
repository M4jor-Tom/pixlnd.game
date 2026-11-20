"""Literal source/config policies; catalog identities stay in keyed data."""
from copy import deepcopy
from pathlib import Path
import shutil
import tempfile
import unittest

import jsonschema
import yaml
from linkml_runtime.utils.schemaview import SchemaView

from ontology_source_contracts import assert_declared_root, bind_source, unbind_source, validate_source
from test_ontology_schema import SCHEMA, generated
from test_ontology_schema_authoring import catalog


ROOT_FIELDS = {
    "item-types": {"$schema", "_doc", "_s-additions", "entries"},
    "materials": {"$schema", "_doc", "entries"},
    "equipment-slots": {"$schema", "_doc", "slots", "extra", "rules"},
    "consumables": {"$schema", "_doc", "rules", "entries"},
    "ingredients": {"$schema", "_doc", "_unused-data", "entries"},
    "recipes": {"$schema", "_doc", "gear-armor-quantities", "gear-weapons", "refining",
                "cooking", "alchemy", "crafting-tabs-a", "recipe-sources", "customization"},
    "crafting-stations": {"$schema", "_doc", "entries"},
    "key-items": {"$schema", "_doc", "counts-per-land-s", "special-accessories-x", "entries"},
    "pet-food": {"$schema", "_doc", "rules", "shop-set", "foods", "cut"},
    "affixes": {"$schema", "_doc", "common", "uncommon", "rare", "epic", "legendary",
                "name-forms", "plus-suffix", "examples"},
    "economy": {"$schema", "currency", "incomes", "prices", "shops", "rules", "loot",
                "gaps", "gaps-decided"},
    "npc-roles": {"$schema", "dialogue-corpus", "entries"},
    "mission-types": {"$schema", "alpha", "steam"},
}
NESTED_FIELDS = {
    "npc-dialogue-corpus-source": {"known-lines", "mechanics"},
    "key-item-counts-source": {"movement", "ticket", "total-max", "gnome-suppliers", "books"},
    "key-item-cut-summary-source": {"name", "alpha-type", "list", "versions"},
    "ingredient-unused-data": {"entries"},
    "ingredient-unused-entry": {"key", "value"},
    "mission-alpha-source": {"entries"},
    "mission-steam-source": {"_shared", "region-completion-order", "entries"},
    "mission-shared-source": {"discover", "tiers", "reward", "repeat", "completed"},
}
MAP_OWNERS = {
    "item-types-source", "materials-source", "ingredients-source", "crafting-stations-source",
    "consumables-source", "key-items-source", "npc-roles-source", "ingredient-unused-data",
    "mission-alpha-source", "mission-steam-source",
}


class FixedSectionsTests(unittest.TestCase):
    def assert_section_declarations(self, view):
        for owner, fields in NESTED_FIELDS.items():
            slots = {slot.alias or slot.name: slot for slot in view.class_induced_slots(owner)}
            self.assertEqual(set(slots), fields, owner)
            self.assertEqual({key for key, slot in slots.items() if slot.required}, fields, owner)
            self.assertFalse(view.get_class(owner).extra_slots)
        for owner in MAP_OWNERS:
            self.assertEqual(view.get_class(owner).annotations["source-map-entries"].value, "entries")
        for owner, alias, target in (
                ("npc-roles-source", "dialogue-corpus", "npc-dialogue-corpus-source"),
                ("key-items-source", "counts-per-land-s", "key-item-counts-source"),
                ("key-items-source", "special-accessories-x", "key-item-cut-summary-source"),
                ("ingredients-source", "_unused-data", "ingredient-unused-data"),
                ("mission-types-source", "alpha", "mission-alpha-source"),
                ("mission-types-source", "steam", "mission-steam-source"),
                ("mission-steam-source", "_shared", "mission-shared-source")):
            slot = next(s for s in view.class_induced_slots(owner) if (s.alias or s.name) == alias)
            self.assertEqual((slot.range, slot.required, slot.inlined, slot.multivalued),
                             (target, True, True, None))
            self.assertFalse(slot.any_of or slot.exactly_one_of)
        npc = view.induced_slot("value", "npc-role-source-entry")
        self.assertEqual(npc.range, "npc-role-source-row")
        self.assertFalse(npc.any_of)
        key_item = view.induced_slot("value", "key-items-source-entry")
        self.assertEqual([branch.range for branch in key_item.any_of],
                         ["key-item-source-row", "key-item-artifact-source"])
        self.assertNotIn("list", view.get_class("key-item-source-row").attributes)
        unused = view.induced_slot("value", "ingredient-unused-entry")
        self.assertEqual((unused.range, unused.required), ("integer", True))
        for owner in ("ingredient-unused-data", "mission-alpha-source", "mission-steam-source"):
            entries = view.induced_slot("entries", owner)
            self.assertEqual((entries.multivalued, entries.inlined, entries.inlined_as_list,
                              entries.minimum_cardinality), (True, True, True, 1))
        self.assertEqual(view.induced_slot("value", "mission-alpha-entry").range, "mission-alpha-row")
        self.assertEqual(view.get_slot("recipe-map-key").pattern, '^[a-z0-9][a-z0-9|.-]*$')
        for owner, fields, range_, many in (
                ("npc-dialogue-corpus-source", ("known-lines", "mechanics"), "string", True),
                ("key-item-counts-source", ("movement", "ticket", "total-max", "gnome-suppliers", "books"), "integer", None),
                ("key-item-cut-summary-source", ("list", "versions"), "string", True),
                ("key-item-cut-summary-source", ("alpha-type",), "integer", None)):
            for field in fields:
                slot = view.induced_slot(field, owner)
                self.assertEqual((slot.range, slot.required, slot.multivalued), (range_, True, many))

    def test_literal_root_and_nested_policies(self):
        view = SchemaView(str(SCHEMA))
        self.assert_section_declarations(view)
        for name, fields in ROOT_FIELDS.items():
            with self.subTest(root=name):
                assert_declared_root(name + "-source", fields, fields, schema=generated(name + "-source"))
        for owner, fields in NESTED_FIELDS.items():
            with self.subTest(nested=owner):
                assert_declared_root(owner, fields, fields, schema=generated(owner))

    def test_all13_unchanged_sources_roundtrip(self):
        for name, fields in ROOT_FIELDS.items():
            with self.subTest(source=name):
                source = catalog(name)
                assert_declared_root(name + "-source", fields, fields, schema=generated(name + "-source"))
                bound = bind_source(name, source)
                self.assertEqual(unbind_source(name, bound), source)
                validate_source(name, source)
        roles = bind_source("npc-roles", catalog("npc-roles"))
        self.assertEqual({row["key"] for row in roles["entries"]},
                         set(catalog("npc-roles")) - {"$schema", "dialogue-corpus"})
        items = bind_source("key-items", catalog("key-items"))
        self.assertEqual({row["key"] for row in items["entries"]},
                         set(catalog("key-items")) - {"$schema", "_doc", "counts-per-land-s", "special-accessories-x"})
        missions = bind_source("mission-types", catalog("mission-types"))
        self.assertEqual(missions["alpha"]["entries"], [
            {"key": key, "value": value} for key, value in catalog("mission-types")["alpha"].items()])
        self.assertEqual(catalog("mission-types")["alpha"]["quests-cut"]["versions"], ["X"])
        self.assertEqual(items["special-accessories-x"]["versions"], ["X"])
        self.assertIsNone(catalog("npc-roles")["gem-trader"]["building"])
        self.assertNotIn("building", catalog("npc-roles")["captive"])

    def test_fixed_sections_reject_missing_null_wrong_shapes_and_rows(self):
        paths = (
            ("npc-roles", ("dialogue-corpus",)),
            ("key-items", ("counts-per-land-s",)),
            ("key-items", ("special-accessories-x",)),
            ("ingredients", ("_unused-data",)),
            ("mission-types", ("alpha",)),
            ("mission-types", ("steam", "_shared")),
        )
        for name, path in paths:
            for replacement in ("omit", None, [], {}, True, 3, "wrong"):
                bad = deepcopy(catalog(name))
                node = bad
                for key in path[:-1]:
                    node = node[key]
                if replacement == "omit":
                    del node[path[-1]]
                else:
                    node[path[-1]] = replacement
                with self.subTest(source=name, path=path, value=replacement), self.assertRaises(
                        jsonschema.ValidationError):
                    validate_source(name, bad)
        for name, section, row in (("npc-roles", "dialogue-corpus", "villager"),
                                   ("key-items", "counts-per-land-s", "boat"),
                                   ("key-items", "special-accessories-x", "boat")):
            source = catalog(name)
            for bad in (dict(source, **{section: source[row]}),
                        dict(source, **{"future-content": source[section]})):
                with self.subTest(source=name, section=section), self.assertRaises(jsonschema.ValidationError):
                    validate_source(name, bad)
            bound = bind_source(name, source)
            bound["entries"].append({"key": section, "value": source[row]})
            with self.assertRaises(jsonschema.ValidationError):
                unbind_source(name, bound)

    def test_fixed_section_missing_members_and_guide_policy(self):
        for name, section in (("npc-roles", "dialogue-corpus"), ("key-items", "counts-per-land-s"),
                              ("key-items", "special-accessories-x")):
            source = catalog(name)
            for key in source[section]:
                bad = deepcopy(source)
                del bad[section][key]
                with self.subTest(section=section, missing=key), self.assertRaises(jsonschema.ValidationError):
                    validate_source(name, bad)
        for replacement in (None, {}, True, 3, "wrong", ["guide", 1], "omit"):
            raw = deepcopy(catalog("mission-types"))
            if replacement == "omit":
                del raw["steam"]["region-completion-order"]
            else:
                raw["steam"]["region-completion-order"] = replacement
            with self.subTest(guide=replacement), self.assertRaises(jsonschema.ValidationError):
                validate_source("mission-types", raw)
        raw = deepcopy(catalog("mission-types"))
        raw["steam"]["region-completion-order"] = []
        validate_source("mission-types", raw)  # Existing declaration selects no minimum length.
        self.assertEqual(unbind_source("mission-types", bind_source("mission-types", raw)), raw)

    def test_unseen_keys_and_typed_unused_table(self):
        for name, path, value in (
                ("npc-roles", (), {"name": "Future role", "versions": ["S"]}),
                ("key-items", (), {"name": "Future item", "versions": ["X"]}),
                ("ingredients", (), {"name": "Future ingredient"}),
                ("ingredients", ("_unused-data",), 15),
                ("mission-types", ("alpha",), {"name": "Future cut quest", "versions": ["X"]}),
                ("mission-types", ("steam",), {"name": "Future mission", "icon": None})):
            raw = deepcopy(catalog(name))
            node = raw
            for key in path:
                node = node[key]
            node["future-content-key"] = value
            validate_source(name, raw)
            self.assertEqual(unbind_source(name, bind_source(name, raw)), raw)
        for replacement in (None, True, False, 1.5, "3", [], {}, {"value": 3}):
            raw = deepcopy(catalog("ingredients"))
            raw["_unused-data"]["future-content-key"] = replacement
            with self.subTest(unused=replacement), self.assertRaises(jsonschema.ValidationError):
                validate_source("ingredients", raw)
        for section, field, replacement in (
                ("counts-per-land-s", "books", True),
                ("counts-per-land-s", "movement", None),
                ("special-accessories-x", "alpha-type", [21]),
                ("special-accessories-x", "list", ["key", 1]),
                ("special-accessories-x", "versions", "X")):
            raw = deepcopy(catalog("key-items"))
            raw[section][field] = replacement
            with self.subTest(section=section, field=field), self.assertRaises(jsonschema.ValidationError):
                validate_source("key-items", raw)

    def test_actual_yaml_fixed_section_mutations(self):
        self.assert_section_declarations(SchemaView(str(SCHEMA)))
        mutations = (
            ("catalog-crafting-social.yaml", "npc-roles-source", "dialogue-corpus", "required", False),
            ("catalog-crafting-social.yaml", "npc-roles-source", "dialogue-corpus", "range", "npc-role-source-row"),
            ("catalog-crafting-social.yaml", "npc-role-source-entry", "value", "range", "npc-dialogue-corpus-source"),
            ("items.yaml", "key-items-source", "counts-per-land-s", "required", False),
            ("items.yaml", "key-items-source", "special-accessories-x", "range", "key-item-source-row"),
            ("items.yaml", "key-items-source-entry", "value", "any_of", [{"range": "key-item-counts-source"}]),
            ("items.yaml", "ingredient-unused-entry", "value", "range", "string"),
            ("catalog-properties.yaml", "mission-steam-source", "shared", "required", False),
            ("catalog-properties.yaml", "mission-alpha-source", "entries", "minimum_cardinality", 0),
        )
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            shutil.copytree(SCHEMA.parent, target)
            for filename, owner, attribute, facet, value in mutations:
                path = target / filename
                original = path.read_text()
                data = yaml.safe_load(original)
                data["classes"][owner]["attributes"][attribute][facet] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(owner=owner, facet=facet), self.assertRaises(AssertionError):
                    self.assert_section_declarations(SchemaView(str(target / "pixlnd.yaml")))
                path.write_text(original)


if __name__ == "__main__":
    unittest.main()
