## §3.1 world: one seed, zones streamed around `target` (gen-world neighbourhood, design.terrain.view-zones).
extends Node3D

const WorldGen := preload("res://game/world/world_gen.gd")
const ZoneMesh := preload("res://game/world/zone_mesh.gd")

@export var world_seed := 0             # 0 → design.terrain.seed-default (alpha server.cfg default)
var target: Node3D                      # set by main.gd: camera for now, the player-character once §3.2 lands

var gen: WorldGen
var zones := {}                         # Vector2i → MeshInstance3D
var _zone_blocks: int
var _view: int
var _land_mat := StandardMaterial3D.new()
var _water_mat := StandardMaterial3D.new()

func _ready() -> void:
	if world_seed == 0:
		world_seed = int(OntologyDB.design["terrain"]["seed-default"])
	gen = WorldGen.new(world_seed, OntologyDB.design, OntologyDB.data.landscapes)
	_zone_blocks = int(gen.terrain["zone-blocks"]); _view = int(gen.terrain["view-zones"])
	for m in [_land_mat, _water_mat]:
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true                       # palette hex codes are sRGB
	_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _process(_dt: float) -> void:
	if target == null:
		return
	var c := Vector2i(floori(target.global_position.x / _zone_blocks), floori(target.global_position.z / _zone_blocks))
	for zc in zones.keys():
		if maxi(absi(zc.x - c.x), absi(zc.y - c.y)) > _view + 1:
			zones[zc].queue_free(); zones.erase(zc)
	# ponytail: nearest ring first, ≤ 2 zones per frame on the main thread; thread it when it hitches
	var built := 0
	for r in _view + 1:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r or zones.has(c + Vector2i(dx, dy)):
					continue
				_spawn_zone(c + Vector2i(dx, dy))
				built += 1
				if built >= 2:
					return

func _spawn_zone(zc: Vector2i) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = ZoneMesh.build(gen, zc)
	mi.mesh.surface_set_material(0, _land_mat)
	if mi.mesh.get_surface_count() > 1:
		mi.mesh.surface_set_material(1, _water_mat)
	mi.position = Vector3(zc.x * _zone_blocks, 0, zc.y * _zone_blocks)
	var body := StaticBody3D.new()                        # land surface only (surface 0); water has no collision
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	var cs := CollisionShape3D.new(); cs.shape = shape
	body.add_child(cs); mi.add_child(body)
	add_child(mi)
	zones[zc] = mi

## True once the zone under `pos` is built (the player waits for it instead of falling through).
func has_ground(pos: Vector3) -> bool:
	return zones.has(Vector2i(floori(pos.x / _zone_blocks), floori(pos.z / _zone_blocks)))
