## Stateless source/cycle receipts, delivery and saved daily vendor transactions.
extends RefCounted
const Domain := preload("res://game/domain/domain.gd")
const Targeting := preload("res://game/combat/targeting.gd")
const EncounterGen := preload("res://game/world/encounter_gen.gd")
const Rewards := preload("res://game/items/encounter_rewards.gd")
const Items := preload("res://game/items/items.gd")
const Shop := preload("res://game/items/shop.gd")
const Save := preload("res://game/world/save_data.gd")
const Item := preload("res://game/items/item.gd")


static func stage_tables(world, site: Dictionary, layout: Dictionary, cycle: int) -> void:
	var cfg: Dictionary = world.design["initial-encounters"]
	var plan_ := EncounterGen.content_plan(layout, cfg)
	for key in plan_.props:
		if plan_.props[key].kind != "table":
			continue
		var rules: Dictionary = cfg.furnishings.table
		var level: int = int(site.room_levels[plan_.props[key].room])
		var potion = Item.stack(
			&"consumable",
			StringName(rules.potion),
			int(rules["potion-count"]),
			clampi(Domain.power_for_level(level), 1, 100)
		)
		potion.rarity = int(rules["potion-rarity"])
		var pair := [
			Item.stack(&"ingredient", StringName(rules.flask), int(rules["flask-count"])), potion
		]
		site.rewards["furnishing/%d/%s" % [cycle, key]] = {
			"payload": pair.map(Save.item_data), "delivered": false, "level": level
		}


static func site_death(world, id: String, stable: Dictionary, mob: Node3D) -> void:
	var site: Dictionary = world.state_data.sites[id]
	var saved: Dictionary = mob.incarnation
	var key := "kill/%d/%s" % [saved.cycle, stable.key]
	if site.rewards.has(key):
		return
	var spirit_level: int = int(site.spirit_levels[stable.key]) if stable.spirit != "" else 0
	var payload := Rewards.kill_payload(
		stable, int(saved.cycle), int(saved.level), spirit_level, world.ontology, world.design
	)
	world.state_data.issue_reward(id, key, payload.map(Save.item_data))
	site.rewards[key].level = int(saved.level)
	site.rewards[key].position = mob.logical_position()
	site.cleared = site.mobs.values().all(func(m): return m.dead)
	_finish_death(world, id, site, mob)


static func _issue_mission(world, id: String, site: Dictionary, mob: Node3D) -> bool:
	var layout: Dictionary = world.site_layout(id)
	var boss: Dictionary = layout.assignments.filter(func(a): return a.boss)[0]
	var mission := "mission/%d" % site.cycle
	var classes := Rewards.completion_classes(
		world.party_provider.call(), site.volumes, mob.last_attacker
	)
	var cls: String = (
		classes[Rewards.rng_for(id + "/" + mission + "/class").randi_range(0, classes.size() - 1)]
		if not classes.is_empty()
		else ""
	)
	site.rewards[mission] = {
		"payload": [],
		"delivered": false,
		"level": int(site.mobs[id + "/" + boss.key].level),
		"classes": classes,
		"class_id": cls
	}
	world.resolve_package(id, mission)
	return true


static func resolve_package(world, id: String, key: String) -> void:
	var record: Dictionary = world.state_data.sites[id].rewards[key]
	if record.class_id == "" or not record.payload.is_empty():
		return
	var layout: Dictionary = world.site_layout(id)
	record.payload = (
		Rewards
		. package_payload(
			id + "/" + key,
			int(layout.tier),
			int(record.level),
			StringName(record.class_id),
			world.ontology,
			world.design
		)
		. map(Save.item_data)
	)


static func deliver_rewards(world, id: String) -> void:
	var site: Dictionary = world.state_data.sites[id]
	for key in site.rewards:
		if not _deliver_record(world, id, site, key):
			return


static func _deliver_record(world, id: String, site: Dictionary, key) -> bool:
	if key.begins_with("furnishing/"):
		return true
	var record: Dictionary = site.rewards[key]
	if record.delivered:
		return true
	var point: Array
	if key.begins_with("mission/"):
		return _deliver_mission(world, id, site, key, record)
	point = record.position
	return _spawn_reward(world, id, key, record, point)


static func _deliver_mission(world, id: String, site: Dictionary, key, record: Dictionary) -> bool:
	if record.class_id == "":
		if not _resolve_entrant(world, id, site, key, record):
			return false
	return _deliver_package(world, id, site, key, record)


static func _resolve_entrant(world, id: String, site: Dictionary, key, record: Dictionary) -> bool:
	for member in world.party_provider.call():
		if world.state_data.inside(site.volumes, [Targeting.position_of(member)]):
			record.class_id = Rewards.class_of(member)
			world.resolve_package(id, key)
			world.state_changed.emit()
			break
	return true


static func _spawn_reward(world, id: String, key, record: Dictionary, point: Array) -> bool:
	if not world.site_views.has(id) or not world.site_views[id].is_inside_tree():
		return true
	record.delivered = true  # durable before callbacks expose shared ordinary pickups
	var pos: Vector3 = (
		world.frame.to_local(point)
		if world.frame != null
		else Vector3(point[0], point[1], point[2])
	)
	Items.spawn_drops(
		world.site_views[id],
		pos,
		record.payload.map(Save.item_from),
		Rewards.rng_for(id + "/" + key + "/scatter"),
		world.ontology,
		world.design
	)
	world.state_changed.emit()
	return true


static func complete_supplier(world, id: String) -> bool:
	var site: Dictionary = world.state_data.sites[id]
	if site.family != "supplier" or site.completed or not site.cleared:
		return false
	if not world.site_layout(id).has("captive"):
		return false
	site.completed = true
	site.pending = false
	world.deliver_rewards(id)
	world.state_changed.emit()
	return true


static func supplier_ceiling(world, coords: Vector2i) -> int:
	var count := int(
		world.ontology.rarities[StringName(world.design.settlement.shop["rarity-cap"])].slot_index
	)
	for ordinal in world.design["initial-encounters"].supplier.tiers.size():
		var id: String = world.state_data.site_id(coords, "supplier", ordinal)
		if world.state_data.sites.has(id) and world.state_data.sites[id].completed:
			count += 1
	return count


static func vendor_stock(world, role: StringName, player_level: int, coords: Vector2i) -> Array:
	var land = world.gen.land_at(coords)
	if not Shop.is_vendor(role) or not world.ensure_land(land):
		return []
	if role == &"item-vendor":
		return Shop.stock(
			role,
			world.gen,
			land,
			world.gen.village_at(land),
			player_level,
			world.ontology,
			world.design
		)
	return _daily_stock(world, role, player_level, coords, land)


static func _daily_stock(
	world, role: StringName, player_level: int, coords: Vector2i, land
) -> Array:
	var key := "%d,%d/%s" % [coords.x, coords.y, role]
	var day := floori(world.state_data.clock / float(world.design.time["day-s"]))
	if not world.state_data.vendors.has(key) or world.state_data.vendors[key].day != day:
		var cap: int = world.supplier_ceiling(coords)
		var items := Shop.stock(
			role,
			world.gen,
			land,
			world.gen.village_at(land),
			player_level,
			world.ontology,
			world.design,
			cap,
			day
		)
		world.state_data.vendors[key] = {
			"day": day, "ceiling": cap, "level": player_level, "items": items.map(Save.item_data)
		}
		world.state_changed.emit()
	return world.state_data.vendors[key].items.map(Save.item_from)


static func buy_vendor(
	world, role: StringName, index: int, player, coords: Vector2i, expected = null
) -> bool:
	var stock: Array = world.vendor_stock(role, player.level, coords)
	if index < 0 or index >= stock.size():
		return false
	if (
		expected != null
		and not Save.same_data(Save.item_data(expected), Save.item_data(stock[index]))
	):
		return false
	return _purchase(world, role, index, player, coords, stock)


static func restock_vendors(world) -> void:
	var levels: Array = world.party_levels()
	if levels.is_empty():
		return
	var day := floori(world.state_data.clock / float(world.design.time["day-s"]))
	for key in world.state_data.vendors.keys():
		if world.state_data.vendors[key].day == day:
			continue
		var parts: PackedStringArray = key.split("/")
		var xy: PackedStringArray = parts[0].split(",")
		world.vendor_stock(StringName(parts[1]), int(levels[0]), Vector2i(int(xy[0]), int(xy[1])))


static func _finish_death(world, id: String, site: Dictionary, mob: Node3D) -> void:
	if site.cleared and site.family != "ruins":
		if not _issue_mission(world, id, site, mob):
			return
	world.deliver_rewards(id)
	world.state_changed.emit()


static func _deliver_package(world, id: String, site: Dictionary, key, record: Dictionary) -> bool:
	if record.class_id == "" or (site.family == "supplier" and not site.completed):
		return true
	var layout: Dictionary = world.site_layout(id)
	var point: Array = (
		layout.captive.duplicate()
		if site.family == "supplier"
		else [layout.centre[0], layout.floor, layout.centre[1]]
	)
	point[1] += (
		float(world.design["initial-encounters"]["mission-package"]["delivery-height"]) - 0.5
	)  # spawn_drops supplies its usual half block
	return _spawn_reward(world, id, key, record, point)


static func _purchase(
	world, role: StringName, index: int, player, coords: Vector2i, stock: Array
) -> bool:
	# Remove authoritative gear BEFORE Inventory.changed can expose/save the purchase.
	var key := "%d,%d/%s" % [coords.x, coords.y, role]
	if player.inventory.coins < Shop.buy_price(stock[index], world.ontology, world.design):
		return false
	if role != &"item-vendor":
		world.state_data.vendors[key].items.remove_at(index)
	Shop.buy(player, stock[index])
	world.state_changed.emit()
	return true
