## Initial encounter geography and stable assignments. Plain JSON data; no nodes or mutable incarnations.
## Cardinal layouts keep block geometry exact, including at the finite world's large coordinates.
extends RefCounted
const Settlement := preload("res://game/world/settlement.gd")
const Spawner := preload("res://game/world/spawner.gd")
const Combat := preload("res://game/combat/combat.gd")
const Targeting := preload("res://game/combat/targeting.gd")


static func rotate(x: float, z: float, turn: int) -> Vector2:
	match posmod(turn, 4):
		1:
			return Vector2(-z, x)
		2:
			return Vector2(-x, -z)
		3:
			return Vector2(z, -x)
	return Vector2(x, z)


static func point(site: Dictionary, x: float, z: float) -> Vector2:
	return Vector2(site.centre[0], site.centre[1]) + rotate(x, z, site.turn)


static func rect(site: Dictionary, local: Array) -> Array:
	var a := point(site, local[0], local[1])
	var b := point(site, local[2], local[3])
	return [minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y)]


static func make_site(
	gen, land, centre: Vector2i, turn: int, family: String, ordinal: int, cfg: Dictionary
) -> Dictionary:
	var rules: Dictionary = cfg[family]
	var site := {
		"family": family,
		"ordinal": ordinal,
		"centre": [centre.x, centre.y],
		"turn": turn,
		"floor":
		maxi(gen._raw_height(centre.x, centre.y) + 1, gen.sea_level + int(cfg["dry-above-sea"])),
		"components": [],
		"volumes": [],
		"assignments": []
	}
	var rng := RandomNumberGenerator.new()
	rng.seed = land.land_seed ^ hash(family + str(ordinal))
	var rooms: Array = []
	if family == "ruins":
		var r: Dictionary = rules
		var x := -float(r.bounds[0]) / 2
		var right: float = x + r.room[0]
		var z := -float(r.bounds[1]) / 2
		site.components.append([x, z, right, z + r.court[1]])
		z += r.court[1]
		var middle: float = x + r.room[0] / 2.0
		site.components.append(
			[middle - r.passage[0] / 2.0, z, middle + r.passage[0] / 2.0, z + r.passage[1]]
		)
		z += r.passage[1]
		for i in r["pack-tiers"].size():
			var room := [x, z, right, z + r.room[1]]
			rooms.append(room)
			site.components.append(room)
			z += r.room[1]
			if i < r["pack-tiers"].size() - 1:
				site.components.append(
					[
						middle - r.corridor[0] / 2.0,
						z,
						middle + r.corridor[0] / 2.0,
						z + r.corridor[1]
					]
				)
				z += r.corridor[1]
		site.components.append(
			[
				right,
				rooms[1][1] + r.room[1] / 3.0,
				right + r.alcove[0],
				rooms[1][1] + r.room[1] / 3.0 + r.alcove[1]
			]
		)
		site.entry = [middle, -float(r.bounds[1]) / 2]
	else:
		var half := float(rules.size) / 2
		site.components.append([-half, -half, half, half])
		site.entry = [0, -half]
		rooms = [[-half, -half, 0, 0], [0, 0, half, half]]
		site.tier = rules.tier if family == "camp" else rules.tiers[ordinal]
		if family == "supplier":
			var captive := point(site, 0, half / 2)
			site.captive = [captive.x, site.floor, captive.y]
	for component in site.components:
		var b := rect(site, component)
		site.volumes.append(
			[
				b[0],
				site.floor + rules.occupancy[0],
				b[1],
				b[2],
				site.floor + rules.occupancy[1],
				b[3]
			]
		)
	for i in rooms.size():
		var room: Array = rooms[i]
		var cx: float = (room[0] + room[2]) / 2
		var cz: float = (room[1] + room[3]) / 2
		var role := Spawner._roll_role(cfg["role-weights"], rng)
		var tier: int = rules["pack-tiers"][i] if family == "ruins" else site.tier
		for member in int(cfg["pack-size"]):
			# Spread guards across the room, outside its central four-wide traversal lane.
			var offset: float = (
				(member - (cfg["pack-size"] - 1) / 2.0)
				* float(rules.room[1] if family == "ruins" else rules.size / 2)
				/ 4
			)
			assignment(
				site,
				str(i),
				member,
				cx - (room[2] - room[0]) / 4,
				cz + offset,
				tier,
				false,
				role,
				rng,
				cfg
			)
	var tiers: Array = rules["boss-tiers"] if family == "ruins" else [site.tier]
	for i in tiers.size():
		var room: Array = rooms[i + 1] if family == "ruins" else site.components[0]
		var cx: float = (room[0] + room[2]) / 2
		var cz: float = (room[1] + room[3]) / 2
		assignment(
			site,
			str(rooms.size() + i),
			0,
			cx + (room[2] - room[0]) / 4,
			cz,
			tiers[i],
			true,
			Spawner._roll_role(cfg["role-weights"], rng),
			rng,
			cfg
		)
	return site


static func assignment(
	site: Dictionary,
	pack: String,
	member: int,
	x: float,
	z: float,
	tier: int,
	boss: bool,
	role: String,
	rng: RandomNumberGenerator,
	cfg: Dictionary
) -> void:
	var p := point(site, x, z)
	site.assignments.append(
		{
			"key": pack + "/" + str(member),
			"pack": pack,
			"home": [p.x, site.floor, p.y],
			"role": role,
			"tier": tier,
			"boss": boss,
			"seed": rng.randi(),
			"special": Spawner._roll_role(cfg["boss-specials"], rng) if boss else "",
			"spirit":
			Spawner._roll_role(cfg.spirits, rng) if boss and site.family == "ruins" else ""
		}
	)


static func plan(gen, land, v: Dictionary, cfg: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = land.land_seed ^ hash("initial-encounters")
	var radius := rng.randi_range(int(cfg["distance-min"]) + 1, int(cfg["distance-max"]))
	var a := roundi(radius / 2.0)
	var b := roundi(radius * sqrt(3.0) / 2)
	var offsets := [
		Vector2i(radius, 0),
		Vector2i(a, b),
		Vector2i(-a, b),
		Vector2i(-radius, 0),
		Vector2i(-a, -b),
		Vector2i(a, -b)
	]
	var shift := rng.randi_range(0, offsets.size() - 1)
	var sites: Array = []
	for i in offsets.size():
		var offset: Vector2i = offsets[(i + shift) % offsets.size()]
		var turn := 3 if offset.x > 0 else 1
		if absi(offset.y) > absi(offset.x):
			turn = 0 if offset.y > 0 else 2
		var family := "ruins" if i == 0 else ("camp" if i == 1 else "supplier")
		sites.append(make_site(gen, land, v.centre + offset, turn, family, maxi(0, i - 2), cfg))
	# Retain the authored empty-house opening, not an external connection-access test.
	var house: int = gen.settlement.buildings.find("house")
	v.merge(Settlement.opening(gen.settlement, house, cfg.ruins.door[0]), true)
	var out := {
		"village":
		{
			"centre": [v.centre.x, v.centre.y],
			"height": v.height,
			"name": v.name,
			"style": str(v.style),
			"hub": v.hub,
			"gate_index": v.gate_index,
			"gate_width": v.gate_width,
			"gate_offset": v.gate_offset
		},
		"sites": sites
	}
	var errors := validate(gen, out, cfg)
	return out if errors.is_empty() else {"error": "; ".join(errors)}


## Optional decoration only. All vector arithmetic is village-local, including at world limits.
## Samples existing terrain; never searches for walkability or adds connecting supports.
static func guidance(gen, plan_: Dictionary, cfg: Dictionary) -> Array:
	var out: Array = []
	var village: Array = plan_.village.centre
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([gen.world_seed, village, "guidance"])
	for i in plan_.sites.size():
		var site: Dictionary = plan_.sites[i]
		var delta := Vector2(float(site.centre[0]) - village[0], float(site.centre[1]) - village[1])
		var distance := delta.length()
		var unit := delta / distance
		var family: String = cfg["leading-objects"][site.family]
		var road := {"destination": i, "family": family, "markers": []}
		var next := 40.0
		while next < distance - 16:
			var side := rng.randf_range(-5, 5)
			var x := int(village[0]) + roundi(unit.x * next - unit.y * side)
			var z := int(village[1]) + roundi(unit.y * next + unit.x * side)
			next += rng.randf_range(14, 22)
			if not gen.valid_block(x - 1, z - 1) or not gen.valid_block(x + 1, z + 1):
				continue
			var free := true
			for other in plan_.sites:
				for volume in other.volumes:
					if (
						x >= volume[0] - cfg.apron - 1
						and x <= volume[3] + cfg.apron + 1
						and z >= volume[2] - cfg.apron - 1
						and z <= volume[5] + cfg.apron + 1
					):
						free = false
			var top: int = gen.height_at(x, z) + 1
			if not free or top <= gen.sea_level + 1:
				continue
			road.markers.append(
				{
					"x": x,
					"z": z,
					"top": top,
					"family": family,
					"bounds": [x - 0.75, z - 0.7, x + 0.75, z + 0.7]
				}
			)
		out.append(road)
	return out


static func validate(gen, plan_: Dictionary, cfg: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var v: Dictionary = plan_.village
	var square := Vector2(v.centre[0], v.centre[1])
	var half := float(cfg["hub-size"]) / 2
	if (
		not gen.valid_block(square.x - half, square.y - half)
		or not gen.valid_block(square.x + half, square.y + half)
	):
		errors.append("village hub outside finite bounds")
	for site in plan_.sites:
		var centre := Vector2(site.centre[0], site.centre[1])
		var distance := centre.distance_to(square)
		if distance < cfg["distance-min"] or distance > cfg["distance-max"]:
			errors.append("site distance " + site.family)
		for other in plan_.sites:
			if (
				other != site
				and centre.distance_to(Vector2(other.centre[0], other.centre[1])) < cfg.separation
			):
				errors.append("site separation")
		for volume in site.volumes:
			if (
				not gen.valid_block(volume[0] - cfg.apron, volume[2] - cfg.apron)
				or not gen.valid_block(volume[3] + cfg.apron, volume[5] + cfg.apron)
			):
				errors.append("site/apron outside finite bounds")
		for m in site.assignments:
			if (
				Vector2(m.home[0], m.home[2]).distance_to(square) - float(gen.ai_leash)
				< float(gen.settlement["no-hostiles-within"])
			):
				errors.append("home/pursuit crosses protected village")
	return errors


static func height(level: int, cfg: Dictionary) -> float:
	var h: Dictionary = cfg["boss-height"]
	return (
		float(h.base)
		* (
			float(h["min-mult"])
			+ (
				float(h.growth)
				* (clampi(level, 1, int(h["max-level"])) - 1)
				/ (float(h["max-level"]) - 1)
			)
		)
	)


static func incarnation(
	gen,
	land,
	stable: Dictionary,
	id: String,
	levels: Array,
	design: Dictionary,
	cycle: int = 0,
	room_level: int = 0
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(stable.seed) ^ hash("incarnation" + str(cycle))
	var level: int = (
		room_level if room_level > 0 else gen.creature_level(land, levels[0], levels[1], rng)
	)
	var cfg: Dictionary = design["initial-encounters"]
	var power := float(cfg["power-base-offset"]) + int(stable.tier)
	var hp := (
		Combat.enemy_max_hp(level, power) * (float(cfg["boss-hp-mult"]) if stable.boss else 1.0)
	)
	var out := {
		"species": cfg.species,
		"level": level,
		"power_base": power,
		"max_hp": hp,
		"hp": hp,
		"damage":
		(
			Combat.enemy_damage(level, power, design.combat)
			* (float(cfg["boss-damage-mult"]) if stable.boss else 1.0)
		),
		"hostility": "H",
		"role": stable.role,
		"home": stable.home.duplicate(),
		"position": stable.home.duplicate(),
		"pack": id.get_base_dir(),
		"seed": stable.seed,
		"dead": false,
		"eligible": false,
		"cycle": cycle,
		"combat": Targeting.fresh()
	}
	if stable.boss:
		out.special = {
			"phase": "ready",
			"left": cfg["special-profile"]["ready-s"],
			"recovery": 0.0,
			"engaged": false,
			"origin": [],
			"endpoint": [],
			"target": ""
		}
	return out


## A separate stream never perturbs permanent geography/roles/special/spirit draws.
static func room_levels(gen, land, layout: Dictionary, levels: Array, cycle: int) -> Array:
	var out: Array = []
	if layout.family != "ruins":
		return out
	for i in layout.components.size():
		if i not in [2, 4, 6]:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = land.land_seed ^ hash("room-level/" + str(i) + "/" + str(cycle))
		out.append(gen.creature_level(land, levels[0], levels[1], rng))
	return out


## Authored decorations stay off the central four-wide route and all door/exit/support masks.
static func content_plan(layout: Dictionary, cfg: Dictionary) -> Dictionary:
	var out := {"rubble": {}, "props": {}, "traps": []}
	for stable in layout.assignments:
		if not stable.boss:
			continue
		var offsets := [[-2, -2], [0, -3], [0, -2], [-3, 0], [-2, 2], [0, 3], [0, 2], [-2, 0]]
		for i in int(cfg.rubble["per-arena"]):
			var offset := rotate(offsets[i][0], offsets[i][1], layout.turn)
			out.rubble[stable.key + "/" + str(i)] = [
				float(stable.home[0]) + offset.x, layout.floor, float(stable.home[2]) + offset.y
			]
	if layout.family == "ruins":
		for room in cfg.ruins["pack-tiers"].size():
			var r: Array = layout.components[2 + room * 2]
			var middle: float = (r[1] + r[3]) / 2
			for vase in int(cfg.furnishings.vase["per-room"]):
				var p := point(layout, r[0] + 3, middle + (-8 if vase == 0 else 8))
				out.props["room/%d/vase/%d" % [room, vase]] = {
					"point": [p.x, layout.floor, p.y], "kind": "vase", "room": room
				}
			var table := point(layout, r[2] - 3, middle + 8)
			out.props["room/%d/table/0" % room] = {
				"point": [table.x, layout.floor, table.y], "kind": "table", "room": room
			}
			if room < int(cfg.spikes.count):
				var trap := point(layout, r[0] + 3, middle)
				out.traps.append({"point": [trap.x, layout.floor, trap.y]})
	return out


static func fresh_contents(layout: Dictionary, cfg: Dictionary) -> Dictionary:
	var plan_ := content_plan(layout, cfg)
	var out := {"rubble": {}, "props": {}, "traps": []}
	for key in plan_.rubble:
		out.rubble[key] = {"broken": false, "restore_at": 0.0}
	for key in plan_.props:
		out.props[key] = {"hp": cfg.furnishings[plan_.props[key].kind].hp}
	for trap in plan_.traps:
		out.traps.append({"phase": "idle", "left": 0.0, "hit": []})
	return out
