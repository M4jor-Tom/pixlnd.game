## Required heterogeneous inputs and mapped tables, in their original traversal order.
extends RefCounted
const Encounters := preload("res://ontology/model_encounters.gd")


static func validate_required_inputs(o) -> void:
	for kind in o.REQUIRED_INPUTS:
		for path in str(o.REQUIRED_INPUTS[kind]).split(" "):
			o._required_path(path, kind)
	return validate_flat_catalogs(o)


static func validate_flat_catalogs(o) -> void:
	for name in str(o.REQUIRED_INPUTS.catalog).split(" "):
		if not validate_catalog(o, name):
			return
	return validate_nested_catalogs(o)


static func validate_nested_catalogs(o) -> void:
	for path in [
		"stats.resources",
		"stats.stats",
		"pet-food.foods",
		"pet-food.cut",
		"mission-types.alpha",
		"mission-types.steam",
		"buildings.districts",
		"buildings.buildings"
	]:
		if not validate_nested_catalog(o, path):
			return
	o._validate_mapped_tables()


static func validate_catalog(o, name: String) -> bool:
	var catalog: Dictionary = o._object(o.configs.get(name))
	var count := 0
	for id in catalog:
		if catalog_metadata(o, name, id):
			continue
		count += 1
		if not catalog_row(o, name, id, catalog):
			return false
	return required_catalog_content(o, name, count)


static func catalog_metadata(o, name: String, id) -> bool:
	return (
		str(id).begins_with("_") or str(id).begins_with("$") or id in o.CATALOG_CONFIG.get(name, [])
	)


# Completion, not validity: ordinary rejected rows finish; native abort implicitly returns false.
static func catalog_row(o, name: String, id, catalog: Dictionary) -> bool:
	var path: String = name + "." + str(id)
	if o._input_shape(catalog[id], "object", path):
		if catalog[id].is_empty():
			o.errors.append(path + ": empty content row")
		o._typed_fields_valid(name, catalog[id], path)
	return true


static func validate_nested_catalog(o, path: String) -> bool:
	var parts := path.split(".")
	var rows: Dictionary = o._object(o._object(o.configs.get(parts[0])).get(parts[1]))
	var count := 0
	for id in rows:
		if str(id).begins_with("_") or id == "region-completion-order":
			continue
		count += 1
		if nested_row(o, path, id, rows):
			continue
		return false
	return required_catalog_content(o, path, count)


static func required_catalog_content(o, path: String, count: int) -> bool:
	if count == 0:
		o.errors.append(path + ": required catalog content missing")
	return true


static func nested_row(o, path: String, id, rows: Dictionary) -> bool:
	if o._input_shape(rows[id], "object", path + "." + str(id)):
		if rows[id].is_empty():
			o.errors.append(path + "." + str(id) + ": empty content row")
		if path == "pet-food.foods":
			o._typed_fields_valid("pet-food", rows[id], path + "." + str(id))
	return true


static func validate_mapped_tables(o) -> void:
	var families: Dictionary = o._object(o.configs.get("creature-families"))
	for id in (
		"beetles runners slimes alpacas dogs cats golems trolls skeletons sprouts guardians fish"
		. split(" ")
	):
		family_row(o, families, id)
	for land in o._object(families.get("landscape-rosters")):
		o._input_shape(
			families["landscape-rosters"][land],
			"strings",
			"creature-families.landscape-rosters." + str(land)
		)
	for id in o._object(families.get("forest-dungeon-rosters")):
		o._fields_valid(
			families["forest-dungeon-rosters"][id],
			"creature-families.forest-dungeon-rosters." + str(id),
			{"strings": "members", "string": "boss"}
		)
	for version in ["alpha", "steam"]:
		block_table(o, version)
	static_table(o)
	ability_buffs(o)
	o._validate_settlement_references()
	design_tables(o)


static func family_row(o, families: Dictionary, id: String) -> void:
	var path := "creature-families." + id
	var row: Dictionary = o._object(families.get(id))
	if o._fields_valid(families.get(id), path, {"strings": "members"}):
		family_members(o, path, row.members)
	if row.has("traits"):
		o._input_shape(row.traits, "strings", path + ".traits")


static func family_members(o, path: String, members: Array) -> void:
	for id in members:
		if not o.creatures.has(id):
			o.errors.append(path + ".members: unknown creature " + id)


static func block_table(o, version: String) -> void:
	var rows: Dictionary = o._object(o._object(o.configs.get("block-types")).get(version))
	var count := 0
	for id in rows:
		if id in ["flags", "note"]:
			continue
		count += 1
		block_row(o, version, id, rows[id])
	if count == 0:
		o.errors.append("block-types." + version + ": required numeric table content missing")


static func block_row(o, version: String, id, row: Variant) -> void:
	var path: String = "block-types." + version + "." + str(id)
	if not str(id).is_valid_int():
		o.errors.append(path + ": numeric table key required")
	if version == "alpha":
		o._fields_valid(row, path, {"string": "id", "bool": "solid"})
	else:
		o._input_shape(row, "string", path)


static func static_table(o) -> void:
	if o._object(o._object(o.configs.get("static-entities")).get("by-id")).is_empty():
		o.errors.append("static-entities.by-id: required numeric table content missing")
	for id in o._object(o._object(o.configs.get("static-entities")).get("by-id")):
		if not str(id).is_valid_int():
			o.errors.append("static-entities.by-id." + str(id) + ": numeric key required")
		o._input_shape(
			o.configs["static-entities"]["by-id"][id], "string", "static-entities.by-id." + str(id)
		)


static func ability_buffs(o) -> void:
	var buffs: Dictionary = o._object(
		o._object(o.configs.get("status-effects")).get("ability-buffs")
	)
	if o._input_shape(buffs.get("list"), "strings", "status-effects.ability-buffs.list"):
		for id in buffs.list:
			if not o.abilities.has(id.split(" ")[0]):
				o.errors.append("status-effects.ability-buffs.list: unknown ability " + id)


static func design_tables(o) -> void:
	var generators: Dictionary = o._object(o.configs.get("generators"))
	var design: Dictionary = o._object(generators.get("design"))
	var rows: Dictionary = o._object(design.get("abilities"))
	for id in rows:
		if str(id).begins_with("_") or id in ["runtimes", "dash-speed", "all-min"]:
			continue
		o._input_shape(rows[id], "object", "design.abilities." + str(id))
	var names: Dictionary = o._object(design.get("names"))
	for land in o._object(names.get("land-suffix")):
		o._input_shape(
			names["land-suffix"][land], "strings", "design.names.land-suffix." + str(land)
		)
	for rule in o._array(o._object(design.get("climate")).get("rules")):
		climate_rule(o, rule)


static func climate_rule(o, rule: Variant) -> void:
	var path := "design.climate.rules"
	if not o._identity_strings(rule) or rule.size() != 2:
		o.errors.append(path + ": [landscape-id, expression-string] required")
		return
	if not o.landscapes.has(rule[0]):
		o.errors.append(path + ": unknown landscape " + rule[0])
	else:
		o._fields_valid(
			o.landscapes[rule[0]].raw.get("gen"),
			"landscapes." + str(rule[0]) + ".gen",
			{"number": "relief base", "string": "surface top cliff"}
		)
	var expression := Expression.new()
	# Required terrain field names.
	if expression.parse(rule[1], ["temp", "humidity", "continent", "relief", "roll"]) != OK:
		o.errors.append(path + ": invalid climate expression " + rule[1])


static func validate_races(o) -> void:
	var catalog: Variant = o.configs.get("races")
	if not catalog is Dictionary:
		o.errors.append("races: required catalog object missing or malformed")
		return
	required_races(o, catalog)
	for id in catalog:
		if str(id).begins_with("$") or str(id).begins_with("_"):
			continue
		race_row(o, id, catalog[id])


static func race_row(o, id, row: Variant) -> void:
	var path := "races." + str(id)
	if not row is Dictionary:
		o.errors.append(path + ": required row object")
		return
	if not row.get("playable") is bool:
		o.errors.append(path + ".playable: boolean required")
	if row.get("size-class") not in ["small", "normal", "large"]:
		o.errors.append(path + ".size-class: small, normal or large required")


static func validate_rosters(o) -> bool:
	var rosters: Dictionary = o._object(
		o._object(o.configs.get("creature-families")).get("landscape-rosters")
	)
	for land in rosters:
		if not o._identity_strings(rosters[land]):
			continue
		roster_members(o, land, rosters[land])
	return validate_design_root(o)


static func roster_members(o, land, members: Array) -> void:
	for id in members:
		if not o.creatures.has(id):
			o.errors.append("roster %s: unknown creature %s" % [land, id])


static func validate_design_root(o) -> bool:
	var generator_config: Variant = o.configs.get("generators")
	if not generator_config is Dictionary:
		o.errors.append("generators: required object missing or malformed")
		generator_config = {}
	var design_input: Variant = generator_config.get("design")
	if not design_input is Dictionary:
		o.errors.append("design: required object missing or malformed")
		design_input = {}
	var design: Dictionary = design_input
	return Encounters.validate_encounter_phases(o, design)


static func required_races(o, catalog: Dictionary) -> void:
	for id in ["human", "elf", "dwarf", "goblin", "lizardman", "orc", "undead", "frogman"]:
		if not catalog.has(id):
			o.errors.append("races.%s: required playable race missing" % id)
