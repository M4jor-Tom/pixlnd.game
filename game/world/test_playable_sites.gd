extends SceneTree
const Model := preload("res://ontology/model.gd")
const Gen := preload("res://game/world/world_gen.gd")
const State := preload("res://game/world/world_state.gd")
var failed := 0
func check(ok: bool,label: String) -> void:
	if not ok: failed += 1; printerr("FAIL: ",label)
func _init() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var d: Dictionary = o.configs.generators.design
	var g := Gen.new(26879,d,o.landscapes)
	if not g.has_method("encounters_at"):
		check(false,"real joint six-site generation interface"); quit(1); return
	for seed_ in [26879,1,7,9001]:
		var a := Gen.new(seed_,d,o.landscapes)
		var b := Gen.new(seed_,d,o.landscapes)
		for lc in [Vector2i.ZERO,Vector2i(-512,-512),Vector2i(511,511),Vector2i(-5,7)]:
			var land = a.land_at(lc)
			var plan_: Dictionary = a.encounters_at(land)
			check(not plan_.is_empty(),"complete joint plan "+str([seed_,lc,a.diagnostics]))
			if plan_.is_empty(): continue
			check(plan_ == b.encounters_at(b.land_at(lc)),"seed determinism")
			check(plan_.sites.size() == 6,"all six sites")
			var homes := 0; var bosses := 0; var captives := 0
			var v: Dictionary = plan_.village
			check(a.height_at(v.centre[0],v.centre[1]) in [int(v.height),int(v.height)-1] and v.height >= a.sea_level+3,"dry village square support below actual access surface")
			for site in plan_.sites:
				var distance := Vector2(site.centre[0]-v.centre[0],site.centre[1]-v.centre[1]).length()
				check(distance >= 192 and distance <= 215,"canonical site distance")
				for other in plan_.sites:
					if other == site: continue
					check(Vector2(site.centre[0]-other.centre[0],site.centre[1]-other.centre[1]).length() >= 192,"site separation")
				check(site.floor >= a.sea_level+4,"dry flat floor")
				for m in site.assignments:
					homes += 1
					if m.boss: bosses += 1
					check(Vector2(m.home[0]-v.centre[0],m.home[2]-v.centre[1]).length()-d.spawns.ai.leash >= d.settlement["no-hostiles-within"],"protected pursuit envelope")
					check(State.inside(site.volumes,[Vector3(m.home[0],m.home[1],m.home[2])]),"home in closed playable union")
				if site.family == "supplier": captives += 1
				for volume in site.volumes:
					check(State.inside(site.volumes,[Vector3(volume[0],volume[1],volume[2])]) and State.inside(site.volumes,[Vector3(volume[3],volume[4],volume[5])]),"closed volume corners")
				if site.family == "ruins":
					check(site.components.size() == 8,"three rooms/two corridors/court/passage/alcove")
					check(not State.inside(site.volumes,[Vector3(site.centre[0]+17,site.floor,site.centre[1]+50)]),"envelope void excluded (orientation checked by runtime test)") if site.turn == 0 else null
			check(homes == 46 and bosses == 7 and captives == 4,"46 skeletons / seven bosses / four captives")
			for route in plan_.routes:
				var previous: Variant = null
				for step in route.steps:
					check(step.width == 4,"four-wide real route slab")
					check(a.valid_block(step.x,step.z),"route finite bounds")
					if previous != null: check(absf(step.top-previous.top) <= 1,"route steps at most one block")
					previous = step
	# All-sea failure of the old village search must yield the actual settlement/hub, not no village.
	var ocean := Gen.new(3,d,o.landscapes)
	ocean._h_base = 0; ocean._h_amp = 0
	var sea_plan: Dictionary = ocean.encounters_at(ocean.land_at(Vector2i.ZERO))
	check(not sea_plan.is_empty() and sea_plan.village.hub,"all-sea village fallback")
	if not sea_plan.is_empty():
		var centre: Array = sea_plan.village.centre
		for x in range(-32,32):
			for z in range(-32,32): check(ocean.height_at(centre[0]+x,centre[1]+z) >= ocean.sea_level+1,"entire 64-square hub dry")
		var boardwalk: Dictionary = sea_plan.routes[-1].steps[sea_plan.routes[-1].steps.size()/2]
		check(ocean.height_at(roundi(boardwalk.x),roundi(boardwalk.z)) < ocean.sea_level,"ocean bed remains below a real boardwalk, not a filled causeway")
	# Impossible actual bounds: complete diagnostic, never a partial publication.
	var impossible := Gen.new(3,d,o.landscapes); impossible.land_blocks = 64
	var no_plan: Dictionary = impossible.encounters_at(impossible.land_at(Vector2i.ZERO))
	check(no_plan.is_empty() and not impossible.diagnostics.is_empty(),"atomic impossible generation diagnosed")
	print("playable sites generation ok" if failed == 0 else "playable sites generation FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
