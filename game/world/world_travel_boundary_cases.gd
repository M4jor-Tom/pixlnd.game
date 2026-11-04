## True-scale edge/corner fixture phases; the owning test retains shared player/input/check state.
extends RefCounted


static func edges(t, p, edge, edge_floors) -> bool:
	for edge_case in [
		[Vector3(edge + 0.5, 0, 0), "move_left", "move_right", "min-x"],
		[Vector3(-edge - 0.5, 0, 0), "move_right", "move_left", "max-x"],
		[Vector3(0, 0, edge + 0.5), "move_forward", "move_back", "min-z"],
		[Vector3(0, 0, -edge - 0.5), "move_back", "move_forward", "max-z"]
	]:
		if not await _edge_case(t, p, edge, edge_floors, edge_case):
			return false
	return true


static func _edge_case(t, p, edge, edge_floors, edge_case) -> bool:
	var pos: Vector3 = edge_case[0]
	return (
		await _edge_outward(t, p, edge, edge_floors, edge_case, pos)
		and await t._edge_inward(p, edge, edge_case, pos)
	)


static func corners(t, edge) -> bool:
	for corner_case in [
		[
			Vector3(edge + 0.5, 0, edge + 0.5),
			"move_left",
			"move_forward",
			"move_right",
			"move_back",
			"min/min"
		],
		[
			Vector3(edge + 0.5, 0, -edge - 0.5),
			"move_left",
			"move_back",
			"move_right",
			"move_forward",
			"min/max"
		],
		[
			Vector3(-edge - 0.5, 0, edge + 0.5),
			"move_right",
			"move_forward",
			"move_left",
			"move_back",
			"max/min"
		],
		[
			Vector3(-edge - 0.5, 0, -edge - 0.5),
			"move_right",
			"move_back",
			"move_left",
			"move_forward",
			"max/max"
		]
	]:
		if not await _corner_case(t, edge, corner_case):
			return false
	return true


static func _corner_case(t, edge, corner_case) -> bool:
	var corner: Vector3 = corner_case[0]
	var floor_offset := Vector3(-10 if corner.x > 0.0 else 10, 0, -10 if corner.z > 0.0 else 10)
	var corner_floor: StaticBody3D = t.floor_at(
		corner.x + floor_offset.x, corner.z + floor_offset.z, Vector2(40, 40)
	)
	var corner_player: CharacterBody3D = t.make_player(&"warrior", &"berserker")
	t.place(corner_player, corner)
	return await _corner_outward(t, edge, corner_case, corner, corner_floor, corner_player)


static func _corner_outward(t, edge, corner_case, corner, corner_floor, corner_player) -> bool:
	await t.frames(3)
	Input.action_press(corner_case[1])
	Input.action_press(corner_case[2])
	await t.frames(60)
	Input.action_release(corner_case[1])
	Input.action_release(corner_case[2])
	var stop_x: float = edge if corner.x < 0.0 else -edge - 0.5
	var stop_z: float = edge if corner.z < 0.0 else -edge - 0.5
	if not _corner_outward_bounds(t, corner_player, edge, corner_case):
		return false
	t.check(
		(
			absf(corner_player.position.x - stop_x) <= 0.01
			and absf(corner_player.position.z - stop_z) <= 0.01
		),
		"%s corner outward diagonal stops within 0.01 block of exact boundary" % corner_case[5]
	)
	return await t._corner_inward(edge, corner_case, corner, corner_floor, corner_player)


static func _edge_outward(t, p, edge, edge_floors, edge_case, pos) -> bool:
	edge_floors.append(t.floor_at(pos.x, pos.z))
	t.place(p, pos)
	await t.frames(3)
	var hp_before: float = p.hp
	Input.action_press(edge_case[1])
	await t.frames(60)
	Input.action_release(edge_case[1])
	if not _outward_edge_bounds(t, p, edge, edge_case):
		return false
	t.check(
		p.hp == hp_before and not p.dead, "%s edge causes no special damage/death" % edge_case[3]
	)
	return true


static func _outward_edge_bounds(t, p, edge, edge_case) -> bool:
	t.check(
		(
			p.position.x >= edge
			and p.position.x < -edge
			and p.position.z >= edge
			and p.position.z < -edge
		),
		"%s outward walk remains inside bounds" % edge_case[3]
	)
	return true


static func _inward_edge_bounds(t, p, edge, edge_case) -> bool:
	t.check(
		(
			p.position.x >= edge
			and p.position.x < -edge
			and p.position.z >= edge
			and p.position.z < -edge
		),
		"%s inward walk stays in bounds" % edge_case[3]
	)
	return true


static func _corner_outward_bounds(t, corner_player, edge, corner_case) -> bool:
	t.check(
		(
			corner_player.position.x >= edge
			and corner_player.position.x < -edge
			and corner_player.position.z >= edge
			and corner_player.position.z < -edge
		),
		"%s corner outward diagonal remains within half-open bounds" % corner_case[5]
	)
	return true


static func _corner_inward_bounds(t, return_player, edge, corner_case) -> bool:
	t.check(
		(
			return_player.position.x >= edge
			and return_player.position.x < -edge
			and return_player.position.z >= edge
			and return_player.position.z < -edge
		),
		"%s corner inward movement remains in bounds" % corner_case[5]
	)
	return true
