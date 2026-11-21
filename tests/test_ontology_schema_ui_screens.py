"""Selected source-shaped screens; not UI behavior or complete-envelope admission."""
import json
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
from test_ontology_schema import SCHEMA, copy_schema
from test_ontology_schema_authoring import catalog, generated, validate, validator
from test_ontology_schema_ui_presentation import assert_contract

SCREEN = "ui-screen-presentation"
CATALOG = "ui-presentation-catalog"
FIELDS = ("desc", "shows", "extras")
PROJECTED_FIELDS = (*FIELDS, "tabs", "stats")
CONTEXT = "ui-screen-context-lists"
KEYS = ["world-map", "overview-map", "inventory", "character-sheet", "skills", "npc-service",
        "crafting", "quick-select", "customization-bench", "character-creation", "world-selection",
        "friends-widget", "system-menu", "move-list", "item-tooltip"]


def projections():
    return {key: {field: value for field, value in body.items() if field in PROJECTED_FIELDS}
            for key, body in catalog("ui")["screens"].items()}


class UiScreensTests(unittest.TestCase):
    def test_selected_classes_and_native_roots_exist(self):
        view = SchemaView(str(SCHEMA))
        self.assertIsNotNone(view.get_class(SCREEN))
        assert_contract(self, view)
        for owner, properties in [(SCREEN, {"screen", "desc", "shows", "extras", "tabs", "stats"}),
                                  (CONTEXT, {"A", "S"}),
                                  (CATALOG, {"hud", "camera", "screens", "options"})]:
            with self.subTest(owner=owner):
                schema = generated(owner)
                self.assertEqual(set(schema.get("properties", {})), properties)
                self.assertFalse(schema["additionalProperties"])

    def test_original_keys_bodies_and_text_are_unmodified(self):
        source, rows = catalog("ui")["screens"], projections()
        self.assertEqual(list(rows), KEYS)
        self.assertEqual([key for key, body in rows.items() if "desc" in body],
                         ["world-map", "overview-map", "skills", "npc-service", "quick-select",
                          "customization-bench", "character-creation", "world-selection", "system-menu", "item-tooltip"])
        self.assertEqual(sum(len(body) for body in rows.values()), 15)
        self.assertEqual(rows["inventory"], {
            "tabs": {"A": ["equipment", "amulets", "items", "ingredients", "pets"],
                     "S": ["equipment", "special", "items", "ingredients", "pets", "artifacts"]},
            "extras": ["S per-land pages", "S weapon/armor star rating at left", "coins (A)"]})
        self.assertEqual(rows["crafting"], {
            "tabs": ["weapon", "armor", "amulet & ring", "cooking", "alchemy", "ingredients"],
            "shows": "materials count + required station"})
        self.assertEqual(rows["character-sheet"], {"stats": {
            "A": ["power", "hp", "attack power", "spell power", "armor", "resi", "crit", "tempo", "reg", "mana reg"],
            "S": ["power", "hp", "armor", "resi", "crit", "haste", "reg", "weapon rating", "armor rating"]}})
        lists = [rows["crafting"]["tabs"], *rows["inventory"]["tabs"].values(),
                 *rows["character-sheet"]["stats"].values()]
        self.assertEqual(len(lists), 5)
        self.assertEqual(sum(map(len, lists)), 36)
        self.assertEqual([key for key, body in rows.items() if not body], ["friends-widget", "move-list"])
        for key, body in rows.items():
            self.assertNotIn("screen", body)
            self.assertNotIn("id", body)
            self.assertEqual(body, {f: source[key][f] for f in PROJECTED_FIELDS if f in source[key]})
            validate(SCREEN, dict(body, screen=key))  # Actual local key, never a fabricated ID.
        validate(CATALOG, {"screens": rows})
        for row in (catalog("ui"), {"screens": source}):
            with self.assertRaises(jsonschema.ValidationError):
                validate(CATALOG, row)

    def test_scalar_list_optional_and_closed_boundaries(self):
        base = {"screen": "inventory"}
        validate(SCREEN, base)
        for field in FIELDS:
            good = [None, [], [""], ["same"] * 127] if field == "extras" else [None, "", "text ≈" * 127]
            bad = [True, 1, {}, "text", [None], [1], [True], [[]], [{}]] if field == "extras" else [True, 1, {}, [], ["text"]]
            for value in good:
                validate(SCREEN, dict(base, **{field: value}))
            for value in bad:
                with self.subTest(field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                    validate(SCREEN, dict(base, **{field: value}))
        for row in (dict(base, unknown="extra"), dict(base, tabs=[{}]), dict(base, stats=[]),
                    dict(base, id="inventory"), dict(base, versions=["A"])):
            with self.subTest(row=row), self.assertRaises(jsonschema.ValidationError):
                validate(SCREEN, row)
        for value in (None, {}):
            validate(CATALOG, {"screens": value})
        for value in ([], True, 1, "text", [{"screen": "inventory"}]):
            with self.subTest(value=value), self.assertRaises(jsonschema.ValidationError):
                validate(CATALOG, {"screens": value})

    def test_context_union_optional_null_empty_and_closed_boundaries(self):
        validate(CONTEXT, {})
        for alias in ("A", "S"):
            for value in (None, [], [""], ["unrestricted stat ≈"] * 127):
                validate(CONTEXT, {alias: value})
            for value in (True, 1, "text", {}, [None], [1], [True], [[]], [{}]):
                with self.subTest(alias=alias, value=value), self.assertRaises(jsonschema.ValidationError):
                    validate(CONTEXT, {alias: value})
        for row in ({"a": []}, {"s": []}, {"unknown": []}, {"id": "x"}, {"screen": "inventory"}):
            with self.subTest(row=row), self.assertRaises(jsonschema.ValidationError):
                validate(CONTEXT, row)
        for field in ("tabs", "stats"):
            for value in (None, {}, {"A": []}, {"S": []}, {"A": None}, {"S": None},
                          {"A": ["same"] * 127, "S": [""]}):
                validate(SCREEN, {"screen": "inventory", field: value})
                validate(CATALOG, {"screens": {"inventory": {field: value}}})
            for value in (True, 1, "text", [{"A": []}], {"A": "text"}, {"S": [None]},
                          {"A": [["nested"]]}, {"a": []}, {"unknown": []}):
                with self.subTest(field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                    validate(SCREEN, {"screen": "inventory", field: value})
        for value in ([], [""], ["same"] * 127):
            validate(SCREEN, {"screen": "crafting", "tabs": value})
            with self.assertRaises(jsonschema.ValidationError):
                validate(SCREEN, {"screen": "character-sheet", "stats": value})
        for value in ([None], [1], [True], [[]], [{}]):
            with self.subTest(value=value), self.assertRaises(jsonschema.ValidationError):
                validate(SCREEN, {"screen": "crafting", "tabs": value})

    def test_container_keys_are_not_global_ids_or_body_equality(self):
        for row in ({}, {"screen": None}, {"screen": 1}, {"screen": True}, {"screen": []}):
            with self.subTest(row=row), self.assertRaises(jsonschema.ValidationError):
                validate(SCREEN, row)
        for key in ("", "Bad_ID", "resolution|windowed", "A", "local label ≈"):
            validate(SCREEN, {"screen": key})  # Unrestricted local string, no kebab-ID constraint.
            validate(CATALOG, {"screens": {key: {}}})
        for body in ({}, None, {"screen": "different"}, {"screen": ""}, {"shows": None}):
            validate(CATALOG, {"screens": {"inventory": body}})
        for body in ("text", 1, True, [], {"screen": None}, {"screen": 1}, {"shows": []}, {"unknown": "x"}):
            with self.subTest(body=body), self.assertRaises(jsonschema.ValidationError):
                validate(CATALOG, {"screens": {"inventory": body}})

    def test_actual_yaml_mutations_falsify_same_inherited_contract(self):
        assert_contract(self, SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "meta.yaml"
            original = yaml.safe_load(path.read_text())
            cases = []
            for owner, aliases in [(SCREEN, ("screen", *FIELDS)), (CATALOG, ("screens",))]:
                for alias in aliases:
                    name = owner + "-" + alias
                    slot = original["slots"][name]
                    for facet, value in [("alias", "wrong"), ("domain", "option"), ("slot_uri", "pixlnd:wrong"),
                                         ("range", "integer"), ("required", not slot["required"]),
                                         ("multivalued", not slot.get("multivalued", False)),
                                         ("inlined", not slot.get("inlined", False))]:
                        cases.append(("slots", name, facet, value))
                    attached = original["classes"][owner]["slots"]
                    cases.append(("classes", owner, "slots", [s for s in attached if s != name]))
            cases += [("slots", SCREEN + "-screen", "key", False),
                      ("slots", CATALOG + "-screens", "inlined_as_list", True)]
            for section, name, facet, value in cases:
                data = deepcopy(original)
                data[section][name][facet] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(name=name, facet=facet), self.assertRaises(AssertionError):
                    assert_contract(self, SchemaView(str(target / "pixlnd.yaml")))
            self.assertEqual(len(cases), 42)

    def test_context_yaml_mutations_falsify_same_inherited_contract(self):
        assert_contract(self, SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "meta.yaml"
            original = yaml.safe_load(path.read_text())
            cases = []
            for owner, name in [(SCREEN, SCREEN + "-tabs"), (SCREEN, SCREEN + "-stats"),
                                (CONTEXT, CONTEXT + "-a"), (CONTEXT, CONTEXT + "-s")]:
                slot = original["slots"][name]
                for facet, value in [("alias", "wrong"), ("domain", "option"), ("slot_uri", "pixlnd:wrong"),
                                     ("range", "integer"), ("required", True),
                                     ("multivalued", not slot.get("multivalued", False)),
                                     ("inlined", not slot.get("inlined", False)),
                                     ("inlined_as_list", True), ("list_elements_unique", True),
                                     ("minimum_cardinality", 1), ("maximum_cardinality", 2)]:
                    cases.append(("slots", name, facet, value))
                cases.append(("classes", owner, "slots", [s for s in original["classes"][owner]["slots"] if s != name]))
            cases += [("slots", SCREEN + "-tabs", "any_of", [branch]) for branch in
                      original["slots"][SCREEN + "-tabs"]["any_of"]]
            cases += [("classes", CONTEXT, "class_uri", "pixlnd:wrong"),
                      ("classes", CONTEXT, "slots", list(reversed(original["classes"][CONTEXT]["slots"])))]
            for section, name, facet, value in cases:
                data = deepcopy(original)
                data[section][name][facet] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(name=name, facet=facet), self.assertRaises(AssertionError):
                    assert_contract(self, SchemaView(str(target / "pixlnd.yaml")))
            self.assertEqual(len(cases), 52)

    def test_native_mutation_rejection_no_effect_and_broadening(self):
        cases = [
            (SCREEN + "-desc", "attachment", None, SCREEN, {"screen": "skills", "desc": "tree"}, False, None),
            (SCREEN + "-desc", "alias", "wrong", SCREEN, {"screen": "skills", "desc": "tree"}, False, None),
            (SCREEN + "-desc", "domain", "option", SCREEN, {"screen": "skills", "desc": "tree"}, True, None),
            (SCREEN + "-desc", "slot_uri", "pixlnd:wrong", SCREEN, {"screen": "skills", "desc": "tree"}, True, None),
            (SCREEN + "-desc", "inlined", True, SCREEN, {"screen": "skills", "desc": "tree"}, True, None),
            (SCREEN + "-desc", "range", "integer", SCREEN, {"screen": "skills", "desc": "tree"}, False, {"screen": "skills", "desc": 1}),
            (SCREEN + "-shows", "multivalued", True, SCREEN, {"screen": "crafting", "shows": "station"}, False, {"screen": "crafting", "shows": ["station"]}),
            (SCREEN + "-extras", "multivalued", False, SCREEN, {"screen": "inventory", "extras": ["coins"]}, False, {"screen": "inventory", "extras": "coins"}),
            (SCREEN + "-desc", "required", True, SCREEN, {"screen": "friends-widget"}, False, None),
            (SCREEN + "-screen", "key", False, CATALOG, {"screens": {"inventory": {}}}, False, None),
            (CATALOG + "-screens", "multivalued", False, CATALOG, {"screens": {"inventory": {}}}, False, None),
            (CATALOG + "-screens", "inlined_as_list", True, CATALOG, {"screens": {"inventory": {}}}, False, None),
            (SCREEN + "-tabs", "any_of", [{"range": "string", "multivalued": True}], SCREEN,
             {"screen": "inventory", "tabs": {"A": ["equipment"]}}, False, None),
            (SCREEN + "-tabs", "any_of", [{"range": CONTEXT}], SCREEN,
             {"screen": "crafting", "tabs": ["weapon"]}, False, None),
            (SCREEN + "-tabs", "attachment", None, SCREEN,
             {"screen": "crafting", "tabs": ["weapon"]}, False, None),
            (SCREEN + "-stats", "alias", "wrong", SCREEN,
             {"screen": "character-sheet", "stats": {"S": ["hp"]}}, False, None),
            (SCREEN + "-stats", "domain", "option", SCREEN,
             {"screen": "character-sheet", "stats": {"S": ["hp"]}}, True, None),
            (SCREEN + "-stats", "slot_uri", "pixlnd:wrong", SCREEN,
             {"screen": "character-sheet", "stats": {"S": ["hp"]}}, True, None),
            (SCREEN + "-stats", "required", True, SCREEN, {"screen": "friends-widget"}, False, None),
            (CONTEXT + "-a", "alias", "a", CONTEXT, {"A": ["hp"]}, False, {"a": ["hp"]}),
            (CONTEXT + "-s", "attachment", None, CONTEXT, {"S": ["hp"]}, False, None),
            (CONTEXT + "-a", "multivalued", False, CONTEXT, {"A": ["hp"]}, False, {"A": "hp"}),
            (CONTEXT + "-s", "range", "integer", CONTEXT, {"S": ["hp"]}, False, {"S": [1]}),
        ]
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "meta.yaml"
            original = yaml.safe_load(path.read_text())
            for name, facet, value, owner, row, no_effect, alternate in cases:
                self.assertTrue(validator(owner).is_valid(row))
                data = deepcopy(original)
                if facet == "attachment":
                    data["classes"][owner]["slots"].remove(name)
                else:
                    data["slots"][name][facet] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(name=name, facet=facet):
                    with self.assertRaises(AssertionError):
                        assert_contract(self, SchemaView(str(target / "pixlnd.yaml")))
                    schema = json.loads(JsonSchemaGenerator(str(target / "pixlnd.yaml"), top_class=owner,
                                        preserve_names=True, not_closed=False).serialize())
                    check = jsonschema.Draft201909Validator(schema)
                    check.check_schema(schema)
                    self.assertEqual(check.is_valid(row), no_effect)
                    print("SCREENS-NATIVE-MUTATION", name, facet, "native-no-effect" if no_effect else "native-rejection")
                    if alternate is not None:
                        self.assertFalse(validator(owner).is_valid(alternate))
                        self.assertTrue(check.is_valid(alternate))
                        print("SCREENS-NATIVE-MUTATION", name, facet, "native-broadening", alternate)


if __name__ == "__main__":
    unittest.main()
