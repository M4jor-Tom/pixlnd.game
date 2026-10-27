## Stun/death admission at real input consumers and shared requested-action endpoints (F2).
## Native screen events here are desktop synthetic evidence, not Android hardware acceptance.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const GROUND := preload("res://game/items/ground_item.tscn")
const NPC := preload("res://game/entities/npc.gd")
const Item := preload("res://game/items/item.gd")
const Touch := preload("res://game/meta/android_touch.gd")
const InventoryPanel := preload("res://game/items/inventory_panel.gd")
const SkillPanel := preload("res://game/progression/skill_panel.gd")
const ShopPanel := preload("res://game/items/shop_panel.gd")
const World := preload("res://game/world/world.gd")
const WorldState := preload("res://game/world/world_state.gd")

var failed := 0
var o
var design: Dictionary
var p
var world
var touch_ui
var inventory_panel
var skill_panel
var shop_panel
var supplier_id: String
var key_driver: KeyDriver
var signals := {}


# Godot stamps parsed key edges for the next physics tick. Emit one tick before
# observing admission, at a priority preceding the real player's normal callback.
class KeyDriver:
	extends Node
	var action := ""
	var sent := false
	var edge := false

	func _physics_process(_dt: float) -> void:
		if action == "":
			return
		if sent:
			edge = Input.is_action_just_pressed(action)
			action = ""
			sent = false
			return
		var event = InputMap.action_get_events(action)[0].duplicate()
		event.pressed = true
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		sent = true


func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", message)


func _init() -> void:
	run.call_deferred()


func frames(count := 1) -> void:
	for i in count:
		await physics_frame
		await process_frame  # Observe after the real player callback, not before it.


func key(action: String, down: bool) -> void:
	var event = InputMap.action_get_events(action)[0].duplicate()
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func key_frame(action: String) -> void:
	key_driver.edge = false
	key_driver.action = action
	await frames(2)
	check(key_driver.edge, "precondition: mapped edge " + action)
	key(action, false)


func touch_at(position: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 20
	event.position = position
	event.pressed = down
	touch_ui.handle_touch(event)


func button(action: String, down: bool) -> void:
	touch_at(touch_ui.targets[action].get_center(), down)


func tap(action: String) -> void:
	button(action, true)
	button(action, false)


func fixture(native := false) -> void:
	p = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design.movement, design.camera, &"normal")
	p.setup_combat(design.combat, design.crit, {}, 260.0)
	p.setup_items(o, design)
	p.inventory.coins = 100
	p.spawn_point = Vector3(9, 0, 9)
	p.skill_tree.points = {&"smash": 1}
	p.hp = 50.0
	signals = {"bag": 0, "talk": 0, "notice": 0, "skills": 0, "pickup": 0}
	p.inventory.changed.connect(func(): signals.bag += 1)
	p.talked.connect(func(_npc): signals.talk += 1)
	p.talked.connect(world.on_talked)
	p.notice.connect(func(_text): signals.notice += 1)
	p.skills_changed.connect(func(): signals.skills += 1)
	p.picked_up.connect(func(_text): signals.pickup += 1)
	inventory_panel = InventoryPanel.new()
	skill_panel = SkillPanel.new()
	shop_panel = ShopPanel.new()
	root.add_child(inventory_panel)
	root.add_child(skill_panel)
	root.add_child(shop_panel)
	shop_panel.set_process(false)  # Do not close the just-opened shop on the same E edge.
	if native:
		touch_ui = Touch.new()
		root.add_child(touch_ui)
		touch_ui.setup(
			o.configs["controller-profiles"].android, p, inventory_panel, skill_panel, shop_panel
		)
		touch_ui.set_process(false)  # Fixed synthetic viewport metrics, not desktop display metrics.
		touch_ui.set_layout(Rect2(0, 0, 1280, 720), Vector2.ONE)
	inventory_panel.bind(p, touch_ui)
	skill_panel.bind(p, touch_ui)
	shop_panel.bind(p, world, touch_ui)
	await frames(3)
	check(p.is_on_floor(), "precondition: actual floor contact")


func cleanup() -> void:
	if touch_ui != null:
		touch_ui.cancel_all()
		touch_ui.free()  # Owns reparented native panels.
		touch_ui = null
	else:
		inventory_panel.free()
		skill_panel.free()
		shop_panel.free()
	p.free()
	p = null


func stun() -> void:
	p.apply_status(&"stun", design["status-effects"].stun, 0.0, p)
	check(p.stunned(), "precondition: real stun applied")


func reject_state(mode: String) -> void:
	if mode == "stun":
		stun()
	else:
		p.dead = true  # Endpoint boundary fixture, not a second respawn test.
		p.hp = 0.0


func snapshot() -> Dictionary:
	return {
		"hp": p.hp,
		"coins": p.inventory.coins,
		"entries": p.inventory.entries.duplicate(),
		"counts": p.inventory.entries.map(func(it): return it.count),
		"spawn": p.spawn_point,
		"points": p.skill_tree.points.duplicate(),
		"bank": p.skill_points,
		"signals": signals.duplicate(),
		"shop": shop_panel._panel.visible,
		"supplier": world.state_data.sites[supplier_id].completed
	}


func ground(item) -> Node3D:
	var drop = GROUND.instantiate()
	root.add_child(drop)
	drop.position = p.position + Vector3(1, 0, 0)
	drop.setup(item, "test drop", Color.YELLOW, design.loot.ground)
	return drop


func run() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs.generators.design
	InputMapBuilder.build(o.configs.keybinds.hybrid)
	key_driver = KeyDriver.new()
	key_driver.process_physics_priority = -100
	root.add_child(key_driver)
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	collision.shape = box
	floor.add_child(collision)
	floor.position.y = -0.5
	root.add_child(floor)
	world = World.new()
	root.add_child(world)
	world.set_process(false)
	world.set_physics_process(false)
	world.configure(
		o,
		design,
		WorldState.new(design, int(design.terrain["seed-default"])),
		func(): return [p] if p != null else []
	)
	world.targeting.set_physics_process(false)
	await fixture()
	check(world.ensure_land(world.gen.land_at(Vector2i.ZERO)), "precondition: real supplier state")
	supplier_id = world.state_data.site_id(Vector2i.ZERO, "supplier", 0)
	world.state_data.sites[supplier_id].cleared = true
	cleanup()
	for native in [false, true]:
		await vertical(native)
	for mode in ["stun", "dead"]:
		await endpoints(mode)
		await selected_use(mode, false)
		await selected_use(mode, true)
		for role in [&"item-vendor", &"class-trainer", &"innkeeper", &"captive"]:
			for keyboard in [false, true]:
				await service(mode, role, keyboard)
	await native_requests()
	await live_effects()
	world.free()
	floor.free()
	print("stun input ok" if failed == 0 else "stun input FAILED (%d)" % failed)
	quit(0 if failed == 0 else 1)


func vertical(native: bool) -> void:
	var label := "native" if native else "desktop"
	await fixture(native)
	stun()
	if native:
		button("jump", true)
		check(touch_ui.held.get("jump", false), label + " jump hold delivered")
		await frames(3)
	else:
		await key_frame("jump")
	check(
		p.stunned() and p.position.y < 0.05 and p.velocity.y <= 0,
		label + " stunned grounded jump rejected"
	)
	if native:
		button("jump", false)
	# Expiry uses normal callbacks; rejected trigger must not replay.
	await create_timer(2.1).timeout
	await frames()
	check(not p.stunned() and p.is_on_floor(), label + " expiry without buffered jump")
	if native:
		button("jump", true)
	else:
		key_driver.edge = false
		key_driver.action = "jump"
	await frames(2 if not native else 1)
	if not native:
		check(key_driver.edge, label + " fresh jump edge")
	check(p.velocity.y > 13.0, label + " fresh grounded jump succeeds")
	stun()
	await frames()
	check(
		p.velocity.y > 0.0 and p.velocity.y <= sqrt(96.0) + 0.001,
		label + " stun interrupts held sustain, not gravity"
	)
	if native:
		button("jump", false)
	else:
		key("jump", false)
	p.position = Vector3(0, 2, 0)
	p.velocity = Vector3.ZERO
	p.water_top = 100
	if native:
		button("swim-ascent", true)
		check(touch_ui.held.get("swim-ascent", false), label + " ascent hold delivered")
	else:
		key("jump", true)
		check(Input.is_action_pressed("jump"), label + " ascent key held")
	await frames(3)
	check(p.stunned() and p.velocity.y < 0.0, label + " stunned ascent sinks")
	if native:
		button("swim-ascent", false)
	else:
		key("jump", false)
	await create_timer(2.1).timeout
	if native:
		button("swim-ascent", true)
	else:
		key("jump", true)
	await frames(3)
	check(
		not p.stunned() and is_equal_approx(p.velocity.y, 3.0), label + " fresh ascent after expiry"
	)
	if native:
		button("swim-ascent", false)
	else:
		key("jump", false)
	cleanup()


func endpoints(mode: String) -> void:
	await fixture()
	var drop = ground(Item.stack(&"consumable", &"life-potion", 2))
	check(p._nearest_in_group("ground-items", 2.0) == drop, "precondition: pickup target")
	reject_state(mode)
	var before := snapshot()
	check(not p.pick_up_nearest(), mode + " direct pickup returns false")
	check(
		snapshot() == before and not drop.is_queued_for_deletion(),
		mode + " direct pickup preserves state"
	)
	var it = p.inventory.first_consumable()
	before = snapshot()
	var result = p.call("use_item", it)
	check(result == false, mode + " selected Use returns false")
	check(snapshot() == before, mode + " direct Use preserves HP/counts/signals")
	before = snapshot()
	check(not p.use_quick(), mode + " Quick propagates false")
	check(snapshot() == before, mode + " Quick preserves HP/counts/signals")
	before = snapshot()
	await key_frame("quick-item")
	check(snapshot() == before, mode + " actual Q rejects")
	if is_instance_valid(drop):
		drop.free()
	drop = ground(Item.stack(&"consumable", &"life-potion", 2))
	check(p._nearest_in_group("ground-items", 2.0) == drop, "precondition: E pickup target")
	before = snapshot()
	await key_frame("interact")
	check(snapshot() == before, mode + " actual E pickup rejects")
	if is_instance_valid(drop):
		drop.free()
	cleanup()


func service(mode: String, role: StringName, keyboard: bool) -> void:
	await fixture()
	world.state_data.sites[supplier_id].completed = false
	var npc := NPC.new(role, str(role), Color.BLUE)
	npc.position = Vector3(1.5, 0, 0)
	if role == &"captive":
		npc.set_meta("encounter_site", supplier_id)
	root.add_child(npc)
	check(p._nearest_in_group("npcs", 3.0) == npc, "precondition: real service target " + role)
	reject_state(mode)
	var before := snapshot()
	if keyboard:
		await key_frame("interact")
	else:
		check(not p.talk_nearest(), mode + " direct Talk rejects " + role)
	check(snapshot() == before, mode + " service unchanged " + role + " keyboard=" + str(keyboard))
	p.dead = false
	p.statuses.clear()
	p.inventory.coins = 100
	p.skill_tree.points = {&"smash": 1}
	p.skill_points = 0
	p.hp = 50.0
	p.spawn_point = Vector3(9, 0, 9)
	world.state_data.sites[supplier_id].completed = false
	shop_panel._open(false)
	await key_frame("interact")
	match role:
		&"item-vendor":
			check(shop_panel._panel.visible and signals.talk > 0, "fresh E opens vendor")
		&"class-trainer":
			check(
				(
					p.inventory.coins == 95
					and p.skill_tree.points.is_empty()
					and p.skill_points == 1
					and signals.skills > 0
				),
				"fresh E respecs at trainer"
			)
		&"innkeeper":
			check(
				p.hp == p.max_hp and p.spawn_point != Vector3(9, 0, 9) and signals.notice > 0,
				"fresh E rests at inn"
			)
		&"captive":
			check(
				world.state_data.sites[supplier_id].completed and signals.talk > 0,
				"fresh E completes cleared rescue"
			)
	npc.free()
	cleanup()


func selected_use(mode: String, native: bool) -> void:
	await fixture(native)
	# Distinct supported stack: avoid selecting any Apple/F9 policy.
	var second = Item.stack(&"consumable", &"life-potion", 5, 2)
	p.inventory.add(second)
	var first = p.inventory.first_consumable()
	check(first != second, "precondition: distinct second stack")
	if native:
		touch_ui.open_panel("inventory")
	else:
		var event := InputEventAction.new()
		event.action = "inventory"
		event.pressed = true
		inventory_panel._unhandled_input(event)
	await process_frame
	await process_frame
	check(
		p.ui_open and inventory_panel._panel.visible, "precondition: selected Use in open inventory"
	)
	if native:
		select_native(second)
	reject_state(mode)
	var before := snapshot()
	await activate_selected(second, native)
	check(snapshot() == before, mode + " selected panel Use preserves state native=" + str(native))
	p.dead = false
	p.statuses.clear()
	p.hp = 1.0
	var first_count: int = first.count
	var second_count: int = second.count
	await activate_selected(second, native)
	check(
		(
			p.ui_open
			and p.hp > 1.0
			and second.count == second_count - 1
			and first.count == first_count
		),
		"unstunned open-panel Use selects second stack native=" + str(native)
	)
	check(
		p.use_quick() and first.count == first_count - 1 and second.count == second_count - 1,
		"Quick still uses first stack"
	)
	cleanup()


func activate_selected(it, native: bool) -> void:
	var row: int = inventory_panel._rows.find(it)
	check(row >= 0, "precondition: selected item row exists")
	if native:
		if not p.dead:
			select_native(it)
		var control: Button = inventory_panel.touch_buttons[1]
		check(not control.disabled, "native Use confirmation enabled")
		touch_at(control.get_global_rect().get_center(), true)
		touch_at(control.get_global_rect().get_center(), false)
	else:
		inventory_panel._list.item_activated.emit(row)
	await process_frame


func select_native(it) -> void:
	var row: int = inventory_panel._rows.find(it)
	var position: Vector2 = (
		inventory_panel._list.get_global_rect().position + Vector2(30, 24 + 48 * row)
	)
	touch_at(position, true)
	touch_at(position, false)
	check(
		inventory_panel._list.get_selected_items() == PackedInt32Array([row]),
		"native row selection delivered"
	)


func native_requests() -> void:
	await fixture(true)
	var npc := NPC.new(&"item-vendor", "Vendor", Color.BLUE)
	npc.position = Vector3(1.5, 0, 0)
	root.add_child(npc)
	var drop = ground(Item.stack(&"consumable", &"life-potion", 2))
	stun()
	var before := snapshot()
	for action in ["interact", "pick-up", "quick-item"]:
		tap(action)
	await frames(3)
	check(
		snapshot() == before and touch_ui.panel_id == "",
		"native stunned requests reject including vendor preemption"
	)
	await create_timer(2.1).timeout
	await frames()
	check(snapshot() == before, "rejected native requests never replay after expiry")
	tap("interact")
	await frames()
	check(touch_ui.panel_id == "shop", "fresh native Talk opens vendor")
	touch_ui.back()
	npc.free()
	tap("pick-up")
	await frames()
	check(not is_instance_valid(drop) and signals.pickup == 1, "fresh native pickup succeeds")
	var it = p.inventory.first_consumable()
	var count: int = it.count
	tap("quick-item")
	await frames()
	check(it.count == count - 1, "fresh native Quick succeeds")
	# Passive currency retains the ground Area's automatic route under stun.
	stun()
	var coins: int = p.inventory.coins
	ground(Item.stack(&"coin", &"", 7))
	await frames(4)
	check(
		p.stunned() and p.inventory.coins == coins + 7,
		"passive coin pickup remains live while stunned"
	)
	cleanup()


func live_effects() -> void:
	await fixture()
	p.set_physics_process(false)  # Exact timer arithmetic, no input claims in this case.
	p.skill_tree.points = {&"heroic-shout": 1, &"war-frenzy": 1}
	check(p.abilities.use(o.abilities[&"heroic-shout"]), "precondition: committed healing")
	check(p.use_class_skill(3), "precondition: committed buff")
	p.apply_status(&"poison", design["status-effects"].poison, 20.0, p)
	stun()
	var source := Node3D.new()
	root.add_child(source)
	source.position = Vector3(-5, 0, 0)
	p.apply_status(&"knockback", design["status-effects"].knockback, 0.0, source)
	var cooldown: float = p.abilities.cooldowns[&"war-frenzy"]
	var buff: float = p.abilities.buffs[&"war-frenzy"].left
	var hp: float = p.hp
	p._physics_process(0.5)
	check(
		p.stunned() and p.position.x > 0 and p.hp > hp,
		"stun preserves external push and committed HoT"
	)
	p._physics_process(0.5)
	check(
		is_equal_approx(p.hp, hp + p.max_hp * 0.0525 - 20.0), "DOT and HoT both advance during stun"
	)
	check(
		(
			is_equal_approx(p.abilities.cooldowns[&"war-frenzy"], cooldown - 1.0)
			and is_equal_approx(p.abilities.buffs[&"war-frenzy"].left, buff - 1.0)
		),
		"cooldown and buff clocks advance during stun"
	)
	source.free()
	cleanup()
