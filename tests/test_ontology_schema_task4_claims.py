"""Personal claim declarations; native typing is not claim issuance or persistence."""
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml_runtime.utils.schemaview import SchemaView
from test_ontology_schema import SCHEMA, copy_schema, generated

OWNER = "personal-permanent-source-claim"
FIELDS = ("character", "world", "source-kind", "source-key")


def assert_claim_declaration(test, view):
    owner = view.get_class(OWNER)
    test.assertEqual(owner.class_uri, "pixlnd:personal-permanent-source-claim")
    test.assertIsNone(owner.is_a)
    test.assertFalse(owner.mixins)
    test.assertEqual(set(view.class_slots(OWNER)), set(FIELDS))
    test.assertEqual(set(owner.attributes), set(FIELDS))
    test.assertEqual(set(owner.unique_keys), {"character-world-source"})
    test.assertEqual(owner.unique_keys["character-world-source"].unique_key_slots,
                     ["character", "world", "source-kind", "source-key"])
    expected = {"character": "player-character", "world": "world",
                "source-kind": "PersonalPermanentSourceKind", "source-key": "string"}
    for name, target in expected.items():
        raw = owner.attributes[name]
        slot = view.induced_slot(name, OWNER)
        for declaration in (raw, slot):
            test.assertEqual((declaration.alias, declaration.domain, declaration.range),
                             (name, OWNER, target))
            test.assertEqual(declaration.slot_uri, f"pixlnd:{OWNER}/{name}")
            test.assertIs(declaration.required, True)
            test.assertFalse(declaration.multivalued)
            test.assertFalse(declaration.inlined)
            test.assertFalse(declaration.identifier)
            test.assertFalse(declaration.key)
            test.assertIsNone(declaration.ifabsent)
    enum = view.get_enum("PersonalPermanentSourceKind")
    test.assertEqual(set(enum.permissible_values), {"artifact", "one_time_book"})
    test.assertEqual(enum.permissible_values["one_time_book"].aliases, ["one-time-book"])
    test.assertFalse(enum.permissible_values["artifact"].aliases)
    test.assertIn("../domain/3_Classes.md#save-data", owner.see_also)
    for phrase in ("not a current save wire member", "tuple itself states ownership",
                   "at the source", "never a remote award", "daily enemy resets never renew",
                   "matching-seed worlds", "Source existence, compound uniqueness and lifecycle"):
        test.assertIn(phrase, owner.description)
    test.assertIn("never the generation seed", owner.attributes["world"].description)
    for phrase in ("Opaque", "qualified by world and source-kind", "not a global identifier",
                   "allocation scheme", "not the portable reward item"):
        test.assertIn(phrase, owner.attributes["source-key"].description)


def claim_row():
    return {"character": "character-a", "world": "world-a",
            "source-kind": "artifact", "source-key": "opaque-source"}


class PersonalSourceClaimTests(unittest.TestCase):
    def test_literal_owner_range_kind_and_compound_key(self):
        assert_claim_declaration(self, SchemaView(str(SCHEMA)))

    def test_native_claim_shape_boundaries(self):
        schema = generated(OWNER)
        validator = jsonschema.Draft201909Validator(schema)
        definition = schema["$defs"][OWNER]
        self.assertEqual(set(definition["properties"]), set(FIELDS))
        self.assertEqual(set(definition["required"]), set(FIELDS))
        self.assertIs(definition["additionalProperties"], False)
        row = claim_row()
        for kind in ("artifact", "one_time_book"):
            validator.validate(dict(row, **{"source-kind": kind}))
        for field in FIELDS:
            missing = deepcopy(row)
            del missing[field]
            with self.subTest(missing=field), self.assertRaises(jsonschema.ValidationError):
                validator.validate(missing)
            for value in (None, True, 7, [], {"id": "embedded"}):
                with self.subTest(field=field, value=value), self.assertRaises(
                        jsonschema.ValidationError):
                    validator.validate(dict(row, **{field: value}))
        # The canonical hyphenated alias is metadata, not an admitted native token.
        for kind in ("book", "recipe", "one-time", "one-time-book", "ground-loot"):
            with self.subTest(kind=kind), self.assertRaises(jsonschema.ValidationError):
                validator.validate(dict(row, **{"source-kind": kind}))
        for value in ([], [row], "claim", None):
            with self.subTest(container=value), self.assertRaises(jsonschema.ValidationError):
                validator.validate(value)
        for field in ("claimed", "timestamp", "id", "reward", "seed"):
            with self.subTest(extra=field), self.assertRaises(jsonschema.ValidationError):
                validator.validate(dict(row, **{field: "unapproved"}))

    def test_native_compound_set_membership_and_lifecycle_limits(self):
        schema = generated(OWNER)
        validator = jsonschema.Draft201909Validator(schema)
        row = claim_row()
        # Shape-only references: neither owners nor world/kind/key source existence is resolved.
        validator.validate(dict(row, character="unresolved-character", world="unresolved-world",
                                **{"source-key": "unresolved-source"}))
        for patch in ({"character": "character-b"}, {"world": "world-b"},
                      {"source-kind": "one_time_book"}):
            validator.validate(dict(row, **patch))  # Same opaque key, distinct qualified tuple.
        # A collection of native claim rows still has no emitted compound-key enforcement.
        collection = {"type": "array", "items": {"$ref": f"#/$defs/{OWNER}"},
                      "$defs": schema["$defs"]}
        jsonschema.Draft201909Validator(collection).validate([row, deepcopy(row)])
        self.assertNotIn("uniqueItems", collection)
        # Stateless validation cannot prevent reissuance after return/restart/daily reset.
        for _ in ("return", "restart", "daily-reset"):
            validator.validate(row)
        view = SchemaView(str(SCHEMA))
        self.assertIs(view.induced_slot("knows-recipe", "player-character").list_elements_unique, True)
        player_schema = generated("player-character")
        prop = player_schema["$defs"]["player-character"]["properties"]["known-recipes"]
        self.assertNotIn("uniqueItems", prop)
        # Existing learned-set declaration is separate from source claims and is also not enforced.
        jsonschema.Draft201909Validator(dict(prop, **{"$defs": player_schema["$defs"]})).validate(
            ["unresolved-recipe", "unresolved-recipe"])

    def test_actual_yaml_claim_facet_mutations(self):
        assert_claim_declaration(self, SchemaView(str(SCHEMA)))
        cases = [
            (("attributes", "character", "domain"), "character-world-state"),
            (("attributes", "character", "range"), "entity"),
            (("attributes", "world", "range"), "string"),
            (("attributes", "source-key", "required"), False),
            (("attributes", "source-key", "identifier"), True),
            (("attributes", "source-kind", "range"), "string"),
            (("unique_keys", "character-world-source", "unique_key_slots"),
             ["character", "source-kind", "source-key"]),
        ]
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "schema"
            copy_schema(target)
            path = target / "associations.yaml"
            original = yaml.safe_load(path.read_text())
            for keys, value in cases:
                data = deepcopy(original)
                node = data["classes"][OWNER]
                for key in keys[:-1]:
                    node = node[key]
                node[keys[-1]] = value
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(keys=keys), self.assertRaises(AssertionError):
                    assert_claim_declaration(self, SchemaView(str(target / "pixlnd.yaml")))
            for patch in ({"ground-loot": {}}, {"one_time_book": {"aliases": ["book"]}}):
                data = deepcopy(original)
                data["enums"]["PersonalPermanentSourceKind"]["permissible_values"].update(patch)
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.subTest(enum_patch=patch), self.assertRaises(AssertionError):
                    assert_claim_declaration(self, SchemaView(str(target / "pixlnd.yaml")))
