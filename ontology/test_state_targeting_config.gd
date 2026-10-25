extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	var expected := {
		"time": {"speed": 10.0, "day-s": 86400.0, "initial-hour": 7.0},
		"spawns.ai":
		{
			"threat-per-full-hp": 100.0,
			"threat-decay-per-s": 1.0,
			"return-speed-mult": 2.0,
			"return-damage-reduction": 0.9
		},
		"abilities.heroic-shout": {"taunt-s": 3.0}
	}
	var shipped = Model.Ontology.load_dir("res://ontology/instances")
	check(shipped.validate(), "shipped valid")
	for path in expected:
		for field in expected[path]:
			for bad in [null, "invalid", true, [], {}, -1, INF, NAN, expected[path][field] + 1.0]:
				var o = Model.Ontology.load_dir("res://ontology/instances")
				var row: Dictionary = o.configs["generators"]["design"]
				for part in path.split("."):
					if not row.get(part) is Dictionary:
						row[part] = {}
					row = row[part]
				row[field] = bad
				o.errors.append("earlier error")
				check(not o.validate(), path + "." + field + " rejected")
				check(
					"design." + path + "." + field in "\n".join(o.errors),
					"specific diagnostic " + path + "." + field
				)
				check("earlier error" in o.errors, "cumulative errors")
		# Whole selected parents are required, not optional/defaulted.
		for bad in [null, "bad", [], {}, true]:
			var o = Model.Ontology.load_dir("res://ontology/instances")
			var row: Dictionary = o.configs.generators.design
			var parts: PackedStringArray = path.split(".")
			for part in parts.slice(0, parts.size() - 1):
				row = row[part]
			row[parts[-1]] = bad
			check(
				not o.validate() and "design." + path in "\n".join(o.errors),
				"selected parent rejected " + path
			)
	print(
		"state targeting config ok" if failed == 0 else "state targeting config FAILED %d" % failed
	)
	quit(0 if failed == 0 else 1)
