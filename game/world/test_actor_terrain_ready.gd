## Restored creatures must wait for support at their own scalar position, not the player's tile.
extends SceneTree
const Main := preload("res://game/main.tscn")
const MeshData := preload("res://game/world/zone_mesh.gd")
const Gen := preload("res://game/world/encounter_gen.gd")
const Spawner := preload("res://game/world/spawner.gd")
const Save := preload("res://game/world/save_data.gd")
const Targeting := preload("res://game/combat/targeting.gd")
var failed := 0
var directory: String


class HeldTerrain:
	extends "res://game/world/terrain_worker.gd"
	var release := Semaphore.new()
	var first := true

	func _run(zone: Vector2i, epoch: int, guides: bool) -> void:
		if first:
			first = false
			release.wait()
		super._run(zone, epoch, guides)

	func stop() -> void:
		# Every fixture cleanup/owner exit releases the held terrain before joining it.
		release.post()
		super.stop()


func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok:
		failed += 1


func zone_at(at: Array) -> Vector2i:
	return Vector2i(floori(float(at[0]) / 64), floori(float(at[2]) / 64))


func open_main(path: String):
	var main = Main.instantiate()
	main.save_path = path
	root.add_child(main)
	main.get_node("World").set_process(false)
	main.get_node("Player").set_physics_process(false)
	main.get_node("Player").feel = null
	return main


func site_fixture(main, land: Vector2i) -> Dictionary:
	var world = main.get_node("World")
	check(world.ensure_land(world.gen.land_at(land)), "required land staged for readiness fixture")
	var id: String = world.state_data.site_id(land, "supplier", 0)
	var layout: Dictionary = world.site_layout(id)
	var stable: Dictionary = layout.assignments[0]
	var point := Gen.point(
		layout, -float(world.design["initial-encounters"].supplier.size) / 2 - 4, -12
	)
	var at := [float(point.x) + 0.5, layout.floor, float(point.y) + 0.5]
	check(
		Targeting.distance_squared(at, stable.home) < pow(float(world.design.spawns.ai.leash), 2),
		"exterior apron survivor remains inside lawful leash"
	)
	check(
		not world.state_data.inside(layout.volumes, [at]),
		"saved actor is outside the authored physical site floor"
	)
	var mob_id: String = id + "/" + stable.key
	var record: Dictionary = world.state_data.sites[id].mobs[mob_id]
	record.position = at
	record.hp -= 1
	record.combat.returning = true
	var px: float = float(at[0]) + 40
	if zone_at([px, at[1], at[2]]) == zone_at(at):
		px = float(at[0]) - 40
	var player_at := [px, world.gen.height_at(floori(px), floori(at[2])) + 2, at[2]]
	main.relocate_player(player_at)
	return {
		"id": mob_id, "at": at, "record": record.duplicate(true), "home_zone": zone_at(stable.home)
	}


func ambient_fixture(main) -> Dictionary:
	var world = main.get_node("World")
	for x in range(125, 132):
		for z in range(125, 132):
			var zone := Vector2i(x, z)
			var plan_: Array = Spawner.plan(
				world.gen, zone, world.design, world.creatures, world.rosters, 1
			)
			for group_index in plan_.size():
				for member in plan_[group_index].positions.size():
					var home: Vector3 = plan_[group_index].positions[member]
					var px := (
						(zone.x * 64 - 2.5)
						if home.x - zone.x * 64 < 32
						else ((zone.x + 1) * 64 + 2.5)
					)
					var at := [
						px, world.gen.height_at(floori(px), floori(home.z)) + 1, float(home.z)
					]
					if (
						Targeting.distance_squared(at, [home.x, home.y, home.z])
						>= pow(float(world.design.spawns.ai.leash), 2)
					):
						continue
					var inside := false
					for site in world.state_data.sites.values():
						inside = inside or world.state_data.inside(site.volumes, [at])
					if inside:
						continue
					world._publish_zone(zone, MeshData.data(world.gen, zone))
					var id := (
						"%s/ambient/%d,%d/%d/%d"
						% [world.state_data.world_id, x, z, group_index, member]
					)
					var actor = world.targeting.live[id]
					actor.set_logical_position(at)
					actor.hp -= 1
					actor.incarnation.combat.returning = true
					world.capture_mobs()
					var record: Dictionary = world.state_data.mobs[id].duplicate(true)
					main.relocate_player([float(home.x), home.y + 2, float(home.z)])
					return {"id": id, "at": at, "record": record, "home_zone": zone}
	return {}


func run_case(label: String, land: Vector2i, ambient: bool) -> void:
	var path := directory.path_join("readiness-" + label + ".json")
	DirAccess.remove_absolute(path)
	var main = open_main(path)
	var fixture: Dictionary = ambient_fixture(main) if ambient else site_fixture(main, land)
	check(not fixture.is_empty(), label + " has a legitimate generated saved survivor")
	if fixture.is_empty():
		main.free()
		return
	check(main.save_now(), label + " exterior survivor passes strict current-save validation")
	main.free()
	main = open_main(path)
	var world = main.get_node("World")
	var player = main.get_node("Player")
	var at: Array = fixture.at
	var missing := zone_at(at)
	var player_zone := zone_at(player.logical_position())
	check(missing != player_zone, label + " actor tile differs from ready player tile")
	world._publish_zone(player_zone, MeshData.data(world.gen, player_zone))
	if ambient and fixture.home_zone != player_zone:
		world._publish_zone(fixture.home_zone, MeshData.data(world.gen, fixture.home_zone))
	var held := HeldTerrain.new(
		world.world_seed, world.design, world.ontology.landscapes, world.state_data.lands
	)
	world._terrain_worker = held
	world._spawn_zone(missing)
	world.stream_sites()
	world.set_process(true)
	check(
		world.has_ground(player.position) and not world.zones.has(missing),
		label + " positive player support cannot stand in for missing actor support"
	)
	var clock: float = world.state_data.clock
	for i in 30:
		await physics_frame
		await process_frame
	var current: Array = (
		world.targeting.live[fixture.id].logical_position()
		if world.targeting.live.has(fixture.id)
		else fixture.record.position
	)
	print(
		"HELD_TERRAIN ",
		label,
		" expected=",
		JSON.stringify(at),
		" actual=",
		JSON.stringify(current),
		" live=",
		world.targeting.live.has(fixture.id)
	)
	check(
		Save.same_data(current, at),
		label + " saved position preserved while terrain worker is held"
	)
	check(
		not world.zones.has(missing) and held._thread.is_alive(),
		label + " terrain computation really remains pending"
	)
	check(
		world.state_data.clock > clock,
		label + " logical world clock remains live while support is pending"
	)
	held.release.post()
	for i in 240:
		if world.zones.has(missing) and world.targeting.live.has(fixture.id):
			break
		await physics_frame
		await process_frame
	check(
		world.zones.has(missing) and world.targeting.live.has(fixture.id),
		label + " actor automatically materializes/resumes after actual terrain publication"
	)
	if world.targeting.live.has(fixture.id):
		var actor = world.targeting.live[fixture.id]
		check(
			actor.is_physics_processing(),
			label + " tested creature runs normal physics, never a fixture freeze"
		)
		check(
			(
				actor.logical_id == fixture.id
				and actor.hp == fixture.record.hp
				and actor.level == fixture.record.level
				and actor.role == StringName(fixture.record.role)
			),
			label + " actual survivor HP/ID/level/role preserved"
		)
		var query := PhysicsRayQueryParameters3D.create(
			world.frame.to_local([at[0], float(at[1]) + 2, at[2]]),
			world.frame.to_local([at[0], float(at[1]) - 2, at[2]]),
			1,
			[actor.get_rid()]
		)
		check(
			not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),
			label + " newly published support has real collision"
		)
		var origin: Array = actor.logical_position()
		var floor_seen: bool = actor.is_on_floor()
		for i in 10:
			await physics_frame
			await process_frame
			floor_seen = floor_seen or actor.is_on_floor()
		check(
			floor_seen and actor.logical_position() != origin,
			label + " normal supported return motion resumes"
		)
	world.set_process(false)
	held.stop()
	main.free()
	await process_frame


func _init() -> void:
	call_deferred("run")


func run() -> void:
	directory = OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		quit(2)
		return
	await run_case("site", Vector2i.ZERO, false)
	await run_case("ambient", Vector2i.ZERO, true)
	await run_case("far-site", Vector2i(-512, 511), false)
	print("actor terrain readiness ok" if failed == 0 else "actor terrain readiness FAILED")
	quit(0 if failed == 0 else 1)
