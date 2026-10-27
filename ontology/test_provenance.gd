## Finite §5 source scopes; annotations are history, never availability.
extends SceneTree

const Model := preload("res://ontology/model.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func fresh():
	return Model.Ontology.load_dir("res://ontology/instances")


func _init() -> void:
	var o = fresh()
	check(o.validate(), "canonical definitions validate")
	check(o.landscapes["swamp-lands"].versions.is_empty(), "S? is not confirmed S")
	check(Model.Entry.parse_versions(["A?", "S"]) == [Model.Version.S], "mixed qualification")
	check(o.pet_foods["bubble-gum"].versions.is_empty(), "no food A+S fallback")
	check(o.landscapes["swamp-lands"].source_tags == ["S?"], "qualified annotation modeled")
	check(o.landscapes["swamp-lands"].raw.versions == ["S?"], "raw qualification retained")
	check(
		(
			Model.Entry.parse_versions(["A", "S", "X", "Ω"])
			== [Model.Version.A, Model.Version.S, Model.Version.X, Model.Version.OMEGA]
		),
		"confirmed enums unchanged"
	)
	check_scopes(o)
	check_holds(o)
	check_overrides()
	check_nested_annotations()
	check_context_annotations()
	check_raw_loading()
	print("provenance ok" if failed == 0 else "provenance FAILED (%d)" % failed)
	quit(0 if failed == 0 else 1)


func expect_source(o, path: String, tags: Array, origin: String, status: String) -> void:
	check(
		o.source_at(path) == {"tags": tags, "origin": origin, "status": status},
		path + " resolves " + str(tags)
	)


func check_scopes(o) -> void:
	# Every approved envelope, including all exact mixed-container and generator subfacts.
	var scopes := {
		"A":
		"block-types.alpha item-types static-entities.by-id mission-types.alpha rarities.alpha-relative-colors stats.alpha-item-stat-formulas stats.alpha-character-formulas audio.sfx-alpha-ids equipment-slots.slots equipment-slots.extra.consumable economy.currency.A economy.incomes.A economy.prices.A economy.shops.weapon-shop.stock.A economy.shops.item-shop.sells.A economy.rules.buy-back.A economy.loot.A-boss economy.loot.A-dungeon recipes.crafting-tabs-a recipes.recipe-sources.A recipes.customization.spirit-cubes-a buildings.map-visibility.A generators.world-scales.alpha generators.seed.alpha-default generators.seed.alpha-source generators.land.alpha-level generators.land.alpha-rarity generators.land.alpha-per-land generators.settlement.alpha-count generators.settlement.districts-alpha generators.settlement.inn.A generators.dungeon.alpha-layout generators.dungeon.traps-alpha generators.dungeon.boss.A generators.boss.alpha-size-scaling generators.boss.alpha-spirit-drop generators.level-formulas-alpha generators.network-alpha",
		"S":
		"block-types.steam item-types._s-additions static-entities.s-additions mission-types.steam rarities.mob-strength-tiers-s economy.currency.S economy.incomes.S economy.prices.S economy.shops.weapon-shop.stock.S economy.shops.item-shop.sells.S economy.rules.buy-back.S economy.loot.S-mission economy.loot.S-dungeon recipes.recipe-sources.S recipes.customization.fully-modded-legendary-plus-s buildings.map-visibility.S audio.ambient.S key-items.counts-per-land-s generators.world-scales.steam generators.seed.steam generators.land.steam-tiers generators.land.steam-per-land generators.settlement.steam-count generators.settlement.inn.S generators.dungeon.steam-layout generators.dungeon.boss.S generators.dungeon.artifact-s generators.dungeon.size-cap-s generators.boss.steam-loot generators.boss.coins-s generators.key-items-s",
		"X": "generators.dungeon.traps-data-x",
		"Ω": "audio.ambient.Ω generators.npc-appearance.omega generators.coarse-map-omega"
	}
	for tag in scopes:
		for path in scopes[tag].split(" ", false):
			if path == "item-types":
				path = "item-types.none"
				expect_source(o, path, [tag], "item-types", "inherited")
			else:
				expect_source(o, path, [tag], path, "inherited")
			# The equivalent unannotated fact outside the envelope gains no source.
			var value: Variant = o._source_value(path)
			o.configs["outside"] = {
				"fact": value.duplicate(true) if value is Dictionary or value is Array else value
			}
			expect_source(o, "outside.fact", [], "", "unresolved")
	for pair in [
		["block-types.alpha.0", "block-types.alpha", "A"],
		["block-types.steam.19", "block-types.steam", "S"],
		["item-types.pet-cage", "item-types", "A"],
		["static-entities.by-id.46", "static-entities.by-id", "A"],
		["equipment-slots.slots.1", "equipment-slots.slots", "A"],
		["mission-types.steam.arena", "mission-types.steam", "S"]
	]:
		expect_source(o, pair[0], [pair[2]], pair[1], "inherited")
	expect_source(o, "item-types.block", ["X"], "item-types.block", "explicit")
	expect_source(
		o, "mission-types.alpha.quests-cut", ["X"], "mission-types.alpha.quests-cut", "explicit"
	)
	expect_source(
		o,
		"buildings.buildings.watchtower",
		["Ω", "A?"],
		"buildings.buildings.watchtower",
		"explicit"
	)


func check_holds(o) -> void:
	for path in [
		"item-types",
		"block-types.alpha.flags",
		"block-types.steam.note",
		"mission-types.steam._shared",
		"mission-types.steam.region-completion-order",
		"equipment-slots.rules",
		"static-entities.behaviour",
		"static-entities.candles",
		"economy",
		"economy.currency",
		"generators",
		"generators.design",
		"buildings.settlement-styles",
		"buildings.population",
		"audio.ambient",
		"audio.tracks",
		"affixes.common",
		"creature-families.landscape-rosters",
		"creature-families.forest-dungeon-rosters"
	]:
		expect_source(o, path, [], "", "unresolved")
	for family in (
		"beetles runners slimes alpacas dogs cats golems trolls skeletons sprouts guardians fish"
		. split(" ")
	):
		expect_source(o, "creature-families." + family, [], "", "unresolved")
	var untagged := 0
	var tagged := 0
	for id in o.pet_foods:
		var food = o.pet_foods[id]
		if food.raw.has("versions"):
			tagged += 1
			check(
				food.source_tags == ["S"] and food.versions == [Model.Version.S],
				str(id) + " sourced S food unchanged"
			)
		else:
			untagged += 1
			check(
				food.versions.is_empty() and food.source_tags.is_empty(),
				str(id) + " unresolved food has no invented tags"
			)
			expect_source(o, "pet-food.foods." + str(id), [], "", "unresolved")
	check(untagged == 48 and tagged == 10, "all 48 unresolved and ten S foods distinguished")
	check(o.pet_foods["banana-mash"].subtype == 170, "Banana Mash identity retained")
	check(
		o.pet_foods["bubble-gum"].subtype == 19 and o.pet_foods["biscuit-roll"].subtype == 151,
		"numeric IDs 19/151 do not confer ancestry"
	)
	check(
		o.configs["item-types"].ingredient.subtypes["25"] == "soulflower (X)",
		"nested cut qualifier remains raw, not functional alpha availability"
	)
	check(
		"inferred" in str(o.configs["equipment-slots"].slots[1].note),
		"slot inference qualifier unchanged"
	)
	for id in o.configs["pet-food"].cut:
		expect_source(o, "pet-food.cut." + str(id), ["X"], "pet-food.cut." + str(id), "explicit")
	for pair in [
		["slash-commands.!goto <player> / !tp <loc>", ["A-mod"]],
		["ui.hud.debug-menu", ["hybrid"]],
		["ui.screens.skills", ["A", "hybrid"]],
		["ui.screens.npc-service", ["hybrid"]]
	]:
		expect_source(o, pair[0], pair[1], pair[0], "unresolved")
		check(o._source_value(pair[0]).versions == pair[1], pair[0] + " raw context unchanged")


func reject(o, path: String) -> void:
	check(not o.validate(), path + " independently fails")
	check(path in "\n".join(o.errors), path + " diagnosed")
	o.errors.append("prior load diagnostic")
	for ruleset in o.rulesets.values():
		ruleset.is_default = false
	o.configs["block-types"].alpha["0"].versions = ["Q"]
	check(not o.validate(), path + " fails cumulatively")
	var text := "\n".join(o.errors)
	for expected in [
		path,
		"prior load diagnostic",
		"block-types.alpha.0.versions",
		"exactly one ruleset must be default"
	]:
		check(expected in text, path + " retains " + expected)


func check_overrides() -> void:
	var o = fresh()
	o.configs["block-types"].alpha["0"].versions = ["A?"]
	expect_source(o, "block-types.alpha.0", ["A?"], "block-types.alpha.0", "explicit")
	expect_source(o, "block-types.alpha.0.solid", ["A?"], "block-types.alpha.0", "explicit")
	check(o.validate(), "qualified override accepted without promotion")
	o = fresh()
	o.configs["mission-types"].alpha["quests-cut"].erase("versions")
	expect_source(o, "mission-types.alpha.quests-cut", ["A"], "mission-types.alpha", "inherited")
	for tags in [
		null,
		true,
		42,
		"A",
		{},
		[],
		[null],
		[42],
		[{}],
		["Q"],
		["A", "Q"],
		["A?", "Q"],
		["A-mod"],
		["hybrid"],
		["A", "hybrid"],
		["Ω?"]
	]:
		o = fresh()
		o.races.human.raw.versions = tags
		reject(o, "human")
		o = fresh()
		o.configs["slash-commands"]["/disconnect"].versions = tags
		reject(o, "slash-commands./disconnect.versions")
		o = fresh()
		o.configs.ui.screens.inventory.versions = tags
		reject(o, "ui.screens.inventory.versions")
		o = fresh()
		o.configs["block-types"].alpha["0"].versions = tags
		expect_source(o, "block-types.alpha.0", [], "block-types.alpha.0", "invalid")
		reject(o, "block-types.alpha.0.versions")
	o = fresh()
	o.races.human.raw.erase("versions")
	reject(o, "human")
	o = fresh()
	o.configs["item-types"].none.v = ["S?"]
	expect_source(o, "item-types.none", ["S?"], "item-types.none", "explicit")
	check(o.validate(), "v alias preserves qualification")
	o.configs["item-types"].none.v = ["A", null]
	reject(o, "item-types.none.v")


func check_nested_annotations() -> void:
	var o = fresh()
	o.configs["item-types"].none["nested"] = [{"v": ["A?"], "value": 1}]
	expect_source(
		o, "item-types.none.nested.0.value", ["A?"], "item-types.none.nested.0", "explicit"
	)
	check(o.validate(), "nested array override validates")
	o.configs["item-types"].none.nested[0].v = ["A", "Q"]
	expect_source(o, "item-types.none.nested.0.value", [], "item-types.none.nested.0", "invalid")
	reject(o, "item-types.none.nested.0.v")
	o = fresh()
	o.configs["item-types"]["_s-additions"]["nested"] = [{"versions": ["Q"]}]
	reject(o, "item-types._s-additions.nested.0.versions")
	o = fresh()
	o.configs.creatures.collie["nested"] = {"records": [{"versions": [null]}]}
	reject(o, "creatures.collie.nested.records.0.versions")
	o = fresh()
	o.configs.ui.screens.skills["nested"] = [{"versions": ["Q"]}]
	reject(o, "ui.screens.skills.nested.0.versions")


func check_raw_loading() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		check(false, "PIXLND_TEST_DIR must be an existing isolated absolute directory")
		return
	var scratch := directory.path_join("provenance")
	check(DirAccess.make_dir_recursive_absolute(scratch) == OK, "scratch created")
	for file in DirAccess.open("res://ontology/instances").get_files():
		if file.ends_with(".json"):
			check(
				(
					DirAccess.copy_absolute(
						ProjectSettings.globalize_path("res://ontology/instances/" + file),
						scratch.path_join(file)
					)
					== OK
				),
				"copied " + file
			)
	var path := scratch.path_join("races.json")
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for tags in [
		["A?"],
		["S?"],
		["A?", "S"],
		["A", "S", "X", "Ω"],
		null,
		"A",
		["A", "Q"],
		[null],
		[42],
		[{}],
		["A-mod"],
		["hybrid"]
	]:
		var raw := original.duplicate(true)
		raw.human.versions = tags
		raw.elf["nested"] = [{"versions": ["A?"]}]
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(raw))
		file.close()
		var o = Model.Ontology.load_dir(scratch)
		if (
			tags is Array
			and not tags.is_empty()
			and tags[0] in ["A?", "S?", "A"]
			and not "Q" in tags
		):
			check(o.validate(), "valid annotation loaded " + str(tags))
			o.configs.races.elf.nested[0].versions = ["Q"]
			reject(o, "races.elf.nested.0.versions")
			check(o.races.human.source_tags == tags, "loaded exact tags " + str(tags))
			check(
				o.races.human.versions == Model.Entry.parse_versions(tags),
				"loaded only confirmed enums"
			)
		else:
			reject(o, "races.human.versions")
	for tags in [["A?"], ["A", "Q"], null]:
		var raw := original.duplicate(true)
		raw.elf["nested"] = [{"v": tags}]
		var nested_file := FileAccess.open(path, FileAccess.WRITE)
		nested_file.store_string(JSON.stringify(raw))
		nested_file.close()
		var nested = Model.Ontology.load_dir(scratch)
		if tags == ["A?"]:
			check(nested.validate(), "raw nested qualified override accepted")
		else:
			reject(nested, "races.elf.nested.0.v")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(original))
	file.close()
	check(Model.Ontology.load_dir(scratch).validate(), "restored scratch validates")


func check_context_annotations() -> void:
	var contexts := {
		"slash-commands.!goto <player> / !tp <loc>": ["A-mod"],
		"ui.hud.debug-menu": ["hybrid"],
		"ui.screens.skills": ["A", "hybrid"],
		"ui.screens.npc-service": ["hybrid"]
	}
	for path in contexts:
		var o = fresh()
		for field in ["versions", "v"]:
			for bad in [null, true, 42, "A", {}, [], ["Q"], ["A", "Q"], [42]]:
				o = fresh()
				o._source_value(path)[field] = bad
				if field == "versions":
					o._source_value(path).v = ["A"]
				expect_source(o, path, [], path, "invalid")
				reject(o, path + "." + field)
		o = fresh()
		o._source_value(path).v = contexts[path]
		expect_source(o, path, [], path, "invalid")
		reject(o, path + ".v")
		for tags in [["A"], ["S?"], ["A?", "S"]]:
			o = fresh()
			o._source_value(path).versions = tags
			expect_source(o, path, tags, path, "explicit")
			check(o.validate(), path + " strict replacement validates")
			o = fresh()
			o._source_value(path).v = tags
			expect_source(o, path, contexts[path], path, "unresolved")
			check(o.validate(), path + " original context with strict alias validates")
	check_context_loading(contexts)


func check_context_loading(contexts: Dictionary) -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		check(false, "context ingestion needs isolated PIXLND_TEST_DIR")
		return
	var scratch := directory.path_join("context-provenance")
	check(DirAccess.make_dir_recursive_absolute(scratch) == OK, "context scratch created")
	for file in DirAccess.open("res://ontology/instances").get_files():
		if file.ends_with(".json"):
			check(
				(
					DirAccess.copy_absolute(
						ProjectSettings.globalize_path("res://ontology/instances/" + file),
						scratch.path_join(file)
					)
					== OK
				),
				"context copied " + file
			)
	for path in contexts:
		var parts: PackedStringArray = str(path).split(".")
		var file_path := scratch.path_join(parts[0] + ".json")
		var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file_path))
		for field in ["versions", "v"]:
			for tags in (
				[null, true, 42, "A", {}, [], ["Q"], ["A", "Q"], [42], ["A?", "S"]]
				+ ([contexts[path]] if field == "v" else [])
			):
				var raw := original.duplicate(true)
				var row: Dictionary = raw
				for i in range(1, parts.size()):
					row = row[parts[i]]
				row[field] = tags
				if field == "versions":
					row.v = ["A"]
				var file := FileAccess.open(file_path, FileAccess.WRITE)
				file.store_string(JSON.stringify(raw))
				file.close()
				var o = Model.Ontology.load_dir(scratch)
				if tags is Array and tags == ["A?", "S"]:
					check(o.validate(), path + " raw strict " + field + " validates")
					expect_source(
						o,
						path,
						tags if field == "versions" else contexts[path],
						path,
						"explicit" if field == "versions" else "unresolved"
					)
				else:
					expect_source(o, path, [], path, "invalid")
					reject(o, path + "." + field)
		var file := FileAccess.open(file_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(original))
		file.close()
		var restored = Model.Ontology.load_dir(scratch)
		check(restored.validate(), path + " original context raw control validates")
		expect_source(restored, path, contexts[path], path, "unresolved")
