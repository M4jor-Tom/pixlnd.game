## Ordered reward/vendor checks. Completion phases keep ordinary rejected rows
## separate from native-error false, which propagates to the original owner.
extends RefCounted
const Rewards := preload("res://game/items/encounter_rewards.gd")
const Shop := preload("res://game/items/shop.gd")


static func validate_rewards(save, site: Dictionary, layout: Dictionary) -> void:
	if _missing_reward_inputs(save, site):
		return
	var sources := {}
	for stable in layout.assignments:
		sources[stable.key] = stable
	if not _records(save, site, layout, sources):
		return
	_receipts(save, site, layout)


static func validate_vendors(save, w: Dictionary) -> void:
	if not save.require(w.get("vendors") is Dictionary, "world.vendors"):
		return
	for key in w.vendors:
		if not _vendor(save, w, key):
			return


static func _reward(
	save, site: Dictionary, layout: Dictionary, sources: Dictionary, key: Variant
) -> bool:
	if key is String and key.begins_with("furnishing/"):
		return true
	if not save.require(key is String, "world.site.reward.identity"):
		return true
	return _reward_cycle_record(save, site, layout, sources, key)


static func _kill(
	save, site: Dictionary, sources: Dictionary, parts: PackedStringArray, record: Variant
) -> bool:
	var source := "/".join(parts.slice(2))
	if not save.require(parts.size() == 4 and sources.has(source), "world.site.kill.source"):
		return true
	var stable: Dictionary = sources[source]
	var mob: Variant = site.mobs.get(site.id + "/" + source)
	if _missing_incarnation(save, mob):
		return true
	return (
		_kill_incarnation(save, record, mob, parts)
		and _kill_spirit_payload(save, site, stable, source, parts, record)
	)


static func _mission(
	save,
	site: Dictionary,
	layout: Dictionary,
	key: Variant,
	parts: PackedStringArray,
	record: Variant
) -> bool:
	if not save.require(
		parts.size() == 2 and layout.family != "ruins", "world.site.mission.source"
	):
		return true
	save.require(record.size() == 5, "world.site.mission.fields")
	var classes: Variant = record.get("classes")
	var cls: Variant = record.get("class_id")
	if not save.require(classes is Array and cls is String, "world.site.mission.class snapshot"):
		return true
	return _mission_snapshot(save, site, layout, key, parts, record, classes, cls)


static func _vendor(save, w: Dictionary, key: Variant) -> bool:
	if not save.require(key is String, "world.vendor.identity"):
		return true
	return _vendor_land_record(save, w, key)


static func _death_receipts(save, site: Dictionary, stable: Variant) -> bool:
	var mob: Variant = site.mobs.get(site.id + "/" + stable.key)
	if _missing_incarnation(save, mob):
		return true
	save.require(mob.cycle <= site.cycle, "world.site.kill.incarnation cycle")
	# One receipt per genuine death; never accept deleted issued records as a reroll opportunity.
	var count := int(mob.cycle) + (1 if mob.get("dead") == true else 0)
	return _death_receipt_count(save, site, stable, count)


static func _reward_record(save, record: Variant) -> bool:
	return (
		record is Dictionary
		and record.get("delivered") is bool
		and record.get("payload") is Array
		and save._integer(record.get("level"), 1)
	)


static func _kill_incarnation(
	save, record: Variant, mob: Dictionary, parts: PackedStringArray
) -> bool:
	save.require(record.size() == 4, "world.site.kill.fields")
	save.position(record.get("position"), "world.site.kill.position")
	save.require(
		int(parts[1]) < mob.cycle or (int(parts[1]) == mob.cycle and mob.get("dead") == true),
		"world.site.kill.genuine death"
	)
	if int(parts[1]) == mob.cycle:
		save.require(record.level == mob.get("level"), "world.site.kill.current level")
	return true


static func _mission_snapshot(
	save,
	site: Dictionary,
	layout: Dictionary,
	key: Variant,
	parts: PackedStringArray,
	record: Variant,
	classes: Variant,
	cls: Variant
) -> bool:
	var seen := {}
	var valid := true
	for candidate in classes:
		if not save.require(
			_distinct_class(save, candidate, seen), "world.site.mission.distinct classes"
		):
			valid = false
		seen[candidate] = true
	return _mission_class_selection(save, site, layout, key, parts, record, classes, cls, valid)


static func _mission_completion(
	save, site: Dictionary, layout: Dictionary, record: Variant, parts: PackedStringArray
) -> bool:
	if int(parts[1]) == site.cycle:
		save.require(site.get("cleared") == true, "world.site.mission.designated clear")
		var boss: Dictionary = layout.assignments.filter(func(a): return a.boss)[0]
		if site.mobs.get(site.id + "/" + boss.key) is Dictionary:
			save.require(
				record.level == site.mobs[site.id + "/" + boss.key].get("level"),
				"world.site.mission.saved boss level"
			)
	return true


static func _vendor_registered_land(w: Dictionary, parts: PackedStringArray) -> bool:
	return w.get("lands") is Dictionary and w.lands.has(parts[0])


static func _vendor_gear_inputs(save, record: Variant) -> bool:
	return (
		save._integer(record.get("ceiling"))
		and save._integer(record.get("level"), 1)
		and record.get("items") is Array
	)


static func _remaining_stock(save, record: Variant, expected: Array) -> bool:
	var cursor := 0
	for item in record.items:
		save.validate_item(item, "world.vendor.item")
		while cursor < expected.size() and not save._same_data(item, expected[cursor]):
			cursor += 1
		save.require(cursor < expected.size(), "world.vendor.exact remaining stock")
		cursor += 1

	return true


static func _vendor_stock(save, record: Variant, parts: PackedStringArray) -> bool:
	var xy: PackedStringArray = parts[0].split(",")
	var land = save._geography.land_at(Vector2i(int(xy[0]), int(xy[1])))
	var expected := (
		Shop
		. stock(
			StringName(parts[1]),
			save._geography,
			land,
			save._geography.village_at(land),
			int(record.level),
			save.o,
			save.design,
			int(record.ceiling),
			int(record.day)
		)
		. map(save._item_data)
	)
	return _remaining_stock(save, record, expected)


static func _missing_reward_inputs(save, site: Dictionary) -> bool:
	return (
		not site.get("rewards") is Dictionary
		or not site.get("mobs") is Dictionary
		or not save._integer(site.get("cycle"))
	)


static func _records(save, site: Dictionary, layout: Dictionary, sources: Dictionary) -> bool:
	for key in site.rewards:
		if not _reward(save, site, layout, sources, key):
			return false
	return true


static func _reward_payload(
	save,
	site: Dictionary,
	layout: Dictionary,
	sources: Dictionary,
	key: Variant,
	parts: PackedStringArray
) -> bool:
	var record: Variant = site.rewards[key]
	if not save.require(_reward_record(save, record), "world.site.reward.record"):
		return true
	if parts[0] == "kill":
		return _kill(save, site, sources, parts, record)
	if parts[0] == "mission":
		return _mission(save, site, layout, key, parts, record)
	save.require(false, "world.site.reward.unknown source")
	return true


static func _vendor_record(save, w: Dictionary, parts: PackedStringArray, record: Variant) -> bool:
	save.require(record.size() == 4, "world.vendor.fields")
	var valid: bool = (
		save._integer(record.get("day"))
		and save._number(w.get("clock"))
		and record.get("day", INF) <= floori(w.clock / float(save.design.time["day-s"]))
		and _vendor_gear_inputs(save, record)
	)
	if not save.require(valid, "world.vendor.stock inputs"):
		return true
	return _vendor_ceiling_stock(save, w, parts, record)


static func _mission_class_selection(
	save,
	site: Dictionary,
	layout: Dictionary,
	key: Variant,
	parts: PackedStringArray,
	record: Variant,
	classes: Variant,
	cls: Variant,
	valid: bool
) -> bool:
	if not save.require(cls == "" or save.o.classes.has(cls), "world.site.mission.selected class"):
		return true
	if not _uniform_class_snapshot(save, site, key, classes, cls, valid):
		return false
	return _mission_delivery(save, site, layout, key, parts, record, cls)


static func _mission_delivery(
	save,
	site: Dictionary,
	layout: Dictionary,
	key: Variant,
	parts: PackedStringArray,
	record: Variant,
	cls: Variant
) -> bool:
	if not _mission_completion(save, site, layout, record, parts):
		return false
	if not _mission_payload(save, site, layout, key, record, cls):
		return false
	return _rescue_delivery(save, layout, site, record)


static func _missing_incarnation(save, mob: Variant) -> bool:
	return not mob is Dictionary or not save._integer(mob.get("cycle"))


static func _distinct_class(save, candidate: Variant, seen: Dictionary) -> bool:
	return candidate is String and save.o.classes.has(candidate) and not seen.has(candidate)


static func _receipts(save, site: Dictionary, layout: Dictionary) -> void:
	for stable in layout.assignments:
		if not _death_receipts(save, site, stable):
			return
	if site.get("cleared") == true and layout.family != "ruins":
		save.require(
			site.rewards.has("mission/%d" % site.cycle), "world.site.mission.completion receipt"
		)


static func _kill_spirit_payload(
	save,
	site: Dictionary,
	stable: Dictionary,
	source: String,
	parts: PackedStringArray,
	record: Variant
) -> bool:
	var spirit_level: Variant = 0
	if stable.spirit != "":
		if not site.get("spirit_levels") is Dictionary:
			return true  # diagnosed by the site-content boundary
		spirit_level = site.spirit_levels.get(source)
	if not save._integer(spirit_level):
		return true
	var expected := (
		Rewards
		. kill_payload(
			stable, int(parts[1]), int(record.level), int(spirit_level), save.o, save.design
		)
		. map(save._item_data)
	)
	save.require(save._same_data(record.payload, expected), "world.site.kill.exact payload")
	return true


static func _vendor_ceiling_stock(
	save, w: Dictionary, parts: PackedStringArray, record: Variant
) -> bool:
	var ceiling := 0
	if w.get("sites") is Dictionary:
		for ordinal in save.design["initial-encounters"].supplier.tiers.size():
			var id := "%s/site/%s/supplier/%d" % [w.world_id, parts[0], ordinal]
			if w.sites.get(id) is Dictionary and w.sites[id].get("completed") == true:
				ceiling += 1
	return _earned_vendor_stock(save, record, parts, ceiling)


static func _mission_payload(
	save, site: Dictionary, layout: Dictionary, key: Variant, record: Variant, cls: Variant
) -> bool:
	if cls == "":
		save.require(
			record.payload.is_empty() and not record.delivered, "world.site.mission.pending class"
		)
	else:
		save.require(
			save._same_data(
				record.payload,
				(
					Rewards
					. package_payload(
						site.id + "/" + key,
						int(layout.tier),
						int(record.level),
						StringName(cls),
						save.o,
						save.design
					)
					. map(save._item_data)
				)
			),
			"world.site.mission.exact payload"
		)
	return true


static func _reward_cycle_record(
	save, site: Dictionary, layout: Dictionary, sources: Dictionary, key: Variant
) -> bool:
	var parts: PackedStringArray = key.split("/")
	var valid: bool = _reward_parts(parts) and int(parts[1]) <= site.cycle
	if not save.require(valid, "world.site.reward.cycle"):
		return true
	return _reward_payload(save, site, layout, sources, key, parts)


static func _earned_vendor_stock(
	save, record: Variant, parts: PackedStringArray, ceiling: int
) -> bool:
	if not save.require(record.ceiling <= ceiling, "world.vendor.earned ceiling"):
		return true
	return _vendor_stock(save, record, parts)


static func _rescue_delivery(save, layout: Dictionary, site: Dictionary, record: Variant) -> bool:
	if layout.family == "supplier" and site.get("completed") != true:
		save.require(not record.delivered, "world.site.mission.rescue delivery order")
	return true


static func _vendor_land_record(save, w: Dictionary, key: Variant) -> bool:
	var parts: PackedStringArray = key.split("/")
	var valid: bool = (
		parts.size() == 2
		and save._coordinate_pair(parts[0], int(save.design.terrain["lands-per-axis"]) / 2)
		and parts[1] in ["weapon-vendor", "armor-vendor"]
		and _vendor_registered_land(w, parts)
	)
	if not save.require(valid, "world.vendor.land/role"):
		return true
	return _vendor_representation(save, w, key, parts)


static func _vendor_representation(
	save, w: Dictionary, key: Variant, parts: PackedStringArray
) -> bool:
	var record: Variant = w.vendors[key]
	if not save.require(record is Dictionary, "world.vendor.record"):
		return true
	return _vendor_record(save, w, parts, record)


static func _reward_parts(parts: PackedStringArray) -> bool:
	return (
		parts.size() >= 2
		and parts[1].is_valid_int()
		and str(int(parts[1])) == parts[1]
		and int(parts[1]) >= 0
	)


static func _uniform_class_snapshot(
	save, site: Dictionary, key: Variant, classes: Variant, cls: Variant, valid: bool
) -> bool:
	if valid and not classes.is_empty():
		var sorted: Array = classes.duplicate()
		sorted.sort()
		save.require(
			(
				classes == sorted
				and (
					cls
					== classes[Rewards.rng_for(site.id + "/" + key + "/class").randi_range(
						0, classes.size() - 1
					)]
				)
			),
			"world.site.mission.uniform class snapshot"
		)
	return true


static func _death_receipt_count(save, site: Dictionary, stable: Variant, count: int) -> bool:
	var actual := 0
	for key in site.rewards:
		if (
			key is String
			and key.begins_with("kill/")
			and "/".join(key.split("/").slice(2)) == stable.key
		):
			actual += 1
	save.require(actual == count, "world.site.kill.death receipt count")
	return true
