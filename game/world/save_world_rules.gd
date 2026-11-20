## Ordered world representation checks. Completion phases keep ordinary rejected rows
## separate from native-error false, which propagates to the original owner.
extends RefCounted
const Combat := preload("res://game/combat/combat.gd")
const Domain := preload("res://game/domain/domain.gd")
const WorldGen := preload("res://game/world/world_gen.gd")


static func validate_world(save, w: Dictionary) -> void:
	if not _world_identity(save, w):
		return
	save.require(
		save._number(w.get("seed"), -INF) and float(w.seed) == floorf(float(w.seed)), "world.seed"
	)
	for field in ["clock", "elapsed"]:
		save.require(save._number(w.get(field)), "world." + field)
	if _characters(save, w) and _ambient(save, w):
		_geography_and_sites(save, w)


static func validate_mob(save, m: Variant, path: String) -> void:
	if not save.require(m is Dictionary, path):
		return
	save.require(m.get("species") is String and save.o.creatures.has(m.species), path + ".species")
	if not _mob_stats(save, m, path):
		return
	_mob_fields(save, m, path)


static func validate_combat(save, r: Variant, path: String) -> void:
	if not save.require(r is Dictionary, path):
		return
	if _combat_representation(save, r, path):
		_combat_pairs(save, r, path)


static func ambient_identity(save, id: Variant, world_id: String) -> bool:
	if not id is String:
		return false
	var p: PackedStringArray = id.split("/")
	if p.size() != 5 or p[0] != world_id or p[1] != "ambient":
		return false
	var extent := (
		int(save.design.terrain["land-blocks"])
		* int(save.design.terrain["lands-per-axis"])
		/ (2 * int(save.design.terrain["zone-blocks"]))
	)
	return _ambient_members(save, p, extent)


static func site_identity(save, id: String, world_id: String, family: Variant) -> bool:
	var p: PackedStringArray = id.split("/")
	if _invalid_site_header(p, world_id):
		return false
	if not _site_family(p, family):
		return false
	return _site_coordinate_ordinal(save, p) and _site_member(p, family)


static func validate_ambient_stats(save, m: Dictionary, path: String) -> void:
	var pb: Variant = m.get("power_base")
	if not _ambient_power(save, pb, path):
		return
	if _invalid_curve_inputs(save, m):
		return
	save.require(
		(
			is_equal_approx(m.max_hp, Combat.enemy_max_hp(int(m.level), pb))
			and is_equal_approx(m.damage, Combat.enemy_damage(int(m.level), pb, save.design.combat))
		),
		path + ".NPC curves"
	)
	if _life_state_inputs(save, m):
		save.require(m.dead == (m.hp == 0), path + ".life state")


static func _characters(save, w: Dictionary) -> bool:
	if save.require(w.get("characters") is Dictionary, "world.characters"):
		for id in w.characters:
			var c: Variant = w.characters[id]
			if save.require(save._text(id) and c is Dictionary, "world.character"):
				save.position(c.get("position"), "world.character.position")
				save.position(c.get("respawn"), "world.character.respawn")
	return true


static func _ambient(save, w: Dictionary) -> bool:
	if not save.require(w.get("mobs") is Dictionary, "world.mobs"):
		return true
	for id in w.mobs:
		if not _ambient_row(save, w, id):
			return false

	return true


static func _lands(save, w: Dictionary, expected_sites: Dictionary) -> bool:
	if not save.require(w.get("lands") is Dictionary, "world.lands"):
		return true
	if save._geography == null or save._geography.world_seed != int(w.seed):
		save._geography = WorldGen.new(int(w.seed), save.design, save.o.landscapes)
	return _land_records(save, w, expected_sites)


static func _sites(save, w: Dictionary, expected_sites: Dictionary) -> bool:
	if save.require(w.get("sites") is Dictionary, "world.sites"):
		save.require(
			w.sites.size() == expected_sites.size(), "world.sites complete six per generated land"
		)
		for id in w.sites:
			if not _site(save, w, id, expected_sites):
				return false

	return true


static func _ambient_record(save, w: Dictionary, id: String) -> bool:
	var mob: Variant = w.mobs[id]
	if mob is Dictionary:
		save.require(mob.get("pack") == id.get_base_dir(), "world.mob.pack identity")
		var species = save.o.creatures.get(mob.get("species"))
		if species != null:
			if not _ambient_species(save, mob, species, id):
				return false
		save.validate_ambient_stats(mob, "world.mobs." + id)
	return true


static func _ambient_species(save, mob: Dictionary, species, id: String) -> bool:
	var role := str(Domain.combat_role(species))
	if role != "any-class":
		save.require(
			(
				mob.get("role")
				== (
					role
					if save.design["creature-roles"].has(role)
					else str(save.design["creature-roles"].default)
				)
			),
			"world.mob.species role"
		)
	var size := Domain.group_size(species)
	var maximum := size.y
	if size == Vector2i(1, 1):
		maximum = int(save.design.spawns["default-group"][1])
	save.require(int(id.get_file()) < maximum, "world.mob.member count")
	return true


static func _site(save, w: Dictionary, id: Variant, expected_sites: Dictionary) -> bool:
	var s: Variant = w.sites[id]
	var valid: bool = (
		s is Dictionary
		and s.get("id") == id
		and id is String
		and id.begins_with(w.world_id + "/site/")
	)
	if not save.require(valid, "world.site.identity"):
		return true
	return _site_contents(save, w, id, s, expected_sites)


static func _site_volumes(save, s: Variant) -> bool:
	if not save.require(_volume_array(s), "world.site.volumes"):
		return true
	for v in s.volumes:
		if not _volume(save, v):
			return false
	return true


static func _site_mobs(save, s: Variant, id: Variant) -> bool:
	if save.require(s.get("mobs") is Dictionary, "world.site.mobs"):
		for mob_id in s.mobs:
			if save.require(
				mob_id is String and mob_id.begins_with(id + "/"), "world.site.mob.identity"
			):
				save.validate_mob(s.mobs[mob_id], "world.site.mob")
	return true


static func _site_rewards(save, s: Variant) -> bool:
	if not save.require(s.get("rewards") is Dictionary, "world.site.rewards"):
		return true
	for reward in s.rewards.values():
		if save.require(_reward_representation(reward), "world.site.reward"):
			for item in reward.payload:
				save.validate_item(item, "world.site.reward.item")
	return true


static func _threat(save, r: Variant, id: Variant, seen: Dictionary, path: String) -> bool:
	save.require(
		save._text(id) and save._number(r.threat[id]) and r.threat[id] > 0, path + ".threat"
	)
	var order: Variant = r.order.get(id)
	if save.require(save._integer(order), path + ".order"):
		return _threat_order(save, r, order, seen, path)
	return true


static func _geography_and_sites(save, w: Dictionary) -> void:
	var expected_sites := {}
	if _lands(save, w, expected_sites) and _sites(save, w, expected_sites):
		save.validate_vendors(w)


static func _mob_stats(save, m: Variant, path: String) -> bool:
	var valid: bool = (
		save._integer(m.get("level"), 1)
		and (save._number(m.get("max_hp")) and m.max_hp > 0)
		and save._number(m.get("damage"))
		and save._number(m.get("hp"))
		and m.hp <= m.max_hp
	)
	save.require(valid, path + ".stats")
	return true


static func _combat_representation(save, r: Variant, path: String) -> bool:
	for field in ["threat", "order", "provoked"]:
		if not save.require(r.get(field) is Dictionary, path + "." + field):
			return false
	save.require(_combat_timers(save, r), path + ".timers/order")
	for field in ["current", "taunt"]:
		save.require(r.get(field) is String, path + "." + field)
	return true


static func _ambient_members(save, p: PackedStringArray, extent: int) -> bool:
	return (
		save._coordinate_pair(p[2], extent) and _ambient_group(save, p) and _ambient_member_index(p)
	)


static func _ambient_group(save, p: PackedStringArray) -> bool:
	return (
		p[3].is_valid_int()
		and str(int(p[3])) == p[3]
		and int(p[3]) >= 0
		and int(p[3]) < int(save.design.spawns["groups-per-zone"][1])
	)


static func _ambient_member_index(p: PackedStringArray) -> bool:
	return p[4].is_valid_int() and str(int(p[4])) == p[4] and int(p[4]) >= 0


static func _invalid_site_header(p: PackedStringArray, world_id: String) -> bool:
	return p.size() != 5 or p[0] != world_id or p[1] != "site"


static func _site_family(p: PackedStringArray, family: Variant) -> bool:
	if p[3] != family or family not in ["ruins", "camp", "supplier"]:
		return false
	return true


static func _ambient_power(save, pb: Variant, path: String) -> bool:
	var valid: bool = (
		save._number(pb, -INF)
		and pb >= save.design["enemy-hp"]["power-base"][0]
		and pb <= save.design["enemy-hp"]["power-base"][1]
	)
	return save.require(valid, path + ".power_base")


static func _invalid_curve_inputs(save, m: Dictionary) -> bool:
	return (
		not save._integer(m.get("level"), 1)
		or not save._number(m.get("max_hp"))
		or not save._number(m.get("damage"))
	)


static func _land(save, w: Dictionary, key: Variant, expected_sites: Dictionary) -> bool:
	if not save.require(
		(
			key is String
			and save._coordinate_pair(key, int(save.design.terrain["lands-per-axis"]) / 2)
		),
		"world.land.identity"
	):
		return true
	return _joint_geography(save, w, key, expected_sites)


static func _volume(save, v: Variant) -> bool:
	if not save.require(v is Array and v.size() == 6, "world.site.volume"):
		return true
	if (
		save.position(v.slice(0, 3), "world.site.volume.min")
		and save.position(v.slice(3, 6), "world.site.volume.max")
	):
		return _volume_order(save, v)
	return true


static func _reward_representation(reward: Variant) -> bool:
	return (
		reward is Dictionary and reward.get("delivered") is bool and reward.get("payload") is Array
	)


static func _threat_order(save, r: Variant, order: Variant, seen: Dictionary, path: String) -> bool:
	var valid: bool = (
		not seen.has(order) and save._integer(r.get("next_order")) and order < r.next_order
	)
	save.require(valid, path + ".order uniqueness")
	seen[order] = true
	return true


static func _world_identity(save, w: Dictionary) -> bool:
	var valid: bool = save._text(w.get("world_id")) and not "/" in w.world_id
	return save.require(valid, "world.world_id")


static func _mob_generation(save, m: Variant) -> bool:
	return (
		save._integer(m.get("seed")) and save._integer(m.get("cycle")) and save._text(m.get("pack"))
	)


static func _combat_pairs(save, r: Variant, path: String) -> void:
	var seen := {}
	for id in r.threat:
		if not _threat(save, r, id, seen, path):
			return
	save.require(r.order.size() == r.threat.size(), path + ".order cardinality")
	for id in r.provoked:
		save.require(save._text(id) and r.provoked[id] == true, path + ".provoked")


static func _site_coordinate_ordinal(save, p: PackedStringArray) -> bool:
	return (
		save._coordinate_pair(p[2], int(save.design.terrain["lands-per-axis"]) / 2)
		and p[4].is_valid_int()
		and str(int(p[4])) == p[4]
	)


static func _site_member(p: PackedStringArray, family: Variant) -> bool:
	return int(p[4]) >= 0 and int(p[4]) < (4 if family == "supplier" else 1)


static func _life_state_inputs(save, m: Variant) -> bool:
	return m.get("dead") is bool and save._number(m.get("hp"))


static func _ambient_row(save, w: Dictionary, id: Variant) -> bool:
	if not save.require(save.ambient_identity(id, w.world_id), "world.mob.identity"):
		return true
	save.validate_mob(w.mobs[id], "world.mobs." + id)
	return _ambient_record(save, w, id)


static func _registered_site(
	save, w: Dictionary, id: Variant, s: Variant, expected_sites: Variant
) -> bool:
	save.require(
		save.site_identity(id, w.world_id, s.get("family")), "world.site.family/ordinal/land"
	)
	if save.require(expected_sites.has(id), "world.site registered joint land"):
		save.validate_site_content(
			s, expected_sites[id], float(w.clock) if save._number(w.get("clock")) else 0.0
		)
		save.validate_rewards(s, expected_sites[id])
	return true


static func _combat_timers(save, r: Variant) -> bool:
	return (
		save._integer(r.get("next_order"))
		and save._number(r.get("taunt_left"))
		and r.get("returning") is bool
	)


static func _volume_order(save, v: Array) -> bool:
	save.require(v[0] <= v[3] and v[1] <= v[4] and v[2] <= v[5], "world.site.volume.order")
	return true


static func _land_records(save, w: Dictionary, expected_sites: Dictionary) -> bool:
	for key in w.lands:
		if not _land(save, w, key, expected_sites):
			return false
	return true


static func _site_representation(save, s: Variant, id: Variant) -> bool:
	for flag in ["pending", "cleared", "completed"]:
		save.require(s.get(flag) is bool, "world.site." + flag)
	save.require(save._integer(s.get("cycle")), "world.site.cycle")
	return _site_volumes(save, s) and _site_mobs(save, s, id) and _site_rewards(save, s)


static func _volume_array(s: Variant) -> bool:
	return s.get("volumes") is Array and not s.volumes.is_empty()


static func _joint_geography(save, w: Dictionary, key: Variant, expected_sites: Dictionary) -> bool:
	var xy: PackedStringArray = key.split(",")
	var plan_: Dictionary = save._geography.encounters_at(
		save._geography.land_at(Vector2i(int(xy[0]), int(xy[1])))
	)
	var valid: bool = not plan_.is_empty() and save._same_data(w.lands[key], plan_)
	if not save.require(valid, "world.land.joint geography/assignments"):
		return true
	for layout in plan_.sites:
		var id: String = "%s/site/%s/%s/%d" % [w.world_id, key, layout.family, layout.ordinal]
		expected_sites[id] = layout
	return true


static func _mob_fields(save, m: Variant, path: String) -> void:
	save.require(
		m.get("hostility") in ["H", "N", "P", "F"] and m.get("role") in ["melee", "ranged", "mage"],
		path + ".hostility/role"
	)
	save.position(m.get("home"), path + ".home")
	save.position(m.get("position"), path + ".position")
	save.require(_mob_generation(save, m), path + ".generation")
	for flag in ["dead", "eligible"]:
		save.require(m.get(flag) is bool, path + "." + flag)
	save.validate_combat(m.get("combat"), path + ".combat")


static func _site_contents(
	save, w: Dictionary, id: Variant, s: Variant, expected_sites: Variant
) -> bool:
	return _registered_site(save, w, id, s, expected_sites) and _site_representation(save, s, id)
