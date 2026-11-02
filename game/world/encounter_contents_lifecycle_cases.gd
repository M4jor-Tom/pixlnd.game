## Feature restart, safe rubble, trap partitions, renewal and independent schema cases.
## The calling SceneTree retains fixture and await/cleanup ownership.
extends RefCounted
const MAIN := preload("res://game/main.tscn")


static func _restart_features(
	t, main, w, p, id: String, trap: Dictionary, table_key: String
) -> Array:
	var contents
	var hp: float
	t.check(main.save_now(), "actual main atomic feature save")
	var path: String = main.save_path
	main.free()
	await t.process_frame
	main = MAIN.instantiate()
	main.save_path = path
	t.root.add_child(main)
	t.stop(main)
	w = main.get_node("World")
	p = main.get_node("Player")
	w.stream_sites()
	t.stop(main)
	contents = w.site_views[id].get_node("Contents")
	contents.set_physics_process(false)
	t.check(
		t.get_nodes_in_group("ground-items").is_empty(),
		"delivered table pair never rematerializes on restart"
	)
	t.check(
		w.state_data.sites[id].contents.props[table_key].hp == 0, "broken table survives restart"
	)
	p.set_logical_position(trap.point)
	hp = p.hp
	contents.advance(0.05)
	t.check(p.hp == hp, "saved activation hitset prevents replay after restart")
	p.set_logical_position([trap.point[0], trap.point[1] + 1.01, trap.point[2]])
	contents.advance(3)
	t.check(p.hp == hp, "jump above trap avoids standing retrigger")
	return [main, w, p, contents]


static func _rubble_collision(t, w, p, id: String, contents) -> Array:
	var rubble_key: String = contents.rubble.keys()[0]
	var rubble_point: Array = contents.plan.rubble[rubble_key]
	await t.physics_frame
	await t.physics_frame
	var native: Vector3 = contents.native(rubble_point)
	var query := PhysicsRayQueryParameters3D.create(
		native + Vector3.UP * 1.5, native + Vector3.UP * 0.5
	)
	var hit: Dictionary = w.get_world_3d().direct_space_state.intersect_ray(query)
	t.check(
		not hit.is_empty() and hit.collider == contents.rubble[rubble_key],
		"stone voxel has real collision"
	)
	contents.break_rubble(rubble_key)
	t.check(w.state_data.sites[id].contents.rubble[rubble_key].broken, "rubble destruction saved")
	t.check(contents.rubble[rubble_key].collision_layer == 0, "rubble really loses collision")
	hit = w.get_world_3d().direct_space_state.intersect_ray(query)
	t.check(hit.is_empty(), "destroyed voxel no longer blocks actual ray")
	var deadline: float = w.state_data.sites[id].contents.rubble[rubble_key].restore_at
	t.check(
		is_equal_approx(deadline - w.state_data.clock, 72 * 3600),
		"72 world hour restoration deadline"
	)
	p.set_logical_position([0, 100, 0])
	w.state_data.clock = deadline - 0.01
	contents.restore_due()
	t.check(w.state_data.sites[id].contents.rubble[rubble_key].broken, "no early rubble restore")
	w.state_data.clock = deadline
	p.set_logical_position(rubble_point)
	contents.restore_due()
	t.check(
		w.state_data.sites[id].contents.rubble[rubble_key].broken,
		"occupied site defers rubble restore"
	)
	p.set_logical_position([0, 100, 0])
	var actor_id: String = w.state_data.sites[id].mobs.keys()[0]
	var actor = w.targeting.live[actor_id]
	var old_point: Array = actor.logical_position()
	actor.set_logical_position(rubble_point)
	contents.restore_due()
	t.check(
		w.state_data.sites[id].contents.rubble[rubble_key].broken,
		"actor overlap defers restoration without player occupancy"
	)
	actor.set_logical_position(old_point)
	contents.restore_due()
	t.check(
		(
			not w.state_data.sites[id].contents.rubble[rubble_key].broken
			and contents.rubble[rubble_key].collision_layer != 0
		),
		"unoccupied nonoverlapping due rubble restores collision"
	)
	return [rubble_key, rubble_point]


static func _trap_partitions(
	t, main, p, trap: Dictionary, contents, rubble_key: String, table_key: String
) -> void:
	p.set_logical_position(trap.point)
	p.hp = 1000
	p.max_hp = 1000
	p._iframes = 0
	p.blocking = false
	p.armor = 0
	contents.saved.traps[0] = {"phase": "idle", "left": 0.0, "hit": []}
	contents.advance(4)
	var coarse: Dictionary = contents.saved.traps[0].duplicate(true)
	var coarse_loss: float = 1000 - p.hp
	contents.saved.traps[0] = {"phase": "idle", "left": 0.0, "hit": []}
	p.hp = 1000
	for i in 40:
		contents.advance(0.1)
	t.check(
		(
			coarse_loss == 60
			and 1000 - p.hp == coarse_loss
			and contents.saved.traps[0].phase == coarse.phase
			and is_equal_approx(contents.saved.traps[0].left, coarse.left)
		),
		"coarse and fragmented trap time preserves standing retriggers/boundaries"
	)
	contents.saved.traps[0] = {"phase": "idle", "left": 0.0, "hit": []}
	contents.advance(0)
	p.set_logical_position([0, 100, 0])
	contents.advance(0.8)
	t.check(contents.saved.traps[0].phase == "active", "leaving never cancels warning")
	# The inherited site t.root translates all content once with the production frame.
	var before_point: Array = contents.plan.rubble[rubble_key].duplicate()
	main.frame.shift_to([main.frame.origin[0] + 64, main.frame.origin[1] - 64])
	t.check(
		(
			contents.rubble[rubble_key].global_position
			== contents.native(before_point) + Vector3.UP * 0.5
		),
		"rubble remains in canonical logical position through live frame transaction"
	)
	t.check(
		(
			contents.props[table_key].global_position
			== contents.native(contents.plan.props[table_key].point) + Vector3.UP * 0.5
		),
		"prop follows tracked site root once"
	)


static func _renew_rooms(t, w, p, id: String, contents, table_key: String) -> bool:
	# A coalesced safe renewal rolls each room once and does not rescale its surviving guards.
	var survivor: String = w.state_data.sites[id].mobs.keys()[1]
	var old_level: int = w.state_data.sites[id].mobs[survivor].level
	var dead_id: String = w.state_data.sites[id].mobs.keys()[0]
	w.targeting.live[dead_id].take_damage(1e9, p)
	p.level = 20
	p.skill_points = 19 * preload("res://ontology/model.gd").SKILL_POINTS_PER_LEVEL
	w.state_data.sites[id].pending = true
	w.state_data.advance(0, [[0, 100, 0]])
	await t.process_frame
	t.check(
		(
			w.state_data.sites[id].cycle == 1
			and w.state_data.sites[id].room_levels.all(func(l): return l >= 17)
		),
		"safe renewal rerolls saved room band once"
	)
	t.check(
		w.state_data.sites[id].mobs[survivor].level == old_level,
		"mixed-level surviving guard unchanged"
	)
	t.check(
		w.state_data.sites[id].mobs[dead_id].level == w.state_data.sites[id].room_levels[0],
		"replacement uses renewed room level"
	)
	t.check(
		(
			w.state_data.sites[id].contents.props[table_key].hp == 20
			and w.state_data.sites[id].contents.traps[0].phase == "idle"
		),
		"daily renewal restores props and idles traps"
	)
	t.check(
		(
			(
				t
				. get_nodes_in_group("ground-items")
				. filter(func(n): return n.item.type == &"consumable")
				. size()
			)
			== 3
		),
		"one fresh table potion per room at renewal"
	)
	return _renewed_tables(t, w, id)


static func _feature_schema(
	t, main, w, p, id: String, table_key: String, rubble_key: String
) -> void:
	var snapshot: Dictionary = main.save_data.capture(w.state_data, p)
	t.check(main.save_data.validate(snapshot), "generated content schema validates")
	for field in ["room_levels", "contents"]:
		var bad := snapshot.duplicate(true)
		bad.world.sites[id].erase(field)
		t.check(not main.save_data.validate(bad), "missing " + field + " rejected")
	for path_ in [
		["traps", 0, "phase"],
		["traps", 0, "left"],
		["traps", 0, "hit"],
		["props", table_key, "hp"],
		["rubble", rubble_key, "restore_at"],
		["rubble", rubble_key, "broken"]
	]:
		_malformed_feature(t, main, snapshot, id, path_)
	var bad := snapshot.duplicate(true)
	bad.world.sites[id].room_levels = [1, null, 1]
	bad.world.sites[id].contents.traps[0].left = INF
	t.check(
		not main.save_data.validate(bad) and main.save_data.errors.size() >= 2,
		"invalid room level and trap timer accumulate"
	)


static func _cold_rubble(t, main, w, id: String, contents, rubble_key: String, rubble_point: Array):
	contents.break_rubble(rubble_key)
	var delayed: float = w.state_data.sites[id].contents.rubble[rubble_key].restore_at
	var blocker_id: String = w.state_data.sites[id].mobs.keys()[0]
	w.state_data.sites[id].mobs[blocker_id].position = rubble_point.duplicate()
	w.retire_views()
	t.check(main.save_now(), "save broken rubble while unloaded")
	var save_path: String = main.save_path
	main.free()
	await t.process_frame
	main = MAIN.instantiate()
	main.save_path = save_path
	t.root.add_child(main)
	t.stop(main)
	w = main.get_node("World")
	t.check(
		(
			w.state_data.sites[id].contents.rubble[rubble_key].broken
			and w.state_data.sites[id].contents.rubble[rubble_key].restore_at == delayed
		),
		"unloaded broken rubble deadline survives cold restart exactly"
	)
	w.state_data.clock = delayed
	w.restore_rubble(id)
	t.check(
		w.state_data.sites[id].contents.rubble[rubble_key].broken,
		"saved unloaded actor still defers due rubble"
	)
	w.state_data.sites[id].mobs[blocker_id].position = (
		w.state_data.sites[id].mobs[blocker_id].home.duplicate()
	)
	w.restore_rubble(id)
	t.check(
		not w.state_data.sites[id].contents.rubble[rubble_key].broken,
		"unloaded actor-safe due restoration updates logical owner"
	)
	return main


static func _renewed_tables(t, w, id: String) -> bool:
	var renewed_powers := {17: 45, 18: 46, 19: 48, 20: 49, 21: 51, 22: 52, 23: 53}
	var renewed_site: Dictionary = w.state_data.sites[id]
	for room in 3:
		var reward_key := "furnishing/1/room/%d/table/0" % room
		if not renewed_site.rewards.has(reward_key):
			t.check(false, "renewed table receipt exists: " + reward_key)
			t.quit(1)
			return false
		var reward: Dictionary = renewed_site.rewards[reward_key]
		t.check(
			(
				reward.level == renewed_site.room_levels[room]
				and reward.payload[1].level == renewed_powers.get(int(reward.level), -1)
			),
			"renewed potion converts saved room source; survivor level stays unchanged"
		)
	return true


static func _malformed_feature(t, main, snapshot: Dictionary, id: String, path_) -> void:
	for value in [null, [], {}, "bad", true, INF, -1]:
		_feature_value(t, main, snapshot, id, path_, value)


static func _feature_value(t, main, snapshot: Dictionary, id: String, path_, value) -> void:
	if path_[-1] == "broken" and value is bool:
		return
	if path_[-1] == "hit" and value is Array:
		return
	var invalid := snapshot.duplicate(true)
	invalid.world.sites[id].contents[path_[0]][path_[1]][path_[2]] = value
	t.check(
		not main.save_data.validate(invalid),
		"malformed saved content rejected " + str(path_) + str(value)
	)
