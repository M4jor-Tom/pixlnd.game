## entity (§3.2): anything with a position, HP and a body; base of player and creature.
## Shared kinematics: the 1-block auto step-up Cube World walks over. Damage/death live here.
extends CharacterBody3D

signal damaged(amount: float, from: Node)
signal died

var level := 1
var max_hp := 100.0
var hp := 100.0
var armor := 0.0
var hostility: StringName = &"P"          # H hostile, N neutral, P passive, F friendly
var dead := false

func take_damage(amount: float, from: Node) -> void:
	if dead:
		return
	hp = maxf(0.0, hp - amount)
	damaged.emit(amount, from)
	if hp <= 0.0:
		dead = true
		died.emit()

## If the horizontal motion is blocked here but free `step` higher, lift the body; move_and_slide's
## floor snap sets it down on the ledge.
func step_up(motion: Vector3, step: float) -> void:
	if not is_on_floor() or motion.is_zero_approx() or not test_move(global_transform, motion):
		return
	var lift := Vector3.UP * (step + 0.05)
	if not test_move(global_transform.translated(lift), motion):
		global_position += lift
