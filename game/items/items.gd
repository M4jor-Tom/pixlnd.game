## §3.4 generators, pure and static: gen-item, gen-item-stats, gen-name for items, gen-loot.
## Numbers: stats.json#alpha-item-stat-formulas, generators.json#design.gear-hp|loot|stack-cap.
## ponytail: gear regen/tempo/crit remain unapplied; implement their stat rules when selected (todo_implement.md).
extends RefCounted

const Domain := preload("res://game/domain/domain.gd")
const Item := preload("res://game/items/item.gd")
const GROUND := preload("res://game/items/ground_item.tscn")


## gen-item takes already-converted power; modifiers seed the roll (c-stat-roll) and name.
static func generate(
	rng: RandomNumberGenerator,
	type: StringName,
	subtype: StringName,
	material: StringName,
	power: int,
	rarity: int
) -> Item:
	var it := Item.new()
	it.type = type
	it.subtype = subtype
	it.material = material
	it.level = clampi(power, 1, 100)
	it.rarity = clampi(rarity, Domain.Rarity.COMMON, Domain.Rarity.LEGENDARY)  # c-rarity-range
	it.modifier = rng.randi()
	it.minus_modifier = rng.randi()
	return it


## gen-item-stats damage = curve(level, rarity) × weapon-type k. The roll does not touch damage.
static func damage(it: Item, o: Domain.Ontology) -> float:
	if it.type != &"weapon":
		return 0.0
	return Domain.stat_curve(it.level, it.rarity) * o.weapon_types[it.subtype].slot_damage_k


## gen-item-stats armor = curve × slot mult (chest 1.0, other 0.5) × material armor-mult.
static func armor(it: Item, o: Domain.Ontology) -> float:
	return _defence_stat(it, o, "slot_armor_mult", 1.0)


static func resistance(it: Item, o: Domain.Ontology) -> float:
	return _defence_stat(it, o, "slot_resi_mult", null)


## Hybrid fixed HP: only HP-bearing slots, independent of either modifier (c-gear-hp).
static func hp(it: Item, o: Domain.Ontology) -> float:
	if it.type not in [&"weapon", &"chest-armor", &"shoulder-armor", &"gloves", &"boots"]:
		return 0.0
	var slot := slot_id(it, o)
	if slot not in [&"main-hand", &"off-hand", &"chest", &"shoulders", &"gloves", &"boots"]:
		return 0.0
	return _hp_in_slot(it, o, slot)


static func _hp_in_slot(it: Item, o: Domain.Ontology, slot: StringName) -> float:
	for s in o.configs["equipment-slots"]["slots"]:
		if StringName(s["id"]) == slot and s.has("hp-mult"):
			return _slot_hp(it, o, s)
	return 0.0


static func _slot_hp(it: Item, o: Domain.Ontology, s) -> float:
	var cfg: Dictionary = o.configs["generators"]["design"]["gear-hp"]
	var material: Object = o.materials[it.material]
	var bonus := (
		float(material.slot_hp_bonus) if it.material in [&"iron", &"cotton", &"linen"] else 0.0
	)
	var n := it.level + float(cfg["upgrade-step"]) * it.upgrade_count
	return (
		Domain.stat_curve(n, it.rarity)
		* float(cfg["curve-mult"])
		* float(s["hp-mult"])
		* (float(cfg["base"]) + bonus)
	)


static func _defence_stat(
	it: Item, o: Domain.Ontology, material_key: String, missing_material_default: Variant
) -> float:
	var slot := slot_id(it, o)
	if slot == &"" or it.type == &"weapon":
		return 0.0
	return _slot_defence(it, o, slot, material_key, missing_material_default)


static func _slot_defence(
	it: Item,
	o: Domain.Ontology,
	slot: StringName,
	material_key: String,
	missing_material_default: Variant
) -> float:
	var mult := 0.0
	for s in o.configs["equipment-slots"]["slots"]:
		if StringName(s["id"]) == slot:
			var slot_mult: Variant = s.get("hp-mult")
			if not _valid_multiplier(slot_mult):
				return 0.0
			mult = float(slot_mult)
	return _material_defence(it, o, mult, material_key, missing_material_default)


static func _material_defence(
	it: Item,
	o: Domain.Ontology,
	mult: float,
	material_key: String,
	missing_material_default: Variant
) -> float:
	var m: Object = o.materials[it.material]
	var material_mult: Variant = m.get(material_key)
	if material_mult == null:
		material_mult = missing_material_default
	if not _valid_multiplier(material_mult):
		return 0.0
	return Domain.stat_curve(it.level, it.rarity) * mult * float(material_mult)


static func _valid_multiplier(value: Variant) -> bool:
	if not value is int and not value is float:
		return false
	return _finite_multiplier(float(value))


static func _finite_multiplier(number: float) -> bool:
	return not is_nan(number) and not is_inf(number) and number >= 0.0


## consumable-heal: curve(level, rarity) × heal-mult (stats.json).
static func heal(it: Item, o: Domain.Ontology) -> float:
	var c: Object = o.consumables.get(it.subtype)
	return (
		Domain.stat_curve(it.level, it.rarity)
		* (c.slot_heal_mult if c != null and c.slot_heal_mult != null else 0)
	)


## equips-in: canonical slot/type/subtype routing; Inventory adds class and prospective hand checks.
static func slot_id(it: Item, o: Domain.Ontology) -> StringName:
	if it == null:
		return &""
	if it.type == &"weapon":
		return _weapon_slot(it, o)
	return _nonweapon_slot(it, o)


static func _weapon_slot(it: Item, o: Domain.Ontology) -> StringName:
	if not o.weapon_types.has(it.subtype):
		return &""
	var wt: Object = o.weapon_types[it.subtype]
	if Domain.hands(wt) == Domain.Hands.NONE:
		return &""
	return &"off-hand" if Domain.hands(wt) == Domain.Hands.OFFHAND else &"main-hand"


static func _nonweapon_slot(it: Item, o: Domain.Ontology) -> StringName:
	for s in o.configs["equipment-slots"]["slots"]:
		var accepted = _slot_accepts(it, s)
		if accepted == null:
			return &""
		if not accepted:
			continue
		return StringName(s["id"])

	return &""


## A native evaluation abort returns null, not an ordinary false/non-match.
static func _slot_accepts(it: Item, s) -> Variant:
	if String(it.type) not in s.get("accepts", []):
		return false
	return _slot_subtype(it, s)


static func _slot_subtype(it: Item, s) -> Variant:
	var restrictions: Array = s.get("accepts-subtypes", [])
	return not (not restrictions.is_empty() and it.subtype not in restrictions)


static func weapon_material_allowed(it: Item, o: Domain.Ontology) -> bool:
	if it == null or it.type != &"weapon":
		return false
	if not o.weapon_types.has(it.subtype) or not o.materials.has(it.material):
		return false
	return _weapon_material_matches(it, o)


static func _weapon_material_matches(it: Item, o: Domain.Ontology) -> bool:
	var material: Variant = o.weapon_types[it.subtype].slot_material
	var raw: String = str(material if material != null else "")
	for option in raw.split("|"):
		if it.material == StringName(option.strip_edges().split(" ")[0]):
			return true
	return false


static func rarity_id(index: int, o: Domain.Ontology) -> StringName:
	for id in o.rarities:
		if o.rarities[id].slot_index == index:
			return id
	return &"common"


## gen-name: <prefix> <Material> <Type> [of <Name>] (affixes.json#name-forms); epic/legendary always named.
static func item_name(it: Item, o: Domain.Ontology, design: Dictionary) -> String:
	match it.type:
		&"coin":
			return "%d copper" % it.count
		&"consumable":
			return o.consumables[it.subtype].slot_name
		&"ingredient":
			return _ingredient_name(it, o)
	if slot_id(it, o) == &"":
		return String(it.type)
	return _gear_name(it, o, design)


static func _ingredient_name(it: Item, o: Domain.Ontology) -> String:
	return (
		o.materials[it.subtype].slot_name
		if (o.materials.has(it.subtype) and o.materials[it.subtype].slot_kind == "spirit")
		else str(o.configs["ingredients"][it.subtype]["name"])
	)


static func _gear_name(it: Item, o: Domain.Ontology, design: Dictionary) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = it.modifier * 31 + it.minus_modifier
	var rid := rarity_id(it.rarity, o)
	var prefixes: Array = o.configs["affixes"][rid]
	var kind: String = (
		o.weapon_types[it.subtype].slot_name
		if it.type == &"weapon"
		else str(o.configs["item-types"][it.type]["name"])
	)
	var n := (
		"%s %s %s"
		% [prefixes[rng.randi() % prefixes.size()], o.materials[it.material].slot_name, kind]
	)
	if o.rarities[rid].slot_named == true:
		var syl: Array = design["names"]["syllables"]
		var who := ""
		for i in rng.randi_range(2, 3):
			who += syl[rng.randi() % syl.size()]
		n += " of " + who.capitalize()
	return n


static func _weighted(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0.0
	for k in weights:
		total += float(weights[k])
	var x := rng.randf() * total
	for k in weights:
		x -= float(weights[k])
		if x < 0.0:
			return str(k)
	return str(weights.keys().back())


static func roll_rarity(rng: RandomNumberGenerator, loot: Dictionary, o: Domain.Ontology) -> int:
	return o.rarities[StringName(_weighted(rng, loot["rarity-weights"]))].slot_index


## Already-powered gear: kind by weight; uniform class gives weapon-type or armor material.
static func roll_gear(
	rng: RandomNumberGenerator,
	power: int,
	rarity: int,
	o: Domain.Ontology,
	loot: Dictionary,
	class_id: StringName = &""
) -> Item:
	var kind := _weighted(rng, loot["gear-kinds"])
	var cls: Object = o.classes[
		class_id if class_id != &"" else o.classes.keys()[rng.randi() % o.classes.size()]
	]
	if kind == "weapon":
		var wt: StringName = cls.slot_weapon_types[rng.randi() % cls.slot_weapon_types.size()]
		return generate(rng, &"weapon", wt, weapon_material(o.weapon_types[wt]), power, rarity)
	return generate(rng, StringName(kind), &"", cls.slot_armor_material, power, rarity)


## weapon-type.material "iron (+cotton yarn)" | "gold|silver" → first material id.
static func weapon_material(wt: Object) -> StringName:
	var raw: String = str(wt.slot_material if wt.slot_material != null else "iron")
	return StringName(raw.split(" ")[0].split("|")[0])


## gen-loot (D18): independent rolls per kill; coins are a `coin` item with a count.
static func roll_loot(
	rng: RandomNumberGenerator, level: int, c: Object, o: Domain.Ontology, design: Dictionary
) -> Array:
	var loot: Dictionary = design["loot"]
	var out: Array = []
	if rng.randf() < float(loot["coins"]["chance"]):
		out.append(
			Item.stack(
				&"coin", &"", int(loot["coins"]["base"]) + int(loot["coins"]["per-level"]) * level
			)
		)
	var spread := int(loot["level-spread"])
	var power := clampi(Domain.power_for_level(level) + rng.randi_range(-spread, spread), 1, 100)
	if rng.randf() < float(loot["gear-chance"]):
		out.append(roll_gear(rng, power, roll_rarity(rng, loot, o), o, loot))
	if rng.randf() < float(loot["consumable-chance"]):
		var pool: Array = loot["consumable-pool"]
		out.append(Item.stack(&"consumable", StringName(pool[rng.randi() % pool.size()]), 1, power))
	if c != null:
		return _species_drops(rng, c, o, loot, out)
	return out


static func _species_drops(
	rng: RandomNumberGenerator, c: Object, o: Domain.Ontology, loot: Dictionary, out: Array
) -> Array:
	var drops: Array = c.slot_drops if c.slot_drops != null else []
	for d in drops:  # ponytail: drops without an ingredients.json row (popcorn, jellies) are skipped
		if o.configs["ingredients"].has(d) and rng.randf() < float(loot["species-drop-chance"]):
			out.append(Item.stack(&"ingredient", d, 1))
	return out


## Creature died → roll its loot and lay it on the ground under its zone node (unloads with the zone).
static func drop_for(m: Node3D, o: Domain.Ontology, design: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([m.species, m.home])
	return spawn_drops(
		m.get_parent(),
		m.global_position,
		roll_loot(rng, m.level, o.creatures.get(m.species), o, design),
		rng,
		o,
		design
	)


static func spawn_drops(
	parent: Node3D,
	pos: Vector3,
	items: Array,
	rng: RandomNumberGenerator,
	o: Domain.Ontology,
	design: Dictionary
) -> Array:
	var ground: Dictionary = design["loot"]["ground"]
	var s := float(ground["scatter"])
	var made: Array = []
	for it in items:
		var color := (
			Color.GOLD
			if it.type == &"coin"
			else Color(str(o.rarities[rarity_id(it.rarity, o)].slot_hex))
		)
		var n := GROUND.instantiate()
		n.setup(it, item_name(it, o, design), color, ground)
		n.position = parent.to_local(
			pos + Vector3(rng.randf_range(-s, s), 0.5, rng.randf_range(-s, s))
		)
		parent.add_child(n)
		var frame = parent.get_meta("local_frame") if parent.has_meta("local_frame") else null
		if frame != null:
			frame.track(n)
		made.append(n)
	return made
