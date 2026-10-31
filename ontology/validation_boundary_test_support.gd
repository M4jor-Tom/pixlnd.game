## Child-only original validation-scope completion, alias and typed-boundary characterization.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const CATALOGS = preload("res://ontology/callback_probe_test_support.gd").CATALOGS
const EXPECTED := [
	["wrong-null", false, [], ["design.creature-roles.species.collie"]],
	["wrong-int", false, [], ["design.creature-roles.species.collie"]],
	["wrong-array", false, [], ["design.creature-roles.species.collie"]],
	[
		"ordinary-next",
		false,
		[
			"design.creature-roles.species.missing is not a creature",
			"design.creature-roles.species.collie: required object missing or malformed",
			"exactly one ruleset must be default (found 0)"
		],
		["design.creature-roles.species.sheep"]
	],
	["parent-array", false, [], []],
	["parent-deleted", false, [], []],
	[
		"parent-dict",
		false,
		["exactly one ruleset must be default (found 0)"],
		["design.creature-roles.species.key"]
	],
	[
		"missing-insert",
		false,
		[
			"design.creature-roles.species.key is not a creature",
			"exactly one ruleset must be default (found 0)"
		],
		[]
	],
	[
		"missing-reset",
		false,
		[
			"callback reset",
			"design.creature-roles.species.key is not a creature",
			"exactly one ruleset must be default (found 0)"
		],
		[]
	],
	["flat", "bool", false, ["exactly one ruleset must be default (found 0)"], 0],
	[
		"flat",
		"array",
		false,
		["ingredients.probe: empty content row", "exactly one ruleset must be default (found 0)"],
		0
	],
	["flat", "null", false, ["exactly one ruleset must be default (found 0)"], 0],
	["flat", "string", false, ["exactly one ruleset must be default (found 0)"], 0],
	[
		"flat",
		"ordinary",
		false,
		[
			"ingredients.probe: required object missing or malformed",
			"ingredients.after: empty content row",
			"exactly one ruleset must be default (found 0)"
		],
		1
	],
	["nested", "bool", false, ["exactly one ruleset must be default (found 0)"], 0],
	[
		"nested",
		"array",
		false,
		[
			"pet-food.foods.probe: empty content row",
			"exactly one ruleset must be default (found 0)"
		],
		0
	],
	["nested", "null", false, ["exactly one ruleset must be default (found 0)"], 0],
	["nested", "string", false, ["exactly one ruleset must be default (found 0)"], 0],
	[
		"nested",
		"ordinary",
		false,
		[
			"pet-food.foods.probe: required object missing or malformed",
			"pet-food.foods.after: empty content row",
			"exactly one ruleset must be default (found 0)"
		],
		1
	],
	["tree-null", 0, [], 0],
	["tree-number", 0, [], 0],
	["tree-resource", 0, [], 0],
	["tree-empty", 1, [], 0],
	["tree-malformed", 1, [], 1],
	["operand-positive-string", false, [], ["ability.turns-per-s"]],
	["operand-zero-string", false, [], ["ability.turns-per-s"]],
	[
		"operand-negative-string",
		false,
		["ability.turns-per-s: must be > 0"],
		["ability.turns-per-s", "ability.drain-per-s"]
	],
	[
		"operand-numeric-zero",
		false,
		["ability.turns-per-s: must be > 0"],
		["ability.turns-per-s", "ability.drain-per-s"]
	],
	["operand-numeric-positive", true, [], ["ability.turns-per-s", "ability.drain-per-s"]],
	[
		"operand-numeric-negative",
		false,
		["ability.turns-per-s: must be > 0"],
		["ability.turns-per-s", "ability.drain-per-s"]
	],
	["operand-runtime-object", false, [], []],
	[
		"operand-earlier-invalid",
		false,
		["ability.turns-per-s: required number missing or malformed"],
		["ability.cost", "ability.turns-per-s", "ability.drain-per-s", "ability.cost.mp"]
	],
	["metadata-nested-object", false, ["exactly one ruleset must be default (found 0)"], 0, 1],
	[
		"metadata-nested-skip",
		false,
		[
			"pet-food.foods: required catalog content missing",
			"exactly one ruleset must be default (found 0)"
		],
		1,
		1
	],
	[
		"metadata-nested-zero",
		false,
		[
			"pet-food.foods: required catalog content missing",
			"exactly one ruleset must be default (found 0)"
		],
		1,
		0
	],
	["metadata-nested-content", false, ["exactly one ruleset must be default (found 0)"], 1, 0],
	[
		"metadata-flat-zero",
		false,
		[
			"ingredients: required catalog content missing",
			"initial-encounters.furnishings.table.flask: required ingredient",
			"initial-encounters.mission-package: required ingredient emerald",
			"initial-encounters.mission-package: required ingredient sapphire",
			"initial-encounters.mission-package: required ingredient ruby",
			"initial-encounters.mission-package: required ingredient diamond",
			"initial-encounters.mission-package: required ingredient glass-flask",
			"exactly one ruleset must be default (found 0)"
		],
		1,
		0
	],
	["metadata-flat-object", false, ["exactly one ruleset must be default (found 0)"], 1, 3]
]
const HEADERS := [
	"SCRIPT ERROR: Invalid access to property or key 'combat_role' on a base object of type 'Nil'.",
	"SCRIPT ERROR: Trying to assign a non-object value to a variable of type ''.",
	"SCRIPT ERROR: Trying to assign a non-object value to a variable of type ''.",
	"SCRIPT ERROR: Invalid access to property or key 'key' on a base object of type 'Array'.",
	"SCRIPT ERROR: Invalid access to property or key 'species' on a base object of type 'Dictionary'.",
	"SCRIPT ERROR: Invalid call. Nonexistent function 'is_empty' in base 'bool'.",
	"SCRIPT ERROR: Invalid type in function '_typed_fields_valid' in base 'RefCounted (Probe)'. Cannot convert argument 2 from Array to Dictionary.",
	"SCRIPT ERROR: Invalid call. Nonexistent function 'is_empty' in base 'Nil'.",
	"SCRIPT ERROR: Invalid type in function '_typed_fields_valid' in base 'RefCounted (Probe)'. Cannot convert argument 2 from String to Dictionary.",
	"SCRIPT ERROR: Invalid call. Nonexistent function 'is_empty' in base 'bool'.",
	"SCRIPT ERROR: Invalid type in function '_typed_fields_valid' in base 'RefCounted (Probe)'. Cannot convert argument 2 from Array to Dictionary.",
	"SCRIPT ERROR: Invalid call. Nonexistent function 'is_empty' in base 'Nil'.",
	"SCRIPT ERROR: Invalid type in function '_typed_fields_valid' in base 'RefCounted (Probe)'. Cannot convert argument 2 from String to Dictionary.",
	"SCRIPT ERROR: Invalid access to property or key 'alpha_tree' on a base object of type 'Nil'.",
	"SCRIPT ERROR: Trying to assign a non-object value to a variable of type ''.",
	"SCRIPT ERROR: Trying to assign value of type '' to a variable of type ''.",
	"SCRIPT ERROR: Invalid operands 'String' and 'int' in operator '=='.",
	"SCRIPT ERROR: Invalid operands 'String' and 'int' in operator '=='.",
	"SCRIPT ERROR: Invalid operands 'Object' and 'String' in operator '=='.",
	"SCRIPT ERROR: Invalid operands 'Object' and 'String' in operator '=='."
]


class Key:
	extends RefCounted
	var action: Callable
	var calls := 0

	func _to_string() -> String:
		calls += 1
		if calls == 1 and action.is_valid():
			action.call()
		return "key"


class Late:
	extends Model.Ontology
	var action: Callable
	var seen: Array = []
	var keys: Array = []

	func _role_errors(
		r: Dictionary, where: String, se: Dictionary, alpha_sfx: Array, feel_sfx: Dictionary
	) -> Array:
		var result := super._role_errors(r, where, se, alpha_sfx, feel_sfx)
		if where == "design.creature-roles.mage" and action.is_valid():
			action.call()
		return result

	func _role_fields_valid(row: Dictionary, path: String) -> bool:
		if path.begins_with("design.creature-roles.species."):
			seen.append(path)
		return super._role_fields_valid(row, path)


class Probe:
	extends Model.Ontology
	var mapped := 0
	var point := "ingredients.probe"
	var replacement: Variant = false
	var parent: Dictionary = {}
	var changed := false

	func _input_shape(value: Variant, kind: String, path: String) -> bool:
		var result := super._input_shape(value, kind, path)
		if not changed and path == point:
			changed = true
			parent["probe"] = replacement
		return result

	func _validate_mapped_tables() -> void:
		mapped += 1
		super._validate_mapped_tables()


func run_case(name: String) -> void:
	var o := Late.new()
	var base := Model.Ontology.load_dir("res://ontology/instances")
	for f in CATALOGS:
		o.set(f, base.get(f))
	var cr: Dictionary = o.configs.generators.design["creature-roles"]
	var collie: Resource = o.creatures.collie
	o.rulesets["ruleset-hybrid"].is_default = false
	o.action = func(): setup(o, cr, collie, name)
	var result := o.validate()
	print("BOUNDARY ", JSON.stringify([name, result, Array(o.errors), o.seen], "", false, true))
	o.action = Callable()
	for key in o.keys:
		key.action = Callable()
	o.keys.clear()


func setup(o, cr: Dictionary, collie: Resource, name: String) -> void:
	cr["species"] = {"collie": {}}
	match name.get_slice("-", 0):
		"wrong":
			wrong_creature(o, name)
		"ordinary":
			cr["species"] = {"missing": {}, "collie": null, "sheep": {}}
		_:
			parent_mutation(o, cr, collie, name)


func wrong_creature(o, name: String) -> void:
	match name:
		"wrong-null":
			o.creatures.collie = null
		"wrong-int":
			o.creatures.collie = 42
		"wrong-array":
			o.creatures.collie = []


func parent_mutation(o, cr: Dictionary, collie: Resource, name: String) -> void:
	var key := Key.new()
	o.keys.append(key)
	cr["species"] = {key: {}}
	if name.begins_with("parent-"):
		o.creatures[key] = collie
	match name:
		"parent-array":
			key.action = func(): cr["species"] = []
		"parent-deleted":
			key.action = func(): cr.erase("species")
		"parent-dict":
			key.action = func(): cr["species"] = {key: {}}
		"missing-insert":
			key.action = func():
				o.creatures[key] = collie
				cr["species"] = []
		"missing-reset":
			key.action = func(): o.errors = PackedStringArray(["callback reset"])


func run_catalog_case(family: String, kind: String) -> void:
	var o := Probe.new()
	var base := Model.Ontology.load_dir("res://ontology/instances")
	for f in CATALOGS:
		o.set(f, base.get(f))
	o.parent = o.configs.ingredients if family == "flat" else o.configs["pet-food"].foods
	o.point = "ingredients.probe" if family == "flat" else "pet-food.foods.probe"
	o.parent["probe"] = {"probe": 1}
	o.parent["after"] = {}
	match kind:
		"bool":
			o.replacement = false
		"array":
			o.replacement = []
		"null":
			o.replacement = null
		"string":
			o.replacement = "text"
		"ordinary":
			o.changed = true
			o.parent["probe"] = false
	o.rulesets["ruleset-hybrid"].is_default = false
	var result := o.validate()
	print(
		"BOUNDARY ",
		JSON.stringify([family, kind, result, Array(o.errors), o.mapped], "", false, true)
	)


func run_tree_case(name: String) -> void:
	var o := Model.Ontology.new()
	var key := Key.new()
	var a := Model.Ability.new()
	a.owner = "warrior"
	a.alpha_tree = {"column": "class", "rank": 1, "needs": 0}
	match name:
		"tree-null":
			o.abilities["first"] = null
		"tree-number":
			o.abilities["first"] = 1
		"tree-resource":
			o.abilities["first"] = Model.Entry.new()
		"tree-empty":
			a.alpha_tree = {}
			o.abilities[key] = a
		"tree-malformed":
			a.alpha_tree = {"column": "bad", "needs": 0}
			o.abilities[key] = a
	var later := Model.Ability.new()
	later.owner = "warrior"
	later.alpha_tree = {"column": "class", "rank": 2, "needs": 0}
	o.abilities["later"] = later
	var result := o.skill_tree(&"warrior", &"berserker")
	print(
		"BOUNDARY ",
		JSON.stringify([name, result.size(), Array(o.errors), key.calls], "", false, true)
	)


class OperandProbe:
	extends Model.Ontology
	var row: Dictionary
	var selected: Variant = 1
	var paths: Array = []

	func _input_shape(value: Variant, kind: String, path: String) -> bool:
		paths.append(path)
		var result := super._input_shape(value, kind, path)
		if path == "ability.turns-per-s":
			row["turns-per-s"] = selected
		return result


func run_operand(name: String) -> void:
	var o := OperandProbe.new()
	o.row = {"runtime": "channel", "turns-per-s": 1, "drain-per-s": 0}
	match name:
		"operand-positive-string":
			o.selected = "0.1"
		"operand-zero-string":
			o.selected = "0"
		"operand-negative-string":
			o.selected = "-0.1"
		"operand-numeric-zero":
			o.selected = 0
		"operand-numeric-positive":
			o.selected = 1
		"operand-numeric-negative":
			o.selected = -1
		"operand-runtime-object":
			o.row.runtime = RefCounted.new()
		"operand-earlier-invalid":
			o.row["turns-per-s"] = []
			o.row["cost"] = {"mp": 1}
	var result := o._ability_fields_valid(o.row, "ability")
	print("BOUNDARY ", JSON.stringify([name, result, Array(o.errors), o.paths], "", false, true))


class MetaKey:
	extends RefCounted
	var text := "probe"
	var calls := 0

	func _to_string() -> String:
		calls += 1
		return text


class MetaProbe:
	extends Model.Ontology
	var mapped := 0

	func _validate_mapped_tables() -> void:
		mapped += 1
		super._validate_mapped_tables()


func run_metadata(name: String) -> void:
	var o := MetaProbe.new()
	var base := Model.Ontology.load_dir("res://ontology/instances")
	for f in CATALOGS:
		o.set(f, base.get(f))
	var key := MetaKey.new()
	match name:
		"metadata-nested-object":
			o.configs["pet-food"].foods = {key: {"probe": 1}}
		"metadata-nested-skip":
			key.text = "_skip"
			o.configs["pet-food"].foods = {key: {}}
		"metadata-nested-zero":
			o.configs["pet-food"].foods = {"_doc": "meta", "region-completion-order": []}
		"metadata-nested-content":
			o.configs["pet-food"].foods = {"probe": {"probe": 1}}
		"metadata-flat-zero":
			o.configs.ingredients = {"_doc": "meta"}
		"metadata-flat-object":
			o.configs.rarities[key] = {"probe": 1}
	o.rulesets["ruleset-hybrid"].is_default = false
	var result := o.validate()
	print(
		"BOUNDARY ",
		JSON.stringify([name, result, Array(o.errors), o.mapped, key.calls], "", false, true)
	)


func _init() -> void:
	for name in [
		"wrong-null",
		"wrong-int",
		"wrong-array",
		"ordinary-next",
		"parent-array",
		"parent-deleted",
		"parent-dict",
		"missing-insert",
		"missing-reset"
	]:
		run_case(name)
	for family in ["flat", "nested"]:
		for kind in ["bool", "array", "null", "string", "ordinary"]:
			run_catalog_case(family, kind)
	for name in ["tree-null", "tree-number", "tree-resource", "tree-empty", "tree-malformed"]:
		run_tree_case(name)
	for name in [
		"operand-positive-string",
		"operand-zero-string",
		"operand-negative-string",
		"operand-numeric-zero",
		"operand-numeric-positive",
		"operand-numeric-negative",
		"operand-runtime-object",
		"operand-earlier-invalid"
	]:
		run_operand(name)
	for name in [
		"metadata-nested-object",
		"metadata-nested-skip",
		"metadata-nested-zero",
		"metadata-nested-content",
		"metadata-flat-zero",
		"metadata-flat-object"
	]:
		run_metadata(name)
	quit()
