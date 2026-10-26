## Required race catalog and movesets: missing inputs must not silently skip validation.
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
	# Independent late failure and an earlier load failure must both survive.
	o.errors.append("prior load diagnostic")
	for ruleset in o.rulesets.values():
		ruleset.is_default = false
	check(not o.validate(), path + " rejected")
	var text := "\n".join(o.errors)
	check(path in text, path + " diagnosed")
	check("prior load diagnostic" in text, path + " retains prior load error")
	check("exactly one ruleset must be default" in text, path + " continues validation")


func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()


func _init() -> void:
	check(fresh().validate(), "canonical catalogs validate")
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		printerr("PIXLND_TEST_DIR must name an existing isolated absolute directory")
		quit(1)
		return
	var scratch := directory.path_join("required-catalogs")
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
	var race_path := scratch.path_join("races.json")
	var races: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(race_path))
	DirAccess.remove_absolute(race_path)
	reject(Model.Ontology.load_dir(scratch), "races")
	var missing = fresh()
	missing.configs.generators.design.erase("movesets")
	reject(missing, "design.movesets")
	var empty = fresh()
	empty.configs.generators.design.movesets = {}
	reject(empty, "design.movesets")
	for bad in [null, true, 42, "bad", [], {}, {"_doc": "metadata only"}]:
		write_json(race_path, bad)
		reject(Model.Ontology.load_dir(scratch), "races")
	for bad in [null, true, 42, "bad", [], {}]:
		var raw := races.duplicate(true)
		raw.human = bad
		write_json(race_path, raw)
		reject(Model.Ontology.load_dir(scratch), "races.human")
	for field in ["playable", "size-class"]:
		for bad in [null, 42, [], {}, "unknown"]:
			var raw := races.duplicate(true)
			raw.human[field] = bad
			write_json(race_path, raw)
			reject(Model.Ontology.load_dir(scratch), "races.human." + field)
		var raw := races.duplicate(true)
		raw.human.erase(field)
		write_json(race_path, raw)
		reject(Model.Ontology.load_dir(scratch), "races.human." + field)
	var raw := races.duplicate(true)
	raw.erase("human")
	write_json(race_path, raw)
	reject(Model.Ontology.load_dir(scratch), "races.human")
	write_json(race_path, races)
	check(Model.Ontology.load_dir(scratch).validate(), "restored raw races validate")
	for bad in [null, true, 42, "bad", []]:
		var o = fresh()
		o.configs.generators.design.movesets = bad
		reject(o, "design.movesets")
	for field in ["default", "kinds", "bow"]:
		var o = fresh()
		o.configs.generators.design.movesets.erase(field)
		reject(o, "design.movesets")
		for bad in [null, true, 42, "bad", [], {}]:
			o = fresh()
			o.configs.generators.design.movesets[field] = bad
			reject(o, "design.movesets." + field)
	for bad in [null, 42, [], {}, "missing", "kinds", "axe"]:
		var o = fresh()
		o.configs.generators.design.movesets.sword = {"as": bad}
		reject(o, "design.movesets.sword")
	for bad in [null, true, 42, "bad", [], {}]:
		var o = fresh()
		o.configs.generators.design.movesets.default.m1 = bad
		reject(o, "design.movesets.default.m1")
	for field in ["kind", "applies", "damage-mult", "finisher"]:
		var o = fresh()
		o.configs.generators.design.movesets.default.m1[field] = null
		reject(o, "design.movesets.default.m1")
	for field in ["every", "chance", "applies"]:
		var o = fresh()
		o.configs.generators.design.movesets.greatsword.m1.finisher[field] = [null]
		reject(o, "design.movesets.greatsword.m1")
	for bad in [null, "1", [], {}, true, INF, NAN]:
		var o = fresh()
		o.configs.generators.design.movesets.bow.m1.speed = bad
		reject(o, "design.movesets.bow.m1")
	for bad in [null, "true", [], 1]:
		var o = fresh()
		o.configs.generators.design.movesets.bow.m1.pierce = bad
		reject(o, "design.movesets.bow.m1")
	var o = fresh()
	o.configs.generators.design.movesets.kinds = [null]
	o.configs.generators.design.movesets.default.m1.applies = ["unknown-status"]
	reject(o, "design.movesets.kinds")
	check(
		"design.movesets.default.m1" in "\n".join(o.errors), "independent moveset errors accumulate"
	)
	# Whole-file ingestion must preserve malformed movesets for the same checker.
	var generator_path := scratch.path_join("generators.json")
	var generators: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(generator_path))
	generators.design.movesets = null
	write_json(generator_path, generators)
	reject(Model.Ontology.load_dir(scratch), "design.movesets")
	print("required catalogs ok" if failed == 0 else "required catalogs FAILED (%d)" % failed)
	quit(0 if failed == 0 else 1)
