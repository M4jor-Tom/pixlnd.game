## screens.inventory (§3.7, ui.json): B toggles a centred list of worn gear + bag. Activate (double-click
## / Enter) equips gear or uses a consumable. Built in code like hud.gd. ponytail: one list, no tabs,
## no tooltips, no drag; the mouse is freed while it is open.
extends CanvasLayer

var player: Node
var _panel: PanelContainer
var _list: ItemList
var _worn: Label
var _rows: Array = []          # ItemList index → Item

func bind(p_player: Node) -> void:
	player = p_player
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
	if e.is_action_pressed("inventory") and player != null:
		_panel.visible = not _panel.visible
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
	_list.clear(); _rows.clear()
	for it in inv.entries:
		_list.add_item(("%s ×%d" % [player.item_label(it), it.count]) if it.count > 1 else player.item_label(it))
		_rows.append(it)

func _on_activated(index: int) -> void:
	var it = _rows[index]
	if it.type == &"consumable":
		player.use_item(it)
	else:
		player.inventory.equip(it)
