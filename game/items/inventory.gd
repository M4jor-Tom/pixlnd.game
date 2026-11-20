## inventory (§3.4): bag entries, worn gear per equipment-slot, coins. Stack rule c-stack-rule,
## slot rule c-slot-accepts. The shared class gate also colors wrong-class inventory rows.
extends RefCounted

signal changed

const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Domain := preload("res://game/domain/domain.gd")

var entries: Array = []  # Item; count lives on the item
var equipment: Dictionary = {}  # slot id → Item
var coins := 0
var _o
var _stackable: Array = []
var class_id: StringName
var _level_provider: Callable


func _init(o, design: Dictionary, p_class_id: StringName, level_provider: Callable) -> void:
	_o = o
	class_id = p_class_id
	_level_provider = level_provider
	_stackable = design["stack-cap"]["stackable"]


func add(it: Item) -> void:
	if it.type == &"coin":
		coins += it.count
		changed.emit()
		return
	if String(it.type) in _stackable:
		_add_stack(it)
		return
	if entries.has(it) or equipment.values().has(it):
		return
	entries.append(it)
	changed.emit()


func _add_stack(it: Item) -> void:
	for e in entries:
		var same = _same_stack(e, it)
		if same == null:
			return  # Preserve add's abort boundary for malformed public bag entries.
		if same:
			e.count += it.count
			changed.emit()
			return
	entries.append(it)
	changed.emit()


## A native evaluation abort returns null, not an ordinary false/non-match.
func _same_stack(e, it: Item) -> Variant:
	return (
		e.type == it.type
		and e.subtype == it.subtype
		and e.level == it.level
		and e.rarity == it.rarity
	)


func remove(it: Item, n := 1) -> void:
	it.count -= n
	if it.count <= 0:
		entries.erase(it)
	changed.emit()


## Moves a bag item into its prospective slot; all legality checks happen before mutation.
func equip(it: Item) -> bool:
	if not _carried_once(it):
		return false
	var slot := _equip_slot(it)
	if slot == &"" or not _item_allowed(it, slot):
		return false
	return _equip_allowed(it, slot)


func _equip_allowed(it: Item, slot: StringName) -> bool:
	var next := equipment.duplicate()
	next[slot] = it
	if not _loadout_valid(next.get(&"main-hand"), next.get(&"off-hand")):
		return false
	return _commit_equip(it, slot)


func _carried_once(it: Item) -> bool:
	return not (it == null or entries.count(it) != 1 or equipment.values().has(it))


func _commit_equip(it: Item, slot: StringName) -> bool:
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
	return _hand_slot(it, slot)


func _hand_slot(it: Item, slot: StringName) -> StringName:
	if slot != &"main-hand" or it.type != &"weapon" or not _o.weapon_types.has(it.subtype):
		return slot
	var wt: Object = _o.weapon_types[it.subtype]
	var current: Item = equipment.get(&"main-hand")
	return _available_hand(wt, current)


func _available_hand(wt: Object, current: Item) -> StringName:
	if (
		Domain.hands(wt) == Domain.Hands.ONE_HANDED
		and current != null
		and _o.weapon_types.has(current.subtype)
	):
		return _second_hand_slot(current)
	return &"main-hand"


func _second_hand_slot(current: Item) -> StringName:
	var current_hands: Domain.Hands = Domain.hands(_o.weapon_types[current.subtype])
	if current_hands == Domain.Hands.ONE_HANDED and not equipment.has(&"off-hand"):
		return &"off-hand"
	return &"main-hand"


func _item_allowed(it: Item, slot: StringName) -> bool:
	return (
		slot != &""
		and it.type != &"pet-food"
		and class_allowed(it)
		and it.level <= Domain.power_for_level(int(_level_provider.call()))
	)


func class_allowed(it: Item) -> bool:
	if it == null:
		return false
	if it.type == &"weapon":
		if not _weapon_class_allowed(it):
			return false
	if it.type in [&"chest-armor", &"gloves", &"boots", &"shoulder-armor"]:
		return _armor_class_allowed(it)
	return true


func _weapon_class_allowed(it: Item) -> bool:
	if not _o.weapon_types.has(it.subtype):
		return false
	var wt: Object = _o.weapon_types[it.subtype]
	if not _weapon_owner_allowed(wt):
		return false
	return _weapon_membership_allowed(it)


func _weapon_membership_allowed(it: Item) -> bool:
	return not (
		not _o.classes[class_id].slot_weapon_types.has(it.subtype)
		or not Items.weapon_material_allowed(it, _o)
	)


func _weapon_owner_allowed(wt: Object) -> bool:
	return not (
		not _o.classes.has(class_id)
		or not wt.slot_class is String
		or wt.slot_class != str(class_id)
	)


func _armor_class_allowed(it: Item) -> bool:
	return not (
		not _o.classes.has(class_id) or it.material != _o.classes[class_id].slot_armor_material
	)


func _has_loadout(fragment: String) -> bool:
	if not _o.classes.has(class_id):
		return false
	for loadout in _o.classes[class_id].slot_weapon_loadouts:
		if fragment in str(loadout):
			return true
	return false


func _loadout_valid(main: Item, off: Item) -> bool:
	for it in [main, off]:
		if it != null and (it.type != &"weapon" or not _o.weapon_types.has(it.subtype)):
			return false
	return _hand_pair_valid(main, off)


func _hand_pair_valid(main: Item, off: Item) -> bool:
	if main != null:
		if not _main_hand_valid(main, off):
			return false
	return _off_hand_valid(off)


func _off_hand_valid(off: Item) -> bool:
	if off == null:
		return true
	var off_hands: Domain.Hands = Domain.hands(_o.weapon_types[off.subtype])
	if off_hands == Domain.Hands.OFFHAND:
		return _has_loadout("1h + shield")
	return off_hands == Domain.Hands.ONE_HANDED and _has_loadout("dual")


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


func _main_hand_valid(main: Item, off: Item) -> bool:
	var hands: Domain.Hands = Domain.hands(_o.weapon_types[main.subtype])
	if hands not in [Domain.Hands.ONE_HANDED, Domain.Hands.TWO_HANDED]:
		return false
	if off != null and hands == Domain.Hands.TWO_HANDED:
		return false
	return true
