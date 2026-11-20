## Attack dispatch, contact resolution and settlement; Player retains RNG, resources and combo state.
extends RefCounted

const Combat := preload("res://game/combat/combat.gd")
const Projectile := preload("res://game/combat/projectile.gd")
const Domain := preload("res://game/domain/domain.gd")


static func _combat_time_tick(p, dt: float) -> void:
	p._swing_t -= dt
	p._combo_t -= dt
	if p._combo_t <= 0.0:
		p.combo = 0
	if p.abilities == null:
		return
	p.abilities.tick(dt)
	if p.stunned():
		p._charge = -1.0
	elif p.mp_passive:
		p.mp = minf(
			float(p.design["resources"]["mp"]["max"]),
			p.mp + float(p.design["resources"]["mp"]["mage-regen-per-s"]) * dt
		)


static func _combat_tick(p, dt: float) -> void:
	p._combat_time_tick(dt)
	if p.abilities == null:
		_basic_without_abilities(p)
		return
	if p.stunned() or p.ui_open or p.map_open:
		return
	_desktop_combat(p, dt)


static func _basic_without_abilities(p) -> void:
	if _desktop_unblocked(p) and Input.is_action_just_pressed("basic-attack") and p._swing_t <= 0.0:
		p._swing()


static func _desktop_combat(p, dt: float) -> void:
	if not _class_inputs(p):
		return
	if p.abilities.busy():
		return
	if Input.is_action_just_pressed("basic-attack") and p._swing_t <= 0.0:
		p._swing()
	p._special_tick(dt)


static func _class_inputs(p) -> bool:
	for slot in 4:
		if (
			Input.is_action_just_pressed("class-skill-%d" % (slot + 1))
			or (slot == 3 and Input.is_action_just_pressed("ultimate"))
		):
			p.use_class_skill(slot + 1)
	return true


static func _apply_touch_request(p, request: Dictionary, dir: Vector3) -> void:
	if p.dead or p.ui_open or p.map_open or p.stunned():
		return
	var action: String = request.action
	if action in ["jump", "basic-attack", "special-attack"]:
		_touch_attack(p, request, action)
		return
	if action in ["dodge", "interact", "pick-up", "quick-item"]:
		_touch_world(p, action, dir)
		return
	_touch_panel_skill(p, request, action)


static func _touch_attack(p, request: Dictionary, action: String) -> void:
	match action:
		"jump":
			if request.phase == "start" and p.global_position.y >= p.water_top - 0.5:
				p._touch_jump = true
		"basic-attack":
			_touch_basic(p)
		"special-attack":
			_touch_special(p, request)


static func _touch_basic(p) -> void:
	if p._swing_t <= 0 and (p.abilities == null or not p.abilities.busy()):
		p._swing()


static func _touch_special(p, request: Dictionary) -> void:
	if p.weapon.is_empty():
		return
	if request.phase == "cancel":
		p._charge = -1.0
		return
	if p.abilities == null or p.abilities.busy():
		if request.phase == "release":
			p._charge = -1.0
		return
	_touch_special_commit(p, request)


static func _touch_special_commit(p, request: Dictionary) -> void:
	if request.phase == "start" and p.mp >= float(p.design["special-attack"]["min-mp"]):
		if p.special_mode == &"charged":
			p._charge = 0.0
		else:
			p._special(p.mp)
	elif request.phase == "release" and p._charge >= 0:
		p._special(minf(p.mp, p._charge))
		p._charge = -1.0


static func _touch_world(p, action: String, dir: Vector3) -> void:
	match action:
		"dodge":
			p.dodge(dir)
		"interact":
			p.talk_nearest()
		"pick-up":
			p.pick_up_nearest()
		"quick-item":
			p.use_quick()


static func _touch_panel_skill(p, request: Dictionary, action: String) -> void:
	match action:
		"inventory", "skills-window":
			p.touch_input.open_panel(action)
		"zoom":
			p.rig.zoom_steps(int(request["steps"]))
		_:
			if action.begins_with("class-skill-"):
				p.use_class_skill(int(action.right(1)))


static func _special_tick(p, dt: float) -> void:
	if p.weapon.is_empty():
		return
	var sp: Dictionary = p.design["special-attack"]
	if p.special_mode == &"charged":
		_charged_special(p, dt, sp)
	elif Input.is_action_just_pressed("special-attack") and p.mp >= float(sp["min-mp"]):
		p._special(p.mp)


static func _special(p, charged: float) -> void:
	if p.weapon.is_empty():
		return
	var sp: Dictionary = p.design["special-attack"]
	var f := charged / float(p.design["resources"]["mp"]["max"])
	p.mp -= charged
	var m: Dictionary = p.moveset["m2"]
	var applies: Array = m.get("applies", []).duplicate()
	if p._rng.randf() < f * float(sp["stun-chance-at-full"]):
		applies.append(&"stun")
	p._attack(
		m,
		float(p.weapon["damage"]) * (1.0 + f * (float(sp["damage-mult-at-full"]) - 1.0)),
		false,
		applies
	)


static func _front(p) -> Vector3:
	var ba: Dictionary = p.combat["basic-attack"]
	return (
		p.global_position
		+ Vector3.UP
		+ (Basis(Vector3.UP, p.rig.rotation.y) * Vector3.FORWARD) * float(ba["reach"]) * 0.6
	)


static func aim(p) -> Vector3:
	return -p.rig.global_transform.basis.z


static func eye(p) -> Vector3:
	return p.global_position + Vector3.UP * p.rig.position.y


static func moveset_for(p, type: StringName, default_moveset: Dictionary) -> Dictionary:
	var mv: Dictionary = p.design.get("movesets", {})
	var m: Dictionary = mv.get(type, mv.get("default", default_moveset))
	return mv[m["as"]] if m.has("as") else m


static func _swing(p) -> void:
	if p.weapon.is_empty():
		return
	var ba: Dictionary = p.combat["basic-attack"]
	var m: Dictionary = p.moveset["m1"]
	p._swing_t = (
		float(ba["swing-s"])
		* float(m.get("swing-mult", 1.0))
		* (p.abilities.mult("swing-mult") if p.abilities != null else 1.0)
	)
	var applies: Array = m.get("applies", []).duplicate()
	if not _finisher(p, m, applies):
		return
	var hits: int = p._attack(m, float(p.weapon["damage"]), true, applies)
	if hits == 0:
		p._m1_hits = 0


static func _attack(p, m: Dictionary, dmg: float, combo_bonus: bool, applies: Array) -> int:
	var ba: Dictionary = p.combat["basic-attack"]
	var attack_type: StringName = p.weapon_attack_type()
	dmg *= float(m.get("damage-mult", 1.0))
	var hits: int = 0
	match str(m.get("kind", "melee")):
		"projectile":
			p._fire(m, dmg, combo_bonus, applies, Vector3.INF, attack_type)
			return -1
		"beam", "at-cursor":
			hits = p._strike(
				p._aim_point(float(m["range"])),
				float(m["radius"]),
				dmg,
				combo_bonus,
				applies,
				attack_type
			)
		_:
			var result = _melee_attack(p, m, dmg, combo_bonus, applies, attack_type, ba)
			if result == null:
				return 0
			hits = result
	if hits > 0:
		p._landed(combo_bonus)
	else:
		p.combo = 0  # c-combo-reset
	return hits


static func _aim_point(p, range: float) -> Vector3:
	var from: Vector3 = p.eye()
	var q := PhysicsRayQueryParameters3D.create(
		from, from + p.aim() * range, 0xFFFFFFFF, [p.get_rid()]
	)
	var hit: Dictionary = p.get_world_3d().direct_space_state.intersect_ray(q)
	return hit["position"] if not hit.is_empty() else from + p.aim() * range


static func _fire(
	p,
	s: Dictionary,
	dmg: float,
	combo_bonus: bool,
	applies: Array,
	from := Vector3.INF,
	attack_type: StringName = Combat.PHYSICAL
) -> Array:
	if from == Vector3.INF:
		from = p.eye()
	if p.feel != null:
		p.feel.play(&"shoot")  # D25: once per attack, not per shot of a volley
	return Projectile.fire(p, from, p.aim(), s, dmg, combo_bonus, applies, attack_type)


static func _landed(p, combo_bonus: bool, committed_weapon: Dictionary = {}) -> void:
	var source: Dictionary = p.weapon if committed_weapon.is_empty() else committed_weapon
	if source.is_empty():
		return
	p.combo = mini(p.combo + 1, int(source["combo_cap"]))
	p._combo_t = float(p.combat["combo"]["expire-s"])
	if not combo_bonus:
		return
	_basic_rewards(p)


static func bodies_within(p, center: Vector3, radius: float) -> Array:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), center)
	q.exclude = [p.get_rid()]
	var out: Array = []
	for r in p.get_world_3d().direct_space_state.intersect_shape(q, 16):
		var body: Object = r["collider"]
		var admitted = _damageable(body)
		if admitted == null:
			return []
		if admitted:
			out.append(body)
	out.sort_custom(
		func(x: Node3D, y: Node3D) -> bool:
			return (
				x.global_position.distance_squared_to(p.global_position)
				< y.global_position.distance_squared_to(p.global_position)
			)
	)
	return out


static func nearest_enemy(p, radius: float) -> Node3D:
	for b in p.bodies_within(p.global_position + Vector3.UP, radius):
		if not b.has_method("take_direct_damage") and b.get("hostility") != &"F":
			return b
	return null


static func weapon_attack_type(p) -> StringName:
	if p.o == null or not p.weapon.has("type") or not p.o.weapon_types.has(p.weapon["type"]):
		return Combat.PHYSICAL
	return (
		Combat.MAGICAL
		if p.o.weapon_types[p.weapon["type"]].slot_class == &"mage"
		else Combat.PHYSICAL
	)


static func ability_attack_type(p, a) -> StringName:
	var owner: StringName = StringName(str(a.slot_owner)) if a.slot_owner is String else p.spec
	var source_class: StringName = (
		StringName(p.o.specs[owner].slot_class) if p.o.specs.has(owner) else owner
	)
	return Combat.MAGICAL if source_class == &"mage" else Combat.PHYSICAL


static func _charged_special(p, dt: float, sp: Dictionary) -> void:
	if Input.is_action_just_pressed("special-attack") and p.mp >= float(sp["min-mp"]):
		p._charge = 0.0
	if p._charge >= 0.0:
		p._charge = minf(
			p.mp, p._charge + float(sp["charge-mp-per-s"]) * p.abilities.mult("charge-mult") * dt
		)
		if not Input.is_action_pressed("special-attack"):
			p._special(p._charge)
			p._charge = -1.0


static func _finisher(p, m: Dictionary, applies: Array) -> bool:
	if m.has("finisher"):
		var fin: Dictionary = m["finisher"]
		if (p._m1_hits + 1) % int(fin["every"]) == 0 and p._rng.randf() < float(fin["chance"]):
			applies.append_array(fin["applies"])
	return true


static func _melee_attack(
	p,
	m: Dictionary,
	dmg: float,
	combo_bonus: bool,
	applies: Array,
	attack_type: StringName,
	ba: Dictionary
):
	var lunge := float(m.get("lunge", 0.0))
	if lunge > 0.0:
		p.move_and_collide((Basis(Vector3.UP, p.rig.rotation.y) * Vector3.FORWARD) * lunge)  # ponytail: instant lunge, no animation
	p._enforce_world_boundary()
	var center: Vector3 = p.global_position + Vector3.UP if m.get("around", false) else p._front()
	return p._strike(
		center,
		float(ba["hit-radius"]) * float(m.get("radius-mult", 1.0)),
		dmg,
		combo_bonus,
		applies,
		attack_type
	)


static func _basic_rewards(p) -> void:
	p._m1_hits += 1
	if p.abilities != null and not p.mp_passive:
		var bonus: float = (
			1.0 + p._hit_stealth * float(p.defence["stealth"]["mp-mult-at-full"])
			if not p.defence.is_empty()
			else 1.0
		)
		p.mp = minf(
			float(p.design["resources"]["mp"]["max"]),
			p.mp + float(p.design["resources"]["mp"]["per-hit"]) * bonus
		)


static func _damageable(body: Object):
	return (
		body.has_method("take_direct_damage")
		or (body.has_method("take_damage") and not body.get("dead"))
	)


static func _desktop_unblocked(p):
	return not p.ui_open and not p.map_open
