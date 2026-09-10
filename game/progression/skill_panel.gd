## screens.skills (§3.7, ui.json, D20): X toggles the class/spec tree as a list; activate (double-click / Enter)
## spends one banked point (c-skill-spend). Built in code like inventory_panel.gd. ponytail: a flat list, no
## columns drawn, no tooltips, no respec; the mouse is freed while it is open.
extends CanvasLayer

var player: Node
var _panel: PanelContainer
var _list: ItemList
var _bank: Label
var _rows: Array = []          # ItemList index → Ability

func bind(p_player: Node) -> void:
	player = p_player
	player.skills_changed.connect(_refresh)

func _ready() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(520, 360)
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new(); _panel.add_child(box)
	var title := Label.new(); title.text = "Skills  (X closes, activate = spend one point; keys 1-4 fire the class skills)"; box.add_child(title)
	_bank = Label.new(); box.add_child(_bank)
	_list = ItemList.new(); _list.size_flags_vertical = Control.SIZE_EXPAND_FILL; box.add_child(_list)
	_list.item_activated.connect(_on_activated)

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("skills-window") and player != null:
		_panel.visible = not _panel.visible
		player.ui_open = _panel.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _panel.visible else Input.MOUSE_MODE_CAPTURED
		if _panel.visible:
			_refresh(); _list.grab_focus()

func _refresh() -> void:
	if player == null:
		return
	var tree = player.skill_tree
	_bank.text = "%d skill points to spend" % player.skill_points
	_list.clear(); _rows.clear()
	for a in tree.nodes:
		var t: Dictionary = a.alpha_tree
		var where: String = "key %d" % int(t["rank"]) if str(t["column"]) == "class" else ("key 4" if str(t["column"]) == "ultimate" else str(t["column"]))
		var line := "%-22s %-10s %2d pts" % [a.display_name, where, tree.spent(a.id)]
		if not tree.is_open(a):
			line += "   (needs %d in %s)" % [int(t["needs"]), tree.prerequisite(a).display_name]
		_list.add_item(line)
		_rows.append(a)

func _on_activated(index: int) -> void:
	player.spend_skill(_rows[index])
