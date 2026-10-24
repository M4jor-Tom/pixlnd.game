extends SceneTree
const MAIN := preload("res://game/main.tscn")
const DB := preload("res://game/ontology_db.gd")
const Save := preload("res://game/world/save_data.gd")
const Gen := preload("res://game/world/encounter_gen.gd")
const Projectile := preload("res://game/combat/projectile.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const Combat := preload("res://game/combat/combat.gd")
var failed := 0
func check(ok: bool, label: String) -> void:
	if not ok: failed += 1; printerr("FAIL: ",label)
func _init() -> void: call_deferred("run")
func stop(main) -> void:
	main.set_physics_process(false)
	var w = main.get_node("World"); w.set_process(false); w.set_physics_process(false); w.targeting.set_physics_process(false)
	main.get_node("Player").set_physics_process(false)
	for mob in w.targeting.live.values(): mob.set_physics_process(false)
func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path(): printerr("PIXLND_TEST_DIR required"); quit(1); return
	if not root.has_node("OntologyDB"):
		var db := DB.new(); db.name = "OntologyDB"; root.add_child(db)
	var main = MAIN.instantiate(); main.save_path = directory.path_join("contents.json"); DirAccess.remove_absolute(main.save_path)
	root.add_child(main); stop(main)
	var w = main.get_node("World"); var p = main.get_node("Player"); var d: Dictionary = w.design
	var id := ""
	for key in w.state_data.sites:
		if w.state_data.sites[key].family == "ruins": id = key; break
	var site: Dictionary = w.state_data.sites[id]
	check(site.has("room_levels") and site.has("contents"),"staged saved room levels and contents")
	if site.has("contents"):
		var count := 0
		for state in w.state_data.sites.values(): count += state.contents.rubble.size()
		check(count == 56,"eight genuine rubble voxels per each of seven arenas")
		for stable in w.site_layout(id).assignments:
			if not stable.boss: check(site.mobs[id+"/"+stable.key].level == site.room_levels[int(stable.pack)],"creation shares saved room guard level")
	main.relocate_player([w.site_layout(id).centre[0],w.site_layout(id).floor,w.site_layout(id).centre[1]])
	w.stream_sites(); stop(main)
	var contents = w.site_views[id].get_node_or_null("Contents")
	check(contents != null,"actual main materializes physical contents")
	if contents != null:
		contents.set_physics_process(false)
		await physics_frame; await physics_frame
		check(contents.rubble.size() == 16 and contents.props.size() == 9 and contents.traps.size() == 2,"two ruins arenas, six vases/three tables/two traps")
		for point in contents.plan.rubble.values():
			var local := Gen.rotate(float(point[0])-contents.layout.centre[0],float(point[2])-contents.layout.centre[1],-int(contents.layout.turn))
			check(not (local.x >= 0.5 and local.x <= 5.5 and local.y >= 3.5 and local.y <= 14.5),"rubble stays outside four-wide alcove approach")
		for prop in contents.plan.props.values():
			var local := Gen.rotate(float(prop.point[0])-contents.layout.centre[0],float(prop.point[2])-contents.layout.centre[1],-int(contents.layout.turn))
			check(not (local.x >= 2 and local.x <= 4 and local.y >= 5.5 and local.y <= 12.5),"furnishings preserve real alcove approach route")
		var ground_count := get_nodes_in_group("ground-items").size()
		check(ground_count == 6,"intact tables initially issue six independent loose pickups")
		for ground in get_nodes_in_group("ground-items"):
			check(ground.global_position.y > float(contents.layout.floor)+1,"loose table contents are above the intact physical table, not hidden inside it")
		var key: String = contents.props.keys()[0]; var prop = contents.props[key]
		var before_combo: int = p.combo; var before_mp: float = p.mp
		p.combo = 4; p.mp = 0
		p._strike(prop.global_position,0.6,1.0,true,[&"stun",&"burning"])
		check(site.contents.props[key].hp < 10 and site.contents.props[key].hp > 0,"real player direct attack damages vase")
		check(p.combo == 4 and p.mp == 0,"prop strike grants no combo/MP")
		check(not prop.has_method("take_damage") and not prop.has_method("apply_status"),"props excluded from DOT/status path")
		p.combo = before_combo; p.mp = before_mp
		var table_key := "room/0/table/0"
		contents.props[table_key].take_direct_damage(1000,p)
		check(get_nodes_in_group("ground-items").size() == ground_count,"table break does not issue pair")
		for mob in w.targeting.live.values(): mob.collision_layer = 0
		var projectile_key := "room/1/vase/0"; var projectile_prop = contents.props[projectile_key]
		var shot: Dictionary = d.movesets.bow.m1
		var shots := Projectile.fire(p,projectile_prop.global_position+Vector3(0,0,2),Vector3.FORWARD,shot,100,false,[&"burning"],Combat.PHYSICAL)
		shots[0].set_physics_process(false); p.mp = 0
		shots[0]._physics_process(0.1)
		check(site.contents.props[projectile_key].hp == 0 and p.mp == 0,"actual swept projectile breaks furnishing without combat reward/status")
		await process_frame
		# The table's loose pair is unaffected by pickup/expiry before its destruction.
		var loose: Array = get_nodes_in_group("ground-items").filter(func(n): return n.item.type == &"ingredient")
		var bag_size: int = p.inventory.entries.size()
		p.pick_up(loose[0]); p.pick_up(loose[0])
		check(p.inventory.entries.size() == bag_size+1,"loose table flask pickup grants exactly once")
		for ground in get_nodes_in_group("ground-items"):
			if ground.item.type == &"consumable": ground._ttl = 0; ground._process(0)
		await process_frame
		var remaining_drops := get_nodes_in_group("ground-items").size()
		contents.props["room/1/table/0"].take_direct_damage(1000,p)
		check(get_nodes_in_group("ground-items").size() == remaining_drops,"breaking after pickup/expiry never refills table")
		var trap: Dictionary = contents.plan.traps[0]
		p.set_logical_position(trap.point); p.hp = p.max_hp; p.armor = 0; p.resistance = 10000; p._iframes = 5; p.blocking = true
		var hp: float = p.hp; var power: float = p.block_power; var mp: float = p.mp
		contents.advance(0.8)
		check(is_equal_approx(hp-p.hp,30),"warning boundary activates physical spikes bypassing dodge/block/resistance")
		check(p.block_power == power and p.mp == mp,"spikes grant/spend no block resources")
		contents.advance(0.1); check(p.hp == hp-30,"one trap hit per activation")
		check(site.contents.traps[0].phase == "active","trap phase persists")
		for point in [[trap.point[0]-1,trap.point[1],trap.point[2]-1],[trap.point[0]+1,trap.point[1]+1,trap.point[2]+1]]:
			p.set_logical_position(point); check(contents.eligible(trap,p),"closed footprint corners/height")
		p.set_logical_position([trap.point[0]+1.001,trap.point[1],trap.point[2]])
		check(not contents.eligible(trap,p),"outside trap footprint safe")
		var other = PLAYER.instantiate(); root.add_child(other)
		other.setup(d.movement,d.camera,&"normal"); other.setup_combat(d.combat,d.crit,{},268); other.setup_items(w.ontology,d,&"warrior")
		other.logical_id = "second-connected"; other.set_physics_process(false); other.set_logical_position(trap.point); other.armor = 0
		w.party_provider = func(): return [p,other]
		var other_hp: float = other.hp
		contents.advance(0.01); check(other.hp == other_hp-30,"second player receives own once-only activation hit")
		contents.advance(0.01); check(other.hp == other_hp-30,"second player hitset retained")
		other.free(); w.party_provider = main.connected_party
		p.set_logical_position(trap.point)
		p.armor = 10; p.abilities.buffs[&"test-hazard"] = {"left":1.0,"r":{"damage-taken-mult":0.5},"pool":3.0}
		hp = p.hp; p.take_hazard_damage(30,contents)
		check(is_equal_approx(hp-p.hp,7),"hazard ordered armor then reduction then absorption")
		p.abilities.buffs.clear(); p.armor = 0
		check(main.save_now(),"actual main atomic feature save")
		var path: String = main.save_path
		main.free(); await process_frame
		main = MAIN.instantiate(); main.save_path = path; root.add_child(main); stop(main)
		w = main.get_node("World"); p = main.get_node("Player"); w.stream_sites(); stop(main)
		contents = w.site_views[id].get_node("Contents"); contents.set_physics_process(false)
		check(get_nodes_in_group("ground-items").is_empty(),"delivered table pair never rematerializes on restart")
		check(w.state_data.sites[id].contents.props[table_key].hp == 0,"broken table survives restart")
		p.set_logical_position(trap.point); hp = p.hp
		contents.advance(0.05); check(p.hp == hp,"saved activation hitset prevents replay after restart")
		p.set_logical_position([trap.point[0],trap.point[1]+1.01,trap.point[2]])
		contents.advance(3); check(p.hp == hp,"jump above trap avoids standing retrigger")
		var rubble_key: String = contents.rubble.keys()[0]
		var rubble_point: Array = contents.plan.rubble[rubble_key]
		await physics_frame; await physics_frame
		var native: Vector3 = contents.native(rubble_point)
		var query := PhysicsRayQueryParameters3D.create(native+Vector3.UP*1.5,native+Vector3.UP*0.5)
		var hit: Dictionary = w.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and hit.collider == contents.rubble[rubble_key],"stone voxel has real collision")
		contents.break_rubble(rubble_key)
		check(w.state_data.sites[id].contents.rubble[rubble_key].broken,"rubble destruction saved")
		check(contents.rubble[rubble_key].collision_layer == 0,"rubble really loses collision")
		hit = w.get_world_3d().direct_space_state.intersect_ray(query)
		check(hit.is_empty(),"destroyed voxel no longer blocks actual ray")
		var deadline: float = w.state_data.sites[id].contents.rubble[rubble_key].restore_at
		check(is_equal_approx(deadline-w.state_data.clock,72*3600),"72 world hour restoration deadline")
		p.set_logical_position([0,100,0]); w.state_data.clock = deadline-0.01; contents.restore_due()
		check(w.state_data.sites[id].contents.rubble[rubble_key].broken,"no early rubble restore")
		w.state_data.clock = deadline; p.set_logical_position(rubble_point); contents.restore_due()
		check(w.state_data.sites[id].contents.rubble[rubble_key].broken,"occupied site defers rubble restore")
		p.set_logical_position([0,100,0])
		var actor_id: String = w.state_data.sites[id].mobs.keys()[0]
		var actor = w.targeting.live[actor_id]; var old_point: Array = actor.logical_position()
		actor.set_logical_position(rubble_point); contents.restore_due()
		check(w.state_data.sites[id].contents.rubble[rubble_key].broken,"actor overlap defers restoration without player occupancy")
		actor.set_logical_position(old_point); contents.restore_due()
		check(not w.state_data.sites[id].contents.rubble[rubble_key].broken and contents.rubble[rubble_key].collision_layer != 0,"unoccupied nonoverlapping due rubble restores collision")
		p.set_logical_position(trap.point); p.hp = 1000; p.max_hp = 1000; p._iframes = 0; p.blocking = false; p.armor = 0
		contents.saved.traps[0] = {"phase":"idle","left":0.0,"hit":[]}
		contents.advance(4)
		var coarse: Dictionary = contents.saved.traps[0].duplicate(true)
		var coarse_loss: float = 1000-p.hp
		contents.saved.traps[0] = {"phase":"idle","left":0.0,"hit":[]}; p.hp = 1000
		for i in 40: contents.advance(0.1)
		check(coarse_loss == 60 and 1000-p.hp == coarse_loss and contents.saved.traps[0].phase == coarse.phase and is_equal_approx(contents.saved.traps[0].left,coarse.left),"coarse and fragmented trap time preserves standing retriggers/boundaries")
		contents.saved.traps[0] = {"phase":"idle","left":0.0,"hit":[]}
		contents.advance(0); p.set_logical_position([0,100,0]); contents.advance(0.8)
		check(contents.saved.traps[0].phase == "active","leaving never cancels warning")
		# The inherited site root translates all content once with the production frame.
		var before_point: Array = contents.plan.rubble[rubble_key].duplicate()
		main.frame.shift_to([main.frame.origin[0]+64,main.frame.origin[1]-64])
		check(contents.rubble[rubble_key].global_position == contents.native(before_point)+Vector3.UP*0.5,"rubble remains in canonical logical position through live frame transaction")
		check(contents.props[table_key].global_position == contents.native(contents.plan.props[table_key].point)+Vector3.UP*0.5,"prop follows tracked site root once")
		# A coalesced safe renewal rolls each room once and does not rescale its surviving guards.
		var survivor: String = w.state_data.sites[id].mobs.keys()[1]
		var old_level: int = w.state_data.sites[id].mobs[survivor].level
		var dead_id: String = w.state_data.sites[id].mobs.keys()[0]
		w.targeting.live[dead_id].take_damage(1e9,p)
		p.level = 20; p.skill_points = 19*preload("res://ontology/model.gd").SKILL_POINTS_PER_LEVEL; w.state_data.sites[id].pending = true
		w.state_data.advance(0,[[0,100,0]])
		await process_frame
		check(w.state_data.sites[id].cycle == 1 and w.state_data.sites[id].room_levels.all(func(l): return l >= 17),"safe renewal rerolls saved room band once")
		check(w.state_data.sites[id].mobs[survivor].level == old_level,"mixed-level surviving guard unchanged")
		check(w.state_data.sites[id].mobs[dead_id].level == w.state_data.sites[id].room_levels[0],"replacement uses renewed room level")
		check(w.state_data.sites[id].contents.props[table_key].hp == 20 and w.state_data.sites[id].contents.traps[0].phase == "idle","daily renewal restores props and idles traps")
		check(get_nodes_in_group("ground-items").filter(func(n): return n.item.type == &"consumable").size() == 3,"one fresh table potion per room at renewal")
		p.level = 1; p.skill_points = 0; p.xp = 0
		var snapshot: Dictionary = main.save_data.capture(w.state_data,p)
		check(main.save_data.validate(snapshot),"generated content schema validates")
		for field in ["room_levels","contents"]:
			var bad := snapshot.duplicate(true); bad.world.sites[id].erase(field)
			check(not main.save_data.validate(bad),"missing "+field+" rejected")
		for path_ in [["traps",0,"phase"],["traps",0,"left"],["traps",0,"hit"],["props",table_key,"hp"],["rubble",rubble_key,"restore_at"],["rubble",rubble_key,"broken"]]:
			for value in [null,[],{},"bad",true,INF,-1]:
				if path_[-1] == "broken" and value is bool: continue
				if path_[-1] == "hit" and value is Array: continue
				var invalid := snapshot.duplicate(true)
				invalid.world.sites[id].contents[path_[0]][path_[1]][path_[2]] = value
				check(not main.save_data.validate(invalid),"malformed saved content rejected "+str(path_)+str(value))
		var bad := snapshot.duplicate(true)
		bad.world.sites[id].room_levels = [1,null,1]
		bad.world.sites[id].contents.traps[0].left = INF
		check(not main.save_data.validate(bad) and main.save_data.errors.size() >= 2,"invalid room level and trap timer accumulate")
		contents.break_rubble(rubble_key)
		var delayed: float = w.state_data.sites[id].contents.rubble[rubble_key].restore_at
		var blocker_id: String = w.state_data.sites[id].mobs.keys()[0]
		w.state_data.sites[id].mobs[blocker_id].position = rubble_point.duplicate()
		w.retire_views(); check(main.save_now(),"save broken rubble while unloaded")
		var save_path: String = main.save_path
		main.free(); await process_frame
		main = MAIN.instantiate(); main.save_path = save_path; root.add_child(main); stop(main)
		w = main.get_node("World")
		check(w.state_data.sites[id].contents.rubble[rubble_key].broken and w.state_data.sites[id].contents.rubble[rubble_key].restore_at == delayed,"unloaded broken rubble deadline survives cold restart exactly")
		w.state_data.clock = delayed; w.restore_rubble(id)
		check(w.state_data.sites[id].contents.rubble[rubble_key].broken,"saved unloaded actor still defers due rubble")
		w.state_data.sites[id].mobs[blocker_id].position = w.state_data.sites[id].mobs[blocker_id].home.duplicate()
		w.restore_rubble(id)
		check(not w.state_data.sites[id].contents.rubble[rubble_key].broken,"unloaded actor-safe due restoration updates logical owner")
	main.free(); await physics_frame; await physics_frame
	print("encounter contents ok" if failed == 0 else "encounter contents FAILED "+str(failed))
	quit(0 if failed == 0 else 1)
