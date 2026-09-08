## creature (§3.2) + ai-behavior: a spawned species instance with a 5-state FSM
## idle → wander → chase (hostile, or neutral once hit, target in aggro range) → attack (in reach,
## windup then damage) → return (past the leash). `ai` = design.spawns.ai, `atk` = design.combat.
## enemy-attack, injected by the spawner. ponytail: no aggro table, A*, potions, loot or corpse
## (todo_implement.md); capsule placeholder sized by design.spawns.size-by-category.
extends "res://game/entities/entity.gd"

enum State { IDLE, WANDER, CHASE, ATTACK, RETURN }

var species: StringName
var ai: Dictionary = {}
var atk: Dictionary = {}
var damage := 0.0
var target: Node3D                       # what we chase (the player)
var home := Vector3.ZERO
var state := State.IDLE
var provoked := false
var gravity := 32.0
var color := Color.WHITE
var flash_s := 0.12
var _goal := Vector3.ZERO
var _wait := 0.0
var _windup := 0.0
var _cooldown := 0.0
var _rng := RandomNumberGenerator.new()
var _sim_r2 := INF                      # design.spawns.ai.sim-radius², D16

func setup(p_species: StringName, p_level: int, p_max_hp: float, p_damage: float, p_hostility: StringName, p_ai: Dictionary, p_atk: Dictionary, size: float, p_color: Color, seed: int) -> void:
	species = p_species; level = p_level; max_hp = p_max_hp; hp = p_max_hp; damage = p_damage
	hostility = p_hostility; ai = p_ai; atk = p_atk; color = p_color
	_sim_r2 = pow(float(ai["sim-radius"]), 2.0)
	_rng.seed = seed
	$Collision.shape.radius = size * 0.25; $Collision.shape.height = size; $Collision.position.y = size / 2.0
	$Body.mesh.radius = size * 0.25; $Body.mesh.height = size; $Body.position.y = size / 2.0
	$Body.material_override = StandardMaterial3D.new(); $Body.material_override.albedo_color = color
	floor_snap_length = 1.2
	damaged.connect(_on_damaged)
	died.connect(_on_died)

func _on_damaged(_amount: float, from: Node) -> void:
	provoked = true
	if from is Node3D and from != self:
		target = from
	var mat: StandardMaterial3D = $Body.material_override
	mat.albedo_color = Color.WHITE                          # game-feel: hit flash, eased back
	create_tween().tween_property(mat, "albedo_color", color, flash_s)

func _on_died() -> void:
	set_physics_process(false)
	$Collision.disabled = true
	create_tween().tween_property($Body, "scale", Vector3(1.3, 0.2, 1.3), 0.2).finished.connect(queue_free)

func _physics_process(dt: float) -> void:
	if ai.is_empty():
		return
	# c-sim-radius (D16): far creatures are frozen — no AI, no move_and_slide. ~95 bodies on trimesh zones
	# cost 40 ms per physics tick and the engine ran 8 catch-up ticks per frame (4 FPS).
	if target != null and is_instance_valid(target) and global_position.distance_squared_to(target.global_position) > _sim_r2:
		return
	velocity.y -= gravity * dt
	_cooldown -= dt
	var next := _tick(dt)
	if next != state:
		state = next
		_wait = _rng.randf_range(float(ai["wander-pause-s"][0]), float(ai["wander-pause-s"][1]))
		_windup = float(atk["windup-s"])
	move_and_slide()

func _can_chase() -> bool:
	return (hostility == &"H" or (hostility == &"N" and provoked)) and target != null and is_instance_valid(target) and not target.get("dead")

## Returns the state for the next frame; movement intent is applied to velocity.x/z here.
func _tick(dt: float) -> State:
	var can_chase := _can_chase()
	var to_target: float = global_position.distance_to(target.global_position) if can_chase else INF
	match state:
		State.IDLE:
			_move(Vector3.ZERO, 0.0)
			if can_chase and to_target < float(ai["aggro-range"]):
				return State.CHASE
			_wait -= dt
			if _wait <= 0.0:
				var r := float(ai["wander-radius"])
				_goal = home + Vector3(_rng.randf_range(-r, r), 0, _rng.randf_range(-r, r))
				return State.WANDER
		State.WANDER:
			if can_chase and to_target < float(ai["aggro-range"]):
				return State.CHASE
			if _move(_goal, float(ai["walk"])):
				return State.IDLE
		State.CHASE:
			if not can_chase or global_position.distance_to(home) > float(ai["leash"]):
				return State.RETURN
			if to_target <= float(atk["reach"]) and _cooldown <= 0.0:
				return State.ATTACK
			_move(target.global_position, float(ai["chase"]))
		State.ATTACK:
			_move(Vector3.ZERO, 0.0)
			_windup -= dt
			if _windup <= 0.0:
				if can_chase and to_target <= float(atk["reach"]) * 1.25 and target.has_method("take_damage"):
					target.take_damage(damage, self)
				_cooldown = float(atk["cooldown-s"])
				return State.CHASE
		State.RETURN:
			if _move(home, float(ai["chase"])):
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
