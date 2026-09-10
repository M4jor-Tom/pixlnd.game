## Headless check of §3.1 gen-settlement + §3.4 shop + D22 services: `godot --headless -s game/world/test_settlement.gd`.
## Village placement (determinism, dry land, plateau), layout, no wild spawns near the square, shop stock + prices,
## c-settlement-config; then a scene: buy / sell, trainer respec, inn rest, E finds the NPC, NPCs are unattackable.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
const Settlement := preload("res://game/world/settlement.gd")
const Spawner := preload("res://game/world/spawner.gd")
const Shop := preload("res://game/items/shop.gd")
const Items := preload("res://game/items/items.gd")
const NPC := preload("res://game/entities/npc.gd")
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
	var st: Dictionary = design["settlement"]
	var a := WorldGen.new(26879, design, o.landscapes)
	var b := WorldGen.new(26879, design, o.landscapes)
	var c := WorldGen.new(1, design, o.landscapes)
	var name_re := RegEx.create_from_string("^[A-Z][a-z]+$")
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var villages := 0; var r := float(st["radius"])
	for lx in range(-3, 4):
		for ly in range(-3, 4):
			var l = a.land_at(Vector2i(lx, ly))
			var v := a.village_at(l)
			check(v.hash() == b.village_at(b.land_at(Vector2i(lx, ly))).hash(), "same seed → same village at land %d,%d" % [lx, ly])
			if v.is_empty():
				continue
			villages += 1
			check(v["height"] >= a.sea_level + int(st["placement"]["min-above-sea"]), "village on dry land: h %d" % v["height"])
			check(name_re.search(v["name"]) != null, "village name shape: '%s'" % v["name"])
			check(o.configs["buildings"]["settlement-styles"].has(String(v["style"])), "style %s is a settlement-style" % v["style"])
			check(a.height_at(v["centre"].x, v["centre"].y) == v["height"], "square is at the village height")
			for i in 12:
				var ang := rng.randf() * TAU; var d := rng.randf() * (r - 1.0)
				var p := Vector2i(v["centre"].x + roundi(cos(ang) * d), v["centre"].y + roundi(sin(ang) * d))
				check(a.height_at(p.x, p.y) == v["height"], "plateau flat at %s (%d != %d)" % [p, a.height_at(p.x, p.y), v["height"]])
			var far := Vector2i(v["centre"].x + int(r + st["blend"]) + 3, v["centre"].y)
			check(a.height_at(far.x, far.y) == a._raw_height(far.x, far.y), "beyond radius + blend the heightfield is untouched")
	check(villages >= 30, "most of 49 lands have a village: %d" % villages)
	var v0 := a.village_at(a.land_at(Vector2i.ZERO)); var v0c := c.village_at(c.land_at(Vector2i.ZERO))
	check(not v0.is_empty() and (v0c.is_empty() or v0["name"] != v0c["name"]), "different seed → different village name")
	# layout: every building inside the radius, doors clear of their box, one NPC per service
	var lay := Settlement.layout(v0, st)
	check(lay.size() == st["buildings"].size(), "layout has %d buildings" % lay.size())
	var roles := {}
	for bd in lay:
		var cen: Vector3 = bd["centre"]; var half: float = maxf(bd["size"].x, bd["size"].z) / 2.0
		check(Vector2(cen.x - v0["centre"].x, cen.z - v0["centre"].y).length() + half < r, "building %s inside the plateau" % bd["id"])
		check(bd["door"].distance_to(cen) > bd["size"].z / 2.0, "door of %s is outside its box" % bd["id"])
		if bd["role"] != &"":
			roles[bd["role"]] = true
	check(roles.size() == st["npc"]["roles"].size(), "one NPC per service building: %s" % [roles.keys()])
	var node := Settlement.build(v0, st, o.configs["npc-roles"])
	check(node.get_child_count() == lay.size() + roles.size(), "village node = buildings + NPCs: %d" % node.get_child_count())
	node.free()
	# c-hostile-in-city: no wild group within no-hostiles-within of the square, over the 3×3 zones around it
	var zb: int = a.terrain["zone-blocks"]; var zc := Vector2i(floori(float(v0["centre"].x) / zb), floori(float(v0["centre"].y) / zb))
	var near := 0; var groups := 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for g in Spawner.plan(a, zc + Vector2i(dx, dy), design, o.creatures, o.configs["creature-families"]["landscape-rosters"], 1):
				groups += 1
				for p in g["positions"]:
					if Vector2(p.x - v0["centre"].x, p.z - v0["centre"].y).length() < float(st["no-hostiles-within"]) - float(design["spawns"]["group-spread"]) * 1.5:
						near += 1
	check(near == 0, "no wild spawns near the square (%d of %d groups)" % [near, groups])
	# shop stock + prices
	var l0 = a.land_at(Vector2i.ZERO)
	var w1 := Shop.stock(&"weapon-vendor", a, l0, v0, 3, o, design); var w2 := Shop.stock(&"weapon-vendor", a, l0, v0, 3, o, design)
	check(w1.size() == int(st["shop"]["stock"]), "weapon stock has %d items" % w1.size())
	var cap: int = o.rarities[StringName(st["shop"]["rarity-cap"])].index
	var bad := 0
	for i in w1.size():
		if w1[i].type != &"weapon" or w1[i].rarity > cap or w1[i].level < 1 or Items.item_name(w1[i], o, design) != Items.item_name(w2[i], o, design):
			bad += 1
	check(bad == 0, "weapon stock: weapons, rarity ≤ %s, deterministic (%d bad)" % [st["shop"]["rarity-cap"], bad])
	bad = 0
	for it in Shop.stock(&"armor-vendor", a, l0, v0, 3, o, design):
		if it.type == &"weapon" or Items.slot_id(it, o) == &"": bad += 1
	check(bad == 0, "armor stock is wearable armor")
	var pool: Array = design["loot"]["consumable-pool"]
	var cons := Shop.stock(&"item-vendor", a, l0, v0, 7, o, design)
	check(cons.size() == pool.size() and cons[0].type == &"consumable" and cons[0].level == 7, "item shop sells the consumable pool at the player level")
	var sword := Items.generate(rng, &"weapon", &"sword", &"iron", 1, 0)
	var rare := Items.generate(rng, &"weapon", &"sword", &"iron", 3, Model.Rarity.RARE)
	check(Shop.buy_price(sword, o, design) == 6 and Shop.buy_price(rare, o, design) == 72, "buy = base 6 × level × rarity-mult: %d, %d" % [Shop.buy_price(sword, o, design), Shop.buy_price(rare, o, design)])
	check(Shop.sell_price(rare, o, design) == 18 and Shop.sell_price(cons[0], o, design) >= 1, "sell = 25 %%, at least 1")
	# c-settlement-config fires
	st["ring-radius"] = 99.0
	check(not o.validate(), "c-settlement-config rejects ring-radius ≥ radius")
	st["ring-radius"] = 15.0; o.errors.clear()
	# scene: player next to an NPC; E resolves it; buy / sell / respec / rest
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, 260.0)
	p.setup_items(o, design)
	p.position = Vector3(0, 1, 0)
	var vendor := NPC.new(&"weapon-vendor", "Weapon Vendor", Color.BLUE); vendor.position = Vector3(2, 0, 0); root.add_child(vendor)
	var talked: Array = []
	p.talked.connect(func(n: Node) -> void: talked.append(n.role))
	await _frames(3)
	check(p.interact_nearest() and talked == [&"weapon-vendor"], "E within interact-radius talks to the vendor: %s" % [talked])
	check(p.bodies_within(p.global_position + Vector3.UP, 5.0).is_empty(), "NPCs are not strike targets (c-hostile-in-city)")
	vendor.position = Vector3(20, 0, 0)
	await _frames(2)
	check(not p.interact_nearest(), "E with nothing in range does nothing")
	var before: int = p.inventory.entries.size()
	check(not Shop.buy(p, w1[0]) and p.inventory.entries.size() == before, "no coins → no purchase")
	p.inventory.coins = 100
	var price := Shop.buy_price(w1[0], o, design)
	check(Shop.buy(p, w1[0]) and p.inventory.coins == 100 - price and w1[0] in p.inventory.entries, "buy moves the item and charges %d" % price)
	var potion = p.inventory.first_consumable(); var n0: int = potion.count; var coins0: int = p.inventory.coins
	Shop.sell(p, potion)
	check(potion.count == n0 - 1 and p.inventory.coins == coins0 + Shop.sell_price(potion, o, design), "sell one unit of a stack")
	Shop.sell(p, w1[0])
	check(not w1[0] in p.inventory.entries, "selling gear removes it from the bag")
	p.skill_points = 2
	var smash = p.skill_tree.class_slot(1)
	p.spend_skill(smash); p.spend_skill(smash)
	p.inventory.coins = 0
	check(not p.respec() and p.skill_tree.spent(smash.id) == 2, "respec refused without the fee")
	p.inventory.coins = int(st["trainer"]["respec-fee-per-level"]) * p.level
	check(p.respec() and p.skill_points == 2 and p.skill_tree.spent(smash.id) == 0 and p.inventory.coins == 0, "respec refunds 2 points for the fee")
	p.hp = 10.0; p.spawn_point = Vector3(50, 1, 50)
	p.rest()
	check(is_equal_approx(p.hp, p.max_hp) and p.spawn_point.distance_to(p.global_position) < 0.01, "inn heals and moves the respawn point")
	print("settlement: village '%s' (%s) at %s h %d; %d villages in 7×7 lands" % [v0["name"], v0["style"], v0["centre"], v0["height"], villages])
	print("settlement ok" if _failed == 0 else "settlement FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
