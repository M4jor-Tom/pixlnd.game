## Ordered combat validation, called through the concrete ontology.
extends RefCounted
const Inputs := preload("res://ontology/model_inputs.gd")
const Movesets := preload("res://ontology/model_movesets.gd")
const Presentation := preload("res://ontology/model_presentation.gd")
const Equipment := preload("res://ontology/model_equipment.gd")


static func ability_fields_valid(o, row: Dictionary, path: String) -> bool:
	var valid: bool = o._optional_fields_valid(
		row,
		path,
		{
			"object": "cost throw strike",
			"number": "cooldown-s distance radius duration-s cast-s heal-pct stealth-per-s"
		}
	)
	return channel_fields(o, row, path, valid)


static func role_fields_valid(o, row: Dictionary, path: String) -> bool:
	var valid = o._optional_fields_valid(
		row,
		path,
		{
			"number": "range keep-away windup-s cooldown-s damage-mult",
			"object": "shot",
			"strings": "applies",
			"string": "kind sfx color"
		}
	)
	if row.get("shot") is Dictionary and not o._moveset_fields_valid(row.shot, path + ".shot"):
		valid = false
	return valid


static func moveset_fields_valid(o, row: Dictionary, path: String) -> bool:
	return Movesets.fields_valid(o, row, path)


static func validate_combat_floor(o, design: Dictionary) -> bool:
	var combat: Variant = design.get("combat")
	if not combat is Dictionary:
		o.errors.append("design.combat: required object missing or malformed")
	else:
		combat_floor_fields(o, combat)
	return Equipment.validate_gear_inputs(o, design)


static func validate_dot(o, design: Dictionary, ab: Dictionary, stamina_max: float) -> bool:
	# c-combat-burning-applications / c-combat-poison-applications: required selected inputs.
	var dot_config: Variant = design.get("status-effects")
	var se: Dictionary = {}
	if not dot_config is Dictionary:
		o.errors.append("design.status-effects: required object missing or malformed")
	else:
		se = dot_config
	for id in ["burning", "poison"]:
		dot_selected_row(o, id, se.get(id))
	for id in se:
		dot_reference(o, id, se)
	return validate_movesets(o, design, ab, stamina_max, se)


static func validate_movesets(
	o, design: Dictionary, ab: Dictionary, stamina_max: float, se: Dictionary
) -> bool:
	return Movesets.validate_movesets(o, design, ab, stamina_max, se)


static func _shot_errors(s: Dictionary, where: String) -> Array:
	return Movesets._shot_errors(s, where)


static func validate_ability_runtime(
	o, a, ab: Dictionary, stamina_max: float, runtimes: Array
) -> bool:
	var r = ab.get(a.id)
	if runtime_selected(o, a, r, runtimes):
		if o._ability_fields_valid(r, "design.abilities.%s" % a.id):
			return runtime_values(o, a, r, stamina_max)
	return true


static func runtime_selected(o, a, r: Variant, runtimes: Array) -> bool:
	if not r is Dictionary or not (str(r.get("runtime")) in runtimes):
		o.errors.append("design.abilities.%s: missing or unknown runtime" % a.id)
		return false
	return true


static func runtime_values(o, a, r: Dictionary, stamina_max: float) -> bool:
	if runtime_cooldown(o, a, r):
		if runtime_costs(o, a, r, stamina_max):
			return o._validate_runtime_kind(a, r)
	return false


static func unseen_runtime_node(id: StringName, column: String, seen: Dictionary) -> bool:
	if column != "class" and column != "ultimate" or seen.has(id):
		return false
	seen[id] = true
	return true


static func moveset_coverage(
	o, class_id, weapon, hands: int, offhand: int, movesets: Dictionary
) -> void:
	if hands != offhand and not movesets.has(weapon):
		o.errors.append(
			"design.movesets: class %s weapon-type %s has no entry" % [class_id, weapon]
		)


static func validate_defence_dodge(
	o, design: Dictionary, ab: Dictionary, stamina_max: float, se: Dictionary
) -> bool:
	var df = o._object(design.get("defence"))  # c-defence-config (D23)
	var dg = o._object(df.get("dodge"))
	if o._fields_valid(
		df.get("dodge"),
		"design.defence.dodge",
		{"number": "stamina distance duration-s iframe-s", "object": "on-dodge"}
	):
		dodge_values(o, dg, stamina_max)
		return o._validate_dodge_passives(design, ab, stamina_max, se, df, dg)
	return validate_defence_block(o, design, ab, se, df)


static func validate_defence_block(
	o, design: Dictionary, ab: Dictionary, se: Dictionary, df: Dictionary
) -> bool:
	block_rules(o, df)
	stealth_rules(o, df)
	enemy_hit_rules(o, df)
	stealth_ability_rules(o, ab)
	return Presentation.validate_feel(o, design, se)


static func dodge_ability_exists(o, id) -> bool:
	if not o.abilities.has(id):
		o.errors.append("design.defence.dodge.on-dodge.%s is not a passive" % id)
		return false
	return true


static func dodge_ability_kind(o, id, kind: int, passive: int) -> void:
	if kind != passive:
		o.errors.append("design.defence.dodge.on-dodge.%s is not a passive" % id)


static func stamina_max(o, design: Dictionary) -> float:
	var stamina_input: Variant = o._object(o._object(design.get("movement")).get("stamina")).get(
		"max"
	)
	return (
		float(stamina_input)
		if o._input_shape(stamina_input, "number", "design.movement.stamina.max")
		else 0.0
	)


static func channel_fields(o, row: Dictionary, path: String, valid: bool) -> bool:
	if row.get("runtime") == "channel":
		return channel_values(o, row, path, valid)
	return cost_fields(o, row, path, valid)


static func channel_values(o, row: Dictionary, path: String, valid: bool) -> bool:
	for field in ["turns-per-s", "drain-per-s"]:
		if o._input_shape(row.get(field), "number", path + "." + field):
			var outside: bool = (
				float(row[field]) < 0.0 or (field == "turns-per-s" and row[field] == 0)
			)
			valid = channel_result(o, outside, path, field, valid)
		else:
			valid = false
	return cost_fields(o, row, path, valid)


static func cost_fields(o, row: Dictionary, path: String, valid: bool) -> bool:
	if row.get("cost") is Dictionary:
		for key in row.cost:
			if not cost_field(o, row.cost[key], path, key):
				valid = false
	return ability_effect_fields(o, row, path, valid)


static func cost_field(o, value: Variant, path: String, key: Variant) -> bool:
	return (
		(value is String and value == "all")
		or o._input_shape(value, "number", path + ".cost." + str(key))
	)


static func ability_effect_fields(o, row: Dictionary, path: String, valid: bool) -> bool:
	if not strike_fields(o, row, path):
		valid = false
	if not throw_fields(o, row, path):
		valid = false
	if not o._moveset_fields_valid(row, path):
		valid = false
	return valid


static func strike_fields(o, row: Dictionary, path: String) -> bool:
	if row.get("strike") is Dictionary:
		return o._fields_valid(row.strike, path + ".strike", {"number": "radius"})
	return true


static func throw_fields(o, row: Dictionary, path: String) -> bool:
	if row.get("throw") is Dictionary:
		return o._moveset_fields_valid(row.throw, path + ".throw")
	return true


static func role_statuses(
	r: Dictionary, where: String, se: Dictionary, alpha_sfx: Array, feel_sfx: Dictionary, out: Array
) -> Array:
	for sid in r.get("applies", []):
		if not se.has(sid):
			out.append("%s: applies %s has no design.status-effects entry" % [where, sid])
	return role_presentation(r, where, alpha_sfx, feel_sfx, out)


static func combat_floor_fields(o, combat: Dictionary) -> void:
	var innate_resistance: Variant = combat.get("creature-resistance")
	if (not innate_resistance is float and not innate_resistance is int) or innate_resistance != 0:
		(
			o
			. errors
			. append(
				"design.combat.creature-resistance: must equal selected unequipped creature/NPC innate Resistance 0"
			)
		)
	if not o._is_selected_multiplier(combat.get("armor-floor"), 0.1):
		o.errors.append("design.combat.armor-floor: must equal selected 0.1 hit-damage floor")


static func dot_selected_row(o, id: String, row: Variant) -> void:
	var path: String = "design.status-effects." + id
	if not row is Dictionary:
		o.errors.append(path + ": required object missing or malformed")
		return
	var selected = (
		{"duration-s": 4.0, "tick-s": 0.5, "pct-of-hit": 0.1}
		if id == "burning"
		else {"duration-s": 5.0, "tick-s": 1.0, "pct-of-hit": 1.0}
	)
	dot_values(o, row, path, selected)
	if dot_route_outside(id, row):
		o.errors.append(path + ".as: must route to burning DOT behavior")


static func dot_reference(o, id, se: Dictionary) -> void:
	if str(id).begins_with("_"):
		return
	if not o.status_effects.has(id):
		o.errors.append("design.status-effects.%s is not a status-effect" % id)
	elif not se[id] is Dictionary:
		o.errors.append("design.status-effects.%s: malformed object" % id)
	else:
		dot_alias(o, id, se[id], se)


static func runtime_costs(o, a, r: Dictionary, stamina_max: float) -> bool:
	for res in r.get("cost", {}):
		var v = r["cost"][res]
		var cap = 100.0 if str(res) == "mp" else stamina_max
		if not runtime_cost_valid(v, cap):
			o.errors.append(
				"design.abilities.%s: cost %s = %s outside [0, %d] / 'all'" % [a.id, res, v, cap]
			)

	return true


static func block_rules(o, df: Dictionary) -> void:
	var bl = o._object(df.get("block"))
	if o._fields_valid(
		df.get("block"),
		"design.defence.block",
		{"number": "max power-per-hit damage-reduction front-dot regen-per-s guardian-mult"}
	):
		block_values(o, bl)


static func stealth_rules(o, df: Dictionary) -> void:
	var sl = o._object(df.get("stealth"))
	if o._fields_valid(
		df.get("stealth"), "design.defence.stealth", {"number": "decay-per-s still-mult aggro-cut"}
	):
		if float(sl["decay-per-s"]) < 0.0 or float(sl["still-mult"]) < 1.0:
			o.errors.append("design.defence.stealth: decay-per-s >= 0, still-mult >= 1")
		if float(sl["aggro-cut"]) < 0.0 or float(sl["aggro-cut"]) > 1.0:
			o.errors.append("design.defence.stealth.aggro-cut outside [0,1]")


static func enemy_hit_rules(o, df: Dictionary) -> void:
	for k in o._object(df.get("enemy-hit")):
		var value: Variant = df["enemy-hit"][k]
		if (
			o._input_shape(value, "number", "design.defence.enemy-hit." + str(k))
			and (value < 0 or value > 1)
		):
			o.errors.append("design.defence.enemy-hit.%s outside [0,1]" % k)


static func stealth_ability_rules(o, ab: Dictionary) -> void:
	for id in ab:
		stealth_ability_row(o, id, ab[id])


static func role_presentation(
	r: Dictionary, where: String, alpha_sfx: Array, feel_sfx: Dictionary, out: Array
) -> Array:
	var sfx_id = str(r.get("sfx", ""))
	if not alpha_sfx.has(sfx_id):
		out.append("%s: sfx %s is not an audio.json sfx-alpha-ids entry" % [where, sfx_id])
	elif not feel_sfx.has(sfx_id):
		out.append("%s: sfx %s has no design.feel.sfx entry" % [where, sfx_id])
	if not Color.html_is_valid(str(r.get("color", ""))):
		out.append("%s: color is not a valid html colour" % where)
	return out


static func runtime_cooldown(o, a, r: Dictionary) -> bool:
	if float(r.get("cooldown-s", 0)) <= 0.0:
		o.errors.append("design.abilities.%s: cooldown-s must be > 0" % a.id)

	return true


static func dodge_values(o, dg: Dictionary, stamina_max: float) -> void:
	if float(dg["stamina"]) <= 0.0 or float(dg["stamina"]) > stamina_max:
		o.errors.append("design.defence.dodge.stamina outside (0, %d]" % stamina_max)
	if (
		float(dg["distance"]) <= 0.0
		or float(dg["duration-s"]) <= 0.0
		or float(dg["iframe-s"]) < 0.0
	):
		o.errors.append("design.defence.dodge: distance / duration-s > 0, iframe-s >= 0")


static func channel_result(o, outside: bool, path: String, field: String, valid: bool) -> bool:
	if outside:
		o.errors.append(
			path + "." + field + ": must be " + ("> 0" if field == "turns-per-s" else ">= 0")
		)
		return false
	return valid


static func dot_values(o, row: Dictionary, path: String, selected: Dictionary) -> void:
	for field in selected:
		var value: Variant = row.get(field)
		if not selected_dot_number(value, selected[field]):
			o.errors.append(
				path + "." + field + ": must equal selected value " + str(selected[field])
			)


static func selected_dot_number(value: Variant, expected: float) -> bool:
	return Inputs.number(value) and value == expected


static func dot_route_outside(id: String, row: Dictionary) -> bool:
	return (id == "poison" and row.get("as") != "burning") or (id == "burning" and row.has("as"))


static func dot_alias(o, id, row: Dictionary, se: Dictionary) -> void:
	if row.has("as") and not se.has(str(row["as"])):
		o.errors.append("design.status-effects.%s: `as` %s has no entry" % [id, row["as"]])


static func runtime_cost_valid(value: Variant, cap: float) -> bool:
	return (
		str(value) == "all"
		or ((value is float or value is int) and float(value) >= 0.0 and float(value) <= cap)
	)


static func runtime_area(o, a, r: Dictionary) -> bool:
	if float(r.get("radius", 0)) <= 0.0:
		o.errors.append("design.abilities.%s: radius must be > 0" % a.id)
	if str(r["runtime"]) == "channel" and float(r.get("duration-s", 0)) <= 0.0:
		o.errors.append("design.abilities.%s: duration-s must be > 0" % a.id)

	return true


static func runtime_heal(o, a, r: Dictionary) -> bool:
	if float(r.get("cast-s", -1)) < 0.0 or float(r.get("heal-pct", 0)) <= 0.0:
		o.errors.append("design.abilities.%s: heal needs cast-s >= 0 and heal-pct > 0" % a.id)

	return true


static func block_values(o, bl: Dictionary) -> void:
	if float(bl["max"]) <= 0.0 or float(bl["power-per-hit"]) <= 0.0:
		o.errors.append("design.defence.block: max / power-per-hit must be > 0")
	if float(bl["damage-reduction"]) < 0.0 or float(bl["damage-reduction"]) > 1.0:
		o.errors.append("design.defence.block.damage-reduction outside [0,1]")
	if absf(float(bl["front-dot"])) > 1.0:
		o.errors.append("design.defence.block.front-dot outside [-1,1]")
	if float(bl["regen-per-s"]) < 0.0 or float(bl["guardian-mult"]) < 1.0:
		o.errors.append("design.defence.block: regen-per-s >= 0, guardian-mult >= 1")


static func stealth_ability_row(o, id, raw: Variant) -> void:
	if (
		raw is Dictionary
		and raw.has("stealth-per-s")
		and o._input_shape(
			raw["stealth-per-s"], "number", "design.abilities." + str(id) + ".stealth-per-s"
		)
		and raw["stealth-per-s"] < 0
	):
		o.errors.append("design.abilities.%s.stealth-per-s < 0" % id)


# True means processed/skipped normally; native failure alone stops the old validate scope.
static func process_runtime_node(
	o, a, column: String, seen: Dictionary, ab: Dictionary, stamina_max: float, runtimes: Array
) -> bool:
	if unseen_runtime_node(a.id, column, seen):
		return validate_ability_runtime(o, a, ab, stamina_max, runtimes)
	return true
