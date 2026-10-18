## screens.npc-service (§3.7, ui.json, D22): E at a vendor opens its stock (left) and the bag (right); activate
## (double-click / Enter) buys or sells at design.prices; E or Esc closes. Built in code like inventory_panel.gd.
## ponytail: no buy-back tab, no tooltips; the mouse is freed while it is open.
extends CanvasLayer

const Shop := preload("res://game/items/shop.gd")

var touch_ui: Node = null
var touch_buttons: Array[Button] = []
var player: Node
var world: Node
var _panel: PanelContainer
var _title: Label
var _stock: ItemList
var _bag: ItemList
var _stock_rows: Array = []
var _bag_rows: Array = []

func bind(p_player: Node, p_world: Node, p_touch: Node = null) -> void:
	player = p_player; world = p_world; touch_ui = p_touch
	if touch_ui != null: _bind_touch()
	player.talked.connect(_on_talked)
	player.inventory.changed.connect(_refresh)

func _ready() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(760, 400)
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new(); _panel.add_child(box)
	_title = Label.new(); box.add_child(_title)
	var row := HBoxContainer.new(); row.size_flags_vertical = Control.SIZE_EXPAND_FILL; box.add_child(row)
	_stock = _column(row, "Stock  (activate = buy)"); _stock.item_activated.connect(_on_buy)
	_bag = _column(row, "Your bag  (activate = sell one)"); _bag.item_activated.connect(_on_sell)

func _column(parent: Control, caption: String) -> ItemList:
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; parent.add_child(col)
	var l := Label.new(); l.text = caption; col.add_child(l)
	var list := ItemList.new(); list.size_flags_vertical = Control.SIZE_EXPAND_FILL; col.add_child(list)
	return list

func _on_talked(npc: Node) -> void:
	if not Shop.is_vendor(npc.role):
		return
	var l = world.gen.land_of_block(int(player.global_position.x), int(player.global_position.z))
	_stock_rows = Shop.stock(npc.role, world.gen, l, world.gen.village_at(l), player.level, player.o, player.design)
	_title.text = npc.display_name if touch_ui != null else "%s  (E closes)" % npc.display_name
	_open(true)

func _process(_dt: float) -> void:
	if touch_ui == null and _panel.visible and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("menu")):
		_open(false)

func _open(on: bool) -> void:
	if touch_ui != null:
		touch_ui.open_panel("shop" if on else ""); return
	_panel.visible = on; player.ui_open = on
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_CAPTURED
	if on:
		_refresh(); _stock.grab_focus()

func _refresh() -> void:
	if not _panel.visible:
		return
	for button in touch_buttons: button.disabled = true
	_stock.clear()
	for it in _stock_rows:
		_stock.add_item("%s — %d copper" % [player.item_label(it), Shop.buy_price(it, player.o, player.design)])
	_bag.clear(); _bag_rows.clear()
	for it in player.inventory.entries:
		var label: String = player.item_label(it) + (" ×%d" % it.count if it.count > 1 else "")
		_bag.add_item("%s — %d copper" % [label, Shop.sell_price(it, player.o, player.design)])
		_bag_rows.append(it)
	_title.text = _title.text.get_slice("  ·", 0) + "  ·  %d copper" % player.inventory.coins

	if touch_ui != null: touch_ui.fit_panel(self)

func _on_buy(index: int) -> void:
	var it = _stock_rows[index]
	if not Shop.buy(player, it):
		player.notice.emit("Not enough copper")
		return
	if it.type != &"consumable":
		_stock_rows.remove_at(index)
	_refresh()

func _on_sell(index: int) -> void:
	Shop.sell(player, _bag_rows[index])

func _bind_touch() -> void:
	_stock.item_activated.disconnect(_on_buy); _bag.item_activated.disconnect(_on_sell)
	_stock.get_parent().get_child(0).text = "Stock"
	_bag.get_parent().get_child(0).text = "Your bag"
	for data in [["Buy", _stock, _on_buy], ["Sell", _bag, _on_sell]]:
		var list: ItemList = data[1]
		var callback: Callable = data[2]
		var button: Button = touch_ui.operation_button(self, data[0], func():
			var selected := list.get_selected_items()
			if selected.size() == 1: callback.call(selected[0]))
		button.disabled = true; touch_buttons.append(button)
		list.item_selected.connect(func(_i): button.disabled = false)

func touch_lists() -> Array:
	return [_stock, _bag]

func set_touch_open(on: bool) -> void:
	_panel.visible = on
	if on: _refresh()
