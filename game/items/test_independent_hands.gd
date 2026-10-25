extends SceneTree
const Model := preload("res://ontology/model.gd")
const Combat := preload("res://game/combat/combat.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Save := preload("res://game/world/save_data.gd")
const State := preload("res://game/world/world_state.gd")
const InputBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		printerr("set isolated PIXLND_TEST_DIR")
		quit(1)
		return
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var d: Dictionary = o.configs.generators.design
	InputBuilder.build(o.configs.keybinds.hybrid)
	var save := Save.new(o, d)
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	for subtype in [&"shield", &"axe"]:
		var p = PLAYER.instantiate()
		root.add_child(p)
		p.setup(d.movement, d.camera, &"normal")
		p.setup_combat(d.combat, d.crit, {}, Combat.player_max_hp(1, o.classes[&"warrior"].hp_mult))
		p.setup_items(o, d)
		p.logical_id = "independent-hands"
		p.set_physics_process(false)
		var main = p.inventory.equipment[&"main-hand"]
		var off = Items.generate(rng, &"weapon", subtype, &"iron", 2, 1)
		p.inventory.add(off)
		check(p.inventory.equip(off), "initial legal pair " + str(subtype))
		p.inventory.unequip(&"main-hand")
		check(
			(
				p.inventory.equipment.size() == 1
				and p.inventory.equipment[&"off-hand"] == off
				and p.inventory.entries.count(main) == 1
			),
			"independent removal leaves other object in place " + str(subtype)
		)
		check(p.weapon.is_empty() and p.moveset.is_empty(), "off-hand is not an attack source")
		check(
			(
				is_equal_approx(p.max_hp, p._base_max_hp + Items.hp(off, o))
				and is_equal_approx(p.armor, Items.armor(off, o))
				and is_equal_approx(p.resistance, Items.resistance(off, o))
			),
			"off-hand HP/defence remain worn"
		)
		p.mp = 80
		p.combo = 4
		p._swing_t = 0
		p._swing()
		p._special(50)
		check(
			p.mp == 80 and p.combo == 4 and p._swing_t == 0,
			"off-hand-only attack rejection does not spend"
		)
		var attacker := Node3D.new()
		root.add_child(attacker)
		attacker.position = p.position + Vector3.FORWARD.rotated(Vector3.UP, p.rig.rotation.y)
		Input.action_press("special-attack")
		p._defence_tick(0, Vector3.ZERO, false)
		Input.action_release("special-attack")
		check(
			p.blocking == (subtype == &"shield"),
			"ordinary block intention remains usable without a main-hand weapon"
		)
		p.block_power = p.block_max()
		var hp: float = p.hp
		var blocked: bool = p.take_damage(10, attacker)
		check(
			blocked == (subtype == &"shield"),
			"ordinary shield-only block eligibility " + str(subtype)
		)
		check(
			is_equal_approx(
				hp - p.hp,
				10 * (1.0 - float(d.defence.block["damage-reduction"])) if blocked else 10
			),
			"existing block damage reduction retained"
		)
		var state := State.new(d, 26879)
		var data: Dictionary = save.capture(state, p)
		var path := directory.path_join("test-independent-" + str(subtype) + ".json")
		var written := save.write_atomic(path, data)
		check(written, "off-hand-only atomic save accepted " + str(subtype) + str(save.errors))
		if written:
			var loaded: Dictionary = save.load_file(path)
			var q = PLAYER.instantiate()
			root.add_child(q)
			q.setup(d.movement, d.camera, &"normal")
			q.setup_combat(
				d.combat, d.crit, {}, Combat.player_max_hp(1, o.classes[&"warrior"].hp_mult)
			)
			q.setup_items(o, d)
			q.set_physics_process(false)
			save.restore_player(q, loaded.character, loaded.world)
			check(
				(
					q.logical_id == p.logical_id
					and q.weapon.is_empty()
					and q.inventory.equipment.size() == 1
					and Save.item_data(q.inventory.equipment[&"off-hand"]) == Save.item_data(off)
				),
				"off-hand saved identity/payload and slot restored"
			)
			check(
				(
					q.max_hp == p.max_hp
					and q.armor == p.armor
					and q.resistance == p.resistance
					and q.can_block() == p.can_block()
				),
				"restored worn stats and block eligibility"
			)
			q.free()
		check(
			(
				p.inventory.equip(main)
				and p.inventory.equipment[&"off-hand"] == off
				and p.inventory.equipment[&"main-hand"] == main
				and not p.weapon.is_empty()
			),
			"reequip main preserves off-hand and restores attacks"
		)
		var two = Items.generate(rng, &"weapon", &"greatsword", &"iron", 1, 0)
		p.inventory.add(two)
		check(
			not p.inventory.equip(two) and p.inventory.equipment[&"off-hand"] == off,
			"2H conflict still rejected atomically"
		)
		p.inventory.unequip(&"off-hand")
		check(
			p.inventory.equipment[&"main-hand"] == main and p.inventory.entries.count(off) == 1,
			"reverse independent removal preserves main"
		)
		check(p.inventory.equip(two), "2H equip permitted after off-hand removed")
		p.inventory.unequip(&"main-hand")
		check(p.inventory.equipment.is_empty(), "fully empty loadout remains legal")
		p.free()
		attacker.free()
	# Rule-invalid saves and malformed direct shared-boundary calls must still fail safely.
	var p = PLAYER.instantiate()
	root.add_child(p)
	p.setup(d.movement, d.camera, &"normal")
	p.setup_combat(d.combat, d.crit, {}, Combat.player_max_hp(1, o.classes[&"warrior"].hp_mult))
	p.setup_items(o, d)
	p.logical_id = "invalid-hands"
	p.set_physics_process(false)
	var state := State.new(d, 26879)
	var data: Dictionary = save.capture(state, p)
	for kind in [
		"off-2h",
		"main-shield",
		"wrong-class",
		"wrong-material",
		"unknown",
		"non-weapon",
		"paired-2h"
	]:
		var bad: Dictionary = data.duplicate(true)
		var it = Items.generate(rng, &"weapon", &"axe", &"iron", 1, 0)
		match kind:
			"off-2h":
				it.subtype = &"greatsword"
			"main-shield":
				it.subtype = &"shield"
			"wrong-class":
				it.subtype = &"bracelet"
				it.material = &"gold"
			"wrong-material":
				it.material = &"wood"
			"unknown":
				it.subtype = &"unknown"
			"non-weapon":
				it = Item.stack(&"consumable", &"life-potion", 1)
			"paired-2h":
				it.subtype = &"greatsword"
		bad.character.equipment = (
			{"off-hand": Save.item_data(it)}
			if kind != "main-shield"
			else {"main-hand": Save.item_data(it)}
		)
		if kind == "paired-2h":
			bad.character.equipment = {
				"main-hand": Save.item_data(it),
				"off-hand": Save.item_data(Items.generate(rng, &"weapon", &"shield", &"iron", 1, 0))
			}
		check(not save.validate(bad), "illegal hand save rejected " + kind)
	check(
		not p.inventory._loadout_valid(null, Item.stack(&"consumable", &"life-potion", 1)),
		"non-weapon direct loadout rejected"
	)
	p.setup_items(o, d, &"warrior", &"guardian")
	var axe = Items.generate(rng, &"weapon", &"axe", &"iron", 1, 0)
	p.inventory.add(axe)
	p.inventory.equip(axe)
	p.inventory.unequip(&"main-hand")
	check(p.can_block(), "Guardian any-weapon block retains eligible off-hand-only weapon")
	p.blocking = true
	p.inventory.unequip(&"off-hand")
	var attacker := Node3D.new()
	root.add_child(attacker)
	attacker.position = p.position + Vector3.FORWARD
	check(
		not p.blocks_from(attacker),
		"last item removal ends block eligibility immediately, even before next input tick"
	)
	check(
		not p.can_block(), "Guardian without any weapon/shield or committed Cyclone is not eligible"
	)
	p.free()
	print("independent hands ok" if failed == 0 else "independent hands FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
