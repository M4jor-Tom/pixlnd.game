## Selected historical district/landscape references, not all world-description strings.
extends SceneTree

const Model := preload("res://ontology/model.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func fresh():
	return Model.Ontology.load_dir("res://ontology/instances")


func reject(o, path: String) -> void:
	check(not o.validate(), path + " fails without an unrelated error")
	o.errors.append("prior load diagnostic")
	for ruleset in o.rulesets.values():
		ruleset.is_default = false
	check(not o.validate(), path + " rejected")
	var text := "\n".join(o.errors)
	check(path in text, path + " diagnosed")
	check("prior load diagnostic" in text, path + " retains prior load error")
	check("exactly one ruleset must be default" in text, path + " continues validation")


func _init() -> void:
	var baseline = fresh()
	check(baseline.validate(), "normalized world references validate")
	var buildings: Dictionary = baseline.configs.buildings
	check(
		(
			buildings.districts.adventurer.buildings
			== [
				{"id": "class-trainer", "class": "warrior"},
				{"id": "class-trainer", "class": "ranger"},
				{"id": "class-trainer", "class": "rogue"},
				{"id": "class-trainer", "class": "mage"}
			]
		),
		"four distinct class-qualified trainers survive loading"
	)
	check(buildings.districts.adventurer.versions == ["A"], "district provenance retained")
	check(
		buildings.buildings["class-trainer"].desc == "ranger master has aim targets",
		"ranger annotation retained"
	)
	check(
		baseline.landscapes.jungles.dungeon_types == [&"temple", &"ruins"],
		"jungle dungeon IDs load without pseudo-types"
	)
	check(
		"overworld ruins" in str(baseline.landscapes.jungles.raw.notes), "jungle variant retained"
	)
	check(
		(
			baseline.landscapes.oceans.dungeon_types == [&"temple", &"island"]
			and baseline.landscapes.oceans.raw.pois == ["arena"]
		),
		"arena stays in POI family"
	)
	check(
		(
			"large islands" in str(baseline.landscapes.oceans.raw.notes)
			and "more common" in str(baseline.landscapes.oceans.raw.notes)
		),
		"ocean qualifiers retained"
	)
	check(
		(
			baseline.landscapes.deserts.dungeon_types == [&"pyramid"]
			and "unresolved" in str(baseline.landscapes.deserts.raw.notes)
		),
		"desert identity remains evidence, not a resolved alias"
	)
	for bad in [
		"missing-building",
		"class-trainer-warrior",
		null,
		42,
		[],
		{},
		{"id": "class-trainer"},
		{"id": "class-trainer", "class": "missing"},
		{"id": "class-trainer", "class": []},
		{"id": [], "class": "warrior"},
		{"id": "inn", "class": "warrior"}
	]:
		var o = fresh()
		o.configs.buildings.districts.adventurer.buildings[0] = bad
		reject(o, "buildings.districts.adventurer.buildings")
	var duplicate = fresh()
	duplicate.configs.buildings.districts.adventurer.buildings[1] = {
		"id": "class-trainer", "class": "warrior"
	}
	reject(duplicate, "buildings.districts.adventurer.buildings")
	for field in ["dungeons", "pois"]:
		for bad in [
			null,
			42,
			"temple",
			{},
			[null],
			[42],
			[{}],
			["unknown"],
			["arena" if field == "dungeons" else "temple"],
			["temple (large islands)"]
		]:
			var o = fresh()
			o.landscapes.oceans.raw[field] = bad
			reject(o, "landscapes.oceans." + field)
	var multiple = fresh()
	multiple.configs.buildings.districts.trade.buildings = ["missing"]
	multiple.landscapes.oceans.raw.dungeons = ["arena"]
	reject(multiple, "buildings.districts.trade.buildings")
	check(
		"landscapes.oceans.dungeons" in "\n".join(multiple.errors),
		"independent references accumulate"
	)
	for bad in [null, [], 42]:
		var o = fresh()
		o.configs.buildings = bad
		reject(o, "buildings")
		for field in ["districts", "buildings"]:
			o = fresh()
			o.configs.buildings[field] = bad
			reject(o, "buildings." + field)
		o = fresh()
		o.configs.buildings.districts.adventurer.buildings = bad
		reject(o, "buildings.districts.adventurer.buildings")
	check_raw_loading()
	print("world references ok" if failed == 0 else "world references FAILED (%d)" % failed)
	quit(0 if failed == 0 else 1)


func check_raw_loading() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		check(false, "PIXLND_TEST_DIR must name an existing isolated absolute directory")
		return
	var scratch := directory.path_join("world-references")
	check(DirAccess.make_dir_recursive_absolute(scratch) == OK, "scratch created")
	var source := DirAccess.open("res://ontology/instances")
	for file in source.get_files():
		if file.ends_with(".json"):
			check(
				(
					DirAccess.copy_absolute(
						ProjectSettings.globalize_path("res://ontology/instances/" + file),
						scratch.path_join(file)
					)
					== OK
				),
				"copied " + file
			)
	var path := scratch.path_join("landscapes.json")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for bad in [null, {}, [null, 42, {"id": "temple"}], ["arena"]]:
		raw.oceans.dungeons = bad
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(raw))
		file.close()
		reject(Model.Ontology.load_dir(scratch), "landscapes.oceans.dungeons")
