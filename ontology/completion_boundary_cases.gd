## Defence/melee work belonged to validate(), unlike the old shape/shot-local defaults.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const FIELDS = preload("res://ontology/callback_probe_test_support.gd").CATALOGS
const ChildOutput := preload("res://ontology/callback_expectations_test_support.gd")
const LATE := "exactly one ruleset must be default (found 0)"
const FLOAT := "SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor."
const INT := "SCRIPT ERROR: Invalid call. Nonexistent 'int' constructor."
const ITERATE := "SCRIPT ERROR: Unable to iterate on object of type 'Nil'."
const CASES := [
	"dodge:stamina",
	"dodge:distance",
	"dodge:duration-s",
	"dodge:iframe-s",
	"dodge:on-dodge",
	"block:max",
	"block:power-per-hit",
	"block:damage-reduction",
	"block:front-dot",
	"block:regen-per-s",
	"block:guardian-mult",
	"stealth:decay-per-s",
	"stealth:still-mult",
	"stealth:aggro-cut",
	"melee:swing-mult",
	"melee:radius-mult",
	"melee:lunge",
	"finisher:every",
	"finisher:chance",
	"finisher:applies",
	"partial:front-dot",
	"ordinary:block",
	"ordinary:finisher",
	"shape:block",
	"shape:finisher",
	"ability:field",
	"ability:row",
	"ability:negative"
]


class Probe:
	extends Model.Ontology
	var mode := ""
	var enabled := false
	var events: Array = []
	var ability_rows: Dictionary = {}
	var in_defence := false

	func _input_shape(value: Variant, kind: String, path: String) -> bool:
		var valid := super._input_shape(value, kind, path)
		if (
			in_defence
			and mode.begins_with("ability:")
			and path == "design.abilities.aim.stealth-per-s"
		):
			events.append(["guard", valid])
			if enabled:
				mutate_ability()
		return valid

	func mutate_ability() -> void:
		match mode:
			"ability:field":
				ability_rows.aim["stealth-per-s"] = []
			"ability:row":
				ability_rows.aim = {"stealth-per-s": -1}
			"ability:negative":
				ability_rows.aim["stealth-per-s"] = -1

	func _fields_valid(row: Variant, path: String, fields: Dictionary) -> bool:
		var valid := super._fields_valid(row, path, fields)
		if path == "design.defence.dodge":
			in_defence = true
		if path == "design.feel.hit-stop":
			events.append("later")
		observe_target(row, path, valid)
		return valid

	func _moveset_fields_valid(row: Dictionary, path: String) -> bool:
		var valid := super._moveset_fields_valid(row, path)
		observe_target(row, path, valid)
		if path == "design.movesets.greatsword.m2" and is_moveset():
			events.append("next-slot")
		return valid

	func observe_target(row: Variant, path: String, valid: bool) -> void:
		if path == target_path():
			events.append(["guard", valid])
			if enabled and valid:
				mutate(row)

	func is_moveset() -> bool:
		return mode.get_slice(":", 0) in ["melee", "finisher"] or mode.ends_with(":finisher")

	func target_path() -> String:
		if is_moveset():
			return (
				"design.movesets.greatsword.m1"
				+ ("" if mode.begins_with("melee:") else ".finisher")
			)
		return (
			"design.defence."
			+ (
				"block"
				if mode.get_slice(":", 0) in ["partial", "ordinary", "shape"]
				else mode.get_slice(":", 0)
			)
		)

	func mutate(row: Dictionary) -> void:
		var field := mode.get_slice(":", 1)
		if mode.begins_with("ordinary:"):
			ordinary_mutation(row, field)
		elif mode.begins_with("partial:"):
			row["max"] = 0
			row[field] = []
		elif field in ["on-dodge", "applies"]:
			row[field] = null
		else:
			row[field] = []
		if mode.begins_with("finisher:") and field != "applies":
			row["applies"] = ["missing"]

	func ordinary_mutation(row: Dictionary, field: String) -> void:
		if field == "block":
			row["max"] = 0
		else:
			row["every"] = 1


static func verify(test) -> void:
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
			"res://ontology/completion_boundary_cases.gd"
		],
		output,
		true
	)
	var text := "\n".join(output)
	var file := FileAccess.open(
		OS.get_environment("PIXLND_TEST_DIR").path_join("completion-boundary.log"), FileAccess.WRITE
	)
	file.store_string("exit=%d\n%s" % [status, text])
	file.close()
	var records := ChildOutput.observations(text, "COMPLETION ")
	var expected := expected_records()
	test.check(status == 0, "completion child finishes")
	test.check(
		ChildOutput.diagnostics(text) == expected_headers(),
		"completion exact ordered native headers"
	)
	for index in expected.size():
		test.check(
			index < records.size() and records[index] == JSON.stringify(expected[index]),
			(
				"validate completion/partial effects/continuation "
				+ str(expected[index][0])
				+ " #"
				+ str(index)
			)
		)
	test.check(records.size() == expected.size(), "completion exact observation count")


static func expected_records() -> Array:
	var expected: Array = [["canonical", true, TYPE_BOOL, [], ["later"]]]
	for enabled in [false, true]:
		for mode in CASES:
			expected.append(expected_record(mode, enabled))
	return expected


static func expected_headers() -> Array:
	var headers: Array = []
	for mode in CASES:
		if not completes_normally(mode):
			headers.append(expected_header(mode))
	return headers


static func completes_normally(mode: String) -> bool:
	return (
		mode.begins_with("ordinary:")
		or mode.begins_with("shape:")
		or mode in ["ability:row", "ability:negative"]
	)


static func expected_header(mode: String) -> String:
	if mode == "ability:field":
		return "SCRIPT ERROR: Invalid operands 'Array' and 'int' in operator '<'."
	if mode == "finisher:every":
		return INT
	if mode in ["dodge:on-dodge", "finisher:applies"]:
		return ITERATE
	return FLOAT


static func expected_record(mode: String, enabled: bool) -> Array:
	var errors: Array = ["prior"]
	var events: Array = [["guard", true]]
	var moveset := mode.get_slice(":", 0) in ["melee", "finisher"] or mode.ends_with(":finisher")
	var continues := not enabled or completes_normally(mode)
	if enabled:
		errors.append_array(mutation_errors(mode))
		if mode.begins_with("shape:"):
			events = [["guard", false]]
	if continues:
		continuation_events(moveset, events)
		errors.append(LATE)
	return [mode, enabled, false, TYPE_BOOL, errors, events]


static func continuation_events(moveset: bool, events: Array) -> void:
	if moveset:
		events.append("next-slot")
	events.append("later")


static func mutation_errors(mode: String) -> Array:
	return (
		{
			"ability:row": ["design.abilities.aim.stealth-per-s < 0"],
			"ability:negative": ["design.abilities.aim.stealth-per-s < 0"],
			"partial:front-dot": ["design.defence.block: max / power-per-hit must be > 0"],
			"ordinary:block": ["design.defence.block: max / power-per-hit must be > 0"],
			"ordinary:finisher":
			["design.movesets.greatsword.m1: finisher every >= 2, chance in [0,1]"],
			"shape:block": ["design.defence.block.max: required number missing or malformed"],
			"shape:finisher":
			["design.movesets.greatsword.m1.finisher.every: finite number required"]
		}
		. get(mode, [])
	)


func run_case(mode: String, enabled: bool) -> void:
	var base := Model.Ontology.load_dir("res://ontology/instances")
	var o := Probe.new()
	for field in FIELDS:
		o.set(field, base.get(field))
	o.mode = mode
	o.enabled = enabled
	o.ability_rows = o.configs.generators.design.abilities
	if mode == "canonical":
		var result := o.validate()
		print(
			"COMPLETION ", JSON.stringify([mode, result, typeof(result), Array(o.errors), o.events])
		)
		return
	o.errors.append("prior")
	o.rulesets["ruleset-hybrid"].is_default = false
	if enabled and mode == "shape:block":
		o.configs.generators.design.defence.block.max = []
	elif enabled and mode == "shape:finisher":
		o.configs.generators.design.movesets.greatsword.m1.finisher.every = []
	var result := o.validate()
	print(
		"COMPLETION ",
		JSON.stringify([mode, enabled, result, typeof(result), Array(o.errors), o.events])
	)


func _init() -> void:
	run_case("canonical", false)
	for enabled in [false, true]:
		for mode in CASES:
			run_case(mode, enabled)
	quit()
