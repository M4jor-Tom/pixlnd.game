## Headless check of §3.3 (D15): `godot --headless -s game/combat/test_combat.gd`.
## Formulas, then a floor with a player and a hostile wolf: hit, combo, whiff, retaliation, kill, respawn.
extends SceneTree

const Model := preload("res://ontology/model.gd")
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

func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)

func _init() -> void:
	var o := Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	var design: Dictionary = o.configs["generators"]["design"]
	var cb: Dictionary = design["combat"]
	check(is_equal_approx(Combat.weapon_damage(1, 0, 4, cb), 40.0), "level-1 common sword = 40: %.1f" % Combat.weapon_damage(1, 0, 4, cb))
	check(is_equal_approx(Combat.after_armor(40.0, 100.0, cb), 4.0), "armor floor 10 %")
	var rng := RandomNumberGenerator.new(); rng.seed = 1
	check(is_equal_approx(Combat.crit_mult(1.5, rng, design["crit"]), 2.5), "crit overflow: chance 1.5 → ×2.5")
	check(is_equal_approx(Combat.combo_mult(10, cb), 1.2), "combo 10 → ×1.2")
	check(is_equal_approx(Combat.player_max_hp(1, 1.3), 260.0), "warrior level 1 = 260 HP")
	check(is_equal_approx(Combat.enemy_damage(1, 0.0, cb), 12.0), "level-1 mob hits for 12")
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(cb, design["crit"], {"type": &"sword", "damage": 40.0, "combo_cap": 30}, 260.0)
	p.position = Vector3(0, 1, 0); p.spawn_point = Vector3(0, 1, 0)
	var holder := Node3D.new(); root.add_child(holder)
	var wolf: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"H", "max_hp": 200.0, "damage": 12.0, "positions": [Vector3(0, 1, -2)], "seed": 1}], design, o.creatures, p)[0]
	await _frames(20)
	await _tap("basic-attack")                                   # camera yaw 0 → forward is -Z, wolf 2 blocks ahead
	await _frames(5)
	check(is_equal_approx(wolf.hp, 160.0), "first hit does 40: wolf hp %.1f" % wolf.hp)
	check(p.combo == 1, "combo 1 after a hit: %d" % p.combo)
	await _frames(35)
	await _tap("basic-attack")
	await _frames(5)
	check(is_equal_approx(wolf.hp, 160.0 - 40.8), "second hit gets +2 %% combo: %.1f" % wolf.hp)
	var hp_before: float = p.hp
	await _frames(150)
	check(p.hp < hp_before, "wolf retaliates: player hp %.0f → %.0f" % [hp_before, p.hp])
	var wid := wolf.get_instance_id()
	for i in 8:
		await _frames(35)
		await _tap("basic-attack")
	await _frames(30)
	check(not is_instance_id_valid(wid), "wolf dies and is freed after ~5 hits")
	await _frames(35)
	await _tap("basic-attack")
	await _frames(2)
	check(p.combo == 0, "whiff resets combo: %d" % p.combo)
	p.take_damage(p.hp + 1.0, p)
	check(p.dead, "player dies at 0 hp")
	await _frames(int(float(cb["death"]["respawn-s"]) * 60) + 20)
	check(not p.dead and is_equal_approx(p.hp, p.max_hp) and p.position.distance_to(p.spawn_point) < 1.0, "respawns full at the spawn point (c-no-death-penalty)")
	print("combat ok" if _failed == 0 else "combat FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
