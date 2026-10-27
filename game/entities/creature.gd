## creature (§3.2) + ai-behavior: a spawned species instance with a 5-state FSM
## idle → wander → chase (hostile, or neutral once hit, target in aggro range) → attack (a reach bite, or —
## for a ranged / mage combat-role — a windup then a shot) → return (past the leash). `ai` = design.spawns.ai,
## `atk` = design.combat.enemy-attack, `role_cfg` = design.creature-roles[role] merged with its species override,
## all injected by the spawner. Canonical pair targeting lives in combat/targeting.gd.
## ponytail: no A*, potions or corpse, no lead on a moving
## target and no beam for the wizard laser / witch ray (todo_implement.md); capsule placeholder sized by
## design.spawns.size-by-category.
## D23: a stealthed target is noticed from a shorter range, and a landed hit rolls design.defence.enemy-hit statuses.
## D26: a projectile role keeps `keep-away` blocks between us and the target, needs line of sight, and damages
## through combat/projectile.gd calling `_strike` back on us — never hitting another creature.
extends "res://game/entities/entity.gd"

const Projectile := preload("res://game/combat/projectile.gd")
const Targeting := preload("res://game/combat/targeting.gd")
const Combat := preload("res://game/combat/combat.gd")

enum State { IDLE, WANDER, CHASE, ATTACK, RETURN }

var special  # optional encounter boss helper; saved state is incarnation.special
var targeting: Node  # injected pair/pack authority; survives streaming
var pack_id := ""
var incarnation: Dictionary = {}  # world-owned saved descriptor; empty in isolated tests
var species: StringName
var ai: Dictionary = {}
var atk: Dictionary = {}
var design: Dictionary = {}  # generators.json#design (defence.enemy-hit, status-effects, D23); empty = neither
var role: StringName = &"melee"  # D26 combat-role, resolved per group by the spawner
var role_cfg: Dictionary = {}  # design.creature-roles[role] + species override; empty / kind melee = the reach bite
var damage := 0.0
var target  # what we chase (the player)
var home := Vector3.ZERO
var state := State.IDLE
var provoked := false
var gravity := 32.0
var color := Color.WHITE
var flash_s := 0.12
var _goal: Array = [0.0, 0.0, 0.0]
var _wait := 0.0
var _windup := 0.0
var _cooldown := 0.0
var _rng := RandomNumberGenerator.new()
var _sim_r2 := INF  # design.spawns.ai.sim-radius², D16
var _stun_push := Vector3.ZERO  # actual external x/z, separate from AI; collisions consume it


func setup(
	p_species: StringName,
	p_level: int,
	p_max_hp: float,
	p_damage: float,
	p_hostility: StringName,
	p_ai: Dictionary,
	p_atk: Dictionary,
	size: float,
	p_color: Color,
	seed: int,
	p_resistance: float = 0.0
) -> void:
	species = p_species
	level = p_level
	max_hp = p_max_hp
	hp = p_max_hp
	damage = p_damage
	resistance = p_resistance
	hostility = p_hostility
	ai = p_ai
	atk = p_atk
	color = p_color
	_sim_r2 = pow(float(ai["sim-radius"]), 2.0)
	_rng.seed = seed
	# Scene subresources are shared until copied: encounter bosses must not resize every ordinary body.
	$Collision.shape = $Collision.shape.duplicate()
	$Body.mesh = $Body.mesh.duplicate()
	$Collision.shape.radius = size * 0.25
	$Collision.shape.height = size
	$Collision.position.y = size / 2.0
	$Body.mesh.radius = size * 0.25
	$Body.mesh.height = size
	$Body.position.y = size / 2.0
	$Body.material_override = StandardMaterial3D.new()
	$Body.material_override.albedo_color = color
	floor_snap_length = 1.2
	damaged.connect(_on_damaged)
	died.connect(_on_died)


func _on_damaged(amount: float, from: Node) -> void:
	if targeting != null:
		targeting.damaged(self, amount, from)
		provoked = not targeting.record(self).provoked.is_empty()
		target = targeting.select(self)
	var mat: StandardMaterial3D = $Body.material_override
	mat.albedo_color = Color.WHITE  # game-feel: hit flash, eased back
	create_tween().tween_property(mat, "albedo_color", color, flash_s)


func _on_died() -> void:
	if special != null:
		special.cancel()
	if (
		last_attacker != null
		and is_instance_valid(last_attacker)
		and last_attacker.has_method("on_kill")
	):
		last_attacker.on_kill(level)
	if targeting != null:
		targeting.died(self)
	if not incarnation.is_empty():
		incarnation.dead = true
		incarnation.eligible = false
		incarnation.hp = 0.0
	set_physics_process(false)
	$Collision.disabled = true
	create_tween().tween_property($Body, "scale", Vector3(1.3, 0.2, 1.3), 0.2).finished.connect(
		queue_free
	)


func _physics_process(dt: float) -> void:
	if ai.is_empty():
		return
	# Authority timers run independently, including unloaded logical survivors.
	if targeting != null:
		var near := false
		for p in targeting.party():
			if (
				Targeting.valid_member(p)
				and (
					Targeting.distance_squared(logical_position(), Targeting.position_of(p))
					<= _sim_r2
				)
			):
				near = true
		if not near:
			return
	elif (
		target != null
		and is_instance_valid(target)
		and Targeting.distance_squared(logical_position(), Targeting.position_of(target)) > _sim_r2
	):
		return
	velocity.y -= gravity * dt
	_cooldown -= dt
	tick_statuses(dt)
	if dead:
		return
	if stunned():  # D21: cannot act; a knockback keeps carrying us
		if special != null:
			special.advance(dt)
		velocity.x = _stun_push.x
		velocity.z = _stun_push.z
		move_and_slide()
		_stun_push = Vector3(velocity.x, 0, velocity.z)
		return
	_stun_push = Vector3.ZERO  # ordinary AI/special motion owns x/z again
	if special != null:
		_select_target()
		if special.advance(dt):
			velocity.x = 0
			velocity.z = 0
			move_and_slide()
			return
	var next := _tick(dt)
	if next != state:
		state = next
		_wait = _rng.randf_range(float(ai["wander-pause-s"][0]), float(ai["wander-pause-s"][1]))
		_windup = float(role_cfg["windup-s"]) if _shoots() else float(atk["windup-s"])
	move_and_slide()


func _can_chase() -> bool:
	return (
		target != null
		and Targeting.valid_member(target)
		and not target.get("dead")
		and (targeting != null or hostility == &"H" or (hostility == &"N" and provoked))
	)


func apply_status(id: StringName, cfg: Dictionary, hit: float, from: Node) -> void:
	var knockback := not dead and StringName(str(cfg.get("as", id))) == &"knockback"
	if special != null and knockback:
		special.cancel()  # retire special-owned motion BEFORE the base inserts the real impulse
	var before := velocity
	super.apply_status(id, cfg, hit, from)
	if knockback:
		_stun_push += Vector3(velocity.x - before.x, 0, velocity.z - before.z)
	if special != null and stunned():
		special.cancel()


func _select_target() -> void:
	if targeting != null:
		if state == State.RETURN or targeting.record(self).returning:
			state = State.RETURN
			targeting.start_return(self)
		elif (
			state in [State.CHASE, State.ATTACK]
			and (
				sqrt(Targeting.distance_squared(logical_position(), _home_point()))
				> float(ai["leash"])
			)
		):
			targeting.start_return(self)
			state = State.RETURN
		else:
			target = targeting.select(self)
			if target == null and state in [State.CHASE, State.ATTACK]:
				targeting.start_return(self)
				state = State.RETURN


## Returns the state for the next frame; movement intent is applied to velocity.x/z here.
func _tick(dt: float) -> State:
	_select_target()
	var can_chase := _can_chase()
	var to_target: float = (
		sqrt(Targeting.distance_squared(logical_position(), Targeting.position_of(target)))
		if can_chase
		else INF
	)
	match state:
		State.IDLE:
			_move([], 0.0)
			if can_chase and (targeting != null or to_target < _aggro_range()):
				return State.CHASE
			_wait -= dt
			if _wait <= 0.0:
				var r := float(ai["wander-radius"])
				_goal = _home_point()
				_goal[0] += _rng.randf_range(-r, r)
				_goal[2] += _rng.randf_range(-r, r)
				return State.WANDER
		State.WANDER:
			if can_chase and (targeting != null or to_target < _aggro_range()):
				return State.CHASE
			if _move(_goal, float(ai["walk"])):
				return State.IDLE
		State.CHASE:
			if (
				not can_chase
				or (
					sqrt(Targeting.distance_squared(logical_position(), _home_point()))
					> float(ai["leash"])
				)
			):
				return State.RETURN
			# ponytail: `design.spawns.ai.aggro-range` decides when we notice a target whatever our role, so a
			# role `range` beyond it only applies once we are already chasing (todo_implement.md)
			if _shoots():  # D26: hold the gap, shoot when we can see them
				var keep := float(role_cfg["keep-away"])
				if to_target < keep:
					var here := logical_position()
					var there := Targeting.position_of(target)
					var away := (
						(
							Vector3(float(here[0]) - there[0], 0, float(here[2]) - there[2])
							. normalized()
						)
						* keep
					)
					_move(
						[float(here[0]) + away.x, here[1], float(here[2]) + away.z],
						float(ai["chase"])
					)
				elif to_target <= float(role_cfg["range"]) and _cooldown <= 0.0 and _los():
					return State.ATTACK
				else:
					_move(Targeting.position_of(target), float(ai["chase"]))
				return state
			if to_target <= float(atk["reach"]) and _cooldown <= 0.0:
				return State.ATTACK
			_move(Targeting.position_of(target), float(ai["chase"]))
		State.ATTACK:
			_move([], 0.0)
			_windup -= dt
			if _windup <= 0.0:
				if _shoots():
					if can_chase and to_target <= float(role_cfg["range"]) and _los():  # they may have stepped behind cover
						_shoot()
					_cooldown = float(role_cfg["cooldown-s"])
					return State.CHASE
				if (
					can_chase
					and to_target <= float(atk["reach"]) * 1.25
					and Targeting.view_of(target) != null
					and Targeting.view_of(target).has_method("take_damage")
				):
					var victim = Targeting.view_of(target)
					if special != null:
						for body in bodies_within(victim.global_position, float(atk["reach"])):
							if body.has_method("take_direct_damage"):
								body.take_direct_damage(damage, self)
					var d := Combat.after_defence(
						damage,
						float(victim.get("armor")),
						float(victim.get("resistance")),
						Combat.PHYSICAL,
						design.get("combat", {})
					)
					if not victim.take_damage(d, self):
						_hit_statuses(victim)
				_cooldown = float(atk["cooldown-s"])
				return State.CHASE
		State.RETURN:
			if _move(_home_point(), float(ai["chase"]) * float(ai["return-speed-mult"])):
				if targeting != null:
					targeting.arrive(self)
				provoked = false
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
	return hit.is_empty() or hit["collider"] == Targeting.view_of(target)


## The target's head, or a block above it for anything that is not an entity (a bare Node3D in tests).
func _target_head() -> Vector3:
	var point := Targeting.position_of(target)
	point[1] = float(point[1]) + (1.5 if target is Dictionary or target.has_method("head") else 1.0)
	return frame.to_local(point) if frame != null else Vector3(point[0], point[1], point[2])


## One shot of `role_cfg.shot` at the target's head, aimed high by the drop it takes over the flight
## (ponytail: no lead on a moving target). Damage and statuses come back through `_strike`.
func _shoot() -> void:
	var s: Dictionary = (role_cfg["shot"] as Dictionary).duplicate()
	s["color"] = role_cfg["color"]  # projectile.gd tints the sphere from the shot dict
	var from := head()
	var dir: Vector3 = _target_head() - from
	var d := dir.length()
	if d < 0.01:
		return
	var t := d / float(s["speed"])
	dir.y += float(s.get("gravity", 0.0)) * t * t * 0.5
	if feel != null:
		feel.sfx(StringName(str(role_cfg["sfx"])))
	Projectile.fire(
		self,
		from,
		dir.normalized(),
		s,
		damage * float(role_cfg["damage-mult"]),
		false,
		role_cfg.get("applies", []),
		Combat.MAGICAL if role == &"mage" else Combat.PHYSICAL
	)


## projectile.gd damages through the shooter. Every landed shot rolls design.defence.enemy-hit and the role's
## `applies` statuses; the number over the target is floated by its own take_damage (D25).
## ponytail: creature attacks have no crit or combo; add those only with approved creature-combat rules.
func _strike(
	center: Vector3,
	radius: float,
	dmg: float,
	_combo_bonus: bool,
	applies: Array = [],
	attack_type: StringName = Combat.PHYSICAL,
	target_limit: int = 0
) -> int:
	var se: Dictionary = design.get("status-effects", {})
	var hits := 0
	var bodies := bodies_within(center, radius)
	if target_limit > 0:
		bodies = bodies.slice(0, target_limit)
	for body in bodies:
		if body.has_method("take_direct_damage"):
			body.take_direct_damage(dmg, self)
			continue
		var d := Combat.after_defence(
			dmg,
			float(body.get("armor")),
			float(body.get("resistance")),
			attack_type,
			design.get("combat", {})
		)
		if not body.take_damage(d, self):
			_hit_statuses(body)
			for id in applies:
				if se.has(id) and body.has_method("apply_status"):
					body.apply_status(id, se[id], d, self)
		hits += 1
	return hits


## Live damageable bodies in the sphere that are not creatures: a creature shot never hits a creature.
func bodies_within(center: Vector3, radius: float) -> Array:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), center)
	q.exclude = [get_rid()]
	var out: Array = []
	for r in get_world_3d().direct_space_state.intersect_shape(q, 16):
		var body: Object = r["collider"]
		if (
			(special != null and body.has_method("take_direct_damage"))
			or (
				body.has_method("take_damage")
				and not body.get("dead")
				and body.get("species") == null
			)
		):
			out.append(body)
	return out


## The player's combo / MP bookkeeping; a creature keeps none.
func _landed(_combo_bonus: bool) -> void:
	pass


## design.defence.stealth.aggro-cut: full stealth shrinks how far we notice the target (D23).
func _aggro_range(candidate = null) -> float:
	if candidate == null:
		candidate = target
	var s := (
		float(candidate.get("stealth"))
		if candidate != null and candidate.get("stealth") != null
		else 0.0
	)
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
func _home_point() -> Array:
	return (
		incarnation.home.duplicate()
		if not incarnation.is_empty()
		else [float(home.x), float(home.y), float(home.z)]
	)


func _move(goal: Array, speed: float) -> bool:
	if speed <= 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		return true
	var here := logical_position()
	var dx: float = float(goal[0]) - float(here[0])
	var dz: float = float(goal[2]) - float(here[2])
	var distance := sqrt(dx * dx + dz * dz)
	if distance < 0.5:
		velocity.x = 0.0
		velocity.z = 0.0
		return true
	var d := Vector3(dx / distance, 0, dz / distance) * speed * status_move_mult()
	velocity.x = d.x
	velocity.z = d.z
	step_up(Vector3(velocity.x, 0, velocity.z) * get_physics_process_delta_time(), 1.0)
	return false


func received_damage_mult() -> float:
	return (
		1.0 - float(ai["return-damage-reduction"])
		if state == State.RETURN or (targeting != null and targeting.record(self).returning)
		else 1.0
	)


## Current direct sighting; pack awareness shares this observation, not a retained sighting.
func detects(p) -> bool:
	if (
		sqrt(Targeting.distance_squared(logical_position(), Targeting.position_of(p)))
		> _aggro_range(p)
	):
		return false
	var point := Targeting.position_of(p)
	point[1] = float(point[1]) + (1.5 if p is Dictionary or p.has_method("head") else 1.0)
	var end: Vector3 = (
		frame.to_local(point) if frame != null else Vector3(point[0], point[1], point[2])
	)
	var q := PhysicsRayQueryParameters3D.create(head(), end, 0xFFFFFFFF, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or hit.collider == Targeting.view_of(p)
