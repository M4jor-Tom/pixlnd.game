## §3.1 world: one seed, zones streamed around `target` (gen-world neighbourhood, design.terrain.view-zones).
extends Node3D

const WorldStreaming := preload("res://game/world/world_streaming.gd")
const WorldSites := preload("res://game/world/world_sites.gd")
const WorldRewards := preload("res://game/world/world_rewards.gd")
const Domain := preload("res://game/domain/domain.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
const ZoneMesh := preload("res://game/world/zone_mesh.gd")
const TerrainWorker := preload("res://game/world/terrain_worker.gd")
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
var guidance: Dictionary = {}  # optional unsaved decoration; required geography never depends on it
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
var _terrain_worker
var _terrain_epoch := 0
var _pending_guidance: Array = []
var _pending_ambient: Dictionary = {}  # loaded home zones with actors awaiting their actual tile


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
	_terrain_worker = TerrainWorker.new(world_seed, design, ontology.landscapes, state_data.lands)
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
	_pending_ambient.erase(zc)
	var made := Spawner.populate(
		zones[zc],
		plan_,
		design,
		creatures,
		target,
		ontology,
		targeting,
		prefix,
		state_data.mobs,
		_ambient_ground_ready.bind(zc)
	)
	for mob in made:
		mob.died.connect(func(): state_changed.emit())


func _process(_dt: float) -> void:
	WorldStreaming.process(self)


func _spawn_zone(zc: Vector2i) -> void:
	WorldStreaming.spawn_zone(self, zc)


func _poll_terrain() -> void:
	WorldStreaming.poll_terrain(self)


func _marker_clear(marker: Dictionary, prospective: Dictionary = {}) -> bool:
	return WorldStreaming.marker_clear(self, marker, prospective)


static func _marker_near(marker: Dictionary, at: Array) -> bool:
	# The existing actor-sized empty halo is cosmetic placement safety, not a connecting lane.
	return absf(float(at[0]) - marker.x) < 3 and absf(float(at[2]) - marker.z) < 3


func _exit_tree() -> void:
	if _terrain_worker != null:
		_terrain_worker.stop()


func _publish_zone(zc: Vector2i, surfaces: Array) -> void:
	if surfaces.is_empty():
		generation_error = "terrain generation returned no surface: " + str(zc)
		generation_failed.emit(generation_error)
		return

	var mi := MeshInstance3D.new()
	mi.mesh = ZoneMesh.from_data(surfaces)
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
	WorldStreaming.stream_village(self)


## True once the zone under `pos` is built (the player waits for it instead of falling through).
func has_ground(pos: Vector3) -> bool:
	var logical: Array = frame.to_logical(pos) if frame != null else [pos.x, pos.y, pos.z]
	if target != null and frame != null:
		logical = target.logical_position()
	return has_terrain_at(logical)


## Logical scalar input is authoritative: never substitute the player's ready tile for another actor.
func has_terrain_at(logical: Array) -> bool:
	if not gen.valid_block(logical[0], logical[2]):
		return false
	var zc := Vector2i(
		floori(float(logical[0]) / _zone_blocks), floori(float(logical[2]) / _zone_blocks)
	)
	return gen.valid_zone(zc) and zones.has(zc)


func _actor_ground_ready(at: Array) -> bool:
	if has_terrain_at(at):
		return true
	# Built authored floors already provide support without waiting for their terrain zones.
	for id in site_views:
		if state_data.inside(site_layout(id).volumes, [at]):
			return true
	return false


func _ambient_ground_ready(at: Array, home_zone: Vector2i) -> bool:
	if _actor_ground_ready(at):
		return true
	_pending_ambient[home_zone] = true
	return false


## Publish complete land data only after geography AND every incarnation have succeeded.
func ensure_land(land) -> bool:
	return WorldSites.ensure_land(self, land)


func site_layout(id: String) -> Dictionary:
	return WorldSites.site_layout(self, id)


func populate_site(id: String) -> void:
	WorldSites.populate_site(self, id)


## Safe daily refresh is invoked by WorldState only when the entire closed union is empty.
## Completion-before-refresh is shared by conversation and automatic last-player exit.
func refresh_site(id: String) -> bool:
	return WorldSites.refresh_site(self, id)


func stream_sites() -> void:
	WorldStreaming.stream_sites(self)


## Discontinuous owner relocation: capture before exit; never translate an old neighborhood by a world-sized delta.
func retire_views() -> void:
	_terrain_epoch += 1
	_pending_ambient.clear()
	capture_mobs()
	for id in site_views:
		unload_specials(id)
	for views in [zones, villages, site_views, access_views]:
		for view in views.values():
			remove_child(view)
			view.queue_free()
		views.clear()


func unload_specials(id: String) -> void:
	WorldSites.unload_specials(self, id)


func stage_tables(site: Dictionary, layout: Dictionary, cycle: int) -> void:
	WorldRewards.stage_tables(self, site, layout, cycle)


## World-clock restoration also runs for unloaded sites, with saved actors included.
func restore_rubble(id: String) -> void:
	WorldSites.restore_rubble(self, id)


static func overlaps_voxel(point: Array, feet: Array, radius: float, height_: float) -> bool:
	return WorldSites.overlaps_voxel(point, feet, radius, height_)


## Creature's own died handler commits incarnation/finisher XP before this connected callback.
func site_death(id: String, stable: Dictionary, mob: Node3D) -> void:
	WorldRewards.site_death(self, id, stable, mob)


func resolve_package(id: String, key: String) -> void:
	WorldRewards.resolve_package(self, id, key)


func deliver_rewards(id: String) -> void:
	WorldRewards.deliver_rewards(self, id)


func on_talked(npc: Node) -> void:
	if npc.get("role") == &"captive" and npc.has_meta("encounter_site"):
		complete_supplier(npc.get_meta("encounter_site"))


func complete_supplier(id: String) -> bool:
	return WorldRewards.complete_supplier(self, id)


func supplier_ceiling(coords: Vector2i) -> int:
	return WorldRewards.supplier_ceiling(self, coords)


func vendor_stock(role: StringName, player_level: int, coords: Vector2i) -> Array:
	return WorldRewards.vendor_stock(self, role, player_level, coords)


func buy_vendor(role: StringName, index: int, player, coords: Vector2i, expected = null) -> bool:
	return WorldRewards.buy_vendor(self, role, index, player, coords, expected)


func restock_vendors() -> void:
	WorldRewards.restock_vendors(self)
