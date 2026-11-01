## Saved ambient incarnation preparation; caller retains support checks and materialization order.
extends RefCounted
const Targeting := preload("res://game/combat/targeting.gd")


static func prepare(
	saved: Dictionary,
	g: Dictionary,
	i: int,
	pack: String,
	design: Dictionary,
	authority: Node,
	id: String
) -> Dictionary:
	if not saved.is_empty() and saved.dead:
		saved = _renew(saved, g, authority, id)
		if saved.is_empty():
			return {}
	return _retained_or_fresh(saved, g, i, pack, design)


static func _retained_or_fresh(
	saved: Dictionary, g: Dictionary, i: int, pack: String, design: Dictionary
) -> Dictionary:
	var spawn: Dictionary = saved if not saved.is_empty() else _fresh_spawn(g, i, pack, design)
	if spawn.is_empty():
		return {}
	if g.has("power_base") and not spawn.has("power_base"):
		spawn.power_base = g.power_base
	return spawn


static func _renew(saved: Dictionary, g: Dictionary, authority: Node, id: String) -> Dictionary:
	saved = saved.duplicate(true)  # old corpse callbacks must not mutate a new incarnation
	saved.dead = false
	saved.eligible = false
	saved.cycle += 1
	saved.level = g.level
	saved.max_hp = g.max_hp
	saved.hp = g.max_hp
	saved.damage = g.damage
	if g.has("power_base"):
		saved.power_base = g.power_base
	saved.position = saved.home.duplicate()
	saved.combat = Targeting.fresh()
	authority.records[id] = saved.combat
	return saved


static func _fresh_spawn(g: Dictionary, i: int, pack: String, design: Dictionary) -> Dictionary:
	return {
		"species": str(g.species),
		"level": g.level,
		"max_hp": g.max_hp,
		"hp": g.max_hp,
		"damage": g.damage,
		"hostility": str(g.hostility),
		"role": str(g.get("role", design["creature-roles"].default)),
		"home": [g.positions[i].x, g.positions[i].y, g.positions[i].z],
		"position": [g.positions[i].x, g.positions[i].y, g.positions[i].z],
		"seed": g.seed + i,
		"pack": pack,
		"dead": false,
		"eligible": false,
		"cycle": 0,
		"combat": Targeting.fresh()
	}
