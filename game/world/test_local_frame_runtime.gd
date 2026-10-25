## Actual automatic main/World/Targeting/player lifecycle, including scalar-only connected members.
extends SceneTree
const MAIN := preload("res://game/main.tscn")
const Player := preload("res://game/entities/player.gd")
const Targeting := preload("res://game/combat/targeting.gd")
const Save := preload("res://game/world/save_data.gd")
var failed := 0


class ObservedPlayer:
	extends Player
	var calls := 0
	var frames: Array = []

	func _physics_process(dt: float) -> void:
		calls += 1
		frames.append(Engine.get_physics_frames())
		super(dt)


class RouteDriver:
	extends Node
	signal done
	var p
	var points: Array = []
	var index := 0
	var calls := 0
	var active := false
	var exhausted := false
	var died := false

	func _physics_process(_dt: float) -> void:
		if not active:
			return
		calls += 1
		if p.dead:
			died = true
			finish()
			return
		if calls >= 1800:
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
		printerr("PIXLND_TEST_DIR required")
		quit(1)
		return
	var path := directory.path_join("test-local-frame-main.json")
	DirAccess.remove_absolute(path)
	var main = MAIN.instantiate()
	main.save_path = path
	var p = main.get_node("Player")
	p.set_script(ObservedPlayer)
	root.add_child(main)
	var w = main.get_node("World")
	var driver := RouteDriver.new()
	driver.p = p
	driver.process_physics_priority = -2
	root.add_child(driver)
	var total_callbacks := 0
	for land in [
		Vector2i.ZERO,
		Vector2i(-512, -512),
		Vector2i(511, 511),
		Vector2i(-512, 511),
		Vector2i(511, -512)
	]:
		var v: Dictionary = w.gen.village_at(w.gen.land_at(land))
		var spawn := [v.centre.x + 0.5, v.height + 2.0, v.centre.y + 0.5]
		p.velocity = Vector3.ZERO
		main.relocate_player(spawn)
		check(p.logical_position() == spawn, "cold scalar main position " + str(land))
		check(absf(p.position.x) < 64 and absf(p.position.z) < 64, "cold bounded main position")
		for i in 20:
			await physics_frame
		var key := "%d,%d" % [land.x, land.y]
		check(main.state_data.lands.has(key), "automatic main generates actual logical land")
		var plan_: Dictionary = main.state_data.lands[key]
		var gate: Array = plan_.routes[0].points
		driver.points = []
		for point in gate:
			driver.points.append([float(point[0]), float(v.height + 1), float(point[1])])
		for i in range(gate.size() - 1, -1, -1):
			driver.points.append([float(gate[i][0]), float(v.height + 1), float(gate[i][1])])
		driver.index = 0
		driver.calls = 0
		driver.exhausted = false
		driver.died = false
		var start_calls: int = p.calls
		var elapsed: float = main.state_data.elapsed
		var shifts: int = main.frame.transactions
		driver.active = true
		await driver.done
		# done emits before this frame's actor callbacks; observe after their completed callback boundary.
		await process_frame
		check(
			not driver.exhausted and not driver.died,
			"real automatic town/gate/reversal route completes " + str(land)
		)
		check(
			p.calls > start_calls and main.state_data.elapsed > elapsed,
			"normal actor AND World clock callbacks enabled"
		)
		check(main.frame.transactions > shifts, "occupied live frame crossings occur")
		total_callbacks += p.calls - start_calls
		print(
			"automatic main land=",
			land,
			" route_callbacks=",
			driver.calls,
			" frame_transactions=",
			main.frame.transactions - shifts,
			" index=",
			driver.index,
			" position=",
			p.logical_position(),
			" goal=",
			driver.points[mini(driver.index, driver.points.size() - 1)]
		)
	# Connected logical records do not require a native view and have no four-member truncation.
	var members: Array = []
	for i in 6:
		members.append(
			{
				"logical_id": "member" + str(i),
				"level": i + 2,
				"class_id": ["warrior", "ranger", "mage", "rogue"][i % 4],
				"dead": i == 5,
				"position":
				[
					float(p.logical_position()[0]) + i,
					p.logical_position()[1],
					float(p.logical_position()[2]) + i
				],
				"stealth": 0.0,
				"view": null
			}
		)
	w.party_provider = func(): return members
	w.targeting.players = w.party_provider
	check(w.party_levels() == [2, 7], "party levels include every no-view/awaiting member")
	var site: Dictionary = main.state_data.sites.values()[0]
	var volume: Array = site.volumes[0]
	members[5].position = [volume[0], volume[1], volume[2]]
	site.pending = true
	main.state_data.advance(0, members.map(func(m): return m.position))
	check(site.pending, "no-view awaiting member on closed boundary protects occupancy")
	# A logical living target survives absence of its physical view; positive threat does not require detection.
	var mob = null
	for candidate in w.targeting.live.values():
		if not candidate.dead and candidate.hostility == &"H":
			mob = candidate
			break
	if mob != null:
		var r: Dictionary = w.targeting.record(mob)
		r.returning = false
		r.threat = {"member0": 4.0}
		r.order = {"member0": 0}
		r.next_order = 1
		var selected = w.targeting.select(mob)
		check(
			selected != null and Targeting.identity(selected) == "member0",
			"no-view logical threat target retained"
		)
		members[0].position = mob.logical_position()
		w.targeting.taunt([members[0]])
		w.targeting.flush_taunts()
		check(
			r.taunt == "member0" and r.taunt_left == 3.0,
			"scalar-only taunt reach and winner retained"
		)
	else:
		# Old neighborhood was legitimately retired; its surviving pair records are still logical members.
		check(not w.targeting.records.is_empty(), "retired-view logical pair records remain")
	w.party_provider = main.connected_party
	w.targeting.players = w.party_provider
	# Explicit fractional saved position/respawn, with no native movement allowed during serialization.
	main.set_physics_process(false)
	p.set_physics_process(false)
	w.set_process(false)
	w.set_physics_process(false)
	w.targeting.set_physics_process(false)
	var exact := [-8380416.123456789, 100.25, 8380416.234567891]
	main.relocate_player(exact)
	p.set_logical_respawn([8380416.345678913, 102.5, -8380416.456789123])
	for i in 20:
		main.frame.shift_to(
			[main.frame.origin[0] + (64 if i % 2 == 0 else -64), main.frame.origin[1]]
		)
	check(main.save_now(), "actual main fractional save " + str(main.save_data.errors))
	var loaded: Dictionary = main.save_data.load_file(path)
	check(
		loaded.world.characters[p.logical_id].position == exact,
		"exact fractional scalar save, not native reconstruction"
	)
	check(
		loaded.world.characters[p.logical_id].respawn == p.logical_respawn(),
		"independent fractional scalar respawn save"
	)
	check(
		(
			p.calls == p.frames.size()
			and (
				p.frames.size()
				== (
					p
					. frames
					. reduce(
						func(unique, frame):
							unique[frame] = true
							return unique,
						{}
					)
					. size()
				)
			)
		),
		"exactly one real player callback per native frame"
	)
	w.party_provider = main.connected_party
	w.targeting.players = w.party_provider
	print("fraction/provider assertions completed; retiring first main")
	driver.free()
	main.free()
	print("first main retired; cold restarting")
	var second = MAIN.instantiate()
	second.save_path = path
	root.add_child(second)
	var restored = second.get_node("Player")
	check(
		restored.logical_position() == exact,
		"actual main cold reload preserves all fractional coordinates"
	)
	check(
		restored.logical_respawn() == loaded.world.characters[restored.logical_id].respawn,
		"actual main cold reload preserves respawn"
	)
	second.free()
	print(
		(
			"local frame automatic runtime ok callbacks=" + str(total_callbacks)
			if not failed
			else "local frame automatic runtime FAILED " + str(failed)
		)
	)
	quit(0 if not failed else 1)
