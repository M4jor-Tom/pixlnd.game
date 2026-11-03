## Ordered simulation phases; Player owns every mutable field and public entry point.
extends RefCounted


static func _physics_process(p, dt: float, push_decay: float) -> void:
	if p.touch_input != null:
		p._touch_frame = p.touch_input.take_frame()  # Drain even unavailable/dead frames.
		p._touch_jump = false
	if p.cfg.is_empty() or p.dead or not p.ground_ready.call(p.global_position):
		_drop_terminal_touch(p)
		return
	var g := float(p.cfg["gravity"])
	p.tick_statuses(dt)
	if p.dead:
		return
	_live_tick(p, dt, g, push_decay)


static func _drop_terminal_touch(p) -> void:
	if (
		p.touch_input != null
		and p._touch_frame["requests"].any(
			func(q): return q.action == "special-attack" and q.phase in ["release", "cancel"]
		)
	):
		p._charge = -1.0  # An unavailable terminal cancels without firing or replay.


static func _preempt_vendor(p) -> bool:
	if p.touch_input != null and not p.ui_open and not p.stunned():
		if p.touch_input.preempt_vendor_panel(p._touch_frame["requests"]):
			p._touch_frame = p.touch_input.take_frame()
	return true


static func _touch_look(p) -> bool:
	if p.touch_input != null:
		p.rig.apply_touch_look(
			p._touch_frame["look"],
			p._touch_frame["safe_width"],
			float(p.touch_input.profile["look-deg-per-safe-width"])
		)
	return true


static func _movement_input(p):
	return (
		Vector2.ZERO
		if p.ui_open or p.map_open or p.stunned()
		else (
			Input.get_vector("move_left", "move_right", "move_forward", "move_back")
			if p.touch_input == null
			else p._touch_frame["move"]
		)
	)


static func _requests_allowed(p):
	return not p.ui_open and not p.map_open and not p.stunned()


static func _touch_actions(p, dt: float, dir: Vector3, swimming: bool) -> bool:
	if not p.combat.is_empty():
		p._combat_time_tick(dt)
	if swimming:
		p.touch_input.retire_hold("jump")
	else:
		p.touch_input.retire_hold("swim-ascent")
	p._touch_frame["held"] = p.touch_input.held.duplicate()
	var allowed = _requests_allowed(p)
	if allowed == null:
		return false
	if allowed:
		return _touch_requests_charge(p, dir, dt)
	return _touch_charge(p, dt)


static func _touch_requests(p, dir: Vector3) -> bool:
	for request in p._touch_frame["requests"]:
		p._apply_touch_request(request, dir)
		if p.ui_open:
			break
	return true


static func _touch_charge(p, dt: float) -> bool:
	if not (p._charge >= 0):
		return true
	var allowed = _requests_allowed(p)
	if allowed == null:
		return false
	if allowed and not p.abilities.busy():
		p._charge = minf(
			p.mp,
			(
				p._charge
				+ (
					float(p.design["special-attack"]["charge-mp-per-s"])
					* p.abilities.mult("charge-mult")
					* dt
				)
			)
		)
	return true


static func _sprinting(p, dir: Vector3, swimming: bool):
	return (
		(
			Input.is_action_pressed("sprint")
			if p.touch_input == null
			else p._touch_frame["held"].get("sprint", false)
		)
		and _sprint_motion(p, dir, swimming)
	)


static func _sprint_motion(p, dir: Vector3, swimming: bool) -> bool:
	return dir != Vector3.ZERO and p.stamina > 0.0 and not swimming


static func _walk_speed(p, dt: float, dir: Vector3, swimming: bool):
	var speed := float(p.cfg["walk"])
	var st: Dictionary = p.cfg["stamina"]
	var sprinting = _sprinting(p, dir, swimming)
	if sprinting == null:
		return null
	if sprinting:
		speed *= float(p.cfg["sprint-mult"])
		p.stamina = maxf(0.0, p.stamina - float(st["sprint-drain"]) * dt)
		p._stamina_idle = 0.0
	else:
		p._stamina_idle += dt
		if p._stamina_idle >= float(st["regen-delay-s"]):
			p.stamina = minf(float(st["max"]), p.stamina + float(st["regen"]) * dt)
	return _speed_buffs(p, speed)


static func _swim_up(p):
	var allowed = _requests_allowed(p)
	if allowed == null:
		return null
	if not allowed:
		return false
	return _swim_held(p)


static func _swim_held(p):
	return not not (
		Input.is_action_pressed("jump")
		if p.touch_input == null
		else p._touch_frame["held"].get("swim-ascent", false)
	)


static func _vertical_motion(p, dt: float, g: float, swimming: bool, speed: float):
	if swimming:
		return _swim_motion(p, speed)
	if not _jump_motion(p, dt, g):
		return null
	return speed


static func _ground_jump(p, allowed):
	return (
		allowed
		and p.is_on_floor()
		and (Input.is_action_just_pressed("jump") if p.touch_input == null else p._touch_jump)
	)


static func _cut_jump(p):
	if not (p.velocity.y > 0.0):
		return false
	return _jump_released(p)


static func _jump_released(p):
	if p.ui_open or p.map_open or p.stunned():
		return true
	return not (
		Input.is_action_pressed("jump")
		if p.touch_input == null
		else p._touch_frame["held"].get("jump", false)
	)


static func _jump_motion(p, dt: float, g: float) -> bool:
	p.velocity.y -= g * dt
	var jh: Dictionary = p.cfg["jump-height"]
	var allowed = _requests_allowed(p)
	if allowed == null:
		return false
	var jump = _ground_jump(p, allowed)
	if jump == null:
		return false
	if jump:
		p.velocity.y = sqrt(2.0 * g * float(jh["hold"]))
	else:
		var cut = _cut_jump(p)
		if cut == null:
			return false
		if cut:
			p.velocity.y = minf(p.velocity.y, sqrt(2.0 * g * float(jh["tap"])))
	return true


static func _move(p, dt: float, dir: Vector3, speed: float, push_decay: float) -> bool:
	p.velocity.x = dir.x * speed
	p.velocity.z = dir.z * speed
	if not p._dodge.is_empty():
		var roll: Vector3 = (
			p._dodge["dir"]
			* float(p.defence["dodge"]["distance"])
			/ float(p.defence["dodge"]["duration-s"])
		)
		p.velocity.x = roll.x
		p.velocity.z = roll.z
		p._fall_from = -INF  # the roll's landing does no fall damage
	p.velocity.x += p._push.x
	p.velocity.z += p._push.z
	p._push = p._push.move_toward(Vector3.ZERO, push_decay * dt)
	if p.abilities != null and not p.abilities.dash.is_empty():
		var dv: Vector3 = p.abilities.dash_velocity()
		p.velocity.x = dv.x
		p.velocity.z = dv.z
	p._apply_world_precision(dt)
	p.step_up(Vector3(p.velocity.x, 0, p.velocity.z) * dt, float(p.cfg["step-up"]))
	var was_airborne: bool = not p.is_on_floor()
	p.move_and_slide()
	p._enforce_world_boundary()
	if p.abilities != null:
		p.abilities.after_move(dt)
	p._fall_damage(was_airborne)
	return true


static func _desktop_actions(p, dt: float) -> void:
	if p.touch_input == null and not p.combat.is_empty():
		p._combat_tick(dt)
	_desktop_items(p)


static func _desktop_items(p) -> void:
	if _desktop_items_allowed(p):
		if Input.is_action_just_pressed("interact"):
			p.interact_nearest()
		if Input.is_action_just_pressed("quick-item"):
			p.use_quick()


static func _apply_world_precision(p, dt: float) -> void:
	var logical: Array = p.logical_position()
	var x: Array = p._precision_axis(
		p.global_position.x,
		p.velocity.x,
		dt,
		p.global_position.x + p.world_min.x - logical[0],
		p.global_position.x + p.world_max.x - 0.5 - logical[0],
		p._motion_remainder_x
	)
	var z: Array = p._precision_axis(
		p.global_position.z,
		p.velocity.z,
		dt,
		p.global_position.z + p.world_min.y - logical[2],
		p.global_position.z + p.world_max.y - 0.5 - logical[2],
		p._motion_remainder_z
	)
	p.velocity.x = x[0]
	p._motion_remainder_x = x[1]
	p.velocity.z = z[0]
	p._motion_remainder_z = z[1]
	if (x[2] or z[2]) and p.abilities != null and not p.abilities.dash.is_empty():
		p.abilities.dash["left"] = 0.0


static func _precision_axis(
	position: float, speed: float, dt: float, minimum: float, maximum: float, remainder: float
) -> Array:
	if speed == 0.0:
		return [0.0, 0.0, false]
	var direct_displacement := float(Vector3(position + speed * dt, 0, 0).x) - position
	if remainder == 0.0 and direct_displacement == speed * dt:
		return [speed, 0.0, false]
	var requested := speed * dt + remainder
	var unbounded := position + requested
	var target := clampf(unbounded, minimum, maximum)
	var displacement := float(Vector3(target, 0, 0).x) - position
	if displacement == 0.0:
		return [0.0, 0.0 if target != unbounded else requested, target != unbounded]
	return _precision_displacement(displacement, dt, target, unbounded, requested)


static func _enforce_world_boundary(p) -> void:
	var logical: Array = p.logical_position()
	var bx := clampf(logical[0], p.world_min.x, p.world_max.x - 0.5)
	var bz := clampf(logical[2], p.world_min.y, p.world_max.y - 0.5)
	if not _boundary_motion(p, logical, bx, bz):
		return
	p.global_position.x += bx - float(logical[0])
	p.global_position.z += bz - float(logical[2])
	p.logical_position()


static func _fall_damage(p, was_airborne: bool) -> void:
	if not p.is_on_floor():
		p._fall_from = maxf(p._fall_from, p.global_position.y)
		return
	if was_airborne and p._fall_from > -INF:
		var fd: Dictionary = p.cfg["fall-damage"]
		var drop: float = p._fall_from - p.global_position.y - float(fd["from-blocks"])
		if drop > 0.0:
			p.take_damage(p.max_hp * float(fd["pct-max-hp-per-block"]) / 100.0 * drop, p)
	p._fall_from = -INF


static func _end_dash(p) -> bool:
	if p.abilities != null and not p.abilities.dash.is_empty():
		p.abilities.dash["left"] = 0.0
	return true


static func _precision_displacement(
	displacement: float, dt: float, target: float, unbounded: float, requested: float
) -> Array:
	return [
		displacement / dt,
		0.0 if target != unbounded else requested - displacement,
		target != unbounded
	]


static func _prepare_input(p):
	if not _preempt_vendor(p):
		return null
	if not _touch_look(p):
		return null
	return _movement_input(p)


static func _live_tick(p, dt: float, g: float, push_decay: float) -> void:
	var input_value = _prepare_input(p)
	if input_value == null:
		return
	var input: Vector2 = input_value
	var dir := (Basis(Vector3.UP, p.rig.rotation.y) * Vector3(input.x, 0, input.y)).normalized()
	if not p.defence.is_empty():
		p._defence_tick(dt, dir, input == Vector2.ZERO)
	var swimming: bool = p.global_position.y < p.water_top - 0.5
	if not _touch_phase(p, dt, dir, swimming):
		return
	_motion_tick(p, dt, g, dir, swimming, push_decay)


static func _motion_tick(
	p, dt: float, g: float, dir: Vector3, swimming: bool, push_decay: float
) -> bool:
	var speed_value = _walk_speed(p, dt, dir, swimming)
	if speed_value == null:
		return false
	var speed: float = speed_value
	var vertical_speed = _vertical_motion(p, dt, g, swimming, speed)
	if vertical_speed == null:
		return false
	speed = vertical_speed
	if not _move(p, dt, dir, speed, push_decay):
		return false
	if p.dead:
		return true
	_desktop_actions(p, dt)
	return true


static func _touch_requests_charge(p, dir: Vector3, dt: float) -> bool:
	if not _touch_requests(p, dir):
		return false
	return _touch_charge(p, dt)


static func _speed_buffs(p, speed: float):
	if p.abilities != null:
		speed *= p.abilities.mult("move-mult")
	if p.blocking and not p._cyclone():
		speed *= float(p.defence["block"]["move-mult"])
	return speed


static func _swim_motion(p, speed: float):
	speed *= (
		float(p.cfg["swim-mult"])
		* (p.skill_tree.effect_mult(&"swimming") if p.skill_tree != null else 1.0)
	)
	var vertical := float(p.cfg["swim-vertical"])
	var up = _swim_up(p)
	if up == null:
		return null
	p.velocity.y = vertical * (1.0 if up else -0.3)
	p._fall_from = -INF
	return speed


static func _desktop_items_allowed(p):
	return _desktop_items_base(p) and not p.ui_open and not p.map_open and not p.stunned()


static func _boundary_motion(p, logical: Array, bx: float, bz: float) -> bool:
	if logical[0] != bx and not _stop_axis(p, 0):
		return false
	if logical[2] != bz and not _stop_axis(p, 2):
		return false
	return true


static func _stop_axis(p, axis: int) -> bool:
	if axis == 0:
		p.velocity.x = 0.0
		p._motion_remainder_x = 0.0
	else:
		p.velocity.z = 0.0
		p._motion_remainder_z = 0.0
	return _end_dash(p)


static func _touch_phase(p, dt: float, dir: Vector3, swimming: bool) -> bool:
	if p.touch_input == null:
		return true
	return _touch_actions(p, dt, dir, swimming)


static func _desktop_items_base(p):
	return p.touch_input == null and p.inventory != null
