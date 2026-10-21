extends SceneTree

const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Combat := preload("res://game/combat/combat.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const InputMapBuilder := preload("res://game/meta/input_map.gd")

var failed := 0
var o
var design: Dictionary

func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)

func item(type: StringName, subtype: StringName, material: StringName = &"iron") -> Item:
	return Items.generate(RandomNumberGenerator.new(), type, subtype, material, 1, 0)

func player(class_id: StringName) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design.movement, design.camera, &"normal")
	p.setup_combat(design.combat, design.crit, {}, Combat.player_max_hp(1, o.classes[class_id].hp_mult))
	p.setup_items(o, design, class_id)
	p.set_physics_process(false)
	return p

func _init() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	design = o.configs["generators"]["design"]
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	check(o.validate(), "ontology valid")
	var lamp := item(&"light", &"lamp")
	var bad_lamp := item(&"light", &"not-lamp")
	var boat := item(&"special", &"boat")
	var bad_special := item(&"special", &"not-special")
	check(Items.slot_id(lamp, o) == &"lamp" and Items.slot_id(boat, o) == &"special", "valid subtypes route to their slots")
	check(Items.slot_id(bad_lamp, o) == &"" and Items.slot_id(bad_special, o) == &"", "invalid subtypes have no usable slot")
	var food := item(&"pet-food", &"wolf-food")
	check(Items.slot_id(food, o) == &"pet", "pet-food declares the pet slot")

	var warrior := player(&"warrior")
	var inv = warrior.inventory
	var foreign := item(&"weapon", &"sword")
	var bag_before: Array = inv.entries.duplicate()
	var initially_worn: Dictionary = inv.equipment.duplicate()
	var changes := [0]
	inv.changed.connect(func(): changes[0] += 1)
	check(not inv.equip(null) and not inv.equip(foreign), "null and foreign gear cannot equip")
	check(inv.entries == bag_before and inv.equipment == initially_worn and changes[0] == 0, "foreign equip does not mutate or signal")
	var starter: Item = inv.equipment[&"main-hand"]
	check(not inv.equip(starter), "already-worn gear cannot equip twice")
	check(inv.entries == bag_before and inv.equipment == initially_worn and changes[0] == 0, "repeat equip does not duplicate or signal")

	var owner := player(&"warrior")
	var owned_chest := item(&"chest-armor", &"", &"iron")
	var owner_changes := [0]
	owner.inventory.changed.connect(func(): owner_changes[0] += 1)
	owner.inventory.add(owned_chest)
	var owner_bag: Array = owner.inventory.entries.duplicate()
	var owner_worn: Dictionary = owner.inventory.equipment.duplicate()
	var owner_hp: float = owner.max_hp
	var owner_damage: float = owner.weapon["damage"]
	var owner_signals: int = owner_changes[0]
	owner.inventory.add(owned_chest)
	check(owner.inventory.entries == owner_bag and owner.inventory.equipment == owner_worn and owner.inventory.entries.count(owned_chest) + owner.inventory.equipment.values().count(owned_chest) == 1, "adding the same carried gear does not duplicate its local owner")
	check(owner_changes[0] == owner_signals and owner.max_hp == owner_hp and owner.weapon["damage"] == owner_damage, "repeated carried add does not signal or alter stats")
	check(owner.inventory.equip(owned_chest), "single carried gear equips normally")
	owner_bag = owner.inventory.entries.duplicate()
	owner_worn = owner.inventory.equipment.duplicate()
	owner_hp = owner.max_hp
	owner_damage = owner.weapon["damage"]
	owner_signals = owner_changes[0]
	owner.inventory.add(owned_chest)
	check(owner.inventory.entries == owner_bag and owner.inventory.equipment == owner_worn and owner.inventory.entries.count(owned_chest) + owner.inventory.equipment.values().count(owned_chest) == 1, "adding the same worn gear does not put it back in the bag")
	check(owner_changes[0] == owner_signals and owner.max_hp == owner_hp and owner.weapon["damage"] == owner_damage, "repeated worn add does not signal or alter stats")

	var malformed := player(&"warrior")
	var doubled_chest := item(&"chest-armor", &"", &"iron")
	malformed.inventory.add(doubled_chest)
	malformed.inventory.entries.append(doubled_chest) # Deliberately malformed public bag, not an add() call.
	var malformed_bag: Array = malformed.inventory.entries.duplicate()
	var malformed_worn: Dictionary = malformed.inventory.equipment.duplicate()
	var malformed_hp: float = malformed.max_hp
	var malformed_damage: float = malformed.weapon["damage"]
	var malformed_changes := [0]
	malformed.inventory.changed.connect(func(): malformed_changes[0] += 1)
	check(not malformed.inventory.equip(doubled_chest), "equip rejects duplicate references already in the bag")
	check(malformed.inventory.entries == malformed_bag and malformed.inventory.equipment == malformed_worn and malformed.inventory.entries.count(doubled_chest) == 2 and malformed_changes[0] == 0, "rejected malformed bag remains unchanged without signal or silent repair")
	check(malformed.max_hp == malformed_hp and malformed.weapon["damage"] == malformed_damage, "rejected malformed bag preserves HP and damage")

	var ring_a := item(&"ring", &"")
	var ring_b := item(&"ring", &"")
	var ring_c := item(&"ring", &"")
	for ring in [ring_a, ring_b, ring_c]: inv.add(ring)
	check(inv.equip(ring_a) and inv.equip(ring_b), "two distinct rings equip")
	check(inv.equipment.get(&"ring-left") == ring_a and inv.equipment.get(&"ring-right") == ring_b, "second ring uses right slot")
	check(inv.equip(ring_c) and inv.equipment.get(&"ring-left") == ring_c and inv.equipment.get(&"ring-right") == ring_b, "third ring replaces first")
	check(ring_a in inv.entries and ring_b not in inv.entries and ring_c not in inv.entries, "ring replacement preserves bag identity")
	for ring in [ring_a, ring_b, ring_c]:
		check(inv.entries.count(ring) + inv.equipment.values().count(ring) == 1, "ring replacement conserves each item exactly once")
	var repeated_bag: Array = inv.entries.duplicate()
	var repeated_worn: Dictionary = inv.equipment.duplicate()
	var repeated_changes: int = changes[0]
	check(not inv.equip(ring_b) and not inv.equip(ring_c), "worn rings cannot be equipped again")
	check(inv.entries == repeated_bag and inv.equipment == repeated_worn and changes[0] == repeated_changes, "failed ring repeats preserve bag and signals")
	var axe := item(&"weapon", &"axe")
	warrior.inventory.add(axe)
	check(warrior.inventory.equip(axe) and warrior.inventory.equipment.get(&"off-hand") == axe, "warrior can place a second legal 1H weapon off-hand")
	var hp_before: float = warrior.max_hp
	var damage_before: float = warrior.weapon["damage"]
	var greatsword := item(&"weapon", &"greatsword")
	warrior.inventory.add(greatsword)
	var worn_before: Dictionary = warrior.inventory.equipment.duplicate()
	check(not warrior.inventory.equip(greatsword), "2H cannot displace a legal off-hand pair")
	check(warrior.inventory.equipment == worn_before and warrior.max_hp == hp_before and warrior.weapon["damage"] == damage_before, "rejected hand change is atomic and preserves HP/damage")
	var mage_wand := item(&"weapon", &"wand", &"wood")
	warrior.inventory.add(mage_wand)
	check(not warrior.inventory.equip(mage_wand) and mage_wand in warrior.inventory.entries, "wrong-class Wand remains in the bag")
	var silk_chest := item(&"chest-armor", &"", &"silk")
	warrior.inventory.add(silk_chest)
	var state_before: Dictionary = warrior.inventory.equipment.duplicate()
	check(not warrior.inventory.equip(silk_chest) and warrior.inventory.equipment == state_before, "wrong armor material is rejected atomically")
	var food_before: Array = warrior.inventory.entries.duplicate()
	warrior.inventory.add(food)
	check(not warrior.inventory.equip(food) and warrior.inventory.entries == food_before + [food], "pet-food is not unconditionally equipable outside taming")

	var reverse := player(&"warrior")
	var two := item(&"weapon", &"greatsword")
	var shield := item(&"weapon", &"shield")
	reverse.inventory.add(two); reverse.inventory.add(shield)
	check(reverse.inventory.equip(two), "2H equips alone")
	var reverse_before: Dictionary = reverse.inventory.equipment.duplicate()
	check(not reverse.inventory.equip(shield) and reverse.inventory.equipment == reverse_before, "shield-after-2H is rejected without mutation")
	var shield_first := player(&"warrior")
	var two_again := item(&"weapon", &"greatsword")
	var shield_again := item(&"weapon", &"shield")
	shield_first.inventory.add(two_again); shield_first.inventory.add(shield_again)
	check(shield_first.inventory.equip(shield_again), "shield equips with a 1H main hand")
	var shield_before: Dictionary = shield_first.inventory.equipment.duplicate()
	check(not shield_first.inventory.equip(two_again) and shield_first.inventory.equipment == shield_before, "2H-after-shield is rejected without mutation")

	var rogue := player(&"rogue")
	var fist := item(&"weapon", &"fist")
	rogue.inventory.add(fist)
	check(rogue.inventory.equip(fist), "Rogue can equip the approved fist replacement")
	var rogue_off: Item = rogue.inventory.equipment.get(&"off-hand")
	var rogue_main: Item = rogue.inventory.equipment.get(&"main-hand")
	check(rogue_off != null and rogue_main != null and rogue_off.subtype == &"fist" and rogue_main.subtype == &"dagger", "Rogue permits the approved dagger/fist pair")

	var mage := player(&"mage")
	var bracelet_a := item(&"weapon", &"bracelet", &"gold")
	var bracelet_b := item(&"weapon", &"bracelet", &"gold")
	mage.inventory.add(bracelet_a); mage.inventory.add(bracelet_b)
	check(mage.inventory.equip(bracelet_a), "Mage bracelet replacement is valid")
	check(mage.inventory.equip(bracelet_b) and mage.inventory.equipment.get(&"off-hand") == bracelet_b, "Mage can place the second bracelet off-hand")
	var wand_damage: float = mage.weapon["damage"]
	var wand_moveset: Dictionary = mage.moveset.duplicate(true)
	var wand := item(&"weapon", &"wand", &"wood")
	mage.inventory.add(wand)
	var mage_before: Dictionary = mage.inventory.equipment.duplicate()
	check(not mage.inventory.equip(wand) and mage.inventory.equipment == mage_before, "Wand rejects every occupied off-hand item")
	check(is_equal_approx(mage.weapon["damage"], wand_damage) and mage.moveset == wand_moveset, "rejected Wand preserves current attacks and damage")
	mage.inventory.unequip(&"off-hand")
	var second_wand := item(&"weapon", &"wand", &"wood")
	mage.inventory.add(second_wand)
	check(mage.inventory.equip(second_wand) and mage.inventory.equipment[&"main-hand"] == second_wand and not mage.inventory.equipment.has(&"off-hand"), "second Wand cannot create an off-hand item")
	var mage_shield := item(&"weapon", &"shield")
	mage.inventory.add(mage_shield)
	check(not mage.inventory.equip(mage_shield) and mage_shield in mage.inventory.entries, "cross-class off-hand item remains in the bag")

	print("equipment ok" if failed == 0 else "equipment FAILED (%d)" % failed)
	quit(0 if failed == 0 else 1)
