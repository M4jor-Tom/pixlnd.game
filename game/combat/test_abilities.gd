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

func _player(class_id: StringName, spec: StringName, at: Vector3, points: Dictionary) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(1, 1.0))
	p.setup_items(o, design, class_id, spec)
	p.position = at; p.spawn_point = at
	for id in points:
		p.skill_tree.points[id] = points[id]
	return p

func _init() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs["generators"]["design"]
	var ab: Dictionary = design["abilities"]
	# c-ability-runtime fires
	ab["smash"]["runtime"] = "fly"
	check(not o.validate(), "c-ability-runtime rejects an unknown runtime"); o.errors.clear()
	ab["smash"]["runtime"] = "dash"; ab["smash"]["cost"]["mp"] = 150
	check(not o.validate(), "c-ability-runtime rejects mp cost > 100"); o.errors.clear()
	ab["smash"]["cost"].erase("mp"); check(o.validate(), "restored")
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)
	var p := _player(&"warrior", &"berserker", Vector3(0, 1, 0), {&"smash": 5, &"cyclone": 1, &"war-frenzy": 1, &"rock-fist": 1})
	var holder := Node3D.new(); root.add_child(holder)
	var wolf: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"H", "max_hp": 1e6, "damage": 0.0,
		"positions": [Vector3(0, 1, -4)], "seed": 1}], design, o.creatures, p, null)[0]
	await _frames(5)
	var dmg: float = p.weapon["damage"]
	# cost rule: 'all' below all-min refuses, else empties the bar
	p.stamina = 5.0
	check(not p.abilities.pay({"stamina": "all"}) and is_equal_approx(p.stamina, 5.0), "'all' needs all-min, nothing spent")
	p.stamina = 40.0
	check(p.abilities.pay({"stamina": "all"}) and is_zero_approx(p.stamina), "'all' empties the bar")
	check(not p.use_class_skill(1), "smash refused without 100 stamina")
	# Smash: dash to one block short of the wolf, strike ×2 (5 points: ×1.25), stun, 100 stamina, cooldown 10 × 0.75
	p.stamina = 100.0
	var hp0: float = wolf.hp
	check(p.use_class_skill(1) and not p.abilities.dash.is_empty(), "smash starts a dash")
	await _frames(12)
	var expected := Combat.after_armor(dmg * 2.0 * 1.25, wolf.armor, design["combat"])
	check(is_equal_approx(hp0 - wolf.hp, expected), "smash = weapon × 2 × 1.25 after armor: %.1f vs %.1f" % [hp0 - wolf.hp, expected])
	check(p.abilities.dash.is_empty() and p.position.distance_to(wolf.position) < 2.5, "dash stopped next to the wolf (it walks toward us): %s" % p.position)
	check(wolf.stunned() and is_zero_approx(p.stamina), "wolf stunned, stamina spent")
	check(not p.use_class_skill(1) and p.abilities.cooldowns[&"smash"] > 7.0, "second smash blocked by the cooldown")
	# Cyclone: channel 5 s, ticks every 0.25 s within 3 blocks, 25 + 25/s stamina, no basic attack meanwhile
	p.stamina = 100.0; hp0 = wolf.hp
	check(p.use_class_skill(2) and p.abilities.busy(), "cyclone channels")
	await _frames(31)
	var ticks := int(round((hp0 - wolf.hp) / Combat.after_armor(dmg * 0.5 * 1.05, wolf.armor, design["combat"])))
	check(ticks >= 2 and ticks <= 4, "cyclone ticked %d times in 0.5 s" % ticks)
	check(p.stamina < 75.0 - 10.0 and p.stamina > 75.0 - 20.0, "cyclone stamina 25 + 25/s: %.1f" % p.stamina)
	p.abilities.channel = {}
	# War Frenzy: damage buff ×1.2 for 10 × 1.05 s, basic hits give MP
	check(p.use_class_skill(3) and is_equal_approx(p.abilities.mult("damage-mult"), 1.2) and p.abilities.buffs[&"war-frenzy"]["left"] > 10.0, "war frenzy buff")
	await _frames(35)
	hp0 = wolf.hp
	p._swing()
	check(is_equal_approx(hp0 - wolf.hp, Combat.after_armor(dmg * 1.2, wolf.armor, design["combat"])), "basic hit ×1.2 under war frenzy")
	check(is_equal_approx(p.mp, 8.0), "a landed hit gives 8 MP: %.1f" % p.mp)
	# M2 special: below min-mp nothing; held 0.5 s under war frenzy (charge-mult 2) charges ~50 MP → ×(1 + f × 1.5)
	Input.action_press("special-attack"); await physics_frame; Input.action_release("special-attack"); await physics_frame
	check(is_equal_approx(p.mp, 8.0), "M2 below min-mp does nothing")
	p.mp = 100.0; hp0 = wolf.hp
	Input.action_press("special-attack")
	await _frames(30)
	check(p._charge > 40.0 and p._charge <= 50.0, "M2 held 0.5 s at 50/s × 2 charges ~50 MP: %.1f" % p._charge)
	Input.action_release("special-attack"); await _frames(2)
	var charged: float = 100.0 - p.mp
	check(charged > 40.0 and charged <= 52.0 and p._charge < 0.0, "release spends the charge: mp %.1f" % p.mp)
	var f := charged / 100.0
	check(is_equal_approx(hp0 - wolf.hp, Combat.after_armor(dmg * (1.0 + f * 1.5) * 1.2, wolf.armor, design["combat"])), "special damage grows with MP spent")
	# Rock Fist: dash forward (−Z) 10 blocks or until a wall; the wolf is in the way → strike ×3, knockback + stun
	await _frames(int(2.5 * 60))                              # wolf's stun ends
	p.position = Vector3(0, 1, 6); p.abilities.buffs.clear(); wolf.position = Vector3(0, 1, -4); wolf.velocity = Vector3.ZERO
	await _frames(2)
	hp0 = wolf.hp
	check(p.use_class_skill(4), "rock fist (ultimate, key 4)")
	await _frames(40)
	check(hp0 - wolf.hp > 0.0 and p.position.z < 0.0, "rock fist charged forward and hit: moved to z %.1f, dmg %.1f" % [p.position.z, hp0 - wolf.hp])
	check(wolf.stunned() and wolf.velocity.length() > 0.0, "wolf stunned and knocked back")
	# Mage: passive MP regen; Fire Explosion burns; Healing Stream casts; Mana Shield absorbs; Bulwark stun immunity
	var fm := _player(&"mage", &"fire-mage", Vector3(3, 1, -4), {&"fire-explosion": 1})
	check(fm.mp_passive and fm.special_mode == &"charged", "mage regenerates MP passively")
	await _frames(60)
	check(fm.mp > 4.0 and fm.mp < 6.0, "mage +5 MP/s: %.1f" % fm.mp)
	await _frames(int(2.5 * 60))
	fm.mp = 100.0; hp0 = wolf.hp
	check(fm.use_class_skill(1) and is_equal_approx(fm.mp, 50.0), "fire explosion costs 50 MP")
	var burst: float = hp0 - wolf.hp
	check(burst > 0.0 and wolf.statuses.has(&"burning") and wolf.stunned(), "explosion hits, burns, stuns")
	await _frames(35)
	check(hp0 - wolf.hp > burst * 1.05, "burning ticks after the hit: %.1f > %.1f" % [hp0 - wolf.hp, burst])
	var wm := _player(&"mage", &"water-mage", Vector3(-3, 1, -4), {&"healing-stream": 1, &"mana-shield": 1})
	wm.mp = 100.0; wm.hp = 10.0
	check(wm.use_class_skill(1) and wm.abilities.busy() and is_equal_approx(wm.hp, 10.0), "healing stream casts first")
	await _frames(int(1.5 * 60) + 3)
	check(is_equal_approx(wm.hp, minf(wm.max_hp, 10.0 + wm.max_hp * 0.5 * 1.05)), "heal 50 %% × 1.05 after the cast: %.1f / %.1f" % [wm.hp, wm.max_hp])
	check(wm.use_class_skill(2), "mana shield")
	var before: float = wm.hp
	wm.take_damage(10.0, wolf)
	check(is_equal_approx(wm.hp, before) and is_equal_approx(wm.abilities.buffs[&"mana-shield"]["pool"], wm.max_hp * 0.3 - 10.0), "shield absorbs 10 of its pool")
	var gd := _player(&"warrior", &"guardian", Vector3(0, 1, 8), {&"bulwark": 1})
	check(gd.use_class_skill(3) and gd.stun_immune(), "bulwark: stun immune")
	gd.apply_status(&"stun", design["status-effects"]["stun"], 0.0, wolf)
	check(not gd.stunned(), "stun ignored under bulwark")
	before = gd.hp; gd.take_damage(20.0, wolf)
	check(is_equal_approx(before - gd.hp, 10.0), "bulwark halves damage taken")
	print("abilities ok" if _failed == 0 else "abilities FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
