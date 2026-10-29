## One private terrain sampler, one bounded zone job at a time; only plain data crosses threads.
## Guidance measured ~2ms for a land, so it shares this worker, after terrain publication.
extends RefCounted
const Model := preload("res://ontology/model.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
const ZoneMesh := preload("res://game/world/zone_mesh.gd")
const Encounters := preload("res://game/world/encounter_gen.gd")
var _gen
var _thread := Thread.new()
var _mutex := Mutex.new()
var _packets: Array = []


func _init(seed_: int, design: Dictionary, landscapes: Dictionary, saved: Dictionary) -> void:
	var private_landscapes := {}
	for id in landscapes:
		var landscape := Model.Landscape.new()
		landscape.gen = landscapes[id].gen.duplicate(true)
		private_landscapes[id] = landscape
	_gen = WorldGen.new(seed_, design.duplicate(true), private_landscapes)
	_gen.saved_lands = saved.duplicate(true)


func request(zc: Vector2i, epoch: int, with_guidance: bool) -> Error:
	if _thread.is_started():
		return ERR_BUSY
	return _thread.start(_run.bind(zc, epoch, with_guidance))


func _publish(packet: Dictionary) -> void:
	_mutex.lock()
	_packets.append(packet)
	_mutex.unlock()


func _run(zc: Vector2i, epoch: int, with_guidance: bool) -> void:
	var surfaces := ZoneMesh.data(_gen, zc)
	_publish({"kind": "terrain", "zone": zc, "epoch": epoch, "surfaces": surfaces})
	var land = _gen.land_of_block(zc.x * _gen.cell_blocks, zc.y * _gen.cell_blocks)
	var key := "%d,%d" % [land.coords.x, land.coords.y]
	if not with_guidance:
		return
	var plan_: Dictionary = _gen.encounters_at(land)
	if plan_.is_empty():
		return
	var result := _guidance(plan_)
	_publish(
		{
			"kind": "guidance",
			"zone": zc,
			"epoch": epoch,
			"land": key,
			"routes": result.get("routes", []),
			"error": result.get("error", "")
		}
	)


func _guidance(plan_: Dictionary) -> Dictionary:
	return {"routes": Encounters.guidance(_gen, plan_, _gen.encounter_config)}


func poll() -> Array:
	_mutex.lock()
	var packets := _packets
	_packets = []
	_mutex.unlock()
	if _thread.is_started() and not _thread.is_alive():
		_thread.wait_to_finish()
	return packets


func stop() -> void:
	# Shutdown only, never ordinary UI polling. A job is one bounded zone, not a whole network.
	if _thread.is_started():
		_thread.wait_to_finish()
