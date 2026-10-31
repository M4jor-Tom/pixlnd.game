## Creature role defaults and species overrides.
extends RefCounted


static func validate_roles(o, design: Dictionary, se: Dictionary, fl: Dictionary) -> bool:
	var cr = o._object(design.get("creature-roles"))  # c-creature-roles (D26)
	if not cr.is_empty():
		var alpha_sfx2: Array = o._array(o._object(o.configs.get("audio")).get("sfx-alpha-ids"))
		var feel_sfx = o._object(fl.get("sfx"))
		var role_kinds = ["melee", "ranged", "mage"]
		default_role(o, cr, role_kinds)
		return role_weights(o, cr, role_kinds, se, alpha_sfx2, feel_sfx)
	return o._validate_defaults()


static func role_definitions(
	o, cr: Dictionary, role_kinds: Array, se: Dictionary, alpha_sfx2: Array, feel_sfx: Dictionary
) -> bool:
	if str(o._object(cr.get("melee")).get("kind", "")) != "melee":
		o.errors.append("design.creature-roles.melee.kind must be melee")
	for rid in ["ranged", "mage"]:
		o.errors.append_array(
			o._role_errors(
				o._object(cr.get(rid)), "design.creature-roles.%s" % rid, se, alpha_sfx2, feel_sfx
			)
		)
	return o._validate_species_roles(cr, se, alpha_sfx2, feel_sfx, role_kinds)


static func species_keys(o, sid, ov: Dictionary) -> void:
	var keys := [
		"range",
		"keep-away",
		"windup-s",
		"cooldown-s",
		"damage-mult",
		"shot",
		"applies",
		"sfx",
		"color"
	]
	for key in ov:
		if not keys.has(key):
			o.errors.append(
				"design.creature-roles.species.%s: unknown override key %s" % [sid, key]
			)


static func species_role(
	o,
	cr: Dictionary,
	sid,
	ov: Dictionary,
	role: String,
	kinds: Array,
	se: Dictionary,
	alpha_sfx: Array,
	feel_sfx: Dictionary
) -> void:
	if role not in kinds:
		role = str(cr.get("default", "melee"))
	var merged: Dictionary = o._object(cr.get(role)).duplicate(true)
	merged.merge(ov, true)
	if role == "melee":
		if str(merged.get("kind", "")) != "melee":
			o.errors.append("design.creature-roles.species.%s (merged): kind must be melee" % sid)
	else:
		o.errors.append_array(
			o._role_errors(
				merged, "design.creature-roles.species.%s (merged)" % sid, se, alpha_sfx, feel_sfx
			)
		)


static func role_weights(
	o, cr: Dictionary, role_kinds: Array, se: Dictionary, alpha_sfx: Array, feel_sfx: Dictionary
) -> bool:
	var ac = o._object(cr.get("any-class"))
	var w_sum = 0.0
	for k in ac:
		if not o._input_shape(ac[k], "number", "design.creature-roles.any-class." + str(k)):
			continue
		role_weight_key(o, k, role_kinds)
		if float(ac[k]) < 0.0:
			o.errors.append("design.creature-roles.any-class.%s must be >= 0" % k)
		w_sum += float(ac[k])
	if w_sum <= 0.0:
		o.errors.append("design.creature-roles.any-class weights must sum > 0")
	return role_definitions(o, cr, role_kinds, se, alpha_sfx, feel_sfx)


static func default_role(o, cr: Dictionary, role_kinds: Array) -> void:
	if str(cr.get("default", "")) not in role_kinds:
		o.errors.append("design.creature-roles.default must be one of %s" % [role_kinds])


static func role_weight_key(o, k, role_kinds: Array) -> void:
	if str(k) not in role_kinds:
		o.errors.append(
			"design.creature-roles.any-class key %s must be one of %s" % [k, role_kinds]
		)
