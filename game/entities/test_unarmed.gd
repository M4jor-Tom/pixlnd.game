extends SceneTree
const Model := preload("res://ontology/model.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const Spawner := preload("res://game/world/spawner.gd")
const HUD := preload("res://game/meta/hud.gd")
const InputBuilder := preload("res://game/meta/input_map.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var d: Dictionary = o.configs.generators.design
	InputBuilder.build(o.configs.keybinds.hybrid)
	for spec_id in o.specs:
		var class_id: StringName = o.specs[spec_id].character_class
		var p = PLAYER.instantiate()
		root.add_child(p)
		p.setup(d.movement, d.camera, &"normal")
		p.setup_combat(d.combat, d.crit, {}, 100)
		p.setup_items(o, d, class_id, spec_id)
		p.set_physics_process(false)
		var original = p.inventory.equipment[&"main-hand"]
		var armed: Dictionary = p.weapon.duplicate()
		p.inventory.unequip(&"main-hand")
		check(
			p.weapon.is_empty() and p.moveset.is_empty(),
			"removed weapon clears derived attack state " + str(class_id)
		)
		p.mp = 80
		p.stamina = 100
		p.combo = 4
		p._combo_t = 2
		p._swing_t = 0
		p._swing()
		p._special(50)
		p._special_tick(0.1)
		p._apply_touch_request({"action": "basic-attack", "phase": "start"}, Vector3.ZERO)
		p._apply_touch_request({"action": "special-attack", "phase": "start"}, Vector3.ZERO)
		check(
			(
				p.mp == 80
				and p.stamina == 100
				and p.combo == 4
				and p._combo_t == 2
				and p._swing_t == 0
				and p._charge < 0
			),
			"unarmed basic/special desktop/touch no spend " + str(class_id)
		)
		for a in p.skill_tree.nodes:
			var r: Dictionary = p.abilities.runtime(a)
			if r.is_empty():
				continue
			p.abilities.reset()
			p.abilities.cooldowns.clear()
			p.mp = 100
			p.stamina = 100
			p.combo = 4
			var damaging: bool = (
				r.runtime not in ["buff", "heal"]
				and (
					r.runtime == "projectile"
					or float(r.get("damage-mult", 0)) > 0
					or r.has("throw")
					or r.get("strike", {}).has("damage-mult")
				)
			)
			var used: bool = p.abilities.use(a)
			check(used != damaging, "class request eligibility " + str(a.id))
			if damaging:
				check(
					(
						p.mp == 100
						and p.stamina == 100
						and p.combo == 4
						and p.abilities.cooldowns.is_empty()
					),
					"weapon skill no spend " + str(a.id)
				)
			if r.runtime == "buff":
				check(p.abilities.buffs.has(a.id), "independent buff applied unarmed " + str(a.id))
			if r.runtime == "heal":
				p.hp = 10
				p.abilities.tick(float(r["cast-s"]))
				check(p.hp > 10, "independent heal resolves unarmed")
		p.abilities.reset()
		p.abilities.cooldowns.clear()
		check(
			p.inventory.equip(original) and p.weapon == armed,
			"reequip restores attacks " + str(class_id)
		)
		p.queue_free()
	# Committed damaging effects keep their original weapon payload after unequip.
	var p = PLAYER.instantiate()
	root.add_child(p)
	p.setup(d.movement, d.camera, &"normal")
	p.setup_combat(d.combat, d.crit, {}, 100)
	p.setup_items(o, d)
	p.set_physics_process(false)
	var holder := Node3D.new()
	root.add_child(holder)
	var m = (
		Spawner
		. populate(
			holder,
			[
				{
					"species": &"wolf",
					"level": 1,
					"hostility": &"H",
					"max_hp": 1e6,
					"damage": 0,
					"positions": [Vector3(0, 0, -1)],
					"seed": 1
				}
			],
			d,
			o.creatures,
			p
		)[0]
	)
	m.set_physics_process(false)
	await physics_frame
	p.stamina = 100
	check(p.abilities.use(o.abilities[&"cyclone"]), "armed channel committed")
	p.inventory.unequip(&"main-hand")
	var hp0: float = m.hp
	p.abilities.tick(0.25)
	check(m.hp < hp0 and p.combo > 0, "committed channel damages and lands without weapon")
	p.abilities.reset()
	p.stamina = 100
	var weapon = p.inventory.entries.filter(func(it): return it.type == &"weapon")[0]
	p.inventory.equip(weapon)
	check(p.abilities.use(o.abilities[&"smash"]), "armed dash committed")
	p.inventory.unequip(&"main-hand")
	hp0 = m.hp
	p.abilities.after_move(1)
	check(m.hp < hp0, "committed dash strike survives unequip")
	# Already-fired projectile may still land and award combo with its committed cap.
	p.inventory.equip(weapon)
	var shots: Array = p._fire(d.movesets.bow.m1, 40, true, [], Vector3(0, 1, -1))
	for shot in shots:
		shot.set_physics_process(false)
	p.inventory.unequip(&"main-hand")
	p.combo = 4
	shots[0]._hit(1)
	check(p.combo == 5, "in-flight hit has captured combo cap")
	for shot in shots:
		shot.queue_free()
	p.setup_items(o, d, &"warrior", &"guardian")
	p.inventory.unequip(&"main-hand")
	p.combo = 4
	p.hp = 10
	check(p.abilities.use(o.abilities[&"heroic-shout"]), "unarmed taunt request available")
	p.targeting.flush_taunts()
	p.abilities.tick(0.5)
	check(
		p.targeting.record(m).taunt_left == 3 and p.hp > 10 and p.combo == 4,
		"unarmed shout still taunts/heals without combo mutation"
	)
	var hud = HUD.new()
	root.add_child(hud)
	hud.bind(p, null)
	hud._process(0)
	check(p.weapon.is_empty(), "HUD accepts absent weapon")
	print("unarmed ok" if failed == 0 else "unarmed FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
