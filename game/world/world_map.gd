## ponytail: boundary/player overview only; terrain/map manipulation when a full map slice is authorized.
extends CanvasLayer

var player: CharacterBody3D
var touch: Node
var panel: PanelContainer
var map_view: Control
var close_button: Button
var open := false

func bind(p_player: CharacterBody3D, p_touch: Node) -> void:
	player = p_player; touch = p_touch
	layer = 20
	panel = PanelContainer.new(); panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := StyleBoxFlat.new(); background.bg_color = Color(0.025, 0.035, 0.06, 0.94)
	panel.add_theme_stylebox_override("panel", background)
	add_child(panel)
	var column := VBoxContainer.new(); panel.add_child(column)
	var header := HBoxContainer.new(); column.add_child(header)
	var title := Label.new(); title.text = "World boundary"; title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	close_button = Button.new(); close_button.text = "Close"; close_button.pressed.connect(set_open.bind(false)); header.add_child(close_button)
	map_view = Control.new(); map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_view.draw.connect(_draw_map); column.add_child(map_view)
	panel.hide()
	if touch != null:
		touch.map_requested.connect(_toggle)
		touch.set_map_screen(self)
		reparent(touch.view)
		layer = 0

func _unhandled_input(event: InputEvent) -> void:
	if touch != null or not event.is_action_pressed("world-map") or event.is_echo(): return
	_toggle()
	get_viewport().set_input_as_handled()

func _toggle() -> void:
	set_open(not open)

func set_open(value: bool) -> void:
	if open == value: return
	open = value
	panel.visible = open
	player.map_open = open
	if open:
		player.cancel_touch_requests()
		player._charge = -1.0
	if touch == null:
		if open:
			_restore_cursor = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif _restore_cursor:
			if not player.ui_open: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_restore_cursor = false
	else:
		touch.set_map_open(open)

var _restore_cursor := false

func set_safe_area(rect: Rect2, pixels_per_dp: Vector2, minimum_target_dp: float) -> void:
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.position = rect.position; panel.size = rect.size
	close_button.custom_minimum_size = Vector2.ONE * minimum_target_dp * pixels_per_dp

static func project_position(position: Vector2, minimum: Vector2, maximum: Vector2, rect: Rect2) -> Vector2:
	return Vector2(lerpf(rect.position.x, rect.end.x, inverse_lerp(minimum.x, maximum.x, position.x)),
		lerpf(rect.position.y, rect.end.y, inverse_lerp(minimum.y, maximum.y, position.y)))

func _process(_dt: float) -> void:
	if open: map_view.queue_redraw()

func _draw_map() -> void:
	var rect := map_view.get_rect().grow(-32)
	var square := minf(rect.size.x, rect.size.y) * 0.82
	var world_rect := Rect2(rect.get_center() - Vector2.ONE * square * 0.5, Vector2.ONE * square)
	map_view.draw_rect(world_rect, Color(0.1, 0.15, 0.2), true)
	map_view.draw_rect(world_rect, Color(0.35, 0.95, 1.0), false, 4.0)
	var min_pos: Vector2 = player.world_min
	var max_pos: Vector2 = player.world_max
	var marker := project_position(Vector2((float(player.logical_position()[0])-min_pos.x)/(max_pos.x-min_pos.x),(float(player.logical_position()[2])-min_pos.y)/(max_pos.y-min_pos.y)), Vector2.ZERO, Vector2.ONE, world_rect)
	map_view.draw_circle(marker, 8.0, Color(1.0, 0.9, 0.15))
	map_view.draw_string(ThemeDB.fallback_font, marker + Vector2(12, -8), "You (%.0f, %.0f)" % [player.logical_position()[0], player.logical_position()[2]], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
