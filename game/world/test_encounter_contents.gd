extends SceneTree
const Lifecycle := preload("res://game/world/encounter_contents_lifecycle_cases.gd")
const MAIN := preload("res://game/main.tscn")
const DB := preload("res://game/ontology_db.gd")
const Save := preload("res://game/world/save_data.gd")
const Gen := preload("res://game/world/encounter_gen.gd")
const Projectile := preload("res://game/combat/projectile.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const Combat := preload("res://game/combat/combat.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func stop(main) -> void:
	main.set_physics_process(false)
	var w = main.get_node("World")
	w.set_process(false)
	w.set_physics_process(false)
	w.targeting.set_physics_process(false)
	main.get_node("Player").set_physics_process(false)
	for mob in w.targeting.live.values():
		mob.set_physics_process(false)


func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		printerr("PIXLND_TEST_DIR required")
		quit(1)
		return
	if not root.has_node("OntologyDB"):
		var db := DB.new()
		db.name = "OntologyDB"
		root.add_child(db)
	var main = MAIN.instantiate()
	main.save_path = directory.path_join("contents.json")
	DirAccess.remove_absolute(main.save_path)
	root.add_child(main)
	await _run_main(main)


func _props(w, p, d: Dictionary, site: Dictionary, contents) -> String:
	var ground_count := get_nodes_in_group("ground-items").size()
	check(ground_count == 6, "intact tables initially issue six independent loose pickups")
	_table_height(contents)
	var key: String = contents.props.keys()[0]
	var prop = contents.props[key]
	var before_combo: int = p.combo
	var before_mp: float = p.mp
	p.combo = 4
	p.mp = 0
	p._strike(prop.global_position, 0.6, 1.0, true, [&"stun", &"burning"])
	check(
		site.contents.props[key].hp < 10 and site.contents.props[key].hp > 0,
		"real player direct attack damages vase"
	)
	check(p.combo == 4 and p.mp == 0, "prop strike grants no combo/MP")
	check(
		not prop.has_method("take_damage") and not prop.has_method("apply_status"),
		"props excluded from DOT/status path"
	)
	p.combo = before_combo
	p.mp = before_mp
	var table_key := "room/0/table/0"
	contents.props[table_key].take_direct_damage(1000, p)
	check(
		get_nodes_in_group("ground-items").size() == ground_count, "table break does not issue pair"
	)
	await _projectile_props(w, p, d, site, contents)
	await _table_pickups(p, contents)
	return table_key


func _trap_defences(w, p, d: Dictionary, site: Dictionary, contents, main) -> Dictionary:
	var trap: Dictionary = contents.plan.traps[0]
	p.set_logical_position(trap.point)
	p.hp = p.max_hp
	p.armor = 0
	p.resistance = 10000
	p._iframes = 5
	p.blocking = true
	var hp: float = p.hp
	var power: float = p.block_power
	var mp: float = p.mp
	contents.advance(0.8)
	check(
		is_equal_approx(hp - p.hp, 30),
		"warning boundary activates physical spikes bypassing dodge/block/resistance"
	)
	check(p.block_power == power and p.mp == mp, "spikes grant/spend no block resources")
	contents.advance(0.1)
	check(p.hp == hp - 30, "one trap hit per activation")
	check(site.contents.traps[0].phase == "active", "trap phase persists")
	for point in [
		[trap.point[0] - 1, trap.point[1], trap.point[2] - 1],
		[trap.point[0] + 1, trap.point[1] + 1, trap.point[2] + 1]
	]:
		p.set_logical_position(point)
		check(contents.eligible(trap, p), "closed footprint corners/height")
	p.set_logical_position([trap.point[0] + 1.001, trap.point[1], trap.point[2]])
	check(not contents.eligible(trap, p), "outside trap footprint safe")
	var other = PLAYER.instantiate()
	root.add_child(other)
	other.setup(d.movement, d.camera, &"normal")
	other.setup_combat(d.combat, d.crit, {}, 268)
	other.setup_items(w.ontology, d, &"warrior")
	other.logical_id = "second-connected"
	other.set_physics_process(false)
	other.set_logical_position(trap.point)
	other.armor = 0
	w.party_provider = func(): return [p, other]
	var other_hp: float = other.hp
	contents.advance(0.01)
	check(other.hp == other_hp - 30, "second player receives own once-only activation hit")
	contents.advance(0.01)
	check(other.hp == other_hp - 30, "second player hitset retained")
	other.free()
	w.party_provider = main.connected_party
	p.set_logical_position(trap.point)
	p.armor = 10
	p.abilities.buffs[&"test-hazard"] = {"left": 1.0, "r": {"damage-taken-mult": 0.5}, "pool": 3.0}
	hp = p.hp
	p.take_hazard_damage(30, contents)
	check(is_equal_approx(hp - p.hp, 7), "hazard ordered armor then reduction then absorption")
	p.abilities.buffs.clear()
	p.armor = 0
	return trap


func _projectile_props(w, p, d: Dictionary, site: Dictionary, contents) -> void:
	for mob in w.targeting.live.values():
		mob.collision_layer = 0
	var projectile_key := "room/1/vase/0"
	var projectile_prop = contents.props[projectile_key]
	var shot: Dictionary = d.movesets.bow.m1
	var neighbour_key := "room/1/vase/1"
	var neighbour = contents.props[neighbour_key]
	var neighbour_position: Vector3 = neighbour.global_position
	neighbour.global_position = projectile_prop.global_position + Vector3(.1, 0, 0)
	p.global_position = projectile_prop.global_position + Vector3(0, 0, 3)
	await physics_frame
	await physics_frame
	check(
		(
			p.bodies_within(projectile_prop.global_position, float(shot.radius))
			== [projectile_prop, neighbour]
		),
		"furnishing contact setup: two eligible props in shooter-distance order"
	)
	var before_xp: int = p.xp
	var neighbour_hp: float = site.contents.props[neighbour_key].hp
	for damage in [1.0, 100.0]:
		_projectile_contact(
			p,
			projectile_prop,
			shot,
			damage,
			neighbour,
			site,
			projectile_key,
			neighbour_key,
			before_xp,
			neighbour_hp
		)
	neighbour.global_position = neighbour_position
	await process_frame


func _table_pickups(p, contents) -> void:
	# The table's loose pair is unaffected by pickup/expiry before its destruction.
	var loose: Array = get_nodes_in_group("ground-items").filter(
		func(n): return n.item.type == &"ingredient"
	)
	var bag_size: int = p.inventory.entries.size()
	p.pick_up(loose[0])
	p.pick_up(loose[0])
	check(
		p.inventory.entries.size() == bag_size + 1, "loose table flask pickup grants exactly once"
	)
	for ground in get_nodes_in_group("ground-items"):
		if ground.item.type == &"consumable":
			ground._ttl = 0
			ground._process(0)
	await process_frame
	var remaining_drops := get_nodes_in_group("ground-items").size()
	contents.props["room/1/table/0"].take_direct_damage(1000, p)
	check(
		get_nodes_in_group("ground-items").size() == remaining_drops,
		"breaking after pickup/expiry never refills table"
	)


func _initial_contents(w, id: String) -> Dictionary:
	var site: Dictionary = w.state_data.sites[id]
	check(site.has("room_levels") and site.has("contents"), "staged saved room levels and contents")
	if site.has("contents"):
		var count := 0
		for state in w.state_data.sites.values():
			count += state.contents.rubble.size()
		check(count == 56, "eight genuine rubble voxels per each of seven arenas")
		_room_guards(w, id, site)
	return site


func _content_clearance(contents) -> void:
	for point in contents.plan.rubble.values():
		var local := Gen.rotate(
			float(point[0]) - contents.layout.centre[0],
			float(point[2]) - contents.layout.centre[1],
			-int(contents.layout.turn)
		)
		_rubble_clearance(local)
	for prop in contents.plan.props.values():
		var local := Gen.rotate(
			float(prop.point[0]) - contents.layout.centre[0],
			float(prop.point[2]) - contents.layout.centre[1],
			-int(contents.layout.turn)
		)
		_prop_clearance(local)


func _live_contents(main, w, p, d: Dictionary, id: String, site: Dictionary, contents):
	contents.set_physics_process(false)
	await physics_frame
	await physics_frame
	check(
		contents.rubble.size() == 16 and contents.props.size() == 9 and contents.traps.size() == 2,
		"two ruins arenas, six vases/three tables/two traps"
	)
	_content_clearance(contents)
	var table_key := await _props(w, p, d, site, contents)
	var trap := _trap_defences(w, p, d, site, contents, main)
	var restarted := await Lifecycle._restart_features(self, main, w, p, id, trap, table_key)
	main = restarted[0]
	w = restarted[1]
	p = restarted[2]
	contents = restarted[3]
	var rubble_data := await Lifecycle._rubble_collision(self, w, p, id, contents)
	var rubble_key: String = rubble_data[0]
	var rubble_point: Array = rubble_data[1]
	Lifecycle._trap_partitions(self, main, p, trap, contents, rubble_key, table_key)
	if not await Lifecycle._renew_rooms(self, w, p, id, contents, table_key):
		return null
	p.level = 1
	p.skill_points = 0
	p.xp = 0
	Lifecycle._feature_schema(self, main, w, p, id, table_key, rubble_key)
	main = await Lifecycle._cold_rubble(self, main, w, id, contents, rubble_key, rubble_point)
	return main


func _table_height(contents) -> void:
	for ground in get_nodes_in_group("ground-items"):
		check(
			ground.global_position.y > float(contents.layout.floor) + 1,
			"loose table contents are above the intact physical table, not hidden inside it"
		)


func _projectile_contact(
	p,
	projectile_prop,
	shot: Dictionary,
	damage: float,
	neighbour,
	site: Dictionary,
	projectile_key: String,
	neighbour_key: String,
	before_xp: int,
	neighbour_hp: float
) -> void:
	var shots := Projectile.fire(
		p,
		projectile_prop.global_position + Vector3(0, 0, 2),
		Vector3.FORWARD,
		shot,
		damage,
		true,
		[&"burning", &"stun"],
		Combat.PHYSICAL
	)
	shots[0].set_physics_process(false)
	var record: Dictionary = shots[0].attack
	p.combo = 4
	p.mp = 0
	var from: Vector3 = shots[0].global_position
	var to := from + Vector3(0, -.016, -1.2)
	var ray := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [p.get_rid()])
	check(
		p.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),
		"prop setup: sphere contact precedes solid ray"
	)
	check(
		p.bodies_within(to, float(shot.radius)) == [projectile_prop, neighbour],
		"prop setup: two eligible sphere contacts"
	)
	shots[0]._physics_process(0.04)
	_projectile_result(record, shots, site, projectile_key, damage)
	check(
		(
			p.combo == 0
			and p.mp == 0
			and p.xp == before_xp
			and site.contents.props[neighbour_key].hp == neighbour_hp
		),
		"prop consumes shot without combat reward/XP or second-body spill"
	)


func _rubble_clearance(local: Vector2) -> void:
	check(
		not (local.x >= 0.5 and local.x <= 5.5 and local.y >= 3.5 and local.y <= 14.5),
		"rubble stays outside four-wide alcove approach"
	)


func _prop_clearance(local: Vector2) -> void:
	check(
		not (local.x >= 2 and local.x <= 4 and local.y >= 5.5 and local.y <= 12.5),
		"furnishings preserve real alcove approach route"
	)


func _run_main(main) -> void:
	stop(main)
	var w = main.get_node("World")
	var p = main.get_node("Player")
	var d: Dictionary = w.design
	var id := _ruins_id(w)
	var site := _initial_contents(w, id)
	main.relocate_player(
		[w.site_layout(id).centre[0], w.site_layout(id).floor, w.site_layout(id).centre[1]]
	)
	w.stream_sites()
	stop(main)
	var contents = w.site_views[id].get_node_or_null("Contents")
	check(contents != null, "actual main materializes physical contents")
	if contents != null:
		main = await _live_contents(main, w, p, d, id, site, contents)
		if main == null:
			return
	main.free()
	await physics_frame
	await physics_frame
	print("encounter contents ok" if failed == 0 else "encounter contents FAILED " + str(failed))
	quit(0 if failed == 0 else 1)


func _room_guards(w, id: String, site: Dictionary) -> void:
	for stable in w.site_layout(id).assignments:
		if not stable.boss:
			check(
				site.mobs[id + "/" + stable.key].level == site.room_levels[int(stable.pack)],
				"creation shares saved room guard level"
			)


func _projectile_result(
	record: Dictionary, shots: Array, site: Dictionary, projectile_key: String, damage: float
) -> void:
	check(
		record.hits == 0 and record.live == 0 and shots[0].is_queued_for_deletion(),
		"nonlethal/lethal furnishing contact consumes ordinary shot without combat hit"
	)
	check(
		site.contents.props[projectile_key].hp == (9 if damage == 1 else 0),
		"actual swept projectile damages only selected furnishing"
	)


func _ruins_id(w) -> String:
	var id := ""
	for key in w.state_data.sites:
		if w.state_data.sites[key].family == "ruins":
			id = key
			break
	return id
