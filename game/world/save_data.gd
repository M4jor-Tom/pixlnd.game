## Current-rule JSON boundary. Validate before publishing nodes AND before replacing the original save.
## Same-directory temp + flush + rename; no legacy migration, offline catch-up or corrupt-save fallback.
extends RefCounted
const Model := preload("res://ontology/model.gd")
const Item := preload("res://game/items/item.gd")
const Rewards := preload("res://game/items/encounter_rewards.gd")
const Shop := preload("res://game/items/shop.gd")
const Items := preload("res://game/items/items.gd")
const Inventory := preload("res://game/items/inventory.gd")
const SkillTree := preload("res://game/progression/skill_tree.gd")
const Combat := preload("res://game/combat/combat.gd")
const EncounterGen := preload("res://game/world/encounter_gen.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
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
	for n in value:
		if not require((n is int or n is float) and is_finite(float(n)), path):
			return false
	var limit: float = (
		float(design.terrain["land-blocks"]) * float(design.terrain["lands-per-axis"]) / 2
	)
	return require(
		value[0] >= -limit and value[0] < limit and value[2] >= -limit and value[2] < limit,
		path + ".world-bounds"
	)


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
	if (
		w is Dictionary
		and c is Dictionary
		and c.get("id") is String
		and w.get("characters") is Dictionary
	):
		require(w.characters.has(c.id), "world.characters." + c.id)
	return errors.is_empty()


func validate_character(c: Dictionary) -> void:
	require(text(c.get("id")), "character.id")
	var cls: Variant = c.get("class_id")
	var spec: Variant = c.get("spec")
	if not require(cls is String and o.classes.has(cls), "character.class_id"):
		return
	if not require(
		spec is String and o.specs.has(spec) and o.specs[spec].character_class == StringName(cls),
		"character.spec"
	):
		return
	if require(integer(c.get("level"), 1) and integer(c.get("xp")), "character.level/xp"):
		require(c.xp < Model.xp_to_next(int(c.level)), "character.xp settled")
	require(integer(c.get("coins")), "character.coins")
	if require(integer(c.get("banked")) and c.get("points") is Dictionary, "character.skills"):
		var tree := SkillTree.new(o, design["skill-point"], StringName(cls), StringName(spec))
		for id in c.points:
			if (
				require(id is String or id is StringName, "character.points.id")
				and require(integer(c.points[id], 1), "character.points." + str(id))
			):
				var found := false
				for a in tree.nodes:
					if a.id == StringName(id):
						found = true
				require(found, "character.points." + str(id))
				tree.points[StringName(id)] = c.points[id]
		var spent := 0
		for a in tree.nodes:
			spent += tree.spent(a.id)
			if tree.spent(a.id) > 0:
				require(tree.is_open(a), "character.points prerequisite " + str(a.id))
		if integer(c.get("level"), 1):
			require(
				c.banked + spent == (c.level - 1) * Model.SKILL_POINTS_PER_LEVEL,
				"character.skill point total"
			)
	var inv := Inventory.new(o, design, StringName(cls), func(): return int(c.level))
	if require(c.get("bag") is Array, "character.bag"):
		for row in c.bag:
			if validate_item(row, "character.bag"):
				inv.entries.append(item_from(row))
	if require(c.get("equipment") is Dictionary, "character.equipment"):
		for slot in c.equipment:
			var row: Variant = c.equipment[slot]
			if not validate_item(row, "character.equipment." + str(slot)):
				continue
			var it = item_from(row)
			var expected := Items.slot_id(it, o)
			require(
				(
					expected != &""
					and inv.class_allowed(it)
					and (
						str(expected) == str(slot)
						or (expected == &"ring-left" and slot == "ring-right")
						or (expected == &"main-hand" and slot == "off-hand")
					)
				),
				"character.equipment." + str(slot) + " slot/class"
			)
			inv.equipment[StringName(slot)] = it
		var main = inv.equipment.get(&"main-hand")
		var off = inv.equipment.get(&"off-hand")
		if (main == null or main.type == &"weapon") and (off == null or off.type == &"weapon"):
			require(inv._loadout_valid(main, off), "character.equipment hand loadout")
		else:
			require(false, "character.equipment hand types")


func validate_item(row: Variant, path: String) -> bool:
	var start := errors.size()
	if not require(row is Dictionary, path):
		return false
	for field in ["type", "subtype", "material"]:
		require(row.get(field) is String or row.get(field) is StringName, path + "." + field)
	for field in ["rarity", "upgrade_count", "modifier", "minus_modifier"]:
		require(integer(row.get(field)), path + "." + field)
	require(integer(row.get("level"), 1) and integer(row.get("count"), 1), path + ".level/count")
	if errors.size() != start:
		return false
	require(row.rarity <= Model.Rarity.LEGENDARY, path + ".rarity")
	require(row.type in design["stack-cap"].stackable or row.count == 1, path + ".stack")
	match str(row.type):
		"weapon":
			require(
				(
					o.weapon_types.has(row.subtype)
					and Items.weapon_material_allowed(item_from(row), o)
				),
				path + ".weapon/material"
			)
		"chest-armor", "gloves", "boots", "shoulder-armor", "ring", "amulet":
			require(o.materials.has(row.material), path + ".material")
		"consumable":
			require(o.consumables.has(row.subtype), path + ".consumable")
		"ingredient":
			require(
				(
					o.configs["ingredients"].has(row.subtype)
					or (
						o.materials.has(row.subtype)
						and o.materials[row.subtype].raw.get("kind") == "spirit"
					)
				),
				path + ".ingredient"
			)
		"coin":
			require(row.subtype == "" and row.material == "", path + ".coin")
		"pet-food":
			require(o.pet_foods.has(row.subtype), path + ".pet-food")
		_:
			require(false, path + ".implemented item type")
	return errors.size() == start


func validate_world(w: Dictionary) -> void:
	if not require(text(w.get("world_id")) and not "/" in w.world_id, "world.world_id"):
		return
	require(number(w.get("seed"), -INF) and float(w.seed) == floorf(float(w.seed)), "world.seed")
	for field in ["clock", "elapsed"]:
		require(number(w.get(field)), "world." + field)
	if require(w.get("characters") is Dictionary, "world.characters"):
		for id in w.characters:
			var c: Variant = w.characters[id]
			if require(text(id) and c is Dictionary, "world.character"):
				position(c.get("position"), "world.character.position")
				position(c.get("respawn"), "world.character.respawn")
	if require(w.get("mobs") is Dictionary, "world.mobs"):
		for id in w.mobs:
			if require(ambient_identity(id, w.world_id), "world.mob.identity"):
				validate_mob(w.mobs[id], "world.mobs." + id)
				var mob: Variant = w.mobs[id]
				if mob is Dictionary:
					require(mob.get("pack") == id.get_base_dir(), "world.mob.pack identity")
					var species = o.creatures.get(mob.get("species"))
					if species != null:
						var role := str(species.combat_role)
						if role != "any-class":
							require(
								(
									mob.get("role")
									== (
										role
										if design["creature-roles"].has(role)
										else str(design["creature-roles"].default)
									)
								),
								"world.mob.species role"
							)
						var maximum: int = (
							int(design.spawns["default-group"][1])
							if species.group_size == Vector2i(1, 1)
							else species.group_size.y
						)
						require(int(id.get_file()) < maximum, "world.mob.member count")
					validate_ambient_stats(mob, "world.mobs." + id)
	var expected_sites := {}
	if require(w.get("lands") is Dictionary, "world.lands"):
		if _geography == null or _geography.world_seed != int(w.seed):
			_geography = WorldGen.new(int(w.seed), design, o.landscapes)
		for key in w.lands:
			if not require(
				key is String and coordinate_pair(key, int(design.terrain["lands-per-axis"]) / 2),
				"world.land.identity"
			):
				continue
			var xy: PackedStringArray = key.split(",")
			var plan_: Dictionary = _geography.encounters_at(
				_geography.land_at(Vector2i(int(xy[0]), int(xy[1])))
			)
			if not require(
				not plan_.is_empty() and same_data(w.lands[key], plan_),
				"world.land.joint geography/assignments"
			):
				continue
			for layout in plan_.sites:
				var id: String = (
					"%s/site/%s/%s/%d" % [w.world_id, key, layout.family, layout.ordinal]
				)
				expected_sites[id] = layout
	if require(w.get("sites") is Dictionary, "world.sites"):
		require(
			w.sites.size() == expected_sites.size(), "world.sites complete six per generated land"
		)
		for id in w.sites:
			var s: Variant = w.sites[id]
			if not require(
				(
					s is Dictionary
					and s.get("id") == id
					and id is String
					and id.begins_with(w.world_id + "/site/")
				),
				"world.site.identity"
			):
				continue
			require(
				site_identity(id, w.world_id, s.get("family")), "world.site.family/ordinal/land"
			)
			if require(expected_sites.has(id), "world.site registered joint land"):
				validate_site_content(
					s, expected_sites[id], float(w.clock) if number(w.get("clock")) else 0.0
				)
				validate_rewards(s, expected_sites[id])
			for flag in ["pending", "cleared", "completed"]:
				require(s.get(flag) is bool, "world.site." + flag)
			require(integer(s.get("cycle")), "world.site.cycle")
			if require(
				s.get("volumes") is Array and not s.volumes.is_empty(), "world.site.volumes"
			):
				for v in s.volumes:
					if not require(v is Array and v.size() == 6, "world.site.volume"):
						continue
					if (
						position(v.slice(0, 3), "world.site.volume.min")
						and position(v.slice(3, 6), "world.site.volume.max")
					):
						require(
							v[0] <= v[3] and v[1] <= v[4] and v[2] <= v[5],
							"world.site.volume.order"
						)
			if require(s.get("mobs") is Dictionary, "world.site.mobs"):
				for mob_id in s.mobs:
					if require(
						mob_id is String and mob_id.begins_with(id + "/"), "world.site.mob.identity"
					):
						validate_mob(s.mobs[mob_id], "world.site.mob")
			if require(s.get("rewards") is Dictionary, "world.site.rewards"):
				for reward in s.rewards.values():
					if not require(
						(
							reward is Dictionary
							and reward.get("delivered") is bool
							and reward.get("payload") is Array
						),
						"world.site.reward"
					):
						continue
					for item in reward.payload:
						validate_item(item, "world.site.reward.item")

	validate_vendors(w)


func validate_mob(m: Variant, path: String) -> void:
	if not require(m is Dictionary, path):
		return
	require(m.get("species") is String and o.creatures.has(m.species), path + ".species")
	require(
		(
			integer(m.get("level"), 1)
			and (number(m.get("max_hp")) and m.max_hp > 0)
			and number(m.get("damage"))
			and number(m.get("hp"))
			and m.hp <= m.max_hp
		),
		path + ".stats"
	)
	require(
		m.get("hostility") in ["H", "N", "P", "F"] and m.get("role") in ["melee", "ranged", "mage"],
		path + ".hostility/role"
	)
	position(m.get("home"), path + ".home")
	position(m.get("position"), path + ".position")
	require(
		integer(m.get("seed")) and integer(m.get("cycle")) and text(m.get("pack")),
		path + ".generation"
	)
	for flag in ["dead", "eligible"]:
		require(m.get(flag) is bool, path + "." + flag)
	validate_combat(m.get("combat"), path + ".combat")


func validate_combat(r: Variant, path: String) -> void:
	if not require(r is Dictionary, path):
		return
	for field in ["threat", "order", "provoked"]:
		if not require(r.get(field) is Dictionary, path + "." + field):
			return
	require(
		integer(r.get("next_order")) and number(r.get("taunt_left")) and r.get("returning") is bool,
		path + ".timers/order"
	)
	for field in ["current", "taunt"]:
		require(r.get(field) is String, path + "." + field)
	var seen := {}
	for id in r.threat:
		require(text(id) and number(r.threat[id]) and r.threat[id] > 0, path + ".threat")
		var order: Variant = r.order.get(id)
		if require(integer(order), path + ".order"):
			require(
				not seen.has(order) and integer(r.get("next_order")) and order < r.next_order,
				path + ".order uniqueness"
			)
			seen[order] = true
	require(r.order.size() == r.threat.size(), path + ".order cardinality")
	for id in r.provoked:
		require(text(id) and r.provoked[id] == true, path + ".provoked")


static func coordinate_pair(value: String, extent: int) -> bool:
	var parts := value.split(",")
	if parts.size() != 2:
		return false
	for part in parts:
		if (
			not part.is_valid_int()
			or str(int(part)) != part
			or int(part) < -extent
			or int(part) >= extent
		):
			return false
	return true


func ambient_identity(id: Variant, world_id: String) -> bool:
	if not id is String:
		return false
	var p: PackedStringArray = id.split("/")
	if p.size() != 5 or p[0] != world_id or p[1] != "ambient":
		return false
	var extent := (
		int(design.terrain["land-blocks"])
		* int(design.terrain["lands-per-axis"])
		/ (2 * int(design.terrain["zone-blocks"]))
	)
	return (
		coordinate_pair(p[2], extent)
		and p[3].is_valid_int()
		and str(int(p[3])) == p[3]
		and int(p[3]) >= 0
		and int(p[3]) < int(design.spawns["groups-per-zone"][1])
		and p[4].is_valid_int()
		and str(int(p[4])) == p[4]
		and int(p[4]) >= 0
	)


func site_identity(id: String, world_id: String, family: Variant) -> bool:
	var p: PackedStringArray = id.split("/")
	if (
		p.size() != 5
		or p[0] != world_id
		or p[1] != "site"
		or p[3] != family
		or family not in ["ruins", "camp", "supplier"]
	):
		return false
	if (
		not coordinate_pair(p[2], int(design.terrain["lands-per-axis"]) / 2)
		or not p[4].is_valid_int()
		or str(int(p[4])) != p[4]
	):
		return false
	return int(p[4]) >= 0 and int(p[4]) < (4 if family == "supplier" else 1)


func validate_ambient_stats(m: Dictionary, path: String) -> void:
	var pb: Variant = m.get("power_base")
	if not require(
		(
			number(pb, -INF)
			and pb >= design["enemy-hp"]["power-base"][0]
			and pb <= design["enemy-hp"]["power-base"][1]
		),
		path + ".power_base"
	):
		return
	if not integer(m.get("level"), 1) or not number(m.get("max_hp")) or not number(m.get("damage")):
		return
	require(
		(
			is_equal_approx(m.max_hp, Combat.enemy_max_hp(int(m.level), pb))
			and is_equal_approx(m.damage, Combat.enemy_damage(int(m.level), pb, design.combat))
		),
		path + ".NPC curves"
	)
	if m.get("dead") is bool and number(m.get("hp")):
		require(m.dead == (m.hp == 0), path + ".life state")


## Absolute serialization tolerance, never relative world-coordinate tolerance (which grows at world edges).
static func same_data(value: Variant, expected: Variant) -> bool:
	if expected is int or expected is float:
		return number(value, -INF) and absf(float(value) - float(expected)) < 0.000001
	if expected is Dictionary:
		if not value is Dictionary or value.size() != expected.size():
			return false
		for key in expected:
			if not value.has(key) or not same_data(value[key], expected[key]):
				return false
		return true
	if expected is Array:
		if not value is Array or value.size() != expected.size():
			return false
		for i in expected.size():
			if not same_data(value[i], expected[i]):
				return false
		return true
	return typeof(value) == typeof(expected) and value == expected


func validate_site_content(site: Dictionary, layout: Dictionary, clock: float) -> void:
	require(
		same_data(site.get("volumes"), layout.volumes), "world.site.exact closed playable union"
	)
	validate_features(site, layout, clock)
	if not require(site.get("mobs") is Dictionary, "world.site.mobs"):
		return
	require(site.mobs.size() == layout.assignments.size(), "world.site.exact designated count")
	var spirits: Variant = site.get("spirit_levels")
	var spirit_count := 0
	for stable in layout.assignments:
		var id: String = site.id + "/" + stable.key
		var m: Variant = site.mobs.get(id)
		if not require(m is Dictionary, "world.site.designated identity " + id):
			continue
		require(
			m.get("species") == design["initial-encounters"].species and m.get("hostility") == "H",
			"world.site.skeleton hostility"
		)
		for field in ["home", "role", "seed"]:
			require(same_data(m.get(field), stable[field]), "world.site.stable " + field)
		require(m.get("pack") == site.id + "/" + stable.pack, "world.site.generated pack")
		var power: float = (
			float(design["initial-encounters"]["power-base-offset"]) + int(stable.tier)
		)
		require(m.get("power_base") == power, "world.site.local power")
		if integer(m.get("level"), 1):
			var cfg: Dictionary = design["initial-encounters"]
			var hp := (
				Combat.enemy_max_hp(int(m.level), power)
				* (float(cfg["boss-hp-mult"]) if stable.boss else 1.0)
			)
			var damage := (
				Combat.enemy_damage(int(m.level), power, design.combat)
				* (float(cfg["boss-damage-mult"]) if stable.boss else 1.0)
			)
			require(
				(
					number(m.get("max_hp"))
					and number(m.get("damage"))
					and is_equal_approx(m.max_hp, hp)
					and is_equal_approx(m.damage, damage)
				),
				"world.site.local NPC curves"
			)
		if m.get("dead") is bool and number(m.get("hp")):
			require(m.dead == (m.hp == 0), "world.site.life state")
		if stable.boss:
			validate_special(m.get("special"), "world.site.mob.special", stable.special)
		elif layout.family == "ruins":
			if (
				require(
					(
						integer(m.get("room_cycle"))
						and integer(site.get("cycle"))
						and m.get("room_cycle", INF) <= site.cycle
					),
					"world.site.guard.room_cycle"
				)
				and m.room_cycle == site.cycle
				and site.get("room_levels") is Array
				and site.room_levels.size() == 3
			):
				require(
					(
						integer(site.room_levels[int(stable.pack)], 1)
						and m.get("level") == site.room_levels[int(stable.pack)]
					),
					"world.site.guard.shared room level"
				)
		if stable.spirit != "":
			spirit_count += 1
			if require(spirits is Dictionary, "world.site.initial spirit levels"):
				require(integer(spirits.get(stable.key), 1), "world.site.initial spirit level")
				if m.get("cycle") == 0:
					require(
						spirits.get(stable.key) == m.get("level"), "world.site.first spirit level"
					)
	if require(spirits is Dictionary, "world.site.initial spirit levels"):
		require(spirits.size() == spirit_count, "world.site.spirit cardinality")
	if (
		site.get("cleared") is bool
		and site.mobs.values().all(func(m): return m is Dictionary and m.get("dead") is bool)
	):
		require(
			site.cleared == site.mobs.values().all(func(m): return m.dead),
			"world.site.designated clear predicate"
		)
	if site.get("completed") == true:
		require(
			site.family == "supplier" and site.get("cleared") == true,
			"world.site.completed one-time objective"
		)


func validate_special(value: Variant, path: String, kind: String) -> void:
	if not require(value is Dictionary, path):
		return
	require(value.size() == 7, path + ".fields")
	var cfg: Dictionary = design["initial-encounters"]["special-profile"]
	var phase: String = value.phase if value.get("phase") is String else ""
	require(phase in ["ready", "cooldown", "warning", "charge"], path + ".phase")
	var maximum: float = (
		cfg["ready-s"]
		if phase == "ready"
		else (cfg["warning-s"] if phase == "warning" else cfg["cooldown-s"])
	)
	require(number(value.get("left")) and value.get("left", INF) <= maximum, path + ".left")
	require(
		number(value.get("recovery")) and value.get("recovery", INF) <= cfg["recovery-s"],
		path + ".recovery"
	)
	require(
		value.get("engaged") is bool and value.get("target") is String, path + ".engaged/target"
	)
	if phase in ["warning", "charge"]:
		if (
			position(value.get("origin"), path + ".origin")
			and position(value.get("endpoint"), path + ".endpoint")
		):
			var a: Array = value.origin
			var b: Array = value.endpoint
			var distance := Vector2(float(b[0]) - a[0], float(b[2]) - a[2]).length()
			require(
				(
					a[1] == b[1]
					and (
						distance <= cfg.stomp.radius
						if kind == "stomp"
						else distance > cfg.charge.range[0] and distance <= cfg.charge.range[1]
					)
				),
				path + ".snapshot range/floor"
			)
		require(value.get("engaged") is bool and value.engaged, path + ".active engagement")
		require(text(value.get("target")), path + ".active target")
		if phase == "charge":
			require(
				kind == "charge" and number(value.get("left")) and value.left == 0,
				path + ".charge assignment/execution"
			)
	else:
		require(
			(
				value.get("origin") is Array
				and value.origin.is_empty()
				and value.get("endpoint") is Array
				and value.endpoint.is_empty()
				and value.get("target") is String
				and value.target == ""
			),
			path + ".inactive snapshot"
		)
	if phase != "cooldown":
		require(number(value.get("recovery")) and value.recovery == 0, path + ".recovery phase")
	elif number(value.get("left")) and number(value.get("recovery")):
		require(value.recovery <= value.left, path + ".recovery remainder")


func validate_features(site: Dictionary, layout: Dictionary, clock: float) -> void:
	var cfg: Dictionary = design["initial-encounters"]
	var plan_ := EncounterGen.content_plan(layout, cfg)
	var levels: Variant = site.get("room_levels")
	if require(
		levels is Array and levels.size() == (3 if layout.family == "ruins" else 0),
		"world.site.room_levels"
	):
		for level in levels:
			require(integer(level, 1), "world.site.room_levels.level")
	var contents: Variant = site.get("contents")
	if not require(contents is Dictionary, "world.site.contents"):
		return
	require(contents.size() == 3, "world.site.contents.fields")
	for field in ["rubble", "props"]:
		var rows: Variant = contents.get(field)
		if not require(rows is Dictionary, "world.site.contents." + field):
			continue
		require(rows.size() == plan_[field].size(), "world.site.contents." + field + ".count")
		for key in plan_[field]:
			var row: Variant = rows.get(key)
			if not require(row is Dictionary, "world.site.contents." + field + ".identity"):
				continue
			if field == "rubble":
				require(row.size() == 2, "world.site.contents.rubble.fields")
				require(
					row.get("broken") is bool and number(row.get("restore_at")),
					"world.site.contents.rubble.state"
				)
				if row.get("broken") is bool and number(row.get("restore_at")):
					require(
						row.restore_at > 0 if row.broken else row.restore_at == 0,
						"world.site.contents.rubble.deadline"
					)
					require(
						row.restore_at <= clock + float(cfg.rubble["restore-world-hours"]) * 3600,
						"world.site.contents.rubble.deadline upper bound"
					)
			else:
				require(row.size() == 1, "world.site.contents.prop.fields")
				require(
					(
						number(row.get("hp"))
						and row.get("hp", INF) <= cfg.furnishings[plan_.props[key].kind].hp
					),
					"world.site.contents.prop.hp"
				)
	var traps_: Variant = contents.get("traps")
	if require(
		traps_ is Array and traps_.size() == plan_.traps.size(), "world.site.contents.traps"
	):
		for trap in traps_:
			if not require(trap is Dictionary, "world.site.contents.trap"):
				continue
			require(trap.size() == 3, "world.site.contents.trap.fields")
			var phase: String = trap.phase if trap.get("phase") is String else ""
			require(
				phase in ["idle", "warning", "active", "cooldown"], "world.site.contents.trap.phase"
			)
			var maximum: float = cfg.spikes.get(str(phase) + "-s", 0)
			require(
				number(trap.get("left")) and trap.get("left", INF) <= maximum,
				"world.site.contents.trap.left"
			)
			if require(trap.get("hit") is Array, "world.site.contents.trap.hit"):
				var seen := {}
				for id in trap.hit:
					require(text(id) and not seen.has(id), "world.site.contents.trap.hit identity")
					seen[id] = true
				if phase in ["idle", "warning"]:
					require(trap.hit.is_empty(), "world.site.contents.trap.phase hitset")
	if not site.get("rewards") is Dictionary:
		return
	for id in site.rewards:
		if not id is String or not id.begins_with("furnishing/"):
			continue  # other reward owners validate their own sources
		var parts: PackedStringArray = id.split("/")
		if not require(
			(
				parts.size() == 6
				and parts[1].is_valid_int()
				and str(int(parts[1])) == parts[1]
				and int(parts[1]) >= 0
				and integer(site.get("cycle"))
				and int(parts[1]) <= site.cycle
			),
			"world.site.furnishing reward cycle"
		):
			continue
		var key := "/".join(parts.slice(2))
		if not require(plan_.props.has(key), "world.site.furnishing reward source"):
			continue
		var reward: Variant = site.rewards[id]
		if not require(
			(
				reward is Dictionary
				and integer(reward.get("level"), 1)
				and reward.get("payload") is Array
			),
			"world.site.furnishing reward level/payload"
		):
			continue
		var prop: Dictionary = plan_.props[key]
		var level: int = int(reward.level)
		if int(parts[1]) == site.get("cycle") and levels is Array and levels.size() == 3:
			require(
				integer(levels[prop.room], 1) and level == levels[prop.room],
				"world.site.furnishing saved room reward level"
			)
		var expected: Array
		if prop.kind == "vase":
			var count := (
				int(cfg.furnishings.vase["coin-base"])
				+ int(cfg.furnishings.vase["coin-per-level"]) * level
			)
			expected = [item_data(Item.stack(&"coin", &"", count))]
		else:
			var rules: Dictionary = cfg.furnishings.table
			var potion = Item.stack(
				&"consumable", StringName(rules.potion), int(rules["potion-count"]), level
			)
			potion.rarity = int(rules["potion-rarity"])
			expected = [
				item_data(
					Item.stack(&"ingredient", StringName(rules.flask), int(rules["flask-count"]))
				),
				item_data(potion)
			]
		require(same_data(reward.payload, expected), "world.site.furnishing exact payload")

	for key in plan_.props:
		if not integer(site.get("cycle")):
			continue
		var id := "furnishing/%d/%s" % [site.cycle, key]
		if plan_.props[key].kind == "table":
			require(site.rewards.has(id), "world.site.table issued independently")
		elif (
			contents.get("props") is Dictionary
			and contents.props.get(key) is Dictionary
			and number(contents.props[key].get("hp"))
		):
			require(
				site.rewards.has(id) == (contents.props[key].hp == 0),
				"world.site.vase destruction issuance"
			)


func validate_rewards(site: Dictionary, layout: Dictionary) -> void:
	if (
		not site.get("rewards") is Dictionary
		or not site.get("mobs") is Dictionary
		or not integer(site.get("cycle"))
	):
		return
	var sources := {}
	for stable in layout.assignments:
		sources[stable.key] = stable
	for key in site.rewards:
		if key is String and key.begins_with("furnishing/"):
			continue
		if not require(key is String, "world.site.reward.identity"):
			continue
		var parts: PackedStringArray = key.split("/")
		if not require(
			(
				parts.size() >= 2
				and parts[1].is_valid_int()
				and str(int(parts[1])) == parts[1]
				and int(parts[1]) >= 0
				and int(parts[1]) <= site.cycle
			),
			"world.site.reward.cycle"
		):
			continue
		var record: Variant = site.rewards[key]
		if not require(
			(
				record is Dictionary
				and record.get("delivered") is bool
				and record.get("payload") is Array
				and integer(record.get("level"), 1)
			),
			"world.site.reward.record"
		):
			continue
		if parts[0] == "kill":
			var source := "/".join(parts.slice(2))
			if not require(parts.size() == 4 and sources.has(source), "world.site.kill.source"):
				continue
			var stable: Dictionary = sources[source]
			var mob: Variant = site.mobs.get(site.id + "/" + source)
			if not mob is Dictionary or not integer(mob.get("cycle")):
				continue
			require(record.size() == 4, "world.site.kill.fields")
			position(record.get("position"), "world.site.kill.position")
			require(
				(
					int(parts[1]) < mob.cycle
					or (int(parts[1]) == mob.cycle and mob.get("dead") == true)
				),
				"world.site.kill.genuine death"
			)
			if int(parts[1]) == mob.cycle:
				require(record.level == mob.get("level"), "world.site.kill.current level")
			var spirit_level: Variant = 0
			if stable.spirit != "":
				if not site.get("spirit_levels") is Dictionary:
					continue  # diagnosed by the site-content boundary
				spirit_level = site.spirit_levels.get(source)
			if not integer(spirit_level):
				continue
			var expected := (
				Rewards
				. kill_payload(
					stable, int(parts[1]), int(record.level), int(spirit_level), o, design
				)
				. map(item_data)
			)
			require(same_data(record.payload, expected), "world.site.kill.exact payload")
		elif parts[0] == "mission":
			if not require(
				parts.size() == 2 and layout.family != "ruins", "world.site.mission.source"
			):
				continue
			require(record.size() == 5, "world.site.mission.fields")
			var classes: Variant = record.get("classes")
			var cls: Variant = record.get("class_id")
			if not require(classes is Array and cls is String, "world.site.mission.class snapshot"):
				continue
			var seen := {}
			var valid := true
			for candidate in classes:
				if not require(
					candidate is String and o.classes.has(candidate) and not seen.has(candidate),
					"world.site.mission.distinct classes"
				):
					valid = false
				seen[candidate] = true
			if not require(cls == "" or o.classes.has(cls), "world.site.mission.selected class"):
				continue
			if valid and not classes.is_empty():
				var sorted: Array = classes.duplicate()
				sorted.sort()
				require(
					(
						classes == sorted
						and (
							cls
							== classes[Rewards.rng_for(site.id + "/" + key + "/class").randi_range(
								0, classes.size() - 1
							)]
						)
					),
					"world.site.mission.uniform class snapshot"
				)
			if int(parts[1]) == site.cycle:
				require(site.get("cleared") == true, "world.site.mission.designated clear")
				var boss: Dictionary = layout.assignments.filter(func(a): return a.boss)[0]
				if site.mobs.get(site.id + "/" + boss.key) is Dictionary:
					require(
						record.level == site.mobs[site.id + "/" + boss.key].get("level"),
						"world.site.mission.saved boss level"
					)
			if cls == "":
				require(
					record.payload.is_empty() and not record.delivered,
					"world.site.mission.pending class"
				)
			else:
				require(
					same_data(
						record.payload,
						(
							Rewards
							. package_payload(
								site.id + "/" + key,
								int(layout.tier),
								int(record.level),
								StringName(cls),
								o,
								design
							)
							. map(item_data)
						)
					),
					"world.site.mission.exact payload"
				)
			if layout.family == "supplier" and site.get("completed") != true:
				require(not record.delivered, "world.site.mission.rescue delivery order")
		else:
			require(false, "world.site.reward.unknown source")
	for stable in layout.assignments:
		var mob: Variant = site.mobs.get(site.id + "/" + stable.key)
		if not mob is Dictionary or not integer(mob.get("cycle")):
			continue
		require(mob.cycle <= site.cycle, "world.site.kill.incarnation cycle")
		# One receipt per genuine death; never accept deleted issued records as a reroll opportunity.
		var count := int(mob.cycle) + (1 if mob.get("dead") == true else 0)
		var actual := 0
		for key in site.rewards:
			if (
				key is String
				and key.begins_with("kill/")
				and "/".join(key.split("/").slice(2)) == stable.key
			):
				actual += 1
		require(actual == count, "world.site.kill.death receipt count")
	if site.get("cleared") == true and layout.family != "ruins":
		require(
			site.rewards.has("mission/%d" % site.cycle), "world.site.mission.completion receipt"
		)


func validate_vendors(w: Dictionary) -> void:
	if not require(w.get("vendors") is Dictionary, "world.vendors"):
		return
	for key in w.vendors:
		if not require(key is String, "world.vendor.identity"):
			continue
		var parts: PackedStringArray = key.split("/")
		if not require(
			(
				parts.size() == 2
				and coordinate_pair(parts[0], int(design.terrain["lands-per-axis"]) / 2)
				and parts[1] in ["weapon-vendor", "armor-vendor"]
				and w.get("lands") is Dictionary
				and w.lands.has(parts[0])
			),
			"world.vendor.land/role"
		):
			continue
		var record: Variant = w.vendors[key]
		if not require(record is Dictionary, "world.vendor.record"):
			continue
		require(record.size() == 4, "world.vendor.fields")
		if not require(
			(
				integer(record.get("day"))
				and number(w.get("clock"))
				and record.get("day", INF) <= floori(w.clock / float(design.time["day-s"]))
				and integer(record.get("ceiling"))
				and integer(record.get("level"), 1)
				and record.get("items") is Array
			),
			"world.vendor.stock inputs"
		):
			continue
		var ceiling := 0
		if w.get("sites") is Dictionary:
			for ordinal in design["initial-encounters"].supplier.tiers.size():
				var id := "%s/site/%s/supplier/%d" % [w.world_id, parts[0], ordinal]
				if w.sites.get(id) is Dictionary and w.sites[id].get("completed") == true:
					ceiling += 1
		if not require(record.ceiling <= ceiling, "world.vendor.earned ceiling"):
			continue
		var xy: PackedStringArray = parts[0].split(",")
		var land = _geography.land_at(Vector2i(int(xy[0]), int(xy[1])))
		var expected := (
			Shop
			. stock(
				StringName(parts[1]),
				_geography,
				land,
				_geography.village_at(land),
				int(record.level),
				o,
				design,
				int(record.ceiling),
				int(record.day)
			)
			. map(item_data)
		)
		var cursor := 0
		for item in record.items:
			validate_item(item, "world.vendor.item")
			while cursor < expected.size() and not same_data(item, expected[cursor]):
				cursor += 1
			require(cursor < expected.size(), "world.vendor.exact remaining stock")
			cursor += 1
