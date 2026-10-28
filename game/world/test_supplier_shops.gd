extends SceneTree
const MAIN := preload("res://game/main.tscn")
const DB := preload("res://game/ontology_db.gd")
const Save := preload("res://game/world/save_data.gd")
const Shop := preload("res://game/items/shop.gd")
const Rewards := preload("res://game/items/encounter_rewards.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func stop(main) -> void:
	main.set_physics_process(false)
	var w = main.get_node("World")
	w.set_process(false)
	w.set_physics_process(false)
	w.targeting.set_physics_process(false)
	main.get_node("Player").set_physics_process(false)
	for mob in w.targeting.live.values():
		mob.set_physics_process(false)
	for view in w.site_views.values():
		view.get_node("Contents").set_physics_process(false)


func visit(main, id: String) -> void:
	var w = main.get_node("World")
	var layout: Dictionary = w.site_layout(id)
	main.relocate_player([layout.centre[0], layout.floor, layout.centre[1]])
	w.stream_sites()
	stop(main)


func clear(main, id: String, finisher) -> void:
	var w = main.get_node("World")
	for assignment in w.site_layout(id).assignments:
		w.targeting.live[id + "/" + assignment.key].take_damage(1e9, finisher)


func reject(save, data: Dictionary, label: String) -> void:
	check(not save.validate(data), "save rejects " + label)


func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		printerr("PIXLND_TEST_DIR required")
		quit(1)
		return
	if not root.has_node("OntologyDB"):
		var db := DB.new()
		db.name = "OntologyDB"
		root.add_child(db)
	var path := directory.path_join("suppliers.json")
	DirAccess.remove_absolute(path)
	var main = MAIN.instantiate()
	main.save_path = path
	root.add_child(main)
	stop(main)
	var w = main.get_node("World")
	var p = main.get_node("Player")
	var state = w.state_data
	var roles := [&"weapon-vendor", &"armor-vendor"]
	var land = w.gen.land_at(Vector2i.ZERO)
	var panel
	for child in main.get_children():
		if child.get_script() == preload("res://game/items/shop_panel.gd"):
			panel = child
	# Real service NPC -> talked -> panel -> saved world transaction, not panel-local removal.
	w._stream_village()
	var vendor
	for npc in get_nodes_in_group("npcs"):
		if npc.role == &"weapon-vendor":
			vendor = npc
			break
	check(vendor != null and panel != null, "actual main village vendor and shop panel")
	p.set_logical_position(main.frame.to_logical(vendor.global_position))
	p.interact_nearest()
	check(
		panel._panel.visible and panel._stock_rows.size() == 8,
		"actual interaction opens saved stock"
	)
	p.inventory.coins = 100000
	var expected = panel._stock_rows[0]
	var price := Shop.buy_price(expected, p.o, p.design)
	panel._on_buy(0)
	check(
		p.inventory.coins == 100000 - price and panel._stock_rows.size() == 7,
		"actual shop buy uses original price/removes saved gear"
	)
	check(
		not w.buy_vendor(&"weapon-vendor", 0, p, Vector2i.ZERO, expected),
		"stale row cannot buy replacement at same index"
	)
	panel._open(false)
	p.talked.emit(vendor)
	check(panel._stock_rows.size() == 7, "reopen does not reroll purchased gear")
	panel._open(false)
	for role in roles:
		var stock: Array = w.vendor_stock(role, 1, Vector2i.ZERO)
		check(
			(
				stock.size() == (7 if role == &"weapon-vendor" else 8)
				and stock.all(func(it): return it.rarity == 0)
			),
			"initial common ceiling/quantity"
		)
	p.inventory.coins = 0
	var before: Dictionary = state.vendors.duplicate(true)
	check(not w.buy_vendor(&"armor-vendor", 0, p, Vector2i.ZERO), "unaffordable purchase rejected")
	check(state.vendors == before, "failed purchase leaves authoritative stock unchanged")
	p.inventory.coins = 100000
	var consumables: Array = w.vendor_stock(&"item-vendor", p.level, Vector2i.ZERO)
	for repeat_ in 3:
		check(w.buy_vendor(&"item-vendor", 0, p, Vector2i.ZERO), "unlimited consumable buy")
	check(
		w.vendor_stock(&"item-vendor", p.level, Vector2i.ZERO).size() == consumables.size(),
		"consumables never deplete"
	)
	for ordinal in 4:
		var id: String = state.site_id(Vector2i.ZERO, "supplier", ordinal)
		visit(main, id)
		var site: Dictionary = state.sites[id]
		var layout: Dictionary = w.site_layout(id)
		var captive
		for npc in w.site_views[id].get_children():
			if npc.get("role") == &"captive":
				captive = npc
				break
		w.on_talked(captive)
		check(not site.completed, "talk before clear rejected")
		var prior_stock: Dictionary = state.vendors.duplicate(true)
		var extra := {
			"logical_id": "awaiting",
			"class_id": "mage",
			"level": 1,
			"dead": true,
			"position": [layout.centre[0], layout.floor, layout.centre[1]]
		}
		w.party_provider = func(): return [p, extra]
		clear(main, id, p)
		check(
			site.cleared and not site.completed,
			"final designated death clears but waits for rescue"
		)
		var record: Dictionary = site.rewards["mission/%d" % site.cycle]
		check(
			(
				record.classes == ["mage", "warrior"]
				and not record.delivered
				and record.payload.size() == 4
			),
			"final-death snapshot includes awaiting distinct class before talk"
		)
		var chosen: String = record.class_id
		extra.class_id = "ranger"  # later conversation must not resnapshot
		var xp_before: int = p.xp
		var level_before: int = p.level
		if ordinal % 2 == 0:
			p.set_logical_position(layout.captive)
			check(p.interact_nearest(), "actual captive conversation")
		else:
			site.pending = true
			var outside := [0, 0, 0]
			state.advance(0, [extra.position])
			check(
				not site.completed and site.pending,
				"awaiting last occupant prevents automatic completion and refresh"
			)
			state.advance(0, [outside])
		check(p.xp == xp_before and p.level == level_before, "rescue completion awards no extra XP")
		check(
			site.completed and not site.pending and record.class_id == chosen,
			"talk/last-exit same once-only completion before refresh"
		)
		check(
			site.mobs.values().all(func(m): return m.dead),
			"last-exit pending refresh cannot resurrect rescue"
		)
		check(
			record.delivered and w.supplier_ceiling(Vector2i.ZERO) == ordinal + 1,
			"one shared package and one shared land benefit"
		)
		check(state.vendors == prior_stock, "rescue never rerolls existing stock")
		check(not w.complete_supplier(id), "duplicate completion is inert")
		var mission_nodes: Array = w.site_views[id].get_children().filter(
			func(n): return n.get("item") != null
		)
		w.deliver_rewards(id)
		check(
			(
				w.site_views[id].get_children().filter(func(n): return n.get("item") != null).size()
				== mission_nodes.size()
			),
			"repeat delivery cannot duplicate package/kill rewards"
		)
		state.advance(8640, [[0, 0, 0]])
		check(
			site.completed and site.mobs.values().all(func(m): return m.dead),
			"completed rescue stays clear after midnight"
		)
		w.party_provider = main.connected_party
	# Next normal midnight regeneration applies new ceiling, without forcing every roll to top grade.
	var old_stock: Dictionary = state.vendors.duplicate(true)
	w.restock_vendors()
	check(state.vendors != old_stock, "normal due daily restock regenerates saved gear")
	var day_stock: Dictionary = state.vendors.duplicate(true)
	w.party_provider = func(): return []
	state.advance(8640, [[0, 0, 0]])
	w.restock_vendors()
	check(
		state.vendors == day_stock,
		"empty connected party defers generation without fabricating level"
	)
	w.party_provider = main.connected_party
	w.restock_vendors()
	check(state.vendors != day_stock, "later connected party consumes ordinary due restock once")
	for record in state.vendors.values():
		check(
			record.ceiling == 4 and record.day == floori(state.clock / 86400),
			"saved restock uses legendary unlocked ceiling/current day"
		)
	var saw_low := false
	var saw_high := false
	for day in 150:
		for cap in 5:
			var stock := Shop.stock(
				&"weapon-vendor", w.gen, land, w.gen.village_at(land), 1, p.o, p.design, cap, day
			)
			check(
				stock.size() == 8 and stock.all(func(it): return it.rarity <= cap),
				"raw rarity clamped at each ceiling"
			)
			if cap == 4:
				saw_low = saw_low or stock.any(func(it): return it.rarity < 4)
				saw_high = saw_high or stock.any(func(it): return it.rarity == 4)
	check(saw_low and saw_high, "ceiling permits legendary without guaranteeing top grade")
	# Camp absent-class payload survives unload/restart, then first later entrant supplies class.
	var camp_id: String = state.site_id(Vector2i.ZERO, "camp", 0)
	visit(main, camp_id)
	w.party_provider = func(): return []
	clear(main, camp_id, null)
	var camp: Dictionary = state.sites[camp_id]
	var mission: String = "mission/%d" % camp.cycle
	var pending: Dictionary = camp.rewards[mission]
	check(
		pending.class_id == "" and pending.payload.is_empty() and not pending.delivered,
		"no connected inside or finisher class leaves pending package"
	)
	w.site_views[camp_id].free()
	w.site_views.erase(camp_id)
	w.deliver_rewards(camp_id)
	check(not pending.delivered, "absent view never marks undelivered delivered")
	# A separate undelivered fixed payload (ordinary kill) cannot be consumed merely by an absent view.
	var kill_key: String = camp.rewards.keys().filter(func(r): return r.begins_with("kill/"))[0]
	camp.rewards[kill_key].delivered = false
	var fixed: Array = camp.rewards[kill_key].payload.duplicate(true)
	w.deliver_rewards(camp_id)
	check(
		not camp.rewards[kill_key].delivered and camp.rewards[kill_key].payload == fixed,
		"fixed pending kill payload retained without live view"
	)
	w.party_provider = main.connected_party
	# Keep hero outside the cleared camp until after cold load.
	p.set_logical_position([0, 10, 0])
	check(main.save_now(), "full completion/vendor/pending save: " + str(main.save_data.errors))
	var data: Dictionary = main.save_data.capture(state, p)
	var key: String = state.vendors.keys()[0]
	var kill_record: String = camp.rewards.keys().filter(func(r): return r.begins_with("kill/"))[0]
	for path_ in [
		["world", "vendors", key],
		["world", "sites", camp_id, "rewards", mission],
		["world", "sites", camp_id, "rewards", kill_record]
	]:
		var valid: Dictionary = data
		for part in path_:
			valid = valid[part]
		for field in valid:
			for bad_value in [null, true, "invalid", -1, INF, []]:
				var bad: Dictionary = data.duplicate(true)
				var parent: Dictionary = bad
				for part in path_:
					parent = parent[part]
				if (
					Save.same_data(bad_value, parent[field])
					or (field == "delivered" and bad_value is bool)
					or (field == "items" and bad_value is Array)
				):
					continue
				parent[field] = bad_value
				reject(main.save_data, bad, str(path_) + " malformed " + field)
			var missing: Dictionary = data.duplicate(true)
			var parent: Dictionary = missing
			for part in path_:
				parent = parent[part]
			parent.erase(field)
			reject(main.save_data, missing, str(path_) + " missing " + field)
	for mutation in [
		"missing-vendors",
		"vendor-day",
		"vendor-cap",
		"vendor-level",
		"vendor-payload",
		"vendor-duplicate",
		"unknown-reward",
		"kill-payload",
		"kill-deleted",
		"mission-pending",
		"mission-classes",
		"mission-level",
		"resurrect"
	]:
		var bad: Dictionary = data.duplicate(true)
		match mutation:
			"missing-vendors":
				bad.world.erase("vendors")
			"vendor-day":
				bad.world.vendors[key].day += 100
			"vendor-cap":
				bad.world.vendors[key].ceiling = 5
			"vendor-level":
				bad.world.vendors[key].level = 0
			"vendor-payload":
				bad.world.vendors[key].items[0].rarity = (
					4 if bad.world.vendors[key].items[0].rarity != 4 else 0
				)
			"vendor-duplicate":
				bad.world.vendors[key].items.append(bad.world.vendors[key].items[0].duplicate())
			"unknown-reward":
				bad.world.sites[camp_id].rewards["fake/0"] = {
					"level": 1, "delivered": false, "payload": []
				}
			"kill-payload":
				var r: String = camp.rewards.keys().filter(func(r): return r.begins_with("kill/"))[0]
				bad.world.sites[camp_id].rewards[r].payload.append(
					Save.item_data(preload("res://game/items/item.gd").stack(&"coin", &"", 999))
				)
			"kill-deleted":
				var r: String = camp.rewards.keys().filter(func(r): return r.begins_with("kill/"))[0]
				bad.world.sites[camp_id].rewards.erase(r)
			"mission-pending":
				bad.world.sites[camp_id].rewards[mission].delivered = true
			"mission-classes":
				bad.world.sites[camp_id].rewards[mission].classes = ["mage", "mage"]
			"mission-level":
				bad.world.sites[camp_id].rewards[mission].level += 1
			"resurrect":
				bad.world.sites[state.site_id(Vector2i.ZERO, "supplier", 0)].completed = true
				bad.world.sites[state.site_id(Vector2i.ZERO, "supplier", 0)].cleared = false
		reject(main.save_data, bad, mutation)
	var cumulative: Dictionary = data.duplicate(true)
	cumulative.world.vendors[key].day = -1
	cumulative.world.sites[camp_id].rewards[mission].class_id = "not-class"
	check(
		not main.save_data.validate(cumulative) and main.save_data.errors.size() >= 2,
		"independent invalid save errors accumulate"
	)
	main.free()
	await process_frame
	var cold = MAIN.instantiate()
	cold.save_path = path
	root.add_child(cold)
	stop(cold)
	w = cold.get_node("World")
	p = cold.get_node("Player")
	state = w.state_data
	check(
		(
			Save.same_data(state.vendors, data.world.vendors)
			and w.supplier_ceiling(Vector2i.ZERO) == 4
		),
		"real main restart retains stock/purchases/shared progress"
	)
	check(
		not state.sites[camp_id].rewards[mission].delivered,
		"pending class survives actual cold main load"
	)
	visit(cold, camp_id)
	check(
		(
			state.sites[camp_id].rewards[kill_key].delivered
			and Save.same_data(state.sites[camp_id].rewards[kill_key].payload, fixed)
		),
		"fixed undelivered kill payload delivered after restart without reroll"
	)
	check(
		(
			state.sites[camp_id].rewards[mission].class_id == "warrior"
			and state.sites[camp_id].rewards[mission].delivered
		),
		"first later entrant resolves/delivers pending class once"
	)
	var resolved: Dictionary = state.sites[camp_id].rewards[mission]
	var source_powers := {
		1: 1, 2: 5, 3: 10, 4: 14, 5: 17, 6: 21, 7: 24, 8: 26, 9: 29, 10: 32, 11: 34, 12: 36, 13: 38
	}
	check(
		(
			resolved.payload[0].level == source_powers.get(int(resolved.level), -1)
			and resolved.payload[2].level == source_powers.get(int(resolved.level), -1)
		),
		"deferred class uses saved mission source power for gear/potion after restart"
	)
	var count: int = (
		w.site_views[camp_id].get_children().filter(func(n): return n.get("item") != null).size()
	)
	w.deliver_rewards(camp_id)
	check(
		(
			(
				w
				. site_views[camp_id]
				. get_children()
				. filter(func(n): return n.get("item") != null)
				. size()
			)
			== count
		),
		"pending resolution never redelivers"
	)
	check(cold.save_now(), "resolved class save valid: " + str(cold.save_data.errors))
	cold.free()
	await process_frame
	print("supplier shops ok" if failed == 0 else "supplier shops FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
