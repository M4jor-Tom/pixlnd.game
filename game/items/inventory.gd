## inventory (§3.4): bag entries, worn gear per equipment-slot, coins. Stack rule c-stack-rule,
## slot rule c-slot-accepts. ponytail: no tabs, no class check on equip (red names come with character creation).
extends RefCounted

signal changed

const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Model := preload("res://ontology/model.gd")

var entries: Array = []            # Item; count lives on the item
var equipment: Dictionary = {}     # slot id → Item
var coins := 0
var _o
var _stackable: Array = []

func _init(o, design: Dictionary) -> void:
	_o = o
	_stackable = design["stack-cap"]["stackable"]

func add(it: Item) -> void:
	if it.type == &"coin":
		coins += it.count; changed.emit(); return
	if String(it.type) in _stackable:
		for e in entries:
			if e.type == it.type and e.subtype == it.subtype and e.level == it.level and e.rarity == it.rarity:
				e.count += it.count; changed.emit(); return
	entries.append(it); changed.emit()

func remove(it: Item, n := 1) -> void:
	it.count -= n
	if it.count <= 0:
		entries.erase(it)
	changed.emit()

## Moves a bag item into its slot; the previous occupant goes back to the bag. False = no slot or hand conflict; nothing moves.
func equip(it: Item) -> bool:
	var slot := Items.slot_id(it, _o)
	if slot == &"":
		return false
	if slot in [&"main-hand", &"off-hand"]:              # c-hands: check the prospective pair before mutating inventory
		var main: Item = it if slot == &"main-hand" else equipment.get(&"main-hand")
		var off: Item = it if slot == &"off-hand" else equipment.get(&"off-hand")
		if main != null and off != null and _o.weapon_types[main.subtype].hands == Model.Hands.TWO_HANDED:
			return false
	if equipment.has(slot):
		entries.append(equipment[slot])
	entries.erase(it); equipment[slot] = it
	changed.emit()
	return true

func unequip(slot: StringName) -> void:
	if equipment.has(slot):
		entries.append(equipment[slot]); equipment.erase(slot); changed.emit()

func first_consumable() -> Item:
	for e in entries:
		if e.type == &"consumable": return e
	return null
