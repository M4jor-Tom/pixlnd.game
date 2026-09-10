## skill-tree (§3.5, D6/D10/D20): the nodes of one (class, spec) pair from model.gd#skill_tree, points spent
## per node, the spend rule (c-skill-spend) and the per-point multipliers of design.skill-point. Pure state;
## the player owns one, the X panel and the class-skill keys consume it.
extends RefCounted

var nodes: Array = []            # Ability, screen order
var points: Dictionary = {}      # ability id → points spent
var sp: Dictionary = {}          # design.skill-point

func _init(o, sp_design: Dictionary, class_id: StringName, spec_id: StringName) -> void:
	nodes = o.skill_tree(class_id, spec_id); sp = sp_design

func spent(id: StringName) -> int:
	return int(points.get(id, 0))

## The node that must hold `alpha-tree.needs` points first: the previous rank of the class column, rank 3
## for the ultimate, the shared node whose unlocks-next is us; null for roots.
func prerequisite(a) -> Variant:
	var t: Dictionary = a.alpha_tree
	for b in nodes:
		var u: Dictionary = b.alpha_tree
		if str(t["column"]) == "class":
			if str(u["column"]) == "class" and int(u.get("rank", 0)) == int(t["rank"]) - 1:
				return b
		elif str(t["column"]) == "ultimate":
			if str(u["column"]) == "class" and int(u.get("rank", 0)) == 3:
				return b
		elif StringName(str(b.raw.get("unlocks-next", ""))) == a.id:
			return b
	return null

func is_open(a) -> bool:
	var pre = prerequisite(a)
	return pre == null or spent(pre.id) >= int(a.alpha_tree["needs"])

## c-skill-spend: one point from the bank onto an open node; returns what is left in the bank.
func spend(a, banked: int) -> int:
	var cap = sp.get("cap")
	if banked <= 0 or not is_open(a) or (cap != null and spent(a.id) >= int(cap)):
		return banked
	points[a.id] = spent(a.id) + 1
	return banked - 1

## Trainer respec (D22): every point back to the bank; returns how many.
func respec() -> int:
	var n := 0
	for id in points:
		n += int(points[id])
	points.clear()
	return n

## D6: +effect-per-point per point, uncapped.
func effect_mult(id: StringName) -> float:
	return 1.0 + float(sp["effect-per-point"]) * spent(id)

## D6: −cooldown-per-point per point down to cooldown-floor.
func cooldown_mult(id: StringName) -> float:
	return maxf(float(sp["cooldown-floor"]), 1.0 - float(sp["cooldown-per-point"]) * spent(id))

## Keys 1-4 → class column rank 1..3, then the ultimate (D10/D20); null when the spec has none (assassin).
func class_slot(index: int) -> Variant:
	for b in nodes:
		var u: Dictionary = b.alpha_tree
		if (index <= 3 and str(u["column"]) == "class" and int(u.get("rank", 0)) == index) or (index == 4 and str(u["column"]) == "ultimate"):
			return b
	return null

## The ability's own positive cooldown (S value first, then A) or -1 when the sources give none / 0.
static func listed_cooldown(a) -> float:
	var c = a.cooldown_s
	if c is Dictionary:
		c = c.get("S", c.get("A"))
	return float(c) if (c is float or c is int) and float(c) > 0.0 else -1.0
