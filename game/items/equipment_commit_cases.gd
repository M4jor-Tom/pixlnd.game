## Native mutation-abort regression; expected errors stay in bounded child-process logs.
extends RefCounted
const Domain := preload("res://game/domain/domain.gd")
const Inventory := preload("res://game/items/inventory.gd")
const Item := preload("res://game/items/item.gd")
const CASES := [
	["equipment-open", true, [], {"main-hand": 2}, 1, []],
	[
		"equipment-locked",
		false,
		[],
		{},
		0,
		[
			"ERROR: Dictionary is in read-only state.",
			"SCRIPT ERROR: Invalid assignment on read-only value (on base: 'Dictionary')."
		]
	],
	["entries-open", true, [1], {"chest": 2}, 1, []],
	[
		"entries-locked",
		true,
		[2],
		{"chest": 2},
		1,
		["ERROR: Array is in read-only state.", "ERROR: Array is in read-only state."]
	]
]


static func run(test) -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		test.check(false, "equipment commit needs an existing isolated absolute PIXLND_TEST_DIR")
		return
	for sample in CASES:
		_run_case(test, directory, sample)


static func _run_case(test, directory: String, sample: Array) -> void:
	var output: Array = []
	var status := OS.execute(
		"timeout",
		[
			"30",
			OS.get_executable_path(),
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"-s",
			"res://game/items/test_equipment.gd",
			"--",
			"--equip-commit-case=" + sample[0]
		],
		output,
		true
	)
	var text := "\n".join(output)
	var log := FileAccess.open(
		directory.path_join("equip-commit-" + sample[0] + ".log"), FileAccess.WRITE
	)
	log.store_string("exit=%d\n%s" % [status, text])
	log.close()
	test.check(status == 0, sample[0] + " bounded child exits successfully")
	test.check(_headers(text) == sample[5], sample[0] + " exact ordered native diagnostics")
	var expected := {
		"result": sample[1], "bag": sample[2], "equipment": sample[3], "signals": sample[4]
	}
	test.check(
		_observations(text) == [JSON.stringify(expected)],
		sample[0] + " independent result/partial-state/signals"
	)


static func _headers(text: String) -> Array:
	var headers: Array = []
	for line in text.split("\n"):
		if (
			line.begins_with("ERROR:")
			or line.begins_with("SCRIPT ERROR:")
			or line.begins_with("ontology INVALID")
		):
			headers.append(line)
	return headers


static func _observations(text: String) -> Array:
	var observations: Array = []
	for line in text.split("\n"):
		if line.begins_with("EQUIP_COMMIT "):
			observations.append(line.trim_prefix("EQUIP_COMMIT "))
	return observations


static func probe(mode: String) -> Dictionary:
	var o = Domain.Ontology.load_dir()
	var inv := Inventory.new(o, o.configs.generators.design, &"warrior", func(): return 100)
	var it := Item.new()
	it.type = &"weapon"
	it.subtype = &"sword"
	it.material = &"iron"
	it.modifier = 2
	if mode.begins_with("entries"):
		it.type = &"chest-armor"
		it.subtype = &""
		var old := Item.new()
		old.type = &"chest-armor"
		old.material = &"iron"
		old.modifier = 1
		inv.equipment[&"chest"] = old
	inv.entries.append(it)
	var changes := [0]
	inv.changed.connect(func(): changes[0] += 1)
	if mode == "equipment-locked":
		inv.equipment.make_read_only()
	elif mode == "entries-locked":
		inv.entries.make_read_only()
	var result := inv.equip(it)
	var worn := {}
	for slot in inv.equipment:
		worn[str(slot)] = inv.equipment[slot].modifier
	return {
		"result": result,
		"bag": inv.entries.map(func(entry): return entry.modifier),
		"equipment": worn,
		"signals": changes[0]
	}
