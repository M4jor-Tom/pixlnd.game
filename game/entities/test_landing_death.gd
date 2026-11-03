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
	if not _fresh_edges(label):
		return
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
	await _action_frame(
		p, mode, action, label, potion, count, entries, equipment, coins, equipped_max, deaths
	)


func _fresh_edges(label: String) -> bool:
	for other in ["quick-item", "basic-attack", "class-skill-1"]:
		check(not Input.is_action_just_pressed(other), label + ": no stale " + other + " edge")
	return true


func _action_frame(
	p,
	mode: String,
	action: String,
	label: String,
	potion,
	count: int,
	entries: Array,
	equipment: Dictionary,
	coins: int,
	equipped_max: float,
	deaths: Dictionary
) -> void:
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
	await _verify_landing(
		p, mode, action, label, potion, count, entries, equipment, coins, equipped_max, deaths
	)


func _verify_landing(
	p,
	mode: String,
	action: String,
	label: String,
	potion,
	count: int,
	entries: Array,
	equipment: Dictionary,
	coins: int,
	equipped_max: float,
	deaths: Dictionary
) -> void:
	if mode == "nonlethal landing":
		if not _surviving_landing(p, action, label, potion, count, deaths):
			return
	else:
		if not await _fatal_landing(
			p, mode, label, potion, count, entries, equipment, coins, equipped_max, deaths
		):
			return
	p.free()


func _surviving_landing(
	p, action: String, label: String, potion, count: int, deaths: Dictionary
) -> bool:
	check(p.is_on_floor() and not p.dead and deaths["count"] == 0, label + ": lands alive")
	return _landing_action(p, action, label, potion, count)


func _fatal_landing(
	p,
	mode: String,
	label: String,
	potion,
	count: int,
	entries: Array,
	equipment: Dictionary,
	coins: int,
	equipped_max: float,
	deaths: Dictionary
) -> bool:
	if not _terminal_landing(p, mode, label, potion, count):
		return false
	if not await _pre_respawn(p, label, deaths):
		return false
	if not await _respawn(p, label, equipped_max):
		return false
	return _retained_items(p, label, potion, count, entries, equipment, coins)


func _dead_actions(p, label: String) -> bool:
	check(
		(
			p.abilities.dash.is_empty()
			and p.abilities.channel.is_empty()
			and p.abilities.cast.is_empty()
			and p.abilities.cooldowns.is_empty()
		),
		label + ": no post-death skill or cooldown"
	)
	return true


func _dead_resources(p, label: String) -> bool:
	check(p.stamina == 100.0 and p.mp == 100.0, label + ": no post-death spend")
	check(p.velocity == Vector3.ZERO, label + ": death cleanup retained")
	return true


func _retained_items(
	p, label: String, potion, count: int, entries: Array, equipment: Dictionary, coins: int
) -> bool:
	var retained_items = (
		p.inventory.entries == entries
		and p.inventory.equipment == equipment
		and potion.count == count
		and p.inventory.coins == coins
		and p.xp == 7
	)
	check(retained_items, label + ": items, equipment, coins and XP survive")
	return true


func _potion_landing(p, label: String, potion, count: int) -> bool:
	check(potion.count == count - 1 and p.hp > 100.0, label + ": potion still works")
	return true


func _swing_landing(p, label: String) -> bool:
	check(p._swing_t > 0.0, label + ": swing still works")
	return true


func _smash_landing(p, label: String) -> bool:
	check(
		(
			not p.abilities.dash.is_empty()
			and p.abilities.cooldowns.has(&"smash")
			and p.stamina < 100.0
		),
		label + ": learned Smash still works"
	)
	return true


func _landing_action(p, action: String, label: String, potion, count: int) -> bool:
	match action:
		"quick-item":
			return _potion_landing(p, label, potion, count)
		"basic-attack":
			return _swing_landing(p, label)
		"class-skill-1":
			return _smash_landing(p, label)
	return true


func _terminal_landing(p, mode: String, label: String, potion, count: int) -> bool:
	if mode == "fatal landing":
		check(p.is_on_floor(), label + ": actual landing collision")
	else:
		check(not p.is_on_floor(), label + ": DOT terminates before movement")
	check(p.dead and p.hp == 0.0, label + ": terminal zero HP")
	check(potion.count == count, label + ": no post-death consumption")
	check(p._swing_t == 0.0, label + ": no post-death swing or combat clock")
	return _dead_actions(p, label) and _dead_resources(p, label)


func _pre_respawn(p, label: String, deaths: Dictionary) -> bool:
	p.take_damage(10.0, p)
	p._physics_process(0.01)
	await create_timer(0.05).timeout
	check(p.dead and p.hp == 0.0, label + ": stays dead before respawn delay")
	check(deaths["count"] == 1, label + ": death emitted once")
	return true


func _respawn(p, label: String, equipped_max: float) -> bool:
	await create_timer(float(design["combat"]["death"]["respawn-s"]) + 0.1).timeout
	check(
		not p.dead and p.hp == equipped_max and p.position == p.spawn_point,
		label + ": ordinary respawn at equipped maximum"
	)
	return true
