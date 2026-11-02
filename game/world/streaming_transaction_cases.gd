## Literal streaming chronology and origin-last witnesses, independent of extraction helpers.
extends RefCounted
const World := preload("res://game/world/world.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
const Frame := preload("res://game/world/local_frame.gd")


class Target:
	extends Node3D

	func logical_position() -> Array:
		return [8192.0, 100.0, 8192.0]


class Worker:
	extends RefCounted
	var events: Array
	var packets: Array = []

	func poll() -> Array:
		events.append("poll")
		var out := packets
		packets = []
		return out

	func request(zone: Vector2i, epoch: int, guides: bool) -> Error:
		events.append(["request", zone, epoch, guides])
		return ERR_BUSY

	func stop() -> void:
		pass


class ObservedWorld:
	extends World
	var events: Array = []

	func ensure_land(_land) -> bool:
		events.append("ensure")
		return true

	func populate_zone(zone: Vector2i) -> void:
		events.append(["populate", zone])

	func capture_mobs() -> void:
		events.append("capture")

	func _stream_village() -> void:
		events.append("village")

	func stream_sites() -> void:
		events.append("sites")

	func _publish_zone(zone: Vector2i, _surfaces: Array) -> void:
		events.append(["terrain", zone, Thread.is_main_thread()])
		var view := Node3D.new()
		add_child(view)
		zones[zone] = view


class Witness:
	extends CharacterBody3D
	var frame
	var observations: Array = []
	var _native_sample: Vector3:
		set(value):
			observations.append([frame.origin.duplicate(), value, global_position])

	func logical_position() -> Array:
		observations.append(["capture", frame.origin.duplicate(), global_position])
		return [0.0, 0.0, 0.0]


static func run(test, ontology) -> void:
	_stream_order(test, ontology)
	_epoch_and_deferral(test, ontology)
	_origin_last(test)


static func _world(test, ontology):
	var world := ObservedWorld.new()
	test.root.add_child(world)
	world.set_process(false)
	world._zone_blocks = 64
	world._view = 1
	world.gen = WorldGen.new(3, ontology.configs.generators.design, ontology.landscapes)
	world.state_data = {"mobs": {}, "sites": {}, "lands": {}}
	var target := Target.new()
	world.add_child(target)
	world.target = target
	var worker := Worker.new()
	worker.events = world.events
	world._terrain_worker = worker
	return world


static func _stream_order(test, ontology) -> void:
	var world = _world(test, ontology)
	var centre := Vector2i(128, 128)
	for zone in [centre, Vector2i(132, 128)]:
		var view := Node3D.new()
		world.add_child(view)
		world.zones[zone] = view
	world.state_changed.connect(func(): world.events.append("changed"))
	world._pending_ambient[centre] = true
	world.state_data.mobs["world/ambient/128,128/0/0"] = {"dead": true, "eligible": true}
	world._process(0)
	test.check(
		(
			world.events
			== [
				"poll",
				"capture",
				"changed",
				["populate", centre],
				"ensure",
				"village",
				"sites",
				"ensure",
				["request", Vector2i(127, 127), 0, true]
			]
		),
		"literal poll-retire-retry-land-village-sites-nearest-request chronology"
	)
	test.check(world.zones.keys() == [centre], "retirement uses view plus one before requests")
	world.free()


static func _epoch_and_deferral(test, ontology) -> void:
	var world = _world(test, ontology)
	var zone := Vector2i(128, 128)
	world._terrain_worker.packets = [
		{"kind": "terrain", "zone": zone, "epoch": 0, "surfaces": []},
		{
			"kind": "guidance",
			"zone": zone,
			"epoch": 0,
			"land": "0,0",
			"error": "",
			"routes": [{"markers": []}]
		},
		{"kind": "terrain", "zone": Vector2i(129, 128), "epoch": -1, "surfaces": []},
		{"kind": "terrain", "zone": Vector2i(131, 128), "epoch": 0, "surfaces": []}
	]
	world._poll_terrain()
	test.check(
		world.events == ["poll", ["terrain", zone, true]],
		"main-thread terrain rejects stale epoch and out-of-range packets"
	)
	test.check(
		world.guidance.is_empty() and world._pending_guidance.size() == 1,
		"guidance waits a separate polling frame after terrain"
	)
	world._poll_terrain()
	test.check(
		world.guidance == {"0,0": [{"markers": []}]}, "next poll publishes exact deferred guidance"
	)
	world._pending_guidance.append({"epoch": 0, "kind": "guidance"})
	world.retire_views()
	world._poll_terrain()
	test.check(
		world._terrain_epoch == 1 and world._pending_guidance.is_empty(),
		"retirement epoch rejects deferred stale guidance before reading its payload"
	)
	world.free()


static func _origin_last(test) -> void:
	var frame := Frame.new(64)
	var parent := Node3D.new()
	test.root.add_child(parent)
	var body := Witness.new()
	parent.add_child(body)
	body.frame = frame
	body.position = Vector3(2, 3, 4)
	frame.track(parent)
	frame.track(body)
	frame.shift_to([64, -64])
	test.check(
		(
			body.observations
			== [
				["capture", [0, 0], Vector3(2, 3, 4)],
				[[0, 0], Vector3(-62, 3, 68), Vector3(-62, 3, 68)]
			]
		),
		"capture and final native-sample write observe old origin; nested root translated once"
	)
	test.check(
		frame.origin == [64, -64] and frame.transactions == 1,
		"origin and transaction publish only after native restoration"
	)
	frame.shift_to([64, -64])
	test.check(
		frame.transactions == 1 and body.observations.size() == 2,
		"equal-origin transaction performs no capture or restoration"
	)
	parent.free()
