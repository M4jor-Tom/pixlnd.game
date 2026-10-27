## Regression of corrected checked-in artifact data, not production artifact enforcement.
extends SceneTree

var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func read_json(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://ontology/instances/" + name))


func _init() -> void:
	var generators := read_json("generators.json")
	var config: Dictionary = generators.design.artifact
	check(config.get("first") == 0.05, "first contribution stays 5%")
	check(config.get("z") == 0.1, "initial adjustable z is 0.1")
	check(not config.has("decay") and not config.has("floor"), "obsolete decay/floor removed")
	check(
		config.get("total-bonus") == "B(x) = first * ln(1 + z * x) / ln(1 + z)",
		"normalized logarithmic total recorded"
	)
	var semantics := str(config.get("stats", ""))
	for term in ["z > 0", "B(0) = 0", "B(x)/x", "additive", "current artifact-free"]:
		check(term in semantics, "config semantics: " + term)
	check(
		(
			generators.design["artifacts-per-land"].min == 1
			and generators.design["artifacts-per-land"].max == 3
			and (
				generators.design["artifacts-per-land"].roll
				== "uniform, seeded, at land generation (D11)"
			)
		),
		"existing per-land allocation config unchanged"
	)
	var items := read_json("key-items.json")
	var artifact: Dictionary = items.artifact
	check(
		(
			artifact["stat-kinds"]
			== [
				"climb-speed",
				"swim-speed",
				"diving-skill",
				"ride-speed",
				"glide-speed",
				"sail-speed",
				"light-radius"
			]
		),
		"seven stable traversal kinds unchanged"
	)
	check(
		artifact.versions == ["S"] and artifact["alpha-static-entity"] == 46,
		"source identities retained"
	)
	check(
		(
			items["counts-per-land-s"].movement == 4
			and items["counts-per-land-s"].ticket == 3
			and items["counts-per-land-s"]["total-max"] == 9
			and items["counts-per-land-s"]["gnome-suppliers"] == 4
			and items["counts-per-land-s"].books == 4
		),
		"historical per-land counts unchanged"
	)
	var historical := ""
	var hybrid := ""
	for rule in artifact.rules:
		if rule.begins_with("S reference:"):
			historical += rule + "\n"
		if rule.begins_with("Hybrid:"):
			hybrid += rule + "\n"
	for term in [
		"+1 character level", "non-functional", "lootable by all players", "100% realm lore"
	]:
		check(term in historical, "historical report scoped: " + term)
	for term in [
		"exactly one",
		"attack and max HP",
		"no character levels",
		"no traversal-gate bypass",
		"matching artifacts",
		"all artifacts",
		"B(x)/x",
		"additive",
		"current artifact-free"
	]:
		check(term in hybrid, "hybrid description: " + term)
	var rulesets := read_json("rulesets.json")
	var selected: Dictionary = rulesets["ruleset-hybrid"]
	check(
		not "D6 bonuses unchanged" in selected._rule, "hybrid no longer claims obsolete D6 bonuses"
	)
	check("logarithmic" in selected._rule, "hybrid points to approved logarithmic bonuses")
	check(
		selected.flags.artifacts and not selected.flags["artifacts-define-level"],
		"hybrid flags unchanged"
	)
	print("artifact corrections: ", failed, " failures")
	quit(1 if failed else 0)
