## Cached successful guidance must recheck actors when its actual collision is recreated.
extends SceneTree
const Main := preload("res://game/main.tscn")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func freeze(world) -> void:
	world.set_process(false)
	world.set_physics_process(false)
	world.targeting.set_physics_process(false)
	for actor in world.targeting.live.values():
		actor.set_physics_process(false)


func guide_hits(world, player, marker: Dictionary) -> int:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player.get_node("Collision").shape
	query.transform = player.global_transform
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


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		quit(2)
		return
	var path := directory.path_join("cached-guidance.json")
	DirAccess.remove_absolute(path)
	var main = Main.instantiate()
	main.save_path = path
	root.add_child(main)
	var world = main.get_node("World")
	var player = main.get_node("Player")
	player.set_physics_process(false)
	for i in 180:
		if world.access_views.has("0,0"):
			break
		await physics_frame
	freeze(world)
	world._terrain_worker.stop()
	check(
		world.access_views.has("0,0"), "successful worker guidance reaches actual view publication"
	)
	if not world.access_views.has("0,0"):
		main.free()
		quit(1)
		return
	await physics_frame
	var marker: Dictionary = {}
	for road in world.guidance["0,0"]:
		for candidate in road.markers:
			if guide_hits(world, player, candidate) > 0:
				marker = candidate.duplicate(true)
				break
		if not marker.is_empty():
			break
	check(
		not marker.is_empty(), "nonempty cached guide has real capsule-overlapping solid collision"
	)
	if not marker.is_empty():
		var cached: Array = world.guidance["0,0"].duplicate(true)
		print("CACHED_MARKER ", JSON.stringify(marker))
		main.relocate_player([marker.x, marker.top, marker.z])
		# Retired bodies are removed before recreating the cache. The player's physics stays disabled.
		await process_frame
		await physics_frame
		world.stream_sites()
		freeze(world)
		await physics_frame
		var at: Array = player.logical_position()
		print(
			"PUBLICATION_QUERY_POSITION ",
			JSON.stringify(at),
			" physics_enabled=",
			player.is_physics_processing()
		)
		check(
			(
				float(at[0]) == float(marker.x)
				and float(at[1]) == float(marker.top)
				and float(at[2]) == float(marker.z)
			),
			"query precedes player movement or contact recovery"
		)
		check(
			guide_hits(world, player, marker) == 0,
			"cached recreation omits solid guide through relocated player capsule"
		)
		check(
			world.guidance["0,0"] == cached,
			"actor safety does not destructively edit pure cached guidance"
		)
		var control := 0
		for road in cached:
			for other in road.markers:
				if guide_hits(world, player, other) > 0:
					control += 1
		check(control > 0, "nonconflicting cached guides still publish real solid scenery")
	main.free()
	print("guidance cached publication ok" if failed == 0 else "guidance cached publication FAILED")
	quit(0 if failed == 0 else 1)
