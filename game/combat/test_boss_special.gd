extends SceneTree
const PLAYER := preload("res://game/entities/player.tscn")
const MAIN := preload("res://game/main.tscn")
const Lifecycle := preload("res://game/combat/boss_special_lifecycle_cases.gd")
const DB := preload("res://game/ontology_db.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func stop(main) -> void:
	main.set_physics_process(false)
	main.get_node("Player").set_physics_process(false)
	var w = main.get_node("World")
	w.set_process(false)
	w.set_physics_process(false)
	w.targeting.set_physics_process(false)
	for mob in w.targeting.live.values():
		mob.set_physics_process(false)


func arm(boss, p, layout: Dictionary, kind: String, distance: float = 3.0) -> void:
	boss.clear_stars()
	boss.statuses.clear()
	boss.velocity = Vector3.ZERO
	boss._stun_push = Vector3.ZERO
	boss.set_logical_position([layout.centre[0], layout.floor, layout.centre[1]])
	p.set_logical_position([layout.centre[0] + distance, layout.floor, layout.centre[1]])
	p._iframes = 0
	p.blocking = false
	p.statuses.clear()
	p.armor = 0
	p.resistance = 10000
	boss.target = p
	boss.state = boss.State.CHASE
	boss.targeting.record(boss).returning = false
	boss.special.kind = kind
	boss.special.cancel()
	boss.incarnation.special.phase = "cooldown"
	boss.incarnation.special.left = 0
	boss.incarnation.special.recovery = 0


func wall(parent, position_: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.02, 5, 4)
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
	body.global_position = position_ + Vector3.UP * 2.5
	return body


func interrupted_motion(boss, p, layout: Dictionary, design: Dictionary) -> void:
	for phase in ["stomp-warning", "charge-warning", "charge"]:
		for stun_first in [true, false]:
			for obstructed in [false, true]:
				await _interrupted_case(boss, p, layout, design, phase, stun_first, obstructed)


func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		printerr("PIXLND_TEST_DIR required")
		quit(1)
		return
	if not root.has_node("OntologyDB"):
		var db := DB.new()
		db.name = "OntologyDB"
		root.add_child(db)
	var main = MAIN.instantiate()
	main.save_path = directory.path_join("boss.json")
	DirAccess.remove_absolute(main.save_path)
	root.add_child(main)
	await _run_main_cases(main)


func _run_main_cases(main) -> void:
	stop(main)
	var w = main.get_node("World")
	var p = main.get_node("Player")
	var boss
	var id = _camp_id(w)
	var layout: Dictionary = w.site_layout(id)
	main.relocate_player([layout.centre[0], layout.floor, layout.centre[1]])
	w.stream_sites()
	stop(main)
	boss = _bound_boss(w, id)
	check(boss != null, "actual main binds boss special")
	if boss != null:
		# Fixed attack input: literal 40 stomp / 50 charge, independent of defence code.
		var generated_damage: float = boss.damage
		boss.damage = 40
		await _stomp_timing(boss, p, w, layout)
		await _charge_and_interrupt(boss, p, w, layout)
		await interrupted_motion(boss, p, layout, w.design)
		await _rubble_and_defence(boss, p, w, layout, id)
		await _walls(boss, p, w, layout)
		await _two_players(boss, p, w, layout, main)
		_admission_and_cancel(boss, p, w, layout)
		boss.damage = generated_damage
		main = await Lifecycle.run(self, boss, p, w, layout, main, id)
	await Lifecycle.release(self, main)
	print("boss special ok" if failed == 0 else "boss special FAILED " + str(failed))
	quit(0 if failed == 0 else 1)


func _stomp_timing(boss, p, w, layout) -> void:
	_isolate_boss(w, boss)
	boss.set_logical_position([layout.centre[0], layout.floor, layout.centre[1]])
	p.set_logical_position([layout.centre[0] + 3, layout.floor, layout.centre[1]])
	p.hp = 10000
	p.max_hp = 10000
	p.armor = 0
	p.resistance = 10000
	boss.target = null
	boss.special.advance(20)
	check(boss.incarnation.special.left == 3, "readiness waits for engagement")
	boss.target = p
	boss.role = &"mage"
	boss.special.kind = "stomp"
	await physics_frame
	await physics_frame
	var hp: float = p.hp
	check(not boss.special.advance(2.99), "initial three seconds only after engagement")
	check(
		boss.special.advance(0.01) and boss.incarnation.special.phase == "warning",
		"readiness enters visible warning"
	)
	check(p.hp == hp, "warning does not damage")
	check(
		boss.special.warning != null and boss.special.warning.mesh.top_radius == 4,
		"stomp warning is a real four radius circle"
	)
	boss.special.advance(1.19)
	check(p.hp == hp, "warning lasts 1.2 seconds")
	boss.special.advance(0.01)
	check(is_equal_approx(hp - p.hp, 40), "mage stomp is one physical boss hit")
	check(
		(
			boss.incarnation.special.phase == "cooldown"
			and is_equal_approx(boss.incarnation.special.left, 10)
		),
		"completion starts ten second cooldown"
	)
	check(boss.special.advance(0.79), "recovery suppresses basic attacks")
	check(not boss.special.advance(0.02), "basic attacks resume during remaining cooldown")


func _charge_and_interrupt(boss, p, w, layout) -> void:
	boss.special.kind = "charge"
	boss.incarnation.special.left = 0
	boss.incarnation.special.recovery = 0
	p.set_logical_position([layout.centre[0] + 8, layout.floor, layout.centre[1]])
	boss.target = p
	boss.special.advance(0)
	var endpoint: Array = boss.incarnation.special.endpoint.duplicate()
	p.set_logical_position([layout.centre[0] + 8, layout.floor, layout.centre[1] + 5])
	boss.special.advance(1.2)
	check(boss.incarnation.special.endpoint == endpoint, "charge snapshots direction and endpoint")
	boss.special.advance(0.25)
	check(
		is_equal_approx(boss.logical_position()[0] - layout.centre[0], 3),
		"charge travels three blocks in quarter second"
	)
	boss.special.advance(0.75)
	check(boss.incarnation.special.phase == "cooldown", "charge ends at endpoint")
	check(absf(boss.logical_position()[2] - layout.centre[1]) < 0.01, "charge never homes")
	boss.incarnation.special.left = 0
	boss.incarnation.special.recovery = 0
	boss.set_logical_position([layout.centre[0], layout.floor, layout.centre[1]])
	p.set_logical_position([layout.centre[0] + 8, layout.floor, layout.centre[1]])
	boss.target = p
	boss.special.advance(0)
	boss.special.advance(1.2)
	await physics_frame
	await physics_frame
	var hp: float = p.hp
	boss.special.advance(1)
	check(
		is_equal_approx(hp - p.hp, 50) and boss.logical_position()[0] < layout.centre[0] + 8,
		"swept capsule hits first player on coarse tick"
	)
	boss.incarnation.special.left = 0
	boss.incarnation.special.recovery = 0
	boss.set_logical_position([layout.centre[0], layout.floor, layout.centre[1]])
	boss.target = p
	boss.special.kind = "stomp"
	p.set_logical_position([layout.centre[0] + 3, layout.floor, layout.centre[1]])
	boss.special.advance(0)
	boss.apply_status(&"knockback", w.design["status-effects"]["knockback"], 1, p)
	check(boss.incarnation.special.phase == "cooldown", "instantaneous knockback cancels")
	arm(boss, p, layout, "stomp")
	boss.special.advance(0)
	boss.apply_status(&"stun", w.design["status-effects"]["stun"], 1, p)
	boss.special.advance(1)
	check(
		is_equal_approx(boss.incarnation.special.left, 9),
		"cooldown continues during active-simulation stun"
	)


func _rubble_and_defence(boss, p, w, layout, id) -> void:
	arm(boss, p, layout, "charge", 8)
	var contents = boss.special.contents
	var rubble_key: String = contents.rubble.keys()[0]
	var at: Array = contents.plan.rubble[rubble_key]
	boss.set_logical_position([at[0] - 3, at[1], at[2]])
	p.set_logical_position([at[0] + 5, at[1], at[2]])
	boss.special.advance(0)
	boss.special.advance(1.2)
	await physics_frame
	await physics_frame
	var hp: float = p.hp
	var drops := get_nodes_in_group("ground-items").size()
	boss.special.advance(1)
	check(
		w.state_data.sites[id].contents.rubble[rubble_key].broken and p.hp < hp,
		"charge shatters real crossed rubble and continues into player"
	)
	check(get_nodes_in_group("ground-items").size() == drops, "rubble yields no resource drops")
	arm(boss, p, layout, "stomp")
	p.armor = 10
	hp = p.hp
	boss.special.hit_player(p, 1)
	check(is_equal_approx(hp - p.hp, 30), "physical armor subtracts ten; Resistance ignored")
	p.armor = 10000
	hp = p.hp
	boss.special.hit_player(p, 1)
	check(is_equal_approx(hp - p.hp, 4), "physical armor floor is ten percent")
	arm(boss, p, layout, "stomp")
	p._iframes = 1
	hp = p.hp
	boss.special.hit_player(p, 1)
	check(p.hp == hp, "special preserves normal dodge")
	p._iframes = 0
	p.spec = &"guardian"
	p.blocking = true
	p.block_power = p.block_max()
	p.mp = 0
	p.rig.rotation.y = PI / 2
	hp = p.hp
	var power: float = p.block_power
	boss.special.hit_player(p, 1)
	check(
		is_equal_approx(hp - p.hp, 8) and p.block_power < power and p.mp == 8,
		"normal special block mitigation/resources retained"
	)
	arm(boss, p, layout, "stomp")
	p.set_logical_position([layout.centre[0] + 4, layout.floor + 1, layout.centre[1]])
	hp = p.hp
	boss.special.advance(0)
	boss.special.advance(1.2)
	check(p.hp < hp, "closed stomp radius/height boundary hits")
	arm(boss, p, layout, "stomp")
	boss.special.advance(0)
	p.set_logical_position([layout.centre[0] + 3, layout.floor + 1.01, layout.centre[1]])
	hp = p.hp
	boss.special.advance(1.2)
	check(p.hp == hp, "jump above one avoids stomp")
	arm(boss, p, layout, "stomp")
	boss.special.advance(0)
	p.set_logical_position([layout.centre[0] + 3, layout.floor - 0.01, layout.centre[1]])
	hp = p.hp
	boss.special.advance(1.2)
	check(p.hp == hp, "feet below floor avoid stomp")


func _walls(boss, p, w, layout) -> void:
	arm(boss, p, layout, "charge", 8)
	boss.special.advance(0)
	boss.special.advance(1.2)
	var obstacle := wall(w, boss.global_position + Vector3(4, 0, 0))
	await physics_frame
	await physics_frame
	var hp: float = p.hp
	boss.special.advance(1)
	check(
		p.hp == hp and boss.logical_position()[0] < layout.centre[0] + 4,
		"swept capsule stops at thin wall on coarse dt"
	)
	obstacle.free()
	arm(boss, p, layout, "stomp")
	boss.special.advance(0)
	obstacle = wall(w, boss.global_position + Vector3(1.5, 0, 0))
	await physics_frame
	await physics_frame
	hp = p.hp
	boss.special.advance(1.2)
	check(
		p.hp == hp and boss.incarnation.special.phase == "cooldown",
		"windup sight loss cancels through physical wall"
	)
	obstacle.free()


func _two_players(boss, p, w, layout, main) -> void:
	arm(boss, p, layout, "charge", 8)
	var other = PLAYER.instantiate()
	root.add_child(other)
	other.setup(w.design.movement, w.design.camera, &"normal")
	other.setup_combat(w.design.combat, w.design.crit, {}, 268)
	other.setup_items(w.ontology, w.design, &"warrior")
	other.frame = w.frame
	other.logical_id = "near-special-victim"
	other.set_physics_process(false)
	other.armor = 0
	other.set_logical_position([layout.centre[0] + 5, layout.floor, layout.centre[1] + 5])
	w.targeting.players = func(): return [p, other]
	await physics_frame
	await physics_frame
	var hp: float = p.hp
	var other_hp: float = other.hp
	boss.special.advance(0)
	boss.special.advance(1.2)
	other.set_logical_position([layout.centre[0] + 5, layout.floor, layout.centre[1]])
	await physics_frame
	await physics_frame
	boss.special.advance(1)
	check(
		p.hp == hp and other.hp < other_hp and boss.logical_position()[0] < layout.centre[0] + 5,
		"swept charge stops at first of two players, not selected far target"
	)
	arm(boss, p, layout, "stomp")
	other.set_logical_position([layout.centre[0], layout.floor, layout.centre[1] + 3])
	w.targeting.taunt([other])
	w.targeting.flush_taunts()
	boss._select_target()
	boss.special.advance(0)
	check(
		boss.incarnation.special.target == other.logical_id,
		"boss special consumes canonical taunt-selected current target"
	)
	boss.special.cancel()
	w.targeting.record(boss).taunt = ""
	w.targeting.record(boss).taunt_left = 0
	other.free()
	w.targeting.players = main.connected_party


func _admission_and_cancel(boss, p, w, layout) -> void:
	arm(boss, p, layout, "stomp")
	for point in [[4, 2, true], [4.001, 0, false], [3, 2.001, false]]:
		p.set_logical_position(
			[layout.centre[0] + point[0], layout.floor + point[1], layout.centre[1]]
		)
		check(
			boss.special.can_start(p) == point[2],
			"stomp start distance/height boundary " + str(point)
		)
	boss.special.kind = "charge"
	for point in [
		[4, 0, false], [4.001, 1, true], [10, 1, true], [10.001, 0, false], [8, 1.001, false]
	]:
		p.set_logical_position(
			[layout.centre[0] + point[0], layout.floor + point[1], layout.centre[1]]
		)
		check(
			boss.special.can_start(p) == point[2],
			"charge start distance/height boundary " + str(point)
		)
	arm(boss, p, layout, "stomp")
	boss.special.advance(0)
	p.dead = true
	boss.special.advance(0)
	check(
		boss.incarnation.special.phase == "cooldown", "invalid/dead target cancels active special"
	)
	p.dead = false
	arm(boss, p, layout, "stomp")
	boss.special.advance(0)
	w.targeting.start_return(boss)
	boss.special.advance(0)
	check(
		boss.incarnation.special.phase == "cooldown", "protected home return cancels active special"
	)


func _interrupted_case(boss, p, layout, design, phase, stun_first, obstructed) -> void:
	var label: String = phase + "/" + str(stun_first) + "/wall=" + str(obstructed)
	arm(
		boss,
		p,
		layout,
		"stomp" if phase == "stomp-warning" else "charge",
		3 if phase == "stomp-warning" else 8
	)
	await physics_frame
	await physics_frame
	boss.special.advance(0)
	if phase == "charge":
		boss.special.advance(1.2)
		boss.special.advance(0.02)
	check(
		boss.incarnation.special.phase == ("charge" if phase == "charge" else "warning"),
		"active special precondition " + label
	)
	var obstacle: StaticBody3D
	if obstructed:
		obstacle = wall(boss.get_parent(), boss.global_position + Vector3(-3, 0, 0))
		await physics_frame
		await physics_frame
	_apply_interrupt(boss, p, design, stun_first, label)
	await _carried_interrupt(boss, obstructed, label)
	if obstructed:
		await _interrupted_wall(boss, obstacle, label)
	boss.set_physics_process(false)


func _camp_id(w) -> String:
	var count := 0
	for id in w.state_data.sites:
		var layout: Dictionary = w.site_layout(id)
		for stable in layout.assignments:
			if stable.boss:
				count += 1
				check(
					w.state_data.sites[id].mobs[id + "/" + stable.key].has("special"),
					"every permanent boss owns special FSM"
				)
	check(count == 7, "seven bosses")
	var id := ""
	for key in w.state_data.sites:
		if w.state_data.sites[key].family == "camp":
			id = key
	return id


func _bound_boss(w, id):
	var boss
	for mob in w.targeting.live.values():
		if (
			mob.has_meta("encounter_site")
			and mob.get_meta("encounter_site") == id
			and mob.get("special") != null
		):
			boss = mob
	return boss


func _isolate_boss(w, boss) -> void:
	for mob in w.targeting.live.values():
		if mob != boss:
			mob.collision_layer = 0


func _apply_interrupt(boss, p, design, stun_first, label) -> void:
	var before_y: float = boss.velocity.y
	for status in [&"stun", &"knockback"] if stun_first else [&"knockback", &"stun"]:
		boss.apply_status(status, design["status-effects"][status], 0, p)
	check(
		(
			boss.incarnation.special.phase == "cooldown"
			and boss.incarnation.special.left == 10
			and boss.incarnation.special.recovery == 0.8
		),
		"interruption starts cooldown/recovery " + label
	)
	check(
		is_equal_approx(boss.velocity.x, -8) and is_equal_approx(boss.velocity.y - before_y, 2),
		"cancellation preserves actual base impulse " + label
	)


func _interrupted_wall(boss, obstacle, label) -> void:
	for i in 30:
		await physics_frame
		await process_frame
	check(boss.is_on_wall() and absf(boss.velocity.x) < 0.01, "boss push blocked by wall " + label)
	var at: Vector3 = boss.global_position
	obstacle.free()
	for i in 6:
		await physics_frame
		await process_frame
	check(
		absf(boss.global_position.x - at.x) < 0.01,
		"boss never reinjects consumed wall impulse " + label
	)


func _carried_interrupt(boss, obstructed, label) -> void:
	var at: Vector3 = boss.global_position
	boss.set_physics_process(true)
	for i in 6:
		await physics_frame
		await process_frame
	check(
		boss.global_position.x < at.x - 0.1,
		"cancelled special still carries external push " + label
	)
	if not obstructed:
		check(
			is_equal_approx(boss.velocity.x, -8) and is_zero_approx(boss.velocity.z),
			"callbacks carry exactly one horizontal impulse " + label
		)
	check(
		boss.incarnation.special.left < 10 and boss.incarnation.special.recovery < 0.8,
		"cancelled special clocks continue during stun " + label
	)
