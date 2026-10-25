extends SceneTree
const Model := preload("res://ontology/model.gd")
const PLAYER := preload("res://game/entities/player.tscn")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var p = PLAYER.instantiate()
	root.add_child(p)
	p.set_physics_process(false)
	check(p.has_method("logical_position"), "entity exposes scalar logical position")
	check(ResourceLoader.exists("res://game/world/local_frame.gd"), "injected local frame exists")
	if failed:
		p.free()
		quit(1)
		return
	var d: Dictionary = (
		Model.Ontology.load_dir("res://ontology/instances").configs.generators.design
	)
	p.setup(d.movement, d.camera, &"normal")
	var frame = load("res://game/world/local_frame.gd").new(int(d.terrain["zone-blocks"]))
	var exact := [8380416.123456789, 100.25, -8380416.234567891]
	frame.set_origin(exact)
	frame.place_entity(p, exact, true)
	check(p.logical_position() == exact, "cold placement retains fractional scalar anchor")
	check(absf(p.global_position.x) < 64 and absf(p.global_position.z) < 64, "bounded native pose")
	var rid: RID = p.get_rid()
	for i in 20:
		frame.shift_to([frame.origin[0] + (64 if i % 2 == 0 else -64), frame.origin[1]])
		check(p.logical_position() == exact, "no-motion frame change never rounds scalar anchor")
		check(p.get_rid() == rid, "frame change keeps native RID")
	var before: Vector3 = p.global_position
	p.position.x += 0.125
	check(
		p.logical_position()[0] == exact[0] + float(p.global_position.x) - float(before.x),
		"only measured native displacement changes anchor"
	)
	var q: Array = p.logical_position()
	frame.place_entity(p, [-0.125, q[1], 0.25], true)
	frame.prepare(p)
	check(frame.origin == [-64, 0], "negative fractional zone uses floor")
	check(p.logical_position() == [-0.125, q[1], 0.25], "explicit discontinuous placement")
	# A live pending target is distinct from its committed native pose; translation preserves both.
	var native = PhysicsServer3D.body_get_direct_state(rid)
	PhysicsServer3D.body_set_state(
		rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3(2, 0, 0)
	)
	p.position.x += 0.125
	p.force_update_transform()
	# Staging a target wakes a kinematic body; seed the generated/sleep witness AFTER staging.
	native.linear_velocity = Vector3(0.75, 0.25, 0)
	native.angular_velocity = Vector3(0, 0.125, 0)
	native.sleeping = true
	var committed: Transform3D = PhysicsServer3D.body_get_state(
		rid, PhysicsServer3D.BODY_STATE_TRANSFORM
	)
	var pending: Transform3D = p.global_transform
	check(committed != pending, "witness actually has genuine pending native movement")
	var old: Array = frame.origin.duplicate()
	var next := [old[0] + 64, old[1]]
	frame.shift_to(next)
	var delta := Vector3(-64, 0, 0)
	check(
		(
			PhysicsServer3D.body_get_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
			== committed.translated(delta)
		),
		"live translated committed C preserved"
	)
	check(p.global_transform == pending.translated(delta), "live genuine pending T preserved")
	check(
		(
			native.linear_velocity == Vector3(0.75, 0.25, 0)
			and native.angular_velocity == Vector3(0, 0.125, 0)
			and native.sleeping
		),
		"generated velocity/angular/sleep restored without overwriting constants"
	)
	# The server velocity getter reports generated velocity, not the separate kinematic constant.
	# Let the genuine pending target complete, then constant behavior must resume without script motion.
	native.sleeping = false
	for i in 3:
		await physics_frame
	check(
		PhysicsServer3D.body_get_direct_state(rid).linear_velocity == Vector3(2, 0, 0),
		"constant native velocity remains distinct on subsequent callbacks"
	)
	p.free()
	print("local frame ok" if not failed else "local frame FAILED")
	quit(0 if not failed else 1)
