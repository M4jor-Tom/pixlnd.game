## creature (§3.2) + ai-behavior: a spawned species instance with a 5-state FSM
## idle → wander → chase (hostile, or neutral once hit, target in aggro range) → attack (a reach bite, or —
## for a ranged / mage combat-role — a windup then a shot) → return (past the leash). `ai` = design.spawns.ai,
## `atk` = design.combat.enemy-attack, `role_cfg` = design.creature-roles[role] merged with its species override,
## all injected by the spawner. ponytail: no aggro table, A*, potions, loot or corpse, no lead on a moving
## target and no beam for the wizard laser / witch ray (todo_implement.md); capsule placeholder sized by
## design.spawns.size-by-category.
## D23: a stealthed target is noticed from a shorter range, and a landed hit rolls design.defence.enemy-hit statuses.
## D26: a projectile role keeps `keep-away` blocks between us and the target, needs line of sight, and damages
## through combat/projectile.gd calling `_strike` back on us — never hitting another creature.
extends "res://game/entities/entity.gd"

const Projectile := preload("res://game/combat/projectile.gd")

enum State { IDLE, WANDER, CHASE, ATTACK, RETURN }

var species: StringName
var ai: Dictionary = {}
var atk: Dictionary = {}
var design: Dictionary = {}              # generators.json#design (defence.enemy-hit, status-effects, D23); empty = neither
var role: StringName = &"melee"          # D26 combat-role, resolved per group by the spawner
var role_cfg: Dictionary = {}            # design.creature-roles[role] + species override; empty / kind melee = the reach bite
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
	if target != null and is_instance_valid(target) and target.has_method("on_kill"):
		target.on_kill(level)                               # D19: XP to whoever we were fighting (last attacker)
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
	tick_statuses(dt)
	if stunned():                                           # D21: cannot act; a knockback keeps carrying us
		move_and_slide()
		return
	var next := _tick(dt)
	if next != state:
		state = next
		_wait = _rng.randf_range(float(ai["wander-pause-s"][0]), float(ai["wander-pause-s"][1]))
		_windup = float(role_cfg["windup-s"]) if _shoots() else float(atk["windup-s"])
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
			if can_chase and to_target < _aggro_range():
				return State.CHASE
			_wait -= dt
			if _wait <= 0.0:
				var r := float(ai["wander-radius"])
				_goal = home + Vector3(_rng.randf_range(-r, r), 0, _rng.randf_range(-r, r))
				return State.WANDER
		State.WANDER:
			if can_chase and to_target < _aggro_range():
				return State.CHASE
			if _move(_goal, float(ai["walk"])):
				return State.IDLE
		State.CHASE:
			if not can_chase or global_position.distance_to(home) > float(ai["leash"]):
				return State.RETURN
			# ponytail: `design.spawns.ai.aggro-range` decides when we notice a target whatever our role, so a
			# role `range` beyond it only applies once we are already chasing (todo_implement.md)
			if _shoots():                                   # D26: hold the gap, shoot when we can see them
				var keep := float(role_cfg["keep-away"])
				if to_target < keep:
					var away := global_position - target.global_position; away.y = 0.0
					_move(global_position + away.normalized() * keep, float(ai["chase"]))
				elif to_target <= float(role_cfg["range"]) and _cooldown <= 0.0 and _los():
					return State.ATTACK
				else:
					_move(target.global_position, float(ai["chase"]))
				return state
			if to_target <= float(atk["reach"]) and _cooldown <= 0.0:
				return State.ATTACK
			_move(target.global_position, float(ai["chase"]))
		State.ATTACK:
			_move(Vector3.ZERO, 0.0)
			_windup -= dt
			if _windup <= 0.0:
				if _shoots():
					if can_chase and to_target <= float(role_cfg["range"]) and _los():   # they may have stepped behind cover
						_shoot()
					_cooldown = float(role_cfg["cooldown-s"])
					return State.CHASE
				if can_chase and to_target <= float(atk["reach"]) * 1.25 and target.has_method("take_damage"):
					target.take_damage(damage, self)
					_hit_statuses(target)
				_cooldown = float(atk["cooldown-s"])
				return State.CHASE
		State.RETURN:
			if _move(home, float(ai["chase"])):
				return State.IDLE
	return state

## D26: does this combat-role fire a shot instead of biting (design.creature-roles[role].kind)?
func _shoots() -> bool:
	return str(role_cfg.get("kind", "melee")) == "projectile"

## Clear line from our head to the target's: nothing between us, or the first thing hit is the target.
## ponytail: whatever blocks the ray — a wall, or a body tall enough to reach it — simply cancels the shot; we
## never strafe for a clear angle. The ray runs head to head (`entity.gd#head`, a flat 1.5 blocks up), so only
## bodies taller than that stand in it: a wolf or another small creature is shot straight over.
func _los() -> bool:
	var q := PhysicsRayQueryParameters3D.create(head(), _target_head(), 0xFFFFFFFF, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or hit["collider"] == target

## The target's head, or a block above it for anything that is not an entity (a bare Node3D in tests).
func _target_head() -> Vector3:
	return target.head() if target.has_method("head") else target.global_position + Vector3.UP

## One shot of `role_cfg.shot` at the target's head, aimed high by the drop it takes over the flight
## (ponytail: no lead on a moving target). Damage and statuses come back through `_strike`.
func _shoot() -> void:
	var s: Dictionary = (role_cfg["shot"] as Dictionary).duplicate()
	s["color"] = role_cfg["color"]                          # projectile.gd tints the sphere from the shot dict
	var from := head()
	var dir: Vector3 = _target_head() - from
	var d := dir.length()
	if d < 0.01:
		return
	var t := d / float(s["speed"])
	dir.y += float(s.get("gravity", 0.0)) * t * t * 0.5
	if feel != null:
		feel.sfx(StringName(str(role_cfg["sfx"])))
	Projectile.fire(self, from, dir.normalized(), s, damage * float(role_cfg["damage-mult"]), false, role_cfg.get("applies", []))

## projectile.gd damages through the shooter. Every landed shot rolls design.defence.enemy-hit and the role's
## `applies` statuses; the number over the target is floated by its own take_damage (D25).
## ponytail: no crit, no combo and no armor on a creature hit — parity with the reach bite above, which ignores
## the target's armor too (todo_implement.md).
func _strike(center: Vector3, radius: float, dmg: float, _combo_bonus: bool, applies: Array = []) -> int:
	var se: Dictionary = design.get("status-effects", {})
	var hits := 0
	for body in bodies_within(center, radius):
		body.take_damage(dmg, self)
		_hit_statuses(body)
		for id in applies:
			if se.has(id) and body.has_method("apply_status"):
				body.apply_status(id, se[id], dmg, self)
		hits += 1
	return hits

## Live damageable bodies in the sphere that are not creatures: a creature shot never hits a creature.
func bodies_within(center: Vector3, radius: float) -> Array:
	var shape := SphereShape3D.new(); shape.radius = radius
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape; q.transform = Transform3D(Basis(), center); q.exclude = [get_rid()]
	var out: Array = []
	for r in get_world_3d().direct_space_state.intersect_shape(q, 16):
		var body: Object = r["collider"]
		if body.has_method("take_damage") and not body.get("dead") and body.get("species") == null:
			out.append(body)
	return out

## The player's combo / MP bookkeeping; a creature keeps none.
func _landed(_combo_bonus: bool) -> void:
	pass

## design.defence.stealth.aggro-cut: full stealth shrinks how far we notice the target (D23).
func _aggro_range() -> float:
	var s := float(target.get("stealth")) if target != null and target.get("stealth") != null else 0.0
	var cut := float(design.get("defence", {}).get("stealth", {}).get("aggro-cut", 0.0))
	return float(ai["aggro-range"]) * (1.0 - s * cut)

## design.defence.enemy-hit: each status rolls its chance; the target decides whether it took the hit (dodge / block).
func _hit_statuses(t: Node) -> void:
	var eh: Dictionary = design.get("defence", {}).get("enemy-hit", {})
	if eh.is_empty() or not t.has_method("apply_status"):
		return
	for key in eh:
		var id := StringName(str(key).trim_suffix("-chance"))
		if _rng.randf() < float(eh[key]) and design["status-effects"].has(id):
			t.apply_status(id, design["status-effects"][id], damage, self)

## Steer horizontally toward `goal` at `speed`; true when arrived.
func _move(goal: Vector3, speed: float) -> bool:
	var d := goal - global_position; d.y = 0.0
	if speed <= 0.0 or d.length() < 0.5:
		velocity.x = 0.0; velocity.z = 0.0
		return true
	d = d.normalized() * speed * status_move_mult()          # slow (D21)
	velocity.x = d.x; velocity.z = d.z
	step_up(Vector3(velocity.x, 0, velocity.z) * get_physics_process_delta_time(), 1.0)
	return false
