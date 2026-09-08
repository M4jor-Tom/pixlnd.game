## §3.3 formulas, pure and static: stats.json#alpha-item-stat-formulas, generators.json#design.combat|crit.
extends RefCounted

const Model := preload("res://ontology/model.gd")

## gen-item-stats damage × the attack-power multiplier (D15). ponytail: the 0..20 modifier roll is ignored.
static func weapon_damage(level: int, rarity: int, k: int, combat: Dictionary) -> float:
	return Model.stat_curve(level, rarity) * k * float(combat["attack-power-mult"])

## Armor is subtractive with a floor (D15).
static func after_armor(attack: float, armor: float, combat: Dictionary) -> float:
	return maxf(attack - armor, attack * float(combat["armor-floor"]))

## design.crit: ×2, chance above 1 adds to the multiplier.
static func crit_mult(chance: float, rng: RandomNumberGenerator, crit: Dictionary) -> float:
	var m := float(crit["multiplier"]) + maxf(chance - 1.0, 0.0)
	return m if rng.randf() < chance else 1.0

static func combo_mult(combo: int, combat: Dictionary) -> float:
	return 1.0 + combo * float(combat["combo"]["bonus-per-hit"])

## stats.json#player-hp: base-hp × 2 × 100 × class mult.
static func player_max_hp(level: int, class_hp_mult: float) -> float:
	return Model.stat_curve(level, 0) * 2.0 * 100.0 * class_hp_mult

## design.combat.enemy-attack.formula
static func enemy_damage(level: int, power_base: float, combat: Dictionary) -> float:
	return Model.stat_curve(level, 0) * float(combat["enemy-attack"]["mult"]) * pow(2.0, power_base * 0.25)
