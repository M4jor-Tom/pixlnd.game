## Item 10: class strikes share landed-hit bookkeeping; channels miss only as a whole; taunts are neutral.
## Run: godot --headless -s game/combat/test_class_combos.gd
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Spawner := preload("res://game/world/spawner.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")

var _failed := 0
var o
var design: Dictionary

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _init() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _player(class_id: StringName, spec: StringName, at: Vector3, points: Dictionary) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate(); p.position = at; root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, 260.0)
	p.setup_items(o, design, class_id, spec)
	p.skill_tree.points = points
	p.weapon["damage"] = 40.0                            # hand-checkable fixture; keep the actual weapon's cap
	p.set_physics_process(false)                        # manual runtime ticks, no incidental inputs or timer expiry
	return p

func _wolf(p: Node, at: Vector3) -> CharacterBody3D:
	var holder := Node3D.new(); root.add_child(holder)
	var w: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"N", "max_hp": 1e6,
		"damage": 0.0, "positions": [at], "seed": 1}], design, o.creatures, p, null)[0]
	w.set_physics_process(false); w.armor = 0.0
	return w

func _run() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs["generators"]["design"]
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var p := _player(&"warrior", &"berserker", Vector3.ZERO, {&"smash": 1, &"cyclone": 1, &"war-frenzy": 1})
	var wolf := _wolf(p, Vector3(0, 0, -2))
	var mage := _player(&"mage", &"fire-mage", Vector3(40, 0, 0), {&"fire-explosion": 1, &"teleport": 1})
	var w1 := _wolf(mage, Vector3(40, 0, -2))
	var w2 := _wolf(mage, Vector3(41, 0, -2))
	await _frames(2)
	# A damaging AoE counts once per successful strike, not once per target; no basic-hit MP/finisher reward.
	for landed in [true, false]:
		w1.position.z = -2.0 if landed else -50.0; w2.position.z = w1.position.z
		await _frames(2)
		mage.combo = 4; mage._combo_t = 1.0; mage._m1_hits = 7; mage.mp = 100.0
		mage.abilities.cooldowns.clear()
		var hp1: float = w1.hp; var hp2: float = w2.hp
		check(mage.use_class_skill(1), "fire explosion starts")
		check(mage.combo == (5 if landed else 0), "burst increments once on hit / resets on miss: %d" % mage.combo)
		check(is_equal_approx(mage._combo_t, 5.0 if landed else 1.0), "burst refreshes inactivity only on hit")
		check(is_equal_approx(mage.mp, 50.0) and mage._m1_hits == 7, "class hit keeps cost, gives no M1 MP or finisher reward")
		check(is_equal_approx(mage.abilities.cooldowns[&"fire-explosion"], 9.5), "class hit keeps the point-scaled cooldown")
		check(is_equal_approx(hp1 - w1.hp, 84.0 if landed else 0.0) and is_equal_approx(hp2 - w2.hp, 84.0 if landed else 0.0), "burst damage unchanged: 40 × 2 × 1.05 per target")
	# Dash strikes resolve the combo at impact, not on starting the dash.
	for landed in [true, false]:
		wolf.position.z = -2.0 if landed else -50.0
		await _frames(2)
		p.combo = 4; p._combo_t = 1.0; p.stamina = 100.0; p.abilities.cooldowns.clear()
		var hp0: float = wolf.hp
		check(p.use_class_skill(1) and p.combo == 4, "smash launch does not settle combo before its strike")
		p.abilities.after_move(1.0)                       # finish the real dash at the fixture position
		check(p.abilities.dash.is_empty() and p.combo == (5 if landed else 0), "dash impact counts hit / resets miss")
		check(is_equal_approx(hp0 - wolf.hp, 84.0 if landed else 0.0) and is_zero_approx(p.stamina), "smash damage and 100-stamina cost unchanged")
	# Channel misses: empty ticks preserve the chain until normal duration, stamina exhaustion or reset ends it.
	for ending in ["duration", "stamina", "reset"]:
		p.abilities.cooldowns.clear(); p.stamina = 100.0; p.combo = 4; p._combo_t = 2.0
		check(p.use_class_skill(2), ending + ": cyclone starts")
		p.abilities.tick(0.25)
		check(p.combo == 4 and is_equal_approx(p._combo_t, 2.0), ending + ": empty tick neither resets nor refreshes")
		match ending:
			"duration":
				for i in 19:
					p.stamina = 100.0                   # keep enough fuel to reach the configured 5-second duration
					p.abilities.tick(0.25)
			"stamina":
				p.stamina = 0.1; p.abilities.tick(0.01)
			"reset":
				p.abilities.reset()
		check(p.abilities.channel.is_empty() and p.combo == 0, ending + ": wholly missed channel resets on end")
	# Late hits and multiple ticks gain normally; later misses and early/normal ends do not undo those hits.
	for ending in ["duration", "stamina", "reset"]:
		wolf.position.z = -50.0; await _frames(2)
		p.abilities.cooldowns.clear(); p.stamina = 100.0; p.combo = 4; p._combo_t = 2.0
		check(p.use_class_skill(2), ending + ": mixed channel starts")
		p.abilities.tick(0.25)
		check(p.combo == 4, ending + ": miss before first hit is not final")
		wolf.position.z = -2.0; await _frames(2)
		var hp0: float = wolf.hp
		p.abilities.tick(0.25); p.abilities.tick(0.25)
		check(p.combo == 6 and is_equal_approx(p._combo_t, 5.0), ending + ": successful ticks gain and refresh normally")
		check(is_equal_approx(hp0 - wolf.hp, 42.0) and is_equal_approx(p.stamina, 56.25), ending + ": two 21-damage ticks; unchanged 25 + 25/s stamina")
		wolf.position.z = -50.0; await _frames(2)
		p._combo_t = 0.7
		match ending:
			"duration":
				for i in 17:
					p.stamina = 100.0; p.abilities.tick(0.25)
			"stamina":
				p.stamina = 0.1; p.abilities.tick(0.01)
			"reset":
				p.abilities.reset()
		check(p.abilities.channel.is_empty() and p.combo == 6 and is_equal_approx(p._combo_t, 0.7), ending + ": earlier hit prevents end/miss reset, no timer refresh")
	# Normal inactivity still expires during a channel; its remembered hit must never resurrect an expired combo.
	wolf.position.z = -2.0; await _frames(2)
	p.abilities.cooldowns.clear(); p.stamina = 100.0; p.combo = 4
	check(p.use_class_skill(2), "inactivity channel starts")
	p.abilities.tick(0.25)
	wolf.position.z = -50.0; await _frames(2)
	p._combo_t = 0.1; p._combat_tick(0.2)
	check(p.combo == 0 and not p.abilities.channel.is_empty(), "normal inactivity expires mid-channel")
	p.abilities.reset()
	check(p.combo == 0, "ending a previously successful channel does not revive an expired combo")
	# Per-weapon cap applies to successful class strikes and ticks, including refreshing at the cap.
	wolf.position.z = -2.0; await _frames(2)
	p.abilities.cooldowns.clear(); p.stamina = 100.0; p.combo = 29; p._combo_t = 1.0
	check(p.use_class_skill(2), "cap channel starts")
	p.abilities.tick(0.25); p.abilities.tick(0.25)
	check(p.combo == 30 and is_equal_approx(p._combo_t, 5.0), "sword cap remains 30, hits at cap still refresh")
	p.abilities.reset()
	w1.position.z = -2.0; await _frames(2)
	for i in 2:
		mage.abilities.cooldowns.clear(); mage.mp = 100.0; mage.combo = 49 if i == 0 else mage.combo; mage._combo_t = 1.0
		check(mage.use_class_skill(1), "cap burst starts")
		check(mage.combo == 50 and is_equal_approx(mage._combo_t, 5.0), "staff cap remains 50 for class bursts")
	# Heroic Shout: real taunt/provocation and healing remain, with no combo effect even when no target is present.
	var guardian := _player(&"warrior", &"guardian", Vector3(80, 0, 0), {&"heroic-shout": 1})
	var taunted := _wolf(guardian, Vector3(80, 0, -2))
	for in_range in [true, false]:
		taunted.position.z = -2.0 if in_range else -50.0
		taunted.provoked = false; taunted.target = null
		await _frames(2)
		guardian.combo = 4; guardian._combo_t = 1.0; guardian.hp = 10.0; guardian.abilities.cooldowns.clear()
		guardian.abilities.heals.clear()
		var hp0: float = taunted.hp
		check(guardian.use_class_skill(4), "heroic shout starts")
		check(guardian.combo == 4 and is_equal_approx(guardian._combo_t, 1.0), "taunt neither increments, resets nor refreshes combo")
		check(taunted.provoked == in_range and (taunted.target == guardian if in_range else taunted.target == null) and is_equal_approx(taunted.hp, hp0), "zero damage and existing taunt targeting preserved")
		guardian._combat_tick(0.5)
		check(is_equal_approx(guardian.hp, 16.825), "shout heals 50% × 1.05 over 10 seconds unchanged")
		guardian._combat_tick(0.6)
		check(guardian.combo == 0, "taunt healing does not keep combo alive")
	# Non-attacking buff, movement and heal paths must not become false misses.
	p.combo = 4; p._combo_t = 1.0; p.abilities.cooldowns.clear()
	check(p.use_class_skill(3) and p.combo == 4 and is_equal_approx(p._combo_t, 1.0), "buff has no combo result")
	mage.combo = 4; mage._combo_t = 1.0; mage.mp = 100.0
	check(mage.use_class_skill(3), "teleport starts")
	mage.abilities.after_move(1.0)
	check(mage.combo == 4 and is_equal_approx(mage._combo_t, 1.0), "movement-only dash has no combo result")
	var water := _player(&"mage", &"water-mage", Vector3(120, 0, 0), {&"healing-stream": 1, &"bubbles": 1})
	water.combo = 4; water._combo_t = 1.0; water.hp = 10.0; water.mp = 100.0
	check(water.use_class_skill(1), "healing stream starts")
	water.abilities.tick(1.5)
	check(water.combo == 4 and is_equal_approx(water._combo_t, 1.0) and is_equal_approx(water.hp, 146.5), "cast heals without a false combo miss or refresh")
	check(water.use_class_skill(4), "bubbles starts")
	check(water.combo == 4 and is_equal_approx(water._combo_t, 1.0), "projectile's side heal does not resolve combo before shots")
	# The existing volley path, not the heal, resolves its hit/miss exactly once.
	for shot in root.get_children():
		if shot.get("shot") != null:
			shot.set_physics_process(false)
			shot._end()
	check(water.combo == 0, "wholly missed class volley retains its existing reset")
	print("class combos ok" if _failed == 0 else "class combos FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
