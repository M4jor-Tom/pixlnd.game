"""Six source-shaped payloads; catalog tables are not static entity instances."""
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml_runtime.utils.schemaview import SchemaView
from test_ontology_schema import SCHEMA, JsonSchemaGenerator, copy_schema, load_module
from test_ontology_schema_authoring import catalog, validate, validator
from test_ontology_schema_crafting_social import mutated

MODULE = "structured-world.yaml"
ROOT = "static-entity-catalog"
FIELDS = {
    "flora": [("yields", "flora-yield-entry", True, True)],
    "dungeon-type": [("variants", "dungeon-variant-entry", True, True)],
    ROOT: [("by-id", "static-index-name", True, True),
           ("behaviour", "static-behaviour-entry", True, True),
           ("s-additions", "string", True, False),
           ("candles", "static-candles", False, True)],
    "static-candles": [("colors", "string", True, False),
                       ("sizes", "string", True, False),
                       ("placement", "string", False, False)],
}
ASSOCIATIONS = {
    "flora-yield-entry": ("ingredient", "ingredient", "quantity", None),
    "dungeon-variant-entry": ("label", "string", "description", "string"),
    "static-index-name": ("index", "string", "name", "string"),
    "static-behaviour-entry": ("group", "string", "description", "string"),
}
BRANCHES = [{"range": "integer"},
            {"range": "integer", "multivalued": True,
             "minimum_cardinality": 2, "maximum_cardinality": 2},
            {"range": "string", "equals_string": "n"}]

def assert_marker_contract(self, view):
    triple, place = "map-marker-integer-triple", "map-marker-place-key"
    entry, tile, keyed = "place-marker-list-entry", "zone-tile-marker-collection", "place-keyed-marker-collection"
    expected = {
        tile: [("markers", triple, True, True, True)],
        keyed: [("places", entry, True, True, True)],
        triple: [(axis, "integer", False, False, True) for axis in ("x", "y", "z")],
        place: [(axis, "integer", False, False, True) for axis in ("x", "y")],
        entry: [("place", place, False, True, True), ("positions", triple, True, True, True)],
    }
    for owner, fields in expected.items():
        cls = view.get_class(owner)
        self.assertIsNotNone(cls)
        self.assertEqual(cls.slots, [owner + "-" + alias for alias, *_ in fields])
        self.assertEqual(str(cls.class_uri), "pixlnd:" + owner)
        for alias, range_, multiple, inline, required in fields:
            slot = view.induced_slot(owner + "-" + alias, owner)
            self.assertEqual((slot.alias, slot.domain, slot.range), (alias, owner, range_))
            self.assertEqual(str(slot.slot_uri), "pixlnd:" + owner + "/" + alias)
            self.assertEqual((bool(slot.multivalued), bool(slot.inlined), bool(slot.required)),
                             (multiple, inline, required))
            self.assertFalse(slot.key or slot.identifier)
            self.assertIsNone(slot.minimum_cardinality)
            self.assertIsNone(slot.maximum_cardinality)
    self.assertIn("t05-infinite-alpha-worldmap-h.txt", view.get_class(tile).description)
    self.assertIn("t06-infinite-alpha-worldmap-cpp.txt", view.get_class(tile).description)
    self.assertIn("t14-release-worldmap-h.txt", view.get_class(keyed).description)
    self.assertIn("t15-release-worldmap-cpp.txt", view.get_class(keyed).description)
    for owner in (tile, keyed):
        self.assertIn("universal wire/save contract", view.get_class(owner).description)

def assert_contract(self, view):
    assert_marker_contract(self, view)
    for owner, fields in FIELDS.items():
        for alias, range_, multiple, inline in fields:
            name = owner + "-" + alias
            self.assertIn(name, view.class_slots(owner))
            slot = view.induced_slot(name, owner)
            self.assertEqual((slot.alias, slot.domain, slot.range), (alias, owner, range_))
            self.assertEqual(str(slot.slot_uri), "pixlnd:" + owner + "/" + alias)
            self.assertEqual((bool(slot.multivalued), bool(slot.inlined)), (multiple, inline))
            self.assertFalse(slot.required or slot.key or slot.identifier or slot.inlined_as_list)
            self.assertFalse(slot.list_elements_unique)
            for facet in ("minimum_cardinality", "maximum_cardinality", "minimum_value", "maximum_value"):
                self.assertIsNone(getattr(slot, facet))
    for owner, (key, target, value, range_) in ASSOCIATIONS.items():
        self.assertEqual(view.get_class(owner).slots, [owner + "-" + key, owner + "-" + value])
        for alias, expected in ((key, target), (value, range_)):
            slot = view.get_slot(owner + "-" + alias)
            self.assertEqual((slot.alias, slot.domain, slot.range), (alias, owner, expected))
            self.assertEqual(str(slot.slot_uri), "pixlnd:" + owner + "/" + alias)
            self.assertTrue(slot.required)
            self.assertEqual(bool(slot.key), alias == key)
            self.assertFalse(slot.identifier or slot.multivalued or slot.inlined)
    quantity = view.get_slot("flora-yield-entry-quantity")
    self.assertEqual(len(quantity.any_of), 3)
    for branch, expected in zip(quantity.any_of, BRANCHES):
        for facet in ("range", "multivalued", "minimum_cardinality", "maximum_cardinality", "equals_string"):
            self.assertEqual(getattr(branch, facet), expected.get(facet))
        self.assertIsNone(branch.minimum_value)
        self.assertIsNone(branch.maximum_value)
    for owner in (ROOT, "static-candles", *ASSOCIATIONS):
        self.assertIsNone(view.get_class(owner).is_a)
        self.assertNotIn("id", view.class_slots(owner))
        self.assertEqual(str(view.get_class(owner).class_uri), "pixlnd:" + owner)
    self.assertTrue(set(view.class_slots(ROOT)).isdisjoint(view.class_slots("static-entity")))
    self.assertEqual(view.get_class("ingredient-yield").slots,
                     ["ingredient-yield-ingredient", "ingredient-yield-minimum", "ingredient-yield-maximum"])
    assert_config_contract(self, view)

def projections():
    result = {}
    for owner, file in (("flora", "flora"), ("dungeon-type", "dungeon-types")):
        result[owner] = [dict({alias: row[alias] for alias, *_ in FIELDS[owner] if alias in row}, id=key)
                         for key, row in catalog(file).items() if not key.startswith(("_", "$"))]
    source = catalog("static-entities")
    result[ROOT] = [{alias: source[alias] for alias, *_ in FIELDS[ROOT]}]
    return result

def verify_config_field(self, owner, field, range_, inline):
    good = [{}, None] if inline else ([0, -1, 10**30, None] if range_ == "integer"
                                       else ["", "arbitrary ≈ text", None])
    bad = [[], True, 2, "text"] if inline else ([True, "2", 1.5, [], {}] if range_ == "integer"
                                              else [2, False, [], {}])
    for value in good:
        validate(owner, {field: value})
    for value in bad:
        with self.subTest(owner=owner, field=field, value=value), self.assertRaises(jsonschema.ValidationError):
            validate(owner, {field: value})


class StructuredWorldTests(unittest.TestCase):
    def test_selected_contract(self):
        assert_contract(self, SchemaView(str(SCHEMA)))

    def test_unchanged_projections(self):
        rows = projections()
        self.assertEqual([len(rows[o]) for o in ("flora", "dungeon-type", ROOT)], [24, 24, 1])
        for owner, entries in rows.items():
            for row in entries:
                validate(owner, row)
        flora = catalog("flora")
        self.assertEqual(flora["thorn-tree"]["yields"], {})
        self.assertNotIn("yields", flora["trees"])
        targets = [target for row in flora.values() if isinstance(row, dict) for target in row.get("yields", {})]
        self.assertEqual(len(targets), 24)
        self.assertTrue(set(targets) <= catalog("ingredients").keys())
        self.assertEqual(flora["apple-tree"]["yields"], {"apple": "n"})
        self.assertEqual(catalog("dungeon-types")["ruins"]["variants"], {
            "dungeon-ruins": "damaged castles", "overworld-ruins": "scattered white Greco-Roman buildings, no interior"})
        static = catalog("static-entities")
        self.assertNotIn("70", static["by-id"])
        self.assertEqual([static["by-id"][str(i)] for i in (12, 13, 14)], ["table"] * 3)
        self.assertIn("door|big-door|gate", static["behaviour"])
        self.assertIn("menhir/tablet", static["s-additions"])
        for owner, extra in (("flora", {"yields": {"apple": "n"}}),
                             ("dungeon-type", {"variants": {"label": "text"}})):
            with self.assertRaises(jsonschema.ValidationError):
                validate(owner, dict(catalog("flora" if owner == "flora" else "dungeon-types")["bush" if owner == "flora" else "ruins"], **extra, id="x"))
        with self.assertRaises(jsonschema.ValidationError):
            validate(ROOT, static)  # Full source envelope remains unqualified.

    def test_native_values_and_limits(self):
        for owner, field, good, bad in [
            ("flora", "yields", [{}, {"apple": 1}, {"apple": [1, 3]}, {"apple": "n"},
                                  {"unknown": -9}, {"apple": 0}, {"apple": 1000000}, {"apple": [9, -2]}],
             [[], 1, True, "n", {"apple": None}, {"apple": True}, {"apple": "N"},
              {"apple": "anything"}, {"apple": 1.5}, {"apple": []}, {"apple": [1]},
              {"apple": [1, 2, 3]}, {"apple": [1, "n"]}, {"apple": [True, 3]}, {"apple": {}}]),
            ("dungeon-type", "variants", [{}, {"unknown": "description"}], [[], "text", {"a": 1}, {"a": None}]),
            (ROOT, "by-id", [{}, {"999": "same", "998": "same"}], [[], 1, {"0": 0}, {"0": None}]),
            (ROOT, "behaviour", [{}, {"raw|group": "qualified"}], [[], "text", {"x": False}, {"x": None}]),
            (ROOT, "s-additions", [[], ["divine door", "divine door"]], [{}, "text", [1], [None]]),
            (ROOT, "candles", [{}, {"colors": [], "sizes": ["unlisted"], "placement": "raw"}], [[], 1, "red", {"colors": "red"}, {"sizes": [1]}, {"placement": []}]),
        ]:
            base = {} if owner == ROOT else {"id": "example"}
            validate(owner, base)
            for value in [None, *good]:
                validate(owner, dict(base, **{field: value}))
            for value in bad:
                with self.subTest(owner=owner, field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                    validate(owner, dict(base, **{field: value}))
        for owner, field, body in [("flora", "yields", {"ingredient": "different", "quantity": "n"}),
                                   ("dungeon-type", "variants", {"label": "different", "description": "text"}),
                                   (ROOT, "by-id", {"index": "different", "name": "text"}),
                                   (ROOT, "behaviour", {"group": "different", "description": "text"})]:
            base = {} if owner == ROOT else {"id": "example"}
            validate(owner, dict(base, **{field: {"unknown": body}}))
            key, value = body  # Literal two-slot test bodies above retain key/value order.
            validate(owner, dict(base, **{field: {"unknown": {value: body[value]}}}))
            with self.assertRaises(jsonschema.ValidationError):
                validate(owner, dict(base, **{field: {"unknown": {key: body[key]}}}))
        quantity = validator("flora").schema["$defs"]["flora"]["properties"]["yields"]["additionalProperties"]["anyOf"][1]
        self.assertEqual(quantity["anyOf"], [{"type": "integer"},
            {"type": "array", "items": {"type": "integer"}, "minItems": 2, "maxItems": 2},
            {"type": "string", "const": "n"}])
        validate(ROOT, {"by-id": {"not-numeric": "name"}})  # Raw string keys, no invented namespace restriction.
        for field in ("colors", "sizes", "placement"):
            validate(ROOT, {"candles": {field: None}})

    def test_native_yaml_mutations(self):
        cases = [
            ("flora-yield-entry-quantity", "any_of", BRANCHES[1:], "flora", {"id": "x", "yields": {"apple": 1}}, False),
            ("flora-yield-entry-quantity", "any_of", [BRANCHES[0], BRANCHES[2]], "flora", {"id": "x", "yields": {"apple": [1, 3]}}, False),
            ("flora-yield-entry-quantity", "any_of", BRANCHES[:2], "flora", {"id": "x", "yields": {"apple": "n"}}, False),
            ("flora-yield-entry-quantity", "any_of", BRANCHES[:2] + [{"range": "string"}], "flora", {"id": "x", "yields": {"apple": "arbitrary"}}, True),
            ("flora-yield-entry-quantity", "any_of", [BRANCHES[0], dict(BRANCHES[1], minimum_cardinality=1), BRANCHES[2]], "flora", {"id": "x", "yields": {"apple": [1]}}, True),
            ("flora-yield-entry-quantity", "any_of", [BRANCHES[0], dict(BRANCHES[1], maximum_cardinality=3), BRANCHES[2]], "flora", {"id": "x", "yields": {"apple": [1, 2, 3]}}, True),
        ]
        for owner, field, association, key, value in [
            ("flora", "yields", "flora-yield-entry", "ingredient", "quantity"),
            ("dungeon-type", "variants", "dungeon-variant-entry", "label", "description"),
            (ROOT, "by-id", "static-index-name", "index", "name"),
            (ROOT, "behaviour", "static-behaviour-entry", "group", "description"),
        ]:
            row = {field: {"raw": 1 if owner == "flora" else "text"}}
            if owner != ROOT:
                row["id"] = "x"
            cases += [(owner + "-" + field, "multivalued", False, owner, row, False),
                      (owner + "-" + field, "inlined", False, owner, row, True),
                      (association + "-" + key, "key", False, owner, row, False),
                      (association + "-" + value, "required", False, owner,
                       dict(row, **{field: {"raw": None}}), True)]
        cases += [(ROOT + "-s-additions", "multivalued", False, ROOT, {"s-additions": ["raw"]}, False),
                  ("static-candles-colors", "range", "integer", ROOT, {"candles": {"colors": ["red"]}}, False),
                  ("static-candles-sizes", "multivalued", False, ROOT, {"candles": {"sizes": ["small"]}}, False),
                  ("static-candles-placement", "range", "integer", ROOT, {"candles": {"placement": "raw"}}, False)]
        for name, facet, value, owner, row, expected in cases:
            # inlined:false is the known key-only native no-effect case; other
            # admitted mutants are explicit invalid-to-valid broadening controls.
            baseline = validator(owner).is_valid(row)
            self.assertEqual(baseline, not expected or facet == "inlined")
            with self.subTest(name=name, facet=facet):
                self.assertEqual(mutated(MODULE, name, facet, value, owner, row), expected)

    def test_same_contract_metadata_mutations(self):
        assert_contract(self, SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / MODULE
            original = path.read_text()
            data = yaml.safe_load(original)
            cases = [(name, "alias", "wrong") for name in data["slots"]]
            cases += [(owner + "-" + field, "inlined", False) for owner, fields in FIELDS.items()
                      for field, _, _, inline in fields if inline]
            cases += [("flora-yield-entry-ingredient", "range", "material"),
                      ("flora-yield-entry-ingredient", "identifier", True),
                      ("flora-yield-entry-quantity", "any_of", BRANCHES[:2])]
            for name, facet, value in cases:
                mutant = yaml.safe_load(original)
                mutant["slots"][name][facet] = value
                path.write_text(yaml.safe_dump(mutant, sort_keys=False))
                with self.subTest(name=name, facet=facet), self.assertRaises(AssertionError):
                    assert_contract(self, SchemaView(str(target / "pixlnd.yaml")))
            path.write_text(original)
            for owner, fields in FIELDS.items():
                attachment = target / ("world-catalog.yaml" if owner in ("flora", "dungeon-type") else MODULE)
                text = attachment.read_text()
                for field, *_ in fields:
                    mutant = yaml.safe_load(text)
                    mutant["classes"][owner]["slots"].remove(owner + "-" + field)
                    attachment.write_text(yaml.safe_dump(mutant, sort_keys=False))
                    with self.assertRaises(AssertionError):
                        assert_contract(self, SchemaView(str(target / "pixlnd.yaml")))
                attachment.write_text(text)


CONFIG_ROOT = "block-type-catalog"
CONFIG_FIELDS = {
    CONFIG_ROOT: [("scale", "block-scale", True), ("cub-format", "block-cub-format", True)],
    "block-scale": [("block-native-units", "integer", False),
                    ("alpha-zone-blocks", "integer", False),
                    ("steam-zone-blocks", "integer", False),
                    ("steam-map-chunk-blocks", "integer", False),
                    ("character-height-m", "string", False)],
    "block-cub-format": [(field, "string", False) for field in
                         ("header", "body", "empty", "compression", "storage")],
}


def assert_raw_config_contract(self, raw):
    for owner, fields in CONFIG_FIELDS.items():
        self.assertIn(owner, raw["classes"])
        cls = raw["classes"][owner]
        self.assertEqual(cls.get("slots", []), [owner + "-" + alias for alias, *_ in fields])
        for alias, range_, inline in fields:
            name = owner + "-" + alias
            slot = raw.get("slots", {}).get(name, {})
            if any((name in cls.get("slot_usage", {}), slot.get("is_a"), slot.get("mixins"))):
                continue  # Induction resolves overrides/inheritance; raw checks cannot contradict it.
            for facet, expected in dict(alias=alias, domain=owner, slot_uri="pixlnd:" + owner + "/" + alias,
                                        range=range_, inlined=inline, required=False,
                                        identifier=False, multivalued=False).items():
                if slot.get(facet) is not None:
                    self.assertEqual(slot[facet], expected)


def assert_config_contract(self, view):
    path = Path(view) if isinstance(view, (str, Path)) else Path(view.schema.source_file)
    assert_raw_config_contract(self, load_module(path.with_name(MODULE)))
    view = SchemaView(str(path)) if isinstance(view, (str, Path)) else view
    for owner, fields in CONFIG_FIELDS.items():
        cls = view.get_class(owner)
        self.assertIsNotNone(cls)
        self.assertEqual(cls.slots, [owner + "-" + alias for alias, *_ in fields])
        self.assertEqual(str(cls.class_uri), "pixlnd:" + owner)
        self.assertIsNone(cls.is_a)
        self.assertFalse(cls.mixins or cls.aliases)
        self.assertIn("../domain/3_Classes.md#block", cls.see_also)
        self.assertIn("../instances/block-types.json", cls.see_also)
        for alias, range_, inline in fields:
            slot = view.induced_slot(owner + "-" + alias, owner)
            self.assertEqual((slot.alias, slot.domain, slot.range), (alias, owner, range_))
            self.assertEqual(str(slot.slot_uri), "pixlnd:" + owner + "/" + alias)
            self.assertEqual(bool(slot.inlined), inline)
            self.assertFalse(slot.required or slot.key or slot.identifier or slot.multivalued)
            self.assertFalse(slot.inlined_as_list or slot.list_elements_unique or slot.any_of)
            self.assertIsNone(slot.equals_string)
            self.assertIsNone(slot.equals_number)
            for facet in ("minimum_value", "maximum_value", "minimum_cardinality", "maximum_cardinality", "pattern"):
                self.assertIsNone(getattr(slot, facet))
            self.assertIn("../domain/3_Classes.md#block", slot.see_also)
            self.assertIn("../instances/block-types.json", slot.see_also)
    selected = {owner + "-" + alias for owner, fields in CONFIG_FIELDS.items() for alias, *_ in fields}
    for owner in ("block", "block-type", "static-entity", "save-data"):
        self.assertTrue(selected.isdisjoint(view.class_slots(owner)))


def config_projections():
    source = catalog("block-types")
    return {CONFIG_ROOT: [{"scale": source["scale"], "cub-format": source["cub-format"]}],
            "block-scale": [source["scale"]], "block-cub-format": [source["cub-format"]]}


class BlockConfigurationTests(unittest.TestCase):
    def test_config_contract(self):
        assert_config_contract(self, SCHEMA)

    def test_real_config_projections(self):
        source = catalog("block-types")
        for owner, rows in config_projections().items():
            self.assertEqual(set(validator(owner).schema.get("properties", {})), set(rows[0]))
            for row in rows:
                validate(owner, row)
        self.assertEqual(source["scale"], {"block-native-units": 65536, "alpha-zone-blocks": 256,
            "steam-zone-blocks": 64, "steam-map-chunk-blocks": 20, "character-height-m": "≈2"})
        self.assertTrue(all(type(source["scale"][field]) is int for field, range_, _ in
                            CONFIG_FIELDS["block-scale"] if range_ == "integer"))
        self.assertEqual(source["cub-format"], {"header": "3 × uint32 LE (x,y,z size)",
            "body": "x*y*z × RGB bytes, loop for z: for y: for x", "empty": "RGB (0,0,0)",
            "compression": "none", "storage": "alpha data1.db sqlite (obfuscated)"})
        with self.assertRaises(jsonschema.ValidationError):
            validate(CONFIG_ROOT, source)  # Excluded envelope, not production source rejection.

    def test_config_native_types_and_optional_limits(self):
        for owner, fields in CONFIG_FIELDS.items():
            validate(owner, {})  # No fabricated ID or completeness requirement.
            with self.assertRaises(jsonschema.ValidationError):
                validate(owner, {"unknown": "extra"})
            for field, range_, inline in fields:
                verify_config_field(self, owner, field, range_, inline)
        validate(CONFIG_ROOT, {"scale": {}, "cub-format": {}})
        validate(CONFIG_ROOT, {"scale": None, "cub-format": None})
        for field in ("scale", "cub-format"):
            with self.assertRaises(jsonschema.ValidationError):
                validate(CONFIG_ROOT, {field: {"unknown": "extra"}})

    def test_config_native_yaml_mutations(self):
        for owner, fields in CONFIG_FIELDS.items():
            row = config_projections()[owner][0]
            for field, range_, inline in fields:
                name = owner + "-" + field
                with self.subTest(name=name, facet="range"):
                    self.assertTrue(validator(owner).is_valid(row))
                    self.assertFalse(mutated(MODULE, name, "range",
                                             "string" if range_ == "integer" else "integer", owner, row))
                with self.subTest(name=name, facet="required"):
                    self.assertTrue(validator(owner).is_valid({}))
                    self.assertFalse(mutated(MODULE, name, "required", True, owner, {}))
                if inline:
                    # Native single-valued anonymous objects still inline: metadata detects this no-effect mutation.
                    self.assertTrue(mutated(MODULE, name, "inlined", False, owner, row))
        self.assertFalse(mutated(MODULE, "block-scale-character-height-m", "identifier", True,
                                 "block-scale", {}))

    def test_config_native_attachment_mutations(self):
        row = config_projections()[CONFIG_ROOT][0]
        self.assertTrue(validator(CONFIG_ROOT).is_valid(row))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / MODULE
            original = path.read_text()
            for field, *_ in CONFIG_FIELDS[CONFIG_ROOT]:
                data = yaml.safe_load(original)
                data["classes"][CONFIG_ROOT]["slots"].remove(CONFIG_ROOT + "-" + field)
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                schema = yaml.safe_load(JsonSchemaGenerator(
                    str(target / "pixlnd.yaml"), top_class=CONFIG_ROOT,
                    preserve_names=True, not_closed=False).serialize())
                cls = jsonschema.validators.validator_for(schema)
                cls.check_schema(schema)
                with self.subTest(field=field):
                    self.assertFalse(cls(schema).is_valid(row))

    def test_config_same_metadata_contract_mutations(self):
        assert_config_contract(self, SCHEMA)
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / MODULE
            original = path.read_text()
            data = yaml.safe_load(original)
            cases = []
            for owner, fields in CONFIG_FIELDS.items():
                for field, range_, inline in fields:
                    name = owner + "-" + field
                    cases += [("slots", name, facet, value) for facet, value in
                              [("alias", "wrong"), ("domain", "static-entity"), ("slot_uri", "pixlnd:wrong"),
                               ("range", "string" if range_ == "integer" else "integer"),
                               ("required", True), ("identifier", True), ("multivalued", True),
                               ("inlined", not inline)]]
                attachments = data["classes"][owner]["slots"]
                cases += [("classes", owner, "slots", [s for s in attachments if s != removed])
                          for removed in attachments]
                cases += [("classes", owner, "class_uri", "pixlnd:wrong"),
                          ("classes", owner, "is_a", "static-entity")]
            for section, name, facet, value in cases:
                mutant = yaml.safe_load(original)
                mutant[section][name][facet] = value
                path.write_text(yaml.safe_dump(mutant, sort_keys=False))
                with self.subTest(name=name, facet=facet), self.assertRaises(AssertionError):
                    assert_config_contract(self, target / "pixlnd.yaml")


class MapMarkerContracts(unittest.TestCase):
    TILE = "zone-tile-marker-collection"
    KEYED = "place-keyed-marker-collection"
    TRIPLE = "map-marker-integer-triple"
    PLACE = "map-marker-place-key"
    ENTRY = "place-marker-list-entry"

    def test_marker_collection_metadata(self):
        view = SchemaView(str(SCHEMA))
        assert_marker_contract(self, view)
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / MODULE
            data = yaml.safe_load(path.read_text())
            data["slots"][self.TRIPLE + "-x"]["range"] = "string"
            path.write_text(yaml.safe_dump(data, sort_keys=False))
            mutated_view = SchemaView(str(target / "pixlnd.yaml"))
            with self.assertRaises(AssertionError):
                slot = mutated_view.induced_slot(self.TRIPLE + "-x", self.TRIPLE)
                self.assertEqual(slot.range, "integer")

    def test_marker_collection_native_boundaries_and_yaml_mutations(self):
        from test_ontology_schema_contracts import assert_root

        for name, fields in ((self.TILE, {"markers"}), (self.KEYED, {"places"}),
                             (self.TRIPLE, {"x", "y", "z"}), (self.PLACE, {"x", "y"}),
                             (self.ENTRY, {"place", "positions"})):
            assert_root(self, name, fields, fields)
        triple = {"x": -7, "y": 0, "z": 19}
        place = {"x": 3, "y": -2}
        validate(self.TILE, {"markers": [triple, {"x": 2, "y": 3, "z": 4}]})
        validate(self.TILE, {"markers": []})
        validate(self.KEYED, {"places": [{"place": place, "positions": [triple]}]})
        validate(self.KEYED, {"places": []})
        for owner, row in (
            (self.TILE, {"markers": [{"x": 1, "y": 2}]}),
            (self.TILE, {"markers": [{"x": 1, "y": 2, "z": "3"}]}),
            (self.TILE, {"markers": [1]}),
            (self.KEYED, {"places": [{"place": {"x": 1}, "positions": []}]}),
            (self.KEYED, {"places": [{"place": place, "positions": [{"x": 1, "y": 2}]}]}),
            (self.KEYED, {"places": [{"place": place, "positions": [triple], "extra": 1}]}),
        ):
            with self.subTest(owner=owner, row=row), self.assertRaises(jsonschema.ValidationError):
                validate(owner, row)
        self.assertTrue(validator(self.TILE).is_valid({"markers": [triple]}))
        self.assertFalse(mutated(MODULE, self.TILE + "-markers", "range", "string", self.TILE,
                                 {"markers": [triple]}))
        self.assertFalse(mutated(MODULE, self.KEYED + "-places", "multivalued", False, self.KEYED,
                                 {"places": [{"place": place, "positions": [triple]}]}))
        self.assertFalse(mutated(MODULE, self.TRIPLE + "-z", "range", "string", self.TILE,
                                 {"markers": [triple]}))

class FullStructuredWorldSources(unittest.TestCase):
    def test_whole_block_types_source(self):
        from ontology_source_contracts import (
            bind_source,
            unbind_source,
            validate_source,
        )
        from test_ontology_schema_contracts import assert_root

        row = catalog("block-types")
        fields = {"$schema", "_doc", "alpha", "steam", "scale", "cub-format"}
        assert_root(self, "block-types-source", fields, fields)
        self.assertEqual(unbind_source("block-types", bind_source("block-types", row)), row)
        validate_source("block-types", row)
        for owner, nested_fields in (("alpha-block-table-source", {"flags", "entries"}),
                                     ("steam-block-table-source", {"note", "entries"})):
            assert_root(self, owner, nested_fields, nested_fields)
        self.assertEqual(row["steam"]["0"], "air")
        for path, value in [(("steam",), []), (("steam", "0"), {}), (("steam", "0"), None),
                            (("steam", "note"), []), (("steam", "Bad Key!"), "air"),
                            (("steam", "entries"), "air"), (("alpha", "0"), "air"),
                            (("alpha", "0"), None), (("alpha", "0", "solid"), "false"),
                            (("alpha", "0", "extra"), True), (("alpha", "flags"), None),
                            (("alpha", "flags", "dark"), []), (("alpha", "not-numeric"), row["alpha"]["0"]),
                            (("alpha", "entries"), row["alpha"]["0"]),
                            (("scale",), {}), (("scale", "character-height-m"), 2),
                            (("cub-format", "body"), []), (("unknown",), {})]:
            bad = deepcopy(row)
            node = bad
            for part in path[:-1]:
                node = node[part]
            node[path[-1]] = value
            with self.subTest(path=path, value=value), self.assertRaises(jsonschema.ValidationError):
                validate_source("block-types", bad)
        for field in fields:
            bad = deepcopy(row)
            bad.pop(field, None)
            with self.subTest(missing=field), self.assertRaises(jsonschema.ValidationError):
                validate_source("block-types", bad)
        # Reconstruction cannot overwrite metadata, nor accept duplicate numeric keys.
        for owner, fixed in (("alpha", "flags"), ("steam", "note")):
            bound = bind_source("block-types", row)
            bound[owner]["entries"].append(deepcopy(bound[owner]["entries"][0]))
            with self.assertRaises(jsonschema.ValidationError):
                unbind_source("block-types", bound)
            bound[owner]["entries"][-1]["key"] = fixed
            with self.assertRaises(jsonschema.ValidationError):
                unbind_source("block-types", bound)
        for bad in (None, [], {}, dict(row, entries={})):
            with self.subTest(root=bad), self.assertRaises(jsonschema.ValidationError):
                validate_source("block-types", bad)

    def test_whole_static_entities_source(self):
        from ontology_source_contracts import (
            bind_source,
            unbind_source,
            validate_source,
        )
        from test_ontology_schema_contracts import assert_root

        row = catalog("static-entities")
        fields = {"$schema", "_doc", "by-id", "behaviour", "s-additions", "candles"}
        assert_root(self, "static-entities-source", fields, fields)
        self.assertEqual(unbind_source("static-entities", bind_source("static-entities", row)), row)
        validate_source("static-entities", row)
        for path, value in [(("by-id", "0"), 0), (("by-id", "0"), {"value": "statue"}),
                            (("by-id", "not-numeric"), "statue"), (("behaviour", "door|big-door|gate"), []),
                            (("candles", "colors"), "red"), (("candles", "sizes"), [None]),
                            (("candles",), {}), (("s-additions",), None), (("extra",), True)]:
            bad = deepcopy(row)
            node = bad
            for part in path[:-1]:
                node = node[part]
            node[path[-1]] = value
            with self.subTest(path=path), self.assertRaises(jsonschema.ValidationError):
                validate_source("static-entities", bad)
        self.assertNotIn("70", row["by-id"])
        self.assertEqual([row["by-id"][str(i)] for i in (12, 13, 14)], ["table"] * 3)

    def test_whole_buildings_source(self):
        from ontology_source_contracts import (
            bind_source,
            unbind_source,
            validate_source,
        )
        from test_ontology_schema_contracts import assert_root

        row = catalog("buildings")
        fields = {"$schema", "districts", "buildings", "settlement-styles", "population", "map-visibility"}
        assert_root(self, "buildings-source", fields, fields)
        self.assertEqual(unbind_source("buildings", bind_source("buildings", row)), row)
        validate_source("buildings", row)
        for path, value in [(("districts", "trade", "quarter-id"), [1]),
                            (("districts", "trade", "quarter-id"), [1, "1"]),
                            (("districts", "trade", "buildings"), [False]),
                            (("districts", "adventurer", "buildings"), [{"id": "class-trainer"}]),
                            (("districts", "adventurer", "buildings"), [{"id": "class-trainer", "class": 1}]),
                            (("districts", "adventurer", "buildings"), [{"id": "class-trainer", "class": "mage", "extra": 1}]),
                            (("buildings", "inn", "count", "A"), 2), (("buildings", "smithy", "stations"), "anvil"),
                            (("settlement-styles", "log", "lands"), [1]), (("population", "majority"), {}),
                            (("population", "growth"), None), (("map-visibility", "S"), []), (("extra",), {})]:
            bad = deepcopy(row)
            node = bad
            for part in path[:-1]:
                node = node[part]
            node[path[-1]] = value
            with self.subTest(path=path), self.assertRaises(jsonschema.ValidationError):
                validate_source("buildings", bad)
        self.assertEqual(row["districts"]["adventurer"]["buildings"], [
            {"id": "class-trainer", "class": name} for name in ("warrior", "ranger", "rogue", "mage")])

if __name__ == "__main__":
    unittest.main()
