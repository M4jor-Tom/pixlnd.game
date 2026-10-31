extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func fresh():
	return Model.Ontology.load_dir("res://ontology/instances")


func rejected(o, path: String) -> void:
	check(not o.validate(), path + " rejected")
	check(path in "\n".join(o.errors), path + " diagnosed")


func _init() -> void:
	var shipped = fresh()
	check(shipped.validate(), "shipped ontology valid")
	terrain_parents()
	terrain_scales()
	var multiple = fresh()
	multiple.errors.append("earlier error")
	multiple.configs["generators"]["design"]["terrain"].erase("lands-per-axis")
	multiple.configs["generators"]["design"]["terrain"].erase("zone-blocks")
	rejected(multiple, "design.terrain.lands-per-axis")
	check(
		(
			"design.terrain.zone-blocks" in "\n".join(multiple.errors)
			and "earlier error" in multiple.errors
		),
		"errors accumulate"
	)
	print("world bounds config ok" if failed == 0 else "world bounds config FAILED %d" % failed)
	quit(0 if failed == 0 else 1)


func terrain_parents() -> void:
	for path in ["generators", "design", "terrain"]:
		terrain_parent_values(path)
		var missing = fresh()
		if path == "generators":
			missing.configs.erase("generators")
		elif path == "design":
			missing.configs["generators"].erase("design")
		else:
			missing.configs["generators"]["design"].erase("terrain")
		rejected(missing, path if path == "generators" else "design.terrain")


func terrain_parent_values(path) -> void:
	for bad in [null, [], "invalid", true, {}]:
		terrain_parent_value(path, bad)


func terrain_parent_value(path, bad) -> void:
	var o = fresh()
	if path == "generators":
		o.configs["generators"] = bad
	elif path == "design":
		o.configs["generators"]["design"] = bad
	else:
		o.configs["generators"]["design"]["terrain"] = bad
	rejected(o, terrain_parent_diagnostic(path, bad))


func terrain_scales() -> void:
	for field in ["lands-per-axis", "land-blocks", "zone-blocks", "land-zones"]:
		var expected: int = {
			"lands-per-axis": 1024, "land-blocks": 16384, "zone-blocks": 64, "land-zones": 256
		}[field]
		var absent = fresh()
		absent.configs["generators"]["design"]["terrain"].erase(field)
		rejected(absent, "design.terrain." + field)
		for bad in [null, [], {}, "1024", true, -1, 0, 0.25, expected + 1, NAN, INF]:
			var o = fresh()
			o.configs["generators"]["design"]["terrain"][field] = bad
			rejected(o, "design.terrain." + field)


func terrain_parent_diagnostic(path, bad: Variant) -> String:
	return (
		"design"
		if path == "generators" and bad is Dictionary
		else path if path == "generators" else "design.terrain"
	)
