## Headless check of the §6 gen-world invariants: `godot --headless -s game/world/test_world_gen.gd`.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
const ZoneMesh := preload("res://game/world/zone_mesh.gd")

var _failed := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _init() -> void:
	var o := Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	var design: Dictionary = o.configs["generators"]["design"]
	var a := WorldGen.new(26879, design, o.landscapes)
	var b := WorldGen.new(26879, design, o.landscapes)
	var c := WorldGen.new(1, design, o.landscapes)
	var hmin := int(design["terrain"]["height"]["min"]); var hmax := int(design["terrain"]["height"]["max"])
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	var differs := false
	for i in 300:
		var x := rng.randi_range(-200000, 200000); var y := rng.randi_range(-200000, 200000)
		var h := a.height_at(x, y)
		check(h == b.height_at(x, y), "same seed → same world at %d,%d" % [x, y])
		check(h >= hmin and h <= hmax, "height in range at %d,%d: %d" % [x, y, h])
		if h != c.height_at(x, y): differs = true
	check(differs, "different seed → different world")
	var seen := {}
	var name_re := RegEx.create_from_string("^[A-Z][a-z]+ (Plains|Hills|Mountains|Forest|Islands)$")
	for lx in range(-8, 9):
		for ly in range(-8, 9):
			var l = a.land_at(Vector2i(lx, ly))
			check(l == a.land_at(Vector2i(lx, ly)), "land cached")
			check(l.name == b.land_at(Vector2i(lx, ly)).name, "same seed → same land name")
			check(o.landscapes.has(l.landscape) and not Model.Version.X in o.landscapes[l.landscape].versions, "landscape %s is shipped content" % l.landscape)
			check(name_re.search(l.name) != null, "land name shape: '%s'" % l.name)
			seen[l.landscape] = true
	check(seen.size() >= 4, "climate rules give variety over 17×17 lands: %s" % [seen.keys()])
	var m := ZoneMesh.build(a, Vector2i.ZERO)
	check(m.get_surface_count() >= 1 and m.surface_get_array_len(0) >= 64 * 64 * 6, "zone mesh has a top quad per column")
	var below_sea := false
	for i in 64:
		for j in 64:
			if a.height_at(i, j) < a.sea_level: below_sea = true
	check((m.get_surface_count() == 2) == below_sea, "water surface iff a column is below sea level")
	print("world-gen: %d landscapes over 17×17 lands %s; origin = '%s' (%s)" % [seen.size(), seen.keys(), a.land_at(Vector2i.ZERO).name, a.land_at(Vector2i.ZERO).landscape])
	print("world-gen ok" if _failed == 0 else "world-gen FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
