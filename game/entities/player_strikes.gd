## Strike contact resolution and strongest feedback; Player owns RNG, resources and public API.
extends RefCounted

const Combat := preload("res://game/combat/combat.gd")


static func _strike(
	p,
	tiers: Array[StringName],
	center: Vector3,
	radius: float,
	dmg: float,
	combo_bonus: bool,
	applies: Array = [],
	attack_type: StringName = Combat.PHYSICAL,
	target_limit: int = 0,
	contacts: Variant = null,
	continuing: Callable = Callable()
) -> int:
	var chance: float = (
		p.crit_chance + (p.abilities.add("crit-add") if p.abilities != null else 0.0)
	)
	var se: Dictionary = p.design.get("status-effects", {})
	p._hit_stealth = p.stealth
	if not p.defence.is_empty():
		var sl: Dictionary = p.defence["stealth"]
		dmg *= 1.0 + p.stealth * float(sl["attack-mult-at-full"])
		chance += p.stealth * float(sl["crit-add-at-full"])
	var bodies: Array = p.bodies_within(center, radius) if contacts == null else contacts
	if target_limit > 0:
		bodies = bodies.slice(0, target_limit)
	return _strike_bodies(
		p, tiers, bodies, chance, dmg, combo_bonus, applies, attack_type, se, continuing
	)


static func _strike_bodies(
	p,
	tiers: Array[StringName],
	bodies: Array,
	chance: float,
	dmg: float,
	combo_bonus: bool,
	applies: Array,
	attack_type: StringName,
	se: Dictionary,
	continuing: Callable
) -> int:
	var hits: int = 0
	var tier := -1
	var tier_at := Vector3.ZERO
	for body in bodies:
		var result := _strike_contact(
			p,
			tiers,
			body,
			chance,
			dmg,
			combo_bonus,
			applies,
			attack_type,
			se,
			continuing,
			tier,
			tier_at
		)
		if result.is_empty():
			return 0  # The original strike's native int default, not partial hits.
		match result[0]:
			0:
				break  # Pre-contact cancellation still runs the epilogue.
			1:
				continue
			2:
				return hits + 1  # Post-damage cancellation is terminal, before feedback/statuses.
		hits += 1
		tier = result[1]
		tier_at = result[2]
	return _finish_strike(p, tiers, hits, tier, tier_at)


# Contact result: [] native abort; [0] pre-break; [1] skip; [2,...] early cancel; [3,tier,at] hit.
static func _strike_contact(
	p,
	tiers: Array[StringName],
	body,
	chance: float,
	dmg: float,
	combo_bonus: bool,
	applies: Array,
	attack_type: StringName,
	se: Dictionary,
	continuing: Callable,
	tier: int,
	tier_at: Vector3
) -> Array:
	match _contact_guard(body, continuing):
		0:
			return []
		1:
			return [0]
		2:
			return [1]
		3:
			body.take_direct_damage(
				dmg * (p.abilities.mult("damage-mult") if p.abilities != null else 1.0), p
			)
			return [1]
	return _damage_contact(
		p,
		tiers,
		body,
		chance,
		dmg,
		combo_bonus,
		applies,
		attack_type,
		se,
		continuing,
		tier,
		tier_at
	)


static func _cancelled(continuing: Callable) -> bool:
	return continuing.is_valid() and not continuing.call()


static func _contact_guard(body, continuing: Callable) -> int:
	if _cancelled(continuing):
		return 1
	return _contact_kind(body)


static func _contact_kind(body) -> int:
	if not is_instance_valid(body) or body.is_queued_for_deletion():
		return 2
	if body.has_method("take_direct_damage"):
		return 3
	if body.get("dead"):
		return 2
	return 4


static func _damage_contact(
	p,
	tiers: Array[StringName],
	body,
	chance: float,
	dmg: float,
	combo_bonus: bool,
	applies: Array,
	attack_type: StringName,
	se: Dictionary,
	continuing: Callable,
	tier: int,
	tier_at: Vector3
) -> Array:
	var cm := Combat.crit_mult(chance, p._rng, p.crit)
	var d := dmg * (Combat.combo_mult(p.combo, p.combat) if combo_bonus else 1.0) * cm
	if p.abilities != null:
		d *= p.abilities.mult("damage-mult")
	d = Combat.after_defence(
		d, float(body.get("armor")), float(body.get("resistance")), attack_type, p.combat
	)
	var result := [3, tier, tier_at]
	var outcome := _damage_body(p, tiers, body, d, cm, continuing, result)
	return _settle_contact(p, body, applies, se, d, outcome, result)


static func _damage_body(
	p, tiers: Array[StringName], body, d: float, cm: float, continuing: Callable, result: Array
) -> int:
	var blocked := false
	if d > 0.0:
		var before: float = body.hp
		blocked = body.take_damage(d, p)
		if _cancelled(continuing):
			return 3
		if not _contact_feedback(p, tiers, body, before, cm, result):
			return 0
	return 2 if blocked else 1


static func _contact_feedback(
	p, tiers: Array[StringName], body, before: float, cm: float, result: Array
) -> bool:
	if p.feel != null and before > body.hp:
		var kind: StringName = &"crit" if cm > 1.0 else &"hit"
		p.feel.number(body.head(), before - body.hp, kind)
		var rank: int = tiers.find(&"kill" if body.dead else kind)
		if rank > result[1]:
			result[1] = rank
			result[2] = body.head()
	return true


static func _hit_statuses(p, body, applies: Array, se: Dictionary, d: float) -> bool:
	for id in applies:
		if se.has(id) and body.has_method("apply_status"):
			body.apply_status(id, se[id], d, p)
	return true


static func _finish_strike(
	p, tiers: Array[StringName], hits: int, tier: int, tier_at: Vector3
) -> int:
	if tier >= 0:
		p.feel.play(tiers[tier], tier_at)
	if hits > 0 and not (p.abilities != null and p.abilities.flag("stealth-full")):
		p.stealth = 0.0
	return hits


static func _settle_contact(
	p, body, applies: Array, se: Dictionary, d: float, outcome: int, result: Array
) -> Array:
	if outcome == 0:
		result.clear()
		return result
	if outcome == 3:
		result[0] = 2
		return result
	if outcome != 2:
		if not _hit_statuses(p, body, applies, se, d):
			result.clear()
			return result
	return result
