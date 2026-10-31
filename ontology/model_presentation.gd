## Ordered presentation validation; direct tails retain the original validate failure domain.

extends RefCounted

const Inputs := preload("res://ontology/model_inputs.gd")


static func validate_android(o) -> void:
	var path = "controller-profiles.android"
	var profiles: Variant = o.configs.get("controller-profiles")
	if not profiles is Dictionary or not profiles.get("android") is Dictionary:
		o.errors.append(path + ": required object missing or malformed")
		return
	var a: Dictionary = profiles["android"]
	android_policy(o, a, path)
	android_actions(o, a, path)


static func android_actions(o, a: Dictionary, path: String) -> void:
	var actions: Variant = a.get("actions")
	var required = [
		"move",
		"look",
		"zoom",
		"sprint",
		"jump",
		"swim-ascent",
		"basic-attack",
		"special-attack",
		"block",
		"dodge",
		"class-skill-1",
		"class-skill-2",
		"class-skill-3",
		"class-skill-4",
		"interact",
		"pick-up",
		"quick-item",
		"inventory",
		"skills-window",
		"ui-cancel",
		"equip-item",
		"use-inventory-item",
		"spend-skill-point",
		"buy-item",
		"sell-item",
		"world-map"
	]
	if not actions is Array or actions.size() != required.size():
		o.errors.append(path + ".actions: required distinct first-slice action array")
		return
	for action in required:
		if actions.count(action) != 1:
			o.errors.append(path + ".actions: required unique canonical action " + action)


static func required_events(o, ev: Dictionary) -> void:
	for id in [
		"hit",
		"crit",
		"kill",
		"hurt",
		"block",
		"dodge",
		"shoot",
		"impact",
		"level-up",
		"pickup",
		"coin"
	]:
		if not ev.has(id):
			o.errors.append("design.feel.events missing required event %s" % id)


static func android_policy(o, a: Dictionary, path: String) -> void:
	var selected = {"deadzone-ratio": 0.15, "min-target-dp": 48, "look-deg-per-safe-width": 180}
	for field in selected:
		var value: Variant = a.get(field)
		var expected: float = selected[field]
		if not Inputs.number(value) or value != expected:
			o.errors.append(path + "." + field + ": must equal selected policy " + str(expected))


static func event_sound(o, id, e: Dictionary, alpha_sfx: Array, sfx: Dictionary) -> void:
	var sid = str(e.get("sfx", ""))
	if not alpha_sfx.has(sid):
		o.errors.append(
			"design.feel.events.%s.sfx %s is not an audio.json sfx-alpha-ids entry" % [id, sid]
		)
	elif not sfx.has(sid):
		o.errors.append("design.feel.events.%s.sfx %s has no design.feel.sfx entry" % [id, sid])


static func validate_feel(o, design: Dictionary, se: Dictionary) -> bool:
	var fl = o._object(design.get("feel"))  # c-feel-config (D25)
	var hs = o._object(fl.get("hit-stop"))
	var sh = o._object(fl.get("shake"))
	var nb = o._object(fl.get("numbers"))
	var im = o._object(fl.get("impact"))
	var tr = o._object(fl.get("trail"))
	var lv = o._object(fl.get("level-up"))
	var ev = o._object(fl.get("events"))
	var sfx = o._object(fl.get("sfx"))
	var alpha_sfx = o._array(o._object(o.configs.get("audio")).get("sfx-alpha-ids"))
	return hit_stop(o, design, se, fl, hs, sh, nb, im, tr, lv, ev, sfx, alpha_sfx)


static func hit_stop(
	o,
	design: Dictionary,
	se: Dictionary,
	fl: Dictionary,
	hs: Dictionary,
	sh: Dictionary,
	nb: Dictionary,
	im: Dictionary,
	tr: Dictionary,
	lv: Dictionary,
	ev: Dictionary,
	sfx: Dictionary,
	alpha_sfx: Array
) -> bool:
	if o._fields_valid(fl.get("hit-stop"), "design.feel.hit-stop", {"number": "time-scale max-s"}):
		if float(hs["time-scale"]) <= 0.0 or float(hs["time-scale"]) >= 1.0:
			o.errors.append("design.feel.hit-stop.time-scale outside (0,1)")
		if float(hs["max-s"]) <= 0.0 or float(hs["max-s"]) > 1.0:
			o.errors.append("design.feel.hit-stop.max-s outside (0,1]")
	return shake(o, design, se, fl, hs, sh, nb, im, tr, lv, ev, sfx, alpha_sfx)


static func shake(
	o,
	design: Dictionary,
	se: Dictionary,
	fl: Dictionary,
	hs: Dictionary,
	sh: Dictionary,
	nb: Dictionary,
	im: Dictionary,
	tr: Dictionary,
	lv: Dictionary,
	ev: Dictionary,
	sfx: Dictionary,
	alpha_sfx: Array
) -> bool:
	if o._fields_valid(
		fl.get("shake"),
		"design.feel.shake",
		{"number": "decay-per-s max-offset shake-mult max-roll-deg"}
	):
		if float(sh["decay-per-s"]) <= 0.0:
			o.errors.append("design.feel.shake.decay-per-s must be > 0")
		if float(sh["max-offset"]) < 0.0:
			o.errors.append("design.feel.shake.max-offset must be >= 0")
		if float(sh["shake-mult"]) < 0.0:
			o.errors.append("design.feel.shake.shake-mult must be >= 0")
		if float(sh["max-roll-deg"]) < 0.0:
			o.errors.append("design.feel.shake.max-roll-deg must be >= 0")
	required_events(o, ev)
	return events(o, design, se, fl, hs, nb, im, tr, lv, ev, sfx, alpha_sfx)


static func events(
	o,
	design: Dictionary,
	se: Dictionary,
	fl: Dictionary,
	hs: Dictionary,
	nb: Dictionary,
	im: Dictionary,
	tr: Dictionary,
	lv: Dictionary,
	ev: Dictionary,
	sfx: Dictionary,
	alpha_sfx: Array
) -> bool:
	for id in ev:
		var event_path = "design.feel.events." + str(id)
		if not o._input_shape(ev[id], "object", event_path):
			continue
		var e: Dictionary = ev[id]
		if o._optional_fields_valid(
			e, event_path, {"number": "hit-stop-s trauma", "string": "sfx"}
		):
			event_hit_stop(o, id, float(e.get("hit-stop-s", 0)), e, hs)
			event_trauma(o, id, float(e.get("trauma", 0)), e)
			event_sound(o, id, e, alpha_sfx, sfx)
	return sounds(o, design, se, fl, nb, im, tr, lv, sfx)


static func sounds(
	o,
	design: Dictionary,
	se: Dictionary,
	fl: Dictionary,
	nb: Dictionary,
	im: Dictionary,
	tr: Dictionary,
	lv: Dictionary,
	sfx: Dictionary
) -> bool:
	for id in sfx:
		if not o._fields_valid(
			sfx[id], "design.feel.sfx." + str(id), {"number": "hz len-s noise slide"}
		):
			continue
		var sd: Dictionary = sfx[id]
		sound_positive(o, id, float(sd.get("hz", 0)))
		sound_range(o, id, float(sd.get("len-s", 0)), sd, "len-s")
		sound_range(o, id, float(sd.get("noise", 0)), sd, "noise")
	return numbers(o, design, se, fl, nb, im, tr, lv)


static func numbers(
	o,
	design: Dictionary,
	se: Dictionary,
	fl: Dictionary,
	nb: Dictionary,
	im: Dictionary,
	tr: Dictionary,
	lv: Dictionary
) -> bool:
	if o._fields_valid(
		fl.get("numbers"),
		"design.feel.numbers",
		{"number": "life-s crit-scale rise-blocks font-size"}
	):
		if float(nb["life-s"]) <= 0.0:
			o.errors.append("design.feel.numbers.life-s must be > 0")
		if float(nb["crit-scale"]) < 1.0:
			o.errors.append("design.feel.numbers.crit-scale must be >= 1")
		if float(nb["rise-blocks"]) <= 0.0:
			o.errors.append("design.feel.numbers.rise-blocks must be > 0")
		if int(nb["font-size"]) <= 0:
			o.errors.append("design.feel.numbers.font-size must be > 0")
	return number_colours(o, design, se, fl, nb, im, tr, lv)


static func number_colours(
	o,
	design: Dictionary,
	se: Dictionary,
	fl: Dictionary,
	nb: Dictionary,
	im: Dictionary,
	tr: Dictionary,
	lv: Dictionary
) -> bool:
	var colours = o._object(nb.get("colours"))
	if not colours.has("hit"):
		o.errors.append("design.feel.numbers.colours: required hit fallback")
	for k in colours:
		o._input_shape(colours[k], "colour", "design.feel.numbers.colours." + str(k))
	return impact(o, design, se, fl, im, tr, lv)


static func impact(
	o,
	design: Dictionary,
	se: Dictionary,
	fl: Dictionary,
	im: Dictionary,
	tr: Dictionary,
	lv: Dictionary
) -> bool:
	if o._fields_valid(
		fl.get("impact"), "design.feel.impact", {"number": "impact-s impact-radius"}
	):
		if float(im["impact-s"]) <= 0.0:
			o.errors.append("design.feel.impact.impact-s must be > 0")
		if float(im["impact-radius"]) <= 0.0:
			o.errors.append("design.feel.impact.impact-radius must be > 0")
	return trail(o, design, se, fl, tr, lv)


static func trail(
	o, design: Dictionary, se: Dictionary, fl: Dictionary, tr: Dictionary, lv: Dictionary
) -> bool:
	if o._fields_valid(fl.get("trail"), "design.feel.trail", {"number": "trail-s trail-every-s"}):
		if float(tr["trail-s"]) <= 0.0:
			o.errors.append("design.feel.trail.trail-s must be > 0")
		if float(tr["trail-every-s"]) <= 0.0:
			o.errors.append("design.feel.trail.trail-every-s must be > 0")
	return level_up(o, design, se, fl, lv)


static func level_up(o, design: Dictionary, se: Dictionary, fl: Dictionary, lv: Dictionary) -> bool:
	if o._fields_valid(
		fl.get("level-up"), "design.feel.level-up", {"number": "pop-s pop-scale", "string": "text"}
	):
		if float(lv["pop-s"]) <= 0.0:
			o.errors.append("design.feel.level-up.pop-s must be > 0")
		if float(lv["pop-scale"]) < 1.0:
			o.errors.append("design.feel.level-up.pop-scale must be >= 1")
		if str(lv["text"]).is_empty():
			o.errors.append("design.feel.level-up.text must not be empty")
	return o._validate_creature_roles(design, se, fl)


# First conversions stay in the encompassing phase; later reads keep the original short circuit.
static func event_hit_stop(o, id, first: float, e: Dictionary, hs: Dictionary) -> void:
	if event_hit_stop_outside(first, e, hs):
		o.errors.append("design.feel.events.%s.hit-stop-s outside [0, max-s]" % id)


static func event_trauma(o, id, first: float, e: Dictionary) -> void:
	if first < 0.0 or float(e.get("trauma", 0)) > 1.0:
		o.errors.append("design.feel.events.%s.trauma outside [0,1]" % id)


static func event_hit_stop_outside(first: float, e: Dictionary, hs: Dictionary) -> bool:
	if first < 0.0:
		return true
	return (
		(hs.get("max-s") is int or hs.get("max-s") is float)
		and float(e.get("hit-stop-s", 0)) > float(hs["max-s"])
	)


static func sound_positive(o, id, first: float) -> void:
	if first <= 0.0:
		o.errors.append("design.feel.sfx.%s.hz must be > 0" % id)


static func sound_range(o, id, first: float, sd: Dictionary, field: String) -> void:
	var below: bool = first <= 0.0 if field == "len-s" else first < 0.0
	if below or float(sd.get(field, 0)) > 1.0:
		o.errors.append(
			(
				"design.feel.sfx.%s.%s outside %s"
				% [id, field, "(0,1]" if field == "len-s" else "[0,1]"]
			)
		)
