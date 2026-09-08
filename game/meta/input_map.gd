## input-binding (§3.7): builds Godot's InputMap from keybinds.json#hybrid (D13). Gameplay reads
## action names only; rebinding (S: remappable) later swaps the events, never the names.
extends RefCounted

const MOUSE := {"M1": MOUSE_BUTTON_LEFT, "M2": MOUSE_BUTTON_RIGHT, "M3": MOUSE_BUTTON_MIDDLE}

static func build(hybrid: Dictionary) -> void:
	for action in hybrid:
		if str(action).begins_with("_"):
			continue
		var token: String = str(hybrid[action])
		match token:
			"WASD":
				_key("move_forward", KEY_W); _key("move_back", KEY_S); _key("move_left", KEY_A); _key("move_right", KEY_D)
			"wheel":
				_mouse(action + "_in", MOUSE_BUTTON_WHEEL_UP); _mouse(action + "_out", MOUSE_BUTTON_WHEEL_DOWN)
			_:
				if MOUSE.has(token):
					_mouse(action, MOUSE[token])
				else:
					var code := OS.find_keycode_from_string(token)
					if code == KEY_NONE:
						push_error("keybinds.json#hybrid %s: unknown key '%s'" % [action, token])
					else:
						_key(action, code)

static func _key(action: String, key: Key) -> void:
	var e := InputEventKey.new(); e.physical_keycode = key
	_add(action, e)

static func _mouse(action: String, button: MouseButton) -> void:
	var e := InputEventMouseButton.new(); e.button_index = button
	_add(action, e)

static func _add(action: String, e: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_add_event(action, e)
