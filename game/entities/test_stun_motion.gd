extends SceneTree
const Model := preload("res://ontology/model.gd")
const CREATURE := preload("res://game/entities/creature.tscn")
const Entity := preload("res://game/entities/entity.gd")
var failed := 0
var design: Dictionary
var target
var source


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame


func box(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	body.position = at
	root.add_child(body)
	return body


func wolf(mode: int):
	var w = CREATURE.instantiate()
	root.add_child(w)
	w.setup(
		&"wolf",
		1,
		200,
		12,
		&"H",
		design.spawns.ai,
		design.combat["enemy-attack"],
		1.0,
		Color.WHITE,
		1
	)
	w.design = design
	w.target = target
	w.home = Vector3(50, 0, 0) if mode == w.State.RETURN else Vector3.ZERO
	w.state = mode
	if mode == w.State.WANDER:
		w.hostility = &"P"
		w._goal = [20.0, 0.0, 0.0]
	await frames(6)
	check(w.is_on_floor() and w.velocity.x > 1, "moving grounded precondition " + str(mode))
	return w


func pure_stun(mode: int) -> void:
	var w = await wolf(mode)
	w.apply_status(&"stun", design["status-effects"].stun, 0, source)
	var at: Vector3 = w.position
	var cooldown: float = w._cooldown
	await frames(30)
	check(w.stunned(), "pure stun still active " + str(mode))
	check(
		absf(w.position.x - at.x) < 0.01 and absf(w.position.z - at.z) < 0.01,
		"pure stun removes AI motion " + str(mode)
	)
	check(
		w._cooldown < cooldown and w.is_on_floor(), "stun retains clocks and gravity " + str(mode)
	)
	if mode == w.State.RETURN:
		var hp: float = w.hp
		w.take_damage(10, source)
		check(is_equal_approx(hp - w.hp, 1), "stunned return retains damage reduction")
	for i in 150:
		if not w.stunned():
			break
		await frames(1)
	await frames(2)
	check(not w.stunned() and w.velocity.x > 1, "ordinary AI resumes on expiry " + str(mode))
	w.free()


func mixed_status(stun_first: bool, obstruction: String) -> void:
	var w = await wolf(2)  # CHASE: AI intent is +X, real push is -X (and +Z for sliding).
	var label := str(stun_first) + "/" + obstruction
	var obstacle: StaticBody3D
	if obstruction != "open":
		obstacle = box(w.position + Vector3(-1, 2.5, 0), Vector3(0.2, 5, 30))
		await frames(2)
	source.position = w.position + Vector3(4, 0, -4 if obstruction == "slide" else 0)
	var before_y: float = w.velocity.y
	for id in [&"stun", &"knockback"] if stun_first else [&"knockback", &"stun"]:
		w.apply_status(id, design["status-effects"][id], 0, source)
	check(
		is_equal_approx(w.velocity.y - before_y, 2), "base vertical impulse exactly once " + label
	)
	var at: Vector3 = w.position
	await frames(6)
	check(w.position.x < at.x - 0.1, "legitimate push opposes previous AI " + label)
	if obstruction == "open":
		check(
			is_equal_approx(w.velocity.x, -8), "only external horizontal impulse carried " + label
		)
	else:
		var touched_wall: bool = w.is_on_wall()
		for i in 24:
			await frames(1)
			touched_wall = touched_wall or w.is_on_wall()
		check(
			touched_wall and absf(w.velocity.x) < 0.01, "wall consumes blocked component " + label
		)
		var stopped: Vector3 = w.position
		obstacle.free()
		await frames(12)
		check(
			absf(w.position.x - stopped.x) < 0.01,
			"no reinjected push or reverse AI after wall removal " + label
		)
		if obstruction == "slide":
			check(w.position.z > stopped.z + 0.1, "unblocked slide component survives " + label)
		else:
			check(
				absf(w.position.z - stopped.z) < 0.01, "head-on wall has no sideways drift " + label
			)
	# Ordinary ownership must retire old impulse, not revive it on a later pure stun.
	for i in 150:
		if not w.stunned():
			break
		await frames(1)
	await frames(3)
	check(not w.stunned() and w.velocity.x > 1, "post-push chase resumes " + label)
	w.apply_status(&"stun", design["status-effects"].stun, 0, source)
	at = w.position
	await frames(6)
	check(
		absf(w.position.x - at.x) < 0.01 and absf(w.position.z - at.z) < 0.01,
		"later pure stun has no stale impulse " + label
	)
	w.free()


func inactive_and_dead() -> void:
	var w = await wolf(2)
	source.position = w.position + Vector3(4, 0, 0)
	w.apply_status(&"stun", design["status-effects"].stun, 0, source)
	w.apply_status(&"knockback", design["status-effects"].knockback, 0, source)
	target.position.x = 200
	var at: Vector3 = w.position
	var left: float = w.statuses[&"stun"].left
	var velocity: Vector3 = w.velocity
	await frames(12)
	check(
		w.position == at and w.velocity == velocity and w.statuses[&"stun"].left == left,
		"outside simulation radius freezes motion and stun"
	)
	target.position.x = 20
	await frames(6)
	check(
		w.position.x < at.x - 0.1 and w.statuses[&"stun"].left < left,
		"reentering simulation resumes actual push and clock"
	)
	w.take_damage(w.max_hp, source)
	at = w.position
	await frames(2)
	check(
		w.dead and w.position == at and not w.is_physics_processing(), "dead creature stops physics"
	)
	w.free()


func run() -> void:
	var ontology = Model.Ontology.load_dir("res://ontology/instances")
	design = ontology.configs.generators.design
	var floor_ := box(Vector3(0, -0.5, 0), Vector3(100, 1, 100))
	target = Entity.new()
	source = Entity.new()
	root.add_child(target)
	root.add_child(source)
	target.position = Vector3(20, 0, 0)
	source.position = Vector3(10, 0, 0)
	for mode in [2, 1, 4]:  # CHASE, WANDER, protected RETURN
		await pure_stun(mode)
	for stun_first in [true, false]:
		for obstruction in ["open", "wall", "slide"]:
			await mixed_status(stun_first, obstruction)
	await inactive_and_dead()
	target.free()
	source.free()
	floor_.free()
	await frames(2)
	print("stun motion ok" if failed == 0 else "stun motion FAILED " + str(failed))
	quit(0 if failed == 0 else 1)
