## Creature contact resolution; the actor retains mutable state, RNG and public callbacks.
extends RefCounted
const Combat := preload("res://game/combat/combat.gd")
const Projectile := preload("res://game/combat/projectile.gd")
const Targeting := preload("res://game/combat/targeting.gd")


static func _shoot(c) -> void:
	var s: Dictionary = (c.role_cfg["shot"] as Dictionary).duplicate()
	s["color"] = c.role_cfg["color"]  # projectile.gd tints the sphere from the shot dict
	var from: Vector3 = c.head()
	var dir: Vector3 = c._target_head() - from
	var d := dir.length()
	if d < 0.01:
		return
	var t := d / float(s["speed"])
	dir.y += float(s.get("gravity", 0.0)) * t * t * 0.5
	if c.feel != null:
		c.feel.sfx(StringName(str(c.role_cfg["sfx"])))
	Projectile.fire(
		c,
		from,
		dir.normalized(),
		s,
		c.damage * float(c.role_cfg["damage-mult"]),
		false,
		c.role_cfg.get("applies", []),
		Combat.MAGICAL if c.role == &"mage" else Combat.PHYSICAL
	)


static func _strike(
	c,
	center: Vector3,
	radius: float,
	dmg: float,
	_combo_bonus: bool,
	applies: Array = [],
	attack_type: StringName = Combat.PHYSICAL,
	target_limit: int = 0
) -> int:
	var se: Dictionary = c.design.get("status-effects", {})
	var hits := 0
	var bodies: Array = c.bodies_within(center, radius)
	if target_limit > 0:
		bodies = bodies.slice(0, target_limit)
	for body in bodies:
		var completed = _strike_body(c, body, dmg, applies, attack_type, se)
		if completed == null:
			return 0
		if not completed:
			continue
		hits += 1
	return hits


static func bodies_within(c, center: Vector3, radius: float) -> Array:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), center)
	q.exclude = [c.get_rid()]
	var out: Array = []
	for r in c.get_world_3d().direct_space_state.intersect_shape(q, 16):
		var body: Object = r["collider"]
		var admitted = _contact_body(c, body)
		if admitted == null:
			return []
		if admitted:
			out.append(body)
	return out


# null = native noncompletion, false = prop-only contact, true = counted hit.
static func _strike_body(
	c, body, dmg: float, applies: Array, attack_type: StringName, se: Dictionary
) -> Variant:
	if body.has_method("take_direct_damage"):
		body.take_direct_damage(dmg, c)
		return false
	var d := Combat.after_defence(
		dmg,
		float(body.get("armor")),
		float(body.get("resistance")),
		attack_type,
		c.design.get("combat", {})
	)
	if not body.take_damage(d, c):
		c._hit_statuses(body)
		if not _shot_statuses(c, body, applies, se, d):
			return null
	return true


static func _shot_statuses(c, body, applies: Array, se: Dictionary, d: float) -> bool:
	for id in applies:
		if se.has(id) and body.has_method("apply_status"):
			body.apply_status(id, se[id], d, c)
	return true


static func _contact_body(c, body: Object):
	return (
		(c.special != null and body.has_method("take_direct_damage"))
		or (body.has_method("take_damage") and not body.get("dead") and body.get("species") == null)
	)


static func _bite(c) -> bool:
	var victim = Targeting.view_of(c.target)
	if c.special != null:
		for body in c.bodies_within(victim.global_position, float(c.atk["reach"])):
			if body.has_method("take_direct_damage"):
				body.take_direct_damage(c.damage, c)
	var d := Combat.after_defence(
		c.damage,
		float(victim.get("armor")),
		float(victim.get("resistance")),
		Combat.PHYSICAL,
		c.design.get("combat", {})
	)
	if not victim.take_damage(d, c):
		c._hit_statuses(victim)
	return true


static func _try_bite(c, can_chase, to_target) -> bool:
	var admitted := _bite_admission(c, can_chase, to_target)
	if admitted == 0:
		return false
	if admitted == 2:
		return _bite(c)
	return true


# 0 = native noncompletion, 1 = no bite, 2 = bite; preserve repeated live view reads.
static func _bite_admission(c, can_chase, to_target) -> int:
	if (
		can_chase
		and to_target <= float(c.atk["reach"]) * 1.25
		and Targeting.view_of(c.target) != null
		and Targeting.view_of(c.target).has_method("take_damage")
	):
		return 2
	return 1
