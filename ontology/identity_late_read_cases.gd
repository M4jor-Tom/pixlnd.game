## Whole-identity late Ability reads; the selected validation tree remains the original alias.
extends RefCounted
const Model := preload("res://ontology/model.gd")
const PRIOR := [
	"prior",
	"classes: required catalog object with rows",
	"classes.warrior: required identity row",
	"classes.ranger: required identity row",
	"classes.mage: required identity row",
	"classes.rogue: required identity row",
	"specializations: required catalog object with rows",
	"specializations.berserker: required identity row",
	"specializations.guardian: required identity row",
	"specializations.sniper: required identity row",
	"specializations.scout: required identity row",
	"specializations.fire-mage: required identity row",
	"specializations.water-mage: required identity row",
	"specializations.assassin: required identity row",
	"specializations.ninja: required identity row",
	"abilities: required catalog object with rows",
	"abilities.camouflage: required identity row"
]


class TreeProbe:
	extends Model.Ontology
	static var target: Resource
	static var selected: Dictionary
	static var mode := ""
	static var events: Array = []

	static func _tree_field_errors(tree: Variant, path: String) -> Array:
		events.append(["tree", is_same(tree, selected), path])
		var result := super._tree_field_errors(tree, path)
		if mode == "validator-owner":
			target.owner = "missing"
		elif mode == "validator-tree":
			target.alpha_tree = {"class": "missing", "column": "bad"}
		return result


class Key:
	extends RefCounted
	var target: Resource
	var mode := ""
	var calls := 0

	func _to_string() -> String:
		calls += 1
		TreeProbe.events.append(["key", calls])
		if calls == 2:
			if mode == "key-owner":
				target.owner = "missing"
			elif mode in ["key-tree", "malformed-selected"]:
				target.alpha_tree = {"class": "missing", "column": "bad"}
		return "key"


static func run(test) -> void:
	for mode in [
		"control",
		"class-precedence",
		"key-owner",
		"key-tree",
		"validator-owner",
		"validator-tree",
		"malformed-selected",
		"empty"
	]:
		_run_case(test, mode)


static func _run_case(test, mode: String) -> void:
	var o := TreeProbe.new()
	var a := Model.Ability.new()
	a.owner = "all"
	a.raw = {"owner": "all"}
	a.alpha_tree = {"column": "class", "rank": 1, "needs": 0}
	if mode == "empty":
		a.alpha_tree = {}
	elif mode == "class-precedence":
		a.owner = "missing"
		a.alpha_tree["class"] = "all"
	elif mode == "malformed-selected":
		a.alpha_tree["needs"] = -1
	var key := Key.new()
	key.target = a
	key.mode = mode
	o.abilities[key] = a
	o.errors.append("prior")
	TreeProbe.target = a
	TreeProbe.selected = a.alpha_tree
	TreeProbe.mode = mode
	TreeProbe.events = []
	o._validate_identity()
	var expected := PRIOR.duplicate()
	var events: Array = [["key", 1]]
	if mode != "empty":
		events.append_array([["key", 2], ["tree", true, "abilities.key.alpha-tree"]])
	if mode == "malformed-selected":
		expected.append("abilities.key.alpha-tree.needs: nonnegative integer required")
	if mode in ["key-owner", "key-tree", "validator-owner", "validator-tree", "malformed-selected"]:
		expected.append("abilities.key.alpha-tree.class: known tree owner required")
		events.append(["key", 3])
	print("IDENTITY_LATE ", JSON.stringify([mode, Array(o.errors), TreeProbe.events]))
	test.check(Array(o.errors) == expected, "whole identity ordered late-read diagnostics " + mode)
	test.check(TreeProbe.events == events, "identity selected alias/callback order " + mode)
	TreeProbe.target = null
	TreeProbe.selected = {}
	TreeProbe.events = []
