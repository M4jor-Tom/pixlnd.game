## Real main/world/streaming lifecycle, isolated from user:// and driven without offline/wall time.
extends SceneTree
const MeshData := preload("res://game/world/zone_mesh.gd")
const MAIN := preload("res://game/main.tscn")
const DB := preload("res://game/ontology_db.gd")
const Spawner := preload("res://game/world/spawner.gd")
const Items := preload("res://game/items/items.gd")
const Save := preload("res://game/world/save_data.gd")
var path := ""
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func stop_nodes(main) -> void:
	main.get_node("Player").set_physics_process(false)
	main.get_node("World").set_process(false)
	main.get_node("World").set_physics_process(false)
	main.get_node("World").targeting.set_physics_process(false)


func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		printerr("PIXLND_TEST_DIR must name an isolated absolute scratch directory")
		quit(1)
		return
	path = directory.path_join("test-saved-runtime.json")
	if not root.has_node("OntologyDB"):
		var db := DB.new()
		db.name = "OntologyDB"
		root.add_child(db)
	DirAccess.remove_absolute(path)
	var main = MAIN.instantiate()
	main.save_path = path
	root.add_child(main)
	stop_nodes(main)
	var p = main.get_node("Player")
	var w = main.get_node("World")
	p.gain_xp(60)
	p.spend_skill(p.skill_tree.class_slot(1))
	p.inventory.coins = 777
	p.position += Vector3(3, 0, 0)
	p.spawn_point = p.position + Vector3(2, 0, 0)
	# Actual seeded ambient generation/instantiation, no fake encounter mechanic.
	var zone := Vector2i.ZERO
	var found := false
	for x in range(125, 136):
		for y in range(125, 136):
			var plan_: Array = Spawner.plan(
				w.gen, Vector2i(x, y), w.design, w.creatures, w.rosters, p.level
			)
			if (
				not plan_.is_empty()
				and plan_.reduce(func(n, g): return n + g.positions.size(), 0) >= 2
			):
				zone = Vector2i(x, y)
				found = true
				break
		if found:
			break
	check(found, "seed has ambient zone")
	w._publish_zone(zone, MeshData.data(w.gen, zone))
	var mobs: Array = w.targeting.live.values()
	for mob in mobs:
		mob.set_physics_process(false)
	var survivor = mobs[0]
	var id: String = survivor.logical_id
	check(
		survivor.hostility in [&"H", &"N"],
		"generated combat-capable survivor, no forced hostility fixture"
	)
	survivor.take_damage(1, p)
	var threat: float = w.targeting.record(survivor).threat[p.logical_id]
	var lvl: int = survivor.level
	var home: Vector3 = survivor.home
	var role: StringName = survivor.role
	var identity: String = main.state_data.world_id
	w.capture_mobs()
	# Node unload does not erase logical pairs, and timers continue while unloaded.
	w.zones[zone].free()
	w.zones.erase(zone)
	check(not w.targeting.live.has(id), "unloaded node detached")
	w.targeting.advance(0.001)
	check(main.state_data.mobs[id].combat.threat[p.logical_id] < threat, "unloaded threat decay")
	w._publish_zone(zone, MeshData.data(w.gen, zone))
	survivor = w.targeting.live[id]
	survivor.set_physics_process(false)
	check(
		survivor.level == lvl and survivor.home == home and survivor.role == role,
		"unload retains incarnation assignments"
	)
	var death = null
	for mob in w.targeting.live.values():
		mob.set_physics_process(false)
		if mob != survivor:
			death = mob
			break
	check(death != null, "fixture includes genuine dead and surviving members")
	var death_id := ""
	if death != null:
		death_id = death.logical_id
		death.take_damage(1e9, p)
		check(main.state_data.mobs[death_id].dead, "genuine death saved before unload")
	check(main.save_now(), "normal runtime atomic save: " + str(main.save_data.errors))
	var saved := Save.new(root.get_node("OntologyDB").data, w.design).load_file(path)
	var clock: float = main.state_data.clock
	var expected_xp: int = p.xp
	var expected_level: int = p.level
	var expected_position: Vector3 = p.position
	main.free()
	var second = MAIN.instantiate()
	second.save_path = path
	root.add_child(second)
	stop_nodes(second)
	var q = second.get_node("Player")
	var world = second.get_node("World")
	check(
		second.state_data.world_id == identity and second.state_data.clock == clock,
		"restart identity/clock; no offline advance"
	)
	check(
		(
			q.inventory.coins == 777
			and q.xp == expected_xp
			and q.level == expected_level
			and q.skill_tree.spent(&"smash") == 1
		),
		"real main restores progression not starter overwrites"
	)
	check(
		q.position == expected_position and q.spawn_point != q.position,
		"real main restores position and respawn"
	)
	world._publish_zone(zone, MeshData.data(world.gen, zone))
	check(
		world.targeting.live.has(id) and world.targeting.live[id].level == lvl,
		"restart materializes saved survivor"
	)
	check(
		not world.targeting.record(world.targeting.live[id]).threat.is_empty(),
		"restart preserves survivor threat"
	)
	if death_id != "":
		check(
			not world.targeting.live.has(death_id),
			"unload/restart not a new death, no reward reroll"
		)
	# Next ordinary midnight permits only dead members to renew, using current connected party levels.
	q.level = 20
	second.state_data.clock = 86400 - 1
	world._physics_process(0.1 * Engine.time_scale)
	world.populate_zone(zone)
	check(world.targeting.live[id].level == lvl, "midnight never rescales surviving incarnation")
	if death_id != "":
		check(
			world.targeting.live.has(death_id) and world.targeting.live[death_id].level >= 17,
			"new incarnation follows current party band"
		)
		check(
			world.targeting.record(world.targeting.live[death_id]).threat.is_empty(),
			"genuine regeneration fresh pair state"
		)
		# A retired corpse may leave after the new incarnation exists; it cannot detach/overwrite the new body.
		var renewed = world.targeting.live[death_id]
		var level_now: int = renewed.level
		check(renewed.hp == renewed.max_hp and level_now >= 17, "new incarnation starts at full HP")
	var clock_before: float = second.state_data.clock
	var scale := Engine.time_scale
	Engine.time_scale = 0.5
	world._physics_process(0.05)
	Engine.time_scale = scale
	check(
		is_equal_approx(second.state_data.clock - clock_before, 1.0),
		"10x real running clock unaffected by presentation time scale"
	)
	# Return fixture to valid progression before graceful shutdown validation.
	q.level = expected_level
	for mob in world.targeting.live.values():
		mob.set_physics_process(false)
	check(second.save_now(), "renewed generation validated saved state")
	q.inventory.unequip(&"main-hand")
	check(second.save_now(), "normal main saves legal empty equipment")
	second.free()
	var third = MAIN.instantiate()
	third.save_path = path
	root.add_child(third)
	stop_nodes(third)
	var bare = third.get_node("Player")
	check(
		(
			bare.weapon.is_empty()
			and bare.moveset.is_empty()
			and not bare.inventory.equipment.has(&"main-hand")
		),
		"actual main/HUD boot restores unarmed without starter leakage"
	)
	third.get_node("HUD")._process(0)
	var current = third
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	for subtype in [&"shield", &"axe"]:
		var hero = current.get_node("Player")
		var sword = hero.inventory.equipment.get(&"main-hand")
		if sword == null:
			sword = hero.inventory.entries.filter(func(it): return it.subtype == &"sword")[0]
			check(hero.inventory.equip(sword), "lifecycle equip main before pair")
		var off = Items.generate(rng, &"weapon", subtype, &"iron", 3, 1)
		hero.inventory.add(off)
		check(hero.inventory.equip(off), "lifecycle equip legal off-hand " + str(subtype))
		hero.inventory.unequip(&"main-hand")
		check(
			(
				hero.inventory.equipment[&"off-hand"] == off
				and hero.inventory.entries.count(sword) == 1
			),
			"lifecycle removal leaves off-hand untouched"
		)
		var stats := [hero.max_hp, hero.armor, hero.resistance]
		var payload := Save.item_data(off)
		# Exercise the real changed -> request_save -> deferred atomic commit path, not only save_now().
		await process_frame
		await process_frame
		var persisted: Dictionary = current.save_data.load_file(path)
		check(
			not persisted.is_empty() and persisted.character.equipment.keys() == ["off-hand"],
			"lifecycle autosave accepts independently empty main " + str(subtype)
		)
		current.free()
		current = MAIN.instantiate()
		current.save_path = path
		root.add_child(current)
		stop_nodes(current)
		hero = current.get_node("Player")
		check(
			hero.logical_id == persisted.character.id and current.state_data.world_id == identity,
			"off-hand lifecycle preserves character/world identity"
		)
		var restored_off = hero.inventory.equipment[&"off-hand"]
		check(
			(
				Save.item_data(restored_off) == payload
				and [hero.max_hp, hero.armor, hero.resistance] == stats
			),
			"off-hand payload and worn stats survive real restart"
		)
		check(
			(
				hero.weapon.is_empty()
				and hero.moveset.is_empty()
				and hero.can_block() == (subtype == &"shield")
			),
			"real main restores only eligible off-hand block, no attacks"
		)
		hero.mp = 80
		hero.combo = 4
		hero._swing()
		hero._special(50)
		check(
			not hero.use_class_skill(1) and hero.mp == 80 and hero.combo == 4,
			"main-less action paths reject without spending"
		)
		current.get_node("HUD")._process(0)
		sword = hero.inventory.entries.filter(func(it): return it.subtype == &"sword")[0]
		check(
			(
				hero.inventory.equip(sword)
				and hero.inventory.equipment[&"off-hand"] == restored_off
				and not hero.weapon.is_empty()
			),
			"real restart equip transition preserves off-hand"
		)
		hero.inventory.unequip(&"off-hand")
		check(
			hero.inventory.equipment[&"main-hand"] == sword,
			"reverse lifecycle unequip leaves main untouched"
		)
		await process_frame
	current.free()
	check(not saved.is_empty(), "saved snapshot independently loadable")
	print("saved runtime ok" if failed == 0 else "saved runtime FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
