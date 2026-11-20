## Original creature-role plan search and independent RNG/no-role comparisons.
extends RefCounted
const Domain := preload("res://game/domain/domain.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
const Spawner := preload("res://game/world/spawner.gd")
var t
var o
var design: Dictionary
var rosters: Dictionary
var skel: Dictionary = {}  # an any-class group
var plain: Dictionary = {}  # a group of a species with no role text
var at_seed := 0
var at_zone := Vector2i.ZERO  # a zone whose FIRST group is any-class, with a second behind it
var many_seed := 0
var many_zone := Vector2i.ZERO


func run(tree, ontology, rules: Dictionary) -> void:
	t = tree
	o = ontology
	design = rules
	rosters = o.configs["creature-families"]["landscape-rosters"]
	_plans()


func check(ok: bool, what: String) -> void:
	t.check(ok, what)


func _plans() -> void:
	# --- gen-spawns: a role per group, any-class rolled, deterministic
	_search()
	check(not skel.is_empty(), "found a skeleton (any-class) group in a plan")
	check(
		str(skel.get("role", "")) in ["melee", "ranged", "mage"],
		"the any-class group rolled a role: %s" % skel.get("role", "-")
	)
	check(
		not plain.is_empty() and str(plain.get("role", "")) == "melee",
		"a species with no role plans as melee: %s" % plain.get("role", "-")
	)
	var a := Spawner.plan(
		WorldGen.new(at_seed, design, o.landscapes), at_zone, design, o.creatures, rosters, 1
	)
	var b := Spawner.plan(
		WorldGen.new(at_seed, design, o.landscapes), at_zone, design, o.creatures, rosters, 1
	)
	check(var_to_str(a) == var_to_str(b), "same seed → same roles")

	_shared_rng()


func _search() -> void:
	for s in range(1, 60):
		var gen := WorldGen.new(s, design, o.landscapes)
		_seed_zones(gen, s)
		if _search_complete():
			break


func _shared_rng() -> void:
	# --- the role roll must not touch the shared zone rng: the same zone planned with every any-class species
	# forced to melee (no roll at all) must give byte-identical groups apart from `role`.
	check(many_seed != 0, "found a zone with ≥ 2 groups behind an any-class first group")
	var any_plan := Spawner.plan(
		WorldGen.new(many_seed, design, o.landscapes), many_zone, design, o.creatures, rosters, 1
	)
	var was: Dictionary = {}
	for id in o.creatures:
		if Domain.combat_role(o.creatures[id]) == &"any-class":
			was[id] = o.creatures[id].slot_role
			o.creatures[id].slot_role = "melee"
	var melee_plan := Spawner.plan(
		WorldGen.new(many_seed, design, o.landscapes), many_zone, design, o.creatures, rosters, 1
	)
	for id in was:
		o.creatures[id].slot_role = was[id]
	check(
		any_plan.size() == melee_plan.size(),
		(
			"same group count with and without the role roll (%d / %d)"
			% [any_plan.size(), melee_plan.size()]
		)
	)
	var rolled := false
	for i in mini(any_plan.size(), melee_plan.size()):
		var x: Dictionary = (any_plan[i] as Dictionary).duplicate(true)
		var y: Dictionary = (melee_plan[i] as Dictionary).duplicate(true)
		rolled = rolled or str(x["role"]) != str(y["role"])
		x.erase("role")
		y.erase("role")
		check(
			var_to_str(x) == var_to_str(y),
			"group %d: species / positions / level / hp / seed untouched by the role roll" % i
		)
	check(rolled, "…and the any-class group did roll a role other than melee at this seed")


func _zone(gen, s, zx, zy) -> void:
	var zc := Vector2i(zx * 16, zy * 16)
	var p_ := Spawner.plan(gen, zc, design, o.creatures, rosters, 1)
	for g in p_:
		_group(g, s, zc)
	if (
		many_seed == 0
		and p_.size() >= 2
		and str(p_[0]["role"]) != "melee"
		and (str(Domain.combat_role(o.creatures[p_[0]["species"]])) == "any-class")
	):
		many_seed = s
		many_zone = zc


func _group(g, s, zc) -> void:
	if g["species"] == &"skeleton" and skel.is_empty():
		skel = g
		at_seed = s
		at_zone = zc
	elif plain.is_empty() and str(Domain.combat_role(o.creatures[g["species"]])) == "":
		plain = g


func _seed_zones(gen, s) -> void:
	for zx in range(-3, 4):
		for zy in range(-3, 4):
			_zone(gen, s, zx, zy)


func _search_complete() -> bool:
	return not skel.is_empty() and not plain.is_empty() and many_seed != 0
