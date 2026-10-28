## Apple healing through real selected, Quick, inventory and Android Use paths.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const InventoryPanel := preload("res://game/items/inventory_panel.gd")
const Touch := preload("res://game/meta/android_touch.gd")
var failed := 0
var checks := 0
var o
var p
var desktop
var panel
var touch_ui


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	run.call_deferred()


func reset_bag(quick: bool):
	p.dead = false
	p.statuses.clear()
	p.hp = 10.0
	p.inventory.entries.clear()
	var apple = Item.stack(&"consumable", &"apple", 2)
	var potion = Item.stack(&"consumable", &"life-potion", 5)
	p.inventory.add(apple if quick else potion)
	p.inventory.add(potion if quick else apple)
	return [apple, potion]


func activate(route: String, apple) -> void:
	match route:
		"selected":
			check(p.use_item(apple), "selected Use returns true")
		"quick":
			check(p.inventory.first_consumable() == apple, "Quick precondition: Apple is first")
			check(p.use_quick(), "Quick returns true")
		"inventory":
			var row: int = desktop._rows.find(apple)
			check(row == 1, "desktop precondition: Apple is second")
			desktop._list.item_activated.emit(row)
		"android":
			touch_ui.open_panel("inventory")
			var row: int = panel._rows.find(apple)
			check(row == 1 and p.ui_open, "Android precondition: open inventory, second Apple")
			panel._list.select(row)
			panel._list.item_selected.emit(row)
			check(not panel.touch_buttons[1].disabled, "Android Use enabled for selected Apple")
			touch_ui.confirming = true
			panel.touch_buttons[1].pressed.emit()
			touch_ui.confirming = false


func run() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "shipped ontology validates")
	var design: Dictionary = o.configs.generators.design
	p = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design.movement, design.camera, &"normal")
	p.setup_combat(design.combat, design.crit, {}, 260.0)
	p.setup_items(o, design)
	p.set_physics_process(false)
	desktop = InventoryPanel.new()
	root.add_child(desktop)
	desktop.bind(p)
	panel = InventoryPanel.new()
	root.add_child(panel)
	touch_ui = Touch.new()
	root.add_child(touch_ui)
	touch_ui.setup(o.configs["controller-profiles"].android, p, panel, null, null)
	panel.bind(p, touch_ui)
	touch_ui.set_layout(Rect2(0, 0, 1280, 720), Vector2.ONE)
	var apple = Item.stack(&"consumable", &"apple", 2)
	var potion = Item.stack(&"consumable", &"life-potion", 5)
	print(
		"APPLE raw_has_heal_mult=",
		o.configs.consumables.apple.has("heal-mult"),
		" loaded=",
		o.consumables.apple.heal_mult,
		" nominal=",
		Items.heal(apple, o),
		" potion_nominal=",
		Items.heal(potion, o)
	)
	check(is_equal_approx(Items.heal(apple, o), 20.0), "common power1 Apple nominal expected 20 HP")
	check(is_equal_approx(Items.heal(potion, o), 200.0), "Life Potion nominal remains 200 HP")
	for route in ["selected", "quick", "inventory", "android"]:
		var bag: Array = reset_bag(route == "quick")
		activate(route, bag[0])
		print(
			"EFFECT route=", route, " hp=", p.hp, " apple=", bag[0].count, " potion=", bag[1].count
		)
		check(is_equal_approx(p.hp, 30.0), route + " Apple increases HP by 20 (10 -> 30)")
		check(
			bag[0].count == 1 and p.inventory.entries.has(bag[0]),
			route + " consumes exactly one selected Apple"
		)
		check(
			bag[1].count == 5 and p.inventory.entries.has(bag[1]),
			route + " preserves unrelated Potion stack"
		)
		bag = reset_bag(route == "quick")
		p.hp = p.max_hp - 7.0
		activate(route, bag[0])
		check(is_equal_approx(p.hp, p.max_hp), route + " healing caps at missing 7 HP")
		check(bag[0].count == 1 and bag[1].count == 5, route + " cap consumes one Apple only")
		for gate in ["dead", "stunned"]:
			bag = reset_bag(route == "quick")
			if gate == "dead":
				p.dead = true
				p.hp = 0.0
			else:
				p.apply_status(&"stun", design["status-effects"]["stun"], 0.0, p)
			var hp_before: float = p.hp
			match route:
				"selected":
					check(not p.use_item(bag[0]), gate + " selected returns false")
				"quick":
					check(not p.use_quick(), gate + " Quick returns false")
				_:
					activate(route, bag[0])
			check(
				p.hp == hp_before and bag[0].count == 2 and bag[1].count == 5,
				route + " " + gate + " preserves HP and both stacks"
			)
	var cap_control: Array = reset_bag(false)
	p.hp = p.max_hp - 7.0
	check(
		p.use_item(cap_control[1]) and is_equal_approx(p.hp, p.max_hp),
		"Potion control confirms existing missing-HP cap"
	)
	check(
		cap_control[1].count == 4 and cap_control[0].count == 2,
		"Potion cap control spends selected Potion only"
	)
	# Independent literals: power21 gives exponent 1.5; rare adds exponent .5.
	for sample in [[21, 0, 56.5685424949238], [1, 2, 28.2842712474619], [21, 2, 80.0]]:
		apple.level = sample[0]
		apple.rarity = sample[1]
		potion.level = sample[0]
		potion.rarity = sample[1]
		check(
			is_equal_approx(Items.heal(apple, o), sample[2]), "Apple curve literal " + str(sample)
		)
		check(
			is_equal_approx(Items.heal(apple, o) * 10.0, Items.heal(potion, o)),
			"Apple is one tenth equal-power/rarity Potion " + str(sample)
		)
		var bag: Array = reset_bag(false)
		bag[0].level = sample[0]
		bag[0].rarity = sample[1]
		check(
			p.use_item(bag[0]) and is_equal_approx(p.hp, 10.0 + sample[2]),
			"selected Apple curve heals literal " + str(sample)
		)
		check(
			bag[0].count == 1 and bag[1].count == 5,
			"higher curve consumes Apple only " + str(sample)
		)
	print("Apple healing: checks=", checks, " failures=", failed)
	touch_ui.free()
	desktop.free()
	p.free()
	quit(0 if failed == 0 else 1)
