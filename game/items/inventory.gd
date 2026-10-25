## inventory (§3.4): bag entries, worn gear per equipment-slot, coins. Stack rule c-stack-rule,
## slot rule c-slot-accepts. The shared class gate also colors wrong-class inventory rows.
extends RefCounted

signal changed

const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Model := preload("res://ontology/model.gd")

var entries: Array = []  # Item; count lives on the item
var equipment: Dictionary = {}  # slot id → Item
var coins := 0
var _o
var _stackable: Array = []
var class_id: StringName


func _init(o, design: Dictionary, p_class_id: StringName) -> void:
	_o = o
	class_id = p_class_id
	_stackable = design["stack-cap"]["stackable"]


func add(it: Item) -> void:
	if it.type == &"coin":
		coins += it.count
		changed.emit()
		return
	if String(it.type) in _stackable:
		for e in entries:
			if (
				e.type == it.type
				and e.subtype == it.subtype
				and e.level == it.level
				and e.rarity == it.rarity
			):
				e.count += it.count
				changed.emit()
				return
	elif entries.has(it) or equipment.values().has(it):
		return
	entries.append(it)
	changed.emit()


func remove(it: Item, n := 1) -> void:
	it.count -= n
	if it.count <= 0:
		entries.erase(it)
	changed.emit()


## Moves a bag item into its prospective slot; all legality checks happen before mutation.
func equip(it: Item) -> bool:
	if it == null or entries.count(it) != 1 or equipment.values().has(it):
		return false
	var slot := _equip_slot(it)
	if slot == &"" or not _item_allowed(it, slot):
		return false
	var next := equipment.duplicate()
	next[slot] = it
	if not _loadout_valid(next.get(&"main-hand"), next.get(&"off-hand")):
		return false
	if equipment.has(slot):
		entries.append(equipment[slot])
	entries.erase(it)
	equipment[slot] = it
	changed.emit()
	return true


func _equip_slot(it: Item) -> StringName:
	var slot := Items.slot_id(it, _o)
	if slot == &"ring-left" and equipment.has(slot) and not equipment.has(&"ring-right"):
		return &"ring-right"
	if slot != &"main-hand" or it.type != &"weapon" or not _o.weapon_types.has(it.subtype):
		return slot
	var wt: Model.WeaponType = _o.weapon_types[it.subtype]
	var current: Item = equipment.get(&"main-hand")
	if (
		wt.hands == Model.Hands.ONE_HANDED
		and current != null
		and _o.weapon_types.has(current.subtype)
	):
		var current_hands: Model.Hands = (
			(_o.weapon_types[current.subtype] as Model.WeaponType).hands
		)
		if current_hands == Model.Hands.ONE_HANDED and not equipment.has(&"off-hand"):
			return &"off-hand"
	return &"main-hand"


func _item_allowed(it: Item, slot: StringName) -> bool:
	return slot != &"" and it.type != &"pet-food" and class_allowed(it)


func class_allowed(it: Item) -> bool:
	if it == null:
		return false
	if it.type == &"weapon":
		if not _o.weapon_types.has(it.subtype):
			return false
		var wt: Model.WeaponType = _o.weapon_types[it.subtype]
		if (
			not _o.classes.has(class_id)
			or not wt.raw.get("class") is String
			or wt.raw.get("class") != str(class_id)
			or not (_o.classes[class_id] as Model.CharacterClass).weapon_types.has(it.subtype)
			or not Items.weapon_material_allowed(it, _o)
		):
			return false
	if it.type in [&"chest-armor", &"gloves", &"boots", &"shoulder-armor"]:
		if (
			not _o.classes.has(class_id)
			or it.material != (_o.classes[class_id] as Model.CharacterClass).armor_material
		):
			return false
	return true


func _has_loadout(fragment: String) -> bool:
	if not _o.classes.has(class_id):
		return false
	for loadout in (_o.classes[class_id] as Model.CharacterClass).raw.get("weapon-loadouts", []):
		if fragment in str(loadout):
			return true
	return false


func _loadout_valid(main: Item, off: Item) -> bool:
	for it in [main, off]:
		if it != null and (it.type != &"weapon" or not _o.weapon_types.has(it.subtype)):
			return false
	if main != null:
		var hands: Model.Hands = (_o.weapon_types[main.subtype] as Model.WeaponType).hands
		if hands not in [Model.Hands.ONE_HANDED, Model.Hands.TWO_HANDED]:
			return false
		if off != null and hands == Model.Hands.TWO_HANDED:
			return false
	if off == null:
		return true
	var off_hands: Model.Hands = (_o.weapon_types[off.subtype] as Model.WeaponType).hands
	if off_hands == Model.Hands.OFFHAND:
		return _has_loadout("1h + shield")
	return off_hands == Model.Hands.ONE_HANDED and _has_loadout("dual")


func unequip(slot: StringName) -> void:
	if equipment.has(slot):
		entries.append(equipment[slot])
		equipment.erase(slot)
		changed.emit()


func first_consumable() -> Item:
	for e in entries:
		if e.type == &"consumable":
			return e
	return null
