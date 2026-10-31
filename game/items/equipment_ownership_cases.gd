extends RefCounted
const Item := preload("res://game/items/item.gd")


static func run(test) -> void:
	_duplicate_add(test)
	_malformed_bag(test)


static func _duplicate_add(test) -> void:
	var owner: CharacterBody3D = test.player(&"warrior")
	var owned_chest: Item = test.item(&"chest-armor", &"", &"iron")
	var owner_changes := [0]
	owner.inventory.changed.connect(func(): owner_changes[0] += 1)
	owner.inventory.add(owned_chest)
	var owner_bag: Array = owner.inventory.entries.duplicate()
	var owner_worn: Dictionary = owner.inventory.equipment.duplicate()
	var owner_hp: float = owner.max_hp
	var owner_damage: float = owner.weapon["damage"]
	var owner_signals: int = owner_changes[0]
	owner.inventory.add(owned_chest)
	test.check(
		_single_owner(owner, owned_chest, owner_bag, owner_worn),
		"adding the same carried gear does not duplicate its local owner"
	)
	test.check(
		(
			owner_changes[0] == owner_signals
			and owner.max_hp == owner_hp
			and owner.weapon["damage"] == owner_damage
		),
		"repeated carried add does not signal or alter stats"
	)
	test.check(owner.inventory.equip(owned_chest), "single carried gear equips normally")
	_duplicate_worn(test, owner, owned_chest, owner_changes)


static func _malformed_bag(test) -> void:
	var malformed: CharacterBody3D = test.player(&"warrior")
	var doubled_chest: Item = test.item(&"chest-armor", &"", &"iron")
	malformed.inventory.add(doubled_chest)
	malformed.inventory.entries.append(doubled_chest)  # Deliberately malformed public bag, not an add() call.
	var malformed_bag: Array = malformed.inventory.entries.duplicate()
	var malformed_worn: Dictionary = malformed.inventory.equipment.duplicate()
	var malformed_hp: float = malformed.max_hp
	var malformed_damage: float = malformed.weapon["damage"]
	var malformed_changes := [0]
	malformed.inventory.changed.connect(func(): malformed_changes[0] += 1)
	test.check(
		not malformed.inventory.equip(doubled_chest),
		"equip rejects duplicate references already in the bag"
	)
	test.check(
		_malformed_unchanged(
			malformed, doubled_chest, malformed_bag, malformed_worn, malformed_changes
		),
		"rejected malformed bag remains unchanged without signal or silent repair"
	)
	test.check(
		malformed.max_hp == malformed_hp and malformed.weapon["damage"] == malformed_damage,
		"rejected malformed bag preserves HP and damage"
	)


static func _duplicate_worn(test, owner: Node, owned_chest: Item, owner_changes: Array) -> void:
	var owner_bag: Array = owner.inventory.entries.duplicate()
	var owner_worn: Dictionary = owner.inventory.equipment.duplicate()
	var owner_hp: float = owner.max_hp
	var owner_damage: float = owner.weapon["damage"]
	var owner_signals: int = owner_changes[0]
	owner.inventory.add(owned_chest)
	test.check(
		_single_owner(owner, owned_chest, owner_bag, owner_worn),
		"adding the same worn gear does not put it back in the bag"
	)
	test.check(
		(
			owner_changes[0] == owner_signals
			and owner.max_hp == owner_hp
			and owner.weapon["damage"] == owner_damage
		),
		"repeated worn add does not signal or alter stats"
	)


static func _single_owner(
	owner: Node, owned_chest: Item, owner_bag: Array, owner_worn: Dictionary
) -> bool:
	return (
		owner.inventory.entries == owner_bag
		and owner.inventory.equipment == owner_worn
		and (
			(
				owner.inventory.entries.count(owned_chest)
				+ owner.inventory.equipment.values().count(owned_chest)
			)
			== 1
		)
	)


static func _malformed_unchanged(
	malformed: Node,
	doubled_chest: Item,
	malformed_bag: Array,
	malformed_worn: Dictionary,
	malformed_changes: Array
) -> bool:
	return (
		malformed.inventory.entries == malformed_bag
		and malformed.inventory.equipment == malformed_worn
		and malformed.inventory.entries.count(doubled_chest) == 2
		and malformed_changes[0] == 0
	)
