## hud-element (§3.7), the first three of ui.json: HP bar, stamina bar (hidden until not full, A),
## combo counter, land caption. Built in code, bottom-left. ponytail: no portrait/XP/MP/minimap yet.
extends CanvasLayer

var player: Node
var world: Node
var _hp: ProgressBar
var _stamina: ProgressBar
var _combo: Label
var _land: Label

func bind(p_player: Node, p_world: Node) -> void:
	player = p_player; world = p_world

func _ready() -> void:
	var margin := MarginContainer.new()                     # full rect; the box shrinks to bottom-left
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	add_child(margin)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.size_flags_vertical = Control.SIZE_SHRINK_END
	margin.add_child(box)
	_land = Label.new(); box.add_child(_land)
	_combo = Label.new(); box.add_child(_combo)
	_hp = _bar(box, Color(0.8, 0.15, 0.15))
	_stamina = _bar(box, Color(0.9, 0.8, 0.2))

func _bar(parent: Control, color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(260, 18); b.show_percentage = false
	var fill := StyleBoxFlat.new(); fill.bg_color = color
	b.add_theme_stylebox_override("fill", fill)
	parent.add_child(b)
	return b

func _process(_dt: float) -> void:
	if player == null:
		return
	_hp.max_value = player.max_hp; _hp.value = player.hp
	var st_max := float(player.cfg["stamina"]["max"]) if not player.cfg.is_empty() else 100.0
	_stamina.max_value = st_max; _stamina.value = player.stamina
	_stamina.visible = player.stamina < st_max
	_combo.text = "combo %d" % player.combo if player.combo > 0 else ""
	if world != null and world.gen != null:
		var l = world.gen.land_of_block(int(player.global_position.x), int(player.global_position.z))
		_land.text = "%s  (%s, %s)" % [l.name, l.landscape, l.danger_tier]
