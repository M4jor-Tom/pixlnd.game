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
	check(not o.validate(), path + " rejected")
	if not path in "\n".join(o.errors):
		printerr("missing diagnostic ", path, " from ", o.errors)
	check(path in "\n".join(o.errors), path + " diagnosed")


func _init() -> void:
	var shipped = fresh()
	check(shipped.validate(), "shipped encounter configuration valid")
	var shipped_flag: Variant = shipped.rulesets["ruleset-hybrid"].flags["settlements-per-land"]
	check(
		(shipped_flag is int or shipped_flag is float) and shipped_flag == 1,
		"hybrid settlement flag is exactly one"
	)

	for path in ["generators", "design", "settlement"]:
		var o = fresh()
		if path == "generators":
			o.configs.erase("generators")
		elif path == "design":
			o.configs["generators"].erase("design")
		else:
			o.configs["generators"]["design"].erase("settlement")
		reject(o, "design.settlement")

	for path in ["generators", "design", "settlement"]:
		for bad in [null, [], "invalid", true]:
			var o = fresh()
			if path == "generators":
				o.configs["generators"] = bad
			elif path == "design":
				o.configs["generators"]["design"] = bad
			else:
				o.configs["generators"]["design"]["settlement"] = bad
			reject(o, "design.settlement")

	var empty = fresh()
	empty.configs["generators"]["design"]["settlement"] = {}
	reject(empty, "design.settlement.per-land")

	for path in ["rulesets", "ruleset-hybrid", "flags"]:
		var o = fresh()
		if path == "rulesets":
			o.rulesets.clear()
		elif path == "ruleset-hybrid":
			o.rulesets.erase("ruleset-hybrid")
		else:
			o.rulesets["ruleset-hybrid"].raw.erase("flags")
		reject(o, "rulesets.ruleset-hybrid" if path != "flags" else "rulesets.ruleset-hybrid.flags")

	var missing_count = fresh()
	missing_count.configs["generators"]["design"]["settlement"].erase("per-land")
	reject(missing_count, "design.settlement.per-land")
	var missing_flag = fresh()
	missing_flag.rulesets["ruleset-hybrid"].raw["flags"].erase("settlements-per-land")
	reject(missing_flag, "rulesets.ruleset-hybrid.flags.settlements-per-land")

	for bad in [null, [], {}, "1", true, 0, 2, NAN, INF]:
		var design = fresh()
		design.configs["generators"]["design"]["settlement"]["per-land"] = bad
		reject(design, "design.settlement.per-land")
		var flag = fresh()
		flag.rulesets["ruleset-hybrid"].raw["flags"]["settlements-per-land"] = bad
		reject(flag, "rulesets.ruleset-hybrid.flags.settlements-per-land")

	for bad_flags in [null, [], "invalid", true]:
		var malformed = fresh()
		malformed.rulesets["ruleset-hybrid"].raw["flags"] = bad_flags
		reject(malformed, "rulesets.ruleset-hybrid.flags")

	var stale = fresh()
	stale.rulesets["ruleset-hybrid"].raw["flags"]["settlements-per-land"] = "many"
	reject(stale, "rulesets.ruleset-hybrid.flags.settlements-per-land")

	var changed = fresh()
	changed.configs["generators"]["design"]["settlement"]["per-land"] = 2
	changed.rulesets["ruleset-hybrid"].raw["flags"]["settlements-per-land"] = "many"
	changed.errors.append("earlier load error")
	check(not changed.validate(), "selected input changes rejected")
	var diagnostics := "\n".join(changed.errors)
	check("design.settlement.per-land" in diagnostics, "design drift diagnosed")
	check(
		"rulesets.ruleset-hybrid.flags.settlements-per-land" in diagnostics,
		"ruleset drift diagnosed"
	)
	check("earlier load error" in changed.errors, "prior load diagnostic retained")
	print(
		(
			"initial encounter config ok"
			if failed == 0
			else "initial encounter config FAILED %d" % failed
		)
	)
	quit(0 if failed == 0 else 1)
