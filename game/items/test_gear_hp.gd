## Fixed HP: catches missing/double class-scaled gear, swap healing and lost lifecycle contributions.
## Expected amounts are literal fixtures, independent of Items.hp and Model.stat_curve.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Combat := preload("res://game/combat/combat.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const HUD := preload("res://game/meta/hud.gd")
const PLAYER := preload("res://game/entities/player.tscn")

var failed := 0
var o
var design: Dictionary


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func state(p: Node, current: float, maximum: float, label: String) -> void:
	check(
		is_equal_approx(p.hp, current) and is_equal_approx(p.max_hp, maximum),
		"%s: expected %.9f/%.9f, got %.9f/%.9f" % [label, current, maximum, p.hp, p.max_hp]
	)


func gear(type: StringName, material: StringName, subtype: StringName = &"") -> Item:
	return Items.generate(RandomNumberGenerator.new(), type, subtype, material, 1, 0)


func player(class_id: StringName) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design.movement, design.camera, &"normal")
	p.setup_combat(
		design.combat, design.crit, {}, Combat.player_max_hp(1, o.classes[class_id].hp_mult)
	)
	p.setup_items(o, design, class_id)
	p.set_physics_process(false)
	return p


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(
		func():
			printerr("FAIL: gear HP test exceeded 20 seconds")
			quit(1)
	)
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs.generators.design
	InputMapBuilder.build(o.configs.keybinds.hybrid)
	_item_fixtures()
	_extraneous_hp_fields()
	# Each class uses its canonical armor material; the HP bonus is independent of class base HP.
	for row in [
		[&"warrior", &"iron", 267.5, 282.5],
		[&"ranger", &"linen", 225.0, 237.5],
		[&"mage", &"silk", 205.0, 215.0],
		[&"rogue", &"cotton", 247.5, 261.25]
	]:
		var hero := player(row[0])
		state(hero, row[2], row[2], "%s starts full, including starter weapon" % row[0])
		var chest := gear(&"chest-armor", row[1])
		hero.inventory.add(chest)
		state(hero, row[2], row[2], "bag has no HP effect")
		hero.hp = 80.0
		check(hero.inventory.equip(chest), "chest equips")
		state(hero, 80, row[3], "%s adds class-valid gear without healing" % row[0])
		hero.free()

	var dressed := player(&"warrior")
	for row in [
		[&"chest-armor", &"iron", &""],
		[&"shoulder-armor", &"iron", &""],
		[&"gloves", &"iron", &""],
		[&"boots", &"iron", &""],
		[&"weapon", &"iron", &"shield"]
	]:
		var it := gear(row[0], row[1], row[2])
		dressed.inventory.add(it)
		check(dressed.inventory.equip(it), "HP-bearing piece equips")
	state(dressed, 267.5, 312.5, "all six class-valid HP-bearing slots sum once")
	dressed.free()

	var p := player(&"warrior")
	var above := Items.generate(RandomNumberGenerator.new(), &"chest-armor", &"", &"iron", 2, 0)
	p.inventory.add(above)
	p.hp = 80
	var attack: Dictionary = p.weapon.duplicate(true)
	check(not p.inventory.equip(above), "above-power chest rejected before HP update")
	state(p, 80, 267.5, "above-power rejection preserves current and maximum HP")
	check(p.weapon == attack, "above-power rejection preserves attack")
	# Keep HP swap fixtures independent on the unfixed RED runtime.
	if p.inventory.equipment.get(&"chest") == above:
		p.inventory.unequip(&"chest")
	var chest := gear(&"chest-armor", &"iron")
	var upgraded := gear(&"chest-armor", &"iron")
	upgraded.upgrade_count = 10  # Same HP curve input n=2, with an eligible +1 requirement.
	var shield := gear(&"weapon", &"iron", &"shield")
	var two := gear(&"weapon", &"iron", &"greatsword")
	for it in [chest, upgraded, shield, two]:
		p.inventory.add(it)
	p.hp = 80
	p.inventory.equip(chest)
	state(p, 80, 282.5, "wounded equip")
	p.inventory.equip(upgraded)
	state(p, 80, 284.0613427051072, "class-valid replacement removes displaced HP")
	p.hp = 284.0613427051072
	p.inventory.unequip(&"chest")
	state(p, 267.5, 267.5, "unequip caps down")
	p.inventory.equip(chest)
	state(p, 267.5, 282.5, "re-equip never fills lost HP")
	for i in 5:
		p.inventory.equip(upgraded)
		p.inventory.equip(chest)
	state(p, 267.5, 282.5, "repeated swaps never heal or accumulate")
	p.inventory.equip(shield)
	state(p, 267.5, 290, "valid sword plus offhand contributes once each")
	var before: Dictionary = p.inventory.equipment.duplicate()
	check(
		not p.inventory.equip(two) and p.inventory.equipment == before,
		"2H plus shield rejected atomically"
	)
	state(p, 267.5, 290, "rejected equip leaves HP unchanged")
	p.inventory.add(Item.stack(&"coin", &"", 3))
	var potion: Item = p.inventory.first_consumable()
	p.inventory.remove(potion)
	p.inventory.changed.emit()
	state(p, 267.5, 290, "coin, removal and repeated changed notifications are idempotent")
	p.inventory.unequip(&"off-hand")
	p.inventory.equip(two)
	state(p, 267.5, 282.5, "2H alone has one weapon bonus")
	check(not p.inventory.equip(shield), "shield rejected with 2H already worn")
	state(p, 267.5, 282.5, "reverse rejected equip leaves HP unchanged")
	# L2 base 287.063273555191 + chest 15 + unchanged L1 weapon 7.5.
	p.gain_xp(50)
	state(p, 309.563273555191, 309.563273555191, "level-up retains gear and heals fully")
	check(
		p.level == 2 and p.inventory.equipment[&"main-hand"] == two,
		"level-up retains item identity"
	)
	p.inventory.changed.emit()
	state(p, 309.563273555191, 309.563273555191, "notification after level-up does not reset base")
	p.hp = 10
	p.use_item(potion)
	state(p, 210, 309.563273555191, "consumable retains flat heal")
	p.rest()
	state(p, 309.563273555191, 309.563273555191, "inn refills equipped maximum")
	var hud := HUD.new()
	root.add_child(hud)
	hud.bind(p, null)
	hud._process(0)
	check(
		(
			is_equal_approx(hud._hp.max_value, 309.563273555191)
			and absf(hud._hp.value - p.hp) <= hud._hp.step
		),
		"real HUD reads equipped maximum and current HP within its existing display step"
	)
	# Actual lethal damage enters the existing death/respawn coroutine.
	p.take_damage(10000, p)
	check(p.dead, "lethal damage kills")
	p.inventory.equip(upgraded)
	state(p, 0, 311.124616260298, "dead replacement stays at zero")
	check(p.dead, "equipping does not revive")
	p.inventory.changed.emit()
	state(p, 0, 311.124616260298, "dead notification stays at zero")
	await create_timer(float(design.combat.death["respawn-s"]) + .1).timeout
	check(not p.dead, "real respawn completes")
	state(p, 311.124616260298, 311.124616260298, "respawn refills retained equipment maximum")
	hud.free()
	p.free()
	await _max_hp_consumers()
	print("gear HP ok" if failed == 0 else "gear HP FAILED: %d" % failed)
	quit(0 if failed == 0 else 1)


func _item_fixtures() -> void:
	# At level 1/common, curve=1: chest 5*(2+bonus), other HP slots half.
	for row in [
		[&"iron", 15.0, 7.5],
		[&"cotton", 13.75, 6.875],
		[&"linen", 12.5, 6.25],
		[&"silk", 10.0, 5.0],
		[&"wood", 10.0, 5.0],
		[&"gold", 10.0, 5.0]
	]:
		for type in [&"chest-armor", &"shoulder-armor", &"gloves", &"boots", &"weapon"]:
			var it := gear(type, row[0], &"shield" if type == &"weapon" else &"")
			for roll in 21:
				it.modifier = roll
				it.minus_modifier = 0
				check(
					is_equal_approx(Items.hp(it, o), row[1] if type == &"chest-armor" else row[2]),
					"fixed %s %s, roll %d" % [row[0], type, roll]
				)
			it.minus_modifier = 12345
			check(
				is_equal_approx(Items.hp(it, o), row[1] if type == &"chest-armor" else row[2]),
				"minus modifier never affects HP"
			)
	for type in [
		&"ring",
		&"amulet",
		&"lamp",
		&"hang-glider",
		&"boat",
		&"pet-cage",
		&"consumable",
		&"ingredient",
		&"coin"
	]:
		check(is_zero_approx(Items.hp(gear(type, &"iron"), o)), "%s never grants HP" % type)
	for subtype in [&"sword", &"greatsword", &"shield", &"staff", &"bracelet"]:
		check(
			is_equal_approx(Items.hp(gear(&"weapon", &"iron", subtype), o), 7.5),
			"%s uses half-slot HP" % subtype
		)
	for row in [
		[5, 2, 3, &"chest-armor", &"iron", 30.6487173482063],
		[2, 4, 0, &"weapon", &"iron", 16.561342705107187],
		[1, 0, 1, &"weapon", &"iron", 7.577993848581611],
		[100, 4, 32, &"boots", &"linen", 71.15325378128668]
	]:
		var it := Items.generate(
			RandomNumberGenerator.new(),
			row[3],
			&"sword" if row[3] == &"weapon" else &"",
			row[4],
			row[0],
			row[1]
		)
		it.upgrade_count = row[2]
		check(
			is_equal_approx(Items.hp(it, o), row[5]),
			"level/rarity/fractional-upgrade fixture %s" % [row]
		)
	var sword := gear(&"weapon", &"iron", &"sword")
	sword.upgrade_count = 3
	check(
		is_equal_approx(Items.damage(sword, o), 4.0), "HP upgrade input does not change other stats"
	)


func _extraneous_hp_fields() -> void:
	var extra := Model.Ontology.load_dir("res://ontology/instances")
	for material in [&"wood", &"silk", &"gold"]:
		extra.materials[material].raw["hp-bonus"] = 1.0
	for slot in extra.configs["equipment-slots"]["slots"]:
		if slot["id"] not in ["chest", "shoulders", "gloves", "boots", "main-hand", "off-hand"]:
			slot["hp-mult"] = 1.0
	check(extra.validate(), "extraneous HP fields remain outside selected validation")
	for row in [
		[&"weapon", &"wood", &"bow", 5.0],
		[&"chest-armor", &"silk", &"", 10.0],
		[&"boots", &"gold", &"", 5.0]
	]:
		check(
			is_equal_approx(Items.hp(gear(row[0], row[1], row[2]), extra), row[3]),
			"%s ignores extraneous material HP bonus" % row[1]
		)
	for type in [&"ring", &"amulet", &"lamp", &"hang-glider", &"boat", &"pet-cage", &"ingredient"]:
		check(
			is_zero_approx(Items.hp(gear(type, &"iron"), extra)),
			"%s ignores extraneous HP slot fields" % type
		)


func _max_hp_consumers() -> void:
	var mage := player(&"mage")
	var chest := gear(&"chest-armor", &"silk")
	mage.inventory.add(chest)
	mage.inventory.equip(chest)
	check(mage.abilities.use(o.abilities[&"mana-shield"]), "real shield activates")
	check(
		is_equal_approx(mage.abilities.buffs[&"mana-shield"]["pool"], 64.5),
		"shield samples equipped max 215 at activation"
	)
	mage.inventory.unequip(&"chest")
	check(
		is_equal_approx(mage.abilities.buffs[&"mana-shield"]["pool"], 64.5),
		"swap does not rescale existing shield"
	)
	mage.abilities.reset()
	mage.mp = 100
	mage.hp = 10
	check(mage.abilities.use(o.abilities[&"healing-stream"]), "real healing cast starts")
	mage.inventory.equip(chest)
	state(mage, 10, 215, "equip during heal cast does not itself heal")
	mage.abilities.tick(1.5)
	state(mage, 117.5, 215, "heal samples equipped max at cast completion")
	# Real landing collision exercises fall damage at 10 blocks above the free eight.
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	collision.shape = box
	floor.add_child(collision)
	floor.position.y = -.5
	root.add_child(floor)
	mage.position = Vector3(0, .1, 0)
	mage.abilities.reset()
	mage.hp = 215
	await physics_frame
	mage.velocity = Vector3(0, -10, 0)
	mage.move_and_slide()
	check(mage.is_on_floor(), "fall fixture lands on real floor")
	mage._fall_from = mage.global_position.y + 10
	mage._fall_damage(true)
	state(mage, 193.5, 215, "fall damage samples equipped max: two blocks at 5 percent")
	mage.free()
	floor.free()
