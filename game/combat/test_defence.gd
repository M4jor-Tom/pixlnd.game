## Headless check of §3.3 defence (D23): `godot --headless -s game/combat/test_defence.gd`.
## c-defence-config fires; a floor with a frozen wolf: dodge (cost, roll, i-frames, needs movement, ninja MP / assassin
## stealth), block (shield front cone, block-power, MP, behind = full, exhausted = full, regen, guardian without shield),
## stealth (sneak fills, aggro range shrinks, hit ×1.2 then empties, camouflage pins), enemy-hit stun / knockback and
## their absence through a block.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Combat := preload("res://game/combat/combat.gd")
const Items := preload("res://game/items/items.gd")
const Spawner := preload("res://game/world/spawner.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")

var _failed := 0
var design: Dictionary
var o

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _player(class_id: StringName, spec: StringName, at: Vector3) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(1, 1.0))
	p.setup_items(o, design, class_id, spec)
	p.position = at; p.spawn_point = at
	return p

func _wolf(p: Node, at: Vector3) -> CharacterBody3D:
	var holder := Node3D.new(); root.add_child(holder)
	var w: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"P", "max_hp": 1e6, "damage": 12.0,
		"positions": [at], "seed": 1}], design, o.creatures, p, null)[0]
	w.set_physics_process(false)                              # stays put: we call its hooks by hand
	return w

func _init() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs["generators"]["design"]
	var df: Dictionary = design["defence"]
	df["block"]["damage-reduction"] = 2.0
	check(not o.validate(), "c-defence-config rejects damage-reduction > 1"); o.errors.clear()
	df["block"]["damage-reduction"] = 0.8
	df["dodge"]["on-dodge"]["smash"] = {"mp": 1}
	check(not o.validate(), "c-defence-config rejects a non-passive on-dodge key"); o.errors.clear()
	df["dodge"]["on-dodge"].erase("smash"); check(o.validate(), "restored")
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)
	var p := _player(&"warrior", &"berserker", Vector3(0, 1, 0))
	var wolf := _wolf(p, Vector3(0, 1, -3))                   # in front: the rig looks down -Z
	await _frames(5)
	# --- dodge
	var dg: Dictionary = df["dodge"]
	check(not p.dodge(Vector3.ZERO) and is_equal_approx(p.stamina, 100.0), "dodge needs movement")
	var x0: float = p.global_position.x
	Input.action_press("move_right"); Input.action_press("dodge"); await _frames(2); Input.action_release("dodge")
	check(is_equal_approx(p.stamina, 100.0 - float(dg["stamina"])) or p.stamina < 76.0, "dodge costs %d stamina: %.1f" % [dg["stamina"], p.stamina])
	check(p._iframes > 0.0, "i-frames running")
	var hp0: float = p.hp
	p.take_damage(50.0, wolf); wolf._hit_statuses(p)
	check(is_equal_approx(p.hp, hp0), "hit during i-frames ignored")
	await _frames(40); Input.action_release("move_right"); await _frames(5)
	var rolled: float = p.global_position.x - x0
	check(rolled >= float(dg["distance"]) * 0.8, "rolled ~%d blocks: %.1f" % [dg["distance"], rolled])
	check(p._iframes <= 0.0 and p._dodge.is_empty(), "dodge over")
	# --- block with a shield
	var shield = Items.generate(RandomNumberGenerator.new(), &"weapon", &"shield", &"iron", 1, 0)
	check(not p.can_block(), "berserker without shield cannot block")
	p.inventory.add(shield); p.inventory.equip(shield)
	check(p.inventory.equipment.get(&"off-hand") == shield and p.can_block(), "shield in the off-hand → can block")
	p.global_position = Vector3(0, 1, 0); p.velocity = Vector3.ZERO; p.mp = 0.0
	var bl: Dictionary = df["block"]
	Input.action_press("special-attack"); await _frames(3)
	check(p.blocking, "M2 held = blocking")
	hp0 = p.hp; p.take_damage(100.0, wolf)
	check(is_equal_approx(hp0 - p.hp, 100.0 * (1.0 - float(bl["damage-reduction"]))), "front hit reduced: %.1f" % (hp0 - p.hp))
	check(is_equal_approx(p.block_power, float(bl["max"]) - float(bl["power-per-hit"])), "block-power spent: %.0f" % p.block_power)
	check(is_equal_approx(p.mp, float(bl["mp-per-block"])), "block gives MP: %.0f" % p.mp)
	df["enemy-hit"]["stun-chance"] = 1.0; df["enemy-hit"]["knockback-chance"] = 1.0
	wolf._hit_statuses(p)
	check(not p.stunned() and p._push == Vector3.ZERO, "a blocked hit carries no status")
	wolf.global_position = Vector3(0, 1, 3)                   # behind
	hp0 = p.hp; p.take_damage(100.0, wolf)
	check(is_equal_approx(hp0 - p.hp, 100.0), "hit from behind is not blocked")
	wolf.global_position = Vector3(0, 1, -3)
	p.block_power = 0.0; await _frames(1)
	check(not p.blocking, "no block-power = no block")
	Input.action_release("special-attack"); await _frames(30)
	check(p.block_power > 0.0, "block-power regenerates while not blocking: %.0f" % p.block_power)
	# --- enemy-hit statuses land when not blocking
	p.hp = p.max_hp
	wolf._hit_statuses(p)
	check(p.stunned(), "creature hit stuns (chance 1)")
	check(p._push.length() > 0.0, "creature hit knocks back (chance 1)")
	var z0: float = p.global_position.z
	await _frames(10)
	check(p.global_position.z > z0 + 0.5, "knockback moved us away from the wolf: %.2f" % (p.global_position.z - z0))
	p.statuses.clear(); p._push = Vector3.ZERO
	df["enemy-hit"]["stun-chance"] = 0.05; df["enemy-hit"]["knockback-chance"] = 0.15
	# --- guardian blocks bare-handed with double power
	var g := _player(&"warrior", &"guardian", Vector3(20, 1, 0))
	await _frames(3)
	check(g.can_block() and is_equal_approx(g.block_max(), float(bl["max"]) * float(bl["guardian-mult"])), "guardian: any weapon, block-power ×%d" % bl["guardian-mult"])
	g.queue_free()
	# --- stealth: assassin sneak
	var a := _player(&"rogue", &"assassin", Vector3(0, 1, 0))
	p.global_position = Vector3(40, 1, 40)
	a.skill_tree.points[&"sneak"] = 1; a.skill_tree.points[&"camouflage"] = 1
	wolf.target = a
	await _frames(3)
	check(is_equal_approx(wolf._aggro_range(), float(design["spawns"]["ai"]["aggro-range"])), "no stealth: full aggro range")
	check(a.abilities.use(o.abilities[&"sneak"]), "sneak used")
	await _frames(30)
	check(a.stealth > 0.1, "sneak fills the stealth bar: %.2f" % a.stealth)
	a.stealth = 1.0; await _frames(1)
	check(wolf._aggro_range() < float(design["spawns"]["ai"]["aggro-range"]) * 0.2, "full stealth: aggro range × ~0.1: %.1f" % wolf._aggro_range())
	wolf.global_position = Vector3(0, 1, -2); await _frames(2)   # inside the basic-attack sphere, physics server synced
	a.stealth = 1.0
	var sl: Dictionary = df["stealth"]
	var w0: float = wolf.hp; var dmg: float = a.weapon["damage"]
	a._swing()
	var dealt: float = w0 - wolf.hp
	var expect: float = dmg * (1.0 + float(sl["attack-mult-at-full"]))
	check(is_equal_approx(dealt, expect) or is_equal_approx(dealt, expect * float(design["crit"]["multiplier"])), "stealth hit ×%.1f (or crit): %.1f vs %.1f" % [1.0 + float(sl["attack-mult-at-full"]), dealt, expect])
	check(is_zero_approx(a.stealth), "a landed hit empties stealth")
	a.abilities.buffs.clear(); a.abilities.cooldowns.clear()
	check(a.abilities.use(o.abilities[&"camouflage"]), "camouflage used")
	await _frames(2)
	check(is_equal_approx(a.stealth, 1.0), "camouflage pins stealth at 1")
	a._swing(); await _frames(2)
	check(is_equal_approx(a.stealth, 1.0), "…and keeps it through a hit")
	a.abilities.buffs.clear(); await _frames(30)
	check(a.stealth < 1.0, "stealth decays without a source: %.2f" % a.stealth)
	# --- dodge rewards per passive: assassin stealth, ninja MP
	a.stealth = 0.0; a.stamina = 100.0
	check(a.dodge(Vector3.RIGHT) and is_equal_approx(a.stealth, float(dg["on-dodge"]["way-of-the-shadows"]["stealth"])), "assassin dodge builds stealth: %.2f" % a.stealth)
	var n := _player(&"rogue", &"ninja", Vector3(60, 1, 0))
	await _frames(3)
	n.mp = 0.0
	check(n.dodge(Vector3.RIGHT) and is_equal_approx(n.mp, float(dg["on-dodge"]["elusiveness"]["mp"])), "ninja dodge gives MP: %.0f" % n.mp)
	print("test_defence: %s" % ("FAILED (%d)" % _failed if _failed > 0 else "ok"))
	quit(1 if _failed > 0 else 0)
