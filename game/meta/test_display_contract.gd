## Literal display/cache and camera/map ownership controls, independent of extracted helpers.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const HUD := preload("res://game/meta/hud.gd")
const WorldMap := preload("res://game/world/world_map.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _initialize() -> void:
	await process_frame
	var o := Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "display ontology validates")
	var design: Dictionary = o.configs.generators.design
	InputMapBuilder.build(o.configs.keybinds.hybrid)
	var p = PLAYER.instantiate()
	p.setup(design.movement, design.camera, &"normal")
	p.setup_combat(design.combat, design.crit, {}, 260.0)
	p.setup_items(o, design, &"warrior", &"berserker")
	check(p.get_node("CameraRig").arm != null, "camera setup precedes ready")
	root.add_child(p)
	p.set_physics_process(false)
	var hud := HUD.new()
	root.add_child(hud)
	hud.bind(p, null)
	hud.set_process(false)
	_resources(p, hud)
	_hotbar(p, hud)
	_cache(p, hud, design)
	_camera(p)
	_map(p)
	hud.free()
	p.free()
	print("display contract ok" if failed == 0 else "display contract FAILED: %d" % failed)
	quit(0 if failed == 0 else 1)


func _resources(p, hud) -> void:
	p.hp = 81.0
	p.stamina = 23.0
	p.mp = 47.0
	p._charge = 2.0
	p.inventory.coins = 17
	hud._process(0)
	check(hud._hp.max_value == 267.5 and hud._hp.value == 81.0, "literal HP display")
	check(hud._stamina.value == 23.0 and hud._stamina.visible, "spent stamina visible")
	check(hud._mp.value == 47.0, "literal MP display")
	check(
		(hud._mp.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == Color(0.95, 0.4, 0.8),
		"charged MP color"
	)
	check(hud._coins.text == "17 copper", "literal coin display")
	p.stamina = 100.0
	p._charge = -1.0
	hud._process(0)
	check(not hud._stamina.visible, "full stamina hidden")
	check(
		(hud._mp.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == Color(0.3, 0.4, 0.9),
		"ordinary MP color"
	)


func _hotbar(p, hud) -> void:
	p.skill_tree.points[&"smash"] = 1
	p.abilities.cooldowns[&"smash"] = 3.0
	check(
		(
			hud._skills_line()
			== "1 Smash: 3s   2 Cyclone: no points   3 War Frenzy: no points   4 Rock Fist: no points"
		),
		"literal desktop hotbar order and states"
	)
	# touch_ui is only read as a non-null layout selector by this string helper.
	hud.touch_ui = Node.new()
	check(
		(
			hud._skills_line()
			== "Smash: 3s\nCyclone: no points\nWar Frenzy: no points\nRock Fist: no points"
		),
		"literal touch hotbar labels"
	)
	hud.touch_ui.free()
	hud.touch_ui = null


func _cache(p, hud, design) -> void:
	p.abilities.buffs[&"war-frenzy"] = {"left": 5.0, "r": {"duration-s": 10.0}}
	hud._buff_icons()
	var first = hud._buffs.get_child(0)
	check(first.get_child(1).text == "W", "literal buff initial")
	check(first.get_node("Fill").anchor_top == 0.5, "literal half-duration fill")
	p.abilities.buffs[&"war-frenzy"]["left"] = 2.0
	hud._buff_icons()
	check(hud._buffs.get_child(0) == first, "duration updates retain cached node")
	check(is_equal_approx(first.get_node("Fill").anchor_top, 0.8), "cached fill updates")
	p.abilities.buffs[&"bulwark"] = {"left": 1.0, "r": design.abilities.bulwark}
	hud._buff_icons()
	check(
		first.get_parent() == null and first.is_queued_for_deletion(),
		"rebuild detaches then queues old icon"
	)
	check(hud._buff_key == "war-frenzy,bulwark", "cache preserves insertion order")
	check(hud._buffs.get_child_count() == 2, "changed buff set rebuilds both icons")
	p.abilities.buffs.clear()
	hud._buff_icons()
	check(hud._buff_key == "" and hud._buffs.get_child_count() == 0, "empty cache retires icons")


func _camera(p) -> void:
	var rig = p.get_node("CameraRig")
	rig.apply_touch_look(Vector2(30, 0), 180.0, 180.0)
	check(is_equal_approx(rig.rotation.y, -PI / 6.0), "literal touch yaw")
	p.ui_open = true
	var before: Vector3 = rig.rotation
	rig.apply_touch_look(Vector2(30, 40), 180.0, 180.0)
	check(rig.rotation == before, "panel owns touch look")
	var distance: float = rig.arm.spring_length
	rig.zoom_steps(1)
	check(rig.arm.spring_length > distance, "desktop zoom remains allowed under panel")
	rig.touch_only = true
	distance = rig.arm.spring_length
	rig.zoom_steps(1)
	check(rig.arm.spring_length == distance, "touch panel owns zoom")
	p.ui_open = false
	rig.touch_only = false


func _map(p) -> void:
	var map := WorldMap.new()
	root.add_child(map)
	map.bind(p, null)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	map.set_open(true)
	check(map.open and p.map_open, "map opens for real player")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "map reveals cursor")
	p.ui_open = true
	map.set_open(false)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "another panel retains cursor")
	check(not map._restore_cursor, "closing consumes cursor restore ownership")
	p.ui_open = false
	print("display backend: ", DisplayServer.get_name())
	if DisplayServer.get_name() != "headless":
		_native_cursor(p, map)
	else:
		print("captured-cursor controls require native display; not executed headlessly")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	map.free()


func _native_cursor(p, map) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "native capture precondition")
	map.set_open(true)
	check(map.open and p.map_open and map._restore_cursor, "map records captured cursor")
	p.ui_open = true
	map.set_open(false)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "native panel retains cursor")
	check(not map._restore_cursor, "native close consumes restore ownership")
	p.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	map.set_open(true)
	map.set_open(false)
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "ordinary map close recaptures cursor")
	print("native captured-cursor controls executed")
