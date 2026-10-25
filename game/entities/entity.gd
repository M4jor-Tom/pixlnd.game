## entity (§3.2): anything with a position, HP and a body; base of player and creature.
## Shared kinematics: the 1-block auto step-up Cube World walks over. Damage/death live here, and the
## status-effects the engine applies (design.status-effects, D21): stun, knockback, burning, slow.
## D25: `feel` (combat/feel.gd) is set on the player by main.gd; anything we take a hit from lends us theirs,
## so dot ticks float a number and a stun puts stars over the head without the spawner knowing about it.
extends CharacterBody3D

signal damaged(amount: float, from: Node)
signal died

var frame  # main/world-owned local_frame, null in origin-zero isolated scenes
var _logical_anchor: Array = []
var _native_sample := Vector3.ZERO


func logical_position() -> Array:
	var native := global_position if is_inside_tree() else position
	if frame == null:
		return [float(native.x), float(native.y), float(native.z)]
	if _logical_anchor.is_empty():
		_logical_anchor = frame.to_logical(native)
		_native_sample = native
	for axis in 3:
		var displacement: float = float(native[axis]) - float(_native_sample[axis])
		_logical_anchor[axis] = float(_logical_anchor[axis]) + displacement
	_native_sample = native
	return _logical_anchor.duplicate()


func set_logical_position(p: Array) -> void:
	if frame != null:
		frame.place_entity(self, p, true)
	else:
		global_position = Vector3(p[0], p[1], p[2])


var logical_id := ""  # stable saved-world/character identity, supplied by runtime
var last_attacker: Node  # finishing damage source, never inferred from current target
var level := 1
var max_hp := 100.0
var hp := 100.0
var armor := 0.0
var resistance := 0.0
var hostility: StringName = &"P"  # H hostile, N neutral, P passive, F friendly
var dead := false
var statuses: Dictionary = {}  # status id → timed dict, or array of independent DOT application dicts
var feel: Node  # combat/feel.gd (D25), or null: every call site guards
var dot_tick := false  # true only while tick_statuses applies a dot: number, never a bundle
var _stars: Node  # the '✶ ✶ ✶' label, alive exactly as long as the stun


## Borrow the attacker's feel node the first time they touch us (creatures are spawned without one).
func _learn_feel(from: Node) -> void:
	if feel == null and from != null and from != self and from.get("feel") != null:
		feel = from.feel


func head() -> Vector3:
	return global_position + Vector3.UP * 1.5


## Returns whether this hit was blocked; callers skip its attached statuses when true.
func take_damage(amount: float, from: Node, _status: StringName = &"") -> bool:
	if dead:
		return false
	_learn_feel(from)
	var before := hp
	hp = maxf(0.0, hp - maxf(0.0, amount) * received_damage_mult())
	if hp < before:
		last_attacker = from
	damaged.emit(before - hp, from)  # actual post-defence loss, capped at remaining HP
	if hp <= 0.0:
		dead = true
		died.emit()
	return false


func received_damage_mult() -> float:
	return 1.0


## ability.applies → design.status-effects[id] (`as` redirects knockdown to stun). `hit` = the damage that applied it.
func apply_status(id: StringName, cfg: Dictionary, hit: float, from: Node) -> void:
	if dead:
		return
	_learn_feel(from)
	match StringName(str(cfg.get("as", id))):
		&"stun":
			if not statuses.has(&"stun") and not stun_immune():  # c-stun-immunity
				statuses[&"stun"] = {"left": float(cfg["duration-s"])}
				if feel != null:
					_stars = feel.stars(self)  # ui.json#hud.stun-stars (D25)
		&"knockback":
			var d: Vector3 = global_position - (from as Node3D).global_position
			d.y = 0.0
			velocity += (
				d.normalized() * float(cfg["impulse"]) + Vector3.UP * float(cfg["impulse"]) * 0.25
			)
		&"burning":
			if not statuses.has(id):
				statuses[id] = []
			statuses[id].append(
				{
					"left": float(cfg["duration-s"]),
					"tick": float(cfg["tick-s"]),
					"tick-s": float(cfg["tick-s"]),
					"dmg": hit * float(cfg["pct-of-hit"]),
					"from": from
				}
			)
		&"slow":
			statuses[&"slow"] = {
				"left": float(cfg["duration-s"]), "move-mult": float(cfg["move-mult"])
			}


func tick_statuses(dt: float) -> void:
	# Snapshot all lists and their applications before any damage callback can attach more effects.
	var active := statuses.duplicate()
	var applications_at_start := {}
	for id in active:
		if id in [&"burning", &"poison"]:
			applications_at_start[id] = active[id].duplicate()
	for id in active:
		if dead:
			return
		if not is_same(statuses.get(id), active[id]):  # synchronous signals may clear/replace later effects
			continue
		if id in [&"burning", &"poison"]:
			var applications: Array = active[id]
			for s: Dictionary in applications_at_start[id]:
				# Only time inside this application's lifetime can make ticks due, including the final tick.
				s["tick"] -= minf(dt, s["left"])
				s["left"] -= dt
				while s["tick"] <= 1e-9:  # tolerate floating-point subtraction at exact boundaries
					s["tick"] += s["tick-s"]
					var before := hp
					dot_tick = true  # D25: the number only, never the hurt bundle
					take_damage(s["dmg"], s["from"] if is_instance_valid(s["from"]) else self, id)
					dot_tick = false
					if feel != null and before > hp:
						feel.number(head(), before - hp, &"dot")
					if dead or not is_same(statuses.get(id), applications):
						break  # never resurrect a cleared/replaced application list
				if dead or not is_same(statuses.get(id), applications):
					break
				if s["left"] <= 1e-9:
					applications.erase(s)
			if is_same(statuses.get(id), applications) and applications.is_empty():
				statuses.erase(id)
		else:
			var s: Dictionary = statuses[id]
			s["left"] -= dt
			if s["left"] <= 0.0:
				statuses.erase(id)
				if id == &"stun":
					clear_stars()


## The stun ended (or was cleared wholesale by a death / respawn): the stars go with it.
func clear_stars() -> void:
	if _stars != null and is_instance_valid(_stars):
		_stars.queue_free()
	_stars = null


func stunned() -> bool:
	return statuses.has(&"stun")


func status_move_mult() -> float:
	return float(statuses[&"slow"]["move-mult"]) if statuses.has(&"slow") else 1.0


func stun_immune() -> bool:
	return false


## If an obstacle blocks horizontal motion here but not `step` higher, lift the body;
## floor-only contacts are support, not obstacles. Floor snap sets it down on the ledge.
func step_up(motion: Vector3, step: float) -> void:
	if not is_on_floor() or motion.is_zero_approx():
		return
	var collision := KinematicCollision3D.new()
	if not test_move(global_transform, motion, collision):
		return
	var floor_only := true
	for i in collision.get_collision_count():
		if collision.get_angle(i, up_direction) > floor_max_angle:
			floor_only = false
			break
	if floor_only:
		return
	var lift := Vector3.UP * (step + 0.05)
	if not test_move(global_transform.translated(lift), motion):
		global_position += lift
