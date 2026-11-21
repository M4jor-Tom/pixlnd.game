"""Exactly 24 world catalog properties; raw text is not resolved relation data."""
import json
import shutil
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import catalog, validate, validator

# Literal source-backed facet oracles, not an alternate validation engine.
FIELDS = {
    "block-type": [("solid", "boolean", False)],
    "terrain-feature": [("name", "string", False), ("named", None, False)],
    "flora": [("name", "string", False), ("aid", "integer", False),
              ("lands", "string", True), ("variants", "string", True)],
    "deposit": [("aid", "integer", False), ("yields", "ingredient", False),
                ("lands", "string", True)],
    "dungeon-type": [("name", "string", False), ("naming", "string", True),
                     ("lands", "string", True), ("entrance", "string", False),
                     ("rosters", "string", True), ("natural", "boolean", False),
                     ("boss", "string", False)],
    "poi-type": [("name", "string", False), ("map", "string", False),
                 ("contents", "string", True), ("lands", "string", True),
                 ("variants", "string", True), ("static-id", "integer", False),
                 ("static-ids", "integer", True)],
}
FILES = {"block-type": "block-types", "terrain-feature": "terrain-features",
         "flora": "flora", "deposit": "deposits", "dungeon-type": "dungeon-types",
         "poi-type": "poi-types"}


def sample(range_, multiple):
    value = {"boolean": False, "integer": 0, "string": "qualified (text)",
             "ingredient": "iron-nugget", None: True}[range_]
    return [value] if multiple else value


PAIR_FIELDS = ("alpha-loc", "quarter")


def assert_pair_facets(self, view):
    for field in PAIR_FIELDS:
        name = "poi-type-" + field
        self.assertIn(name, view.class_slots("poi-type"))
        slot = view.induced_slot(name, "poi-type")
        self.assertEqual((slot.alias, slot.domain, slot.range), (field, "poi-type", "integer"))
        self.assertEqual(str(slot.slot_uri), "pixlnd:poi-type/" + field)
        self.assertTrue(slot.multivalued)
        self.assertFalse(slot.required or slot.key or slot.identifier or slot.inlined)
        self.assertFalse(slot.inlined_as_list or slot.list_elements_unique)
        self.assertEqual((slot.minimum_cardinality, slot.maximum_cardinality), (2, 2))
        for facet in ("minimum_value", "maximum_value", "exact_cardinality"):
            self.assertIsNone(getattr(slot, facet))
        self.assertIn("../domain/3_Classes.md#poi-type", slot.see_also)
        self.assertIn("../instances/poi-types.json", slot.see_also)


def verify_field_facets(self, view, owner, field, range_, multiple):
    name = owner + "-" + field
    self.assertIn(name, view.class_slots(owner))
    slot = view.induced_slot(name, owner)
    expected_range = "string" if (owner, field) == ("terrain-feature", "named") else range_
    self.assertEqual((slot.alias, slot.domain, slot.range), (field, owner, expected_range))
    if (owner, field) == ("terrain-feature", "named"):
        authored = yaml.safe_load((SCHEMA.parent / "world-catalog.yaml").read_text())
        self.assertNotIn("range", authored["slots"][name])
    self.assertEqual(str(slot.slot_uri), "pixlnd:" + owner + "/" + field)
    self.assertEqual(bool(slot.multivalued), multiple)
    self.assertFalse(slot.required or slot.key or slot.identifier or slot.inlined)
    self.assertIsNone(slot.minimum_value)
    self.assertIsNone(slot.maximum_value)
    self.assertIsNone(slot.minimum_cardinality)
    self.assertIsNone(slot.maximum_cardinality)
    self.assertIn("../domain/3_Classes.md#" + owner, slot.see_also)
    self.assertTrue(any(FILES[owner] + ".json" in s for s in slot.see_also))
    validate(owner, {"id": "example", field: sample(range_, multiple)})
    validate(owner, {"id": "example"})
    # Native optional-null alternatives are NOT source-null equivalence.
    validate(owner, {"id": "example", field: None})
    malformed = [True, 1, "text", {}, [True], [None], [["text"]], [{}]] if multiple else {
        "boolean": [0, 1, "false", [], {}],
        "integer": [True, "0", 1.5, [], {}],
        "string": [True, 0, [], {}],
        "ingredient": [True, 0, [], {}, {"id": "iron-nugget"}],
        None: [0, 1.5, [], {}],
    }[range_]
    if multiple:
        malformed += [["0"], [0.5]] if range_ == "integer" else [[1]]
    for bad in malformed:
        with self.subTest(bad=bad), self.assertRaises(jsonschema.ValidationError):
            validate(owner, {"id": "example", field: bad})
    if multiple:
        validate(owner, {"id": "example", field: []})
    if range_ == "boolean":
        validate(owner, {"id": "example", field: True})
    if range_ == "integer":
        value = [-1, 1000000] if multiple else -1
        validate(owner, {"id": "example", field: value})


class WorldCatalogTests(unittest.TestCase):
    def test_selected_native_facets_and_limits(self):
        view = SchemaView(str(SCHEMA))
        self.assertEqual(sum(map(len, FIELDS.values())), 24)
        for owner, fields in FIELDS.items():
            for field, range_, multiple in fields:
                with self.subTest(owner=owner, field=field):
                    verify_field_facets(self, view, owner, field, range_, multiple)
            for row in ({}, {"id": None}):
                with self.assertRaises(jsonschema.ValidationError):
                    validate(owner, row)
        named = view.get_slot("terrain-feature-named")
        self.assertEqual([b.range for b in named.any_of], ["boolean", "string"])
        emitted = validator("terrain-feature").schema["$defs"]["terrain-feature"]["properties"]["named"]
        self.assertEqual({b["type"] for b in emitted["anyOf"]}, {"boolean", "string", "null"})
        for value in (False, True, "as landmark 'Mountain', 'Peak'"):
            validate("terrain-feature", {"id": "example", "named": value})
        # Target is typed, but JSON Schema still cannot enforce existence.
        self.assertNotIn("not-an-ingredient", catalog("ingredients"))
        validate("deposit", {"id": "example", "yields": "not-an-ingredient"})
        for owner, field in [("flora", "lands"), ("deposit", "lands"),
                             ("dungeon-type", "rosters"), ("poi-type", "contents")]:
            validate(owner, {"id": "example", field: ["not-a-resolved-id (qualifier)"]})

    def test_unchanged_ordinary_row_projections(self):
        for owner, excluded, count in [
            ("block-type", {"flags"}, 16),
            ("terrain-feature", {"$schema"}, 24),
            ("flora", {"$schema", "_doc"}, 24),
            ("deposit", {"$schema", "_doc"}, 9),
            ("dungeon-type", {"$schema", "_doc", "_dungeon-rules"}, 24),
            ("poi-type", {"$schema"}, 28),
        ]:
            rows = catalog(FILES[owner])
            if owner == "block-type":
                self.assertEqual(set(rows), {"$schema", "_doc", "alpha", "steam", "scale", "cub-format"})
                rows = rows["alpha"]
            self.assertTrue(excluded <= rows.keys())
            ordinary = rows.keys() - excluded
            self.assertEqual(len(ordinary), count)
            fields = [f for f, _, _ in FIELDS[owner]]
            for key in sorted(ordinary):
                source = rows[key]
                row = {field: source[field] for field in fields if field in source}
                # Alpha numeric outer keys are source indices, not stable identities.
                row["id"] = source["id"] if owner == "block-type" else key
                validate(owner, row)
                if owner == "block-type":
                    self.assertNotEqual(row["id"], key)
        self.assertEqual(catalog("poi-types")["revival-statue"]["static-id"], 0)
        self.assertEqual(catalog("static-entities")["by-id"]["0"], "statue")
        self.assertEqual(catalog("poi-types")["streetlight"]["static-ids"], [50, 51])
        validate("poi-type", {"id": "example", "static-ids": [1]})
        targets = {row["yields"] for row in catalog("deposits").values()
                   if isinstance(row, dict) and "yields" in row}
        # Characterize inherited source gap, not a permanent exemption: update when
        # separately authorized reconciliation supplies the missing ingredient.
        self.assertEqual(targets - catalog("ingredients").keys(), {"sandstone"})
        self.assertEqual(len(targets & catalog("ingredients").keys()), 8)
        validate("deposit", {"id": "sandstone-deposit", "yields": "sandstone"})

    def test_actual_yaml_mutation_controls(self):
        cases = []
        for owner, fields in FIELDS.items():
            for field, range_, multiple in fields:
                if range_ is not None:
                    cases.append((owner, field, "range", "integer" if range_ in ("string", "ingredient") else "string",
                                  {field: sample(range_, multiple)}))
        cases += [
            ("poi-type", "map", "alias", "wrong-map", {"map": "skull"}),
            ("flora", "lands", "multivalued", False, {"lands": ["most"]}),
            ("deposit", "yields", "attachment", None, {"yields": "iron-nugget"}),
            ("dungeon-type", "name", "required", True, {}),
            ("terrain-feature", "named", "any_of", [{"range": "boolean"}], {"named": "'Peak'"}),
            ("terrain-feature", "named", "any_of", [{"range": "string"}], {"named": False}),
        ]
        for owner, field, facet, value, properties in cases:
            row = dict(properties, id="example")
            validate(owner, row)
            with self.subTest(owner=owner, field=field, facet=facet), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                shutil.copytree(SCHEMA.parent, target)
                module = target / "world-catalog.yaml"
                data = yaml.safe_load(module.read_text())
                name = owner + "-" + field
                if facet == "attachment":
                    data["classes"][owner]["slots"].remove(name)
                else:
                    data["slots"][name][facet] = value
                module.write_text(yaml.safe_dump(data, sort_keys=False))
                schema = json.loads(JsonSchemaGenerator(
                    str(target / "pixlnd.yaml"), top_class=owner, preserve_names=True,
                    not_closed=False).serialize())
                cls = jsonschema.validators.validator_for(schema)
                cls.check_schema(schema)
                with self.assertRaises(jsonschema.ValidationError):
                    cls(schema).validate(row)


class PoiPairTests(unittest.TestCase):
    def test_pair_contract(self):
        assert_pair_facets(self, SchemaView(str(SCHEMA)))

    def test_pair_emitted_properties(self):
        schema = validator("poi-type").schema
        self.assertTrue(set(PAIR_FIELDS) <= schema["properties"].keys())
        for field in PAIR_FIELDS:
            emitted = schema["properties"][field]
            self.assertEqual(emitted["type"], ["array", "null"])
            self.assertEqual((emitted["minItems"], emitted["maxItems"]), (2, 2))
            self.assertEqual(emitted["items"], {"type": "integer"})

    def test_pair_source_projections(self):
        rows = catalog("poi-types")
        self.assertEqual(rows["portal"]["alpha-loc"], [10, 0])
        self.assertEqual(rows["portal"]["quarter"], [4, 0])
        ordinary = rows.keys() - {"$schema"}
        self.assertEqual(len(ordinary), 28)
        self.assertEqual([key for key in ordinary if any(f in rows[key] for f in PAIR_FIELDS)], ["portal"])
        for key in sorted(ordinary):
            source = rows[key]
            row = dict({f: source[f] for f in PAIR_FIELDS if f in source}, id=key)
            for field in PAIR_FIELDS:
                if field in row:
                    self.assertTrue(all(type(v) is int for v in row[field]))
            validate("poi-type", row)
        with self.assertRaises(jsonschema.ValidationError):
            validate("poi-type", rows["portal"])

    def test_pair_native_boundaries(self):
        for field in PAIR_FIELDS:
            validate("poi-type", {"id": "example"})
            # Native optional null is broader than observed source; [] is not omission.
            for value in (None, [0, 0], [-1, 1000000000000], [41, -23]):
                validate("poi-type", {"id": "example", field: value})
            for bad in ([], [0], [0, 1, 2], [0, 1, 2, 3], [True, 0], [0, False],
                        ["0", 0], [0, "1"], [0.5, 0], [0, 0.5], True, 0, "0", {}, [[10, 0]], [[1], [0]]):
                with self.subTest(field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    validate("poi-type", {"id": "example", field: bad})
            for row in ({field: [10, 0]}, {"id": None, field: [10, 0]},
                        {"id": "example", field: [10, 0], "unknown": 0}):
                with self.assertRaises(jsonschema.ValidationError):
                    validate("poi-type", row)
        validate("poi-type", {"id": "example", "static-ids": [1]})

    def test_pair_actual_yaml_mutations(self):
        for field in PAIR_FIELDS:
            cases = [("minimum_cardinality", None, [0]), ("minimum_cardinality", 1, [0]),
                     ("maximum_cardinality", None, [0, 1, 2]), ("maximum_cardinality", 3, [0, 1, 2]),
                     ("range", "string", [10, 0]), ("multivalued", False, [10, 0]),
                     ("alias", "wrong", [10, 0]), ("attachment", None, [10, 0]),
                     ("required", True, None)]
            for facet, value, pair in cases:
                row = {"id": "example"} if facet == "required" else {"id": "example", field: pair}
                baseline_valid = validator("poi-type").is_valid(row)
                self.assertEqual(baseline_valid, facet not in ("minimum_cardinality", "maximum_cardinality"))
                with self.subTest(field=field, facet=facet, value=value), tempfile.TemporaryDirectory() as scratch:
                    target = Path(scratch) / "schema"
                    shutil.copytree(SCHEMA.parent, target)
                    path = target / "world-catalog.yaml"
                    data = yaml.safe_load(path.read_text())
                    name = "poi-type-" + field
                    if facet == "attachment":
                        data["classes"]["poi-type"]["slots"].remove(name)
                    elif value is None:
                        del data["slots"][name][facet]
                    else:
                        data["slots"][name][facet] = value
                    path.write_text(yaml.safe_dump(data, sort_keys=False))
                    with self.assertRaises(AssertionError):
                        assert_pair_facets(self, SchemaView(str(target / "pixlnd.yaml")))
                    schema = json.loads(JsonSchemaGenerator(
                        str(target / "pixlnd.yaml"), top_class="poi-type", preserve_names=True,
                        not_closed=False).serialize())
                    cls = jsonschema.validators.validator_for(schema)
                    cls.check_schema(schema)
                    self.assertNotEqual(cls(schema).is_valid(row), baseline_valid)


class FullWorldSources(unittest.TestCase):
    def assert_source(self, name, fields, mutations):
        from ontology_source_contracts import (
            bind_source,
            unbind_source,
            validate_source,
        )
        from test_ontology_schema_contracts import assert_root

        row = catalog(name)
        assert_root(self, name + "-source", fields, fields)
        self.assertEqual(unbind_source(name, bind_source(name, row)), row)
        validate_source(name, row)
        for path, value in mutations:
            bad = deepcopy(row)
            node = bad
            for part in path[:-1]:
                node = node[part]
            node[path[-1]] = value
            with self.subTest(source=name, path=path, value=value), self.assertRaises(jsonschema.ValidationError):
                validate_source(name, bad)
        for bad in (None, [], {}, dict(row, _unknown={})):
            with self.subTest(source=name, root=bad), self.assertRaises(jsonschema.ValidationError):
                validate_source(name, bad)

    def test_whole_landscapes_source(self):
        self.assert_source("landscapes", {"$schema", "_doc", "_shared", "entries"}, [
            (("greenlands", "gen", "top"), "green"), (("greenlands", "gen", "base"), "0"),
            (("greenlands", "gen", "surface"), {}), (("greenlands", "gen"), {}),
            (("greenlands", "climate", "temp"), 36), (("greenlands", "climate"), None),
            (("deserts", "notes"), "resolved ruins"), (("deserts", "dungeons"), [None]),
            (("swamp-lands", "note"), []), (("swamp-lands", "versions"), [None]),
            (("_shared", "village-styles"), None), (("greenlands", "unknown"), True)])
        self.assertIn("unresolved", catalog("landscapes")["deserts"]["notes"][0])
        self.assertEqual(catalog("landscapes")["swamp-lands"]["versions"], ["S?"])

    def test_whole_terrain_features_source(self):
        self.assert_source("terrain-features", {"$schema", "entries"}, [
            (("mountain", "name"), None), (("mountain", "named"), 1),
            (("road", "desc"), []), (("overhang", "versions"), "A"),
            (("mountain", "unknown"), 1)])
        self.assertIn("unknown", catalog("terrain-features")["overhang"]["desc"])

    def test_whole_flora_source(self):
        self.assert_source("flora", {"$schema", "_doc", "entries"}, [
            (("bush", "aid"), "120"), (("bush", "yields", "wood-log"), [1]),
            (("bush", "yields", "wood-log"), [1, "3"]), (("bush", "yields"), None),
            (("bush", "yields", "wood-log"), [1, 2, 3]),
            (("apple-tree", "yields", "apple"), "N"), (("bush", "lands"), {}),
            (("bush", "unknown"), True)])
        self.assertEqual(catalog("flora")["apple-tree"]["yields"], {"apple": "n"})

    def test_whole_deposits_source_and_missing_sandstone_target(self):
        self.assert_source("deposits", {"$schema", "_doc", "entries"}, [
            (("sandstone-deposit", "yields"), []), (("sandstone-deposit", "aid"), "134"),
            (("sandstone-deposit", "yields"), None), (("iron-deposit", "note"), {}),
            (("gold-deposit", "unknown"), 1)])
        view = SchemaView(str(SCHEMA))
        self.assertEqual(view.induced_slot("yields", "deposit-source-row").range, "ingredient")
        self.assertEqual(view.get_slot("deposit-yields").range, "ingredient")
        self.assertEqual(catalog("deposits")["sandstone-deposit"]["yields"], "sandstone")
        self.assertNotIn("sandstone", catalog("ingredients"))

    def test_whole_poi_types_source(self):
        self.assert_source("poi-types", {"$schema", "entries"}, [
            (("portal", "alpha-loc"), [10]), (("portal", "alpha-loc"), [10, "0"]),
            (("portal", "alpha-loc"), [[10, 0], [4, 0]]),
            (("portal", "quarter"), [4, 0, 1]), (("portal", "quarter"), [True, 0]),
            (("portal", "quarter"), None), (("streetlight", "static-ids"), ["50"]),
            (("campsite", "contents"), {}), (("portal", "unknown"), 1)])

    def test_whole_dungeon_types_source(self):
        self.assert_source("dungeon-types", {"$schema", "_doc", "_dungeon-rules", "entries"}, [
            (("castle", "alpha-loc"), [14]), (("castle", "alpha-loc"), [14, 0, 1]),
            (("castle", "alpha-loc"), ["0-9", 14]), (("castle", "alpha-loc"), [True, 0]),
            (("castle", "alpha-loc"), [14, None]), (("castle", "alpha-loc"), None),
            (("castle", "alpha-loc"), {"first": 14, "second": 0}),
            (("castle", "alpha-loc"), [[5, 0], 1]), (("ruins", "alpha-loc"), [[5], [14, 1]]),
            (("ruins", "alpha-loc"), [[5, 0], [14, 1, 2]]),
            (("ruins", "alpha-loc"), [[5, "0-9"], [14, 1]]),
            (("castle", "contents", "S"), "artifact"), (("castle", "contents"), {"A": []}),
            (("ruins", "variants", "dungeon-ruins"), 1), (("sewer", "contents"), [None]),
            (("_dungeon-rules", "A"), None), (("castle", "unknown"), True)])
        from ontology_source_contracts import (
            bind_source,
            unbind_source,
            validate_source,
        )
        from test_ontology_schema_contracts import assert_root
        for owner in ("source-integer-pair", "source-alpha-location-pair", "source-alpha-location-pair-pair"):
            assert_root(self, owner, {"first", "second"}, {"first", "second"})
        location = SchemaView(str(SCHEMA)).induced_slot("alpha-loc", "dungeon-source-row")
        self.assertEqual(location.annotations["source-tuple-positions"].value, "first second")
        row = catalog("dungeon-types")
        self.assertEqual(row["ruins"]["alpha-loc"], [[5, 0], [14, 1]])
        self.assertEqual(row["forest-dungeon"]["alpha-loc"], [3, "0-9"])
        del row["castle"]["alpha-loc"]
        validate_source("dungeon-types", row)
        bound = bind_source("dungeon-types", row)
        ruined = next(e["value"] for e in bound["entries"] if e["key"] == "ruins")
        ruined["alpha-loc"]["third"] = 1
        with self.assertRaises(jsonschema.ValidationError):
            unbind_source("dungeon-types", bound)


if __name__ == "__main__":
    unittest.main()
