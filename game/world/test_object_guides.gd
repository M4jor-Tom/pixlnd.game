## Terrain-following guides remain solid, non-targetable and harmless scenery.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const Gen := preload("res://game/world/world_gen.gd")
const Site := preload("res://game/world/encounter_site.gd")
const Player := preload("res://game/entities/player.tscn")
const Projectile := preload("res://game/combat/projectile.gd")
const Frame := preload("res://game/world/local_frame.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var d: Dictionary = o.configs.generators.design
	var g := Gen.new(3, d, o.landscapes)
	g._h_base = 140
	g._h_amp = 0
	var plan_: Dictionary = g.encounters_at(g.land_at(Vector2i.ZERO))
	check(not plan_.is_empty(), "dry-terrain complete joint plan")
	if plan_.is_empty():
		quit(1)
		return
	var frame := Frame.new(64)
	frame.set_origin([plan_.village.centre[0], 0, plan_.village.centre[1]])
	plan_["routes"] = Gen.Encounters.guidance(g, plan_, g.encounter_config)
	var view := Site.roads(plan_, d, frame)
	root.add_child(view)
	var p = Player.instantiate()
	root.add_child(p)
	p.setup(d.movement, d.camera, o.races.human.size_class)
	p.setup_combat(d.combat, d.crit, {}, 100)
	p.setup_items(o, d, &"warrior")
	p.set_physics_process(false)
	p.frame = frame
	await physics_frame
	await physics_frame
	var space := view.get_world_3d().direct_space_state
	var families := [
		"masonry", "stake-torch", "broken-crate", "broken-crate", "broken-crate", "broken-crate"
	]
	var checked := 0
	for road in plan_.routes:
		check(
			road.family == families[road.destination],
			"destination identity, no tier-specific family"
		)
		check(
			road.markers.size() >= 2,
			"nonempty repeated dry-terrain guides " + str(road.destination)
		)
		for marker in road.markers:
			check(marker.family == road.family, "one guide family per branch")
			var at: Vector3 = frame.to_local([marker.x, marker.top, marker.z])
			var hit := space.intersect_ray(
				PhysicsRayQueryParameters3D.create(at + Vector3.UP * 2, at + Vector3.UP * 0.01)
			)
			check(
				not hit.is_empty() and hit.position.y > marker.top,
				"actual guide solid art/collision"
			)
			if hit.is_empty():
				continue
			var body = hit.collider
			check(
				(
					not body.has_method("take_damage")
					and not body.has_method("take_direct_damage")
					and not body.has_method("interact")
				),
				"guide has no combat or interaction entry points"
			)
			check(
				body.get_groups().is_empty() and body.get_script() == null,
				"guide has no target, pickup, reward or damage registration"
			)
			# Ordinary player strike and real projectile contact cannot turn scenery into a rewarding target.
			p.position = at + Vector3(0, 0, 3)
			var xp: int = p.xp
			var coins: int = p.inventory.coins
			var hp: float = p.hp
			var drops := get_nodes_in_group("ground-items").size()
			check(
				p._strike(at + Vector3.UP * 0.12, 1, 10000, true, [&"burning"]) == 0,
				"direct guide strike hits no target"
			)
			var shots := Projectile.fire(
				p,
				at + Vector3(0, 0.12, 2),
				Vector3.FORWARD,
				d.movesets.bow.m1,
				10000,
				true,
				[],
				&"physical"
			)
			var shot = shots[0]
			shot.set_physics_process(false)
			var record: Dictionary = shot.attack
			shot._physics_process(0.1)
			check(
				shot.is_queued_for_deletion() and record.hits == 0,
				"real projectile stops at solid guide without a combat hit"
			)
			check(
				(
					p.xp == xp
					and p.inventory.coins == coins
					and p.hp == hp
					and get_nodes_in_group("ground-items").size() == drops
				),
				"attacks/contact grant no rewards, damage or drops"
			)
			check(
				is_instance_valid(body) and not body.is_queued_for_deletion(),
				"guide is unbreakable"
			)
			checked += 1
			await process_frame
	check(checked >= 6, "real physical negative checks cover every destination")
	p.free()
	view.free()
	print(
		(
			"dry-terrain solid guides ok"
			if failed == 0
			else "dry-terrain solid guides FAILED %d" % failed
		)
	)
	quit(0 if failed == 0 else 1)
