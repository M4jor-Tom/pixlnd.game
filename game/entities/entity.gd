## entity (§3.2): anything with a position, HP and a body; base of player and creature.
## Shared kinematics: the 1-block auto step-up Cube World walks over. Damage/death live here, and the
## status-effects the engine applies (design.status-effects, D21): stun, knockback, burning, slow.
## D25: `feel` (combat/feel.gd) is set on the player by main.gd; anything we take a hit from lends us theirs,
## so dot ticks float a number and a stun puts stars over the head without the spawner knowing about it.
extends CharacterBody3D

signal damaged(amount: float, from: Node)
signal died

var level := 1
var max_hp := 100.0
var hp := 100.0
var armor := 0.0
var hostility: StringName = &"P"          # H hostile, N neutral, P passive, F friendly
var dead := false
var statuses: Dictionary = {}             # status id → {"left": seconds, ...}
var feel: Node                            # combat/feel.gd (D25), or null: every call site guards

## Borrow the attacker's feel node the first time they touch us (creatures are spawned without one).
func _learn_feel(from: Node) -> void:
	if feel == null and from != null and from != self and from.get("feel") != null:
		feel = from.feel

func head() -> Vector3:
	return global_position + Vector3.UP * 1.5

func take_damage(amount: float, from: Node) -> void:
	if dead:
		return
	_learn_feel(from)
	hp = maxf(0.0, hp - amount)
	damaged.emit(amount, from)
	if hp <= 0.0:
		dead = true
		died.emit()

## ability.applies → design.status-effects[id] (`as` redirects knockdown to stun). `hit` = the damage that applied it.
func apply_status(id: StringName, cfg: Dictionary, hit: float, from: Node) -> void:
	_learn_feel(from)
	match StringName(str(cfg.get("as", id))):
		&"stun":
			if not statuses.has(&"stun") and not stun_immune():         # c-stun-immunity
				statuses[&"stun"] = {"left": float(cfg["duration-s"])}
				if feel != null:
					feel.stars(self, float(cfg["duration-s"]))          # ui.json#hud.stun-stars (D25)
		&"knockback":
			var d: Vector3 = global_position - (from as Node3D).global_position; d.y = 0.0
			velocity += d.normalized() * float(cfg["impulse"]) + Vector3.UP * float(cfg["impulse"]) * 0.25
		&"burning":
			statuses[&"burning"] = {"left": float(cfg["duration-s"]), "tick": 0.0, "tick-s": float(cfg["tick-s"]), "dmg": hit * float(cfg["pct-of-hit"]), "from": from}
		&"slow":
			statuses[&"slow"] = {"left": float(cfg["duration-s"]), "move-mult": float(cfg["move-mult"])}

func tick_statuses(dt: float) -> void:
	for id in statuses.keys():
		if not statuses.has(id):                          # a tick killed us and the death handler cleared the rest
			continue
		var s: Dictionary = statuses[id]
		s["left"] -= dt
		if id == &"burning":
			s["tick"] -= dt
			if s["tick"] <= 0.0:
				s["tick"] = s["tick-s"]
				take_damage(s["dmg"], s["from"] if is_instance_valid(s["from"]) else self)
				if feel != null:
					feel.number(head(), s["dmg"], &"dot")       # D25: dot ticks float their own number
		if s["left"] <= 0.0:
			statuses.erase(id)

func stunned() -> bool:
	return statuses.has(&"stun")

func status_move_mult() -> float:
	return float(statuses[&"slow"]["move-mult"]) if statuses.has(&"slow") else 1.0

func stun_immune() -> bool:
	return false

## If the horizontal motion is blocked here but free `step` higher, lift the body; move_and_slide's
## floor snap sets it down on the ledge.
func step_up(motion: Vector3, step: float) -> void:
	if not is_on_floor() or motion.is_zero_approx() or not test_move(global_transform, motion):
		return
	var lift := Vector3.UP * (step + 0.05)
	if not test_move(global_transform.translated(lift), motion):
		global_position += lift
