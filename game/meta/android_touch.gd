## Android-only native input/UI overlay. World simulation stays in the root viewport.
extends CanvasLayer
signal map_requested
const TouchLayout := preload("res://game/meta/android_touch_layout.gd")
const TouchPointer := preload("res://game/meta/android_touch_pointer.gd")
const Shop := preload("res://game/items/shop.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const LABELS := {
	"sprint": "Sprint",
	"jump": "Jump",
	"swim-ascent": "Swim Up",
	"basic-attack": "Attack",
	"special-attack": "Special",
	"block": "Block",
	"dodge": "Dodge",
	"class-skill-1": "Skill 1",
	"class-skill-2": "Skill 2",
	"class-skill-3": "Skill 3",
	"class-skill-4": "Skill 4",
	"interact": "Talk",
	"pick-up": "Pick Up",
	"quick-item": "Quick Item",
	"inventory": "Inventory",
	"skills-window": "Skills",
	"nearer": "Camera\nnearer",
	"farther": "Camera\nfarther",
	"world-map": "Map"
}
const HOLDS := ["sprint", "jump", "swim-ascent", "block", "special-attack"]
var profile: Dictionary
var player: Node
var panels := {}
var panel_id := ""
var map_open := false
var map_screen: CanvasLayer
var view: SubViewport
var stick: VirtualJoystick
var stick_rect := Rect2()
var targets := {}
var buttons := {}
var held := {}
var look := Vector2.ZERO
var requests: Array[Dictionary] = []
var safe := Rect2()
var pixels_per_dp := Vector2.ONE
var confirming := false
var _owners := {}  # index -> {target, position}; empty target is an ignored/retired physical touch
var _occupied := {}
var _dispatch := ""
var _normal_release := false
var _suppress := false
var _stick_position := Vector2.ZERO
var _display: TextureRect
var _gameplay: Node2D
var _navigation: HBoxContainer
var _metrics := []
var _layout_valid := false


func setup(
	p_profile: Dictionary,
	p_player: Node,
	inventory: CanvasLayer,
	skills: CanvasLayer,
	shop: CanvasLayer
) -> void:
	TouchLayout.setup(self, p_profile, p_player, inventory, skills, shop)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		handle_touch(event)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if (
		what
		in [
			NOTIFICATION_APPLICATION_FOCUS_OUT,
			NOTIFICATION_APPLICATION_PAUSED,
			NOTIFICATION_WM_WINDOW_FOCUS_OUT
		]
	):
		cancel_all()
		# The OS ended this stream; old drags cannot resume, new downs may reuse its indices.
		_owners.clear()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()


func _process(_dt: float) -> void:
	if OS.has_feature("android") and view != null:
		_refresh_metrics()


func _refresh_metrics() -> void:
	var rect := DisplayServer.get_display_safe_area()
	var dpi := DisplayServer.screen_get_dpi()
	var transform := get_viewport().get_screen_transform()
	var metrics := [rect, dpi, transform, get_viewport().get_visible_rect().size]
	if metrics == _metrics:
		return
	_metrics = metrics
	if dpi <= 0 or rect.size.x <= 0 or rect.size.y <= 0 or is_zero_approx(transform.determinant()):
		cancel_all()
		_layout_valid = false
		push_error(
			(
				"Android display metrics unavailable: safe=%s dpi=%s transform=%s"
				% [rect, dpi, transform]
			)
		)
		return
	var inverse := transform.affine_inverse()
	var logical := inverse * Rect2(rect)
	var dp := Vector2(float(dpi) / 160.0, float(dpi) / 160.0)
	set_layout(
		logical,
		Vector2(
			(inverse.basis_xform(Vector2(dp.x, 0))).length(),
			(inverse.basis_xform(Vector2(0, dp.y))).length()
		)
	)


func set_layout(rect: Rect2, dp: Vector2) -> void:
	TouchLayout.set_layout(self, rect, dp)


static func _texture(size: Vector2i, color: Color) -> ImageTexture:
	return TouchLayout._texture(size, color)


func _pressed(action: String) -> void:
	if _suppress or _dispatch != action:
		return
	if action == "world-map":
		map_requested.emit()
		return
	_press_gameplay(action)


func _released(action: String) -> void:
	if _suppress or _dispatch != action:
		return
	_release_action(action)


func _target(position: Vector2) -> String:
	if stick_rect.has_point(position):
		return "move"
	for action in targets:
		if targets[action].has_point(position):
			return action
	if safe.has_point(position) and position.x > safe.get_center().x:
		return "look"
	return ""


func handle_touch(event: InputEvent) -> void:
	if view == null:
		return
	var id: int = event.index
	if not _layout_valid:
		_invalid_layout_touch(event, id)
		return
	if event is InputEventScreenTouch and event.pressed:
		_touch_down(event, id)
		return
	_owned_touch(event, id)


func _retire(id: int) -> void:
	var owner: Dictionary = _owners[id]
	var target: String = owner.target
	var e := InputEventScreenTouch.new()
	e.index = id
	e.position = owner.position
	e.canceled = true
	_dispatch = target
	_normal_release = false
	view.push_input(e, true)
	_dispatch = ""
	_occupied.erase(target)
	owner.target = ""


func retire_hold(action: String) -> void:
	if _occupied.has(action):
		_retire(_occupied[action])
	held.erase(action)


func cancel_all() -> void:
	_suppress = true
	if not _cancel_widgets():
		return
	for owner in _owners.values():
		owner.target = ""
	_occupied.clear()
	held.clear()
	requests.clear()
	look = Vector2.ZERO
	if not _release_channels():
		return
	_suppress = false
	if player != null:
		player.cancel_touch_requests()


func take_frame() -> Dictionary:
	var move := Vector2.ZERO
	if (
		_occupied.has("move")
		and (
			_stick_position.distance_to(stick_rect.get_center())
			> stick_rect.size.x * .5 * float(profile["deadzone-ratio"])
		)
	):
		move = (
			Vector2(
				(
					Input.get_action_strength("android_move_right")
					- Input.get_action_strength("android_move_left")
				),
				(
					Input.get_action_strength("android_move_down")
					- Input.get_action_strength("android_move_up")
				)
			)
			. normalized()
		)
	var frame := {
		"move": move,
		"held": held.duplicate(),
		"look": look,
		"requests": requests.duplicate(),
		"safe_width": safe.size.x / pixels_per_dp.x if _layout_valid else 0.0
	}
	requests.clear()
	look = Vector2.ZERO
	return frame


func set_map_screen(screen: CanvasLayer) -> void:
	map_screen = screen
	if _layout_valid:
		map_screen.set_safe_area(safe, pixels_per_dp, float(profile["min-target-dp"]))


func set_map_open(value: bool) -> void:
	if map_open == value:
		return
	cancel_all()
	map_open = value
	_gameplay.visible = panel_id == "" and not map_open and _layout_valid
	_navigation.visible = panel_id != ""


func open_panel(id: String) -> void:
	cancel_all()
	if not _hide_panels():
		return
	panel_id = id
	if player != null:
		player.ui_open = id != ""
	_gameplay.visible = id == "" and not map_open and _layout_valid
	_navigation.visible = id != ""
	_show_panel(id)


func back() -> void:
	if map_open:
		cancel_all()
		map_requested.emit()
	elif view != null:
		open_panel("")


func fit_panel(panel: CanvasLayer) -> void:
	TouchLayout.fit_panel(self, panel)


func operation_button(panel: CanvasLayer, text: String, callback: Callable) -> Button:
	return TouchLayout.operation_button(self, panel, text, callback)


var _pointer_control: Control
var _pointer_list: ItemList
var _pointer_down := false


func _panel_target(position: Vector2) -> String:
	return TouchPointer._panel_target(self, position)


func _pointer(position: Vector2, down: bool) -> void:
	TouchPointer._pointer(self, position, down)


func _pointer_drag(event: InputEventScreenDrag) -> void:
	TouchPointer._pointer_drag(self, event)


func _pointer_release(position: Vector2, normal: bool) -> void:
	TouchPointer._pointer_release(self, position, normal)


func preempt_vendor_panel(pending: Array) -> bool:
	if panels.get("shop") == null or not pending.any(func(q): return q.action == "interact"):
		return false
	var npc: Node3D = player._nearest_in_group(
		"npcs", float(player.design["settlement"]["npc"]["interact-radius"])
	)
	if npc == null or not Shop.is_vendor(npc.role):
		return false
	player.talk_nearest()  # The existing service endpoint opens the real shop, ahead of uncommitted gameplay.
	return panel_id != ""


func _press_context(action: String) -> bool:
	if player != null and action in ["jump", "swim-ascent"]:
		var swimming: bool = player.global_position.y < player.water_top - .5
		return _matching_context(action, swimming)
	return true


func _press_gameplay(action: String) -> void:
	if not _press_context(action):
		return
	if action in HOLDS:
		held[action] = true
	var phase := "start" if action in ["jump", "special-attack"] else "trigger"
	if action in ["sprint", "swim-ascent", "block"]:
		return
	_request_press(action, phase)


func _release_action(action: String) -> void:
	held.erase(action)
	if action in ["jump", "special-attack"]:
		if not _normal_release:
			requests = requests.filter(func(q): return q.action != action)
		requests.append({"action": action, "phase": "release" if _normal_release else "cancel"})


func _touch_down(event: InputEvent, id: int) -> void:
	if _owners.has(id):
		return
	var selected = _new_target(event.position)
	if selected == null:
		return
	var target: String = selected
	_owners[id] = {"target": target, "position": event.position}
	if target == "":
		return
	_occupied[target] = id
	_dispatch_down(event, target)


func _touch_drag(event: InputEvent, id: int, owner: Dictionary, target: String) -> void:
	owner.position = event.position
	if target == "look":
		look += event.relative / pixels_per_dp
	elif target == "pointer":
		_pointer_drag(event)
	elif target == "move":
		_stick_position = event.position
		view.push_input(event, true)
	elif target != "" and not targets[target].has_point(event.position):
		_retire(id)
	return


func _touch_up(event: InputEvent, id: int, target: String) -> void:
	if target == "pointer":
		_pointer_release(event.position, not event.canceled)
	else:
		if not _button_up(event, target):
			return
	_occupied.erase(target)
	_owners.erase(id)


func _new_target(position: Vector2):
	var target: String = (
		_panel_target(position) if panel_id != "" or map_open else _target(position)
	)
	if player != null and player.dead:
		target = ""
	if _occupied.has(target):
		target = ""
	return target


func _dispatch_down(event: InputEvent, target: String) -> void:
	if target == "look":
		return
	if target == "pointer":
		_pointer(event.position, true)
		return
	_dispatch = target
	_normal_release = false
	view.push_input(event, true)
	_dispatch = ""
	if target == "move":
		_stick_position = event.position
	# UI ownership preempts the entire unconsumed batch, not just later arrivals.
	if target in ["inventory", "skills-window"]:
		open_panel(target)
	return


func _cancel_widgets() -> bool:
	if view != null:
		_pointer_release(Vector2(-10000, -10000), false)
		for id in _owners:
			if _owners[id].target not in ["", "look", "pointer"]:
				_retire(id)
	return true


func _release_channels() -> bool:
	for action in ["left", "right", "up", "down"]:
		if InputMap.has_action("android_move_" + action):
			Input.action_release("android_move_" + action)
	return true


func _hide_panels() -> bool:
	for panel in panels.values():
		if panel != null:
			panel.set_touch_open(false)
	return true


func _invalid_layout_touch(event: InputEvent, id: int) -> void:
	# Layout cancellation already reset native widgets; only physical releases retire tombstones.
	if event is InputEventScreenTouch and not event.pressed:
		_owners.erase(id)


func _owned_touch(event: InputEvent, id: int) -> void:
	if not _owners.has(id):
		return
	var owner: Dictionary = _owners[id]
	var target: String = owner.target
	if event is InputEventScreenDrag:
		_touch_drag(event, id, owner, target)
		return
	if event is InputEventScreenTouch and not event.pressed:
		_touch_up(event, id, target)


func _show_panel(id: String) -> void:
	if id != "" and panels.get(id) != null:
		panels[id].set_touch_open(true)


func _matching_context(action: String, swimming: bool) -> bool:
	return not ((action == "jump" and swimming) or (action == "swim-ascent" and not swimming))


func _request_press(action: String, phase: String) -> void:
	var canonical := "zoom" if action in ["nearer", "farther"] else action
	if canonical not in profile["actions"]:
		return
	var request := {"action": canonical, "phase": phase}
	if canonical == "zoom":
		request["steps"] = -1 if action == "nearer" else 1
	requests.append(request)


func _native_release(event: InputEvent, target: String) -> bool:
	_dispatch = target
	_normal_release = (
		not event.canceled and (target == "move" or targets[target].has_point(event.position))
	)
	view.push_input(event, true)
	_dispatch = ""
	_normal_release = false
	return true


func _button_up(event: InputEvent, target: String) -> bool:
	if target not in ["", "look"]:
		return _native_release(event, target)
	return true
