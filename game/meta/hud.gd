## hud-element (§3.7), the first three of ui.json: HP bar, stamina bar (hidden until not full, A),
## combo counter, land caption, coins, item-notifications (pick-up toast), level + XP line (portrait's text, D19).
## MP bar (pink while M2 charges) + hotbar line: keys 1-4 state and active buffs (D21). Village name in the land caption
## and NPC service notices as toasts (D22). Block-power and stealth bar, "blocking" in the combo line (D23).
## D25 game feel: the level-up toast pops from design.feel.level-up.pop-scale, and a buff-icon row
## (ui.json#hud.buff-icons) shows one box per active buff with its initial and a draining fill; being stunned is
## the 3D stars over the head now (combat/feel.gd), not text.
## Built in code, bottom-left.
## ponytail: no portrait head/minimap yet; buff icons are letter boxes, no art (todo_implement.md).
extends CanvasLayer

const Model := preload("res://ontology/model.gd")

var player: Node
var world: Node
var _hp: ProgressBar
var _stamina: ProgressBar
var _combo: Label
var _land: Label
var _coins: Label
var _level: Label
var _skills: Label
var _mp: ProgressBar
var _block: ProgressBar
var _stealth: ProgressBar
var _toast: Label
var _buffs: HBoxContainer
var _buff_key := ""

func bind(p_player: Node, p_world: Node) -> void:
	player = p_player; world = p_world
	if player.has_signal("picked_up"):
		player.picked_up.connect(_on_picked_up)
	if player.has_signal("notice"):
		player.notice.connect(_show_toast)
	if player.has_signal("leveled_up"):
		player.leveled_up.connect(_on_level_up)

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
	_coins = Label.new(); box.add_child(_coins)
	_level = Label.new(); box.add_child(_level)
	_toast = Label.new(); _toast.modulate.a = 0.0; box.add_child(_toast)
	_skills = Label.new(); box.add_child(_skills)
	_buffs = HBoxContainer.new(); box.add_child(_buffs)
	_combo = Label.new(); box.add_child(_combo)
	_hp = _bar(box, Color(0.8, 0.15, 0.15))
	_mp = _bar(box, Color(0.3, 0.4, 0.9))
	_stamina = _bar(box, Color(0.9, 0.8, 0.2))
	_block = _bar(box, Color(0.7, 0.7, 0.75))
	_stealth = _bar(box, Color(0.6, 0.3, 0.8))

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
	if player.get("abilities") != null:
		_mp.max_value = float(player.design["resources"]["mp"]["max"]); _mp.value = player.mp
		(_mp.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.95, 0.4, 0.8) if player._charge >= 0.0 else Color(0.3, 0.4, 0.9)
		_skills.text = _skills_line()
		_buff_icons()
	var line: PackedStringArray = []
	if player.combo > 0: line.append("combo %d" % player.combo)
	if player.has_method("stunned") and player.stunned(): line.append("stunned!")   # first person sees no stars
	if player.get("blocking"): line.append("blocking")
	_combo.text = "   ".join(line)
	if player.get("defence") != null and not player.defence.is_empty():
		_block.max_value = player.block_max(); _block.value = player.block_power
		_block.visible = player.blocking or player.block_power < player.block_max()
		_stealth.max_value = 1.0; _stealth.value = player.stealth; _stealth.visible = player.stealth > 0.0
	if player.get("inventory") != null:
		_coins.text = "%d copper" % player.inventory.coins
	if player.get("xp") != null:
		_level.text = "level %d   %d / %d xp   %d skill points" % [player.level, player.xp, Model.xp_to_next(player.level), player.skill_points]
	if world != null and world.gen != null:
		var l = world.gen.land_of_block(int(player.global_position.x), int(player.global_position.z))
		_land.text = "%s  (%s, %s)" % [l.name, l.landscape, l.danger_tier]
		var v: Dictionary = world.gen.village_at(l)
		if not v.is_empty() and Vector2(player.global_position.x - v["centre"].x, player.global_position.z - v["centre"].y).length() <= float(world.gen.settlement["radius"]):
			_land.text += "  —  %s (village)" % v["name"]

func _on_picked_up(label: String) -> void:
	_show_toast("+ " + label)

func _show_toast(text: String) -> void:
	_toast.text = text; _toast.modulate.a = 1.0
	create_tween().tween_property(_toast, "modulate:a", 0.0, 2.0).set_delay(1.0)

## level-up (D25): design.feel.level-up text, popping from pop-scale back to 1 (overshoot, then settle).
func _on_level_up(_level: int) -> void:
	var lv: Dictionary = player.design.get("feel", {}).get("level-up", {}) if player.get("design") != null else {}
	if lv.is_empty():
		return
	_show_toast(str(lv["text"]))
	await get_tree().process_frame                          # the label must be laid out before we centre the pivot
	_toast.pivot_offset = _toast.size * 0.5
	_toast.scale = Vector2.ONE * float(lv["pop-scale"])
	_toast.create_tween().tween_property(_toast, "scale", Vector2.ONE, float(lv["pop-s"])) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## ui.json#hud.buff-icons: one 18×18 box per active buff, its initial, and a fill draining with left / duration.
## Rebuilt only when the set of buffs changes; the fill is redrawn every frame.
func _buff_icons() -> void:
	var buffs: Dictionary = player.abilities.buffs
	var key := ",".join(PackedStringArray(buffs.keys()))
	if key != _buff_key:
		_buff_key = key
		for c in _buffs.get_children():
			_buffs.remove_child(c); c.queue_free()          # never free a live child mid-layout
		for id in buffs:
			var box := ColorRect.new()
			box.custom_minimum_size = Vector2(18, 18); box.color = Color(0.1, 0.1, 0.15)
			var fill := ColorRect.new()
			fill.color = Color(0.3, 0.4, 0.9); fill.name = "Fill"
			fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			box.add_child(fill)
			var l := Label.new()
			l.text = str(player.o.abilities[id].display_name).substr(0, 1)
			l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(l)
			_buffs.add_child(box)
	var i := 0
	for id in buffs:
		if i >= _buffs.get_child_count():
			break
		var b: Dictionary = buffs[id]
		var fill: ColorRect = _buffs.get_child(i).get_node("Fill")
		fill.anchor_top = 1.0 - clampf(float(b["left"]) / maxf(0.01, float(b["r"].get("duration-s", 1.0))), 0.0, 1.0)
		i += 1

## hotbar (ui.json#hud.hotbar, keys 1-4): class skill name + ready / cooldown / no points, then active buffs (D21).
func _skills_line() -> String:
	var parts: PackedStringArray = []
	for slot in range(1, 5):
		var a = player.skill_tree.class_slot(slot)
		if a == null:
			continue
		var cd := float(player.abilities.cooldowns.get(a.id, 0.0))
		var state := "no points" if player.skill_tree.spent(a.id) == 0 else ("%.0fs" % cd if cd > 0.0 else "ready")
		parts.append("%d %s: %s" % [slot, a.display_name, state])
	for id in player.abilities.buffs:
		parts.append("[%s %.0fs]" % [player.o.abilities[id].display_name, player.abilities.buffs[id]["left"]])
	return "   ".join(parts)
