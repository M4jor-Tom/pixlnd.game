## Scoped Android required-input/reference regressions; broader catalog validation is deferred.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const ACTIONS := ["move", "look", "zoom", "sprint", "jump", "swim-ascent", "basic-attack", "special-attack", "block", "dodge", "class-skill-1", "class-skill-2", "class-skill-3", "class-skill-4", "interact", "pick-up", "quick-item", "inventory", "skills-window", "ui-cancel", "equip-item", "use-inventory-item", "spend-skill-point", "buy-item", "sell-item", "world-map"]
var failed := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1; printerr("FAIL: ", message)
func fresh():
	return Model.Ontology.load_dir("res://ontology/instances")
func rejected(value: Variant, label: String) -> void:
	var o = fresh(); o.configs["controller-profiles"] = value
	check(not o.validate(), label + " rejected")
	check("controller-profiles.android" in "\n".join(o.errors), label + " has path diagnostic")
func _init() -> void:
	var o = fresh()
	check(o.validate(), "valid ontology")
	check(o.configs.has("controller-profiles"), "required executable Android profile exists")
	var missing = fresh(); missing.configs.erase("controller-profiles")
	check(not missing.validate(), "missing whole profile rejected")
	if not o.configs.has("controller-profiles"):
		quit(1); return
	var profile: Dictionary = o.configs["controller-profiles"]
	var android: Dictionary = profile["android"]
	var controls := FileAccess.get_file_as_string("res://ontology/domain/controls.md")
	check(android["actions"].size() == ACTIONS.size(), "exact selected action set")
	for action in ACTIONS:
		check(action in android["actions"] and ('id="%s"' % action) in controls, "canonical reference " + action)
	check(android["actions"].count("world-map") == 1, "world-map action is required exactly once")
	var missing_map: Dictionary = profile.duplicate(true)
	missing_map["android"]["actions"].erase("world-map")
	rejected(missing_map, "missing world-map action")
	var missing_map_model = fresh(); missing_map_model.configs["controller-profiles"] = missing_map
	missing_map_model.validate()
	check("controller-profiles.android.actions: required distinct first-slice action array" in "\n".join(missing_map_model.errors), "missing world-map reports action-array diagnostic")
	var duplicate_map: Dictionary = profile.duplicate(true)
	duplicate_map["android"]["actions"].append("world-map")
	rejected(duplicate_map, "duplicate world-map action")
	var substituted_map: Dictionary = profile.duplicate(true)
	substituted_map["android"]["actions"][ACTIONS.find("world-map")] = "block"
	check(substituted_map["android"]["actions"].size() == ACTIONS.size(), "world-map substitution preserves array length")
	rejected(substituted_map, "substituted world-map action")
	var substituted_model = fresh(); substituted_model.configs["controller-profiles"] = substituted_map
	substituted_model.validate()
	check("controller-profiles.android.actions: required unique canonical action world-map" in "\n".join(substituted_model.errors), "substituted world-map reports required-action diagnostic")
	for value in [null, [], 1, "android", {}, {"android": null}, {"android": []}]:
		rejected(value, "malformed profile " + str(value))
	for field in ["deadzone-ratio", "min-target-dp", "look-deg-per-safe-width", "actions"]:
		var bad := profile.duplicate(true); bad["android"].erase(field)
		rejected(bad, "missing " + field)
	for field in ["deadzone-ratio", "min-target-dp", "look-deg-per-safe-width"]:
		for value in [null, "48", true, [], {}, -1, 0, 999]:
			var bad := profile.duplicate(true); bad["android"][field] = value
			rejected(bad, "invalid " + field + " " + str(value))
	for value in [null, {}, "move", ["move"], ACTIONS + ["ultimate"], ACTIONS + ["class-skill-5"], ACTIONS + ["block"], ACTIONS.filter(func(a): return a != "block")]:
		var bad := profile.duplicate(true); bad["android"]["actions"] = value
		rejected(bad, "invalid action set " + str(value))
	for substitute in ["unknown-action", "move", "special-attack/block"]:
		var bad := profile.duplicate(true)
		bad["android"]["actions"][ACTIONS.find("block")] = substitute
		check(bad["android"]["actions"].size() == ACTIONS.size(), "F6 same-length fixture " + substitute)
		var invalid = fresh(); invalid.configs["controller-profiles"] = bad
		check(not invalid.validate(), "F6 same-length substitution rejected " + substitute)
		check("controller-profiles.android.actions: required unique canonical action block" in invalid.errors, "F6 required Block diagnostic " + substitute)
		if substitute == "move":
			check("controller-profiles.android.actions: required unique canonical action move" in invalid.errors, "F6 duplicate Move diagnostic")
	print("android profile ok" if failed == 0 else "android profile FAILED: %d" % failed)
	quit(0 if failed == 0 else 1)
