## Moveset shape, projectile and finisher rules; traversal stays at the original phase.
extends RefCounted
const Inputs := preload("res://ontology/model_inputs.gd")


static func fields_valid(o, row: Dictionary, path: String) -> bool:
	var valid := numeric_fields(o, row, path)
	if row.has("pierce") and not row["pierce"] is bool:
		o.errors.append(path + ".pierce: boolean required")
		valid = false
	if not applies_fields(o, row.get("applies", []), path):
		valid = false
	return valid


static func numeric_fields(o, row: Dictionary, path: String) -> bool:
	var valid := true
	for field in [
		"damage-mult",
		"swing-mult",
		"radius-mult",
		"lunge",
		"range",
		"radius",
		"speed",
		"life-s",
		"count",
		"spread",
		"gravity",
		"splash",
		"tick-s",
		"every",
		"chance"
	]:
		if row.has(field):
			if not numeric_field(o, row[field], path + "." + field):
				valid = false
	return valid


static func numeric_field(o, value: Variant, path: String) -> bool:
	if not Inputs.finite_number(value):
		o.errors.append(path + ": finite number required")
		return false
	return true


static func applies_fields(o, applies: Variant, path: String) -> bool:
	var valid := true
	if not applies is Array:
		o.errors.append(path + ".applies: status ID array required")
		valid = false
	else:
		for id in applies:
			if not id is String:
				o.errors.append(path + ".applies: status ID string required")
				valid = false
	return valid


static func validate_movesets(
	o, design: Dictionary, ab: Dictionary, stamina_max: float, se: Dictionary
) -> bool:
	var input: Variant = design.get("movesets")
	var mv: Dictionary = input if input is Dictionary else {}
	moveset_roots(o, mv)
	var kinds_input: Variant = mv.get("kinds")
	var kinds: Array = kinds_input if kinds_input is Array else []
	moveset_kinds(o, kinds)
	for id in mv:
		if metadata(id):
			continue
		if moveset_entry(o, mv, id, kinds, se):
			continue
		return false
	return o._validate_moveset_coverage(design, ab, stamina_max, se, mv)


static func moveset_roots(o, mv: Dictionary) -> void:
	if mv.is_empty():
		o.errors.append("design.movesets: required nonempty object missing or malformed")
	if not mv.get("default") is Dictionary:
		o.errors.append("design.movesets.default: required object missing or malformed")


static func moveset_kinds(o, kinds: Array) -> void:
	if kinds.is_empty():
		o.errors.append("design.movesets.kinds: required nonempty array")
	for kind in kinds:
		if kind not in ["melee", "projectile", "beam", "at-cursor"]:
			o.errors.append("design.movesets.kinds: unknown or malformed kind " + str(kind))


static func metadata(id) -> bool:
	return str(id).begins_with("_") or str(id) == "kinds"


static func moveset_entry(o, mv: Dictionary, id, kinds: Array, se: Dictionary) -> bool:
	moveset_weapon_reference(o, id)
	if not mv[id] is Dictionary:
		o.errors.append("design.movesets.%s: entry object required" % id)
		return true
	var m: Dictionary = mv[id]
	if m.has("as"):
		moveset_alias(o, mv, id, m)
		return true
	for slot in ["m1", "m2"]:
		if moveset_slot(o, m.get(slot), "design.movesets.%s.%s" % [id, slot], kinds, se):
			continue
		return false

	return true


static func moveset_alias(o, mv: Dictionary, id, m: Dictionary) -> void:
	var target: Variant = mv.get(m["as"]) if m["as"] is String else null
	if not target is Dictionary or target.has("as") or str(m["as"]).begins_with("_"):
		o.errors.append("design.movesets.%s: `as` %s is not a plain entry" % [id, m["as"]])


static func moveset_slot(o, s: Variant, where: String, kinds: Array, se: Dictionary) -> bool:
	if not slot_fields(o, s, where, kinds):
		return true
	for id in s.get("applies", []):
		if not se.has(id):
			o.errors.append("%s: applies %s has no design.status-effects entry" % [where, id])
	if float(s.get("damage-mult", 1)) <= 0.0:
		o.errors.append("%s: damage-mult must be > 0" % where)
	return o._validate_moveset_kind(s, where, se)


static func slot_fields(o, s: Variant, where: String, kinds: Array) -> bool:
	if not s is Dictionary or not (str(s.get("kind")) in kinds):
		o.errors.append("%s: kind must be one of %s" % [where, kinds])
		return false
	return o._moveset_fields_valid(s, where)


# Completion, not validity: ordinary invalid/shape-rejected finishers still reach later slots.
static func melee_slot(o, s: Dictionary, where: String, se: Dictionary) -> bool:
	if (
		float(s.get("swing-mult", 1)) <= 0.0
		or float(s.get("radius-mult", 1)) <= 0.0
		or float(s.get("lunge", 0)) < 0.0
	):
		o.errors.append("%s: swing-mult, radius-mult > 0, lunge >= 0" % where)
	if s.has("finisher"):
		return finisher(o, s["finisher"], where, se)
	return true


static func finisher(o, value: Variant, where: String, se: Dictionary) -> bool:
	if not value is Dictionary:
		o.errors.append(where + ": finisher object required")
		return true
	var f: Dictionary = value
	if not o._moveset_fields_valid(f, where + ".finisher"):
		return true
	if not finisher_bounds(o, f, where):
		return false
	return finisher_statuses(o, f, where, se)


static func finisher_bounds(o, f: Dictionary, where: String) -> bool:
	if (
		int(f.get("every", 0)) < 2
		or float(f.get("chance", -1)) < 0.0
		or float(f.get("chance", -1)) > 1.0
	):
		o.errors.append("%s: finisher every >= 2, chance in [0,1]" % where)
	return true


# Array tails discard only this original shot-local result on a native abort.
static func _shot_errors(s: Dictionary, where: String) -> Array:
	var out: Array = []
	if (
		float(s.get("speed", 0)) <= 0.0
		or float(s.get("radius", 0)) <= 0.0
		or float(s.get("life-s", 0)) <= 0.0
	):
		out.append("%s: speed, radius, life-s must be > 0" % where)
	return shot_spread_errors(s, where, out)


static func shot_spread_errors(s: Dictionary, where: String, out: Array) -> Array:
	if (
		int(s.get("count", 1)) < 1
		or float(s.get("spread", 0)) < 0.0
		or float(s.get("gravity", 0)) < 0.0
		or float(s.get("splash", 0)) < 0.0
	):
		out.append("%s: count >= 1, spread / gravity / splash >= 0" % where)
	return shot_pierce_errors(s, where, out)


static func shot_pierce_errors(s: Dictionary, where: String, out: Array) -> Array:
	if s.get("pierce", false) and float(s.get("tick-s", 0)) <= 0.0:
		out.append("%s: pierce needs tick-s > 0" % where)
	return out


static func moveset_weapon_reference(o, id) -> void:
	if str(id) != "default" and not o.weapon_types.has(id):
		o.errors.append("design.movesets.%s is not a weapon-type" % id)


static func finisher_statuses(o, f: Dictionary, where: String, se: Dictionary) -> bool:
	for id in f.get("applies", []):
		if not se.has(id):
			o.errors.append(
				"%s: finisher applies %s has no design.status-effects entry" % [where, id]
			)
	return true
