## Required finite angular progress and nonnegative drain through actual ingestion/validation.
## Malformed configurations never reach a runtime scheduler. Zero drain is a legal bounded channel.
extends SceneTree

const Model := preload("res://ontology/model.gd")
var failures := 0
var checks := 0


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("ASSERTION FAILED [channel config]: ", label)


func fresh():
	return Model.Ontology.load_dir("res://ontology/instances")


func selected():
	var o = fresh()
	o.configs.generators.design.abilities.cyclone["turns-per-s"] = 1.0
	return o


func rejected(o, path: String, label: String) -> void:
	var valid: bool = o.validate()
	var diagnostics := "\n".join(o.errors)
	print("NEGATIVE ", label, " valid=", valid, " diagnostics=", diagnostics.replace("\n", " | "))
	check(not valid, label + " rejected")
	check(path in diagnostics, label + " locates malformed field")


func _init() -> void:
	var shipped = fresh()
	check(shipped.validate(), "shipped ontology valid")
	var raw: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://ontology/instances/generators.json")
	)
	for row in [
		["raw", raw.design.abilities.cyclone],
		["loaded", shipped.configs.generators.design.abilities.cyclone]
	]:
		var speed: Variant = row[1].get("turns-per-s")
		check(
			(speed is int or speed is float) and speed == 1.0,
			str(row[0]) + " shipped angular speed is numeric one, independently of selected fixture"
		)
	for field in ["turns-per-s", "drain-per-s"]:
		for raw_ingest in [true, false]:
			for value in [null, [], {}, "1", true, false, -1, INF, -INF, NAN]:
				var o = selected()
				var data: Dictionary = o.configs.generators.duplicate(true)
				data.design.abilities.cyclone[field] = value
				if raw_ingest:
					o._ingest("generators", data)
				else:
					o.configs.generators = data
				rejected(
					o,
					"design.abilities.cyclone." + field,
					("raw " if raw_ingest else "loaded ") + field + "=" + str(value)
				)
			var missing = selected()
			var data: Dictionary = missing.configs.generators.duplicate(true)
			data.design.abilities.cyclone.erase(field)
			if raw_ingest:
				missing._ingest("generators", data)
			else:
				missing.configs.generators = data
			rejected(
				missing,
				"design.abilities.cyclone." + field,
				"missing " + field + " raw=" + str(raw_ingest)
			)
	for raw_ingest in [true, false]:
		var zero_speed = selected()
		var data: Dictionary = zero_speed.configs.generators.duplicate(true)
		data.design.abilities.cyclone["turns-per-s"] = 0
		if raw_ingest:
			zero_speed._ingest("generators", data)
		else:
			zero_speed.configs.generators = data
		rejected(
			zero_speed,
			"design.abilities.cyclone.turns-per-s",
			"zero angular progress raw=" + str(raw_ingest)
		)
	for speed in [1, 1.0, 0.5, 2.0]:
		for drain in [0, 0.0, 25, 25.0]:
			var good = selected()
			good.configs.generators.design.abilities.cyclone["turns-per-s"] = speed
			good.configs.generators.design.abilities.cyclone["drain-per-s"] = drain
			check(good.validate(), "positive finite progress / legal drain " + str([speed, drain]))
	# Earlier errors must survive, and both malformed fields must diagnose in the same pass.
	var cumulative = selected()
	cumulative.errors.append("prior load sentinel")
	cumulative.configs.generators.design.abilities.cyclone.erase("turns-per-s")
	cumulative.configs.generators.design.abilities.cyclone["drain-per-s"] = -25
	rejected(cumulative, "design.abilities.cyclone.turns-per-s", "cumulative progress")
	check("prior load sentinel" in cumulative.errors, "prior diagnostic preserved")
	check(
		"design.abilities.cyclone.drain-per-s" in "\n".join(cumulative.errors),
		"cumulative drain diagnostic preserved"
	)
	print("Channel config SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)
