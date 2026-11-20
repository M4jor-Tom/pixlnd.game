## Current-rule JSON boundary. Validate before publishing nodes AND before replacing the original save.
## Same-directory temp + flush + rename; no legacy migration, offline catch-up or corrupt-save fallback.
extends RefCounted
const Domain := preload("res://game/domain/domain.gd")
const Item := preload("res://game/items/item.gd")
const Rewards := preload("res://game/items/encounter_rewards.gd")
const Shop := preload("res://game/items/shop.gd")
const Items := preload("res://game/items/items.gd")
const Inventory := preload("res://game/items/inventory.gd")
const SkillTree := preload("res://game/progression/skill_tree.gd")
const Combat := preload("res://game/combat/combat.gd")
const EncounterGen := preload("res://game/world/encounter_gen.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
const CharacterRules := preload("res://game/world/save_character_rules.gd")
const WorldRules := preload("res://game/world/save_world_rules.gd")
const SiteRules := preload("res://game/world/save_site_rules.gd")
const FeatureRules := preload("res://game/world/save_feature_rules.gd")
const RewardRules := preload("res://game/world/save_reward_rules.gd")
var _geography

var o
var design: Dictionary
var errors: Array[String] = []


func _init(ontology, p_design: Dictionary) -> void:
	o = ontology
	design = p_design


static func item_data(it) -> Dictionary:
	return {
		"type": str(it.type),
		"subtype": str(it.subtype),
		"material": str(it.material),
		"rarity": it.rarity,
		"level": it.level,
		"upgrade_count": it.upgrade_count,
		"modifier": it.modifier,
		"minus_modifier": it.minus_modifier,
		"count": it.count
	}


static func item_from(data: Dictionary):
	var it := Item.new()
	it.type = StringName(data.type)
	it.subtype = StringName(data.subtype)
	it.material = StringName(data.material)
	for field in ["rarity", "level", "upgrade_count", "modifier", "minus_modifier", "count"]:
		it.set(field, int(data[field]))
	return it


func capture(world, player) -> Dictionary:
	world.characters[player.logical_id] = {
		"position": player.logical_position(), "respawn": player.logical_respawn()
	}
	var equipment := {}
	for slot in player.inventory.equipment:
		equipment[str(slot)] = item_data(player.inventory.equipment[slot])
	return {
		"version": 1,
		"world": world.snapshot(),
		"character":
		{
			"id": player.logical_id,
			"class_id": str(player.inventory.class_id),
			"spec": str(player.spec),
			"level": player.level,
			"xp": player.xp,
			"banked": player.skill_points,
			"points": player.skill_tree.points.duplicate(),
			"coins": player.inventory.coins,
			"bag": player.inventory.entries.map(item_data),
			"equipment": equipment
		}
	}


func restore_player(player, c: Dictionary, world: Dictionary) -> void:
	player.logical_id = c.id
	player.level = int(c.level)
	player.xp = int(c.xp)
	player.skill_points = int(c.banked)
	# setup_items must have been called with the validated class/spec, before the hero is published.
	player.skill_tree.points.clear()
	for id in c.points:
		player.skill_tree.points[StringName(id)] = int(c.points[id])
	player.inventory.entries = c.bag.map(item_from)
	player.inventory.equipment.clear()
	for slot in c.equipment:
		player.inventory.equipment[StringName(slot)] = item_from(c.equipment[slot])
	player.inventory.coins = int(c.coins)
	player._base_max_hp = Combat.player_max_hp(player.level, player.hp_mult)
	player._refresh_gear()
	player.hp = player.max_hp
	player.set_logical_position(world.characters[c.id].position)
	player.set_logical_respawn(world.characters[c.id].respawn)


func write_atomic(path: String, data: Dictionary) -> bool:
	if not validate(data):
		return false
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		errors.append("save temp open: " + error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "", true, true))
	file.flush()
	var status := file.get_error()
	file.close()
	if status != OK:
		errors.append("save temp write: " + error_string(status))
		return false
	status = DirAccess.rename_absolute(tmp, path)
	if status != OK:
		errors.append("save atomic rename: " + error_string(status))
		return false
	return true


func load_file(path: String) -> Dictionary:
	errors.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("save open: " + error_string(FileAccess.get_open_error()))
		return {}
	var json := JSON.new()
	var status := json.parse(file.get_as_text())
	file.close()
	if status != OK:
		errors.append("save JSON line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return {}
	if not validate(json.data):
		return {}
	return json.data


static func number(value: Variant, minimum: float = 0) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum


static func integer(value: Variant, minimum: int = 0) -> bool:
	return (
		number(value, minimum)
		and float(value) < 9223372036854775808.0
		and float(value) == floorf(float(value))
	)  # native signed integer storage


static func text(value: Variant) -> bool:
	return value is String and not value.is_empty()


func require(ok: bool, path: String) -> bool:
	if not ok:
		errors.append(path + ": missing, malformed or rule-invalid")
	return ok


func position(value: Variant, path: String) -> bool:
	if not require(value is Array and value.size() == 3, path):
		return false
	if not _position_coordinates(value, path):
		return false
	var limit: float = (
		float(design.terrain["land-blocks"]) * float(design.terrain["lands-per-axis"]) / 2
	)
	return _inside_world(value, limit, path)


func validate(data: Variant) -> bool:
	errors.clear()
	if not require(data is Dictionary, "save"):
		return false
	require(data.get("version") == 1 and integer(data.get("version")), "save.version")
	var w: Variant = data.get("world")
	var c: Variant = data.get("character")
	if require(w is Dictionary, "world"):
		validate_world(w)
	if require(c is Dictionary, "character"):
		validate_character(c)
	if _character_link(w, c):
		require(w.characters.has(c.id), "world.characters." + c.id)
	return errors.is_empty()


func validate_character(c: Dictionary) -> void:
	CharacterRules.validate_character(self, c)


func validate_item(row: Variant, path: String) -> bool:
	return CharacterRules.validate_item(self, row, path)


func validate_world(w: Dictionary) -> void:
	WorldRules.validate_world(self, w)


func validate_mob(m: Variant, path: String) -> void:
	WorldRules.validate_mob(self, m, path)


func validate_combat(r: Variant, path: String) -> void:
	WorldRules.validate_combat(self, r, path)


static func coordinate_pair(value: String, extent: int) -> bool:
	var parts := value.split(",")
	if parts.size() != 2:
		return false
	for part in parts:
		if _invalid_coordinate(part, extent):
			return false
	return true


func ambient_identity(id: Variant, world_id: String) -> bool:
	return WorldRules.ambient_identity(self, id, world_id)


func site_identity(id: String, world_id: String, family: Variant) -> bool:
	return WorldRules.site_identity(self, id, world_id, family)


func validate_ambient_stats(m: Dictionary, path: String) -> void:
	WorldRules.validate_ambient_stats(self, m, path)


func validate_site_content(site: Dictionary, layout: Dictionary, clock: float) -> void:
	SiteRules.validate_site_content(self, site, layout, clock)


func validate_special(value: Variant, path: String, kind: String) -> void:
	SiteRules.validate_special(self, value, path, kind)


func validate_features(site: Dictionary, layout: Dictionary, clock: float) -> void:
	FeatureRules.validate_features(self, site, layout, clock)


func validate_rewards(site: Dictionary, layout: Dictionary) -> void:
	RewardRules.validate_rewards(self, site, layout)


func validate_vendors(w: Dictionary) -> void:
	RewardRules.validate_vendors(self, w)


## Absolute serialization tolerance, never relative world-coordinate tolerance (which grows at world edges).
static func same_data(value: Variant, expected: Variant) -> bool:
	if expected is int or expected is float:
		return _same_number(value, expected)
	if expected is Dictionary:
		return _same_dictionary(value, expected)
	if expected is Array:
		return _same_array(value, expected)
	return typeof(value) == typeof(expected) and value == expected


static func _finite_coordinate(n: Variant) -> bool:
	return (n is int or n is float) and is_finite(float(n))


func _inside_world(value: Array, limit: float, path: String) -> bool:
	return require(
		value[0] >= -limit and value[0] < limit and value[2] >= -limit and value[2] < limit,
		path + ".world-bounds"
	)


static func _character_link(w: Variant, c: Variant) -> bool:
	return (
		w is Dictionary
		and c is Dictionary
		and c.get("id") is String
		and w.get("characters") is Dictionary
	)


static func _invalid_coordinate(part: String, extent: int) -> bool:
	return (
		not part.is_valid_int()
		or str(int(part)) != part
		or int(part) < -extent
		or int(part) >= extent
	)


static func _same_dictionary(value: Variant, expected: Dictionary) -> bool:
	if not value is Dictionary or value.size() != expected.size():
		return false
	return _dictionary_values(value, expected)


static func _same_array(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size():
		return false
	return _array_values(value, expected)


static func _same_number(value: Variant, expected: Variant) -> bool:
	return number(value, -INF) and absf(float(value) - float(expected)) < 0.000001


func _position_coordinates(value: Array, path: String) -> bool:
	for n in value:
		if not require(_finite_coordinate(n), path):
			return false
	return true


static func _dictionary_values(value: Dictionary, expected: Dictionary) -> bool:
	for key in expected:
		if not value.has(key) or not same_data(value[key], expected[key]):
			return false
	return true


static func _array_values(value: Array, expected: Array) -> bool:
	for i in expected.size():
		if not same_data(value[i], expected[i]):
			return false
	return true


# Keep extracted instance phases on the original bare-static receiver, including subclasses.
func _number(value: Variant, minimum: float = 0) -> bool:
	return number(value, minimum)


func _integer(value: Variant, minimum: int = 0) -> bool:
	return integer(value, minimum)


func _text(value: Variant) -> bool:
	return text(value)


func _coordinate_pair(value: String, extent: int) -> bool:
	return coordinate_pair(value, extent)


func _same_data(value: Variant, expected: Variant) -> bool:
	return same_data(value, expected)


func _item_data(it) -> Dictionary:
	return item_data(it)


func _validate_equipment_item(c: Dictionary, slot: Variant, inv) -> bool:
	var row: Variant = c.equipment[slot]
	if not validate_item(row, "character.equipment." + str(slot)):
		return true
	var it = item_from(row)
	var expected := Items.slot_id(it, o)
	if expected != &"" and inv.class_allowed(it):
		return _matching_equipment_slot(inv, it, slot, expected)
	require(false, "character.equipment." + str(slot) + " slot/class")
	inv.equipment[StringName(slot)] = it
	return true


func _validate_bag_item(inv, row: Variant) -> bool:
	if validate_item(row, "character.bag"):
		inv.entries.append(item_from(row))
	return true


func _validate_weapon_item(row: Variant, path: String) -> bool:
	require(row.level <= 100, path + ".power")
	require(
		o.weapon_types.has(row.subtype) and Items.weapon_material_allowed(item_from(row), o),
		path + ".weapon/material"
	)
	return true


func _matching_equipment_slot(inv, it, slot: Variant, expected: StringName) -> bool:
	var valid: bool = (
		str(expected) == str(slot)
		or (expected == &"ring-left" and slot == "ring-right")
		or (expected == &"main-hand" and slot == "off-hand")
	)
	require(valid, "character.equipment." + str(slot) + " slot/class")
	inv.equipment[StringName(slot)] = it
	return true
