"""Typed realm, land bounds, spawn clock and encounter geometry world schema tests."""
from copy import deepcopy
import unittest

import jsonschema
from linkml_runtime.utils.schemaview import SchemaView

from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import validate


def verify_realm_component(self, view, owner, fields, expected):
    from ontology_source_contracts import assert_declared_root

    assert_declared_root(owner, fields, set())
    for alias, range_ in expected.items():
        slot = view.induced_slot(owner + "-" + alias, owner)
        self.assertEqual((slot.alias, slot.domain, slot.range), (alias, owner, range_))
        self.assertFalse(slot.required or slot.inlined or slot.multivalued)
        self.assertIsNone(slot.minimum_value)
        self.assertIsNone(slot.maximum_value)
    row = {"name": "Named place/person"}
    row.update({alias: -42 if range_ == "integer" else "identified-place"
                for alias, range_ in expected.items()})
    validate(owner, row)
    validate(owner, {})
    for alias, range_ in expected.items():
        for value in (["year", True, 1.5, [], {}] if range_ == "integer" else [1, True, [], {}]):
            with self.subTest(owner=owner, alias=alias, value=value), self.assertRaises(jsonschema.ValidationError):
                validate(owner, dict(row, **{alias: value}))
    with self.assertRaises(jsonschema.ValidationError):
        validate(owner, dict(row, age=42))


class LogicalWorldTests(unittest.TestCase):
    def test_typed_realm_components(self):
        view = SchemaView(str(SCHEMA))
        for owner, fields, expected in (
            ("realm-leader", {"name", "personality-trait", "birth-year", "hometown", "tomb-location"},
             {"birth-year": "integer", "hometown": "settlement", "tomb-location": "poi"}),
            ("realm-capital", {"name", "founding-year", "destruction-date"},
             {"founding-year": "integer", "destruction-date": "integer"}),
        ):
            verify_realm_component(self, view, owner, fields, expected)
        slot_name = "realm-capital-destruction-date"
        self.assertEqual(view.get_class("realm-capital").slots.count(slot_name), 1)
        slot = view.induced_slot(slot_name, "realm-capital")
        self.assertIs(view.get_slot(slot_name).required, False)
        self.assertEqual(str(slot.slot_uri), "pixlnd:realm-capital/destruction-date")
        self.assertIn("../domain/3_Classes.md#realm", slot.see_also)
        self.assertIsNone(slot.ifabsent)
        for year in (-1000000, 0, 1000000):
            validate("realm-capital", {"founding-year": 42, "destruction-date": year})
        # Native optional null is not a historical source-wire guarantee.
        validate("realm-capital", {"destruction-date": None})
        for value in (None, True, 42, "capital", []):
            with self.subTest(capital=value), self.assertRaises(jsonschema.ValidationError):
                validate("realm-capital", value)

    def test_world_land_bounds_and_context_facets(self):
        from ontology_source_contracts import assert_declared_root

        world_fields = {"id", "seed", "day", "time-ms", "spawn-rule", "name", "origin-poi", "discovered-zones"}
        assert_declared_root("world", world_fields, {"id", "seed", "day", "time-ms", "spawn-rule", "discovered-zones"})
        world = {"id": "world-a", "seed": 0, "day": 1, "time-ms": 0, "spawn-rule": "near-village", "discovered-zones": []}
        validate("world", world)
        for field, value in (("seed", -1), ("seed", 4294967296), ("time-ms", -1), ("time-ms", 86400001)):
            with self.subTest(field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                validate("world", dict(world, **{field: value}))
        land = {"id": "land-a", "name": "Plain", "landscape": "greenlands", "level": 1,
                "danger-tier": "normal", "coords": [-512, 511], "settlements": ["village"]}
        fields = {"id", "name", "landscape", "level", "danger-tier", "coords", "settlements", "tier-range", "rarity", "realm",
                  "key-items", "gnome-suppliers", "books-of-crafting", "circles-of-power", "artifacts", "wizard-towers", "border"}
        assert_declared_root("land", fields, {"id", "name", "landscape", "level", "danger-tier", "coords", "settlements"})
        validate("land", land)
        for field, good, bad in (("coords", [-512, 511], [[-513, 0], [0, 512], [0], [0, "1"]]),
                                 ("settlements", ["v"], [[], ["a", "b"]]),
                                 ("key-items", ["a"] * 9, [["a"] * 10]),
                                 ("gnome-suppliers", ["a"] * 4, [["a"] * 3, ["a"] * 5]),
                                 ("books-of-crafting", ["a"] * 4, [["a"] * 3]),
                                 ("wizard-towers", 5, [-1, 6, "5"]),
                                 ("rarity", 4, [-1, 5]), ("circles-of-power", ["a"], [[]]),
                                 ("artifacts", ["a"], [[]])):
            validate("land", dict(land, **{field: good}))
            for value in bad:
                with self.subTest(field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                    validate("land", dict(land, **{field: value}))
        view = SchemaView(str(SCHEMA))
        self.assertEqual(view.induced_slot("style", "settlement").range, "settlement-style")
        self.assertEqual(view.induced_slot("population-races", "settlement").range, "race")
        self.assertEqual(view.induced_slot("population-animals", "settlement").range, "creature")

    def test_precise_field_spawn_clock_and_orientation(self):
        from ontology_source_contracts import assert_declared_root

        assert_declared_root("field", {"base-z", "blocks"}, {"base-z", "blocks"})
        row = {"base-z": -10, "blocks": [{"id": "block-a", "type": "grass", "rgb": [0, 127, 255], "breakable": False}]}
        validate("field", row)
        for path, value in [(("base-z",), "0"), (("blocks",), None), (("blocks",), [None]),
                            (("blocks", 0, "rgb"), [0, 256, 0]), (("blocks", 0, "rgb"), [0, 1]),
                            (("blocks", 0, "rgb"), [0, True, 0])]:
            bad = deepcopy(row)
            node = bad
            for part in path[:-1]:
                node = node[part]
            node[path[-1]] = value
            with self.subTest(path=path), self.assertRaises(jsonschema.ValidationError):
                validate("field", bad)
        view = SchemaView(str(SCHEMA))
        expected = {"hostility", "type", "class", "spec", "level", "power-base", "appearance", "equipment", "name"}
        assert_declared_root("creature-spawn", expected, {"hostility", "type", "level", "power-base", "appearance"})
        self.assertEqual(view.induced_slot("entity-species", "creature-spawn").range, "race-or-creature")
        self.assertEqual(view.induced_slot("entity-equipment", "creature-spawn").maximum_cardinality, 13)
        self.assertEqual(view.induced_slot("spawns", "zone").range, "creature-spawn")
        self.assertEqual(view.induced_slot("columns", "zone").range, "field")
        validate("static-entity", {"id": "door", "orientation": 0})
        for value in (-1, 4, "0", False):
            with self.subTest(orientation=value), self.assertRaises(jsonschema.ValidationError):
                validate("static-entity", {"id": "door", "orientation": value})
        assert_declared_root("game-clock", {"speed", "initial-time-ms", "reference-sleep-speed"}, {"speed", "initial-time-ms"})
        validate("game-clock", {"speed": 10, "initial-time-ms": 25200000, "reference-sleep-speed": 100})
        for field, value in (("speed", 1), ("initial-time-ms", 0), ("reference-sleep-speed", 10)):
            with self.subTest(clock=field), self.assertRaises(jsonschema.ValidationError):
                validate("game-clock", {"speed": 10, "initial-time-ms": 25200000, field: value})

    def test_encounter_geometry_and_population(self):
        from ontology_source_contracts import assert_declared_root

        for owner, width, depth, above in (("ruins-room-volume", 24, 24, 12), ("ruins-corridor-volume", 8, 8, 12),
                                         ("ruins-court-volume", 24, 16, 12), ("ruins-passage-volume", 8, 8, 12),
                                         ("ruins-alcove-volume", 12, 8, 12), ("camp-battlefield-volume", 64, 64, 16),
                                         ("rescue-battlefield-volume", 48, 48, 16)):
            row = {"width": width, "depth": depth, "below-floor": 1, "above-floor": above}
            assert_declared_root(owner, set(row), set(row))
            validate(owner, row)
            for field in row:
                bad = dict(row, **{field: row[field] + 1})
                with self.subTest(owner=owner, field=field), self.assertRaises(jsonschema.ValidationError):
                    validate(owner, bad)
                with self.assertRaises(jsonschema.ValidationError):
                    validate(owner, {k: v for k, v in row.items() if k != field})
            with self.assertRaises(jsonschema.ValidationError):
                validate(owner, dict(row, closed=False))  # Closedness is not a gameplay toggle.
        for owner, packs, bosses, hostiles, captives in (("ruins-population", 3, 2, 11, 0),
                                                       ("camp-population", 2, 1, 7, 0), ("rescue-population", 2, 1, 7, 1)):
            row = {"packs": packs, "pack-size": 3, "bosses": bosses, "hostiles": hostiles, "captives": captives}
            assert_declared_root(owner, set(row), set(row))
            validate(owner, row)
            for field in row:
                with self.subTest(owner=owner, field=field), self.assertRaises(jsonschema.ValidationError):
                    validate(owner, dict(row, **{field: row[field] + 1}))


if __name__ == "__main__":
    unittest.main()
