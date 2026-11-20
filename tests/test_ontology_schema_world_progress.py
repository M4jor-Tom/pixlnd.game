"""Spirit scope, progress exclusion and ruins room level world schema tests."""
from copy import deepcopy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView

from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import catalog, validate, validator


def verify_spirit_declaration(self, owner, boss, needed, absent, raw, view, anchor, special_anchor):
    declaration = raw[owner]
    self.assertEqual(declaration["is_a"], "encounter-assignment")
    self.assertFalse(declaration.get("attributes") or declaration.get("slots") or declaration.get("mixins"))
    self.assertEqual(declaration["slot_usage"], {
        "boss": {"equals_expression": str(boss)}, **{f: {"required": True} for f in needed}})
    forbidden = [{"slot_conditions": {f: {"value_presence": "PRESENT"}}} for f in absent]
    self.assertEqual(declaration.get("none_of", []), forbidden)
    for cls in (view.get_class(owner), view.induced_class(owner)):
        self.assertEqual(str(cls.class_uri), "pixlnd:" + owner)
        self.assertEqual(cls.see_also, [anchor, special_anchor])
        self.assertEqual([str(next(iter(c.slot_conditions.values())).value_presence) for c in cls.none_of],
                         ["PRESENT"] * len(absent))
    self.assertEqual(view.induced_class(owner).attributes["boss"].equals_expression, str(boss))
    return declaration


def verify_spirit_slots(self, owner, boss, needed, declaration, raw, view, fields, base_required):
    from ontology_source_contracts import assert_declared_root

    slots = view.class_induced_slots(owner)
    self.assertEqual(len(slots), 5)
    self.assertEqual({s.name for s in slots}, fields)
    self.assertEqual({s.alias for s in slots}, fields)
    schema = validator(owner).schema
    assert_declared_root(owner, fields, base_required | set(needed), view=view, schema=schema)
    definition = schema["$defs"][owner]
    self.assertEqual(len(definition["required"]), len(base_required | set(needed)))
    self.assertEqual(definition["description"], declaration["description"])
    for slot in slots:
        self.assertEqual(str(slot.slot_uri), "pixlnd:encounter-assignment/" + slot.name)
        self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined)
        self.assertIsNone(slot.ifabsent)
        self.assertEqual(bool(slot.required), slot.name in base_required | set(needed))
        self.assertEqual(definition["properties"][slot.alias]["description"], slot.description)
    self.assertEqual(view.induced_slot("boss", owner).equals_expression, str(boss))
    self.assertEqual(definition["properties"]["boss"], {
        "type": "boolean", "description": raw["encounter-assignment"]["attributes"]["boss"]["description"]})
    return definition


def verify_spirit_fields(self, owner, view, definition, types, absent):
    for field, range_, values in (("special", "string", ["stomp", "charge"]), ("spirit", "material", types)):
        alternatives = view.induced_slot(field, owner).exactly_one_of
        self.assertEqual([(a.range, a.equals_string_in) for a in alternatives], [(range_, values)])
        self.assertEqual(definition["properties"][field]["oneOf"], [{"type": "string", "enum": values}])
    if absent:
        self.assertEqual(definition["not"], {"anyOf": [
            {"properties": {f: {}}, "required": [f]} for f in absent]})
    else:
        self.assertNotIn("not", definition)


def verify_spirit_candidate(
    self, owner, boss, absent, types, missing, supplied_boss, special, spirit
):
    candidate = {"role": "mage", "tier": 3, "boss": supplied_boss}
    if special is not missing:
        candidate["special"] = special
    if spirit is not missing:
        candidate["spirit"] = spirit
    native_expected = ((special is missing if "special" in absent else
                        isinstance(special, str) and special in ("stomp", "charge")) and
                       (spirit is missing if "spirit" in absent else
                        isinstance(spirit, str) and spirit in types))
    with self.subTest(owner=owner, candidate=candidate):
        self.assertEqual(validator(owner).is_valid(candidate), native_expected)
    # Domain requires the authored boss literal too; native does NOT enforce it.
    return int(native_expected and supplied_boss != boss)


def verify_spirit_matrix(self, owner, boss, absent, types, missing):
    admitted_against_boolean_rule = 0
    matrix_rows = 0
    for supplied_boss in (False, True):
        for special in (missing, "stomp", "charge", None, "fireball", True, 1, [], {}):
            for spirit in (missing, *types, None, "sandstone", True, 1, [], {}, [types[0]], {"id": types[0]}):
                admitted_against_boolean_rule += verify_spirit_candidate(
                    self, owner, boss, absent, types, missing, supplied_boss, special, spirit)
                matrix_rows += 1
    return admitted_against_boolean_rule, matrix_rows


def verify_spirit_rejections(self, owner, row, base_required):
    for field in base_required:
        with self.assertRaises(jsonschema.ValidationError):
            validate(owner, {k: v for k, v in row.items() if k != field})
    for field, bads in (("boss", (None, 0, 1, "true", "false", [], {})),
                        ("role", (None, "any-class", True, 1, [], {})),
                        ("tier", (None, -1, 5, True, "3", [], {}))):
        for bad in bads:
            with self.subTest(field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                validate(owner, dict(row, **{field: bad}))
    for bad in (None, [], [row], 0, False, "assignment", {owner: row}):
        with self.assertRaises(jsonschema.ValidationError):
            validate(owner, bad)
    for field in ("id", "mission", "site-id", "initial-level", "current-level", "payload", "receipt", "effects", "per-player"):
        with self.assertRaises(jsonschema.ValidationError):
            validate(owner, dict(row, **{field: True}))


def verify_spirit_profile_sources(self, field, value, probability, anchor, item_anchor, source_anchor, view):
    sources = [anchor]
    if probability:
        token = field.removesuffix("-probability")
        sources += ["../instances/materials.json#" + token, source_anchor]
        self.assertEqual(catalog("materials")[token]["kind"], "spirit")
        self.assertEqual(catalog("generators")["design"]["initial-encounters"]["spirits"][token], value)
    elif field == "power-spread":
        sources.append(item_anchor)
    elif field == "minimum-initial-boss-level":
        sources.append("save-world.yaml#saved-spirit-level-level")
        initial = view.induced_slot("saved-spirit-level-level", "saved-spirit-level")
        self.assertEqual((initial.range, initial.minimum_value), ("integer", 1))
        self.assertIn("Initial boss level", view.get_class("saved-spirit-level").description)
    return sources


def verify_spirit_profile_bounds(self, probability, authored, slot, emitted, value):
    if probability:
        self.assertEqual((authored["minimum_value"], authored["maximum_value"]), (value, value))
        self.assertEqual((slot.minimum_value, slot.maximum_value), (value, value))
        self.assertEqual((emitted["minimum"], emitted["maximum"]), (value, value))
    else:
        self.assertEqual((authored["equals_number"], slot.equals_number, emitted["const"]), (value, value, value))


def verify_profile_declaration(self, owner, row, view, raw, class_sources):
    from ontology_source_contracts import assert_declared_root

    declaration = raw[owner]
    self.assertEqual(set(declaration["attributes"]), set(row))
    self.assertFalse(declaration.get("slots") or declaration.get("is_a") or
                     declaration.get("mixins") or declaration.get("slot_usage"))
    self.assertEqual((declaration["class_uri"], str(view.get_class(owner).class_uri)), ("pixlnd:" + owner,) * 2)
    self.assertEqual((declaration["see_also"], view.get_class(owner).see_also), (class_sources[owner],) * 2)
    self.assertEqual(view.get_class(owner).description, declaration["description"])
    slots = view.class_induced_slots(owner)
    self.assertEqual((len(slots), {s.name for s in slots}, {s.alias for s in slots}),
                     (len(row), set(row), set(row)))
    schema = validator(owner).schema
    assert_declared_root(owner, set(row), set(row), view=view, schema=schema)
    definition = schema["$defs"][owner]
    self.assertEqual(set(definition["properties"]), set(row))
    self.assertEqual((len(definition["required"]), set(definition["required"])), (len(row), set(row)))
    self.assertIs(definition["additionalProperties"], False)
    self.assertEqual(definition["description"], declaration["description"])
    validate(owner, row)
    return declaration, definition


def verify_profile_field(
    self, owner, row, field, value, declaration, view, definition, field_sources
):
    authored = declaration["attributes"][field]
    slot = view.induced_slot(field, owner)
    fractional = field == "delivery-height-above-floor-blocks"
    range_ = "double" if fractional else "integer"
    uri = "pixlnd:" + owner + "/" + field
    self.assertEqual((authored["alias"], authored["range"], authored["required"]), (field, range_, True))
    self.assertEqual((slot.alias, slot.range, slot.required), (field, range_, True))
    self.assertEqual((authored["slot_uri"], str(slot.slot_uri)), (uri, uri))
    self.assertEqual((authored["see_also"], slot.see_also), (field_sources[field],) * 2)
    self.assertEqual(slot.description, authored["description"])
    self.assertFalse({"identifier", "key", "multivalued", "inlined", "ifabsent"} & set(authored))
    self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined)
    self.assertIsNone(slot.ifabsent)
    emitted = definition["properties"][field]
    self.assertEqual(emitted["type"], "number" if fractional else "integer")
    self.assertEqual(emitted["description"], authored["description"])
    self.assertNotIn("default", emitted)
    if fractional:
        self.assertEqual((authored["minimum_value"], authored["maximum_value"]), (value, value))
        self.assertEqual((slot.minimum_value, slot.maximum_value), (value, value))
        self.assertEqual((emitted["minimum"], emitted["maximum"]), (value, value))
        self.assertIsNone(slot.equals_number)
    else:
        self.assertEqual((authored["equals_number"], slot.equals_number, emitted["const"]), (value,) * 3)
        self.assertIsNone(slot.minimum_value)
        self.assertIsNone(slot.maximum_value)
    with self.assertRaises(jsonschema.ValidationError):
        validate(owner, {k: v for k, v in row.items() if k != field})
    for bad in (value - 1, value + 1, value + 0.25, str(value), True, False, None, [], {}, [value]):
        with self.subTest(bad=bad), self.assertRaises(jsonschema.ValidationError):
            validate(owner, dict(row, **{field: bad}))


def verify_ruins_room_contract(self, raw, view, schema, rule, names, anchor, fields):
    from ontology_source_contracts import assert_declared_root

    self.assertEqual(raw["classes"]["saved-site"].get("rules"), [rule])
    self.assertEqual(raw["classes"]["saved-site"]["slots"], names)
    for cls in (view.get_class("saved-site"), view.induced_class("saved-site")):
        self.assertEqual(str(cls.class_uri), "pixlnd:saved-site")
        self.assertEqual(cls.see_also, ["../domain/3_Classes.md#save-data"])
        self.assertEqual(len(cls.rules), 1)
        condition = cls.rules[0]
        self.assertEqual(condition.see_also, [anchor])
        self.assertEqual(set(condition.preconditions.slot_conditions), {"saved-site-family"})
        self.assertEqual(condition.preconditions.slot_conditions["saved-site-family"].equals_string, "ruins")
        self.assertEqual(set(condition.postconditions.slot_conditions), {"saved-site-room-levels"})
        levels = condition.postconditions.slot_conditions["saved-site-room-levels"]
        self.assertEqual((levels.minimum_cardinality, levels.maximum_cardinality), (3, 3))
        self.assertIsNone(condition.elseconditions)
        self.assertFalse(condition.bidirectional or condition.deactivated)
    self.assertEqual(raw["slots"]["saved-site-room-levels"], {
        "slot_uri": "pixlnd:saved-site/room_levels", "alias": "room_levels", "domain": "saved-site",
        "range": "integer", "required": True, "see_also": ["../domain/3_Classes.md#save-data"],
        "multivalued": True, "minimum_value": 1, "maximum_cardinality": 3})
    for field, name, range_ in (("family", "saved-site-family", "saved-site-family"),
                                 ("room_levels", "saved-site-room-levels", "integer")):
        slot = view.induced_slot(name, "saved-site")
        self.assertEqual((slot.alias, slot.domain, slot.range), (field, "saved-site", range_))
        self.assertEqual(str(slot.slot_uri), "pixlnd:saved-site/" + field)
        self.assertTrue(slot.required)
        self.assertFalse(slot.identifier or slot.key or slot.inlined)
    levels = view.induced_slot("saved-site-room-levels", "saved-site")
    self.assertTrue(levels.multivalued)
    self.assertEqual((levels.minimum_value, levels.maximum_cardinality), (1, 3))
    self.assertIsNone(levels.minimum_cardinality)
    self.assertIsNone(levels.maximum_value)
    self.assertIsNone(levels.ifabsent)
    self.assertEqual(set(view.get_enum("saved-site-family").permissible_values), {"ruins", "camp", "supplier"})
    self.assertEqual({s.alias for s in view.class_induced_slots("saved-site")}, fields)
    assert_declared_root("saved-site", fields, fields, view=view, schema=schema)
    definition = schema["$defs"]["saved-site"]
    self.assertEqual(definition["properties"]["room_levels"], {
        "type": "array", "items": {"type": "integer", "minimum": 1}, "maxItems": 3})
    # Native 1.12.1 uses canonical rule names, not the closed root's wire aliases.
    self.assertEqual(definition["if"], {
        "properties": {"saved-site-family": {"const": "ruins"}}, "required": ["saved-site-family"]})
    # Independently inspect the ACTUAL canonical then key: cardinalities are also omitted.
    self.assertEqual(definition["then"], {
        "properties": {"saved-site-room-levels": {"type": "array", "items": {}}},
        "required": ["saved-site-room-levels"]})
    self.assertNotIn("saved-site-family", definition["properties"])
    self.assertNotIn("saved-site-room-levels", definition["properties"])


class LogicalWorldTests(unittest.TestCase):
    def test_spirit_scope_assignments(self):
        from ontology_source_contracts import assert_declared_root

        anchor = "../domain/encounter-contracts.md#guaranteed-boss-gear-and-spirits"
        special_anchor = "../domain/encounter-contracts.md#boss-specials-and-breakable-rubble"
        fields = {"role", "tier", "boss", "special", "spirit"}
        base_required = {"role", "tier", "boss"}
        types = ["spirit-fire", "spirit-unholy", "spirit-ice", "spirit-wind"]
        scopes = [("initial-nonboss-assignment", False, [], ["special", "spirit"]),
                  ("initial-ruins-boss-assignment", True, ["special", "spirit"], []),
                  ("initial-mission-boss-assignment", True, ["special"], ["spirit"])]
        view = SchemaView(str(SCHEMA))
        for owner, _, _, _ in scopes:
            self.assertTrue(owner in view.all_classes(), "Missing declared source class: " + owner)
        raw = yaml.safe_load((SCHEMA.parent / "world.yaml").read_text())["classes"]
        generic_schema = validator("encounter-assignment").schema
        assert_declared_root("encounter-assignment", fields, base_required, view=view, schema=generic_schema)
        self.assertEqual(raw["encounter-assignment"]["attributes"]["spirit"]["exactly_one_of"],
                         [{"range": "material", "equals_string_in": types}])
        # The approved nominal TYPE correction must not change native wire admission.
        with tempfile.TemporaryDirectory() as scratch:
            copied = Path(scratch) / "schema"
            shutil.copytree(SCHEMA.parent, copied)
            path = copied / "world.yaml"
            mutated = yaml.safe_load(path.read_text())
            mutated["classes"]["encounter-assignment"]["attributes"]["spirit"]["exactly_one_of"][0]["range"] = "ingredient"
            path.write_text(yaml.safe_dump(mutated, sort_keys=False))
            previous_nominal = json.loads(JsonSchemaGenerator(
                str(copied / SCHEMA.name), top_class="encounter-assignment",
                preserve_names=True, not_closed=False).serialize())
            self.assertEqual(previous_nominal, generic_schema)
        missing = object()
        admitted_against_boolean_rule = 0
        matrix_rows = 0
        for owner, boss, needed, absent in scopes:
            declaration = verify_spirit_declaration(
                self, owner, boss, needed, absent, raw, view, anchor, special_anchor)
            definition = verify_spirit_slots(
                self, owner, boss, needed, declaration, raw, view, fields, base_required)
            verify_spirit_fields(self, owner, view, definition, types, absent)
            row = {"role": "mage", "tier": 3, "boss": boss,
                   **{f: ("stomp" if f == "special" else types[0]) for f in needed}}
            validate(owner, row)
            admitted_delta, matrix_delta = verify_spirit_matrix(self, owner, boss, absent, types, missing)
            matrix_rows += matrix_delta
            admitted_against_boolean_rule += admitted_delta
            verify_spirit_rejections(self, owner, row, base_required)
        self.assertEqual((matrix_rows, admitted_against_boolean_rule), (702, 11))

    def test_spirit_scope_fixed_profile(self):
        from ontology_source_contracts import assert_declared_root

        owner = "initial-spirit-profile"
        anchor = "../domain/encounter-contracts.md#guaranteed-boss-gear-and-spirits"
        item_anchor = "../domain/3_Classes.md#item"
        cube_anchor = "../domain/3_Classes.md#spirit-cube"
        source_anchor = "../instances/generators.json#design.initial-encounters.spirits"
        row = {"ruins-boss-count-per-death": 1, "mission-boss-count-per-death": 0,
               "spirit-fire-probability": 0.25, "spirit-unholy-probability": 0.25,
               "spirit-ice-probability": 0.25, "spirit-wind-probability": 0.25,
               "power-spread": 0, "minimum-initial-boss-level": 1}
        view = SchemaView(str(SCHEMA))
        self.assertTrue(owner in view.all_classes(), "Missing declared source class: " + owner)
        schema = validator(owner).schema
        assert_declared_root(owner, set(row), set(row), view=view, schema=schema)
        declaration = yaml.safe_load((SCHEMA.parent / "world.yaml").read_text())["classes"][owner]
        self.assertEqual(set(declaration["attributes"]), set(row))
        self.assertFalse(declaration.get("is_a") or declaration.get("slots") or declaration.get("mixins") or declaration.get("slot_usage"))
        self.assertEqual((declaration["class_uri"], str(view.get_class(owner).class_uri)), ("pixlnd:" + owner,) * 2)
        self.assertEqual(declaration["see_also"], [anchor, item_anchor, cube_anchor, source_anchor])
        self.assertEqual(view.get_class(owner).see_also, declaration["see_also"])
        slots = view.class_induced_slots(owner)
        self.assertEqual((len(slots), {s.name for s in slots}, {s.alias for s in slots}), (8, set(row), set(row)))
        definition = schema["$defs"][owner]
        self.assertEqual(len(definition["required"]), 8)
        self.assertEqual(definition["description"], declaration["description"])
        validate(owner, row)
        for field, value in row.items():
            authored = declaration["attributes"][field]
            slot = view.induced_slot(field, owner)
            probability = field.endswith("-probability")
            range_ = "double" if probability else "integer"
            sources = verify_spirit_profile_sources(
                self, field, value, probability, anchor, item_anchor, source_anchor, view)
            self.assertEqual((authored["alias"], authored["range"], authored["required"]), (field, range_, True))
            self.assertEqual((slot.alias, slot.range, slot.required), (field, range_, True))
            self.assertEqual((authored["slot_uri"], str(slot.slot_uri)), ("pixlnd:" + owner + "/" + field,) * 2)
            self.assertEqual((authored["see_also"], slot.see_also), (sources, sources))
            self.assertEqual(slot.description, authored["description"])
            self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined)
            self.assertIsNone(slot.ifabsent)
            emitted = definition["properties"][field]
            self.assertEqual(emitted["type"], "number" if probability else "integer")
            self.assertEqual(emitted["description"], authored["description"])
            self.assertNotIn("default", emitted)
            verify_spirit_profile_bounds(self, probability, authored, slot, emitted, value)
            with self.assertRaises(jsonschema.ValidationError):
                validate(owner, {k: v for k, v in row.items() if k != field})
            for bad in (value - 1, value + 1, value + 0.5, str(value), True, False, None, [], {}, [value]):
                with self.subTest(field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    validate(owner, dict(row, **{field: bad}))
        for fragment in ("two ruins bosses", "mission bosses", "first logical generation", "independently",
                         "permanent", "initial boss level", "power(L)", "across daily renewal",
                         "current defeated boss level", "shared ground drops", "collecting and carrying", "no numerical effects"):
            self.assertIn(fragment, declaration["description"])
        for bad in (None, [], [row], 0, False, "profile", {owner: row}):
            with self.assertRaises(jsonschema.ValidationError):
                validate(owner, bad)
        for field in ("id", "boss", "mission", "source-level", "initial-boss-level", "current-boss-level", "item-power",
                      "payload", "receipt", "cycle", "delivered", "effects", "attach", "damage", "per-player", "reroll"):
            with self.assertRaises(jsonschema.ValidationError):
                validate(owner, dict(row, **{field: True}))

    def test_progress_exclusion_profiles(self):
        shared_anchor = "../domain/encounter-contracts.md#shared-mission-packages-and-supplier-shops"
        source_anchor = "../domain/encounter-contracts.md#initial-permanent-source-scope"
        shop_anchor = "../domain/3_Classes.md#shop"
        supplier_anchor = "../domain/3_Classes.md#gnome-supplier-s"
        artifact_anchor = "../domain/3_Classes.md#artifact"
        book_anchor = "../domain/3_Classes.md#book-of-crafting"
        profiles = {
            "supplier-gear-stock-ceiling-profile": {
                "initial-rarity-index": 0, "rarity-increment-per-completed-rescue": 1,
                "maximum-rarity-index": 4},
            "shared-mission-completion-profile": {
                "delivery-height-above-floor-blocks": 0.5, "extra-completion-xp": 0},
            "initial-permanent-source-profile": {
                "artifact-source-count": 0, "one-time-book-source-count": 0},
        }
        class_sources = {
            "supplier-gear-stock-ceiling-profile": [shared_anchor, shop_anchor, supplier_anchor],
            "shared-mission-completion-profile": [shared_anchor],
            "initial-permanent-source-profile": [source_anchor, artifact_anchor, book_anchor],
        }
        field_sources = {
            "initial-rarity-index": [shared_anchor, shop_anchor, supplier_anchor, "../instances/rarities.json#common"],
            "rarity-increment-per-completed-rescue": [shared_anchor, shop_anchor, supplier_anchor],
            "maximum-rarity-index": [shared_anchor, shop_anchor, supplier_anchor, "../instances/rarities.json#legendary"],
            "delivery-height-above-floor-blocks": [shared_anchor],
            "extra-completion-xp": [shared_anchor],
            "artifact-source-count": [source_anchor, artifact_anchor],
            "one-time-book-source-count": [source_anchor, book_anchor],
        }
        view = SchemaView(str(SCHEMA))
        for owner in profiles:
            self.assertTrue(owner in view.all_classes(), "Missing declared source class: " + owner)
        raw = yaml.safe_load((SCHEMA.parent / "world.yaml").read_text())["classes"]
        for owner, row in profiles.items():
            declaration, definition = verify_profile_declaration(self, owner, row, view, raw, class_sources)
            for field, value in row.items():
                with self.subTest(owner=owner, field=field):
                    verify_profile_field(
                        self, owner, row, field, value, declaration, view, definition, field_sources)
            for bad in (None, [], [row], 0, False, "profile", {owner: row}):
                with self.subTest(owner=owner, root=bad), self.assertRaises(jsonschema.ValidationError):
                    validate(owner, bad)
            for field in ("id", "land-id", "completed-rescues", "current-ceiling", "stock", "restock-at",
                          "rescue-reroll", "guaranteed-quality", "shared", "per-player", "payload", "receipt",
                          "cycle", "delivered", "selected-class", "kill-xp", "additional-currency",
                          "global-exclusion", "full-land", "artifacts-disabled", "books-disabled", "claim"):
                errors = list(validator(owner).iter_errors(dict(row, **{field: True})))
                self.assertEqual([error.validator for error in errors], ["additionalProperties"])
        for owner, fragments in (
            ("supplier-gear-stock-ceiling-profile", ("saved world", "land", "four", "next normal",
             "not an extra rescue-triggered reroll", "not a guarantee", "quantities and prices", "strength when travelling")),
            ("shared-mission-completion-profile", ("one shared package", "source level", "class snapshot",
             "fallback", "deferred", "camp centre", "captive feet", "once per cycle", "undelivered", "ordinary ground pickup")),
            ("initial-permanent-source-profile", ("six initial sites", "alcove, bosses, props and packages",
             "not full-land", "not a permanent or global", "Personal claims", "artifact allocation", "Historical Steam",
             "Later full-land sources", "spirit customization")),
        ):
            for fragment in fragments:
                self.assertIn(fragment, raw[owner]["description"])
        self.assertIn("one grade per completed supplier rescue", raw["supplier-gear-stock-ceiling-profile"]["attributes"]["rarity-increment-per-completed-rescue"]["description"])
        self.assertIn("blocks above the floor", raw["shared-mission-completion-profile"]["attributes"]["delivery-height-above-floor-blocks"]["description"])
        self.assertIn("not removal of kill XP", raw["shared-mission-completion-profile"]["attributes"]["extra-completion-xp"]["description"])
        self.assertEqual((catalog("rarities")["common"]["index"], catalog("rarities")["legendary"]["index"]), (0, 4))

    def test_ruins_room_level_condition(self):
        from ontology_source_contracts import assert_declared_root

        anchor = "../domain/encounter-contracts.md#spike-traps-and-furnishing-contents"
        rule = {"see_also": [anchor],
                "preconditions": {"slot_conditions": {"saved-site-family": {"equals_string": "ruins"}}},
                "postconditions": {"slot_conditions": {"saved-site-room-levels": {
                    "minimum_cardinality": 3, "maximum_cardinality": 3}}}}
        fields = {"id", "family", "volumes", "pending", "cleared", "completed", "cycle", "mobs",
                  "rewards", "spirit_levels", "room_levels", "contents"}
        names = ["saved-site-" + field.replace("_", "-") for field in (
            "id", "family", "volumes", "pending", "cleared", "completed", "cycle", "mobs", "rewards",
            "spirit_levels", "room_levels", "contents")]

        def assert_contract(raw, view, schema):
            verify_ruins_room_contract(self, raw, view, schema, rule, names, anchor, fields)

        raw = yaml.safe_load((SCHEMA.parent / "save-world.yaml").read_text())
        view = SchemaView(str(SCHEMA))
        self.assertIn("saved-site", view.all_classes())
        # Declaration-first RED must not rely on unsupported native conditional rejection.
        self.assertEqual(raw["classes"]["saved-site"].get("rules"), [rule])
        schema = validator("saved-site").schema
        assert_contract(raw, view, schema)
        row = {"id": "site", "family": "ruins", "volumes": [[0, 0, 0, 10, 5, 10]],
               "pending": False, "cleared": False, "completed": False, "cycle": 0, "mobs": {},
               "rewards": {}, "spirit_levels": {}, "room_levels": [1, 2, 3],
               "contents": {"rubble": {}, "props": {}, "traps": []}}
        witnesses = []
        for family in ("ruins", "camp", "supplier"):
            # Short ruins arrays admit NATIVELY despite the precise authored exactly-three rule.
            # Nonruins keep their previous admission; neither result certifies runtime save validity.
            for levels in ([], [1], [1, 2], [1, 2, 3], [1, 1, 1]):
                candidate = dict(row, family=family, room_levels=levels)
                validate("saved-site", candidate)
                witnesses.append((candidate, True))
            for levels in ([1, 2, 3, 4], None, 1, True, "1", {}, [[1]], [0, 1, 2], [-1, 1, 2],
                           [True, 1, 2], [1.5, 1, 2], ["1", 1, 2], [None, 1, 2]):
                candidate = dict(row, family=family, room_levels=levels)
                with self.subTest(family=family, levels=levels), self.assertRaises(jsonschema.ValidationError):
                    validate("saved-site", candidate)
                witnesses.append((candidate, False))
            missing = {k: v for k, v in dict(row, family=family).items() if k != "room_levels"}
            with self.assertRaises(jsonschema.ValidationError):
                validate("saved-site", missing)
            witnesses.append((missing, False))
        for field in fields:
            with self.subTest(missing=field), self.assertRaises(jsonschema.ValidationError):
                validate("saved-site", {k: v for k, v in row.items() if k != field})
        for bad in (None, [], [row], 0, False, "site", {"saved-site": row}, dict(row, extra=True),
                    dict(row, **{"saved-site-family": "ruins", "saved-site-room-levels": [1, 2, 3]})):
            with self.assertRaises(jsonschema.ValidationError):
                validate("saved-site", bad)
        for family in (None, "other", True, 1, [], {}):
            with self.assertRaises(jsonschema.ValidationError):
                validate("saved-site", dict(row, family=family))
        for mutation in ("removed-rule", "wrong-family", "wrong-cardinality"):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as scratch:
                copied = Path(scratch) / "schema"
                shutil.copytree(SCHEMA.parent, copied)
                path = copied / "save-world.yaml"
                mutant = deepcopy(raw)
                if mutation == "removed-rule":
                    del mutant["classes"]["saved-site"]["rules"]
                elif mutation == "wrong-family":
                    mutant["classes"]["saved-site"]["rules"][0]["preconditions"]["slot_conditions"]["saved-site-family"]["equals_string"] = "camp"
                else:
                    mutant["classes"]["saved-site"]["rules"][0]["postconditions"]["slot_conditions"]["saved-site-room-levels"] = {
                        "minimum_cardinality": 2, "maximum_cardinality": 2}
                path.write_text(yaml.safe_dump(mutant, sort_keys=False))
                mutated_view = SchemaView(str(copied / SCHEMA.name))
                emitted = json.loads(JsonSchemaGenerator(
                    str(copied / SCHEMA.name), top_class="saved-site", preserve_names=True, not_closed=False).serialize())
                assert_declared_root("saved-site", fields, fields, view=mutated_view, schema=emitted)
                with self.assertRaises(AssertionError):
                    assert_contract(yaml.safe_load(path.read_text()), mutated_view, emitted)
                self.assertEqual(emitted == schema, mutation == "wrong-cardinality")
                native = jsonschema.Draft201909Validator(emitted)
                for candidate, admitted in witnesses:
                    self.assertEqual(native.is_valid(candidate), admitted)


if __name__ == "__main__":
    unittest.main()
