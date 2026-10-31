## Child-only callback/read/alias/native-abort characterization for test_model_compatibility.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const Cases := preload("res://ontology/callback_expectations_test_support.gd")
const CATALOGS := [
	"races",
	"classes",
	"specs",
	"abilities",
	"weapon_types",
	"materials",
	"rarities",
	"creatures",
	"pet_foods",
	"landscapes",
	"status_effects",
	"consumables",
	"key_items",
	"rulesets",
	"configs"
]


class Key:
	extends RefCounted
	var action: Callable
	var at := 1
	var calls := 0
	var enabled := OS.get_environment("PROBE_CONTROL") != "1"
	var text := "key"

	func _to_string() -> String:
		calls += 1
		if enabled and calls == at and action.is_valid():
			action.call()
		return text


class Mutation:
	extends Model.Ontology
	var action: Callable
	var point := ""
	var hook := "shape"
	var paths: Array = []
	var keys: Array = []
	var changed := false

	func fire(path: String, at_hook: String) -> void:
		if not changed and path == point and hook == at_hook and action.is_valid():
			changed = true
			action.call()

	func _input_shape(value: Variant, kind: String, path: String) -> bool:
		paths.append(path)
		var result := super._input_shape(value, kind, path)
		fire(path, "shape")
		return result

	func _fields_valid(row: Variant, path: String, fields: Dictionary) -> bool:
		var result := super._fields_valid(row, path, fields)
		fire(path, "fields")
		return result

	func _optional_fields_valid(row: Dictionary, path: String, fields: Dictionary) -> bool:
		var result := super._optional_fields_valid(row, path, fields)
		fire(path, "optional")
		return result

	func _role_fields_valid(row: Dictionary, path: String) -> bool:
		var result := super._role_fields_valid(row, path)
		fire(path, "role")
		return result


func loaded() -> Mutation:
	var o := Mutation.new()
	var base := Model.Ontology.load_dir("res://ontology/instances")
	for field in CATALOGS:
		o.set(field, base.get(field))
	return o


func tree_case(name: String, enabled: bool) -> void:
	var o := Mutation.new()
	var a := Model.Ability.new()
	a.owner = "warrior"
	a.alpha_tree = {"column": "class", "rank": 1, "needs": 0}
	var key := Key.new()
	o.keys.append(key)
	if enabled:
		if name == "tree-owner":
			key.action = func(): a.owner = "mage"
		else:
			key.action = func():
				a.alpha_tree = {"column": "class", "rank": 1, "needs": 0, "class": "mage"}
	o.abilities[key] = a
	var result := o.skill_tree(&"warrior", &"berserker")
	print(
		"PROBE ", JSON.stringify([name, result.size(), Array(o.errors), key.calls], "", false, true)
	)


func channel_case(enabled: bool) -> void:
	var o := Mutation.new()
	var row := {"runtime": "channel", "turns-per-s": 1, "drain-per-s": 0}
	if enabled:
		o.point = "ability.turns-per-s"
		o.action = func(): row["turns-per-s"] = []
	var result := o._ability_fields_valid(row, "ability")
	print("PROBE ", JSON.stringify(["channel", result, Array(o.errors), o.paths], "", false, true))


func configure(o, name: String) -> void:
	match name.get_slice("-", 0):
		"variant":
			configure_variant(o, name)
		"numeric":
			configure_numeric(o, name)
		"diagnostic":
			configure_diagnostic(o, name)
		"catalog":
			configure_catalog(o, name)
		"event":
			configure_events(o, name)
		"sound":
			configure_sounds(o, name)
		"weight":
			configure_weight(o, name)
		"species":
			configure_species(o, name)


func configure_variant(o, name: String) -> void:
	var design: Dictionary = o.configs.generators.design
	var feel: Dictionary = design.feel
	if name.begins_with("variant-"):
		var parts := name.trim_prefix("variant-").split(":")
		var row: Dictionary = feel[parts[0]]
		o.point = "design.feel." + parts[0]
		o.hook = "fields"
		match parts[2]:
			"array":
				o.action = func(): row[parts[1]] = []
			"object":
				o.action = func(): row[parts[1]] = RefCounted.new()
			"null":
				o.action = func(): row[parts[1]] = null
			"string":
				o.action = func(): row[parts[1]] = "0.5"
			"negative":
				o.action = func(): row[parts[1]] = -1


func configure_diagnostic(o, name: String) -> void:
	var design: Dictionary = o.configs.generators.design
	var feel: Dictionary = design.feel
	if name.begins_with("diagnostic-"):
		var key := Key.new()
		o.keys.append(key)
		key.at = 2
		if name.begins_with("diagnostic-sound"):
			var row := {"hz": -1, "len-s": 0.1, "noise": 0, "slide": 0}
			feel.sfx[key] = row
			if name == "diagnostic-sound-slot":
				key.action = func(): feel.sfx[key] = {"len-s": []}
			else:
				key.action = func(): row["len-s"] = []
		else:
			var row := {"hit-stop-s": -1, "trauma": 0, "sfx": "hit"}
			feel.events[key] = row
			key.action = func(): row["trauma"] = []


func configure_species(o, name: String) -> void:
	var design: Dictionary = o.configs.generators.design
	if name == "species-mutated-alias":
		var roles: Dictionary = design["creature-roles"]
		roles["species"] = {"collie": {}}
		var ov: Dictionary = roles.species.collie
		o.point = "design.creature-roles.species.collie"
		o.hook = "role"
		o.action = func(): ov["kind"] = "projectile"
	elif name.begins_with("species-"):
		var roles: Dictionary = design["creature-roles"]
		roles["species"] = {"collie": {}}
		o.point = "design.creature-roles.species.collie"
		o.hook = "shape" if name == "species-shape" else "role"
		if name == "species-alias":
			o.action = func(): roles.species.collie = {"kind": "projectile"}
		else:
			o.action = func(): roles.species.collie = []


func configure_weight(o, name: String) -> void:
	var design: Dictionary = o.configs.generators.design
	if name == "weight-key":
		var roles: Dictionary = design["creature-roles"]
		var key := Key.new()
		o.keys.append(key)
		key.text = "melee"
		key.at = 3
		roles["any-class"] = {key: -1}
		key.action = func(): roles["any-class"][key] = 1
	elif name.begins_with("weight-"):
		var roles: Dictionary = design["creature-roles"]
		roles["any-class"] = {"melee": 1}
		o.point = "design.creature-roles.any-class.melee"
		if name == "weight-negative":
			o.action = func(): roles["any-class"]["melee"] = -1
		else:
			o.action = func(): roles["any-class"]["melee"] = []


func configure_numeric(o, name: String) -> void:
	var design: Dictionary = o.configs.generators.design
	var feel: Dictionary = design.feel
	if name.begins_with("numeric-"):
		var parts := name.trim_prefix("numeric-").split(":")
		o.point = "design.feel." + parts[0]
		o.hook = "fields"
		var row: Dictionary = feel[parts[0]]
		o.action = func(): row.erase(parts[1])


func configure_events(o, name: String) -> void:
	var design: Dictionary = o.configs.generators.design
	var feel: Dictionary = design.feel
	if name == "event-key":
		var key := Key.new()
		o.keys.append(key)
		feel.events[key] = {}
		key.action = func(): feel.events[key] = {"trauma": 2}
	elif name.begins_with("event-"):
		o.point = "design.feel.events.hit"
		if name == "event-shape":
			o.action = func(): feel.events.hit = []
		else:
			o.hook = "optional"
			var row: Dictionary = feel.events.hit
			o.action = func(): row["trauma"] = []


func configure_sounds(o, name: String) -> void:
	var feel: Dictionary = o.configs.generators.design.feel
	if name == "sound-shape":
		var id = feel.sfx.keys()[0]
		o.point = "design.feel.sfx." + str(id)
		o.hook = "fields"
		o.action = func(): feel.sfx[id] = {"hz": -1, "len-s": 0.1, "noise": 0, "slide": 0}
	elif name == "sound-failure":
		var id = feel.sfx.keys()[0]
		o.point = "design.feel.sfx." + str(id)
		o.hook = "fields"
		var row: Dictionary = feel.sfx[id]
		o.action = func(): row["hz"] = []


func configure_catalog(o, name: String) -> void:
	if name == "catalog-key":
		var key := Key.new()
		o.keys.append(key)
		key.at = 3
		o.configs.ingredients[key] = {"probe": 1}
		key.action = func(): o.configs.ingredients[key] = {}
	elif name == "catalog-shape":
		o.configs.ingredients["probe"] = {"probe": 1}
		o.point = "ingredients.probe"
		o.action = func(): o.configs.ingredients["probe"] = {}


func validation_case(name: String, enabled: bool) -> void:
	var o := loaded()
	configure(o, name)
	if not enabled:
		o.action = Callable()

	o.rulesets["ruleset-hybrid"].is_default = false
	var result := o.validate()
	print("PROBE ", JSON.stringify([name, result, Array(o.errors)], "", false, true))

	o.action = Callable()
	for key in o.keys:
		key.action = Callable()
	o.keys.clear()


func run_case(name: String, enabled: bool) -> void:
	if name.begins_with("tree-"):
		tree_case(name, enabled)
	elif name == "channel":
		channel_case(enabled)
	else:
		validation_case(name, enabled)


func _init() -> void:
	var first := int(OS.get_environment("CALLBACK_GROUP"))
	for enabled in [false, true]:
		OS.set_environment("PROBE_CONTROL", "0" if enabled else "1")
		for index in range(first, mini(first + 8, Cases.CASES.size())):
			run_case(Cases.CASES[index], enabled)
	quit()
