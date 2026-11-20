## True-scale real-player travel regressions at the half-open world edges and corners.
extends SceneTree
const Domain := preload("res://game/domain/domain.gd")
const Combat := preload("res://game/combat/combat.gd")
const Spawner := preload("res://game/world/spawner.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const BoundaryCases := preload("res://game/world/world_travel_boundary_cases.gd")
const PLAYER := preload("res://game/entities/player.tscn")
var failed := 0
var design: Dictionary
var o


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func frames(count: int) -> void:
	for _i in count:
		await physics_frame


func make_player(
	class_id: StringName, spec_id: StringName = &"", points: Dictionary = {}
) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(1, 1.0))
	p.setup_items(o, design, class_id, spec_id)
	var edge := (
		-float(design["terrain"]["lands-per-axis"]) * float(design["terrain"]["land-blocks"]) / 2.0
	)
	p.world_min = Vector2(edge, edge)
	p.world_max = Vector2(-edge, -edge)
	for id in points:
		p.skill_tree.points[id] = points[id]
	return p


func floor_at(x: float, z: float, size := Vector2(16, 16)) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 1, size.y)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(x, -0.5, z)
	root.add_child(body)
	return body


func place(p: CharacterBody3D, position: Vector3) -> void:
	p.position = position
	p.velocity = Vector3.ZERO
	p._motion_remainder_x = 0.0
	p._motion_remainder_z = 0.0


func _init() -> void:
	await process_frame
	o = Domain.Ontology.load_dir()
	check(o.errors.is_empty(), "ontology valid")
	design = o.configs["generators"]["design"]
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var terrain: Dictionary = design["terrain"]
	var edge := -float(terrain["lands-per-axis"]) * float(terrain["land-blocks"]) / 2.0
	var p := make_player(&"warrior", &"berserker", {&"smash": 5, &"rock-fist": 1})
	var edge_floors: Array[StaticBody3D] = []
	if await _travel(p, edge, edge_floors):
		print("world travel paths ok" if failed == 0 else "world travel paths FAILED: %d" % failed)
		quit(0 if failed == 0 else 1)


func _tangent(p, edge) -> bool:
	# Tangent movement at an edge works, then remains stopped after input release.
	var tangent := Vector3(-edge - 0.5, 0, 0)
	floor_at(tangent.x, tangent.z)
	place(p, tangent)
	await frames(3)
	Input.action_press("move_forward")
	await frames(60)
	Input.action_release("move_forward")
	await frames(1)
	var tangent_stop := Vector2(p.position.x, p.position.z)
	check(
		(
			absf(tangent_stop.x - tangent.x) <= 0.01
			and absf(tangent_stop.y + float(design["movement"]["walk"])) < 1.0
		),
		"boundary tangent retains normal walk distance"
	)
	await frames(30)
	check(
		Vector2(p.position.x, p.position.z) == tangent_stop,
		"sub-ULP remainder is discarded when input stops"
	)
	return true


func _wall() -> bool:
	# Ordinary spawn-scale physical wall keeps native tangent sliding and cannot replay through it.
	var wall_player := make_player(&"warrior", &"berserker")
	var wall_start := Vector3(8192, 0, 8192)
	floor_at(wall_start.x, wall_start.z, Vector2(40, 40))
	place(wall_player, wall_start)
	await frames(3)
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(1, 4, 40)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(8194.5, 2, 8192)
	root.add_child(wall)
	Input.action_press("move_right")
	Input.action_press("move_forward")
	await frames(180)
	Input.action_release("move_right")
	Input.action_release("move_forward")
	await frames(1)
	var wall_stop := Vector2(wall_player.position.x, wall_player.position.z)
	check(
		wall_stop.x < wall.position.x and wall_stop.x > wall_start.x,
		"spawn-scale player collides with ordinary wall"
	)
	check(
		absf(wall_stop.y - wall_start.z) > 10.0,
		"spawn-scale wall collision preserves native tangent slide"
	)
	await frames(30)
	check(
		Vector2(wall_player.position.x, wall_player.position.z) == wall_stop,
		"ordinary-wall remainder cannot replay after release"
	)
	return true


func _respawn(edge) -> bool:
	# A real death/respawn clears any sub-ULP remainder instead of carrying it to spawn.
	var respawner := make_player(&"warrior", &"berserker")
	place(respawner, Vector3(-edge - 0.5, 0, 0))
	await frames(3)
	Input.action_press("move_left")
	await physics_frame
	Input.action_release("move_left")
	check(respawner._motion_remainder_x != 0.0, "true-scale input retained a sub-ULP remainder")
	var killer := Node3D.new()
	root.add_child(killer)
	respawner.hp = 1.0
	respawner.take_damage(2.0, killer)
	await create_timer(2.2, true, false, true).timeout
	check(
		(
			not respawner.dead
			and (
				Vector2(respawner.global_position.x, respawner.global_position.z)
				== Vector2(respawner.spawn_point.x, respawner.spawn_point.z)
			)
			and respawner._motion_remainder_x == 0.0
		),
		"respawn does not replay prior movement remainder"
	)
	return true


func _sprint(p, edge) -> bool:
	# Sprint at the edge retains its normal stamina drain.
	place(p, Vector3(edge + 0.5, 0, 0))
	await frames(3)
	var sprint_stamina: float = p.stamina
	Input.action_press("move_left")
	Input.action_press("sprint")
	await frames(60)
	Input.action_release("move_left")
	Input.action_release("sprint")
	check(
		p.position.x >= edge and p.position.x < -edge and sprint_stamina - p.stamina > 9.0,
		"blocked sprint remains bounded and pays ordinary stamina cost"
	)
	return true


func _air_water(p, edge) -> bool:
	# Airborne and swimming motion use the same horizontal guard.
	place(p, Vector3(-edge - 0.5, 0, 0))
	await frames(3)
	Input.action_press("move_left")
	Input.action_press("jump")
	await frames(25)
	Input.action_release("move_left")
	Input.action_release("jump")
	check(
		p.position.y > 0.5 and p.position.x <= -edge - 0.5,
		"airborne movement remains bounded while gravity/jump run"
	)
	p.water_top = 1000.0
	place(p, Vector3(edge + 0.5, 0, 0))
	await frames(3)
	Input.action_press("move_right")
	await frames(60)
	Input.action_release("move_right")
	check(p.position.x >= edge and p.position.x < -edge, "swimming movement remains in bounds")
	p.water_top = -INF
	return true


func _dodge_knockback(p, edge) -> bool:
	# Dodge and status knockback are already-committed travel; neither may cross or hurt at the edge.
	place(p, Vector3(-edge - 0.5, 0, 0))
	await frames(3)
	var hp_before: float = p.hp
	var stamina_before: float = p.stamina
	check(p.dodge(Vector3.RIGHT), "dodge request accepted before edge collision")
	await frames(30)
	check(
		p.position.x <= -edge - 0.5 and p.hp == hp_before and p.stamina < stamina_before,
		"outward dodge stops without edge damage and retains cost"
	)
	var source := Node3D.new()
	root.add_child(source)
	source.position = Vector3(-edge - 5, 0, 0)
	place(p, Vector3(-edge - 0.5, 0, 0))
	await frames(3)
	p.apply_status(&"knockback", design["status-effects"]["knockback"], 0.0, source)
	await frames(30)
	check(
		p.position.x <= -edge - 0.5 and p.hp == hp_before,
		"outward knockback remains bounded without special damage"
	)
	return true


func _damaging_dash(edge) -> bool:
	# A damaging active dash hits normally but terminates at the boundary.
	var rusher := make_player(&"warrior", &"berserker", {&"rock-fist": 1})
	var holder := Node3D.new()
	root.add_child(holder)
	var enemy_z: float = edge + 0.5
	var enemy = (
		Spawner
		. populate(
			holder,
			[
				{
					"species": &"wolf",
					"level": 1,
					"hostility": "H",
					"max_hp": 1000.0,
					"damage": 0.0,
					"positions": [Vector3(1.5, 0, enemy_z)],
					"seed": 701
				}
			],
			design,
			o.creatures,
			rusher,
			null
		)[0]
	)
	enemy.set_physics_process(false)  # real off-lane collider/strike target; the boundary, not an approaching actor, ends this dash
	floor_at(0, edge + 5)
	place(rusher, Vector3(0, 0, edge + 2.0))
	await frames(3)
	var enemy_hp: float = enemy.hp
	check(rusher.use_class_skill(4), "forward damaging dash starts")
	await frames(8)
	check(
		rusher.position.z >= edge and rusher.abilities.dash.is_empty(),
		"damaging dash stops at edge"
	)
	check(
		rusher.frame == null and rusher.position.z == edge,
		"frame-null damaging dash reaches exact representable minimum-z boundary"
	)
	check(
		enemy.hp < enemy_hp and rusher.hp == rusher.max_hp,
		"edge-stopped dash resolves its normal strike without edge damage"
	)
	return true


func _lunge(edge) -> bool:
	# Instant lunge route through the real special-attack / moveset consumer.
	var lunger := make_player(&"warrior", &"berserker")
	lunger.moveset = design["movesets"]["longsword"]
	floor_at(0, edge + 5)
	place(lunger, Vector3(0, 0, edge + 0.5))
	await frames(3)
	lunger.mp = 100
	lunger._special(100)
	check(
		lunger.position.z >= edge and lunger.mp == 0,
		"instant weapon lunge stays in bounds and keeps ordinary MP cost"
	)
	return true


func _teleports(edge) -> bool:
	# Current Teleport: all four outward headings stop without refund or cooldown changes.
	var mage := make_player(&"mage", &"fire-mage", {&"teleport": 5})
	for edge_case in [
		[Vector3(0, 0, edge + 0.5), 0.0, "min-z"],
		[Vector3(0, 0, -edge - 0.5), PI, "max-z"],
		[Vector3(edge + 0.5, 0, 0), PI / 2.0, "min-x"],
		[Vector3(-edge - 0.5, 0, 0), -PI / 2.0, "max-x"]
	]:
		if not await _teleport_case(mage, edge, edge_case):
			return false
	return true


func _teleport_case(mage, edge, edge_case) -> bool:
	var pos: Vector3 = edge_case[0]
	floor_at(pos.x + (5.0 if pos.x != 0 else 0.0), pos.z + (5.0 if pos.z != 0 else 0.0))
	place(mage, pos)
	mage.get_node("CameraRig").rotation.y = edge_case[1]
	mage.mp = 100.0
	mage.abilities.cooldowns.erase(&"teleport")
	await frames(3)
	check(mage.use_class_skill(3), "%s Teleport cast" % edge_case[2])
	var expected_cooldown: float = 10.0 * mage.skill_tree.cooldown_mult(&"teleport")
	check(
		mage.mp == 0 and is_equal_approx(mage.abilities.cooldowns[&"teleport"], expected_cooldown),
		"%s Teleport retains MP cost and cooldown" % edge_case[2]
	)
	await frames(8)
	if not _teleport_bounds(mage, edge, edge_case):
		return false
	check(
		mage.mp < 1.0 and mage.abilities.cooldowns[&"teleport"] > expected_cooldown - 0.5,
		"%s edge stop does not refund or clear costs" % edge_case[2]
	)
	return true


func _inward_teleports(edge) -> bool:
	var inward := make_player(&"mage", &"fire-mage", {&"teleport": 5})
	inward.mp = 100
	var inward_start := Vector3(-edge - 20.5, 0, 0)
	floor_at(inward_start.x - 10.0, 0, Vector2(50, 50))
	place(inward, inward_start)
	inward.get_node("CameraRig").rotation.y = PI / 2.0
	await frames(3)
	check(inward.use_class_skill(3), "near-limit inward Teleport casts")
	await frames(60)
	check(
		(
			absf(absf(inward.global_position.x - inward_start.x) - 20.0) < 0.1
			and inward.abilities.dash.is_empty()
		),
		"near-limit inward Teleport retains its full 20-block distance"
	)
	var inside := make_player(&"mage", &"fire-mage", {&"teleport": 5})
	inside.mp = 100
	floor_at(0, 0)
	place(inside, Vector3(0, 0, 0))
	await frames(3)
	check(inside.use_class_skill(3), "interior Teleport casts")
	await frames(60)
	check(
		absf(inside.position.z + 20.0) < 0.1 and inside.abilities.dash.is_empty(),
		"interior Teleport retains 20-block dash"
	)
	return true


func _teleport_bounds(mage, edge, edge_case) -> bool:
	var actual = (
		mage.position.x >= edge
		and mage.position.x < -edge
		and mage.position.z >= edge
		and mage.position.z < -edge
		and mage.abilities.dash.is_empty()
	)
	check(actual, "%s outward Teleport stops inside world" % edge_case[2])
	return true


func _travel(p, edge, edge_floors) -> bool:
	if not await BoundaryCases.edges(self, p, edge, edge_floors):
		return false
	# Give each boundary fixture an independent player/floor and a settled physics transform.
	p.queue_free()
	for body in edge_floors:
		body.queue_free()
	await frames(2)
	if not await BoundaryCases.corners(self, edge):
		return false
	p = make_player(&"warrior", &"berserker")
	return await _physical_paths(p, edge) and await _committed_paths(p, edge)


func _physical_paths(p, edge) -> bool:
	return (
		await _tangent(p, edge)
		and await _wall()
		and await _respawn(edge)
		and await _sprint(p, edge)
		and await _air_water(p, edge)
	)


func _committed_paths(p, edge) -> bool:
	return (
		await _dodge_knockback(p, edge)
		and await _damaging_dash(edge)
		and await _lunge(edge)
		and await _teleports(edge)
		and await _inward_teleports(edge)
	)


func _edge_inward(p, edge, edge_case, pos) -> bool:
	place(p, pos)
	await frames(3)
	Input.action_press(edge_case[2])
	await frames(60)
	Input.action_release(edge_case[2])
	var progressed := absf(p.position.x - pos.x) + absf(p.position.z - pos.z)
	check(
		absf(progressed - float(design["movement"]["walk"])) < 1.0,
		"%s inward turn preserves ordinary 60Hz walk distance" % edge_case[3]
	)
	if not BoundaryCases._inward_edge_bounds(self, p, edge, edge_case):
		return false
	return true


func _corner_inward(edge, corner_case, corner, corner_floor, corner_player) -> bool:
	corner_player.queue_free()
	await frames(2)
	var return_player: CharacterBody3D = make_player(&"warrior", &"berserker")
	place(return_player, corner)
	await frames(3)
	Input.action_press(corner_case[3])
	Input.action_press(corner_case[4])
	await frames(60)
	Input.action_release(corner_case[3])
	Input.action_release(corner_case[4])
	var expected_axis := float(design["movement"]["walk"]) / sqrt(2.0)
	check(
		(
			absf(absf(return_player.position.x - corner.x) - expected_axis) < 0.75
			and absf(absf(return_player.position.z - corner.z) - expected_axis) < 0.75
		),
		"%s corner inward turn preserves normalized 60Hz movement" % corner_case[5]
	)
	if not BoundaryCases._corner_inward_bounds(self, return_player, edge, corner_case):
		return false
	return_player.queue_free()
	corner_floor.queue_free()
	await frames(2)
	return true
