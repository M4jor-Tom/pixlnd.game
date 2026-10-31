## Typed ingestion; constructors and closed vocabularies belong to the public facade.
extends RefCounted


static func creatures(
	o, name: String, data: Dictionary, types: Dictionary, vocabulary: Dictionary
) -> void:
	for id in o._typed_rows(name, data):
		var c = types.Creature.new()
		o._fill(c, id, data[id])
		c.alpha_entity_id = int(data[id].get("aid", -1) if data[id].get("aid") != null else -1)
		c.family = StringName(str(data[id].get("family", "")))
		c.category = (
			{
				"animal": vocabulary.CreatureCategory.ANIMAL,
				"insect": vocabulary.CreatureCategory.INSECT,
				"aquatic": vocabulary.CreatureCategory.AQUATIC,
				"plant-creature": vocabulary.CreatureCategory.PLANT_CREATURE,
				"monster": vocabulary.CreatureCategory.MONSTER,
				"undead": vocabulary.CreatureCategory.UNDEAD,
				"demon": vocabulary.CreatureCategory.DEMON,
				"elemental": vocabulary.CreatureCategory.ELEMENTAL,
				"humanoid": vocabulary.CreatureCategory.HUMANOID,
				"boss-species": vocabulary.CreatureCategory.BOSS_SPECIES,
				"static-target": vocabulary.CreatureCategory.STATIC_TARGET
			}
			. get(str(data[id].get("cat", "unused")), vocabulary.CreatureCategory.UNUSED)
		)
		c.hostility = StringName(str(data[id].get("h", "P")).left(1))  # "P (rarely H)" → base letter
		c.lands.assign(data[id].get("lands", []))
		var g: Variant = data[id].get("group")
		if g is Array and g.size() == 2:
			c.group_size = Vector2i(int(g[0]), int(g[1]))
		c.tame_food = StringName(
			str(data[id].get("tame", "") if data[id].get("tame") != null else "")
		)
		c.rideable = data[id].get("ride", false) == true
		c.boss_species = bool(data[id].get("boss", false))
		c.boss_capable = bool(data[id].get("bossable", false))
		c.drops.assign(data[id].get("drops", []))
		c.combat_role = combat_role(data[id].get("role"))
		o.creatures[id] = c


static func pet_food(
	o, name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._typed_rows(name, data.get("foods")):
		var row: Dictionary = data["foods"][id]
		var f = types.PetFood.new()
		o._fill(f, id, row)
		f.subtype = int(row.get("id", -1))
		f.tames = StringName(str(row.get("tames", "")))
		f.rideable = row.get("rideable", false) == true
		f.shop = bool(row.get("shop", false))
		o.pet_foods[id] = f


static func landscapes(
	o, name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._typed_rows(name, data):
		var l = types.Landscape.new()
		o._fill(l, id, data[id])
		l.climate = data[id].get("climate", {})
		l.hazards.assign(data[id].get("hazards", []))
		var dungeons: Variant = data[id].get("dungeons", [])
		if dungeons is Array:
			for dungeon in dungeons:
				if dungeon is String:
					l.dungeon_types.append(StringName(dungeon))
		# Malformed references stay in raw for cumulative validation.
		l.style = str(data[id].get("style", ""))
		l.gen = data[id].get("gen", {})
		o.landscapes[id] = l


static func status_effects(
	o, name: String, data: Dictionary, types: Dictionary, _vocabulary: Dictionary
) -> void:
	for id in o._typed_rows(name, data):
		if not data[id].has("kind"):
			continue
		var s = types.StatusEffect.new()
		o._fill(s, id, data[id])
		s.kind = StringName(str(data[id]["kind"]))
		s.sources.assign(data[id].get("sources", []))
		s.countered_by.assign(data[id].get("countered-by", []))
		o.status_effects[id] = s


static func combat_role(raw: Variant) -> StringName:
	var role := str(raw if raw != null else "")
	if role.contains("any-class"):
		return &"any-class"
	if role.contains("ranged"):
		return &"ranged"
	if role.contains("mage"):
		return &"mage"
	if role.contains("melee"):
		return &"melee"
	return &""
