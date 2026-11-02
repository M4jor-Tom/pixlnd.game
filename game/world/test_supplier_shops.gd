extends SceneTree
const Persistence := preload("res://game/world/supplier_shop_persistence_cases.gd")
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
	await _run_main(main, path)


func _rescues(main, w, p, state) -> void:
	for ordinal in 4:
		_rescue_case(main, w, p, state, ordinal)


func _daily_stock(main, w, state, land, p) -> void:
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
	_rarity_ceiling(w, land, p)


func _vendor_transactions(main, w, p, state, roles: Array) -> void:
	var panel
	for child in main.get_children():
		if child.get_script() == preload("res://game/items/shop_panel.gd"):
			panel = child
	_shop_interaction(main, w, p, state, panel)
	_stock_transactions(w, p, state, roles)


func _rescue_case(main, w, p, state, ordinal: int) -> void:
	var id: String = state.site_id(Vector2i.ZERO, "supplier", ordinal)
	visit(main, id)
	var site: Dictionary = state.sites[id]
	var layout: Dictionary = w.site_layout(id)
	_uncleared_captive(w, id, site)
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
	check(site.cleared and not site.completed, "final designated death clears but waits for rescue")
	var record := _rescue_death(site)
	_complete_rescue(w, p, state, ordinal, site, layout, extra, record)
	_rescue_receipts(w, state, id, site, prior_stock)
	w.party_provider = main.connected_party


func _rarity_day(w, land, p, day: int, saw_low: bool, saw_high: bool) -> Array:
	for cap in 5:
		var stock := _stock_ceiling(w, land, p, cap, day)
		if cap == 4:
			saw_low = saw_low or stock.any(func(it): return it.rarity < 4)
			saw_high = saw_high or stock.any(func(it): return it.rarity == 4)
	return [saw_low, saw_high]


func _rarity_ceiling(w, land, p) -> void:
	var saw_low := false
	var saw_high := false
	for day in 150:
		var seen := _rarity_day(w, land, p, day, saw_low, saw_high)
		saw_low = seen[0]
		saw_high = seen[1]
	check(saw_low and saw_high, "ceiling permits legendary without guaranteeing top grade")


func _run_main(main, path: String) -> void:
	stop(main)
	var w = main.get_node("World")
	var p = main.get_node("Player")
	var state = w.state_data
	var roles := [&"weapon-vendor", &"armor-vendor"]
	var land = w.gen.land_at(Vector2i.ZERO)
	_vendor_transactions(main, w, p, state, roles)
	_rescues(main, w, p, state)
	_daily_stock(main, w, state, land, p)
	await _pending_camp(main, w, p, state, path)
	print("supplier shops ok" if failed == 0 else "supplier shops FAILED %d" % failed)
	quit(0 if failed == 0 else 1)


func _pending_camp(main, w, p, state, path: String) -> void:
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
	var fixed_receipt := _pending_fixed(w, camp, camp_id)
	var kill_key: String = fixed_receipt[0]
	var fixed: Array = fixed_receipt[1]
	w.party_provider = main.connected_party
	# Keep hero outside the cleared camp until after cold load.
	p.set_logical_position([0, 10, 0])
	check(main.save_now(), "full completion/vendor/pending save: " + str(main.save_data.errors))
	var data: Dictionary = main.save_data.capture(state, p)
	var key: String = state.vendors.keys()[0]
	var kill_record: String = camp.rewards.keys().filter(func(r): return r.begins_with("kill/"))[0]
	Persistence._saved_negatives(self, main, state, data, camp, camp_id, mission, key, kill_record)
	await Persistence._cold_packages(self, main, path, data, camp_id, mission, kill_key, fixed)


func _shop_interaction(main, w, p, state, panel) -> void:
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
	_purchase_callback(w, p, state, panel)
	panel._open(false)
	p.talked.emit(vendor)
	check(panel._stock_rows.size() == 7, "reopen does not reroll purchased gear")
	panel._open(false)


func _stock_transactions(w, p, state, roles: Array) -> void:
	for role in roles:
		_initial_stock(w, role)
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


func _complete_rescue(
	w,
	p,
	state,
	ordinal: int,
	site: Dictionary,
	layout: Dictionary,
	extra: Dictionary,
	record: Dictionary
) -> void:
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
	_completion_snapshot(p, site, record, chosen, xp_before, level_before)
	check(
		record.delivered and w.supplier_ceiling(Vector2i.ZERO) == ordinal + 1,
		"one shared package and one shared land benefit"
	)


func _rescue_receipts(w, state, id: String, site: Dictionary, prior_stock: Dictionary) -> void:
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


func _stock_ceiling(w, land, p, cap: int, day: int) -> Array:
	var stock := Shop.stock(
		&"weapon-vendor", w.gen, land, w.gen.village_at(land), 1, p.o, p.design, cap, day
	)
	check(
		stock.size() == 8 and stock.all(func(it): return it.rarity <= cap),
		"raw rarity clamped at each ceiling"
	)
	return stock


func _uncleared_captive(w, id: String, site: Dictionary) -> void:
	var captive
	for npc in w.site_views[id].get_children():
		if npc.get("role") == &"captive":
			captive = npc
			break
	w.on_talked(captive)
	check(not site.completed, "talk before clear rejected")


func _pending_fixed(w, camp: Dictionary, camp_id: String) -> Array:
	# A separate undelivered fixed payload (ordinary kill) cannot be consumed merely by an absent view.
	var kill_key: String = camp.rewards.keys().filter(func(r): return r.begins_with("kill/"))[0]
	camp.rewards[kill_key].delivered = false
	var fixed: Array = camp.rewards[kill_key].payload.duplicate(true)
	w.deliver_rewards(camp_id)
	check(
		not camp.rewards[kill_key].delivered and camp.rewards[kill_key].payload == fixed,
		"fixed pending kill payload retained without live view"
	)
	return [kill_key, fixed]


func _purchase_callback(w, p, state, panel) -> void:
	p.inventory.coins = 100000
	var expected = panel._stock_rows[0]
	var price := Shop.buy_price(expected, p.o, p.design)
	var purchase_entry: Array = []
	p.inventory.changed.connect(
		func():
			purchase_entry.append(
				[
					state.vendors["0,0/weapon-vendor"].items.size(),
					p.inventory.coins,
					panel._stock_rows.size()
				]
			),
		CONNECT_ONE_SHOT
	)
	panel._on_buy(0)
	check(
		purchase_entry == [[7, 100000 - price, 8]],
		"authoritative stock removed before synchronous inventory/panel callbacks"
	)
	check(
		p.inventory.coins == 100000 - price and panel._stock_rows.size() == 7,
		"actual shop buy uses original price/removes saved gear"
	)
	check(
		not w.buy_vendor(&"weapon-vendor", 0, p, Vector2i.ZERO, expected),
		"stale row cannot buy replacement at same index"
	)


func _initial_stock(w, role) -> void:
	var stock: Array = w.vendor_stock(role, 1, Vector2i.ZERO)
	check(
		(
			stock.size() == (7 if role == &"weapon-vendor" else 8)
			and stock.all(func(it): return it.rarity == 0)
		),
		"initial common ceiling/quantity"
	)


func _completion_snapshot(
	p, site: Dictionary, record: Dictionary, chosen: String, xp_before: int, level_before: int
) -> void:
	check(p.xp == xp_before and p.level == level_before, "rescue completion awards no extra XP")
	check(
		site.completed and not site.pending and record.class_id == chosen,
		"talk/last-exit same once-only completion before refresh"
	)
	check(
		site.mobs.values().all(func(m): return m.dead),
		"last-exit pending refresh cannot resurrect rescue"
	)


func _rescue_death(site: Dictionary) -> Dictionary:
	var record: Dictionary = site.rewards["mission/%d" % site.cycle]
	check(
		(
			record.classes == ["mage", "warrior"]
			and not record.delivered
			and record.payload.size() == 4
		),
		"final-death snapshot includes awaiting distinct class before talk"
	)
	return record
