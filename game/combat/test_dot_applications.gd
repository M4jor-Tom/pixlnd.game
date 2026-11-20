## Independent hit-derived DOT schedules and synchronous lifecycle regressions.
extends SceneTree
const Domain := preload("res://game/domain/domain.gd")
const Entity := preload("res://game/entities/entity.gd")
var failed := 0
var se: Dictionary
var design: Dictionary


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func target():
	var e := Entity.new()
	e.hp = 10000
	e.max_hp = 10000
	root.add_child(e)
	return e


func loss(e, want: float, label: String) -> void:
	check(
		is_equal_approx(10000 - e.hp, want), "%s: lost %s expected %s" % [label, 10000 - e.hp, want]
	)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var o = Domain.Ontology.load_dir()
	check(o.errors.is_empty(), "ontology valid")
	design = o.configs.generators.design
	se = design["status-effects"]
	_schedules()
	_independent_sources()
	_mixed_staggers()
	_source_lifetime()
	_synchronous_clear()
	_callback_applications()
	_lethal_clear()
	_player_defence(o)
	_lethal_bite()
	print("DOT applications ok" if failed == 0 else "DOT applications FAILED: %d" % failed)
	quit(0 if failed == 0 else 1)


func _schedules() -> void:
	# Resetting the first timer to zero, skipping the final tick or catching only one due tick must fail.
	for id in [&"burning", &"poison"]:
		_schedule(id)


func _independent_sources() -> void:
	# Same-time and staggered applications neither replace nor renew each other; sources remain distinct.
	for id in [&"burning", &"poison"]:
		for stagger in [0.0, 2.0]:
			_source_pair(id, stagger)


func _mixed_staggers() -> void:
	var staggered = target()
	staggered.apply_status(&"burning", se.burning, 100, staggered)
	staggered.tick_statuses(.25)
	staggered.apply_status(&"burning", se.burning, 50, staggered)
	staggered.tick_statuses(.249)
	loss(staggered, 0, "off-grid stagger not early")
	staggered.tick_statuses(.001)
	loss(staggered, 10, "later burn does not reset original next tick")
	staggered.tick_statuses(.25)
	loss(staggered, 15, "later burn has own first tick")
	staggered.tick_statuses(3.25)
	loss(staggered, 115, "off-grid original terminal tick")
	staggered.tick_statuses(.25)
	loss(staggered, 120, "off-grid later terminal tick")
	staggered.free()
	var e = target()
	e.apply_status(&"burning", se.burning, 100, e)
	e.apply_status(&"poison", se.poison, 50, e)
	e.tick_statuses(.5)
	loss(e, 10, "mixed first burn")
	e.tick_statuses(.5)
	loss(e, 70, "mixed due burn and poison")
	e.tick_statuses(20)
	loss(e, 330, "mixed full totals")
	e.free()


func _source_lifetime() -> void:
	# Freely injected values, not hardcoded runtime constants.
	var e = target()
	e.apply_status(&"burning", {"duration-s": 1.5, "tick-s": .5, "pct-of-hit": .2}, 50, null)
	e.tick_statuses(20)
	loss(e, 30, "injected config and null attacker")
	e.free()
	e = target()
	var source = target()
	var safe: Array = []
	e.apply_status(&"poison", se.poison, 10, source)
	source.free()
	e.damaged.connect(func(_amount, from): safe.append(from == e))
	e.tick_statuses(20)
	loss(e, 50, "freed source still ticks")
	check(safe.size() == 5 and safe.all(func(ok): return ok), "freed source uses self fallback")
	e.free()


func _synchronous_clear() -> void:
	# A signal may clear synchronously, including clear + reapplication of the same status id.
	for replace in [false, true]:
		var e = target()
		var victim = e
		e.apply_status(&"burning", se.burning, 100, e)
		e.apply_status(&"poison", se.poison, 50, e)
		e.damaged.connect(
			func(_amount, _from):
				victim.statuses.clear()
				if replace:
					victim.apply_status(&"burning", se.burning, 10, victim),
			CONNECT_ONE_SHOT
		)
		e.tick_statuses(20)
		loss(e, 10, "synchronous clear stops old applications")
		e.tick_statuses(.5)
		loss(e, 11 if replace else 10, "clear never resurrects old stacks")
		e.free()


func _callback_applications() -> void:
	# Later effects must use update-entry list AND application identities, not callback additions.
	for first in [&"burning", &"poison"]:
		var later := &"poison" if first == &"burning" else &"burning"
		for replace in [false, true]:
			_callback_application(first, later, replace)


func _lethal_clear() -> void:
	var e = target()
	e.hp = 5
	var deaths: Array = []
	e.died.connect(
		func():
			deaths.append(true)
			e.statuses.clear()
	)
	e.apply_status(&"burning", se.burning, 100, e)
	e.apply_status(&"poison", se.poison, 50, e)
	e.tick_statuses(20)
	_lethal_result(e, deaths)
	_dead_admission(e)


func _player_defence(o) -> void:
	# Due ticks reuse the real player's block -> buff -> shield path once each, even on catchup.
	var player = preload("res://game/entities/player.tscn").instantiate()
	root.add_child(player)
	player.setup(design.movement, design.camera, &"normal")
	player.setup_combat(design.combat, design.crit, {}, 260)
	player.setup_items(o, design)
	player.set_physics_process(false)
	var attacker = target()
	attacker.position.z = -1
	player.apply_status(&"burning", se.burning, 100, attacker)
	player.abilities.buffs[&"bulwark"] = {"left": 10, "r": design.abilities.bulwark}
	player.abilities.buffs[&"mana-shield"] = {
		"left": 10, "r": design.abilities["mana-shield"], "pool": 1.5
	}
	player.blocking = true
	player.mp = 0
	player.tick_statuses(1.0)
	check(
		(
			is_equal_approx(player.hp, 267.0)
			and is_equal_approx(player.block_power, 50)
			and is_equal_approx(player.mp, 16)
		),
		"two caught-up ticks each traverse block, buff and shield once"
	)
	player.free()
	attacker.free()


func _lethal_bite() -> void:
	# A creature killed during its real physics entry point must not finish a queued bite.
	var prey = target()
	var creature = preload("res://game/entities/creature.tscn").instantiate()
	root.add_child(creature)
	creature.setup(
		&"wolf",
		1,
		5,
		12,
		&"H",
		design.spawns.ai,
		design.combat["enemy-attack"],
		1.2,
		Color.WHITE,
		1
	)
	creature.set_physics_process(false)
	creature.target = prey
	creature.state = creature.State.ATTACK
	creature._windup = 0
	creature.apply_status(&"poison", se.poison, 10, prey)
	creature._physics_process(1.0)
	check(
		creature.dead and prey.hp == 10000, "lethal creature DOT stops queued attack in same frame"
	)
	creature.free()
	prey.free()


func _source_pair(id, stagger) -> void:
	var e = target()
	var a = target()
	var b = target()
	var hits: Array = []
	e.damaged.connect(func(amount, source): hits.append([amount, source]))
	e.apply_status(id, se[id], 100, a)
	e.tick_statuses(stagger)
	e.apply_status(id, se[id], 50, b)
	e.tick_statuses(4.0 - stagger if id == &"burning" else 5.0 - stagger)
	_original_expiry(e, id, stagger)
	if stagger > 0:
		e.tick_statuses(stagger - .001)
		loss(e, 115 if id == &"burning" else 700, str(id) + " delayed second terminal tick")
		e.tick_statuses(.001)
		loss(e, 120 if id == &"burning" else 750, str(id) + " own terminal tick")
	e.tick_statuses(20)
	loss(e, 120 if id == &"burning" else 750, str(id) + " independent totals")
	_source_hits(hits, a, b, id)
	e.free()
	a.free()
	b.free()


func _callback_application(first, later, replace) -> void:
	var e = target()
	var victim = e
	e.apply_status(first, se[first], 100, e)
	e.apply_status(later, se[later], 50, e)
	e.damaged.connect(
		func(_amount, _from):
			if replace:
				victim.statuses.clear()
			victim.apply_status(later, se[later], 10, victim),
		CONNECT_ONE_SHOT
	)
	e.tick_statuses(20)
	_callback_lifetime(e, first, later, replace)
	e.free()


func _schedule(id) -> void:
	var interval := .5 if id == &"burning" else 1.0
	var count := 8 if id == &"burning" else 5
	var damage := 10.0 if id == &"burning" else 100.0
	var e = target()
	e.apply_status(id, se[id], 100, e)
	e.tick_statuses(interval - .001)
	loss(e, 0, str(id) + " no early first tick")
	e.tick_statuses(.001)
	loss(e, damage, str(id) + " first tick")
	for n in range(2, count + 1):
		e.tick_statuses(interval - .001)
		loss(e, damage * (n - 1), str(id) + " not early " + str(n))
		e.tick_statuses(.001)
		loss(e, damage * n, str(id) + " due " + str(n))
	e.tick_statuses(20)
	loss(e, damage * count, str(id) + " no expired tick")
	check(e.statuses.is_empty(), str(id) + " expires after terminal tick")
	e.free()
	for steps in [[20.0], [.1, .2, .7, 1.3, .4, 2.3, 5.0]]:
		e = target()
		e.apply_status(id, se[id], 100, e)
		for dt in steps:
			e.tick_statuses(dt)
		loss(e, damage * count, str(id) + " coarse/fragmented catchup")
		e.free()


func _dead_admission(e) -> void:
	e.apply_status(&"burning", se.burning, 100, e)
	e.apply_status(&"slow", se.slow, 100, e)
	check(e.statuses.is_empty(), "dead entities cannot regain attached effects")
	e.free()


func _source_hits(hits, a, b, id) -> void:
	check(
		(
			(
				hits
				. filter(func(h): return h[1] == a and h[0] == (10 if id == &"burning" else 100))
				. size()
			)
			== (8 if id == &"burning" else 5)
		),
		str(id) + " first source/damage"
	)
	_second_source_hits(hits, b, id)


func _callback_lifetime(e, first, later, replace) -> void:
	var initial_loss := (
		(10.0 if first == &"burning" else 100.0)
		if replace
		else (330.0 if first == &"burning" else 540.0)
	)
	var label := "%s -> %s %s" % [first, later, "replacement" if replace else "append"]
	loss(e, initial_loss, label + " does not age callback application")
	var interval := 1.0 if later == &"poison" else .5
	var damage := 10.0 if later == &"poison" else 1.0
	_callback_wait(e, initial_loss, interval, damage, later, label)


func _lethal_result(e, deaths) -> void:
	check(
		e.dead and e.hp == 0 and deaths.size() == 1 and e.statuses.is_empty() and not e.dot_tick,
		"lethal catchup stops and clears safely"
	)


func _original_expiry(e, id, stagger) -> void:
	loss(
		e,
		(
			(120.0 if id == &"burning" else 750.0)
			if stagger == 0
			else (100.0 if id == &"burning" else 650.0)
		),
		str(id) + " original expiry"
	)


func _second_source_hits(hits, b, id) -> void:
	check(
		(
			(
				hits
				. filter(func(h): return h[1] == b and h[0] == (5 if id == &"burning" else 50))
				. size()
			)
			== (8 if id == &"burning" else 5)
		),
		str(id) + " second source/damage"
	)


func _callback_wait(e, initial_loss, interval, damage, later, label) -> void:
	e.tick_statuses(interval - .001)
	loss(e, initial_loss, label + " waits full first interval")
	e.tick_statuses(.001)
	loss(e, initial_loss + damage, label + " own first tick")
	e.tick_statuses(20)
	loss(e, initial_loss + (50 if later == &"poison" else 8), label + " retains whole lifetime")
