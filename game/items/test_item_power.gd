extends SceneTree
# Source-level producers and powered import boundaries; literal expectations are independent
# of power_for_level() and of the producers replayed by save validation.
const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Rewards := preload("res://game/items/encounter_rewards.gd")
const Shop := preload("res://game/items/shop.gd")
const Save := preload("res://game/world/save_data.gd")
const World := preload("res://game/world/world.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
const EncounterGen := preload("res://game/world/encounter_gen.gd")
var failed := 0
var passed := 0
var fingerprints := {}


class LevelTrace:
	extends RefCounted
	var base
	var world_seed: int
	var levels: Array = []

	func _init(generator):
		base = generator
		world_seed = generator.world_seed

	func creature_level(land, lo: int, hi: int, rng: RandomNumberGenerator) -> int:
		var value: int = base.creature_level(land, lo, hi, rng)
		levels.append(value)
		return value


func check(ok: bool, label: String, actual: Variant = null) -> void:
	print("PASS " if ok else "FAIL ", label, " actual=", JSON.stringify(actual))
	if ok:
		passed += 1
	else:
		failed += 1


func nonpower(payload: Array) -> Array:
	return payload.map(
		func(it):
			var row := Save.item_data(it)
			row.erase("level")
			if row.type == "coin":
				row.erase("count")
			return row
	)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var scratch := OS.get_environment("PIXLND_TEST_DIR")
	if not scratch.is_absolute_path() or not DirAccess.dir_exists_absolute(scratch):
		printerr("INFRA: existing isolated absolute PIXLND_TEST_DIR required")
		quit(2)
		return
	var o := Model.Ontology.load_dir("res://ontology/instances")
	if not o.validate() or not o.errors.is_empty():
		printerr("INFRA: ontology validation failed ", o.errors)
		quit(2)
		return
	var d: Dictionary = o.configs.generators.design
	var save := Save.new(o, d)
	var rng := RandomNumberGenerator.new()
	for pair in [[0, 1], [1, 1], [32, 32], [100, 100], [101, 100]]:
		rng.seed = 42
		var gear = Items.generate(rng, &"weapon", &"sword", &"iron", pair[0], 0)
		check(gear.level == pair[1], "powered constructor %d -> %d" % pair, gear.level)
	for kind in [
		"weapon",
		"chest-armor",
		"gloves",
		"boots",
		"shoulder-armor",
		"ring",
		"amulet",
		"consumable",
		"spirit"
	]:
		for power in [0, 1, 100, 101]:
			var it = Items.generate(rng, &"weapon", &"sword", &"iron", 1, 0)
			if kind not in ["weapon", "consumable", "spirit"]:
				it = Items.generate(rng, StringName(kind), &"", &"iron", 1, 0)
			if kind == "consumable":
				it = Item.stack(&"consumable", &"life-potion", 1)
			elif kind == "spirit":
				it = Item.stack(&"ingredient", &"spirit-fire", 1)
			it.level = power  # serialized boundary: do not let the constructor sanitize it
			save.errors.clear()
			var accepted := save.validate_item(Save.item_data(it), "test.item")
			check(
				accepted == (power in [1, 100]),
				"import %s power%d" % [kind, power],
				{"accepted": accepted, "errors": save.errors.duplicate()}
			)
	for anchor in [
		[1, [1, 2]], [10, [31, 32, 33]], [100, [83, 84, 85]], [200, [90, 91, 92]], [1981, [99, 100]]
	]:
		var gear_powers := {}
		var consumable_powers := {}
		var coins := {}
		for seed_value in range(128):
			rng.seed = seed_value
			var payload := Items.roll_loot(rng, anchor[0], null, o, d)
			for it in payload:
				if it.type == &"coin":
					coins[it.count] = true
				elif it.type == &"consumable":
					consumable_powers[it.level] = true
				else:
					gear_powers[it.level] = true
		var gp := gear_powers.keys()
		var cp := consumable_powers.keys()
		gp.sort()
		cp.sort()
		check(gp == anchor[1], "ordinary L%d gear powers" % anchor[0], gp)
		check(cp == anchor[1], "ordinary L%d consumable powers" % anchor[0], cp)
		if anchor[0] == 10:
			check(coins.keys() == [21], "L10 coin source units unchanged", coins.keys())
	# Unit conversion must not consume randomness or alter any nonpower field.
	for seed_value in range(32):
		rng.seed = seed_value
		var low := Items.roll_loot(rng, 10, o.creatures[&"skeleton"], o, d)
		var state_after := rng.state
		rng.seed = seed_value
		var high := Items.roll_loot(rng, 200, o.creatures[&"skeleton"], o, d)
		check(
			rng.state == state_after and nonpower(low) == nonpower(high),
			"ordinary RNG/nonpower seed%d" % seed_value
		)
		fingerprints["ordinary/%d" % seed_value] = {
			"rng_state": str(state_after), "nonpower": nonpower(low)
		}
	var gen := WorldGen.new(8158, d, o.landscapes)
	var land = gen.land_at(Vector2i.ZERO)
	var layout := EncounterGen.make_site(
		gen, land, Vector2i.ZERO, 0, "ruins", 0, d["initial-encounters"]
	)
	var stable: Dictionary = layout.assignments.filter(func(a): return a.boss and a.spirit != "")[0]
	var kill := Rewards.kill_payload(stable, 0, 10, 3, o, d)
	check(kill[-2].level == 32, "current boss L10 guaranteed gear32", kill[-2].level)
	check(kill[-1].level == 10, "initial boss L3 spirit10", kill[-1].level)
	check(
		str(kill[-1].subtype) == str(stable.spirit) and kill[-1].count == 1,
		"stable spirit type/count",
		Save.item_data(kill[-1])
	)
	fingerprints.boss = nonpower(kill)
	var high_boss := Rewards.kill_payload(stable, 1, 1981, 200, o, d)
	check(
		high_boss[-2].level == 100 and high_boss[-1].level == 91,
		"high current/initial boss sources remain distinct",
		[high_boss[-2].level, high_boss[-1].level]
	)
	for anchor in [[1, 1], [10, 32], [100, 84], [200, 91], [1981, 100]]:
		var package := Rewards.package_payload("proof/mission", 2, anchor[0], &"warrior", o, d)
		check(
			package[0].level == anchor[1] and package[2].level == anchor[1],
			"mission L%d gear/potion power%d" % anchor,
			[package[0].level, package[2].level]
		)
		check(
			(
				package[1].count == 60
				and package[2].count == 1
				and package[3].count == 3
				and package[3].subtype == &"ruby"
			),
			"mission unchanged coin/potion/gems",
			package.map(Save.item_data)
		)
		fingerprints["package/%d" % anchor[0]] = nonpower(package)
	var trace := LevelTrace.new(gen)
	var stock := Shop.stock(&"weapon-vendor", trace, land, {"centre": [0, 0]}, 10, o, d)
	check(
		trace.levels == [11, 10, 11, 11, 10, 10, 11, 11],
		"real WorldGen.creature_level sources (not player10)",
		trace.levels
	)
	var powers := stock.map(func(it): return it.level)
	check(
		powers == [33, 33, 35, 34, 33, 31, 34, 34],
		"actual rolled source conversion before vendor spread",
		powers
	)
	fingerprints.vendor_weapon = nonpower(stock)
	var armor_trace := LevelTrace.new(gen)
	var armor := Shop.stock(&"armor-vendor", armor_trace, land, {"centre": [0, 0]}, 10, o, d)
	check(
		armor_trace.levels == [11, 11, 11, 11, 11, 11, 12, 12],
		"real armor vendor sources",
		armor_trace.levels
	)
	check(
		armor.map(func(it): return it.level) == [34, 33, 33, 33, 34, 34, 36, 37],
		"armor vendor actual sources powered before spread",
		armor.map(func(it): return it.level)
	)
	fingerprints.vendor_armor = nonpower(armor)
	var consumables := Shop.stock(&"item-vendor", gen, land, {"centre": [0, 0]}, 10, o, d)
	check(
		consumables.map(func(it): return it.level) == [32, 32, 32],
		"item vendor player10 -> consumables32",
		consumables.map(Save.item_data)
	)
	for role in Shop.VENDORS:
		var high_stock := Shop.stock(role, gen, land, {"centre": [0, 0]}, 1981, o, d)
		check(
			high_stock.all(func(it): return it.level >= 99 and it.level <= 100),
			"high vendor source bounded " + str(role)
		)
	var ordinary_ingredient = Item.stack(&"ingredient", &"wood-cube", 1, 1981)
	save.errors.clear()
	check(
		save.validate_item(Save.item_data(ordinary_ingredient), "test.item"),
		"nonpower ingredient is not source-converted or capped",
		save.errors.duplicate()
	)
	var world := World.new()
	world.design = d
	var tables := {
		"cycle": 0,
		"room_levels": [10, 1981, 1],
		"rewards": {},
		"contents": EncounterGen.fresh_contents(layout, d["initial-encounters"])
	}
	world.stage_tables(tables, layout, 0)
	var prop_plan := EncounterGen.content_plan(layout, d["initial-encounters"])
	for key in tables.rewards:
		var receipt: Dictionary = tables.rewards[key]
		var prop_key := "/".join(str(key).split("/").slice(2))
		var room: int = prop_plan.props[prop_key].room
		check(
			receipt.level == [10, 1981, 1][room] and receipt.payload[1].level == [32, 100, 1][room],
			"room table source stays level / potion powered " + key,
			receipt
		)
	save.errors.clear()
	save.validate_features(tables, layout, 0.0)
	check(
		save.errors.is_empty(),
		"produced table receipts replay under current rules",
		save.errors.duplicate()
	)
	# Independently replace only item powers, never source records, RNG or geometry.
	for key in tables.rewards:
		var prop_key := "/".join(str(key).split("/").slice(2))
		tables.rewards[key].payload[1].level = [32, 100, 1][prop_plan.props[prop_key].room]
	save.errors.clear()
	save.validate_features(tables, layout, 0.0)
	check(
		save.errors.is_empty(),
		"canonical power table receipt accepted by real validator",
		save.errors.duplicate()
	)
	for key in tables.rewards:
		var bad: Dictionary = tables.duplicate(true)
		bad.rewards[key].payload[1].level = bad.rewards[key].level
		if bad.rewards[key].level == 1:
			continue
		save.errors.clear()
		save.validate_features(bad, layout, 0.0)
		check(not save.errors.is_empty(), "old source-unit table receipt rejected " + key)
	world.free()
	var key := "kill/0/" + str(stable.key)
	var site_id := "proof/site/0,0/ruins/0"
	var site := {
		"id": site_id,
		"cycle": 1,
		"family": "ruins",
		"cleared": false,
		"spirit_levels": {stable.key: 3},
		"mobs": {site_id + "/" + str(stable.key): {"cycle": 1, "dead": false, "level": 20}},
		"rewards":
		{
			key:
			{
				"level": 10,
				"delivered": true,
				"position": [0, 0, 0],
				"payload": kill.map(Save.item_data)
			}
		}
	}
	var reward_layout := {"family": "ruins", "assignments": [stable]}
	save.errors.clear()
	save.validate_rewards(site, reward_layout)
	check(
		save.errors.is_empty(),
		"produced delivered historical kill replays",
		save.errors.duplicate()
	)
	# Guaranteed tail is independently 32/10; ordinary prefix rolls stay untouched.
	site.rewards[key].payload[-2].level = 32
	site.rewards[key].payload[-1].level = 10
	save.errors.clear()
	save.validate_rewards(site, reward_layout)
	check(
		save.errors.is_empty(),
		"canonical guaranteed boss/spirit receipt accepted",
		save.errors.duplicate()
	)
	var old_kill: Dictionary = site.duplicate(true)
	old_kill.rewards[key].payload[-2].level = 10
	old_kill.rewards[key].payload[-1].level = 3
	save.errors.clear()
	save.validate_rewards(old_kill, reward_layout)
	check(not save.errors.is_empty(), "old-unit delivered historical boss/spirit receipt rejected")
	check(
		(
			site.rewards[key].level == 10
			and site.spirit_levels[stable.key] == 3
			and site.mobs.values()[0].level == 20
		),
		"receipt/current/initial source records unchanged"
	)
	var f := FileAccess.open(scratch.path_join("nonpower-baseline.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(fingerprints, "\t"))
	f.close()
	print("RESULT passed=", passed, " failed=", failed)
	quit(0 if failed == 0 else 1)
