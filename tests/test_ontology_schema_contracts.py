"""Selected-root guards; full source families are added with their contracts."""

import filecmp
import json
import shutil
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path
from unittest.mock import patch

import jsonschema
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
from ontology_source_contracts import (
    assert_declared_root,
    source_contract,
    validate_source,
)
from test_ontology_schema import ROOT, SCHEMA, generated


def assert_root(test: unittest.TestCase, name: str, properties: set[str],
                required: set[str], *, additional_properties: bool | dict = False) -> dict:
    from ontology_source_contracts import assert_declared_root

    view = SchemaView(str(SCHEMA))
    test.assertIn(name, view.all_classes())
    return assert_declared_root(name, properties, required, schema=generated(name), view=view,
                                additional_properties=additional_properties)


class FullInputContracts(unittest.TestCase):
    def test_all_complete_inputs(self):
        paths = sorted((ROOT / "ontology/instances").glob("*.json"))
        self.assertTrue(paths, "No original source inputs")
        for path in paths:
            with self.subTest(path=path.name):
                validate_source(path.stem, json.loads(path.read_text()))

    def test_undeclared_source_is_rejected(self):
        with self.assertRaisesRegex(AssertionError, "Missing declared source class"):
            validate_source("not-a-selected-source", {})

    def test_native_determinism(self):
        names = [p.stem for p in sorted((ROOT / "ontology/instances").glob("*.json"))]
        self.assertTrue(names, "No original source inputs")
        expectations = {}
        for name in names:
            source_contract(name)
            root = name + "-source"
            definition = generated(root)["$defs"][root]
            expectations[root] = (set(definition["properties"]),
                                  set(definition.get("required", [])),
                                  definition["additionalProperties"])
        fields = {"version", "world", "character"}
        assert_declared_root("save-data", fields, fields)
        expectations["save-data"] = (fields, fields, False)
        with tempfile.TemporaryDirectory() as tmp:
            outputs = []
            for copy in ("first", "second"):
                directory = Path(tmp) / copy
                shutil.copytree(SCHEMA.parent, directory / "schema")
                generator = JsonSchemaGenerator(
                    str(directory / "schema/pixlnd.yaml"), preserve_names=True, not_closed=False)
                self.assertTrue(set(expectations) <= set(generator.schemaview.all_classes()))
                for root, (properties, required, policy) in expectations.items():
                    with self.subTest(copy=copy, root=root):
                        generator.top_class = root
                        serialized = generator.serialize()
                        assert_declared_root(root, properties, required,
                                             schema=json.loads(serialized), view=generator.schemaview,
                                             additional_properties=policy)
                        (directory / (root + ".json")).write_text(serialized)
                outputs.append(directory)
            for root in expectations:
                with self.subTest(root=root):
                    self.assertTrue(filecmp.cmp(outputs[0] / (root + ".json"),
                                                outputs[1] / (root + ".json"), shallow=False))

    def test_current_save_full_fixture_and_root(self):
        row = json.loads((ROOT / "tests/fixtures/ontology-schema/current-save.json").read_text())
        fields = {"version", "world", "character"}
        schema = assert_root(self, "save-data", fields, fields)
        jsonschema.Draft201909Validator(schema).validate(row)
        for key in ("version", "world", "character"):
            bad = deepcopy(row)
            del bad[key]
            with self.subTest(key=key), self.assertRaises(jsonschema.ValidationError):
                jsonschema.Draft201909Validator(schema).validate(bad)
        bad = deepcopy(row)
        bad["unexpected-field"] = True
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.Draft201909Validator(schema).validate(bad)

    def test_whole_generators_source(self):
        from ontology_generator_expectations import SOURCE_FIELDS
        from ontology_source_contracts import validate_source
        from test_ontology_schema_authoring import catalog

        assert_root(self, "generators-source", SOURCE_FIELDS, SOURCE_FIELDS)
        row = catalog("generators")
        validate_source("generators", row)

    def test_whole_races_source(self):
        from ontology_source_contracts import (
            bind_source,
            unbind_source,
            validate_source,
        )
        from test_ontology_schema_authoring import catalog

        row = catalog("races")
        assert_root(self, "races-source", {"$schema", "_doc", "_creation", "entries"},
                    {"$schema", "_doc", "_creation", "entries"})
        self.assertEqual(unbind_source("races", bind_source("races", row)), row)
        validate_source("races", row)
        for field, value in (("playable", "true"), ("size-class", "giant"),
                             ("quirks", "text"), ("alpha-entity-ids", []),
                             ("hair", {"m": -1, "f": 0}), ("name", None)):
            bad = deepcopy(row)
            bad["human"][field] = value
            with self.subTest(field=field), self.assertRaises(jsonschema.ValidationError):
                validate_source("races", bad)
        for value in (None, [], "row", True, {}):
            bad = dict(row, human=value)
            with self.subTest(row=value), self.assertRaises(jsonschema.ValidationError):
                validate_source("races", bad)
        for key in ("_unknown", "Bad Key!", ""):
            bad = dict(row, **{key: row["human"]})
            with self.subTest(key=key), self.assertRaises(jsonschema.ValidationError):
                validate_source("races", bad)
        for bad in (None, [], {}, dict(row, _creation=None), dict(row, _doc=[])):
            with self.subTest(root=bad), self.assertRaises(jsonschema.ValidationError):
                validate_source("races", bad)
        # A genuine catalog key named like the binding field must not be discarded.
        collision = dict(row, entries=deepcopy(row["human"]))
        self.assertEqual(unbind_source("races", bind_source("races", collision)), collision)
        validate_source("races", collision)
        bound = bind_source("races", row)
        bound["entries"].append(deepcopy(bound["entries"][0]))
        with self.assertRaises(jsonschema.ValidationError):
            unbind_source("races", bound)
        bound["entries"][-1]["key"] = "_doc"
        with self.assertRaises(jsonschema.ValidationError):
            unbind_source("races", bound)

    def assert_family(self, name, fields, specimen, mutations):
        from ontology_source_contracts import (
            bind_source,
            unbind_source,
            validate_source,
        )
        from test_ontology_schema_authoring import catalog

        row = catalog(name)
        assert_root(self, name + "-source", fields, fields)
        bound = bind_source(name, row)
        self.assertEqual(unbind_source(name, bound), row)
        validate_source(name, row)
        for path, value in mutations:
            bad = deepcopy(row)
            node = bad
            for part in path[:-1]:
                node = node[part]
            node[path[-1]] = value
            with self.subTest(source=name, path=path, value=value):
                with self.assertRaises(jsonschema.ValidationError):
                    validate_source(name, bad)
        for bad in (None, [], {}, dict(row, **{"_unknown": {}})):
            with self.subTest(root=name), self.assertRaises(jsonschema.ValidationError):
                validate_source(name, bad)
        if specimen:
            for value in (None, [], "row", True, {}):
                with self.subTest(row=name, value=value), self.assertRaises(jsonschema.ValidationError):
                    validate_source(name, dict(row, **{specimen: value}))
            for key in ("_unknown", "Bad Key!", ""):
                with self.subTest(key=key), self.assertRaises(jsonschema.ValidationError):
                    validate_source(name, dict(row, **{key: row[specimen]}))
            bad = deepcopy(row)
            bad[specimen]["unrecognized-field"] = True
            with self.assertRaises(jsonschema.ValidationError):
                validate_source(name, bad)
            bad = deepcopy(bound)
            bad["entries"][0]["value"] = None
            from test_ontology_schema_authoring import validate
            with self.assertRaises(jsonschema.ValidationError):
                validate(name + "-source", bad)

    def test_whole_classes_source(self):
        self.assert_family("classes", {"$schema", "_paladin", "_shared", "entries"}, "warrior", [
            (("warrior", "id-number"), 5), (("warrior", "hp-mult"), "1.3"),
            (("warrior", "specializations"), ["berserker"]),
            (("warrior", "special-attack-mode"), "unknown"),
            (("_shared", "spec-change", "A"), []), (("_paladin", "status"), None)])

    def test_whole_specializations_source(self):
        self.assert_family("specializations", {"$schema", "_doc", "entries"}, "assassin", [
            (("assassin", "index"), 2), (("assassin", "class"), {}),
            (("assassin", "kit", "A"), "camouflage"),
            (("assassin", "passives", "S"), [None]), (("assassin", "versions"), ["future"])])

    def test_whole_creatures_source(self):
        self.assert_family("creatures", {"$schema", "_doc", "_playable-races-as-enemies", "entries"}, "collie", [
            (("collie", "aid"), "19"), (("collie", "cat"), "unknown"),
            (("collie", "ride"), "true"), (("collie", "tame"), {}),
            (("collie", "lands"), "cities"), (("collie", "v"), []),
            (("savage-dog", "group"), [4]), (("_playable-races-as-enemies", "note"), [])])
        from ontology_source_contracts import validate_source
        from test_ontology_schema_authoring import catalog
        row = catalog("creatures")
        row["collie"]["aid"] = None
        validate_source("creatures", row)
        del row["collie"]["aid"]
        validate_source("creatures", row)

    def test_creature_optional_boolean_null_boundary(self):
        from ontology_source_contracts import validate_source
        from test_ontology_schema_authoring import catalog

        row = catalog("creatures")
        for field in ("ride", "boss", "bossable", "breaks-terrain", "drinks-potions", "lantern-at-night"):
            for value in (None, "true", 1, [], {}):
                bad = deepcopy(row)
                bad["collie"][field] = value
                with self.subTest(field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                    validate_source("creatures", bad)
            for value in (False, True):
                good = deepcopy(row)
                good["collie"][field] = value
                validate_source("creatures", good)
            omitted = deepcopy(row)
            omitted["collie"].pop(field, None)
            validate_source("creatures", omitted)
        row["collie"]["aid"] = None
        row["collie"]["tame"] = None
        validate_source("creatures", row)
        del row["collie"]["aid"]
        del row["collie"]["tame"]
        validate_source("creatures", row)

    def test_whole_creature_families_source(self):
        self.assert_family("creature-families", {"$schema", "forest-dungeon-rosters", "landscape-rosters", "entries"}, "dogs", [
            (("dogs", "members"), "collie"), (("dogs", "members"), [1]),
            (("forest-dungeon-rosters", "beetle", "boss"), []),
            (("forest-dungeon-rosters", "undead", "members"), {}),
            (("landscape-rosters", "greenlands"), [None]),
            (("landscape-rosters", "greenlands"), None)])

    def test_whole_factions_source(self):
        self.assert_family("factions", {"$schema", "_doc", "realm-name-examples", "entries"}, "bandits", [
            (("bandits", "alignment"), "unknown"), (("bandits", "members"), "bandit"),
            (("realm-name-examples", "kingdoms"), [False]), (("bandits", "versions"), [])])

    def test_whole_abilities_source(self):
        self.assert_family("abilities", {"$schema", "_doc", "_omega-signature", "entries"}, "camouflage", [
            (("camouflage", "kind"), "unknown"), (("camouflage", "alpha-tree", "rank"), 4),
            (("camouflage", "alpha-tree", "also-ultimate"), 1),
            (("camouflage", "cooldown-s", "S"), []), (("camouflage", "_controls"), {}),
            (("smash", "cost", "S", "stamina"), True), (("smash", "cost", "S"), None),
            (("smash", "alpha-id"), -1), (("_omega-signature", "zombie-eat"), {})])
        from test_ontology_schema_authoring import catalog
        row = catalog("abilities")["camouflage"]
        self.assertEqual(row["alpha-tree"], {"column": "class", "rank": 3, "needs": 5, "also-ultimate": True})
        self.assertEqual(row["_controls"], ["../domain/controls.md#class-skill-3"])

    def test_whole_weapon_types_source(self):
        self.assert_family("weapon-types", {"$schema", "_doc", "_controls", "entries"}, "wand", [
            (("wand", "hands"), "3h"), (("wand", "cube-capacity"), -1),
            (("wand", "damage-k"), True), (("wand", "alpha-attack-ids", "firebeam"), "94"),
            (("bracelet", "alpha-attack-ids", "firebolt"), [False]),
            (("_controls", "m1"), []), (("arrow", "usable"), None)])

    def test_whole_status_effects_source(self):
        self.assert_family("status-effects", {"$schema", "ability-buffs", "not-found", "entries"}, "poison", [
            (("poison", "kind"), "unknown"), (("poison", "sources"), "dagger-ambush"),
            (("elixir-life", "duration-s"), -1), (("ability-buffs", "list"), [None]),
            (("not-found",), {}), (("poison", "effect"), None)])

    def test_whole_rarities_source(self):
        self.assert_family("rarities", {"$schema", "_doc", "mob-strength-tiers-s", "alpha-relative-colors", "entries"}, "common", [
            (("common", "index"), 6), (("common", "hex"), "white"),
            (("common", "stars"), 0), (("common", "named"), "false"),
            (("mob-strength-tiers-s", "white", "hp-range"), [150]),
            (("alpha-relative-colors", "landmark-name", "white"), [])])

    def test_whole_stats_source(self):
        self.assert_family("stats", {"$schema", "resources", "stats", "alpha-item-stat-formulas", "alpha-character-formulas", "gaps", "gaps-decided"}, None, [
            (("resources", "mp", "range"), [0]), (("resources", "mp"), None),
            (("stats", "hp", "source"), "gear"), (("stats", "hp", "versions"), [False]),
            (("alpha-item-stat-formulas", "hp"), 1),
            (("alpha-character-formulas", "skill-points-per-level"), 3),
            (("alpha-character-formulas", "power-table", "1"), True),
            (("alpha-character-formulas", "power-table", "0"), 1),
            (("resources", "_unknown"), {"name": "X", "versions": ["A"]})])

    def test_source_optional_collections_are_not_null(self):
        from ontology_source_contracts import validate_source
        from test_ontology_schema_authoring import catalog

        for name, identifier, field in (("creatures", "collie", "lands"), ("creatures", "collie", "pet-types"),
                                         ("creatures", "collie", "notes"), ("abilities", "camouflage", "alpha-tree"),
                                         ("abilities", "camouflage", "_controls"), ("abilities", "camouflage", "applies")):
            row = catalog(name)
            del row[identifier][field]
            validate_source(name, row)
            row[identifier][field] = None
            with self.subTest(source=name, field=field), self.assertRaises(jsonschema.ValidationError):
                validate_source(name, row)

    def verify_source_style(self, view, path, name, fields, row):
        self.assertIn(name, view.all_classes())
        schema = json.loads(JsonSchemaGenerator(
            str(path), top_class=name, preserve_names=True, not_closed=False
        ).serialize())
        definition = schema["$defs"][name]
        self.assertEqual(set(definition["properties"]), fields)
        self.assertEqual(set(definition["required"]), fields)
        policy = False
        if name == "flat":
            policy = {"anyOf": [{"$ref": "#/$defs/row"}, {"type": "null"}]}
        elif name == "flat-required":
            policy = {"$ref": "#/$defs/row"}
        print("NATIVE-PROBE", name, json.dumps(definition, sort_keys=True))
        self.assertEqual(definition["additionalProperties"], policy)
        if "$ref" in schema:
            self.assertEqual(schema["$ref"], "#/$defs/" + name)
        else:
            self.assertEqual(schema["properties"], definition["properties"])
            self.assertEqual(schema["required"], definition["required"])
            self.assertEqual(schema["additionalProperties"], policy)
        check = jsonschema.Draft201909Validator(schema)
        check.validate(row)
        for bad in (None, [], "root"):
            with self.assertRaises(jsonschema.ValidationError):
                check.validate(bad)
        if name in ("flat", "flat-required"):
            self.verify_flat_style(check, name, row)
        elif name == "keyed":
            self.verify_keyed_style(check, view)
        else:
            self.verify_fixed_style(check, row, fields)

    def verify_flat_style(self, check, name, row):
        if name == "flat":
            check.validate(dict(row, human=None))
        else:
            with self.assertRaises(jsonschema.ValidationError):
                check.validate(dict(row, human=None))
        # Neither dynamic range constrains the property names.
        for key, value in (("_unknown", {"playable": True}),
                           ("Bad Key!", {"playable": True})):
            check.validate(dict(row, **{key: value}))
        for value in ([], {}, {"playable": "true"}, {"playable": True, "extra": 1}):
            with self.assertRaises(jsonschema.ValidationError):
                check.validate(dict(row, human=value))

    def verify_keyed_style(self, check, view):
        for value in (None, [], {"human": {"playable": "true"}}, {"human": None}):
            with self.assertRaises(jsonschema.ValidationError):
                check.validate({"entries": value})
        self.assertEqual(view.induced_slot("key", "keyed-row").pattern, "^[a-z]+$")
        self.assertTrue(view.induced_slot("key", "keyed-row").key)
        # Native keyed collections retain the declaration but do not enforce key patterns.
        check.validate({"entries": {"Bad Key!": {"playable": True}}})
        # SimpleDict admits the scalar value in addition to the authored object row.
        check.validate({"entries": {"human": True}})
        for value in ("true", 1, []):
            with self.assertRaises(jsonschema.ValidationError):
                check.validate({"entries": {"human": value}})

    def verify_fixed_style(self, check, row, fields):
        with self.assertRaises(jsonschema.ValidationError):
            check.validate(dict(row, unknown=True))
        for field in fields:
            with self.assertRaises(jsonschema.ValidationError):
                check.validate({k: v for k, v in row.items() if k != field})
            with self.assertRaises(jsonschema.ValidationError):
                check.validate(dict(row, **{field: None}))

    def test_native_source_styles(self):
        # Native metamodel qualification, not an alternate source-family model.
        probe = """
id: https://w3id.org/pixlnd/native-source-probe
name: native-source-probe
prefixes:
  linkml: https://w3id.org/linkml/
imports: [linkml:types]
default_range: string
classes:
  row:
    attributes:
      playable: {range: boolean, required: true}
  flat:
    attributes:
      _doc: {range: string, required: true}
    extra_slots:
      range_expression: {range: row, inlined: true}
  flat-required:
    attributes:
      _doc: {range: string, required: true}
    extra_slots:
      range_expression: {range: row, inlined: true, required: true}
  keyed-row:
    attributes:
      key: {range: string, key: true, pattern: '^[a-z]+$'}
      playable: {range: boolean, required: true}
  keyed:
    attributes:
      entries: {range: keyed-row, multivalued: true, inlined: true, required: true}
  fixed:
    attributes:
      setting: {range: boolean, required: true}
  saved:
    attributes:
      version: {range: integer, required: true}
      state: {range: row, inlined: true, required: true}
"""
        with tempfile.TemporaryDirectory() as scratch:
            path = Path(scratch) / "probe.yaml"
            path.write_text(probe)
            view = SchemaView(str(path))
            for name, fields, row in (
                ("flat", {"_doc"}, {"_doc": "metadata", "human": {"playable": True}}),
                ("flat-required", {"_doc"}, {"_doc": "metadata", "human": {"playable": True}}),
                ("keyed", {"entries"}, {"entries": {"human": {"playable": True}}}),
                ("fixed", {"setting"}, {"setting": True}),
                ("saved", {"version", "state"}, {"version": 1, "state": {"playable": True}}),
            ):
                with self.subTest(style=name):
                    self.verify_source_style(view, path, name, fields, row)

    def test_native_numeric_tables_require_binding(self):
        # Pinned native dynamic values cannot constrain numeric property names;
        # SimpleDict also admits an object alternative for a scalar table value.
        probe = """
id: https://w3id.org/pixlnd/numeric-table-probe
name: numeric-table-probe
imports: [linkml:types]
prefixes:
  linkml: https://w3id.org/linkml/
classes:
  steam:
    attributes:
      note: {range: string, required: true}
    extra_slots:
      range_expression: {range: string, required: true}
  named:
    attributes:
      index: {range: string, key: true, pattern: '^[0-9]+$'}
      value: {range: string, required: true}
  simple:
    attributes:
      rows: {range: named, multivalued: true, inlined: true, required: true}
"""
        with tempfile.TemporaryDirectory() as scratch:
            path = Path(scratch) / "numeric.yaml"
            path.write_text(probe)
            for owner, good, broadened in (
                ("steam", {"note": "raw", "0": "air"}, {"note": "raw", "not-numeric": "air"}),
                ("simple", {"rows": {"0": "air"}}, {"rows": {"not-numeric": {"value": "air"}}}),
            ):
                schema = json.loads(JsonSchemaGenerator(
                    str(path), top_class=owner, preserve_names=True, not_closed=False).serialize())
                jsonschema.Draft201909Validator.check_schema(schema)
                check = jsonschema.Draft201909Validator(schema)
                check.validate(good)
                check.validate(broadened)
                print("NUMERIC-TABLE-NATIVE-LIMIT", owner, json.dumps(schema["$defs"][owner], sort_keys=True))

    def test_native_positional_pair_binding(self):
        from ontology_source_contracts import assert_declared_root

        probe = """
id: https://w3id.org/pixlnd/positional-pair-probe
name: positional-pair-probe
imports: [linkml:types]
prefixes:
  linkml: https://w3id.org/linkml/
default_range: string
classes:
  integer-pair:
    attributes:
      first: {range: integer, required: true}
      second: {range: integer, required: true}
  scalar-pair:
    attributes:
      first: {range: integer, required: true}
      second:
        required: true
        any_of: [{range: integer}, {range: string, equals_string: '0-9'}]
  pair-pair:
    attributes:
      first: {range: integer-pair, required: true, inlined: true}
      second: {range: integer-pair, required: true, inlined: true}
  owner:
    attributes:
      location:
        exactly_one_of:
        - {range: scalar-pair, inlined: true}
        - {range: pair-pair, inlined: true}
"""
        with tempfile.TemporaryDirectory() as scratch:
            path = Path(scratch) / "positional.yaml"
            path.write_text(probe)
            view = SchemaView(str(path))
            for name in ("integer-pair", "scalar-pair", "pair-pair", "owner"):
                schema = json.loads(JsonSchemaGenerator(
                    str(path), top_class=name, preserve_names=True, not_closed=False).serialize())
                fields = {"location"} if name == "owner" else {"first", "second"}
                assert_declared_root(name, fields, set() if name == "owner" else fields,
                                     schema=schema, view=view)
                if name == "owner":
                    check = jsonschema.Draft201909Validator(schema)
                    pair = {"first": 5, "second": 0}
                    for value in (pair, {"first": 3, "second": "0-9"}, {"first": pair, "second": pair}):
                        check.validate({"location": value})
                    check.validate({})
                    for value in (None, [], 1, "raw", True, {"first": "0-9", "second": 3},
                                  {"first": pair, "second": 1}, {"first": True, "second": 0},
                                  {"first": 1}, dict(pair, third=2), {"first": None, "second": 0},
                                  {"first": dict(pair, third=2), "second": pair}):
                        with self.subTest(value=value), self.assertRaises(jsonschema.ValidationError):
                            check.validate({"location": value})
                    print("POSITIONAL-PAIR-NATIVE", json.dumps(schema["$defs"]["owner"], sort_keys=True))

    def test_unknown_root_is_rejected(self):
        with self.assertRaises(AssertionError):
            assert_root(self, "not-a-selected-class", set(), set())

    def test_wrong_root_properties_are_rejected(self):
        with self.assertRaises(AssertionError):
            assert_root(self, "entity", {"not-a-declared-property"}, set())

    def test_root_guard_rejects_weakened_outputs(self):
        fields = {"version", "world", "character"}
        original = assert_root(self, "save-data", fields, fields)
        for location in ("root", "definition"):
            for key, value in (("required", []), ("additionalProperties", True)):
                bad = deepcopy(original)
                node = bad if location == "root" else bad["$defs"]["save-data"]
                node[key] = value
                with self.subTest(location=location, key=key):
                    with patch("test_ontology_schema_contracts.generated", return_value=bad):
                        with self.assertRaises(AssertionError):
                            assert_root(self, "save-data", fields, fields)
        bad = deepcopy(original)
        bad["$ref"] = "#/$defs/entity"
        with patch("test_ontology_schema_contracts.generated", return_value=bad):
            with self.assertRaises(AssertionError):
                assert_root(self, "save-data", fields, fields)


if __name__ == "__main__":
    unittest.main()
