## item (§3.4): one concrete item, the alpha ItemData fields the slice uses. Stats are derived
## by items.gd (gen-item-stats); nothing here is authored, everything comes from a generator.
extends RefCounted

var type: StringName = &""            # item-type id (weapon, chest-armor, consumable, ingredient, coin…)
var subtype: StringName = &""         # weapon-type id | consumable id | ingredient id
var material: StringName = &""        # material id (gear only)
var rarity := 0                       # rarity index 0..4 (c-rarity-range)
var level := 1                        # alpha power +1..+100
var modifier := 0                     # ItemData.modifier: seed of roll + name
var minus_modifier := 0               # ItemData.minus_modifier ("attributes" in the roll)
var count := 1                        # > 1 only for stackable types (c-stack-rule)

## c-stat-roll: ((attributes << 16) + modifier) mod 21 ∈ 0..20.
func roll() -> int:
	return posmod((minus_modifier << 16) + modifier, 21)

static func stack(p_type: StringName, p_subtype: StringName, p_count: int, p_level := 1):
	var it := new()
	it.type = p_type; it.subtype = p_subtype; it.count = p_count; it.level = p_level
	return it
