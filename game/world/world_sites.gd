## Stateless site lifecycle; mutable records remain on WorldState and views on World.
extends RefCounted
const Model := preload("res://ontology/model.gd")
const Spawner := preload("res://game/world/spawner.gd")
const Targeting := preload("res://game/combat/targeting.gd")
const EncounterGen := preload("res://game/world/encounter_gen.gd")
const BossSpecial := preload("res://game/combat/boss_special.gd")


static func ensure_land(world, land) -> bool:
	if land == null:
		return false
	var key := "%d,%d" % [land.coords.x, land.coords.y]
	if world.state_data.lands.has(key):
		return true
	var levels: Array = world.party_levels()
	if levels.is_empty():
		return false
	var plan_: Dictionary = world.gen.encounters_at(land)
	if plan_.is_empty():
		world.generation_error = "\n".join(world.gen.diagnostics)
		world.generation_failed.emit(world.generation_error)
		return false
	return _stage_land(world, land, key, levels, plan_)


## Completion returns distinguish a native abort from a successfully staged record.
static func _stage_site(world, land, layout, levels: Array, staged: Dictionary) -> bool:
	var id: String = world.state_data.site_id(land.coords, layout.family, layout.ordinal)
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
		"room_levels": EncounterGen.room_levels(world.gen, land, layout, levels, 0),
		"contents": EncounterGen.fresh_contents(layout, world.design["initial-encounters"])
	}
	for stable in layout.assignments:
		if not _stage_incarnation(world, land, layout, stable, levels, id, site):
			return false
	world.stage_tables(site, layout, 0)
	staged[id] = site
	return true


static func _stage_incarnation(
	world, land, layout, stable, levels: Array, id: String, site: Dictionary
) -> bool:
	var mob_id: String = id + "/" + stable.key
	var fresh = _initial_incarnation(world, land, layout, stable, mob_id, levels, site)
	if fresh == null:
		return false
	site.mobs[mob_id] = fresh
	if layout.family == "ruins" and not stable.boss:
		site.mobs[mob_id].room_cycle = 0
	if stable.spirit != "":
		site.spirit_levels[stable.key] = site.mobs[mob_id].level
	return true


static func site_layout(world, id: String) -> Dictionary:
	var parts := id.split("/")
	var plan_: Dictionary = world.state_data.lands[parts[2]]
	for layout in plan_.sites:
		if layout.family == parts[3] and layout.ordinal == int(parts[4]):
			return layout
	return {}


static func populate_site(world, id: String) -> void:
	var site: Dictionary = world.state_data.sites[id]
	var layout: Dictionary = world.site_layout(id)
	for stable in layout.assignments:
		if not _populate_assignment(world, id, site, stable):
			return


static func _populate_assignment(world, id: String, site: Dictionary, stable) -> bool:
	var mob_id: String = id + "/" + stable.key
	var saved: Dictionary = site.mobs[mob_id]
	if (
		saved.dead
		or world.targeting.live.has(mob_id)
		or not world._actor_ground_ready(saved.position)
	):
		return true
	var size_: float = (
		EncounterGen.height(saved.level, world.design["initial-encounters"])
		if stable.boss
		else float(world.design.spawns["size-by-category"].undead)
	)
	return _materialize(world, id, stable, mob_id, saved, size_)


static func _materialize(
	world, id: String, stable, mob_id: String, saved: Dictionary, size_: float
) -> bool:
	var colour := Color.WHITE
	for rarity in world.ontology.rarities.values():
		if rarity.index == int(stable.tier):
			colour = Color(rarity.raw.hex)
			break
	var mob := Spawner.materialize(
		world.site_views[id],
		saved,
		mob_id,
		world.design,
		world.target,
		world.targeting,
		size_,
		colour
	)
	mob.set_meta("encounter_site", id)
	mob.set_meta("assignment", stable.key)
	if stable.boss:
		mob.special = BossSpecial.new()
		mob.special.kind = stable.special
		mob.special.setup(
			mob,
			saved.special,
			world.design["initial-encounters"]["special-profile"],
			world.site_views[id].get_node("Contents")
		)
	mob.died.connect(world.site_death.bind(id, stable, mob))
	return true


static func refresh_site(world, id: String) -> bool:
	var site: Dictionary = world.state_data.sites[id]
	if site.family == "supplier" and (site.completed or site.cleared):
		return false
	var levels: Array = world.party_levels()
	if levels.is_empty():
		return false
	var layout: Dictionary = world.site_layout(id)
	var parts := id.split("/")[2].split(",")
	var land = world.gen.land_at(Vector2i(int(parts[0]), int(parts[1])))
	if not _refresh_contents(world, id, site, layout, land, levels):
		return false
	return _renew_site_mobs(world, id, site, layout, land, levels)


static func _refresh_contents(
	world, id: String, site: Dictionary, layout: Dictionary, land, levels: Array
) -> bool:
	site.room_levels = EncounterGen.room_levels(
		world.gen, land, layout, levels, int(site.cycle) + 1
	)
	# Rubble uses independent 72-hour deadlines, never daily furnishing renewal.
	var fresh_contents := EncounterGen.fresh_contents(layout, world.design["initial-encounters"])
	site.contents.props = fresh_contents.props
	site.contents.traps = fresh_contents.traps
	world.stage_tables(site, layout, int(site.cycle) + 1)
	if world.site_views.has(id):
		var contents = world.site_views[id].get_node("Contents")
		contents.saved = site.contents
		contents.sync_views()
		# WorldState increments the coalesced cycle only after this callback returns.
		contents.call_deferred("deliver_furnishings")
	return true


static func _renew_incarnation(
	world, id: String, site: Dictionary, layout: Dictionary, land, levels: Array, stable
) -> bool:
	var mob_id: String = id + "/" + stable.key
	var old: Dictionary = site.mobs[mob_id]
	if not old.dead:
		return true
	var fresh = _renewed_incarnation(world, land, stable, mob_id, levels, old, site, layout)
	if fresh == null:
		return false
	if layout.family == "ruins" and not stable.boss:
		fresh.room_cycle = int(site.cycle) + 1
	site.mobs[mob_id] = fresh
	world.targeting.records[mob_id] = fresh.combat
	world.targeting.members[mob_id] = {"pack": fresh.pack, "hostility": fresh.hostility}
	return true


static func unload_specials(world, id: String) -> void:
	for mob_id in world.state_data.sites[id].mobs:
		var mob = world.targeting.live.get(mob_id)
		if is_instance_valid(mob) and mob.special != null:
			mob.special.unload()


static func restore_rubble(world, id: String) -> void:
	var site: Dictionary = world.state_data.sites[id]
	if not site.contents.rubble.values().any(
		func(r): return r.broken and world.state_data.clock >= r.restore_at
	):
		return
	_restore_unoccupied(world, id, site)


## null propagates a moved native abort without exposing a later restore or notification.
static func _restore_block(
	world, id: String, site: Dictionary, layout: Dictionary, plan_: Dictionary, key
) -> Variant:
	var record: Dictionary = site.contents.rubble[key]
	if not record.broken or world.state_data.clock < record.restore_at:
		return false
	var point: Array = plan_.rubble[key]
	var occupied = _content_occupancy(world, id, site, layout, point)
	if occupied == null:
		return null
	if occupied:
		return false
	record.broken = false
	record.restore_at = 0.0
	return true


static func _site_occupancy(
	world, id: String, site: Dictionary, layout: Dictionary, point: Array
) -> Variant:
	var occupied := false
	for mob_id in site.mobs:
		var overlap = _site_mob_occupancy(world, id, site, layout, point, mob_id)
		if overlap == null:
			return null
		if overlap:
			occupied = true
	return occupied


static func _ambient_occupancy(world, point: Array) -> Variant:
	var occupied := false
	for mob_id in world.state_data.mobs:
		var mob: Dictionary = world.state_data.mobs[mob_id]
		if mob.dead:
			continue
		var species = world.ontology.creatures[StringName(mob.species)]
		var category: String = Model.CreatureCategory.keys()[species.category].to_lower().replace(
			"_", "-"
		)
		var size_: float = world.design.spawns["size-by-category"].get(category, 1.0)
		var live = world.targeting.live.get(mob_id)
		var p: Array = live.logical_position() if is_instance_valid(live) else mob.position
		if world.overlaps_voxel(point, p, size_ * 0.25, size_):
			occupied = true
	return occupied


static func _physical_occupancy(world, point: Array) -> Variant:
	if world.is_inside_tree():
		var q := PhysicsShapeQueryParameters3D.new()
		var box_ := BoxShape3D.new()
		box_.size = Vector3.ONE
		q.shape = box_
		q.transform.origin = (
			world.frame.to_local(point)
			if world.frame != null
			else Vector3(point[0], point[1], point[2])
		)
		q.transform.origin.y += 0.5
		return _physical_hits(world, q)
	return false


static func overlaps_voxel(point: Array, feet: Array, radius: float, height_: float) -> bool:
	return (
		absf(float(point[0]) - feet[0]) <= 0.5 + radius
		and absf(float(point[2]) - feet[2]) <= 0.5 + radius
		and feet[1] <= point[1] + 1
		and feet[1] + height_ >= point[1]
	)


static func _stage_land(world, land, key: String, levels: Array, plan_: Dictionary) -> bool:
	var staged := {}
	for layout in plan_.sites:
		if not _stage_site(world, land, layout, levels, staged):
			return false
	world.state_data.lands[key] = plan_.duplicate(true)
	world.state_data.sites.merge(staged)
	for site in staged.values():
		world.bind_saved_mobs(site.mobs)
	world.state_changed.emit()
	return true


static func _initial_incarnation(
	world, land, layout, stable, mob_id: String, levels: Array, site: Dictionary
) -> Variant:
	return EncounterGen.incarnation(
		world.gen,
		land,
		stable,
		mob_id,
		levels,
		world.design,
		0,
		(
			int(site.room_levels[int(stable.pack)])
			if layout.family == "ruins" and not stable.boss
			else 0
		)
	)


static func _renewed_incarnation(
	world,
	land,
	stable,
	mob_id: String,
	levels: Array,
	old: Dictionary,
	site: Dictionary,
	layout: Dictionary
) -> Variant:
	return EncounterGen.incarnation(
		world.gen,
		land,
		stable,
		mob_id,
		levels,
		world.design,
		int(old.cycle) + 1,
		(
			int(site.room_levels[int(stable.pack)])
			if layout.family == "ruins" and not stable.boss
			else 0
		)
	)


static func _renew_site_mobs(
	world, id: String, site: Dictionary, layout: Dictionary, land, levels: Array
) -> bool:
	for stable in layout.assignments:
		if not _renew_incarnation(world, id, site, layout, land, levels, stable):
			return false
	site.cleared = false
	return true


static func _restore_unoccupied(world, id: String, site: Dictionary) -> void:
	var positions: Array = world.party_provider.call().map(Targeting.position_of)
	if world.state_data.inside(site.volumes, positions):
		return
	var layout: Dictionary = world.site_layout(id)
	var plan_ := EncounterGen.content_plan(layout, world.design["initial-encounters"])
	var changed = _restore_records(world, id, site, layout, plan_)
	if changed == null:
		return
	if changed:
		if world.site_views.has(id):
			world.site_views[id].get_node("Contents").sync_views()
		world.state_changed.emit()


static func _content_occupancy(
	world, id: String, site: Dictionary, layout: Dictionary, point: Array
) -> Variant:
	var occupied = _saved_site_occupancy(world, id, site, layout, point)
	if occupied == null:
		return null
	var ambient = _ambient_occupancy(world, point)
	if ambient == null:
		return null
	occupied = ambient or occupied
	var physical = _physical_occupancy(world, point)
	if physical == null:
		return null
	occupied = physical or occupied
	return occupied


static func _site_mob_occupancy(
	world, id: String, site: Dictionary, layout: Dictionary, point: Array, mob_id
) -> Variant:
	var mob: Dictionary = site.mobs[mob_id]
	if mob.dead:
		return false
	var live = world.targeting.live.get(mob_id)
	var p: Array = live.logical_position() if is_instance_valid(live) else mob.position
	var stable: Dictionary = layout.assignments.filter(func(a): return id + "/" + a.key == mob_id)[0]
	var height_: float = (
		EncounterGen.height(mob.level, world.design["initial-encounters"])
		if stable.boss
		else float(world.design.spawns["size-by-category"].undead)
	)
	return world.overlaps_voxel(point, p, height_ * 0.25, height_)


static func _physical_hits(world, q: PhysicsShapeQueryParameters3D) -> Variant:
	var occupied := false
	for hit in world.get_world_3d().direct_space_state.intersect_shape(q, 128):
		if hit.collider is CharacterBody3D or hit.collider.is_in_group("npcs"):
			occupied = true
	return occupied


static func _restore_records(
	world, id: String, site: Dictionary, layout: Dictionary, plan_: Dictionary
) -> Variant:
	var changed := false
	for key in site.contents.rubble:
		var restored = _restore_block(world, id, site, layout, plan_, key)
		if restored == null:
			return null
		if restored:
			changed = true
	return changed


static func _saved_site_occupancy(
	world, id: String, site: Dictionary, layout: Dictionary, point: Array
) -> Variant:
	var occupied = _site_occupancy(world, id, site, layout, point)
	if occupied == null:
		return null
	if layout.has("captive") and world.overlaps_voxel(point, layout.captive, 0.4, 1.8):
		occupied = true
	return occupied
