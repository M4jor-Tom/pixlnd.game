## Independent nominal diagonal strip: continuous box clearance and ordinary player capsule, including corners.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const Settlement := preload("res://game/world/settlement.gd")
const InputBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")
var failed := 0


class Frame:
	var centre: Vector2i

	func to_local(p: Array) -> Vector3:
		return Vector3(float(p[0]) - centre.x, p[1], float(p[2]) - centre.y)


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var d: Dictionary = o.configs.generators.design
	InputBuilder.build(o.configs.keybinds.hybrid)
	# Literal house6 direction; never derive expected strip from layout or recorded raster cells.
	var u := Vector2(-0.8090169943749475, -0.5877852522924731)
	for centre in [
		Vector2i.ZERO,
		Vector2i(-8380416, -8380416),
		Vector2i(-8380416, 8380416),
		Vector2i(8380416, -8380416),
		Vector2i(8380416, 8380416)
	]:
		var v := {
			"centre": centre, "height": 100, "style": "undead", "gate_index": 6, "gate_width": 4
		}
		var b: Dictionary = Settlement.layout(v, d.settlement)[6]
		# Opening is centred on the square's nominal radial line, with unchanged five-wide house.
		v.gate_offset = -0.1106158710412371
		var frame := Frame.new()
		frame.centre = centre
		var village := Settlement.build(v, d.settlement, o.configs["npc-roles"], frame)
		root.add_child(village)
		await physics_frame
		await physics_frame
		var space := village.get_world_3d().direct_space_state
		var box := BoxShape3D.new()
		box.size = Vector3(4, 1.8, 24)
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = box
		q.transform = Transform3D(
			Basis(Vector3.UP, atan2(u.x, u.y)), Vector3(u.x * 12, 101.9, u.y * 12)
		)
		# A solid four-wide query touches the two door boundaries (native contact is not penetration).
		# Prove those selected intervals analytically, then query the entire strip against EVERY other collider.
		var model: Dictionary = Settlement.local_layout(d.settlement)[6]
		check(
			(
				absf(model.centre[0] + 11.6352549156242) < 0.00000001
				and absf(model.centre[1] + 8.3167787843871) < 0.00000001
			),
			"nominal ring15 offsets, not global rounding"
		)
		var intervals := Settlement.walls(model, true, 4, v.gate_offset)
		check(
			(
				intervals.size() == 2
				and is_equal_approx(intervals[0][1], 0.3893841289587629)
				and is_equal_approx(intervals[1][1], 0.6106158710412371)
			),
			"literal remaining five-wide house walls preserve exact four-wide cut"
		)
		check(
			(
				is_equal_approx(intervals[0][0] + intervals[0][1] / 2, -2.1106158710412371)
				and is_equal_approx(intervals[1][0] - intervals[1][1] / 2, 1.8893841289587629)
			),
			"full continuous strip boundaries coincide with wall interval boundaries"
		)
		var selected: Array[RID] = []
		for wall in (
			village
			. get_children()
			. filter(func(child): return child is MeshInstance3D)[6]
			. get_children()
		):
			if wall is MeshInstance3D and wall.mesh is BoxMesh:
				selected.append(wall.get_child(0).get_rid())
		q.exclude = selected
		check(
			space.intersect_shape(q).is_empty(),
			"entire four-wide strip clear of all other buildings and NPCs at " + str(centre)
		)
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.4
		capsule.height = 1.8
		var near_edge := PhysicsShapeQueryParameters3D.new()
		near_edge.shape = capsule
		for side in [-1.59, 1.59]:
			var start: Vector2 = u * 6 + Vector2(-u.y, u.x) * side
			near_edge.transform = Transform3D(Basis.IDENTITY, Vector3(start.x, 101.9, start.y))
			near_edge.motion = Vector3(u.x * 18, 0, u.y * 18)
			check(
				(
					space.intersect_shape(near_edge).is_empty()
					and space.cast_motion(near_edge)[0] == 1
				),
				"actual normal player capsule near each unchanged opening edge"
			)
		# This touched raster cell is not inside the strip: lateral distance 2.455, not <2.
		var hit := space.intersect_ray(
			PhysicsRayQueryParameters3D.create(
				Vector3(-14.5, 110, -7.5), Vector3(-14.5, 101.01, -7.5)
			)
		)
		check(not hit.is_empty(), "real wall outside strip retained, not removed to certify cells")
		var services := 0
		for child in village.get_children():
			if child is StaticBody3D:
				services += 1
		check(
			services == 5 and village.get_child_count() == 15,
			"all buildings and service NPCs remain"
		)
		# No narrower lane, controller/margin/step edits, or teleport during the traversal.
		var floor_ := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var ground := BoxShape3D.new()
		ground.size = Vector3(80, 1, 80)
		cs.shape = ground
		floor_.position.y = 100.5
		floor_.add_child(cs)
		root.add_child(floor_)
		var p = PLAYER.instantiate()
		root.add_child(p)
		p.setup(d.movement, d.camera, &"normal")
		p.position = Vector3(0, 101.05, 0)
		p.get_node("CameraRig").rotation.y = atan2(-u.x, -u.y)
		await physics_frame
		Input.action_press("move_forward")
		for n in 260:
			await physics_frame
			if Vector2(p.position.x, p.position.z).dot(u) >= 25:
				break
		Input.action_release("move_forward")
		check(
			Vector2(p.position.x, p.position.z).dot(u) >= 25,
			"real ordinary capsule traverses diagonal door at " + str(centre)
		)
		print("opening centre=", centre, " capsule=", p.position, " nominal house6=", b)
		p.free()
		floor_.free()
		village.free()
		await physics_frame
	print("settlement opening ok" if failed == 0 else "settlement opening FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
