## Pure encounter payloads; source/cycle keys own rolls, never disposable nodes or player count.
extends RefCounted
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Targeting := preload("res://game/combat/targeting.gd")
const State := preload("res://game/world/world_state.gd")


static func rng_for(source: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(source)
	return rng


static func kill_payload(
	stable: Dictionary, cycle: int, level: int, spirit_level: int, o, design: Dictionary
) -> Array:
	var rng := rng_for("kill/%d/%d" % [int(stable.seed), cycle])
	var out := Items.roll_loot(
		rng, level, o.creatures[design["initial-encounters"].species], o, design
	)
	if stable.boss:
		out.append(
			Items.roll_gear(
				rng,
				level,
				mini(
					int(stable.tier) + int(design.loot["boss-rarity-shift"]),
					o.rarities[&"legendary"].index
				),
				o,
				design.loot
			)
		)
		if stable.spirit != "":
			out.append(Item.stack(&"ingredient", StringName(stable.spirit), 1, spirit_level))
	return out


static func package_payload(
	source: String, tier: int, level: int, class_id: StringName, o, design: Dictionary
) -> Array:
	var cfg: Dictionary = design["initial-encounters"]["mission-package"]
	var grade := tier + int(cfg["rarity-shift"])
	var gear = Items.roll_gear(rng_for(source), level, grade, o, design.loot, class_id)
	gear.upgrade_count = int(cfg.upgrades)
	var potion = Item.stack(&"consumable", StringName(cfg.potion), int(cfg["potion-count"]), level)
	potion.rarity = int(cfg["potion-rarity"])
	return [
		gear,
		Item.stack(&"coin", &"", int(cfg["coin-per-grade"]) * grade),
		potion,
		Item.stack(
			&"ingredient", StringName(cfg.gems[tier]), grade * int(cfg["gem-count-per-grade"])
		)
	]


static func class_of(member) -> String:
	if member is Dictionary:
		return str(member.get("class_id", ""))
	if not is_instance_valid(member):
		return ""
	var inventory = member.get("inventory")
	return str(inventory.class_id) if inventory != null else ""


static func completion_classes(party: Array, volumes: Array, finisher) -> Array:
	var classes: Array = []
	for member in party:
		var cls := class_of(member)
		if (
			cls != ""
			and State.inside(volumes, [Targeting.position_of(member)])
			and not cls in classes
		):
			classes.append(cls)
	classes.sort()
	if classes.is_empty():
		var cls := class_of(finisher)
		if cls != "":
			classes.append(cls)
	return classes
