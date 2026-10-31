## Typed ingestion; constructors and closed vocabularies belong to the public facade.
extends RefCounted


static func races(
	o, _name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._rows(data):
		var r = types.Race.new()
		o._fill(r, id, data[id])
		r.playable = data[id].get("playable") is bool and data[id]["playable"]
		r.size_class = StringName(str(data[id].get("size-class", "normal")))
		o.races[id] = r


static func classes(
	o, name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._rows(data):
		var issues = o._identity_row_errors(name, data[id], name + "." + str(id))
		if not issues.is_empty():
			o.errors.append_array(issues)
			continue
		var c = types.CharacterClass.new()
		o._fill(c, id, data[id])
		c.id_number = int(data[id].get("id-number", 0))
		c.weapon_types.assign(data[id].get("weapon-types", []))
		c.armor_material = StringName(str(data[id].get("armor-material", "")))
		c.specializations.assign(data[id].get("specializations", []))
		c.special_attack_mode = StringName(str(data[id].get("special-attack-mode", "charged")))
		c.hp_mult = float(data[id].get("hp-mult", 1.0))
		o.classes[id] = c


static func specializations(
	o, name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._rows(data):
		var issues = o._identity_row_errors(name, data[id], name + "." + str(id))
		if not issues.is_empty():
			o.errors.append_array(issues)
			continue
		var s = types.Specialization.new()
		o._fill(s, id, data[id])
		s.character_class = StringName(str(data[id].get("class", "")))
		s.index = int(data[id].get("index", 0))
		s.kit_a.assign(data[id].get("kit", {}).get("A", []))
		s.kit_s.assign(data[id].get("kit", {}).get("S", []))
		s.passives_a.assign(data[id].get("passives", {}).get("A", []))
		s.passives_s.assign(data[id].get("passives", {}).get("S", []))
		o.specs[id] = s


static func abilities(
	o, name: String, data: Dictionary, types: Dictionary, vocabulary: Dictionary
) -> void:
	for id in o._rows(data):
		var issues = o._identity_row_errors(name, data[id], name + "." + str(id))
		if not issues.is_empty():
			o.errors.append_array(issues)
			continue
		var a = types.Ability.new()
		o._fill(a, id, data[id])
		a.kind = (
			{
				"active": vocabulary.AbilityKind.ACTIVE,
				"passive": vocabulary.AbilityKind.PASSIVE,
				"shared-passive": vocabulary.AbilityKind.SHARED_PASSIVE,
				"movement": vocabulary.AbilityKind.MOVEMENT
			}
			. get(str(data[id].get("kind", "active")), vocabulary.AbilityKind.ACTIVE)
		)
		a.owner = data[id].get("owner")
		a.input = data[id].get("input", {})
		a.cost = data[id].get("cost", {})
		a.cooldown_s = data[id].get("cooldown-s")
		a.duration_s = data[id].get("duration-s")
		a.effect = str(data[id].get("effect", ""))
		a.applies.assign(data[id].get("applies", []))
		a.alpha_ability_id = int(data[id].get("alpha-id", -1))
		a.alpha_tree = data[id].get("alpha-tree", {})
		o.abilities[id] = a
