## Ordered encounters validation, called through the concrete ontology.
extends RefCounted
const World := preload("res://ontology/model_world.gd")


static func selected_tree(o, value: Variant, expected: Variant, path: String) -> void:
	if expected is Dictionary:
		selected_object(o, value, expected, path)
	elif expected is Array:
		selected_array(o, value, expected, path)
	elif expected is int or expected is float:
		selected_number(o, value, expected, path)
	elif typeof(value) != typeof(expected) or value != expected:
		o.errors.append(path + ": must equal selected " + str(expected))


static func selected_object(o, value: Variant, expected: Dictionary, path: String) -> void:
	if not value is Dictionary:
		o.errors.append(path + ": required object missing or malformed")
		return
	for key in expected:
		o._selected_tree(value.get(key), expected[key], path + "." + key)
	for key in value:
		if unknown_selected_field(key, expected):
			o.errors.append(path + "." + str(key) + ": unknown selected field")


static func unknown_selected_field(key: Variant, expected: Dictionary) -> bool:
	return not key is String or (not key.begins_with("_") and not expected.has(key))


static func selected_array(o, value: Variant, expected: Array, path: String) -> void:
	if not value is Array or value.size() != expected.size():
		o.errors.append(path + ": required selected array")
		return
	for i in expected.size():
		o._selected_tree(value[i], expected[i], path + "[" + str(i) + "]")


static func selected_number(o, value: Variant, expected: Variant, path: String) -> void:
	if not o._is_selected_multiplier(value, expected):
		o.errors.append(path + ": must equal selected " + str(expected))


static func validate_playable_sites(o, design: Dictionary) -> void:
	o._selected_tree(
		design.get("initial-encounters"), site_selection(), "design.initial-encounters"
	)
	validate_stone(o)
	validate_site_references(o, design)


static func validate_encounter_phases(o, design: Dictionary) -> bool:
	o._validate_initial_encounter_config(design)
	o._validate_playable_sites(design)
	return World.validate_terrain_ai(o, design)


static func validate_initial_encounter_config(o, design: Dictionary) -> bool:
	var settlement: Variant = design.get("settlement")
	if not settlement is Dictionary:
		o.errors.append("design.settlement: required object missing or malformed")
	elif not o._is_selected_multiplier(settlement.get("per-land"), 1.0):
		o.errors.append("design.settlement.per-land: must equal selected exact count 1")
	# Approved AI/game-clock inputs; require selected values, never runtime defaults.
	var selected = {
		"time": {"speed": 10.0, "day-s": 86400.0, "initial-hour": 7.0},
		"spawns.ai":
		{
			"threat-per-full-hp": 100.0,
			"threat-decay-per-s": 1.0,
			"return-speed-mult": 2.0,
			"return-damage-reduction": 0.9
		},
		"abilities.heroic-shout": {"taunt-s": 3.0}
	}
	for path in selected:
		selected_policy_path(o, design, path, selected[path])
	return o._validate_hybrid_count()


static func hybrid_flags(o, raw: Dictionary) -> bool:
	var raw_flags: Variant = raw.get("flags")
	if not raw_flags is Dictionary:
		o.errors.append("rulesets.ruleset-hybrid.flags: required object missing or malformed")
	elif not o._is_selected_multiplier(raw_flags.get("settlements-per-land"), 1.0):
		o.errors.append(
			"rulesets.ruleset-hybrid.flags.settlements-per-land: must equal selected exact count 1"
		)

	return true


# Fresh mutable expected rows preserve subclass annotation/selection callbacks.
static func site_selection() -> Dictionary:
	return {
		"distance-min": 192,
		"distance-max": 215,
		"separation": 192,
		"apron": 8,
		"leading-objects": {"ruins": "masonry", "camp": "stake-torch", "supplier": "broken-crate"},
		"dry-above-sea": 4,
		"hub-size": 64,
		"ruins":
		{
			"room": [24, 24],
			"corridor": [8, 8],
			"court": [24, 16],
			"passage": [8, 8],
			"alcove": [12, 8],
			"bounds": [36, 112],
			"ceiling": 6,
			"door": [4, 5],
			"occupancy": [-1, 12],
			"pack-tiers": [1, 2, 3],
			"boss-tiers": [2, 3]
		},
		"camp": {"size": 64, "occupancy": [-1, 16], "exit-width": 8, "tier": 1, "packs": 2},
		"supplier":
		{"size": 48, "occupancy": [-1, 16], "exit-width": 8, "tiers": [0, 1, 2, 3], "packs": 2},
		"pack-size": 3,
		"species": "skeleton",
		"role-weights": {"melee": 0.5, "ranged": 0.3, "mage": 0.2},
		"power-base-offset": 2,
		"boss-hp-mult": 4,
		"boss-damage-mult": 1.5,
		"boss-height": {"base": 1.7, "min-mult": 1.25, "growth": 0.75, "max-level": 10},
		"boss-specials": {"stomp": 0.5, "charge": 0.5},
		"spirits":
		{"spirit-fire": 0.25, "spirit-unholy": 0.25, "spirit-ice": 0.25, "spirit-wind": 0.25},
		"mission-package":
		{
			"coin-per-grade": 20,
			"potion": "life-potion",
			"potion-rarity": 0,
			"potion-count": 1,
			"gems": ["emerald", "sapphire", "ruby", "diamond"],
			"gem-count-per-grade": 1,
			"rarity-shift": 1,
			"upgrades": 0,
			"delivery-height": 0.5
		},
		"special-profile": site_special_profile(),
		"rubble":
		{"per-arena": 8, "voxel-size": 1, "restore-world-hours": 72, "block-type": "rock-building"},
		"spikes":
		{
			"count": 2,
			"footprint": [2, 2],
			"victim-height": [0, 1],
			"warning-s": 0.8,
			"active-s": 0.25,
			"cooldown-s": 2,
			"damage": 30,
			"attack-type": "physical",
			"warning-sfx": "block"
		},
		"furnishings": site_furnishings()
	}


static func site_special_profile() -> Dictionary:
	return {
		"ready-s": 3,
		"cooldown-s": 10,
		"recovery-s": 0.8,
		"warning-s": 1.2,
		"stomp": {"radius": 4, "start-height-diff": 2, "victim-height": [0, 1], "damage-mult": 1},
		"charge":
		{
			"range": [4, 10],
			"start-height-diff": 1,
			"lane-width": 2,
			"speed": 12,
			"sweep-radius": 1,
			"damage-mult": 1.25
		}
	}


static func site_furnishings() -> Dictionary:
	return {
		"vase": {"per-room": 2, "hp": 10, "coin-base": 1, "coin-per-level": 2},
		"table":
		{
			"per-room": 1,
			"hp": 20,
			"flask": "glass-flask",
			"flask-count": 1,
			"potion": "life-potion",
			"potion-count": 1,
			"potion-rarity": 0
		},
		"armor": 0
	}


static func validate_stone(o) -> void:
	var blocks: Variant = o.configs.get("block-types")
	if not stone_definition(blocks):
		o.errors.append("initial-encounters.rubble.block-type: required stone definition")


static func stone_definition(blocks: Variant) -> bool:
	if not blocks is Dictionary or not blocks.get("alpha") is Dictionary:
		return false
	return stone_row(blocks.alpha.get("6"))


static func stone_row(row: Variant) -> bool:
	if not row is Dictionary:
		return false
	return (
		row.get("id") is String
		and row.id == "rock-building"
		and row.get("solid") is bool
		and row.solid
	)


static func validate_site_references(o, design: Dictionary) -> void:
	furnishing_references(o)
	if not o._object(o._object(design.get("feel")).get("sfx")).has("block"):
		o.errors.append("initial-encounters.spikes.warning-sfx: required sound")
	if not o.creatures.has(&"skeleton"):
		o.errors.append("initial-encounters.species: skeleton required")
	spirit_references(o)


static func selected_policy_path(o, design: Dictionary, path: String, selected: Dictionary) -> void:
	var row: Variant = design
	for part in path.split("."):
		row = row.get(part) if row is Dictionary else null
	selected_policy_values(o, row, selected, path)


static func furnishing_references(o) -> void:
	if not o._object(o.configs.get("ingredients")).has("glass-flask"):
		o.errors.append("initial-encounters.furnishings.table.flask: required ingredient")
	if not o.consumables.has(&"life-potion"):
		o.errors.append("initial-encounters.furnishings.table.potion: required consumable")


static func spirit_references(o) -> void:
	for id in ["spirit-fire", "spirit-unholy", "spirit-ice", "spirit-wind"]:
		if not o.materials.has(id) or o.materials[id].raw.get("kind") != "spirit":
			o.errors.append("initial-encounters.spirits: missing spirit " + id)


static func selected_policy_values(o, row: Variant, selected: Dictionary, path: String) -> void:
	for field in selected:
		if not o._is_selected_multiplier(
			row.get(field) if row is Dictionary else null, selected[field]
		):
			o.errors.append(
				"design." + path + "." + field + ": must equal selected " + str(selected[field])
			)
