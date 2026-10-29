## External cliffs never reject destinations; optional decorations cannot reshape terrain.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const Gen := preload("res://game/world/world_gen.gd")
const Encounters := preload("res://game/world/encounter_gen.gd")
var failed := 0


class CliffGen:
	extends "res://game/world/world_gen.gd"

	func _raw_height(x: int, z: int) -> int:
		return 140 if posmod(x + z, 2) == 0 else 110


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
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
		check(plan_.sites.size() == 6, "all six destinations retained")
		check(
			not plan_.has("routes"), "required saved geography does not contain optional guidance"
		)
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
	for fixture in [
		[26879, Vector2i.ZERO, false],
		[1, Vector2i(511, 511), false],
		[3, Vector2i.ZERO, true],
		[9001, Vector2i(-512, -512), false]
	]:
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
	print("natural guidance ok" if failed == 0 else "natural guidance FAILED")
	quit(0 if failed == 0 else 1)
