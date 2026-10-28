## Directional Cyclone through actual class slots, player contacts, damage and landed bookkeeping.
## Manual runner time isolates scheduling; physics frames register real moving bodies, not fake strikes.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const Spawner := preload("res://game/world/spawner.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")

var o
var design: Dictionary
var p
var holder: Node3D
var wolves: Array = []
var contacts: Array = []
var contact_facings: Array = []
var failures := 0
var preconditions := 0
var checks := 0


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("ASSERTION FAILED [Cyclone]: ", label)


func require(ok: bool, label: String) -> bool:
	if not ok:
		preconditions += 1
		printerr("PRECONDITION FAILED [Cyclone]: ", label)
	return ok


func _init() -> void:
	_run.call_deferred()


func frames() -> void:
	await physics_frame
	await physics_frame


func layout(points: Array) -> void:
	for i in wolves.size():
		wolves[i].position = points[i] if i < points.size() else Vector3(30 + i * 3, 0, 0)
	await frames()


func start(fuel := 100.0, drain := 25.0, yaw := 0.0) -> void:
	p.abilities.reset()
	p.abilities.cooldowns.clear()
	p.abilities.cfg = design.abilities.duplicate(true)
	p.abilities.cfg.cyclone["drain-per-s"] = drain
	p.stamina = fuel
	p.combo = 4
	p._combo_t = 2.0
	p.rig.rotation.y = yaw
	contacts.clear()
	contact_facings.clear()
	for w in wolves:
		w.hp = 1e6
	require(p.use_class_skill(2), "actual armed class-slot activation")
	check(is_equal_approx(p.stamina, fuel - 25.0), "startup costs exactly 25")
	check(
		is_equal_approx(p.abilities.cooldowns[&"cyclone"], 28.5),
		"rank-one cooldown keeps 30s multiplier"
	)


func damage(index: int) -> float:
	return 1e6 - wolves[index].hp


func ordered_contacts() -> void:
	# Clockwise from north: north, east, south, west. Only north may land at activation.
	await layout([Vector3(0, 0, -2), Vector3(2, 0, 0), Vector3(0, 0, 2), Vector3(-2, 0, 0)])
	start()
	check(contacts == [0] and is_equal_approx(damage(0), 21.0), "immediate front-only 21 damage")
	p.abilities.tick(0.249)
	check(contacts == [0], "east waits until quarter turn")
	p.abilities.tick(0.001)
	check(contacts == [0, 1], "east at exactly .25 seconds")
	p.abilities.tick(0.5)
	check(contacts == [0, 1, 2, 3], "coarse half-second orders south then west, not radius order")
	p.abilities.tick(0.25)
	p.abilities.tick(0.0)
	check(contacts == [0, 1, 2, 3, 0], "one seam contact at full revolution, zero update adds none")
	check(
		p.combo == 9 and is_equal_approx(p._combo_t, 5.0),
		"each directional contact gains once without basic rewards"
	)
	check(
		p._m1_hits == 0 and is_zero_approx(p.mp),
		"channel contacts do not grant basic MP or finisher hits"
	)
	# Starting yaw -PI/2 points east; clockwise then reaches south, west, north.
	start(100.0, 25.0, -PI / 2)
	check(contacts == [1], "activation-facing offset points east")
	p.abilities.tick(0.75)
	check(contacts == [1, 2, 3, 0], "offset uses same clockwise contact order")


func same_azimuth_combo() -> void:
	await layout([Vector3(0, 0, -2), Vector3(0, 0, -2.5)])
	start()
	check(
		contacts == [0, 1] and p.combo == 5,
		"same-azimuth targets share one successful class strike, not per-target combo"
	)
	p.abilities.tick(1.0)
	check(
		contacts == [0, 1, 0, 1] and p.combo == 6,
		"next same-azimuth pass gains once and damages both again"
	)


func equal_static_time() -> void:
	await layout([Vector3(0, 0, -2)])
	var fine: Array = []
	fine.resize(15)
	fine.fill(0.1)
	var sixty: Array = []
	sixty.resize(90)
	sixty.fill(1.0 / 60.0)
	for row in [
		["6x.25", [0.25, 0.25, 0.25, 0.25, 0.25, 0.25]],
		["15x.1", fine],
		["90x1/60", sixty],
		["1x1.5", [1.5]]
	]:
		start()
		for dt in row[1]:
			p.abilities.tick(float(dt))
		print(
			"STATIC ",
			p.spec,
			" ",
			row[0],
			" contacts=",
			contacts,
			" damage=",
			damage(0),
			" stamina=",
			p.stamina
		)
		check(
			contacts == [0, 0] and is_equal_approx(damage(0), 42.0),
			str(row[0]) + ": literal two north passes in 1.5s"
		)
		check(
			is_equal_approx(p.stamina, 37.5) and not p.abilities.channel.is_empty(),
			str(row[0]) + ": independent literal fuel/lifetime"
		)


func clipped_boundaries() -> void:
	await layout([Vector3(2, 0, 0), Vector3(0, 0, 2)])
	start()
	p.abilities.channel.left = 0.4  # Isolate the residual lifetime without inventing fuel.
	p.abilities.tick(1.0)
	check(is_equal_approx(p.stamina, 65.0), ".4 seconds left drains 10, not full 25")
	check(
		contacts == [0] and p.abilities.channel.is_empty(),
		"partial duration reaches east but never south"
	)
	var before := contacts.duplicate()
	p.abilities.tick(10.0)
	check(contacts == before and is_equal_approx(p.stamina, 65.0), "no contacts or drain after end")
	# Fuel 6.25 after startup buys precisely a quarter turn, including the final east contact.
	start(31.25)
	p.abilities.tick(1.0)
	check(
		contacts == [0] and p.abilities.channel.is_empty() and is_zero_approx(p.stamina),
		"exact fuel endpoint includes east once"
	)
	p.abilities.tick(1.0)
	check(contacts == [0], "no duplicate exact final contact")
	# Five fuel buys .2 seconds; east at .25 must not land under either partition.
	for parts in [[0.01, 0.30], [0.01, 0.19, 0.11]]:
		start(30.0)
		for dt in parts:
			p.abilities.tick(dt)
		check(
			contacts.is_empty() and p.abilities.channel.is_empty() and is_zero_approx(p.stamina),
			"five fuel stops at .2s, never late east: " + str(parts)
		)
		check(
			body_forward().is_equal_approx(Vector3(0.95105652, 0, -0.30901699)),
			"five fuel stops Body at 72 degrees under either partition"
		)
	# Zero drain is legal: duration still bounds progress, with exact final north seam.
	await layout([Vector3(0, 0, -2)])
	start(25.0, 0.0)
	p.abilities.tick(9.0)
	check(
		contacts == [0, 0, 0, 0, 0, 0] and is_equal_approx(damage(0), 126.0),
		"zero drain reaches five turns and includes exact final seam once"
	)
	check(
		p.abilities.channel.is_empty() and is_zero_approx(p.stamina),
		"zero drain still ends at five seconds"
	)
	p.abilities.tick(1.0)
	check(contacts.size() == 6, "zero-drain final seam not repeated after end")
	# Non-seam exact duration boundary is inclusive, not only full turns.
	await layout([Vector3(-2, 0, 0), Vector3(0, 0, -2)])
	start()
	p.abilities.channel.left = 0.75
	p.abilities.tick(2.0)
	check(
		contacts == [1, 0] and is_equal_approx(p.stamina, 56.25),
		"exact .75 duration reaches west once and never next north"
	)


func moving_contacts() -> void:
	await layout([])
	start(100.0, 0.0)
	p.abilities.tick(0.4)
	await layout([Vector3(2, 0, 0)])
	p.abilities.tick(0.1)
	check(contacts.is_empty(), "entering swept east area waits for next pass")
	p.abilities.tick(0.75)
	check(contacts == [0], "entry lands at next east pass 1.25s")
	await layout([])
	p.abilities.tick(0.1)
	await layout([Vector3(-2, 0, 0)])
	p.abilities.tick(0.4)
	check(contacts == [0], "exit and different-azimuth reentry cannot rehit same revolution")
	p.abilities.tick(1.0)
	check(contacts == [0, 0], "reentered target hits on next revolution")
	# Leaving before a pending pass avoids the hit; return to a swept area still waits.
	await layout([Vector3(0, 0, 2)])
	start(100.0, 0.0)
	p.abilities.tick(0.25)
	await layout([])
	p.abilities.tick(0.25)
	check(contacts.is_empty(), "leaving reach before south pass avoids pending hit")
	await layout([Vector3(0, 0, 2)])
	p.abilities.tick(0.1)
	check(contacts.is_empty(), "entry at old endpoint does not retroactively hit")
	p.abilities.tick(0.9)
	check(contacts == [0], "returned south target waits to 1.5 seconds")
	# Current azimuth, not activation azimuth: move an east target to west before its pass.
	await layout([Vector3(2, 0, 0)])
	start()
	p.abilities.tick(0.1)
	await layout([Vector3(-2, 0, 0)])
	p.abilities.tick(0.15)
	check(contacts.is_empty(), "moving target is not struck at stale east azimuth")
	p.abilities.tick(0.5)
	check(contacts == [0], "moving target struck at current west azimuth")
	# Player motion changes relative azimuth too: north target is now east of player.
	await layout([Vector3(0, 0, -2)])
	start()
	p.position = Vector3(-2, 0, -2)
	await frames()
	p.abilities.tick(0.25)
	check(contacts == [0], "player movement respects one-hit-per-revolution")
	p.abilities.tick(1.0)
	check(contacts == [0, 0], "current relative player position schedules east next revolution")
	p.position = Vector3.ZERO
	await frames()


func body_forward() -> Vector3:
	return -p.get_node("Body").global_transform.basis.z


func facing_and_camera() -> void:
	await layout([Vector3(2, 0, 0), Vector3(0, 0, -2)])
	start()
	var aim_before: Vector3 = p.aim()
	var camera_before: Transform3D = p.rig.get_node("Arm/Camera").global_transform
	p.abilities.channel.left = 0.4
	p.abilities.tick(1.0)
	check(
		body_forward().is_equal_approx(Vector3(0.58778525, 0, 0.80901699)),
		".4s partial duration stops actual Body at 144 degrees clockwise"
	)
	check(
		contact_facings.size() == 2 and contact_facings[1].is_equal_approx(Vector3.RIGHT),
		"actual Body faces east at the east damage callback, before final partial stop"
	)
	check(
		(
			p.aim().is_equal_approx(aim_before)
			and p.rig.get_node("Arm/Camera").global_transform.is_equal_approx(camera_before)
		),
		"spin does not rotate actual camera or normal aim"
	)
	var stopped: Vector3 = body_forward()
	p.abilities.tick(2.0)
	check(
		body_forward().is_equal_approx(stopped), "post-end tick leaves partial Body stop unchanged"
	)
	start(31.25)
	p.abilities.tick(1.0)
	check(
		body_forward().is_equal_approx(Vector3.RIGHT),
		"exact fuel endpoint stops actual Body facing east"
	)
	var north_hp: float = wolves[1].hp
	var east_hp: float = wolves[0].hp
	p._swing()  # Ordinary real weapon attack remains camera-directed north, not stopped-body east.
	check(
		wolves[1].hp < north_hp and is_equal_approx(wolves[0].hp, east_hp),
		"subsequent real basic attack uses unchanged camera direction"
	)
	start(100.0, 25.0, -PI / 2)
	check(
		body_forward().is_equal_approx(Vector3.RIGHT),
		"actual Body begins at activation camera facing"
	)
	p.abilities.channel.left = 0.25
	p.abilities.tick(1.0)
	check(
		body_forward().is_equal_approx(Vector3.BACK),
		"offset exact endpoint stops actual Body south"
	)
	# Look remains live and camera-owned; it cannot retarget the activation-referenced channel.
	start()
	p.rig._yaw = 0.0
	p.rig.apply_touch_look(Vector2(45, 0), 180.0, 180.0)
	p.abilities.channel.left = 0.25
	p.abilities.tick(1.0)
	check(
		(
			body_forward().is_equal_approx(Vector3.RIGHT)
			and is_equal_approx(p.rig.rotation.y, -PI / 4)
		),
		"live look changes camera, not Cyclone reference or exact stop"
	)
	check(
		p._front().x > 0.0 and p._front().z < 0.0, "ordinary front aim still follows changed camera"
	)
	p.rig._yaw = 0.0
	p.rig.rotation.y = 0.0


func dead_target_no_rehit() -> void:
	await layout([])
	wolves[3].position = Vector3(2, 0, 0)
	await frames()
	start()
	wolves[3].hp = 1.0
	p.abilities.tick(2.0)
	check(
		wolves[3].dead and contacts == [3] and p.combo == 5,
		"a target killed on first east pass cannot award another hit/combo in a coarse sweep"
	)
	wolves.pop_back()  # Its real death tween retires the corpse; later fixtures only need targets0/1.
	p.abilities.reset()


func cancellation() -> void:
	await layout([Vector3(2, 0, 0), Vector3(0, 0, 2)])
	start()
	p.abilities.tick(0.1)
	p.abilities.reset()
	p.abilities.tick(2.0)
	check(
		contacts.is_empty() and p.combo == 0,
		"synchronous reset stops remaining contacts and settles wholly missed channel"
	)
	await layout([Vector3(0, 0, -2), Vector3(0, 0, -2.5)])
	wolves[0].damaged.connect(func(_amount, _from): p.abilities.reset(), CONNECT_ONE_SHOT)
	start()
	check(
		contacts == [0] and p.combo == 0 and p.abilities.channel.is_empty(),
		"reentrant activation reset cancels later same-azimuth body and landed bookkeeping"
	)
	p.abilities.tick(1.0)
	check(
		(
			contacts == [0]
			and is_equal_approx(p.stamina, 75.0)
			and body_forward().is_equal_approx(Vector3.FORWARD)
		),
		"activation cancellation never drains or rotates past initial contact"
	)
	await layout([Vector3(2, 0, 0), Vector3(0, 0, 2)])
	for mode in ["reset", "death"]:
		start()
		var cancel := func(_amount, _from):
			if mode == "reset":
				p.abilities.reset()
			else:
				p.take_damage(1e9, p)
		wolves[0].damaged.connect(cancel, CONNECT_ONE_SHOT)
		p.abilities.tick(1.0)
		check(
			contacts == [0] and p.abilities.channel.is_empty(),
			"reentrant " + mode + " stops within coarse sweep"
		)
		check(p.combo == 0, "reentrant " + mode + " cannot resurrect combo after reset")
		check(
			is_equal_approx(p.stamina, 68.75), "reentrant " + mode + " stops drain at .25 contact"
		)
		check(
			body_forward().is_equal_approx(Vector3.RIGHT),
			"reentrant " + mode + " stops Body at actual quarter-turn contact"
		)
		p.abilities.tick(1.0)
		check(
			contacts == [0] and body_forward().is_equal_approx(Vector3.RIGHT),
			"reentrant " + mode + " cannot restart old channel or rotate Body"
		)
		if mode == "death":
			check(p.dead, "actual lethal damage synchronously cancels runner")


func _run() -> void:
	var scratch := OS.get_environment("PIXLND_TEST_DIR")
	if not require(
		scratch.is_absolute_path() and DirAccess.dir_exists_absolute(scratch),
		"existing isolated absolute PIXLND_TEST_DIR"
	):
		quit(2)
		return
	o = Model.Ontology.load_dir("res://ontology/instances")
	if not require(o.validate(), "canonical ontology valid: " + str(o.errors)):
		quit(2)
		return
	design = o.configs.generators.design
	InputMapBuilder.build(o.configs.keybinds.hybrid)
	for spec in [&"berserker", &"guardian"]:
		p = PLAYER.instantiate()
		root.add_child(p)
		p.setup(design.movement, design.camera, &"normal")
		p.setup_combat(design.combat, design.crit, {}, 260.0)
		p.setup_items(o, design, &"warrior", spec)
		p.skill_tree.points = {&"cyclone": 1}
		p.weapon.damage = 40.0
		p.crit_chance = 0.0
		p.mp = 0.0
		p.set_physics_process(false)
		holder = Node3D.new()
		root.add_child(holder)
		wolves = Spawner.populate(
			holder,
			[
				{
					"species": &"wolf",
					"level": 1,
					"hostility": &"N",
					"max_hp": 1e6,
					"damage": 0.0,
					"positions":
					[Vector3(0, 0, -2), Vector3(2, 0, 0), Vector3(0, 0, 2), Vector3(-2, 0, 0)],
					"seed": 1
				}
			],
			design,
			o.creatures,
			p,
			null
		)
		for i in wolves.size():
			wolves[i].set_physics_process(false)
			wolves[i].armor = 0.0
			wolves[i].resistance = 0.0
			wolves[i].damaged.connect(
				func(_amount, _from):
					contacts.append(i)
					contact_facings.append(body_forward())
			)
		await frames()
		if not require(
			not p.weapon.is_empty() and not p.dead and p.bodies_within(Vector3.UP, 3.0).size() == 4,
			str(spec) + ": real armed player and four physical contacts"
		):
			quit(2)
			return
		await ordered_contacts()
		await same_azimuth_combo()
		await equal_static_time()
		await clipped_boundaries()
		await moving_contacts()
		await facing_and_camera()
		await dead_target_no_rehit()
		await cancellation()
		p.free()
		holder.free()
	print(
		"Cyclone SUMMARY checks=%d failures=%d preconditions=%d" % [checks, failures, preconditions]
	)
	quit(2 if preconditions > 0 else (1 if failures > 0 else 0))
