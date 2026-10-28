## Apple selected-input negatives through real ingestion and loaded validation.
## No checked-in data is changed; each case owns its model and dictionaries.
extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0
var checks := 0


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func fresh():
	return Model.Ontology.load_dir("res://ontology/instances")


func selected_fixture():
	var o = fresh()
	# Each negative starts from a valid selected coefficient.
	o.configs.consumables.apple["heal-mult"] = 20
	o.consumables.apple.heal_mult = 20
	return o


func rejected(o, label: String) -> void:
	var valid: bool = o.validate()
	var diagnostics: String = "\n".join(o.errors)
	print("NEGATIVE ", label, " valid=", valid, " diagnostics=", diagnostics.replace("\n", " | "))
	check(not valid, label + " must reject")
	check("consumables.apple" in diagnostics, label + " must diagnose selected Apple input")


func raw_case(mode: String, value: Variant = null) -> void:
	var o = selected_fixture()
	var data: Dictionary = o.configs.consumables.duplicate(true)
	match mode:
		"absent-row":
			data.erase("apple")
		"malformed-row":
			data.apple = value
		"absent-coefficient":
			data.apple.erase("heal-mult")
		_:
			data.apple["heal-mult"] = value
	o.consumables.clear()  # Do not allow a stale loaded row to mask raw failure.
	o._ingest("consumables", data)
	rejected(o, "raw " + mode + " " + str(value))


func _init() -> void:
	var shipped = fresh()
	check(shipped.validate(), "shipped ontology validates")
	check(shipped.consumables.apple.heal_mult == 20, "shipped loaded Apple coefficient must be 20")
	check(
		shipped.configs.consumables.apple.get("heal-mult") == 20,
		"shipped raw Apple coefficient must be 20"
	)
	var good = selected_fixture()
	check(good.validate(), "test-only selected Apple20 fixture validates")
	check(
		not good.configs.consumables.cookie.has("heal-mult"),
		"control: nonhealing food remains optional"
	)
	var absent_catalog = selected_fixture()
	absent_catalog.configs.erase("consumables")
	rejected(absent_catalog, "raw absent consumables catalog")
	for value in [null, [], "consumables", true, 20]:
		var malformed = selected_fixture()
		malformed.configs.consumables = value
		rejected(malformed, "raw malformed consumables catalog " + str(value))
	var empty_loaded = selected_fixture()
	empty_loaded.consumables.clear()
	rejected(empty_loaded, "loaded empty consumables catalog")
	var float_control = selected_fixture()
	float_control.configs.consumables.apple["heal-mult"] = 20.0
	check(float_control.validate(), "exact numeric 20.0 is valid without integer coercion")
	raw_case("absent-row")
	for value in [null, [], "apple", true, 20]:
		raw_case("malformed-row", value)
	raw_case("absent-coefficient")
	for value in [null, [], {}, "20", true, 0, -1, 19, 200, 20.5, INF, NAN]:
		raw_case("coefficient", value)
	# Detach config from Entry.raw: loaded correctness must not mask invalid raw config.
	for value in [null, [], {}, "20", true, 0, 19, 20.5, INF, NAN]:
		var o = selected_fixture()
		o.configs.consumables = o.configs.consumables.duplicate(true)
		o.configs.consumables.apple["heal-mult"] = value
		check(o.consumables.apple.raw["heal-mult"] == 20, "loaded raw control stays valid")
		rejected(o, "detached raw coefficient " + str(value))
	# Loaded catalog deletion and typed value drift are independent of the raw config.
	var missing = selected_fixture()
	missing.consumables.erase(&"apple")
	rejected(missing, "loaded absent Apple")
	for value in [0, -1, 19, 200]:
		var o = selected_fixture()
		o.consumables.apple.heal_mult = value
		rejected(o, "loaded coefficient " + str(value))
	# Detach Entry.raw, otherwise the alias changes configs and hides which boundary is checked.
	var absent = selected_fixture()
	absent.consumables.apple.raw = absent.consumables.apple.raw.duplicate(true)
	absent.consumables.apple.raw.erase("heal-mult")
	rejected(absent, "loaded raw absent coefficient")
	for value in [null, [], {}, "20", true, 0, 19, 20.5, INF, NAN]:
		var o = selected_fixture()
		o.consumables.apple.raw = o.consumables.apple.raw.duplicate(true)
		o.consumables.apple.raw["heal-mult"] = value
		rejected(o, "loaded raw coefficient " + str(value))
	var cumulative = selected_fixture()
	cumulative.errors.append("prior load sentinel")
	cumulative.consumables.apple.heal_mult = 0
	rejected(cumulative, "cumulative Apple and prior load error")
	check("prior load sentinel" in cumulative.errors, "prior load error remains")
	print("Apple config: checks=", checks, " failures=", failed)
	quit(0 if failed == 0 else 1)
