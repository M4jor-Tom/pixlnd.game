## Native screen-event -> real player/camera/panel integration, not request injection.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const Touch := preload("res://game/meta/android_touch.gd")
const InventoryPanel := preload("res://game/items/inventory_panel.gd")
const SkillPanel := preload("res://game/progression/skill_panel.gd")
const ShopPanel := preload("res://game/items/shop_panel.gd")
const Item := preload("res://game/items/item.gd")
const NPC := preload("res://game/entities/npc.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
var failed := 0
var o
var design: Dictionary
var p
var a
var inv
var skills
var shop
var world: Node
func check(ok: bool, message: String) -> void:
	if not ok: failed += 1; printerr("FAIL: ", message)
func touch(id: int, position: Vector2, down: bool, canceled := false) -> void:
	var e := InputEventScreenTouch.new(); e.index = id; e.position = position; e.pressed = down; e.canceled = canceled
	a.handle_touch(e)
func drag(id: int, position: Vector2, relative: Vector2) -> void:
	var e := InputEventScreenDrag.new(); e.index = id; e.position = position; e.relative = relative
	a.handle_touch(e)
func down(action: String, id := 10) -> void: touch(id, a.targets[action].get_center(), true)
func up(action: String, id := 10, canceled := false) -> void: touch(id, a.targets[action].get_center(), false, canceled)
func tap(action: String, id := 10) -> void: down(action, id); up(action, id)
func step(dt := .01) -> void: p._physics_process(dt)
func _init() -> void: run.call_deferred()
func fixture(class_id := &"warrior", spec := &"") -> void:
	p = PLAYER.instantiate(); root.add_child(p)
	p.setup(design.movement, design.camera, &"normal"); p.setup_combat(design.combat, design.crit, {}, 260.0); p.setup_items(o, design, class_id, spec)
	p.set_physics_process(false)
	inv = InventoryPanel.new(); skills = SkillPanel.new(); shop = ShopPanel.new()
	root.add_child(inv); root.add_child(skills); root.add_child(shop)
	a = Touch.new(); root.add_child(a)
	a.setup(o.configs["controller-profiles"].android, p, inv, skills, shop)
	inv.bind(p, a); skills.bind(p, a); shop.bind(p, world, a)
	a.set_layout(Rect2(0, 0, 1280, 720), Vector2.ONE)
	await physics_frame
	step()
func cleanup() -> void:
	a.cancel_all(); a.free(); p.free()
func click_control(control: Control, id := 30) -> void:
	var pos := control.get_global_rect().get_center(); touch(id, pos, true); touch(id, pos, false)
func select_row(list: ItemList, row: int, id := 31) -> void:
	var pos := list.get_global_rect().position + Vector2(30, 24 + 48 * row)
	touch(id, pos, true); touch(id, pos, false)
func run() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances"); design = o.configs.generators.design
	var initial = PLAYER.instantiate()
	check("touch_input" in initial, "player accepts independent touch source")
	initial.free()
	if failed: quit(1); return
	world = Node3D.new(); world.set_script(load("res://game/world/world.gd")); root.add_child(world)
	world.set_process(false); world.set_physics_process(false)
	world.configure(o,design,preload("res://game/world/world_state.gd").new(design,int(design.terrain["seed-default"])),func(): return [p] if is_instance_valid(p) else [])
	world.targeting.set_physics_process(false) # real saved vendor owner, without autonomous AI in this input fixture
	var floor := StaticBody3D.new(); var collision := CollisionShape3D.new(); var shape := BoxShape3D.new()
	shape.size = Vector3(100, 1, 100); collision.shape = shape; floor.add_child(collision); floor.position.y = -.5; root.add_child(floor)
	await fixture()
	var center: Vector2 = a.stick_rect.get_center()
	touch(0, center, true); drag(0, center + Vector2(50, 0), Vector2(50, 0)); step()
	check(is_equal_approx(p.velocity.x, 6), "native stick requests full walk speed")
	down("sprint", 1); step(.1)
	check(is_equal_approx(p.velocity.x, 10.8) and is_equal_approx(p.stamina, 99), "separate sprint multiplier and drain")
	a.cancel_all(); touch(0, center, false); up("sprint", 1)
	var rig = p.get_node("CameraRig"); var yaw: float = rig.rotation.y
	touch(2, Vector2(800, 200), true); drag(2, Vector2(1440, 100), Vector2(640, -100)); step()
	check(is_equal_approx(rig.rotation.y - yaw, -PI / 2) and rig.rotation.x > -.35, "look signed safe-width conversion")
	a.cancel_all(); touch(2, Vector2.ZERO, false)
	# Equal 100-physical-pixel drags through a nonuniform viewport transform.
	a.set_layout(Rect2(0, 0, 960, 540), Vector2(.5, .75))
	var pitch: float = rig.rotation.x; yaw = rig.rotation.y
	touch(2, Vector2(700, 100), true); drag(2, Vector2(750, 175), Vector2(50, 75)); step()
	check(is_equal_approx(rig.rotation.y - yaw, deg_to_rad(-9.375)) and is_equal_approx(rig.rotation.x - pitch, deg_to_rad(-9.375)), "F4 nonuniform equal physical distances give equal signed camera angles")
	touch(2, Vector2.ZERO, false); a.set_layout(Rect2(0, 0, 1280, 720), Vector2.ONE)
	for delta in [Vector2(0, -10000), Vector2(0, 10000)]:
		touch(2, Vector2(800, 200), true); drag(2, Vector2(800, 200) + delta, delta); step(); touch(2, Vector2.ZERO, false)
		check(is_equal_approx(rig.rotation.x, deg_to_rad(60 if delta.y < 0 else -80)), "touch pitch clamps to design bounds")
	for i in 6: tap("nearer"); step()
	check(is_zero_approx(rig._dist) and not p.get_node("Body").visible, "stepped zoom reaches first person")
	down("farther"); step(); step(); check(is_equal_approx(rig._dist, 1), "held zoom never repeats"); up("farther")
	for i in 20: tap("farther"); step()
	check(is_equal_approx(rig._dist, 12) and p.get_node("Body").visible, "far zoom clamps and restores body")
	# Native Jump enters the existing grounded jump, release cuts sustain to tap velocity.
	p.position = Vector3.ZERO; p.velocity = Vector3.ZERO
	await physics_frame; step()
	down("jump"); step()
	check(p.velocity.y > 13, "native grounded Jump starts hold-height velocity")
	up("jump"); step()
	check(p.velocity.y <= sqrt(96.0) + .001, "normal Jump release cuts to existing tap-height velocity")
	p.position = Vector3.ZERO; p.velocity = Vector3.ZERO
	await physics_frame; step()
	# Raw desktop input never supplies Android movement/attacks.
	InputMapBuilder_setup()
	Input.action_press("move_right"); Input.action_press("basic-attack"); step()
	check(is_zero_approx(p.velocity.x) and p._swing_t <= 0, "Android ignores keyboard/mouse gameplay")
	Input.action_release("move_right"); Input.action_release("basic-attack")
	# Distinct charged cancellation and intentional completion for all charged classes.
	cleanup()
	for cls in [&"warrior", &"ranger", &"mage"]:
		await fixture(cls)
		p.mp = 100; down("special-attack"); step(.1)
		check(p._charge > 0 and not p.blocking, str(cls) + " special does not request block")
		up("special-attack", 10, true); step()
		check(p._charge < 0 and is_equal_approx(p.mp, 100), str(cls) + " cancel never spends reserved MP")
		down("special-attack"); step(.1); up("special-attack"); step()
		check(p._charge < 0 and p.mp < 100, str(cls) + " normal release spends charge")
		cleanup()
	await fixture(&"rogue")
	p.mp = 100; down("special-attack"); step()
	check(is_zero_approx(p.mp), "Rogue instant special once on down")
	step(); up("special-attack"); cleanup()
	await fixture(&"warrior", &"guardian")
	rig = p.get_node("CameraRig")
	p.mp = 100; down("block"); step()
	check(p.blocking and p._charge < 0, "block independent from special")
	a.cancel_all(); up("block")
	down("basic-attack"); step(); var swing: float = p._swing_t; step(.01)
	check(p._swing_t < swing, "held basic attack does not repeat"); up("basic-attack")
	p._swing_t = 0; p.skill_tree.points = {&"smash": 5, &"cyclone": 1, &"war-frenzy": 1}
	tap("class-skill-1", 11); tap("basic-attack", 12); step()
	check(p.abilities.busy() and p._swing_t <= 0, "arrival order skill busy state excludes later basic")
	p.abilities.reset(); p.abilities.cooldowns.clear(); p.stamina = 100; p._swing_t = 0
	tap("basic-attack", 12); tap("class-skill-1", 11); step()
	check(p._swing_t > 0 and p.abilities.busy(), "basic committed first does not invent skill exclusion")
	p.abilities.reset(); p.abilities.cooldowns.clear(); p.stamina = 100; p._swing_t = 0
	for order in [["basic-attack", "inventory"], ["inventory", "basic-attack"]]:
		for action in order: tap(action, 12)
		step(); check(p.ui_open and p._swing_t <= 0, "panel preempts ALL queued gameplay " + str(order)); a.back()
	# Drop unready requests, do not replay after eligibility returns.
	p.ground_ready = func(_pos): return false
	tap("basic-attack"); step(); p.ground_ready = func(_pos): return true
	step(); check(p._swing_t <= 0, "unavailable frame drains trigger")
	for terminal in ["release", "cancel", "slide"]:
		p.mp = 100; down("special-attack"); step(.1)
		check(p._charge > 0, "F2 charge starts before unavailable " + terminal)
		p.ground_ready = func(_pos): return false
		step(.1); check(p._charge > 0, "F2 ordinary held charge retained while unavailable " + terminal)
		if terminal == "slide": drag(10, Vector2.ZERO, Vector2(-100, -100))
		else: up("special-attack", 10, terminal == "cancel")
		step(.1)
		check(p._charge < 0 and is_equal_approx(p.mp, 100), "F2 unavailable terminal cancels without fire/spend " + terminal)
		p.ground_ready = func(_pos): return true
		step(.1); step(.1)
		check(p._charge < 0 and is_equal_approx(p.mp, 100), "F2 charge never resumes/replays after readiness " + terminal)
		if terminal == "slide": up("special-attack")
	# Competing requests recheck resources in arrival order, using current movement.
	for order in [["class-skill-1", "dodge"], ["dodge", "class-skill-1"]]:
		p.abilities.reset(); p.abilities.cooldowns.clear(); p.stamina = 100; p._dodge = {}; p._dodge_cd = 0
		touch(0, a.stick_rect.get_center(), true)
		drag(0, a.stick_rect.get_center() + Vector2(60, 0), Vector2(60, 0))
		for action in order: tap(action)
		step()
		check((p.abilities.busy() and p._dodge.is_empty() and p.stamina == 0) if order[0] == "class-skill-1" else (not p.abilities.busy() and not p._dodge.is_empty() and p.stamina == 75), "arrival resource recheck " + str(order))
		a.cancel_all(); touch(0, Vector2.ZERO, false)
	p.abilities.reset(); p._dodge = {}; p._dodge_cd = 0
	# A panel opened by actual vendor Talk also suppresses all pending combat.
	var vendor := NPC.new(&"item-vendor", "Item Vendor", Color.BLUE)
	vendor.position = p.position + Vector3(1, 0, 0); root.add_child(vendor)
	for order in [["basic-attack", "interact"], ["interact", "basic-attack"]]:
		p._swing_t = 0
		for action in order: tap(action)
		step()
		check(a.panel_id == "shop" and p._swing_t <= 0, "vendor panel preempts pending attacks " + str(order))
		a.back()
	vendor.free()
	# Separate Jump/Swim Up, and holds cannot convert across water/land.
	p.position = Vector3(0, 2, 0); p.water_top = 100
	down("jump"); step(); check(p.velocity.y < 0, "Jump is not swimming ascent")
	p.water_top = -INF; step(); check(p.velocity.y <= 0, "held water Jump cannot become ground jump"); up("jump")
	p.water_top = 100; down("swim-ascent"); step(); check(is_equal_approx(p.velocity.y, 3), "separate ascent")
	p.water_top = -INF; step(); p.water_top = 100; step(); check(p.velocity.y < 0, "ascent context exit retires touch"); up("swim-ascent"); p.water_top = -INF
	# Starting in the wrong context cannot convert even between two physics ticks.
	p.position.y = 0; p.water_top = 100; down("jump"); p.water_top = -INF; step()
	check(p.velocity.y <= 0, "water Jump down cannot convert before first consuming frame"); up("jump")
	p.water_top = -INF; down("swim-ascent"); p.position.y = 2; p.water_top = 100; step()
	check(p.velocity.y < 0, "land ascent down cannot convert before first consuming frame"); up("swim-ascent"); p.water_top = -INF
	# Distinct Talk, pickup and one first-stack Quick Item.
	var ground := Area3D.new(); ground.set_script(load("res://game/items/ground_item.gd"))
	ground.item = Item.stack(&"consumable", &"life-potion", 1); ground.label = "Potion"; ground.add_to_group("ground-items"); ground.position = p.position; root.add_child(ground)
	tap("interact"); step(); check(not ground.is_queued_for_deletion(), "Talk never falls back to pickup")
	tap("pick-up"); step(); check(ground.is_queued_for_deletion(), "Pick Up invokes ground collection")
	var count: int = p.inventory.first_consumable().count
	p.hp = 1; down("quick-item"); step(); step(); up("quick-item")
	check(p.inventory.first_consumable().count == count - 1, "Quick Item once on down, first stack retained")
	# All real native panels: selection/scroll do not commit, operations commit only on inside release.
	for id in ["inventory", "skills-window", "shop"]:
		a.open_panel(id); await process_frame; await process_frame
		check(p.ui_open and not a._gameplay.visible, id + " exclusive touch ownership")
		var hp: float = p.hp; p.apply_status(&"poison", design["status-effects"].poison, 10, p); step(.1)
		check(is_equal_approx(p.hp, hp), id + " DOT never ticks early"); step(.9)
		check(is_equal_approx(p.hp, hp - 10), id + " DOT stays live at one second"); p.statuses.clear()
		p.abilities.cooldowns[&"smash"] = 1; p._swing_t = .3; p._combo_t = .3; p.combo = 2
		step(.5)
		check(is_equal_approx(p.abilities.cooldowns[&"smash"], .5) and p.combo == 0 and p._swing_t <= 0, id + " timers advance once")
		var before_yaw: float = rig.rotation.y
		tap("basic-attack"); step(); check(p._swing_t <= 0 and is_equal_approx(rig.rotation.y, before_yaw), id + " no gameplay leakage")
		a.back(); check(not p.ui_open, id + " Back closes")
	a.open_panel("skills-window"); p.skill_points = 2; skills._refresh(); await process_frame; await process_frame
	select_row(skills._list, 0); check(p.skill_points == 2, "selection alone never spends")
	click_control(skills.touch_buttons[0]); check(p.skill_points == 1, "native Spend inside release once")
	var pos: Vector2 = skills.touch_buttons[0].get_global_rect().get_center()
	touch(30, pos, true); drag(30, Vector2.ZERO, -pos); drag(30, pos, pos); touch(30, pos, false)
	check(p.skill_points == 1, "confirmation slide out/back terminal cancel")
	for interruption in ["focus", "layout", "back"]:
		select_row(skills._list, 0)
		var bank_before: int = p.skill_points
		pos = skills.touch_buttons[0].get_global_rect().get_center(); touch(30, pos, true)
		match interruption:
			"focus": a._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
			"layout": a.set_layout(a.safe, a.pixels_per_dp)
			"back": a.back()
		touch(30, pos, false)
		check(p.skill_points == bank_before, "native confirmation canceled by " + interruption)
		a.open_panel("skills-window"); await process_frame; await process_frame
	a.open_panel("inventory"); await process_frame; await process_frame
	var potion_row := -1
	for i in inv._rows.size():
		if inv._rows[i].type == &"consumable": potion_row = i; break
	select_row(inv._list, potion_row); var selected = inv._rows[potion_row]; count = selected.count
	click_control(inv.touch_buttons[1]); check(selected.count == count - 1, "native Use selected bag row")
	var apple = Item.stack(&"consumable", &"apple", 2); p.inventory.add(apple)
	await process_frame; await process_frame
	var first_count: int = p.inventory.first_consumable().count
	select_row(inv._list, inv._rows.find(apple)); click_control(inv.touch_buttons[1])
	check(apple.count == 1 and p.inventory.first_consumable().count == first_count, "Use selects second consumable, never Quick Item target")
	# Populate every slot supported by existing equip routing, not an injected equipment dictionary.
	for definition in [[&"weapon", &"shield"], [&"chest-armor", &""], [&"gloves", &""], [&"boots", &""], [&"shoulder-armor", &""], [&"amulet", &""], [&"ring", &""]]:
		var worn := Item.new(); worn.type = definition[0]; worn.subtype = definition[1]; worn.material = &"iron"; worn.rarity = 4
		p.inventory.add(worn); check(p.inventory.equip(worn), "F3 real equip " + str(definition[0]))
	check(p.inventory.equipment.size() == 8, "F3 normally populated supported equipment")
	# Layout under a high-DPI phone's logical viewport: every panel operation stays safe and >=48dp.
	for id in ["inventory", "skills-window", "shop"]:
		a.set_layout(Rect2(0, 0, 1280, 720), Vector2(2, 2)); a.open_panel(id)
		await process_frame; await process_frame
		var panel = a.panels[id]
		check(a.safe.encloses(panel._panel.get_global_rect()), id + " high-DPI panel remains in safe area")
		for button in panel.touch_buttons:
			var rect: Rect2 = button.get_global_rect()
			check(a.safe.encloses(rect) and rect.size.x >= 96 and rect.size.y >= 96, id + " high-DPI confirmation safe >=48dp")
	a.open_panel("inventory"); await process_frame; await process_frame
	var bag_rect: Rect2 = inv._list.get_global_rect()
	var bag_row: Rect2 = inv._list.get_item_rect(0)
	check(bag_rect.size.y >= 96 and a.safe.encloses(bag_rect) and bag_row.size.y >= 96 and bag_row.end.y <= bag_rect.size.y, "F3 filled inventory has a safe accessible >=48dp bag row")
	var potion_before: int = p.inventory.first_consumable().count
	pos = bag_rect.position + bag_row.get_center(); touch(36, pos, true); touch(36, pos, false)
	click_control(inv.touch_buttons[1], 37)
	check(p.inventory.first_consumable().count == potion_before - 1, "F3 filled high-DPI bag selection and Use are reachable")
	await process_frame; await process_frame
	var worn_list: ItemList = inv._touch_worn
	check(worn_list.item_count == p.inventory.equipment.size() + 1 and a.safe.encloses(worn_list.get_global_rect()), "F3 all worn information retained in safe native scroller")
	for slot in p.inventory.equipment:
		var line := "%s: %s" % [slot, p.item_label(p.inventory.equipment[slot])]
		check(range(worn_list.item_count).any(func(i): return worn_list.get_item_text(i) == line), "F3 full worn line retained " + str(slot))
	pos = worn_list.get_global_rect().get_center()
	touch(38, pos, true); drag(38, pos - Vector2(0, 2000), Vector2(0, -2000)); touch(38, pos - Vector2(0, 2000), false)
	var scroll: VScrollBar = worn_list.get_v_scroll_bar()
	check(scroll.value > 0 and is_equal_approx(scroll.value, scroll.max_value - scroll.page) and p.inventory.first_consumable().count == potion_before - 1, "F3 owned worn scroll reaches last equipment without committing")
	for button in a._navigation.get_children():
		var rect: Rect2 = button.get_global_rect()
		check(a.safe.encloses(rect) and rect.size.x >= 96 and rect.size.y >= 96, "F3 filled inventory navigation safe >=48dp")
	a.set_layout(Rect2(0, 0, 1280, 720), Vector2.ONE); a.open_panel("inventory")
	await process_frame; await process_frame
	# Equip uses the selected row; Buy and Sell go through real native confirmation.
	var gear := Item.new(); gear.type = &"weapon"; gear.subtype = &"sword"; gear.material = &"iron"
	p.inventory.add(gear); await process_frame; await process_frame
	select_row(inv._list, inv._rows.find(gear))
	click_control(inv.touch_buttons[0]); check(p.inventory.equipment.values().has(gear), "native Equip selected row")
	var wrong := Item.new(); wrong.type = &"chest-armor"; wrong.material = &"silk"
	var wrong_weapon := Item.new(); wrong_weapon.type = &"weapon"; wrong_weapon.subtype = &"wand"; wrong_weapon.material = &"wood"
	p.inventory.add(wrong); p.inventory.add(wrong_weapon); await process_frame; await process_frame
	var wrong_row: int = inv._rows.find(wrong); var weapon_row: int = inv._rows.find(wrong_weapon)
	check(wrong_row >= 0 and inv._list.get_item_custom_fg_color(wrong_row) == Color.RED, "touch inventory marks wrong-class armor red")
	check(weapon_row >= 0 and inv._list.get_item_custom_fg_color(weapon_row) == Color.RED, "touch inventory marks wrong-class weapon red")
	select_row(inv._list, wrong_row); click_control(inv.touch_buttons[0])
	select_row(inv._list, weapon_row); click_control(inv.touch_buttons[0])
	check(wrong in p.inventory.entries and wrong_weapon in p.inventory.entries and not p.inventory.equipment.values().has(wrong), "native Equip rejects wrong-class gear without removal")
	a.back()
	vendor = NPC.new(&"item-vendor", "Item Vendor", Color.BLUE); vendor.position = p.position; root.add_child(vendor)
	tap("interact"); step(); await process_frame; await process_frame
	check(a.panel_id == "shop" and shop._stock_rows.size() > 0, "actual Talk opens generated vendor shop")
	p.inventory.coins = 1000; shop._refresh(); await process_frame; await process_frame
	var coins: int = p.inventory.coins
	select_row(shop._stock, 0); check(p.inventory.coins == coins, "stock selection does not buy")
	click_control(shop.touch_buttons[0]); check(p.inventory.coins < coins, "native Buy selected stock")
	await process_frame; await process_frame
	coins = p.inventory.coins; select_row(shop._bag, 1); click_control(shop.touch_buttons[1])
	check(p.inventory.coins > coins, "native Sell selected bag entry")
	# Long native lists scroll under an owned drag without committing any operation.
	for i in 30:
		var extra := Item.new(); extra.type = &"weapon"; extra.subtype = &"sword"; extra.material = &"iron"; p.inventory.add(extra)
	a.open_panel("inventory"); await process_frame; await process_frame
	var coins_before: int = p.inventory.coins
	var list_pos: Vector2 = inv._list.get_global_rect().get_center()
	touch(35, list_pos, true); drag(35, list_pos - Vector2(0, 100), Vector2(0, -100)); touch(35, list_pos - Vector2(0, 100), false)
	check(inv._list.get_v_scroll_bar().value > 0 and p.inventory.coins == coins_before, "owned native list scrolling never commits")
	a.back(); vendor.free()
	p.hp = 1; tap("quick-item"); p.apply_status(&"poison", design["status-effects"].poison, 10, p); step(1.0)
	check(p.dead and p.hp == 0 and a.take_frame().requests.is_empty(), "death preempts queued heal and clears touches")
	await create_timer(float(design.combat.death["respawn-s"]) + .1).timeout
	cleanup()
	await fixture(&"rogue", &"assassin")
	check(not a.buttons.has("class-skill-4") and a.buttons.has("class-skill-3") and not a.buttons.has("ultimate"), "Assassin has only third-slot Camouflage, no fifth alias")
	cleanup()
	print("android controls ok" if failed == 0 else "android controls FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
func InputMapBuilder_setup() -> void:
	load("res://game/meta/input_map.gd").build(o.configs.keybinds.hybrid)
