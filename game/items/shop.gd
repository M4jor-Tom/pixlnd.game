## shop (§3.4, D22): vendor stock and design.prices, pure and static. Stock is rolled from (world seed, village, role)
## at the land's creature level band around the player level (gen.creature_level), rarity ≤ design.settlement.shop.rarity-cap.
## ponytail: rolled per open at the current level, never restocks (c-midnight-reset later); no buy-back, no gnome unlocks.
extends RefCounted

const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")

const VENDORS := [&"weapon-vendor", &"armor-vendor", &"item-vendor"]

static func is_vendor(role: StringName) -> bool:
	return role in VENDORS

## design.prices.base key of an item-type.
static func price_group(it: Item) -> String:
	match it.type:
		&"weapon": return "weapon"
		&"ring", &"amulet": return "ring|amulet"
		&"consumable": return "consumable"
		&"ingredient": return "material"
		&"formula": return "formula"
	return "armor"

## buy = base[group] × level × rarity-mult (copper), at least 1.
static func buy_price(it: Item, o: Model.Ontology, design: Dictionary) -> int:
	var p: Dictionary = design["prices"]
	var mult := float(p["rarity-mult"].get(String(Items.rarity_id(it.rarity, o)), 1.0))
	return maxi(1, ceili(float(p["base"].get(price_group(it), 1)) * it.level * mult))

## sell = buy × design.prices.sell, at least 1 (per unit).
static func sell_price(it: Item, o: Model.Ontology, design: Dictionary) -> int:
	return maxi(1, floori(buy_price(it, o, design) * float(design["prices"]["sell"])))

static func stock(role: StringName, gen, land, village: Dictionary, player_level: int, o: Model.Ontology, design: Dictionary) -> Array:
	var st: Dictionary = design["settlement"]["shop"]
	var out: Array = []
	if role == &"item-vendor":                                   # unlimited consumables at the player's level
		for c in design["loot"]["consumable-pool"]:
			out.append(Item.stack(&"consumable", StringName(c), 1, maxi(1, player_level)))
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([gen.world_seed, village["centre"], role])
	var cap: int = (o.rarities[StringName(st["rarity-cap"])] as Model.RarityDef).index
	var spread := int(st["level-spread"])
	var armor_kinds: Array = design["loot"]["gear-kinds"].keys().filter(func(k: String) -> bool: return k != "weapon")
	for i in int(st["stock"]):
		var lvl := maxi(1, gen.creature_level(land, player_level, player_level, rng) + rng.randi_range(-spread, spread))
		var rarity := mini(Items.roll_rarity(rng, design["loot"], o), cap)
		var cls: Model.CharacterClass = o.classes[o.classes.keys()[rng.randi() % o.classes.size()]]
		if role == &"weapon-vendor":
			var wt: StringName = cls.weapon_types[rng.randi() % cls.weapon_types.size()]
			out.append(Items.generate(rng, &"weapon", wt, Items.weapon_material(o.weapon_types[wt]), lvl, rarity))
		else:
			out.append(Items.generate(rng, StringName(armor_kinds[rng.randi() % armor_kinds.size()]), &"", cls.armor_material, lvl, rarity))
	return out

## Coins → bag. Consumables are unlimited stock (a fresh stack of one); gear moves out of the stock. False = too poor.
static func buy(player: Node, it: Item) -> bool:
	var price := buy_price(it, player.o, player.design)
	if player.inventory.coins < price:
		return false
	player.inventory.coins -= price
	player.inventory.add(Item.stack(it.type, it.subtype, 1, it.level) if it.type == &"consumable" else it)
	return true

## One unit of a bag entry → coins (worn gear is not in the bag, so it cannot be sold).
static func sell(player: Node, it: Item) -> void:
	player.inventory.coins += sell_price(it, player.o, player.design)
	player.inventory.remove(it, 1)
