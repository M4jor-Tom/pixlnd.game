## Typed ingestion; constructors and closed vocabularies belong to the public facade.
extends RefCounted


static func weapon_types(
	o, name: String, data: Dictionary, types: Dictionary, vocabulary: Dictionary
) -> void:
	for id in o._typed_rows(name, data):
		var w = types.WeaponType.new()
		o._fill(w, id, data[id])
		w.subtype = int(data[id].get("subtype", -1) if data[id].get("subtype") != null else -1)
		w.character_class = StringName(str(data[id].get("class", "")))
		w.hands = weapon_hands(data[id].get("hands"), vocabulary.Hands)
		w.damage_k = int(data[id].get("damage-k", 0))
		var capacity: Variant = data[id].get("cube-capacity")
		w.cube_capacity = int(capacity) if capacity is int or capacity is float else 0
		w.combo_cap = int(
			data[id].get("combo-cap", -1) if data[id].get("combo-cap") != null else -1
		)
		o.weapon_types[id] = w


static func materials(
	o, name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._typed_rows(name, data):
		var m = types.MaterialDef.new()
		o._fill(m, id, data[id])
		m.material_id = int(data[id].get("id", -1) if data[id].get("id") != null else -1)
		m.kind = StringName(str(data[id].get("kind", "")))
		m.obtainable = bool(data[id].get("obtainable", true))
		o.materials[id] = m


static func rarities(
	o, name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._typed_rows(name, data):
		if not data[id].has("index"):
			continue
		var r = types.RarityDef.new()
		o._fill(r, id, data[id])
		r.index = int(data[id]["index"])
		r.color = StringName(str(data[id].get("color", "")))
		r.stars = int(data[id].get("stars", 0) if data[id].get("stars") != null else 0)
		r.gem = StringName(str(data[id].get("gem", "") if data[id].get("gem") != null else ""))
		r.named = bool(data[id].get("named", false))
		o.rarities[id] = r


static func weapon_hands(raw: Variant, hands: Dictionary) -> int:
	var h: String = raw if raw is String else ""
	match h:
		"2h":
			return hands.TWO_HANDED
		"offhand":
			return hands.OFFHAND
		"1h", "1h dual (need two)":
			return hands.ONE_HANDED
	return hands.NONE
