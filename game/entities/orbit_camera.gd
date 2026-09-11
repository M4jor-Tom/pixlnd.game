## camera-systems: third-person orbit on a SpringArm3D (wall push-in), wheel zoom in steps;
## distance 0 = first person (D9). Numbers: generators.json#design.camera (D13).
## D25 game feel: `add_trauma` feeds a 0..1 trauma that shakes the Camera3D offsets + roll (never the body),
## decaying every frame; the numbers are design.feel.shake, pushed in by combat/feel.gd#setup.
extends Node3D

var cfg: Dictionary = {}
var shake: Dictionary = {}                            # design.feel.shake (D25); empty = no shake
var trauma := 0.0
var _shake_t := 0.0
var _yaw := 0.0
var _pitch := -0.35
var _dist := 6.0
var _body: Node3D
@onready var arm: SpringArm3D = $Arm

func setup(camera: Dictionary, body_height: float, player: CharacterBody3D) -> void:
	cfg = camera
	position.y = body_height * float(cfg["eye-height-factor"])
	_dist = float(cfg["distance"]["default"])
	arm = $Arm                                            # setup may run before _ready
	arm.spring_length = _dist
	arm.add_excluded_object(player.get_rid())
	_body = player.get_node("Body")
	rotation = Vector3(_pitch, _yaw, 0)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## game-feel trauma: hits ADD, they never reset; shake = trauma² so small hits barely move the frame.
func add_trauma(amount: float) -> void:
	if shake.is_empty() or amount <= 0.0:
		return
	trauma = clampf(trauma + amount * float(shake["shake-mult"]), 0.0, 1.0)

func _process(dt: float) -> void:
	if shake.is_empty() or (trauma <= 0.0 and _shake_t == 0.0):
		return
	var cam: Camera3D = $Arm/Camera
	trauma = maxf(0.0, trauma - float(shake["decay-per-s"]) * dt)
	if trauma <= 0.0:                                     # back to rest, exactly
		cam.h_offset = 0.0; cam.v_offset = 0.0; cam.rotation.z = 0.0
		_shake_t = 0.0
		return
	_shake_t += dt * 30.0                                 # sampled sines, not randf per frame (that buzzes)
	var k := trauma * trauma
	var mo := float(shake["max-offset"])
	cam.h_offset = mo * k * sin(_shake_t * 1.7)
	cam.v_offset = mo * k * sin(_shake_t * 2.3)
	cam.rotation.z = deg_to_rad(float(shake["max-roll-deg"])) * k * sin(_shake_t * 1.1)

func _unhandled_input(e: InputEvent) -> void:
	if cfg.is_empty():
		return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s := float(cfg["sensitivity"])
		var lim: Array = cfg["pitch-deg"]
		_yaw -= e.relative.x * s
		_pitch = clampf(_pitch - e.relative.y * s, deg_to_rad(float(lim[0])), deg_to_rad(float(lim[1])))
		rotation = Vector3(_pitch, _yaw, 0)
	elif e.is_action_pressed("zoom_in") or e.is_action_pressed("zoom_out"):
		var d: Dictionary = cfg["distance"]
		_dist = clampf(_dist + float(d["step"]) * (-1.0 if e.is_action_pressed("zoom_in") else 1.0), float(d["min"]), float(d["max"]))
		arm.spring_length = _dist
		_body.visible = _dist > 0.0                        # first person hides our own capsule
	elif e.is_action_pressed("menu"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
