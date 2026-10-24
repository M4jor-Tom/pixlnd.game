extends SceneTree
const MAIN := preload("res://game/main.tscn")
const Rewards := preload("res://game/items/encounter_rewards.gd")
const Save := preload("res://game/world/save_data.gd")
const Items := preload("res://game/items/items.gd")
const Inventory := preload("res://game/items/inventory.gd")
const DB := preload("res://game/ontology_db.gd")
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
	var main = MAIN.instantiate(); main.save_path = directory.path_join("rewards.json"); DirAccess.remove_absolute(main.save_path)
	root.add_child(main); stop(main)
	var w = main.get_node("World"); var p = main.get_node("Player")
	var id: String = w.state_data.sites.keys()[0]; var layout: Dictionary = w.site_layout(id)
	main.relocate_player([layout.centre[0],layout.floor,layout.centre[1]]); w.stream_sites(); stop(main)
	var stable: Dictionary = layout.assignments[0]; var mob = w.targeting.live[id+"/"+stable.key]
	mob.take_damage(1e9,p)
	check(w.state_data.sites[id].rewards.has("kill/0/"+stable.key),"actual death issues shared ordinary reward")
	check(w.has_method("deliver_rewards"),"world owns pending delivery")
	var site: Dictionary = w.state_data.sites[id]
	var receipt: Dictionary = site.rewards["kill/0/"+stable.key]
	var rolled: Array = receipt.payload.duplicate(true)
	w.site_death(id,stable,mob)
	check(receipt.payload == rolled and receipt.delivered,"duplicate callback never rerolls/reawards")
	var o = p.o; var d: Dictionary = p.design
	# Pure generation checks consume the same contract/pools, including all four legal classes.
	var kinds := {}
	for cls in o.classes:
		var inv := Inventory.new(o,d,cls)
		for tier in 4:
			for seed_ in 80:
				var package := Rewards.package_payload("probe/%d" % seed_,tier,7,cls,o,d)
				var gear = package[0]; kinds[gear.type] = true
				check(inv.class_allowed(gear) and gear.level == 7 and gear.rarity == tier+1 and gear.upgrade_count == 0,"package gear legal/class/level/rarity/upgrades")
				if gear.type == &"weapon": check(Items.weapon_material_allowed(gear,o),"package exact legal weapon material")
				check(package[1].count == 20*(tier+1) and package[2].subtype == &"life-potion" and package[2].level == 7 and package[2].rarity == 0,"exact package copper and potion")
				check(package[3].subtype == ["emerald","sapphire","ruby","diamond"][tier] and package[3].count == tier+1,"exact grade gems")
	check(kinds.size() == 5,"all weighted gear kinds reachable")
	for state_id in w.state_data.sites:
		for assignment in w.site_layout(state_id).assignments:
			if not assignment.boss: continue
			var payload := Rewards.kill_payload(assignment,0,13,3,o,d)
			var ordinary := Items.roll_loot(Rewards.rng_for("kill/%d/0" % int(assignment.seed)),13,o.creatures[&"skeleton"],o,d)
			check(payload.size() == ordinary.size()+1+(1 if assignment.spirit != "" else 0),"boss guarantees additional to ordinary rolls")
			check(Save.same_data(payload.slice(0,ordinary.size()).map(Save.item_data),ordinary.map(Save.item_data)),"ordinary rolls preserved exactly in combined boss payload")
			var gear = payload[ordinary.size()]
			check(gear.level == 13 and gear.rarity == mini(int(assignment.tier)+1,4) and gear.upgrade_count == 0,"all seven boss fixed rarity/current level/zero upgrades")
			if assignment.spirit != "":
				var spirit = payload[-1]
				check(spirit.subtype == StringName(assignment.spirit) and spirit.level == 3 and spirit.count == 1,"permanent logical spirit keeps initial level")
				check(not Items.item_name(spirit,o,d).is_empty(),"spirit inventory name")
				check(Rewards.kill_payload(assignment,1,25,3,o,d)[-1].subtype == spirit.subtype,"renewed spirit assignment fixed")
			else: check(not payload.any(func(it): return str(it.subtype).begins_with("spirit-")),"mission bosses no spirits")
	var v: Array = site.volumes[0]; var point := [v[0],v[1],v[2]]
	var party := [{"class_id":"mage","position":point,"dead":true},{"class_id":"mage","position":point,"dead":false},{"class_id":"ranger","position":point,"dead":true}]
	check(Rewards.completion_classes(party,site.volumes,null) == ["mage","ranger"],"distinct inside classes include awaiting/no-view and closed boundary")
	check(Rewards.completion_classes([],site.volumes,p) == [str(p.inventory.class_id)],"outsider finisher fallback")
	check(Rewards.completion_classes([],site.volumes,null).is_empty(),"unknown class defers")
	# Every ruins boss is killed through the real main signal; shared spirit can be carried/saved.
	for assignment in layout.assignments:
		if not assignment.boss: continue
		var actor = w.targeting.live[id+"/"+assignment.key]; actor.take_damage(1e9,p)
	var spirit_node
	for node in w.site_views[id].get_children():
		if node.get("item") != null and str(node.item.subtype).begins_with("spirit-"): spirit_node = node; break
	check(spirit_node != null,"actual boss death materializes spirit pickup")
	if spirit_node != null:
		var subtype: StringName = spirit_node.item.subtype
		p.pick_up(spirit_node); p.pick_up(spirit_node)
		check(p.inventory.entries.filter(func(it): return it.subtype == subtype).reduce(func(n,it): return n+it.count,0) == 1,"two pickup attempts award once")
	for broken in [null,[],true]:
		var invalid: Dictionary = main.save_data.capture(w.state_data,p)
		invalid.world.sites[id].spirit_levels = broken
		check(not main.save_data.validate(invalid),"malformed spirit-level parent rejected alongside existing kill receipts")
	check(main.save_now(),"actual rewards save: "+str(main.save_data.errors))
	for node in w.site_views[id].get_children():
		if node.get("item") != null and not node.is_queued_for_deletion(): node._ttl = 0; node._process(0)
	var after_expiry: Dictionary = site.rewards.duplicate(true)
	w.deliver_rewards(id)
	check(Save.same_data(site.rewards,after_expiry),"ordinary pickup expiry never refills issued rewards")
	var path: String = main.save_path; var before: Dictionary = site.rewards.duplicate(true)
	w.site_views[id].free(); w.site_views.erase(id); w.stream_sites(); stop(main)
	check(not w.site_views[id].get_children().any(func(n): return n.get("item") != null),"delivered ground loot retires on unload, never rematerializes")
	main.free()
	await process_frame
	var cold = MAIN.instantiate(); cold.save_path = path; root.add_child(cold); stop(cold)
	check(Save.same_data(cold.state_data.sites[id].rewards,before),"restart preserves fixed issued/delivered payloads")
	check(cold.get_node("Player").inventory.entries.any(func(it): return str(it.subtype).begins_with("spirit-")),"carried spirit persists through real main restart")
	cold.free()
	await process_frame
	print("encounter rewards ok" if failed == 0 else "encounter rewards FAILED")
	quit(0 if failed == 0 else 1)
