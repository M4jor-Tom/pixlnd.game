"""Selected presentation shapes only; no control, rendering or source-loader claim."""
import json
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
from test_ontology_schema import SCHEMA, copy_schema, load_module
from test_ontology_schema_authoring import catalog, generated, validate, validator

CATALOG = "ui-presentation-catalog"
CAMERA = "ui-camera-presentation"
OPTION = "ui-option-presentation"
FIELDS = {
    "hud-element": [("pos", "string", False, False),
                    ("shows", None, False, False),
                    ("desc", "string", False, False),
                    ("default", "string", False, False)],
    CATALOG: [("hud", "hud-element", True, True), ("camera", CAMERA, False, True)],
    CAMERA: [(field, "string", False, False) for field in ("mode", "aim", "map")],
}


def verify_field_contract(test, view, owner, alias, range_, multiple, inline):
    name = owner + "-" + alias
    slot = view.get_slot(name)
    test.assertEqual((slot.alias, slot.domain, slot.range), (alias, owner, range_))
    test.assertEqual(str(slot.slot_uri), "pixlnd:" + owner + "/" + alias)
    test.assertIs(slot.required, False)
    test.assertEqual((bool(slot.multivalued), bool(slot.inlined)), (multiple, inline))
    test.assertFalse(slot.identifier or slot.key or slot.inlined_as_list or slot.list_elements_unique)
    test.assertIn("../domain/3_Classes.md#hud-element", slot.see_also)
    test.assertIn("../instances/ui.json#" + ("hud" if owner == "hud-element" else alias
                  if owner == CATALOG else "camera"), slot.see_also)
    for facet in ("minimum_cardinality", "maximum_cardinality", "minimum_value", "maximum_value",
                  "pattern", "equals_string", "equals_number"):
        test.assertIsNone(getattr(slot, facet))
    if alias != "shows":
        test.assertFalse(slot.any_of)


def verify_owner_contract(test, view, owner, fields):
    cls = view.get_class(owner)
    test.assertIsNotNone(cls)
    test.assertEqual(str(cls.class_uri), "pixlnd:" + owner)
    test.assertEqual(cls.slots, (["id"] if owner == "hud-element" else []) +
                     [owner + "-" + alias for alias, *_ in fields] +
                     (["ui-presentation-catalog-screens", CATALOG + "-options"] if owner == CATALOG else []))
    test.assertIsNone(cls.is_a)
    test.assertFalse(cls.mixins or cls.unique_keys)
    for alias, range_, multiple, inline in fields:
        verify_field_contract(test, view, owner, alias, range_, multiple, inline)


def verify_screen_slot(test, view, owner, alias, range_, required, multiple, inline, key):
    slot = view.get_slot(owner + "-" + alias)
    test.assertEqual((slot.alias, slot.domain, slot.range), (alias, owner, range_))
    test.assertEqual(str(slot.slot_uri), "pixlnd:" + owner + "/" + alias)
    test.assertIs(slot.required, required)
    test.assertEqual((bool(slot.multivalued), bool(slot.inlined), bool(slot.key)), (multiple, inline, key))
    test.assertFalse(slot.identifier or slot.inlined_as_list or slot.list_elements_unique or slot.any_of)
    test.assertIn("../domain/3_Classes.md#hud-element", slot.see_also)
    test.assertIn("../instances/ui.json#screens", slot.see_also)
    for facet in ("minimum_cardinality", "maximum_cardinality", "minimum_value", "maximum_value",
                  "pattern", "equals_string", "equals_number"):
        test.assertIsNone(getattr(slot, facet))


def verify_scalar_field(self, owner, base, field, inline):
    if inline:
        good = [None, {}]
        bad = [[], True, 1, "text"]
    elif field == "shows":
        good = [None, "", "label", [], [""], ["same"] * 127]
        bad = [True, 1, {}, [1], [True], [None], [[]], [["label"]], [{}]]
    else:
        good = [None, "", "unrestricted text ≈" * 127]
        bad = [True, 1, [], {}, ["text"]]
    for value in good:
        validate(owner, dict(base, **{field: value}))
    for value in bad:
        with self.subTest(owner=owner, field=field, value=value), self.assertRaises(jsonschema.ValidationError):
            validate(owner, dict(base, **{field: value}))


def verify_alternate(self, check, name, facet, owner):
    alternate = None
    if name == "hud-element-pos" and facet in ("range", "multivalued"):
        alternate = {"id": "x", "pos": 1 if facet == "range" else ["left"]}
    if name == CATALOG + "-hud" and facet == "inlined":
        alternate = {"hud": ["arbitrary-reference"]}
    if alternate is not None:
        self.assertFalse(validator(owner).is_valid(alternate))
        self.assertTrue(check.is_valid(alternate))
        print("NATIVE-MUTATION", name, facet, "native-broadening", alternate)


def verify_option_fields(self, base):
    for field, good, bad in [
        ("default", [None, -111, 0, 111, 111.0], [True, False, "111", 111.5, [], {}]),
        ("cfg", [None, "", "unrestricted ≈" * 127], [True, 1, [], {}, ["text"]]),
    ]:
        for value in good:
            validate(OPTION, dict(base, **{field: value}))
        for value in bad:
            with self.subTest(field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                validate(OPTION, dict(base, **{field: value}))


def verify_option_bodies(self, base):
    for body in ("text", 1, True, [], {"option": None}, {"option": 1}, {"default": True},
                 {"cfg": []}, {"since": "2013-07-23"}, {"note": "text"}, {"versions": ["S"]},
                 {"missing": []}, {"id": "x"}, {"unknown": "x"}):
        with self.subTest(body=body), self.assertRaises(jsonschema.ValidationError):
            validate(CATALOG, {"options": {"fps-limit": body}})
        with self.subTest(standalone=body), self.assertRaises(jsonschema.ValidationError):
            validate(OPTION, dict(base, **body) if isinstance(body, dict) else body)


def assert_contract(test, view):
    view.all_classes()  # Materialize imported modules before inspecting their own declarations.
    module = load_module(Path(view.schema.source_file).with_name("meta.yaml"))
    test.assertEqual(set(module["slots"]), {o + "-" + a for o, fs in FIELDS.items() for a, *_ in fs} |
                     {"ui-presentation-catalog-screens", "ui-screen-presentation-screen",
                      "ui-screen-presentation-desc", "ui-screen-presentation-shows", "ui-screen-presentation-extras",
                      "ui-screen-presentation-tabs", "ui-screen-presentation-stats",
                      "ui-screen-context-lists-a", "ui-screen-context-lists-s",
                      OPTION + "-option", OPTION + "-default", OPTION + "-cfg", CATALOG + "-options",
                      "control-action-id", "control-action-value", "control-action-lifecycle",
                      "control-action-context", "control-action-effect-reference",
                      "input-binding-action", "input-binding-physical-input",
                      "input-binding-phases", "input-binding-contexts", "input-binding-mapping-status",
                      "input-binding-alias-of", "input-binding-alias", "android-profile-deadzone-ratio",
                      "android-profile-min-target-dp", "android-profile-look-deg-per-safe-width"})
    test.assertEqual(set(module["classes"]), {"ruleset", "control-action", "controller-profile", "input-binding",
                     "android-profile-parameters", "android-controller-profile",
                     "hud-element", "option", "slash-command", "audio", "mission-type", "arena",
                     "arena-wave", "gnome-supplier", "circle-of-power", CATALOG, CAMERA, "ui-screen-presentation",
                     "ui-screen-context-lists", OPTION})
    for owner, fields in FIELDS.items():
        verify_owner_contract(test, view, owner, fields)
    shows = view.get_slot("hud-element-shows")
    test.assertEqual([(b.range, b.multivalued) for b in shows.any_of],
                     [("string", None), ("string", True)])
    for branch in shows.any_of:
        for facet in ("minimum_cardinality", "maximum_cardinality", "pattern", "equals_string"):
            test.assertIsNone(getattr(branch, facet))
    identity = view.induced_slot("id", "hud-element")
    test.assertTrue(identity.identifier and identity.required)
    test.assertEqual(identity.pattern, "^[a-z0-9]+(?:-[a-z0-9]+)*$")
    screen = view.get_class("ui-screen-presentation")
    test.assertEqual(str(screen.class_uri), "pixlnd:ui-screen-presentation")
    test.assertEqual(screen.slots, ["ui-screen-presentation-" + a for a in
                                  ("screen", "desc", "shows", "extras", "tabs", "stats")])
    test.assertIsNone(screen.is_a)
    test.assertFalse(screen.mixins or screen.unique_keys)
    for owner, alias, range_, required, multiple, inline, key in [
        ("ui-screen-presentation", "screen", "string", True, False, False, True),
        ("ui-screen-presentation", "desc", "string", False, False, False, False),
        ("ui-screen-presentation", "shows", "string", False, False, False, False),
        ("ui-screen-presentation", "extras", "string", False, True, False, False),
        (CATALOG, "screens", "ui-screen-presentation", False, True, True, False),
    ]:
        verify_screen_slot(test, view, owner, alias, range_, required, multiple, inline, key)
    assert_context_contract(test, view)
    assert_option_contract(test, view)


def assert_context_contract(test, view):
    owner = "ui-screen-context-lists"
    cls = view.get_class(owner)
    test.assertIsNotNone(cls)
    test.assertEqual(str(cls.class_uri), "pixlnd:" + owner)
    test.assertEqual(cls.slots, ["ui-screen-context-lists-a", "ui-screen-context-lists-s"])
    test.assertIsNone(cls.is_a)
    test.assertFalse(cls.mixins or cls.unique_keys)
    test.assertIn("../domain/3_Classes.md#hud-element", cls.see_also)
    test.assertIn("../instances/ui.json#screens", cls.see_also)
    for name, alias, domain, range_, multiple, inline in [
        ("ui-screen-presentation-tabs", "tabs", "ui-screen-presentation", None, False, True),
        ("ui-screen-presentation-stats", "stats", "ui-screen-presentation", owner, False, True),
        ("ui-screen-context-lists-a", "A", owner, "string", True, False),
        ("ui-screen-context-lists-s", "S", owner, "string", True, False),
    ]:
        slot = view.get_slot(name)
        test.assertIsNotNone(slot)
        test.assertEqual((slot.alias, slot.domain, slot.range), (alias, domain, range_))
        test.assertEqual(str(slot.slot_uri), "pixlnd:" + domain + "/" + alias)
        test.assertIs(slot.required, False)
        test.assertEqual((bool(slot.multivalued), bool(slot.inlined)), (multiple, inline))
        test.assertFalse(slot.identifier or slot.key or slot.inlined_as_list or slot.list_elements_unique)
        test.assertIn("../domain/3_Classes.md#hud-element", slot.see_also)
        test.assertIn("../instances/ui.json#screens", slot.see_also)
        for facet in ("minimum_cardinality", "maximum_cardinality", "minimum_value", "maximum_value",
                      "pattern", "equals_string", "equals_number", "ifabsent"):
            test.assertIsNone(getattr(slot, facet))
        if alias != "tabs":
            test.assertFalse(slot.any_of)
    branches = view.get_slot("ui-screen-presentation-tabs").any_of
    test.assertEqual([(b.range, b.multivalued) for b in branches],
                     [("string", True), (owner, None)])
    for branch in branches:
        for facet in ("minimum_cardinality", "maximum_cardinality", "pattern", "equals_string",
                      "minimum_value", "maximum_value"):
            test.assertIsNone(getattr(branch, facet))
        test.assertFalse(branch.required or branch.inlined_as_list)


def assert_option_contract(test, view):
    cls = view.get_class(OPTION)
    test.assertIsNotNone(cls)
    test.assertEqual(str(cls.class_uri), "pixlnd:" + OPTION)
    test.assertEqual(cls.slots, [OPTION + "-" + a for a in ("option", "default", "cfg")])
    test.assertIsNone(cls.is_a)
    test.assertFalse(cls.mixins or cls.unique_keys)
    test.assertIn("../domain/3_Classes.md#option", cls.see_also)
    test.assertIn("../instances/ui.json#options", cls.see_also)
    for owner, alias, range_, required, multiple, inline, key in [
        (OPTION, "option", "string", True, False, False, True),
        (OPTION, "default", "integer", False, False, False, False),
        (OPTION, "cfg", "string", False, False, False, False),
        (CATALOG, "options", OPTION, False, True, True, False),
    ]:
        slot = view.get_slot(owner + "-" + alias)
        test.assertIsNotNone(slot)
        test.assertEqual((slot.alias, slot.domain, slot.range), (alias, owner, range_))
        test.assertEqual(str(slot.slot_uri), "pixlnd:" + owner + "/" + alias)
        test.assertIs(slot.required, required)
        test.assertEqual((bool(slot.multivalued), bool(slot.inlined), bool(slot.key)), (multiple, inline, key))
        test.assertFalse(slot.identifier or slot.inlined_as_list or slot.list_elements_unique or slot.any_of)
        test.assertIn("../domain/3_Classes.md#option", slot.see_also)
        test.assertIn("../instances/ui.json#options", slot.see_also)
        for facet in ("minimum_cardinality", "maximum_cardinality", "minimum_value", "maximum_value",
                      "pattern", "equals_string", "equals_number", "ifabsent"):
            test.assertIsNone(getattr(slot, facet))


def option_projections():
    return {key: {field: value for field, value in body.items() if field in ("default", "cfg")}
            for key, body in catalog("ui")["options"].items() if isinstance(body, dict)}


def projections():
    source = catalog("ui")
    hud = {key: {field: value for field, value in row.items()
                 if field in ("pos", "shows", "desc", "default")}
           for key, row in source["hud"].items()}
    return {"hud": hud, "camera": source["camera"]}


class UiPresentationTests(unittest.TestCase):
    def test_contract(self):
        assert_contract(self, SchemaView(str(SCHEMA)))

    def test_complete_ui_source_contract(self):
        from ontology_source_contracts import assert_declared_root, validate_source

        row = catalog("ui")
        fields = {"$schema", "_controls", "_profiles", "hud", "screens", "options", "camera"}
        assert_declared_root("ui-source", fields, fields)
        validate_source("ui", row)
        self.assertEqual(row["options"]["fps-limit"]["default"], 111)
        self.assertIsInstance(row["options"]["missing"], list)

    def test_missing_top_class_is_permissive_not_admission_proof(self):
        schema = generated("not-a-selected-class")
        self.assertNotIn("properties", schema)
        check = jsonschema.Draft201909Validator(schema)
        self.assertTrue(check.is_valid({}))
        self.assertTrue(check.is_valid({"unknown": [True, 1]}))

    def test_unchanged_source_projections(self):
        source, row = catalog("ui"), projections()
        self.assertEqual(list(row["hud"]), list(source["hud"]))
        self.assertEqual(len(row["hud"]), 21)
        self.assertEqual(sum(len(body) for body in row["hud"].values()) + len(row["camera"]), 30)
        self.assertEqual([sum(f in b for b in row["hud"].values()) for f in
                          ("pos", "shows", "desc", "default")], [11, 8, 7, 1])
        shows = {k: b["shows"] for k, b in row["hud"].items() if "shows" in b}
        self.assertEqual(shows, {
            "portrait": ["head", "name", "level & class", "HP", "XP current/needed (A)"],
            "key-item-bar": "collected land key items",
            "buff-icons": ["mana absorption", "circle of power", "elixirs"],
            "environment": ["time", "temperature", "humidity",
                            "minimap (3-D, rotates with camera, revealed tiles, boss heads & quest givers)", "compass"],
            "bars": ["HP", "MP (pink while charging)", "stamina (hidden when full, A)", "stealth (rogue/sniper)"],
            "pet-panel": ["pet HP", "XP (A)", "hydration droplets (A)"],
            "message-log": "last ~9 item/XP messages",
            "debug-menu": ["FPS", "frametime graph", "CPU/GPU time", "GPU + driver", "OS", "engine version"]})
        self.assertEqual(sum(type(v) is list for v in shows.values()), 6)
        self.assertEqual(sum(type(v) is str for v in shows.values()), 2)
        self.assertEqual(set(row["camera"]), {"mode", "aim", "map"})
        self.assertEqual(row["camera"], source["camera"])
        for identifier, body in row["hud"].items():
            self.assertNotIn("id", body)
            self.assertEqual(body, {k: v for k, v in source["hud"][identifier].items()
                                    if k in ("pos", "shows", "desc", "default")})
            validate("hud-element", dict(body, id=identifier))
        for identifier in ("stun-stars", "hp-bars-toggle"):
            self.assertEqual(row["hud"][identifier], {})
            validate("hud-element", {"id": identifier})
        validate(CAMERA, row["camera"])
        validate(CATALOG, row)
        with self.assertRaises(jsonschema.ValidationError):
            validate(CATALOG, source)  # Excluded full envelope, not loader admission.

    def test_native_scalar_union_and_optional_boundaries(self):
        for owner, fields in FIELDS.items():
            base = {"id": "example"} if owner == "hud-element" else {}
            validate(owner, base)
            with self.assertRaises(jsonschema.ValidationError):
                validate(owner, dict(base, unknown="extra"))
            for field, range_, multiple, inline in fields:
                verify_scalar_field(self, owner, base, field, inline)
        for row in ({"camera": {"unknown": "extra"}}, {"hud": {"x": {"unknown": "extra"}}},
                    {"hud": {"x": {"shows": [None]}}}, {"camera": {"mode": {}}}):
            with self.subTest(row=row), self.assertRaises(jsonschema.ValidationError):
                validate(CATALOG, row)

    def test_standalone_and_keyed_identity_are_distinct(self):
        for row in ({}, {"id": None}, {"id": "Bad_ID"}, {"id": ""}, {"id": 1}):
            with self.subTest(row=row), self.assertRaises(jsonschema.ValidationError):
                validate("hud-element", row)
        validate("hud-element", {"id": "valid-kebab-9"})
        # Keyed bodies omit id; key patterns and key/body equality are NOT enforced.
        for hud in ({"Bad_ID": {}}, {"": {}}, {"x": {"id": "different"}},
                    {"x": None}, {"x": {"shows": None}}):
            validate(CATALOG, {"hud": hud})
        # Neither a list of identified bodies nor scalar shorthand is native here.
        for hud in ([{"id": "x"}], {"x": "text"}, {"x": []}, {"x": 1},
                    {"x": {"id": None}}, {"x": {"id": "Bad_ID"}}):
            with self.subTest(hud=hud), self.assertRaises(jsonschema.ValidationError):
                validate(CATALOG, {"hud": hud})

    def test_actual_yaml_mutations_falsify_same_contract(self):
        assert_contract(self, SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "meta.yaml"
            original = yaml.safe_load(path.read_text())
            cases = []
            for owner, fields in FIELDS.items():
                for alias, range_, multiple, inline in fields:
                    name = owner + "-" + alias
                    for facet, value in [("alias", "wrong"), ("domain", "option"),
                                         ("slot_uri", "pixlnd:wrong"), ("range", "integer"),
                                         ("required", True), ("multivalued", not multiple),
                                         ("inlined", not inline)]:
                        cases.append(("slots", name, facet, value))
                    attached = original["classes"][owner]["slots"]
                    cases.append(("classes", owner, "slots", [s for s in attached if s != name]))
            cases += [("slots", "hud-element-shows", "any_of", [branch]) for branch in
                      original["slots"]["hud-element-shows"]["any_of"]]
            cases += [("slots", CATALOG + "-hud", "inlined_as_list", True)]
            for section, name, facet, value in cases:
                data = deepcopy(original)
                data[section][name][facet] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(name=name, facet=facet), self.assertRaises(AssertionError):
                    assert_contract(self, SchemaView(str(target / "pixlnd.yaml")))
            self.assertEqual(len(cases), 75)

    def test_native_mutation_distinctions(self):
        # Each row tests one actual temporary declaration, not a changed-dict comparison.
        cases = [
            ("hud-element-pos", "attachment", None, "hud-element", {"id": "x", "pos": "left"}),
            ("hud-element-pos", "alias", "wrong", "hud-element", {"id": "x", "pos": "left"}),
            ("hud-element-pos", "domain", "option", "hud-element", {"id": "x", "pos": "left"}),
            ("hud-element-pos", "slot_uri", "pixlnd:wrong", "hud-element", {"id": "x", "pos": "left"}),
            ("hud-element-pos", "range", "integer", "hud-element", {"id": "x", "pos": "left"}),
            ("hud-element-pos", "required", True, "hud-element", {"id": "x"}),
            ("hud-element-pos", "multivalued", True, "hud-element", {"id": "x", "pos": "left"}),
            ("hud-element-pos", "inlined", True, "hud-element", {"id": "x", "pos": "left"}),
            ("hud-element-shows", "any_of", [{"range": "string"}], "hud-element", {"id": "x", "shows": ["label"]}),
            ("hud-element-shows", "any_of", [{"range": "string", "multivalued": True}], "hud-element", {"id": "x", "shows": "label"}),
            (CATALOG + "-hud", "multivalued", False, CATALOG, {"hud": {"x": {}}}),
            (CATALOG + "-hud", "inlined", False, CATALOG, {"hud": {"x": {}}}),
            (CATALOG + "-hud", "inlined_as_list", True, CATALOG, {"hud": {"x": {}}}),
            (CATALOG + "-camera", "inlined", False, CATALOG, {"camera": {"mode": "text"}}),
        ]
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "meta.yaml"
            original = yaml.safe_load(path.read_text())
            for name, facet, value, owner, row in cases:
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
                    schema = json.loads(JsonSchemaGenerator(
                        str(target / "pixlnd.yaml"), top_class=owner,
                        preserve_names=True, not_closed=False).serialize())
                    check = jsonschema.Draft201909Validator(schema)
                    check.check_schema(schema)
                    no_effect = facet in ("domain", "slot_uri") or (facet == "inlined" and
                                name in ("hud-element-pos", CATALOG + "-camera"))
                    self.assertEqual(check.is_valid(row), no_effect)
                    classification = "native-no-effect" if no_effect else "native-rejection"
                    print("NATIVE-MUTATION", name, facet, classification)
                    verify_alternate(self, check, name, facet, owner)

    def test_direct_root_properties(self):
        for owner, fields in FIELDS.items():
            # Missing top classes silently generate permissive roots: require actual properties.
            with self.subTest(owner=owner):
                schema = generated(owner)
                self.assertEqual(set(schema.get("properties", {})),
                                 {a for a, *_ in fields} | ({"id"} if owner == "hud-element" else set()) |
                                 ({"screens", "options"} if owner == CATALOG else set()))
                self.assertFalse(schema["additionalProperties"])


class UiOptionPresentationTests(unittest.TestCase):
    def test_option_contract(self):
        assert_option_contract(self, SchemaView(str(SCHEMA)))

    def test_option_source_and_native_boundaries(self):
        # Removing declarations/types/closedness must lose these actual source witnesses.
        for owner, properties in [(OPTION, {"option", "default", "cfg"}),
                                  (CATALOG, {"hud", "camera", "screens", "options"})]:
            schema = generated(owner)
            self.assertEqual(set(schema.get("properties", {})), properties)
            self.assertFalse(schema["additionalProperties"])
        source, rows = catalog("ui")["options"], option_projections()
        self.assertEqual(list(rows), ["fps-limit", "invert-y", "camera-speed", "resolution|windowed",
                         "render-distance", "anti-aliasing", "rarity-display", "music-loop", "volumes",
                         "shadows|view-distance", "remap-controls", "background-refresh-reduce"])
        self.assertEqual(sum(map(len, rows.values())), 2)
        self.assertEqual(sum(not body for body in rows.values()), 10)
        self.assertEqual(rows["fps-limit"], {"default": 111})
        self.assertEqual(rows["anti-aliasing"], {"cfg": "antiAliasingSamples 8 (1 disables)"})
        for key, body in rows.items():
            self.assertNotIn("option", body)
            validate(OPTION, dict(body, option=key))
        validate(CATALOG, dict(projections(), options=rows))
        for row in ({"options": source}, catalog("ui")):
            with self.assertRaises(jsonschema.ValidationError):
                validate(CATALOG, row)
        base = {"option": "fps-limit"}
        validate(OPTION, base)
        verify_option_fields(self, base)
        # JSON Schema integer is mathematical, not lexical 111-versus-111.0 enforcement.
        for value in (111, True, [], {}):
            with self.subTest(hud_default=value), self.assertRaises(jsonschema.ValidationError):
                validate("hud-element", {"id": "help-widget", "default": value})
        self.assertEqual(catalog("ui")["hud"]["help-widget"]["default"], "on for new characters (0.9.3-0)")
        for row in ({}, {"option": None}, {"option": 1}, {"option": True}, {"option": []}):
            with self.subTest(row=row), self.assertRaises(jsonschema.ValidationError):
                validate(OPTION, row)
        for key in ("", "Bad_ID", "resolution|windowed", "shadows|view-distance", "local label ≈"):
            validate(OPTION, {"option": key})
            validate(CATALOG, {"options": {key: {}}})
        for value in (None, {}):
            validate(CATALOG, {"options": value})
        for body in ({}, None, {"option": "different"}, {"option": ""}, {"default": None}, {"cfg": None}):
            validate(CATALOG, {"options": {"fps-limit": body}})
        for value in ([], True, 1, "text", [{"option": "fps-limit"}]):
            with self.subTest(value=value), self.assertRaises(jsonschema.ValidationError):
                validate(CATALOG, {"options": value})
        verify_option_bodies(self, base)

    def test_option_yaml_mutations_falsify_same_contract(self):
        assert_contract(self, SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "meta.yaml"
            original = yaml.safe_load(path.read_text())
            cases = []
            for owner, alias in [(OPTION, "option"), (OPTION, "default"), (OPTION, "cfg"), (CATALOG, "options")]:
                name = owner + "-" + alias
                slot = original["slots"][name]
                for facet, value in [("alias", "wrong"), ("domain", "option"), ("slot_uri", "pixlnd:wrong"),
                                     ("range", "string" if alias == "default" else "integer"),
                                     ("required", not slot["required"]), ("key", not slot.get("key", False)),
                                     ("multivalued", not slot.get("multivalued", False)),
                                     ("inlined", not slot.get("inlined", False)), ("inlined_as_list", True),
                                     ("minimum_value", 0), ("maximum_value", 111), ("pattern", "^x$"),
                                     ("ifabsent", "string(x)")]:
                    cases.append(("slots", name, facet, value))
                cases.append(("classes", owner, "slots", [s for s in original["classes"][owner]["slots"] if s != name]))
            cases += [("classes", OPTION, "class_uri", "pixlnd:wrong"),
                      ("classes", OPTION, "slots", list(reversed(original["classes"][OPTION]["slots"])))]
            for section, name, facet, value in cases:
                data = deepcopy(original)
                data[section][name][facet] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(name=name, facet=facet), self.assertRaises(AssertionError):
                    assert_contract(self, SchemaView(str(target / "pixlnd.yaml")))
            self.assertEqual(len(cases), 58)

    def test_option_native_mutation_distinctions(self):
        cases = [
            (OPTION + "-default", "attachment", None, OPTION, {"option": "fps-limit", "default": 111}, False, None),
            (OPTION + "-default", "alias", "wrong", OPTION, {"option": "fps-limit", "default": 111}, False, None),
            (OPTION + "-default", "domain", "option", OPTION, {"option": "fps-limit", "default": 111}, True, None),
            (OPTION + "-default", "slot_uri", "pixlnd:wrong", OPTION, {"option": "fps-limit", "default": 111}, True, None),
            (OPTION + "-default", "inlined", True, OPTION, {"option": "fps-limit", "default": 111}, True, None),
            (OPTION + "-default", "range", "string", OPTION, {"option": "fps-limit", "default": 111}, False, {"option": "fps-limit", "default": "111"}),
            (OPTION + "-default", "required", True, OPTION, {"option": "camera-speed"}, False, None),
            (OPTION + "-default", "multivalued", True, OPTION, {"option": "fps-limit", "default": 111}, False, {"option": "fps-limit", "default": [111]}),
            (OPTION + "-default", "minimum_value", 0, OPTION, {"option": "fps-limit", "default": -1}, False, None),
            (OPTION + "-option", "required", False, OPTION, {"option": "camera-speed"}, True, None),
            (OPTION + "-option", "key", False, CATALOG, {"options": {"camera-speed": {}}}, False, None),
            (CATALOG + "-options", "multivalued", False, CATALOG, {"options": {"fps-limit": {"default": 111}}}, False, None),
            (CATALOG + "-options", "inlined", False, CATALOG, {"options": {"fps-limit": {"default": 111}}}, True, None),
            (CATALOG + "-options", "inlined_as_list", True, CATALOG, {"options": {"fps-limit": {"default": 111}}}, False, None),
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
                    self.assertIn("properties", schema)
                    self.assertFalse(schema["additionalProperties"])
                    check = jsonschema.Draft201909Validator(schema)
                    check.check_schema(schema)
                    self.assertEqual(check.is_valid(row), no_effect)
                    print("OPTIONS-NATIVE-MUTATION", name, facet, "native-no-effect" if no_effect else "native-rejection")
                    if alternate is not None:
                        self.assertFalse(validator(owner).is_valid(alternate))
                        self.assertTrue(check.is_valid(alternate))
                        print("OPTIONS-NATIVE-MUTATION", name, facet, "native-broadening", alternate)
                    if (name, facet) in ((OPTION + "-option", "required"), (CATALOG + "-options", "inlined")):
                        # key implies required; identity-free ranges inline regardless of this facet.
                        invalid = {} if owner == OPTION else {"options": ["arbitrary-reference"]}
                        self.assertFalse(validator(owner).is_valid(invalid))
                        self.assertFalse(check.is_valid(invalid))
                        print("OPTIONS-NATIVE-MUTATION", name, facet, "still-rejected", invalid)


if __name__ == "__main__":
    unittest.main()
