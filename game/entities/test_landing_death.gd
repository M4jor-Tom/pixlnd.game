## Fatal landing must terminate the frame, independently of item-use eligibility (F1).
## Run: godot --headless -s game/entities/test_landing_death.gd
extends SceneTree

const Model := preload("res://ontology/model.gd")
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


func _run() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs["generators"]["design"]
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	collision.shape = box
	floor.add_child(collision)
	floor.position.y = -0.5
	root.add_child(floor)
	for mode in ["fatal landing", "nonlethal landing", "lethal DOT"]:
		for action in ["quick-item", "basic-attack", "class-skill-1"]:
			await _case(mode, action)
	floor.free()
	print("landing death ok" if _failed == 0 else "landing death FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)


func _case(mode: String, action: String) -> void:
	var label := mode + " / " + action
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, 260.0)
	p.setup_items(o, design)
	p.inventory.coins = 37
	p.set_physics_process(false)  # Real callback, deterministic admission at the input edge.
	p.skill_tree.points = {&"smash": 1}
	p.xp = 7
	p.mp = 100.0
	p.spawn_point = Vector3(3, 1, -5)
	p.position = Vector3(0, 1, -5)
	await physics_frame
	await process_frame
	for other in ["quick-item", "basic-attack", "class-skill-1"]:
		check(not Input.is_action_just_pressed(other), label + ": no stale " + other + " edge")
	p._physics_process(0.01)
	check(not p.is_on_floor(), label + ": airborne precondition")
	p.position.y = 0.05
	p.velocity = Vector3(0, -20, 0)
	p._fall_from = 40.0 if mode == "fatal landing" else 10.0
	p.hp = 1.0 if mode != "nonlethal landing" else 100.0
	p._swing_t = 0.0
	if mode == "lethal DOT":
		p.apply_status(&"poison", design["status-effects"]["poison"], 10.0, p)
	var potion = p.inventory.first_consumable()
	var count: int = potion.count
	var entries: Array = p.inventory.entries.duplicate()
	var equipment: Dictionary = p.inventory.equipment.duplicate()
	var coins: int = p.inventory.coins
	var equipped_max: float = p.max_hp
	check(equipped_max > 260.0, label + ": equipped HP precondition")
	var deaths := {"count": 0}
	p.died.connect(func(): deaths["count"] += 1)
	await process_frame
	# Use the actual mapped key/mouse event, not action_press across an await.
	var event = InputMap.action_get_events(action)[0].duplicate()
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	var edge := Input.is_action_just_pressed(action)
	check(edge, label + ": mapped edge immediately before callback")
	p._physics_process(1.0 if mode == "lethal DOT" else 0.01)
	var release = event.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	print("  ", label, ": edge=", edge, " floor=", p.is_on_floor(), " dead=", p.dead)
	if mode == "nonlethal landing":
		check(p.is_on_floor() and not p.dead and deaths["count"] == 0, label + ": lands alive")
		match action:
			"quick-item":
				check(potion.count == count - 1 and p.hp > 100.0, label + ": potion still works")
			"basic-attack":
				check(p._swing_t > 0.0, label + ": swing still works")
			"class-skill-1":
				check(
					(
						not p.abilities.dash.is_empty()
						and p.abilities.cooldowns.has(&"smash")
						and p.stamina < 100.0
					),
					label + ": learned Smash still works"
				)
	else:
		if mode == "fatal landing":
			check(p.is_on_floor(), label + ": actual landing collision")
		else:
			check(not p.is_on_floor(), label + ": DOT terminates before movement")
		check(p.dead and p.hp == 0.0, label + ": terminal zero HP")
		check(potion.count == count, label + ": no post-death consumption")
		check(p._swing_t == 0.0, label + ": no post-death swing or combat clock")
		check(
			(
				p.abilities.dash.is_empty()
				and p.abilities.channel.is_empty()
				and p.abilities.cast.is_empty()
				and p.abilities.cooldowns.is_empty()
			),
			label + ": no post-death skill or cooldown"
		)
		check(p.stamina == 100.0 and p.mp == 100.0, label + ": no post-death spend")
		check(p.velocity == Vector3.ZERO, label + ": death cleanup retained")
		p.take_damage(10.0, p)
		p._physics_process(0.01)
		await create_timer(0.05).timeout
		check(p.dead and p.hp == 0.0, label + ": stays dead before respawn delay")
		check(deaths["count"] == 1, label + ": death emitted once")
		await create_timer(float(design["combat"]["death"]["respawn-s"]) + 0.1).timeout
		check(
			not p.dead and p.hp == equipped_max and p.position == p.spawn_point,
			label + ": ordinary respawn at equipped maximum"
		)
		check(
			(
				p.inventory.entries == entries
				and p.inventory.equipment == equipment
				and potion.count == count
				and p.inventory.coins == coins
				and p.xp == 7
			),
			label + ": items, equipment, coins and XP survive"
		)
	p.free()
