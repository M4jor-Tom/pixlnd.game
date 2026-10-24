## Canonical mob/player pair authority (§3.2 ai-behavior). All records are plain saved values.
## A connected-party provider supplies present characters; no networking or mutable ontology state.
extends Node

var design: Dictionary
var players: Callable
var records: Dictionary = {}
var members: Dictionary = {}               # derived pack/hostility for loaded AND unloaded survivors
var live: Dictionary = {}                  # logical mob id -> currently materialized node, not serialized
var _taunts: Dictionary = {}                    # same physics interval's casts, resolved independently per enemy
var _rng := RandomNumberGenerator.new()
var _observed_players: Dictionary = {}
var _observed_views: Dictionary = {}

func configure(p_design: Dictionary, provider: Callable) -> void:
	design = p_design; players = provider
	_rng.randomize()

static func identity(entity) -> String:
	if entity is Dictionary: return str(entity.logical_id)
	return entity.logical_id if entity.get("logical_id") != null and entity.logical_id != "" else str(entity.get_instance_id())

static func valid_member(member) -> bool:
	return not member.is_empty() if member is Dictionary else is_instance_valid(member)

static func position_of(member) -> Array:
	if member is Dictionary: return member.position.duplicate()
	if member.has_method("logical_position"): return member.logical_position()
	return [float(member.global_position.x),float(member.global_position.y),float(member.global_position.z)]

static func view_of(member):
	var view = member.get("view") if member is Dictionary else member
	return view if is_instance_valid(view) and view.is_inside_tree() else null

static func distance_squared(a: Array, b: Array) -> float:
	var sum := 0.0
	for i in 3: sum += pow(float(a[i])-float(b[i]),2)
	return sum

static func fresh() -> Dictionary:
	return {"threat": {}, "order": {}, "next_order": 0, "provoked": {}, "current": "", "taunt": "", "taunt_left": 0.0, "returning": false}

func attach(mob: Node, id: String, pack_id: String, saved: Dictionary = {}) -> void:
	mob.logical_id = id; mob.pack_id = pack_id; mob.targeting = self
	live[id] = mob
	members[id] = {"pack": pack_id,"hostility": str(mob.hostility)}
	if not records.has(id): records[id] = saved if not saved.is_empty() else fresh()
	observe_players()

func detach(mob: Node) -> void:
	if live.get(mob.logical_id) == mob: live.erase(mob.logical_id)

func record(mob: Node) -> Dictionary:
	return records[mob.logical_id]

func party() -> Array:
	return players.call() if players.is_valid() else []

func observe_players() -> void:
	for p in party():
		var id := identity(p)
		var view = view_of(p)
		_observed_players[id] = true
		if view != null and not _observed_views.has(view.get_instance_id()) and view.has_signal("died"):
			_observed_views[view.get_instance_id()] = true
			view.died.connect(player_died.bind(id))
		if p.get("dead"): player_died(id)

func player_died(id: String) -> void:
	for r: Dictionary in records.values():
		r.threat.erase(id); r.order.erase(id)
		if r.current == id: r.current = ""
		if r.taunt == id: r.taunt = ""; r.taunt_left = 0.0

func _physics_process(dt: float) -> void:
	advance(dt/Engine.time_scale if Engine.time_scale > 0 else 0.0) # elapsed running seconds, not accelerated world time

func advance(dt: float) -> void:
	observe_players()
	flush_taunts()
	var present := {}
	for p in party():
		if valid_member(p) and not p.get("dead"): present[identity(p)] = p
	for r: Dictionary in records.values():
		for id in r.threat.keys():
			r.threat[id] = maxf(0.0, r.threat[id] - dt * float(design.spawns.ai["threat-decay-per-s"]))
			if r.threat[id] == 0:
				r.threat.erase(id); r.order.erase(id)
		r.taunt_left = maxf(0,r.taunt_left-dt)
		if r.taunt_left == 0 or not present.has(r.taunt):
			r.taunt = ""; r.taunt_left = 0.0

func damaged(mob: Node, loss: float, attacker: Node) -> void:
	if not mob.hostility in [&"H",&"N"]: return
	if loss <= 0 or attacker == null or not is_instance_valid(attacker) or attacker == mob: return
	observe_players()
	if not party().any(func(p): return identity(p)==identity(attacker)) and not _observed_players.has(identity(attacker)): return
	var id := identity(attacker)
	# A real damaging attack provokes this neutral pack even when full stealth suppresses threat.
	for other_id in members:
		if members[other_id].pack == mob.pack_id and members[other_id].hostility == "N":
			records[other_id].provoked[id] = true
	var r := record(mob)
	if attacker.get("stealth") != null and attacker.stealth >= 1.0: return
	if not r.threat.has(id):
		r.order[id] = r.next_order; r.next_order += 1
		r.threat[id] = 0.0
	r.threat[id] += float(design.spawns.ai["threat-per-full-hp"]) * loss / mob.max_hp

func eligible(mob: Node, p) -> bool:
	return mob.hostility == &"H" or (mob.hostility == &"N" and record(mob).provoked.has(identity(p)))

func detected(mob: Node, p) -> bool:
	if mob.detects(p): return true
	for mate in live.values():
		if is_instance_valid(mate) and not mate.dead and mate.pack_id == mob.pack_id and mate.hostility in [&"H",&"N"] and not record(mate).returning and mate.detects(p):
			return true
	return false

func select(mob: Node):
	observe_players()
	var r := record(mob)
	if mob.dead or r.returning: return null
	var candidates: Array = []
	for p in party():
		if not valid_member(p) or p.get("dead"): continue
		var id := identity(p)
		if r.taunt == id and r.taunt_left > 0:
			r.current = id; return p
		if eligible(mob,p) and (float(r.threat.get(id,0)) > 0 or detected(mob,p)):
			candidates.append(p)
	if candidates.is_empty(): r.current = ""; return null
	var top := 0.0
	for p in candidates: top = maxf(top,float(r.threat.get(identity(p),0)))
	var leaders: Array = candidates.filter(func(p): return float(r.threat.get(identity(p),0)) == top)
	for p in leaders:
		if identity(p) == r.current: return p
	var chosen
	if top > 0:
		leaders.sort_custom(func(a,b): return r.order[identity(a)] < r.order[identity(b)])
		chosen = leaders[0]
	else:
		var nearest := INF
		for p in leaders: nearest = minf(nearest,distance_squared(mob.logical_position(),position_of(p)))
		leaders = leaders.filter(func(p): return distance_squared(mob.logical_position(),position_of(p)) == nearest)
		chosen = leaders[_rng.randi_range(0,leaders.size()-1)]
	r.current = identity(chosen)
	return chosen

## The ability dispatch queues a cast batch. Per-mob equal-chance arbitration happens once at next physics tick.
func taunt(casters: Array) -> void:
	# Capture reach/eligibility when the cast lands, not after movement at the next physics tick.
	for mob in live.values():
		if not is_instance_valid(mob) or mob.dead: continue
		var r := record(mob)
		if r.returning or not (mob.hostility == &"H" or (mob.hostility == &"N" and not r.provoked.is_empty())): continue
		for caster in casters:
			if not valid_member(caster) or not party().any(func(p): return identity(p)==identity(caster)) or caster.get("dead"): continue
			if sqrt(distance_squared(mob.logical_position(),position_of(caster))) > float(design.abilities["heroic-shout"].radius): continue
			if not _taunts.has(mob.logical_id): _taunts[mob.logical_id] = []
			if not _taunts[mob.logical_id].has(identity(caster)): _taunts[mob.logical_id].append(identity(caster))

func flush_taunts() -> void:
	for id in _taunts:
		var mob: Node = live.get(id)
		if not is_instance_valid(mob) or mob.dead or record(mob).returning: continue
		var reached: Array = party().filter(func(caster): return valid_member(caster) and _taunts[id].has(identity(caster)) and not caster.get("dead"))
		if reached.is_empty(): continue
		var r := record(mob)
		r.taunt = identity(reached[_rng.randi_range(0,reached.size()-1)])
		r.taunt_left = float(design.abilities["heroic-shout"]["taunt-s"])
	_taunts.clear()

func start_return(mob: Node) -> void:
	var r := record(mob)
	r.returning = true; r.taunt = ""; r.taunt_left = 0.0
	mob.target = null

func arrive(mob: Node) -> void:
	records[mob.logical_id].merge(fresh(),true)
	if not mob.dead: mob.hp = mob.max_hp

func died(mob: Node) -> void:
	members.erase(mob.logical_id)
	records[mob.logical_id].merge(fresh(),true)
	live.erase(mob.logical_id)
