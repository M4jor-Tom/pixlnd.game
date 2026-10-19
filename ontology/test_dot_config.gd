## Selected combat DOT inputs must fail closed; broader validation remains separate.
extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1; printerr("FAIL: ", label)
func rejected(value: Variant, path: String, label: String) -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	o.configs["generators"]["design"]["status-effects"] = value
	check(not o.validate(), label + " rejected")
	check(path in "\n".join(o.errors), label + " has scoped diagnostic")
func _init() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "shipped ontology passes")
	var se: Dictionary = o.configs["generators"]["design"]["status-effects"]
	o.configs["generators"]["design"].erase("status-effects")
	check(not o.validate(), "missing whole DOT block rejected")
	check("design.status-effects: required object missing or malformed" in o.errors, "missing whole block has scoped diagnostic")
	for value in [null, [], "burning", 1, true]:
		rejected(value, "design.status-effects", "malformed whole block " + str(value))
	for id in ["burning", "poison"]:
		var missing := se.duplicate(true); missing.erase(id)
		rejected(missing, "design.status-effects." + id, "missing " + id)
		for value in [null, [], "burning", 1, true]:
			var bad := se.duplicate(true); bad[id] = value
			rejected(bad, "design.status-effects." + id, "malformed row " + id + str(value))
		for field in ["duration-s", "tick-s", "pct-of-hit"]:
			var absent := se.duplicate(true); absent[id].erase(field)
			rejected(absent, "design.status-effects." + id + "." + field, "missing " + id + field)
			for value in [null, [], {}, "1", true, -1, 0, 99, NAN, INF]:
				var bad := se.duplicate(true); bad[id][field] = value
				rejected(bad, "design.status-effects." + id + "." + field, "invalid " + id + field + str(value))
	var alias := se.duplicate(true); alias["poison"]["as"] = "slow"
	rejected(alias, "design.status-effects.poison.as", "misrouted poison")
	var both := se.duplicate(true); both["burning"]["tick-s"] = 0; both["poison"]["duration-s"] = 0
	var invalid = Model.Ontology.load_dir("res://ontology/instances")
	invalid.configs["generators"]["design"]["status-effects"] = both
	check(not invalid.validate(), "multiple invalid fields rejected")
	check("design.status-effects.burning.tick-s" in "\n".join(invalid.errors) and "design.status-effects.poison.duration-s" in "\n".join(invalid.errors), "errors accumulate")
	print("DOT config ok" if failed == 0 else "DOT config FAILED: %d" % failed)
	quit(0 if failed == 0 else 1)
