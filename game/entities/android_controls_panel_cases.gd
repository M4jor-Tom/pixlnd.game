## Real Android inventory/skills/shop scenarios; shared lifecycle stays on the owning SceneTree.
extends RefCounted
const Item := preload("res://game/items/item.gd")
const NPC := preload("res://game/entities/npc.gd")


static func run(t, rig) -> bool:
	return (
		await _panels(t, rig)
		and await _skills(t)
		and await _selected(t)
		and await _gear(t)
		and await _dpi(t)
		and await _equip(t)
	)


static func _panels(t, rig) -> bool:
	# All real native panels: selection/scroll do not commit, operations commit only on inside release.
	for id in ["inventory", "skills-window", "shop"]:
		if not await _panel_lifetime(t, rig, id):
			return false
	return true


static func _skills(t) -> bool:
	t.a.open_panel("skills-window")
	t.p.skill_points = 2
	t.skills._refresh()
	await t.process_frame
	await t.process_frame
	t.select_row(t.skills._list, 0)
	t.check(t.p.skill_points == 2, "selection alone never spends")
	t.click_control(t.skills.touch_buttons[0])
	t.check(t.p.skill_points == 1, "native Spend inside release once")
	var pos: Vector2 = t.skills.touch_buttons[0].get_global_rect().get_center()
	t.touch(30, pos, true)
	t.drag(30, Vector2.ZERO, -pos)
	t.drag(30, pos, pos)
	t.touch(30, pos, false)
	t.check(t.p.skill_points == 1, "confirmation slide out/back terminal cancel")
	for interruption in ["focus", "layout", "back"]:
		t.select_row(t.skills._list, 0)
		var bank_before: int = t.p.skill_points
		pos = t.skills.touch_buttons[0].get_global_rect().get_center()
		t.touch(30, pos, true)
		match interruption:
			"focus":
				t.a._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
			"layout":
				t.a.set_layout(t.a.safe, t.a.pixels_per_dp)
			"back":
				t.a.back()
		t.touch(30, pos, false)
		t.check(t.p.skill_points == bank_before, "native confirmation canceled by " + interruption)
		t.a.open_panel("skills-window")
		await t.process_frame
		await t.process_frame
	return true


static func _selected(t) -> bool:
	t.a.open_panel("inventory")
	await t.process_frame
	await t.process_frame
	var potion_row := -1
	for i in t.inv._rows.size():
		if t.inv._rows[i].type == &"consumable":
			potion_row = i
			break
	t.select_row(t.inv._list, potion_row)
	var selected = t.inv._rows[potion_row]
	var count: int = selected.count
	t.click_control(t.inv.touch_buttons[1])
	t.check(selected.count == count - 1, "native Use selected bag row")
	var apple = Item.stack(&"consumable", &"apple", 2)
	t.p.inventory.add(apple)
	await t.process_frame
	await t.process_frame
	var first_count: int = t.p.inventory.first_consumable().count
	t.p.hp = t.p.max_hp - 30.0
	var hp_before: float = t.p.hp
	t.select_row(t.inv._list, t.inv._rows.find(apple))
	t.click_control(t.inv.touch_buttons[1])
	t.check(is_equal_approx(t.p.hp, hp_before + 20.0), "native selected Apple Use heals 20 HP")
	t.check(
		apple.count == 1 and t.p.inventory.first_consumable().count == first_count,
		"Use selects second consumable, never Quick Item target"
	)
	return true


static func _gear(t) -> bool:
	# Populate every slot supported by existing equip routing, not an injected equipment dictionary.
	for definition in [
		[&"weapon", &"shield"],
		[&"chest-armor", &""],
		[&"gloves", &""],
		[&"boots", &""],
		[&"shoulder-armor", &""],
		[&"amulet", &""],
		[&"ring", &""]
	]:
		var worn := Item.new()
		worn.type = definition[0]
		worn.subtype = definition[1]
		worn.material = &"iron"
		worn.rarity = 4
		t.p.inventory.add(worn)
		t.check(t.p.inventory.equip(worn), "F3 real equip " + str(definition[0]))
	t.check(t.p.inventory.equipment.size() == 8, "F3 normally populated supported equipment")
	return true


static func _dpi(t) -> bool:
	# Layout under a high-DPI phone's logical viewport: every panel operation stays safe and >=48dp.
	for id in ["inventory", "skills-window", "shop"]:
		if not await _dpi_panel(t, id):
			return false
	t.a.open_panel("inventory")
	await t.process_frame
	await t.process_frame
	if not await _filled_bag(t):
		return false
	t.a.set_layout(Rect2(0, 0, 1280, 720), Vector2.ONE)
	t.a.open_panel("inventory")
	await t.process_frame
	await t.process_frame
	return true


static func _equip(t) -> bool:
	return await _equip_selected(t) and await _native_vendor(t)


static func batch_preemption(t) -> bool:
	t.p.abilities.reset()
	t.p.abilities.cooldowns.clear()
	t.p.stamina = 100
	t.p._swing_t = 0
	for order in [["basic-attack", "inventory"], ["inventory", "basic-attack"]]:
		for action in order:
			t.tap(action, 12)
		t.step()
		t.check(
			t.p.ui_open and t.p._swing_t <= 0, "panel preempts ALL queued gameplay " + str(order)
		)
		t.a.back()
	return true


static func vendor_preemption(t) -> bool:
	# A panel opened by actual vendor Talk also suppresses all pending combat.
	var vendor := NPC.new(&"item-vendor", "Item Vendor", Color.BLUE)
	vendor.position = t.p.position + Vector3(1, 0, 0)
	t.root.add_child(vendor)
	for order in [["basic-attack", "interact"], ["interact", "basic-attack"]]:
		t.p._swing_t = 0
		for action in order:
			t.tap(action)
		t.step()
		t.check(
			t.a.panel_id == "shop" and t.p._swing_t <= 0,
			"vendor panel preempts pending attacks " + str(order)
		)
		t.a.back()
	vendor.free()
	return true


static func _panel_lifetime(t, rig, id: String) -> bool:
	t.a.open_panel(id)
	await t.process_frame
	await t.process_frame
	t.check(t.p.ui_open and not t.a._gameplay.visible, id + " exclusive touch ownership")
	return _panel_time(t, id) and _panel_input(t, rig, id)


static func _panel_time(t, id: String) -> bool:
	var hp: float = t.p.hp
	t.p.apply_status(&"poison", t.design["status-effects"].poison, 10, t.p)
	t.step(.1)
	t.check(is_equal_approx(t.p.hp, hp), id + " DOT never ticks early")
	t.step(.9)
	t.check(is_equal_approx(t.p.hp, hp - 10), id + " DOT stays live at one second")
	t.p.statuses.clear()
	t.p.abilities.cooldowns[&"smash"] = 1
	t.p._swing_t = .3
	t.p._combo_t = .3
	t.p.combo = 2
	t.step(.5)
	t.check(
		(
			is_equal_approx(t.p.abilities.cooldowns[&"smash"], .5)
			and t.p.combo == 0
			and t.p._swing_t <= 0
		),
		id + " timers advance once"
	)
	return true


static func _panel_input(t, rig, id: String) -> bool:
	var before_yaw: float = rig.rotation.y
	t.tap("basic-attack")
	t.step()
	t.check(
		t.p._swing_t <= 0 and is_equal_approx(rig.rotation.y, before_yaw),
		id + " no gameplay leakage"
	)
	t.a.back()
	t.check(not t.p.ui_open, id + " Back closes")
	return true


static func _dpi_panel(t, id: String) -> bool:
	t.a.set_layout(Rect2(0, 0, 1280, 720), Vector2(2, 2))
	t.a.open_panel(id)
	await t.process_frame
	await t.process_frame
	var panel = t.a.panels[id]
	t.check(
		t.a.safe.encloses(panel._panel.get_global_rect()),
		id + " high-DPI panel remains in safe area"
	)
	for button in panel.touch_buttons:
		var rect: Rect2 = button.get_global_rect()
		t.check(
			t.a.safe.encloses(rect) and rect.size.x >= 96 and rect.size.y >= 96,
			id + " high-DPI confirmation safe >=48dp"
		)
	return true


static func _filled_bag(t) -> bool:
	var bag_rect: Rect2 = t.inv._list.get_global_rect()
	var bag_row: Rect2 = t.inv._list.get_item_rect(0)
	if not _bag_geometry(t, bag_rect, bag_row):
		return false
	var potion_before: int = t.p.inventory.first_consumable().count
	var pos: Vector2 = bag_rect.position + bag_row.get_center()
	t.touch(36, pos, true)
	t.touch(36, pos, false)
	t.click_control(t.inv.touch_buttons[1], 37)
	t.check(
		t.p.inventory.first_consumable().count == potion_before - 1,
		"F3 filled high-DPI bag selection and Use are reachable"
	)
	await t.process_frame
	await t.process_frame
	var worn_list: ItemList = t.inv._touch_worn
	return (
		_worn_info(t, worn_list)
		and _worn_scroll(t, worn_list, potion_before)
		and _navigation_size(t)
	)


static func _bag_geometry(t, bag_rect: Rect2, bag_row: Rect2) -> bool:
	t.check(
		(
			bag_rect.size.y >= 96
			and t.a.safe.encloses(bag_rect)
			and bag_row.size.y >= 96
			and bag_row.end.y <= bag_rect.size.y
		),
		"F3 filled inventory has a safe accessible >=48dp bag row"
	)
	return true


static func _worn_info(t, worn_list: ItemList) -> bool:
	t.check(
		(
			worn_list.item_count == t.p.inventory.equipment.size() + 1
			and t.a.safe.encloses(worn_list.get_global_rect())
		),
		"F3 all worn information retained in safe native scroller"
	)
	for slot in t.p.inventory.equipment:
		var line := "%s: %s" % [slot, t.p.item_label(t.p.inventory.equipment[slot])]
		t.check(
			range(worn_list.item_count).any(func(i): return worn_list.get_item_text(i) == line),
			"F3 full worn line retained " + str(slot)
		)
	return true


static func _worn_scroll(t, worn_list: ItemList, potion_before: int) -> bool:
	var pos: Vector2 = worn_list.get_global_rect().get_center()
	t.touch(38, pos, true)
	t.drag(38, pos - Vector2(0, 2000), Vector2(0, -2000))
	t.touch(38, pos - Vector2(0, 2000), false)
	var scroll: VScrollBar = worn_list.get_v_scroll_bar()
	t.check(
		(
			scroll.value > 0
			and is_equal_approx(scroll.value, scroll.max_value - scroll.page)
			and t.p.inventory.first_consumable().count == potion_before - 1
		),
		"F3 owned worn scroll reaches last equipment without committing"
	)
	return true


static func _navigation_size(t) -> bool:
	for button in t.a._navigation.get_children():
		var rect: Rect2 = button.get_global_rect()
		t.check(
			t.a.safe.encloses(rect) and rect.size.x >= 96 and rect.size.y >= 96,
			"F3 filled inventory navigation safe >=48dp"
		)
	return true


static func _equip_selected(t) -> bool:
	# Equip uses the selected row; Buy and Sell go through real native confirmation.
	var gear := Item.new()
	gear.type = &"weapon"
	gear.subtype = &"sword"
	gear.material = &"iron"
	t.p.inventory.add(gear)
	await t.process_frame
	await t.process_frame
	t.select_row(t.inv._list, t.inv._rows.find(gear))
	t.click_control(t.inv.touch_buttons[0])
	t.check(t.p.inventory.equipment.values().has(gear), "native Equip selected row")
	var wrong := Item.new()
	wrong.type = &"chest-armor"
	wrong.material = &"silk"
	var wrong_weapon := Item.new()
	wrong_weapon.type = &"weapon"
	wrong_weapon.subtype = &"wand"
	wrong_weapon.material = &"wood"
	t.p.inventory.add(wrong)
	t.p.inventory.add(wrong_weapon)
	await t.process_frame
	await t.process_frame
	var wrong_row: int = t.inv._rows.find(wrong)
	var weapon_row: int = t.inv._rows.find(wrong_weapon)
	if not _wrong_rows(t, wrong_row, weapon_row):
		return false
	t.select_row(t.inv._list, wrong_row)
	t.click_control(t.inv.touch_buttons[0])
	t.select_row(t.inv._list, weapon_row)
	t.click_control(t.inv.touch_buttons[0])
	return _rejected_class(t, wrong, wrong_weapon)


static func _wrong_rows(t, wrong_row: int, weapon_row: int) -> bool:
	t.check(
		wrong_row >= 0 and t.inv._list.get_item_custom_fg_color(wrong_row) == Color.RED,
		"touch inventory marks wrong-class armor red"
	)
	t.check(
		weapon_row >= 0 and t.inv._list.get_item_custom_fg_color(weapon_row) == Color.RED,
		"touch inventory marks wrong-class weapon red"
	)
	return true


static func _native_vendor(t) -> bool:
	t.a.back()
	var vendor := NPC.new(&"item-vendor", "Item Vendor", Color.BLUE)
	vendor.position = t.p.position
	t.root.add_child(vendor)
	t.tap("interact")
	t.step()
	await t.process_frame
	await t.process_frame
	t.check(
		t.a.panel_id == "shop" and t.shop._stock_rows.size() > 0,
		"actual Talk opens generated vendor shop"
	)
	t.p.inventory.coins = 1000
	t.shop._refresh()
	await t.process_frame
	await t.process_frame
	var coins: int = t.p.inventory.coins
	t.select_row(t.shop._stock, 0)
	t.check(t.p.inventory.coins == coins, "stock selection does not buy")
	t.click_control(t.shop.touch_buttons[0])
	t.check(t.p.inventory.coins < coins, "native Buy selected stock")
	await t.process_frame
	await t.process_frame
	coins = t.p.inventory.coins
	t.select_row(t.shop._bag, 1)
	t.click_control(t.shop.touch_buttons[1])
	t.check(t.p.inventory.coins > coins, "native Sell selected bag entry")
	# Long native lists scroll under an owned drag without committing any operation.
	for i in 30:
		var extra := Item.new()
		extra.type = &"weapon"
		extra.subtype = &"sword"
		extra.material = &"iron"
		t.p.inventory.add(extra)
	t.a.open_panel("inventory")
	await t.process_frame
	await t.process_frame
	var coins_before: int = t.p.inventory.coins
	var list_pos: Vector2 = t.inv._list.get_global_rect().get_center()
	t.touch(35, list_pos, true)
	t.drag(35, list_pos - Vector2(0, 100), Vector2(0, -100))
	t.touch(35, list_pos - Vector2(0, 100), false)
	t.check(
		t.inv._list.get_v_scroll_bar().value > 0 and t.p.inventory.coins == coins_before,
		"owned native list scrolling never commits"
	)
	t.a.back()
	vendor.free()
	return true


static func _rejected_class(t, wrong, wrong_weapon) -> bool:
	t.check(
		(
			wrong in t.p.inventory.entries
			and wrong_weapon in t.p.inventory.entries
			and not t.p.inventory.equipment.values().has(wrong)
		),
		"native Equip rejects wrong-class gear without removal"
	)
	return true
