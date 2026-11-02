## Main-thread streaming phases; World owns every view, queue and saved-state reference.
extends RefCounted
const Spawner := preload("res://game/world/spawner.gd")
const EncounterSite := preload("res://game/world/encounter_site.gd")
const Contents := preload("res://game/world/encounter_contents.gd")
const Settlement := preload("res://game/world/settlement.gd")


static func process(world) -> void:
	world._poll_terrain()
	if (
		world.gen == null
		or world.target == null
		or not world.gen.valid_block(
			float(world.target.logical_position()[0]), float(world.target.logical_position()[2])
		)
	):
		return
	var c := Vector2i(
		floori(float(world.target.logical_position()[0]) / world._zone_blocks),
		floori(float(world.target.logical_position()[2]) / world._zone_blocks)
	)
	_stream_neighbourhood(world, c)


static func _stream_neighbourhood(world, c: Vector2i) -> void:
	if not _retire_zones(world, c) or not _retry_ambient(world):
		return
	if not world.ensure_land(
		world.gen.land_of_block(
			floori(float(world.target.logical_position()[0])),
			floori(float(world.target.logical_position()[2]))
		)
	):
		return
	world._stream_village()
	world.stream_sites()
	_request_ring(world, c)


static func _retire_zones(world, c: Vector2i) -> bool:
	for zc in world.zones.keys():
		if maxi(absi(zc.x - c.x), absi(zc.y - c.y)) > world._view + 1:
			world.capture_mobs()
			world.zones[zc].queue_free()
			world.zones.erase(zc)
			world.state_changed.emit()
	return true


static func _retry_ambient(world) -> bool:
	# Materialize only genuinely eligible dead incarnations; loaded survivors are never replaced.
	if world.state_data == null:
		return true
	var renew: Dictionary = world._pending_ambient.duplicate()
	if not _eligible_zones(world, renew):
		return false
	for zc in renew:
		if world.zones.has(zc):
			world.populate_zone(zc)
		else:
			world._pending_ambient.erase(zc)
	return true


static func _eligible_zones(world, renew: Dictionary) -> bool:
	for id in world.state_data.mobs:
		if not _eligible_zone(world, renew, id):
			return false
	return true


static func _eligible_zone(world, renew: Dictionary, id) -> bool:
	var mob: Dictionary = world.state_data.mobs[id]
	if not mob.dead or not mob.eligible:
		return true
	var parts: PackedStringArray = id.split("/")[2].split(",")
	var zc := Vector2i(int(parts[0]), int(parts[1]))
	if world.zones.has(zc):
		renew[zc] = true
	return true


static func _request_ring(world, c: Vector2i) -> void:
	# Nearest ring first; worker requests never build terrain on this thread.
	for r in world._view + 1:
		var requested = _request_radius(world, c, r)
		if requested == null or requested:
			return


# null is native incompletion, false means this ring had no request; both stop/continue at the caller.
static func _request_radius(world, c: Vector2i, r: int) -> Variant:
	for dy in range(-r, r + 1):
		var requested = _request_row(world, c, r, dy)
		if requested == null or requested:
			return requested
	return false


static func _request_row(world, c: Vector2i, r: int, dy: int) -> Variant:
	for dx in range(-r, r + 1):
		var occupied = _ring_occupied(world, c, r, dx, dy)
		if occupied == null:
			return null
		if occupied:
			continue
		world._spawn_zone(c + Vector2i(dx, dy))
		return true
	return false


static func _ring_occupied(world, c: Vector2i, r: int, dx: int, dy: int) -> Variant:
	return (
		maxi(absi(dx), absi(dy)) != r
		or not world.gen.valid_zone(c + Vector2i(dx, dy))
		or world.zones.has(c + Vector2i(dx, dy))
	)


static func spawn_zone(world, zc: Vector2i) -> void:
	if not world.gen.valid_zone(zc):
		return
	if (
		world.state_data != null
		and not world.ensure_land(
			world.gen.land_of_block(zc.x * world._zone_blocks, zc.y * world._zone_blocks)
		)
	):
		return
	_request_zone(world, zc)


static func _request_zone(world, zc: Vector2i) -> void:
	var land = world.gen.land_of_block(zc.x * world._zone_blocks, zc.y * world._zone_blocks)
	var key := "%d,%d" % [land.coords.x, land.coords.y]
	var status: Error = world._terrain_worker.request(
		zc, world._terrain_epoch, not world.guidance.has(key)
	)
	if status != OK and status != ERR_BUSY:
		world.generation_error = "terrain worker start failed: " + error_string(status)
		world.generation_failed.emit(world.generation_error)


static func poll_terrain(world) -> void:
	if world._terrain_worker == null:
		return
	# Even a cheap guide result is published a frame after its ready terrain.
	var packets: Array = world._pending_guidance
	world._pending_guidance = []
	if not _take_packets(world, packets):
		return
	_publish_packets(world, packets)


static func _publish_packets(world, packets: Array) -> void:
	for packet in packets:
		if not _publish_packet(world, packet):
			return


static func _take_packets(world, packets: Array) -> bool:
	for packet in world._terrain_worker.poll():
		if packet.kind == "guidance":
			world._pending_guidance.append(packet)
		else:
			packets.append(packet)
	return true


static func _publish_packet(world, packet) -> bool:
	if packet.epoch != world._terrain_epoch or world.target == null:
		return true
	var logical: Array = world.target.logical_position()
	var here := Vector2i(
		floori(float(logical[0]) / world._zone_blocks),
		floori(float(logical[2]) / world._zone_blocks)
	)
	if maxi(absi(packet.zone.x - here.x), absi(packet.zone.y - here.y)) > world._view + 1:
		return true
	return _accept_packet(world, packet)


static func _accept_packet(world, packet) -> bool:
	if packet.kind == "terrain":
		if not world.zones.has(packet.zone):
			world._publish_zone(packet.zone, packet.surfaces)
	else:
		if not packet.error.is_empty():
			push_warning("Optional guidance omitted: " + str(packet.error))
		world.guidance[packet.land] = packet.routes.duplicate(true)
	return true


static func marker_clear(world, marker: Dictionary, prospective: Dictionary) -> bool:
	var occupied = _live_occupancy(world, marker)
	if occupied == null or occupied:
		return false
	occupied = _saved_occupancy(world, marker)
	if occupied == null or occupied:
		return false
	var levels: Array = world.party_levels()
	if levels.is_empty():
		return false
	return _prospective_clear(world, marker, prospective, levels)


static func _live_occupancy(world, marker: Dictionary) -> Variant:
	var actors: Array = world.party_provider.call() if world.party_provider.is_valid() else []
	if world.targeting != null:
		actors.append_array(world.targeting.live.values())
	for actor in actors:
		if is_instance_valid(actor) and world._marker_near(marker, actor.logical_position()):
			return true
	return false


static func _saved_occupancy(world, marker: Dictionary) -> Variant:
	# ponytail: O(markers × saved mobs) per view publication; index by zone if large saves make this costly.
	var occupied = _mobs_occupancy(world, marker, world.state_data.mobs)
	if occupied == null or occupied:
		return occupied
	for site in world.state_data.sites.values():
		occupied = _mobs_occupancy(world, marker, site.mobs)
		if occupied == null or occupied:
			return occupied
	return false


static func _mobs_occupancy(world, marker: Dictionary, mobs) -> Variant:
	for mob in mobs.values():
		if world._marker_near(marker, mob.home) or world._marker_near(marker, mob.position):
			return true
	return false


static func _prospective_clear(
	world, marker: Dictionary, prospective: Dictionary, levels: Array
) -> bool:
	# Include neighbouring zone sources whose configured spread can reach the marker's actor halo.
	var pad := 3 + int(world.design.spawns["group-spread"])
	for x in range(
		floori((marker.x - pad) / world._zone_blocks),
		floori((marker.x + pad) / world._zone_blocks) + 1
	):
		if not _prospective_column(world, marker, prospective, levels, pad, x):
			return false
	return true


static func _prospective_column(
	world, marker: Dictionary, prospective: Dictionary, levels: Array, pad: int, x: int
) -> bool:
	for z in range(
		floori((marker.z - pad) / world._zone_blocks),
		floori((marker.z + pad) / world._zone_blocks) + 1
	):
		var zone := Vector2i(x, z)
		if not _prospective_zone(world, marker, prospective, levels, zone):
			return false
	return true


static func _prospective_zone(
	world, marker: Dictionary, prospective: Dictionary, levels: Array, zone: Vector2i
) -> bool:
	if not world.gen.valid_zone(zone):
		return true
	if not prospective.has(zone):
		prospective[zone] = Spawner.plan(
			world.gen, zone, world.design, world.creatures, world.rosters, levels[0], levels[1]
		)
	return _planned_clear(world, marker, prospective[zone])


static func _planned_clear(world, marker: Dictionary, groups) -> bool:
	for group in groups:
		for at in group.positions:
			if world._marker_near(marker, [at.x, at.y, at.z]):
				return false
	return true


static func stream_village(world) -> void:
	var here = world.gen.land_of_block(
		floori(float(world.target.logical_position()[0])),
		floori(float(world.target.logical_position()[2]))
	)
	var v: Dictionary = world.gen.village_at(here)
	var want = _village_wanted(world, here, v)
	if want == null:
		return
	if not _retire_villages(world, here, want):
		return
	_publish_village(world, here, v, want)


static func _publish_village(world, here, v: Dictionary, want) -> void:
	if want and not world.villages.has(here.coords):
		world.villages[here.coords] = Settlement.build(
			v, world.gen.settlement, world.ontology.configs["npc-roles"], world.frame
		)
		world.add_child(world.villages[here.coords])
		if world.frame != null:
			world.frame.track(world.villages[here.coords])


static func _village_wanted(world, here, v: Dictionary) -> Variant:
	return (
		here != null
		and not v.is_empty()
		and (
			(
				Vector2(
					float(world.target.logical_position()[0]) - v["centre"].x,
					float(world.target.logical_position()[2]) - v["centre"].y
				)
				. length()
			)
			< (world._view + 1) * world._zone_blocks
		)
	)


static func _retire_villages(world, here, want) -> bool:
	for lc in world.villages.keys():
		if not want or lc != here.coords:
			world.villages[lc].queue_free()
			world.villages.erase(lc)
	return true


static func stream_sites(world) -> void:
	var reach := float((world._view + 1) * world._zone_blocks)
	if not _retire_sites(world, reach) or not _nearby_sites(world, reach):
		return
	if not _retire_access(world, reach):
		return
	_publish_access(world, reach)


static func _retire_sites(world, reach: float) -> bool:
	for id in world.site_views.keys():
		var layout: Dictionary = world.site_layout(id)
		if (
			(
				Vector2(
					float(world.target.logical_position()[0]) - layout.centre[0],
					float(world.target.logical_position()[2]) - layout.centre[1]
				)
				. length()
			)
			> reach + float(world.design["initial-encounters"].ruins.bounds[1])
		):
			world.capture_mobs()
			world.unload_specials(id)
			world.site_views[id].free()
			world.site_views.erase(id)
			world.state_changed.emit()
	return true


static func _nearby_sites(world, reach: float) -> bool:
	for id in world.state_data.sites:
		var layout: Dictionary = world.site_layout(id)
		if (
			(
				Vector2(
					float(world.target.logical_position()[0]) - layout.centre[0],
					float(world.target.logical_position()[2]) - layout.centre[1]
				)
				. length()
			)
			> reach
		):
			continue
		if not _stream_site(world, id, layout):
			return false
	return true


static func _stream_site(world, id, layout: Dictionary) -> bool:
	if not world.site_views.has(id):
		if not _publish_site(world, id, layout):
			return false
	world.populate_site(id)
	world.deliver_rewards(id)
	return true


static func _publish_site(world, id, layout: Dictionary) -> bool:
	world.site_views[id] = EncounterSite.build(
		layout, world.design["initial-encounters"], world.design, world.frame
	)
	world.add_child(world.site_views[id])
	if world.frame != null:
		world.frame.track(world.site_views[id])
	for child in world.site_views[id].get_children():
		if child.get("role") == &"captive":
			child.set_meta("encounter_site", id)
	var contents := Contents.new()
	world.site_views[id].add_child(contents)
	contents.setup(world, id, layout)
	return true


static func _retire_access(world, reach: float) -> bool:
	for key in world.access_views.keys():
		var v: Dictionary = world.state_data.lands[key].village
		if (
			(
				Vector2(
					float(world.target.logical_position()[0]) - v.centre[0],
					float(world.target.logical_position()[2]) - v.centre[1]
				)
				. length()
			)
			> reach + float(world.design["initial-encounters"]["distance-max"])
		):
			world.access_views[key].free()
			world.access_views.erase(key)
	return true


static func _publish_access(world, reach: float) -> void:
	for key in world.state_data.lands:
		if not _publish_land_access(world, key, reach):
			return


static func _publish_land_access(world, key, reach: float) -> bool:
	var plan_: Dictionary = world.state_data.lands[key]
	var v: Dictionary = plan_.village
	var wanted = _access_wanted(world, key, v, reach)
	if wanted == null:
		return false
	if wanted:
		return _publish_roads(world, key, plan_)
	return true


static func _access_wanted(world, key, v: Dictionary, reach: float) -> Variant:
	return (
		(
			(
				Vector2(
					float(world.target.logical_position()[0]) - v.centre[0],
					float(world.target.logical_position()[2]) - v.centre[1]
				)
				. length()
			)
			<= reach + float(world.design["initial-encounters"]["distance-max"])
		)
		and world.guidance.has(key)
		and not world.access_views.has(key)
	)


static func _publish_roads(world, key, plan_: Dictionary) -> bool:
	var visible: Array = []
	var prospective := {}  # one deterministic plan per nearby zone for this publication
	for road in world.guidance[key]:
		var safe: Dictionary = road.duplicate(true)
		safe.markers = road.markers.filter(
			func(marker): return world._marker_clear(marker, prospective)
		)
		visible.append(safe)
	world.access_views[key] = EncounterSite.roads(
		{"village": plan_.village, "routes": visible}, world.design, world.frame
	)
	world.add_child(world.access_views[key])
	if world.frame != null:
		world.frame.track(world.access_views[key])
	return true
