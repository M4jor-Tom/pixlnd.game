extends SceneTree
const Model := preload("res://ontology/model.gd")
const Gen := preload("res://game/world/world_gen.gd")
const ZoneMesh := preload("res://game/world/zone_mesh.gd")
const Spawner := preload("res://game/world/spawner.gd")
const World := preload("res://game/world/world.gd")
var failed := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1; printerr("FAIL: ", label)
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var design: Dictionary = o.configs["generators"]["design"]
	var g = Gen.new(26879, design, o.landscapes)
	check(g.land_at(Vector2i(-512, 511)) != null and g.land_at(Vector2i(511, -512)) != null, "literal corner lands")
	for p in [Vector2i(-513, 0), Vector2i(512, 0), Vector2i(0, -513), Vector2i(0, 512), Vector2i(-513, 512)]:
		check(g.land_at(p) == null and not g._lands.has(p), "invalid land rejected %s" % p)
	for p in [Vector2i(-8388608, 8388607), Vector2i(8388607, -8388608), Vector2i(-1, -1)]:
		check(g.land_of_block(p.x, p.y) != null, "inside block %s" % p)
	for p in [Vector2i(-8388609, 0), Vector2i(8388608, 0), Vector2i(0, -8388609), Vector2i(0, 8388608)]:
		check(g.land_of_block(p.x, p.y) == null, "outside block %s" % p)
	var cached_before: int = g._lands.size()
	for block in [70368744177664, -70368744177664, 9223372036854775807, -9223372036854775807]:
		check(g.land_of_block(block, 0) == null and g.land_of_block(0, block) == null,
			"large block rejected on both axes %s" % block)
	check(g._lands.size() == cached_before and not g._lands.has(Vector2i.ZERO), "large blocks did not cache or alias lands")
	var rosters: Dictionary = o.configs["creature-families"]["landscape-rosters"]
	for z in [Vector2i(-131072, -131072), Vector2i(131071, 131071), Vector2i(-131072, 131071), Vector2i(131071, -131072)]:
		var mesh := ZoneMesh.build(g, z)
		check(mesh.get_surface_count() > 0, "corner mesh %s" % z)
		for vertex in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			check(vertex.x >= 0 and vertex.x <= 64 and vertex.z >= 0 and vertex.z <= 64, "mesh footprint %s" % z)
		for group in Spawner.plan(g, z, design, o.creatures, rosters, 1):
			for pos in group.positions:
				check(pos.x >= -8388608 and pos.x < 8388608 and pos.z >= -8388608 and pos.z < 8388608, "spawn inside grid")
	for z in [Vector2i(-131073, 0), Vector2i(131072, 0), Vector2i(0, -131073), Vector2i(0, 131072)]:
		check(ZoneMesh.build(g, z).get_surface_count() == 0, "invalid mesh %s" % z)
		check(Spawner.plan(g, z, design, o.creatures, rosters, 1).is_empty(), "invalid plan %s" % z)
	for p in g._lands:
		check(p.x >= -512 and p.x <= 511 and p.y >= -512 and p.y <= 511, "cached land inside grid")
	var db := preload("res://game/ontology_db.gd").new()
	db.name = "OntologyDB"; root.add_child(db)
	var target := Node3D.new(); target.position = Vector3(8388607, 0, 8388607)
	root.add_child(target)
	var world = World.new()
	world.set_process(false); world.target = target; root.add_child(world)
	world.gen = g; world._zone_blocks = 64; world._view = 2
	world._stream_village()
	check(not world.has_ground(Vector3(8388608, 0, 8388607)), "outside ground unavailable")
	for i in 5: world._process(0.0)
	check(world.zones.size() > 0, "valid nearby zones progress")
	for z in world.zones:
		check(z.x <= 131071 and z.y <= 131071, "no invalid streamed zone")
	for outside in [Vector2i(8388608, 0), Vector2i(-8388609, 0), Vector2i(0, 8388608), Vector2i(0, -8388609)]:
		target.position = Vector3(outside.x, 0, outside.y)
		world._stream_village()
		check(not world.has_ground(target.position), "outside ground %s" % outside)
	for z in [Vector2i(131072, 0), Vector2i(-131073, 0), Vector2i(0, 131072), Vector2i(0, -131073)]:
		world._spawn_zone(z)
		check(not world.zones.has(z), "direct invalid spawn rejected %s" % z)
	var origin := MeshInstance3D.new(); world.add_child(origin)
	world.zones[Vector2i.ZERO] = origin
	var existing_zones: Array = world.zones.keys()
	for far in [Vector3(281474976710656, 0, 0), Vector3(-281474976710656, 0, 0),
		Vector3(0, 0, 281474976710656), Vector3(0, 0, -281474976710656)]:
		target.position = far
		world._process(0.0)
		check(not world.has_ground(far), "large target has no ground %s" % far)
		check(world.zones[Vector2i.ZERO] == origin, "large target did not alias streamed origin %s" % far)
		for z in world.zones:
			check(z in existing_zones, "large target did not create aliased zone %s" % z)
	world.free(); target.free(); db.free()
	print("world bounds ok" if failed == 0 else "world bounds FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
