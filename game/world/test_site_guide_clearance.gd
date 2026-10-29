## Successful whole-land guidance must yield to a legitimately saved, unloaded site survivor.
extends SceneTree
const Main := preload("res://game/main.tscn")
const Encounters := preload("res://game/world/encounter_gen.gd")
const MeshData := preload("res://game/world/zone_mesh.gd")
const Targeting := preload("res://game/combat/targeting.gd")
const Save := preload("res://game/world/save_data.gd")
var failed := 0
var directory: String


func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok:
		failed += 1


func open_main(path: String):
	var main = Main.instantiate()
	main.save_path = path
	root.add_child(main)
	main.get_node("World").set_process(false)
	main.get_node("World").set_physics_process(false)
	main.get_node("Player").set_physics_process(false)
	main.get_node("Player").feel = null
	return main


func zone_at(at: Array) -> Vector2i:
	return Vector2i(floori(float(at[0]) / 64), floori(float(at[2]) / 64))


func guide_hits(world, shape: CapsuleShape3D, at: Array, exclude: Array[RID] = []) -> int:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = world.frame.to_local(at) + Vector3.UP * shape.height / 2
	query.exclude = exclude
	var count := 0
	for hit in world.get_world_3d().direct_space_state.intersect_shape(query, 128):
		if world.access_views["0,0"].is_ancestor_of(hit.collider):
			count += 1
	return count


func restore_and_query(path: String, metadata: Dictionary) -> void:
	var main = open_main(path)
	var world = main.get_node("World")
	var player = main.get_node("Player")
	main.relocate_player(metadata.far)
	var at: Array = metadata.record.position
	var zone := zone_at(at)
	# Make real support ready without loading the encounter view; isolate Q2 from terrain readiness.
	world._publish_zone(zone, MeshData.data(world.gen, zone))
	world._pending_guidance.append(
		{
			"kind": "guidance",
			"epoch": world._terrain_epoch,
			"zone": zone_at(player.logical_position()),
			"land": "0,0",
			"error": "",
			"routes": metadata.routes
		}
	)
	world._poll_terrain()
	world.stream_sites()
	for actor in world.targeting.live.values():
		actor.set_physics_process(false)
	check(
		not world.site_views.has(metadata.site) and not world.targeting.live.has(metadata.mob),
		"conflicting saved site survivor really remains unloaded during guide publication"
	)
	check(
		world.access_views.has("0,0"),
		"successful nonempty whole-land guide view publishes independently of unloaded site"
	)
	await physics_frame
	var near := [float(at[0]) + 20, float(at[1]) + 2, at[2]]
	player.set_logical_position(near)  # approaching retains the already-published guide view
	world.stream_sites()
	for actor in world.targeting.live.values():
		actor.set_physics_process(false)  # collision is queried before any contact recovery
	check(
		world.targeting.live.has(metadata.mob),
		"same saved site survivor materializes when its site enters range"
	)
	if world.targeting.live.has(metadata.mob):
		var actor = world.targeting.live[metadata.mob]
		await physics_frame
		check(
			Save.same_data(actor.logical_position(), at) and not actor.is_physics_processing(),
			"native capsule query precedes survivor movement/recovery"
		)
		check(
			guide_hits(world, actor.get_node("Collision").shape, at, [actor.get_rid()]) == 0,
			"guide collision omitted for saved unloaded site position before restore"
		)
		for field in ["home", "position", "hp", "level", "role", "seed", "pack"]:
			check(
				Save.same_data(actor.incarnation[field], metadata.record[field]),
				"restoration preserves site survivor " + field
			)
		var solid := 0
		for road in metadata.routes:
			for marker in road.markers:
				if (
					guide_hits(
						world,
						actor.get_node("Collision").shape,
						[marker.x, marker.top, marker.z],
						[actor.get_rid()]
					)
					> 0
				):
					solid += 1
		check(solid > 0, "nonconflicting guide objects retain actual solid collision")
	check(
		Save.same_data(world.guidance["0,0"], metadata.routes),
		"pure successful guidance cache is unchanged"
	)
	check(main.save_now(), "restored exterior encounter remains strict current-save valid")
	main.free()
	await process_frame


func _init() -> void:
	call_deferred("run")


func run() -> void:
	directory = OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		quit(2)
		return
	var path := directory.path_join("site-guide-clearance.json")
	var metadata_path := directory.path_join("site-guide-expect.json")
	if "--read" in OS.get_cmdline_user_args():
		var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
		await restore_and_query(path, metadata)
		print("site guide cold restore ok" if failed == 0 else "site guide cold restore FAILED")
		quit(0 if failed == 0 else 1)
		return
	DirAccess.remove_absolute(path)
	var main = open_main(path)
	var world = main.get_node("World")
	var plan_: Dictionary = world.state_data.lands["0,0"]
	var routes := Encounters.guidance(world.gen, plan_, world.design["initial-encounters"])
	var metadata: Dictionary = {}
	# Use an actual generated marker and actual guard home within the selected30-block leash.
	for road in routes:
		var layout: Dictionary = plan_.sites[road.destination]
		for marker in road.markers:
			var at := [marker.x, marker.top, marker.z]
			if not world._marker_clear(marker):
				continue
			for stable in layout.assignments:
				if (
					stable.boss
					or (
						Targeting.distance_squared(at, stable.home)
						> pow(float(world.design.spawns.ai.leash), 2)
					)
				):
					continue
				var site_id: String = world.state_data.site_id(
					Vector2i.ZERO, layout.family, layout.ordinal
				)
				var mob_id: String = site_id + "/" + stable.key
				var record: Dictionary = world.state_data.sites[site_id].mobs[mob_id]
				record.position = at
				record.hp -= 1
				var vx: float = plan_.village.centre[0]
				var vz: float = plan_.village.centre[1]
				var delta := Vector2(layout.centre[0] - vx, layout.centre[1] - vz).normalized()
				var far := [vx - delta.x * 200, plan_.village.height + 2, vz - delta.y * 200]
				main.relocate_player(far)
				metadata = {
					"site": site_id,
					"mob": mob_id,
					"record": record.duplicate(true),
					"routes": routes,
					"far": far
				}
				break
			if not metadata.is_empty():
				break
		if not metadata.is_empty():
			break
	check(
		not metadata.is_empty(),
		"seeded guide has a legitimate exterior site-survivor overlap within leash, no forced placement"
	)
	if metadata.is_empty():
		main.free()
		quit(1)
		return
	print(
		"SITE_GUIDE_CASE ",
		metadata.site,
		" position=",
		JSON.stringify(metadata.record.position),
		" home=",
		JSON.stringify(metadata.record.home)
	)
	check(main.save_now(), "unloaded exterior survivor passes current-rule save validation")
	var file := FileAccess.open(metadata_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "", true, true))
	file.close()
	main.free()
	await restore_and_query(path, metadata)
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
		file = FileAccess.open(directory.path_join("site-guide-cold.log"), FileAccess.WRITE)
		file.store_string("exit=%d\n%s" % [status, text])
		file.close()
		print(text)
		check(
			status == 0 and "SCRIPT ERROR" not in text and "ERROR:" not in text,
			"bounded fresh-process saved-site guide clearance"
		)
	print("site guide clearance ok" if failed == 0 else "site guide clearance FAILED")
	quit(0 if failed == 0 else 1)
