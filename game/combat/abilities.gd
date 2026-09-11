## §3.3 ability runtimes (D21): dash / channel / burst / buff / heal from design.abilities, one runner per player.
## Holds the transient state (cooldowns, one dash, one channel, one cast, active buffs, heals over time) and the
## multipliers the player reads; strikes go through player._strike so crit / armor / status rules stay in one place.
## D24: `projectile` shots and a dash `throw` go through player._fire (combat/projectile.gd).
## ponytail: clone and zone ultimates are bursts or buffs (todo_implement.md); no cast interruption.
extends RefCounted

var p                                # the player
var cfg: Dictionary = {}             # design.abilities
var cooldowns: Dictionary = {}       # ability id → seconds left
var buffs: Dictionary = {}           # ability id → {"left", "r", "pool"?}
var dash: Dictionary = {}            # {"a", "r", "dir", "left", "origin", "e"}
var channel: Dictionary = {}         # {"a", "r", "left", "tick", "e"}
var cast: Dictionary = {}            # {"a", "r", "left", "e"}
var heals: Array = []                # [{"left", "per-s"}]

func _init(player, abilities: Dictionary) -> void:
	p = player; cfg = abilities

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
	for res in cost:
		var have: float = p.mp if str(res) == "mp" else p.stamina
		var amount := have if str(cost[res]) == "all" else float(cost[res])
		if str(res) == "mp":
			p.mp = have - amount
		else:
			p.stamina = have - amount
	return true

func use(a) -> bool:
	var r := runtime(a)
	if r.is_empty() or not ready(a) or not pay(r.get("cost", {})):
		return false
	cooldowns[a.id] = float(r["cooldown-s"]) * p.skill_tree.cooldown_mult(a.id)
	var e: float = p.skill_tree.effect_mult(a.id)
	match str(r["runtime"]):
		"dash":
			if r.has("throw"):
				p._fire(r["throw"], float(p.weapon["damage"]) * float(r["throw"].get("damage-mult", 1.0)) * e, false, a.applies)
			var d := _dash_dir(r)
			dash = {"a": a, "r": r, "dir": d[0], "left": d[1], "origin": p.global_position, "e": e}
		"channel":
			channel = {"a": a, "r": r, "left": float(r["duration-s"]), "tick": 0.0, "e": e}
		"burst":
			_strike(a, r, p.global_position, e)
		"projectile":
			p._fire(r, float(p.weapon["damage"]) * float(r.get("damage-mult", 1.0)) * e, false, a.applies)
			if r.has("heal-pct"):
				_strike(a, {"heal-pct": r["heal-pct"], "heal-over-s": r.get("heal-over-s", 0.0)}, p.global_position, e)
		"buff":
			buffs[a.id] = {"left": float(r["duration-s"]) * e, "r": r}
			if r.has("absorb-pct-hp"):
				buffs[a.id]["pool"] = p.max_hp * float(r["absorb-pct-hp"])
		"heal":
			cast = {"a": a, "r": r, "left": float(r["cast-s"]), "e": e}
	return true

## [direction, distance]: toward the nearest enemy within `range` (stop one block short), else forward / back.
func _dash_dir(r: Dictionary) -> Array:
	var forward: Vector3 = Basis(Vector3.UP, p.rig.rotation.y) * Vector3.FORWARD
	var dist := float(r["distance"])
	if str(r["toward"]) == "target":
		var t: Node3D = p.nearest_enemy(float(r.get("range", dist)))
		if t != null:
			var d: Vector3 = t.global_position - p.global_position; d.y = 0.0
			return [d.normalized(), minf(dist, maxf(d.length() - 1.0, 0.0))]
		return [forward, dist]
	return [forward if str(r["toward"]) == "forward" else -forward, dist]

func _strike(a, r: Dictionary, at: Vector3, e: float) -> void:
	if float(r.get("damage-mult", 0.0)) > 0.0 or not a.applies.is_empty():
		p._strike(at + Vector3.UP, float(r["radius"]), float(p.weapon["damage"]) * float(r.get("damage-mult", 0.0)) * e, false, a.applies)
	if r.has("heal-pct"):
		var total: float = p.max_hp * float(r["heal-pct"]) * e
		var over := float(r.get("heal-over-s", 0.0))
		if over > 0.0:
			heals.append({"left": over, "per-s": total / over})
		else:
			p.hp = minf(p.max_hp, p.hp + total)

## Horizontal velocity the player applies this tick while dashing (Vector3.ZERO when idle).
func dash_velocity() -> Vector3:
	return dash["dir"] * float(cfg["dash-speed"]) if not dash.is_empty() else Vector3.ZERO

## After move_and_slide: the dash ends at its distance or against a wall, then strikes at its end or origin.
func after_move(dt: float) -> void:
	if dash.is_empty():
		return
	dash["left"] -= float(cfg["dash-speed"]) * dt
	if dash["left"] <= 0.0 or p.is_on_wall():
		var r: Dictionary = dash["r"]
		if r.has("strike"):
			var s: Dictionary = r["strike"]
			_strike(dash["a"], s, dash["origin"] if str(s.get("at", "end")) == "origin" else p.global_position, dash["e"])
		dash = {}

func tick(dt: float) -> void:
	for id in cooldowns:
		cooldowns[id] -= dt
	for id in buffs.keys():
		buffs[id]["left"] -= dt
		if buffs[id]["left"] <= 0.0:
			buffs.erase(id)
	for h in heals.duplicate():
		p.hp = minf(p.max_hp, p.hp + h["per-s"] * dt)
		h["left"] -= dt
		if h["left"] <= 0.0:
			heals.erase(h)
	if not cast.is_empty():
		cast["left"] -= dt
		if cast["left"] <= 0.0:
			_strike(cast["a"], cast["r"], p.global_position, cast["e"])
			cast = {}
	if not channel.is_empty():
		var r: Dictionary = channel["r"]
		channel["left"] -= dt; channel["tick"] -= dt
		p.stamina = maxf(0.0, p.stamina - float(r["drain-per-s"]) * dt); p._stamina_idle = 0.0
		if channel["tick"] <= 0.0:
			channel["tick"] = float(r["tick-s"])
			_strike(channel["a"], r, p.global_position, channel["e"])
		if channel["left"] <= 0.0 or p.stamina <= 0.0:
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
			buffs[id]["pool"] -= use; amount -= use
	return amount

func reset() -> void:
	dash = {}; channel = {}; cast = {}; buffs.clear(); heals.clear()
