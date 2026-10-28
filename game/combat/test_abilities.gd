## Headless check of §3.3 class abilities (D21): `godot --headless -s game/combat/test_abilities.gd`.
## c-ability-runtime fires, cost rules, then a floor with a wolf: Smash dash + stun + stamina, Cyclone channel ticks,
## War Frenzy buff, Rock Fist dash forward, MP per hit, M2 charged special, mage regen + Fire Explosion burning,
## Healing Stream cast, Bulwark stun immunity and Mana Shield absorb.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Combat := preload("res://game/combat/combat.gd")
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


func _player(
	class_id: StringName, spec: StringName, at: Vector3, points: Dictionary
) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(1, 1.0))
	p.setup_items(o, design, class_id, spec)
	p.position = at
	p.spawn_point = at
	for id in points:
		p.skill_tree.points[id] = points[id]
	return p


## Advance the real runner synchronously: exact boundaries without 26-second wall-clock waits.
func _camouflage_boundaries() -> void:
	for row in [[6, 26.0, 28.0], [7, 27.0, 26.0]]:
		var rank: int = row[0]
		var duration: float = row[1]
		var cooldown: float = row[2]
		var p := _player(&"rogue", &"assassin", Vector3.ZERO, {&"camouflage": rank})
		p.set_physics_process(false)
		var runner = p.abilities
		check(p.use_class_skill(3), "Camouflage %d: initial cast through class slot" % rank)
		check(
			(
				runner.flag("stealth-full")
				and is_equal_approx(runner.buffs[&"camouflage"].left, duration)
				and is_equal_approx(runner.cooldowns[&"camouflage"], cooldown)
			),
			"Camouflage %d: literal duration/cooldown %s/%s" % [rank, duration, cooldown]
		)
		# A rejected use must not refresh either timer.
		runner.tick(1.0)
		check(not p.use_class_skill(3), "Camouflage %d: immediate recast rejected" % rank)
		check(
			(
				is_equal_approx(runner.buffs[&"camouflage"].left, duration - 1.0)
				and is_equal_approx(runner.cooldowns[&"camouflage"], cooldown - 1.0)
			),
			"Camouflage %d: rejected recast leaves both timers untouched" % rank
		)
		runner.tick(24.875)  # t=25.875: before rank-6 expiry / rank-7 cooldown
		if rank == 6:
			check(runner.flag("stealth-full"), "Camouflage 6: active before expiry")
			runner.tick(0.125)
			check(not runner.flag("stealth-full"), "Camouflage 6: expires at 26 seconds")
			check(not p.use_class_skill(3), "Camouflage 6: two-second recast gap begins")
			runner.tick(1.875)
		check(not p.use_class_skill(3), "Camouflage %d: rejected just before cooldown" % rank)
		runner.tick(0.125)
		check(
			runner.flag("stealth-full") == (rank == 7),
			"Camouflage %d: overlap only at seven points" % rank
		)
		check(p.use_class_skill(3), "Camouflage %d: recast at exact cooldown boundary" % rank)
		runner.tick(1.0)  # rank 7 reaches the OLD expiry; refreshed buff must survive it
		check(
			(
				runner.flag("stealth-full")
				and is_equal_approx(runner.buffs[&"camouflage"].left, duration - 1.0)
			),
			"Camouflage %d: recast refreshes duration, not stack/add/old expiry" % rank
		)
		runner.tick(duration - 1.125)
		check(
			runner.flag("stealth-full"), "Camouflage %d: active just before renewed expiry" % rank
		)
		runner.tick(0.125)
		check(not runner.flag("stealth-full"), "Camouflage %d: renewed buff expires exactly" % rank)
		check(
			p.use_class_skill(3) == (rank == 7),
			"Camouflage %d: same recast availability after renewed expiry" % rank
		)
		p.free()


## Commit through the real class slot; retire Bubbles shots before isolating heal arithmetic.
func _start_hot(p, id: StringName, entries := 1) -> bool:
	p.abilities.cooldowns.clear()
	p.combo = 4
	p._combo_t = 2.0
	var used: bool = p.use_class_skill(4)
	check(used, "%s: class slot starts" % id)
	check(
		p.combo == 4 and is_equal_approx(p._combo_t, 2.0),
		"%s: committed heal is combo-neutral" % id
	)
	for shot in root.get_children():
		if shot.get("shooter") == p:
			shot.set_physics_process(false)
			shot._end()
			shot.free()
	# Volley misses resolve combo separately; they must not cancel or duplicate the side heal.
	p.combo = 4
	check(p.abilities.heals.size() == entries, "%s: one heal committed per use" % id)
	return used and p.abilities.heals.size() == entries


func _hot_boundaries() -> void:
	for row in [
		[&"warrior", &"guardian", &"heroic-shout", 10.0, 0.525],
		[&"mage", &"water-mage", &"bubbles", 5.0, 0.2625],
	]:
		var id: StringName = row[2]
		var duration: float = row[3]
		var p := _player(row[0], row[1], Vector3.ZERO, {id: 1})
		p.set_physics_process(false)
		var total: float = p.max_hp * float(row[4])  # selected heal fraction × rank-1 effect
		for parts in [[duration], [duration - 0.1, 0.2], [duration * 2.0]]:
			p.abilities.reset()
			p.hp = 10.0
			if not _start_hot(p, id):
				continue
			check(
				(
					is_equal_approx(p.abilities.heals[0]["per-s"], total / duration)
					and is_equal_approx(p.abilities.heals[0]["left"], duration)
					and is_equal_approx(p.hp, 10.0)
				),
				"%s: selected rate/duration, no immediate healing" % id
			)
			for dt in parts:
				p.abilities.tick(dt)
			check(
				is_equal_approx(p.hp - 10.0, total),
				"%s %s: bounded total %.6f, got %.6f" % [id, parts, total, p.hp - 10.0]
			)
			check(p.abilities.heals.is_empty(), "%s %s: expired" % [id, parts])
			var hp: float = p.hp
			p.abilities.tick(duration)
			check(is_equal_approx(p.hp, hp), "%s: no post-expiry healing" % id)
			check(
				p.combo == 4 and is_equal_approx(p._combo_t, 2.0),
				"%s: healing ticks neither resolve nor refresh combo" % id
			)
		# Two real uses, staggered by half a lifetime; isolate HP so the cap cannot hide excess.
		p.hp = 10.0
		if _start_hot(p, id):
			p.abilities.tick(duration * 0.5)
			check(is_equal_approx(p.hp - 10.0, total * 0.5), "%s: half-lifetime heal" % id)
			if _start_hot(p, id, 2):
				p.hp = 10.0
				p.abilities.tick(duration * 0.75)
				check(
					is_equal_approx(p.hp - 10.0, total * 1.25),
					"%s: staggered entries clip independently" % id
				)
				check(p.abilities.heals.size() == 1, "%s: only older entry expires" % id)
				p.hp = 10.0
				p.abilities.tick(duration)
				check(
					is_equal_approx(p.hp - 10.0, total * 0.25) and p.abilities.heals.is_empty(),
					"%s: younger entry keeps only its remaining quarter" % id
				)
		p.abilities.reset()
		p.hp = p.max_hp - 1.0
		if _start_hot(p, id):
			p.abilities.tick(duration * 0.5)
			check(
				p.hp == p.max_hp and p.abilities.heals.size() == 1,
				"%s: reaching max HP does not end the lifetime early" % id
			)
			p.hp -= 1.0
			p.abilities.tick(duration)
			check(
				p.hp == p.max_hp and p.abilities.heals.is_empty(),
				"%s: HP cap and full lifetime preserved" % id
			)
		for die in [false, true]:
			p.abilities.reset()
			p.hp = 10.0
			if not _start_hot(p, id):
				continue
			p.abilities.tick(0.1)
			if die:
				p.take_damage(p.max_hp * 2.0, null)
				check(p.dead and p.hp == 0.0, "%s: actual death precondition" % id)
			else:
				p.abilities.reset()
			var hp: float = p.hp
			check(p.abilities.heals.is_empty(), "%s: reset/death clears active heal" % id)
			p.abilities.tick(duration * 2.0)
			check(is_equal_approx(p.hp, hp), "%s: no healing after reset/death" % id)
		p.free()


func _init() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs["generators"]["design"]
	var ab: Dictionary = design["abilities"]
	# c-ability-runtime fires
	ab["smash"]["runtime"] = "fly"
	check(not o.validate(), "c-ability-runtime rejects an unknown runtime")
	o.errors.clear()
	ab["smash"]["runtime"] = "dash"
	ab["smash"]["cost"]["mp"] = 150
	check(not o.validate(), "c-ability-runtime rejects mp cost > 100")
	o.errors.clear()
	ab["smash"]["cost"].erase("mp")
	check(o.validate(), "restored")
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	_camouflage_boundaries()
	await process_frame  # HoT fixtures need ready cameras and an active tree for actual death.
	_hot_boundaries()
	var floor := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	cs.shape = box
	floor.add_child(cs)
	floor.position.y = -0.5
	root.add_child(floor)
	var p := _player(
		&"warrior",
		&"berserker",
		Vector3(0, 1, 0),
		{&"smash": 5, &"cyclone": 1, &"war-frenzy": 1, &"rock-fist": 1}
	)
	var holder := Node3D.new()
	root.add_child(holder)
	var wolf: CharacterBody3D = (
		Spawner
		. populate(
			holder,
			[
				{
					"species": &"wolf",
					"level": 1,
					"hostility": &"H",
					"max_hp": 1e6,
					"damage": 0.0,
					"positions": [Vector3(0, 1, -4)],
					"seed": 1
				}
			],
			design,
			o.creatures,
			p,
			null
		)[0]
	)
	await _frames(5)
	var dmg: float = p.weapon["damage"]
	# cost rule: 'all' below all-min refuses, else empties the bar
	p.stamina = 5.0
	check(
		not p.abilities.pay({"stamina": "all"}) and is_equal_approx(p.stamina, 5.0),
		"'all' needs all-min, nothing spent"
	)
	p.stamina = 40.0
	check(
		p.abilities.pay({"stamina": "all"}) and is_zero_approx(p.stamina), "'all' empties the bar"
	)
	check(not p.use_class_skill(1), "smash refused without 100 stamina")
	# Smash: dash to one block short of the wolf, strike ×2 (5 points: ×1.25), stun, 100 stamina, cooldown 10 × 0.75
	p.stamina = 100.0
	var hp0: float = wolf.hp
	check(p.use_class_skill(1) and not p.abilities.dash.is_empty(), "smash starts a dash")
	await _frames(12)
	var expected := Combat.after_armor(dmg * 2.0 * 1.25, wolf.armor, design["combat"])
	check(
		is_equal_approx(hp0 - wolf.hp, expected),
		"smash = weapon × 2 × 1.25 after armor: %.1f vs %.1f" % [hp0 - wolf.hp, expected]
	)
	check(
		p.abilities.dash.is_empty() and p.position.distance_to(wolf.position) < 2.5,
		"dash stopped next to the wolf (it walks toward us): %s" % p.position
	)
	check(wolf.stunned() and is_zero_approx(p.stamina), "wolf stunned, stamina spent")
	check(
		not p.use_class_skill(1) and p.abilities.cooldowns[&"smash"] > 7.0,
		"second smash blocked by the cooldown"
	)
	# Cyclone: one clockwise turn/s; front hit now, next front pass at 1s; 25 + 25/s stamina.
	p.stamina = 100.0
	hp0 = wolf.hp
	check(p.use_class_skill(2) and p.abilities.busy(), "cyclone channels")
	await _frames(31)
	var ticks := int(
		round((hp0 - wolf.hp) / Combat.after_armor(dmg * 0.5 * 1.05, wolf.armor, design["combat"]))
	)
	check(ticks == 1, "cyclone reaches front once in the first 0.5s: %d" % ticks)
	check(
		p.stamina < 75.0 - 10.0 and p.stamina > 75.0 - 20.0,
		"cyclone stamina 25 + 25/s: %.1f" % p.stamina
	)
	p.abilities.reset()
	# War Frenzy: damage buff ×1.2 for 10 × 1.05 s, basic hits give MP
	check(
		(
			p.use_class_skill(3)
			and is_equal_approx(p.abilities.mult("damage-mult"), 1.2)
			and p.abilities.buffs[&"war-frenzy"]["left"] > 10.0
		),
		"war frenzy buff"
	)
	await _frames(35)
	p.combo = 0  # isolate the buff multiplier; prior class hits now build combo
	hp0 = wolf.hp
	p._swing()
	check(
		is_equal_approx(hp0 - wolf.hp, Combat.after_armor(dmg * 1.2, wolf.armor, design["combat"])),
		"basic hit ×1.2 under war frenzy"
	)
	check(is_equal_approx(p.mp, 8.0), "a landed hit gives 8 MP: %.1f" % p.mp)
	# M2 special: below min-mp nothing; held 0.5 s under war frenzy (charge-mult 2) charges ~50 MP → ×(1 + f × 1.5)
	Input.action_press("special-attack")
	await physics_frame
	Input.action_release("special-attack")
	await physics_frame
	check(is_equal_approx(p.mp, 8.0), "M2 below min-mp does nothing")
	p.mp = 100.0
	hp0 = wolf.hp
	Input.action_press("special-attack")
	await _frames(30)
	check(
		p._charge > 40.0 and p._charge <= 50.0,
		"M2 held 0.5 s at 50/s × 2 charges ~50 MP: %.1f" % p._charge
	)
	Input.action_release("special-attack")
	await _frames(2)
	var charged: float = 100.0 - p.mp
	check(
		charged > 40.0 and charged <= 52.0 and p._charge < 0.0,
		"release spends the charge: mp %.1f" % p.mp
	)
	var f := charged / 100.0
	check(
		is_equal_approx(
			hp0 - wolf.hp,
			Combat.after_armor(dmg * (1.0 + f * 1.5) * 1.2, wolf.armor, design["combat"])
		),
		"special damage grows with MP spent"
	)
	# Rock Fist: dash forward (−Z) 10 blocks or until a wall; the wolf is in the way → strike ×3, knockback + stun
	await _frames(int(2.5 * 60))  # wolf's stun ends
	p.position = Vector3(0, 1, 6)
	p.abilities.buffs.clear()
	wolf.position = Vector3(0, 1, -4)
	wolf.velocity = Vector3.ZERO
	await _frames(2)
	hp0 = wolf.hp
	check(p.use_class_skill(4), "rock fist (ultimate, key 4)")
	await _frames(40)
	check(
		hp0 - wolf.hp > 0.0 and p.position.z < 0.0,
		(
			"rock fist charged forward and hit: moved to z %.1f, dmg %.1f"
			% [p.position.z, hp0 - wolf.hp]
		)
	)
	check(wolf.stunned() and wolf.velocity.length() > 0.0, "wolf stunned and knocked back")
	# Mage: passive MP regen; Fire Explosion burns; Healing Stream casts; Mana Shield absorbs; Bulwark stun immunity
	var fm := _player(&"mage", &"fire-mage", Vector3(3, 1, -4), {&"fire-explosion": 1})
	check(fm.mp_passive and fm.special_mode == &"charged", "mage regenerates MP passively")
	await _frames(60)
	check(fm.mp > 4.0 and fm.mp < 6.0, "mage +5 MP/s: %.1f" % fm.mp)
	await _frames(int(2.5 * 60))
	fm.mp = 100.0
	hp0 = wolf.hp
	check(fm.use_class_skill(1) and is_equal_approx(fm.mp, 50.0), "fire explosion costs 50 MP")
	var burst: float = hp0 - wolf.hp
	check(
		burst > 0.0 and wolf.statuses.has(&"burning") and wolf.stunned(),
		"explosion hits, burns, stuns"
	)
	await _frames(35)
	check(
		hp0 - wolf.hp > burst * 1.05,
		"burning ticks after the hit: %.1f > %.1f" % [hp0 - wolf.hp, burst]
	)
	var wm := _player(
		&"mage", &"water-mage", Vector3(-3, 1, -4), {&"healing-stream": 1, &"mana-shield": 1}
	)
	wm.mp = 100.0
	wm.hp = 10.0
	check(
		wm.use_class_skill(1) and wm.abilities.busy() and is_equal_approx(wm.hp, 10.0),
		"healing stream casts first"
	)
	await _frames(int(1.5 * 60) + 3)
	check(
		is_equal_approx(wm.hp, minf(wm.max_hp, 10.0 + wm.max_hp * 0.5 * 1.05)),
		"heal 50 %% × 1.05 after the cast: %.1f / %.1f" % [wm.hp, wm.max_hp]
	)
	check(wm.use_class_skill(2), "mana shield")
	var before: float = wm.hp
	wm.take_damage(10.0, wolf)
	check(
		(
			is_equal_approx(wm.hp, before)
			and is_equal_approx(wm.abilities.buffs[&"mana-shield"]["pool"], wm.max_hp * 0.3 - 10.0)
		),
		"shield absorbs 10 of its pool"
	)
	var gd := _player(&"warrior", &"guardian", Vector3(0, 1, 8), {&"bulwark": 1})
	check(gd.use_class_skill(3) and gd.stun_immune(), "bulwark: stun immune")
	gd.apply_status(&"stun", design["status-effects"]["stun"], 0.0, wolf)
	check(not gd.stunned(), "stun ignored under bulwark")
	before = gd.hp
	gd.take_damage(20.0, wolf)
	check(is_equal_approx(before - gd.hp, 10.0), "bulwark halves damage taken")
	print("abilities ok" if _failed == 0 else "abilities FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
