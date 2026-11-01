## Optional terrain-sampling decoration, never required geography.
extends RefCounted


## Optional decoration only. All vector arithmetic is village-local, including at world limits.
## Samples existing terrain; never searches for walkability or adds connecting supports.
static func guidance(gen, plan_: Dictionary, cfg: Dictionary) -> Array:
	var out: Array = []
	var village: Array = plan_.village.centre
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([gen.world_seed, village, "guidance"])
	for i in plan_.sites.size():
		if not _guide_road(gen, plan_, cfg, village, rng, i, out):
			return []
	return out


static func _guide_road(
	gen,
	plan_: Dictionary,
	cfg: Dictionary,
	village: Array,
	rng: RandomNumberGenerator,
	i: int,
	out: Array
) -> bool:
	var site: Dictionary = plan_.sites[i]
	var delta := Vector2(float(site.centre[0]) - village[0], float(site.centre[1]) - village[1])
	var distance := delta.length()
	var unit := delta / distance
	var family: String = cfg["leading-objects"][site.family]
	var road := {"destination": i, "family": family, "markers": []}
	var next := 40.0
	while next < distance - 16:
		var side := rng.randf_range(-5, 5)
		var x := int(village[0]) + roundi(unit.x * next - unit.y * side)
		var z := int(village[1]) + roundi(unit.y * next + unit.x * side)
		next += rng.randf_range(14, 22)
		if not _guide_marker(gen, plan_, cfg, x, z, family, road):
			return false
	out.append(road)
	return true


static func _marker_in_bounds(gen, x: int, z: int) -> bool:
	return not (not gen.valid_block(x - 1, z - 1) or not gen.valid_block(x + 1, z + 1))


static func _guide_marker(
	gen, plan_: Dictionary, cfg: Dictionary, x: int, z: int, family: String, road: Dictionary
) -> bool:
	if not _marker_in_bounds(gen, x, z):
		return true
	var clearance := _guide_clearance(plan_, cfg, x, z)
	if clearance.is_empty():
		return false
	var free: bool = clearance[0]
	var top: int = gen.height_at(x, z) + 1
	if not free or top <= gen.sea_level + 1:
		return true
	road.markers.append(
		{
			"x": x,
			"z": z,
			"top": top,
			"family": family,
			"bounds": [x - 0.75, z - 0.7, x + 0.75, z + 0.7]
		}
	)
	return true


static func _guide_clearance(plan_: Dictionary, cfg: Dictionary, x: int, z: int) -> Array:
	var free := true
	for other in plan_.sites:
		var clearance := _site_clearance(other, cfg, x, z)
		if clearance.is_empty():
			return []
		if not clearance[0]:
			free = false
	return [free]


static func _site_clearance(other, cfg: Dictionary, x: int, z: int) -> Array:
	var free := true
	for volume in other.volumes:
		var clearance := _volume_clearance(volume, cfg, x, z)
		if clearance.is_empty():
			return []
		if not clearance[0]:
			free = false
	return [free]


static func _volume_clearance(volume, cfg: Dictionary, x: int, z: int) -> Array:
	if (
		x >= volume[0] - cfg.apron - 1
		and x <= volume[3] + cfg.apron + 1
		and z >= volume[2] - cfg.apron - 1
		and z <= volume[5] + cfg.apron + 1
	):
		return [false]
	return [true]
