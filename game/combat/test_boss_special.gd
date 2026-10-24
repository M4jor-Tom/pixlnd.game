extends SceneTree
const PLAYER := preload("res://game/entities/player.tscn")
const MAIN := preload("res://game/main.tscn")
const DB := preload("res://game/ontology_db.gd")
var failed := 0
func check(ok: bool, label: String) -> void:
	if not ok: failed += 1; printerr("FAIL: ",label)
func _init() -> void: call_deferred("run")
func stop(main) -> void:
	main.set_physics_process(false); main.get_node("Player").set_physics_process(false)
	var w = main.get_node("World"); w.set_process(false); w.set_physics_process(false); w.targeting.set_physics_process(false)
	for mob in w.targeting.live.values(): mob.set_physics_process(false)
func arm(boss, p, layout: Dictionary, kind: String, distance: float = 3.0) -> void:
	boss.statuses.clear(); boss.velocity = Vector3.ZERO
	boss.set_logical_position([layout.centre[0],layout.floor,layout.centre[1]])
	p.set_logical_position([layout.centre[0]+distance,layout.floor,layout.centre[1]])
	p._iframes = 0; p.blocking = false; p.statuses.clear(); p.armor = 0; p.resistance = 10000
	boss.target = p; boss.state = boss.State.CHASE; boss.targeting.record(boss).returning = false
	boss.special.kind = kind; boss.special.cancel()
	boss.incarnation.special.phase = "cooldown"; boss.incarnation.special.left = 0; boss.incarnation.special.recovery = 0

func wall(parent, position_: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new(); var cs := CollisionShape3D.new(); var shape := BoxShape3D.new()
	shape.size = Vector3(0.02,5,4); cs.shape = shape; body.add_child(cs); parent.add_child(body); body.global_position = position_+Vector3.UP*2.5
	return body

func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path(): printerr("PIXLND_TEST_DIR required"); quit(1); return
	if not root.has_node("OntologyDB"):
		var db := DB.new(); db.name = "OntologyDB"; root.add_child(db)
	var main = MAIN.instantiate(); main.save_path = directory.path_join("boss.json"); DirAccess.remove_absolute(main.save_path)
	root.add_child(main); stop(main)
	var w = main.get_node("World"); var p = main.get_node("Player"); var boss
	var count := 0
	for id in w.state_data.sites:
		var layout: Dictionary = w.site_layout(id)
		for stable in layout.assignments:
			if stable.boss:
				count += 1; check(w.state_data.sites[id].mobs[id+"/"+stable.key].has("special"),"every permanent boss owns special FSM")
	check(count == 7,"seven bosses")
	var id := ""
	for key in w.state_data.sites:
		if w.state_data.sites[key].family == "camp": id = key
	var layout: Dictionary = w.site_layout(id)
	main.relocate_player([layout.centre[0],layout.floor,layout.centre[1]])
	w.stream_sites(); stop(main)
	for mob in w.targeting.live.values():
		if mob.has_meta("encounter_site") and mob.get_meta("encounter_site") == id and mob.get("special") != null: boss = mob
	check(boss != null,"actual main binds boss special")
	if boss != null:
		for mob in w.targeting.live.values():
			if mob != boss: mob.collision_layer = 0
		boss.set_logical_position([layout.centre[0],layout.floor,layout.centre[1]])
		p.set_logical_position([layout.centre[0]+3,layout.floor,layout.centre[1]])
		p.hp = 10000; p.max_hp = 10000; p.armor = 0; p.resistance = 10000
		boss.target = p; boss.role = &"mage"; boss.special.kind = "stomp"
		await physics_frame; await physics_frame
		var hp: float = p.hp
		check(not boss.special.advance(2.99),"initial three seconds only after engagement")
		check(boss.special.advance(0.01) and boss.incarnation.special.phase == "warning","readiness enters visible warning")
		check(p.hp == hp,"warning does not damage")
		boss.special.advance(1.19); check(p.hp == hp,"warning lasts 1.2 seconds")
		boss.special.advance(0.01)
		check(is_equal_approx(hp-p.hp,boss.damage),"mage stomp is one physical boss hit")
		check(boss.incarnation.special.phase == "cooldown" and is_equal_approx(boss.incarnation.special.left,10),"completion starts ten second cooldown")
		check(boss.special.advance(0.79),"recovery suppresses basic attacks")
		check(not boss.special.advance(0.02),"basic attacks resume during remaining cooldown")
		boss.special.kind = "charge"; boss.incarnation.special.left = 0; boss.incarnation.special.recovery = 0
		p.set_logical_position([layout.centre[0]+8,layout.floor,layout.centre[1]])
		boss.target = p; boss.special.advance(0)
		var endpoint: Array = boss.incarnation.special.endpoint.duplicate()
		p.set_logical_position([layout.centre[0]+8,layout.floor,layout.centre[1]+5])
		boss.special.advance(1.2)
		check(boss.incarnation.special.endpoint == endpoint,"charge snapshots direction and endpoint")
		boss.special.advance(1)
		check(boss.incarnation.special.phase == "cooldown","charge ends at endpoint")
		check(absf(boss.logical_position()[2]-layout.centre[1]) < 0.01,"charge never homes")
		boss.incarnation.special.left = 0; boss.incarnation.special.recovery = 0
		boss.set_logical_position([layout.centre[0],layout.floor,layout.centre[1]])
		p.set_logical_position([layout.centre[0]+8,layout.floor,layout.centre[1]])
		boss.target = p; boss.special.advance(0); boss.special.advance(1.2)
		await physics_frame; await physics_frame
		hp = p.hp; boss.special.advance(1)
		check(p.hp < hp and boss.logical_position()[0] < layout.centre[0]+8,"swept capsule hits first player on coarse tick")
		boss.incarnation.special.left = 0; boss.incarnation.special.recovery = 0
		boss.set_logical_position([layout.centre[0],layout.floor,layout.centre[1]])
		boss.target = p; boss.special.kind = "stomp"; p.set_logical_position([layout.centre[0]+3,layout.floor,layout.centre[1]])
		boss.special.advance(0); boss.apply_status(&"knockback",w.design["status-effects"]["knockback"],1,p)
		check(boss.incarnation.special.phase == "cooldown","instantaneous knockback cancels")
		arm(boss,p,layout,"stomp")
		boss.special.advance(0); boss.apply_status(&"stun",w.design["status-effects"]["stun"],1,p)
		boss.special.advance(1)
		check(is_equal_approx(boss.incarnation.special.left,9),"cooldown continues during active-simulation stun")
		arm(boss,p,layout,"charge",8)
		var contents = boss.special.contents
		var rubble_key: String = contents.rubble.keys()[0]; var at: Array = contents.plan.rubble[rubble_key]
		boss.set_logical_position([at[0]-3,at[1],at[2]])
		p.set_logical_position([at[0]+5,at[1],at[2]])
		boss.special.advance(0); boss.special.advance(1.2)
		await physics_frame; await physics_frame
		hp = p.hp; var drops := get_nodes_in_group("ground-items").size()
		boss.special.advance(1)
		check(w.state_data.sites[id].contents.rubble[rubble_key].broken and p.hp < hp,"charge shatters real crossed rubble and continues into player")
		check(get_nodes_in_group("ground-items").size() == drops,"rubble yields no resource drops")
		arm(boss,p,layout,"stomp"); p._iframes = 1
		hp = p.hp; boss.special.hit_player(p,1)
		check(p.hp == hp,"special preserves normal dodge")
		p._iframes = 0; p.spec = &"guardian"; p.blocking = true; p.block_power = p.block_max(); p.mp = 0; p.rig.rotation.y = PI/2
		hp = p.hp; var power: float = p.block_power; boss.special.hit_player(p,1)
		check(is_equal_approx(hp-p.hp,boss.damage*0.2) and p.block_power < power and p.mp == 8,"normal special block mitigation/resources retained")
		arm(boss,p,layout,"stomp"); p.set_logical_position([layout.centre[0]+4,layout.floor+1,layout.centre[1]])
		hp = p.hp; boss.special.advance(0); boss.special.advance(1.2)
		check(p.hp < hp,"closed stomp radius/height boundary hits")
		arm(boss,p,layout,"stomp"); boss.special.advance(0)
		p.set_logical_position([layout.centre[0]+3,layout.floor+1.01,layout.centre[1]])
		hp = p.hp; boss.special.advance(1.2); check(p.hp == hp,"jump above one avoids stomp")
		arm(boss,p,layout,"charge",8)
		boss.special.advance(0); boss.special.advance(1.2)
		var obstacle := wall(w,boss.global_position+Vector3(4,0,0))
		await physics_frame; await physics_frame
		hp = p.hp; boss.special.advance(1)
		check(p.hp == hp and boss.logical_position()[0] < layout.centre[0]+4,"swept capsule stops at thin wall on coarse dt")
		obstacle.free()
		arm(boss,p,layout,"stomp"); boss.special.advance(0)
		obstacle = wall(w,boss.global_position+Vector3(1.5,0,0))
		await physics_frame; await physics_frame
		hp = p.hp; boss.special.advance(1.2)
		check(p.hp == hp and boss.incarnation.special.phase == "cooldown","windup sight loss cancels through physical wall")
		obstacle.free()
		arm(boss,p,layout,"charge",8)
		var other = PLAYER.instantiate(); root.add_child(other)
		other.setup(w.design.movement,w.design.camera,&"normal"); other.setup_combat(w.design.combat,w.design.crit,{},268); other.setup_items(w.ontology,w.design,&"warrior")
		other.frame = w.frame; other.logical_id = "near-special-victim"; other.set_physics_process(false); other.armor = 0
		other.set_logical_position([layout.centre[0]+5,layout.floor,layout.centre[1]+5])
		w.targeting.players = func(): return [p,other]
		await physics_frame; await physics_frame
		hp = p.hp; var other_hp: float = other.hp
		boss.special.advance(0); boss.special.advance(1.2)
		other.set_logical_position([layout.centre[0]+5,layout.floor,layout.centre[1]])
		await physics_frame; await physics_frame
		boss.special.advance(1)
		check(p.hp == hp and other.hp < other_hp and boss.logical_position()[0] < layout.centre[0]+5,"swept charge stops at first of two players, not selected far target")
		arm(boss,p,layout,"stomp")
		other.set_logical_position([layout.centre[0],layout.floor,layout.centre[1]+3])
		w.targeting.taunt([other]); w.targeting.flush_taunts(); boss._select_target(); boss.special.advance(0)
		check(boss.incarnation.special.target == other.logical_id,"boss special consumes canonical taunt-selected current target")
		boss.special.cancel(); w.targeting.record(boss).taunt = ""; w.targeting.record(boss).taunt_left = 0
		other.free(); w.targeting.players = main.connected_party
		arm(boss,p,layout,"stomp")
		for point in [[4,2,true],[4.001,0,false],[3,2.001,false]]:
			p.set_logical_position([layout.centre[0]+point[0],layout.floor+point[1],layout.centre[1]])
			check(boss.special.can_start(p) == point[2],"stomp start distance/height boundary "+str(point))
		boss.special.kind = "charge"
		for point in [[4,0,false],[4.001,1,true],[10,1,true],[10.001,0,false],[8,1.001,false]]:
			p.set_logical_position([layout.centre[0]+point[0],layout.floor+point[1],layout.centre[1]])
			check(boss.special.can_start(p) == point[2],"charge start distance/height boundary "+str(point))
		arm(boss,p,layout,"stomp"); boss.special.advance(0); p.dead = true; boss.special.advance(0)
		check(boss.incarnation.special.phase == "cooldown","invalid/dead target cancels active special")
		p.dead = false
		arm(boss,p,layout,"stomp"); boss.special.advance(0); w.targeting.start_return(boss); boss.special.advance(0)
		check(boss.incarnation.special.phase == "cooldown","protected home return cancels active special")
		arm(boss,p,layout,"charge",8); boss.special.advance(0)
		var old_left: float = boss.incarnation.special.left
		p.set_logical_position([layout.centre[0]+1000,layout.floor,layout.centre[1]])
		boss._physics_process(0.5)
		check(boss.incarnation.special.left == old_left,"inactive simulation pauses special timer")
		arm(boss,p,layout,"stomp")
		arm(boss,p,layout,"charge",8); boss.special.advance(0); boss.special.advance(1.2)
		boss.special.advance(0)
		check(boss.incarnation.special.phase == "charge","zero simulation time cannot finish a charge")
		boss.special.cancel()
		boss.incarnation.special.left = 0; boss.incarnation.special.recovery = 0; boss.special.advance(0)
		check(boss.incarnation.special.phase == "warning","new warning before unload")
		w.retire_views()
		var saved: Dictionary
		for row in w.state_data.sites[id].mobs.values():
			if row.has("special"): saved = row.special
		check(saved.phase == "cooldown" and saved.left == 10 and saved.recovery == 0.8,"unload cancels without replay")
		check(main.save_now(),"boss state saves")
		var data: Dictionary = main.save_data.capture(w.state_data,p)
		var boss_id: String = boss.logical_id
		for field in ["phase","left","recovery","origin","endpoint","target","engaged"]:
			var bad := data.duplicate(true); bad.world.sites[id].mobs[boss_id].special.erase(field)
			check(not main.save_data.validate(bad),"missing saved special "+field+" rejected")
			for value in [null,[],{},"bad",true,INF,-1]:
				if field in ["origin","endpoint"] and value is Array: continue
				if field == "engaged" and value is bool: continue
				bad = data.duplicate(true); bad.world.sites[id].mobs[boss_id].special[field] = value
				check(not main.save_data.validate(bad),"malformed saved special "+field+str(value)+" rejected")
		var path: String = main.save_path
		main.free(); await process_frame
		main = MAIN.instantiate(); main.save_path = path; root.add_child(main); stop(main)
		w = main.get_node("World"); p = main.get_node("Player"); w.stream_sites(); stop(main)
		boss = w.targeting.live[boss_id]
		check(boss.incarnation.special.phase == "cooldown" and boss.incarnation.special.left == 10 and boss.incarnation.special.recovery == 0.8,"cold main restart retains waiting remainder/no offline advance")
		arm(boss,p,layout,boss.special.kind,8 if boss.special.kind == "charge" else 3); boss.special.advance(0)
		check(main.save_now(),"save ongoing windup before normal shutdown "+str(main.save_data.errors))
		main.free(); await process_frame
		main = MAIN.instantiate(); main.save_path = path; root.add_child(main); stop(main)
		w = main.get_node("World"); p = main.get_node("Player"); w.stream_sites(); stop(main)
		boss = w.targeting.live[boss_id]
		check(boss.incarnation.special.phase == "cooldown" and boss.incarnation.special.left == 10 and boss.incarnation.special.recovery == 0.8,"cold restart cancels saved windup, never replaying impact")
		for phase in ["charge","cooldown","ready"]:
			arm(boss,p,layout,boss.special.kind,8 if boss.special.kind == "charge" else 3)
			boss.special.advance(0)
			if phase == "charge":
				check(boss.special.kind == "charge","fixed-seed camp exercises real execution restart")
				boss.special.advance(1.2)
			else:
				boss.special.cancel(); boss.incarnation.special.phase = phase
				boss.incarnation.special.left = 2.25 if phase == "ready" else 4.25
				boss.incarnation.special.recovery = 0.0 if phase == "ready" else 0.5
			var waiting: Dictionary = boss.incarnation.special.duplicate(true)
			check(main.save_now(),"save special lifecycle phase "+phase+str(main.save_data.errors))
			main.free(); await process_frame
			main = MAIN.instantiate(); main.save_path = path; root.add_child(main); stop(main)
			w = main.get_node("World"); p = main.get_node("Player"); w.stream_sites(); stop(main); boss = w.targeting.live[boss_id]
			var restored: Dictionary = boss.incarnation.special
			if phase == "charge":
				check(restored.phase == "cooldown" and restored.left == 10 and restored.recovery == 0.8,"execution cold restart cancels without charge/hit replay")
			else: check(restored == waiting,"waiting "+phase+" exact remainders survive cold restart")
	main.free(); await physics_frame; await physics_frame
	print("boss special ok" if failed == 0 else "boss special FAILED "+str(failed))
	quit(0 if failed == 0 else 1)
