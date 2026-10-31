## Ordered world validation, called through the concrete ontology.
extends RefCounted
const Combat := preload("res://ontology/model_combat.gd")


static func validate_settlement_references(o) -> bool:
	var cfg = o._object(o.configs.get("buildings"))
	var buildings = o._object(cfg.get("buildings"))
	var styles = o._object(cfg.get("settlement-styles"))
	building_references(o, buildings)
	style_references(o, styles)
	return landscape_styles(o, buildings, styles)


static func validate_world_references(o) -> void:
	var cfg: Variant = o.configs.get("buildings")
	var buildings: Variant = cfg.get("buildings") if cfg is Dictionary else null
	var districts: Variant = cfg.get("districts") if cfg is Dictionary else null
	if not buildings is Dictionary:
		o.errors.append("buildings.buildings: required catalog object")
		buildings = {}
	if not districts is Dictionary:
		o.errors.append("buildings.districts: required catalog object")
		districts = {}
	district_references(o, districts, buildings)
	landscape_references(o)


static func validate_terrain_ai(o, design: Dictionary) -> bool:
	terrain_scales(o, design)
	var spawns_input: Variant = design.get("spawns", {})
	var ai_input: Variant = spawns_input.get("ai", {}) if spawns_input is Dictionary else {}
	var ai: Dictionary = ai_input if ai_input is Dictionary else {}
	if (
		o._fields_valid(ai, "design.spawns.ai", {"number": "sim-radius aggro-range leash"})
		and (float(ai["sim-radius"]) < float(ai.get("aggro-range", 0)) + float(ai.get("leash", 0)))
	):  # c-sim-radius
		o.errors.append("design.spawns.ai.sim-radius %s < aggro-range + leash" % ai["sim-radius"])
	return Combat.validate_combat_floor(o, design)


static func validate_settlement_runtime(
	o, design: Dictionary, ab: Dictionary, stamina_max: float, se: Dictionary
) -> bool:
	var st_input: Variant = design.get("settlement")  # c-settlement-config (D22)
	if (
		o._fields_valid(
			st_input,
			"design.settlement",
			{
				"number": "radius blend ring-radius no-hostiles-within",
				"strings": "buildings",
				"object": "npc style-by-landscape style-colors"
			}
		)
		and o._fields_valid(st_input.npc, "design.settlement.npc", {"object": "roles"})
	):
		var st: Dictionary = st_input
		var building_config: Variant = o.configs.get("buildings")
		var bj: Dictionary = building_config if building_config is Dictionary else {}
		var building_rows: Variant = bj.get("buildings")
		if not building_rows is Dictionary:
			building_rows = {}
		var roles = o._object(o.configs.get("npc-roles"))
		settlement_geometry(o, st)
		settlement_buildings(o, st, building_rows, roles)
		return o._validate_settlement_landscapes(design, ab, stamina_max, se, st, bj)
	return o._validate_defence(design, ab, stamina_max, se)


static func settlement_landscape(o, id, st: Dictionary, bj: Dictionary) -> void:
	var style = st["style-by-landscape"].get(id)
	if not style is String or not o._object(bj.get("settlement-styles")).has(style):
		o.errors.append(
			"design.settlement.style-by-landscape.%s: missing or unknown style %s" % [id, style]
		)
	elif not (
		st["style-colors"].get(style) is Array and (st["style-colors"][style] as Array).size() == 2
	):
		o.errors.append("design.settlement.style-colors.%s: need [wall, roof]" % style)


static func settlement_shop(o, st: Dictionary) -> void:
	o._selected_tree(
		st.get("shop"),
		{
			"stock": 8,
			"rarity-cap": "common",
			"level-spread": 1,
			"item-shop-pool": "design.loot.consumable-pool",
			"restock": "daily"
		},
		"design.settlement.shop"
	)


static func building_references(o, buildings: Dictionary) -> void:
	for id in buildings:
		building_reference_row(o, id, buildings[id])


static func style_references(o, styles: Dictionary) -> void:
	for id in styles:
		style_reference_row(o, id, styles[id])


static func landscape_styles(o, buildings: Dictionary, styles: Dictionary) -> bool:
	for id in o.landscapes:
		landscape_style_row(o, id, o.landscapes[id].raw, styles)

	var st = o._object(
		o._object(o._object(o.configs.get("generators")).get("design")).get("settlement")
	)
	return service_roles(o, st, buildings, styles)


static func service_roles(o, st: Dictionary, buildings: Dictionary, styles: Dictionary) -> bool:
	var role_map = o._object(o._object(st.get("npc")).get("roles"))
	for id in role_map:
		service_role_row(o, st, buildings, id, role_map[id])

	return runtime_styles(o, st, styles)


static func runtime_styles(o, st: Dictionary, styles: Dictionary) -> bool:
	for land in o._object(st.get("style-by-landscape")):
		runtime_style_row(o, st, styles, land)

	return style_palettes(o, st)


static func building_reference_row(o, id, raw: Variant) -> void:
	var row = o._object(raw)
	for field in ["roles", "stations"]:
		if not row.has(field):
			continue
		building_reference_field(o, id, row, field)


static func building_reference_field(o, id, row: Dictionary, field: String) -> void:
	var path: String = "buildings.buildings." + str(id) + "." + field
	if not o._input_shape(row[field], "strings", path):
		return
	var target = o._object(o.configs.get("npc-roles" if field == "roles" else "crafting-stations"))
	for ref in row[field]:
		if not building_reference_exists(target, ref, field):
			o.errors.append(path + ": unknown reference " + ref)


static func style_reference_row(o, id, row: Variant) -> void:
	var path: String = "buildings.settlement-styles." + str(id)
	if o._fields_valid(row, path, {"strings": "lands"}):
		for land in row.lands:
			if not o.landscapes.has(land):
				o.errors.append(path + ".lands: unknown landscape " + land)


static func landscape_style_row(o, id, raw: Dictionary, styles: Dictionary) -> void:
	if not raw.has("style"):
		return
	var style: Variant = raw.style
	var aliases = {
		"log-houses": "log",
		"jungle (orange roofs)": "jungle",
		"lava-city": "lava",
		"ocean-city (islands)": "ocean",
		"undead (dark grey, pointed roofs, green lights)": "undead"
	}
	# Historical descriptors stay verbatim; runtime uses design.style-by-landscape.
	if not style is String:
		o.errors.append("landscapes." + str(id) + ".style: string required")
		return
	landscape_style_tokens(o, id, style, aliases, styles)


static func district_references(o, districts: Dictionary, buildings: Dictionary) -> void:
	for district in districts:
		district_reference_row(o, district, districts[district], buildings)


static func district_reference_row(o, district, row: Variant, buildings: Dictionary) -> void:
	var path = "buildings.districts." + str(district) + ".buildings"
	if not row is Dictionary:
		o.errors.append(path + ": district row object required")
		return
	var refs: Variant = row.get("buildings", [])
	if not refs is Array:
		o.errors.append(path + ": array required")
		return
	var trainer_classes = []
	for ref in refs:
		district_building_reference(o, path, ref, buildings, trainer_classes)
	adventurer_trainers(o, district, path, refs, trainer_classes)


static func district_building_reference(
	o, path: String, ref: Variant, buildings: Dictionary, trainer_classes: Array
) -> void:
	var id: Variant = ref.get("id") if ref is Dictionary else ref
	if not id is String or not buildings.get(id) is Dictionary:
		o.errors.append(path + ": unknown or malformed building ID " + str(id))
	if ref is Dictionary:
		district_qualification(o, path, id, ref, trainer_classes)


static func trainer_qualification(id: Variant, qualifier: Variant) -> bool:
	return id is String and id == "class-trainer" and qualifier is String


static func landscape_reference_field(o, land, row: Dictionary, field: String) -> void:
	var path: String = "landscapes." + str(land) + "." + field
	var catalog: Variant = o.configs.get("dungeon-types" if field == "dungeons" else "poi-types")
	if not catalog is Dictionary:
		o.errors.append(path + ": reference catalog object required")
		catalog = {}
	var refs: Variant = row[field]
	if not refs is Array:
		o.errors.append(path + ": array of catalog IDs required; qualifiers belong in notes")
		return
	landscape_reference_ids(o, path, refs, catalog)


static func terrain_scales(o, design: Dictionary) -> void:
	var terrain_input: Variant = design.get("terrain")
	if not terrain_input is Dictionary:
		o.errors.append("design.terrain: required object missing or malformed")
	else:
		var scales = {
			"lands-per-axis": 1024, "land-blocks": 16384, "zone-blocks": 64, "land-zones": 256
		}
		for field in scales:
			if not o._is_selected_multiplier(terrain_input.get(field), scales[field]):
				o.errors.append(
					"design.terrain.%s: must equal selected %s" % [field, scales[field]]
				)


static func settlement_geometry(o, st: Dictionary) -> void:
	if float(st["radius"]) <= float(st["blend"]) or float(st["blend"]) < 0.0:
		o.errors.append("design.settlement: need radius > blend >= 0")
	if float(st["ring-radius"]) >= float(st["radius"]):
		o.errors.append("design.settlement.ring-radius must be < radius")
	if float(st["no-hostiles-within"]) < float(st["radius"]):
		o.errors.append("design.settlement.no-hostiles-within < radius")


static func settlement_buildings(
	o, st: Dictionary, building_rows: Dictionary, roles: Dictionary
) -> void:
	for b in st["buildings"]:
		if not building_rows.has(b):
			o.errors.append("design.settlement.buildings: unknown building %s" % b)
	settlement_roles(o, st, roles)


static func landscape_references(o) -> void:
	for land in o.landscapes:
		var row: Dictionary = o.landscapes[land].raw
		for field in ["dungeons", "pois"]:
			if not row.has(field):
				continue
			landscape_reference_field(o, land, row, field)


static func service_role_row(o, st: Dictionary, buildings: Dictionary, id, role: Variant) -> void:
	var path: String = "design.settlement.npc.roles." + str(id)
	if not service_building_exists(o, st, buildings, id):
		o.errors.append(path + ": service building must occur in settlement.buildings")
	if not role is String or role not in o._array(o._object(buildings.get(id)).get("roles")):
		o.errors.append(path + ": role must be offered by building")


static func runtime_style_row(o, st: Dictionary, styles: Dictionary, land) -> void:
	var style: Variant = st["style-by-landscape"][land]
	if not o.landscapes.has(land) or not style is String or not styles.has(style):
		o.errors.append(
			"design.settlement.style-by-landscape." + str(land) + ": unknown landscape or style"
		)


static func building_reference_exists(target: Dictionary, ref, field: String) -> bool:
	return target.get(ref) is Dictionary and (field != "roles" or ref != "dialogue-corpus")


static func landscape_style_tokens(
	o, id, style: String, aliases: Dictionary, styles: Dictionary
) -> void:
	for token in style.split("|"):
		var key: String = token.strip_edges()
		if key.is_empty() or not styles.has(aliases.get(key, key)):
			o.errors.append("landscapes." + str(id) + ".style: unknown style " + key)


static func adventurer_trainers(
	o, district, path: String, refs: Array, trainer_classes: Array
) -> void:
	if district == "adventurer":
		for cid in ["warrior", "ranger", "rogue", "mage"]:
			if trainer_classes.count(cid) != 1:
				o.errors.append(path + ": exactly one class-trainer for " + cid + " required")
		if refs.size() != 4:
			o.errors.append(path + ": four class-qualified trainers required")


static func district_qualification(
	o, path: String, id: Variant, ref: Dictionary, trainer_classes: Array
) -> void:
	var qualifier: Variant = ref.get("class")
	if not trainer_qualification(id, qualifier) or not o.classes.has(qualifier):
		o.errors.append(path + ": class qualification requires a trainer and valid class")
	else:
		trainer_classes.append(qualifier)
	qualification_fields(o, path, ref)


static func qualification_fields(o, path: String, ref: Dictionary) -> void:
	for key in ref:
		if key not in ["id", "class"]:
			o.errors.append(path + ": unknown qualification " + str(key))


static func landscape_reference_ids(o, path: String, refs: Array, catalog: Dictionary) -> void:
	for id in refs:
		if not landscape_reference_exists(id, catalog):
			o.errors.append(path + ": unknown or malformed reference " + str(id))


static func landscape_reference_exists(id: Variant, catalog: Dictionary) -> bool:
	return id is String and catalog.get(id) is Dictionary and not id.begins_with("_")


static func settlement_roles(o, st: Dictionary, roles: Dictionary) -> void:
	for b in st["npc"]["roles"]:
		if not st["npc"]["roles"][b] is String or not roles.has(st["npc"]["roles"][b]):
			o.errors.append(
				"design.settlement.npc.roles.%s: unknown npc-role %s" % [b, st["npc"]["roles"][b]]
			)


static func service_building_exists(o, st: Dictionary, buildings: Dictionary, id) -> bool:
	return buildings.has(id) and id in o._array(st.get("buildings"))


static func style_palettes(o, st: Dictionary) -> bool:
	for style in o._object(st.get("style-colors")):
		o._input_shape(
			st["style-colors"][style], "palette", "design.settlement.style-colors." + str(style)
		)

	return true
