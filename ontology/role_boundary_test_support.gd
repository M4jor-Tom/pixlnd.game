## Original role-local/shot-local Array ownership and lexical static dispatch regressions.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const FIELDS = preload("res://ontology/callback_probe_test_support.gd").CATALOGS
const EXPECTED := [
	["role-valid", [], ["prior", "shape witness"]],
	["role-range-array", [], ["prior", "shape witness"]],
	["role-partial-windup", [], ["prior", "shape witness"]],
	["role-status-null", [], ["prior", "shape witness"]],
	["role-kind-missing", ["role: kind must be projectile"], ["prior", "shape witness"]],
	[
		"role-shot-missing",
		["role.shot: speed, radius, life-s must be > 0"],
		["prior", "shape witness"]
	],
	[
		"role-ordinary",
		[
			"role: range must be > keep-away >= 0",
			"role: windup-s must be >= 0",
			"role: cooldown-s must be > 0",
			"role: damage-mult must be > 0",
			"role.shot: speed, radius, life-s must be > 0",
			"role.shot: count >= 1, spread / gravity / splash >= 0",
			"role.shot: pierce needs tick-s > 0",
			"role: applies missing has no design.status-effects entry",
			"role: sfx bad is not an audio.json sfx-alpha-ids entry",
			"role: color is not a valid html colour"
		],
		["prior", "shape witness"]
	],
	[
		"shot-array",
		["role: applies missing has no design.status-effects entry"],
		["prior", "shape witness"]
	],
	[
		"shot-partial",
		[
			"role: range must be > keep-away >= 0",
			"role: applies missing has no design.status-effects entry"
		],
		["prior", "shape witness"]
	],
	[
		"shot-pierce-array",
		[
			"role: range must be > keep-away >= 0",
			"role: applies missing has no design.status-effects entry"
		],
		["prior", "shape witness"]
	],
	[
		"shot-short",
		[
			"role.shot: speed, radius, life-s must be > 0",
			"role.shot: count >= 1, spread / gravity / splash >= 0",
			"role: applies missing has no design.status-effects entry"
		],
		["prior", "shape witness"]
	],
	["shot-type-array", [], ["prior", "shape witness"]],
	[
		"whole-range-array",
		false,
		[
			"prior",
			"prior",
			"shape witness",
			"design.creature-roles.species.spitter (merged).range: required number missing or malformed",
			"design.creature-roles.species.snout-beetle (merged).range: required number missing or malformed",
			"exactly one ruleset must be default (found 0)"
		]
	],
	["binding", [], [], ["shadow"], ["shadow"], ["shadow"]],
	[
		"projectile",
		false,
		["exactly one ruleset must be default (found 0)"],
		["design.abilities.fire-missiles"]
	],
	[
		"dash",
		false,
		["exactly one ruleset must be default (found 0)"],
		["design.abilities.shuriken-attack"]
	],
	[
		"moveset",
		false,
		["exactly one ruleset must be default (found 0)"],
		["design.movesets.sword.m1"]
	],
	["dash-argument", false, [], ["design.abilities.shuriken-attack"]],
	["accessor", ["shadow"], 0, 0, 0]
]
const HEADERS := [
	"SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.",
	"SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.",
	"SCRIPT ERROR: Unable to iterate on object of type 'Nil'.",
	"SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.",
	"SCRIPT ERROR: Invalid call. Nonexistent 'int' constructor.",
	"SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.",
	"SCRIPT ERROR: Invalid type in function '_shot_errors' in base 'GDScript'. Cannot convert argument 1 from Array to Dictionary.",
	"SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.",
	"SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.",
	"SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.",
	"SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.",
	"SCRIPT ERROR: Invalid type in function '_shot_errors' in base 'GDScript'. Cannot convert argument 1 from Array to Dictionary."
]


class Probe:
	extends Model.Ontology
	var mode := ""

	func _role_fields_valid(row: Dictionary, path: String) -> bool:
		var valid := super._role_fields_valid(row, path)
		if path in ["role", "design.creature-roles.ranged"]:
			errors.append("shape witness")
			mutate(row)
		return valid

	func mutate(row: Dictionary) -> void:
		if mode.begins_with("shot-"):
			shot_mutation(row)
		else:
			role_mutation(row)

	func role_mutation(row: Dictionary) -> void:
		match mode:
			"role-range-array", "whole-range-array":
				row["range"] = []
				row["applies"] = ["missing"]
			"role-partial-windup":
				row["range"] = 0
				row["windup-s"] = []
				row["applies"] = ["missing"]
			"role-status-null":
				row["range"] = 0
				row["applies"] = null
			"role-kind-missing":
				row.erase("kind")
			"role-shot-missing":
				row.erase("shot")
			"role-ordinary":
				ordinary(row)

	func ordinary(row: Dictionary) -> void:
		row["range"] = 0
		row["windup-s"] = -1
		row["cooldown-s"] = 0
		row["damage-mult"] = 0
		row["applies"] = ["missing"]
		row["sfx"] = "bad"
		row["color"] = "invalid"
		row["shot"] = {
			"speed": 0, "radius": 1, "life-s": 1, "count": 0, "pierce": true, "tick-s": 0
		}

	func shot_mutation(row: Dictionary) -> void:
		row["applies"] = ["missing"]
		match mode:
			"shot-array":
				row["shot"]["speed"] = []
			"shot-partial":
				row["range"] = 0
				row["shot"]["speed"] = 0
				row["shot"]["count"] = []
			"shot-pierce-array":
				row["range"] = 0
				row["shot"]["speed"] = 0
				row["shot"]["pierce"] = true
				row["shot"]["tick-s"] = []
			"shot-short":
				row["shot"] = {
					"speed": 0,
					"radius": [],
					"life-s": 1,
					"count": 0,
					"spread": [],
					"pierce": false,
					"tick-s": []
				}
			"shot-type-array":
				row["range"] = 0
				row["shot"] = []


func run_case(name: String) -> void:
	var o := Probe.new()
	o.mode = name
	o.errors.append("prior")
	if name == "whole-range-array":
		var base := Model.Ontology.load_dir("res://ontology/instances")
		for f in FIELDS:
			o.set(f, base.get(f))
		o.errors.append("prior")
		o.rulesets["ruleset-hybrid"].is_default = false
		var valid := o.validate()
		print("ROLEBOUNDARY ", JSON.stringify([name, valid, Array(o.errors)], "", false, true))
	else:
		var row: Dictionary = {
			"kind": "projectile",
			"range": 2,
			"keep-away": 1,
			"windup-s": 0,
			"cooldown-s": 1,
			"damage-mult": 1,
			"shot": {"speed": 1, "radius": 1, "life-s": 1},
			"applies": [],
			"sfx": "hit",
			"color": "#ffffff"
		}
		var result := o._role_errors(row, "role", {}, ["hit"], {"hit": {}})
		print("ROLEBOUNDARY ", JSON.stringify([name, result, Array(o.errors)], "", false, true))


class Shadow:
	extends Model.Ontology

	static func _shot_errors(_row: Dictionary, _where: String) -> Array:
		return ["shadow"]


class CallerProbe:
	extends Model.Ontology
	var mode := ""
	var seen: Array = []

	func _ability_fields_valid(row: Dictionary, path: String) -> bool:
		var valid := super._ability_fields_valid(row, path)
		match [mode, path]:
			["dash-argument", "design.abilities.shuriken-attack"]:
				row["throw"] = []
				seen.append(path)
			["projectile", "design.abilities.fire-missiles"]:
				row["speed"] = []
				seen.append(path)
			["dash", "design.abilities.shuriken-attack"]:
				row["throw"]["speed"] = []
				seen.append(path)
		return valid

	func _moveset_fields_valid(row: Dictionary, path: String) -> bool:
		var valid := super._moveset_fields_valid(row, path)
		if mode == "moveset" and path == "design.movesets.sword.m1":
			row["speed"] = []
			seen.append(path)
		return valid


func binding_case() -> void:
	var shot: Dictionary = {"speed": 1, "radius": 1, "life-s": 1}
	var row: Dictionary = {
		"kind": "projectile",
		"range": 2,
		"keep-away": 1,
		"windup-s": 0,
		"cooldown-s": 1,
		"damage-mult": 1,
		"shot": shot,
		"applies": [],
		"sfx": "hit",
		"color": "#ffffff"
	}
	var base := Model.Ontology.new()
	var shadow := Shadow.new()
	print(
		"ROLEBOUNDARY ",
		JSON.stringify(
			[
				"binding",
				Model.Ontology._shot_errors(shot, "shot"),
				base._shot_errors(shot, "shot"),
				Shadow._shot_errors(shot, "shot"),
				shadow._shot_errors(shot, "shot"),
				shadow._role_errors(row, "role", {}, ["hit"], {"hit": {}})
			],
			"",
			false,
			true
		)
	)


func caller_case(mode: String) -> void:
	var o := CallerProbe.new()
	o.mode = mode
	var base := Model.Ontology.load_dir("res://ontology/instances")
	for f in FIELDS:
		o.set(f, base.get(f))
	if mode == "moveset":
		o.configs.generators.design.movesets.sword.m1 = {
			"kind": "projectile", "speed": 1, "radius": 1, "life-s": 1
		}
	o.rulesets["ruleset-hybrid"].is_default = false
	var result := o.validate()
	print("ROLEBOUNDARY ", JSON.stringify([mode, result, Array(o.errors), o.seen], "", false, true))


class AccessorShadow:
	extends Model.Ontology
	var calls := 0
	var get_calls := 0
	var property_calls := 0
	@warning_ignore("native_method_override")
	func get(_property: StringName) -> Variant:
		get_calls += 1
		return Model.Ontology

	func _get(property: StringName) -> Variant:
		if property == &"script":
			property_calls += 1
			return Model.Ontology
		return null

	@warning_ignore("native_method_override")
	func get_script() -> Variant:
		calls += 1
		return Model.Ontology

	static func _shot_errors(_s: Dictionary, _w: String) -> Array:
		return ["shadow"]


func accessor_case() -> void:
	var o := AccessorShadow.new()
	var row: Dictionary = {
		"kind": "projectile",
		"range": 2,
		"keep-away": 1,
		"windup-s": 0,
		"cooldown-s": 1,
		"damage-mult": 1,
		"shot": {"speed": 1, "radius": 1, "life-s": 1},
		"sfx": "hit",
		"color": "#fff"
	}
	var out := o._role_errors(row, "role", {}, ["hit"], {"hit": {}})
	print(
		"ROLEBOUNDARY ",
		JSON.stringify(["accessor", out, o.calls, o.get_calls, o.property_calls], "", false, true)
	)


func _init() -> void:
	for name in [
		"role-valid",
		"role-range-array",
		"role-partial-windup",
		"role-status-null",
		"role-kind-missing",
		"role-shot-missing",
		"role-ordinary",
		"shot-array",
		"shot-partial",
		"shot-pierce-array",
		"shot-short",
		"shot-type-array",
		"whole-range-array"
	]:
		run_case(name)
	binding_case()
	for mode in ["projectile", "dash", "moveset", "dash-argument"]:
		caller_case(mode)
	accessor_case()
	runtime_id_cases()
	quit()


class RuntimeToken:
	extends RefCounted
	var target: Resource
	var enabled := false
	var calls := 0
	var value := "mp"
	var ids: Array = []

	func _to_string() -> String:
		calls += 1
		if enabled and calls <= ids.size() and ids[calls - 1] != "":
			target.id = StringName(ids[calls - 1])
		return value


class RuntimeProbe:
	extends Model.Ontology
	var mode := ""
	var enabled := false
	var target: Resource
	var tokens: Array = []
	var selected: Dictionary = {}
	var paths: Array = []

	func _ability_fields_valid(row: Dictionary, path: String) -> bool:
		if mode.begins_with("selected-") and is_same(row, selected):
			paths.append(path)
			return true
		var valid := super._ability_fields_valid(row, path)
		if path == "design.abilities.cyclone":
			configure(row)
		return valid

	func token(value: String, ids: Array) -> RuntimeToken:
		var t := RuntimeToken.new()
		t.target = target
		t.enabled = enabled
		t.value = value
		t.ids = ids
		tokens.append(t)
		return t

	func configure(row: Dictionary) -> void:
		if mode.begins_with("selector-"):
			row["runtime"] = token(mode.trim_prefix("selector-"), ["selector1", "selector2"])
		elif mode == "id-amount":
			row["cost"] = {"mp": token("not-all", ["amount1", "amount2"])}
		elif mode == "id-cooldown" and enabled:
			target.id = &"shaped"


func runtime_id_case(mode: String, enabled: bool) -> void:
	var o := RuntimeProbe.new()
	var base := Model.Ontology.load_dir("res://ontology/instances")
	for f in FIELDS:
		o.set(f, base.get(f))
	o.mode = mode
	o.enabled = enabled
	o.target = o.abilities.cyclone
	var row: Dictionary = o.configs.generators.design.abilities.cyclone
	o.selected = row
	row.merge(
		{
			"runtime": "buff",
			"cooldown-s": 1,
			"duration-s": 0,
			"cost": {},
			"radius": 0,
			"distance": 0,
			"cast-s": -1,
			"heal-pct": 0,
			"strike": {"radius": 0},
			"throw": {"speed": 0, "radius": 1, "life-s": 1},
			"speed": 0,
			"life-s": 1
		},
		true
	)
	# A later id read must not select this replacement instead of the captured row.
	for id in [
		"changed",
		"first",
		"second",
		"third",
		"fourth",
		"amount1",
		"amount2",
		"shaped",
		"selector1",
		"selector2",
		"selected1",
		"selected2"
	]:
		o.configs.generators.design.abilities[id] = {
			"runtime": "heal", "cooldown-s": 1, "cast-s": 0, "heal-pct": 1
		}
	match mode:
		"selected-buff", "selected-unknown":
			row["runtime"] = o.token(mode.trim_prefix("selected-"), ["selected1", "selected2"])
		"id-cost":
			row["cost"] = {o.token("mp", ["", "changed"]): 1}
		"id-cost-errors":
			row["cost"] = {
				o.token("mp", ["", "first", "second"]): -1,
				o.token("mp", ["", "third", "fourth"]): -1
			}
		"id-cooldown":
			row["cooldown-s"] = 0
	var result := o.validate()
	var counts: Array = []
	for t in o.tokens:
		counts.append(t.calls)
	var record: Array = [mode, enabled, result, Array(o.errors), str(o.target.id), counts]
	if mode.begins_with("selected-"):
		record.append(o.paths)
	print("ROLEBOUNDARY ", JSON.stringify(record, "", false, true))


func runtime_id_cases() -> void:
	for mode in [
		"selected-buff",
		"selected-unknown",
		"id-cost",
		"id-cost-errors",
		"id-amount",
		"id-cooldown",
		"selector-dash",
		"selector-projectile",
		"selector-burst",
		"selector-channel",
		"selector-buff",
		"selector-heal"
	]:
		for enabled in [false, true]:
			runtime_id_case(mode, enabled)
