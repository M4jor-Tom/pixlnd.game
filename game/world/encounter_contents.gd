## Disposable physical views; all renewal, HP, trap phases and deadlines belong to the saved site.
extends Node3D
const Gen := preload("res://game/world/encounter_gen.gd")
const Prop := preload("res://game/world/encounter_prop.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Save := preload("res://game/world/save_data.gd")
const Targeting := preload("res://game/combat/targeting.gd")
var world
var site_id: String
var layout: Dictionary
var cfg: Dictionary
var saved: Dictionary
var plan: Dictionary
var rubble: Dictionary = {}
var props: Dictionary = {}
var traps: Array = []

func setup(owner_world, id: String, site_layout: Dictionary) -> void:
	world = owner_world; site_id = id; layout = site_layout; cfg = world.design["initial-encounters"]
	saved = world.state_data.sites[id].contents; plan = Gen.content_plan(layout,cfg)
	name = "Contents"
	for key in plan.rubble:
		var body := StaticBody3D.new(); body.set_meta("rubble",key)
		add_body(body,plan.rubble[key],Vector3.ONE*float(cfg.rubble["voxel-size"]),Color.SLATE_GRAY)
		rubble[key] = body
	for key in plan.props:
		var body := Prop.new(); body.contents = self; body.key = key
		var table: bool = plan.props[key].kind == "table"
		add_body(body,plan.props[key].point,Vector3(2,1,1) if table else Vector3(0.7,1,0.7),Color.SADDLE_BROWN if table else Color.SANDY_BROWN)
		props[key] = body
	for trap in plan.traps:
		var mi := MeshInstance3D.new(); var mesh_ := BoxMesh.new()
		mesh_.size = Vector3(cfg.spikes.footprint[0],0.04,cfg.spikes.footprint[1]); mi.mesh = mesh_
		mi.material_override = StandardMaterial3D.new(); add_child(mi)
		mi.global_position = native(trap.point)+Vector3.UP*0.025
		var spikes := Node3D.new(); spikes.name = "Spikes"; mi.add_child(spikes)
		for x in [-0.5,0.5]:
			for z in [-0.5,0.5]:
				var spike := MeshInstance3D.new(); var cone := CylinderMesh.new()
				cone.top_radius = 0; cone.bottom_radius = 0.25; cone.height = float(cfg.spikes["victim-height"][1])
				spike.mesh = cone; spike.material_override = StandardMaterial3D.new(); spike.material_override.albedo_color = Color.SILVER
				spike.position = Vector3(x*cfg.spikes.footprint[0]/2,cone.height/2,z*cfg.spikes.footprint[1]/2); spikes.add_child(spike)
		traps.append(mi)
	sync_views()
	deliver_furnishings()

func native(point: Array) -> Vector3:
	return world.frame.to_local(point) if world.frame != null else Vector3(point[0],point[1],point[2])

func add_body(body: StaticBody3D, point: Array, size_: Vector3, colour: Color) -> void:
	var cs := CollisionShape3D.new(); cs.name = "Collision"; var shape := BoxShape3D.new(); shape.size = size_; cs.shape = shape
	var mi := MeshInstance3D.new(); var mesh_ := BoxMesh.new(); mesh_.size = size_; mi.mesh = mesh_
	mi.material_override = StandardMaterial3D.new(); mi.material_override.albedo_color = colour
	body.add_child(cs); body.add_child(mi); add_child(body)
	body.global_position = native(point)+Vector3.UP*size_.y/2

func sync_views() -> void:
	for key in rubble:
		rubble[key].visible = not saved.rubble[key].broken
		rubble[key].collision_layer = 0 if saved.rubble[key].broken else 1
	for key in props:
		props[key].visible = saved.props[key].hp > 0
		props[key].collision_layer = 1 if saved.props[key].hp > 0 else 0
	for i in traps.size():
		var phase: String = saved.traps[i].phase
		traps[i].material_override.albedo_color = Color.RED if phase == "active" else (Color.ORANGE if phase == "warning" else Color.DIM_GRAY)
		traps[i].get_node("Spikes").visible = phase == "active"

func _physics_process(dt: float) -> void:
	var near := false
	for p in world.party_provider.call():
		if Targeting.distance_squared(Targeting.position_of(p),[layout.centre[0],layout.floor,layout.centre[1]]) <= pow(float(world.design.spawns.ai["sim-radius"]),2): near = true
	if near: advance(dt)

func eligible(trap: Dictionary, p) -> bool:
	var point := Targeting.position_of(p); var at: Array = trap.point
	var h: Array = cfg.spikes["victim-height"]
	return not p.get("dead") and absf(float(point[0])-at[0]) <= float(cfg.spikes.footprint[0])/2 and absf(float(point[2])-at[2]) <= float(cfg.spikes.footprint[1])/2 and point[1] >= at[1]+h[0] and point[1] <= at[1]+h[1]

func hit_trap(i: int) -> void:
	var record: Dictionary = saved.traps[i]
	for p in world.party_provider.call():
		var id := Targeting.identity(p); var view = Targeting.view_of(p)
		if eligible(plan.traps[i],p) and not id in record.hit and view != null:
			record.hit.append(id) # durable before exposing damage/callbacks
			view.take_hazard_damage(float(cfg.spikes.damage),self)

func advance(dt: float) -> void:
	for i in traps.size():
		var record: Dictionary = saved.traps[i]; var remaining := dt
		while true:
			if record.phase == "idle":
				if not world.party_provider.call().any(func(p): return eligible(plan.traps[i],p)): break
				record.phase = "warning"; record.left = float(cfg.spikes["warning-s"]); record.hit = []
				for p in world.party_provider.call():
					var view = Targeting.view_of(p)
					if view != null and view.feel != null: view.feel.sfx(StringName(cfg.spikes["warning-sfx"])); break
			if record.phase == "active": hit_trap(i)
			var step := minf(remaining,float(record.left)); record.left = maxf(0,record.left-step); remaining -= step
			if record.left > 0: break
			match record.phase:
				"warning": record.phase = "active"; record.left = float(cfg.spikes["active-s"]); hit_trap(i)
				"active": record.phase = "cooldown"; record.left = float(cfg.spikes["cooldown-s"])
				"cooldown": record.phase = "idle"; record.left = 0.0; record.hit = []
			if remaining <= 0: break
		sync_views()

func deliver_furnishings() -> void:
	if not is_inside_tree() or not is_instance_valid(world): return # deferred renewal may outlive a retired view
	var site: Dictionary = world.state_data.sites[site_id]
	for id in site.rewards:
		if not id.begins_with("furnishing/"): continue
		var key := "/".join(id.split("/").slice(2))
		var point: Array = plan.props[key].point.duplicate()
		if plan.props[key].kind == "table": point[1] += props[key].get_node("Collision").shape.size.y
		deliver(id,point)

## Minimal furnishing delivery seam; later shared rewards may consume the same plain issued payload.
func deliver(id: String, point: Array) -> bool:
	var reward: Dictionary = world.state_data.sites[site_id].rewards[id]
	if reward.delivered or not is_inside_tree(): return false
	reward.delivered = true
	var rng := RandomNumberGenerator.new(); rng.seed = hash(site_id+id)
	Items.spawn_drops(get_parent(),native(point),reward.payload.map(Save.item_from),rng,world.ontology,world.design)
	world.state_changed.emit()
	return true

func damage_prop(key: String, amount: float, from: Node) -> void:
	if from == null or (not from.has_method("on_kill") and from.get("special") == null): return
	var record: Dictionary = saved.props[key]
	if record.hp <= 0 or amount <= 0: return
	record.hp = maxf(0,record.hp-amount)
	if record.hp == 0 and plan.props[key].kind == "vase":
		var site: Dictionary = world.state_data.sites[site_id]
		var rules: Dictionary = cfg.furnishings.vase
		var count := int(rules["coin-base"])+int(rules["coin-per-level"])*int(site.room_levels[plan.props[key].room])
		var id := "furnishing/%d/%s" % [site.cycle,key]
		world.state_data.issue_reward(site_id,id,[Save.item_data(Item.stack(&"coin",&"",count))])
		site.rewards[id].level = int(site.room_levels[plan.props[key].room])
		deliver(id,plan.props[key].point)
	sync_views(); world.state_changed.emit()

func break_rubble(key: String) -> void:
	var record: Dictionary = saved.rubble[key]
	if record.broken: return
	record.broken = true; record.restore_at = world.state_data.clock+float(cfg.rubble["restore-world-hours"])*3600
	sync_views(); world.state_changed.emit()

func shatter_stomp(point: Array, radius: float, damage: float, from: Node) -> void:
	for key in plan.rubble:
		var p: Array = plan.rubble[key]
		if Vector2(float(p[0])-point[0],float(p[2])-point[2]).length() <= radius: break_rubble(key)
	for key in plan.props:
		var p: Array = plan.props[key].point
		if Vector2(float(p[0])-point[0],float(p[2])-point[2]).length() <= radius: damage_prop(key,damage,from)

func restore_due() -> void:
	world.restore_rubble(site_id)
	sync_views()
