## Transient native frame. Logical points are scalar arrays; no origin enters saved-world data.
extends RefCounted

var origin := [0, 0]
var zone_blocks: int
var roots: Array = []
var transactions := 0


func _init(zone: int) -> void:
	zone_blocks = zone


static func point(v: Vector3) -> Array:
	return [float(v.x), float(v.y), float(v.z)]


static func offset(a: Array, b: Array) -> Vector3:
	return Vector3(float(a[0]) - float(b[0]), float(a[1]) - float(b[1]), float(a[2]) - float(b[2]))


func to_local(p: Array) -> Vector3:
	return Vector3(float(p[0]) - origin[0], float(p[1]), float(p[2]) - origin[1])


func to_logical(p: Vector3) -> Array:
	return [float(origin[0]) + float(p.x), float(p.y), float(origin[1]) + float(p.z)]


func set_origin(p: Array) -> void:
	origin = [
		floori(float(p[0]) / zone_blocks) * zone_blocks,
		floori(float(p[2]) / zone_blocks) * zone_blocks
	]


func track(node: Node3D) -> void:
	node.set_meta("local_frame", self)
	if not roots.has(node):
		roots.append(node)


func place_entity(entity, p: Array, initialize: bool = false) -> void:
	entity.frame = self
	entity._logical_anchor = p.duplicate()
	entity.global_position = to_local(p)
	entity._native_sample = entity.global_position
	track(entity)
	entity.force_update_transform()
	if initialize:
		# Explicit owner-directed placement, not native travel from the scene's previous/default pose.
		var rid: RID = entity.get_rid()
		assert(PhysicsServer3D.body_get_mode(rid) == PhysicsServer3D.BODY_MODE_KINEMATIC)
		PhysicsServer3D.body_set_mode(rid, PhysicsServer3D.BODY_MODE_RIGID)
		PhysicsServer3D.body_set_mode(rid, PhysicsServer3D.BODY_MODE_KINEMATIC)
		PhysicsServer3D.body_set_state(
			rid, PhysicsServer3D.BODY_STATE_TRANSFORM, entity.global_transform
		)
		var state = PhysicsServer3D.body_get_direct_state(rid)
		state.linear_velocity = entity.velocity
		state.angular_velocity = Vector3.ZERO
		entity.reset_physics_interpolation()


func prepare(target) -> void:
	var p: Array = target.logical_position()
	shift_to(
		[
			floori(float(p[0]) / zone_blocks) * zone_blocks,
			floori(float(p[2]) / zone_blocks) * zone_blocks
		]
	)


func _collect(node: Node, bodies: Array, areas: Array, entities: Array) -> void:
	if node is PhysicsBody3D:
		bodies.append(node)
	if node is Area3D:
		areas.append(node)
	if node.has_method("logical_position") and node.get("frame") == self:
		node.logical_position()
		entities.append(node)
	for child in node.get_children():
		_collect(child, bodies, areas, entities)


func shift_to(next: Array) -> void:
	if next == origin:
		return
	var active: Array = []
	roots = roots.filter(func(n): return is_instance_valid(n) and n.is_inside_tree())
	for node in roots:
		if not roots.any(func(other): return other != node and other.is_ancestor_of(node)):
			active.append(node)
	var bodies: Array = []
	var areas: Array = []
	var entities: Array = []
	for node in active:
		_collect(node, bodies, areas, entities)
	var saved: Array = []
	for body in bodies:
		var rid: RID = body.get_rid()
		var mode := PhysicsServer3D.body_get_mode(rid)
		assert(
			mode in [PhysicsServer3D.BODY_MODE_STATIC, PhysicsServer3D.BODY_MODE_KINEMATIC],
			"unsupported body mode in active frame"
		)
		var state = PhysicsServer3D.body_get_direct_state(rid)
		saved.append(
			{
				"rid": rid,
				"mode": mode,
				"C": PhysicsServer3D.body_get_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM),
				"T": body.global_transform,
				"linear": state.linear_velocity,
				"angular": state.angular_velocity,
				"sleeping": state.sleeping
			}
		)
	var delta := Vector3(float(origin[0]) - next[0], 0, float(origin[1]) - next[1])
	for node in active:
		node.position += delta
		node.reset_physics_interpolation()
	for area in areas:
		area.force_update_transform()
	for body in bodies:
		body.force_update_transform()
	for s in saved:
		var target: Transform3D = s.T.translated(delta)
		if s.mode == PhysicsServer3D.BODY_MODE_KINEMATIC:
			PhysicsServer3D.body_set_mode(s.rid, PhysicsServer3D.BODY_MODE_RIGID)
			PhysicsServer3D.body_set_mode(s.rid, PhysicsServer3D.BODY_MODE_KINEMATIC)
			var committed: Transform3D = s.C.translated(delta)
			PhysicsServer3D.body_set_state(s.rid, PhysicsServer3D.BODY_STATE_TRANSFORM, committed)
			if committed != target:
				PhysicsServer3D.body_set_state(s.rid, PhysicsServer3D.BODY_STATE_TRANSFORM, target)
			var state = PhysicsServer3D.body_get_direct_state(s.rid)
			state.linear_velocity = s.linear
			state.angular_velocity = s.angular
			state.sleeping = s.sleeping
		else:
			PhysicsServer3D.body_set_state(s.rid, PhysicsServer3D.BODY_STATE_TRANSFORM, target)
	for entity in entities:
		entity._native_sample = entity.global_position
	origin = next.duplicate()
	transactions += 1
