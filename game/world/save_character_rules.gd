## Ordered character/item checks. Completion phases keep ordinary rejected rows
## separate from native-error false, which propagates to the original owner.
extends RefCounted
const Domain := preload("res://game/domain/domain.gd")
const Inventory := preload("res://game/items/inventory.gd")
const SkillTree := preload("res://game/progression/skill_tree.gd")


static func validate_character(save, c: Dictionary) -> void:
	save.require(save._text(c.get("id")), "character.id")
	var cls: Variant = c.get("class_id")
	var spec: Variant = c.get("spec")
	if _identity(save, cls, spec) and _progression(save, c) and _skills(save, c, cls, spec):
		_inventory(save, c, cls)


static func validate_item(save, row: Variant, path: String) -> bool:
	var start: int = save.errors.size()
	if not save.require(row is Dictionary, path):
		return false
	if not _item_fields(save, row, path) or save.errors.size() != start:
		return false
	return _item_rules(save, row, path, start)


static func _skills(save, c: Dictionary, cls: Variant, spec: Variant) -> bool:
	if not save.require(_skill_representation(save, c), "character.skills"):
		return true
	var tree := SkillTree.new(save.o, save.design["skill-point"], StringName(cls), StringName(spec))
	for id in c.points:
		if not _skill_point(save, c, id, tree):
			return false
	return _skill_total(save, c, tree)


static func _equipment(save, c: Dictionary, inv) -> bool:
	if not save.require(c.get("equipment") is Dictionary, "character.equipment"):
		return true
	for slot in c.equipment:
		if not save._validate_equipment_item(c, slot, inv):
			return false
	return _hands(save, inv)


static func _item_fields(save, row: Variant, path: String) -> bool:
	for field in ["type", "subtype", "material"]:
		save.require(row.get(field) is String or row.get(field) is StringName, path + "." + field)
	for field in ["rarity", "upgrade_count", "modifier", "minus_modifier"]:
		save.require(save._integer(row.get(field)), path + "." + field)
	save.require(
		save._integer(row.get("level"), 1) and save._integer(row.get("count"), 1),
		path + ".level/count"
	)
	return true


static func _item_kind(save, row: Variant, path: String) -> bool:
	var kind := str(row.type)
	match kind:
		"weapon":
			return save._validate_weapon_item(row, path)
		"chest-armor", "gloves", "boots", "shoulder-armor", "ring", "amulet":
			save.require(row.level <= 100, path + ".power")
			save.require(save.o.materials.has(row.material), path + ".material")
		_:
			return _carried_kind(save, row, path, kind)
	return true


static func _ingredient(save, row: Variant, path: String) -> bool:
	if save.o.materials.has(row.subtype) and save.o.materials[row.subtype].slot_kind == "spirit":
		save.require(row.level <= 100, path + ".power")
	save.require(
		(
			save.o.configs["ingredients"].has(row.subtype)
			or (
				save.o.materials.has(row.subtype)
				and save.o.materials[row.subtype].slot_kind == "spirit"
			)
		),
		path + ".ingredient"
	)
	return true


static func _skill_point(save, c: Dictionary, id: Variant, tree) -> bool:
	if (
		save.require(id is String or id is StringName, "character.points.id")
		and save.require(save._integer(c.points[id], 1), "character.points." + str(id))
	):
		var found := false
		for a in tree.nodes:
			if Domain.id_of(a) == StringName(id):
				found = true
		save.require(found, "character.points." + str(id))
		tree.points[StringName(id)] = c.points[id]
	return true


static func _identity(save, cls: Variant, spec: Variant) -> bool:
	if not save.require(cls is String and save.o.classes.has(cls), "character.class_id"):
		return false
	if not _class_spec(save, spec, cls):
		return false
	return true


static func _progression(save, c: Dictionary) -> bool:
	if save.require(
		save._integer(c.get("level"), 1) and save._integer(c.get("xp")), "character.level/xp"
	):
		save.require(c.xp < Domain.xp_to_next(int(c.level)), "character.xp settled")
	save.require(save._integer(c.get("coins")), "character.coins")
	return true


static func _inventory(save, c: Dictionary, cls: Variant) -> bool:
	var inv := Inventory.new(save.o, save.design, StringName(cls), func(): return int(c.level))
	return _bag(save, c, inv) and _equipment(save, c, inv)


static func _skill_total(save, c: Dictionary, tree) -> bool:
	var spent := 0
	for a in tree.nodes:
		spent += tree.spent(Domain.id_of(a))
		if tree.spent(Domain.id_of(a)) > 0:
			save.require(tree.is_open(a), "character.points prerequisite " + str(Domain.id_of(a)))
	if save._integer(c.get("level"), 1):
		save.require(
			c.banked + spent == (c.level - 1) * Domain.SKILL_POINTS_PER_LEVEL,
			"character.skill point total"
		)
	return true


static func _carried_kind(save, row: Variant, path: String, kind: String) -> bool:
	match kind:
		"consumable":
			save.require(row.level <= 100, path + ".power")
			save.require(save.o.consumables.has(row.subtype), path + ".consumable")
		"ingredient":
			return _ingredient(save, row, path)
		"coin":
			save.require(row.subtype == "" and row.material == "", path + ".coin")
		"pet-food":
			save.require(save.o.pet_foods.has(row.subtype), path + ".pet-food")
		_:
			save.require(false, path + ".implemented item type")
	return true


static func _class_spec(save, spec: Variant, cls: Variant) -> bool:
	var valid: bool = (
		spec is String and save.o.specs.has(spec) and save.o.specs[spec].slot_class == cls
	)
	return save.require(valid, "character.spec")


static func _skill_representation(save, c: Dictionary) -> bool:
	return save._integer(c.get("banked")) and c.get("points") is Dictionary


static func _hands(save, inv) -> bool:
	var main = inv.equipment.get(&"main-hand")
	var off = inv.equipment.get(&"off-hand")
	var valid: bool = (
		(main == null or main.type == &"weapon") and (off == null or off.type == &"weapon")
	)
	if valid:
		save.require(inv._loadout_valid(main, off), "character.equipment hand loadout")
	else:
		save.require(false, "character.equipment hand types")
	return true


static func _bag(save, c: Dictionary, inv) -> bool:
	if save.require(c.get("bag") is Array, "character.bag"):
		for row in c.bag:
			if not save._validate_bag_item(inv, row):
				return false
	return true


static func _item_rules(save, row: Variant, path: String, start: int) -> bool:
	save.require(row.rarity <= Domain.Rarity.LEGENDARY, path + ".rarity")
	var stack_valid: bool = row.type in save.design["stack-cap"].stackable or row.count == 1
	save.require(stack_valid, path + ".stack")
	return _item_kind(save, row, path) and save.errors.size() == start
