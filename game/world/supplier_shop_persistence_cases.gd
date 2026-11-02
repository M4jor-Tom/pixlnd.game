## Pending/delivered rewards, cold vendor stock and independent saved-record negatives.
## The calling SceneTree retains fixture and await/cleanup ownership.
extends RefCounted
const MAIN := preload("res://game/main.tscn")
const Save := preload("res://game/world/save_data.gd")


static func _saved_negatives(
	t,
	main,
	state,
	data: Dictionary,
	camp: Dictionary,
	camp_id: String,
	mission: String,
	key: String,
	kill_record: String
) -> void:
	for path_ in [
		["world", "vendors", key],
		["world", "sites", camp_id, "rewards", mission],
		["world", "sites", camp_id, "rewards", kill_record]
	]:
		_reward_fields(t, main, data, path_)
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
		_reward_mutation(t, main, state, data, camp, camp_id, mission, key, mutation)
	var cumulative: Dictionary = data.duplicate(true)
	cumulative.world.vendors[key].day = -1
	cumulative.world.sites[camp_id].rewards[mission].class_id = "not-class"
	t.check(
		not main.save_data.validate(cumulative) and main.save_data.errors.size() >= 2,
		"independent invalid save errors accumulate"
	)


static func _reward_fields(t, main, data: Dictionary, path_) -> void:
	var valid: Dictionary = data
	for part in path_:
		valid = valid[part]
	for field in valid:
		_invalid_reward_field(t, main, data, path_, field)
		var missing: Dictionary = data.duplicate(true)
		var parent: Dictionary = missing
		for part in path_:
			parent = parent[part]
		parent.erase(field)
		t.reject(main.save_data, missing, str(path_) + " missing " + field)


static func _reward_mutation(
	t,
	main,
	state,
	data: Dictionary,
	camp: Dictionary,
	camp_id: String,
	mission: String,
	key: String,
	mutation
) -> void:
	var bad: Dictionary = data.duplicate(true)
	_alter_reward(bad, state, camp, camp_id, mission, key, mutation)
	t.reject(main.save_data, bad, mutation)


static func _invalid_reward_field(t, main, data: Dictionary, path_, field) -> void:
	for bad_value in [null, true, "invalid", -1, INF, []]:
		var bad: Dictionary = data.duplicate(true)
		var parent: Dictionary = bad
		for part in path_:
			parent = parent[part]
		_reject_reward_value(t, main, bad, parent, path_, field, bad_value)


static func _reject_reward_value(
	t, main, bad: Dictionary, parent: Dictionary, path_, field, bad_value
) -> void:
	if (
		Save.same_data(bad_value, parent[field])
		or (field == "delivered" and bad_value is bool)
		or (field == "items" and bad_value is Array)
	):
		return
	parent[field] = bad_value
	t.reject(main.save_data, bad, str(path_) + " malformed " + field)


static func _alter_reward(
	bad: Dictionary,
	state,
	camp: Dictionary,
	camp_id: String,
	mission: String,
	key: String,
	mutation
) -> void:
	_alter_vendor(bad, key, mutation)
	match mutation:
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


static func _alter_vendor(bad: Dictionary, key: String, mutation) -> void:
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


static func _cold_packages(
	t,
	main,
	path: String,
	data: Dictionary,
	camp_id: String,
	mission: String,
	kill_key: String,
	fixed: Array
) -> void:
	var w
	var p
	var state
	main.free()
	await t.process_frame
	var cold = MAIN.instantiate()
	cold.save_path = path
	t.root.add_child(cold)
	t.stop(cold)
	w = cold.get_node("World")
	p = cold.get_node("Player")
	state = w.state_data
	t.check(
		(
			Save.same_data(state.vendors, data.world.vendors)
			and w.supplier_ceiling(Vector2i.ZERO) == 4
		),
		"real main restart retains stock/purchases/shared progress"
	)
	t.check(
		not state.sites[camp_id].rewards[mission].delivered,
		"pending class survives actual cold main load"
	)
	t.visit(cold, camp_id)
	t.check(
		(
			state.sites[camp_id].rewards[kill_key].delivered
			and Save.same_data(state.sites[camp_id].rewards[kill_key].payload, fixed)
		),
		"fixed undelivered kill payload delivered after restart without reroll"
	)
	t.check(
		(
			state.sites[camp_id].rewards[mission].class_id == "warrior"
			and state.sites[camp_id].rewards[mission].delivered
		),
		"first later entrant resolves/delivers pending class once"
	)
	var resolved: Dictionary = state.sites[camp_id].rewards[mission]
	_deferred_power(t, resolved)
	_no_redelivery(t, w, camp_id)
	t.check(cold.save_now(), "resolved class save valid: " + str(cold.save_data.errors))
	cold.free()
	await t.process_frame


static func _deferred_power(t, resolved: Dictionary) -> void:
	var source_powers := {
		1: 1, 2: 5, 3: 10, 4: 14, 5: 17, 6: 21, 7: 24, 8: 26, 9: 29, 10: 32, 11: 34, 12: 36, 13: 38
	}
	t.check(
		(
			resolved.payload[0].level == source_powers.get(int(resolved.level), -1)
			and resolved.payload[2].level == source_powers.get(int(resolved.level), -1)
		),
		"deferred class uses saved mission source power for gear/potion after restart"
	)


static func _no_redelivery(t, w, camp_id: String) -> void:
	var count: int = (
		w.site_views[camp_id].get_children().filter(func(n): return n.get("item") != null).size()
	)
	w.deliver_rewards(camp_id)
	t.check(
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
