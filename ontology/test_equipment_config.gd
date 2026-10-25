extends SceneTree

const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Inventory := preload("res://game/items/inventory.gd")

var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	var o := Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "canonical equipment data validates")
	var slots: Array = o.configs["equipment-slots"]["slots"]
	var by_id := {}
	for slot in slots:
		by_id[slot["id"]] = slot
	check(by_id["main-hand"]["accepts"] == ["weapon"], "main-hand accepts weapon type")
	check(by_id["off-hand"]["accepts"] == ["weapon"], "off-hand accepts weapon type")
	check(
		by_id["lamp"]["accepts"] == ["light"] and by_id["lamp"]["accepts-subtypes"] == ["lamp"],
		"lamp enforces light/lamp"
	)
	check(
		(
			by_id["special"]["accepts"] == ["special"]
			and by_id["special"]["accepts-subtypes"] == ["hang-glider", "boat"]
		),
		"special enforces hang-glider/boat"
	)
	check(
		(
			by_id["pet"]["accepts"] == ["pet-cage", "pet-food"]
			and by_id["pet"]["accepts-conditions"]["pet-food"] == "during-taming"
		),
		"pet-food retains during-taming condition"
	)
	check(by_id["unknown-0"]["accepts"] == [], "reserved slot accepts nothing")
	var wand: Dictionary = o.weapon_types[&"wand"].raw
	check(
		str(wand["hands"]).begins_with("2h") and int(wand["cube-capacity"]) == 32,
		"Wand is mechanically two-handed with 32 cubes"
	)
	var wand_recipe: Dictionary = o.configs["recipes"]["gear-weapons"]["wand"]
	check(
		wand_recipe["inputs"]["wood-cube"] == 20 and wand_recipe["station"] == "workbench",
		"common Wand recipe costs 20 wood cubes"
	)

	# Each malformed fixture must fail closed while retaining all diagnostics.
	var saved_accepts: Array = by_id["lamp"]["accepts"]
	by_id["lamp"]["accepts"] = ["not-an-item-type"]
	wand["hands"] = "1h"
	wand_recipe["inputs"]["wood-cube"] = 10
	o.errors.clear()
	check(
		not o.validate() and o.errors.size() >= 3,
		"slot, Wand and recipe drift accumulate diagnostics"
	)
	by_id["lamp"]["accepts"] = saved_accepts
	wand["hands"] = "2h"
	wand["hands"] = null
	o.errors.clear()
	check(
		not o.validate() and not o.errors.is_empty(),
		"malformed Wand hands rejected without script error"
	)
	wand["hands"] = "2h"
	wand_recipe["inputs"]["wood-cube"] = 20
	o.errors.clear()
	var saved_subtypes: Array = by_id["special"].get("accepts-subtypes")
	by_id["special"].erase("accepts-subtypes")
	check(not o.validate() and o.errors.size() >= 1, "missing subtype restrictions fail closed")
	by_id["special"]["accepts-subtypes"] = saved_subtypes
	var original_index: Variant = by_id["amulet"]["index"]
	by_id["amulet"]["index"] = 0
	by_id["unknown-0"]["index"] = 1
	o.errors.clear()
	check(
		not o.validate() and o.errors.size() >= 2,
		"swapped reserved/amulet indices fail exact identity"
	)
	by_id["unknown-0"]["index"] = 0
	for invalid in ["1", 1.5, null]:
		by_id["amulet"]["index"] = invalid
		o.errors.clear()
		check(
			not o.validate() and not o.errors.is_empty(),
			"malformed slot index rejected: %s" % str(invalid)
		)
	by_id["amulet"]["index"] = original_index
	var saved_slots: Variant = o.configs["equipment-slots"]["slots"]
	for invalid in [null, 42, {}]:
		o.configs["equipment-slots"]["slots"] = invalid
		o.errors.clear()
		check(
			not o.validate() and not o.errors.is_empty(),
			"malformed slot parent rejected: %s" % str(invalid)
		)
	o.configs["equipment-slots"]["slots"] = saved_slots
	var saved_slot_cfg: Variant = o.configs["equipment-slots"]
	o.configs.erase("equipment-slots")
	o.errors.clear()
	check(not o.validate() and not o.errors.is_empty(), "missing whole equipment-slots rejected")
	o.configs["equipment-slots"] = saved_slot_cfg
	var saved_recipes: Variant = o.configs["recipes"]
	for invalid in [null, 42, []]:
		o.configs["recipes"] = invalid
		o.errors.clear()
		check(
			not o.validate() and not o.errors.is_empty(),
			"malformed recipes parent rejected: %s" % str(invalid)
		)
	o.configs.erase("recipes")
	o.errors.clear()
	check(not o.validate() and not o.errors.is_empty(), "missing whole recipes rejected")
	o.configs["recipes"] = saved_recipes
	var saved_weapons: Variant = saved_recipes["gear-weapons"]
	for invalid in [null, 42, []]:
		saved_recipes["gear-weapons"] = invalid
		o.errors.clear()
		check(
			not o.validate() and not o.errors.is_empty(),
			"malformed gear-weapons parent rejected: %s" % str(invalid)
		)
	saved_recipes.erase("gear-weapons")
	o.errors.clear()
	check(not o.validate() and not o.errors.is_empty(), "missing gear-weapons parent rejected")
	saved_recipes["gear-weapons"] = saved_weapons
	o.configs.erase("equipment-slots")
	o.configs.erase("recipes")
	o.errors.clear()
	check(
		not o.validate() and o.errors.size() >= 2, "missing selected parents accumulate diagnostics"
	)
	o.configs["equipment-slots"] = saved_slot_cfg
	o.configs["recipes"] = saved_recipes
	wand_recipe["inputs"] = null
	o.errors.clear()
	check(not o.validate() and o.errors.size() >= 1, "malformed recipe inputs fail closed")
	wand_recipe["inputs"] = {"wood-cube": 20}
	o.errors.clear()
	check(o.validate(), "restored equipment data validates")

	# Exercise load_dir's raw JSON boundary, not only typed Resource mutations.
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path():
		printerr("PIXLND_TEST_DIR required")
		quit(1)
		return
	var scratch := directory.path_join("equipment-config-negative")
	check(
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scratch)) == OK,
		"scratch directory created"
	)
	var source := DirAccess.open("res://ontology/instances")
	for file in source.get_files():
		if file.ends_with(".json"):
			check(
				(
					DirAccess.copy_absolute(
						ProjectSettings.globalize_path("res://ontology/instances/" + file),
						ProjectSettings.globalize_path(scratch + "/" + file)
					)
					== OK
				),
				"copied " + file
			)
	var weapon_path := scratch + "/weapon-types.json"
	var original_weapons := FileAccess.get_file_as_string(weapon_path)
	var raw_weapons: Dictionary = JSON.parse_string(original_weapons)
	var types_path := scratch + "/item-types.json"
	var original_types := FileAccess.get_file_as_string(types_path)
	for invalid in [null, 42, []]:
		var writer := FileAccess.open(types_path, FileAccess.WRITE)
		writer.store_string(JSON.stringify(invalid))
		writer.close()
		var loaded = Model.Ontology.load_dir(scratch)
		loaded.configs["recipes"]["gear-weapons"] = null
		check(not loaded.validate(), "malformed raw item-types rejected")
		check(
			(
				"item-types: required object missing or malformed" in "\n".join(loaded.errors)
				and "design.loot/stack-cap" in "\n".join(loaded.errors)
				and "recipes.gear-weapons" in "\n".join(loaded.errors)
			),
			"item-types, loot and independent recipe diagnostics accumulate"
		)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(types_path))
	var missing_types = Model.Ontology.load_dir(scratch)
	check(
		(
			not missing_types.validate()
			and (
				"item-types: required object missing or malformed"
				in "\n".join(missing_types.errors)
			)
		),
		"missing raw item-types rejected"
	)
	var writer := FileAccess.open(types_path, FileAccess.WRITE)
	writer.store_string(original_types)
	writer.close()
	var numeric_weapons: Dictionary = raw_weapons.duplicate(true)
	numeric_weapons["wand"]["cube-capacity"] = 32.0
	writer = FileAccess.open(weapon_path, FileAccess.WRITE)
	writer.store_string(JSON.stringify(numeric_weapons))
	writer.close()
	check(
		Model.Ontology.load_dir(scratch).validate(),
		"integral JSON numeric float capacity remains valid"
	)
	var supported := {
		"sword": Model.Hands.ONE_HANDED,
		"wand": Model.Hands.TWO_HANDED,
		"shield": Model.Hands.OFFHAND,
		"bracelet": Model.Hands.ONE_HANDED
	}
	var supported_load = Model.Ontology.load_dir(scratch)
	check(supported_load.validate(), "raw supported hands validate")
	for id in supported:
		check(
			supported_load.weapon_types[StringName(id)].hands == supported[id],
			"raw supported hands parse: %s" % id
		)
	for invalid in [
		{"id": "sword", "hands": "1h invalid"},
		{"id": "wand", "hands": "2h invalid"},
		{"id": "sword", "hands": null},
		{"id": "sword", "hands": 42},
		{"id": "sword", "hands": []},
		{"id": "sword"}
	]:
		var raw: Dictionary = raw_weapons.duplicate(true)
		if invalid.has("hands"):
			raw[invalid["id"]]["hands"] = invalid["hands"]
		else:
			raw[invalid["id"]].erase("hands")
		writer = FileAccess.open(weapon_path, FileAccess.WRITE)
		writer.store_string(JSON.stringify(raw))
		writer.close()
		var loaded = Model.Ontology.load_dir(scratch)
		check(
			(
				not loaded.validate()
				and "weapon %s: hands" % invalid["id"] in "\n".join(loaded.errors)
			),
			"raw invalid hands rejected: %s" % str(invalid)
		)
		check(
			loaded.weapon_types[StringName(invalid["id"])].hands == Model.Hands.NONE,
			"raw invalid hands not trusted: %s" % str(invalid)
		)
	writer = FileAccess.open(weapon_path, FileAccess.WRITE)
	writer.store_string(original_weapons)
	writer.close()
	for capacity in ["32", null, true, [], 16, 32.5]:
		var raw: Dictionary = raw_weapons.duplicate(true)
		raw["wand"]["cube-capacity"] = capacity
		writer = FileAccess.open(weapon_path, FileAccess.WRITE)
		writer.store_string(JSON.stringify(raw))
		writer.close()
		var loaded = Model.Ontology.load_dir(scratch)
		check(
			not loaded.validate() and "weapon wand: capacity" in "\n".join(loaded.errors),
			"raw invalid Wand capacity rejected: %s" % str(capacity)
		)
	for invalid_owner in [null, "", 42, [], "warrior", "unknown"]:
		var raw: Dictionary = raw_weapons.duplicate(true)
		raw["wand"]["class"] = invalid_owner
		writer = FileAccess.open(weapon_path, FileAccess.WRITE)
		writer.store_string(JSON.stringify(raw))
		writer.close()
		var loaded = Model.Ontology.load_dir(scratch)
		check(
			not loaded.validate() and "weapon wand: " in "\n".join(loaded.errors),
			"raw invalid Wand owner rejected: %s" % str(invalid_owner)
		)
	var raw: Dictionary = raw_weapons.duplicate(true)
	raw["wand"].erase("class")
	writer = FileAccess.open(weapon_path, FileAccess.WRITE)
	writer.store_string(JSON.stringify(raw))
	writer.close()
	var missing_owner = Model.Ontology.load_dir(scratch)
	check(
		not missing_owner.validate() and "weapon wand: " in "\n".join(missing_owner.errors),
		"missing raw Wand owner rejected"
	)
	missing_owner.weapon_types[&"wand"].raw["cube-capacity"] = "32"
	missing_owner.errors.clear()
	check(
		(
			not missing_owner.validate()
			and "weapon wand: capacity" in "\n".join(missing_owner.errors)
			and "class mage: weapon-type wand" in "\n".join(missing_owner.errors)
		),
		"missing owner and malformed capacity accumulate"
	)
	var inv = Inventory.new(
		missing_owner, missing_owner.configs["generators"]["design"], &"warrior"
	)
	var wand_item = Items.generate(RandomNumberGenerator.new(), &"weapon", &"wand", &"wood", 1, 0)
	inv.add(wand_item)
	check(
		not inv.class_allowed(wand_item) and not inv.equip(wand_item) and wand_item in inv.entries,
		"missing Wand owner cannot grant Warrior eligibility"
	)
	var mismatched = Model.Ontology.load_dir("res://ontology/instances")
	mismatched.classes[&"mage"].weapon_types.erase(&"wand")
	check(
		(
			not mismatched.validate()
			and "weapon wand: class mage does not list weapon" in "\n".join(mismatched.errors)
		),
		"ownership is checked from weapon to class"
	)
	for capacity in [INF, NAN]:
		var nonfinite = Model.Ontology.load_dir("res://ontology/instances")
		nonfinite.weapon_types[&"wand"].raw["cube-capacity"] = capacity
		check(
			not nonfinite.validate() and "weapon wand: capacity" in "\n".join(nonfinite.errors),
			"nonfinite active weapon capacity rejected"
		)
	var no_owner = Model.Ontology.load_dir("res://ontology/instances")
	no_owner.weapon_types[&"wand"].raw.erase("class")
	check(
		(
			not no_owner.validate()
			and "class mage: weapon-type wand must belong to class" in "\n".join(no_owner.errors)
		),
		"ownership is checked from class to weapon"
	)
	for file in source.get_files():
		if file.ends_with(".json"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch + "/" + file))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	print("equipment config ok" if failed == 0 else "equipment config FAILED (%d)" % failed)
	quit(0 if failed == 0 else 1)
