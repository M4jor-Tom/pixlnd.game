## Ordered diagnostics and original-file protection against malformed representations.
extends RefCounted
const Save := preload("res://game/world/save_data.gd")


class IntegerReceiverSave:
	extends "res://game/world/save_data.gd"

	static func number(_value: Variant, _minimum: float = 0) -> bool:
		return false


static func run(test, save, data: Dictionary, path: String) -> void:
	_equality(test)
	_static_receiver(test, save, data)
	_ordered_world(test, save, data)
	_ordered_features(test, save, data)
	_ordered_rewards(test, save, data)
	_atomic_rejection(test, save, data, path)
	_native_boundaries(test, path)


static func _expect(test, save, paths: Array) -> void:
	var expected: Array[String] = ["prior"]
	for path in paths:
		expected.append(path + ": missing, malformed or rule-invalid")
	test.check(save.errors == expected, "ordered diagnostics: " + str(paths))


static func _equality(test) -> void:
	test.check(
		Save.same_data({"v": [1, 2.0, true]}, {"v": [1.0, 2, true]}), "recursive numeric equality"
	)
	test.check(not Save.same_data([true], [1]), "boolean is not a serialized number")
	test.check(
		not Save.same_data({"v": 1, "extra": 0}, {"v": 1}), "recursive exact dictionary cardinality"
	)
	test.check(not Save.same_data([1, 2], [2, 1]), "recursive array order")
	test.check(Save.same_data(100000.0000005, 100000), "absolute tolerance inside")
	test.check(
		not Save.same_data(100000.000002, 100000), "absolute tolerance outside at world edge"
	)
	test.check(not Save.same_data(INF, INF), "nonfinite representation rejected")


static func _ordered_world(test, save, data: Dictionary) -> void:
	var w: Dictionary = data.world.duplicate(true)
	w.clock = -1
	w.mobs = []
	w.lands = []
	w.sites = {"bad": {}}
	w.vendors = []
	save.errors.assign(["prior"])
	save.validate_world(w)
	_expect(
		test,
		save,
		[
			"world.clock",
			"world.mobs",
			"world.lands",
			"world.sites complete six per generated land",
			"world.site.identity",
			"world.vendors"
		]
	)
	test.check(
		save.validate(data) and save.errors.is_empty(), "full validation resets prior errors"
	)
	save.errors.assign(["prior"])
	test.check(not save.validate_item({}, "item"), "local item rejection")
	test.check(save.errors[0] == "prior", "item validation retains prior diagnostics")


static func _ordered_features(test, save, data: Dictionary) -> void:
	var id: String = data.world.sites.keys().filter(func(k): return data.world.sites[k].family == "ruins")[0]
	var site: Dictionary = data.world.sites[id].duplicate(true)
	var layout: Dictionary = data.world.lands["0,0"].sites.filter(func(s): return s.family == "ruins")[0]
	site.room_levels = [0, 0, 0]
	site.contents.rubble[site.contents.rubble.keys()[0]] = {}
	site.contents.props[site.contents.props.keys()[0]] = {}
	site.contents.traps = [{}, {"phase": "idle", "left": 0, "hit": ["hero", "hero"]}]
	site.rewards = {"furnishing/bad": {}, "furnishing/0/not/real/prop/0": {}}
	save.errors.assign(["prior"])
	save.validate_features(site, layout, 0)
	_expect(
		test,
		save,
		[
			"world.site.room_levels.level",
			"world.site.room_levels.level",
			"world.site.room_levels.level",
			"world.site.contents.rubble.fields",
			"world.site.contents.rubble.state",
			"world.site.contents.prop.fields",
			"world.site.contents.prop.hp",
			"world.site.contents.trap.fields",
			"world.site.contents.trap.phase",
			"world.site.contents.trap.left",
			"world.site.contents.trap.hit",
			"world.site.contents.trap.hit identity",
			"world.site.contents.trap.phase hitset",
			"world.site.furnishing reward cycle",
			"world.site.furnishing reward source",
			"world.site.table issued independently",
			"world.site.table issued independently",
			"world.site.table issued independently"
		]
	)


static func _ordered_rewards(test, save, data: Dictionary) -> void:
	var id: String = data.world.sites.keys().filter(func(k): return data.world.sites[k].family == "ruins")[0]
	var site: Dictionary = data.world.sites[id].duplicate(true)
	var layout: Dictionary = data.world.lands["0,0"].sites.filter(func(s): return s.family == "ruins")[0]
	site.rewards = {
		"bad": {},
		"unknown/0": {"level": 1, "delivered": false, "payload": []},
		"kill/0/no/source": {"level": 1, "delivered": false, "payload": []}
	}
	save.errors.assign(["prior"])
	save.validate_rewards(site, layout)
	_expect(
		test,
		save,
		[
			"world.site.reward.cycle",
			"world.site.reward.unknown source",
			"world.site.kill.source",
			"world.site.kill.death receipt count"
		]
	)


static func _atomic_rejection(test, save, data: Dictionary, path: String) -> void:
	var original := FileAccess.get_file_as_bytes(path)
	var tmp := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	tmp.store_string("untouched sentinel")
	tmp.close()
	var bad := data.duplicate(true)
	bad.version = 2
	test.check(not save.write_atomic(path, bad), "schema version unchanged")
	test.check(
		FileAccess.get_file_as_bytes(path) == original, "invalid atomic write leaves original bytes"
	)
	test.check(
		FileAccess.get_file_as_string(path + ".tmp") == "untouched sentinel",
		"validation precedes touching existing temp"
	)
	DirAccess.remove_absolute(path + ".tmp")
	var malformed := path + ".contract-invalid"
	var file := FileAccess.open(malformed, FileAccess.WRITE)
	file.store_string(JSON.stringify(bad))
	file.close()
	var before := FileAccess.get_file_as_bytes(malformed)
	test.check(save.load_file(malformed).is_empty(), "malformed schema load rejected")
	test.check(
		FileAccess.get_file_as_bytes(malformed) == before, "rejected loaded file bytes unchanged"
	)
	test.check(
		save.load_file(path).size() == 3 and save.errors.is_empty(), "successful load resets errors"
	)
	DirAccess.remove_absolute(malformed)


static func _native_boundaries(test, path: String) -> void:
	for mode in ["room", "volume", "mob", "supplier", "pending", "stack"]:
		_native_boundary(test, path, mode)


static func _native_boundary(test, path: String, mode: String) -> void:
	var output: Array = []
	var status := OS.execute(
		"timeout",
		[
			"681",
			OS.get_executable_path(),
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"-s",
			"res://game/world/save_data_boundary_cases.gd",
			"--",
			path,
			mode
		],
		output,
		true
	)
	var text := "\n".join(output)
	var file := FileAccess.open(path + "." + mode + ".log", FileAccess.WRITE)
	file.store_string("exit=%d\n%s" % [status, text])
	file.close()
	var headers: Array[String] = []
	for line in text.split("\n"):
		if line.begins_with("SCRIPT ERROR:") or line.begins_with("ERROR:"):
			headers.append(line)
	var expected := _native_header(mode)
	test.check(status == 0, "bounded expected-error child exits " + mode)
	test.check(headers == [expected], "exact original native header " + mode)
	test.check(
		"BOUNDARY " + mode + " later=false" in text, "native abort stops later phases " + mode
	)

	if mode == "stack":
		test.check(
			"ITEM_RESULT false errors=[]" in text,
			"stack native return and diagnostic delta unchanged"
		)


static func _static_receiver(test, save, data: Dictionary) -> void:
	var inherited := IntegerReceiverSave.new(save.o, save.design)
	test.check(not inherited.number(1), "public overridden static remains dynamic")
	test.check(
		inherited.validate_item(data.character.bag[0], "receiver.item"),
		"instance integer keeps its original lexical number receiver"
	)


static func _native_header(mode: String) -> String:
	match mode:
		"room":
			return "SCRIPT ERROR: Invalid operands 'float' and 'String' in operator '=='."
		"volume":
			return "SCRIPT ERROR: Invalid operands 'Dictionary' and 'float' in operator '<='."
		"mob":
			return "SCRIPT ERROR: Invalid operands 'String' and 'int' in operator '>'."
		"supplier":
			return "SCRIPT ERROR: Invalid operands 'String' and 'bool' in operator '=='."
		"stack":
			return "SCRIPT ERROR: Invalid operands 'String' and 'int' in operator '=='."
	return "SCRIPT ERROR: Invalid operands 'String' and 'bool' in operator '!='."
