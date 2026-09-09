## Headless check of §3.4 (D18): `godot --headless -s game/items/test_items.gd`.
## gen-item determinism + roll, gen-item-stats, names, slots, stack rule, gen-loot rates, c-loot-config,
## then a floor with a player and a wolf: starting inventory, kill → ground items → pick-up → quick item.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Inventory := preload("res://game/items/inventory.gd")
const Spawner := preload("res://game/world/spawner.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")

var _failed := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _init() -> void:
	var o := Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	var design: Dictionary = o.configs["generators"]["design"]
	var loot: Dictionary = design["loot"]
	# gen-item: same seed = same item; roll ∈ 0..20 (c-stat-roll); rarity clamped (c-rarity-range)
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	var a := Items.generate(rng, &"weapon", &"sword", &"iron", 3, 2)
	rng.seed = 7
	var b := Items.generate(rng, &"weapon", &"sword", &"iron", 3, 2)
	check(a.modifier == b.modifier and Items.item_name(a, o, design) == Items.item_name(b, o, design), "gen-item is seed-deterministic")
	var rolls := {}
	for i in 400:
		var r := Items.generate(rng, &"weapon", &"sword", &"iron", 1, 0).roll()
		check(r >= 0 and r <= 20, "roll in 0..20: %d" % r); rolls[r] = true
	check(rolls.size() >= 15, "rolls spread over the range (%d distinct)" % rolls.size())
	check(Items.generate(rng, &"weapon", &"sword", &"iron", 1, 9).rarity == Model.Rarity.LEGENDARY, "rarity clamped to legendary")
	# gen-item-stats: level-1 common sword damage 4 (× attack-power 10 = the boot line's 40); monotone
	var s1 := Items.generate(rng, &"weapon", &"sword", &"iron", 1, 0)
	check(is_equal_approx(Items.damage(s1, o), 4.0), "sword +1 common damage 4: %.2f" % Items.damage(s1, o))
	var s5 := Items.generate(rng, &"weapon", &"sword", &"iron", 5, 0); var s5r := Items.generate(rng, &"weapon", &"sword", &"iron", 5, 3)
	check(Items.damage(s5, o) > Items.damage(s1, o) and Items.damage(s5r, o) > Items.damage(s5, o), "damage monotone in level and rarity")
	check(is_equal_approx(Items.damage(Items.generate(rng, &"weapon", &"greatsword", &"iron", 1, 0), o), 8.0), "2h k = 8")
	var chest := Items.generate(rng, &"chest-armor", &"", &"iron", 1, 0)
	var gloves := Items.generate(rng, &"gloves", &"", &"linen", 1, 0)
	check(is_equal_approx(Items.armor(chest, o), 1.0), "iron chest +1 armor 1.0: %.2f" % Items.armor(chest, o))
	check(is_equal_approx(Items.armor(gloves, o), 0.5 * 0.85), "linen gloves armor 0.425: %.3f" % Items.armor(gloves, o))
	check(is_equal_approx(Items.armor(s1, o), 0.0) and is_equal_approx(Items.damage(chest, o), 0.0), "weapons have no armor, armor no damage")
	# gen-name: rarity prefix list; epic/legendary carry "of <Name>"
	var n1 := Items.item_name(s1, o, design)
	check(n1.split(" ")[0] in o.configs["affixes"]["common"] and n1.ends_with("Iron Sword"), "common name '<prefix> Iron Sword': %s" % n1)
	var leg := Items.generate(rng, &"weapon", &"sword", &"iron", 1, 4)
	check(" of " in Items.item_name(leg, o, design), "legendary is named: %s" % Items.item_name(leg, o, design))
	check(Items.item_name(Item.stack(&"consumable", &"life-potion", 2), o, design) == "Life Potion", "consumable name")
	check(Items.item_name(Item.stack(&"coin", &"", 7), o, design) == "7 copper", "coin name")
	# equips-in / c-slot-accepts
	check(Items.slot_id(s1, o) == &"main-hand" and Items.slot_id(Items.generate(rng, &"weapon", &"shield", &"iron", 1, 0), o) == &"off-hand", "weapon slots by hands")
	check(Items.slot_id(chest, o) == &"chest" and Items.slot_id(gloves, o) == &"gloves" and Items.slot_id(Item.stack(&"consumable", &"apple", 1), o) == &"", "armor slots; consumables have none")
	# inventory: c-stack-rule, equip/swap, coins
	var inv := Inventory.new(o, design)
	inv.add(Item.stack(&"consumable", &"life-potion", 2)); inv.add(Item.stack(&"consumable", &"life-potion", 3))
	check(inv.entries.size() == 1 and inv.entries[0].count == 5, "potions stack: %d entries" % inv.entries.size())
	inv.add(s1); inv.add(s5)
	check(inv.entries.size() == 3, "gear never stacks")
	check(inv.equip(s1) and inv.equipment[&"main-hand"] == s1 and inv.entries.size() == 2, "equip moves to the slot")
	check(inv.equip(s5) and inv.equipment[&"main-hand"] == s5 and s1 in inv.entries, "equip swaps the old one back")
	check(not inv.equip(inv.first_consumable()), "consumables cannot be equipped")
	inv.add(Item.stack(&"coin", &"", 12)); inv.add(Item.stack(&"coin", &"", 3))
	check(inv.coins == 15 and inv.entries.size() == 2, "coins are a counter, not an entry")
	# gen-loot rates over many kills (D18 numbers ± 3 %)
	rng.seed = 99
	var kills := 4000; var coins := 0; var gear := 0; var cons := 0; var feathers := 0; var bad := 0
	var parrot: Model.Creature = o.creatures["parrot"]
	for i in kills:
		for it in Items.roll_loot(rng, 5, parrot, o, design):
			match it.type:
				&"coin": coins += 1; bad += 1 if it.count != 1 + 2 * 5 else 0
				&"consumable": cons += 1
				&"ingredient": feathers += 1
				_:
					gear += 1
					bad += 1 if it.rarity > Model.Rarity.LEGENDARY or it.level < 4 or it.level > 6 or Items.slot_id(it, o) == &"" else 0
	check(absf(coins / float(kills) - float(loot["coins"]["chance"])) < 0.03, "coin rate ≈ %.2f: %.3f" % [loot["coins"]["chance"], coins / float(kills)])
	check(absf(gear / float(kills) - float(loot["gear-chance"])) < 0.03, "gear rate ≈ %.2f: %.3f" % [loot["gear-chance"], gear / float(kills)])
	check(absf(cons / float(kills) - float(loot["consumable-chance"])) < 0.03, "consumable rate: %.3f" % (cons / float(kills)))
	check(absf(feathers / float(kills) - float(loot["species-drop-chance"])) < 0.03, "species drop rate: %.3f" % (feathers / float(kills)))
	check(bad == 0, "every drop: coins 1+2·level, gear rarity ≤ legendary, level ±1, has a slot (%d bad)" % bad)
	rng.seed = 5; var l1 := Items.roll_loot(rng, 3, null, o, design); rng.seed = 5; var l2 := Items.roll_loot(rng, 3, null, o, design)
	check(l1.size() == l2.size() and (l1.is_empty() or Items.item_name(l1[0], o, design) == Items.item_name(l2[0], o, design)), "gen-loot is seed-deterministic")
	# c-loot-config fires
	loot["gear-chance"] = 2.0
	check(not o.validate(), "c-loot-config rejects a chance above 1")
	loot["gear-chance"] = 0.2; o.errors.clear()
	# scene: player with starting inventory, wolf that always drops, pick-up, quick item
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, 260.0)
	p.setup_items(o, design)
	p.position = Vector3(0, 1, 0); p.spawn_point = p.position
	check(p.inventory.equipment[&"main-hand"].subtype == &"sword" and is_equal_approx(p.weapon["damage"], 40.0), "starter sword equipped, damage 40: %s" % p.weapon)
	check(p.inventory.first_consumable() != null and p.inventory.first_consumable().count == 5, "5 life potions (starting-inventory)")
	var sure := design.duplicate(true)
	sure["loot"]["coins"]["chance"] = 1.0; sure["loot"]["gear-chance"] = 1.0; sure["loot"]["consumable-chance"] = 1.0
	var holder := Node3D.new(); root.add_child(holder)
	var wolf: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 2, "hostility": &"H", "max_hp": 200.0, "damage": 12.0, "positions": [Vector3(0, 1, -2)], "seed": 1}], sure, o.creatures, p, o)[0]
	await _frames(5)
	wolf.take_damage(1e9, p)
	var ground := get_nodes_in_group("ground-items")
	check(ground.size() == 3, "kill drops coins + gear + consumable: %d ground items" % ground.size())
	check(ground.size() > 0 and ground[0].get_parent() == holder, "ground items live under the creature's zone node")
	var before: int = p.inventory.entries.size()
	for g in ground:
		p.pick_up(g)
	await _frames(2)
	check(p.inventory.coins == 1 + 2 * 2 and p.inventory.entries.size() == before + 2, "picked up: %d copper, %d entries" % [p.inventory.coins, p.inventory.entries.size()])
	check(get_nodes_in_group("ground-items").is_empty(), "ground items gone after pick-up")
	p.hp = 10.0
	check(p.use_quick() and is_equal_approx(p.hp, minf(260.0, 10.0 + 200.0)) and p.inventory.first_consumable().count == 4, "Q drinks a life potion (+200): hp %.0f" % p.hp)
	p.inventory.unequip(&"main-hand")
	check(p.inventory.equipment.is_empty() and is_zero_approx(p.armor), "unequip clears gear; armor 0")
	print("items ok" if _failed == 0 else "items FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
