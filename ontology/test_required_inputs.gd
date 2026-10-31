## §5 mapped required input boundaries: real ingestion, typed/raw shapes and cumulative diagnostics.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const PATHS = preload("res://ontology/required_input_cases.gd").PATHS

var failed := 0
var cases := 0
var canonical = Model.Ontology.load_dir("res://ontology/instances")


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func fresh():
	var o := Model.Ontology.new()
	for field in [
		"races",
		"classes",
		"specs",
		"abilities",
		"weapon_types",
		"materials",
		"rarities",
		"creatures",
		"pet_foods",
		"landscapes",
		"status_effects",
		"consumables",
		"key_items"
	]:
		o.set(field, canonical.get(field).duplicate())
	for id in canonical.rulesets:
		o.rulesets[id] = canonical.rulesets[id].duplicate(true)
	o.configs = canonical.configs.duplicate(true)
	return o


func reject(o, path: String) -> void:
	cases += 1
	check(not o.validate(), path + " rejects independently")
	check(path in "\n".join(o.errors), path + " diagnosed")
	o.errors.append("prior load diagnostic")
	for ruleset in o.rulesets.values():
		ruleset.is_default = false
	check(not o.validate(), path + " rejects cumulatively")
	var text := "\n".join(o.errors)
	check("prior load diagnostic" in text, path + " retains prior error")
	check("exactly one ruleset must be default" in text, path + " reaches late check")


func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()


func change(root: Dictionary, path: String, value: Variant, remove := false) -> void:
	var parts := path.split(".")
	var parent := root
	for i in range(parts.size() - 1):
		parent = parent[parts[i]]
	if remove:
		parent.erase(parts[-1])
	else:
		parent[parts[-1]] = value


func _init() -> void:
	check(fresh().validate(), "canonical heterogeneous input validates")
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		printerr("PIXLND_TEST_DIR must name an existing isolated absolute directory")
		quit(1)
		return
	var scratch := directory.path_join("required-inputs")
	check(DirAccess.make_dir_recursive_absolute(scratch) == OK, "scratch created")
	var originals := {}
	copy_input_catalogs(scratch, originals)
	missing_input_files(scratch, originals)
	for path in PATHS:
		raw_input_path(scratch, originals, path)
	# In-memory changes use the same definition boundary; no mutation of raw input as fallback.
	for path in PATHS:
		var o = fresh()
		change(o.configs, path, null, true)
		reject(o, path.trim_prefix("generators."))
	_numeric_null_cases(scratch, originals)
	_extra_cases()
	_reference_controls()
	check(Model.Ontology.load_dir(scratch).validate(), "restored scratch validates")
	print("required inputs: %d cases; %d failures" % [cases, failed])
	quit(0 if failed == 0 else 1)


func _numeric_null_cases(scratch: String, originals: Dictionary) -> void:
	for selected in [
		["weapon-types.sword.damage-k", "weapon_types", "torch"],
		["rarities.common.index", "rarities", "uncommon"],
		["pet-food.foods.bubble-gum.id", "pet_foods", "yellow-jelly"],
		["consumables.life-potion.heal-mult", "consumables", "mana-potion"],
		["consumables.elixir-of-power.duration-s", "consumables", "elixir-of-toughness"]
	]:
		var path: String = selected[0]
		var file: String = path.split(".")[0]
		var local := path.trim_prefix(file + ".")
		# Clean assertion RED is possible without reaching the unsafe conversion.
		var raw_only = fresh()
		change(raw_only.configs, path, null)
		reject(raw_only, path)
		var raw: Dictionary = originals[file].duplicate(true)
		change(raw, local, null)
		var target := scratch.path_join(file + ".json")
		write_json(target, raw)
		var o = Model.Ontology.load_dir(scratch)
		check(path in "\n".join(o.errors), path + " diagnosed during load")
		check(o.get(selected[1]).has(selected[2]), path + " later row ingested")
		o.configs.buildings.buildings.inn.roles = [42]
		reject(o, path)
		check(
			"buildings.buildings.inn.roles" in "\n".join(o.errors),
			path + " retains independent malformed building"
		)
		write_json(target, originals[file])
	# Every explicitly supported numeric-null field retains its historical representation.
	var historical = Model.Ontology.load_dir(scratch)
	for selected in [
		["weapon-types", "shuriken", "subtype"],
		["weapon-types", "sword", "combo-cap"],
		["materials", "bronze", "id"],
		["rarities", "mythical", "stars"],
		["creatures", "alpha-dog", "aid"]
	]:
		check(
			historical.configs[selected[0]][selected[1]][selected[2]] == null,
			"historical null control " + ".".join(selected)
		)
	check(historical.validate(), "historical numeric nulls validate after real load")


func _extra_cases() -> void:
	var mutations := {
		"generators.design.progression.gap-mult-range": [[], [0], [0, {}], [0, true], [0, NAN]],
		"generators.design.feel.events.hit": [null, [], 42],
		"generators.design.feel.numbers.colours.hit": [[1, 2], [1, true, 1], [1, INF, 1]],
		"generators.design.feel.sfx.swing": [[], null],
		"generators.design.creature-roles.species.spitter": [null, [], 42],
		"generators.design.creature-roles.species.spitter.shot": [[], null, 42],
		"generators.design.creature-roles.species.spitter.shot.speed": [[], true, INF],
		"generators.design.defence.dodge": [null, []],
		"generators.design.settlement.npc.roles": [[], null],
		"generators.design.settlement.style-colors.desert":
		[{}, ["#ffffff"], ["not-a-colour", "#ffffff"]],
		"generators.design.spawns.ai": [[], null],
		"generators.design.names.land-suffix.greenlands": [[42], [null], [{}]],
		"generators.design.climate.rules":
		[[["oceans"]], [["unknown", "true"]], [["oceans", "temp <"]]],
		"generators.design.abilities.smash.cost": [[], 42],
		"generators.design.abilities.smash.strike": [[], 42],
		"generators.design.abilities.shuriken-attack.throw": [[], 42],
		"generators.design.abilities.shuriken-attack.throw.speed": [[], INF],
		"creature-families.dogs.members": [["unknown"], [42]],
		"creature-families.landscape-rosters.greenlands": [[42], ["unknown"]],
		"creature-families.forest-dungeon-rosters.beetle.members": [[42]],
		"creature-families.forest-dungeon-rosters.beetle.boss": [null, []],
		"buildings.buildings.inn.roles": [["unknown"], ["dialogue-corpus"], [42], null],
		"buildings.buildings.smithy.stations": [["unknown"], [42], null],
		"buildings.settlement-styles.desert.lands": [["unknown"], [42], null],
		"generators.design.settlement.npc.roles.inn": ["unknown", "weapon-vendor", [42]],
		"generators.design.settlement.style-by-landscape.deserts": ["unknown", [42]],
		"status-effects.ability-buffs.list": [["unknown"], [42]],
		"block-types.alpha.0": [null, [], 42],
		"block-types.steam.0": [null, [], 42],
		"static-entities.by-id.0": [null, [], 42]
	}
	extra_mutations(mutations)
	# Malformed content rows are retained and diagnosed, never silently dropped by _rows.
	var representatives := {
		"weapon-types": "sword",
		"materials": "iron",
		"item-types": "weapon",
		"rarities": "common",
		"status-effects": "poison",
		"creatures": "collie",
		"landscapes": "greenlands",
		"terrain-features": "cave",
		"flora": "heartflower",
		"deposits": "iron-deposit",
		"dungeon-types": "castle",
		"poi-types": "arena",
		"factions": "unholy-pact",
		"consumables": "apple",
		"ingredients": "glass-flask",
		"crafting-stations": "anvil",
		"key-items": "artifact",
		"npc-roles": "villager",
		"slash-commands": "/disconnect"
	}
	malformed_content_rows(representatives)
	# Typed conversion hazards, through ingestion rather than only raw validation.
	typed_conversion_hazards()


func _reference_controls() -> void:
	# Historical labels resolve narrowly, without rewriting source strings or runtime selection.
	for descriptor in [
		"european-framework | medieval-stone",
		"log-houses",
		"jungle (orange roofs)",
		"lava-city",
		"ocean-city (islands)",
		"undead (dark grey, pointed roofs, green lights)",
		"desert"
	]:
		var o = Model.Ontology.load_dir("res://ontology/instances")
		o.landscapes.greenlands.raw.style = descriptor
		check(o.validate(), "historical style: " + descriptor)
	for bad in [
		null, true, 42, [], {}, "", "european-framework | unknown", "european-framework | "
	]:
		var o = Model.Ontology.load_dir("res://ontology/instances")
		o.landscapes.greenlands.raw.style = bad
		reject(o, "landscapes.greenlands.style")
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
		for bad in [{}, {"_doc": "metadata only"}]:
			var empty = fresh()
			change(empty.configs, path, bad)
			reject(empty, path)
	var missing_style = fresh()
	missing_style.configs.generators.design.settlement["style-by-landscape"].erase("deserts")
	reject(missing_style, "design.settlement.style-by-landscape.deserts")
	var o = Model.Ontology.load_dir("res://ontology/instances")
	o.configs.buildings["settlement-styles"].erase("medieval-stone")
	reject(o, "landscapes.greenlands.style")
	o = fresh()
	o.configs.generators.design["creature-roles"].species = {}
	check(o.validate(), "empty permissible species override map")
	o = fresh()
	o.configs.generators.erase("design")
	o.configs.buildings.buildings.inn.roles = [42]
	reject(o, "design")
	check(
		"buildings.buildings.inn.roles" in "\n".join(o.errors),
		"independent missing design and malformed building"
	)


func raw_input_path(scratch: String, originals, path) -> void:
	var file: String = path.split(".")[0]
	var local: String = path.trim_prefix(file + ".")
	var target := scratch.path_join(file + ".json")
	if path == file:
		check(DirAccess.remove_absolute(target) == OK, "remove " + file)
		reject(Model.Ontology.load_dir(scratch), path)
		for bad in [null, true, 42, "bad", [], {}, {"_doc": "metadata only"}]:
			write_json(target, bad)
			reject(Model.Ontology.load_dir(scratch), path)
	else:
		var raw: Dictionary = originals[file].duplicate(true)
		change(raw, local, null, true)
		write_json(target, raw)
		reject(Model.Ontology.load_dir(scratch), path.trim_prefix("generators."))
		raw_nested_values(originals, path, file, local)
	write_json(target, originals[file])


func raw_nested_values(originals, path, file, local) -> void:
	for bad in [null, true, 42, [], "bad"]:
		raw_nested_value(originals, path, file, local, bad)


func raw_nested_value(originals, path, file, local, bad) -> void:
	if nested_input_control(path, bad):
		return
	var raw: Dictionary = originals[file].duplicate(true)
	change(raw, local, bad)
	var o = fresh()
	o._ingest(file, raw)
	reject(o, path.trim_prefix("generators."))


func extra_mutations(mutations) -> void:
	for path in mutations:
		for bad in mutations[path]:
			var o = fresh()
			change(o.configs, path, bad)
			var diagnostic: String = path.trim_prefix("generators.")
			if path == "creature-families.landscape-rosters.greenlands" and bad == ["unknown"]:
				diagnostic = "roster greenlands"
			reject(o, diagnostic)


func malformed_content_rows(representatives) -> void:
	for file in representatives:
		var raw: Dictionary = canonical.configs[file]
		var id: String = representatives[file]
		check(raw.has(id), "known content row " + file + "." + id)
		for bad in [null, [], 42]:
			var altered := raw.duplicate(true)
			altered[id] = bad
			var o = fresh()
			o._ingest(file, altered)
			reject(o, file + "." + id)


func typed_conversion_hazards() -> void:
	for selected in [
		["creatures", "collie", "lands"],
		["creatures", "collie", "group"],
		["creatures", "collie", "aid"],
		["landscapes", "greenlands", "climate"],
		["landscapes", "greenlands", "gen"],
		["status-effects", "poison", "sources"],
		["weapon-types", "sword", "subtype"],
		["materials", "iron", "id"],
		["rarities", "common", "index"],
		["consumables", "life-potion", "heal-mult"],
		["consumables", "life-potion", "recipe"]
	]:
		for bad in [[], {}, true]:
			typed_conversion_value(selected, bad)


func copy_input_catalogs(scratch, originals) -> void:
	for file in DirAccess.open("res://ontology/instances").get_files():
		if file.ends_with(".json"):
			var text := FileAccess.get_file_as_string("res://ontology/instances/" + file)
			originals[file.get_basename()] = JSON.parse_string(text)
			write_json(scratch.path_join(file), originals[file.get_basename()])


func missing_input_files(scratch: String, originals) -> void:
	var files := {}
	for path in PATHS:
		files[str(path).split(".")[0]] = true
	for file in files:
		var target := scratch.path_join(str(file) + ".json")
		check(DirAccess.remove_absolute(target) == OK, "remove " + str(file))
		reject(Model.Ontology.load_dir(scratch), str(file))
		write_json(target, originals[file])


func nested_input_control(path, bad: Variant) -> bool:
	match PATHS[path]:
		"array", "strings":
			return bad is Array
		"bool":
			return bad is bool
		"string":
			return bad is String
	return false


func typed_conversion_value(selected, bad) -> void:
	if bad is Array and selected[2] in ["lands", "sources"]:
		return
	if bad is Dictionary and selected[2] in ["climate", "recipe"]:
		return
	var raw: Dictionary = canonical.configs[selected[0]].duplicate(true)
	raw[selected[1]][selected[2]] = bad
	var o = fresh()
	o._ingest(selected[0], raw)
	reject(o, ".".join(selected))
