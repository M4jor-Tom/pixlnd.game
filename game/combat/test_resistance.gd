## Resistance-stage routing, equipped gear, creature baseline and hit-derived burn inheritance.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Combat := preload("res://game/combat/combat.gd")
const Items := preload("res://game/items/items.gd")
const Spawner := preload("res://game/world/spawner.gd")
const PLAYER := preload("res://game/entities/player.tscn")

var failed := 0
var o
var design: Dictionary

func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)

func _init() -> void:
	_run.call_deferred()

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _run() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs.generators.design
	var combat: Dictionary = design.combat
	check(is_equal_approx(Combat.after_defence(100, 0, 30, Combat.MAGICAL, combat), 70), "magical: subtract Resistance")
	check(is_equal_approx(Combat.after_defence(100, 200, 200, Combat.MAGICAL, combat), 10), "magical: 10% Resistance floor, no armor")
	check(is_equal_approx(Combat.after_defence(0, 0, 200, Combat.MAGICAL, combat), 0), "zero damage stays zero")
	check(is_equal_approx(Combat.after_defence(2, 0, 1.95, Combat.MAGICAL, combat), .2), "fractional result retains 10% floor")
	check(is_equal_approx(Combat.after_defence(100, 30, 90, Combat.PHYSICAL, combat), 70), "physical: armor only")

	var floor := StaticBody3D.new(); var collision := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100); collision.shape = box; floor.add_child(collision); floor.position.y = -0.5
	root.add_child(floor)
	var mage := _player(&"mage", &"fire-mage", Vector3.ZERO)
	mage.set_physics_process(false); mage.rig.rotation = Vector3.ZERO
	var chest = Items.generate(RandomNumberGenerator.new(), &"chest-armor", &"", &"silk", 1, 0)
	mage.inventory.add(chest); mage.inventory.equip(chest)
	var expected_r: float = Model.stat_curve(1, 0)
	check(is_equal_approx(mage.resistance, expected_r) and is_equal_approx(Items.resistance(chest, o), expected_r), "equipped silk chest contributes Resistance")
	check(is_equal_approx(mage.armor, Items.armor(chest, o)) and mage.armor != mage.resistance, "gear keeps armor and Resistance separate")
	mage.inventory.unequip(&"chest")
	check(is_zero_approx(mage.resistance), "unequip refreshes Resistance")
	mage.inventory.equip(chest)
	mage.resistance = expected_r

	var holder := Node3D.new(); root.add_child(holder)
	var wolf: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"P", "max_hp": 10000.0, "damage": 12.0,
		"positions": [Vector3(0, 1, -2)], "seed": 1}], design, o.creatures, mage, null)[0]
	wolf.set_physics_process(false)
	check(is_zero_approx(wolf.resistance), "spawned unequipped creature receives selected innate zero")
	wolf.armor = 30.0; wolf.resistance = 90.0
	var hp0: float = wolf.hp
	mage._attack(mage.moveset["m1"], 100.0, false, [])
	check(is_equal_approx(hp0 - wolf.hp, 10.0), "Mage staff attack uses Resistance, not armor")
	var sword = Items.generate(RandomNumberGenerator.new(), &"weapon", &"sword", &"iron", 1, 0)
	mage.inventory.add(sword); mage.inventory.equip(sword)
	check(mage.weapon["type"] == &"sword", "cross-class weapon remains equippable")
	wolf.hp = wolf.max_hp; hp0 = wolf.hp
	mage._attack(mage.moveset["m1"], 100.0, false, [])
	check(is_equal_approx(hp0 - wolf.hp, 70.0), "Mage wielding physical sword uses armor")
	mage.weapon["damage"] = 100.0
	wolf.hp = wolf.max_hp; hp0 = wolf.hp
	mage.abilities._strike(o.abilities[&"fire-explosion"], {"damage-mult": 1.0, "radius": 1.0}, wolf.global_position, 1.0)
	check(is_equal_approx(hp0 - wolf.hp, 10.0), "Mage spell remains magical while holding physical sword")
	mage.inventory.unequip(&"main-hand")
	var bracelet = Items.generate(RandomNumberGenerator.new(), &"weapon", &"bracelet", &"gold", 1, 0)
	mage.inventory.add(bracelet); mage.inventory.equip(bracelet)
	wolf.armor = 30.0; wolf.resistance = 90.0; wolf.hp = wolf.max_hp; hp0 = wolf.hp
	mage.abilities._strike(o.abilities[&"kick"], {"damage-mult": 1.0, "radius": 1.0}, wolf.global_position, 1.0)
	check(is_equal_approx(hp0 - wolf.hp, 10.0), "physical strike skill uses armor with Mage weapon (damage 40, armor 30, Resistance 90)")

	var warrior := _player(&"warrior", &"berserker", Vector3(10, 1, 0)); warrior.set_physics_process(false)
	var wolf2: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"P", "max_hp": 10000.0, "damage": 12.0,
		"positions": [Vector3(10, 1, -2)], "seed": 2}], design, o.creatures, warrior, null)[0]
	wolf2.set_physics_process(false); wolf2.armor = 30.0; wolf2.resistance = 90.0
	hp0 = wolf2.hp
	warrior._strike(wolf2.global_position + Vector3.UP, 1.0, 100.0, false)
	check(is_equal_approx(hp0 - wolf2.hp, 70.0), "physical weapon attack uses armor, not Resistance")

	# The launch weapon sets type once; swapping to a Mage weapon must not reclassify the in-flight arrow.
	var ranger := _player(&"ranger", &"scout", Vector3(30, 1, 0)); ranger.set_physics_process(false); ranger.rig.rotation = Vector3.ZERO
	var wolf3: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"P", "max_hp": 10000.0, "damage": 12.0,
		"positions": [Vector3(30, 1, -8)], "seed": 4}], design, o.creatures, ranger, null)[0]
	wolf3.set_physics_process(false); wolf3.armor = 30.0; wolf3.resistance = 90.0
	hp0 = wolf3.hp
	ranger._attack(ranger.moveset["m1"], 100.0, false, [])
	var wand = Items.generate(RandomNumberGenerator.new(), &"weapon", &"wand", &"wood", 1, 0)
	ranger.inventory.add(wand); ranger.inventory.equip(wand)
	check(ranger.weapon["type"] == &"wand", "cross-class Mage weapon equips during flight")
	await _frames(60)
	check(is_equal_approx(hp0 - wolf3.hp, 70.0), "in-flight arrow retains physical armor routing after Mage weapon swap")

	# A mage-role hit applies Resistance before block, damage-reduction and absorption.
	mage.abilities.buffs[&"bulwark"] = {"left": 10.0, "r": design.abilities.bulwark}
	mage.abilities.buffs[&"mana-shield"] = {"left": 10.0, "r": design.abilities["mana-shield"], "pool": 3.0}
	var enemy: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"P", "max_hp": 10000.0, "damage": 100.0,
		"positions": [Vector3(0, 1, -2)], "seed": 3}], design, o.creatures, mage, null)[0]
	enemy.set_physics_process(false); enemy.role = &"mage"; enemy.design = design
	mage.blocking = true; mage.block_power = 100.0; mage.armor = 200.0; mage.resistance = 30.0
	hp0 = mage.hp
	enemy._strike(mage.global_position + Vector3.UP, 1.0, 100.0, false, [], Combat.MAGICAL)
	check(is_equal_approx(hp0 - mage.hp, 4.0), "Resistance 100→70, then block 14, Bulwark 7, shield 3")
	mage.abilities.buffs.clear(); mage.statuses.clear(); mage.blocking = false; mage.resistance = 30.0; mage.armor = 0.0; mage.hp = mage.max_hp
	hp0 = mage.hp
	enemy._strike(mage.global_position + Vector3.UP, 1.0, 100.0, false, [&"burning"], Combat.MAGICAL)
	check(is_equal_approx(hp0 - mage.hp, 70.0), "magical creature attack uses player's gear Resistance")
	check(mage.statuses.has(&"burning") and is_equal_approx(float(mage.statuses[&"burning"][0]["dmg"]), 7.0), "burn inherits Resistance-adjusted 70 once")
	mage.set_physics_process(false)
	mage.tick_statuses(float(design["status-effects"]["burning"]["tick-s"]))
	check(is_equal_approx(hp0 - mage.hp, 77.0), "first burn tick applies 7 without subtracting Resistance again")
	mage.statuses.clear(); mage.hp = mage.max_hp; mage.resistance = 90.0; mage.armor = 30.0
	enemy.role = &"melee"
	hp0 = mage.hp
	enemy._strike(mage.global_position + Vector3.UP, 1.0, 100.0, false)
	check(is_equal_approx(hp0 - mage.hp, 70.0), "creature physical strike uses armor, not Resistance")
	mage.hp = mage.max_hp; mage.statuses.clear(); enemy.hostility = &"H"; enemy.target = mage
	enemy.global_position = mage.global_position + Vector3(0, 0, -1); enemy.state = enemy.State.ATTACK; enemy._windup = 0.0
	hp0 = mage.hp
	enemy._tick(0.0)
	check(is_equal_approx(hp0 - mage.hp, 70.0), "creature bite uses the physical armor stage")

	print("Resistance combat ok" if failed == 0 else "Resistance combat FAILED: %d" % failed)
	quit(1 if failed > 0 else 0)

func _player(class_id: StringName, spec: StringName, at: Vector3) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design.movement, design.camera, &"normal")
	p.setup_combat(design.combat, design.crit, {}, Combat.player_max_hp(1, 1.0))
	p.setup_items(o, design, class_id, spec)
	p.position = at
	return p
