extends SceneTree
# Actual six-site save, purchased stock and delivered historical mission/kill receipts.
# Default invocation also loads the files in a bounded fresh Godot process.
const Save := preload("res://game/world/save_data.gd")
const State := preload("res://game/world/world_state.gd")
const Model := preload("res://ontology/model.gd")
const World := preload("res://game/world/world.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const POWERS := {7: 24, 8: 26, 9: 29, 10: 32, 11: 34, 12: 36, 13: 38}
const VENDOR_POWERS := {
	"0,0/weapon-vendor": [34, 36, 35, 34, 33, 35, 36],
	"0,0/armor-vendor": [34, 33, 33, 31, 31, 31, 37, 35]
}
var failed := 0


func check(ok: bool, label: String, actual: Variant = null) -> void:
	print("PASS " if ok else "FAIL ", label, " actual=", JSON.stringify(actual))
	if not ok:
		failed += 1


func raw_write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "", true, true))
	file.close()


func rejects_original(save, directory: String, name_: String, data: Dictionary) -> void:
	var path := directory.path_join(name_ + ".json")
	raw_write(path, data)
	var before := FileAccess.get_file_as_string(path)
	check(save.load_file(path).is_empty(), name_ + " full disk rejection", save.errors.duplicate())
	check(FileAccess.get_file_as_string(path) == before, name_ + " original bytes protected")


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		printerr("existing isolated absolute PIXLND_TEST_DIR required")
		quit(2)
		return
	var o := Model.Ontology.load_dir("res://ontology/instances")
	if not o.validate() or not o.errors.is_empty():
		printerr("ontology invalid ", o.errors)
		quit(2)
		return
	var d: Dictionary = o.configs.generators.design
	var save := Save.new(o, d)
	if "--read" in OS.get_cmdline_user_args():
		cold_read(save, directory)
		print("COLD_READ_RESULT failures=", failed)
		quit(0 if failed == 0 else 1)
		return
	var p = PLAYER.instantiate()
	root.add_child(p)
	p.setup(d.movement, d.camera, &"normal")
	p.setup_combat(d.combat, d.crit, {}, 100)
	p.setup_items(o, d)
	p.logical_id = "f7-cold-hero"
	p.set_physics_process(false)
	while p.level < 10:
		p.gain_xp(Model.xp_to_next(p.level) - p.xp)
	p.inventory.coins = 100000
	var state := State.new(d, 26879)
	var world := World.new()
	root.add_child(world)
	world.configure(o, d, state, func(): return [p])
	world.target = p
	world.set_physics_process(false)
	world.set_process(false)
	world.targeting.set_physics_process(false)
	check(
		world.ensure_land(world.gen.land_at(Vector2i.ZERO)),
		"actual complete six-site geometry staged"
	)
	var stock: Array = world.vendor_stock(&"weapon-vendor", 10, Vector2i.ZERO)
	world.vendor_stock(&"armor-vendor", 10, Vector2i.ZERO)
	check(
		world.buy_vendor(&"weapon-vendor", 0, p, Vector2i.ZERO, stock[0]),
		"actual saved vendor purchase"
	)
	# Real completion and safe renewal preserve delivered historical receipts, not invented history.
	var camp_id: String = state.site_id(Vector2i.ZERO, "camp", 0)
	var layout: Dictionary = world.site_layout(camp_id)
	p.set_logical_position([layout.centre[0], layout.floor, layout.centre[1]])
	world.stream_sites()
	for mob in world.targeting.live.values():
		mob.set_physics_process(false)
	for stable in layout.assignments:
		world.targeting.live[camp_id + "/" + stable.key].take_damage(1e9, p)
	var camp: Dictionary = state.sites[camp_id]
	check(
		camp.cleared and camp.rewards["mission/0"].delivered,
		"real delivered mission before renewal"
	)
	camp.pending = true
	p.set_logical_position([0, 100, 0])
	state.advance(0, [[0, 100, 0]])
	check(camp.cycle == 1 and not camp.cleared, "real renewal retains past completion")
	var data := save.capture(state, p)
	var path := directory.path_join("current-rule.json")
	check(
		save.write_atomic(path, data), "actual generated current-rule save", save.errors.duplicate()
	)
	var original := FileAccess.get_file_as_string(path)
	var canonical: Dictionary = data.duplicate(true)
	for key in VENDOR_POWERS:
		var actual: Array = data.world.vendors[key].items.map(func(it): return it.level)
		check(actual == VENDOR_POWERS[key], "saved canonical purchased subset " + key, actual)
		for i in VENDOR_POWERS[key].size():
			canonical.world.vendors[key].items[i].level = VENDOR_POWERS[key][i]
	var mission: Dictionary = canonical.world.sites[camp_id].rewards["mission/0"]
	check(
		POWERS.has(int(mission.level)), "mission source in independent literal band", mission.level
	)
	check(
		(
			mission.payload[0].level == POWERS[int(mission.level)]
			and mission.payload[2].level == POWERS[int(mission.level)]
		),
		"delivered historical mission powers",
		mission.payload
	)
	mission.payload[0].level = POWERS[int(mission.level)]
	mission.payload[2].level = POWERS[int(mission.level)]
	var table_site := ""
	var table_key := ""
	for id in canonical.world.sites:
		for key in canonical.world.sites[id].rewards:
			if str(key).begins_with("furnishing/"):
				table_site = id
				table_key = key
				break
		if table_key != "":
			break
	var table: Dictionary = canonical.world.sites[table_site].rewards[table_key]
	table.payload[1].level = POWERS[int(table.level)]
	# Isolate each independently expected replay from all other production-generated fields.
	for kind in ["table", "mission", "vendor"]:
		var positive: Dictionary = data.duplicate(true)
		if kind == "table":
			positive.world.sites[table_site].rewards[table_key] = table.duplicate(true)
		elif kind == "mission":
			positive.world.sites[camp_id].rewards["mission/0"] = mission.duplicate(true)
		else:
			positive.world.vendors = canonical.world.vendors.duplicate(true)
		check(
			save.validate(positive), "canonical " + kind + " FULL replay", save.errors.duplicate()
		)
		raw_write(directory.path_join("canonical-" + kind + ".json"), positive)
		var bad: Dictionary = positive.duplicate(true)
		if kind == "table":
			bad.world.sites[table_site].rewards[table_key].payload[1].level = table.level
		elif kind == "mission":
			bad.world.sites[camp_id].rewards["mission/0"].payload[0].level = mission.level
			bad.world.sites[camp_id].rewards["mission/0"].payload[2].level = mission.level
		else:
			bad.world.vendors["0,0/weapon-vendor"].items[0].level = 11
		rejects_original(save, directory, "old-unit-" + kind, bad)
	# Full saved delivered historical boss receipt, preserving all ordinary prefix rolls.
	var boss: Dictionary = layout.assignments.filter(func(a): return a.boss)[0]
	var kill_key := "kill/0/" + str(boss.key)
	var kill: Dictionary = data.world.sites[camp_id].rewards[kill_key]
	check(
		kill.delivered and kill.payload[-1].level == POWERS[int(kill.level)],
		"real delivered historical boss gear",
		kill.payload[-1]
	)
	var bad_kill: Dictionary = data.duplicate(true)
	bad_kill.world.sites[camp_id].rewards[kill_key].payload[-1].level = kill.level
	rejects_original(save, directory, "old-unit-kill", bad_kill)
	for kind in ["weapon", "consumable", "spirit"]:
		var bad := data.duplicate(true)
		var row := {
			"type": "weapon",
			"subtype": "sword",
			"material": "iron",
			"rarity": 0,
			"level": 101,
			"upgrade_count": 0,
			"modifier": 0,
			"minus_modifier": 0,
			"count": 1
		}
		if kind == "consumable":
			row.type = "consumable"
			row.subtype = "life-potion"
			row.material = ""
		elif kind == "spirit":
			row.type = "ingredient"
			row.subtype = "spirit-fire"
			row.material = ""
		bad.character.bag.append(row)
		rejects_original(save, directory, "invalid-power-" + kind, bad)
	var bad_shape := data.duplicate(true)
	bad_shape.character.bag[0].count = -1
	check(not save.write_atomic(path, bad_shape), "invalid atomic write rejects")
	check(
		FileAccess.get_file_as_string(path) == original,
		"invalid write preserves current-rule original"
	)
	raw_write(
		directory.path_join("source-identity.json"),
		{
			"site": table_site,
			"table": table_key,
			"source": table.level,
			"power": POWERS[int(table.level)],
			"vendors": data.world.vendors,
			"world_id": data.world.world_id,
			"camp": camp_id,
			"mission_source": mission.level
		}
	)
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
			get_script().resource_path,
			"--",
			"--read"
		],
		output,
		true
	)
	var text := "\n".join(output)
	var log := FileAccess.open(directory.path_join("cold-child.log"), FileAccess.WRITE)
	log.store_string("exit=%d\n%s" % [status, text])
	log.close()
	check(
		(
			status == 0
			and "SCRIPT ERROR" not in text
			and "ERROR:" not in text
			and "ontology INVALID" not in text
		),
		"bounded fresh-process load",
		{"exit": status, "output": text}
	)
	print("COLD_WRITE_RESULT failures=", failed)
	quit(0 if failed == 0 else 1)


func cold_read(save, directory: String) -> void:
	var path := directory.path_join("current-rule.json")
	var before := FileAccess.get_file_as_string(path)
	var data: Dictionary = save.load_file(path)
	check(not data.is_empty(), "cold current-rule save accepted", save.errors.duplicate())
	var identity: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(directory.path_join("source-identity.json"))
	)
	if not data.is_empty():
		check(
			(
				data.world.world_id == identity.world_id
				and Save.same_data(data.world.vendors, identity.vendors)
			),
			"cold purchase subset/world identity exact"
		)
		check(
			data.world.sites[identity.site].rewards[identity.table].level == identity.source,
			"cold table source not converted"
		)
		check(
			(
				(
					data.world.sites[identity.camp].rewards["mission/0"].level
					== identity.mission_source
				)
				and data.world.sites[identity.camp].cycle == 1
			),
			"cold historical mission/source survives renewal"
		)
		var restored := State.new(save.design, 26879)
		restored.restore(data.world)
		check(Save.same_data(restored.snapshot(), data.world), "cold state restore/snapshot exact")
	check(FileAccess.get_file_as_string(path) == before, "cold current-rule original protected")
	for name_ in [
		"canonical-table",
		"canonical-mission",
		"canonical-vendor",
		"old-unit-table",
		"old-unit-mission",
		"old-unit-vendor",
		"old-unit-kill",
		"invalid-power-weapon",
		"invalid-power-consumable",
		"invalid-power-spirit"
	]:
		path = directory.path_join(name_ + ".json")
		before = FileAccess.get_file_as_string(path)
		var loaded: Dictionary = save.load_file(path)
		check(
			loaded.is_empty() != name_.begins_with("canonical-"),
			"cold " + name_ + " current-rule decision",
			save.errors.duplicate()
		)
		check(FileAccess.get_file_as_string(path) == before, "cold " + name_ + " original intact")
