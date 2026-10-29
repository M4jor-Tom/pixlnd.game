## Optional scenery must not perturb compact ambient IDs, saved survivors or future incarnations.
extends SceneTree
const Main := preload("res://game/main.tscn")
const Spawner := preload("res://game/world/spawner.gd")
const MeshData := preload("res://game/world/zone_mesh.gd")
const Encounters := preload("res://game/world/encounter_gen.gd")
const Save := preload("res://game/world/save_data.gd")
const Model := preload("res://ontology/model.gd")
var failed := 0
var directory: String


func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok:
		failed += 1


func freeze(main) -> void:
	main.get_node("Player").set_physics_process(false)
	var world = main.get_node("World")
	world.set_process(false)
	world.set_physics_process(false)
	world.targeting.set_physics_process(false)
	for actor in world.targeting.live.values():
		actor.set_physics_process(false)


func open_main(name_: String, fresh: bool):
	var path := directory.path_join(name_ + ".json")
	if fresh:
		DirAccess.remove_absolute(path)
	var main = Main.instantiate()
	main.save_path = path
	root.add_child(main)
	freeze(main)
	return main


func plan(world, zone: Vector2i) -> Array:
	var levels: Array = world.party_levels()
	return Spawner.plan(
		world.gen, zone, world.design, world.creatures, world.rosters, levels[0], levels[1]
	)


func marker_at(world, at: Array) -> Dictionary:
	return {
		"x": at[0],
		"z": at[2],
		"top": world.gen.height_at(floori(at[0]), floori(at[2])) + 1,
		"family": "masonry",
		"bounds": [float(at[0]) - 0.75, float(at[2]) - 0.7, float(at[0]) + 0.75, float(at[2]) + 0.7]
	}


func accept(world, zone: Vector2i, markers: Array) -> void:
	var routes := Encounters.guidance(
		world.gen, world.state_data.lands["0,0"], world.design["initial-encounters"]
	)
	routes.append({"destination": 0, "family": "masonry", "markers": markers})
	world._pending_guidance.append(
		{
			"kind": "guidance",
			"epoch": world._terrain_epoch,
			"zone": zone,
			"land": "0,0",
			"error": "",
			"routes": routes
		}
	)
	world._poll_terrain()
	world.stream_sites()


func guide_hits(main, marker: Dictionary) -> int:
	var world = main.get_node("World")
	var player = main.get_node("Player")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player.get_node("Collision").shape
	query.transform.origin = (
		world.frame.to_local([marker.x, marker.top, marker.z])
		+ player.get_node("Collision").position
	)
	query.exclude = [player.get_rid()]
	var count := 0
	for hit in world.get_world_3d().direct_space_state.intersect_shape(query, 128):
		if world.access_views["0,0"].is_ancestor_of(hit.collider):
			count += 1
	return count


func controls(main, markers: Array) -> void:
	var world = main.get_node("World")
	check(
		world.guidance.has("0,0") and world.access_views.has("0,0"),
		"nonempty successful guidance is cached and published"
	)
	for marker in markers:
		check(
			guide_hits(main, marker) == 0, "optional solid guide omitted at ambient home/position"
		)
	var solid := 0
	for road in world.guidance["0,0"]:
		for marker in road.markers:
			if guide_hits(main, marker) > 0:
				solid += 1
	check(solid > 0, "nonconflicting real solid guidance remains, not an empty/failure control")


func publish(main, zone: Vector2i) -> void:
	var world = main.get_node("World")
	world._publish_zone(zone, MeshData.data(world.gen, zone))
	freeze(main)


func assert_survivors(world, records: Dictionary) -> void:
	for id in records:
		var saved: Dictionary = records[id]
		check(
			world.targeting.live.has(id) != bool(saved.dead),
			"same compact member identity materializes or remains dead: " + id
		)
		if not world.targeting.live.has(id):
			continue
		var actor = world.targeting.live[id]
		check(
			Save.same_data(actor.logical_position(), saved.position),
			"actual body restores saved wander position"
		)
		check(
			(
				actor.hp == saved.hp
				and actor.level == saved.level
				and actor.role == StringName(saved.role)
			),
			"actual survivor HP/level/role retained"
		)
		for field in [
			"species",
			"home",
			"position",
			"level",
			"max_hp",
			"hp",
			"damage",
			"role",
			"seed",
			"pack",
			"cycle"
		]:
			check(
				Save.same_data(actor.incarnation[field], saved[field]), "survivor retains " + field
			)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	directory = OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		quit(2)
		return
	if "--read" in OS.get_cmdline_user_args():
		await cold_read()
		quit(0 if failed == 0 else 1)
		return
	var main = open_main("guidance-prospective", true)
	var world = main.get_node("World")
	var zone := Vector2i.ZERO
	var baseline: Array = []
	# Bounded fixture selection in the existing runtime test's seeded neighbourhood, not a seed sweep.
	for x in range(125, 132):
		for z in range(125, 132):
			var candidate := plan(world, Vector2i(x, z))
			if candidate.reduce(func(n, g): return n + g.positions.size(), 0) >= 2:
				zone = Vector2i(x, z)
				baseline = candidate
				break
		if not baseline.is_empty():
			break
	check(
		not baseline.is_empty(),
		"literal seed neighbourhood has at least two deterministic ambient members"
	)
	if baseline.is_empty():
		main.free()
		quit(1)
		return
	print("AMBIENT_ZONE ", zone)
	var first: Vector3 = baseline[0].positions[0]
	var prospective := marker_at(world, [first.x, first.y, first.z])
	accept(world, zone, [prospective])
	freeze(main)
	await physics_frame
	check(
		plan(world, zone) == baseline,
		"prospective optional guidance cannot compact/reroll deterministic ambient plan"
	)
	controls(main, [prospective])
	publish(main, zone)
	var count: int = baseline.reduce(func(n, g): return n + g.positions.size(), 0)
	check(
		world.state_data.mobs.size() == count,
		"all prospective genuinely new members materialize despite conflicting cosmetics"
	)
	main.free()

	main = open_main("guidance-ambient", true)
	world = main.get_node("World")
	publish(main, zone)
	var ids: Array = world.state_data.mobs.keys()
	ids.sort()
	var survivor = world.targeting.live[ids[0]]
	survivor.take_damage(1, main.get_node("Player"))
	var home: Array = survivor.incarnation.home.duplicate()
	survivor.set_logical_position([float(home[0]) + 10, home[1], home[2]])
	var dead = world.targeting.live[ids[1]]
	dead.take_damage(1e9, null)
	world.capture_mobs()
	var records: Dictionary = world.state_data.mobs.duplicate(true)
	var markers := [
		marker_at(world, home),
		marker_at(world, records[ids[0]].position),
		marker_at(world, records[ids[1]].home)
	]
	baseline = plan(world, zone)
	world.retire_views()
	await process_frame
	check(
		not world.targeting.live.has(ids[0]),
		"survivor node really unloaded before guidance arrives"
	)
	accept(world, zone, markers)
	freeze(main)
	await physics_frame
	check(
		plan(world, zone) == baseline,
		"guidance arriving while saved actors unloaded preserves exact plan/stats/RNG"
	)
	controls(main, markers)
	publish(main, zone)
	assert_survivors(world, records)
	check(main.save_now(), "actual ambient lifecycle save remains current-rule valid")
	var metadata := {
		"zone": [zone.x, zone.y],
		"records": records,
		"markers": markers,
		"plan": JSON.stringify(baseline)
	}
	var file := FileAccess.open(
		directory.path_join("guidance-ambient-expect.json"), FileAccess.WRITE
	)
	file.store_string(JSON.stringify(metadata, "", true, true))
	file.close()
	main.free()
	if failed == 0:
		var output: Array = []
		var status := OS.execute(
			"timeout",
			[
				"681",
				OS.get_executable_path(),
				"--headless",
				"--path",
				ProjectSettings.globalize_path("res://"),
				"-s",
				get_script().resource_path,
				"--",
				"--read"
			],
			output,
			true
		)
		var text := "\n".join(output)
		file = FileAccess.open(directory.path_join("guidance-ambient-cold.log"), FileAccess.WRITE)
		file.store_string("exit=%d\n%s" % [status, text])
		file.close()
		print(text)
		check(
			status == 0 and "SCRIPT ERROR" not in text and "ERROR:" not in text,
			"fresh-process nonempty-guidance load/materialization/renewal"
		)
	print("guidance ambient identities ok" if failed == 0 else "guidance ambient identities FAILED")
	quit(0 if failed == 0 else 1)


func cold_read() -> void:
	var metadata: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(directory.path_join("guidance-ambient-expect.json"))
	)
	var main = open_main("guidance-ambient", false)
	var world = main.get_node("World")
	var zone := Vector2i(metadata.zone[0], metadata.zone[1])
	check(
		JSON.stringify(plan(world, zone)) == metadata.plan,
		"fresh process regenerates original deterministic plan before guidance"
	)
	accept(world, zone, metadata.markers)
	freeze(main)
	await physics_frame
	check(
		JSON.stringify(plan(world, zone)) == metadata.plan,
		"fresh guidance cannot shift cold saved compact member indices"
	)
	controls(main, metadata.markers)
	publish(main, zone)
	assert_survivors(world, metadata.records)
	var player = main.get_node("Player")
	# Isolate genuine progression/renewal from optional headless level-up audio, as in role tests.
	player.feel = null
	while player.level < 20:
		player.gain_xp(Model.xp_to_next(player.level) - player.xp)
	main.state_data.clock = 86400 - 1
	world._physics_process(0.1 * Engine.time_scale)
	world.populate_zone(zone)
	freeze(main)
	for id in metadata.records:
		var old: Dictionary = metadata.records[id]
		check(
			world.targeting.live.has(id),
			"all saved members materialize after eligible-dead renewal"
		)
		if not world.targeting.live.has(id):
			continue
		var current: Dictionary = world.targeting.live[id].incarnation
		check(
			(
				Save.same_data(current.home, old.home)
				and current.seed == old.seed
				and current.pack == old.pack
			),
			"renewal retains member/home/pack identity"
		)
		if old.dead:
			check(
				(
					current.cycle == old.cycle + 1
					and current.level >= 17
					and current.hp == current.max_hp
				),
				"genuine eligible dead incarnation renews at current party band"
			)
		else:
			check(
				(
					current.level == old.level
					and current.hp == old.hp
					and Save.same_data(current.position, old.position)
				),
				"renewal preserves surviving level/HP/wander position"
			)
	main.free()
	await process_frame
	print(
		(
			"guidance ambient cold renewal ok"
			if failed == 0
			else "guidance ambient cold renewal FAILED"
		)
	)
