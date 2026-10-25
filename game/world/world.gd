## §3.1 world: one seed, zones streamed around `target` (gen-world neighbourhood, design.terrain.view-zones).
extends Node3D

const WorldGen := preload("res://game/world/world_gen.gd")
const ZoneMesh := preload("res://game/world/zone_mesh.gd")
const Spawner := preload("res://game/world/spawner.gd")
const Targeting := preload("res://game/combat/targeting.gd")
const EncounterGen := preload("res://game/world/encounter_gen.gd")
const EncounterSite := preload("res://game/world/encounter_site.gd")
const Contents := preload("res://game/world/encounter_contents.gd")
const BossSpecial := preload("res://game/combat/boss_special.gd")
const Rewards := preload("res://game/items/encounter_rewards.gd")
const Items := preload("res://game/items/items.gd")
const Shop := preload("res://game/items/shop.gd")
const Save := preload("res://game/world/save_data.gd")
const Item := preload("res://game/items/item.gd")
const Settlement := preload("res://game/world/settlement.gd")

@export var world_seed := 0  # 0 → design.terrain.seed-default (alpha server.cfg default)
var frame
var target: Node3D  # set by main.gd: camera for now, the player-character once §3.2 lands

signal state_changed
signal generation_failed(diagnostic: String)
var site_views: Dictionary = {}
var access_views: Dictionary = {}
var generation_error := ""
var state_data  # WorldState, owned by main/saved world, not streaming zones
var party_provider: Callable  # connected characters, including awaiting-respawn characters
var targeting: Node
var gen: WorldGen
var zones := {}  # Vector2i → MeshInstance3D (creatures are its children)
var villages := {}  # land coords → Village node (D22), streamed like zones
var design: Dictionary = {}  # generators.json#design; empty = no creatures
var creatures := {}  # OntologyDB.data.creatures
var rosters := {}  # creature-families.json#landscape-rosters
var ontology  # OntologyDB.data; set → creatures drop loot (items.gd)
var _zone_blocks: int
var _view: int
var _land_mat := StandardMaterial3D.new()
var _water_mat := StandardMaterial3D.new()


func _ready() -> void:
	for m in [_land_mat, _water_mat]:
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
	_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


## Inject before streaming. Neither world nor gameplay scripts access the ontology autoload.
func configure(p_ontology, p_design: Dictionary, saved_world, provider: Callable) -> void:
	ontology = p_ontology
	design = p_design
	state_data = saved_world
	party_provider = provider
	state_data.changed.connect(func(): state_changed.emit())
	world_seed = saved_world.seed
	creatures = ontology.creatures
	rosters = ontology.configs["creature-families"]["landscape-rosters"]
	gen = WorldGen.new(world_seed, design, ontology.landscapes)
	gen.saved_lands = state_data.lands
	state_data.refresh_site = refresh_site
	state_data.complete_on_exit = complete_supplier
	_zone_blocks = int(gen.terrain["zone-blocks"])
	_view = int(gen.terrain["view-zones"])
	targeting = Targeting.new()
	add_child(targeting)
	targeting.configure(design, provider)
	bind_saved_mobs(state_data.mobs, true)
	for site in state_data.sites.values():
		bind_saved_mobs(site.mobs, true)
		for mob in site.mobs.values():
			if mob.has("special"):
				BossSpecial.normalize_unload(
					mob.special, design["initial-encounters"]["special-profile"]
				)


## Register saved records even without live views, so unloaded site/ambient pairs still decay.
func bind_saved_mobs(source: Dictionary, restarted: bool = false) -> void:
	for id in source:
		var r: Dictionary = source[id].combat
		if restarted:
			# Caster entities disappeared during shutdown, but survivor pair memory did not.
			r.current = ""
			r.taunt = ""
			r.taunt_left = 0.0
		targeting.records[id] = r
		if not source[id].dead:
			targeting.members[id] = {"pack": source[id].pack, "hostility": source[id].hostility}


func party_levels() -> Array:
	var party: Array = party_provider.call() if party_provider.is_valid() else []
	if party.is_empty():
		return []
	var levels: Array = party.map(func(p): return p.level)
	return [levels.min(), levels.max()]


func _physics_process(dt: float) -> void:
	if state_data == null:
		return
	var positions: Array = []
	for p in party_provider.call():
		positions.append(Targeting.position_of(p))
	state_data.advance(dt / Engine.time_scale if Engine.time_scale > 0 else 0.0, positions)  # presentation hit-stop does not slow the clock
	for id in state_data.sites:
		restore_rubble(id)
		deliver_rewards(id)
	restock_vendors()


func capture_mobs() -> void:
	if targeting == null:
		return
	for mob in targeting.live.values():
		if is_instance_valid(mob) and not mob.incarnation.is_empty():
			mob.incarnation.position = mob.logical_position()
			mob.incarnation.hp = mob.hp


func populate_zone(zc: Vector2i) -> void:
	if state_data == null:
		return
	var levels := party_levels()
	if levels.is_empty():
		return  # defer materialization; never fabricate an empty-party level
	if not ensure_land(gen.land_of_block(zc.x * _zone_blocks, zc.y * _zone_blocks)):
		return
	var prefix := "%s/ambient/%d,%d" % [state_data.world_id, zc.x, zc.y]
	var plan_: Array = Spawner.plan(gen, zc, design, creatures, rosters, levels[0], levels[1])
	var made := Spawner.populate(
		zones[zc], plan_, design, creatures, target, ontology, targeting, prefix, state_data.mobs
	)
	for mob in made:
		mob.died.connect(func(): state_changed.emit())


func _process(_dt: float) -> void:
	if (
		gen == null
		or target == null
		or not gen.valid_block(
			float(target.logical_position()[0]), float(target.logical_position()[2])
		)
	):
		return
	var c := Vector2i(
		floori(float(target.logical_position()[0]) / _zone_blocks),
		floori(float(target.logical_position()[2]) / _zone_blocks)
	)
	for zc in zones.keys():
		if maxi(absi(zc.x - c.x), absi(zc.y - c.y)) > _view + 1:
			capture_mobs()
			zones[zc].queue_free()
			zones.erase(zc)
			state_changed.emit()
	# Materialize only genuinely eligible dead incarnations; loaded survivors are never replaced.
	if state_data != null:
		var renew := {}
		for id in state_data.mobs:
			var mob: Dictionary = state_data.mobs[id]
			if not mob.dead or not mob.eligible:
				continue
			var parts: PackedStringArray = id.split("/")[2].split(",")
			var zc := Vector2i(int(parts[0]), int(parts[1]))
			if zones.has(zc):
				renew[zc] = true
		for zc in renew:
			populate_zone(zc)
	if not ensure_land(
		gen.land_of_block(
			floori(float(target.logical_position()[0])), floori(float(target.logical_position()[2]))
		)
	):
		return
	_stream_village()
	stream_sites()
	# ponytail: nearest ring first, ≤ 2 zones per frame on the main thread; thread it when it hitches
	var built := 0
	for r in _view + 1:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if (
					maxi(absi(dx), absi(dy)) != r
					or not gen.valid_zone(c + Vector2i(dx, dy))
					or zones.has(c + Vector2i(dx, dy))
				):
					continue
				_spawn_zone(c + Vector2i(dx, dy))
				built += 1
				if built >= 2:
					return


func _spawn_zone(zc: Vector2i) -> void:
	if not gen.valid_zone(zc):
		return
	if (
		state_data != null
		and not ensure_land(gen.land_of_block(zc.x * _zone_blocks, zc.y * _zone_blocks))
	):
		return
	var mi := MeshInstance3D.new()
	mi.mesh = ZoneMesh.build(gen, zc)
	mi.mesh.surface_set_material(0, _land_mat)
	if mi.mesh.get_surface_count() > 1:
		mi.mesh.surface_set_material(1, _water_mat)
	mi.position = (
		frame.to_local([zc.x * _zone_blocks, 0, zc.y * _zone_blocks])
		if frame != null
		else Vector3(zc.x * _zone_blocks, 0, zc.y * _zone_blocks)
	)
	var body := StaticBody3D.new()  # land surface only (surface 0); water has no collision
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	mi.add_child(body)
	add_child(mi)
	zones[zc] = mi
	if frame != null:
		frame.track(mi)
	if not design.is_empty():
		populate_zone(zc)


## gen-settlement (D22): the village of the land under the player exists while its square is within view reach;
## villages sit ≥ 8 km inside their land, so no other land's village can be in reach.
func _stream_village() -> void:
	var here = gen.land_of_block(
		floori(float(target.logical_position()[0])), floori(float(target.logical_position()[2]))
	)
	var v := gen.village_at(here)
	var want := (
		here != null
		and not v.is_empty()
		and (
			(
				Vector2(
					float(target.logical_position()[0]) - v["centre"].x,
					float(target.logical_position()[2]) - v["centre"].y
				)
				. length()
			)
			< (_view + 1) * _zone_blocks
		)
	)
	for lc in villages.keys():
		if not want or lc != here.coords:
			villages[lc].queue_free()
			villages.erase(lc)
	if want and not villages.has(here.coords):
		villages[here.coords] = Settlement.build(
			v, gen.settlement, ontology.configs["npc-roles"], frame
		)
		add_child(villages[here.coords])
		if frame != null:
			frame.track(villages[here.coords])


## True once the zone under `pos` is built (the player waits for it instead of falling through).
func has_ground(pos: Vector3) -> bool:
	var logical: Array = frame.to_logical(pos) if frame != null else [pos.x, pos.y, pos.z]
	if target != null and frame != null:
		logical = target.logical_position()
	if not gen.valid_block(logical[0], logical[2]):
		return false
	var zc := Vector2i(
		floori(float(logical[0]) / _zone_blocks), floori(float(logical[2]) / _zone_blocks)
	)
	return gen.valid_zone(zc) and zones.has(zc)


## Publish complete land data only after geography AND every incarnation have succeeded.
func ensure_land(land) -> bool:
	if land == null:
		return false
	var key := "%d,%d" % [land.coords.x, land.coords.y]
	if state_data.lands.has(key):
		return true
	var levels := party_levels()
	if levels.is_empty():
		return false
	var plan_: Dictionary = gen.encounters_at(land)
	if plan_.is_empty():
		generation_error = "\n".join(gen.diagnostics)
		generation_failed.emit(generation_error)
		return false
	var staged := {}
	for layout in plan_.sites:
		var id: String = state_data.site_id(land.coords, layout.family, layout.ordinal)
		var site := {
			"id": id,
			"family": layout.family,
			"volumes": layout.volumes.duplicate(true),
			"pending": false,
			"cleared": false,
			"completed": false,
			"cycle": 0,
			"mobs": {},
			"rewards": {},
			"spirit_levels": {},
			"room_levels": EncounterGen.room_levels(gen, land, layout, levels, 0),
			"contents": EncounterGen.fresh_contents(layout, design["initial-encounters"])
		}
		for stable in layout.assignments:
			var mob_id: String = id + "/" + stable.key
			site.mobs[mob_id] = EncounterGen.incarnation(
				gen,
				land,
				stable,
				mob_id,
				levels,
				design,
				0,
				(
					int(site.room_levels[int(stable.pack)])
					if layout.family == "ruins" and not stable.boss
					else 0
				)
			)
			if layout.family == "ruins" and not stable.boss:
				site.mobs[mob_id].room_cycle = 0
			if stable.spirit != "":
				site.spirit_levels[stable.key] = site.mobs[mob_id].level
		stage_tables(site, layout, 0)
		staged[id] = site
	state_data.lands[key] = plan_.duplicate(true)
	state_data.sites.merge(staged)
	for site in staged.values():
		bind_saved_mobs(site.mobs)
	state_changed.emit()
	return true


func site_layout(id: String) -> Dictionary:
	var parts := id.split("/")
	var plan_: Dictionary = state_data.lands[parts[2]]
	for layout in plan_.sites:
		if layout.family == parts[3] and layout.ordinal == int(parts[4]):
			return layout
	return {}


func populate_site(id: String) -> void:
	var site: Dictionary = state_data.sites[id]
	var layout := site_layout(id)
	for stable in layout.assignments:
		var mob_id: String = id + "/" + stable.key
		var saved: Dictionary = site.mobs[mob_id]
		if saved.dead or targeting.live.has(mob_id):
			continue
		var size_: float = (
			EncounterGen.height(saved.level, design["initial-encounters"])
			if stable.boss
			else float(design.spawns["size-by-category"].undead)
		)
		var colour := Color.WHITE
		for rarity in ontology.rarities.values():
			if rarity.index == int(stable.tier):
				colour = Color(rarity.raw.hex)
				break
		var mob := Spawner.materialize(
			site_views[id], saved, mob_id, design, target, targeting, size_, colour
		)
		mob.set_meta("encounter_site", id)
		mob.set_meta("assignment", stable.key)
		if stable.boss:
			mob.special = BossSpecial.new()
			mob.special.kind = stable.special
			mob.special.setup(
				mob,
				saved.special,
				design["initial-encounters"]["special-profile"],
				site_views[id].get_node("Contents")
			)
		mob.died.connect(site_death.bind(id, stable, mob))


## Safe daily refresh is invoked by WorldState only when the entire closed union is empty.
## Completion-before-refresh is shared by conversation and automatic last-player exit.
func refresh_site(id: String) -> bool:
	var site: Dictionary = state_data.sites[id]
	if site.family == "supplier" and (site.completed or site.cleared):
		return false
	var levels := party_levels()
	if levels.is_empty():
		return false
	var layout := site_layout(id)
	var parts := id.split("/")[2].split(",")
	var land = gen.land_at(Vector2i(int(parts[0]), int(parts[1])))
	site.room_levels = EncounterGen.room_levels(gen, land, layout, levels, int(site.cycle) + 1)
	# Rubble uses independent 72-hour deadlines, never daily furnishing renewal.
	var fresh_contents := EncounterGen.fresh_contents(layout, design["initial-encounters"])
	site.contents.props = fresh_contents.props
	site.contents.traps = fresh_contents.traps
	stage_tables(site, layout, int(site.cycle) + 1)
	if site_views.has(id):
		var contents = site_views[id].get_node("Contents")
		contents.saved = site.contents
		contents.sync_views()
		# WorldState increments the coalesced cycle only after this callback returns.
		contents.call_deferred("deliver_furnishings")
	for stable in layout.assignments:
		var mob_id: String = id + "/" + stable.key
		var old: Dictionary = site.mobs[mob_id]
		if not old.dead:
			continue
		var fresh := EncounterGen.incarnation(
			gen,
			land,
			stable,
			mob_id,
			levels,
			design,
			int(old.cycle) + 1,
			(
				int(site.room_levels[int(stable.pack)])
				if layout.family == "ruins" and not stable.boss
				else 0
			)
		)
		if layout.family == "ruins" and not stable.boss:
			fresh.room_cycle = int(site.cycle) + 1
		site.mobs[mob_id] = fresh
		targeting.records[mob_id] = fresh.combat
		targeting.members[mob_id] = {"pack": fresh.pack, "hostility": fresh.hostility}
	site.cleared = false
	return true


func stream_sites() -> void:
	var reach := float((_view + 1) * _zone_blocks)
	for id in site_views.keys():
		var layout := site_layout(id)
		if (
			(
				Vector2(
					float(target.logical_position()[0]) - layout.centre[0],
					float(target.logical_position()[2]) - layout.centre[1]
				)
				. length()
			)
			> reach + float(design["initial-encounters"].ruins.bounds[1])
		):
			capture_mobs()
			unload_specials(id)
			site_views[id].free()
			site_views.erase(id)
			state_changed.emit()
	for id in state_data.sites:
		var layout := site_layout(id)
		if (
			(
				Vector2(
					float(target.logical_position()[0]) - layout.centre[0],
					float(target.logical_position()[2]) - layout.centre[1]
				)
				. length()
			)
			> reach
		):
			continue
		if not site_views.has(id):
			site_views[id] = EncounterSite.build(
				layout, design["initial-encounters"], design, frame
			)
			add_child(site_views[id])
			if frame != null:
				frame.track(site_views[id])
			for child in site_views[id].get_children():
				if child.get("role") == &"captive":
					child.set_meta("encounter_site", id)
			var contents := Contents.new()
			site_views[id].add_child(contents)
			contents.setup(self, id, layout)
		populate_site(id)
		deliver_rewards(id)
	for key in access_views.keys():
		var v: Dictionary = state_data.lands[key].village
		if (
			(
				Vector2(
					float(target.logical_position()[0]) - v.centre[0],
					float(target.logical_position()[2]) - v.centre[1]
				)
				. length()
			)
			> reach + float(design["initial-encounters"]["distance-max"])
		):
			access_views[key].free()
			access_views.erase(key)
	for key in state_data.lands:
		var plan_: Dictionary = state_data.lands[key]
		var v: Dictionary = plan_.village
		if (
			(
				(
					Vector2(
						float(target.logical_position()[0]) - v.centre[0],
						float(target.logical_position()[2]) - v.centre[1]
					)
					. length()
				)
				<= reach + float(design["initial-encounters"]["distance-max"])
			)
			and not access_views.has(key)
		):
			access_views[key] = EncounterSite.roads(plan_, design, frame)
			add_child(access_views[key])
			if frame != null:
				frame.track(access_views[key])


## Discontinuous owner relocation: capture before exit; never translate an old neighborhood by a world-sized delta.
func retire_views() -> void:
	capture_mobs()
	for id in site_views:
		unload_specials(id)
	for views in [zones, villages, site_views, access_views]:
		for view in views.values():
			remove_child(view)
			view.queue_free()
		views.clear()


func unload_specials(id: String) -> void:
	for mob_id in state_data.sites[id].mobs:
		var mob = targeting.live.get(mob_id)
		if is_instance_valid(mob) and mob.special != null:
			mob.special.unload()


func stage_tables(site: Dictionary, layout: Dictionary, cycle: int) -> void:
	var cfg: Dictionary = design["initial-encounters"]
	var plan_ := EncounterGen.content_plan(layout, cfg)
	for key in plan_.props:
		if plan_.props[key].kind != "table":
			continue
		var rules: Dictionary = cfg.furnishings.table
		var level: int = int(site.room_levels[plan_.props[key].room])
		var potion = Item.stack(
			&"consumable", StringName(rules.potion), int(rules["potion-count"]), level
		)
		potion.rarity = int(rules["potion-rarity"])
		var pair := [
			Item.stack(&"ingredient", StringName(rules.flask), int(rules["flask-count"])), potion
		]
		site.rewards["furnishing/%d/%s" % [cycle, key]] = {
			"payload": pair.map(Save.item_data), "delivered": false, "level": level
		}


## World-clock restoration also runs for unloaded sites, with saved actors included.
func restore_rubble(id: String) -> void:
	var site: Dictionary = state_data.sites[id]
	if not site.contents.rubble.values().any(
		func(r): return r.broken and state_data.clock >= r.restore_at
	):
		return
	var positions: Array = party_provider.call().map(Targeting.position_of)
	if state_data.inside(site.volumes, positions):
		return
	var layout := site_layout(id)
	var plan_ := EncounterGen.content_plan(layout, design["initial-encounters"])
	var changed := false
	for key in site.contents.rubble:
		var record: Dictionary = site.contents.rubble[key]
		if not record.broken or state_data.clock < record.restore_at:
			continue
		var point: Array = plan_.rubble[key]
		var occupied := false
		for mob_id in site.mobs:
			var mob: Dictionary = site.mobs[mob_id]
			if mob.dead:
				continue
			var live = targeting.live.get(mob_id)
			var p: Array = live.logical_position() if is_instance_valid(live) else mob.position
			var stable: Dictionary = layout.assignments.filter(func(a): return id + "/" + a.key == mob_id)[0]
			var height_: float = (
				EncounterGen.height(mob.level, design["initial-encounters"])
				if stable.boss
				else float(design.spawns["size-by-category"].undead)
			)
			if overlaps_voxel(point, p, height_ * 0.25, height_):
				occupied = true
		if layout.has("captive") and overlaps_voxel(point, layout.captive, 0.4, 1.8):
			occupied = true
		# Unloaded ambient incarnations can overlap a due block too.
		for mob_id in state_data.mobs:
			var mob: Dictionary = state_data.mobs[mob_id]
			if mob.dead:
				continue
			var species = ontology.creatures[StringName(mob.species)]
			var category: String = (
				preload("res://ontology/model.gd")
				. CreatureCategory
				. keys()[species.category]
				. to_lower()
				. replace("_", "-")
			)
			var size_: float = design.spawns["size-by-category"].get(category, 1.0)
			var live = targeting.live.get(mob_id)
			var p: Array = live.logical_position() if is_instance_valid(live) else mob.position
			if overlaps_voxel(point, p, size_ * 0.25, size_):
				occupied = true
		# Physical actors include wanderers from outside the saved site's designated roster.
		if is_inside_tree():
			var q := PhysicsShapeQueryParameters3D.new()
			var box_ := BoxShape3D.new()
			box_.size = Vector3.ONE
			q.shape = box_
			q.transform.origin = (
				frame.to_local(point) if frame != null else Vector3(point[0], point[1], point[2])
			)
			q.transform.origin.y += 0.5
			for hit in get_world_3d().direct_space_state.intersect_shape(q, 128):
				if hit.collider is CharacterBody3D or hit.collider.is_in_group("npcs"):
					occupied = true
		if occupied:
			continue
		record.broken = false
		record.restore_at = 0.0
		changed = true
	if changed:
		if site_views.has(id):
			site_views[id].get_node("Contents").sync_views()
		state_changed.emit()


static func overlaps_voxel(point: Array, feet: Array, radius: float, height_: float) -> bool:
	return (
		absf(float(point[0]) - feet[0]) <= 0.5 + radius
		and absf(float(point[2]) - feet[2]) <= 0.5 + radius
		and feet[1] <= point[1] + 1
		and feet[1] + height_ >= point[1]
	)


## Creature's own died handler commits incarnation/finisher XP before this connected callback.
func site_death(id: String, stable: Dictionary, mob: Node3D) -> void:
	var site: Dictionary = state_data.sites[id]
	var saved: Dictionary = mob.incarnation
	var key := "kill/%d/%s" % [saved.cycle, stable.key]
	if site.rewards.has(key):
		return
	var spirit_level: int = int(site.spirit_levels[stable.key]) if stable.spirit != "" else 0
	var payload := Rewards.kill_payload(
		stable, int(saved.cycle), int(saved.level), spirit_level, ontology, design
	)
	state_data.issue_reward(id, key, payload.map(Save.item_data))
	site.rewards[key].level = int(saved.level)
	site.rewards[key].position = mob.logical_position()
	site.cleared = site.mobs.values().all(func(m): return m.dead)
	if site.cleared and site.family != "ruins":
		var layout := site_layout(id)
		var boss: Dictionary = layout.assignments.filter(func(a): return a.boss)[0]
		var mission := "mission/%d" % site.cycle
		var classes := Rewards.completion_classes(
			party_provider.call(), site.volumes, mob.last_attacker
		)
		var cls: String = (
			classes[Rewards.rng_for(id + "/" + mission + "/class").randi_range(
				0, classes.size() - 1
			)]
			if not classes.is_empty()
			else ""
		)
		site.rewards[mission] = {
			"payload": [],
			"delivered": false,
			"level": int(site.mobs[id + "/" + boss.key].level),
			"classes": classes,
			"class_id": cls
		}
		resolve_package(id, mission)
	deliver_rewards(id)
	state_changed.emit()


func resolve_package(id: String, key: String) -> void:
	var record: Dictionary = state_data.sites[id].rewards[key]
	if record.class_id == "" or not record.payload.is_empty():
		return
	var layout := site_layout(id)
	record.payload = (
		Rewards
		. package_payload(
			id + "/" + key,
			int(layout.tier),
			int(record.level),
			StringName(record.class_id),
			ontology,
			design
		)
		. map(Save.item_data)
	)


func deliver_rewards(id: String) -> void:
	var site: Dictionary = state_data.sites[id]
	for key in site.rewards:
		if key.begins_with("furnishing/"):
			continue
		var record: Dictionary = site.rewards[key]
		if record.delivered:
			continue
		var point: Array
		if key.begins_with("mission/"):
			if record.class_id == "":
				for member in party_provider.call():
					if state_data.inside(site.volumes, [Targeting.position_of(member)]):
						record.class_id = Rewards.class_of(member)
						resolve_package(id, key)
						state_changed.emit()
						break
			if record.class_id == "" or (site.family == "supplier" and not site.completed):
				continue
			var layout := site_layout(id)
			point = (
				layout.captive.duplicate()
				if site.family == "supplier"
				else [layout.centre[0], layout.floor, layout.centre[1]]
			)
			point[1] += (
				float(design["initial-encounters"]["mission-package"]["delivery-height"]) - 0.5
			)  # spawn_drops supplies its usual half block
		else:
			point = record.position
		if not site_views.has(id) or not site_views[id].is_inside_tree():
			continue
		record.delivered = true  # durable before callbacks expose shared ordinary pickups
		var pos: Vector3 = (
			frame.to_local(point) if frame != null else Vector3(point[0], point[1], point[2])
		)
		Items.spawn_drops(
			site_views[id],
			pos,
			record.payload.map(Save.item_from),
			Rewards.rng_for(id + "/" + key + "/scatter"),
			ontology,
			design
		)
		state_changed.emit()


func on_talked(npc: Node) -> void:
	if npc.get("role") == &"captive" and npc.has_meta("encounter_site"):
		complete_supplier(npc.get_meta("encounter_site"))


func complete_supplier(id: String) -> bool:
	var site: Dictionary = state_data.sites[id]
	if (
		site.family != "supplier"
		or site.completed
		or not site.cleared
		or not site_layout(id).has("captive")
	):
		return false
	site.completed = true
	site.pending = false
	deliver_rewards(id)
	state_changed.emit()
	return true


func supplier_ceiling(coords: Vector2i) -> int:
	var count := int(ontology.rarities[StringName(design.settlement.shop["rarity-cap"])].index)
	for ordinal in design["initial-encounters"].supplier.tiers.size():
		var id: String = state_data.site_id(coords, "supplier", ordinal)
		if state_data.sites.has(id) and state_data.sites[id].completed:
			count += 1
	return count


func vendor_stock(role: StringName, player_level: int, coords: Vector2i) -> Array:
	var land = gen.land_at(coords)
	if not Shop.is_vendor(role) or not ensure_land(land):
		return []
	if role == &"item-vendor":
		return Shop.stock(role, gen, land, gen.village_at(land), player_level, ontology, design)
	var key := "%d,%d/%s" % [coords.x, coords.y, role]
	var day := floori(state_data.clock / float(design.time["day-s"]))
	if not state_data.vendors.has(key) or state_data.vendors[key].day != day:
		var cap := supplier_ceiling(coords)
		var items := Shop.stock(
			role, gen, land, gen.village_at(land), player_level, ontology, design, cap, day
		)
		state_data.vendors[key] = {
			"day": day, "ceiling": cap, "level": player_level, "items": items.map(Save.item_data)
		}
		state_changed.emit()
	return state_data.vendors[key].items.map(Save.item_from)


func buy_vendor(role: StringName, index: int, player, coords: Vector2i, expected = null) -> bool:
	var stock := vendor_stock(role, player.level, coords)
	if (
		index < 0
		or index >= stock.size()
		or (
			expected != null
			and not Save.same_data(Save.item_data(expected), Save.item_data(stock[index]))
		)
	):
		return false
	# Remove authoritative gear BEFORE Inventory.changed can expose/save the purchase.
	var key := "%d,%d/%s" % [coords.x, coords.y, role]
	if player.inventory.coins < Shop.buy_price(stock[index], ontology, design):
		return false
	if role != &"item-vendor":
		state_data.vendors[key].items.remove_at(index)
	Shop.buy(player, stock[index])
	state_changed.emit()
	return true


func restock_vendors() -> void:
	var levels := party_levels()
	if levels.is_empty():
		return
	var day := floori(state_data.clock / float(design.time["day-s"]))
	for key in state_data.vendors.keys():
		if state_data.vendors[key].day == day:
			continue
		var parts: PackedStringArray = key.split("/")
		var xy: PackedStringArray = parts[0].split(",")
		vendor_stock(StringName(parts[1]), int(levels[0]), Vector2i(int(xy[0]), int(xy[1])))
