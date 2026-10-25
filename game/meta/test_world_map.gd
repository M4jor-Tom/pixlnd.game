## Production-input projection, gameplay gating, live simulation, and Android owned-touch regressions.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const Combat := preload("res://game/combat/combat.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const WorldMap := preload("res://game/world/world_map.gd")
const AndroidTouch := preload("res://game/meta/android_touch.gd")
const Spawner := preload("res://game/world/spawner.gd")
const NPC := preload("res://game/entities/npc.gd")
var failed := 0
var o
var design: Dictionary
func check(ok: bool, what: String) -> void:
	if not ok:
		failed += 1; printerr("FAIL: ", what)
func frames(count: int) -> void:
	for _i in count: await physics_frame
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new(); event.physical_keycode = code; event.pressed = pressed
	Input.parse_input_event(event)
func screen(index: int, position: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new(); event.index = index; event.position = position; event.pressed = pressed; event.canceled = canceled
	Input.parse_input_event(event)
	await process_frame
func drag(index: int, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new(); event.index = index; event.position = position; event.relative = relative
	Input.parse_input_event(event)
	await process_frame
func player(class_id: StringName = &"warrior", spec_id: StringName = &"berserker") -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate(); root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(1, 1.0))
	p.setup_items(o, design, class_id, spec_id)
	p.world_min = Vector2(-8388608, -8388608); p.world_max = Vector2(8388608, 8388608)
	return p
func _initialize() -> void:
	await process_frame
	o = Model.Ontology.load_dir("res://ontology/instances"); check(o.validate(), "current ontology validates")
	design = o.configs["generators"]["design"]
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	# Full extent and player projection map all four boundaries and the origin to the intended fixed square.
	var extent := 8388608.0; var rect := Rect2(100, 50, 400, 400)
	check(WorldMap.project_position(Vector2(-extent, -extent), Vector2(-extent, -extent), Vector2(extent, extent), rect) == rect.position, "minimum corner projects to map origin")
	check(WorldMap.project_position(Vector2(extent, -extent), Vector2(-extent, -extent), Vector2(extent, extent), rect) == Vector2(rect.end.x, rect.position.y), "maximum x edge projects across map")
	check(WorldMap.project_position(Vector2(-extent, extent), Vector2(-extent, -extent), Vector2(extent, extent), rect) == Vector2(rect.position.x, rect.end.y), "maximum z edge projects across map")
	check(WorldMap.project_position(Vector2(extent, extent), Vector2(-extent, -extent), Vector2(extent, extent), rect) == rect.end, "maximum corner projects to map end")
	check(WorldMap.project_position(Vector2.ZERO, Vector2(-extent, -extent), Vector2(extent, extent), rect) == rect.get_center(), "origin projects to overview center")
	# Desktop InputEvent M toggles the live map; headless tests keep the Close-button cursor visible.
	var p := player(&"warrior", &"guardian"); var map: CanvasLayer = WorldMap.new(); root.add_child(map); map.bind(p, null)
	var holder := Node3D.new(); root.add_child(holder)
	var enemy = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": "H", "max_hp": 1000.0, "damage": 0.0,
		"positions": [Vector3(0, 0, -5)], "seed": 83}], design, o.creatures, p, null)[0]
	var enemy_start: Vector3 = enemy.position; var enemy_hp_before: float = enemy.hp
	var aim: Vector3 = enemy.global_position + Vector3.UP - p.eye()
	p.get_node("CameraRig").rotation.x = atan2(aim.y, -aim.z)
	var projectiles: Array = p._fire(design["movesets"]["bow"]["m1"], 50.0, false, [], p.eye(), Combat.PHYSICAL)
	check(not projectiles.is_empty(), "committed projectile fires before map opens")
	await physics_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	key(KEY_M, true); await process_frame; key(KEY_M, false); await process_frame
	check(map.open and p.map_open and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "desktop M opens live map and keeps cursor available")
	key(KEY_M, true); await process_frame; key(KEY_M, false); await process_frame
	check(not map.open and not p.map_open, "desktop M closes map")
	var camera: Node3D = p.get_node("CameraRig")
	p.ui_open = true
	var panel_zoom_before: float = p.get_node("CameraRig/Arm").spring_length
	camera.zoom_steps(1)
	check(p.get_node("CameraRig/Arm").spring_length != panel_zoom_before, "closed map preserves desktop panel camera zoom")
	camera.zoom_steps(-1); p.ui_open = false
	key(KEY_M, true); await process_frame; key(KEY_M, false); await process_frame
	var yaw := camera.rotation.y
	var quick_before: int = p.inventory.first_consumable().count
	var conversations: Array = []
	p.talked.connect(func(_npc): conversations.append(true))
	# Keep the interaction fixture out of the committed shot's lane at every render/physics ratio.
	var npc: Node3D = NPC.new(&"villager", "Test", Color.WHITE); root.add_child(npc); npc.position = Vector3(1, 0, 0)
	check(p._nearest_in_group("npcs", float(design["settlement"]["npc"]["interact-radius"])) == npc, "interaction fixture remains in reach beside the projectile lane")
	var distance: float = p.get_node("CameraRig/Arm").spring_length
	var class_skill = p.skill_tree.class_slot(1)
	check(class_skill != null and p.can_block(), "class skill and held block have live desktop controls")
	if class_skill != null: p.skill_tree.points[class_skill.id] = 5
	p.mp = 100.0
	var skill_cooldowns_before: int = p.abilities.cooldowns.size()
	Input.action_press("move_right"); Input.action_press("basic-attack"); Input.action_press("special-attack"); Input.action_press("class-skill-1")
	Input.action_press("interact"); Input.action_press("quick-item")
	var zoom := InputEventAction.new(); zoom.action = "zoom_in"; zoom.pressed = true; Input.parse_input_event(zoom)
	var mouse := InputEventMouseMotion.new(); mouse.relative = Vector2(20, 20); Input.parse_input_event(mouse)
	await frames(3)
	check(is_zero_approx(p.position.x) and is_zero_approx(p.position.z), "movement input is gated while map is open")
	check(p._swing_t <= 0.0, "basic attack input is gated")
	check(p._charge < 0.0 and p.mp == 100.0, "special press/release input is gated")
	check(not p.blocking and p.abilities.cooldowns.size() == skill_cooldowns_before and not p.abilities.busy(), "held block and class skill requests are gated")
	check(p.hp == p.max_hp and p.inventory.first_consumable().count == quick_before, "quick item input is gated")
	check(conversations.is_empty(), "interaction input is gated")
	check(camera.rotation.y == yaw and p.get_node("CameraRig/Arm").spring_length == distance, "look and camera zoom are gated")
	Input.action_release("move_right"); Input.action_release("basic-attack"); Input.action_release("special-attack"); Input.action_release("class-skill-1")
	Input.action_release("interact"); Input.action_release("quick-item")
	zoom.pressed = false; Input.parse_input_event(zoom)
	# Existing panel ownership survives map closure; live DOT, cooldowns, enemy simulation continue.
	p.ui_open = true
	p.abilities.cooldowns[&"smash"] = 5.0
	p.abilities.buffs[&"war-frenzy"] = {"left": 5.0, "r": {"move-mult": 1.0}}
	p.hp = 100.0
	p.apply_status(&"burning", design["status-effects"]["burning"], 100.0, p)
	await frames(35)
	check(p.hp < 100.0, "map does not protect from ordinary DOT")
	check(p.abilities.cooldowns[&"smash"] < 5.0 and p.abilities.buffs[&"war-frenzy"]["left"] < 5.0, "cooldowns and buffs continue under map")
	check(enemy.position != enemy_start, "enemy world simulation continues under map")
	check(enemy.hp < enemy_hp_before, "already-fired projectile continues and hits under map")
	# A concurrent inventory remains owner; map closure cannot recapture its visible cursor.
	var inv: Node = load("res://game/items/inventory_panel.gd").new(); root.add_child(inv); inv.bind(p)
	key(KEY_B, true); await process_frame; key(KEY_B, false); await process_frame
	check(p.ui_open and inv._panel.visible, "desktop inventory remains open underneath map")
	key(KEY_M, true); await process_frame; key(KEY_M, false); await process_frame
	check(not map.open and not p.map_open and p.ui_open and inv._panel.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "map closure preserves another panel and its cursor ownership")
	key(KEY_M, true); await process_frame; key(KEY_M, false); await process_frame
	p.hp = 1.0; p.apply_status(&"burning", design["status-effects"]["burning"], 1000.0, p)
	await frames(35)
	check(p.dead, "map does not protect from lethal DOT while another panel remains open")
	await create_timer(2.2, true, false, true).timeout
	check(not p.dead, "live map does not prevent ordinary respawn")
	key(KEY_M, true); await process_frame; key(KEY_M, false); await process_frame
	key(KEY_B, true); await process_frame; key(KEY_B, false); await process_frame
	holder.queue_free(); inv.queue_free(); map.queue_free(); p.queue_free()
	# Android native adapter: real touch actions reach the UI-only SubViewport and retain ownership/cancellation.
	var android_player := player(); android_player.mp = 100.0
	android_player.position = Vector3(-8388607.5, 0, 0)
	var android := AndroidTouch.new(); root.add_child(android)
	android.setup(o.configs["controller-profiles"]["android"], android_player, null, null, null)
	android.set_layout(Rect2(20, 20, 760, 440), Vector2.ONE)
	var android_map: CanvasLayer = WorldMap.new(); root.add_child(android_map); android_map.bind(android_player, android)
	check(android._layout_valid and android.targets["world-map"].size.x >= float(android.profile["min-target-dp"]) * android.pixels_per_dp.x and android.targets["world-map"].size.y >= float(android.profile["min-target-dp"]) * android.pixels_per_dp.y, "Map target meets safe-area 48dp minimum")
	# Concurrent movement, look and charged hold are retired when Map opens; old streams cannot resume.
	var stick_center: Vector2 = android.stick_rect.get_center()
	await screen(1, stick_center, true)
	await drag(1, stick_center + Vector2(80, 0), Vector2(80, 0))
	await screen(2, Vector2(700, 100), true)
	await drag(2, Vector2(710, 105), Vector2(10, 5))
	var special_center: Vector2 = android.targets["special-attack"].get_center()
	await screen(3, special_center, true)
	await frames(2)
	check(android_player._motion_remainder_x != 0.0, "native movement at true scale accumulates sub-ULP motion")
	check(android._owners.has(1) and android._owners.has(2) and android._owners.has(3) and android._owners[1].target == "move" and android._owners[2].target == "look" and android_player._charge >= 0.0, "native movement/look/charge streams are active before map")
	var map_center: Vector2 = android.targets["world-map"].get_center()
	await screen(4, map_center, true)
	await frames(1)
	check(android_map.open and android_player.map_open and android_player._charge < 0.0, "native Map opens and cancels uncommitted charge")
	check(android._owners[1].target == "" and android._owners[2].target == "" and android._owners[3].target == "" and android.held.is_empty() and android_player._motion_remainder_x == 0.0, "opening map retires old touches and cancels pending sub-ULP movement")
	var close_rect: Rect2 = android_map.close_button.get_global_rect()
	check(close_rect.size.x >= float(android.profile["min-target-dp"]) * android.pixels_per_dp.x and close_rect.size.y >= float(android.profile["min-target-dp"]) * android.pixels_per_dp.y and android.safe.encloses(close_rect), "native Close is safe-area contained and >=48dp")
	await screen(1, stick_center + Vector2(80, 0), false)
	var close_center := close_rect.get_center()
	await screen(5, close_center, true); await screen(5, close_center, false); await frames(2)
	check(not android_map.open and not android_player.map_open, "native Close button closes map through adapter-owned pointer path")
	var retired_position: Vector3 = android_player.position
	await frames(15)
	check(Vector2(android_player.position.x, android_player.position.z) == Vector2(retired_position.x, retired_position.z), "cancelled touch/remainder cannot replay after map close")
	var fresh_stick_center: Vector2 = android.stick_rect.get_center()
	await screen(6, fresh_stick_center, true)
	await drag(6, fresh_stick_center + Vector2(80, 0), Vector2(80, 0)); await frames(30)
	check(android_player.position != retired_position, "fresh touch after map close can move")
	await screen(6, fresh_stick_center + Vector2(80, 0), false)
	# Back is delivered through the actual Android notification path and consumes the map context.
	var map_center2: Vector2 = android.targets["world-map"].get_center()
	await screen(7, map_center2, true); await frames(1)
	root.propagate_notification(AndroidTouch.NOTIFICATION_WM_GO_BACK_REQUEST); await process_frame
	check(not android_map.open and not android_player.map_open, "Android Back notification closes map")
	check(android._owners.values().all(func(owner: Dictionary) -> bool: return owner.target == ""), "Back retires current native touch owners")
	android.queue_free(); android_map.queue_free(); android_player.queue_free()
	print("world map acceptance ok" if failed == 0 else "world map acceptance FAILED: %d" % failed)
	quit(0 if failed == 0 else 1)
