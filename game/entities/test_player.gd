## Headless check of player movement (D13): `godot --headless -s game/entities/test_player.gd`.
## Flat floor + a 1-block step; drives the InputMap actions and asserts landing, hold-jump height,
## auto step-up, sprint stamina drain and the camera's orbit distance.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")

var _failed := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var s := BoxShape3D.new()
	s.size = size; cs.shape = s; b.add_child(cs); b.position = pos
	return b

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _init() -> void:
	var o := Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	for a in ["move_forward", "move_right", "jump", "sprint", "zoom_in", "zoom_out", "menu", "basic-attack"]:
		check(InputMap.has_action(a), "InputMap action %s" % a)
	root.add_child(_box(Vector3(60, 1, 60), Vector3(0, -0.5, 0)))          # floor, top at y = 0
	root.add_child(_box(Vector3(4, 1, 60), Vector3(6, 0.5, 0)))            # 1-block step, x in 4..8
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	var design: Dictionary = o.configs["generators"]["design"]
	p.setup(design["movement"], design["camera"], &"normal")
	p.position = Vector3(0, 3, 0)
	await _frames(90)
	check(p.is_on_floor() and absf(p.position.y) < 0.1, "lands on the floor: y=%.2f floor=%s" % [p.position.y, p.is_on_floor()])
	var cam: Camera3D = p.get_node("CameraRig/Arm/Camera")
	var d := cam.global_position.distance_to(p.get_node("CameraRig").global_position)
	check(absf(d - float(design["camera"]["distance"]["default"])) < 0.6, "orbit camera at default distance: %.2f" % d)
	Input.action_press("jump")                                             # hold → full height
	var top := 0.0
	for i in 60:
		await physics_frame
		top = maxf(top, p.position.y)
	Input.action_release("jump")
	await _frames(60)
	var hold := float(design["movement"]["jump-height"]["hold"])
	check(top > hold - 0.4 and top < hold + 0.4, "hold jump reaches ~%.1f blocks: %.2f" % [hold, top])
	check(p.is_on_floor(), "lands again")
	Input.action_press("move_right")                                       # +x with yaw 0; 1 s ≈ 6 blocks
	await _frames(60)
	Input.action_release("move_right")
	await _frames(20)
	check(p.position.x > 4.5 and p.position.x < 8.0 and absf(p.position.y - 1.0) < 0.15, "walks up the 1-block step: x=%.2f y=%.2f" % [p.position.x, p.position.y])
	var before: float = p.stamina
	Input.action_press("move_forward"); Input.action_press("sprint")
	await _frames(60)
	Input.action_release("move_forward"); Input.action_release("sprint")
	check(p.stamina < before - 5.0, "sprint drains stamina: %.1f → %.1f" % [before, p.stamina])
	print("player ok" if _failed == 0 else "player FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
