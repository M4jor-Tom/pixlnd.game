"""Whole Task5 inputs and device-independent control/profile shape contracts."""

import os
import re
import shutil
import tempfile
import unittest
from copy import deepcopy

import jsonschema
import yaml
from linkml_runtime.utils.schemaview import SchemaView
from ontology_source_contracts import (
    assert_declared_root,
    bind_source,
    unbind_source,
    validate_source,
)
from test_ontology_schema import ROOT, SCHEMA, generated
from test_ontology_schema_authoring import catalog, validate

SOURCE_ROOTS = [
    ("rulesets", {"$schema", "_controls", "_doc", "entries"}),
    ("controller-profiles", {"entries"}),
    ("keybinds", {"$schema", "_doc", "_controls", "_profile", "entries"}),
    ("ui", {"$schema", "_controls", "_profiles", "hud", "screens", "options", "camera"}),
    ("audio", {"$schema", "composer", "tracks", "music-rules", "sfx-alpha-ids", "voices", "ambient"}),
    ("slash-commands", {"$schema", "chat-rules", "entries"}),
    ("versions", {"$schema", "timeline", "alpha-to-steam-delta", "reception"}),
]
ANDROID_PARAMETER_SLOTS = {
    "android-profile-deadzone-ratio": ("deadzone-ratio", "float", 0.15, float),
    "android-profile-min-target-dp": ("min-target-dp", "integer", 48, int),
    "android-profile-look-deg-per-safe-width": ("look-deg-per-safe-width", "integer", 180, int),
}
CONTROL_REFERENCE_PREFIX = "../domain/controls.md#"


def assert_exact_numeric_value(test, actual, expected, numeric_type):
    test.assertIsInstance(actual, numeric_type)
    test.assertNotIsInstance(actual, bool)
    test.assertEqual(actual, expected)


def assert_android_profile_contract(test, view, meta_path):
    with open(meta_path, encoding="utf-8") as schema_file:
        raw_meta = yaml.safe_load(schema_file)
    test.assertIn("android-profile-parameters", view.all_classes(),
                  "Android-owned parameter facet class must be declared")
    parameters = view.get_class("android-profile-parameters")
    test.assertTrue(parameters.mixin)
    parameter_names = set(ANDROID_PARAMETER_SLOTS)
    test.assertEqual(set(parameters.slots), parameter_names)
    test.assertFalse(parameter_names & {"id", "key"})
    for slot_name, (alias, range_name, expected, number_type) in ANDROID_PARAMETER_SLOTS.items():
        raw_slot = raw_meta["slots"][slot_name]
        for facet in ("minimum_value", "maximum_value"):
            test.assertIs(type(raw_slot[facet]), number_type)
            test.assertNotIsInstance(raw_slot[facet], bool)
            test.assertEqual(raw_slot[facet], expected)
        slot = view.get_slot(slot_name)
        test.assertEqual((slot.alias, slot.range, bool(slot.required)), (alias, range_name, True))
        assert_exact_numeric_value(test, slot.minimum_value, expected, number_type)
        assert_exact_numeric_value(test, slot.maximum_value, expected, number_type)
    logical = view.get_class("android-controller-profile")
    test.assertEqual(logical.is_a, "controller-profile")
    test.assertIn("android-profile-parameters", logical.mixins)
    test.assertEqual(view.induced_slot("id", "android-controller-profile").equals_string, "android")
    logical_names = {slot.name for slot in view.class_induced_slots("android-controller-profile")}
    test.assertEqual(logical_names, parameter_names | {"id", "has-input-binding"})
    source = view.get_class("android-profile-source-row")
    test.assertIn("android-profile-parameters", source.mixins)
    source_names = {slot.name for slot in view.class_induced_slots("android-profile-source-row")}
    test.assertEqual(source_names, parameter_names | {"actions"})
    test.assertFalse(source_names & {"id", "key"})
    actions = view.induced_slot("actions", "android-profile-source-row")
    test.assertEqual((actions.range, bool(actions.multivalued), bool(actions.required)),
                     ("ControlActionId", True, True))
    entry = view.get_class("controller-profile-source-entry")
    key = entry.attributes["key"]
    test.assertEqual((key.alias, bool(key.key), bool(key.required)), ("key", True, True))
    test.assertEqual((entry.attributes["value"].range, bool(entry.attributes["value"].inlined)),
                     ("android-profile-source-row", True))
    generic = {slot.name for slot in view.class_induced_slots("controller-profile")}
    test.assertEqual(generic, {"id", "has-input-binding"})
    test.assertNotIn("controller-profile-source-row", view.all_classes())
    for owner in ("android-controller-profile", "android-profile-source-row"):
        for slot_name, (alias, range_name, expected, number_type) in ANDROID_PARAMETER_SLOTS.items():
            slot = view.induced_slot(slot_name, owner)
            test.assertEqual((slot.alias, slot.range, bool(slot.required)),
                             (alias, range_name, True))
            assert_exact_numeric_value(test, slot.minimum_value, expected, number_type)
            assert_exact_numeric_value(test, slot.maximum_value, expected, number_type)


def assert_profile_binding_contract(test, view):
    binding_names = [slot.name for slot in view.class_induced_slots("input-binding")]
    test.assertEqual(binding_names, [
        "input-binding-action", "input-binding-physical-input", "input-binding-phases",
        "input-binding-contexts", "input-binding-mapping-status", "input-binding-alias-of",
        "input-binding-alias",
    ])
    test.assertEqual([slot.name for slot in view.class_induced_slots("control-action")], [
        "control-action-id", "control-action-value", "control-action-lifecycle",
        "control-action-context", "control-action-effect-reference", "bound-to-input",
    ])
    test.assertEqual([slot.name for slot in view.class_induced_slots("controller-profile")],
                     ["id", "has-input-binding"])
    action = view.induced_slot("input-binding-action", "input-binding")
    test.assertEqual((action.range, bool(action.required), bool(action.multivalued),
                      action.minimum_cardinality, bool(action.inlined)),
                     ("control-action", True, True, 1, False))
    profile_bindings = view.induced_slot("has-input-binding", "controller-profile")
    test.assertEqual((profile_bindings.alias, profile_bindings.range, bool(profile_bindings.required),
                      bool(profile_bindings.multivalued), bool(profile_bindings.inlined)),
                     ("bindings", "input-binding", False, True, True))
    action_bindings = view.induced_slot("bound-to-input", "control-action")
    test.assertEqual((action_bindings.range, bool(action_bindings.multivalued),
                      bool(action_bindings.inlined)), ("input-binding", True, True))


def assert_ui_option_contract(test, view):
    test.assertNotIn("source-map-paths", view.get_class("ui-source").annotations)
    options = view.induced_slot("options", "ui-source")
    test.assertEqual((options.range, bool(options.required), bool(options.inlined)),
                     ("ui-source-options", True, True))
    option_map = view.get_class("ui-source-options")
    test.assertEqual(option_map.annotations["source-map-entries"].value, "entries")
    local_entries = option_map.attributes["entries"]
    test.assertEqual((local_entries.alias, local_entries.range, bool(local_entries.multivalued),
                      bool(local_entries.inlined), bool(local_entries.inlined_as_list),
                      bool(local_entries.required)),
                     ("entries", "ui-source-option-entry", True, True, True, True))
    option_slots = {slot.name: slot for slot in view.class_induced_slots("ui-source-options")}
    test.assertEqual(set(option_slots), {"missing", "entries"})
    missing = option_slots["missing"]
    test.assertEqual((missing.alias, missing.range, bool(missing.multivalued), bool(missing.required)),
                     ("missing", "string", True, True))
    entries = option_slots["entries"]
    test.assertEqual((entries.range, bool(entries.multivalued), bool(entries.inlined),
                      bool(entries.inlined_as_list), bool(entries.required)),
                     ("ui-source-option-entry", True, True, True, True))
    option_entry = view.get_class("ui-source-option-entry")
    key, value = option_entry.attributes["key"], option_entry.attributes["value"]
    test.assertEqual((key.alias, bool(key.key), bool(key.required)), ("key", True, True))
    test.assertEqual((value.range, bool(value.inlined), bool(value.required)),
                     ("ui-source-option-row", True, True))
    test.assertFalse(value.any_of)
    row_names = {slot.name for slot in view.class_induced_slots("ui-source-option-row")}
    test.assertEqual(row_names, {"default", "cfg", "since", "note", "versions"})
    test.assertFalse(row_names & {"id", "key"})


def assert_control_reference_contract(test, view):
    ability = view.get_class("ability-source-row").attributes["controls"]
    test.assertEqual(ability.alias, "_controls")
    test.assertEqual(len(ability.exactly_one_of), 1)
    test.assertEqual(ability.exactly_one_of[0].range, "control-action")
    test.assertTrue(ability.exactly_one_of[0].multivalued)
    slots = view.get_class("weapon-source-controls").attributes
    for name in ("m1", "m2", "block"):
        slot = slots[name]
        test.assertEqual(slot.range, "control-action")
        test.assertEqual(slot.annotations["source-reference-prefix"].value, CONTROL_REFERENCE_PREFIX)
    test.assertEqual(ability.annotations["source-reference-prefix"].value, CONTROL_REFERENCE_PREFIX)


def assert_whole_source(test, name, properties):
    row = catalog(name)
    assert_declared_root(name + "-source", properties, properties)
    bound = bind_source(name, row)
    test.assertEqual(unbind_source(name, bound), row)
    validate_source(name, row)
    for bad in (dict(bound, unexpected=True),
                {key: value for key, value in bound.items() if key != sorted(properties)[0]}):
        with test.assertRaises(jsonschema.ValidationError):
            validate(name + "-source", bad)


class MetaInputContracts(unittest.TestCase):
    def test_whole_rulesets_source(self):
        assert_whole_source(self, "rulesets", SOURCE_ROOTS[0][1])

    def test_whole_controller_profiles_source(self):
        assert_whole_source(self, "controller-profiles", SOURCE_ROOTS[1][1])

    def test_whole_keybinds_source(self):
        assert_whole_source(self, "keybinds", SOURCE_ROOTS[2][1])

    def test_whole_audio_source(self):
        assert_whole_source(self, "audio", SOURCE_ROOTS[4][1])

    def test_whole_slash_commands_source(self):
        assert_whole_source(self, "slash-commands", SOURCE_ROOTS[5][1])

    def test_whole_versions_source(self):
        assert_whole_source(self, "versions", SOURCE_ROOTS[6][1])

    def test_canonical_actions_and_selected_profile_are_not_inferred(self):
        controls = (ROOT / "ontology/domain/controls.md").read_text()
        action_ids = re.findall(r'^\| <a id="([^"]+)"></a>`([^`]+)` \|', controls, re.M)
        identifiers = [anchor for anchor, label in action_ids]
        self.assertEqual(len(identifiers), 54)
        self.assertEqual(len(set(identifiers)), 54)
        self.assertEqual(identifiers, [label for anchor, label in action_ids])
        view = SchemaView(str(SCHEMA))
        self.assertEqual([slot.name for slot in view.class_induced_slots("control-action")],
                         ["control-action-id", "control-action-value", "control-action-lifecycle",
                          "control-action-context", "control-action-effect-reference", "bound-to-input"])
        self.assertNotIn("control-action-meaning", view.all_slots())
        action_schema = generated("control-action")
        required = {"id", "value", "lifecycle", "context", "effect-reference"}
        self.assertEqual(set(action_schema["properties"]), required | {"bound-to-input"})
        self.assertEqual(set(action_schema["required"]), required)
        self.assertEqual(set(view.get_enum("ControlActionId").permissible_values), set(identifiers))
        for identifier in identifiers:
            validate("control-action", {"id": identifier, "value": "value", "lifecycle": "lifecycle",
                                         "context": "context", "effect-reference": "domain reference"})
        for row in ({"id": "move"}, {"id": "move", "value": None, "lifecycle": "lifecycle",
                     "context": "world", "effect-reference": "player"},
                    {"id": "Bad_ID", "value": "x", "lifecycle": "x", "context": "x",
                     "effect-reference": "x"},
                    {"id": "unknown-action", "value": "x", "lifecycle": "x", "context": "x",
                     "effect-reference": "x"},
                    {"id": "move", "value": "x", "lifecycle": "x", "context": "x",
                     "effect-reference": "x", "unknown": "x"}):
            with self.subTest(row=row), self.assertRaises(jsonschema.ValidationError):
                validate("control-action", row)
        profiles = catalog("controller-profiles")["android"]
        self.assertEqual(profiles["actions"], [
            "move", "look", "zoom", "sprint", "jump", "swim-ascent", "basic-attack",
            "special-attack", "block", "dodge", "class-skill-1", "class-skill-2",
            "class-skill-3", "class-skill-4", "interact", "pick-up", "quick-item",
            "inventory", "skills-window", "ui-cancel", "equip-item", "use-inventory-item",
            "spend-skill-point", "buy-item", "sell-item", "world-map",
        ])
        self.assertTrue(set(profiles["actions"]) <= set(identifiers))
        self.assertNotIn("gamepad", catalog("controller-profiles"))

    def test_profile_bindings_keep_phases_context_and_distinct_references(self):
        view = SchemaView(str(SCHEMA))
        assert_profile_binding_contract(self, view)
        action_schema = generated("input-binding")["properties"]["action"]
        self.assertEqual(action_schema["type"], "array")
        self.assertEqual(action_schema["minItems"], 1)
        self.assertEqual(action_schema["items"]["$ref"], "#/$defs/ControlActionId")
        self.assertEqual(view.induced_slot("input-binding-alias-of", "input-binding").range,
                         "ControlActionId")
        self.assertEqual(view.induced_slot("actions", "android-profile-source-row").range,
                         "ControlActionId")
        bindings = [{"action": [action], "physical-input": "E", "phases": ["trigger"],
                     "contexts": ["world"], "mapping-status": "implemented"}
                    for action in ("climb", "interact", "pick-up")]
        self.assertEqual(len({row["action"][0] for row in bindings}), 3)
        self.assertEqual({row["physical-input"] for row in bindings}, {"E"})
        for row in bindings:
            validate("input-binding", row)
        special = {"action": ["special-attack"], "physical-input": "M2",
                   "phases": ["start", "hold", "release"], "contexts": ["world"],
                   "mapping-status": "implemented"}
        block = {"action": ["block"], "physical-input": "M2", "phases": ["hold"],
                 "contexts": ["eligible equipment/stance"], "mapping-status": "implemented"}
        validate("input-binding", special)
        validate("input-binding", block)
        self.assertNotEqual(special["action"][0], block["action"][0])
        validate("input-binding", {"action": ["class-skill-4"], "physical-input": "R",
                                   "alias-of": "class-skill-4", "alias": "ultimate"})
        # Shape-only witnesses; they do not select a real profile or physical mapping.
        multi_action = {"action": ["climb", "interact"], "physical-input": "shape-only",
                        "phases": ["trigger"], "contexts": ["shape-only"]}
        validate("input-binding", multi_action)
        multi_action_owner = {"id": "climb", "value": "value", "lifecycle": "lifecycle",
                              "context": "context", "effect-reference": "reference",
                              "bound-to-input": [multi_action]}
        validate("control-action", multi_action_owner)
        same_action_rows = [
            {"action": ["jump"], "physical-input": "shape-only-a"},
            {"action": ["jump"], "physical-input": "shape-only-b"},
        ]
        validate("controller-profile", {"id": "shape-only-profile", "bindings": same_action_rows})
        for row in ({"physical-input": "Space"}, {"action": ["jump"]},
                    {"action": ["jump"], "physical-input": None},
                    {"action": [], "physical-input": "Space"},
                    {"action": "jump", "physical-input": "Space"},
                    {"action": ["unknown-action"], "physical-input": "Space"},
                    {"action": [None], "physical-input": "Space"},
                    {"action": ["jump"], "physical-input": "Space", "phases": [None]},
                    {"action": ["jump"], "physical-input": "Space", "unknown": True}):
            with self.subTest(row=row), self.assertRaises(jsonschema.ValidationError):
                validate("input-binding", row)
        validate("controller-profile", {"id": "gamepad"})
        validate("controller-profile", {"id": "android", "bindings": []})
        for row in ({}, {"id": None}, {"id": "gamepad", "unknown": True},
                    {"id": "android", "bindings": ["unbound"]}):
            with self.subTest(profile=row), self.assertRaises(jsonschema.ValidationError):
                validate("controller-profile", row)

    def test_keybind_groups_keep_all_physical_aliases_and_metadata(self):
        bindings = catalog("keybinds")["hybrid"]
        self.assertEqual(len([key for key in bindings if not key.startswith("_")]), 27)
        self.assertEqual((bindings["climb"], bindings["interact"], bindings["pick-up"]), ("E", "E", "E"))
        self.assertEqual((bindings["special-attack"], bindings["ultimate"], bindings["move"]),
                         ("M2", "R", "WASD"))
        view = SchemaView(str(SCHEMA))
        for name in ("control-action", "controller-profile", "input-binding"):
            self.assertIn(name, view.all_classes())
        self.assertIn("keybinds-source-profile", view.all_classes())
        self.assertIn("entries", view.class_slots("keybinds-source-profile"))

    def test_full_ui_missing_list_and_option_scalar_contract(self):
        row = catalog("ui")
        validate_source("ui", row)
        self.assertEqual(row["options"]["fps-limit"]["default"], 111)
        self.assertIsInstance(row["options"]["missing"], list)
        bad = deepcopy(row)
        bad["options"]["missing"] = {"vsync": True}
        with self.assertRaises(jsonschema.ValidationError):
            validate_source("ui", bad)
        for bad in (dict(row, unexpected=True), {key: value for key, value in row.items() if key != "_profiles"}):
            with self.assertRaises(jsonschema.ValidationError):
                validate_source("ui", bad)
        bad = deepcopy(row)
        bad["hud"]["portrait"]["unexpected"] = True
        with self.assertRaises(jsonschema.ValidationError):
            validate_source("ui", bad)
        self.assertEqual(row["hud"]["help-widget"]["default"], "on for new characters (0.9.3-0)")

    def test_history_and_audio_keep_source_qualified_values(self):
        versions = catalog("versions")
        omega = next(row for row in versions["timeline"] if row["date"] == "2023-05-26..10-14")
        alpha = next(row for row in versions["timeline"] if row["v"] == "0.1.1 (?)")
        self.assertEqual(omega["date"], "2023-05-26..10-14")
        self.assertEqual(alpha["date"], "2013-07-23")
        self.assertEqual(versions["reception"]["steam-2019"]["scores"]["metacritic-user"], "2.5/10")
        self.assertEqual(versions["alpha-to-steam-delta"]["removed"][0], "XP/levels/skill points")
        version_timeline = SchemaView(str(SCHEMA)).get_class("version-timeline-entry")
        version_label = version_timeline.attributes["version-label"]
        self.assertEqual((version_label.alias, str(version_label.slot_uri), version_label.range,
                          version_label.required),
                         ("v", "pixlnd:version-timeline-entry/v", "string", True))
        assert_declared_root("version-timeline-entry", {"date", "v", "features"},
                             {"date", "v", "features"})
        audio = catalog("audio")
        self.assertEqual(audio["tracks"]["bgum"]["date"], "2016-08-21 (?)")
        self.assertEqual(audio["music-rules"]["backend"], "xAudio2 (Win7 unsupported)")
        self.assertEqual(audio["ambient"], {"Ω": ["butterflies", "moths around street lights",
                                                   "chimney smoke", "water lilies"],
                                            "S": ["wraith swiping", "nightly lanterns"]})
        ambient = SchemaView(str(SCHEMA)).get_class("audio-source-ambient")
        omega_slot = ambient.attributes["omega"]
        self.assertEqual((omega_slot.alias, str(omega_slot.slot_uri)),
                         ("Ω", "pixlnd:audio-source-ambient/omega"))
        assert_declared_root("audio-source-ambient", {"Ω", "S"}, set())

    def test_slash_command_keys_and_modded_server_context_are_literal(self):
        commands = catalog("slash-commands")
        self.assertIn("!goto <player> / !tp <loc>", commands)
        self.assertEqual(commands["!goto <player> / !tp <loc>"]["versions"], ["A-mod"])
        self.assertEqual(commands["/sit"]["versions"], ["S", "A?"])
        self.assertEqual(commands["cuwo-server-commands"], ["/player", "/pm", "/server", "/who",
                         "/whowhere", "/whereis", "/login", "/say", "/kick", "/setclock",
                         "/ban", "/unban", "/kill", "/stun", "/heal"])

    def test_optional_null_empty_and_source_type_boundaries(self):
        validate("ui-source-option-row", {})
        validate("ui-source-option-row", {"default": None, "cfg": "", "versions": []})
        validate("input-binding", {"action": ["jump"], "physical-input": "Space"})
        validate("input-binding", {"action": ["jump"], "physical-input": "Space",
                                    "phases": None, "contexts": []})
        validate("controller-profile", {"id": "gamepad", "bindings": []})
        validate("audio-source-track-row", {})
        ui = catalog("ui")
        self.assertEqual(ui["options"]["camera-speed"], {})
        validate_source("ui", ui)
        for name, path, value in [
            ("rulesets", ("ruleset-hybrid", "flags", "coin-denominations"), {}),
            ("controller-profiles", ("android", "actions"), ["not-an-action-shape", None]),
            ("keybinds", ("hybrid", "move"), ["WASD"]),
            ("ui", ("hud", "portrait", "shows"), [None]),
            ("audio", ("tracks", "bgum", "date"), 20160821),
            ("slash-commands", ("/sit", "versions"), [None]),
            ("versions", ("timeline", 0, "date"), 20110525),
            ("versions", ("timeline", 0, "v"), ["A"]),
        ]:
            bad = deepcopy(catalog(name))
            node = bad
            for part in path[:-1]:
                node = node[part]
            node[path[-1]] = value
            with self.subTest(source=name, path=path, value=value), self.assertRaises(jsonschema.ValidationError):
                validate_source(name, bad)

    def test_android_profile_parameter_facets_match_literal_policy(self):
        view = SchemaView(str(SCHEMA))
        assert_android_profile_contract(self, view, SCHEMA.parent / "meta.yaml")
        self.assertFalse(type(_TaggedInteger(48)) is int)
        assert_exact_numeric_value(self, _TaggedInteger(48), 48, int)
        assert_exact_numeric_value(self, _TaggedFloat(0.15), 0.15, float)
        for bad in (True, 49, 48.0, "48"):
            with self.subTest(invalid_integer=bad), self.assertRaises(AssertionError):
                assert_exact_numeric_value(self, bad, 48, int)
        for bad in (True, 0.14, 0.1500001, "0.15"):
            with self.subTest(invalid_fraction=bad), self.assertRaises(AssertionError):
                assert_exact_numeric_value(self, bad, 0.15, float)

    def test_android_profile_source_values_and_boundaries(self):
        source = catalog("controller-profiles")
        row = source["android"]
        self.assertIs(type(row["deadzone-ratio"]), float)
        self.assertIs(type(row["min-target-dp"]), int)
        self.assertIs(type(row["look-deg-per-safe-width"]), int)
        self.assertEqual((row["deadzone-ratio"], row["min-target-dp"],
                          row["look-deg-per-safe-width"]), (0.15, 48, 180))
        validate_source("controller-profiles", source)
        logical = {alias: row[alias] for alias, *_ in ANDROID_PARAMETER_SLOTS.values()}
        logical["id"] = "android"
        validate("android-controller-profile", logical)
        for key, value in (("deadzone-ratio", 0.14), ("deadzone-ratio", 0.16),
                           ("deadzone-ratio", True), ("deadzone-ratio", None),
                           ("min-target-dp", 47), ("min-target-dp", 49),
                           ("min-target-dp", False), ("min-target-dp", None),
                           ("look-deg-per-safe-width", 179), ("look-deg-per-safe-width", 181),
                           ("look-deg-per-safe-width", True), ("look-deg-per-safe-width", None)):
            bad = deepcopy(source)
            bad["android"][key] = value
            with self.subTest(field=key, value=value), self.assertRaises(jsonschema.ValidationError):
                validate_source("controller-profiles", bad)
        for alias, *_ in ANDROID_PARAMETER_SLOTS.values():
            bad = deepcopy(source)
            del bad["android"][alias]
            with self.subTest(missing=alias), self.assertRaises(jsonschema.ValidationError):
                validate_source("controller-profiles", bad)

    def test_ui_option_missing_list_and_regular_option_are_disjoint(self):
        row = catalog("ui")
        assert_ui_option_contract(self, SchemaView(str(SCHEMA)))
        validate_source("ui", row)
        self.assertEqual(row["options"]["fps-limit"]["default"], 111)
        self.assertIsInstance(row["options"]["missing"], list)
        self.assertEqual(row["options"]["camera-speed"], {})
        for key, value in (("missing", {}), ("missing", {"default": 111}), ("fps-limit", []),
                           ("missing", None), ("fps-limit", None)):
            bad = deepcopy(row)
            bad["options"][key] = value
            with self.subTest(option=key, value=value), self.assertRaises(jsonschema.ValidationError):
                validate_source("ui", bad)
        bad = deepcopy(row)
        del bad["options"]["missing"]
        with self.assertRaises(jsonschema.ValidationError):
            validate_source("ui", bad)
        empty_missing = deepcopy(row)
        empty_missing["options"]["missing"] = []
        validate_source("ui", empty_missing)
        optional_option = deepcopy(row)
        del optional_option["options"]["fps-limit"]
        validate_source("ui", optional_option)

    def test_ability_control_references_bind_losslessly(self):
        assert_control_reference_contract(self, SchemaView(str(SCHEMA)))
        abilities = catalog("abilities")
        weapons = catalog("weapon-types")
        validate_source("abilities", abilities)
        validate_source("weapon-types", weapons)
        bound_abilities = bind_source("abilities", abilities)
        basic = next(entry["value"] for entry in bound_abilities["entries"]
                     if entry["key"] == "basic-attack")
        swim = next(entry["value"] for entry in bound_abilities["entries"] if entry["key"] == "swim")
        self.assertEqual(basic["_controls"], ["basic-attack"])
        self.assertEqual(swim["_controls"], ["move", "swim-ascent"])
        self.assertEqual(bound_abilities["entries"][0]["key"], "basic-attack")
        bound_weapons = bind_source("weapon-types", weapons)
        self.assertEqual(bound_weapons["_controls"],
                         {"m1": "basic-attack", "m2": "special-attack", "block": "block"})
        self.assertEqual(unbind_source("abilities", bound_abilities), abilities)
        self.assertEqual(unbind_source("weapon-types", bound_weapons), weapons)
        bad_abilities = deepcopy(abilities)
        bad_abilities["basic-attack"]["_controls"] = ["../other.md#basic-attack"]
        with self.assertRaises(jsonschema.ValidationError):
            bind_source("abilities", bad_abilities)
        bad_weapons = deepcopy(weapons)
        bad_weapons["_controls"]["m1"] = "basic-attack"
        with self.assertRaises(jsonschema.ValidationError):
            bind_source("weapon-types", bad_weapons)
        malformed = deepcopy(weapons)
        malformed["_controls"]["m1"] = {"keep": [None]}
        malformed_bound = bind_source("weapon-types", malformed)
        self.assertEqual(unbind_source("weapon-types", malformed_bound), malformed)
        with self.assertRaises(jsonschema.ValidationError):
            validate_source("weapon-types", malformed)
        malformed_list = deepcopy(abilities)
        malformed_list["basic-attack"]["_controls"] = [None]
        self.assertEqual(bind_source("abilities", malformed_list)["entries"][0]["value"]["_controls"],
                         [None])
        with self.assertRaises(jsonschema.ValidationError):
            validate_source("abilities", malformed_list)

    def test_actual_yaml_mutations_keep_profile_option_and_reference_oracles(self):
        cases = [
            ("meta.yaml", ("slots", "android-profile-deadzone-ratio", "maximum_value"), 0.16,
             assert_android_profile_contract),
            ("meta.yaml", ("slots", "android-profile-deadzone-ratio", "alias"), "deadzone",
             assert_android_profile_contract),
            ("meta.yaml", ("slots", "android-profile-deadzone-ratio", "maximum_value"), "0.15",
             assert_android_profile_contract),
            ("meta.yaml", ("slots", "android-profile-min-target-dp", "minimum_value"), "48",
             assert_android_profile_contract),
            ("meta.yaml", ("classes", "android-controller-profile", "mixins"), [],
             assert_android_profile_contract),
            ("meta.yaml", ("classes", "control-action", "slots"),
             ["control-action-id", "control-action-value", "control-action-lifecycle",
              "control-action-context", "control-action-effect-reference"], assert_profile_binding_contract),
            ("meta.yaml", ("classes", "controller-profile", "slots"), ["id"],
             assert_profile_binding_contract),
            ("meta.yaml", ("classes", "controller-profile", "slot_usage", "has-input-binding",
                           "alias"), "wrong-bindings-alias", assert_profile_binding_contract),
            ("meta.yaml", ("classes", "controller-profile", "slot_usage", "has-input-binding",
                           "inlined"), False, assert_profile_binding_contract),
            ("meta.yaml", ("classes", "controller-profile", "slot_usage", "has-input-binding",
                           "required"), True, assert_profile_binding_contract),
            ("meta.yaml", ("classes", "control-action", "slot_usage", "bound-to-input",
                           "inlined"), False, assert_profile_binding_contract),
            ("meta.yaml", ("slots", "input-binding-action", "range"), "ControlActionId",
             assert_profile_binding_contract),
            ("meta.yaml", ("slots", "input-binding-action", "multivalued"), False,
             assert_profile_binding_contract),
            ("meta.yaml", ("slots", "input-binding-action", "minimum_cardinality"), 0,
             assert_profile_binding_contract),
            ("meta.yaml", ("slots", "input-binding-action", "inlined"), True,
             assert_profile_binding_contract),
            ("catalog-meta.yaml", ("classes", "android-profile-source-row", "mixins"), [],
             assert_android_profile_contract),
            ("catalog-meta.yaml", ("classes", "controller-profile-source-entry", "attributes",
                                   "key", "required"), False, assert_android_profile_contract),
            ("catalog-meta.yaml", ("classes", "controller-profile-source-entry", "attributes",
                                   "value", "inlined"), False, assert_android_profile_contract),
            ("catalog-meta.yaml", ("classes", "ui-source-option-entry", "attributes", "key",
                                   "required"), False, assert_ui_option_contract),
            ("catalog-meta.yaml", ("classes", "ui-source-option-entry", "attributes", "value",
                                   "inlined"), False, assert_ui_option_contract),
            ("catalog-meta.yaml", ("classes", "ui-source-options", "attributes", "entries",
                                   "inlined"), False, assert_ui_option_contract),
            ("catalog-identity-combat.yaml", ("classes", "ability-source-row", "attributes",
                                              "controls", "annotations", "source-reference-prefix"),
             "../other.md#", assert_control_reference_contract),
        ]
        assert_ui_option_contract(self, SchemaView(str(SCHEMA)))
        assert_control_reference_contract(self, SchemaView(str(SCHEMA)))
        assert_profile_binding_contract(self, SchemaView(str(SCHEMA)))
        with tempfile.TemporaryDirectory() as scratch:
            target = os.path.join(scratch, "schema")
            shutil.copytree(SCHEMA.parent, target)
            originals = {name: yaml.safe_load((SCHEMA.parent / name).read_text())
                         for name in {case[0] for case in cases}}
            for module, path, value, oracle in cases:
                for name, baseline in originals.items():
                    with open(os.path.join(target, name), "w") as module_file:
                        module_file.write(yaml.safe_dump(deepcopy(baseline), sort_keys=False))
                view = SchemaView(os.path.join(target, "pixlnd.yaml"))
                schema_meta = os.path.join(target, "meta.yaml")
                with self.subTest(module=module, baseline=True):
                    if oracle is assert_android_profile_contract:
                        oracle(self, view, schema_meta)
                    else:
                        oracle(self, view)
                data = deepcopy(originals[module])
                node = data
                for part in path[:-1]:
                    node = node[part]
                node[path[-1]] = value
                with open(os.path.join(target, module), "w") as module_file:
                    module_file.write(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(module=module, path=path, value=value):
                    with self.assertRaises(AssertionError):
                        mutated_view = SchemaView(os.path.join(target, "pixlnd.yaml"))
                        if oracle is assert_android_profile_contract:
                            oracle(self, mutated_view, schema_meta)
                        else:
                            oracle(self, mutated_view)


class _TaggedInteger(int):
    pass


class _TaggedFloat(float):
    pass


if __name__ == "__main__":
    unittest.main()
