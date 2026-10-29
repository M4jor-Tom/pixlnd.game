## Real main streaming must defer terrain computation and publish working collision later.
extends SceneTree
const Main := preload("res://game/main.tscn")
const MeshData := preload("res://game/world/zone_mesh.gd")
var failed := 0


class HeldGuidance:
	extends "res://game/world/terrain_worker.gd"
	var release := Semaphore.new()
	var first := true

	func _guidance(plan_: Dictionary) -> Dictionary:
		if not first:
			return super._guidance(plan_)
		first = false
		release.wait()
		return {"error": "injected optional guidance failure"}


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		quit(1)
		return
	var path := directory.path_join("async-generation.json")
	DirAccess.remove_absolute(path)
	var main = Main.instantiate()
	main.save_path = path
	root.add_child(main)
	var w = main.get_node("World")
	var p = main.get_node("Player")
	var held := HeldGuidance.new(w.world_seed, w.design, w.ontology.landscapes, w.state_data.lands)
	w._terrain_worker = held
	var failures: Array = []
	w.generation_failed.connect(func(message): failures.append(message))
	var at: Array = p.logical_position()
	var zc := Vector2i(floori(float(at[0]) / 64), floori(float(at[2]) / 64))
	w._spawn_zone(zc)
	check(not w.has_ground(p.position), "zone request does not synchronously build terrain")
	var clock: float = main.state_data.clock
	var frames := 0
	while not w.has_ground(p.position) and frames < 180:
		await physics_frame
		frames += 1
	check(w.has_ground(p.position), "background terrain eventually publishes ground")
	await physics_frame
	await physics_frame
	check(main.state_data.clock > clock, "game clock advances while terrain loads")
	var hit: Dictionary = w.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(
			p.position + Vector3.UP * 3, p.position + Vector3.DOWN * 10
		)
	)
	check(not hit.is_empty(), "published terrain has actual collision")
	# Read both meshes through the same native normal/colour encoding, not raw source arrays.
	var expected_mesh := MeshData.build(w.gen, zc)
	var expected: Array = expected_mesh.surface_get_arrays(0)
	var actual: Array = w.zones[zc].mesh.surface_get_arrays(0)
	for field in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR]:
		check(
			actual[field] == expected[field],
			"private worker mesh equals deterministic synchronous sampler mesh"
		)
	var position_: Array = p.logical_position()
	check(
		not w._marker_clear({"x": position_[0], "z": position_[2]}),
		"late solid guide cannot enclose live player"
	)
	check(
		w._marker_clear({"x": float(position_[0]) + 10000, "z": float(position_[2]) + 10000}),
		"empty scenery position remains eligible"
	)
	check(w.guidance.is_empty(), "terrain and collision published while guidance remains pending")
	check(main.save_now(), "current save valid while guidance is pending")
	var original := FileAccess.get_file_as_string(path)
	var loaded: Dictionary = main.save_data.load_file(path)
	check(not loaded.is_empty(), "pending-guidance current save loads without generating guidance")
	var bad := loaded.duplicate(true)
	bad.world.lands["0,0"].sites[0].centre[0] += 1
	check(not main.save_data.write_atomic(path, bad), "required geography remains strict")
	check(
		FileAccess.get_file_as_string(path) == original, "invalid geography preserves original file"
	)
	held.release.post()
	for i in 120:
		if w.guidance.has("0,0"):
			break
		await process_frame
	check(
		w.guidance.has("0,0") and w.guidance["0,0"].is_empty(),
		"failed optional guidance is omitted"
	)
	check(
		failures.is_empty() and w.state_data.sites.size() == 6,
		"optional failure never becomes fatal generation failure or removes destinations"
	)
	main.relocate_player([float(at[0]) + 1024, at[1], at[2]])
	frames = 0
	while not w.has_ground(p.position) and frames < 180:
		await physics_frame
		frames += 1
	check(
		w.has_ground(p.position) and not w.zones.has(zc),
		"relocation discards stale zone jobs and publishes in current local frame"
	)
	main.free()
	print("async generation ok" if failed == 0 else "async generation FAILED")
	quit(0 if failed == 0 else 1)
