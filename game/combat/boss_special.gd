## Optional encounter-boss FSM. Saved remainders are simulation time; nodes never own persistence.
extends RefCounted
const Combat := preload("res://game/combat/combat.gd")
const Targeting := preload("res://game/combat/targeting.gd")
var boss
var saved: Dictionary
var cfg: Dictionary
var contents
var kind: String
var warning: MeshInstance3D
var _passed: Array[RID] = []


func setup(actor, record: Dictionary, profile: Dictionary, site_contents) -> void:
	boss = actor
	saved = record
	cfg = profile
	contents = site_contents
	boss.tree_exiting.connect(unload)


static func normalize_unload(record: Dictionary, profile: Dictionary) -> void:
	if record.phase in ["warning", "charge"]:
		record.phase = "cooldown"
		record.left = float(profile["cooldown-s"])
		record.recovery = float(profile["recovery-s"])
		record.origin = []
		record.endpoint = []
		record.target = ""


func unload() -> void:
	normalize_unload(saved, cfg)
	clear_warning()


func cancel() -> void:
	if saved.phase not in ["warning", "charge"]:
		return
	finish()


func finish() -> void:
	saved.phase = "cooldown"
	saved.left = float(cfg["cooldown-s"])
	saved.recovery = float(cfg["recovery-s"])
	saved.origin = []
	saved.endpoint = []
	saved.target = ""
	boss.velocity.x = 0
	boss.velocity.z = 0
	clear_warning()


func clear_warning() -> void:
	if is_instance_valid(warning):
		warning.queue_free()
	warning = null


func victim():
	for p in boss.targeting.party():
		if Targeting.identity(p) == saved.target and not p.get("dead"):
			return p
	return null


func sight(p) -> bool:
	var view = Targeting.view_of(p)
	if view == null:
		return false
	var q := PhysicsRayQueryParameters3D.create(
		boss.head(), view.head(), 0xFFFFFFFF, [boss.get_rid()]
	)
	var hit: Dictionary = boss.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or hit.collider == view


func can_start(p) -> bool:
	if p == null or not Targeting.valid_member(p) or p.get("dead"):
		return false
	return _start_geometry(p)


func start(p) -> void:
	saved.phase = "warning"
	saved.left = float(cfg["warning-s"])
	saved.origin = boss.logical_position()
	saved.endpoint = Targeting.position_of(p)
	saved.endpoint[1] = saved.origin[1]
	saved.target = Targeting.identity(p)
	_passed = []
	boss.velocity.x = 0
	boss.velocity.z = 0
	warning = MeshInstance3D.new()
	if kind == "stomp":
		var mesh_ := CylinderMesh.new()
		mesh_.top_radius = float(cfg.stomp.radius)
		mesh_.bottom_radius = mesh_.top_radius
		mesh_.height = 0.025
		warning.mesh = mesh_
	else:
		var mesh_ := BoxMesh.new()
		var delta := local_point(saved.endpoint) - local_point(saved.origin)
		mesh_.size = Vector3(cfg.charge["lane-width"], 0.025, delta.length())
		warning.mesh = mesh_
	warning.material_override = StandardMaterial3D.new()
	warning.material_override.albedo_color = Color(1, 0.25, 0.05, 0.6)
	warning.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	contents.add_child(warning)
	warning.global_position = local_point(saved.origin) + Vector3.UP * 0.04
	if kind == "charge":
		warning.global_position = (
			(local_point(saved.origin) + local_point(saved.endpoint)) / 2 + Vector3.UP * 0.04
		)
		warning.look_at(local_point(saved.endpoint) + Vector3.UP * 0.04)


func local_point(point: Array) -> Vector3:
	return (
		boss.frame.to_local(point) if boss.frame != null else Vector3(point[0], point[1], point[2])
	)


## Return whether basic action is suppressed NOW, not throughout the ten-second cooldown.
func advance(dt: float) -> bool:
	var returning: bool = boss.state == boss.State.RETURN or boss.targeting.record(boss).returning
	if boss.dead:
		cancel()
		return false
	var unable: bool = boss.stunned() or returning
	if unable:
		cancel()
	return _advance_phases(dt, unable)


# Local [remaining, result] packets: null continues; bool returns suppression; [] is native failure.
func _advance_phases(remaining: float, unable: bool) -> bool:
	while true:
		var result := _phase(remaining, unable)
		if result.is_empty():
			return false
		remaining = result[0]
		if result[1] != null:
			return result[1]
		if remaining <= 1e-9:
			break
	return _suppressed()


func _phase(remaining: float, unable: bool) -> Array:
	match saved.phase:
		"ready", "cooldown":
			return _cooldown_phase(remaining, unable)
		"warning":
			return _warning_phase(remaining)
		"charge":
			return _charge_phase(remaining)
	return [remaining, null]


func hit_player(view, multiplier: float) -> void:
	var dodged: bool = view.get("_iframes") != null and view._iframes > 0
	var d := Combat.after_defence(
		boss.damage * multiplier,
		float(view.armor),
		float(view.resistance),
		Combat.PHYSICAL,
		boss.design.combat
	)
	if not view.take_damage(d, boss) and not dodged:
		boss._hit_statuses(view)


func stomp() -> void:
	var origin: Array = saved.origin
	var rules: Dictionary = cfg.stomp
	for p in boss.targeting.party():
		if not _stomp_player(p, origin, rules):
			return
	contents.shatter_stomp(
		origin, float(rules.radius), boss.damage * float(rules["damage-mult"]), boss
	)


## Native capsule sweep, never endpoint sampling. Excluding shattered rubble lets the SAME sweep continue.
func charge(dt: float) -> float:
	var rules: Dictionary = cfg.charge
	var from: Vector3 = boss.global_position
	var endpoint := local_point(saved.endpoint)
	var delta := endpoint - from
	delta.y = 0
	if delta.length() == 0:
		finish()
		return 0.0
	if dt <= 0:
		return 0.0
	var distance := minf(delta.length(), float(rules.speed) * dt)
	var motion := delta.normalized() * distance
	var capsule := CapsuleShape3D.new()
	capsule.radius = float(rules["sweep-radius"])
	capsule.height = boss.get_node("Collision").shape.height
	var sweep := ShapeCast3D.new()
	sweep.shape = capsule
	sweep.margin = 0.0
	sweep.max_results = 128
	boss.add_child(sweep)
	sweep.global_transform = Transform3D(Basis(), from + Vector3.UP * capsule.height / 2)
	sweep.target_position = motion
	for rid in _passed:
		sweep.add_exception_rid(rid)
	return _charge_contacts(sweep, rules, from, motion, distance, delta, dt)


func _start_geometry(p) -> bool:
	var a: Array = boss.logical_position()
	var b := Targeting.position_of(p)
	var distance := Vector2(float(b[0]) - a[0], float(b[2]) - a[2]).length()
	var profile: Dictionary = cfg[kind]
	if absf(float(b[1]) - a[1]) > float(profile["start-height-diff"]):
		return false
	return _start_range(p, profile, distance)


func _stomp_player(p, origin: Array, rules: Dictionary) -> bool:
	var point := Targeting.position_of(p)
	var view = Targeting.view_of(p)
	if p.get("dead") or view == null:
		return true
	if (
		Vector2(float(point[0]) - origin[0], float(point[2]) - origin[2]).length()
		> float(rules.radius)
	):
		return true
	if (
		point[1] < origin[1] + rules["victim-height"][0]
		or point[1] > origin[1] + rules["victim-height"][1]
	):
		return true
	if sight(p):
		hit_player(view, float(rules["damage-mult"]))
	return true


func _charge_contacts(
	sweep: ShapeCast3D,
	rules: Dictionary,
	from: Vector3,
	motion: Vector3,
	distance: float,
	delta: Vector3,
	dt: float
) -> float:
	var fraction := 1.0
	var stopped := false
	while true:
		sweep.force_shapecast_update()
		var body = _first_obstacle(sweep, motion)
		if body == null:
			break
		fraction = sweep.get_closest_collision_safe_fraction()
		var result := _charge_contact(sweep, body, rules)
		if result == 0:
			return 0.0
		if result == 1:
			fraction = 1.0
			continue
		stopped = true
		break
	return _finish_charge_motion(sweep, from, motion, fraction, distance, rules, stopped, delta, dt)


func _cooldown_phase(remaining: float, unable: bool) -> Array:
	if saved.phase == "ready":
		if boss.target == null:
			return [remaining, false]
		saved.engaged = true
	var step := minf(remaining, float(saved.left))
	saved.left = maxf(0, saved.left - step)
	saved.recovery = maxf(0, saved.recovery - step)
	remaining -= step
	if saved.left > 1e-9:
		return [remaining, float(saved.recovery) > 0]
	saved.left = 0.0
	return _cooldown_ready(remaining, unable)


func _warning_phase(remaining: float) -> Array:
	var p = victim()
	if p == null or not sight(p):
		finish()
		return [remaining, true]
	var step := minf(remaining, float(saved.left))
	saved.left = maxf(0, saved.left - step)
	remaining -= step
	if saved.left > 1e-9:
		return [remaining, true]
	saved.left = 0.0
	clear_warning()
	if kind == "stomp":
		stomp()
		finish()
	else:
		saved.phase = "charge"
	return [remaining, null]


func _charge_phase(remaining: float) -> Array:
	if victim() == null:
		finish()
		return [remaining, true]
	remaining -= charge(remaining)
	return [remaining, null]


func _start_range(p, profile: Dictionary, distance: float) -> bool:
	if kind == "stomp" and distance > float(profile.radius):
		return false
	if (
		kind == "charge"
		and (distance <= float(profile.range[0]) or distance > float(profile.range[1]))
	):
		return false
	return sight(p)


func _first_obstacle(sweep: ShapeCast3D, motion: Vector3):
	var body
	for i in sweep.get_collision_count():
		# The native cast collects all contacts at impact, including supporting floor contacts.
		# Only a contact opposing this horizontal attack can obstruct it.
		if sweep.get_collision_normal(i).dot(motion) < 0:
			body = sweep.get_collider(i)
			break
	return body


# 0 = native noncompletion, 1 = passed rubble/prop, 2 = original blocking contact.
func _charge_contact(sweep: ShapeCast3D, body, rules: Dictionary) -> int:
	var rid: RID = body.get_rid()
	if body.has_meta("rubble"):
		contents.break_rubble(body.get_meta("rubble"))
		sweep.add_exception_rid(rid)
		_passed.append(rid)
		return 1
	if body.has_method("take_direct_damage"):
		body.take_direct_damage(boss.damage * float(rules["damage-mult"]), boss)
		sweep.add_exception_rid(rid)
		_passed.append(rid)
		return 1
	if boss.targeting.party().any(func(p): return Targeting.view_of(p) == body):
		hit_player(body, float(rules["damage-mult"]))
	return 2


func _suppressed() -> bool:
	return saved.phase in ["warning", "charge"] or float(saved.recovery) > 0


func _cooldown_ready(remaining: float, unable: bool) -> Array:
	if unable or not can_start(boss.target):
		return [remaining, float(saved.recovery) > 0]
	start(boss.target)
	return [remaining, null]


func _finish_charge_motion(
	sweep: ShapeCast3D,
	from: Vector3,
	motion: Vector3,
	fraction: float,
	distance: float,
	rules: Dictionary,
	stopped: bool,
	delta: Vector3,
	dt: float
) -> float:
	sweep.free()
	boss.global_position = from + motion * fraction
	boss.velocity.x = 0
	boss.velocity.z = 0
	var used := distance * fraction / float(rules.speed)
	if stopped or distance >= delta.length():
		finish()
	return used if stopped or saved.phase != "charge" else dt
