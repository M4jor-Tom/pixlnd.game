## Native screen-event -> real player/camera/panel integration, not request injection.
extends SceneTree
const PanelCases := preload("res://game/entities/android_controls_panel_cases.gd")
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
	if not ok:
		failed += 1
		printerr("FAIL: ", message)


func touch(id: int, position: Vector2, down: bool, canceled := false) -> void:
	var e := InputEventScreenTouch.new()
	e.index = id
	e.position = position
	e.pressed = down
	e.canceled = canceled
	a.handle_touch(e)


func drag(id: int, position: Vector2, relative: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = id
	e.position = position
	e.relative = relative
	a.handle_touch(e)


func down(action: String, id := 10) -> void:
	touch(id, a.targets[action].get_center(), true)


func up(action: String, id := 10, canceled := false) -> void:
	touch(id, a.targets[action].get_center(), false, canceled)


func tap(action: String, id := 10) -> void:
	down(action, id)
	up(action, id)


func step(dt := .01) -> void:
	p._physics_process(dt)


func _init() -> void:
	run.call_deferred()


func fixture(class_id := &"warrior", spec := &"") -> void:
	p = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design.movement, design.camera, &"normal")
	p.setup_combat(design.combat, design.crit, {}, 260.0)
	p.setup_items(o, design, class_id, spec)
	p.set_physics_process(false)
	inv = InventoryPanel.new()
	skills = SkillPanel.new()
	shop = ShopPanel.new()
	root.add_child(inv)
	root.add_child(skills)
	root.add_child(shop)
	a = Touch.new()
	root.add_child(a)
	a.setup(o.configs["controller-profiles"].android, p, inv, skills, shop)
	inv.bind(p, a)
	skills.bind(p, a)
	shop.bind(p, world, a)
	a.set_layout(Rect2(0, 0, 1280, 720), Vector2.ONE)
	await physics_frame
	step()


func cleanup() -> void:
	a.cancel_all()
	a.free()
	p.free()


func click_control(control: Control, id := 30) -> void:
	var pos := control.get_global_rect().get_center()
	touch(id, pos, true)
	touch(id, pos, false)


func select_row(list: ItemList, row: int, id := 31) -> void:
	var pos := list.get_global_rect().position + Vector2(30, 24 + 48 * row)
	touch(id, pos, true)
	touch(id, pos, false)


func run() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	design = o.configs.generators.design
	var initial = PLAYER.instantiate()
	check("touch_input" in initial, "player accepts independent touch source")
	initial.free()
	if failed:
		quit(1)
		return
	if not (_world_fixture() and await _movement_controls() and await _combat_controls()):
		return
	_finish()


func _movement_controls() -> bool:
	if not await _walk_controls():
		return false
	var rig = p.get_node("CameraRig")
	return (
		await _look_controls(rig)
		and await _zoom_controls(rig)
		and await _jump_controls()
		and await _desktop_controls()
	)


func _combat_controls() -> bool:
	if not await _charged_controls():
		return false
	await fixture(&"warrior", &"guardian")
	var rig = p.get_node("CameraRig")
	return await _combat_order() and await _water_items() and await _panel_controls(rig)


func _combat_order() -> bool:
	return (
		await _guardian_controls()
		and await PanelCases.batch_preemption(self)
		and await _unavailable_controls()
		and await _competing_controls()
		and await PanelCases.vendor_preemption(self)
	)


func _water_items() -> bool:
	return await _swim_controls() and await _context_controls() and await _pickup_controls()


func _panel_controls(rig) -> bool:
	if not await PanelCases.run(self, rig):
		return false
	if not await _death_controls() or not await _assassin_controls():
		return false
	await _reentrant_confirmation()
	return true


func InputMapBuilder_setup() -> void:
	load("res://game/meta/input_map.gd").build(o.configs.keybinds.hybrid)


func _reentrant_confirmation() -> void:
	await fixture()
	a.open_panel("skills-window")
	p.skill_points = 2
	skills._refresh()
	await process_frame
	await process_frame
	select_row(skills._list, 0)
	var observed := []
	p.skills_changed.connect(
		func():
			observed.append(a.confirming)
			a.open_panel("inventory")
	)
	click_control(skills.touch_buttons[0])
	check(observed == [true], "T8 confirmation remains true during synchronous panel callback")
	check(
		p.skill_points == 1 and a.panel_id == "inventory",
		"T8 callback commits once then changes panel"
	)
	if not _confirmation_flags():
		return
	cleanup()


func _walk_controls() -> bool:
	await fixture()
	var center: Vector2 = a.stick_rect.get_center()
	touch(0, center, true)
	drag(0, center + Vector2(50, 0), Vector2(50, 0))
	step()
	check(is_equal_approx(p.velocity.x, 6), "native stick requests full walk speed")
	down("sprint", 1)
	step(.1)
	check(
		is_equal_approx(p.velocity.x, 10.8) and is_equal_approx(p.stamina, 99),
		"separate sprint multiplier and drain"
	)
	a.cancel_all()
	touch(0, center, false)
	up("sprint", 1)
	return true


func _look_controls(rig) -> bool:
	var yaw: float = rig.rotation.y
	touch(2, Vector2(800, 200), true)
	drag(2, Vector2(1440, 100), Vector2(640, -100))
	step()
	check(
		is_equal_approx(rig.rotation.y - yaw, -PI / 2) and rig.rotation.x > -.35,
		"look signed safe-width conversion"
	)
	a.cancel_all()
	touch(2, Vector2.ZERO, false)
	# Equal 100-physical-pixel drags through a nonuniform viewport transform.
	a.set_layout(Rect2(0, 0, 960, 540), Vector2(.5, .75))
	var pitch: float = rig.rotation.x
	yaw = rig.rotation.y
	touch(2, Vector2(700, 100), true)
	drag(2, Vector2(750, 175), Vector2(50, 75))
	step()
	check(
		(
			is_equal_approx(rig.rotation.y - yaw, deg_to_rad(-9.375))
			and is_equal_approx(rig.rotation.x - pitch, deg_to_rad(-9.375))
		),
		"F4 nonuniform equal physical distances give equal signed camera angles"
	)
	touch(2, Vector2.ZERO, false)
	a.set_layout(Rect2(0, 0, 1280, 720), Vector2.ONE)
	for delta in [Vector2(0, -10000), Vector2(0, 10000)]:
		touch(2, Vector2(800, 200), true)
		drag(2, Vector2(800, 200) + delta, delta)
		step()
		touch(2, Vector2.ZERO, false)
		check(
			is_equal_approx(rig.rotation.x, deg_to_rad(60 if delta.y < 0 else -80)),
			"touch pitch clamps to design bounds"
		)
	return true


func _zoom_controls(rig) -> bool:
	for i in 6:
		tap("nearer")
		step()
	check(
		is_zero_approx(rig._dist) and not p.get_node("Body").visible,
		"stepped zoom reaches first person"
	)
	down("farther")
	step()
	step()
	check(is_equal_approx(rig._dist, 1), "held zoom never repeats")
	up("farther")
	for i in 20:
		tap("farther")
		step()
	check(
		is_equal_approx(rig._dist, 12) and p.get_node("Body").visible,
		"far zoom clamps and restores body"
	)
	return true


func _jump_controls() -> bool:
	# Native Jump enters the existing grounded jump, release cuts sustain to tap velocity.
	p.position = Vector3.ZERO
	p.velocity = Vector3.ZERO
	await physics_frame
	step()
	down("jump")
	step()
	check(p.velocity.y > 13, "native grounded Jump starts hold-height velocity")
	up("jump")
	step()
	check(
		p.velocity.y <= sqrt(96.0) + .001,
		"normal Jump release cuts to existing tap-height velocity"
	)
	p.position = Vector3.ZERO
	p.velocity = Vector3.ZERO
	await physics_frame
	step()
	return true


func _desktop_controls() -> bool:
	# Raw desktop input never supplies Android movement/attacks.
	InputMapBuilder_setup()
	Input.action_press("move_right")
	Input.action_press("basic-attack")
	step()
	check(
		is_zero_approx(p.velocity.x) and p._swing_t <= 0, "Android ignores keyboard/mouse gameplay"
	)
	Input.action_release("move_right")
	Input.action_release("basic-attack")
	return true


func _charged_controls() -> bool:
	# Distinct charged cancellation and intentional completion for all charged classes.
	cleanup()
	for cls in [&"warrior", &"ranger", &"mage"]:
		await fixture(cls)
		p.mp = 100
		down("special-attack")
		step(.1)
		check(p._charge > 0 and not p.blocking, str(cls) + " special does not request block")
		up("special-attack", 10, true)
		step()
		check(
			p._charge < 0 and is_equal_approx(p.mp, 100),
			str(cls) + " cancel never spends reserved MP"
		)
		down("special-attack")
		step(.1)
		up("special-attack")
		step()
		check(p._charge < 0 and p.mp < 100, str(cls) + " normal release spends charge")
		cleanup()
	await fixture(&"rogue")
	p.mp = 100
	down("special-attack")
	step()
	check(is_zero_approx(p.mp), "Rogue instant special once on down")
	step()
	up("special-attack")
	cleanup()
	return true


func _guardian_controls() -> bool:
	p.mp = 100
	down("block")
	step()
	check(p.blocking and p._charge < 0, "block independent from special")
	a.cancel_all()
	up("block")
	down("basic-attack")
	step()
	var swing: float = p._swing_t
	step(.01)
	check(p._swing_t < swing, "held basic attack does not repeat")
	up("basic-attack")
	p._swing_t = 0
	p.skill_tree.points = {&"smash": 5, &"cyclone": 1, &"war-frenzy": 1}
	tap("class-skill-1", 11)
	tap("basic-attack", 12)
	step()
	check(
		p.abilities.busy() and p._swing_t <= 0,
		"arrival order skill busy state excludes later basic"
	)
	p.abilities.reset()
	p.abilities.cooldowns.clear()
	p.stamina = 100
	p._swing_t = 0
	tap("basic-attack", 12)
	tap("class-skill-1", 11)
	step()
	check(
		p._swing_t > 0 and p.abilities.busy(),
		"basic committed first does not invent skill exclusion"
	)
	return true


func _unavailable_controls() -> bool:
	# Drop unready requests, do not replay after eligibility returns.
	p.ground_ready = func(_pos): return false
	tap("basic-attack")
	step()
	p.ground_ready = func(_pos): return true
	step()
	check(p._swing_t <= 0, "unavailable frame drains trigger")
	for terminal in ["release", "cancel", "slide"]:
		if not _unavailable_terminal(terminal):
			return false
	return true


func _competing_controls() -> bool:
	# Competing requests recheck resources in arrival order, using current movement.
	for order in [["class-skill-1", "dodge"], ["dodge", "class-skill-1"]]:
		if not _competing_request(order):
			return false

	p.abilities.reset()
	p._dodge = {}
	p._dodge_cd = 0
	return true


func _swim_controls() -> bool:
	# Separate Jump/Swim Up, and holds cannot convert across water/land.
	p.position = Vector3(0, 2, 0)
	p.water_top = 100
	down("jump")
	step()
	check(p.velocity.y < 0, "Jump is not swimming ascent")
	p.water_top = -INF
	step()
	check(p.velocity.y <= 0, "held water Jump cannot become ground jump")
	up("jump")
	p.water_top = 100
	down("swim-ascent")
	step()
	check(is_equal_approx(p.velocity.y, 3), "separate ascent")
	p.water_top = -INF
	step()
	p.water_top = 100
	step()
	check(p.velocity.y < 0, "ascent context exit retires touch")
	up("swim-ascent")
	p.water_top = -INF
	return true


func _context_controls() -> bool:
	# Starting in the wrong context cannot convert even between two physics ticks.
	p.position.y = 0
	p.water_top = 100
	down("jump")
	p.water_top = -INF
	step()
	check(p.velocity.y <= 0, "water Jump down cannot convert before first consuming frame")
	up("jump")
	p.water_top = -INF
	down("swim-ascent")
	p.position.y = 2
	p.water_top = 100
	step()
	check(p.velocity.y < 0, "land ascent down cannot convert before first consuming frame")
	up("swim-ascent")
	p.water_top = -INF
	return true


func _pickup_controls() -> bool:
	# Distinct Talk, pickup and one first-stack Quick Item.
	var ground := Area3D.new()
	ground.set_script(load("res://game/items/ground_item.gd"))
	ground.item = Item.stack(&"consumable", &"life-potion", 1)
	ground.label = "Potion"
	ground.add_to_group("ground-items")
	ground.position = p.position
	root.add_child(ground)
	tap("interact")
	step()
	check(not ground.is_queued_for_deletion(), "Talk never falls back to pickup")
	tap("pick-up")
	step()
	check(ground.is_queued_for_deletion(), "Pick Up invokes ground collection")
	var count: int = p.inventory.first_consumable().count
	p.hp = 1
	down("quick-item")
	step()
	step()
	up("quick-item")
	check(
		p.inventory.first_consumable().count == count - 1,
		"Quick Item once on down, first stack retained"
	)
	return true


func _death_controls() -> bool:
	p.hp = 1
	tap("quick-item")
	p.apply_status(&"poison", design["status-effects"].poison, 10, p)
	step(1.0)
	check(
		p.dead and p.hp == 0 and a.take_frame().requests.is_empty(),
		"death preempts queued heal and clears touches"
	)
	await create_timer(float(design.combat.death["respawn-s"]) + .1).timeout
	cleanup()
	return true


func _assassin_controls() -> bool:
	await fixture(&"rogue", &"assassin")
	var assassin_slots = (
		not a.buttons.has("class-skill-4")
		and a.buttons.has("class-skill-3")
		and not a.buttons.has("ultimate")
	)
	check(assassin_slots, "Assassin has only third-slot Camouflage, no fifth alias")
	cleanup()
	return true


# Owner-approved complexity deferral; follow docs/HANDOFF.md.
# @cognitive-defer arrival-resource-recheck
func _competing_request(order) -> bool:
	p.abilities.reset()
	p.abilities.cooldowns.clear()
	p.stamina = 100
	p._dodge = {}
	p._dodge_cd = 0
	touch(0, a.stick_rect.get_center(), true)
	drag(0, a.stick_rect.get_center() + Vector2(60, 0), Vector2(60, 0))
	for action in order:
		tap(action)
	step()
	check(
		(
			(p.abilities.busy() and p._dodge.is_empty() and p.stamina == 0)
			if order[0] == "class-skill-1"
			else (not p.abilities.busy() and not p._dodge.is_empty() and p.stamina == 75)
		),
		"arrival resource recheck " + str(order)
	)
	a.cancel_all()
	touch(0, Vector2.ZERO, false)
	return true


func _world_fixture() -> bool:
	world = Node3D.new()
	world.set_script(load("res://game/world/world.gd"))
	root.add_child(world)
	world.set_process(false)
	world.set_physics_process(false)
	world.configure(
		o,
		design,
		preload("res://game/world/world_state.gd").new(design, int(design.terrain["seed-default"])),
		func(): return [p] if is_instance_valid(p) else []
	)
	world.targeting.set_physics_process(false)  # real saved vendor owner, without autonomous AI in this input fixture
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(100, 1, 100)
	collision.shape = shape
	floor.add_child(collision)
	floor.position.y = -.5
	root.add_child(floor)
	return true


func _unavailable_terminal(terminal: String) -> bool:
	p.mp = 100
	down("special-attack")
	step(.1)
	check(p._charge > 0, "F2 charge starts before unavailable " + terminal)
	p.ground_ready = func(_pos): return false
	step(.1)
	check(p._charge > 0, "F2 ordinary held charge retained while unavailable " + terminal)
	if terminal == "slide":
		drag(10, Vector2.ZERO, Vector2(-100, -100))
	else:
		up("special-attack", 10, terminal == "cancel")
	step(.1)
	check(
		p._charge < 0 and is_equal_approx(p.mp, 100),
		"F2 unavailable terminal cancels without fire/spend " + terminal
	)
	p.ground_ready = func(_pos): return true
	step(.1)
	step(.1)
	check(
		p._charge < 0 and is_equal_approx(p.mp, 100),
		"F2 charge never resumes/replays after readiness " + terminal
	)
	if terminal == "slide":
		up("special-attack")
	return true


func _confirmation_flags() -> bool:
	check(not a.confirming, "T8 confirmation clears after callback")
	check(a._pointer_control == null, "T8 pointer control clears after callback")
	check(not a._pointer_down, "T8 pointer button clears after callback")
	check(
		a._occupied.is_empty() and a._owners.is_empty(),
		"T8 synchronous cancellation retires released pointer"
	)
	return true


func _finish() -> void:
	print("android controls ok" if failed == 0 else "android controls FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
