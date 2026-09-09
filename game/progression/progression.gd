## §3.5 progression, pure and static: level-formula (model.gd) + design.progression (D19).
## ponytail: skill points are only banked; the skill-tree UI, trainer respec and power-gate wait (todo_implement.md).
extends RefCounted

const Model := preload("res://ontology/model.gd")

## c-level-up: fold `xp` into levels; returns {level, xp, gained}. Overflow carries, several levels per call.
static func settle(level: int, xp: int) -> Dictionary:
	var gained := 0
	while xp >= Model.xp_to_next(level):
		xp -= Model.xp_to_next(level)
		level += 1; gained += 1
	return {"level": level, "xp": xp, "gained": gained}
