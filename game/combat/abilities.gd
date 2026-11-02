## §3.3 ability runtimes (D21): dash / channel / burst / buff / heal from design.abilities, one runner per player.
## Holds the transient state (cooldowns, one dash, one channel, one cast, active buffs, heals over time) and the
## multipliers the player reads; strikes go through player._strike so crit / armor / status rules stay in one place.
## D24: `projectile` shots and a dash `throw` go through player._fire (combat/projectile.gd).
## ponytail: clone and zone ultimates are bursts or buffs (todo_implement.md); no cast interruption.
extends RefCounted

var p  # the player
var cfg: Dictionary = {}  # design.abilities
var cooldowns: Dictionary = {}  # ability id → seconds left
var buffs: Dictionary = {}  # ability id → {"left", "r", "pool"?}
var dash: Dictionary = {}  # {"a", "r", "dir", "left", "origin", "e"}
var channel: Dictionary = {}  # activation yaw, elapsed turns, last-hit revolution per body
# Node3D coordinates/bases are float32; compare endpoints within roundoff, not a gameplay arc.
const TURN_ROUNDOFF := 0.0000001
var cast: Dictionary = {}  # {"a", "r", "left", "e"}
var heals: Array = []  # [{"left", "per-s"}]


func _init(player, abilities: Dictionary) -> void:
	p = player
	cfg = abilities


func runtime(a) -> Dictionary:
	return cfg.get(a.id, {})


func busy() -> bool:
	return not (dash.is_empty() and channel.is_empty() and cast.is_empty())


func ready(a) -> bool:
	return float(cooldowns.get(a.id, 0.0)) <= 0.0 and not busy()


## c-mp-range / stamina: refuse without spending when short; 'all' needs cfg.all-min and empties the bar.
func pay(cost: Dictionary) -> bool:
	for res in cost:
		var have: float = p.mp if str(res) == "mp" else p.stamina
		if have < (float(cfg["all-min"]) if str(cost[res]) == "all" else float(cost[res])):
			return false
	return _spend(cost)


## Weapon dependence follows the actual runtime payload, not a duplicate ability-id list.
static func requires_weapon(r: Dictionary) -> bool:
	if r.get("runtime") in ["buff", "heal"]:
		return false  # a buff's multiplier is not an immediate weapon strike
	return (
		r.get("runtime") == "projectile"
		or float(r.get("damage-mult", 0.0)) > 0.0
		or r.has("throw")
		or (r.has("strike") and requires_weapon(r["strike"]))
	)


func use(a) -> bool:
	var r := runtime(a)
	if not _admit(a, r):
		return false
	return _commit(a, r)


## [direction, distance]: toward the nearest enemy within `range` (stop one block short), else forward / back.
func _dash_dir(r: Dictionary) -> Array:
	var forward: Vector3 = Basis(Vector3.UP, p.rig.rotation.y) * Vector3.FORWARD
	var dist := float(r["distance"])
	if str(r["toward"]) == "target":
		var t: Node3D = p.nearest_enemy(float(r.get("range", dist)))
		if t != null:
			var d: Vector3 = t.global_position - p.global_position
			d.y = 0.0
			return [d.normalized(), minf(dist, maxf(d.length() - 1.0, 0.0))]
		return [forward, dist]
	return [forward if str(r["toward"]) == "forward" else -forward, dist]


func _strike(
	a,
	r: Dictionary,
	at: Vector3,
	e: float,
	reset_on_miss := true,
	committed_weapon: Dictionary = {}
) -> int:
	var hits := 0
	var damaging := float(r.get("damage-mult", 0.0)) > 0.0
	if a.applies.has(&"taunt") and p.targeting != null:
		p.targeting.taunt([p])
	var contact_hits = _strike_contacts(a, r, at, e, damaging, committed_weapon)
	if contact_hits == null:
		return 0
	hits = contact_hits
	if not _settle_strike(r, e, damaging, hits, reset_on_miss, committed_weapon):
		return 0
	return hits


## Horizontal velocity the player applies this tick while dashing (Vector3.ZERO when idle).
func dash_velocity() -> Vector3:
	return dash["dir"] * float(cfg["dash-speed"]) if not dash.is_empty() else Vector3.ZERO


## After move_and_slide: the dash ends at its distance or against a wall, then strikes at its end or origin.
func after_move(dt: float) -> void:
	if dash.is_empty():
		return
	dash["left"] -= float(cfg["dash-speed"]) * dt
	if dash["left"] <= 0.0 or p.is_on_wall():
		if not _dash_strike():
			return
		dash = {}


func tick(dt: float) -> void:
	if not _tick_timers(dt):
		return
	if not _tick_cast(dt):
		return
	if not channel.is_empty():
		_tick_channel(dt)


## Sweep current relative azimuths over (old, reached], except the explicit activation contact.
func _tick_channel(dt: float, initial := false) -> void:
	var active := channel
	var r: Dictionary = active["r"]
	var speed := float(r["turns-per-s"])
	var drain := float(r["drain-per-s"])
	var elapsed_value = _channel_elapsed(active, drain, dt)
	if elapsed_value == null:
		return
	var elapsed: float = elapsed_value
	var ending: bool = elapsed >= float(active["left"])
	if not ending and drain > 0.0:
		ending = elapsed >= p.stamina / drain
	_sweep_channel(active, r, elapsed, speed, ending, initial)


func _advance_channel(active: Dictionary, reached: float) -> void:
	var r: Dictionary = active["r"]
	var elapsed := (reached - float(active["turn"])) / float(r["turns-per-s"])
	active["left"] -= elapsed
	active["turn"] = reached
	p.stamina = maxf(0.0, p.stamina - float(r["drain-per-s"]) * elapsed)
	p._stamina_idle = 0.0
	p.get_node("Body").rotation.y = float(active["yaw"]) - reached * TAU


## A damaging channel misses only if the entire channel landed nothing, including early ends.
func _end_channel() -> void:
	if (
		not channel.is_empty()
		and channel["hits"] == 0
		and float(channel["r"].get("damage-mult", 0.0)) > 0.0
	):
		p.combo = 0
	channel = {}


## Product over active buffs of `key` (1 when none); `add` sums; `flag` = any buff sets it.
func mult(key: String) -> float:
	var m := 1.0
	for id in buffs:
		m *= float(buffs[id]["r"].get(key, 1.0))
	if key == "move-mult" and not channel.is_empty():
		m *= float(channel["r"].get("move-mult", 1.0))
	return m


func add(key: String) -> float:
	var s := 0.0
	for id in buffs:
		s += float(buffs[id]["r"].get(key, 0.0))
	return s


func flag(key: String) -> bool:
	for id in buffs:
		if buffs[id]["r"].get(key, false):
			return true
	return false


## mana-shield: absorb pools eat damage first; returns what gets through.
func absorb(amount: float) -> float:
	for id in buffs:
		if buffs[id].has("pool"):
			var use := minf(buffs[id]["pool"], amount)
			buffs[id]["pool"] -= use
			amount -= use
	return amount


func reset() -> void:
	_end_channel()
	dash = {}
	cast = {}
	buffs.clear()
	heals.clear()


func _spend(cost: Dictionary) -> bool:
	for res in cost:
		var have: float = p.mp if str(res) == "mp" else p.stamina
		var amount := have if str(cost[res]) == "all" else float(cost[res])
		if str(res) == "mp":
			p.mp = have - amount
		else:
			p.stamina = have - amount
	return true


func _start_dash(a, r: Dictionary, e: float, committed_weapon: Dictionary) -> bool:
	if r.has("throw"):
		p._fire(
			r["throw"],
			float(p.weapon["damage"]) * float(r["throw"].get("damage-mult", 1.0)) * e,
			false,
			a.applies,
			Vector3.INF,
			p.ability_attack_type(a)
		)
	var d := _dash_dir(r)
	dash = {
		"a": a,
		"r": r,
		"dir": d[0],
		"left": d[1],
		"origin": p.logical_position(),
		"e": e,
		"weapon": committed_weapon
	}
	return true


func _start_projectile(a, r: Dictionary, e: float) -> bool:
	p._fire(
		r,
		float(p.weapon["damage"]) * float(r.get("damage-mult", 1.0)) * e,
		false,
		a.applies,
		Vector3.INF,
		p.ability_attack_type(a)
	)
	if r.has("heal-pct"):
		_strike(
			a,
			{"heal-pct": r["heal-pct"], "heal-over-s": r.get("heal-over-s", 0.0)},
			p.global_position,
			e
		)
	return true


func _settle_strike(
	r: Dictionary,
	e: float,
	damaging: bool,
	hits: int,
	reset_on_miss: bool,
	committed_weapon: Dictionary
) -> bool:
	if damaging:  # taunts and heals never change combo or its timer
		if hits > 0:
			p._landed(false, committed_weapon)
		elif reset_on_miss:
			p.combo = 0
	if r.has("heal-pct"):
		var total: float = p.max_hp * float(r["heal-pct"]) * e
		var over := float(r.get("heal-over-s", 0.0))
		if over > 0.0:
			heals.append({"left": over, "per-s": total / over})
		else:
			p.hp = minf(p.max_hp, p.hp + total)
	return true


func _dash_strike() -> bool:
	var r: Dictionary = dash["r"]
	if r.has("strike"):
		var s: Dictionary = r["strike"]
		_strike(
			dash["a"],
			s,
			(
				(
					p.frame.to_local(dash["origin"])
					if p.frame != null
					else Vector3(dash["origin"][0], dash["origin"][1], dash["origin"][2])
				)
				if str(s.get("at", "end")) == "origin"
				else p.global_position
			),
			dash["e"],
			true,
			dash["weapon"]
		)
	return true


func _tick_effects(dt: float) -> bool:
	for id in buffs.keys():
		buffs[id]["left"] -= dt
		if buffs[id]["left"] <= 0.0:
			buffs.erase(id)
	for h in heals.duplicate():
		var elapsed := minf(dt, float(h["left"]))
		p.hp = minf(p.max_hp, p.hp + h["per-s"] * elapsed)
		h["left"] -= dt
		if h["left"] <= 0.0:
			heals.erase(h)
	return true


func _channel_events(
	active: Dictionary, r: Dictionary, first: float, reached: float, initial: bool, events: Array
) -> bool:
	for body in p.bodies_within(p.global_position + Vector3.UP, float(r["radius"])):
		if not _body_channel_events(body, active, first, reached, initial, events):
			return false
	events.sort_custom(func(a, b): return a["turn"] < b["turn"])
	return true


func _resolve_channel(active: Dictionary, r: Dictionary, reached: float, events: Array) -> bool:
	var i := 0
	while i < events.size():
		var contact: float = events[i]["turn"]
		var bodies: Array = []
		# Collinear targets are one class strike, retaining AoE combo ownership.
		var next = _channel_group(active, events, i, contact, bodies)
		if next == null:
			return false
		i = next
		if not _channel_strike(active, r, reached, contact, bodies):
			return false
	return true


func _body_channel_events(
	body, active: Dictionary, first: float, reached: float, initial: bool, events: Array
) -> bool:
	var d: Vector3 = body.global_position - p.global_position
	var phase := fposmod(atan2(d.x, -d.z) + float(active["yaw"]), TAU) / TAU
	if phase <= TURN_ROUNDOFF or 1.0 - phase <= TURN_ROUNDOFF:
		phase = 0.0
	var revolution := maxi(0, int(ceil(first - phase)))
	var contact := phase + revolution
	if not initial and contact <= first + TURN_ROUNDOFF:
		revolution += 1
		contact = phase + revolution
	while contact <= reached + TURN_ROUNDOFF:
		if int(active["last-hit"].get(body.get_instance_id(), -1)) < revolution:
			events.append({"turn": contact, "body": body, "rev": revolution})
		revolution += 1
		contact = phase + revolution
	return true


func _dispatch(a, r: Dictionary, e: float, committed_weapon: Dictionary) -> bool:
	match str(r["runtime"]):
		"dash":
			return _start_dash(a, r, e, committed_weapon)
		"channel":
			return _start_channel(a, r, e, committed_weapon)
		"burst":
			_strike(a, r, p.global_position, e)
		"projectile":
			return _start_projectile(a, r, e)
		"buff":
			buffs[a.id] = {"left": float(r["duration-s"]) * e, "r": r}
			if r.has("absorb-pct-hp"):
				buffs[a.id]["pool"] = p.max_hp * float(r["absorb-pct-hp"])
		"heal":
			cast = {"a": a, "r": r, "left": float(r["cast-s"]), "e": e, "weapon": committed_weapon}
	return true


func _start_channel(a, r: Dictionary, e: float, committed_weapon: Dictionary) -> bool:
	channel = {
		"a": a,
		"r": r,
		"left": float(r["duration-s"]),
		"yaw": p.rig.rotation.y,
		"turn": 0.0,
		"last-hit": {},
		"e": e,
		"hits": 0,
		"weapon": committed_weapon
	}
	_tick_channel(0.0, true)
	return true


func _strike_contacts(
	a, r: Dictionary, at: Vector3, e: float, damaging: bool, committed_weapon: Dictionary
):
	if damaging or (not a.applies.is_empty() and not a.applies.has(&"taunt")):
		return _weapon_strike(a, r, at, e, committed_weapon)
	return 0


func _tick_cast(dt: float) -> bool:
	if not cast.is_empty():
		cast["left"] -= dt
		if cast["left"] <= 0.0:
			_strike(cast["a"], cast["r"], p.global_position, cast["e"], true, cast["weapon"])
			cast = {}
	return true


func _channel_strike(
	active: Dictionary, r: Dictionary, reached: float, contact: float, bodies: Array
) -> bool:
	_advance_channel(active, minf(contact, reached))
	var continuing := func(): return is_same(channel, active) and not p.dead
	var hits: int = p._strike(
		p.global_position + Vector3.UP,
		float(r["radius"]),
		float(active["weapon"]["damage"]) * float(r["damage-mult"]) * float(active["e"]),
		false,
		active["a"].applies,
		p.ability_attack_type(active["a"]),
		0,
		bodies,
		continuing
	)
	if not continuing.call():
		return false  # A synchronous target callback may reset or kill the player.
	if hits > 0:
		active["hits"] += hits
		p._landed(false, active["weapon"])
	return true


func _channel_group(active: Dictionary, events: Array, i: int, contact: float, bodies: Array):
	while i < events.size() and absf(float(events[i]["turn"]) - contact) <= TURN_ROUNDOFF:
		var event: Dictionary = events[i]
		var body = event["body"]
		if is_instance_valid(body) and not body.is_queued_for_deletion():
			active["last-hit"][body.get_instance_id()] = event["rev"]
			bodies.append(body)
		i += 1
	return i


func _commit(a, r: Dictionary) -> bool:
	cooldowns[a.id] = float(r["cooldown-s"]) * p.skill_tree.cooldown_mult(a.id)
	var e: float = p.skill_tree.effect_mult(a.id)
	var committed_weapon: Dictionary = p.weapon.duplicate()
	return _dispatch(a, r, e, committed_weapon)


func _channel_elapsed(active: Dictionary, drain: float, dt: float):
	var elapsed := minf(dt, float(active["left"]))
	if drain > 0.0:
		elapsed = minf(elapsed, p.stamina / drain)
	return elapsed


func _tick_timers(dt: float) -> bool:
	for id in cooldowns:
		cooldowns[id] -= dt
	if not _tick_effects(dt):
		return false
	return true


func _weapon_strike(
	a, r: Dictionary, at: Vector3, e: float, committed_weapon: Dictionary
) -> Variant:
	return p._strike(
		at + Vector3.UP,
		float(r["radius"]),
		(
			float((p.weapon if committed_weapon.is_empty() else committed_weapon)["damage"])
			* float(r.get("damage-mult", 0.0))
			* e
		),
		false,
		a.applies,
		p.ability_attack_type(a)
	)


func _admit(a, r: Dictionary) -> bool:
	if r.is_empty():
		return false
	if requires_weapon(r) and p.weapon.is_empty():
		return false
	return _ready_and_pay(a, r)


func _sweep_channel(
	active: Dictionary, r: Dictionary, elapsed: float, speed: float, ending: bool, initial: bool
) -> void:
	var first: float = active["turn"]
	var reached := first + elapsed * speed
	var events: Array = []
	if not _channel_events(active, r, first, reached, initial, events):
		return
	if not _resolve_channel(active, r, reached, events):
		return
	_advance_channel(active, reached)
	if ending:
		_end_channel()


func _ready_and_pay(a, r: Dictionary) -> bool:
	if not ready(a):
		return false
	return pay(r.get("cost", {}))
