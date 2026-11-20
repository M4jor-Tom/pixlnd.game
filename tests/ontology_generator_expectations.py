"""Independent literal generator obligations from §5, §6 and encounter contracts."""

COLOR_PATTERN = r"^#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?(?![\s\S])"
COLOR_FIELDS = (
    ("generator-projectile-role", "color"), ("generator-role-override", "color"),
    ("generator-design-terrain", "water-color"), ("generator-design-terrain", "sand-color"),
    ("generator-design-terrain", "snow-color"),
    ("generator-design-settlement-style-colors-entry", "value"),
    ("generator-design-settlement-npc", "color"),
)

REQUIRED_WEAPONS = tuple("axe boomerang bow bracelet crossbow dagger fist greataxe greatmace greatsword longsword mace staff sword wand".split())

SOURCE_FIELDS = set("""$schema _doc world-scales seed time climate land terrain coarse-map-omega
settlement dungeon spawns boss names item loot realm npc-appearance schedule key-items-s
level-formulas-alpha design network-alpha""".split())
DESIGN_FIELDS = set("""_doc initial-encounters time gear-hp enemy-level skill-point abilities resources
special-attack status-effects progression crit item-stat-curve prices artifact stack-cap enemy-hp
circle-of-power block-reward regeneration artifacts-per-land pvp recipes terrain climate names
movement camera spawns creature-roles frame-budget loot starting-inventory combat defence movesets
feel settlement""".split())
NESTED_FIELDS = {
    "climate": "_doc field-frequency-lands field-octaves rules hud",
    "resources": "_doc mp",
    "defence": "_doc dodge block stealth enemy-hit",
    "creature-roles": "_doc default any-class melee ranged mage species",
    "feel": "_doc hit-stop shake numbers impact trail level-up events sfx",
    "initial-encounters": """_doc distance-min distance-max separation apron leading-objects dry-above-sea
hub-size ruins camp supplier pack-size species role-weights power-base-offset boss-hp-mult
boss-damage-mult boss-height boss-specials spirits mission-package special-profile rubble spikes furnishings""",
    "initial-encounters-ruins": "room corridor court passage alcove bounds ceiling door occupancy pack-tiers boss-tiers",
    "initial-encounters-special-profile": "ready-s cooldown-s recovery-s warning-s stomp charge",
    "initial-encounters-furnishings": "vase table armor",
    "terrain": """_doc block-m zone-blocks land-zones lands-per-axis land-blocks height sea-level heightfield
land-blend cliff-slope beach-above-sea snow-above water-color sand-color snow-color view-zones seed-default""",
    "settlement": """_doc per-land placement radius blend ring-radius buildings footprint style-by-landscape
style-colors npc shop trainer inn no-hostiles-within""",
}
# Exact selected bounds: source spelling, nominal range and equal endpoints.
FIXED = {
    ("generator-design-terrain", "zone-blocks"): ("integer", 64),
    ("generator-design-terrain", "land-zones"): ("integer", 256),
    ("generator-design-terrain", "lands-per-axis"): ("integer", 1024),
    ("generator-design-terrain", "land-blocks"): ("integer", 16384),
    ("generator-design-initial-encounters", "distance-min"): ("integer", 192),
    ("generator-design-initial-encounters", "distance-max"): ("integer", 215),
    ("generator-design-initial-encounters", "separation"): ("integer", 192),
    ("generator-design-initial-encounters-boss-height", "base"): ("double", 1.7),
    ("generator-design-initial-encounters-boss-height", "min-mult"): ("double", 1.25),
    ("generator-design-initial-encounters-boss-height", "growth"): ("double", 0.75),
    ("generator-design-initial-encounters-boss-height", "max-level"): ("integer", 10),
    ("generator-design-status-effects-burning", "pct-of-hit"): ("double", 0.1),
    ("generator-design-status-effects-poison", "duration-s"): ("double", 5.0),
    ("generator-design-frame-budget", "physics-hz"): ("integer", 60),
}


# Approved completed-object predicates; literal facts, not an expression interpreter.
OBJECT_EXPRESSIONS = {
    ("generator-design-spawns", "ai"): "ai if ai['sim-radius'] >= ai['aggro-range'] + ai['leash'] else ''",
    ("generator-design", "settlement"): "settlement if settlement['radius'] > settlement['blend'] else ''",
    ("generator-design-creature-roles", "ranged"): "ranged if ranged['range'] > ranged['keep-away'] else ''",
    ("generator-design-creature-roles", "mage"): "mage if mage['range'] > mage['keep-away'] else ''",
    ("generators-source", "design"): "design if design['defence']['dodge']['stamina'] <= design['movement']['stamina']['max'] else ''",
    ("generator-design", "feel"): "feel if max([feel['events']['hit']['hit-stop-s'], feel['events']['crit']['hit-stop-s'], feel['events']['kill']['hit-stop-s'], feel['events']['hurt']['hit-stop-s'], feel['events']['block']['hit-stop-s'], feel['events']['dodge']['hit-stop-s'], feel['events']['shoot']['hit-stop-s'], feel['events']['impact']['hit-stop-s'], feel['events']['level-up']['hit-stop-s'], feel['events']['pickup']['hit-stop-s'], feel['events']['coin']['hit-stop-s']]) <= feel['hit-stop']['max-s'] else ''",
}
SETTLEMENT_CONJUNCTS = [
    {"range": "generator-design-settlement", "inlined": True, "required": True,
     "equals_expression": "settlement if settlement['ring-radius'] < settlement['radius'] else ''"},
    {"range": "generator-design-settlement", "inlined": True, "required": True,
     "equals_expression": "settlement if settlement['no-hostiles-within'] >= settlement['radius'] else ''"},
]
NO_EQUALITY_FIELDS = (
    ("generator-design-enemy-hp", "power-base"), ("generator-design-spawns-ai", "wander-pause-s"),
    ("generator-design-spawns", "groups-per-zone"), ("generator-design-spawns", "default-group"),
    ("generator-design-camera", "pitch-deg"), ("generator-design-spawns-ai", "sim-radius"),
    ("generator-design-settlement", "radius"), ("generator-design-settlement", "no-hostiles-within"),
    ("generator-projectile-role", "range"), ("generator-design-defence-dodge", "iframe-s"),
)
ARENA_LITERAL = "[{'first': 'white', 'second': 'green'}, {'first': 'white', 'second': 'green'}, {'first': 'green', 'second': 'blue'}, {'first': 'blue', 'second': 'purple'}, {'first': 'purple', 'second': 'yellow'}]"
SELECTED_MAPS = {
    "generator-design-loot-rarity-weights": ("generator-design-loot-rarity-weights-entry",
        {"common": 60, "uncommon": 25, "rare": 10, "epic": 4, "legendary": 1}),
    "generator-design-loot-gear-kinds": ("generator-design-loot-gear-kinds-entry",
        {"weapon": 4, "chest-armor": 2, "gloves": 2, "boots": 2, "shoulder-armor": 2}),
}
POOL_FACTS = {"range": "consumable", "multivalued": True, "minimum_cardinality": 3,
    "maximum_cardinality": 3, "list_elements_unique": True,
    "all_members": {"range": "consumable", "equals_string_in": ["life-potion", "apple", "pineapple-slice"]},
    "equals_expression": "['life-potion', 'apple', 'pineapple-slice']"}
SHOP_STRINGS = {"rarity-cap": "common", "item-shop-pool": "design.loot.consumable-pool", "restock": "daily"}
STATUS_KEYS = ("burning", "poison", "stun", "knockdown", "knockback", "slow")
FIXED.update({
    ("generator-design-loot-coins", "chance"): ("double", 0.6),
    ("generator-design-loot-coins", "base"): ("integer", 1),
    ("generator-design-loot-coins", "per-level"): ("integer", 2),
    ("generator-design-loot", "gear-chance"): ("double", 0.2),
    ("generator-design-loot", "consumable-chance"): ("double", 0.15),
    ("generator-design-loot", "species-drop-chance"): ("double", 0.5),
    ("generator-design-loot", "level-spread"): ("integer", 1),
    ("generator-design-loot", "boss-rarity-shift"): ("integer", 1),
    ("generator-design-loot-ground", "lifetime-s"): ("integer", 60480),
    ("generator-design-loot-ground", "pickup-radius"): ("double", 2.0),
    ("generator-design-loot-ground", "scatter"): ("double", 1.0),
    ("generator-design-settlement-shop", "stock"): ("integer", 8),
    ("generator-design-settlement-shop", "level-spread"): ("integer", 1),
    ("generator-design-spawns-ai", "threat-per-full-hp"): ("double", 100.0),
    ("generator-design-spawns-ai", "threat-decay-per-s"): ("double", 1.0),
    ("generator-design-spawns-ai", "return-speed-mult"): ("double", 2.0),
    ("generator-design-spawns-ai", "return-damage-reduction"): ("double", 0.9),
})

EVENT_IDS = ("hit", "crit", "kill", "hurt", "block", "dodge", "shoot", "impact", "level-up", "pickup", "coin")
PROJECTILE_FIELDS = {
    "ability-runtime-speed": {"alias": "speed", "required": True, "range": "double", "minimum_value": 0,
                              "none_of": [{"range": "double", "equals_number": 0}], "all_of": [{"range": "double"}]},
    "ability-runtime-radius": {"alias": "radius", "required": True},
    "ability-runtime-life-s": {"alias": "life-s", "required": True, "range": "double", "minimum_value": 0,
                               "none_of": [{"range": "double", "equals_number": 0}], "all_of": [{"range": "double"}]},
}


RUNTIME_FIELDS = {
    "dash": ("distance",),
    "channel": ("duration-s", "turns-per-s", "drain-per-s", "radius", "damage-mult", "move-mult"),
    "buff": ("duration-s",),
    "heal": ("cast-s", "heal-pct"),
    "burst": ("radius", "damage-mult"),
    "projectile": ("speed", "radius", "life-s"),
}
RUNTIME_NONNULL_FIELDS = {
    ("channel", "drain-per-s"), ("channel", "damage-mult"), ("channel", "move-mult"),
    ("heal", "cast-s"), ("heal", "heal-pct"), ("burst", "damage-mult"),
    ("projectile", "speed"), ("projectile", "life-s"),
}
NUMERIC_DOMAIN_FIELDS = (
    ("design-world", "generator-design-spawns-ai", "sim-radius", ("spawns", "ai", "sim-radius"), 0, False),
    ("design-world", "generator-design-spawns-ai", "aggro-range", ("spawns", "ai", "aggro-range"), 0, False),
    ("design-world", "generator-design-spawns-ai", "leash", ("spawns", "ai", "leash"), 0, False),
    ("design-items", "generator-design-settlement", "radius", ("settlement", "radius"), 0, True),
    ("design-items", "generator-design-settlement", "blend", ("settlement", "blend"), 0, False),
    ("design-items", "generator-design-settlement", "ring-radius", ("settlement", "ring-radius"), None, False),
    ("design-items", "generator-design-settlement", "no-hostiles-within", ("settlement", "no-hostiles-within"), 0, False),
    ("design-combat", "generator-design-defence-dodge", "distance", ("defence", "dodge", "distance"), 0, True),
    ("design-combat", "generator-design-defence-block", "max", ("defence", "block", "max"), 0, True),
    ("design-combat", "generator-design-defence-block", "power-per-hit", ("defence", "block", "power-per-hit"), 0, True),
    ("design-combat", "generator-design-defence-block", "regen-per-s", ("defence", "block", "regen-per-s"), 0, False),
    ("design-combat", "generator-design-defence-block", "guardian-mult", ("defence", "block", "guardian-mult"), 1, False),
    ("design-combat", "generator-design-defence-stealth", "still-mult", ("defence", "stealth", "still-mult"), 1, False),
)


def aliases(owner):
    return {field.get("alias", key): field for key, field in owner.get("attributes", {}).items()}


def assert_color_contract(test, classes):
    for name, alias in COLOR_FIELDS:
        test.assertIn(name, classes)
        field = aliases(classes[name])[alias]
        test.assertEqual(field["range"], "string")
        test.assertEqual(field["pattern"], COLOR_PATTERN)
    override = aliases(classes["generator-role-override"])["color"]
    test.assertFalse(override["required"])
    test.assertEqual(override["all_of"], [{"range": "string"}])


def assert_map_batch_contract(test, classes):
    maps = (("generator-design-feel-numbers-colours", "generator-rgb-entry", "string"),
            ("generator-design-status-effects", "generator-status-entry", "status-effect"),
            ("generator-design-settlement-footprint", "generator-footprint-entry", "building"))
    for owner, entry, key_range in maps:
        test.assertEqual(classes[owner]["annotations"], {"source-map-entries": "entries"})
        field = aliases(classes[owner])["entries"]
        test.assertEqual(field["range"], entry)
        test.assertTrue(field["required"])
        test.assertTrue(field["multivalued"])
        test.assertTrue(field["inlined"])
        test.assertTrue(field["inlined_as_list"])
        test.assertEqual(aliases(classes[entry])["key"]["range"], key_range)
    test.assertEqual(set(aliases(classes["generator-design-feel-numbers-colours"])), {"entries"})
    rgb = aliases(classes["generator-rgb-entry"])["value"]
    test.assertEqual(rgb["range"], "double")
    test.assertEqual((rgb["minimum_cardinality"], rgb["maximum_cardinality"]), (3, 3))
    test.assertEqual((rgb["minimum_value"], rgb["maximum_value"]), (0, 1))
    hit = aliases(classes["generator-design-feel-numbers-colours"])["entries"]["has_member"]
    test.assertEqual(hit, {"range_expression": {"slot_conditions": {"key": {"range": "string", "equals_string": "hit"}}}})
    test.assertEqual(aliases(classes["generator-design-feel-numbers"])["colours"]["range"], "generator-design-feel-numbers-colours")
    test.assertEqual(set(aliases(classes["generator-design-status-effects"])), {"_doc", "entries"})
    test.assertEqual(aliases(classes["generator-design"])["status-effects"]["range"], "generator-design-status-effects")
    variants = aliases(classes["generator-status-entry"])["value"]["exactly_one_of"]
    names = ["generator-design-status-effects-" + key for key in ("stun", "knockdown", "knockback", "burning", "slow", "poison")]
    test.assertEqual([branch["range"] for branch in variants], names)
    test.assertTrue(all(branch["inlined"] and branch["required"] for branch in variants))
    conditions = classes["generator-design-status-effects"]["all_of"]
    test.assertEqual([c["slot_conditions"]["entries"]["has_member"]["range_expression"]["slot_conditions"]["key"]["equals_string"]
                      for c in conditions], ["burning", "poison"])
    rules = classes["generator-status-entry"]["rules"]
    test.assertEqual(len(rules), 6)
    for rule, key in zip(rules, STATUS_KEYS):
        test.assertEqual(rule["preconditions"]["slot_conditions"]["key"]["equals_string"], key)
        test.assertEqual(rule["postconditions"]["slot_conditions"]["value"],
                         {"range": "generator-design-status-effects-" + key, "inlined": True, "required": True})
    for alias_owner in ("generator-design-status-effects-knockdown", "generator-design-status-effects-poison"):
        test.assertEqual(aliases(classes[alias_owner])["as"]["range"], "status-effect")
    test.assertEqual(set(aliases(classes["generator-design-settlement-footprint"])), {"default", "entries"})
    test.assertEqual(aliases(classes["generator-design-settlement"])["footprint"]["range"], "generator-design-settlement-footprint")
    for owner, field in (("generator-design-settlement-footprint", "default"), ("generator-footprint-entry", "value")):
        triple = aliases(classes[owner])[field]
        test.assertEqual(triple["range"], "integer")
        test.assertIn("maximum_cardinality", triple)
        test.assertEqual((triple["minimum_cardinality"], triple["maximum_cardinality"]), (3, 3))
    for owner, fields in (("generator-source-world-scales-alpha", ("mission-cells-per-region",)),
                          ("generator-source-time", ("inn-hours",)), ("generator-source-dungeon", ("group-size",)),
                          ("generator-source-item", ("rarity-range",)),
                          ("generator-design-movement-hitbox", ("small", "normal", "large"))):
        for field in fields:
            pair = aliases(classes[owner])[field]
            test.assertIn("maximum_cardinality", pair)
            test.assertEqual((pair["minimum_cardinality"], pair["maximum_cardinality"]), (2, 2))
    test.assertEqual(aliases(classes["generator-design-settlement"])["buildings"]["range"], "building")


def assert_reviewed_contract(test, modules):
    classes = modules["design-combat"]["classes"]
    rule = next(r for r in classes["ability-runtime"]["rules"]
                if r["preconditions"]["slot_conditions"]["ability-runtime-runtime"]["equals_string"] == "projectile")
    test.assertEqual(rule["preconditions"]["slot_conditions"],
                     {"ability-runtime-runtime": {"alias": "runtime", "equals_string": "projectile"}})
    test.assertEqual(rule["postconditions"]["slot_conditions"], PROJECTILE_FIELDS)
    for key in ("ability-runtime-speed", "ability-runtime-life-s"):
        slot = modules["design-combat"]["slots"][key]
        test.assertEqual(slot["minimum_value"], 0)
        test.assertFalse(slot["required"])
        test.assertNotIn("none_of", slot)
    text = aliases(classes["generator-design-feel-level-up"])["text"]
    test.assertEqual((text["range"], text["required"], text["pattern"]), ("string", True, r"[\s\S]+"))
    test.assertIn("generator-feel-event", classes)
    payload = aliases(classes["generator-feel-event"])
    test.assertEqual(set(payload), {"hit-stop-s", "trauma", "sfx"})
    for alias, kind in (("hit-stop-s", "double"), ("trauma", "double"), ("sfx", "string")):
        test.assertEqual(payload[alias]["range"], kind)
        test.assertTrue(payload[alias]["required"])
        test.assertEqual(payload[alias]["slot_uri"], "pixlnd:generator-feel-event/" + alias)
    test.assertEqual(payload["hit-stop-s"]["minimum_value"], 0)
    test.assertEqual((payload["trauma"]["minimum_value"], payload["trauma"]["maximum_value"]), (0, 1))
    parent = aliases(classes["generator-design-feel-events"])
    test.assertEqual(set(parent), set(EVENT_IDS))
    for event in EVENT_IDS:
        test.assertNotIn("generator-design-feel-events-" + event, classes)
        field = parent[event]
        test.assertEqual(field["range"], "generator-feel-event")
        test.assertEqual(field["slot_uri"], "pixlnd:generator-design-feel-events/" + event)
        test.assertTrue(field["required"])
        test.assertTrue(field["inlined"])


def assert_runtime_rule_contract(test, modules):
    rules = modules["design-combat"]["classes"]["ability-runtime"]["rules"]
    test.assertEqual(len(rules), len(RUNTIME_FIELDS))
    by_kind = {r["preconditions"]["slot_conditions"]["ability-runtime-runtime"]["equals_string"]: r for r in rules}
    test.assertEqual(set(by_kind), set(RUNTIME_FIELDS))
    for kind, fields in RUNTIME_FIELDS.items():
        rule = by_kind[kind]
        test.assertEqual(rule["preconditions"]["slot_conditions"],
                         {"ability-runtime-runtime": {"alias": "runtime", "equals_string": kind}})
        expected = {"ability-runtime-" + f: {"alias": f, "required": True} for f in fields}
        for field in fields:
            if (kind, field) in RUNTIME_NONNULL_FIELDS:
                expected["ability-runtime-" + field]["all_of"] = [{"range": "double"}]
        test.assertEqual(rule["postconditions"]["slot_conditions"], PROJECTILE_FIELDS if kind == "projectile" else expected)


def assert_numeric_domain_contract(test, modules):
    for module, owner, field, _, lower, nonzero in NUMERIC_DOMAIN_FIELDS:
        slot = aliases(modules[module]["classes"][owner])[field]
        test.assertEqual((slot["range"], slot["required"], slot["alias"], slot["slot_uri"]),
                         ("double", True, field, "pixlnd:" + owner + "/" + field))
        test.assertEqual(slot.get("minimum_value"), lower)
        test.assertNotIn("maximum_value", slot)
        expected = [{"equals_number": 0}] if nonzero else []
        if owner == "generator-design-settlement" and field == "radius":
            expected = [{"range": "double", "equals_number": 0}]
        test.assertEqual(slot.get("none_of", []), expected)
        if lower is None:
            test.assertNotIn("minimum_value", slot)


def assert_literal_contract(test, modules):
    classes = {key: value for module in modules.values() for key, value in module.get("classes", {}).items()}
    assert_color_contract(test, classes)
    assert_map_batch_contract(test, classes)
    assert_reviewed_contract(test, modules)
    assert_runtime_rule_contract(test, modules)
    assert_numeric_domain_contract(test, modules)
    for name, fields in {"generators-source": SOURCE_FIELDS, "generator-design": DESIGN_FIELDS,
                         **{"generator-design-" + k: set(v.split()) for k, v in NESTED_FIELDS.items()}}.items():
        test.assertIn(name, classes)
        actual = aliases(classes[name])
        test.assertEqual(set(actual), fields, name)
        test.assertTrue(all(field.get("required") for field in actual.values()), name)
    for (name, alias), (kind, value) in FIXED.items():
        test.assertIn(name, classes)
        test.assertIn(alias, aliases(classes[name]))
        field = aliases(classes[name])[alias]
        test.assertIn("minimum_value", field)
        test.assertIn("maximum_value", field)
        test.assertEqual(field["range"], kind)
        test.assertEqual(field["minimum_value"], value)
        test.assertEqual(field["maximum_value"], value)
        test.assertNotIsInstance(field["minimum_value"], bool)
    for owner, key_range in (("generator-design-defence-dodge-on-dodge", "ability"),
                             ("generator-design-prices-rarity-mult", "GeneratorRarity"),
                             ("generator-design-creature-roles-any-class", "GeneratorRole")):
        test.assertEqual(classes[owner]["annotations"], {"source-map-entries": "entries"})
        test.assertEqual(set(aliases(classes[owner])), {"entries"})
        entry = aliases(classes[owner])["entries"]["range"]
        test.assertEqual(aliases(classes[entry])["key"]["range"], key_range)
    test.assertIn("all_of", classes["generator-design-movesets"])
    conditions = classes["generator-design-movesets"]["all_of"]
    test.assertEqual(len(conditions), len(REQUIRED_WEAPONS))
    for condition, key in zip(conditions, REQUIRED_WEAPONS):
        entry = condition["slot_conditions"]["entries"]
        test.assertEqual(entry["range"], "generator-moveset-entry")
        test.assertTrue(entry["required"])
        test.assertTrue(entry["multivalued"])
        test.assertTrue(entry["inlined"])
        test.assertTrue(entry["inlined_as_list"])
        member = entry["has_member"]["range_expression"]["slot_conditions"]["key"]
        test.assertEqual(member, {"range": "weapon-type", "equals_string": key})
    climate = aliases(classes["generator-design-climate"])["rules"]
    test.assertEqual(climate["range"], "generator-climate-rule")
    test.assertEqual(climate["annotations"], {"source-tuple-positions": "first second"})
    test.assertTrue(climate["multivalued"])
    test.assertTrue(climate["inlined_as_list"])
    pair = aliases(classes["generator-climate-rule"])
    test.assertEqual(set(pair), {"first", "second"})
    test.assertEqual(pair["first"]["range"], "landscape")
    test.assertEqual(pair["second"]["range"], "string")
    test.assertEqual(aliases(classes["generator-moveset-alias"])["as"]["range"], "weapon-type")
    test.assertEqual(aliases(classes["generators-source"])["design"]["range"], "generator-design")
    for key in ("item-stat-curve", "block-reward", "regeneration"):
        test.assertEqual(aliases(classes["generator-design"])[key]["range"], "string")

    for (owner, alias), expression in OBJECT_EXPRESSIONS.items():
        field = aliases(classes[owner])[alias]
        test.assertEqual(field.get("equals_expression"), expression)
        test.assertTrue(field["required"])
        test.assertTrue(field["inlined"])
    test.assertEqual(aliases(classes["generator-design"])["settlement"].get("all_of"), SETTLEMENT_CONJUNCTS)
    test.assertNotIn("all_of", aliases(classes["generators-source"])["design"])
    for owner, alias in NO_EQUALITY_FIELDS:
        test.assertNotIn("equals_expression", aliases(classes[owner])[alias])
    for alias, minimum in (("radius", 0), ("blend", 0), ("no-hostiles-within", 0)):
        test.assertEqual(aliases(classes["generator-design-settlement"])[alias].get("minimum_value"), minimum)
    test.assertNotIn("minimum_value", aliases(classes["generator-design-settlement"])["ring-radius"])
    test.assertEqual(aliases(classes["generator-source-boss"])["arena-waves"]["equals_expression"], ARENA_LITERAL)
    for owner, (entry, weights) in SELECTED_MAPS.items():
        field = aliases(classes[owner])["entries"]
        test.assertEqual((field["minimum_cardinality"], field["maximum_cardinality"]), (5, 5))
        test.assertEqual(classes[entry]["rules"], [{"preconditions": {"slot_conditions": {"key": {"equals_string": k}}},
            "postconditions": {"slot_conditions": {"value": {"range": "double", "minimum_value": v, "maximum_value": v}}}}
            for k, v in weights.items()])
    pool = aliases(classes["generator-design-loot"])["consumable-pool"]
    test.assertEqual({k: pool.get(k) for k in POOL_FACTS}, POOL_FACTS)
    test.assertEqual(aliases(classes["generator-design-loot-gear-kinds-entry"])["key"]["equals_string_in"],
                     ["weapon", "chest-armor", "gloves", "boots", "shoulder-armor"])
    for alias, value in SHOP_STRINGS.items():
        test.assertEqual(aliases(classes["generator-design-settlement-shop"])[alias].get("equals_string"), value)
    test.assertEqual(aliases(classes["generator-design-settlement-shop"])["rarity-cap"]["range"], "GeneratorRarity")
    pickup = aliases(classes["generator-design-loot-ground"])["auto-pickup"]
    test.assertEqual((pickup["minimum_cardinality"], pickup["maximum_cardinality"]), (1, 1))
    test.assertEqual(pickup["all_members"], {"range": "string", "equals_string": "coin"})
    taunt_rule = classes["generator-ability-entry"]["rules"][0]
    test.assertEqual(taunt_rule["preconditions"]["slot_conditions"]["key"]["equals_string"], "heroic-shout")
    taunt = taunt_rule["postconditions"]["slot_conditions"]["value"]["range_expression"]["slot_conditions"]["ability-runtime-taunt-s"]
    test.assertEqual(taunt, {"alias": "taunt-s", "range": "double", "required": True, "minimum_value": 3.0, "maximum_value": 3.0})
    member = classes["generator-design-abilities"]["all_of"][0]["slot_conditions"]["entries"]
    test.assertEqual(member["has_member"]["range_expression"]["slot_conditions"]["key"], {"range": "ability", "equals_string": "heroic-shout"})
    shot = modules["design-combat"]["slots"]["runtime-projectile-damage-mult"]
    test.assertEqual(shot.get("none_of"), [{"range": "double", "equals_number": 0}])
    test.assertEqual(shot["minimum_value"], 0)
    test.assertFalse(shot["required"])
