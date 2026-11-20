## Refactor seam checks: ordered scans, live admission callbacks and exact RNG consumption.
extends RefCounted
const Domain := preload("res://game/domain/domain.gd")
const CreatureRow := preload("res://game/generated/domain/link_ml_creature_source_row.gd")
const AbilityRow := preload("res://game/generated/domain/link_ml_ability_source_row.gd")
const TreePosition := preload("res://game/generated/domain/link_ml_ability_tree_position.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Inventory := preload("res://game/items/inventory.gd")
const Rewards := preload("res://game/items/encounter_rewards.gd")
const SkillTree := preload("res://game/progression/skill_tree.gd")
const Bindings := preload("res://game/meta/input_map.gd")


static func run(test, o, design: Dictionary) -> void:
	_stacks(test, o, design)
	_live_admission(test, o, design)
	_slot_scans(test, o)
	_loot_draws(test, o, design)
	_selection(test, o, design)
	_input_tokens(test)


static func _stacks(test, o, design: Dictionary) -> void:
	var inv := Inventory.new(o, design, &"warrior", func(): return 1)
	var first = Item.stack(&"consumable", &"apple", 2)
	var second = Item.stack(&"consumable", &"apple", 7)
	inv.entries = [first, second]
	var changes := [0]
	inv.changed.connect(func(): changes[0] += 1)
	inv.add(Item.stack(&"consumable", &"apple", 3))
	test.check(first.count == 5 and second.count == 7, "stack merges into first match only")
	test.check(changes[0] == 1, "stack merge notifies exactly once")
	var other = Item.stack(&"consumable", &"apple", 1, 2)
	inv.add(other)
	test.check(
		inv.entries == [first, second, other], "different power retains stack identity/order"
	)
	test.check(changes[0] == 2, "stack append notifies exactly once")


static func _live_admission(test, o, design: Dictionary) -> void:
	var inv
	var calls := [0]
	var candidate := Items.generate(RandomNumberGenerator.new(), &"weapon", &"sword", &"iron", 1, 0)
	inv = Inventory.new(
		o,
		design,
		&"warrior",
		func():
			calls[0] += 1
			candidate.level = 2
			return 1
	)
	inv.add(candidate)
	var changes := [0]
	inv.changed.connect(func(): changes[0] += 1)
	# The item level is read BEFORE calling the provider; do not cache the whole admission earlier.
	test.check(inv.equip(candidate), "level comparison retains left operand before provider")
	test.check(calls[0] == 1 and changes[0] == 1, "live provider and equip signal run once")
	test.check(inv.equipment[&"main-hand"] == candidate, "provider mutation retains item identity")


static func _slot_scans(test, o) -> void:
	var slots: Array = o.configs["equipment-slots"]["slots"]
	var original := slots.duplicate(true)
	var chest := Item.new()
	chest.type = &"chest-armor"
	chest.material = &"iron"
	slots.assign(
		[
			{"id": "chest", "accepts": ["chest-armor"], "hp-mult": 1.0},
			{"id": "boots", "accepts": ["chest-armor"], "hp-mult": 0.5},
			{"id": "chest", "accepts": [], "hp-mult": 2.0}
		]
	)
	test.check(Items.slot_id(chest, o) == &"chest", "slot routing keeps first accepted row")
	test.check(Items.hp(chest, o) == 15.0, "HP keeps first matching multiplier")
	test.check(Items.armor(chest, o) == 2.0, "defence keeps last matching multiplier")
	slots[2]["hp-mult"] = -1.0
	test.check(Items.armor(chest, o) == 0.0, "invalid later defence multiplier rejects")
	slots.assign(original)


static func _loot_draws(test, o, design: Dictionary) -> void:
	var d := design.duplicate(true)
	d.loot.coins.chance = 0.0
	d.loot["gear-chance"] = 0.0
	d.loot["consumable-chance"] = 0.0
	d.loot["species-drop-chance"] = 0.0
	var creature := CreatureRow.new()
	creature.slot_drops = ["not-an-ingredient", "wood-cube", "not-an-ingredient", "parrot-feather"]
	var rng := RandomNumberGenerator.new()
	var control := RandomNumberGenerator.new()
	for species in [null, creature]:
		rng.seed = 123
		control.seed = 123
		test.check(Items.roll_loot(rng, 10, species, o, d).is_empty(), "zero chances yield no loot")
		control.randf()
		control.randi_range(-1, 1)  # spread is unconditional, even without gear/consumables
		control.randf()
		control.randf()
		if species != null:
			control.randf()  # only the two known ingredients consume draws
			control.randf()
		test.check(rng.state == control.state, "loot spread/species draw order and count")


static func _selection(test, o, design: Dictionary) -> void:
	var volumes := [[0, 0, 0, 1, 1, 1]]
	var party := [
		{"class_id": "ranger", "position": [1, 1, 1]},
		{"class_id": "mage", "position": [0, 0, 0], "dead": true},
		{"class_id": "ranger", "position": [0, 0, 0]},
		{"class_id": "rogue", "position": [2, 0, 0]}
	]
	test.check(
		Rewards.completion_classes(party, volumes, {"class_id": "warrior"}) == ["mage", "ranger"],
		"completion sorts distinct inside classes, no finisher addition"
	)
	test.check(
		Rewards.completion_classes([], volumes, {"class_id": "rogue"}) == ["rogue"],
		"completion uses outside finisher only when empty"
	)
	var tree := SkillTree.new(o, design["skill-point"], &"warrior", &"berserker")
	var duplicate := AbilityRow.new()
	duplicate.slot_alpha_tree = TreePosition.new()
	duplicate.slot_alpha_tree.slot_column = "class"
	duplicate.slot_alpha_tree.slot_rank = 1
	tree.nodes.push_front(duplicate)
	test.check(tree.class_slot(1) == duplicate, "class slot retains first duplicate")
	test.check(
		tree.prerequisite(o.abilities[&"cyclone"]) == duplicate,
		"prerequisite retains first duplicate"
	)
	duplicate.slot_alpha_tree.slot_rank = 0
	test.check(tree.class_slot(0) == duplicate, "class slot retains original index <=3 rule")


static func _input_tokens(test) -> void:
	Bindings.build(
		{
			"_skip": "not a key",
			"probe-move": "WASD",
			"probe-zoom": "wheel",
			"probe-mouse": "M3",
			"probe-key": "F8"
		}
	)
	test.check(
		not InputMap.has_action("_skip") and not InputMap.has_action("probe-move"),
		"metadata skip and WASD aliases"
	)
	test.check(
		InputMap.action_get_events("move_forward")[0].physical_keycode == KEY_W, "WASD physical key"
	)
	test.check(
		InputMap.action_get_events("probe-zoom_in")[0].button_index == MOUSE_BUTTON_WHEEL_UP,
		"wheel in alias"
	)
	test.check(
		InputMap.action_get_events("probe-zoom_out")[0].button_index == MOUSE_BUTTON_WHEEL_DOWN,
		"wheel out alias"
	)
	test.check(
		InputMap.action_get_events("probe-mouse")[0].button_index == MOUSE_BUTTON_MIDDLE,
		"mouse token"
	)
	test.check(
		InputMap.action_get_events("probe-key")[0].physical_keycode == KEY_F8,
		"named physical key token"
	)
	for action in ["probe-zoom_in", "probe-zoom_out", "probe-mouse", "probe-key"]:
		InputMap.erase_action(action)
