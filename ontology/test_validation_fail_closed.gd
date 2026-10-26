## Finding #1: malformed inputs retain diagnostics and CLI failure never exits successfully.
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
	o.errors.append("prior load diagnostic")
	# This independent check is last in validate(), after loot and movesets.
	for ruleset in o.rulesets.values():
		ruleset.is_default = false
	check(not o.validate(), path + " rejected")
	var diagnostics := "\n".join(o.errors)
	check(path in diagnostics, path + " has useful diagnostic")
	check("prior load diagnostic" in o.errors, path + " retains prior errors")
	check("exactly one ruleset must be default" in diagnostics, path + " reaches later checks")


func _init() -> void:
	# Existing selected-tree checks must keep rejecting historical loot crash cases.
	for bad in [null, true, 42, "bad", []]:
		var o = fresh()
		o.configs.generators.design.loot = bad
		reject(o, "design.loot")
	var missing = fresh()
	missing.configs.generators.design.erase("loot")
	reject(missing, "design.loot")
	for field in [
		"gear-chance", "coins", "rarity-weights", "gear-kinds", "consumable-pool", "ground"
	]:
		var o = fresh()
		o.configs.generators.design.loot.erase(field)
		reject(o, "design.loot." + field)
		for bad in [null, true, 42, "bad", [], {}]:
			o = fresh()
			o.configs.generators.design.loot[field] = bad
			reject(o, "design.loot." + field)
	# The adjacent loot reference consumer must not assume stack-cap container shapes.
	for bad in [null, true, 42, "bad", []]:
		var o = fresh()
		o.configs.generators.design["stack-cap"] = bad
		reject(o, "design.stack-cap")
	for bad in [null, true, 42, "bad", {}, [null], [42], [[]], [{}]]:
		var o = fresh()
		o.configs.generators.design["stack-cap"].stackable = bad
		reject(o, "stack-cap")
	for weapon in [&"unknown-weapon", &""]:
		var o = fresh()
		o.classes[&"mage"].weapon_types.append(weapon)
		reject(o, "class mage: unknown weapon-type")
	var absent = fresh()
	absent.weapon_types.erase(&"wand")
	reject(absent, "class mage: unknown weapon-type wand")
	check_cli()
	print(
		(
			"validation fail-closed ok"
			if failed == 0
			else "validation fail-closed FAILED (%d)" % failed
		)
	)
	quit(0 if failed == 0 else 1)


func check_cli() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		check(false, "PIXLND_TEST_DIR must name an existing isolated absolute directory")
		return
	var scratch := directory.path_join("validator-exit")
	check(DirAccess.make_dir_recursive_absolute(scratch) == OK, "CLI scratch created")
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
	var writer := FileAccess.open(scratch.path_join("broken.json"), FileAccess.WRITE)
	# The loader rejects a JSON null root without the parser emitting an engine error.
	writer.store_string("null")
	writer.close()
	# Override only loading: the inherited production entrypoint validates, prints and quits.
	var fixture := scratch.path_join("cli_fixture.gd")
	writer = FileAccess.open(fixture, FileAccess.WRITE)
	(
		writer
		. store_string(
			'''extends "res://ontology/validate.gd"
class ValidationResult:
	extends Model.Ontology
	var result := false
	func validate() -> bool:
		return result
func _load_ontology() -> Model.Ontology:
	var case: String = OS.get_cmdline_user_args()[0]
	if case == "false-empty" or case == "true-error":
		var o := ValidationResult.new()
		if case == "true-error":
			o.result = true
			o.errors.append("retained diagnostic")
		return o
	if case == "prior-load-error":
		return Model.Ontology.load_dir(get_script().resource_path.get_base_dir())
	var o := Model.Ontology.load_dir("res://ontology/instances")
	if case == "null-loot":
		o.configs.generators.design.loot = null
	if case == "unknown-weapon":
		o.classes[&"mage"].weapon_types.append(&"unknown-weapon")
	return o
'''
		)
	)
	writer.close()
	for case in [
		"valid", "false-empty", "true-error", "prior-load-error", "null-loot", "unknown-weapon"
	]:
		var text := run_child(fixture, ["--", case], case, 0 if case == "valid" else 1)
		check("ERROR:" not in text, case + " no engine errors")
		var expected: String = {
			"valid": "ontology valid",
			"false-empty": "ontology INVALID (0 errors)",
			"true-error": "retained diagnostic",
			"prior-load-error": "invalid JSON: broken.json",
			"null-loot": "design.loot: required object missing or malformed",
			"unknown-weapon": "class mage: unknown weapon-type unknown-weapon"
		}[case]
		check(expected in text, case + " CLI diagnostic")
		if case != "valid":
			check("ontology INVALID" in text, case + " CLI reports failure")
	var db_fixture := scratch.path_join("db_fixture.gd")
	writer = FileAccess.open(db_fixture, FileAccess.WRITE)
	(
		writer
		. store_string(
			'''extends "res://game/ontology_db.gd"
class FailedValidation:
	extends Model.Ontology
	func validate() -> bool:
		return false
func _load_ontology() -> Model.Ontology:
	return FailedValidation.new()
'''
		)
	)
	writer.close()
	var db_runner := scratch.path_join("db_runner.gd")
	writer = FileAccess.open(db_runner, FileAccess.WRITE)
	(
		writer
		. store_string(
			'''extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.add_child(load(get_script().resource_path.get_base_dir().path_join("db_fixture.gd")).new())
	await process_frame
	await process_frame
	quit(0)
'''
		)
	)
	writer.close()
	var text := run_child(db_runner, [], "db-false-empty", 1)
	check("ontology: validation failed" in text, "OntologyDB false/empty useful diagnostic")


func run_child(script: String, args: Array, label: String, expected_status: int) -> String:
	var output: Array = []
	var status := OS.execute(
		"timeout",
		(
			[
				"30",
				OS.get_executable_path(),
				"--headless",
				"--path",
				ProjectSettings.globalize_path("res://"),
				"-s",
				script
			]
			+ args
		),
		output,
		true
	)
	var text := "\n".join(output)
	var writer := FileAccess.open(script.get_base_dir().path_join(label + ".log"), FileAccess.WRITE)
	writer.store_string("exit=%d\n%s" % [status, text])
	writer.close()
	check(status == expected_status, label + " process exit (got %d)" % status)
	check("SCRIPT ERROR:" not in text, label + " no script exceptions")
	return text
