## Mutable saved-world data. Nodes are views; streaming never owns logical identity or reset eligibility.
extends RefCounted

signal changed

var world_id: String
var seed: int
var clock: float
var elapsed := 0.0                         # running simulation seconds, NOT the accelerated world clock
var lands: Dictionary = {}                 # complete joint geography, stable positions/roles/specials/spirit types
var sites: Dictionary = {}
var mobs: Dictionary = {}                  # stable logical id -> incarnation descriptor + independent combat state
var vendors: Dictionary = {}                # land/role -> saved daily remaining gear
var characters: Dictionary = {}            # portable character id -> this world's position / respawn
var time: Dictionary
var refresh_site: Callable                 # returns true only when safe refresh was applied; false defers without consuming it
var complete_on_exit: Callable             # rescue owner runs before pending refresh

func _init(design: Dictionary, world_seed: int) -> void:
	time = design["time"]
	seed = world_seed
	world_id = Crypto.new().generate_random_bytes(16).hex_encode()
	clock = float(time["initial-hour"]) * 3600.0

func site_id(land: Vector2i, family: String, ordinal: int) -> String:
	return "%s/site/%d,%d/%s/%d" % [world_id,land.x,land.y,family,ordinal]

func register_site(id: String, family: String, volumes: Array) -> Dictionary:
	if not sites.has(id):
		sites[id] = {"id": id, "family": family, "volumes": volumes.duplicate(true), "pending": false,
			"cleared": false, "completed": false, "cycle": 0, "mobs": {}, "rewards": {}}
	return sites[id]

static func inside(volumes: Array, positions: Array) -> bool:
	for point in positions:
		var p: Array = [point.x,point.y,point.z] if point is Vector3 else point
		for v: Array in volumes:
			if p[0] >= v[0] and p[1] >= v[1] and p[2] >= v[2] and p[0] <= v[3] and p[1] <= v[4] and p[2] <= v[5]:
				return true
	return false

func advance(dt: float, positions: Array) -> void:
	elapsed += dt
	var dirty := false
	var day := floori(clock / float(time["day-s"]))
	clock += dt * float(time["speed"])
	if floori(clock / float(time["day-s"])) > day:
		dirty = true
		for site: Dictionary in sites.values(): site.pending = true
		for mob: Dictionary in mobs.values():
			if mob.dead: mob.eligible = true
	for id in sites:
		var site: Dictionary = sites[id]
		if inside(site.volumes,positions): continue
		if site.family == "supplier" and site.cleared and not site.completed:
			if not complete_on_exit.is_valid(): continue
			complete_on_exit.call(id)
			dirty = true
			if not site.completed: continue
		if site.completed and site.family == "supplier":
			site.pending = false
		elif site.pending and refresh_site.is_valid() and refresh_site.call(id) == true:
			site.pending = false
			site.cycle += 1
			dirty = true
	if dirty: changed.emit()

## Write the immutable rolled payload before any pickup is exposed. Same logical death/renewal never rerolls.
func issue_reward(site_id_: String, reward_id: String, payload: Array) -> bool:
	var rewards: Dictionary = sites[site_id_].rewards
	if rewards.has(reward_id): return false
	rewards[reward_id] = {"payload": payload.duplicate(true), "delivered": false}
	changed.emit()
	return true

func snapshot() -> Dictionary:
	return {"world_id": world_id, "seed": seed, "clock": clock, "elapsed": elapsed,
		"lands": lands.duplicate(true), "vendors": vendors.duplicate(true), "sites": sites.duplicate(true), "mobs": mobs.duplicate(true), "characters": characters.duplicate(true)}

func restore(data: Dictionary) -> void:
	world_id = data.world_id; seed = int(data.seed); clock = data.clock; elapsed = data.elapsed
	lands = data.lands.duplicate(true)
	vendors = data.vendors.duplicate(true)
	sites = data.sites.duplicate(true); mobs = data.mobs.duplicate(true); characters = data.characters.duplicate(true)
