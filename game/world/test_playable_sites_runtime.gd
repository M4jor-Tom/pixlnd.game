extends SceneTree
const Frame := preload("res://game/world/local_frame.gd")
const MAIN := preload("res://game/main.tscn")
const DB := preload("res://game/ontology_db.gd")
const Gen := preload("res://game/world/encounter_gen.gd")
const Site := preload("res://game/world/encounter_site.gd")
const World := preload("res://game/world/world.gd")
const State := preload("res://game/world/world_state.gd")
const MeshData := preload("res://game/world/zone_mesh.gd")
const Settlement := preload("res://game/world/settlement.gd")
const Save := preload("res://game/world/save_data.gd")
const Combat := preload("res://game/combat/combat.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func stop(main) -> void:
	main.set_physics_process(false)
	main.get_node("Player").set_physics_process(false)
	var w = main.get_node("World")
	w.set_process(false)
	w.set_physics_process(false)
	w.targeting.set_physics_process(false)


func ray(w, from: Vector3, to: Vector3) -> Dictionary:
	return w.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(from, to)
	)


func build_site_ground(w, plan_: Dictionary) -> void:
	var zones := {}
	var v: Dictionary = plan_.village
	var volumes: Array = [
		[v.centre[0] - 32, 0, v.centre[1] - 32, v.centre[0] + 32, 0, v.centre[1] + 32]
	]
	for site in plan_.sites:
		volumes.append_array(site.volumes)
	for volume in volumes:
		for x in range(floori((volume[0] - 8) / 64.0), floori((volume[3] + 8) / 64.0) + 1):
			for z in range(floori((volume[2] - 8) / 64.0), floori((volume[5] + 8) / 64.0) + 1):
				zones[Vector2i(x, z)] = true
	# This fixture checks geometry/renewal, not background scheduling (test_async_generation).
	for zone in zones:
		w._publish_zone(zone, MeshData.data(w.gen, zone))
	for mob in w.targeting.live.values():
		mob.set_physics_process(false)


func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		printerr("PIXLND_TEST_DIR required")
		quit(1)
		return
	var path := directory.path_join("test-playable-sites-runtime.json")
	DirAccess.remove_absolute(path)
	if not root.has_node("OntologyDB"):
		var db := DB.new()
		db.name = "OntologyDB"
		root.add_child(db)
	var main = MAIN.instantiate()
	main.save_path = path
	root.add_child(main)
	await _run_main(main, path)


func _site_geometry(w) -> void:
	var captives := 0
	var bosses := 0
	for id in w.site_views:
		var counts := _geometry_case(w, id, captives, bosses)
		captives = counts[0]
		bosses = counts[1]
	check(captives == 4 and bosses == 7, "four real friendly captives / seven physical bosses")


func _village_gate(w, plan_: Dictionary) -> void:
	# Full gate-width horizontal sweeps through the actual unchanged ring's empty-house passage.
	var gate: Dictionary = Settlement.opening(
		w.design.settlement, plan_.village.gate_index, plan_.village.gate_width
	)
	for side in [-1.99, 0.0, 1.99]:
		var a: Array = plan_.village.centre
		var b: Array = [
			float(a[0]) + gate.direction[0] * (gate.back + 2),
			float(a[1]) + gate.direction[1] * (gate.back + 2)
		]
		var delta := Vector2(b[0] - a[0], b[1] - a[1]).normalized()
		var shift: Vector2 = Vector2(-delta.y, delta.x) * side
		check(
			(
				ray(
					w,
					w.frame.to_local(
						[float(a[0]) + shift.x, plan_.village.height + 2, float(a[1]) + shift.y]
					),
					w.frame.to_local(
						[float(b[0]) + shift.x, plan_.village.height + 2, float(b[1]) + shift.y]
					)
				)
				. is_empty()
			),
			"four-wide actual town gate"
		)


func _save_negatives(main, path: String, loaded: Dictionary, id: String, first: String) -> void:
	var original := FileAccess.get_file_as_string(path)
	for corruption in [
		"partial",
		"geometry",
		"role",
		"special",
		"spirit",
		"count",
		"pack",
		"tier-stats",
		"spirit-level",
		"land-geometry"
	]:
		_save_corruption(main, path, loaded, id, first, original, corruption)


func _supplier_exit(second, world) -> void:
	# Actual automatic last-exit completion precedes pending refresh.
	var supplier_id := ""
	for candidate in second.state_data.sites:
		if second.state_data.sites[candidate].family == "supplier":
			supplier_id = candidate
			break
	_kill_rescue(second, world, supplier_id)
	_completed_exit(second, supplier_id)


func _ocean_corners(second, world) -> void:
	# Actual ocean islands, dry hub at both finite-world corners, with terrain collision.
	var restore_position: Array = second.get_node("Player").logical_position()
	world.retire_views()  # independent saved-world fixture must not overlap the previous world's local native geometry
	for lc in [Vector2i(-512, -512), Vector2i(511, 511), Vector2i(-512, 511), Vector2i(511, -512)]:
		var design: Dictionary = world.design.duplicate(true)
		design.terrain.heightfield.base = 0
		design.terrain.heightfield.amplitude = 0
		var state := State.new(design, 3)
		var fixture := World.new()
		root.add_child(fixture)
		fixture.configure(world.ontology, design, state, func(): return [second.get_node("Player")])
		fixture.target = second.get_node("Player")
		fixture.set_process(false)
		fixture.set_physics_process(false)
		fixture.targeting.set_physics_process(false)
		check(fixture.ensure_land(fixture.gen.land_at(lc)), "ocean corner actual full registration")
		var geography: Dictionary = state.lands.values()[0]
		fixture.frame = Frame.new(int(design.terrain["zone-blocks"]))
		var place := [
			geography.village.centre[0], geography.village.height + 2, geography.village.centre[1]
		]
		fixture.frame.set_origin(place)
		fixture.frame.place_entity(fixture.target, place, true)
		fixture.stream_sites()
		fixture._stream_village()
		build_site_ground(fixture, geography)
		await physics_frame
		await physics_frame
		check(
			(
				geography.village.hub
				and fixture.villages.size() == 1
				and fixture.site_views.size() == 6
			),
			"actual ocean hub settlement/all-six islands"
		)
		fixture.free()
	# Restore this main's per-world position before its shutdown save (fixtures use another saved world).
	second.frame.place_entity(second.get_node("Player"), restore_position, true)
	second.free()


func _survivor_lifecycle(main, w, p, path: String) -> Array:
	# Real survivor/new-incarnation and restart, retaining stable assignment and initial spirit levels.
	var id: String = main.state_data.sites.keys()[0]
	var s: Dictionary = main.state_data.sites[id]
	var layout: Dictionary = w.site_layout(id)
	var assignment: Dictionary = layout.assignments[0]
	var first: String = id + "/" + assignment.key
	var survivor_id: String = id + "/" + layout.assignments[1].key
	var survivor = w.targeting.live[survivor_id]
	survivor.take_damage(1, p)
	survivor.position.x += 1
	var survivor_position: Vector3 = survivor.global_position
	var survivor_level: int = survivor.level
	var survivor_hp: float = survivor.hp
	var spirit_levels: Dictionary = s.spirit_levels.duplicate(true)
	w.targeting.live[first].take_damage(1e9, p)
	_renew_survivor(
		main,
		w,
		p,
		id,
		layout,
		s,
		first,
		survivor_id,
		survivor_level,
		survivor_hp,
		spirit_levels,
		survivor_position
	)
	p.level = 1
	p.xp = 0
	p.skill_points = 0
	for mob in w.targeting.live.values():
		mob.set_physics_process(false)
	check(main.save_now(), "full actual site save: " + str(main.save_data.errors))
	var loaded: Dictionary = main.save_data.load_file(path)
	check(not loaded.is_empty(), "full site boundary roundtrip")
	if not loaded.is_empty():
		_save_negatives(main, path, loaded, id, first)
	return [id, first, survivor_id, survivor_level, survivor_hp, survivor_position, loaded]


func _restored_survivor(
	second,
	world,
	loaded: Dictionary,
	id: String,
	first: String,
	survivor_id: String,
	survivor_level: int,
	survivor_hp: float,
	survivor_position: Vector3
) -> void:
	check(
		second.state_data.lands["0,0"] == loaded.world.lands["0,0"],
		"stable geography/roles/special/spirit saved separately"
	)
	check(
		(
			world.targeting.live[survivor_id].level == survivor_level
			and is_equal_approx(world.targeting.live[survivor_id].hp, survivor_hp)
		),
		"main restart retains survivor"
	)
	check(
		second.state_data.sites[id].mobs[first].cycle == 1,
		"main restart keeps current incarnation generation"
	)
	check(
		(
			world.targeting.live[survivor_id].global_position.is_equal_approx(survivor_position)
			and not world.targeting.record(world.targeting.live[survivor_id]).threat.is_empty()
		),
		"site position and independent survivor threat survive restart"
	)


func _geometry_case(w, id, captives: int, bosses: int) -> Array:
	var layout: Dictionary = w.site_layout(id)
	captives = _captives(w, id, layout, captives)
	_site_entry(w, layout)
	for stable in layout.assignments:
		bosses = _actor_geometry(w, id, stable, bosses)
	return [captives, bosses]


func _captives(w, id, layout: Dictionary, captives: int) -> int:
	if layout.family == "supplier":
		captives = _captive_nodes(w, id, captives)
	return captives


func _site_entry(w, layout: Dictionary) -> void:
	var entry := Gen.point(layout, layout.entry[0], layout.entry[1])
	var front := Gen.rotate(0, -1, layout.turn)
	var from: Vector3 = w.frame.to_local(
		[float(entry.x) + front.x * 2, layout.floor + 1, float(entry.y) + front.y * 2]
	)
	var to: Vector3 = w.frame.to_local(
		[float(entry.x) - front.x * 2, layout.floor + 1, float(entry.y) - front.y * 2]
	)
	check(ray(w, from, to).is_empty(), "actual unobstructed entry")
	if layout.family == "ruins":
		check(
			not ray(w, from + Vector3.UP * 4.5, to + Vector3.UP * 4.5).is_empty(),
			"five-high entry lintel"
		)
		_ruins_components(w, layout)


func _actor_geometry(w, id, stable, bosses: int) -> int:
	var m = w.targeting.live[id + "/" + stable.key]
	var mult: float = 4 if stable.boss else 1
	check(
		is_equal_approx(m.max_hp, Combat.enemy_max_hp(m.level, 2 + stable.tier) * mult),
		"local NPC HP curve"
	)
	check(
		is_equal_approx(
			m.damage,
			(
				Combat.enemy_damage(m.level, 2 + stable.tier, w.design.combat)
				* (1.5 if stable.boss else 1)
			)
		),
		"local NPC damage curve"
	)
	if stable.boss:
		bosses += 1
		check(
			is_equal_approx(
				m.get_node("Collision").shape.height,
				Gen.height(m.level, w.design["initial-encounters"])
			),
			"boss physical height"
		)
	else:
		check(
			is_equal_approx(m.get_node("Collision").shape.height, 1.7),
			"boss does not resize shared ordinary capsules"
		)
	return bosses


func _ruins_components(w, layout: Dictionary) -> void:
	for component in layout.components:
		var centre := Gen.point(
			layout, (component[0] + component[2]) / 2, (component[1] + component[3]) / 2
		)
		var floor_point: Vector3 = w.frame.to_local([centre.x, layout.floor, centre.y])
		check(
			not (ray(w, floor_point + Vector3.UP * 0.2, floor_point - Vector3.UP * 0.2).is_empty()),
			"actual component floor"
		)
		var ceiling := ray(w, floor_point + Vector3.UP * 5.8, floor_point + Vector3.UP * 6.2)
		check(
			not ceiling.is_empty() and absf(ceiling.position.y - layout.floor - 6) < 0.01,
			"six-high clear ceiling"
		)


func _save_corruption(
	main, path: String, loaded: Dictionary, id: String, first: String, original: String, corruption
) -> void:
	var bad: Dictionary = loaded.duplicate(true)
	_alter_site(bad, id, first, corruption)
	check(
		not main.save_data.write_atomic(path, bad) and not main.save_data.errors.is_empty(),
		"reject exact-content " + corruption
	)
	check(FileAccess.get_file_as_string(path) == original, "invalid content preserves original")


func _kill_rescue(second, world, supplier_id: String) -> void:
	for mob_id in second.state_data.sites[supplier_id].mobs:
		if world.targeting.live.has(mob_id):
			world.targeting.live[mob_id].take_damage(1e9, second.get_node("Player"))


func _completed_exit(second, supplier_id: String) -> void:
	var rescue: Dictionary = second.state_data.sites[supplier_id]
	rescue.pending = true
	second.state_data.advance(0, [second.get_node("Player").logical_position()])
	var completed_before_refresh = (
		rescue.cleared
		and rescue.completed
		and not rescue.pending
		and rescue.mobs.values().all(func(m): return m.dead)
	)
	check(completed_before_refresh, "cleared rescue completes before refresh and never resurrects")


func _safe_renewal(
	main,
	w,
	p,
	layout: Dictionary,
	s: Dictionary,
	first: String,
	survivor_id: String,
	survivor_level: int,
	survivor_hp: float,
	spirit_levels: Dictionary,
	boss_id: String
) -> void:
	_closed_midnights(main, p, layout, s, first)
	_renew_band(main, w, p, s, first)
	check(
		s.mobs[survivor_id].level == survivor_level and s.mobs[survivor_id].hp == survivor_hp,
		"renewal preserves survivor incarnation"
	)
	check(
		s.spirit_levels == spirit_levels and s.mobs[boss_id].level >= 17,
		"genuinely renewed boss level changes but initial spirit level does not"
	)


func _run_main(main, path: String) -> void:
	stop(main)
	var w = main.get_node("World")
	var p = main.get_node("Player")
	var plan_: Dictionary = main.state_data.lands["0,0"]
	check(main.state_data.sites.size() == 6, "actual main registers all six atomically")
	w.stream_sites()
	w._stream_village()
	build_site_ground(w, plan_)
	for mob in w.targeting.live.values():
		mob.set_physics_process(false)
	await physics_frame
	await physics_frame
	check(
		(
			w.site_views.size() == 6
			and (
				(
					w
					. targeting
					. live
					. values()
					. filter(func(m): return m.has_meta("encounter_site"))
					. size()
				)
				== 46
			)
		),
		"actual 46 hostiles at all six streamed sites"
	)
	_site_geometry(w)
	_village_gate(w, plan_)
	var history := _survivor_lifecycle(main, w, p, path)
	var id: String = history[0]
	var first: String = history[1]
	var survivor_id: String = history[2]
	var survivor_level: int = history[3]
	var survivor_hp: float = history[4]
	var survivor_position: Vector3 = history[5]
	var loaded: Dictionary = history[6]
	main.free()
	var second = MAIN.instantiate()
	second.save_path = path
	root.add_child(second)
	stop(second)
	var world = second.get_node("World")
	world.stream_sites()
	_restored_survivor(
		second,
		world,
		loaded,
		id,
		first,
		survivor_id,
		survivor_level,
		survivor_hp,
		survivor_position
	)
	_supplier_exit(second, world)
	await _ocean_corners(second, world)
	print(
		"playable sites runtime ok" if failed == 0 else "playable sites runtime FAILED %d" % failed
	)
	quit(0 if failed == 0 else 1)


func _renew_survivor(
	main,
	w,
	p,
	id: String,
	layout: Dictionary,
	s: Dictionary,
	first: String,
	survivor_id: String,
	survivor_level: int,
	survivor_hp: float,
	spirit_levels: Dictionary,
	survivor_position: Vector3
) -> void:
	var boss_id: String = id + "/" + layout.assignments[-1].key
	w.targeting.live[boss_id].take_damage(1e9, p)
	check(s.mobs[first].dead and not s.cleared, "partial clear is not completion")
	w.capture_mobs()
	w.site_views[id].free()
	w.site_views.erase(id)
	check(not w.targeting.live.has(first), "site unload detaches views only")
	w.stream_sites()
	check(
		not w.targeting.live.has(first) and w.targeting.live[survivor_id].hp == survivor_hp,
		"unload/reload no revival or survivor heal"
	)
	check(
		w.targeting.live[survivor_id].global_position == survivor_position,
		"current position survives unload separately from stable home"
	)
	_safe_renewal(
		main,
		w,
		p,
		layout,
		s,
		first,
		survivor_id,
		survivor_level,
		survivor_hp,
		spirit_levels,
		boss_id
	)


func _captive_nodes(w, id, captives: int) -> int:
	for node in w.site_views[id].get_children():
		if node is StaticBody3D and node.get("role") == &"captive":
			captives += 1
			check(
				not node.has_method("take_damage"), "friendly captive not a hostile damage target"
			)
	return captives


func _alter_site(bad: Dictionary, id: String, first: String, corruption) -> void:
	match corruption:
		"partial":
			bad.world.sites.erase(id)
		"geometry":
			bad.world.sites[id].volumes[0][0] += 1
		"role":
			bad.world.lands["0,0"].sites[0].assignments[0].role = "unknown"
		"special":
			bad.world.lands["0,0"].sites[0].assignments[-1].special = "unknown"
		"spirit":
			bad.world.lands["0,0"].sites[0].assignments[-1].spirit = "unknown"
		"count":
			bad.world.sites[id].mobs.erase(first)
		"pack":
			bad.world.sites[id].mobs[first].pack = "foreign"
		"tier-stats":
			bad.world.sites[id].mobs[first].damage *= 2
		"spirit-level":
			bad.world.sites[id].spirit_levels = {}
		"land-geometry":
			bad.world.lands["0,0"].sites[0].components[0][0] += 1


func _closed_midnights(main, p, layout: Dictionary, s: Dictionary, first: String) -> void:
	p.level = 20
	main.state_data.clock = 86400 - 1
	var boundary: Array = layout.volumes[0]
	main.state_data.advance(0.1, [[boundary[0], boundary[1], boundary[2]]])
	check(s.pending and s.mobs[first].dead, "closed boundary delays actual refresh")
	main.state_data.advance(8640, [[boundary[0], boundary[1], boundary[2]]])
	check(s.pending and s.cycle == 0, "missed midnights coalesce")


func _renew_band(main, w, p, s: Dictionary, first: String) -> void:
	main.state_data.advance(0, [p.logical_position()])
	w.stream_sites()
	check(
		not s.pending and s.cycle == 1 and not s.mobs[first].dead and s.mobs[first].level >= 17,
		"safe actual genuine renewal at current party band"
	)
