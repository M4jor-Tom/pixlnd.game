## gen-spawns (§6) for the open world: per zone, seeded from (world seed, zone), 0–2 groups of one
## species from the land's landscape roster (D14). Creatures are children of the zone node, so they
## unload with it. The injected saved-world dictionary retains logical incarnations across streaming.
## Dungeon, settlement and boss generation is separate.
extends RefCounted

const CREATURE := preload("res://game/entities/creature.tscn")
const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Targeting := preload("res://game/combat/targeting.gd")
const Combat := preload("res://game/combat/combat.gd")


## Deterministic plan for one zone: [{species, level, hostility, positions: [Vector3], role}].
static func plan(
	gen,
	zc: Vector2i,
	design: Dictionary,
	creatures: Dictionary,
	rosters: Dictionary,
	party_level: int,
	party_max: int = -1
) -> Array:
	var spawns: Dictionary = design["spawns"]
	var out: Array = []
	if not gen.valid_zone(zc):
		return out
	var n: int = gen.terrain["zone-blocks"]
	var land = gen.land_of_block(zc.x * n + n / 2, zc.y * n + n / 2)
	var roster: Array = rosters.get(land.landscape, [])
	var skip: Array = spawns["skip-categories"]
	var pool: Array = roster.filter(
		func(id: String) -> bool:
			return (
				creatures.has(id)
				and not creatures[id].boss_species
				and not (
					Model.CreatureCategory.keys()[creatures[id].category].to_lower().replace(
						"_", "-"
					)
					in skip
				)
			)
	)
	if pool.is_empty():
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(gen.world_seed, zc.x, zc.y)) ^ hash("spawns")
	for g in rng.randi_range(int(spawns["groups-per-zone"][0]), int(spawns["groups-per-zone"][1])):
		var c: Model.Creature = creatures[pool[rng.randi() % pool.size()]]
		var size := (
			c.group_size
			if c.group_size != Vector2i(1, 1)
			else Vector2i(int(spawns["default-group"][0]), int(spawns["default-group"][1]))
		)
		var count := rng.randi_range(size.x, size.y)
		var cx := zc.x * n + rng.randi_range(4, n - 5)
		var cy := zc.y * n + rng.randi_range(4, n - 5)
		var v: Dictionary = gen.village_at(land)  # c-hostile-in-city (D22): no wild groups near the square
		if (
			not v.is_empty()
			and (
				Vector2(cx - v["centre"].x, cy - v["centre"].y).length()
				< float(design.get("settlement", {}).get("no-hostiles-within", 0))
			)
		):
			continue
		var h: StringName = c.hostility
		if h == &"V":
			h = &"H" if rng.randf() < float(spawns["variable-hostility"]["H"]) else &"N"
		var positions: Array = []
		var spread := int(spawns["group-spread"])
		for i in count:
			var x := cx + rng.randi_range(-spread, spread)
			var y := cy + rng.randi_range(-spread, spread)
			if gen.reserved_ground(x, y):
				continue
			var ground: int = gen.height_at(x, y)
			var in_water: bool = ground < gen.sea_level
			if (
				in_water != (c.category == Model.CreatureCategory.AQUATIC)
				and spawns["aquatic-only-in-water"]
			):
				continue
			positions.append(
				Vector3(x + 0.5, (gen.sea_level if in_water else ground) + 1.0, y + 0.5)
			)
		if positions.is_empty():
			continue
		var lvl: int = gen.creature_level(
			land, party_level, party_level if party_max < 0 else party_max, rng
		)
		var pb := rng.randf_range(
			float(gen.enemy_hp["power-base"][0]), float(gen.enemy_hp["power-base"][1])
		)
		var max_hp := Combat.enemy_max_hp(lvl, pb)  # design.enemy-hp.formula
		var dmg := Combat.enemy_damage(lvl, pb, design["combat"])
		var gseed := rng.randi()  # the group seed, the last draw of the zone rng
		var cr: Dictionary = design["creature-roles"]  # D26: one combat-role per group, off a private
		var role := str(c.combat_role)  # rng so the shared zone stream is untouched
		if role == "any-class":
			var rr := RandomNumberGenerator.new()
			rr.seed = gseed ^ hash("role")
			role = _roll_role(cr["any-class"], rr)  # humanoids roll a class per group
			# ponytail: the roll is the whole "class" — no spec, equipment or appearance behind it (todo_implement.md)
		elif not cr.has(role):
			role = str(cr["default"])  # no role in creatures.json (or `none`): melee
		out.append(
			{
				"species": StringName(c.id),
				"level": lvl,
				"hostility": h,
				"max_hp": max_hp,
				"damage": dmg,
				"power_base": pb,
				"positions": positions,
				"role": role,
				"seed": gseed
			}
		)
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
static func populate(
	parent: Node3D,
	plan_: Array,
	design: Dictionary,
	creatures: Dictionary,
	target: Node3D,
	ontology = null,
	authority: Node = null,
	prefix: String = "",
	saved_mobs: Dictionary = {},
	ready: Callable = Callable()
) -> Array:
	var spawns: Dictionary = design["spawns"]
	if authority == null:
		authority = Targeting.new()
		parent.add_child(authority)
		# Godot diagnoses a freed Node capture before entering a lambda, even behind is_instance_valid.
		var player_ref: WeakRef = weakref(target) if target != null else null
		authority.configure(
			design,
			func():
				var present: Node = player_ref.get_ref() if player_ref != null else null
				return [present] if is_instance_valid(present) else []
		)
	if target != null and "targeting" in target:
		target.targeting = authority
	if prefix == "":
		prefix = str(parent.get_instance_id())
	var made: Array = []
	for group_index in plan_.size():
		var g: Dictionary = plan_[group_index]
		var c: Model.Creature = creatures[g["species"]]
		var cat: String = Model.CreatureCategory.keys()[c.category].to_lower().replace("_", "-")
		var size := float(spawns["size-by-category"].get(cat, 1.0))
		var color := Color(spawns["hostility-colors"].get(g["hostility"], "#e6e6e6"))
		for i in g["positions"].size():
			var id := "%s/%s/%d" % [prefix, str(group_index), i]
			var pack := "%s/%s" % [prefix, str(group_index)]
			var saved: Dictionary = saved_mobs.get(id, {})
			if authority.live.has(id):
				continue
			if not saved.is_empty() and saved.dead and not saved.eligible:
				continue
			var at: Array = (
				(saved.home if saved.dead else saved.position)
				if not saved.is_empty()
				else [g.positions[i].x, g.positions[i].y, g.positions[i].z]
			)
			if ready.is_valid() and not ready.call(at):
				continue  # no incarnation/cycle changes until its actual destination has support
			if not saved.is_empty() and saved.dead:
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
			var spawn: Dictionary = (
				saved
				if not saved.is_empty()
				else {
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
			)
			if g.has("power_base") and not spawn.has("power_base"):
				spawn.power_base = g.power_base
			saved_mobs[id] = spawn
			var m := materialize(parent, spawn, id, design, target, authority, size, color)
			if ontology != null:
				m.died.connect(func() -> void: Items.drop_for(m, ontology, design))
			made.append(m)
	return made


## Shared physical creature factory: ambient and encounter owners supply their own logical/stat policy.
static func materialize(
	parent: Node3D,
	spawn: Dictionary,
	id: String,
	design: Dictionary,
	target: Node3D,
	authority: Node,
	size: float,
	color: Color
) -> CharacterBody3D:
	var m: CharacterBody3D = CREATURE.instantiate()
	var frame = parent.get_meta("local_frame") if parent.has_meta("local_frame") else null
	var reference: Array = (
		frame.to_logical(parent.global_position)
		if frame != null
		else [parent.position.x, parent.position.y, parent.position.z]
	)
	m.position = Vector3(
		float(spawn.position[0]) - reference[0],
		float(spawn.position[1]) - reference[1],
		float(spawn.position[2]) - reference[2]
	)  # zone nodes sit at the zone origin, unrotated
	m.home = Vector3(spawn.home[0], spawn.home[1], spawn.home[2])
	m.target = target
	m.setup(
		StringName(spawn.species),
		int(spawn.level),
		spawn.max_hp,
		spawn.damage,
		StringName(spawn.hostility),
		design["spawns"]["ai"],
		design["combat"]["enemy-attack"],
		size,
		color,
		int(spawn.seed),
		float(design["combat"]["creature-resistance"])
	)
	m.hp = spawn.hp
	m.flash_s = float(design["combat"]["hit-flash-s"])
	m.design = design
	var cr: Dictionary = design["creature-roles"]  # D26: what this role does, species override on top
	m.role = StringName(spawn.role)
	m.role_cfg = (cr[str(m.role)] as Dictionary).duplicate(true)
	m.role_cfg.merge(
		(cr.get("species", {}).get(str(spawn.species), {}) as Dictionary).duplicate(true), true
	)
	m.incarnation = spawn
	parent.add_child(m)
	if frame != null:
		frame.place_entity(m, spawn.position, true)
	m.set_physics_process(true)
	authority.attach(m, id, spawn.pack, spawn.combat)
	spawn.combat = authority.record(m)
	if spawn.combat.returning:
		m.state = m.State.RETURN
	m.tree_exiting.connect(
		func():
			spawn.position = m.logical_position()
			spawn.hp = m.hp
			authority.detach(m)
	)
	m._learn_feel(target)  # the shots need the player's feel node at spawn
	return m
