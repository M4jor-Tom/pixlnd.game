## gen-spawns (§6) for the open world: per zone, seeded from (world seed, zone), 0–2 groups of one
## species from the land's landscape roster (D14). Creatures are children of the zone node, so they
## despawn with it. Dungeon, settlement and boss spawns come with their own slices.
extends RefCounted

const CREATURE := preload("res://game/entities/creature.tscn")
const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Combat := preload("res://game/combat/combat.gd")

## Deterministic plan for one zone: [{species, level, hostility, positions: [Vector3], role}].
static func plan(gen, zc: Vector2i, design: Dictionary, creatures: Dictionary, rosters: Dictionary, party_level: int) -> Array:
	var spawns: Dictionary = design["spawns"]
	var out: Array = []
	var n: int = gen.terrain["zone-blocks"]
	var land = gen.land_of_block(zc.x * n + n / 2, zc.y * n + n / 2)
	var roster: Array = rosters.get(land.landscape, [])
	var skip: Array = spawns["skip-categories"]
	var pool: Array = roster.filter(func(id: String) -> bool:
		return creatures.has(id) and not (Model.CreatureCategory.keys()[creatures[id].category].to_lower().replace("_", "-") in skip))
	if pool.is_empty():
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(gen.world_seed, zc.x, zc.y)) ^ hash("spawns")
	for g in rng.randi_range(int(spawns["groups-per-zone"][0]), int(spawns["groups-per-zone"][1])):
		var c: Model.Creature = creatures[pool[rng.randi() % pool.size()]]
		var size := c.group_size if c.group_size != Vector2i(1, 1) else Vector2i(int(spawns["default-group"][0]), int(spawns["default-group"][1]))
		var count := rng.randi_range(size.x, size.y)
		var cx := zc.x * n + rng.randi_range(4, n - 5); var cy := zc.y * n + rng.randi_range(4, n - 5)
		var v: Dictionary = gen.village_at(land)                      # c-hostile-in-city (D22): no wild groups near the square
		if not v.is_empty() and Vector2(cx - v["centre"].x, cy - v["centre"].y).length() < float(design.get("settlement", {}).get("no-hostiles-within", 0)):
			continue
		var h: StringName = c.hostility
		if h == &"V":
			h = &"H" if rng.randf() < float(spawns["variable-hostility"]["H"]) else &"N"
		var positions: Array = []
		var spread := int(spawns["group-spread"])
		for i in count:
			var x := cx + rng.randi_range(-spread, spread); var y := cy + rng.randi_range(-spread, spread)
			var ground: int = gen.height_at(x, y)
			var in_water: bool = ground < gen.sea_level
			if in_water != (c.category == Model.CreatureCategory.AQUATIC) and spawns["aquatic-only-in-water"]:
				continue
			positions.append(Vector3(x + 0.5, (gen.sea_level if in_water else ground) + 1.0, y + 0.5))
		if positions.is_empty():
			continue
		var lvl: int = gen.creature_level(land, party_level, party_level, rng)
		var pb := rng.randf_range(float(gen.enemy_hp["power-base"][0]), float(gen.enemy_hp["power-base"][1]))
		var max_hp := Model.stat_curve(lvl, 0) * 200.0 * pow(2.0, pb * 0.25)      # design.enemy-hp.formula
		var dmg := Combat.enemy_damage(lvl, pb, design["combat"])
		var cr: Dictionary = design["creature-roles"]                 # D26: one combat-role per group, rolled last
		var role := str(c.combat_role)                                # so every earlier roll keeps its old value
		if role == "any-class":
			role = _roll_role(cr["any-class"], rng)                   # humanoids roll a class per group
			# ponytail: the roll is the whole "class" — no spec, equipment or appearance behind it (todo_implement.md)
		elif not cr.has(role):
			role = str(cr["default"])                                 # no role in creatures.json (or `none`): melee
		out.append({"species": StringName(c.id), "level": lvl, "hostility": h, "max_hp": max_hp, "damage": dmg, "positions": positions, "role": role, "seed": rng.randi()})
	return out

## design.creature-roles.any-class: weighted pick from the group's rng (same seed → same role).
static func _roll_role(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for k in weights:
		total += float(weights[k])
	var r := rng.randf() * total
	for k in weights:
		r -= float(weights[k])
		if r <= 0.0:
			return str(k)
	return str(weights.keys()[-1])

## Instantiate a plan under `parent` (the zone node). Returns the creatures.
## `ontology` set → every creature drops gen-loot on death (items.gd); null (tests) → no loot.
static func populate(parent: Node3D, plan_: Array, design: Dictionary, creatures: Dictionary, target: Node3D, ontology = null) -> Array:
	var spawns: Dictionary = design["spawns"]
	var made: Array = []
	for g in plan_:
		var c: Model.Creature = creatures[g["species"]]
		var cat: String = Model.CreatureCategory.keys()[c.category].to_lower().replace("_", "-")
		var size := float(spawns["size-by-category"].get(cat, 1.0))
		var color := Color(spawns["hostility-colors"].get(g["hostility"], "#e6e6e6"))
		for i in g["positions"].size():
			var m: CharacterBody3D = CREATURE.instantiate()
			m.position = g["positions"][i] - parent.position          # zone nodes sit at the zone origin, unrotated
			m.home = g["positions"][i]
			parent.add_child(m)
			m.target = target
			m.setup(g["species"], g["level"], g["max_hp"], g["damage"], g["hostility"], spawns["ai"], design["combat"]["enemy-attack"], size, color, g["seed"] + i)
			m.flash_s = float(design["combat"]["hit-flash-s"]); m.design = design
			var cr: Dictionary = design["creature-roles"]             # D26: what this role does, species override on top
			m.role = StringName(g.get("role", cr["default"]))
			m.role_cfg = (cr[str(m.role)] as Dictionary).duplicate(true)
			m.role_cfg.merge((cr["species"].get(str(g["species"]), {}) as Dictionary).duplicate(true), true)
			m._learn_feel(target)                                     # the shots need the player's feel node at spawn
			if ontology != null:
				m.died.connect(func() -> void: Items.drop_for(m, ontology, design))
			made.append(m)
	return made
