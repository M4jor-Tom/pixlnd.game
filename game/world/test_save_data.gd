extends SceneTree
const Save := preload("res://game/world/save_data.gd")
const State := preload("res://game/world/world_state.gd")
const Model := preload("res://ontology/model.gd")
const Item := preload("res://game/items/item.gd")
const Items := preload("res://game/items/items.gd")
const Gen := preload("res://game/world/world_gen.gd")
const Spawner := preload("res://game/world/spawner.gd")
const World := preload("res://game/world/world.gd")
const PLAYER := preload("res://game/entities/player.tscn")
var path := ""
var failed := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1; printerr("FAIL: ",label)
func _init() -> void: call_deferred("run")
func run() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		printerr("PIXLND_TEST_DIR must name an isolated absolute scratch directory"); quit(1); return
	path = directory.path_join("test-save-data.json")
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var d: Dictionary = o.configs.generators.design
	var p = PLAYER.instantiate(); root.add_child(p)
	p.setup(d.movement,d.camera,&"normal"); p.setup_combat(d.combat,d.crit,{},100); p.setup_items(o,d)
	p.logical_id = "hero-test"; p.set_physics_process(false)
	p.gain_xp(60); p.skill_points = 1; p.skill_tree.points = {&"smash": 1}
	p.inventory.coins = 123
	p.inventory.add(Item.stack(&"ingredient",&"spirit-fire",1,4))
	var rng := RandomNumberGenerator.new(); rng.seed = 42
	var gear = Items.generate(rng,&"chest-armor",&"",&"iron",2,1)
	p.inventory.add(gear); check(p.inventory.equip(gear), "equipment swapped")
	p.position = Vector3(123,125,456); p.spawn_point = Vector3(321,150,654)
	var state = State.new(d,26879)
	var save = Save.new(o,d)
	var holder := Node3D.new(); root.add_child(holder)
	var gen := Gen.new(26879,d,o.landscapes)
	var zone := Vector2i(125,127)
	var plans: Array = Spawner.plan(gen,zone,d,o.creatures,o.configs["creature-families"]["landscape-rosters"],p.level)
	var made: Array = Spawner.populate(holder,plans,d,o.creatures,p,null,null,state.world_id+"/ambient/125,127",state.mobs)
	for mob in made: mob.set_physics_process(false)
	check(not made.is_empty(),"real generated descriptors in save boundary")
	var site_id: String = state.site_id(Vector2i.ZERO,"ruins",0)
	var world := World.new(); root.add_child(world)
	world.configure(o,d,state,func(): return [p]); world.set_physics_process(false); world.set_process(false)
	check(world.ensure_land(world.gen.land_at(Vector2i.ZERO)),"complete actual joint site fixture")
	var layout: Dictionary = world.site_layout(site_id)
	world.target = p; p.position = Vector3(layout.centre[0],layout.floor,layout.centre[1]); world.stream_sites()
	var stable: Dictionary = layout.assignments[0]
	world.targeting.live[site_id+"/"+stable.key].take_damage(1e9,p)
	var reward_id := "kill/0/"+str(stable.key)
	check(state.sites[site_id].rewards.has(reward_id),"first real logical death issues rolled payload")
	check(not state.issue_reward(site_id,reward_id,[]),"same logical death cannot reroll")
	p.position = Vector3(123,125,456)
	var data: Dictionary = save.capture(state,p)
	check(save.write_atomic(path,data), "atomic write valid state: " + str(save.errors))
	var loaded: Dictionary = save.load_file(path)
	check(not loaded.is_empty(), "load validated: " + str(save.errors))
	var resumed = State.new(d,26879); resumed.restore(loaded.world)
	check(not resumed.issue_reward(site_id,reward_id,[]) and resumed.sites[site_id].rewards[reward_id].payload == loaded.world.sites[site_id].rewards[reward_id].payload,"immutable issued reward survives restart without reroll")
	var q = PLAYER.instantiate(); root.add_child(q)
	q.setup(d.movement,d.camera,&"normal"); q.setup_combat(d.combat,d.crit,{},100); q.setup_items(o,d); q.set_physics_process(false)
	save.restore_player(q,loaded.character,loaded.world)
	check(q.logical_id == p.logical_id and q.level == p.level and q.xp == p.xp, "identity level XP roundtrip")
	check(q.skill_points == 1 and q.skill_tree.spent(&"smash") == 1, "banked and spent skills roundtrip")
	check(q.inventory.entries.any(func(it): return it.subtype == &"spirit-fire" and it.level == 4),"carried spirit payload roundtrip")
	check(q.inventory.coins == 123 and q.inventory.equipment[&"chest"].modifier == gear.modifier, "coins and equipment payload roundtrip")
	check(q.position == p.position and q.spawn_point == p.spawn_point, "per-world position/respawn roundtrip")
	var original := FileAccess.get_file_as_string(path)
	for mutate in ["count", "class", "loadout", "identity", "clock", "skills", "site-family", "site-ordinal", "mob-id", "mob-pack", "mob-stats", "mob-order", "missing-parent", "skill-prerequisite", "member-count", "species-role"]:
		var bad: Dictionary = loaded.duplicate(true)
		match mutate:
			"count": bad.character.bag[0].count = -1
			"class": bad.character.class_id = "unknown"
			"loadout": bad.character.equipment["off-hand"] = bad.character.equipment["chest"].duplicate()
			"identity": bad.world.sites["foreign-site"] = {"family":"ruins"}
			"clock": bad.world.clock = -1
			"skills": bad.character.points = {"unknown":1}
			"site-family": bad.world.sites[site_id].family = "supplier"
			"site-ordinal":
				var invalid: String = site_id.trim_suffix("/0")+"/99"
				bad.world.sites[invalid] = bad.world.sites[site_id].duplicate(true); bad.world.sites[invalid].id = invalid
			"mob-id":
				var first: String = bad.world.mobs.keys()[0]
				bad.world.mobs[state.world_id+"/ambient/not-coordinates/0/0"] = bad.world.mobs[first].duplicate(true)
			"mob-pack": bad.world.mobs.values()[0].pack = "foreign-pack"
			"mob-stats": bad.world.mobs.values()[0].max_hp *= 2
			"mob-order": bad.world.mobs.values()[0].combat = {"threat":{"hero-test":1.0},"order":{},"next_order":0,"provoked":{},"current":"","taunt":"","taunt_left":0.0,"returning":false}
			"missing-parent": bad.world.mobs = []
			"skill-prerequisite": bad.character.points = {"cyclone":1}
			"species-role":
				bad.world.mobs.values()[0].species = "wolf"; bad.world.mobs.values()[0].role = "mage"
			"member-count":
				var first: String = bad.world.mobs.keys()[0]
				bad.world.mobs[first.get_base_dir()+"/999"] = bad.world.mobs[first].duplicate(true)
		check(not save.write_atomic(path,bad) and not save.errors.is_empty(), "reject rule invalid " + mutate)
		check(FileAccess.get_file_as_string(path) == original, "invalid write preserves original " + mutate)
		var bad_path := path + ".invalid"
		var f := FileAccess.open(bad_path,FileAccess.WRITE); f.store_string(JSON.stringify(bad)); f.close()
		check(save.load_file(bad_path).is_empty() and not save.errors.is_empty(), "invalid load rejected " + mutate)
		DirAccess.remove_absolute(bad_path)
	var f := FileAccess.open(path+".invalid",FileAccess.WRITE); f.store_string("{broken"); f.close()
	check(save.load_file(path+".invalid").is_empty(), "corrupt JSON rejected")
	DirAccess.remove_absolute(path+".invalid")
	check(save.load_file(path+".missing").is_empty(), "missing file diagnosed")
	check(FileAccess.get_file_as_string(path) == original, "failed loads leave original untouched")
	check(not FileAccess.file_exists(path+".tmp"), "atomic rename consumed temp")
	# Empty equipment is legal and restores exactly, without starter attack leakage.
	p.inventory.unequip(&"main-hand")
	var unarmed: Dictionary = save.capture(state,p)
	check(save.write_atomic(path,unarmed),"legal unarmed save accepted")
	save.restore_player(q,save.load_file(path).character,unarmed.world)
	check(not q.inventory.equipment.has(&"main-hand") and q.weapon.is_empty() and q.moveset.is_empty(),"unarmed save restores exact equipment and derived state")
	check(not save.write_atomic(path.path_join("missing-parent/save.json"),unarmed) and not save.errors.is_empty(),"I/O failure diagnosed without replacing original")
	print("save data ok" if failed == 0 else "save data FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
