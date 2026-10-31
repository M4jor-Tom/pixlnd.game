## Typed ingestion; constructors and closed vocabularies belong to the public facade.
extends RefCounted


static func consumables(
	o, name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._typed_rows(name, data):
		if not data[id].has("kind"):
			continue
		var c = types.Consumable.new()
		o._fill(c, id, data[id])
		c.kind = StringName(str(data[id]["kind"]))
		c.use = StringName(str(data[id].get("use", "")))
		c.heal_mult = int(data[id].get("heal-mult", 0))
		c.duration_s = int(data[id].get("duration-s", 0))
		c.recipe = (data[id].get("recipe", {}) if data[id].get("recipe") is Dictionary else {})
		c.station = str(data[id].get("station", ""))
		o.consumables[id] = c


static func key_items(
	o, name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._typed_rows(name, data):
		if not data[id].has("group"):
			continue
		var k = types.KeyItem.new()
		o._fill(k, id, data[id])
		k.group = StringName(str(data[id]["group"]))
		o.key_items[id] = k


static func rulesets(
	o, name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._typed_rows(name, data):
		var r = types.Ruleset.new()
		o._fill(r, id, data[id])
		r.flags = data[id].get("flags", {})
		r.is_default = bool(data[id].get("default", false))
		o.rulesets[id] = r
