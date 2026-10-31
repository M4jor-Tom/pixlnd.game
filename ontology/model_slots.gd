## Selected equipment-slot catalog and row acceptance contract.
extends RefCounted
const Inputs := preload("res://ontology/model_inputs.gd")


static func validate_slots(o) -> bool:
	var slot_cfg: Variant = o.configs.get("equipment-slots")
	if not slot_cfg is Dictionary:
		o.errors.append("equipment-slots: required object missing or malformed")
	var slot_rows: Variant = slot_cfg.get("slots") if slot_cfg is Dictionary else null
	var item_type_config: Variant = o.configs.get("item-types")
	if not item_type_config is Dictionary:
		o.errors.append("item-types: required object missing or malformed")
	var item_types: Dictionary = item_type_config if item_type_config is Dictionary else {}
	var expected = {
		"unknown-0": [],
		"amulet": ["amulet"],
		"chest": ["chest-armor"],
		"gloves": ["gloves"],
		"boots": ["boots"],
		"shoulders": ["shoulder-armor"],
		"main-hand": ["weapon"],
		"off-hand": ["weapon"],
		"ring-left": ["ring"],
		"ring-right": ["ring"],
		"lamp": ["light"],
		"special": ["special"],
		"pet": ["pet-cage", "pet-food"]
	}
	var expected_indices = [
		"unknown-0",
		"amulet",
		"chest",
		"gloves",
		"boots",
		"shoulders",
		"main-hand",
		"off-hand",
		"ring-left",
		"ring-right",
		"lamp",
		"special",
		"pet"
	]
	var expected_subtypes = {"lamp": ["lamp"], "special": ["hang-glider", "boat"]}
	var seen_ids = {}
	var seen_indices = {}
	validate_rows(
		o,
		slot_rows,
		expected,
		expected_indices,
		expected_subtypes,
		item_types,
		seen_ids,
		seen_indices
	)
	required_slots(o, expected, seen_ids, seen_indices)
	pet_food_extra(o, slot_cfg)

	return o._validate_equipment_weapons()


static func validate_rows(
	o,
	slot_rows: Variant,
	expected: Dictionary,
	expected_indices: Array,
	expected_subtypes: Dictionary,
	item_types: Dictionary,
	seen_ids: Dictionary,
	seen_indices: Dictionary
) -> void:
	if not slot_rows is Array or slot_rows.size() != 13:
		o.errors.append("equipment-slots.slots: exactly 13 slot rows required")
	else:
		for row in slot_rows:
			validate_row(
				o,
				row,
				expected,
				expected_indices,
				expected_subtypes,
				item_types,
				seen_ids,
				seen_indices
			)


static func validate_row(
	o,
	row: Variant,
	expected: Dictionary,
	expected_indices: Array,
	expected_subtypes: Dictionary,
	item_types: Dictionary,
	seen_ids: Dictionary,
	seen_indices: Dictionary
) -> void:
	if not row is Dictionary:
		o.errors.append("equipment-slots.slots: malformed row")
		return
	var id = str(row.get("id", ""))
	var index: Variant = row.get("index")
	if seen_ids.has(id):
		o.errors.append("equipment-slots.slots.%s: duplicate id" % id)
	seen_ids[id] = true
	validate_index(o, id, index, seen_indices, expected_indices)
	var accepts: Variant = row.get("accepts")
	if not accepts is Array:
		o.errors.append("equipment-slots.slots.%s.accepts: array required" % id)
		return
	acceptance_references(o, id, row, accepts, item_types)
	selected_slot_mapping(o, id, row, accepts, expected, expected_subtypes)


static func validate_index(
	o, id: String, index: Variant, seen_indices: Dictionary, expected_indices: Array
) -> void:
	if not index_is_integer(index):
		o.errors.append("equipment-slots.slots.%s.index: integer required" % id)
	else:
		if seen_indices.has(int(index)):
			o.errors.append("equipment-slots.slots.%s: duplicate index" % id)
		seen_indices[int(index)] = true
		if id in expected_indices and index != expected_indices.find(id):
			o.errors.append("equipment-slots.slots.%s.index: selected mapping mismatch" % id)


static func acceptance_references(
	o, id: String, row: Dictionary, accepts: Array, item_types: Dictionary
) -> void:
	for type_id in accepts:
		acceptance_type(o, id, row, type_id, item_types)


static func acceptance_type(
	o, id: String, row: Dictionary, type_id, item_types: Dictionary
) -> void:
	if not item_types.has(type_id):
		o.errors.append("equipment-slots.slots.%s.accepts: unknown item-type %s" % [id, type_id])
	var type_row: Variant = item_types.get(type_id)
	var restrictions: Variant = row.get("accepts-subtypes", [])
	if restrictions is Array and not restrictions.is_empty() and type_row is Dictionary:
		acceptance_subtypes(o, id, restrictions, type_row)


static func index_is_integer(value: Variant) -> bool:
	if not Inputs.number(value):
		return false
	return not (value is float and (is_nan(value) or is_inf(value) or value != floorf(value)))


static func acceptance_subtypes(o, id: String, restrictions: Array, type_row: Dictionary) -> void:
	var catalog: Variant = type_row.get("subtypes")
	if catalog is Dictionary:
		for subtype in restrictions:
			if not catalog.values().has(subtype):
				o.errors.append("equipment-slots.slots.%s: unknown subtype %s" % [id, subtype])
	elif catalog is String:
		o.errors.append(
			"equipment-slots.slots.%s: subtype restrictions cannot resolve %s" % [id, catalog]
		)


static func required_slots(
	o, expected: Dictionary, seen_ids: Dictionary, seen_indices: Dictionary
) -> void:
	for id in expected:
		if not seen_ids.has(id):
			o.errors.append("equipment-slots.slots.%s: required slot missing" % id)
	required_indices(o, seen_indices)


static func pet_food_extra(o, slot_cfg: Variant) -> void:
	var extra: Variant = slot_cfg.get("extra") if slot_cfg is Dictionary else null
	var food_extra: Variant = extra.get("pet-food") if extra is Dictionary else null
	if not food_extra is Dictionary or food_extra.get("accepts") != ["pet-food"]:
		o.errors.append("equipment-slots.extra.pet-food: separate pet-food acceptance required")


static func selected_slot_mapping(
	o,
	id: String,
	row: Dictionary,
	accepts: Array,
	expected: Dictionary,
	expected_subtypes: Dictionary
) -> void:
	var want: Array = expected.get(id, [])
	if accepts != want:
		o.errors.append("equipment-slots.slots.%s.accepts: selected mapping mismatch" % id)
	if expected_subtypes.has(id) and row.get("accepts-subtypes") != expected_subtypes[id]:
		o.errors.append("equipment-slots.slots.%s.accepts-subtypes: selected mapping mismatch" % id)
	if id == "pet" and row.get("accepts-conditions") != {"pet-food": "during-taming"}:
		o.errors.append("equipment-slots.slots.pet: pet-food must remain conditional during taming")


static func required_indices(o, seen_indices: Dictionary) -> void:
	for index in range(13):
		if not seen_indices.has(index):
			o.errors.append("equipment-slots.slots: required index %d missing" % index)
