## External cliffs never reject destinations; optional decorations cannot reshape terrain.
extends SceneTree
const Domain := preload("res://game/domain/domain.gd")
const Gen := preload("res://game/world/world_gen.gd")
const Encounters := preload("res://game/world/encounter_gen.gd")
var failed := 0


class CliffGen:
	extends "res://game/world/world_gen.gd"

	func _raw_height(x: int, z: int) -> int:
		return 140 if posmod(x + z, 2) == 0 else 110


class Outside:
	extends RefCounted
	var world_seed := 1

	func valid_block(_x: int, _z: int) -> bool:
		return false


class Open:
	extends RefCounted
	var world_seed := 1
	var sea_level := 0

	func valid_block(_x: int, _z: int) -> bool:
		return true

	func height_at(_x: int, _z: int) -> int:
		return 10


class NoHeight:
	extends RefCounted
	var world_seed := 1

	func valid_block(_x: int, _z: int) -> bool:
		return true


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--guidance-boundary="):
			var mode := arg.trim_prefix("--guidance-boundary=")
			print("GUIDANCE_BOUNDARY " + JSON.stringify(_guidance_boundary(mode)))
			quit()
			return
	_run()


func _run() -> void:
	var o = Domain.Ontology.load_dir()
	var d: Dictionary = o.configs.generators.design.duplicate(true)
	var g := CliffGen.new(26879, d, o.landscapes)
	var land = g.land_at(Vector2i.ZERO)
	var village := {
		"centre": Vector2i(8192, 8192),
		"height": 140,
		"name": "Cliff",
		"style": "undead",
		"hub": false
	}
	var plan_: Dictionary = Encounters.plan(g, land, village, g.encounter_config)
	check(not plan_.has("error"), "impassable external cliffs do not reject six destinations")
	if not plan_.has("error"):
		_cliff_plan(g, land, plan_)
	for fixture in [
		[26879, Vector2i.ZERO, false],
		[1, Vector2i(511, 511), false],
		[3, Vector2i.ZERO, true],
		[9001, Vector2i(-512, -512), false]
	]:
		_benchmark(o, fixture)
	_boundary_cases()
	print("natural guidance ok" if failed == 0 else "natural guidance FAILED")
	quit(0 if failed == 0 else 1)


func _cliff_plan(g: CliffGen, land, plan_: Dictionary) -> void:
	check(plan_.sites.size() == 6, "all six destinations retained")
	check(not plan_.has("routes"), "required saved geography does not contain optional guidance")
	var published := g.encounters_at(land)
	var samples := []
	for x in range(8000, 8400, 7):
		samples.append(g.height_at(x, 8192))
	var guides: Array = Encounters.guidance(g, published, g.encounter_config)
	check(guides.size() == 6, "one optional branch per existing destination")
	var n := 0
	for x in range(8000, 8400, 7):
		check(g.height_at(x, 8192) == samples[n], "guidance never changes terrain")
		n += 1
	_guide_families(guides)


func _benchmark(o, fixture: Array) -> void:
	var terrain_design: Dictionary = o.configs.generators.design.duplicate(true)
	if fixture[2]:
		terrain_design.terrain.heightfield.base = 0
		terrain_design.terrain.heightfield.amplitude = 0
	var measured := Gen.new(fixture[0], terrain_design, o.landscapes)
	var began := Time.get_ticks_usec()
	var geography := measured.encounters_at(measured.land_at(fixture[1]))
	var geography_us := Time.get_ticks_usec() - began
	# Prime independent site supports, which belong to terrain, not guidance.
	measured.height_at(geography.village.centre[0], geography.village.centre[1])
	began = Time.get_ticks_usec()
	var routes := Encounters.guidance(measured, geography, measured.encounter_config)
	var guidance_us := Time.get_ticks_usec() - began
	var markers := 0
	for road in routes:
		markers += road.markers.size()
	print(
		"BENCH seed=",
		fixture[0],
		" land=",
		fixture[1],
		" ocean=",
		fixture[2],
		" geography_us=",
		geography_us,
		" guidance_us=",
		guidance_us,
		" markers=",
		markers
	)
	check(
		routes == Encounters.guidance(measured, geography, measured.encounter_config),
		"guidance deterministic independently of completion order"
	)


func _guide_families(guides: Array) -> void:
	for i in guides.size():
		check(
			(
				guides[i].family
				== [
					"masonry",
					"stake-torch",
					"broken-crate",
					"broken-crate",
					"broken-crate",
					"broken-crate"
				][i]
			),
			"destination family unchanged"
		)
		check(
			not guides[i].has("support") and not guides[i].has("corridor"),
			"no connecting supports or walkability corridor"
		)


func _guidance_boundary(mode: String) -> Dictionary:
	var gen: Variant = {"world_seed": 1}
	match mode:
		"outside":
			gen = Outside.new()
		"open":
			gen = Open.new()
		"missing-height":
			gen = NoHeight.new()
	var result := Encounters.guidance(
		gen,
		{
			"village": {"centre": [0, 0]},
			"sites": [{"centre": [100, 0], "family": "camp", "volumes": []}]
		},
		{"leading-objects": {"camp": "stake-torch"}}
	)
	return {"mode": mode, "result": result}


func _boundary_cases() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		check(false, "guidance boundaries need an existing isolated absolute PIXLND_TEST_DIR")
		return
	var open_markers := [
		{
			"x": 40,
			"z": -4,
			"top": 11,
			"family": "stake-torch",
			"bounds": [39.25, -4.7, 40.75, -3.3]
		},
		{"x": 61, "z": 1, "top": 11, "family": "stake-torch", "bounds": [60.25, 0.3, 61.75, 1.7]},
		{"x": 76, "z": -5, "top": 11, "family": "stake-torch", "bounds": [75.25, -5.7, 76.75, -4.3]}
	]
	for sample in [
		[
			"missing-bounds",
			[],
			["SCRIPT ERROR: Invalid call. Nonexistent function 'valid_block' in base 'Dictionary'."]
		],
		["outside", [{"destination": 0, "family": "stake-torch", "markers": []}], []],
		["open", [{"destination": 0, "family": "stake-torch", "markers": open_markers}], []],
		[
			"missing-height",
			[],
			[
				"SCRIPT ERROR: Invalid call. Nonexistent function 'height_at' in base 'RefCounted (NoHeight)'."
			]
		]
	]:
		_boundary_child(directory, sample)


func _boundary_child(directory: String, sample: Array) -> void:
	var output: Array = []
	var status := OS.execute(
		"timeout",
		[
			"681",
			OS.get_executable_path(),
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"-s",
			get_script().resource_path,
			"--",
			"--guidance-boundary=" + sample[0]
		],
		output,
		true
	)
	var text := "\n".join(output)
	var log := FileAccess.open(
		directory.path_join("guidance-boundary-" + sample[0] + ".log"), FileAccess.WRITE
	)
	log.store_string("exit=%d\n%s" % [status, text])
	log.close()
	check(status == 0, sample[0] + " bounded guidance child exits")
	check(
		_boundary_headers(text) == sample[2],
		sample[0] + " exact ordered native guidance diagnostics"
	)
	var observations: Array = []
	for line in text.split("\n"):
		if line.begins_with("GUIDANCE_BOUNDARY "):
			observations.append(line.trim_prefix("GUIDANCE_BOUNDARY "))
	check(
		observations == [JSON.stringify({"mode": sample[0], "result": sample[1]})],
		sample[0] + " independent guidance result and continuation"
	)


func _boundary_headers(text: String) -> Array:
	var headers: Array = []
	for line in text.split("\n"):
		if (
			line.begins_with("ERROR:")
			or line.begins_with("SCRIPT ERROR:")
			or line.begins_with("ontology INVALID")
		):
			headers.append(line)
	return headers
