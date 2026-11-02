## Ordered site roster/special checks. Completion phases keep ordinary rejected rows
## separate from native-error false, which propagates to the original owner.
extends RefCounted
const Combat := preload("res://game/combat/combat.gd")


static func validate_site_content(save, site: Dictionary, layout: Dictionary, clock: float) -> void:
	save.require(
		save._same_data(site.get("volumes"), layout.volumes),
		"world.site.exact closed playable union"
	)
	save.validate_features(site, layout, clock)
	if not save.require(site.get("mobs") is Dictionary, "world.site.mobs"):
		return
	if _designated_roster(save, site, layout):
		_site_completion(save, site)


static func validate_special(save, value: Variant, path: String, kind: String) -> void:
	if not save.require(value is Dictionary, path):
		return
	save.require(value.size() == 7, path + ".fields")
	var cfg: Dictionary = save.design["initial-encounters"]["special-profile"]
	var phase: String = value.phase if value.get("phase") is String else ""
	if (
		_special_inputs(save, value, path, cfg, phase)
		and _special_snapshot(save, value, path, kind, cfg, phase)
	):
		_special_recovery(save, value, path, phase)


static func _designated_mob(save, site: Dictionary, layout: Dictionary, stable, m: Variant) -> bool:
	save.require(
		m.get("species") == save.design["initial-encounters"].species and m.get("hostility") == "H",
		"world.site.skeleton hostility"
	)
	for field in ["home", "role", "seed"]:
		save.require(save._same_data(m.get(field), stable[field]), "world.site.stable " + field)
	save.require(m.get("pack") == site.id + "/" + stable.pack, "world.site.generated pack")
	var power: float = (
		float(save.design["initial-encounters"]["power-base-offset"]) + int(stable.tier)
	)
	save.require(m.get("power_base") == power, "world.site.local power")
	return _designated_incarnation(save, site, layout, stable, m, power)


static func _local_curves(save, m: Variant, stable, power: float) -> bool:
	if save._integer(m.get("level"), 1):
		var cfg: Dictionary = save.design["initial-encounters"]
		var hp := (
			Combat.enemy_max_hp(int(m.level), power)
			* (float(cfg["boss-hp-mult"]) if stable.boss else 1.0)
		)
		var damage := (
			Combat.enemy_damage(int(m.level), power, save.design.combat)
			* (float(cfg["boss-damage-mult"]) if stable.boss else 1.0)
		)
		return _local_stats_match(save, m, hp, damage)
	return true


static func _guard_room(save, site: Dictionary, layout: Dictionary, stable, m: Variant) -> bool:
	if layout.family == "ruins":
		return _guard_generation(save, site, stable, m)
	return true


static func _special_snapshot(
	save, value: Variant, path: String, kind: String, cfg: Dictionary, phase: String
) -> bool:
	if phase in ["warning", "charge"]:
		return _active_snapshot(save, value, path, kind, cfg, phase)
	save.require(_inactive_snapshot(value), path + ".inactive snapshot")
	return true


static func _spirit_level(save, stable, m: Variant, spirits: Variant) -> bool:
	if save.require(spirits is Dictionary, "world.site.initial spirit levels"):
		save.require(save._integer(spirits.get(stable.key), 1), "world.site.initial spirit level")
		if m.get("cycle") == 0:
			save.require(spirits.get(stable.key) == m.get("level"), "world.site.first spirit level")
	return true


static func _site_completion(save, site: Dictionary) -> void:
	if (
		site.get("cleared") is bool
		and site.mobs.values().all(func(m): return m is Dictionary and m.get("dead") is bool)
	):
		save.require(
			site.cleared == site.mobs.values().all(func(m): return m.dead),
			"world.site.designated clear predicate"
		)
	if site.get("completed") == true:
		save.require(
			site.family == "supplier" and site.get("cleared") == true,
			"world.site.completed one-time objective"
		)


static func _special_inputs(
	save, value: Variant, path: String, cfg: Dictionary, phase: String
) -> bool:
	save.require(phase in ["ready", "cooldown", "warning", "charge"], path + ".phase")
	var maximum: float = (
		cfg["ready-s"]
		if phase == "ready"
		else (cfg["warning-s"] if phase == "warning" else cfg["cooldown-s"])
	)
	save.require(
		save._number(value.get("left")) and value.get("left", INF) <= maximum, path + ".left"
	)
	save.require(
		save._number(value.get("recovery")) and value.get("recovery", INF) <= cfg["recovery-s"],
		path + ".recovery"
	)
	save.require(
		value.get("engaged") is bool and value.get("target") is String, path + ".engaged/target"
	)
	return true


static func _local_stats_match(save, m: Variant, hp: float, damage: float) -> bool:
	var valid: bool = (
		save._number(m.get("max_hp"))
		and save._number(m.get("damage"))
		and is_equal_approx(m.max_hp, hp)
		and is_equal_approx(m.damage, damage)
	)
	save.require(valid, "world.site.local NPC curves")
	return true


static func _current_room(save, m: Variant, site: Dictionary, stable) -> bool:
	if (
		m.room_cycle == site.cycle
		and site.get("room_levels") is Array
		and site.room_levels.size() == 3
	):
		save.require(
			(
				save._integer(site.room_levels[int(stable.pack)], 1)
				and m.get("level") == site.room_levels[int(stable.pack)]
			),
			"world.site.guard.shared room level"
		)
	return true


static func _active_snapshot(
	save, value: Variant, path: String, kind: String, cfg: Dictionary, phase: String
) -> bool:
	if not _snapshot_geometry(save, value, path, kind, cfg):
		return false
	save.require(value.get("engaged") is bool and value.engaged, path + ".active engagement")
	save.require(save._text(value.get("target")), path + ".active target")
	if phase == "charge":
		return _charge_execution(save, value, kind, path)
	return true


static func _inactive_snapshot(value: Variant) -> bool:
	return (
		value.get("origin") is Array
		and value.origin.is_empty()
		and value.get("endpoint") is Array
		and value.endpoint.is_empty()
		and value.get("target") is String
		and value.target == ""
	)


static func _snapshot_geometry(
	save, value: Variant, path: String, kind: String, cfg: Dictionary
) -> bool:
	if (
		save.position(value.get("origin"), path + ".origin")
		and save.position(value.get("endpoint"), path + ".endpoint")
	):
		var a: Array = value.origin
		var b: Array = value.endpoint
		var distance := Vector2(float(b[0]) - a[0], float(b[2]) - a[2]).length()
		return _snapshot_range(save, a, b, distance, cfg, kind, path)
	return true


static func _snapshot_range(
	save, a: Array, b: Array, distance: float, cfg: Dictionary, kind: String, path: String
) -> bool:
	var valid: bool = (
		a[1] == b[1]
		and (
			distance <= cfg.stomp.radius
			if kind == "stomp"
			else distance > cfg.charge.range[0] and distance <= cfg.charge.range[1]
		)
	)
	save.require(valid, path + ".snapshot range/floor")
	return true


static func _designated_roster(save, site: Dictionary, layout: Dictionary) -> bool:
	save.require(site.mobs.size() == layout.assignments.size(), "world.site.exact designated count")
	var spirits: Variant = site.get("spirit_levels")
	# One private output holder preserves the original late increment and selected mob alias.
	var spirit_count: Array[int] = [0]
	for stable in layout.assignments:
		if not _designated_assignment(save, site, layout, stable, spirits, spirit_count):
			return false
	if save.require(spirits is Dictionary, "world.site.initial spirit levels"):
		save.require(spirits.size() == spirit_count[0], "world.site.spirit cardinality")
	return true


static func _special_recovery(save, value: Variant, path: String, phase: String) -> void:
	if phase != "cooldown":
		save.require(
			save._number(value.get("recovery")) and value.recovery == 0, path + ".recovery phase"
		)
	elif save._number(value.get("left")) and save._number(value.get("recovery")):
		save.require(value.recovery <= value.left, path + ".recovery remainder")


static func _designated_incarnation(
	save, site: Dictionary, layout: Dictionary, stable, m: Variant, power: float
) -> bool:
	if not _local_curves(save, m, stable, power):
		return false
	if _life_state_inputs(save, m):
		save.require(m.dead == (m.hp == 0), "world.site.life state")
	if stable.boss:
		save.validate_special(m.get("special"), "world.site.mob.special", stable.special)
	elif not _guard_room(save, site, layout, stable, m):
		return false
	return true


static func _charge_execution(save, value: Variant, kind: String, path: String) -> bool:
	var valid: bool = kind == "charge" and save._number(value.get("left")) and value.left == 0
	save.require(valid, path + ".charge assignment/execution")
	return true


static func _designated_assignment(
	save, site: Dictionary, layout: Dictionary, stable, spirits: Variant, spirit_count: Array[int]
) -> bool:
	var id: String = site.id + "/" + stable.key
	var m: Variant = site.mobs.get(id)
	if not save.require(m is Dictionary, "world.site.designated identity " + id):
		return true
	return (
		_designated_mob(save, site, layout, stable, m)
		and _designated_spirit(save, stable, m, spirits, spirit_count)
	)


static func _designated_spirit(
	save, stable, m: Variant, spirits: Variant, spirit_count: Array[int]
) -> bool:
	if stable.spirit != "":
		spirit_count[0] += 1
		if not _spirit_level(save, stable, m, spirits):
			return false
	return true


static func _life_state_inputs(save, m: Variant) -> bool:
	return m.get("dead") is bool and save._number(m.get("hp"))


static func _guard_generation(save, site: Dictionary, stable, m: Variant) -> bool:
	var valid: bool = (
		save._integer(m.get("room_cycle"))
		and save._integer(site.get("cycle"))
		and m.get("room_cycle", INF) <= site.cycle
	)
	if save.require(valid, "world.site.guard.room_cycle"):
		return _current_room(save, m, site, stable)
	return true
