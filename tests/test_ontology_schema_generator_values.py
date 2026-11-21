"""Full bound-source negatives; no climate interpreter or gameplay execution."""

import unittest
from copy import deepcopy

import jsonschema
from ontology_generator_expectations import (
    DESIGN_FIELDS,
    REQUIRED_WEAPONS,
    SOURCE_FIELDS,
)
from ontology_source_contracts import validate_source
from test_ontology_schema_authoring import catalog


def changed(row, path, value):
    result = deepcopy(row)
    node = result
    for part in path[:-1]:
        node = node[part]
    node[path[-1]] = value
    return result


class GeneratorValueTests(unittest.TestCase):
    def assert_invalid(self, row, path, values):
        for value in values:
            with self.subTest(path=path, value=value), self.assertRaises(jsonschema.ValidationError):
                validate_source("generators", changed(row, path, value))

    def test_coupling_scalar_bounds_and_native_ceiling(self):
        from ontology_source_contracts import (
            assert_declared_root,
            bind_source,
            source_view,
            unbind_source,
        )
        from test_ontology_schema_authoring import validator

        source = catalog("generators")
        bound = bind_source("generators", source)
        self.assertEqual(unbind_source("generators", bound), source)
        native = validator("generators-source")
        native.validate(bound)
        full = native.schema
        owner = "generator-design-settlement"
        fields = set("""_doc per-land placement radius blend ring-radius buildings footprint
                     style-by-landscape style-colors npc shop trainer inn no-hostiles-within""".split())
        fragment = dict(full["$defs"][owner], **{"$defs": full["$defs"]})
        assert_declared_root(owner, fields, fields, schema=fragment, view=source_view())
        for field in ("radius", "blend", "no-hostiles-within"):
            with self.subTest(negative_scalar=field), self.assertRaises(jsonschema.ValidationError):
                native.validate(changed(bound, ("design", "settlement", field), -1))
        design = bound["design"]
        affected = [
            ("generator-design", design),
            ("generator-design-settlement", design["settlement"]),
            ("generator-design-spawns", design["spawns"]),
            ("generator-design-creature-roles", design["creature-roles"]),
            ("generator-source-boss", bound["boss"]),
            ("generator-design-enemy-hp", design["enemy-hp"]),
            ("generator-design-camera", design["camera"]),
            ("generator-design-spawns-ai", design["spawns"]["ai"]),
        ]
        for component, fixture in affected:
            definition = full["$defs"][component]
            self.assertEqual(definition["type"], "object")
            self.assertEqual(set(definition["properties"]), set(fixture))
            jsonschema.Draft201909Validator(dict(definition, **{"$defs": full["$defs"]})).validate(fixture)
        native.validate(changed(bound, ("design", "settlement", "ring-radius"), -1))
        cases = [
            (("settlement", "blend"), design["settlement"]["radius"]),
            (("settlement", "ring-radius"), design["settlement"]["radius"]),
            (("settlement", "no-hostiles-within"), design["settlement"]["radius"] - 1),
            (("spawns", "ai", "sim-radius"), 0),
            (("movement", "stamina", "max"), 24),
            (("creature-roles", "ranged", "keep-away"), design["creature-roles"]["ranged"]["range"]),
            (("creature-roles", "mage", "keep-away"), design["creature-roles"]["mage"]["range"]),
        ]
        for path, value in cases:
            native.validate(changed(bound, ("design",) + path, value))
        for event in ("hit", "crit", "kill", "hurt", "block", "dodge", "shoot", "impact", "level-up", "pickup", "coin"):
            native.validate(changed(bound, ("design", "feel", "events", event, "hit-stop-s"),
                            design["feel"]["hit-stop"]["max-s"] + 0.01))
        for path in (("enemy-hp", "power-base"), ("spawns", "ai", "wander-pause-s"),
                     ("spawns", "groups-per-zone"), ("spawns", "default-group"), ("camera", "pitch-deg")):
            value = design
            for key in path:
                value = value[key]
            native.validate(changed(bound, ("design",) + path, list(reversed(value))))
        print("COUPLINGS: 18bound shape-valid relational violations admitted; no equality execution claimed.")
        print("PAIRS: five reversed bound shape-valid examples admitted; NO canonical ordering rule selected.")
        print("AFFECTED real-source bound positive fragments:", [name for name, _ in affected], "generators-source")

    def test_selected_loot_shop_and_ai_inputs(self):
        from ontology_source_contracts import bind_source, unbind_source
        from test_ontology_schema_authoring import validator

        row = catalog("generators")
        bound = bind_source("generators", row)
        self.assertEqual(unbind_source("generators", bound), row)
        native = validator("generators-source")
        native.validate(bound)
        cases = [
            (("loot", "coins", "chance"), 0.61), (("loot", "coins", "base"), 2),
            (("loot", "coins", "per-level"), 3), (("loot", "gear-chance"), 0.21),
            (("loot", "consumable-chance"), 0.16), (("loot", "species-drop-chance"), 0.51),
            (("loot", "level-spread"), 2), (("loot", "boss-rarity-shift"), 2),
            (("loot", "ground", "lifetime-s"), 60481), (("loot", "ground", "pickup-radius"), 2.1),
            (("loot", "ground", "scatter"), 1.1), (("settlement", "shop", "stock"), 9),
            (("settlement", "shop", "level-spread"), 2), (("spawns", "ai", "threat-per-full-hp"), 101.0),
            (("spawns", "ai", "threat-decay-per-s"), 1.1), (("spawns", "ai", "return-speed-mult"), 2.1),
            (("spawns", "ai", "return-damage-reduction"), 0.8),
        ]
        rejections = [(("design",) + path, [bad, True]) for path, bad in cases]
        rejections += [(("design", "settlement", "shop", field), [bad]) for field, bad in (
            ("rarity-cap", "legendary"), ("rarity-cap", "mythical"), ("item-shop-pool", "unknown"), ("restock", "instant"))]
        rejections += [(("design", "loot", "consumable-pool"),
                        [[], ["life-potion", "apple"], ["life-potion", "apple", "unknown"]]),
                       (("design", "loot", "ground", "auto-pickup"), [[], ["weapon"], ["coin", "coin"]])]
        for path, values in rejections:
            for value in values:
                with self.subTest(bound_path=path, value=value), self.assertRaises(jsonschema.ValidationError):
                    native.validate(changed(bound, path, value))
        for name, key in (("rarity-weights", "common"), ("gear-kinds", "weapon")):
            missing = deepcopy(bound)
            entries = missing["design"]["loot"][name]["entries"]
            targets = [entry for entry in entries if entry["key"] == key]
            self.assertEqual(len(targets), 1)
            entries.remove(targets[0])
            with self.subTest(missing_selected_map_member=name), self.assertRaises(jsonschema.ValidationError):
                native.validate(missing)
        for name, key, value in (("rarity-weights", "common", 59), ("gear-kinds", "weapon", 3)):
            fixture = deepcopy(bound)
            targets = [e for e in fixture["design"]["loot"][name]["entries"] if e["key"] == key]
            self.assertEqual(len(targets), 1)
            targets[0]["value"] = value
            with self.subTest(selected_weight=key), self.assertRaises(jsonschema.ValidationError):
                native.validate(fixture)
        taunt = deepcopy(bound)
        targets = [e for e in taunt["design"]["abilities"]["entries"] if e["key"] == "heroic-shout"]
        self.assertEqual(len(targets), 1)
        targets[0]["value"]["taunt-s"] = 2.0
        with self.assertRaises(jsonschema.ValidationError):
            native.validate(taunt)
        for pool in (["apple", "life-potion", "pineapple-slice"], ["apple", "apple", "apple"]):
            native.validate(changed(bound, ("design", "loot", "consumable-pool"), pool))
        missing = deepcopy(bound)
        entries = missing["design"]["abilities"]["entries"]
        targets = [e for e in entries if e["key"] == "heroic-shout"]
        self.assertEqual(len(targets), 1)
        entries.remove(targets[0])
        native.validate(missing)
        print("SELECTED: numeric weight/taunt postconditions enforce; pool order/uniqueness and heroic membership are native ceilings.")
        print("One actual-source binding/roundtrip/positive; negatives validate copied bound fixtures, NOT per-negative raw roundtrips.")

    def test_reviewed_projectile_text_and_registry_facets(self):
        from ontology_source_contracts import bind_source, unbind_source
        from test_ontology_schema_authoring import validator

        source = catalog("generators")
        bound = bind_source("generators", source)
        self.assertEqual(unbind_source("generators", bound), source)
        native = validator("generators-source")
        native.validate(bound)
        for key in ("fire-missiles", "bubbles"):
            entries = [e for e in bound["design"]["abilities"]["entries"] if e["key"] == key]
            self.assertEqual(len(entries), 1)
            self.assertEqual(entries[0]["value"]["runtime"], "projectile")
            for field in ("speed", "life-s"):
                self.assertGreater(entries[0]["value"][field], 0)
                for bad in (0, -1, True, False):
                    fixture = deepcopy(bound)
                    target = next(e for e in fixture["design"]["abilities"]["entries"] if e["key"] == key)
                    target["value"][field] = bad
                    with self.subTest(projectile=key, field=field, value=bad), self.assertRaises(jsonschema.ValidationError):
                        native.validate(fixture)
        with self.assertRaises(jsonschema.ValidationError):
            native.validate(changed(bound, ("design", "feel", "level-up", "text"), ""))
        for text in ("\n", "LEVEL\nUP", " "):
            with self.subTest(nonempty_text=repr(text)):
                native.validate(changed(bound, ("design", "feel", "level-up", "text"), text))
        for path, values in ((("design", "movesets", "kinds"), ["melee"]),
                             (("design", "abilities", "runtimes"), ["dash"])):
            native.validate(changed(bound, path, values))
        events = bound["design"]["feel"]["events"]
        self.assertEqual(set(events), {"hit", "crit", "kill", "hurt", "block", "dodge", "shoot", "impact", "level-up", "pickup", "coin"})
        for key, payload in events.items():
            self.assertEqual(set(payload), {"hit-stop-s", "trauma", "sfx"})
            native.validate(changed(bound, ("design", "feel", "events", key), payload))
        for field, bad in (("hit-stop-s", -1), ("hit-stop-s", True), ("trauma", 1.1), ("trauma", True)):
            with self.subTest(event_field=field, value=bad), self.assertRaises(jsonschema.ValidationError):
                native.validate(changed(bound, ("design", "feel", "events", "hit", field), bad))
        print("REVIEW facets: direct positive/zero/negative/Boolean controls; nonempty LF/multiline legal.")
        print("REGISTRY mismatches admitted: configured kinds/runtimes joins remain canonical, not native enforcement.")
        print("EVENTS all11real payloads positive; one source roundtrip, copied bound controls.")

    def test_numeric_feedback_colour_map(self):
        from ontology_source_contracts import _walk, assert_declared_root, source_view
        from test_ontology_schema import generated

        owner = "generator-design-feel-numbers-colours"
        self.assertIn(owner, source_view().all_classes())
        full = generated(owner)
        self.assertEqual(full["$defs"][owner]["type"], "object")
        native = jsonschema.Draft201909Validator(full)
        hit = {"hit": [1, 1, 1]}
        native.validate(_walk(owner, hit, False))
        assert_declared_root(owner, {"entries"}, {"entries"}, schema=full)
        for row in (hit, {"hit": [1, 1, 1], "additional-kind": [0, 0.5, 1]}):
            bound = _walk(owner, row, False)
            self.assertEqual(_walk(owner, bound, True), row)
            native.validate(bound)
        for row in ({}, {"other": [1, 1, 1]}):
            with self.subTest(missing_hit=row), self.assertRaises(jsonschema.ValidationError):
                native.validate(_walk(owner, row, False))
        for value in ([1, 1], [1, 1, 1, 1], [True, 0, 0], [-0.01, 0, 0],
                      [1.01, 0, 0], ["1", 0, 0], None):
            with self.subTest(rgb=value), self.assertRaises(jsonschema.ValidationError):
                native.validate(_walk(owner, {"hit": value}, False))
        print("RGB required-hit emitted:", full["$defs"][owner]["properties"]["entries"])

    def test_status_effect_config_map(self):
        from ontology_source_contracts import _walk, assert_declared_root, source_view
        from test_ontology_schema import generated

        owner = "generator-design-status-effects"
        self.assertIn(owner, source_view().all_classes())
        full = generated(owner)
        self.assertEqual(full["$defs"][owner]["type"], "object")
        native = jsonschema.Draft201909Validator(full)
        row = catalog("generators")["design"]["status-effects"]
        bound = _walk(owner, row, False)
        native.validate(bound)
        self.assertIn("entries", bound)
        assert_declared_root(owner, {"_doc", "entries"}, {"_doc", "entries"}, schema=full)
        self.assertEqual(_walk(owner, bound, True), row)
        self.assertEqual({e["key"] for e in bound["entries"]},
                         {"stun", "knockdown", "knockback", "burning", "slow", "poison"})
        for value in (None, [], True, {}, {"unknown": 1}, {"duration-s": True}):
            with self.subTest(status_payload=value), self.assertRaises(jsonschema.ValidationError):
                native.validate(_walk(owner, changed(row, ("stun",), value), False))
        unknown = dict(row, **{"not-a-defined-effect": {"duration-s": 2.0}})
        native.validate(_walk(owner, unknown, False))  # Nominal target is not native FK existence.
        alias = changed(row, ("knockdown", "as"), "not-a-configured-effect")
        native.validate(_walk(owner, alias, False))
        missing = deepcopy(row)
        del missing["burning"]
        native.validate(_walk(owner, missing, False))
        contrary = changed(row, ("burning",), {"impulse": 8.0})
        native.validate(_walk(owner, contrary, False))
        for key, value in (("stun", {"impulse": 8.0}), ("knockdown", {"impulse": 8.0}),
                           ("knockback", {"duration-s": 2.0}), ("slow", {"impulse": 8.0})):
            native.validate(_walk(owner, changed(row, (key,), value), False))
        print("STATUS four further known-key contrary payloads admitted; six correlations remain declared.")
        print("STATUS declared required/key-payload predicates remain native ceilings;",
              "missing burning and contrary burning payload admitted")
        print("STATUS emitted:", full["$defs"]["generator-status-entry"].get("allOf"))

    def test_settlement_footprint_map(self):
        from ontology_source_contracts import _walk, assert_declared_root, source_view
        from test_ontology_schema import generated

        owner = "generator-design-settlement-footprint"
        self.assertIn(owner, source_view().all_classes())
        full = generated(owner)
        self.assertEqual(full["$defs"][owner]["type"], "object")
        native = jsonschema.Draft201909Validator(full)
        row = catalog("generators")["design"]["settlement"]["footprint"]
        default = {"default": row["default"]}
        native.validate(_walk(owner, default, False))
        assert_declared_root(owner, {"default", "entries"}, {"default", "entries"}, schema=full)
        for specimen in (default, row, dict(default, inn=row["inn"])):
            bound = _walk(owner, specimen, False)
            native.validate(bound)
            self.assertEqual(_walk(owner, bound, True), specimen)
        for key in ("default", "inn"):
            for value in ([6, 5], [6, 5, 6, 7], [True, 5, 6], ["6", 5, 6]):
                with self.subTest(footprint=key, value=value), self.assertRaises(jsonschema.ValidationError):
                    native.validate(_walk(owner, changed(row, (key,), value), False))
        bound = _walk(owner, default, False)
        bound["entries"].append({"key": "default", "value": [6, 5, 6]})
        with self.assertRaises(jsonschema.ValidationError):
            _walk(owner, bound, True)

    def test_generator_pair_tuple_shapes(self):
        from ontology_source_contracts import source_view
        from test_ontology_schema import generated

        row = catalog("generators")
        owners = [
            ("generator-source-world-scales-alpha", row["world-scales"]["alpha"], ["mission-cells-per-region"]),
            ("generator-source-time", row["time"], ["inn-hours"]),
            ("generator-source-dungeon", row["dungeon"], ["group-size"]),
            ("generator-source-item", row["item"], ["rarity-range"]),
            ("generator-design-movement-hitbox", row["design"]["movement"]["hitbox"], ["small", "normal", "large"]),
        ]
        for owner, specimen, keys in owners:
            self.assertIn(owner, source_view().all_classes())
            full = generated(owner)
            self.assertEqual(full["$defs"][owner]["type"], "object")
            native = jsonschema.Draft201909Validator(full)
            native.validate(specimen)
            for key in keys:
                self.assertIn(key, full["$defs"][owner]["properties"])
                pair = specimen[key]
                for value in (pair[:1], pair + [pair[0]], [True, pair[1]]):
                    with self.subTest(pair_owner=owner, field=key, value=value):
                        with self.assertRaises(jsonschema.ValidationError):
                            native.validate(changed(specimen, (key,), value))

    def test_settlement_building_reference(self):
        from ontology_source_contracts import _walk, source_view
        from test_ontology_schema import generated

        owner = "generator-design-settlement"
        view = source_view()
        self.assertIn(owner, view.all_classes())
        slot = next(s for s in view.class_induced_slots(owner) if s.alias == "buildings")
        self.assertEqual(slot.range, "building")
        self.assertTrue(slot.multivalued)
        self.assertFalse(view.is_inlined(slot))
        full = generated(owner)
        self.assertEqual(full["$defs"][owner]["properties"]["buildings"]["type"], "array")
        self.assertEqual(full["$defs"][owner]["properties"]["buildings"]["items"]["type"], "string")
        row = catalog("generators")["design"]["settlement"]
        self.assertTrue(set(row["buildings"]) <= set(catalog("buildings")["buildings"]))
        self.assertEqual(row["buildings"].count("house"), 5)
        native = jsonschema.Draft201909Validator(full)
        native.validate(_walk(owner, row, False))
        native.validate(_walk(owner, changed(row, ("buildings",), ["house", "house"]), False))
        native.validate(_walk(owner, changed(row, ("buildings",), ["not-a-building"]), False))
        with self.assertRaises(jsonschema.ValidationError):
            native.validate(_walk(owner, changed(row, ("buildings",), [{"id": "inn"}]), False))

    def test_selected_color_syntax_at_all_source_locations(self):
        from ontology_source_contracts import assert_declared_root
        from test_ontology_schema import generated

        full = generated("generator-role-override")
        fields = set("range keep-away windup-s cooldown-s damage-mult shot applies sfx color".split())
        assert_declared_root("generator-role-override", fields, set(), schema=full)
        native = jsonschema.Draft201909Validator(full)
        native.validate({})
        print("OPTIONAL color emitted:", full["$defs"]["generator-role-override"]["properties"]["color"])
        with self.assertRaises(jsonschema.ValidationError):
            native.validate({"color": None})
        row = catalog("generators")
        # This first full-source assertion exposed the old six-only overrestriction in RED.
        validate_source("generators", changed(row, ("design", "creature-roles", "ranged", "color"), "#11223344"))
        locations = [
            ("creature-roles", "ranged", "color"), ("creature-roles", "mage", "color"),
            ("creature-roles", "species", "spitter", "color"),
            ("terrain", "water-color"), ("terrain", "sand-color"), ("terrain", "snow-color"),
            ("settlement", "style-colors", "european-framework", 0),
            ("settlement", "npc", "color"),
        ]
        positives = ("#abcdef", "#AbCdEf", "#abcdef00", "#aBcDeF00", "#aBcDeFFF", "#ABCDEFff")
        negatives = ("", "#abc", "#abcd", "abcdef", "abcdef00", "#abcde", "#abcdef0",
                     "#abcdef000", "#abcdeg", "red", " #abcdef", "#abcdef ",
                     "#abcdef\n", "#abcdef\r", "#abcdef00\n", "#abcdef00\r\n", "#abcdefx", "#abcdef00x",
                     None, True, 1, [], {})
        for suffix in locations:
            path = ("design",) + suffix
            for value in positives:
                with self.subTest(color_path=path, positive=value):
                    validate_source("generators", changed(row, path, value))
            self.assert_invalid(row, path, negatives)

    def test_remaining_config_facets_and_required_weapon_entries(self):
        """VR-A only; legacy selector A no longer denotes the full monolith."""
        from time import monotonic
        phase_start = monotonic()
        from ontology_source_contracts import bind_source, unbind_source
        from test_ontology_schema_authoring import validator
        row = catalog('generators')
        print('VR-A baseline bind begin', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        bound = bind_source('generators', row)
        print('VR-A baseline bind end', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        print('VR-A baseline inverse begin', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        self.assertEqual(unbind_source('generators', bound), row)
        print('VR-A baseline inverse end', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        native = validator('generators-source')
        print('VR-A baseline native positive begin', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        native.validate(bound)
        print('VR-A baseline native positive end', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        native.validate(changed(bound, ('design', 'loot', 'level-spread'), 1))
        for bad in (0, -1, True):
            print('VR-A case begin', bad, 'elapsed', round(monotonic() - phase_start, 6), flush=True)
            with self.subTest(selected_loot_spread=bad), self.assertRaises(jsonschema.ValidationError):
                native.validate(changed(bound, ('design', 'loot', 'level-spread'), bad))
            print('VR-A case end', bad, 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        for suffix, lower in [(('defence', 'block', 'regen-per-s'), 0), (('defence', 'block', 'guardian-mult'), 1), (('defence', 'stealth', 'decay-per-s'), 0), (('defence', 'stealth', 'still-mult'), 1), (('defence', 'dodge', 'iframe-s'), 0), (('feel', 'shake', 'max-offset'), 0), (('feel', 'shake', 'max-roll-deg'), 0), (('feel', 'shake', 'shake-mult'), 0)]:
            print('VR-A case begin', (suffix, lower), 'elapsed', round(monotonic() - phase_start, 6), flush=True)
            path = ('design',) + suffix
            native.validate(changed(bound, path, lower))
            for bad in (lower - 1, True):
                print('VR-A case begin', bad, 'elapsed', round(monotonic() - phase_start, 6), flush=True)
                with self.subTest(bound_path=path, value=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(changed(bound, path, bad))
                print('VR-A case end', bad, 'elapsed', round(monotonic() - phase_start, 6), flush=True)
            print('VR-A case end', (suffix, lower), 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        print('VR-A complete', 'elapsed', round(monotonic() - phase_start, 6), flush=True)

    def test_remaining_config_map_shapes_and_malformed_values(self):
        """VR-B only; legacy selector A no longer denotes the full monolith."""
        from time import monotonic
        phase_start = monotonic()
        from ontology_source_contracts import _walk, bind_source, unbind_source
        from test_ontology_schema_authoring import validator
        row = catalog('generators')
        print('VR-B baseline bind begin', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        bound = bind_source('generators', row)
        print('VR-B baseline bind end', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        print('VR-B baseline inverse begin', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        self.assertEqual(unbind_source('generators', bound), row)
        print('VR-B baseline inverse end', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        native = validator('generators-source')
        print('VR-B baseline native positive begin', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        native.validate(bound)
        print('VR-B baseline native positive end', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        for suffix in (('defence', 'dodge', 'on-dodge'), ('prices', 'rarity-mult'), ('creature-roles', 'any-class')):
            print('VR-B case begin', suffix, 'elapsed', round(monotonic() - phase_start, 6), flush=True)
            node = bound['design']
            for part in suffix:
                node = node[part]
            with self.subTest(map=suffix):
                self.assertIn('entries', node)
            print('VR-B case end', suffix, 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        maps = [(('defence', 'dodge', 'on-dodge'), 'generator-design-defence-dodge-on-dodge', [{'elusiveness': {'unknown': 1}}]), (('prices', 'rarity-mult'), 'generator-design-prices-rarity-mult', [{'mythical': 1}]), (('creature-roles', 'any-class'), 'generator-design-creature-roles-any-class', [{'unknown': 1}, {'melee': -1}, {'melee': 0}])]
        for suffix, owner, malformed in maps:
            print('VR-B case begin', (suffix, owner, malformed), 'elapsed', round(monotonic() - phase_start, 6), flush=True)
            for value in malformed:
                print('VR-B case begin', value, 'elapsed', round(monotonic() - phase_start, 6), flush=True)
                with self.subTest(map=suffix, malformed=value), self.assertRaises(jsonschema.ValidationError):
                    fixture = _walk(owner, value, False)
                    native.validate(changed(bound, ('design',) + suffix, fixture))
                print('VR-B case end', value, 'elapsed', round(monotonic() - phase_start, 6), flush=True)
            print('VR-B case end', (suffix, owner, malformed), 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        print('VR-B complete', 'elapsed', round(monotonic() - phase_start, 6), flush=True)

    def test_remaining_required_weapon_membership_ceiling(self):
        """VR-C only; legacy selector A no longer denotes the full monolith."""
        from time import monotonic
        phase_start = monotonic()
        from ontology_source_contracts import bind_source, unbind_source
        from test_ontology_schema_authoring import validator
        row = catalog('generators')
        print('VR-C baseline bind begin', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        bound = bind_source('generators', row)
        print('VR-C baseline bind end', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        print('VR-C baseline inverse begin', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        self.assertEqual(unbind_source('generators', bound), row)
        print('VR-C baseline inverse end', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        native = validator('generators-source')
        print('VR-C baseline native positive begin', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        native.validate(bound)
        print('VR-C baseline native positive end', 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        for key in REQUIRED_WEAPONS:
            print('VR-C case begin', key, 'elapsed', round(monotonic() - phase_start, 6), flush=True)
            bad = deepcopy(bound)
            entries = bad['design']['movesets']['entries']
            selected = [e for e in entries if e['key'] == key]
            self.assertEqual(len(selected), 1)
            entries.remove(selected[0])
            with self.subTest(declared_required_but_native_admitted=key):
                native.validate(bad)
            print('VR-C case end', key, 'elapsed', round(monotonic() - phase_start, 6), flush=True)
        print('VR-C complete', 'elapsed', round(monotonic() - phase_start, 6), flush=True)


    def test_required_whole_source_and_every_design_group(self):
        row = catalog("generators")
        validate_source("generators", row)
        for key in SOURCE_FIELDS:
            bad = deepcopy(row)
            del bad[key]
            with self.subTest(root=key), self.assertRaises(jsonschema.ValidationError):
                validate_source("generators", bad)
        for key in DESIGN_FIELDS:
            bad = deepcopy(row)
            del bad["design"][key]
            with self.subTest(group=key), self.assertRaises(jsonschema.ValidationError):
                validate_source("generators", bad)
        for key in DESIGN_FIELDS - {"_doc", "item-stat-curve", "block-reward", "regeneration"}:
            self.assert_invalid(row, ("design", key), [None, [], "object", True])
        for key in ("item-stat-curve", "block-reward", "regeneration"):
            self.assert_invalid(row, ("design", key), [None, [], {}, True, 1])
        for malformed in (None, [], {}, True, "source"):
            with self.subTest(root=malformed), self.assertRaises(jsonschema.ValidationError):
                validate_source("generators", malformed)

    def test_climate_collection_pair_and_expression_shapes(self):
        row = catalog("generators")
        path = ("design", "climate", "rules")
        self.assert_invalid(row, path, [None, {}, "oceans", [], [["oceans"]],
                                      [["oceans", "true", "extra"]],
                                      [{"first": "oceans", "second": "true"}],
                                      [[False, "true"]], [["oceans", 1]], [["oceans", None]]])
        # Schema preserves expressions as raw strings. Parseability remains GDScript's check.
        raw_expression = changed(row, path, [["oceans", "not a parsed expression"]])
        validate_source("generators", raw_expression)

    def test_exact_selected_boundaries_and_boolean_numbers(self):
        row = catalog("generators")
        for path, value in [
            (("design", "terrain", "lands-per-axis"), 1024),
            (("design", "terrain", "land-blocks"), 16384),
            (("design", "initial-encounters", "distance-min"), 192),
            (("design", "initial-encounters", "boss-height", "base"), 1.7),
            (("design", "status-effects", "burning", "pct-of-hit"), 0.1),
        ]:
            validate_source("generators", changed(row, path, value))
            self.assert_invalid(row, path, [value - 0.01, value + 0.01, True, False, str(value), None])
        self.assert_invalid(row, ("design", "initial-encounters", "ruins", "room"),
                            [[24], [24, 24, 24], [24, True], [24, 25]])
        self.assert_invalid(row, ("design", "loot", "gear-chance"), [0, 1, -0.001, 1.001, True])
        path = ("design", "defence", "enemy-hit", "stun-chance")
        for value in (0, 1):
            validate_source("generators", changed(row, path, value))
        self.assert_invalid(row, path, [-0.001, 1.001, True])
        from ontology_source_contracts import class_contract, validator

        class_contract("runtime-projectile")
        native = validator("runtime-projectile")
        shot = row["design"]["abilities"]["shuriken-attack"]["throw"]
        self.assertEqual(shot["damage-mult"], 0.6)
        native.validate(shot)
        omitted = deepcopy(shot)
        del omitted["damage-mult"]
        native.validate(omitted)
        for value in (0, True, False):
            with self.subTest(nested_shot=value), self.assertRaises(jsonschema.ValidationError):
                native.validate(dict(shot, **{"damage-mult": value}))
        validate_source("generators", changed(row, ("design", "abilities", "heroic-shout", "damage-mult"), 0))

    def test_closed_moveset_variants_and_partial_role_override(self):
        row = catalog("generators")
        self.assert_invalid(row, ("design", "movesets", "axe"),
                            [{"as": "sword", "m1": {"kind": "melee"}}, {"as": 1}, {}])
        self.assert_invalid(row, ("design", "movesets", "bow", "m1", "speed"), [0, -1, True])
        self.assert_invalid(row, ("design", "movesets", "bow", "m1", "kind"), ["unknown", None])
        self.assert_invalid(row, ("design", "creature-roles", "species", "spitter"),
                            [{"kind": "melee"}, {"arbitrary": 1}])
        validate_source("generators", changed(row, ("design", "creature-roles", "species", "spitter"), {}))
        # Nominal source references are not native foreign-key existence checks.
        validate_source("generators", changed(row, ("design", "movesets", "axe", "as"), "unknown-weapon"))


if __name__ == "__main__":
    unittest.main()
