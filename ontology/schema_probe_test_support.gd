## Child-only characterization for test_model_compatibility; intentional engine errors are captured there.
extends SceneTree
const Model := preload("res://ontology/model.gd")

# Independent expectations for this fixed probe corpus, not generated from model behavior.
const EXPECTED := [
	[false, "empty", true, ["prior"], ["probe"], 0, 0, ["probe"]],
	[false, "active", false, ["prior"], ["probe"], 0, 0, ["probe"]],
	[
		false,
		"both-bad",
		false,
		[
			"prior",
			"probe.first: required string missing or malformed",
			"probe.later: required number missing or malformed"
		],
		["probe", "probe.first", "probe.later"],
		0,
		1,
		["probe", "probe.first", "stringify-fields", "probe.later"]
	],
	[
		false,
		"false-true",
		false,
		["prior", "probe.first: required string missing or malformed"],
		["probe", "probe.first", "probe.later"],
		0,
		1,
		["probe", "probe.first", "stringify-fields", "probe.later"]
	],
	[
		false,
		"true-false",
		false,
		["prior", "probe.later: required number missing or malformed"],
		["probe", "probe.first", "probe.later"],
		0,
		1,
		["probe", "probe.first", "stringify-fields", "probe.later"]
	],
	[
		false,
		"all-good",
		true,
		["prior"],
		["probe", "probe.first", "probe.later"],
		0,
		1,
		["probe", "probe.first", "stringify-fields", "probe.later"]
	],
	[
		false,
		"same-group",
		false,
		["prior", "probe.first: required number missing or malformed"],
		["probe", "probe.first", "probe.later"],
		0,
		1,
		["probe", "stringify-fields", "probe.first", "probe.later"]
	],
	[
		false,
		"same-group-late",
		false,
		["prior", "probe.later: required number missing or malformed"],
		["probe", "probe.first", "probe.later"],
		0,
		1,
		["probe", "stringify-fields", "probe.first", "probe.later"]
	],
	[
		false,
		"mutated",
		true,
		["prior"],
		["probe", "probe.first", "probe.later", "probe.added"],
		0,
		1,
		["probe", "probe.first", "stringify-fields", "probe.later", "probe.added"]
	],
	[
		false,
		"mutated-schema",
		true,
		["prior"],
		["probe", "probe.first", "probe.later", "probe.added"],
		0,
		1,
		["probe", "probe.first", "stringify-fields", "probe.later", "probe.added"]
	],
	[true, "empty", true, ["prior"], [], 0, 0, []],
	[true, "active", false, ["prior"], [], 0, 0, []],
	[
		true,
		"both-bad",
		false,
		[
			"prior",
			"probe.first: required string missing or malformed",
			"probe.later: required number missing or malformed"
		],
		["probe.first", "probe.later"],
		0,
		1,
		["probe.first", "stringify-fields", "probe.later"]
	],
	[
		true,
		"false-true",
		false,
		["prior", "probe.first: required string missing or malformed"],
		["probe.first", "probe.later"],
		0,
		1,
		["probe.first", "stringify-fields", "probe.later"]
	],
	[
		true,
		"true-false",
		false,
		["prior", "probe.later: required number missing or malformed"],
		["probe.first", "probe.later"],
		0,
		1,
		["probe.first", "stringify-fields", "probe.later"]
	],
	[
		true,
		"all-good",
		true,
		["prior"],
		["probe.first", "probe.later"],
		0,
		1,
		["probe.first", "stringify-fields", "probe.later"]
	],
	[
		true,
		"same-group",
		false,
		["prior", "probe.first: required number missing or malformed"],
		["probe.first", "probe.later"],
		0,
		1,
		["stringify-fields", "probe.first", "probe.later"]
	],
	[
		true,
		"same-group-late",
		false,
		["prior", "probe.later: required number missing or malformed"],
		["probe.first", "probe.later"],
		0,
		1,
		["stringify-fields", "probe.first", "probe.later"]
	],
	[
		true,
		"mutated",
		true,
		["prior"],
		["probe.first", "probe.later", "probe.added"],
		0,
		1,
		["probe.first", "stringify-fields", "probe.later", "probe.added"]
	],
	[
		true,
		"mutated-schema",
		true,
		["prior"],
		["probe.first", "probe.later", "probe.added"],
		0,
		1,
		["probe.first", "stringify-fields", "probe.later", "probe.added"]
	]
]


class KindKey:
	extends RefCounted
	var calls := 0

	func _to_string() -> String:
		calls += 1
		return "bad-kind"


class FieldList:
	extends RefCounted
	var text := "later"
	var calls := 0
	var events: Array = []

	func _to_string() -> String:
		calls += 1
		events.append("stringify-fields")
		return text


class ShapeSpy:
	extends Model.Ontology
	var paths: Array = []
	var events: Array = []
	var row_alias: Dictionary = {}
	var groups_alias: Dictionary = {}
	var field_list
	var mutate := false
	var mutate_schema := false

	func _input_shape(value: Variant, kind: String, path: String) -> bool:
		paths.append(path)
		events.append(path)
		if mutate and path == "probe.first":
			row_alias["later"] = 2
			field_list.text = "later added"
			if mutate_schema:
				groups_alias["number"] = field_list
		return super._input_shape(value, kind, path)


func run_case(optional: bool, mode: String) -> void:
	var o := ShapeSpy.new()
	var key := KindKey.new()
	var names := FieldList.new()
	names.events = o.events
	o.field_list = names
	o.errors.append("prior")
	var row := {"first": "ok", "later": 2, "added": 3}
	var groups := {"string": "first", "number": names}
	configure_case(optional, mode, row, groups, key)
	o.row_alias = row
	o.groups_alias = groups
	o.mutate = mode in ["mutated", "mutated-schema"]
	o.mutate_schema = mode == "mutated-schema"
	if o.mutate:
		names.text = "unused"
	configure_field_list(mode, names, groups)
	var result := (
		o._optional_fields_valid(row, "probe", groups)
		if optional
		else o._fields_valid(row, "probe", groups)
	)
	print(
		"RESULT ",
		JSON.stringify(
			[optional, mode, result, Array(o.errors), o.paths, key.calls, names.calls, o.events],
			"",
			false,
			true
		)
	)


func configure_case(optional: bool, mode: String, row: Dictionary, groups: Dictionary, key) -> void:
	match mode:
		"empty":
			row.clear()
			groups.clear()
			groups[key] = "absent" if optional else ""
		"active":
			groups.erase("string")
			var number: Variant = groups["number"]
			groups.clear()
			groups[key] = "first"
			groups["number"] = number
			row["later"] = "bad"
		"both-bad":
			row["first"] = 1
			row["later"] = "bad"
		"false-true":
			row["first"] = 1
		"true-false":
			row["later"] = "bad"
		"same-group":
			groups.erase("string")
			row["first"] = "bad"
		"same-group-late":
			groups.erase("string")
			row["first"] = 1
			row["later"] = "bad"
		"mutated", "mutated-schema":
			row["later"] = "bad"


func configure_field_list(mode: String, names, groups: Dictionary) -> void:
	if mode in ["same-group", "same-group-late"]:
		names.text = "first later"
	if mode == "mutated-schema":
		groups["number"] = "unused"


func _init() -> void:
	for optional in [false, true]:
		for mode in [
			"empty",
			"active",
			"both-bad",
			"false-true",
			"true-false",
			"all-good",
			"same-group",
			"same-group-late",
			"mutated",
			"mutated-schema"
		]:
			run_case(optional, mode)
	quit()
