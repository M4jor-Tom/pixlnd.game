## Placeholder free camera to look at the terrain. Replaced by the player-character (§3.2) and
## camera-systems; keys are hard-coded until input-binding (§3.7, keybinds.json) is implemented.
extends Camera3D

@export var speed := 40.0
var _yaw := 0.0
var _pitch := -0.5

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	rotation = Vector3(_pitch, _yaw, 0)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= e.relative.x * 0.003
		_pitch = clampf(_pitch - e.relative.y * 0.003, -1.5, 1.5)
		rotation = Vector3(_pitch, _yaw, 0)
	elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _process(dt: float) -> void:
	var d := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): d -= basis.z
	if Input.is_physical_key_pressed(KEY_S): d += basis.z
	if Input.is_physical_key_pressed(KEY_A): d -= basis.x
	if Input.is_physical_key_pressed(KEY_D): d += basis.x
	if Input.is_physical_key_pressed(KEY_SPACE): d += Vector3.UP
	if Input.is_physical_key_pressed(KEY_CTRL): d -= Vector3.UP
	var mult := 4.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0
	position += d.normalized() * speed * mult * dt
