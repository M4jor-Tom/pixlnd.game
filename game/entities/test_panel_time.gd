## Item 10: real panels must block gameplay input, not DOT, cooldowns, buffs or dodge expiry.
## Run: godot --headless -s game/entities/test_panel_time.gd
extends SceneTree

const Model := preload("res://ontology/model.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const InventoryPanel := preload("res://game/items/inventory_panel.gd")
const SkillPanel := preload("res://game/progression/skill_panel.gd")
const ShopPanel := preload("res://game/items/shop_panel.gd")
const NPC := preload("res://game/entities/npc.gd")
const Item := preload("res://game/items/item.gd")

var _failed := 0
var o
var design: Dictionary

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _init() -> void:
	_run.call_deferred()

func _toggle(panel: CanvasLayer, action: String) -> void:
	if action == "shop":
		panel._open(not panel._panel.visible)
	else:
		var event := InputEventAction.new()
		event.action = action; event.pressed = true
		panel._unhandled_input(event)

func _run() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs["generators"]["design"]
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)
	var trainer := NPC.new(&"class-trainer", "Trainer", Color.BLUE)
	trainer.position = Vector3(2, 0, 0); root.add_child(trainer)
	for action in ["inventory", "skills-window", "shop"]:
		var p: CharacterBody3D = PLAYER.instantiate(); root.add_child(p)
		p.setup(design["movement"], design["camera"], &"normal")
		p.setup_combat(design["combat"], design["crit"], {}, 260.0)
		p.setup_items(o, design)
		p.set_physics_process(false)                       # deterministic dt through the real physics entry point
		p.skill_tree.points = {&"smash": 5, &"cyclone": 1, &"war-frenzy": 1}
		var panel: CanvasLayer
		match action:
			"inventory": panel = InventoryPanel.new()
			"skills-window": panel = SkillPanel.new()
			"shop": panel = ShopPanel.new()
		root.add_child(panel)
		if action == "shop":
			panel.bind(p, null)
			panel.set_process(false)                      # drive its open/close hook, not the E/escape shortcut
		else:
			panel.bind(p)
		await physics_frame
		p._physics_process(0.01)
		check(p.use_class_skill(3), action + ": start a real buff before browsing")
		p.abilities.buffs[&"war-frenzy"]["left"] = 0.3
		p.abilities.cooldowns[&"war-frenzy"] = 1.0
		p._swing_t = 0.3; p.combo = 3; p._combo_t = 0.3
		check(p.dodge(Vector3.RIGHT), action + ": start a real dodge before browsing")
		p.apply_status(&"poison", design["status-effects"]["poison"], 10.0, p)
		_toggle(panel, action)
		check(p.ui_open and panel._panel.visible, action + ": actual panel opens")
		p._physics_process(0.1)
		check(is_equal_approx(p.hp, 250.0), action + ": poison ticks while browsing during dodge")
		p.take_damage(7.0, p)
		check(is_equal_approx(p.hp, 250.0), action + ": unexpired dodge still protects ordinary hits")
		for i in 4:
			p._physics_process(0.1)
		check(is_equal_approx(p.abilities.cooldowns[&"war-frenzy"], 0.5), action + ": cooldown ticks exactly once per step")
		check(not p.abilities.buffs.has(&"war-frenzy"), action + ": buff expires")
		check(p._iframes <= 0.0 and p._dodge.is_empty(), action + ": dodge protection and roll expire")
		check(p._swing_t <= 0.0 and p.combo == 0, action + ": swing cooldown and normal combo inactivity expire")
		p.take_damage(7.0, p)
		check(is_equal_approx(p.hp, 243.0), action + ": ordinary hit hurts after dodge expiry")
		for i in 7:
			p._physics_process(0.1)
		check(is_equal_approx(p.hp, 233.0), action + ": poison repeats at its normal cadence")
		check(p._dodge_cd <= 0.0, action + ": dodge cooldown expires")
		p.statuses.clear()
		# All gameplay keys remain unavailable while browsing, even with a shield and learned skills.
		var shield := Item.new(); shield.type = &"weapon"; shield.subtype = &"shield"; shield.material = &"iron"
		p.inventory.add(shield); p.inventory.equip(shield)
		p.stamina = 100.0; p.mp = 100.0
		var at := p.position
		var potions: int = p.inventory.first_consumable().count
		var coins: int = p.inventory.coins
		var actions := ["move_right", "sprint", "jump", "dodge", "basic-attack", "special-attack", "class-skill-1", "class-skill-3", "interact", "quick-item"]
		for key in actions:
			Input.action_press(key)
		await physics_frame
		p._physics_process(0.1)
		check(is_equal_approx(p.position.x, at.x) and is_equal_approx(p.position.z, at.z) and p.velocity.y <= 0.0, action + ": no walking, sprinting or jumping")
		check(p._dodge.is_empty() and not p.blocking and p._charge < 0.0, action + ": no dodge, held block or M2 charge")
		check(p._swing_t <= 0.0 and not p.abilities.busy() and not p.abilities.buffs.has(&"war-frenzy"), action + ": no basic or class attacks")
		check(p.inventory.first_consumable().count == potions and is_equal_approx(p.hp, 233.0), action + ": no quick-use potion")
		check(p.inventory.coins == coins and p.skill_tree.spent(&"smash") == 5, action + ": no trainer interaction")
		# Swimming must not consume the jump key either.
		p.water_top = 100.0; p.position.y = 2.0       # off the floor so collision does not zero the sink velocity
		p._physics_process(0.1)
		check(p.velocity.y < 0.0, action + ": no swim-up input")
		p.water_top = -INF
		for key in actions:
			Input.action_release(key)
		_toggle(panel, action)
		check(not p.ui_open and not panel._panel.visible, action + ": actual panel closes")
		Input.action_press("move_right")
		await physics_frame
		p._physics_process(0.1)
		check(p.position.x > at.x, action + ": movement works again after closing")
		Input.action_release("move_right")
		panel.free(); p.free()
	# A lethal tick must stop this frame, not let a queued heal resurrect a dead player.
	var p: CharacterBody3D = PLAYER.instantiate(); root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, 260.0); p.setup_items(o, design)
	p.set_physics_process(false); p.ui_open = true; p.hp = 1.0
	p.abilities.heals.append({"left": 1.0, "per-s": 100.0})
	p.apply_status(&"poison", design["status-effects"]["poison"], 10.0, p)
	p._physics_process(0.1)
	check(p.dead and is_zero_approx(p.hp) and p.velocity == Vector3.ZERO, "lethal poison stops the browsing player's frame")
	# Let the existing respawn coroutine finish before freeing the player.
	await create_timer(float(design["combat"]["death"]["respawn-s"]) + 0.1).timeout
	p.free()
	print("panel time ok" if _failed == 0 else "panel time FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
