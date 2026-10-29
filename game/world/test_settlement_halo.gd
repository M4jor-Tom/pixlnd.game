## Real hard-candidate obstacle halo; every building, selected wall and service capsule retained.
extends SceneTree
const Settlement = preload("res://game/world/settlement.gd")
const Model = preload("res://ontology/model.gd")
const WorldGen = preload("res://game/world/world_gen.gd")


class Frame:
	var ox: float
	var oz: float

	func to_local(p: Array) -> Vector3:
		return Vector3(float(p[0]) - ox, float(p[1]), float(p[2]) - oz)


var g
var centre := Vector2i(8380416, 8380416)
var height: int
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var ontology = Model.Ontology.load_dir("res://ontology/instances")
	var design: Dictionary = ontology.configs.generators.design
	g = WorldGen.new(1, design, ontology.landscapes)
	var land = g.land_at(Vector2i(511, 511))
	height = g._raw_height(centre.x, centre.y)
	var v: Dictionary = {
		"centre": centre,
		"height": height,
		"style": design.settlement["style-by-landscape"][str(land.landscape)],
		"gate_index": 6,
		"gate_width": 4
	}
	v.merge(Settlement.opening(design.settlement, 6, 4), true)
	var frame := Frame.new()
	frame.ox = centre.x
	frame.oz = centre.y
	var village = Settlement.build(v, design.settlement, ontology.configs["npc-roles"], frame)
	root.add_child(village)
	await physics_frame
	await physics_frame
	var space = village.get_world_3d().direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(4, 1.8, 4)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = box
	q.collision_mask = 1
	var obstacles: Dictionary = {}
	for z in range(-36, 37):
		for x in range(-36, 37):
			q.transform = Transform3D(Basis.IDENTITY, Vector3(x, height + 1.9, z))
			if not space.intersect_shape(q, 1).is_empty():
				obstacles[Vector2i(x, z)] = true
	var geometry := Settlement.obstacles(design.settlement, v)
	check(
		not Settlement.box_clear([0.0, -15.0], [1.0, 0.0], [2.0, 2.0], geometry),
		"other actual buildings remain blocked"
	)
	check(
		Settlement.box_clear([-17.0, -12.0], [1.0, 0.0], [2.0, 2.0], geometry),
		"lawful native after-house portal inside old disk"
	)
	check(obstacles.size() > 900, "complete actual settlement retains obstacle halo and NPCs")
	village.free()
	await process_frame
	print("HALO_DIAGNOSTIC_DONE height=", height, " no full-world verdict")
	quit(0 if failed == 0 else 1)
