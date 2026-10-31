## Finite source envelopes and exact annotation resolution; no model dependency.
extends RefCounted

# Exact §5 envelopes. These paths date table facts, not referenced definitions or availability.
const SOURCE_SCOPES := {
	"A":
	"block-types.alpha item-types static-entities.by-id mission-types.alpha rarities.alpha-relative-colors stats.alpha-item-stat-formulas stats.alpha-character-formulas audio.sfx-alpha-ids equipment-slots.slots equipment-slots.extra.consumable economy.currency.A economy.incomes.A economy.prices.A economy.shops.weapon-shop.stock.A economy.shops.item-shop.sells.A economy.rules.buy-back.A economy.loot.A-boss economy.loot.A-dungeon recipes.crafting-tabs-a recipes.recipe-sources.A recipes.customization.spirit-cubes-a buildings.map-visibility.A generators.world-scales.alpha generators.seed.alpha-default generators.seed.alpha-source generators.land.alpha-level generators.land.alpha-rarity generators.land.alpha-per-land generators.settlement.alpha-count generators.settlement.districts-alpha generators.settlement.inn.A generators.dungeon.alpha-layout generators.dungeon.traps-alpha generators.dungeon.boss.A generators.boss.alpha-size-scaling generators.boss.alpha-spirit-drop generators.level-formulas-alpha generators.network-alpha",
	"S":
	"block-types.steam item-types._s-additions static-entities.s-additions mission-types.steam rarities.mob-strength-tiers-s economy.currency.S economy.incomes.S economy.prices.S economy.shops.weapon-shop.stock.S economy.shops.item-shop.sells.S economy.rules.buy-back.S economy.loot.S-mission economy.loot.S-dungeon recipes.recipe-sources.S recipes.customization.fully-modded-legendary-plus-s buildings.map-visibility.S audio.ambient.S key-items.counts-per-land-s generators.world-scales.steam generators.seed.steam generators.land.steam-tiers generators.land.steam-per-land generators.settlement.steam-count generators.settlement.inn.S generators.dungeon.steam-layout generators.dungeon.boss.S generators.dungeon.artifact-s generators.dungeon.size-cap-s generators.boss.steam-loot generators.boss.coins-s generators.key-items-s",
	"X": "generators.dungeon.traps-data-x",
	"Ω": "audio.ambient.Ω generators.npc-appearance.omega generators.coarse-map-omega"
}

# Existing mixed hybrid/modded context is retained verbatim, not a source-tag extension.
const SOURCE_CONTEXT_TAGS := {
	"slash-commands.!goto <player> / !tp <loc>": ["A-mod"],
	"ui.hud.debug-menu": ["hybrid"],
	"ui.screens.skills": ["A", "hybrid"],
	"ui.screens.npc-service": ["hybrid"]
}

const SOURCE_TAGS := ["A", "S", "Ω", "X", "A?", "S?"]
const SOURCE_FIELDS := ["versions", "v"]


static func source_tags_valid(tags: Variant) -> bool:
	return tags is Array and valid_tag_array(tags)


static func valid_tag_array(tags: Array) -> bool:
	if tags.is_empty():
		return false
	for tag in tags:
		if not source_tag_valid(tag):
			return false
	return true


static func source_tag_valid(tag: Variant) -> bool:
	return tag is String and tag in SOURCE_TAGS


static func contextual_annotation(path: String, field: String, tags: Variant) -> bool:
	if field != "versions" or not tags is Array:
		return false
	return SOURCE_CONTEXT_TAGS.has(path) and tags == SOURCE_CONTEXT_TAGS[path]


static func source_value(configs: Dictionary, path: String) -> Variant:
	var value: Variant = configs
	for field in path.split("."):
		value = source_child(value, field)
		if value == null:
			return null
	return value


static func source_child(value: Variant, field: String) -> Variant:
	if value is Dictionary:
		return value.get(field)
	if value is Array and field.is_valid_int():
		var index := int(field)
		if index >= 0 and index < value.size():
			return value[index]
	return null


static func within_source(path: String, scope: String) -> bool:
	return path == scope or path.begins_with(scope + ".")


static func source_at(o, path: String) -> Dictionary:
	var unresolved := {"tags": [], "origin": "", "status": "unresolved"}
	if o._source_value(path) == null:
		return unresolved
	var envelope := source_envelope(o, path)
	if excluded_path(o, path) or metadata_path(path):
		return unresolved
	if envelope.scope == "item-types" and path == envelope.scope:
		return unresolved
	return resolve_envelope(o, path, envelope, unresolved)


static func resolve_envelope(
	o, path: String, envelope: Dictionary, unresolved: Dictionary
) -> Dictionary:
	var explicit := nearest_annotation(o, path, envelope.scope)
	if not explicit.is_empty():
		return explicit
	if not envelope.scope.is_empty():
		return {"tags": [envelope.tag], "origin": envelope.scope, "status": "inherited"}
	return unresolved


static func source_envelope(o, path: String) -> Dictionary:
	var envelope := {"scope": "", "tag": ""}
	for tag in SOURCE_SCOPES:
		select_envelope(o, path, tag, envelope)
	return envelope


static func select_envelope(o, path: String, tag: String, envelope: Dictionary) -> void:
	for candidate in SOURCE_SCOPES[tag].split(" ", false):
		if o._within_source(path, candidate) and candidate.length() > envelope.scope.length():
			envelope.scope = candidate
			envelope.tag = tag


static func excluded_path(o, path: String) -> bool:
	for excluded in [
		"block-types.alpha.flags",
		"block-types.steam.note",
		"mission-types.steam._shared",
		"mission-types.steam.region-completion-order"
	]:
		if o._within_source(path, excluded):
			return true
	return false


static func metadata_path(path: String) -> bool:
	var fields := path.split(".")
	for i in range(1, fields.size()):
		if metadata_field(fields[0], fields[i]):
			return true
	return false


static func metadata_field(root: String, field: String) -> bool:
	if field.begins_with("$"):
		return true
	return field.begins_with("_") and not (root == "item-types" and field == "_s-additions")


static func nearest_annotation(o, path: String, scope: String) -> Dictionary:
	var current := path
	while true:
		var row: Variant = o._source_value(current)
		if annotated_row(row):
			return annotation_result(o, current, row)
		if scope.is_empty() or current == scope:
			break
		current = current.left(current.rfind("."))
	return {}


static func annotated_row(row: Variant) -> bool:
	return row is Dictionary and (row.has("versions") or row.has("v"))


static func annotation_result(o, path: String, row: Dictionary) -> Dictionary:
	for field in SOURCE_FIELDS:
		if row.has(field) and not o._source_annotation_valid(path, field, row[field]):
			return {"tags": [], "origin": path, "status": "invalid"}
	var tags: Array = row.get("versions", row.get("v"))
	return {
		"tags": tags.duplicate(),
		"origin": path,
		"status": "unresolved" if contextual_tags(path, tags) else "explicit"
	}


static func contextual_tags(path: String, tags: Array) -> bool:
	return SOURCE_CONTEXT_TAGS.has(path) and tags == SOURCE_CONTEXT_TAGS[path]


static func source_annotation_errors(o, value: Variant) -> PackedStringArray:
	if value is Dictionary:
		return dictionary_annotation_errors(o, value)
	if value is Array:
		return array_annotation_errors(o, value)
	return []


static func dictionary_annotation_errors(o, value: Dictionary) -> PackedStringArray:
	var issues := field_annotation_errors(o, value)
	for key in value:
		if key not in SOURCE_FIELDS and annotation_container(value[key]):
			issues.append_array(child_annotation_errors(o, value[key], key))
	return issues


static func field_annotation_errors(o, value: Dictionary) -> PackedStringArray:
	var issues: PackedStringArray = []
	for key in SOURCE_FIELDS:
		if value.has(key) and not o._source_tags_valid(value[key]):
			issues.append(key)
	return issues


static func array_annotation_errors(o, value: Array) -> PackedStringArray:
	var issues: PackedStringArray = []
	for i in value.size():
		if annotation_container(value[i]):
			issues.append_array(child_annotation_errors(o, value[i], i))
	return issues


static func child_annotation_errors(o, value: Variant, prefix: Variant) -> PackedStringArray:
	var issues: PackedStringArray = []
	for issue in o._source_annotation_errors(value):
		issues.append(str(prefix) + "." + issue)
	return issues


static func annotation_container(value: Variant) -> bool:
	return value is Dictionary or value is Array


static func validate_source_annotations(o, value: Variant, path: String) -> void:
	for issue in o._source_annotation_errors(value):
		var full_path: String = path + "." + issue
		var split := full_path.rfind(".")
		if not o._source_annotation_valid(
			full_path.left(split), full_path.substr(split + 1), o._source_value(full_path)
		):
			o.errors.append(full_path + ": malformed source version tags")


static func validate_provenance(o) -> void:
	# Versioned catalogs and mapped envelopes only; unrelated untagged records remain holds.
	for path in (
		("races classes specializations abilities weapon-types materials rarities status-effects creatures landscapes consumables key-items ingredients factions npc-roles terrain-features flora deposits dungeon-types poi-types crafting-stations pet-food.foods pet-food.cut buildings.districts buildings.buildings stats.resources stats.stats economy.shops slash-commands ui.hud ui.screens ui.options ui.camera rulesets")
		. split(" ", false)
	):
		o._validate_source_annotations(o._source_value(path), path)
	for tag in SOURCE_SCOPES:
		for path in SOURCE_SCOPES[tag].split(" ", false):
			o._validate_source_annotations(o._source_value(path), path)
