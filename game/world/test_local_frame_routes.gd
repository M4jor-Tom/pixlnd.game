## Real automatic player capsule over every authored site-internal route. Frozen AI isolates geometry only.
extends SceneTree
const MAIN := preload("res://game/main.tscn")
const Gen := preload("res://game/world/encounter_gen.gd")
const World := preload("res://game/world/world.gd")
const State := preload("res://game/world/world_state.gd")
var failed := 0


class Driver:
	extends Node
	signal done
	var p
	var world
	var points: Array = []
	var index := 0
	var calls := 0
	var active := false
	var exhausted := false

	func _physics_process(_dt: float) -> void:
		# Their physical capsules remain; this check proves access, not encounter combat.
		for mob in world.targeting.live.values():
			mob.set_physics_process(false)
		if not active:
			return
		calls += 1
		if calls >= 3000:
			exhausted = true
			finish()
			return
		var at: Array = p.logical_position()
		var dx: float = points[index][0] - float(at[0])
		var dz: float = points[index][2] - float(at[2])
		if sqrt(dx * dx + dz * dz) <= 0.6:
			index += 1
			if index == points.size():
				finish()
				return
			dx = points[index][0] - float(at[0])
			dz = points[index][2] - float(at[2])
		p.get_node("CameraRig").rotation.y = atan2(-dx, -dz)
		Input.action_press("move_forward")

	func finish() -> void:
		Input.action_release("move_forward")
		active = false
		done.emit()


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
	var land := Vector2i.ZERO
	var ocean := false
	for arg in OS.get_cmdline_user_args():
		if arg == "--ocean":
			ocean = true
		if arg.begins_with("--land="):
			var parts := arg.trim_prefix("--land=").split(",")
			land = Vector2i(int(parts[0]), int(parts[1]))
	var path := directory.path_join("test-routes-%d-%d.json" % [land.x, land.y])
	DirAccess.remove_absolute(path)
	var main = MAIN.instantiate()
	main.save_path = path
	root.add_child(main)
	var w = main.get_node("World")
	var p = main.get_node("Player")
	var fixture
	if ocean:
		# Independent all-sea world, like test_playable_sites_runtime; real player/frame/physics unchanged.
		var design: Dictionary = w.design.duplicate(true)
		design.terrain.heightfield.base = 0
		design.terrain.heightfield.amplitude = 0
		var ontology = w.ontology
		w.retire_views()
		w.set_process(false)
		w.set_physics_process(false)
		w.targeting.set_physics_process(false)
		fixture = World.new()
		root.add_child(fixture)
		fixture.configure(ontology, design, State.new(design, 3), main.connected_party)
		fixture.frame = main.frame
		fixture.target = p
		w = fixture
		p.targeting = w.targeting
		p.ground_ready = w.has_ground
	var village: Dictionary = w.gen.village_at(w.gen.land_at(land))
	main.relocate_player([village.centre.x + 0.5, village.height + 2, village.centre.y + 0.5])
	w.ensure_land(w.gen.land_at(land))
	w.stream_sites()
	w._stream_village()
	var plan_: Dictionary = w.state_data.lands["%d,%d" % [land.x, land.y]]
	if ocean:
		check(plan_.village.hub, "forced-ocean capsule route uses real dry village hub")
	var interiors := 0
	var driver := Driver.new()
	driver.p = p
	driver.world = w
	driver.process_physics_priority = -2
	root.add_child(driver)
	for index in plan_.sites.size():
		var layout: Dictionary = plan_.sites[index]
		var entry := Gen.point(layout, layout.entry[0], layout.entry[1])
		var front := Gen.rotate(0, -1, layout.turn)
		var road := {
			"destination": index,
			"points":
			[
				[float(entry.x) + front.x * 2, float(entry.y) + front.y * 2, layout.floor],
				[float(entry.x) - front.x * 2, float(entry.y) - front.y * 2, layout.floor]
			]
		}
		driver.points = []
		for point in road.points:
			driver.points.append([float(point[0]), float(point[2]) + 0.05, float(point[1])])
		if road.has("destination"):
			interiors += 1
			var site: Dictionary = plan_.sites[road.destination]
			if site.family == "ruins":
				for component in site.components.slice(0, -1):
					var point := Gen.point(
						site, (component[0] + component[2]) / 2, (component[1] + component[3]) / 2
					)
					driver.points.append([float(point.x), float(site.floor), float(point.y)])
				# Return via room centres before taking the side alcove around the living boss capsule.
				for component in [site.components[5], site.components[4]]:
					var point := Gen.point(
						site, (component[0] + component[2]) / 2, (component[1] + component[3]) / 2
					)
					driver.points.append([float(point.x), float(site.floor), float(point.y)])
				for local in [[-6, 6], [3, 6], [3, 12], [12, 12]]:
					var point := Gen.point(site, local[0], local[1])
					driver.points.append([float(point.x), float(site.floor), float(point.y)])
			else:
				var half: float = float(w.design["initial-encounters"][site.family].size) / 2
				if site.family == "supplier":
					# The friendly captive is a real unattackable capsule in the battlefield; walk around it.
					for local in [[0, 0], [3, 0], [3, half - 2], [0, half - 2]]:
						var around := Gen.point(site, local[0], local[1])
						driver.points.append([float(around.x), float(site.floor), float(around.y)])
				var point := Gen.point(site, 0, half + 2)
				driver.points.append([float(point.x), float(site.floor), float(point.y)])
		p.velocity = Vector3.ZERO
		p._motion_remainder_x = 0
		p._motion_remainder_z = 0
		main.frame.place_entity(p, driver.points[0], true)
		driver.index = 0
		driver.calls = 0
		driver.exhausted = false
		driver.active = true
		await driver.done
		await process_frame
		print(
			"capsule land=",
			land,
			" route=",
			index,
			" calls=",
			driver.calls,
			" index=",
			driver.index,
			" position=",
			p.logical_position(),
			" goal=",
			driver.points[mini(driver.index, driver.points.size() - 1)]
		)
		check(not driver.exhausted, "actual capsule completes site-interior route " + str(index))
		if driver.exhausted:
			break
	check(interiors == 6, "all six destination interiors are traversed")
	driver.free()
	if fixture != null:
		fixture.free()
	main.free()
	print("all-site capsule routes ok" if not failed else "all-site capsule routes FAILED")
	quit(0 if not failed else 1)
