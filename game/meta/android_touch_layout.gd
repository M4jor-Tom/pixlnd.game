## Construction and physical layout only; AndroidTouch owns widgets, metrics and callbacks.
extends RefCounted
const InputMapBuilder := preload("res://game/meta/input_map.gd")


static func setup(
	a,
	p_profile: Dictionary,
	p_player: Node,
	inventory: CanvasLayer,
	skills: CanvasLayer,
	shop: CanvasLayer
) -> void:
	a.profile = p_profile
	a.player = p_player
	a.panels = {"inventory": inventory, "skills-window": skills, "shop": shop}
	InputMapBuilder.build_android()
	Input.emulate_mouse_from_touch = false
	if not _build_controls(a):
		return
	_finish_setup(a)


static func set_layout(a, rect: Rect2, dp: Vector2) -> void:
	a.cancel_all()
	a.safe = rect
	a.pixels_per_dp = dp
	a._layout_valid = rect.size.x > 0 and rect.size.y > 0 and dp.x > 0 and dp.y > 0
	if not a._layout_valid:
		return
	_layout_geometry(a, rect, dp)


static func _texture(size: Vector2i, color: Color) -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


static func fit_panel(a, panel: CanvasLayer) -> void:
	var height: float = minf(280 * a.pixels_per_dp.y, a.safe.size.y * .4)
	panel._panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel._panel.custom_minimum_size = Vector2.ZERO
	panel._panel.position = a.safe.position + Vector2(0, height)
	panel._panel.size = a.safe.size - Vector2(0, height)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(.035, .05, .08, 1)
	panel._panel.add_theme_stylebox_override("panel", background)
	var theme := Theme.new()
	theme.default_font_size = int(16 * a.pixels_per_dp.y)
	panel._panel.theme = theme
	var row_height: float = float(a.profile["min-target-dp"]) * a.pixels_per_dp.y
	for list in panel.touch_lists():
		list.custom_minimum_size.y = (
			row_height + list.get_theme_stylebox("panel").get_minimum_size().y
		)
		list.fixed_icon_size = Vector2i(1, int(row_height))
		list.add_theme_font_size_override("font_size", int(16 * a.pixels_per_dp.y))
		var icon: ImageTexture = a._texture(Vector2i(1, int(row_height)), Color.TRANSPARENT)
		for i in list.item_count:
			list.set_item_icon(i, icon)
	for button in panel.touch_buttons:
		button.custom_minimum_size = Vector2(116 * a.pixels_per_dp.x, row_height)


static func operation_button(a, panel: CanvasLayer, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(
		func():
			if a.confirming:
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


static func _build_view(a) -> bool:
	# ponytail: one full-size overlay composition; profile on Android before optimizing its render cost.
	a.view = SubViewport.new()
	a.view.transparent_bg = true
	a.view.disable_3d = true
	a.view.handle_input_locally = true
	a.add_child(a.view)
	a._display = TextureRect.new()
	a._display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a._display.texture = a.view.get_texture()
	a._display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	a.add_child(a._display)
	return true


static func _build_gameplay(a) -> bool:
	a._gameplay = Node2D.new()
	a.view.add_child(a._gameplay)
	a.stick = VirtualJoystick.new()
	a.stick.joystick_mode = VirtualJoystick.JOYSTICK_FIXED
	a.stick.visibility_mode = VirtualJoystick.VISIBILITY_ALWAYS
	a.stick.deadzone_ratio = 0.0
	a.stick.action_left = &"android_move_left"
	a.stick.action_right = &"android_move_right"
	a.stick.action_up = &"android_move_up"
	a.stick.action_down = &"android_move_down"
	a._gameplay.add_child(a.stick)
	return true


static func _build_buttons(a) -> bool:
	for action in a.LABELS:
		if (
			action.begins_with("class-skill-")
			and a.player != null
			and a.player.skill_tree.class_slot(int(action.right(1))) == null
		):
			continue
		var button := TouchScreenButton.new()
		button.name = action
		button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
		button.passby_press = false
		a._gameplay.add_child(button)
		a.buttons[action] = button
		button.pressed.connect(a._pressed.bind(action))
		button.released.connect(a._released.bind(action))
		var label := Label.new()
		label.text = a.LABELS[action]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_child(label)
	return true


static func _build_navigation(a) -> bool:
	a._navigation = HBoxContainer.new()
	a.view.add_child(a._navigation)
	a._navigation.hide()
	for id in ["inventory", "skills-window", ""]:
		var b := Button.new()
		b.text = "Close" if id == "" else a.LABELS[id]
		b.pressed.connect(
			func():
				if a.confirming:
					if id == "" and a.map_open:
						a.map_requested.emit()
					else:
						a.open_panel(id)
		)
		a._navigation.add_child(b)
	return true


static func _finish_setup(a) -> bool:
	for panel in a.panels.values():
		if panel != null:
			panel.reparent(a.view)
	if a.player != null:
		a.player.touch_input = a
		a.player.get_node("CameraRig").touch_only = true
	if OS.has_feature("android"):
		a.get_tree().quit_on_go_back = false
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
		a._refresh_metrics()
	return true


static func _layout_stick(a, rect: Rect2, gap: Vector2, joystick_size: float) -> bool:
	a.stick_rect = Rect2(
		rect.position + Vector2(gap.x, rect.size.y - joystick_size - gap.y),
		Vector2.ONE * joystick_size
	)
	a.stick.position = a.stick_rect.position
	a.stick.size = a.stick_rect.size
	a.stick.joystick_size = joystick_size
	a.stick.tip_size = joystick_size * .4
	return true


static func _layout_buttons(a, rect: Rect2, dp: Vector2, unit: Vector2, gap: Vector2) -> bool:
	a.targets.clear()
	var index := 0
	for action in a.buttons:
		var pos: Vector2 = (
			rect.end
			- Vector2((index % 4 + 1) * (unit.x + gap.x), (index / 4 + 1) * (unit.y + gap.y))
		)
		var target: Rect2 = Rect2(pos, unit)
		a.targets[action] = target
		var button: TouchScreenButton = a.buttons[action]
		button.position = pos
		var shape := RectangleShape2D.new()
		shape.size = unit
		button.shape = shape
		button.texture_normal = a._texture(Vector2i(unit), Color(.08, .12, .2, .8))
		button.texture_pressed = a._texture(Vector2i(unit), Color(.22, .5, .7, .95))
		var label: Label = button.get_child(0)
		label.size = unit
		label.add_theme_font_size_override("font_size", int(16 * dp.y))
		index += 1
	return true


static func _validate_targets(a, rect: Rect2, dp: Vector2) -> bool:
	a._layout_valid = rect.encloses(a.stick_rect)
	for target in a.targets.values():
		if not rect.encloses(target) or target.intersects(a.stick_rect):
			a._layout_valid = false
	if not a._layout_valid:
		push_error(
			"Android safe area cannot fit the selected minimum-dp controls: %s dp=%s" % [rect, dp]
		)
	return true


static func _layout_panels(a, rect: Rect2, dp: Vector2, unit: Vector2) -> bool:
	a._navigation.position = Vector2(
		a.safe.end.x - 3 * unit.x - 8 * a.pixels_per_dp.x, a.safe.position.y
	)
	for b in a._navigation.get_children():
		b.custom_minimum_size = unit
		var background := StyleBoxFlat.new()
		background.bg_color = Color(.08, .12, .2, 1)
		b.add_theme_stylebox_override("normal", background)
		b.add_theme_font_size_override("font_size", int(16 * dp.y))
	if not _fit_panels(a, rect, dp):
		return false
	a._gameplay.visible = a.panel_id == "" and not a.map_open and a._layout_valid
	return true


static func _build_controls(a) -> bool:
	return _build_view(a) and _build_gameplay(a) and _build_buttons(a) and _build_navigation(a)


static func _layout_geometry(a, rect: Rect2, dp: Vector2) -> bool:
	a.view.size = Vector2i(a.get_viewport().get_visible_rect().size)
	# Text width can increase a target, never shrink its physical minimum.
	var unit: Vector2 = Vector2(
		maxf(float(a.profile["min-target-dp"]) * dp.x, 96 * dp.x),
		maxf(float(a.profile["min-target-dp"]) * dp.y, 52 * dp.y)
	)
	var gap: Vector2 = 4.0 * dp
	var joystick_size: float = maxf(3.0 * unit.y, float(a.profile["min-target-dp"]) * dp.x)
	return (
		_layout_stick(a, rect, gap, joystick_size)
		and _layout_buttons(a, rect, dp, unit, gap)
		and _validate_targets(a, rect, dp)
		and _layout_panels(a, rect, dp, unit)
	)


static func _fit_panels(a, rect: Rect2, dp: Vector2) -> bool:
	for panel in a.panels.values():
		if panel != null and panel.touch_ui != null:
			a.fit_panel(panel)
	if a.map_screen != null:
		a.map_screen.set_safe_area(rect, dp, float(a.profile["min-target-dp"]))
	return true
