## entity (§3.2): anything with a position, HP and a body; base of player and creature.
## Shared kinematics: gravity and the 1-block auto step-up Cube World walks over.
extends CharacterBody3D

var level := 1
var max_hp := 100.0
var hp := 100.0
var hostility: StringName = &"P"          # H hostile, N neutral, P passive, F friendly

## If the horizontal motion is blocked here but free `step` higher, lift the body; move_and_slide's
## floor snap sets it down on the ledge.
func step_up(motion: Vector3, step: float) -> void:
	if not is_on_floor() or motion.is_zero_approx() or not test_move(global_transform, motion):
		return
	var lift := Vector3.UP * (step + 0.05)
	if not test_move(global_transform.translated(lift), motion):
		global_position += lift
