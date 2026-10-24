## Initial encounter geography and stable assignments. Plain JSON data; no nodes or mutable incarnations.
## Cardinal layouts keep block geometry exact, including at the finite world's large coordinates.
extends RefCounted
const Settlement := preload("res://game/world/settlement.gd")
const Spawner := preload("res://game/world/spawner.gd")
const Combat := preload("res://game/combat/combat.gd")
const Targeting := preload("res://game/combat/targeting.gd")

static func rotate(x: float, z: float, turn: int) -> Vector2:
	match posmod(turn,4):
		1: return Vector2(-z,x)
		2: return Vector2(-x,-z)
		3: return Vector2(z,-x)
	return Vector2(x,z)

static func point(site: Dictionary, x: float, z: float) -> Vector2:
	return Vector2(site.centre[0],site.centre[1])+rotate(x,z,site.turn)

static func rect(site: Dictionary, local: Array) -> Array:
	var a := point(site,local[0],local[1]); var b := point(site,local[2],local[3])
	return [minf(a.x,b.x),minf(a.y,b.y),maxf(a.x,b.x),maxf(a.y,b.y)]

static func make_site(gen, land, centre: Vector2i, turn: int, family: String, ordinal: int, cfg: Dictionary) -> Dictionary:
	var rules: Dictionary = cfg[family]
	var site := {"family":family,"ordinal":ordinal,"centre":[centre.x,centre.y],"turn":turn,
		"floor":maxi(gen._raw_height(centre.x,centre.y)+1,gen.sea_level+int(cfg["dry-above-sea"])),
		"components":[],"volumes":[],"assignments":[]}
	var rng := RandomNumberGenerator.new(); rng.seed = land.land_seed ^ hash(family+str(ordinal))
	var rooms: Array = []
	if family == "ruins":
		var r: Dictionary = rules
		var x := -float(r.bounds[0])/2; var right: float = x+r.room[0]
		var z := -float(r.bounds[1])/2
		site.components.append([x,z,right,z+r.court[1]]); z += r.court[1]
		var middle: float = x+r.room[0]/2.0
		site.components.append([middle-r.passage[0]/2.0,z,middle+r.passage[0]/2.0,z+r.passage[1]]); z += r.passage[1]
		for i in r["pack-tiers"].size():
			var room := [x,z,right,z+r.room[1]]; rooms.append(room); site.components.append(room); z += r.room[1]
			if i < r["pack-tiers"].size()-1:
				site.components.append([middle-r.corridor[0]/2.0,z,middle+r.corridor[0]/2.0,z+r.corridor[1]]); z += r.corridor[1]
		site.components.append([right,rooms[1][1]+r.room[1]/3.0,right+r.alcove[0],rooms[1][1]+r.room[1]/3.0+r.alcove[1]])
		site.entry = [middle,-float(r.bounds[1])/2]
	else:
		var half := float(rules.size)/2
		site.components.append([-half,-half,half,half]); site.entry = [0,-half]
		rooms = [[-half,-half,0,0],[0,0,half,half]]
		site.tier = rules.tier if family == "camp" else rules.tiers[ordinal]
		if family == "supplier":
			var captive := point(site,0,half/2)
			site.captive = [captive.x,site.floor,captive.y]
	for component in site.components:
		var b := rect(site,component)
		site.volumes.append([b[0],site.floor+rules.occupancy[0],b[1],b[2],site.floor+rules.occupancy[1],b[3]])
	for i in rooms.size():
		var room: Array = rooms[i]
		var cx: float = (room[0]+room[2])/2; var cz: float = (room[1]+room[3])/2
		var role := Spawner._roll_role(cfg["role-weights"],rng)
		var tier: int = rules["pack-tiers"][i] if family == "ruins" else site.tier
		for member in int(cfg["pack-size"]):
			# Spread guards across the room, outside its central four-wide traversal lane.
			var offset: float = (member-(cfg["pack-size"]-1)/2.0)*float(rules.room[1] if family == "ruins" else rules.size/2)/4
			assignment(site,str(i),member,cx-(room[2]-room[0])/4,cz+offset,tier,false,role,rng,cfg)
	var tiers: Array = rules["boss-tiers"] if family == "ruins" else [site.tier]
	for i in tiers.size():
		var room: Array = rooms[i+1] if family == "ruins" else site.components[0]
		var cx: float = (room[0]+room[2])/2; var cz: float = (room[1]+room[3])/2
		assignment(site,str(rooms.size()+i),0,cx+(room[2]-room[0])/4,cz,tiers[i],true,Spawner._roll_role(cfg["role-weights"],rng),rng,cfg)
	return site

static func assignment(site: Dictionary, pack: String, member: int, x: float, z: float, tier: int, boss: bool, role: String, rng: RandomNumberGenerator, cfg: Dictionary) -> void:
	var p := point(site,x,z)
	site.assignments.append({"key":pack+"/"+str(member),"pack":pack,"home":[p.x,site.floor,p.y],"role":role,"tier":tier,"boss":boss,
		"seed":rng.randi(),"special":Spawner._roll_role(cfg["boss-specials"],rng) if boss else "",
		"spirit":Spawner._roll_role(cfg.spirits,rng) if boss and site.family == "ruins" else ""})

## Route slabs are both the authored walkable surface and its physics shape, including ocean boardwalks.
static func route(points: Array, start: float, finish: float, cfg: Dictionary) -> Dictionary:
	var length := 0.0
	for i in range(1,points.size()): length += (points[i]-points[i-1]).length()
	if absf(finish-start) > floorf(length)*float(cfg["max-step"]): return {}
	var out := {"points":[],"steps":[]}; var travelled := 0.0
	for p in points: out.points.append([p.x,p.y])
	for i in range(1,points.size()):
		var delta: Vector2 = points[i]-points[i-1]; var dist := delta.length()
		if dist == 0: continue
		var count := ceili(dist); var unit := delta/dist
		for n in count:
			var t := (n+0.5)/count
			# Keep scalar coordinates in double precision until the mesh is made relative to its origin.
			var px: float = points[i-1].x+float(delta.x)*t; var pz: float = points[i-1].y+float(delta.y)*t
			var top := roundf(lerpf(start,finish,(travelled+dist*t)/length))
			out.steps.append({"x":px,"z":pz,"top":top,"width":cfg["path-width"],"length":dist/count,"dx":unit.x,"dz":unit.y})
		travelled += dist
	return out

## SAT: actual rotated service-building footprints against a four-wide straight square-to-gate route.
static func clear_gate(v: Dictionary, settlement: Dictionary, end: Vector2, width: float) -> bool:
	var origin := Vector2(v.centre.x,v.centre.y)
	var delta := end-origin; var u := delta.normalized(); var side := Vector2(-u.y,u.x)
	var buildings := Settlement.layout(v,settlement)
	for i in buildings.size():
		if i == v.get("gate_index",-1): continue # the physical builder cuts this empty house's walk-through
		var building: Dictionary = buildings[i]
		var c := Vector2(building.centre.x,building.centre.z)
		var bx := Vector2(cos(building.yaw),-sin(building.yaw)); var bz := Vector2(sin(building.yaw),cos(building.yaw))
		var separated := false
		for axis: Vector2 in [u,side,bx,bz]:
			var distance := absf((c-(origin+end)/2).dot(axis))
			var reach: float = absf(u.dot(axis))*delta.length()/2+absf(side.dot(axis))*width/2+absf(bx.dot(axis))*building.size.x/2+absf(bz.dot(axis))*building.size.z/2
			if distance > reach: separated = true; break
		if not separated: return false
	return true

static func plan(gen, land, v: Dictionary, cfg: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new(); rng.seed = land.land_seed ^ hash("initial-encounters")
	var radius := rng.randi_range(int(cfg["distance-min"])+1,int(cfg["distance-max"]))
	var a := roundi(radius/2.0); var b := roundi(radius*sqrt(3.0)/2)
	var offsets := [Vector2i(radius,0),Vector2i(a,b),Vector2i(-a,b),Vector2i(-radius,0),Vector2i(-a,-b),Vector2i(a,-b)]
	var shift := rng.randi_range(0,offsets.size()-1)
	var sites: Array = []
	for i in offsets.size():
		var offset: Vector2i = offsets[(i+shift)%offsets.size()]
		var turn := 3 if offset.x > 0 else 1
		if absi(offset.y) > absi(offset.x): turn = 0 if offset.y > 0 else 2
		var family := "ruins" if i == 0 else ("camp" if i == 1 else "supplier")
		sites.append(make_site(gen,land,v.centre+offset,turn,family,maxi(0,i-2),cfg))
	var centre := Vector2(v.centre.x,v.centre.y)
	var ring := float(gen.settlement["no-hostiles-within"])+float(cfg["path-width"])+float(cfg.apron)
	var gate := Vector2.ZERO
	for i in gen.settlement.buildings.size():
		if gen.settlement.buildings[i] != "house": continue
		v.gate_index = i
		var angle: float = TAU*i/gen.settlement.buildings.size()
		var end := centre+Vector2(cos(angle),sin(angle))*ring
		if clear_gate(v,gen.settlement,end,float(cfg["path-width"])): gate = end; break
	if gate == Vector2.ZERO: return {"error":"no four-wide collision-free village gate"}
	var building: Dictionary = Settlement.layout(v,gen.settlement)[v.gate_index]
	v.gate_offset = (centre-Vector2(building.centre.x,building.centre.z)).dot(Vector2(cos(building.yaw),-sin(building.yaw)))
	var routes: Array = [route([centre,gate],v.height+1,v.height+1,cfg)]
	# A complete square ring, outside town's protection, gives every branch a common reachable hub.
	var corners := [centre+Vector2(-ring,-ring),centre+Vector2(ring,-ring),centre+Vector2(ring,ring),centre+Vector2(-ring,ring)]
	var corner: Vector2 = corners[0]
	for p in corners:
		if p.distance_squared_to(gate) < corner.distance_squared_to(gate): corner = p
	routes.append(route([gate,Vector2(corner.x,gate.y),corner],v.height+1,v.height+1,cfg))
	for i in corners.size(): routes.append(route([corners[i],corners[(i+1)%corners.size()]],v.height+1,v.height+1,cfg))
	for site in sites:
		var entry := point(site,site.entry[0],site.entry[1])
		var front := rotate(0,-1,site.turn); var approach := entry+front*float(cfg.apron)
		var start := centre+Vector2(clampf(approach.x-centre.x,-ring,ring),clampf(approach.y-centre.y,-ring,ring))
		var bend := Vector2(approach.x,start.y) if front.y != 0 else Vector2(start.x,approach.y)
		var road := route([start,bend,approach,entry],v.height+1,site.floor,cfg)
		if road.is_empty(): return {"error":"access exceeds one-block step slope: "+site.family+str(site.ordinal)}
		routes.append(road)
	var out := {"village":{"centre":[v.centre.x,v.centre.y],"height":v.height,"name":v.name,"style":str(v.style),"hub":v.hub,"gate_index":v.gate_index,"gate_width":cfg["path-width"],"gate_offset":v.gate_offset},"sites":sites,"routes":routes}
	var errors := validate(gen,out,cfg)
	return out if errors.is_empty() else {"error":"; ".join(errors)}

static func validate(gen, plan_: Dictionary, cfg: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var v: Dictionary = plan_.village
	var square := Vector2(v.centre[0],v.centre[1])
	var half := float(cfg["hub-size"])/2
	if not gen.valid_block(square.x-half,square.y-half) or not gen.valid_block(square.x+half,square.y+half): errors.append("village hub outside finite bounds")
	for site in plan_.sites:
		var centre := Vector2(site.centre[0],site.centre[1]); var distance := centre.distance_to(square)
		if distance < cfg["distance-min"] or distance > cfg["distance-max"]: errors.append("site distance "+site.family)
		for other in plan_.sites:
			if other != site and centre.distance_to(Vector2(other.centre[0],other.centre[1])) < cfg.separation: errors.append("site separation")
		for volume in site.volumes:
			if not gen.valid_block(volume[0]-cfg.apron,volume[2]-cfg.apron) or not gen.valid_block(volume[3]+cfg.apron,volume[5]+cfg.apron): errors.append("site/apron outside finite bounds")
		for m in site.assignments:
			if Vector2(m.home[0],m.home[2]).distance_to(square)-float(gen.ai_leash) < float(gen.settlement["no-hostiles-within"]): errors.append("home/pursuit crosses protected village")
	for road in plan_.routes:
		if road.is_empty(): errors.append("empty route"); continue
		for step in road.steps:
			var r: float = float(step.width)/2+step.length/2
			if not gen.valid_block(step.x-r,step.z-r) or not gen.valid_block(step.x+r,step.z+r): errors.append("route outside finite bounds"); break
	return errors

static func height(level: int, cfg: Dictionary) -> float:
	var h: Dictionary = cfg["boss-height"]
	return float(h.base)*(float(h["min-mult"])+float(h.growth)*(clampi(level,1,int(h["max-level"]))-1)/(float(h["max-level"])-1))

static func incarnation(gen, land, stable: Dictionary, id: String, levels: Array, design: Dictionary, cycle: int = 0, room_level: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new(); rng.seed = int(stable.seed) ^ hash("incarnation"+str(cycle))
	var level: int = room_level if room_level > 0 else gen.creature_level(land,levels[0],levels[1],rng)
	var cfg: Dictionary = design["initial-encounters"]
	var power := float(cfg["power-base-offset"])+int(stable.tier)
	var hp := Combat.enemy_max_hp(level,power)*(float(cfg["boss-hp-mult"]) if stable.boss else 1.0)
	var out := {"species":cfg.species,"level":level,"power_base":power,"max_hp":hp,"hp":hp,
		"damage":Combat.enemy_damage(level,power,design.combat)*(float(cfg["boss-damage-mult"]) if stable.boss else 1.0),
		"hostility":"H","role":stable.role,"home":stable.home.duplicate(),"position":stable.home.duplicate(),"pack":id.get_base_dir(),
		"seed":stable.seed,"dead":false,"eligible":false,"cycle":cycle,"combat":Targeting.fresh()}
	if stable.boss:
		out.special = {"phase":"ready","left":cfg["special-profile"]["ready-s"],"recovery":0.0,"engaged":false,"origin":[],"endpoint":[],"target":""}
	return out

## A separate stream never perturbs permanent geography/roles/special/spirit draws.
static func room_levels(gen, land, layout: Dictionary, levels: Array, cycle: int) -> Array:
	var out: Array = []
	if layout.family != "ruins": return out
	for i in layout.components.size():
		if i not in [2,4,6]: continue
		var rng := RandomNumberGenerator.new(); rng.seed = land.land_seed ^ hash("room-level/"+str(i)+"/"+str(cycle))
		out.append(gen.creature_level(land,levels[0],levels[1],rng))
	return out

## Authored decorations stay off the central four-wide route and all door/exit/support masks.
static func content_plan(layout: Dictionary, cfg: Dictionary) -> Dictionary:
	var out := {"rubble":{},"props":{},"traps":[]}
	for stable in layout.assignments:
		if not stable.boss: continue
		var offsets := [[-2,-2],[0,-3],[0,-2],[-3,0],[-2,2],[0,3],[0,2],[-2,0]]
		for i in int(cfg.rubble["per-arena"]):
			var offset := rotate(offsets[i][0],offsets[i][1],layout.turn)
			out.rubble[stable.key+"/"+str(i)] = [float(stable.home[0])+offset.x,layout.floor,float(stable.home[2])+offset.y]
	if layout.family == "ruins":
		for room in cfg.ruins["pack-tiers"].size():
			var r: Array = layout.components[2+room*2]
			var middle: float = (r[1]+r[3])/2
			for vase in int(cfg.furnishings.vase["per-room"]):
				var p := point(layout,r[0]+3,middle+(-8 if vase == 0 else 8))
				out.props["room/%d/vase/%d" % [room,vase]] = {"point":[p.x,layout.floor,p.y],"kind":"vase","room":room}
			var table := point(layout,r[2]-3,middle+8)
			out.props["room/%d/table/0" % room] = {"point":[table.x,layout.floor,table.y],"kind":"table","room":room}
			if room < int(cfg.spikes.count):
				var trap := point(layout,r[0]+3,middle)
				out.traps.append({"point":[trap.x,layout.floor,trap.y]})
	return out

static func fresh_contents(layout: Dictionary, cfg: Dictionary) -> Dictionary:
	var plan_ := content_plan(layout,cfg)
	var out := {"rubble":{},"props":{},"traps":[]}
	for key in plan_.rubble: out.rubble[key] = {"broken":false,"restore_at":0.0}
	for key in plan_.props: out.props[key] = {"hp":cfg.furnishings[plan_.props[key].kind].hp}
	for trap in plan_.traps: out.traps.append({"phase":"idle","left":0.0,"hit":[]})
	return out
