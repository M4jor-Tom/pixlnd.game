## screens.inventory (§3.7, ui.json): B toggles a centred list of worn gear + bag. Activate (double-click
## / Enter) equips gear or uses a consumable. Built in code like hud.gd. ponytail: one list, no tabs,
## no tooltips, no drag; the mouse is freed while it is open.
extends CanvasLayer

var touch_ui: Node = null
var touch_buttons: Array[Button] = []
var player: Node
var _panel: PanelContainer
var _list: ItemList
var _worn: Label
var _touch_worn: ItemList
var _rows: Array = []          # ItemList index → Item

func bind(p_player: Node, p_touch: Node = null) -> void:
	player = p_player; touch_ui = p_touch
	if touch_ui != null: _bind_touch()
	player.inventory.changed.connect(_refresh)

func _ready() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(420, 360)
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new(); _panel.add_child(box)
	var title := Label.new(); title.text = "Inventory  (B closes, activate = equip / use)"; box.add_child(title)
	_worn = Label.new(); box.add_child(_worn)
	_list = ItemList.new(); _list.size_flags_vertical = Control.SIZE_EXPAND_FILL; box.add_child(_list)
	_list.item_activated.connect(_on_activated)

func _unhandled_input(e: InputEvent) -> void:
	if touch_ui == null and e.is_action_pressed("inventory") and player != null:
		_panel.visible = not _panel.visible
		player.ui_open = _panel.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _panel.visible else Input.MOUSE_MODE_CAPTURED
		if _panel.visible:
			_refresh(); _list.grab_focus()

func _refresh() -> void:
	if player == null:
		return
	var inv = player.inventory
	var worn: PackedStringArray = ["%d copper" % inv.coins]
	for slot in inv.equipment:
		worn.append("%s: %s" % [slot, player.item_label(inv.equipment[slot])])
	_worn.text = "\n".join(worn)
	if _touch_worn != null:
		_touch_worn.clear()
		for line in worn:
			_touch_worn.add_item(line)
			_touch_worn.set_item_selectable(_touch_worn.item_count - 1, false)
	for button in touch_buttons: button.disabled = true
	_list.clear(); _rows.clear()
	for it in inv.entries:
		_list.add_item(("%s ×%d" % [player.item_label(it), it.count]) if it.count > 1 else player.item_label(it))
		_rows.append(it)

	if touch_ui != null: touch_ui.fit_panel(self)

func _on_activated(index: int) -> void:
	var it = _rows[index]
	if it.type == &"consumable":
		player.use_item(it)
	else:
		player.inventory.equip(it)

func touch_lists() -> Array:
	return [_list] if _touch_worn == null else [_touch_worn, _list]

func _bind_touch() -> void:
	_worn.hide()
	_touch_worn = ItemList.new(); _touch_worn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_touch_worn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	var box: Node = _panel.get_child(0); box.add_child(_touch_worn); box.move_child(_touch_worn, 2)
	_list.item_activated.disconnect(_on_activated)
	_panel.get_child(0).get_child(0).text = "Inventory — select an item"
	for operation in ["Equip", "Use"]:
		var button: Button = touch_ui.operation_button(self, operation, func():
			var selected := _list.get_selected_items()
			if selected.size() != 1: return
			var it = _rows[selected[0]]
			if player.inventory.entries.has(it) and ((it.type == &"consumable") == (operation == "Use")):
				_on_activated(selected[0]))
		button.disabled = true; touch_buttons.append(button)
	_list.item_selected.connect(func(index):
		var consumable: bool = _rows[index].type == &"consumable"
		touch_buttons[0].disabled = consumable
		touch_buttons[1].disabled = not consumable)

func set_touch_open(on: bool) -> void:
	_panel.visible = on
	if on: _refresh()
