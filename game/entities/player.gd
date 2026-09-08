## player-character (§3.2) movement + §3.3 basic attack, combo, fall damage, death/respawn.
## Config dicts (design.movement / camera / combat / crit) are injected by main.gd: this script never
## names OntologyDB so headless tests (no autoloads) can drive it.
## ponytail: no climb/dodge/glide/special attack/block/stealth/MP yet (todo_implement.md).
extends "res://game/entities/entity.gd"

const Combat := preload("res://game/combat/combat.gd")

var cfg: Dictionary = {}                                # design.movement
var combat: Dictionary = {}                             # design.combat
var crit: Dictionary = {}                               # design.crit
var weapon: Dictionary = {}                             # {type, damage, combo_cap}
var crit_chance := 0.0
var combo := 0
var water_top := -INF                                   # y of the water surface (sea level + 1)
var ground_ready: Callable = func(_p: Vector3) -> bool: return true   # world: is the zone under us built?
var spawn_point := Vector3.ZERO
var stamina := 100.0
var _stamina_idle := 0.0
var _swing_t := 0.0
var _combo_t := 0.0
var _fall_from := -INF
var _rng := RandomNumberGenerator.new()
@onready var rig: Node3D = $CameraRig

func setup(movement: Dictionary, camera: Dictionary, size_class: StringName) -> void:
	cfg = movement
	stamina = float(cfg["stamina"]["max"])
	var hb: Array = cfg["hitbox"][size_class]
	$Collision.shape.radius = hb[0]; $Collision.shape.height = hb[1]; $Collision.position.y = hb[1] / 2.0
	$Body.mesh.radius = hb[0]; $Body.mesh.height = hb[1]; $Body.position.y = hb[1] / 2.0
	floor_snap_length = float(cfg["step-up"]) + 0.2
	$CameraRig.setup(camera, hb[1], self)               # not `rig`: setup may run before _ready

func setup_combat(p_combat: Dictionary, p_crit: Dictionary, p_weapon: Dictionary, p_max_hp: float) -> void:
	combat = p_combat; crit = p_crit; weapon = p_weapon
	max_hp = p_max_hp; hp = p_max_hp
	if not died.is_connected(_on_died):
		died.connect(_on_died)

func _physics_process(dt: float) -> void:
	if cfg.is_empty() or dead or not ground_ready.call(global_position):
		return
	var g := float(cfg["gravity"])
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (Basis(Vector3.UP, rig.rotation.y) * Vector3(input.x, 0, input.y)).normalized()
	var swimming := global_position.y < water_top - 0.5
	var speed := float(cfg["walk"])
	var st: Dictionary = cfg["stamina"]
	if Input.is_action_pressed("sprint") and dir != Vector3.ZERO and stamina > 0.0 and not swimming:
		speed *= float(cfg["sprint-mult"])
		stamina = maxf(0.0, stamina - float(st["sprint-drain"]) * dt)
		_stamina_idle = 0.0
	else:
		_stamina_idle += dt
		if _stamina_idle >= float(st["regen-delay-s"]):
			stamina = minf(float(st["max"]), stamina + float(st["regen"]) * dt)
	if swimming:
		speed *= float(cfg["swim-mult"])
		velocity.y = float(cfg["swim-vertical"]) * (1.0 if Input.is_action_pressed("jump") else -0.3)
		_fall_from = -INF                                   # water breaks the fall
	else:
		velocity.y -= g * dt
		var jh: Dictionary = cfg["jump-height"]
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = sqrt(2.0 * g * float(jh["hold"]))
		elif velocity.y > 0.0 and not Input.is_action_pressed("jump"):
			velocity.y = minf(velocity.y, sqrt(2.0 * g * float(jh["tap"])))   # released early: tap height
	velocity.x = dir.x * speed; velocity.z = dir.z * speed
	step_up(Vector3(velocity.x, 0, velocity.z) * dt, float(cfg["step-up"]))
	var was_airborne := not is_on_floor()
	move_and_slide()
	_fall_damage(was_airborne)
	if not combat.is_empty():
		_combat_tick(dt)

## design.movement.fall-damage: % of max HP per block beyond the free height.
func _fall_damage(was_airborne: bool) -> void:
	if not is_on_floor():
		_fall_from = maxf(_fall_from, global_position.y)
		return
	if was_airborne and _fall_from > -INF:
		var fd: Dictionary = cfg["fall-damage"]
		var drop := _fall_from - global_position.y - float(fd["from-blocks"])
		if drop > 0.0:
			take_damage(max_hp * float(fd["pct-max-hp-per-block"]) / 100.0 * drop, self)
	_fall_from = -INF

func _combat_tick(dt: float) -> void:
	_swing_t -= dt; _combo_t -= dt
	if _combo_t <= 0.0:
		combo = 0
	if Input.is_action_just_pressed("basic-attack") and _swing_t <= 0.0:
		_swing()

## basic-attack: sphere in front of us (camera yaw); every entity inside takes weapon damage.
## A whiff resets the combo (c-combo-reset); a hit adds one, capped per weapon-type.
func _swing() -> void:
	var ba: Dictionary = combat["basic-attack"]
	_swing_t = float(ba["swing-s"])
	var forward := Basis(Vector3.UP, rig.rotation.y) * Vector3.FORWARD
	var shape := SphereShape3D.new(); shape.radius = float(ba["hit-radius"])
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), global_position + Vector3.UP + forward * float(ba["reach"]) * 0.6)
	q.exclude = [get_rid()]
	var hits := 0
	for r in get_world_3d().direct_space_state.intersect_shape(q, 8):
		var body: Object = r["collider"]
		if body.has_method("take_damage") and not body.get("dead"):
			var dmg := float(weapon["damage"]) * Combat.combo_mult(combo, combat) * Combat.crit_mult(crit_chance, _rng, crit)
			body.take_damage(Combat.after_armor(dmg, float(body.get("armor")), combat), self)
			hits += 1
	if hits > 0:
		combo = mini(combo + 1, int(weapon["combo_cap"]))
		_combo_t = float(combat["combo"]["expire-s"])
	else:
		combo = 0

func _on_died() -> void:
	velocity = Vector3.ZERO
	await get_tree().create_timer(float(combat["death"]["respawn-s"])).timeout
	global_position = spawn_point                            # c-no-death-penalty
	hp = max_hp; stamina = float(cfg["stamina"]["max"]); combo = 0
	dead = false
