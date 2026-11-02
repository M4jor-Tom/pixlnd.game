## Ordered feature record checks. Completion phases keep ordinary rejected rows
## separate from native-error false, which propagates to the original owner.
extends RefCounted
const Model := preload("res://ontology/model.gd")
const Item := preload("res://game/items/item.gd")
const EncounterGen := preload("res://game/world/encounter_gen.gd")


static func validate_features(save, site: Dictionary, layout: Dictionary, clock: float) -> void:
	var cfg: Dictionary = save.design["initial-encounters"]
	var plan_ := EncounterGen.content_plan(layout, cfg)
	var levels: Variant = site.get("room_levels")
	if not _room_levels(save, levels, layout):
		return
	_contents(save, site, plan_, cfg, levels, clock)


static func _solids(
	save, contents: Variant, plan_: Dictionary, cfg: Dictionary, clock: float
) -> bool:
	for field in ["rubble", "props"]:
		if not _solid_family(save, contents, plan_, cfg, clock, field):
			return false
	return true


static func _traps(save, contents: Variant, plan_: Dictionary, cfg: Dictionary) -> bool:
	var traps_: Variant = contents.get("traps")
	if not save.require(_trap_array(traps_, plan_), "world.site.contents.traps"):
		return true
	for trap in traps_:
		if not _trap(save, trap, cfg):
			return false
	return true


static func _furnishing_reward(
	save, site: Dictionary, id: Variant, plan_: Dictionary, cfg: Dictionary, levels: Variant
) -> bool:
	if _other_reward(id):
		return true  # other reward owners validate their own sources
	return _furnishing_cycle_record(save, site, id, plan_, cfg, levels)


static func _solid(
	save,
	rows: Variant,
	field: String,
	key: String,
	plan_: Dictionary,
	cfg: Dictionary,
	clock: float
) -> bool:
	var row: Variant = rows.get(key)
	if not save.require(row is Dictionary, "world.site.contents." + field + ".identity"):
		return true
	if field == "rubble":
		return _rubble(save, row, cfg, clock)
	save.require(row.size() == 1, "world.site.contents.prop.fields")
	save.require(
		(
			save._number(row.get("hp"))
			and row.get("hp", INF) <= cfg.furnishings[plan_.props[key].kind].hp
		),
		"world.site.contents.prop.hp"
	)
	return true


static func _trap(save, trap: Variant, cfg: Dictionary) -> bool:
	if not save.require(trap is Dictionary, "world.site.contents.trap"):
		return true
	save.require(trap.size() == 3, "world.site.contents.trap.fields")
	var phase: String = trap.phase if trap.get("phase") is String else ""
	save.require(
		phase in ["idle", "warning", "active", "cooldown"], "world.site.contents.trap.phase"
	)
	var maximum: float = cfg.spikes.get(str(phase) + "-s", 0)
	save.require(
		save._number(trap.get("left")) and trap.get("left", INF) <= maximum,
		"world.site.contents.trap.left"
	)
	return _trap_hits(save, trap, phase)


static func _room_levels(save, levels: Variant, layout: Dictionary) -> bool:
	if save.require(
		levels is Array and levels.size() == (3 if layout.family == "ruins" else 0),
		"world.site.room_levels"
	):
		for level in levels:
			save.require(save._integer(level, 1), "world.site.room_levels.level")
	return true


static func _issuance(save, site: Dictionary, contents: Variant, plan_: Dictionary) -> void:
	for key in plan_.props:
		if not save._integer(site.get("cycle")):
			continue
		var id := "furnishing/%d/%s" % [site.cycle, key]
		if plan_.props[key].kind == "table":
			save.require(site.rewards.has(id), "world.site.table issued independently")
		elif _vase_inputs(save, contents, key):
			save.require(
				site.rewards.has(id) == (contents.props[key].hp == 0),
				"world.site.vase destruction issuance"
			)


static func _trap_array(traps_: Variant, plan_: Dictionary) -> bool:
	return traps_ is Array and traps_.size() == plan_.traps.size()


static func _furnishing_parts(parts: PackedStringArray) -> bool:
	return (
		parts.size() == 6
		and parts[1].is_valid_int()
		and str(int(parts[1])) == parts[1]
		and int(parts[1]) >= 0
	)


static func _furnishing_record(save, reward: Variant) -> bool:
	return (
		reward is Dictionary
		and save._integer(reward.get("level"), 1)
		and reward.get("payload") is Array
	)


static func _furnishing_contents(
	save, prop: Dictionary, level: int, cfg: Dictionary, reward: Variant
) -> bool:
	var expected: Array
	if prop.kind == "vase":
		var count := (
			int(cfg.furnishings.vase["coin-base"])
			+ int(cfg.furnishings.vase["coin-per-level"]) * level
		)
		expected = [save._item_data(Item.stack(&"coin", &"", count))]
	else:
		var rules: Dictionary = cfg.furnishings.table
		var potion = Item.stack(
			&"consumable",
			StringName(rules.potion),
			int(rules["potion-count"]),
			clampi(Model.power_for_level(level), 1, 100)
		)
		potion.rarity = int(rules["potion-rarity"])
		expected = [
			save._item_data(
				Item.stack(&"ingredient", StringName(rules.flask), int(rules["flask-count"]))
			),
			save._item_data(potion)
		]
	save.require(save._same_data(reward.payload, expected), "world.site.furnishing exact payload")
	return true


static func _rubble(save, row: Variant, cfg: Dictionary, clock: float) -> bool:
	save.require(row.size() == 2, "world.site.contents.rubble.fields")
	save.require(
		row.get("broken") is bool and save._number(row.get("restore_at")),
		"world.site.contents.rubble.state"
	)
	if row.get("broken") is bool and save._number(row.get("restore_at")):
		save.require(
			row.restore_at > 0 if row.broken else row.restore_at == 0,
			"world.site.contents.rubble.deadline"
		)
		save.require(
			row.restore_at <= clock + float(cfg.rubble["restore-world-hours"]) * 3600,
			"world.site.contents.rubble.deadline upper bound"
		)
	return true


static func _trap_hits(save, trap: Variant, phase: String) -> bool:
	if save.require(trap.get("hit") is Array, "world.site.contents.trap.hit"):
		var seen := {}
		for id in trap.hit:
			save.require(_unseen_hit(save, id, seen), "world.site.contents.trap.hit identity")
			seen[id] = true
		if phase in ["idle", "warning"]:
			save.require(trap.hit.is_empty(), "world.site.contents.trap.phase hitset")
	return true


static func _contents(
	save, site: Dictionary, plan_: Dictionary, cfg: Dictionary, levels: Variant, clock: float
) -> void:
	var contents: Variant = site.get("contents")
	if not save.require(contents is Dictionary, "world.site.contents"):
		return
	save.require(contents.size() == 3, "world.site.contents.fields")
	if _solids(save, contents, plan_, cfg, clock) and _traps(save, contents, plan_, cfg):
		_furnishings(save, site, plan_, cfg, levels, contents)


static func _furnishings(
	save, site: Dictionary, plan_: Dictionary, cfg: Dictionary, levels: Variant, contents: Variant
) -> void:
	if not site.get("rewards") is Dictionary:
		return
	for id in site.rewards:
		if not _furnishing_reward(save, site, id, plan_, cfg, levels):
			return

	_issuance(save, site, contents, plan_)


static func _solid_family(
	save, contents: Variant, plan_: Dictionary, cfg: Dictionary, clock: float, field: String
) -> bool:
	var rows: Variant = contents.get(field)
	if not save.require(rows is Dictionary, "world.site.contents." + field):
		return true
	save.require(rows.size() == plan_[field].size(), "world.site.contents." + field + ".count")
	for key in plan_[field]:
		if not _solid(save, rows, field, key, plan_, cfg, clock):
			return false
	return true


static func _other_reward(id: Variant) -> bool:
	return not id is String or not id.begins_with("furnishing/")


static func _furnishing_record_payload(
	save,
	site: Dictionary,
	id: String,
	plan_: Dictionary,
	cfg: Dictionary,
	levels: Variant,
	parts: PackedStringArray,
	key: String
) -> bool:
	var reward: Variant = site.rewards[id]
	if not save.require(
		_furnishing_record(save, reward), "world.site.furnishing reward level/payload"
	):
		return true
	var prop: Dictionary = plan_.props[key]
	var level: int = int(reward.level)
	if not _saved_room_reward(save, parts, site, levels, prop, level):
		return false
	return _furnishing_contents(save, prop, level, cfg, reward)


static func _vase_inputs(save, contents: Variant, key: String) -> bool:
	return (
		contents.get("props") is Dictionary
		and contents.props.get(key) is Dictionary
		and save._number(contents.props[key].get("hp"))
	)


static func _unseen_hit(save, id: Variant, seen: Dictionary) -> bool:
	return save._text(id) and not seen.has(id)


static func _furnishing_cycle_record(
	save, site: Dictionary, id: String, plan_: Dictionary, cfg: Dictionary, levels: Variant
) -> bool:
	var parts: PackedStringArray = id.split("/")
	var valid: bool = (
		_furnishing_parts(parts)
		and save._integer(site.get("cycle"))
		and int(parts[1]) <= site.cycle
	)
	if not save.require(valid, "world.site.furnishing reward cycle"):
		return true
	return _furnishing_source(save, site, id, plan_, cfg, levels, parts)


static func _furnishing_source(
	save,
	site: Dictionary,
	id: String,
	plan_: Dictionary,
	cfg: Dictionary,
	levels: Variant,
	parts: PackedStringArray
) -> bool:
	var key := "/".join(parts.slice(2))
	if not save.require(plan_.props.has(key), "world.site.furnishing reward source"):
		return true
	return _furnishing_record_payload(save, site, id, plan_, cfg, levels, parts, key)


static func _saved_room_reward(
	save, parts: PackedStringArray, site: Dictionary, levels: Variant, prop: Dictionary, level: int
) -> bool:
	if int(parts[1]) == site.get("cycle") and levels is Array and levels.size() == 3:
		save.require(
			save._integer(levels[prop.room], 1) and level == levels[prop.room],
			"world.site.furnishing saved room reward level"
		)
	return true
