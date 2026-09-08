## gen-world, gen-climate, gen-terrain (heightfield) and gen-name (land) from domain.md §6.
## Pure and seeded: same (seed, design, landscapes) → same output. Ontology axes: x, y horizontal,
## z up, in blocks; the mesher maps them to Godot (x, h, y). Numbers: generators.json#design (D12).
extends RefCounted

class Land:
	var coords: Vector2i
	var land_seed: int
	var landscape: StringName
	var name: String
	var temp: float                 # 0..1 (HUD: design.climate.hud)
	var humidity: float             # 0..1
	var relief: float               # landscapes.json#<id>.gen
	var base: float
	var surface: StringName
	var top: Color
	var cliff: Color

const FIELD_NAMES := ["temp", "humidity", "continent", "relief", "roll"]

var world_seed: int
var terrain: Dictionary             # design.terrain
var climate: Dictionary             # design.climate
var names: Dictionary               # design.names
var landscapes := {}                # id → Model.Landscape, only those with a `gen` block (hybrid)
var land_blocks: int
var sea_level: int

var _height := FastNoiseLite.new()
var _fields := {}                   # climate field → FastNoiseLite, sampled in land units
var _rules: Array = []              # [[landscape id, Expression]] in design.climate.rules order
var _lands := {}                    # Vector2i → Land (every roll of a land is derived once)
var _cells := {}                    # Vector2i cell → blended relief/base/palette (see _cell)
var cell_blocks: int
var _h_base: float; var _h_amp: float; var _h_min: int; var _h_max: int; var _cliff_slope: float

func _init(p_seed: int, design: Dictionary, p_landscapes: Dictionary) -> void:
	world_seed = p_seed
	terrain = design["terrain"]; climate = design["climate"]; names = design["names"]
	land_blocks = int(terrain["land-blocks"]); sea_level = int(terrain["sea-level"])
	for id in p_landscapes:
		if not p_landscapes[id].gen.is_empty():
			landscapes[id] = p_landscapes[id]
	cell_blocks = int(terrain["zone-blocks"])
	_cliff_slope = float(terrain["cliff-slope"])
	_h_min = int(terrain["height"]["min"]); _h_max = int(terrain["height"]["max"])
	var hf: Dictionary = terrain["heightfield"]
	_h_base = float(hf["base"]); _h_amp = float(hf["amplitude"])
	_height.seed = world_seed
	_height.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_height.fractal_type = FastNoiseLite.FRACTAL_FBM
	_height.fractal_octaves = int(hf["octaves"]); _height.frequency = float(hf["frequency"])
	_height.fractal_lacunarity = float(hf["lacunarity"]); _height.fractal_gain = float(hf["gain"])
	var k := 1
	for f in ["temp", "humidity", "continent", "relief"]:
		var n := FastNoiseLite.new()
		n.seed = world_seed + k; k += 1
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

func land_at(lc: Vector2i) -> Land:
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
	l.temp = v["temp"]; l.humidity = v["humidity"]
	var inputs: Array = FIELD_NAMES.map(func(n: String) -> float: return v[n])
	for r in _rules:
		if r[1].execute(inputs) == true and landscapes.has(r[0]):
			l.landscape = r[0]
			break
	if l.landscape == &"":
		l.landscape = &"greenlands"
	var g: Dictionary = landscapes[l.landscape].gen
	l.relief = float(g["relief"]); l.base = float(g["base"]); l.surface = StringName(g["surface"])
	l.top = Color(g["top"]); l.cliff = Color(g["cliff"])
	l.name = _land_name(rng, l.landscape)
	_lands[lc] = l
	return l

func land_of_block(x: int, y: int) -> Land:
	return land_at(Vector2i(floori(float(x) / land_blocks), floori(float(y) / land_blocks)))

func _land_name(rng: RandomNumberGenerator, landscape: StringName) -> String:
	var syl: Array = names["syllables"]
	var n := ""
	for i in rng.randi_range(2, 3):
		n += syl[rng.randi() % syl.size()]
	var suffixes: Array = names["land-suffix"].get(landscape, ["Plains"])
	return n.capitalize() + " " + suffixes[rng.randi() % suffixes.size()]

# --- terrain ---------------------------------------------------------------------------------

## Bilinear weights of the 4 land centres around block (x, y): [[Land, weight] × 4] (design.terrain.land-blend).
## Sampled once per zone-sized cell and cached: lands are 16384 blocks wide, a 64-block step is invisible.
func _cell(x: int, y: int) -> Dictionary:
	var key := Vector2i(floori(float(x) / cell_blocks), floori(float(y) / cell_blocks))
	if _cells.has(key):
		return _cells[key]
	var c := {"relief": 0.0, "base": 0.0, "top": Color(0, 0, 0, 0), "cliff": Color(0, 0, 0, 0), "surface": &"", "land": null}
	var best := -1.0
	for lw in _land_blend(key.x * cell_blocks + cell_blocks / 2, key.y * cell_blocks + cell_blocks / 2):
		c["relief"] += lw[0].relief * lw[1]; c["base"] += lw[0].base * lw[1]
		c["top"] += lw[0].top * lw[1]; c["cliff"] += lw[0].cliff * lw[1]
		if lw[1] > best:
			best = lw[1]; c["surface"] = lw[0].surface; c["land"] = lw[0]
	c["top"].a = 1.0; c["cliff"].a = 1.0
	_cells[key] = c
	return c

func _land_blend(x: int, y: int) -> Array:
	var fx := float(x) / land_blocks - 0.5
	var fy := float(y) / land_blocks - 0.5
	var x0 := floori(fx); var y0 := floori(fy)
	var tx := fx - x0; var ty := fy - y0
	return [[land_at(Vector2i(x0, y0)), (1.0 - tx) * (1.0 - ty)], [land_at(Vector2i(x0 + 1, y0)), tx * (1.0 - ty)],
		[land_at(Vector2i(x0, y0 + 1)), (1.0 - tx) * ty], [land_at(Vector2i(x0 + 1, y0 + 1)), tx * ty]]

## Height of the top solid block of column (x, y).
func height_at(x: int, y: int) -> int:
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
