## Headless check of §3.5 (D19): `godot --headless -s game/progression/test_progression.gd`.
## level-formula table, xp-for-kill gap rule, settle (overflow, multi-level), c-xp-config,
## then a floor with a player and wolves: kills → XP → level 2, max HP up, healed, 2 skill points banked.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Progression := preload("res://game/progression/progression.gd")
const Combat := preload("res://game/combat/combat.gd")
const Spawner := preload("res://game/world/spawner.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")

var _failed := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _init() -> void:
	var o := Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	var design: Dictionary = o.configs["generators"]["design"]
	var prog: Dictionary = design["progression"]
	# level-formula (stats.json table)
	for pair in [[1, 50], [2, 97], [5, 216], [10, 360], [20, 537], [50, 760], [100, 881]]:
		check(Model.xp_to_next(pair[0]) == pair[1], "xp-to-next L%d = %d: %d" % [pair[0], pair[1], Model.xp_to_next(pair[0])])
	check(Model.power_for_level(1) == 1 and Model.power_for_level(10) == 32 and Model.power_for_level(1981) == 100, "power table")
	# xp-for-kill: even level = fraction of xp-to-next; 10 below = 0; far above capped ×2
	check(Model.xp_for_kill(2, 2, prog) == int(97 * 0.2), "even kill L2 = 19: %d" % Model.xp_for_kill(2, 2, prog))
	check(Model.xp_for_kill(1, 11, prog) == 0, "grey kill (10 below) = 0")
	check(Model.xp_for_kill(30, 1, prog) == int(Model.xp_to_next(30) * 0.2 * 2.0), "far above capped at ×2")
	check(Model.xp_for_kill(3, 1, prog) > Model.xp_for_kill(3, 3, prog), "higher creature than us = more xp")
	# settle: overflow carries, several levels at once, never below current level
	var s := Progression.settle(1, 49); check(s["level"] == 1 and s["xp"] == 49 and s["gained"] == 0, "49 xp stays L1")
	s = Progression.settle(1, 63); check(s["level"] == 2 and s["xp"] == 13 and s["gained"] == 1, "63 xp → L2 with 13 carried: %s" % s)
	s = Progression.settle(1, 50 + 97 + 5); check(s["level"] == 3 and s["xp"] == 5 and s["gained"] == 2, "two levels in one call: %s" % s)
	# c-xp-config fires
	prog["kill-fraction"] = 1.5
	check(not o.validate(), "c-xp-config rejects kill-fraction > 1")
	prog["kill-fraction"] = 0.2; o.errors.clear()
	# scene: player kills three L2 wolves → 3 × 21 = 63 xp → level 2
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(1, 1.3))
	p.setup_items(o, design)
	p.position = Vector3(0, 1, 0); p.spawn_point = p.position
	var hp1: float = p.max_hp
	var levels: Array = []
	p.leveled_up.connect(func(l: int) -> void: levels.append(l))
	var holder := Node3D.new(); root.add_child(holder)
	var wolves := Spawner.populate(holder, [{"species": &"wolf", "level": 2, "hostility": &"H", "max_hp": 200.0, "damage": 12.0,
		"positions": [Vector3(0, 1, -2), Vector3(2, 1, -2), Vector3(-2, 1, -2)], "seed": 1}], design, o.creatures, p, null)
	await _frames(5)
	wolves[0].take_damage(1e9, p)
	check(p.level == 1 and p.xp == 21 and p.skill_points == 0, "one L2 kill at L1 = 21 xp, still L1: %d xp" % p.xp)
	p.hp = 10.0
	wolves[1].take_damage(1e9, p); wolves[2].take_damage(1e9, p)
	check(p.level == 2 and p.xp == 13 and levels == [2], "three kills → level 2, 13 xp carried (levels %s)" % [levels])
	check(p.skill_points == 2, "2 skill points banked: %d" % p.skill_points)
	check(p.max_hp > hp1 and is_equal_approx(p.max_hp, Combat.player_max_hp(2, 1.3)) and is_equal_approx(p.hp, p.max_hp), "level-up: max hp %.0f → %.0f, healed to full (%.0f)" % [hp1, p.max_hp, p.hp])
	print("progression ok" if _failed == 0 else "progression FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
