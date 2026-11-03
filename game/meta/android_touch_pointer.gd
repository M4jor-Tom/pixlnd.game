## Native panel pointer operations; ownership and confirmation state stay on AndroidTouch.
extends RefCounted


static func _panel_target(a, position: Vector2) -> String:
	if a._occupied.has("pointer"):
		return ""
	var map_hit = _map_target(a, position)
	if map_hit == null:
		return ""
	if map_hit:
		a._pointer_control = a.map_screen.close_button
		a._pointer_list = null
		return "pointer"
	return _ordinary_target(a, position)


static func _ordinary_target(a, position: Vector2) -> String:
	a._pointer_control = null
	a._pointer_list = null
	if not _navigation_target(a, position):
		return ""
	var panel = a.panels.get(a.panel_id)
	if panel != null:
		return _panel_widgets(a, panel, position)
	return "pointer" if a._pointer_control != null or a._pointer_list != null else ""


static func _pointer(a, position: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.device = InputEvent.DEVICE_ID_EMULATION
	e.position = position
	e.global_position = position
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	a._pointer_down = down
	a.view.push_input(e, true)


static func _pointer_drag(a, event: InputEventScreenDrag) -> void:
	if (
		a._pointer_control != null
		and not a._pointer_control.get_global_rect().has_point(event.position)
	):
		a._pointer_release(Vector2(-10000, -10000), false)
		a._owners[event.index].target = ""
		a._occupied.erase("pointer")
		return
	if a._pointer_list != null:
		a._pointer_list.get_v_scroll_bar().value -= event.relative.y
		a._pointer_list.get_h_scroll_bar().value -= event.relative.x
	var e := InputEventMouseMotion.new()
	e.device = InputEvent.DEVICE_ID_EMULATION
	e.position = event.position
	e.global_position = event.position
	e.relative = event.relative
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	a.view.push_input(e, true)


static func _pointer_release(a, position: Vector2, normal: bool) -> void:
	if not a._pointer_down:
		return
	var confirmation = _can_confirm(a, position, normal)
	if confirmation == null:
		return
	a.confirming = confirmation
	a._pointer(position if normal else Vector2(-10000, -10000), false)
	a.confirming = false
	a._pointer_control = null
	a._pointer_list = null


static func _navigation_target(a, position: Vector2) -> bool:
	for b in a._navigation.get_children():
		if b.get_global_rect().has_point(position):
			a._pointer_control = b
	return true


static func _panel_widgets(a, panel, position: Vector2) -> String:
	for b in panel.touch_buttons:
		if b.get_global_rect().has_point(position):
			a._pointer_control = b
	for list in panel.touch_lists():
		if list.get_global_rect().has_point(position):
			a._pointer_list = list
	return "pointer" if a._pointer_control != null or a._pointer_list != null else ""


static func _can_confirm(a, position: Vector2, normal: bool):
	return (
		normal
		and not a._suppress
		and a._pointer_control != null
		and a._pointer_control.get_global_rect().has_point(position)
	)


static func _map_target(a, position: Vector2):
	return (
		a.map_open
		and a.map_screen != null
		and a.map_screen.close_button.get_global_rect().has_point(position)
	)
