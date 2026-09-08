## creature (§3.2) + ai-behavior: a spawned species instance with a 4-state FSM
## idle → wander → chase (hostile, target inside aggro range) → return (past the leash).
## `cfg` = design.spawns.ai, injected by the spawner. ponytail: no attacks, aggro table or A* yet
## (§3.3 combat); capsule placeholder sized by design.spawns.size-by-category until models exist.
extends "res://game/entities/entity.gd"

enum State { IDLE, WANDER, CHASE, RETURN }

var species: StringName
var cfg: Dictionary = {}
var target: Node3D                       # what hostiles chase (the player)
var home := Vector3.ZERO
var state := State.IDLE
var gravity := 32.0
var _goal := Vector3.ZERO
var _wait := 0.0
var _rng := RandomNumberGenerator.new()

func setup(p_species: StringName, p_level: int, p_max_hp: float, p_hostility: StringName, ai: Dictionary, size: float, color: Color, seed: int) -> void:
	species = p_species; level = p_level; max_hp = p_max_hp; hp = p_max_hp; hostility = p_hostility
	cfg = ai; _rng.seed = seed
	$Collision.shape.radius = size * 0.25; $Collision.shape.height = size; $Collision.position.y = size / 2.0
	$Body.mesh.radius = size * 0.25; $Body.mesh.height = size; $Body.position.y = size / 2.0
	$Body.material_override = StandardMaterial3D.new(); $Body.material_override.albedo_color = color
	floor_snap_length = 1.2

func _physics_process(dt: float) -> void:
	if cfg.is_empty():
		return
	velocity.y -= gravity * dt
	var next := _tick(dt)
	if next != state:
		state = next
		_wait = _rng.randf_range(float(cfg["wander-pause-s"][0]), float(cfg["wander-pause-s"][1]))
	move_and_slide()

## Returns the state for the next frame; movement intent is applied to velocity.x/z here.
func _tick(dt: float) -> State:
	var can_chase := hostility == &"H" and target != null and is_instance_valid(target)
	var to_target: float = global_position.distance_to(target.global_position) if can_chase else INF
	match state:
		State.IDLE:
			_move(Vector3.ZERO, 0.0)
			if can_chase and to_target < float(cfg["aggro-range"]):
				return State.CHASE
			_wait -= dt
			if _wait <= 0.0:
				var r := float(cfg["wander-radius"])
				_goal = home + Vector3(_rng.randf_range(-r, r), 0, _rng.randf_range(-r, r))
				return State.WANDER
		State.WANDER:
			if can_chase and to_target < float(cfg["aggro-range"]):
				return State.CHASE
			if _move(_goal, float(cfg["walk"])):
				return State.IDLE
		State.CHASE:
			if not can_chase or global_position.distance_to(home) > float(cfg["leash"]):
				return State.RETURN
			_move(target.global_position, float(cfg["chase"]))
		State.RETURN:
			if _move(home, float(cfg["chase"])):
				return State.IDLE
	return state

## Steer horizontally toward `goal` at `speed`; true when arrived.
func _move(goal: Vector3, speed: float) -> bool:
	var d := goal - global_position; d.y = 0.0
	if speed <= 0.0 or d.length() < 0.5:
		velocity.x = 0.0; velocity.z = 0.0
		return true
	d = d.normalized() * speed
	velocity.x = d.x; velocity.z = d.z
	step_up(Vector3(velocity.x, 0, velocity.z) * get_physics_process_delta_time(), 1.0)
	return false
