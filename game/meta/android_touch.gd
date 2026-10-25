## Android-only native input/UI overlay. World simulation stays in the root viewport.
extends CanvasLayer
signal map_requested
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
	profile = p_profile
	player = p_player
	panels = {"inventory": inventory, "skills-window": skills, "shop": shop}
	InputMapBuilder.build_android()
	Input.emulate_mouse_from_touch = false
	# ponytail: one full-size overlay composition; profile on Android before optimizing its render cost.
	view = SubViewport.new()
	view.transparent_bg = true
	view.disable_3d = true
	view.handle_input_locally = true
	add_child(view)
	_display = TextureRect.new()
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_display.texture = view.get_texture()
	_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_display)
	_gameplay = Node2D.new()
	view.add_child(_gameplay)
	stick = VirtualJoystick.new()
	stick.joystick_mode = VirtualJoystick.JOYSTICK_FIXED
	stick.visibility_mode = VirtualJoystick.VISIBILITY_ALWAYS
	stick.deadzone_ratio = 0.0
	stick.action_left = &"android_move_left"
	stick.action_right = &"android_move_right"
	stick.action_up = &"android_move_up"
	stick.action_down = &"android_move_down"
	_gameplay.add_child(stick)
	for action in LABELS:
		if (
			action.begins_with("class-skill-")
			and player != null
			and player.skill_tree.class_slot(int(action.right(1))) == null
		):
			continue
		var button := TouchScreenButton.new()
		button.name = action
		button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
		button.passby_press = false
		_gameplay.add_child(button)
		buttons[action] = button
		button.pressed.connect(_pressed.bind(action))
		button.released.connect(_released.bind(action))
		var label := Label.new()
		label.text = LABELS[action]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_child(label)
	_navigation = HBoxContainer.new()
	view.add_child(_navigation)
	_navigation.hide()
	for id in ["inventory", "skills-window", ""]:
		var b := Button.new()
		b.text = "Close" if id == "" else LABELS[id]
		b.pressed.connect(
			func():
				if confirming:
					if id == "" and map_open:
						map_requested.emit()
					else:
						open_panel(id)
		)
		_navigation.add_child(b)
	for panel in panels.values():
		if panel != null:
			panel.reparent(view)
	if player != null:
		player.touch_input = self
		player.get_node("CameraRig").touch_only = true
	if OS.has_feature("android"):
		get_tree().quit_on_go_back = false
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
		_refresh_metrics()


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
	cancel_all()
	safe = rect
	pixels_per_dp = dp
	_layout_valid = rect.size.x > 0 and rect.size.y > 0 and dp.x > 0 and dp.y > 0
	if not _layout_valid:
		return
	view.size = Vector2i(get_viewport().get_visible_rect().size)
	# Text width can increase a target, never shrink its physical minimum.
	var unit := Vector2(
		maxf(float(profile["min-target-dp"]) * dp.x, 96 * dp.x),
		maxf(float(profile["min-target-dp"]) * dp.y, 52 * dp.y)
	)
	var gap := 4.0 * dp
	var joystick_size := maxf(3.0 * unit.y, float(profile["min-target-dp"]) * dp.x)
	stick_rect = Rect2(
		rect.position + Vector2(gap.x, rect.size.y - joystick_size - gap.y),
		Vector2.ONE * joystick_size
	)
	stick.position = stick_rect.position
	stick.size = stick_rect.size
	stick.joystick_size = joystick_size
	stick.tip_size = joystick_size * .4
	targets.clear()
	var index := 0
	for action in buttons:
		var pos := (
			rect.end
			- Vector2((index % 4 + 1) * (unit.x + gap.x), (index / 4 + 1) * (unit.y + gap.y))
		)
		var target := Rect2(pos, unit)
		targets[action] = target
		var button: TouchScreenButton = buttons[action]
		button.position = pos
		var shape := RectangleShape2D.new()
		shape.size = unit
		button.shape = shape
		button.texture_normal = _texture(Vector2i(unit), Color(.08, .12, .2, .8))
		button.texture_pressed = _texture(Vector2i(unit), Color(.22, .5, .7, .95))
		var label: Label = button.get_child(0)
		label.size = unit
		label.add_theme_font_size_override("font_size", int(16 * dp.y))
		index += 1
	_layout_valid = rect.encloses(stick_rect)
	for target in targets.values():
		if not rect.encloses(target) or target.intersects(stick_rect):
			_layout_valid = false
	if not _layout_valid:
		push_error(
			"Android safe area cannot fit the selected minimum-dp controls: %s dp=%s" % [rect, dp]
		)
	_navigation.position = Vector2(safe.end.x - 3 * unit.x - 8 * pixels_per_dp.x, safe.position.y)
	for b in _navigation.get_children():
		b.custom_minimum_size = unit
		var background := StyleBoxFlat.new()
		background.bg_color = Color(.08, .12, .2, 1)
		b.add_theme_stylebox_override("normal", background)
		b.add_theme_font_size_override("font_size", int(16 * dp.y))
	for panel in panels.values():
		if panel != null and panel.touch_ui != null:
			fit_panel(panel)
	if map_screen != null:
		map_screen.set_safe_area(rect, dp, float(profile["min-target-dp"]))
	_gameplay.visible = panel_id == "" and not map_open and _layout_valid


static func _texture(size: Vector2i, color: Color) -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _pressed(action: String) -> void:
	if _suppress or _dispatch != action:
		return
	if action == "world-map":
		map_requested.emit()
		return
	if player != null and action in ["jump", "swim-ascent"]:
		var swimming: bool = player.global_position.y < player.water_top - .5
		if (action == "jump" and swimming) or (action == "swim-ascent" and not swimming):
			return
	if action in HOLDS:
		held[action] = true
	var phase := "start" if action in ["jump", "special-attack"] else "trigger"
	if action in ["sprint", "swim-ascent", "block"]:
		return
	var canonical := "zoom" if action in ["nearer", "farther"] else action
	if canonical not in profile["actions"]:
		return
	var request := {"action": canonical, "phase": phase}
	if canonical == "zoom":
		request["steps"] = -1 if action == "nearer" else 1
	requests.append(request)


func _released(action: String) -> void:
	if _suppress or _dispatch != action:
		return
	held.erase(action)
	if action in ["jump", "special-attack"]:
		if not _normal_release:
			requests = requests.filter(func(q): return q.action != action)
		requests.append({"action": action, "phase": "release" if _normal_release else "cancel"})


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
		# Layout cancellation already reset native widgets; only physical releases retire tombstones.
		if event is InputEventScreenTouch and not event.pressed:
			_owners.erase(id)
		return
	if event is InputEventScreenTouch and event.pressed:
		if _owners.has(id):
			return
		var target := (
			_panel_target(event.position) if panel_id != "" or map_open else _target(event.position)
		)
		if player != null and player.dead:
			target = ""
		if _occupied.has(target):
			target = ""
		_owners[id] = {"target": target, "position": event.position}
		if target == "":
			return
		_occupied[target] = id
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
	if not _owners.has(id):
		return
	var owner: Dictionary = _owners[id]
	var target: String = owner.target
	if event is InputEventScreenDrag:
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
	if event is InputEventScreenTouch and not event.pressed:
		if target == "pointer":
			_pointer_release(event.position, not event.canceled)
		elif target not in ["", "look"]:
			_dispatch = target
			_normal_release = (
				not event.canceled
				and (target == "move" or targets[target].has_point(event.position))
			)
			view.push_input(event, true)
			_dispatch = ""
			_normal_release = false
		_occupied.erase(target)
		_owners.erase(id)


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
	if view != null:
		_pointer_release(Vector2(-10000, -10000), false)
		for id in _owners:
			if _owners[id].target not in ["", "look", "pointer"]:
				_retire(id)
	for owner in _owners.values():
		owner.target = ""
	_occupied.clear()
	held.clear()
	requests.clear()
	look = Vector2.ZERO
	for action in ["left", "right", "up", "down"]:
		if InputMap.has_action("android_move_" + action):
			Input.action_release("android_move_" + action)
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
	for panel in panels.values():
		if panel != null:
			panel.set_touch_open(false)
	panel_id = id
	if player != null:
		player.ui_open = id != ""
	_gameplay.visible = id == "" and not map_open and _layout_valid
	_navigation.visible = id != ""
	if id != "" and panels.get(id) != null:
		panels[id].set_touch_open(true)


func back() -> void:
	if map_open:
		cancel_all()
		map_requested.emit()
	elif view != null:
		open_panel("")


func fit_panel(panel: CanvasLayer) -> void:
	var height: float = minf(280 * pixels_per_dp.y, safe.size.y * .4)
	panel._panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel._panel.custom_minimum_size = Vector2.ZERO
	panel._panel.position = safe.position + Vector2(0, height)
	panel._panel.size = safe.size - Vector2(0, height)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(.035, .05, .08, 1)
	panel._panel.add_theme_stylebox_override("panel", background)
	var theme := Theme.new()
	theme.default_font_size = int(16 * pixels_per_dp.y)
	panel._panel.theme = theme
	var row_height := float(profile["min-target-dp"]) * pixels_per_dp.y
	for list in panel.touch_lists():
		list.custom_minimum_size.y = (
			row_height + list.get_theme_stylebox("panel").get_minimum_size().y
		)
		list.fixed_icon_size = Vector2i(1, int(row_height))
		list.add_theme_font_size_override("font_size", int(16 * pixels_per_dp.y))
		var icon := _texture(Vector2i(1, int(row_height)), Color.TRANSPARENT)
		for i in list.item_count:
			list.set_item_icon(i, icon)
	for button in panel.touch_buttons:
		button.custom_minimum_size = Vector2(116 * pixels_per_dp.x, row_height)


func operation_button(panel: CanvasLayer, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(
		func():
			if confirming:
				callback.call()
	)
	var box: Node = panel._panel.get_child(0)
	var row: Node = box.get_node_or_null("TouchOperations")
	if row == null:
		row = HBoxContainer.new()
		row.name = "TouchOperations"
		box.add_child(row)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(button)
	return button


var _pointer_control: Control
var _pointer_list: ItemList
var _pointer_down := false


func _panel_target(position: Vector2) -> String:
	if _occupied.has("pointer"):
		return ""
	if (
		map_open
		and map_screen != null
		and map_screen.close_button.get_global_rect().has_point(position)
	):
		_pointer_control = map_screen.close_button
		_pointer_list = null
		return "pointer"
	_pointer_control = null
	_pointer_list = null
	for b in _navigation.get_children():
		if b.get_global_rect().has_point(position):
			_pointer_control = b
	var panel = panels.get(panel_id)
	if panel != null:
		for b in panel.touch_buttons:
			if b.get_global_rect().has_point(position):
				_pointer_control = b
		for list in panel.touch_lists():
			if list.get_global_rect().has_point(position):
				_pointer_list = list
	return "pointer" if _pointer_control != null or _pointer_list != null else ""


func _pointer(position: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.device = InputEvent.DEVICE_ID_EMULATION
	e.position = position
	e.global_position = position
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	_pointer_down = down
	view.push_input(e, true)


func _pointer_drag(event: InputEventScreenDrag) -> void:
	if (
		_pointer_control != null
		and not _pointer_control.get_global_rect().has_point(event.position)
	):
		_pointer_release(Vector2(-10000, -10000), false)
		_owners[event.index].target = ""
		_occupied.erase("pointer")
		return
	if _pointer_list != null:
		_pointer_list.get_v_scroll_bar().value -= event.relative.y
		_pointer_list.get_h_scroll_bar().value -= event.relative.x
	var e := InputEventMouseMotion.new()
	e.device = InputEvent.DEVICE_ID_EMULATION
	e.position = event.position
	e.global_position = event.position
	e.relative = event.relative
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	view.push_input(e, true)


func _pointer_release(position: Vector2, normal: bool) -> void:
	if not _pointer_down:
		return
	confirming = (
		normal
		and not _suppress
		and _pointer_control != null
		and _pointer_control.get_global_rect().has_point(position)
	)
	_pointer(position if normal else Vector2(-10000, -10000), false)
	confirming = false
	_pointer_control = null
	_pointer_list = null


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
