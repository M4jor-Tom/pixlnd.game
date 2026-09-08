## player-character (§3.2) movement: walk, sprint, variable jump, gravity, swim, 1-block auto
## step-up, stamina (D13). `cfg` = generators.json#design.movement, injected by main.gd: this script
## never names OntologyDB so headless tests (no autoloads) can drive it.
## ponytail: no climb/dodge/glide/fall damage yet; they arrive with §3.3 combat and the HP resource.
extends CharacterBody3D

var cfg: Dictionary = {}
var water_top := -INF                                   # y of the water surface (sea level + 1)
var ground_ready: Callable = func(_p: Vector3) -> bool: return true   # world: is the zone under us built?
var stamina := 100.0
var _stamina_idle := 0.0
@onready var rig: Node3D = $CameraRig

func setup(movement: Dictionary, camera: Dictionary, size_class: StringName) -> void:
	cfg = movement
	stamina = float(cfg["stamina"]["max"])
	var hb: Array = cfg["hitbox"][size_class]
	$Collision.shape.radius = hb[0]; $Collision.shape.height = hb[1]; $Collision.position.y = hb[1] / 2.0
	$Body.mesh.radius = hb[0]; $Body.mesh.height = hb[1]; $Body.position.y = hb[1] / 2.0
	floor_snap_length = float(cfg["step-up"]) + 0.2
	$CameraRig.setup(camera, hb[1], self)               # not `rig`: setup may run before _ready

func _physics_process(dt: float) -> void:
	if cfg.is_empty() or not ground_ready.call(global_position):
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
	else:
		velocity.y -= g * dt
		var jh: Dictionary = cfg["jump-height"]
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = sqrt(2.0 * g * float(jh["hold"]))
		elif velocity.y > 0.0 and not Input.is_action_pressed("jump"):
			velocity.y = minf(velocity.y, sqrt(2.0 * g * float(jh["tap"])))   # released early: tap height
	velocity.x = dir.x * speed; velocity.z = dir.z * speed
	_step_up(Vector3(velocity.x, 0, velocity.z) * dt)
	move_and_slide()

## Cube World walks over 1-block ledges: if the horizontal motion is blocked here but free one
## step higher, lift the body; move_and_slide's floor snap sets it down on the ledge.
func _step_up(motion: Vector3) -> void:
	if not is_on_floor() or motion.is_zero_approx() or not test_move(global_transform, motion):
		return
	var lift := Vector3.UP * (float(cfg["step-up"]) + 0.05)
	if not test_move(global_transform.translated(lift), motion):
		global_position += lift
