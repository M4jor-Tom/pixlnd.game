## screens.npc-service (§3.7, ui.json, D22): E at a vendor opens its stock (left) and the bag (right); activate
## (double-click / Enter) buys or sells at design.prices; E or Esc closes. Built in code like inventory_panel.gd.
## ponytail: no buy-back tab, no tooltips; the mouse is freed while it is open.
extends CanvasLayer

const Shop := preload("res://game/items/shop.gd")

var player: Node
var world: Node
var _panel: PanelContainer
var _title: Label
var _stock: ItemList
var _bag: ItemList
var _stock_rows: Array = []
var _bag_rows: Array = []

func bind(p_player: Node, p_world: Node) -> void:
	player = p_player; world = p_world
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
	_title.text = "%s  (E closes)" % npc.display_name
	_open(true)

func _process(_dt: float) -> void:
	if _panel.visible and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("menu")):
		_open(false)

func _open(on: bool) -> void:
	_panel.visible = on; player.ui_open = on
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_CAPTURED
	if on:
		_refresh(); _stock.grab_focus()

func _refresh() -> void:
	if not _panel.visible:
		return
	_stock.clear()
	for it in _stock_rows:
		_stock.add_item("%s — %d copper" % [player.item_label(it), Shop.buy_price(it, player.o, player.design)])
	_bag.clear(); _bag_rows.clear()
	for it in player.inventory.entries:
		var label: String = player.item_label(it) + (" ×%d" % it.count if it.count > 1 else "")
		_bag.add_item("%s — %d copper" % [label, Shop.sell_price(it, player.o, player.design)])
		_bag_rows.append(it)
	_title.text = _title.text.get_slice("  ·", 0) + "  ·  %d copper" % player.inventory.coins

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
