## §5 mapped required input boundaries: real ingestion, typed/raw shapes and cumulative diagnostics.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const PATHS := {
	"weapon-types": "catalog",
	"materials": "catalog",
	"item-types": "catalog",
	"rarities": "catalog",
	"status-effects": "catalog",
	"creatures": "catalog",
	"landscapes": "catalog",
	"terrain-features": "catalog",
	"flora": "catalog",
	"deposits": "catalog",
	"dungeon-types": "catalog",
	"poi-types": "catalog",
	"factions": "catalog",
	"consumables": "catalog",
	"ingredients": "catalog",
	"crafting-stations": "catalog",
	"key-items": "catalog",
	"npc-roles": "catalog",
	"slash-commands": "catalog",
	"stats.resources": "object",
	"stats.stats": "object",
	"stats.alpha-item-stat-formulas": "object",
	"stats.alpha-character-formulas": "object",
	"equipment-slots.extra": "object",
	"creature-families.beetles": "object",
	"creature-families.runners": "object",
	"creature-families.slimes": "object",
	"creature-families.alpacas": "object",
	"creature-families.dogs": "object",
	"creature-families.cats": "object",
	"creature-families.golems": "object",
	"creature-families.trolls": "object",
	"creature-families.skeletons": "object",
	"creature-families.sprouts": "object",
	"creature-families.guardians": "object",
	"creature-families.fish": "object",
	"creature-families.landscape-rosters": "object",
	"creature-families.forest-dungeon-rosters": "object",
	"pet-food.foods": "object",
	"pet-food.cut": "object",
	"rarities.mob-strength-tiers-s": "object",
	"rarities.alpha-relative-colors": "object",
	"status-effects.ability-buffs": "object",
	"key-items.counts-per-land-s": "object",
	"key-items.special-accessories-x": "object",
	"consumables.rules": "object",
	"factions.realm-name-examples": "object",
	"mission-types.alpha": "object",
	"mission-types.steam": "object",
	"mission-types.steam._shared": "object",
	"block-types.alpha": "object",
	"block-types.steam": "object",
	"block-types.scale": "object",
	"block-types.cub-format": "object",
	"block-types.alpha.flags": "object",
	"static-entities.by-id": "object",
	"static-entities.behaviour": "object",
	"static-entities.candles": "object",
	"recipes.gear-armor-quantities": "object",
	"recipes.gear-weapons": "object",
	"recipes.refining": "object",
	"recipes.recipe-sources": "object",
	"recipes.customization": "object",
	"recipes.cooking": "object",
	"recipes.alchemy": "object",
	"buildings.districts": "object",
	"buildings.buildings": "object",
	"buildings.settlement-styles": "object",
	"buildings.population": "object",
	"buildings.map-visibility": "object",
	"economy.currency": "object",
	"economy.incomes": "object",
	"economy.prices": "object",
	"economy.shops": "object",
	"economy.rules": "object",
	"economy.loot": "object",
	"rulesets.ruleset-hybrid": "object",
	"rulesets.ruleset-hybrid.flags": "object",
	"keybinds.hybrid": "object",
	"controller-profiles.android": "object",
	"ui.hud": "object",
	"ui.screens": "object",
	"ui.options": "object",
	"ui.camera": "object",
	"slash-commands.chat-rules": "object",
	"generators.world-scales": "object",
	"generators.seed": "object",
	"generators.time": "object",
	"generators.climate": "object",
	"generators.land": "object",
	"generators.terrain": "object",
	"generators.settlement": "object",
	"generators.dungeon": "object",
	"generators.spawns": "object",
	"generators.boss": "object",
	"generators.names": "object",
	"generators.item": "object",
	"generators.realm": "object",
	"generators.npc-appearance": "object",
	"generators.schedule": "object",
	"generators.key-items-s": "object",
	"generators.coarse-map-omega": "object",
	"generators.network-alpha": "object",
	"generators.design": "object",
	"versions.alpha-to-steam-delta": "object",
	"versions.reception": "object",
	"generators.design.enemy-level": "object",
	"generators.design.enemy-hp": "object",
	"generators.design.terrain": "object",
	"generators.design.climate": "object",
	"generators.design.names": "object",
	"generators.design.spawns": "object",
	"generators.design.skill-point": "object",
	"generators.design.abilities": "object",
	"generators.design.resources": "object",
	"generators.design.special-attack": "object",
	"generators.design.status-effects": "object",
	"generators.design.progression": "object",
	"generators.design.crit": "object",
	"generators.design.movement": "object",
	"generators.design.camera": "object",
	"generators.design.combat": "object",
	"generators.design.defence": "object",
	"generators.design.movesets": "object",
	"generators.design.creature-roles": "object",
	"generators.design.feel": "object",
	"generators.design.frame-budget": "object",
	"generators.design.prices": "object",
	"generators.design.stack-cap": "object",
	"generators.design.loot": "object",
	"generators.design.starting-inventory": "object",
	"generators.design.settlement": "object",
	"generators.design.gear-hp": "object",
	"generators.design.initial-encounters": "object",
	"generators.design.artifact": "object",
	"generators.design.artifacts-per-land": "object",
	"generators.design.circle-of-power": "object",
	"generators.design.recipes": "object",
	"generators.design.pvp": "object",
	"generators.design.time": "object",
	"generators.design.terrain.height": "object",
	"generators.design.terrain.heightfield": "object",
	"generators.design.spawns.ai": "object",
	"generators.design.names.land-suffix": "object",
	"generators.design.resources.mp": "object",
	"generators.design.movement.stamina": "object",
	"generators.design.defence.dodge": "object",
	"generators.design.defence.block": "object",
	"generators.design.defence.stealth": "object",
	"generators.design.defence.enemy-hit": "object",
	"generators.design.creature-roles.any-class": "object",
	"generators.design.creature-roles.melee": "object",
	"generators.design.creature-roles.ranged": "object",
	"generators.design.creature-roles.mage": "object",
	"generators.design.creature-roles.species": "object",
	"generators.design.feel.hit-stop": "object",
	"generators.design.feel.shake": "object",
	"generators.design.feel.numbers": "object",
	"generators.design.feel.impact": "object",
	"generators.design.feel.trail": "object",
	"generators.design.feel.level-up": "object",
	"generators.design.feel.events": "object",
	"generators.design.feel.sfx": "object",
	"generators.design.feel.numbers.colours": "object",
	"generators.design.settlement.npc": "object",
	"generators.design.settlement.npc.roles": "object",
	"generators.design.settlement.style-by-landscape": "object",
	"generators.design.settlement.style-colors": "object",
	"generators.design.settlement.shop": "object",
	"generators.design.settlement.inn": "object",
	"generators.design.settlement.trainer": "object",
	"generators.design.loot.coins": "object",
	"generators.design.loot.rarity-weights": "object",
	"generators.design.loot.gear-kinds": "object",
	"generators.design.loot.ground": "object",
	"equipment-slots.slots": "array",
	"equipment-slots.rules": "strings",
	"pet-food.rules": "strings",
	"pet-food.shop-set": "strings",
	"status-effects.not-found": "strings",
	"mission-types.steam.region-completion-order": "strings",
	"static-entities.s-additions": "strings",
	"recipes.crafting-tabs-a": "strings",
	"affixes.common": "strings",
	"affixes.uncommon": "strings",
	"affixes.rare": "strings",
	"affixes.epic": "strings",
	"affixes.legendary": "strings",
	"affixes.name-forms": "strings",
	"audio.sfx-alpha-ids": "strings",
	"slash-commands.cuwo-server-commands": "strings",
	"versions.timeline": "array",
	"generators.design.climate.rules": "array",
	"generators.design.names.syllables": "strings",
	"generators.design.abilities.runtimes": "strings",
	"generators.design.movesets.kinds": "strings",
	"generators.design.stack-cap.stackable": "strings",
	"generators.design.loot.consumable-pool": "strings",
	"generators.design.settlement.buildings": "strings",
	"generators.design.item-stat-curve": "string",
	"generators.design.block-reward": "string",
	"generators.design.regeneration": "string",
	"generators.loot": "string",
	"generators.level-formulas-alpha": "string",
	"generators.design.creature-roles.default": "string",
	"rulesets.ruleset-hybrid.default": "bool"
}
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
	for file in DirAccess.open("res://ontology/instances").get_files():
		if file.ends_with(".json"):
			var text := FileAccess.get_file_as_string("res://ontology/instances/" + file)
			originals[file.get_basename()] = JSON.parse_string(text)
			write_json(scratch.path_join(file), originals[file.get_basename()])
	var files := {}
	for path in PATHS:
		files[str(path).split(".")[0]] = true
	for file in files:
		var target := scratch.path_join(str(file) + ".json")
		check(DirAccess.remove_absolute(target) == OK, "remove " + str(file))
		reject(Model.Ontology.load_dir(scratch), str(file))
		write_json(target, originals[file])
	for path in PATHS:
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
			for bad in [null, true, 42, [], "bad"]:
				if (PATHS[path] == "array" or PATHS[path] == "strings") and bad is Array:
					continue
				if PATHS[path] == "bool" and bad is bool:
					continue
				if PATHS[path] == "string" and bad is String:
					continue
				raw = originals[file].duplicate(true)
				change(raw, local, bad)
				var o = fresh()
				o._ingest(file, raw)
				reject(o, path.trim_prefix("generators."))
		write_json(target, originals[file])
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
	for path in mutations:
		for bad in mutations[path]:
			var o = fresh()
			change(o.configs, path, bad)
			var diagnostic: String = path.trim_prefix("generators.")
			if path == "creature-families.landscape-rosters.greenlands" and bad == ["unknown"]:
				diagnostic = "roster greenlands"
			reject(o, diagnostic)
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
	# Typed conversion hazards, through ingestion rather than only raw validation.
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
			if bad is Array and selected[2] in ["lands", "sources"]:
				continue
			if bad is Dictionary and selected[2] in ["climate", "recipe"]:
				continue
			var raw: Dictionary = canonical.configs[selected[0]].duplicate(true)
			raw[selected[1]][selected[2]] = bad
			var o = fresh()
			o._ingest(selected[0], raw)
			reject(o, ".".join(selected))


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
