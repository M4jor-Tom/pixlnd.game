## Ordered equipment validation.
extends RefCounted
const Slots := preload("res://ontology/model_slots.gd")


static func validate_gear_inputs(o, design: Dictionary) -> bool:
	var gear_hp: Variant = design.get("gear-hp")
	if not gear_hp is Dictionary:
		o.errors.append("design.gear-hp: required object missing or malformed")
	else:
		var hp_inputs = {"curve-mult": 5.0, "base": 2.0, "upgrade-step": 0.1}
		for field in hp_inputs:
			if not o._is_selected_multiplier(gear_hp.get(field), hp_inputs[field]):
				o.errors.append(
					"design.gear-hp.%s: must equal selected %s" % [field, hp_inputs[field]]
				)
	return o._validate_hp_materials(design)


static func validate_hp_slots(o, design: Dictionary) -> bool:
	var slot_multipliers = {
		"chest": 1.0,
		"gloves": 0.5,
		"boots": 0.5,
		"shoulders": 0.5,
		"main-hand": 0.5,
		"off-hand": 0.5
	}
	var slot_config: Variant = o.configs.get("equipment-slots", {})
	var equipment_slots: Variant = slot_config.get("slots", []) if slot_config is Dictionary else []
	var found_slots: Dictionary = {}
	if equipment_slots is Array:
		for slot in equipment_slots:
			hp_slot(o, slot, slot_multipliers, found_slots)
	for id in slot_multipliers:
		if not found_slots.has(id):
			o.errors.append("equipment-slots.slots.%s: required HP-bearing slot missing" % id)
	return o._validate_loot(design)


static func material_multiplier(
	o, id, raw: Dictionary, field: String, expected: float, label: String
) -> void:
	if not o._is_selected_multiplier(raw.get(field), expected):
		missing_material_multiplier(o, id, field, expected, label)


static func missing_material_multiplier(
	o, id, field: String, expected: float, label: String
) -> void:
	o.errors.append("material %s.raw.%s: must equal selected %s %s" % [id, field, label, expected])


static func validate_slots(o) -> bool:
	return Slots.validate_slots(o)


static func validate_wand_recipe(o) -> bool:
	var recipe_cfg: Variant = o.configs.get("recipes")
	if not recipe_cfg is Dictionary:
		o.errors.append("recipes: required object missing or malformed")
	var gear_recipes: Variant = recipe_cfg.get("gear-weapons") if recipe_cfg is Dictionary else null
	if not gear_recipes is Dictionary:
		o.errors.append("recipes.gear-weapons: required object missing or malformed")
	wand_recipe_row(o, gear_recipes)

	return true


static func validate_loot(o, design: Dictionary, legendary: int) -> bool:
	var loot_start = o.errors.size()
	o._selected_tree(
		design.get("loot"),
		{
			"coins": {"chance": 0.6, "base": 1, "per-level": 2},
			"gear-chance": 0.2,
			"consumable-chance": 0.15,
			"species-drop-chance": 0.5,
			"level-spread": 1,
			"boss-rarity-shift": 1,
			"rarity-weights": {"common": 60, "uncommon": 25, "rare": 10, "epic": 4, "legendary": 1},
			"gear-kinds":
			{"weapon": 4, "chest-armor": 2, "gloves": 2, "boots": 2, "shoulder-armor": 2},
			"consumable-pool": ["life-potion", "apple", "pineapple-slice"],
			"ground":
			{"lifetime-s": 60480, "pickup-radius": 2, "auto-pickup": ["coin"], "scatter": 1}
		},
		"design.loot"
	)
	if o.errors.size() == loot_start:
		loot_references(o, design, legendary)
	return o._validate_reward_catalogs(design)


static func reward_prerequisites(o) -> void:
	for id in ["emerald", "sapphire", "ruby", "diamond", "glass-flask"]:
		if not o._object(o.configs.get("ingredients")).has(id):
			o.errors.append("initial-encounters.mission-package: required ingredient " + id)
	if o.classes.size() != 4:
		o.errors.append("initial-encounters.rewards: require four classes")


static func reward_class_exists(o, id: String) -> bool:
	if not o.classes.has(id):
		o.errors.append("initial-encounters.rewards: required class " + id)
		return false
	return true


static func reward_class(o, id: String, armor_material: StringName, weapons: Array) -> void:
	if not o.materials.has(armor_material):
		o.errors.append("initial-encounters.rewards: illegal armor material for " + id)
	if weapons.is_empty():
		o.errors.append("initial-encounters.rewards: empty weapon pool for " + id)
	reward_weapons(o, weapons)


static func class_owned(hands: int, none: int, owner: StringName, classes: Dictionary) -> bool:
	return hands != none and owner in classes


static func class_lists_weapon(owned: bool, weapons: Array, id) -> bool:
	if weapons.has(StringName(id)):
		return true
	return owned


static func weapon_active(o, id, raw: Dictionary, owned: bool, hands: int, none: int) -> bool:
	if owned and unsupported_hands(raw):
		o.errors.append("weapon %s: hands must be a supported active weapon value" % id)
	if hands == none or raw.get("usable", true) == false:
		if owned:
			o.errors.append("weapon %s: active class weapon requires usable hands" % id)
		return false
	return true


static func weapon_owner_exists(o, id, raw: Dictionary, active: bool) -> bool:
	if not active:
		return false
	var owner: Variant = raw.get("class")
	if owner is String:
		return named_weapon_owner(o, id, owner)
	o.errors.append("weapon %s: owning class required" % id)
	return false


static func weapon_owner_lists(o, id, owner, weapons: Array) -> void:
	if not weapons.has(StringName(id)):
		o.errors.append("weapon %s: class %s does not list weapon" % [id, owner])


static func weapon_capacity_material(
	o,
	id,
	raw: Dictionary,
	owned: bool,
	hands: int,
	vocabulary: Dictionary,
	max_1h: int,
	max_2h: int
) -> void:
	if not owned:
		return
	var expected := max_2h if hands in [vocabulary.TWO_HANDED, vocabulary.OFFHAND] else max_1h
	if not o._is_selected_multiplier(raw.get("cube-capacity"), expected):
		o.errors.append("weapon %s: capacity must match hands" % id)
	weapon_material(o, id, raw)


static func apple_input(o) -> void:
	var apple: Dictionary = o._object(o._object(o.configs.get("consumables")).get("apple"))
	if not o._is_selected_multiplier(apple.get("heal-mult"), 20):
		o.errors.append("consumables.apple.heal-mult: required numeric 20")


static func apple_loaded(o, raw: Dictionary, coefficient: int) -> void:
	if not o._is_selected_multiplier(raw.get("heal-mult"), 20):
		o.errors.append("consumables.apple.heal-mult: loaded raw must equal numeric 20")
	if coefficient != 20:
		o.errors.append("consumables.apple.heal-mult: loaded coefficient must equal 20")


static func wand_definition(o, wand, two_handed: int, capacity: int) -> bool:
	if not wand_selected(wand, two_handed, capacity):
		o.errors.append("weapon wand: selected mechanical 2h / 32-cube definition required")
	return validate_wand_recipe(o)


static func hp_slot(o, slot: Variant, multipliers: Dictionary, found: Dictionary) -> void:
	if slot is Dictionary and multipliers.has(str(slot.get("id", ""))):
		var id = str(slot["id"])
		if found.has(id):
			o.errors.append("equipment-slots.slots.%s: duplicate HP-bearing slot" % id)
		found[id] = true
		if not o._is_selected_multiplier(slot.get("hp-mult"), multipliers[id]):
			o.errors.append(
				(
					"equipment-slots.slots.%s.hp-mult: must equal selected multiplier %s"
					% [id, multipliers[id]]
				)
			)


static func loot_references(o, design: Dictionary, legendary: int) -> void:
	var loot: Dictionary = design.loot
	loot_rarities(o, loot, legendary)
	var types_input: Variant = o.configs.get("item-types")
	var types: Dictionary = types_input if types_input is Dictionary else {}
	var stack_cap: Variant = design.get("stack-cap", {})
	if not stack_cap is Dictionary:
		o.errors.append("design.stack-cap: object required")
		stack_cap = {}
	var stackable: Variant = stack_cap.get("stackable", [])
	if not stackable is Array:
		o.errors.append("design.stack-cap.stackable: array required")
		stackable = []
	loot_item_types(o, loot, stackable, types)
	loot_consumables(o, loot)


static func unsupported_hands(raw: Dictionary) -> bool:
	return (
		not raw.get("hands") is String
		or raw.get("hands") not in ["1h", "2h", "offhand", "1h dual (need two)"]
	)


static func named_weapon_owner(o, id, owner: String) -> bool:
	if owner.is_empty():
		o.errors.append("weapon %s: owning class required" % id)
	elif owner != "any":
		if not o.classes.has(owner):
			o.errors.append("weapon %s: unknown class %s" % [id, owner])
		else:
			return true
	return false


static func weapon_material(o, id, raw: Dictionary) -> void:
	var material_text := str(raw.get("material", ""))
	if material_text.is_empty():
		o.errors.append("weapon %s: material required" % id)
	else:
		for option in material_text.split("|"):
			var material_id := StringName(option.strip_edges().split(" ")[0])
			if not o.materials.has(material_id):
				o.errors.append("weapon %s: unknown material %s" % [id, material_id])


static func wand_selected(wand, two_handed: int, capacity: int) -> bool:
	return (
		wand != null
		and wand.hands == two_handed
		and wand.cube_capacity == capacity
		and wand_hands(wand.raw)
	)


static func wand_hands(raw: Dictionary) -> bool:
	return raw.get("hands") is String and raw["hands"] == "2h"


static func wand_recipe_inputs(o, recipe: Dictionary) -> void:
	var inputs: Variant = recipe.get("inputs")
	if not selected_wood_input(inputs):
		o.errors.append("recipes.gear-weapons.wand.inputs.wood-cube: must be 20")
	if recipe.get("station") != "workbench":
		o.errors.append("recipes.gear-weapons.wand.station: must be workbench")


static func selected_wood_input(inputs: Variant) -> bool:
	return inputs is Dictionary and numeric_twenty(inputs.get("wood-cube"))


static func numeric_twenty(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == 20.0


static func wand_recipe_row(o, gear_recipes: Variant) -> void:
	var wand_recipe: Variant = gear_recipes.get("wand") if gear_recipes is Dictionary else null
	if not wand_recipe is Dictionary:
		o.errors.append("recipes.gear-weapons.wand: required recipe row missing")
	else:
		wand_recipe_inputs(o, wand_recipe)


static func reward_weapons(o, weapons: Array) -> void:
	for type_id in weapons:
		if not o.weapon_types.has(type_id):
			continue
		reward_weapon_material(o, type_id, o.weapon_types[type_id].raw.get("material"))


static func reward_weapon_material(o, type_id, raw: Variant) -> void:
	if not raw is String or not o.materials.has(raw.split(" ")[0].split("|")[0]):
		o.errors.append("initial-encounters.rewards: missing weapon material " + str(type_id))


static func loot_rarities(o, loot: Dictionary, legendary: int) -> void:
	for id in loot["rarity-weights"]:
		if not o.rarities.has(id) or o.rarities[id].index > legendary:
			o.errors.append("design.loot.rarity-weights: bad rarity " + id)


static func loot_item_types(o, loot: Dictionary, stackable: Array, types: Dictionary) -> void:
	for id in loot["gear-kinds"].keys() + stackable:
		if not types.has(id):
			o.errors.append("design.loot/stack-cap: unknown item-type %s" % str(id))


static func loot_consumables(o, loot: Dictionary) -> void:
	for id in loot["consumable-pool"]:
		if not o.consumables.has(id):
			o.errors.append("design.loot.consumable-pool: unknown consumable " + id)
