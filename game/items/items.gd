## §3.4 generators, pure and static: gen-item, gen-item-stats (damage + armor), gen-name for items,
## gen-loot. Numbers: stats.json#alpha-item-stat-formulas, generators.json#design.loot|stack-cap (D18).
## ponytail: hp/regen/tempo/crit from gear wait for their formulas (todo_implement.md).
extends RefCounted

const Model := preload("res://ontology/model.gd")
const Item := preload("res://game/items/item.gd")
const GROUND := preload("res://game/items/ground_item.tscn")

## gen-item: the two modifiers are the seed of the roll (c-stat-roll) and of the name.
static func generate(rng: RandomNumberGenerator, type: StringName, subtype: StringName, material: StringName, level: int, rarity: int) -> Item:
	var it := Item.new()
	it.type = type; it.subtype = subtype; it.material = material
	it.level = maxi(level, 1)
	it.rarity = clampi(rarity, Model.Rarity.COMMON, Model.Rarity.LEGENDARY)         # c-rarity-range
	it.modifier = rng.randi(); it.minus_modifier = rng.randi()
	return it

## gen-item-stats damage = curve(level, rarity) × weapon-type k. The roll does not touch damage.
static func damage(it: Item, o: Model.Ontology) -> float:
	if it.type != &"weapon":
		return 0.0
	return Model.stat_curve(it.level, it.rarity) * (o.weapon_types[it.subtype] as Model.WeaponType).damage_k

## gen-item-stats armor = curve × slot mult (chest 1.0, other 0.5) × material armor-mult.
static func armor(it: Item, o: Model.Ontology) -> float:
	var slot := slot_id(it, o)
	if slot == &"" or it.type == &"weapon":
		return 0.0
	var mult := 1.0
	for s in o.configs["equipment-slots"]["slots"]:
		if StringName(s["id"]) == slot: mult = float(s.get("hp-mult", 0.5))
	var m: Model.MaterialDef = o.materials[it.material]
	return Model.stat_curve(it.level, it.rarity) * mult * float(m.raw.get("armor-mult", 1.0))

## consumable-heal: curve(level, rarity) × heal-mult (stats.json).
static func heal(it: Item, o: Model.Ontology) -> float:
	var c: Model.Consumable = o.consumables.get(it.subtype)
	return Model.stat_curve(it.level, it.rarity) * (c.heal_mult if c != null else 0)

## equips-in: the equipment-slot whose `accepts` lists the type; weapons by hands (c-slot-accepts).
static func slot_id(it: Item, o: Model.Ontology) -> StringName:
	if it.type == &"weapon":
		return &"off-hand" if (o.weapon_types[it.subtype] as Model.WeaponType).hands == Model.Hands.OFFHAND else &"main-hand"
	for s in o.configs["equipment-slots"]["slots"]:
		if String(it.type) in s["accepts"]:
			return StringName(s["id"])
	return &""

static func rarity_id(index: int, o: Model.Ontology) -> StringName:
	for id in o.rarities:
		if (o.rarities[id] as Model.RarityDef).index == index: return id
	return &"common"

## gen-name: <prefix> <Material> <Type> [of <Name>] (affixes.json#name-forms); epic/legendary always named.
static func item_name(it: Item, o: Model.Ontology, design: Dictionary) -> String:
	match it.type:
		&"coin": return "%d copper" % it.count
		&"consumable": return o.consumables[it.subtype].display_name
		&"ingredient": return str(o.configs["ingredients"][it.subtype]["name"])
	if slot_id(it, o) == &"":
		return String(it.type)
	var rng := RandomNumberGenerator.new(); rng.seed = it.modifier * 31 + it.minus_modifier
	var rid := rarity_id(it.rarity, o)
	var prefixes: Array = o.configs["affixes"][rid]
	var kind: String = o.weapon_types[it.subtype].display_name if it.type == &"weapon" else str(o.configs["item-types"][it.type]["name"])
	var n := "%s %s %s" % [prefixes[rng.randi() % prefixes.size()], o.materials[it.material].display_name, kind]
	if (o.rarities[rid] as Model.RarityDef).named:
		var syl: Array = design["names"]["syllables"]
		var who := ""
		for i in rng.randi_range(2, 3):
			who += syl[rng.randi() % syl.size()]
		n += " of " + who.capitalize()
	return n

static func _weighted(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0.0
	for k in weights: total += float(weights[k])
	var x := rng.randf() * total
	for k in weights:
		x -= float(weights[k])
		if x < 0.0: return str(k)
	return str(weights.keys().back())

static func roll_rarity(rng: RandomNumberGenerator, loot: Dictionary, o: Model.Ontology) -> int:
	return (o.rarities[StringName(_weighted(rng, loot["rarity-weights"]))] as Model.RarityDef).index

## D18 gear: kind by weight; a class rolled uniformly gives the weapon-type or the armor material.
static func roll_gear(rng: RandomNumberGenerator, level: int, rarity: int, o: Model.Ontology, loot: Dictionary) -> Item:
	var kind := _weighted(rng, loot["gear-kinds"])
	var cls: Model.CharacterClass = o.classes[o.classes.keys()[rng.randi() % o.classes.size()]]
	if kind == "weapon":
		var wt: StringName = cls.weapon_types[rng.randi() % cls.weapon_types.size()]
		return generate(rng, &"weapon", wt, weapon_material(o.weapon_types[wt]), level, rarity)
	return generate(rng, StringName(kind), &"", cls.armor_material, level, rarity)

## weapon-type.material "iron (+cotton yarn)" | "gold|silver" → first material id.
static func weapon_material(wt: Model.WeaponType) -> StringName:
	return StringName(str(wt.raw.get("material", "iron")).split(" ")[0].split("|")[0])

## gen-loot (D18): independent rolls per kill; coins are a `coin` item with a count.
static func roll_loot(rng: RandomNumberGenerator, level: int, c: Model.Creature, o: Model.Ontology, design: Dictionary) -> Array:
	var loot: Dictionary = design["loot"]
	var out: Array = []
	if rng.randf() < float(loot["coins"]["chance"]):
		out.append(Item.stack(&"coin", &"", int(loot["coins"]["base"]) + int(loot["coins"]["per-level"]) * level))
	var spread := int(loot["level-spread"])
	var lvl := maxi(1, level + rng.randi_range(-spread, spread))
	if rng.randf() < float(loot["gear-chance"]):
		out.append(roll_gear(rng, lvl, roll_rarity(rng, loot, o), o, loot))
	if rng.randf() < float(loot["consumable-chance"]):
		var pool: Array = loot["consumable-pool"]
		out.append(Item.stack(&"consumable", StringName(pool[rng.randi() % pool.size()]), 1, lvl))
	if c != null:
		for d in c.drops:                                   # ponytail: drops without an ingredients.json row (popcorn, jellies) are skipped
			if o.configs["ingredients"].has(d) and rng.randf() < float(loot["species-drop-chance"]):
				out.append(Item.stack(&"ingredient", d, 1))
	return out

## Creature died → roll its loot and lay it on the ground under its zone node (unloads with the zone).
static func drop_for(m: Node3D, o: Model.Ontology, design: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new(); rng.seed = hash([m.species, m.home])
	return spawn_drops(m.get_parent(), m.global_position, roll_loot(rng, m.level, o.creatures.get(m.species), o, design), rng, o, design)

static func spawn_drops(parent: Node3D, pos: Vector3, items: Array, rng: RandomNumberGenerator, o: Model.Ontology, design: Dictionary) -> Array:
	var ground: Dictionary = design["loot"]["ground"]
	var s := float(ground["scatter"])
	var made: Array = []
	for it in items:
		var color := Color.GOLD if it.type == &"coin" else Color(str(o.rarities[rarity_id(it.rarity, o)].raw.get("hex", "#ffffff")))
		var n := GROUND.instantiate()
		n.setup(it, item_name(it, o, design), color, ground)
		parent.add_child(n)
		n.global_position = pos + Vector3(rng.randf_range(-s, s), 0.5, rng.randf_range(-s, s))
		made.append(n)
	return made
