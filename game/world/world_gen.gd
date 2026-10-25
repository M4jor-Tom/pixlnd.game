## gen-world, gen-climate, gen-terrain (heightfield) and gen-name (land) from ontology/domain/index.md §6.
## Pure and seeded: same (seed, design, landscapes) → same output. Ontology axes: x, y horizontal,
## z up, in blocks; the mesher maps them to Godot (x, h, y). Numbers: generators.json#design (D12).
extends RefCounted

const Encounters := preload("res://game/world/encounter_gen.gd")


class Land:
	var coords: Vector2i
	var land_seed: int
	var landscape: StringName
	var name: String
	var temp: float  # 0..1 (HUD: design.climate.hud)
	var humidity: float  # 0..1
	var relief: float  # landscapes.json#<id>.gen
	var base: float
	var surface: StringName
	var top: Color
	var cliff: Color
	var danger_tier: StringName  # F4: safe / normal / dangerous, rolled once per land
	var village: Dictionary = {}  # D22 layout plus joint generation's dry hub / access gate
	var village_searched := false
	var encounter_plan: Dictionary = {}


const FIELD_NAMES := ["temp", "humidity", "continent", "relief", "roll"]

var world_seed: int
var terrain: Dictionary  # design.terrain
var climate: Dictionary  # design.climate
var names: Dictionary  # design.names
var enemy_level: Dictionary  # design.enemy-level (F4)
var enemy_hp: Dictionary  # design.enemy-hp (D14)
var settlement: Dictionary  # design.settlement (D22); empty = no villages
var landscapes := {}  # id → Model.Landscape, only those with a `gen` block (hybrid)
var land_blocks: int
var land_min: int
var land_max: int
var sea_level: int
var encounter_config: Dictionary
var ai_leash: float
var saved_lands: Dictionary = {}  # injected saved geography; runtime never rerolls it
var diagnostics: Array[String] = []
var _patches: Dictionary = {}  # generated column cuts/supports, only for the active hub neighbourhood

var _height := FastNoiseLite.new()
var _fields := {}  # climate field → FastNoiseLite, sampled in land units
var _rules: Array = []  # [[landscape id, Expression]] in design.climate.rules order
var _lands := {}  # Vector2i → Land (every roll of a land is derived once)
var _cells := {}  # Vector2i cell → blended relief/base/palette (see _cell)
var cell_blocks: int
var _h_base: float
var _h_amp: float
var _h_min: int
var _h_max: int
var _cliff_slope: float


func _init(p_seed: int, design: Dictionary, p_landscapes: Dictionary) -> void:
	world_seed = p_seed
	terrain = design["terrain"]
	climate = design["climate"]
	names = design["names"]
	enemy_level = design["enemy-level"]
	enemy_hp = design["enemy-hp"]
	settlement = design.get("settlement", {})
	encounter_config = design["initial-encounters"]
	ai_leash = float(design.spawns.ai.leash)
	land_blocks = int(terrain["land-blocks"])
	sea_level = int(terrain["sea-level"])
	land_min = -int(terrain["lands-per-axis"]) / 2
	land_max = land_min + int(terrain["lands-per-axis"]) - 1
	for id in p_landscapes:
		if not p_landscapes[id].gen.is_empty():
			landscapes[id] = p_landscapes[id]
	cell_blocks = int(terrain["zone-blocks"])
	_cliff_slope = float(terrain["cliff-slope"])
	_h_min = int(terrain["height"]["min"])
	_h_max = int(terrain["height"]["max"])
	var hf: Dictionary = terrain["heightfield"]
	_h_base = float(hf["base"])
	_h_amp = float(hf["amplitude"])
	_height.seed = world_seed
	_height.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_height.fractal_type = FastNoiseLite.FRACTAL_FBM
	_height.fractal_octaves = int(hf["octaves"])
	_height.frequency = float(hf["frequency"])
	_height.fractal_lacunarity = float(hf["lacunarity"])
	_height.fractal_gain = float(hf["gain"])
	var k := 1
	for f in ["temp", "humidity", "continent", "relief"]:
		var n := FastNoiseLite.new()
		n.seed = world_seed + k
		k += 1
		n.fractal_octaves = int(climate["field-octaves"])
		n.frequency = float(climate["field-frequency-lands"])
		_fields[f] = n
	for rule in climate["rules"]:
		var e := Expression.new()
		if e.parse(rule[1], FIELD_NAMES) != OK:
			push_error("design.climate rule '%s': %s" % [rule[1], e.get_error_text()])
			continue
		_rules.append([StringName(rule[0]), e])


# --- lands -----------------------------------------------------------------------------------


func valid_land(lc: Vector2i) -> bool:
	return lc.x >= land_min and lc.x <= land_max and lc.y >= land_min and lc.y <= land_max


func valid_block(x: float, y: float) -> bool:
	return (
		x >= land_min * land_blocks
		and x < (land_max + 1) * land_blocks
		and y >= land_min * land_blocks
		and y < (land_max + 1) * land_blocks
	)


func valid_zone(zc: Vector2i) -> bool:
	var n: int = terrain["land-zones"]
	return (
		zc.x >= land_min * n
		and zc.x < (land_max + 1) * n
		and zc.y >= land_min * n
		and zc.y < (land_max + 1) * n
	)


func land_at(lc: Vector2i) -> Land:
	if not valid_land(lc):
		return null
	if _lands.has(lc):
		return _lands[lc]
	var l := Land.new()
	l.coords = lc
	l.land_seed = hash(Vector3i(world_seed, lc.x, lc.y))
	var rng := RandomNumberGenerator.new()
	rng.seed = l.land_seed
	var v := {}
	for f in _fields:
		v[f] = clampf(_fields[f].get_noise_2d(lc.x, lc.y) * 0.8 + 0.5, 0.0, 1.0)
	v["roll"] = rng.randf()
	l.temp = v["temp"]
	l.humidity = v["humidity"]
	var inputs: Array = FIELD_NAMES.map(func(n: String) -> float: return v[n])
	for r in _rules:
		if r[1].execute(inputs) == true and landscapes.has(r[0]):
			l.landscape = r[0]
			break
	if l.landscape == &"":
		l.landscape = &"greenlands"
	var g: Dictionary = landscapes[l.landscape].gen
	l.relief = float(g["relief"])
	l.base = float(g["base"])
	l.surface = StringName(g["surface"])
	l.top = Color(g["top"])
	l.cliff = Color(g["cliff"])
	l.name = _land_name(rng, l.landscape)
	l.danger_tier = _roll_tier(rng)
	_lands[lc] = l
	return l


## Weighted roll over design.enemy-level.tier-weights.
func _roll_tier(rng: RandomNumberGenerator) -> StringName:
	var weights: Dictionary = enemy_level["tier-weights"]
	var r := rng.randf()
	var acc := 0.0
	for tier in weights:
		acc += float(weights[tier])
		if r <= acc:
			return StringName(tier)
	return StringName(weights.keys()[-1])


## Creature level in this land for a party level band (solo: own level). design.enemy-level.
func creature_level(land: Land, party_min: int, party_max: int, rng: RandomNumberGenerator) -> int:
	var lo := maxi(1, party_min - int(enemy_level["below"]))
	var hi := party_max + int(enemy_level["above"])
	var t := float(enemy_level["danger-tiers"][land.danger_tier])
	return clampi(roundi(lerpf(lo, hi, t)) + rng.randi_range(-1, 1), lo, hi)


func land_of_block(x: int, y: int) -> Land:
	if not valid_block(x, y):
		return null
	return land_at(Vector2i(floori(float(x) / land_blocks), floori(float(y) / land_blocks)))


func _land_name(rng: RandomNumberGenerator, landscape: StringName) -> String:
	var suffixes: Array = names["land-suffix"].get(landscape, ["Plains"])
	return _syllables(rng) + " " + suffixes[rng.randi() % suffixes.size()]


func _syllables(rng: RandomNumberGenerator) -> String:
	var syl: Array = names["syllables"]
	var n := ""
	for i in rng.randi_range(2, 3):
		n += syl[rng.randi() % syl.size()]
	return n.capitalize()


# --- settlements (D22) ------------------------------------------------------------------------


## gen-settlement: bounded seeded village search, accepted only with all six sites and access.
## All-sea search failure receives the canonical dry hub; actual generation failure has diagnostics.
func village_at(l: Land) -> Dictionary:
	if l == null or settlement.is_empty():
		return {}
	encounters_at(l)
	return l.village


## A single atomic result: village, all six sites, stable assignments and every access route.
## The bounded village search is an implementation algorithm, not a reduced-site fallback.
func encounters_at(l: Land) -> Dictionary:
	if l == null or settlement.is_empty():
		return {}
	if l.village_searched:
		return l.encounter_plan
	l.village_searched = true
	var key := "%d,%d" % [l.coords.x, l.coords.y]
	if saved_lands.has(key):
		l.encounter_plan = saved_lands[key]
		_set_village(l)
		return l.encounter_plan
	var pl: Dictionary = settlement["placement"]
	var step := int(pl["search-step"])
	var min_h: int = sea_level + int(pl["min-above-sea"])
	var cx := l.coords.x * land_blocks + land_blocks / 2
	var cy := l.coords.y * land_blocks + land_blocks / 2
	var candidates: Array = [Vector2i(cx, cy)]
	for r in range(1, int(pl["search-rings"]) + 1):
		for i in 8 * r:
			var ang := TAU * i / (8 * r)
			candidates.append(
				Vector2i(cx + roundi(cos(ang) * r * step), cy + roundi(sin(ang) * r * step))
			)
	var dry: Array = candidates.filter(
		func(c): return valid_block(c.x, c.y) and _raw_height(c.x, c.y) >= min_h
	)
	var fallback := dry.is_empty()
	if fallback:
		dry = [Vector2i(cx, cy)]
	var reasons: Array[String] = []
	for c in dry:
		# A hub cannot straddle its land; reject before spending work on impossible sites/routes.
		var half := float(encounter_config["hub-size"]) / 2
		if (
			c.x - half < l.coords.x * land_blocks
			or c.y - half < l.coords.y * land_blocks
			or c.x + half >= (l.coords.x + 1) * land_blocks
			or c.y + half >= (l.coords.y + 1) * land_blocks
		):
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = l.land_seed ^ hash("village")
		var v := {
			"centre": c,
			"height": maxi(_raw_height(c.x, c.y), min_h - 1),
			"name": _syllables(rng),
			"style": StringName(str(settlement["style-by-landscape"][String(l.landscape)])),
			"hub": fallback
		}
		var result := Encounters.plan(self, l, v, encounter_config)
		if not result.has("error"):
			l.encounter_plan = result
			_set_village(l)
			return result
		reasons.append(str(c) + ": " + str(result.error))
	diagnostics.append(
		(
			"initial-encounters generation failed seed=%d land=%s candidates=%d: %s"
			% [
				world_seed,
				str(l.coords),
				dry.size(),
				(
					"; ".join(reasons)
					if not reasons.is_empty()
					else "village/hub outside finite land bounds"
				)
			]
		)
	)
	return {}


func _set_village(l: Land) -> void:
	var v: Dictionary = l.encounter_plan.village
	l.village = {
		"centre": Vector2i(v.centre[0], v.centre[1]),
		"height": v.height,
		"name": v.name,
		"style": StringName(v.style),
		"hub": v.hub,
		"gate_index": v.gate_index,
		"gate_width": v.gate_width,
		"gate_offset": v.gate_offset
	}


## Rasterize the same site supports and road slabs consumed by physical geometry. Roads cut
## underneath their lowest overlapping slab, so natural ridges cannot protrude through access.
func _install_patches(l: Land) -> void:
	var patches := {}
	var plan_: Dictionary = l.encounter_plan
	var v: Dictionary = plan_.village
	if v.hub:
		var half := int(encounter_config["hub-size"]) / 2
		for x in range(v.centre[0] - half, v.centre[0] + half):
			for z in range(v.centre[1] - half, v.centre[1] + half):
				patches[Vector2i(x, z)] = int(v.height)
	for site in plan_.sites:
		var minx := INF
		var minz := INF
		var maxx := -INF
		var maxz := -INF
		for volume in site.volumes:
			minx = minf(minx, volume[0])
			minz = minf(minz, volume[2])
			maxx = maxf(maxx, volume[3])
			maxz = maxf(maxz, volume[5])
		var apron := int(encounter_config.apron)
		for x in range(int(minx) - apron, int(maxx) + apron):
			for z in range(int(minz) - apron, int(maxz) + apron):
				patches[Vector2i(x, z)] = int(site.floor) - 1
		# The physical floor owns the top block; terrain meets its underside, never a coplanar face.
		for volume in site.volumes:
			for x in range(int(volume[0]), int(volume[3])):
				for z in range(int(volume[2]), int(volume[5])):
					patches[Vector2i(x, z)] = int(site.floor) - 2
	var roads := {}
	for road in plan_.routes:
		for slab in road.steps:
			var radius: float = (slab.width + slab.length) / 2 + 1
			for x in range(floori(slab.x - radius), ceili(slab.x + radius)):
				for z in range(floori(slab.z - radius), ceili(slab.z + radius)):
					var dx: float = x + 0.5 - slab.x
					var dz: float = z + 0.5 - slab.z
					# Cover complete columns touching the slab, including rotated village-gate edges.
					if (
						absf(dx * slab.dx + dz * slab.dz) <= slab.length / 2 + 1
						and absf(-dx * slab.dz + dz * slab.dx) <= slab.width / 2 + 1
					):
						var cell := Vector2i(x, z)
						# Cut ridges below the boardwalk; never fill the ocean bed into a solid causeway.
						var cut := mini(
							int(patches.get(cell, _village_height(x, z, v, _raw_height(x, z)))),
							int(slab.top) - 2
						)
						roads[cell] = mini(int(roads.get(cell, cut)), cut)
	patches.merge(roads, true)
	_patches[l.coords] = patches


# --- terrain ---------------------------------------------------------------------------------


## Bilinear weights of the 4 land centres around block (x, y): [[Land, weight] × 4] (design.terrain.land-blend).
## Sampled once per zone-sized cell and cached: lands are 16384 blocks wide, a 64-block step is invisible.
func _cell(x: int, y: int) -> Dictionary:
	var key := Vector2i(floori(float(x) / cell_blocks), floori(float(y) / cell_blocks))
	if _cells.has(key):
		return _cells[key]
	var c := {
		"relief": 0.0,
		"base": 0.0,
		"top": Color(0, 0, 0, 0),
		"cliff": Color(0, 0, 0, 0),
		"surface": &"",
		"land": null
	}
	var best := -1.0
	for lw in _land_blend(
		key.x * cell_blocks + cell_blocks / 2, key.y * cell_blocks + cell_blocks / 2
	):
		c["relief"] += lw[0].relief * lw[1]
		c["base"] += lw[0].base * lw[1]
		c["top"] += lw[0].top * lw[1]
		c["cliff"] += lw[0].cliff * lw[1]
		if lw[1] > best:
			best = lw[1]
			c["surface"] = lw[0].surface
			c["land"] = lw[0]
	c["top"].a = 1.0
	c["cliff"].a = 1.0
	_cells[key] = c
	return c


func _land_blend(x: int, y: int) -> Array:
	var fx := float(x) / land_blocks - 0.5
	var fy := float(y) / land_blocks - 0.5
	var x0 := floori(fx)
	var y0 := floori(fy)
	var tx := fx - x0
	var ty := fy - y0
	return [
		[
			land_at(Vector2i(clampi(x0, land_min, land_max), clampi(y0, land_min, land_max))),
			(1.0 - tx) * (1.0 - ty)
		],
		[
			land_at(Vector2i(clampi(x0 + 1, land_min, land_max), clampi(y0, land_min, land_max))),
			tx * (1.0 - ty)
		],
		[
			land_at(Vector2i(clampi(x0, land_min, land_max), clampi(y0 + 1, land_min, land_max))),
			(1.0 - tx) * ty
		],
		[
			land_at(
				Vector2i(clampi(x0 + 1, land_min, land_max), clampi(y0 + 1, land_min, land_max))
			),
			tx * ty
		]
	]


## Terrain top block, including island supports and cuts beneath physical site/access floors.
## Unreserved village plateau/blend retain D22; physical floors are rendered by encounter_site.gd.
func height_at(x: int, y: int) -> int:
	var h := _raw_height(x, y)
	if settlement.is_empty():
		return h
	var l := land_of_block(x, y)
	var v := village_at(l)
	if v.is_empty():
		return h
	var reach := (
		float(encounter_config["distance-max"])
		+ float(encounter_config.ruins.bounds[1])
		+ float(encounter_config.apron)
	)
	if absf(x - v.centre.x) <= reach and absf(y - v.centre.y) <= reach:
		if not _patches.has(l.coords):
			_install_patches(l)
		if _patches[l.coords].has(Vector2i(x, y)):
			return _patches[l.coords][Vector2i(x, y)]
	return _village_height(x, y, {"centre": [v.centre.x, v.centre.y], "height": v.height}, h)


func _village_height(x: int, y: int, v: Dictionary, h: int) -> int:
	var d := Vector2(x - v.centre[0], y - v.centre[1]).length()
	var r := float(settlement["radius"])
	var b := float(settlement["blend"])
	if d <= r:
		return v["height"]
	if d < r + b:
		return roundi(lerpf(v["height"], h, (d - r) / b))
	return h


## Ambient rosters are unchanged; authored encounter support/access is reserved from wild populations.
func reserved_ground(x: int, y: int) -> bool:
	var l := land_of_block(x, y)
	if l == null:
		return false
	var v := village_at(l)
	if v.is_empty():
		return false
	var reach := (
		float(encounter_config["distance-max"])
		+ float(encounter_config.ruins.bounds[1])
		+ float(encounter_config.apron)
	)
	if absf(x - v.centre.x) > reach or absf(y - v.centre.y) > reach:
		return false
	if not _patches.has(l.coords):
		_install_patches(l)
	return _patches[l.coords].has(Vector2i(x, y))


func _raw_height(x: int, y: int) -> int:
	var c := _cell(x, y)
	var h: float = _h_base + c["base"] + _h_amp * c["relief"] * _height.get_noise_2d(x, y)
	return clampi(int(h), _h_min, _h_max)


## Top block type + colour of column (x, y) at height h; slope = biggest step to a neighbour (blocks).
func column(x: int, y: int, h: int, slope: int) -> Dictionary:
	if h <= sea_level + int(terrain["beach-above-sea"]):
		return {"type": &"sand", "color": Color(terrain["sand-color"])}
	if h >= int(terrain["snow-above"]):
		return {"type": &"snow", "color": Color(terrain["snow-color"])}
	var c := _cell(x, y)
	if slope > _cliff_slope:
		return {"type": &"rock-building", "color": c["cliff"]}
	return {"type": c["surface"], "color": c["top"]}
