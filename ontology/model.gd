## Cube World rebuild — typed model derived from ontology/domain/index.md (Godot 4.7, GDScript 2.0).
##
## One inner Resource class per enumerable ontology class; enums for closed vocabularies;
## `Ontology.load_dir()` reads ontology/instances/*.json into typed resources and
## `Ontology.validate()` enforces the load-time constraints of domain/index.md §5.
## Runtime-generated content (terrain, bosses, names…) is NOT modelled here: see §6 generators
## and instances/generators.json, which is loaded as a plain Dictionary.
##
## Sync rule: change domain/index.md first, then this file, then instances/.
extends RefCounted
class_name CubeWorldModel

# --- closed vocabularies -----------------------------------------------------------------

enum Version { A, S, OMEGA, X }  # alpha 0.1.x, steam 1.0, omega (announced), cut
enum Hostility { FRIENDLY_PLAYER = 0, HOSTILE = 1, FRIENDLY = 2, NAMED_FRIENDLY = 3, TARGET = 6 }
enum ClassType { NONE = 0, WARRIOR = 1, RANGER = 2, MAGE = 3, ROGUE = 4 }  # cuwo ids
enum Rarity { WORN = -1, COMMON = 0, UNCOMMON = 1, RARE = 2, EPIC = 3, LEGENDARY = 4, MYTHICAL = 5 }
enum AbilityKind { ACTIVE, PASSIVE, SHARED_PASSIVE, MOVEMENT }
enum CreatureCategory {
	ANIMAL,
	INSECT,
	AQUATIC,
	PLANT_CREATURE,
	MONSTER,
	UNDEAD,
	DEMON,
	ELEMENTAL,
	HUMANOID,
	BOSS_SPECIES,
	STATIC_TARGET,
	UNUSED
}
enum Hands { ONE_HANDED, TWO_HANDED, OFFHAND, NONE }
enum MissionTier { WHITE, GREEN, BLUE, PURPLE, YELLOW }

const VERSION_TAGS := {"A": Version.A, "S": Version.S, "Ω": Version.OMEGA, "X": Version.X}
const MAX_CUBES_1H := 16
const MAX_CUBES_2H := 32
const MP_MAX := 100.0
const SKILL_POINTS_PER_LEVEL := 2
const BLOCK_NATIVE_UNITS := 65536

# --- helpers ---------------------------------------------------------------------------------


## Alpha level → power (+1..+100). domain/index.md §3.5 level-formula.
static func power_for_level(level: int) -> int:
	return int((101.0 * level - 81.0) / (level + 19.0))


## Alpha XP needed to leave `level`. cuwo common.py.
static func xp_to_next(level: int) -> int:
	return int(1050.0 - 1000.0 / (0.05 * (level - 1) + 1.0))


## D19: XP awarded to a player for a kill. design.progression.
static func xp_for_kill(creature_level: int, player_level: int, prog: Dictionary) -> int:
	var r: Array = prog["gap-mult-range"]
	var mult := clampf(
		1.0 + float(prog["gap-per-level"]) * (creature_level - player_level),
		float(r[0]),
		float(r[1])
	)
	return int(xp_to_next(creature_level) * float(prog["kill-fraction"]) * mult)


## Alpha item/character base curve. stats.json#alpha-item-stat-formulas.
static func stat_curve(n: float, rarity: int) -> float:
	return pow(2.0, (1.0 - 1.0 / ((n - 1.0) * 0.05 + 1.0)) * 3.0) * pow(2.0, rarity * 0.25)


# --- resource classes (one per enumerable ontology class) ------------------------------


class Entry:
	extends Resource  # common base: stable id + versions
	@export var id: StringName = &""
	@export var display_name: String = ""
	@export var versions: Array[Version] = []  # confirmed history only
	@export var source_tags: Array[String] = []  # exact qualified/confirmed annotations
	@export var raw: Dictionary = {}  # untouched JSON row for fields not typed yet

	## Qualified references never become confirmed history; validation diagnoses invalid tags.
	static func parse_versions(tags: Variant) -> Array[Version]:
		var out: Array[Version] = []
		for t in tags if tags is Array else []:
			if t is String and VERSION_TAGS.has(t):
				out.append(VERSION_TAGS[t])
		return out


class Race:
	extends Entry
	@export var playable := true
	@export var size_class: StringName = &"normal"


class CharacterClass:
	extends Entry
	@export var id_number: ClassType = ClassType.NONE
	@export var weapon_types: Array[StringName] = []
	@export var armor_material: StringName = &""
	@export var specializations: Array[StringName] = []
	@export var special_attack_mode: StringName = &"charged"  # charged | instant
	@export var hp_mult := 1.0  # D15: stats.json#player-hp class multiplier


class Specialization:
	extends Entry
	@export var character_class: StringName = &""
	@export var index := 0  # cuwo spec byte
	@export var kit_a: Array[StringName] = []
	@export var kit_s: Array[StringName] = []
	@export var passives_a: Array[StringName] = []
	@export var passives_s: Array[StringName] = []


class Ability:
	extends Entry
	@export var kind: AbilityKind = AbilityKind.ACTIVE
	@export var owner: Variant  # class / spec id, "all", or Array
	@export var input: Dictionary = {}  # {"A": "1", "S": "r"}
	@export var cost: Dictionary = {}
	@export var cooldown_s: Variant
	@export var duration_s: Variant
	@export var effect: String = ""
	@export var applies: Array[StringName] = []  # status-effect ids
	@export var alpha_ability_id := -1
	@export var alpha_tree: Dictionary = {}  # {column, rank, needs, skill-slot}


class WeaponType:
	extends Entry
	@export var subtype := -1
	@export var character_class: StringName = &""
	@export var hands: Hands = Hands.NONE
	@export var damage_k := 0
	@export var cube_capacity := 0
	@export var combo_cap := -1  # -1 = undocumented


class MaterialDef:
	extends Entry  # MaterialDef: "Material" hides the native class
	@export var material_id := -1
	@export var kind: StringName = &""
	@export var obtainable := true


class RarityDef:
	extends Entry
	@export var index: Rarity = Rarity.COMMON
	@export var color: StringName = &""
	@export var stars := 0
	@export var gem: StringName = &""
	@export var named := false


class Creature:
	extends Entry
	## Legacy API name: numeric source entity ID (alpha or post-alpha), -1 = unrecorded.
	## JSON `aid` and this field keep their names; an ID alone does not establish version provenance.
	@export var alpha_entity_id := -1
	@export var family: StringName = &""
	@export var category: CreatureCategory = CreatureCategory.ANIMAL
	@export var hostility: StringName = &"P"  # P N H V F (+ notes)
	@export var lands: Array[StringName] = []
	@export var group_size := Vector2i(1, 1)
	@export var tame_food: StringName = &""  # "" = untameable
	@export var rideable := false
	@export var boss_species := false
	@export var boss_capable := false
	@export var drops: Array[StringName] = []
	@export var combat_role: StringName = &""  # D26: melee|ranged|mage|any-class|"" (parsed from `role`)


class PetFood:
	extends Entry
	@export var subtype := -1  # numeric source entity ID, including post-alpha
	@export var tames: StringName = &""  # stable ontology creature ID
	@export var rideable := false
	@export var shop := false


class Landscape:
	extends Entry
	@export var climate: Dictionary = {}
	@export var hazards: Array[StringName] = []
	@export var dungeon_types: Array[StringName] = []
	@export var style: String = ""
	@export var gen: Dictionary = {}  # D12: relief, base, surface, top, cliff


class StatusEffect:
	extends Entry
	@export var kind: StringName = &""
	@export var sources: Array[StringName] = []
	@export var countered_by: Array[StringName] = []


class Consumable:
	extends Entry
	@export var kind: StringName = &""  # food | potion | elixir | beverage | bomb
	@export var use: StringName = &""  # sit | channel | throw
	@export var heal_mult := 0
	@export var duration_s := 0
	@export var recipe: Dictionary = {}
	@export var station: String = ""


class KeyItem:
	extends Entry
	@export var group: StringName = &""


class Ruleset:
	extends Entry
	@export var flags: Dictionary = {}
	@export var is_default := false


# --- loader + constraint checker -----------------------------------------------------------


class Ontology:
	extends RefCounted
	var races := {}
	var classes := {}
	var specs := {}
	var abilities := {}
	var weapon_types := {}
	var materials := {}
	var rarities := {}
	var creatures := {}
	var pet_foods := {}
	var landscapes := {}
	var status_effects := {}
	var consumables := {}
	var key_items := {}
	var rulesets := {}
	var configs := {}  # every other instances file, verbatim (ui, keybinds, generators…)
	var errors: PackedStringArray = []

	static func load_dir(dir_path: String) -> Ontology:
		var o := Ontology.new()
		var dir := DirAccess.open(dir_path)
		if dir == null:
			o.errors.append("cannot open %s" % dir_path)
			return o
		for file in dir.get_files():
			if not file.ends_with(".json"):
				continue
			var text := FileAccess.get_file_as_string(dir_path.path_join(file))
			var data: Variant = JSON.parse_string(text)
			if data == null:
				o.errors.append("invalid JSON: %s" % file)
				continue
			o._ingest(file.get_basename(), data)
		return o

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

	static func _source_tags_valid(tags: Variant) -> bool:
		if not tags is Array or tags.is_empty():
			return false
		for tag in tags:
			if not tag is String or tag not in SOURCE_TAGS:
				return false
		return true

	static func _source_annotation_valid(path: String, field: String, tags: Variant) -> bool:
		return (
			_source_tags_valid(tags)
			or (
				field == "versions"
				and tags is Array
				and SOURCE_CONTEXT_TAGS.has(path)
				and tags == SOURCE_CONTEXT_TAGS[path]
			)
		)

	func _source_value(path: String) -> Variant:
		var value: Variant = configs
		for field in path.split("."):
			if value is Dictionary:
				if not value.has(field):
					return null
				value = value[field]
			elif value is Array and field.is_valid_int():
				var index := int(field)
				if index < 0 or index >= value.size():
					return null
				value = value[index]
			else:
				return null
		return value

	static func _within_source(path: String, scope: String) -> bool:
		return path == scope or path.begins_with(scope + ".")

	## Resolve a raw fact's exact annotations and origin; empty tags mean unresolved, not A+S.
	## No mutation of raw source text, no numeric-ID or referenced-definition ancestry.
	func source_at(path: String) -> Dictionary:
		var unresolved := {"tags": [], "origin": "", "status": "unresolved"}
		if _source_value(path) == null:
			return unresolved
		var scope := ""
		var inherited := ""
		for tag in SOURCE_SCOPES:
			for candidate in SOURCE_SCOPES[tag].split(" ", false):
				if _within_source(path, candidate) and candidate.length() > scope.length():
					scope = candidate
					inherited = tag
		# Table metadata is not an instance. S additions are the sole mapped underscore scope.
		for excluded in [
			"block-types.alpha.flags",
			"block-types.steam.note",
			"mission-types.steam._shared",
			"mission-types.steam.region-completion-order"
		]:
			if _within_source(path, excluded):
				return unresolved
		var fields := path.split(".")
		for i in range(1, fields.size()):
			if (
				fields[i].begins_with("$")
				or (
					fields[i].begins_with("_")
					and not (fields[0] == "item-types" and fields[i] == "_s-additions")
				)
			):
				return unresolved
		if scope == "item-types" and path == scope:
			return unresolved  # The mixed parent is not an alpha content record.
		var current := path
		while true:
			var row: Variant = _source_value(current)
			if row is Dictionary and (row.has("versions") or row.has("v")):
				for field in SOURCE_FIELDS:
					if row.has(field) and not _source_annotation_valid(current, field, row[field]):
						return {"tags": [], "origin": current, "status": "invalid"}
				var tags: Array = row.get("versions", row.get("v"))
				var contextual: bool = (
					SOURCE_CONTEXT_TAGS.has(current) and tags == SOURCE_CONTEXT_TAGS[current]
				)
				return {
					"tags": tags.duplicate(),
					"origin": current,
					"status": "unresolved" if contextual else "explicit"
				}
			if scope.is_empty() or current == scope:
				break
			current = current.left(current.rfind("."))
		if not scope.is_empty():
			return {"tags": [inherited], "origin": scope, "status": "inherited"}
		return unresolved

	# Build diagnostic paths only for failures; validation never caches mutable raw results.
	func _source_annotation_errors(value: Variant) -> PackedStringArray:
		var issues: PackedStringArray = []
		if value is Dictionary:
			for key in SOURCE_FIELDS:
				if value.has(key) and not _source_tags_valid(value[key]):
					issues.append(key)
			for key in value:
				if key not in SOURCE_FIELDS and (value[key] is Dictionary or value[key] is Array):
					for issue in _source_annotation_errors(value[key]):
						issues.append(str(key) + "." + issue)
		elif value is Array:
			for i in value.size():
				if value[i] is Dictionary or value[i] is Array:
					for issue in _source_annotation_errors(value[i]):
						issues.append(str(i) + "." + issue)
		return issues

	func _validate_source_annotations(value: Variant, path: String) -> void:
		for issue in _source_annotation_errors(value):
			var full_path := path + "." + issue
			var split := full_path.rfind(".")
			if not _source_annotation_valid(
				full_path.left(split), full_path.substr(split + 1), _source_value(full_path)
			):
				errors.append(full_path + ": malformed source version tags")

	func _validate_provenance() -> void:
		# Versioned catalogs / explicitly annotated historical presentation facts, not arbitrary
		# owner config or release-history keys. Untagged records outside mapped envelopes stay holds.
		for path in (
			("races classes specializations abilities weapon-types materials rarities status-effects creatures landscapes consumables key-items ingredients factions npc-roles terrain-features flora deposits dungeon-types poi-types crafting-stations pet-food.foods pet-food.cut buildings.districts buildings.buildings stats.resources stats.stats economy.shops slash-commands ui.hud ui.screens ui.options ui.camera rulesets")
			. split(" ", false)
		):
			_validate_source_annotations(_source_value(path), path)
		for tag in SOURCE_SCOPES:
			for path in SOURCE_SCOPES[tag].split(" ", false):
				_validate_source_annotations(_source_value(path), path)

	# §5's finite heterogeneous input inventory, not a schema inferred from current JSON.
	const REQUIRED_INPUTS := {
		"catalog":
		"weapon-types materials item-types rarities status-effects creatures landscapes terrain-features flora deposits dungeon-types poi-types factions consumables ingredients crafting-stations key-items npc-roles slash-commands",
		"object":
		"stats.resources stats.stats stats.alpha-item-stat-formulas stats.alpha-character-formulas equipment-slots.extra creature-families.beetles creature-families.runners creature-families.slimes creature-families.alpacas creature-families.dogs creature-families.cats creature-families.golems creature-families.trolls creature-families.skeletons creature-families.sprouts creature-families.guardians creature-families.fish creature-families.landscape-rosters creature-families.forest-dungeon-rosters pet-food.foods pet-food.cut rarities.mob-strength-tiers-s rarities.alpha-relative-colors status-effects.ability-buffs key-items.counts-per-land-s key-items.special-accessories-x consumables.rules factions.realm-name-examples mission-types.alpha mission-types.steam mission-types.steam._shared block-types.alpha block-types.steam block-types.scale block-types.cub-format block-types.alpha.flags static-entities.by-id static-entities.behaviour static-entities.candles recipes.gear-armor-quantities recipes.gear-weapons recipes.refining recipes.recipe-sources recipes.customization recipes.cooking recipes.alchemy buildings.districts buildings.buildings buildings.settlement-styles buildings.population buildings.map-visibility economy.currency economy.incomes economy.prices economy.shops economy.rules economy.loot rulesets.ruleset-hybrid rulesets.ruleset-hybrid.flags keybinds.hybrid controller-profiles.android ui.hud ui.screens ui.options ui.camera slash-commands.chat-rules generators.world-scales generators.seed generators.time generators.climate generators.land generators.terrain generators.settlement generators.dungeon generators.spawns generators.boss generators.names generators.item generators.realm generators.npc-appearance generators.schedule generators.key-items-s generators.coarse-map-omega generators.network-alpha generators.design versions.alpha-to-steam-delta versions.reception generators.design.enemy-level generators.design.enemy-hp generators.design.terrain generators.design.climate generators.design.names generators.design.spawns generators.design.skill-point generators.design.abilities generators.design.resources generators.design.special-attack generators.design.status-effects generators.design.progression generators.design.crit generators.design.movement generators.design.camera generators.design.combat generators.design.defence generators.design.movesets generators.design.creature-roles generators.design.feel generators.design.frame-budget generators.design.prices generators.design.stack-cap generators.design.loot generators.design.starting-inventory generators.design.settlement generators.design.gear-hp generators.design.initial-encounters generators.design.artifact generators.design.artifacts-per-land generators.design.circle-of-power generators.design.recipes generators.design.pvp generators.design.time generators.design.terrain.height generators.design.terrain.heightfield generators.design.spawns.ai generators.design.names.land-suffix generators.design.resources.mp generators.design.movement.stamina generators.design.defence.dodge generators.design.defence.block generators.design.defence.stealth generators.design.defence.enemy-hit generators.design.creature-roles.any-class generators.design.creature-roles.melee generators.design.creature-roles.ranged generators.design.creature-roles.mage generators.design.creature-roles.species generators.design.feel.hit-stop generators.design.feel.shake generators.design.feel.numbers generators.design.feel.impact generators.design.feel.trail generators.design.feel.level-up generators.design.feel.events generators.design.feel.sfx generators.design.feel.numbers.colours generators.design.settlement.npc generators.design.settlement.npc.roles generators.design.settlement.style-by-landscape generators.design.settlement.style-colors generators.design.settlement.shop generators.design.settlement.inn generators.design.settlement.trainer generators.design.loot.coins generators.design.loot.rarity-weights generators.design.loot.gear-kinds generators.design.loot.ground",
		"array": "equipment-slots.slots versions.timeline generators.design.climate.rules",
		"strings":
		"equipment-slots.rules pet-food.rules pet-food.shop-set status-effects.not-found mission-types.steam.region-completion-order static-entities.s-additions recipes.crafting-tabs-a affixes.common affixes.uncommon affixes.rare affixes.epic affixes.legendary affixes.name-forms audio.sfx-alpha-ids slash-commands.cuwo-server-commands generators.design.names.syllables generators.design.abilities.runtimes generators.design.movesets.kinds generators.design.stack-cap.stackable generators.design.loot.consumable-pool generators.design.settlement.buildings",
		"string":
		"generators.design.item-stat-curve generators.design.block-reward generators.design.regeneration generators.loot generators.level-formulas-alpha generators.design.creature-roles.default",
		"bool": "rulesets.ruleset-hybrid.default"
	}
	const CATALOG_CONFIG := {
		"rarities": ["mob-strength-tiers-s", "alpha-relative-colors"],
		"status-effects": ["ability-buffs", "not-found"],
		"factions": ["realm-name-examples"],
		"consumables": ["rules"],
		"key-items": ["counts-per-land-s", "special-accessories-x"],
		"npc-roles": ["dialogue-corpus"],
		"slash-commands": ["cuwo-server-commands", "chat-rules"]
	}

	static func _object(value: Variant) -> Dictionary:
		return value if value is Dictionary else {}

	static func _array(value: Variant) -> Array:
		return value if value is Array else []

	func _input_shape(value: Variant, kind: String, path: String) -> bool:
		var valid := false
		match kind:
			"object", "catalog":
				valid = value is Dictionary
			"array":
				valid = value is Array
			"strings":
				valid = _identity_strings(value)
			"string":
				valid = value is String
			"bool":
				valid = value is bool
			"number":
				valid = (value is int or value is float) and is_finite(float(value))
			"pair":
				valid = value is Array and value.size() == 2
				if valid:
					for item in value:
						if (not item is int and not item is float) or not is_finite(float(item)):
							valid = false
			"colour":
				valid = value is Array and value.size() == 3
				if valid:
					for item in value:
						if (
							(not item is int and not item is float)
							or not is_finite(float(item))
							or item < 0
							or item > 1
						):
							valid = false
			"palette":
				valid = _identity_strings(value) and value.size() == 2
				if valid:
					for item in value:
						if not Color.html_is_valid(item):
							valid = false
		if not valid:
			errors.append(
				path.trim_prefix("generators.") + ": required " + kind + " missing or malformed"
			)
		return valid

	func _required_path(path: String, kind: String) -> bool:
		var value: Variant = configs
		for field in path.split("."):
			value = value.get(field) if value is Dictionary else null
		return _input_shape(value, kind, path)

	func _fields_valid(row: Variant, path: String, fields: Dictionary) -> bool:
		if not _input_shape(row, "object", path):
			return false
		var valid := true
		for kind in fields:
			for field in str(fields[kind]).split(" ", false):
				if not _input_shape(row.get(field), kind, path + "." + field):
					valid = false
		return valid

	const TYPED_STRINGS := {
		"materials": ["kind"],
		"rarities": ["color", "gem"],
		"creatures": ["family", "cat", "h", "tame", "role"],
		"pet-food": ["tames"],
		"landscapes": ["style"],
		"status-effects": ["kind"],
		"consumables": ["kind", "use", "station"],
		"key-items": ["group"]
	}
	const TYPED_NUMBERS := {
		"weapon-types": ["subtype", "damage-k", "combo-cap"],
		"materials": ["id"],
		"rarities": ["index", "stars"],
		"creatures": ["aid"],
		"pet-food": ["id"],
		"consumables": ["heal-mult", "duration-s"]
	}
	# These historical fields already have explicit null handling during typed ingestion.
	const NULLABLE_NUMBERS := {
		"weapon-types": ["subtype", "combo-cap"],
		"materials": ["id"],
		"rarities": ["stars"],
		"creatures": ["aid"]
	}
	const TYPED_ARRAYS := {
		"creatures": ["lands", "drops"],
		"landscapes": ["hazards"],
		"status-effects": ["sources", "countered-by"]
	}
	const TYPED_BOOLS := {
		"materials": ["obtainable"],
		"rarities": ["named"],
		"creatures": ["ride", "boss", "bossable"],
		"pet-food": ["rideable", "shop"]
	}
	const TYPED_OBJECTS := {
		"landscapes": ["climate", "gen"], "rulesets": ["flags"], "consumables": ["recipe"]
	}

	func _typed_fields_valid(name: String, row: Dictionary, path: String) -> bool:
		var start := errors.size()
		var strings: Array = TYPED_STRINGS.get(name, [])
		for field in strings:
			if row.has(field) and row[field] != null:
				_input_shape(row[field], "string", path + "." + field)
		for field in TYPED_BOOLS.get(name, []):
			if row.has(field):
				_input_shape(row[field], "bool", path + "." + field)
		var numbers: Array = TYPED_NUMBERS.get(name, [])
		for field in numbers:
			if row.has(field):
				if row[field] == null and field in NULLABLE_NUMBERS.get(name, []):
					continue
				_input_shape(row[field], "number", path + "." + field)
		var arrays: Array = TYPED_ARRAYS.get(name, [])
		for field in arrays:
			if row.has(field):
				_input_shape(row[field], "strings", path + "." + field)
		if name == "creatures" and row.get("group") != null:
			_input_shape(row.group, "pair", path + ".group")
		for field in TYPED_OBJECTS.get(name, []):
			if row.has(field):
				_input_shape(row[field], "object", path + "." + field)
		if name == "rulesets" and row.has("default"):
			_input_shape(row.default, "bool", path + ".default")
		return errors.size() == start

	func _typed_rows(name: String, data: Variant) -> Dictionary:
		var out := {}
		var path := name + (".foods" if name == "pet-food" else "")
		for id in _rows(data):
			if _typed_fields_valid(name, data[id], path + "." + str(id)):
				out[id] = data[id]
		return out

	func _optional_fields_valid(row: Dictionary, path: String, fields: Dictionary) -> bool:
		var valid := true
		for kind in fields:
			for field in str(fields[kind]).split(" ", false):
				if row.has(field) and not _input_shape(row[field], kind, path + "." + field):
					valid = false
		return valid

	func _ability_fields_valid(row: Dictionary, path: String) -> bool:
		var valid := _optional_fields_valid(
			row,
			path,
			{
				"object": "cost throw strike",
				"number": "cooldown-s distance radius duration-s cast-s heal-pct stealth-per-s"
			}
		)
		if row.get("runtime") == "channel":
			for field in ["turns-per-s", "drain-per-s"]:
				if not _input_shape(row.get(field), "number", path + "." + field):
					valid = false
				elif float(row[field]) < 0.0 or (field == "turns-per-s" and row[field] == 0):
					errors.append(
						(
							path
							+ "."
							+ field
							+ ": must be "
							+ ("> 0" if field == "turns-per-s" else ">= 0")
						)
					)
					valid = false
		if row.get("cost") is Dictionary:
			for key in row.cost:
				if (
					not (row.cost[key] is String and row.cost[key] == "all")
					and not _input_shape(row.cost[key], "number", path + ".cost." + str(key))
				):
					valid = false
		if (
			row.get("strike") is Dictionary
			and not _fields_valid(row.strike, path + ".strike", {"number": "radius"})
		):
			valid = false
		if row.get("throw") is Dictionary and not _moveset_fields_valid(row.throw, path + ".throw"):
			valid = false
		if not _moveset_fields_valid(row, path):
			valid = false
		return valid

	func _role_fields_valid(row: Dictionary, path: String) -> bool:
		var valid := _optional_fields_valid(
			row,
			path,
			{
				"number": "range keep-away windup-s cooldown-s damage-mult",
				"object": "shot",
				"strings": "applies",
				"string": "kind sfx color"
			}
		)
		if row.get("shot") is Dictionary and not _moveset_fields_valid(row.shot, path + ".shot"):
			valid = false
		return valid

	func _validate_required_inputs() -> void:
		for kind in REQUIRED_INPUTS:
			for path in str(REQUIRED_INPUTS[kind]).split(" "):
				_required_path(path, kind)
		for name in str(REQUIRED_INPUTS.catalog).split(" "):
			var catalog := _object(configs.get(name))
			var count := 0
			for id in catalog:
				if (
					str(id).begins_with("_")
					or str(id).begins_with("$")
					or id in CATALOG_CONFIG.get(name, [])
				):
					continue
				count += 1
				var path: String = name + "." + str(id)
				if _input_shape(catalog[id], "object", path):
					if catalog[id].is_empty():
						errors.append(path + ": empty content row")
					_typed_fields_valid(name, catalog[id], path)
			if count == 0:
				errors.append(name + ": required catalog content missing")
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
			var parts := str(path).split(".")
			var rows := _object(_object(configs.get(parts[0])).get(parts[1]))
			var count := 0
			for id in rows:
				if str(id).begins_with("_") or id == "region-completion-order":
					continue
				count += 1
				if _input_shape(rows[id], "object", path + "." + str(id)):
					if rows[id].is_empty():
						errors.append(path + "." + str(id) + ": empty content row")
					if path == "pet-food.foods":
						_typed_fields_valid("pet-food", rows[id], path + "." + str(id))
			if count == 0:
				errors.append(path + ": required catalog content missing")
		_validate_mapped_tables()

	func _validate_mapped_tables() -> void:
		var families := _object(configs.get("creature-families"))
		for id in (
			"beetles runners slimes alpacas dogs cats golems trolls skeletons sprouts guardians fish"
			. split(" ")
		):
			var path := "creature-families." + id
			var row := _object(families.get(id))
			if _fields_valid(families.get(id), path, {"strings": "members"}):
				for cid in row.members:
					if not creatures.has(cid):
						errors.append(path + ".members: unknown creature " + cid)
			if row.has("traits"):
				_input_shape(row.traits, "strings", path + ".traits")
		for land in _object(families.get("landscape-rosters")):
			_input_shape(
				families["landscape-rosters"][land],
				"strings",
				"creature-families.landscape-rosters." + str(land)
			)
		for id in _object(families.get("forest-dungeon-rosters")):
			_fields_valid(
				families["forest-dungeon-rosters"][id],
				"creature-families.forest-dungeon-rosters." + str(id),
				{"strings": "members", "string": "boss"}
			)
		# Forest research tokens include races/families and unresolved singular beetle; shape only.
		for version in ["alpha", "steam"]:
			var rows := _object(_object(configs.get("block-types")).get(version))
			var count := 0
			for id in rows:
				if id in ["flags", "note"]:
					continue
				count += 1
				var path: String = "block-types." + version + "." + str(id)
				if not str(id).is_valid_int():
					errors.append(path + ": numeric table key required")
				if version == "alpha":
					_fields_valid(rows[id], path, {"string": "id", "bool": "solid"})
				else:
					_input_shape(rows[id], "string", path)
			if count == 0:
				errors.append("block-types." + version + ": required numeric table content missing")
		if _object(_object(configs.get("static-entities")).get("by-id")).is_empty():
			errors.append("static-entities.by-id: required numeric table content missing")
		for id in _object(_object(configs.get("static-entities")).get("by-id")):
			if not str(id).is_valid_int():
				errors.append("static-entities.by-id." + str(id) + ": numeric key required")
			_input_shape(
				configs["static-entities"]["by-id"][id],
				"string",
				"static-entities.by-id." + str(id)
			)
		var buffs := _object(_object(configs.get("status-effects")).get("ability-buffs"))
		if _input_shape(buffs.get("list"), "strings", "status-effects.ability-buffs.list"):
			for id in buffs.list:
				if not abilities.has(id.split(" ")[0]):
					errors.append("status-effects.ability-buffs.list: unknown ability " + id)
		_validate_settlement_references()
		var generators := _object(configs.get("generators"))
		var design := _object(generators.get("design"))
		var ability_rows := _object(design.get("abilities"))
		for id in ability_rows:
			if str(id).begins_with("_") or id in ["runtimes", "dash-speed", "all-min"]:
				continue
			_input_shape(ability_rows[id], "object", "design.abilities." + str(id))
		var names := _object(design.get("names"))
		for land in _object(names.get("land-suffix")):
			_input_shape(
				names["land-suffix"][land], "strings", "design.names.land-suffix." + str(land)
			)
		for rule in _array(_object(design.get("climate")).get("rules")):
			var path := "design.climate.rules"
			if not _identity_strings(rule) or rule.size() != 2:
				errors.append(path + ": [landscape-id, expression-string] required")
				continue
			if not landscapes.has(rule[0]):
				errors.append(path + ": unknown landscape " + rule[0])
			else:
				_fields_valid(
					landscapes[rule[0]].raw.get("gen"),
					"landscapes." + str(rule[0]) + ".gen",
					{"number": "relief base", "string": "surface top cliff"}
				)
			var expression := Expression.new()
			# Same input names as WorldGen.FIELD_NAMES; ontology never depends on game/.
			if expression.parse(rule[1], ["temp", "humidity", "continent", "relief", "roll"]) != OK:
				errors.append(path + ": invalid climate expression " + rule[1])

	func _validate_settlement_references() -> void:
		var cfg := _object(configs.get("buildings"))
		var buildings := _object(cfg.get("buildings"))
		var styles := _object(cfg.get("settlement-styles"))
		for id in buildings:
			var row := _object(buildings[id])
			for field in ["roles", "stations"]:
				if not row.has(field):
					continue
				var path: String = "buildings.buildings." + str(id) + "." + field
				if not _input_shape(row[field], "strings", path):
					continue
				var target := _object(
					configs.get("npc-roles" if field == "roles" else "crafting-stations")
				)
				for ref in row[field]:
					if (
						not target.get(ref) is Dictionary
						or (field == "roles" and ref == "dialogue-corpus")
					):
						errors.append(path + ": unknown reference " + ref)
		for id in styles:
			var path: String = "buildings.settlement-styles." + str(id)
			if _fields_valid(styles[id], path, {"strings": "lands"}):
				for land in styles[id].lands:
					if not landscapes.has(land):
						errors.append(path + ".lands: unknown landscape " + land)
		for id in landscapes:
			var raw: Dictionary = landscapes[id].raw
			if not raw.has("style"):
				continue
			var style: Variant = raw.style
			var aliases := {
				"log-houses": "log",
				"jungle (orange roofs)": "jungle",
				"lava-city": "lava",
				"ocean-city (islands)": "ocean",
				"undead (dark grey, pointed roofs, green lights)": "undead"
			}
			# Historical descriptors stay verbatim; runtime uses design.style-by-landscape.
			if not style is String:
				errors.append("landscapes." + str(id) + ".style: string required")
				continue
			for token in style.split("|"):
				var key: String = token.strip_edges()
				if key.is_empty() or not styles.has(aliases.get(key, key)):
					errors.append("landscapes." + str(id) + ".style: unknown style " + key)
		var st := _object(
			_object(_object(configs.get("generators")).get("design")).get("settlement")
		)
		var role_map := _object(_object(st.get("npc")).get("roles"))
		for id in role_map:
			var path: String = "design.settlement.npc.roles." + str(id)
			var role: Variant = role_map[id]
			if not buildings.has(id) or id not in _array(st.get("buildings")):
				errors.append(path + ": service building must occur in settlement.buildings")
			if not role is String or role not in _array(_object(buildings.get(id)).get("roles")):
				errors.append(path + ": role must be offered by building")
		for land in _object(st.get("style-by-landscape")):
			var style: Variant = st["style-by-landscape"][land]
			if not landscapes.has(land) or not style is String or not styles.has(style):
				errors.append(
					(
						"design.settlement.style-by-landscape."
						+ str(land)
						+ ": unknown landscape or style"
					)
				)
		for style in _object(st.get("style-colors")):
			_input_shape(
				st["style-colors"][style], "palette", "design.settlement.style-colors." + str(style)
			)

	func _rows(data: Variant) -> Dictionary:  # skip "$schema", "_doc", "_x" keys
		var out := {}
		if not data is Dictionary:
			return out
		for k in data:
			if str(k).begins_with("$") or str(k).begins_with("_"):
				continue
			if data[k] is Dictionary:
				out[k] = data[k]
		return out

	func _fill(e: Entry, id: String, row: Dictionary) -> void:
		e.id = StringName(id)
		e.display_name = str(row.get("name", id))
		var tags: Variant = row.get("versions", row.get("v", []))
		e.versions = Entry.parse_versions(tags)
		if _source_tags_valid(tags):
			e.source_tags.assign(tags)
		e.raw = row

	func _ingest(name: String, data: Variant) -> void:
		configs[name] = data  # Retain every raw boundary; modeled rows never replace malformed input.
		if not data is Dictionary:
			return
		match name:
			"races":
				for id in _rows(data):
					var r := Race.new()
					_fill(r, id, data[id])
					r.playable = data[id].get("playable") is bool and data[id]["playable"]
					r.size_class = StringName(str(data[id].get("size-class", "normal")))
					races[id] = r
			"classes":
				for id in _rows(data):
					var issues := _identity_row_errors(name, data[id], name + "." + str(id))
					if not issues.is_empty():
						errors.append_array(issues)
						continue
					var c := CharacterClass.new()
					_fill(c, id, data[id])
					c.id_number = int(data[id].get("id-number", 0)) as ClassType
					c.weapon_types.assign(data[id].get("weapon-types", []))
					c.armor_material = StringName(str(data[id].get("armor-material", "")))
					c.specializations.assign(data[id].get("specializations", []))
					c.special_attack_mode = StringName(
						str(data[id].get("special-attack-mode", "charged"))
					)
					c.hp_mult = float(data[id].get("hp-mult", 1.0))
					classes[id] = c
			"specializations":
				for id in _rows(data):
					var issues := _identity_row_errors(name, data[id], name + "." + str(id))
					if not issues.is_empty():
						errors.append_array(issues)
						continue
					var s := Specialization.new()
					_fill(s, id, data[id])
					s.character_class = StringName(str(data[id].get("class", "")))
					s.index = int(data[id].get("index", 0))
					s.kit_a.assign(data[id].get("kit", {}).get("A", []))
					s.kit_s.assign(data[id].get("kit", {}).get("S", []))
					s.passives_a.assign(data[id].get("passives", {}).get("A", []))
					s.passives_s.assign(data[id].get("passives", {}).get("S", []))
					specs[id] = s
			"abilities":
				for id in _rows(data):
					var issues := _identity_row_errors(name, data[id], name + "." + str(id))
					if not issues.is_empty():
						errors.append_array(issues)
						continue
					var a := Ability.new()
					_fill(a, id, data[id])
					a.kind = (
						{
							"active": AbilityKind.ACTIVE,
							"passive": AbilityKind.PASSIVE,
							"shared-passive": AbilityKind.SHARED_PASSIVE,
							"movement": AbilityKind.MOVEMENT
						}
						. get(str(data[id].get("kind", "active")), AbilityKind.ACTIVE)
					)
					a.owner = data[id].get("owner")
					a.input = data[id].get("input", {})
					a.cost = data[id].get("cost", {})
					a.cooldown_s = data[id].get("cooldown-s")
					a.duration_s = data[id].get("duration-s")
					a.effect = str(data[id].get("effect", ""))
					a.applies.assign(data[id].get("applies", []))
					a.alpha_ability_id = int(data[id].get("alpha-id", -1))
					a.alpha_tree = data[id].get("alpha-tree", {})
					abilities[id] = a
			"weapon-types":
				for id in _typed_rows(name, data):
					var w := WeaponType.new()
					_fill(w, id, data[id])
					w.subtype = int(
						data[id].get("subtype", -1) if data[id].get("subtype") != null else -1
					)
					w.character_class = StringName(str(data[id].get("class", "")))
					var raw_h: Variant = data[id].get("hands")
					var h: String = raw_h if raw_h is String else ""
					w.hands = (
						Hands.TWO_HANDED
						if h == "2h"
						else (
							Hands.OFFHAND
							if h == "offhand"
							else (
								Hands.ONE_HANDED
								if h == "1h" or h == "1h dual (need two)"
								else Hands.NONE
							)
						)
					)
					w.damage_k = int(data[id].get("damage-k", 0))
					var capacity: Variant = data[id].get("cube-capacity")
					w.cube_capacity = int(capacity) if capacity is int or capacity is float else 0
					w.combo_cap = int(
						data[id].get("combo-cap", -1) if data[id].get("combo-cap") != null else -1
					)
					weapon_types[id] = w
			"materials":
				for id in _typed_rows(name, data):
					var m := MaterialDef.new()
					_fill(m, id, data[id])
					m.material_id = int(
						data[id].get("id", -1) if data[id].get("id") != null else -1
					)
					m.kind = StringName(str(data[id].get("kind", "")))
					m.obtainable = bool(data[id].get("obtainable", true))
					materials[id] = m
			"rarities":
				for id in _typed_rows(name, data):
					if not data[id].has("index"):
						continue
					var r := RarityDef.new()
					_fill(r, id, data[id])
					r.index = int(data[id]["index"]) as Rarity
					r.color = StringName(str(data[id].get("color", "")))
					r.stars = int(data[id].get("stars", 0) if data[id].get("stars") != null else 0)
					r.gem = StringName(
						str(data[id].get("gem", "") if data[id].get("gem") != null else "")
					)
					r.named = bool(data[id].get("named", false))
					rarities[id] = r
			"creatures":
				for id in _typed_rows(name, data):
					var c := Creature.new()
					_fill(c, id, data[id])
					c.alpha_entity_id = int(
						data[id].get("aid", -1) if data[id].get("aid") != null else -1
					)
					c.family = StringName(str(data[id].get("family", "")))
					c.category = (
						{
							"animal": CreatureCategory.ANIMAL,
							"insect": CreatureCategory.INSECT,
							"aquatic": CreatureCategory.AQUATIC,
							"plant-creature": CreatureCategory.PLANT_CREATURE,
							"monster": CreatureCategory.MONSTER,
							"undead": CreatureCategory.UNDEAD,
							"demon": CreatureCategory.DEMON,
							"elemental": CreatureCategory.ELEMENTAL,
							"humanoid": CreatureCategory.HUMANOID,
							"boss-species": CreatureCategory.BOSS_SPECIES,
							"static-target": CreatureCategory.STATIC_TARGET
						}
						. get(str(data[id].get("cat", "unused")), CreatureCategory.UNUSED)
					)
					c.hostility = StringName(str(data[id].get("h", "P")).left(1))  # "P (rarely H)" → base letter
					c.lands.assign(data[id].get("lands", []))
					var g: Variant = data[id].get("group")
					if g is Array and g.size() == 2:
						c.group_size = Vector2i(int(g[0]), int(g[1]))
					c.tame_food = StringName(
						str(data[id].get("tame", "") if data[id].get("tame") != null else "")
					)
					c.rideable = data[id].get("ride", false) == true
					c.boss_species = bool(data[id].get("boss", false))
					c.boss_capable = bool(data[id].get("bossable", false))
					c.drops.assign(data[id].get("drops", []))
					var role_str := str(
						data[id].get("role", "") if data[id].get("role") != null else ""
					)  # D26: first keyword wins
					if role_str.contains("any-class"):
						c.combat_role = &"any-class"
					elif role_str.contains("ranged"):
						c.combat_role = &"ranged"
					elif role_str.contains("mage"):
						c.combat_role = &"mage"
					elif role_str.contains("melee"):
						c.combat_role = &"melee"
					else:
						c.combat_role = &""
					creatures[id] = c
			"pet-food":
				for id in _typed_rows(name, data.get("foods")):
					var row: Dictionary = data["foods"][id]
					var f := PetFood.new()
					_fill(f, id, row)
					f.subtype = int(row.get("id", -1))
					f.tames = StringName(str(row.get("tames", "")))
					f.rideable = row.get("rideable", false) == true
					f.shop = bool(row.get("shop", false))
					pet_foods[id] = f
			"landscapes":
				for id in _typed_rows(name, data):
					var l := Landscape.new()
					_fill(l, id, data[id])
					l.climate = data[id].get("climate", {})
					l.hazards.assign(data[id].get("hazards", []))
					var dungeons: Variant = data[id].get("dungeons", [])
					if dungeons is Array:
						for dungeon in dungeons:
							if dungeon is String:
								l.dungeon_types.append(StringName(dungeon))
					# Malformed references stay in raw for cumulative validation.
					l.style = str(data[id].get("style", ""))
					l.gen = data[id].get("gen", {})
					landscapes[id] = l
			"status-effects":
				for id in _typed_rows(name, data):
					if not data[id].has("kind"):
						continue
					var s := StatusEffect.new()
					_fill(s, id, data[id])
					s.kind = StringName(str(data[id]["kind"]))
					s.sources.assign(data[id].get("sources", []))
					s.countered_by.assign(data[id].get("countered-by", []))
					status_effects[id] = s
			"consumables":
				for id in _typed_rows(name, data):
					if not data[id].has("kind"):
						continue
					var c := Consumable.new()
					_fill(c, id, data[id])
					c.kind = StringName(str(data[id]["kind"]))
					c.use = StringName(str(data[id].get("use", "")))
					c.heal_mult = int(data[id].get("heal-mult", 0))
					c.duration_s = int(data[id].get("duration-s", 0))
					c.recipe = (
						data[id].get("recipe", {}) if data[id].get("recipe") is Dictionary else {}
					)
					c.station = str(data[id].get("station", ""))
					consumables[id] = c
			"key-items":
				for id in _typed_rows(name, data):
					if not data[id].has("group"):
						continue
					var k := KeyItem.new()
					_fill(k, id, data[id])
					k.group = StringName(str(data[id]["group"]))
					key_items[id] = k
			"rulesets":
				for id in _typed_rows(name, data):
					var r := Ruleset.new()
					_fill(r, id, data[id])
					r.flags = data[id].get("flags", {})
					r.is_default = bool(data[id].get("default", false))
					rulesets[id] = r

	## domain/index.md §5 load-time constraints. Returns true when no errors were added.
	## D20: the skill-tree nodes a (class, spec) pair can spend points on — the shared columns, the class
	## column (its spec-specific rank) and the spec's ultimate — in screen order. `alpha-tree.class` wins
	## over `owner` (sneak's owner is a per-version list).
	func skill_tree(class_id: StringName, spec_id: StringName) -> Array:
		var out: Array = []
		for id in abilities:
			var a: Ability = abilities[id]
			if a.alpha_tree.is_empty() or not _tree_field_errors(a.alpha_tree, str(id)).is_empty():
				continue
			var owner := StringName(
				str(a.alpha_tree.get("class", a.owner if a.owner is String else ""))
			)
			if owner in [&"all", class_id, spec_id]:
				out.append(a)
		out.sort_custom(func(x: Ability, y: Ability) -> bool: return _tree_key(x) < _tree_key(y))
		return out

	static func _tree_key(a: Ability) -> int:
		var t := a.alpha_tree
		if str(t["column"]) == "class":
			return 100 + int(t.get("rank", 0))
		return 104 if str(t["column"]) == "ultimate" else int(t.get("skill-slot", 0))

	## c-moveset-config / c-ability-runtime (D24): a projectile shot (moveset, ultimate or dash `throw`).
	static func _shot_errors(s: Dictionary, where: String) -> Array:
		var out: Array = []
		if (
			float(s.get("speed", 0)) <= 0.0
			or float(s.get("radius", 0)) <= 0.0
			or float(s.get("life-s", 0)) <= 0.0
		):
			out.append("%s: speed, radius, life-s must be > 0" % where)
		if (
			int(s.get("count", 1)) < 1
			or float(s.get("spread", 0)) < 0.0
			or float(s.get("gravity", 0)) < 0.0
			or float(s.get("splash", 0)) < 0.0
		):
			out.append("%s: count >= 1, spread / gravity / splash >= 0" % where)
		if s.get("pierce", false) and float(s.get("tick-s", 0)) <= 0.0:
			out.append("%s: pierce needs tick-s > 0" % where)
		return out

	## c-creature-roles (D26): a ranged/mage role dict from design.creature-roles (or a species-merged one).
	func _role_errors(
		r: Dictionary, where: String, se: Dictionary, alpha_sfx: Array, feel_sfx: Dictionary
	) -> Array:
		var out: Array = []
		if not _role_fields_valid(r, where):
			return out
		if str(r.get("kind", "")) != "projectile":
			out.append("%s: kind must be projectile" % where)
			return out
		if (
			float(r.get("range", -1)) <= float(r.get("keep-away", -1))
			or float(r.get("keep-away", -1)) < 0.0
		):
			out.append("%s: range must be > keep-away >= 0" % where)
		if float(r.get("windup-s", -1)) < 0.0:
			out.append("%s: windup-s must be >= 0" % where)
		if float(r.get("cooldown-s", 0)) <= 0.0:
			out.append("%s: cooldown-s must be > 0" % where)
		if float(r.get("damage-mult", 0)) <= 0.0:
			out.append("%s: damage-mult must be > 0" % where)
		out.append_array(_shot_errors(r.get("shot", {}), "%s.shot" % where))
		for sid in r.get("applies", []):
			if not se.has(sid):
				out.append("%s: applies %s has no design.status-effects entry" % [where, sid])
		var sfx_id := str(r.get("sfx", ""))
		if not alpha_sfx.has(sfx_id):
			out.append("%s: sfx %s is not an audio.json sfx-alpha-ids entry" % [where, sfx_id])
		elif not feel_sfx.has(sfx_id):
			out.append("%s: sfx %s has no design.feel.sfx entry" % [where, sfx_id])
		if not Color.html_is_valid(str(r.get("color", ""))):
			out.append("%s: color is not a valid html colour" % where)
		return out

	# c-slot-accepts / c-weapon-class / c-hands / c-cube-cap: selected equipment contract.
	func _validate_equipment() -> void:
		var slot_cfg: Variant = configs.get("equipment-slots")
		if not slot_cfg is Dictionary:
			errors.append("equipment-slots: required object missing or malformed")
		var slot_rows: Variant = slot_cfg.get("slots") if slot_cfg is Dictionary else null
		var item_type_config: Variant = configs.get("item-types")
		if not item_type_config is Dictionary:
			errors.append("item-types: required object missing or malformed")
		var item_types: Dictionary = item_type_config if item_type_config is Dictionary else {}
		var expected := {
			"unknown-0": [],
			"amulet": ["amulet"],
			"chest": ["chest-armor"],
			"gloves": ["gloves"],
			"boots": ["boots"],
			"shoulders": ["shoulder-armor"],
			"main-hand": ["weapon"],
			"off-hand": ["weapon"],
			"ring-left": ["ring"],
			"ring-right": ["ring"],
			"lamp": ["light"],
			"special": ["special"],
			"pet": ["pet-cage", "pet-food"]
		}
		var expected_indices := [
			"unknown-0",
			"amulet",
			"chest",
			"gloves",
			"boots",
			"shoulders",
			"main-hand",
			"off-hand",
			"ring-left",
			"ring-right",
			"lamp",
			"special",
			"pet"
		]
		var expected_subtypes := {"lamp": ["lamp"], "special": ["hang-glider", "boat"]}
		var seen_ids := {}
		var seen_indices := {}
		if not slot_rows is Array or slot_rows.size() != 13:
			errors.append("equipment-slots.slots: exactly 13 slot rows required")
		else:
			for row in slot_rows:
				if not row is Dictionary:
					errors.append("equipment-slots.slots: malformed row")
					continue
				var id := str(row.get("id", ""))
				var index: Variant = row.get("index")
				if seen_ids.has(id):
					errors.append("equipment-slots.slots.%s: duplicate id" % id)
				seen_ids[id] = true
				if (
					(not index is int and not index is float)
					or (
						index is float
						and (is_nan(index) or is_inf(index) or index != floorf(index))
					)
				):
					errors.append("equipment-slots.slots.%s.index: integer required" % id)
				else:
					if seen_indices.has(int(index)):
						errors.append("equipment-slots.slots.%s: duplicate index" % id)
					seen_indices[int(index)] = true
					if id in expected_indices and index != expected_indices.find(id):
						errors.append(
							"equipment-slots.slots.%s.index: selected mapping mismatch" % id
						)
				var accepts: Variant = row.get("accepts")
				if not accepts is Array:
					errors.append("equipment-slots.slots.%s.accepts: array required" % id)
					continue
				for type_id in accepts:
					if not item_types.has(type_id):
						errors.append(
							"equipment-slots.slots.%s.accepts: unknown item-type %s" % [id, type_id]
						)
					var type_row: Variant = item_types.get(type_id)
					var restrictions: Variant = row.get("accepts-subtypes", [])
					if (
						restrictions is Array
						and not restrictions.is_empty()
						and type_row is Dictionary
					):
						var catalog: Variant = type_row.get("subtypes")
						if catalog is Dictionary:
							for subtype in restrictions:
								if not catalog.values().has(subtype):
									errors.append(
										(
											"equipment-slots.slots.%s: unknown subtype %s"
											% [id, subtype]
										)
									)
						elif catalog is String:
							(
								errors
								. append(
									(
										"equipment-slots.slots.%s: subtype restrictions cannot resolve %s"
										% [id, catalog]
									)
								)
							)
				var want: Array = expected.get(id, [])
				if accepts != want:
					errors.append(
						"equipment-slots.slots.%s.accepts: selected mapping mismatch" % id
					)
				if (
					expected_subtypes.has(id)
					and row.get("accepts-subtypes") != expected_subtypes[id]
				):
					errors.append(
						"equipment-slots.slots.%s.accepts-subtypes: selected mapping mismatch" % id
					)
				if id == "pet" and row.get("accepts-conditions") != {"pet-food": "during-taming"}:
					errors.append(
						"equipment-slots.slots.pet: pet-food must remain conditional during taming"
					)
		for id in expected:
			if not seen_ids.has(id):
				errors.append("equipment-slots.slots.%s: required slot missing" % id)
		for index in range(13):
			if not seen_indices.has(index):
				errors.append("equipment-slots.slots: required index %d missing" % index)
		var extra: Variant = slot_cfg.get("extra") if slot_cfg is Dictionary else null
		var food_extra: Variant = extra.get("pet-food") if extra is Dictionary else null
		if not food_extra is Dictionary or food_extra.get("accepts") != ["pet-food"]:
			errors.append("equipment-slots.extra.pet-food: separate pet-food acceptance required")

		for id in weapon_types:
			var w: WeaponType = weapon_types[id]
			var raw: Dictionary = w.raw
			var class_owned := w.hands != Hands.NONE and w.character_class in classes
			for class_id in classes:
				if (classes[class_id] as CharacterClass).weapon_types.has(StringName(id)):
					class_owned = true
			if (
				class_owned
				and (
					not raw.get("hands") is String
					or raw.get("hands") not in ["1h", "2h", "offhand", "1h dual (need two)"]
				)
			):
				errors.append("weapon %s: hands must be a supported active weapon value" % id)
			if w.hands == Hands.NONE or raw.get("usable", true) == false:
				if class_owned:
					errors.append("weapon %s: active class weapon requires usable hands" % id)
				continue
			var owner: Variant = raw.get("class")
			if owner is String:
				if owner.is_empty():
					errors.append("weapon %s: owning class required" % id)
				elif owner != "any":
					if not classes.has(owner):
						errors.append("weapon %s: unknown class %s" % [id, owner])
					elif not (classes[owner] as CharacterClass).weapon_types.has(StringName(id)):
						errors.append("weapon %s: class %s does not list weapon" % [id, owner])
			else:
				errors.append("weapon %s: owning class required" % id)
			if class_owned:
				var expected_capacity := (
					MAX_CUBES_2H if w.hands in [Hands.TWO_HANDED, Hands.OFFHAND] else MAX_CUBES_1H
				)
				if not _is_selected_multiplier(raw.get("cube-capacity"), expected_capacity):
					errors.append("weapon %s: capacity must match hands" % id)
				var material_text := str(raw.get("material", ""))
				if material_text.is_empty():
					errors.append("weapon %s: material required" % id)
				else:
					for option in material_text.split("|"):
						var material_id := StringName(option.strip_edges().split(" ")[0])
						if not materials.has(material_id):
							errors.append("weapon %s: unknown material %s" % [id, material_id])
		var wand: WeaponType = weapon_types.get(&"wand")
		if (
			wand == null
			or wand.hands != Hands.TWO_HANDED
			or wand.cube_capacity != MAX_CUBES_2H
			or not (wand.raw.get("hands") is String and wand.raw["hands"] == "2h")
		):
			errors.append("weapon wand: selected mechanical 2h / 32-cube definition required")

		var recipe_cfg: Variant = configs.get("recipes")
		if not recipe_cfg is Dictionary:
			errors.append("recipes: required object missing or malformed")
		var gear_recipes: Variant = (
			recipe_cfg.get("gear-weapons") if recipe_cfg is Dictionary else null
		)
		if not gear_recipes is Dictionary:
			errors.append("recipes.gear-weapons: required object missing or malformed")
		var wand_recipe: Variant = gear_recipes.get("wand") if gear_recipes is Dictionary else null
		if not wand_recipe is Dictionary:
			errors.append("recipes.gear-weapons.wand: required recipe row missing")
		else:
			var inputs: Variant = wand_recipe.get("inputs")
			if (
				not inputs is Dictionary
				or not (
					(inputs.get("wood-cube") is int or inputs.get("wood-cube") is float)
					and float(inputs.get("wood-cube")) == 20.0
				)
			):
				errors.append("recipes.gear-weapons.wand.inputs.wood-cube: must be 20")
			if wand_recipe.get("station") != "workbench":
				errors.append("recipes.gear-weapons.wand.station: must be workbench")

	# c-control-references: only the selected Android first-slice input is enforced here.
	func _validate_android() -> void:
		var path := "controller-profiles.android"
		var profiles: Variant = configs.get("controller-profiles")
		if not profiles is Dictionary or not profiles.get("android") is Dictionary:
			errors.append(path + ": required object missing or malformed")
			return
		var a: Dictionary = profiles["android"]
		var selected := {
			"deadzone-ratio": 0.15, "min-target-dp": 48, "look-deg-per-safe-width": 180
		}
		for field in selected:
			var value: Variant = a.get(field)
			var expected: float = selected[field]
			if (not value is float and not value is int) or value != expected:
				errors.append(path + "." + field + ": must equal selected policy " + str(expected))
		var actions: Variant = a.get("actions")
		var required := [
			"move",
			"look",
			"zoom",
			"sprint",
			"jump",
			"swim-ascent",
			"basic-attack",
			"special-attack",
			"block",
			"dodge",
			"class-skill-1",
			"class-skill-2",
			"class-skill-3",
			"class-skill-4",
			"interact",
			"pick-up",
			"quick-item",
			"inventory",
			"skills-window",
			"ui-cancel",
			"equip-item",
			"use-inventory-item",
			"spend-skill-point",
			"buy-item",
			"sell-item",
			"world-map"
		]
		if not actions is Array or actions.size() != required.size():
			errors.append(path + ".actions: required distinct first-slice action array")
			return
		for action in required:
			if actions.count(action) != 1:
				errors.append(path + ".actions: required unique canonical action " + action)

	static func _is_selected_multiplier(value: Variant, selected: float) -> bool:
		if not value is int and not value is float:
			return false
		var number := float(value)
		return not is_nan(number) and not is_inf(number) and number == selected

	# Current selected encounter inputs, not a default or a legacy schema.
	func _selected_tree(value: Variant, expected: Variant, path: String) -> void:
		if expected is Dictionary:
			if not value is Dictionary:
				errors.append(path + ": required object missing or malformed")
				return
			for key in expected:
				_selected_tree(value.get(key), expected[key], path + "." + key)
			for key in value:
				if not key is String or (not key.begins_with("_") and not expected.has(key)):
					errors.append(path + "." + str(key) + ": unknown selected field")
		elif expected is Array:
			if not value is Array or value.size() != expected.size():
				errors.append(path + ": required selected array")
				return
			for i in expected.size():
				_selected_tree(value[i], expected[i], path + "[" + str(i) + "]")
		elif expected is int or expected is float:
			if not _is_selected_multiplier(value, expected):
				errors.append(path + ": must equal selected " + str(expected))
		elif typeof(value) != typeof(expected) or value != expected:
			errors.append(path + ": must equal selected " + str(expected))

	func _validate_playable_sites(design: Dictionary) -> void:
		_selected_tree(
			design.get("initial-encounters"),
			{
				"distance-min": 192,
				"distance-max": 215,
				"separation": 192,
				"apron": 8,
				"path-width": 4,
				"max-step": 1,
				"dry-above-sea": 4,
				"hub-size": 64,
				"ruins":
				{
					"room": [24, 24],
					"corridor": [8, 8],
					"court": [24, 16],
					"passage": [8, 8],
					"alcove": [12, 8],
					"bounds": [36, 112],
					"ceiling": 6,
					"door": [4, 5],
					"occupancy": [-1, 12],
					"pack-tiers": [1, 2, 3],
					"boss-tiers": [2, 3]
				},
				"camp": {"size": 64, "occupancy": [-1, 16], "exit-width": 8, "tier": 1, "packs": 2},
				"supplier":
				{
					"size": 48,
					"occupancy": [-1, 16],
					"exit-width": 8,
					"tiers": [0, 1, 2, 3],
					"packs": 2
				},
				"pack-size": 3,
				"species": "skeleton",
				"role-weights": {"melee": 0.5, "ranged": 0.3, "mage": 0.2},
				"power-base-offset": 2,
				"boss-hp-mult": 4,
				"boss-damage-mult": 1.5,
				"boss-height": {"base": 1.7, "min-mult": 1.25, "growth": 0.75, "max-level": 10},
				"boss-specials": {"stomp": 0.5, "charge": 0.5},
				"spirits":
				{
					"spirit-fire": 0.25,
					"spirit-unholy": 0.25,
					"spirit-ice": 0.25,
					"spirit-wind": 0.25
				},
				"mission-package":
				{
					"coin-per-grade": 20,
					"potion": "life-potion",
					"potion-rarity": 0,
					"potion-count": 1,
					"gems": ["emerald", "sapphire", "ruby", "diamond"],
					"gem-count-per-grade": 1,
					"rarity-shift": 1,
					"upgrades": 0,
					"delivery-height": 0.5
				},
				"special-profile":
				{
					"ready-s": 3,
					"cooldown-s": 10,
					"recovery-s": 0.8,
					"warning-s": 1.2,
					"stomp":
					{
						"radius": 4,
						"start-height-diff": 2,
						"victim-height": [0, 1],
						"damage-mult": 1
					},
					"charge":
					{
						"range": [4, 10],
						"start-height-diff": 1,
						"lane-width": 2,
						"speed": 12,
						"sweep-radius": 1,
						"damage-mult": 1.25
					}
				},
				"rubble":
				{
					"per-arena": 8,
					"voxel-size": 1,
					"restore-world-hours": 72,
					"block-type": "rock-building"
				},
				"spikes":
				{
					"count": 2,
					"footprint": [2, 2],
					"victim-height": [0, 1],
					"warning-s": 0.8,
					"active-s": 0.25,
					"cooldown-s": 2,
					"damage": 30,
					"attack-type": "physical",
					"warning-sfx": "block"
				},
				"furnishings":
				{
					"vase": {"per-room": 2, "hp": 10, "coin-base": 1, "coin-per-level": 2},
					"table":
					{
						"per-room": 1,
						"hp": 20,
						"flask": "glass-flask",
						"flask-count": 1,
						"potion": "life-potion",
						"potion-count": 1,
						"potion-rarity": 0
					},
					"armor": 0
				}
			},
			"design.initial-encounters"
		)
		var blocks: Variant = configs.get("block-types")
		if (
			not blocks is Dictionary
			or not blocks.get("alpha") is Dictionary
			or not blocks.alpha.get("6") is Dictionary
			or not blocks.alpha["6"].get("id") is String
			or blocks.alpha["6"].id != "rock-building"
			or not blocks.alpha["6"].get("solid") is bool
			or not blocks.alpha["6"].solid
		):
			errors.append("initial-encounters.rubble.block-type: required stone definition")
		if not _object(configs.get("ingredients")).has("glass-flask"):
			errors.append("initial-encounters.furnishings.table.flask: required ingredient")
		if not consumables.has(&"life-potion"):
			errors.append("initial-encounters.furnishings.table.potion: required consumable")
		if not _object(_object(design.get("feel")).get("sfx")).has("block"):
			errors.append("initial-encounters.spikes.warning-sfx: required sound")
		if not creatures.has(&"skeleton"):
			errors.append("initial-encounters.species: skeleton required")
		for id in ["spirit-fire", "spirit-unholy", "spirit-ice", "spirit-wind"]:
			if not materials.has(id) or materials[id].raw.get("kind") != "spirit":
				errors.append("initial-encounters.spirits: missing spirit " + id)

	func _validate_initial_encounter_config(design: Dictionary) -> void:
		var settlement: Variant = design.get("settlement")
		if not settlement is Dictionary:
			errors.append("design.settlement: required object missing or malformed")
		elif not _is_selected_multiplier(settlement.get("per-land"), 1.0):
			errors.append("design.settlement.per-land: must equal selected exact count 1")
		# Approved AI/game-clock inputs; require selected values, never runtime defaults.
		var selected := {
			"time": {"speed": 10.0, "day-s": 86400.0, "initial-hour": 7.0},
			"spawns.ai":
			{
				"threat-per-full-hp": 100.0,
				"threat-decay-per-s": 1.0,
				"return-speed-mult": 2.0,
				"return-damage-reduction": 0.9
			},
			"abilities.heroic-shout": {"taunt-s": 3.0}
		}
		for path in selected:
			var row: Variant = design
			for part in path.split("."):
				row = row.get(part) if row is Dictionary else null
			for field in selected[path]:
				if not _is_selected_multiplier(
					row.get(field) if row is Dictionary else null, selected[path][field]
				):
					errors.append(
						(
							"design."
							+ path
							+ "."
							+ field
							+ ": must equal selected "
							+ str(selected[path][field])
						)
					)
		var hybrid: Ruleset = rulesets.get(&"ruleset-hybrid")
		if hybrid == null:
			errors.append("rulesets.ruleset-hybrid: required object missing or malformed")
			return
		var raw_flags: Variant = hybrid.raw.get("flags")
		if not raw_flags is Dictionary:
			errors.append("rulesets.ruleset-hybrid.flags: required object missing or malformed")
		elif not _is_selected_multiplier(raw_flags.get("settlements-per-land"), 1.0):
			(
				errors
				. append(
					"rulesets.ruleset-hybrid.flags.settlements-per-land: must equal selected exact count 1"
				)
			)

	# Guard only fields consumed by the moveset numeric/reference checks below.
	func _moveset_fields_valid(row: Dictionary, path: String) -> bool:
		var valid := true
		for field in [
			"damage-mult",
			"swing-mult",
			"radius-mult",
			"lunge",
			"range",
			"radius",
			"speed",
			"life-s",
			"count",
			"spread",
			"gravity",
			"splash",
			"tick-s",
			"every",
			"chance"
		]:
			if not row.has(field):
				continue
			var value: Variant = row[field]
			if (not value is int and not value is float) or not is_finite(float(value)):
				errors.append(path + "." + field + ": finite number required")
				valid = false
		if row.has("pierce") and not row["pierce"] is bool:
			errors.append(path + ".pierce: boolean required")
			valid = false
		var applies: Variant = row.get("applies", [])
		if not applies is Array:
			errors.append(path + ".applies: status ID array required")
			valid = false
		else:
			for id in applies:
				if not id is String:
					errors.append(path + ".applies: status ID string required")
					valid = false
		return valid

	# Finite required identity boundary; raw metadata is not a race row.
	func _validate_races() -> void:
		var catalog: Variant = configs.get("races")
		if not catalog is Dictionary:
			errors.append("races: required catalog object missing or malformed")
			return
		for id in ["human", "elf", "dwarf", "goblin", "lizardman", "orc", "undead", "frogman"]:
			if not catalog.has(id):
				errors.append("races.%s: required playable race missing" % id)
		for id in catalog:
			if str(id).begins_with("$") or str(id).begins_with("_"):
				continue
			var path := "races." + str(id)
			var row: Variant = catalog[id]
			if not row is Dictionary:
				errors.append(path + ": required row object")
				continue
			if not row.get("playable") is bool:
				errors.append(path + ".playable: boolean required")
			if row.get("size-class") not in ["small", "normal", "large"]:
				errors.append(path + ".size-class: small, normal or large required")

	# Only district buildings and landscape dungeon/POI IDs, not descriptive world strings.
	func _validate_world_references() -> void:
		var cfg: Variant = configs.get("buildings")
		var buildings: Variant = cfg.get("buildings") if cfg is Dictionary else null
		var districts: Variant = cfg.get("districts") if cfg is Dictionary else null
		if not buildings is Dictionary:
			errors.append("buildings.buildings: required catalog object")
			buildings = {}
		if not districts is Dictionary:
			errors.append("buildings.districts: required catalog object")
			districts = {}
		for district in districts:
			var row: Variant = districts[district]
			var path := "buildings.districts." + str(district) + ".buildings"
			if not row is Dictionary:
				errors.append(path + ": district row object required")
				continue
			var refs: Variant = row.get("buildings", [])
			if not refs is Array:
				errors.append(path + ": array required")
				continue
			var trainer_classes := []
			for ref in refs:
				var id: Variant = ref.get("id") if ref is Dictionary else ref
				if not id is String or not buildings.get(id) is Dictionary:
					errors.append(path + ": unknown or malformed building ID " + str(id))
				if ref is Dictionary:
					var qualifier: Variant = ref.get("class")
					if (
						not id is String
						or id != "class-trainer"
						or not qualifier is String
						or not classes.has(qualifier)
					):
						errors.append(
							path + ": class qualification requires a trainer and valid class"
						)
					else:
						trainer_classes.append(qualifier)
					for key in ref:
						if key not in ["id", "class"]:
							errors.append(path + ": unknown qualification " + str(key))
			if district == "adventurer":
				for cid in ["warrior", "ranger", "rogue", "mage"]:
					if trainer_classes.count(cid) != 1:
						errors.append(path + ": exactly one class-trainer for " + cid + " required")
				if refs.size() != 4:
					errors.append(path + ": four class-qualified trainers required")
		for land in landscapes:
			var row: Dictionary = landscapes[land].raw
			for field in ["dungeons", "pois"]:
				if not row.has(field):
					continue
				var path: String = "landscapes." + str(land) + "." + field
				var catalog: Variant = configs.get(
					"dungeon-types" if field == "dungeons" else "poi-types"
				)
				if not catalog is Dictionary:
					errors.append(path + ": reference catalog object required")
					catalog = {}
				var refs: Variant = row[field]
				if not refs is Array:
					errors.append(
						path + ": array of catalog IDs required; qualifiers belong in notes"
					)
					continue
				for id in refs:
					if not id is String or not catalog.get(id) is Dictionary or id.begins_with("_"):
						errors.append(path + ": unknown or malformed reference " + str(id))

	static func _identity_integer(value: Variant, minimum: int, maximum: float = INF) -> bool:
		return (
			(value is int or value is float)
			and is_finite(float(value))
			and float(value) == floor(float(value))
			and value >= minimum
			and value <= maximum
		)

	static func _identity_strings(value: Variant) -> bool:
		if not value is Array:
			return false
		for item in value:
			if not item is String:
				return false
		return true

	static func _tree_field_errors(tree: Variant, path: String) -> Array:
		var out := []
		if not tree is Dictionary or tree.is_empty():
			return [path + ": alpha-tree object required"]
		var raw_column: Variant = tree.get("column")
		var column: String = raw_column if raw_column is String else ""
		if column not in ["class", "ultimate", "pets", "climbing", "water"]:
			out.append(path + ".column: known column required")
		if not _identity_integer(tree.get("needs"), 0):
			out.append(path + ".needs: nonnegative integer required")
		if column == "class" and not _identity_integer(tree.get("rank"), 1, 3):
			out.append(path + ".rank: integer 1..3 required")
		if (
			column in ["pets", "climbing", "water"]
			and not _identity_integer(tree.get("skill-slot"), 0)
		):
			out.append(path + ".skill-slot: nonnegative integer required")
		if column == "ultimate" and not _is_selected_multiplier(tree.get("needs"), 5):
			out.append(path + ".needs: ultimate requires 5 rank-3 points")
		if tree.has("class") and not tree["class"] is String:
			out.append(path + ".class: string required")
		if tree.has("also-ultimate") and not tree["also-ultimate"] is bool:
			out.append(path + ".also-ultimate: boolean required")
		return out

	static func _identity_row_errors(catalog: String, row: Variant, path: String) -> Array:
		if not row is Dictionary or row.is_empty():
			return [path + ": row object required"]
		var out := []
		match catalog:
			"classes":
				for field in ["weapon-types", "specializations"]:
					if not _identity_strings(row.get(field)):
						out.append(path + "." + field + ": string array required")
				for field in ["armor-material", "special-attack-mode"]:
					if not row.get(field) is String:
						out.append(path + "." + field + ": string required")
				if row.get("special-attack-mode") not in ["charged", "instant"]:
					out.append(path + ".special-attack-mode: charged or instant required")
				if not _identity_integer(row.get("id-number"), 1, 4):
					out.append(path + ".id-number: integer 1..4 required")
				var hp: Variant = row.get("hp-mult")
				if not (hp is int or hp is float) or not is_finite(float(hp)) or hp <= 0:
					out.append(path + ".hp-mult: finite positive number required")
			"specializations":
				if not row.get("class") is String:
					out.append(path + ".class: string required")
				if not _identity_integer(row.get("index"), 0, 1):
					out.append(path + ".index: integer 0 or 1 required")
				for field in ["kit", "passives"]:
					if not row.get(field) is Dictionary:
						out.append(path + "." + field + ": object required")
						continue
					for version in ["A", "S"]:
						if not _identity_strings(row[field].get(version)):
							out.append(
								path + "." + field + "." + version + ": string array required"
							)
			"abilities":
				if not row.get("owner") is String and not _identity_strings(row.get("owner")):
					out.append(path + ".owner: string or string array required")
				for field in ["input", "cost"]:
					if row.has(field) and not row[field] is Dictionary:
						out.append(path + "." + field + ": object required")
				if row.has("applies") and not _identity_strings(row["applies"]):
					out.append(path + ".applies: string array required")
				if row.has("alpha-id") and not _identity_integer(row["alpha-id"], 0):
					out.append(path + ".alpha-id: nonnegative integer required")
				if row.has("alpha-tree"):
					out.append_array(_tree_field_errors(row["alpha-tree"], path + ".alpha-tree"))
				if row.has("unlocks-next") and not row["unlocks-next"] is String:
					out.append(path + ".unlocks-next: string required")
		return out

	func _validate_identity() -> void:
		var pairs := {
			"warrior": ["berserker", "guardian"],
			"ranger": ["sniper", "scout"],
			"mage": ["fire-mage", "water-mage"],
			"rogue": ["assassin", "ninja"]
		}
		var required := {
			"classes": pairs.keys(), "specializations": [], "abilities": ["camouflage"]
		}
		for cid in pairs:
			for sid in pairs[cid]:
				required.specializations.append(sid)
				if specs.has(sid) and specs[sid].character_class != StringName(cid):
					errors.append("specializations.%s.class: must belong to %s" % [sid, cid])
		for catalog in required:
			var raw: Variant = configs.get(catalog)
			var modeled: Dictionary = {
				"classes": classes, "specializations": specs, "abilities": abilities
			}[catalog]
			if not raw is Dictionary or _rows(raw).is_empty():
				errors.append(catalog + ": required catalog object with rows")
			if raw is Dictionary:
				for id in raw:
					if str(id).begins_with("_") or str(id).begins_with("$"):
						continue
					errors.append_array(
						_identity_row_errors(catalog, raw[id], catalog + "." + str(id))
					)
			for id in required[catalog]:
				if not modeled.has(id) or not raw is Dictionary or not raw.get(id) is Dictionary:
					errors.append(catalog + "." + id + ": required identity row")
			for id in modeled:
				errors.append_array(
					_identity_row_errors(catalog, modeled[id].raw, catalog + "." + str(id))
				)
		for id in abilities:
			var a: Ability = abilities[id]
			if not a.alpha_tree.is_empty():
				errors.append_array(
					_tree_field_errors(a.alpha_tree, "abilities." + str(id) + ".alpha-tree")
				)
				var owner: Variant = a.alpha_tree.get("class", a.owner)
				if (
					not owner is String
					or (owner != "all" and not classes.has(owner) and not specs.has(owner))
				):
					errors.append("abilities.%s.alpha-tree.class: known tree owner required" % id)

	func validate() -> bool:
		_validate_required_inputs()
		_validate_identity()
		_validate_races()
		_validate_world_references()
		_validate_equipment()
		_validate_android()
		_validate_provenance()
		# c-apple-heal: selected hybrid coefficient, independently at raw and loaded boundaries.
		var apple_input := _object(_object(configs.get("consumables")).get("apple"))
		if not _is_selected_multiplier(apple_input.get("heal-mult"), 20):
			errors.append("consumables.apple.heal-mult: required numeric 20")
		var apple: Consumable = consumables.get(&"apple")
		if apple == null:
			errors.append("consumables.apple: required loaded consumable")
		else:
			if not _is_selected_multiplier(apple.raw.get("heal-mult"), 20):
				errors.append("consumables.apple.heal-mult: loaded raw must equal numeric 20")
			if apple.heal_mult != 20:
				errors.append("consumables.apple.heal-mult: loaded coefficient must equal 20")
		for id in specs:  # c-spec-of-class
			var s: Specialization = specs[id]
			if not classes.has(s.character_class):
				errors.append("spec %s: unknown class %s" % [id, s.character_class])
			elif not (classes[s.character_class] as CharacterClass).specializations.has(
				StringName(id)
			):
				errors.append("class %s does not list spec %s" % [s.character_class, id])
			for a in s.kit_a + s.kit_s + s.passives_a + s.passives_s:
				if not abilities.has(a):
					errors.append("spec %s: unknown ability %s" % [id, a])
		for id in classes:
			var c: CharacterClass = classes[id]
			if c.specializations.size() != 2 or c.specializations[0] == c.specializations[1]:
				errors.append("class %s: two distinct specializations required" % id)
			for i in c.specializations.size():
				var sid := c.specializations[i]
				if not specs.has(sid):
					errors.append("class %s: unknown specialization %s" % [id, sid])
				elif specs[sid].character_class != StringName(id) or specs[sid].index != i:
					errors.append(
						"class %s: specialization %s must be owned with index %d" % [id, sid, i]
					)
			for w in c.weapon_types:
				if not weapon_types.has(w):
					errors.append("class %s: unknown weapon-type %s" % [id, w])
				elif (
					not (weapon_types[w] as WeaponType).raw.get("class") is String
					or (weapon_types[w] as WeaponType).raw.get("class") != str(id)
				):
					errors.append("class %s: weapon-type %s must belong to class" % [id, w])
		for id in pet_foods:  # c-food-id + tamed-by
			var f: PetFood = pet_foods[id]
			if not creatures.has(f.tames):
				errors.append("pet-food %s tames unknown creature %s" % [id, f.tames])
				continue
			var c: Creature = creatures[f.tames]
			if c.tame_food != StringName(id):
				errors.append("pet-food %s ↔ creature %s tame mismatch" % [id, f.tames])
			if c.alpha_entity_id >= 0 and c.alpha_entity_id != f.subtype:
				errors.append(
					"pet-food %s subtype %d != creature id %d" % [id, f.subtype, c.alpha_entity_id]
				)
		for id in creatures:
			var c: Creature = creatures[id]
			if c.tame_food != &"" and not pet_foods.has(c.tame_food):
				errors.append("creature %s: unknown food %s" % [id, c.tame_food])
		for id in weapon_types:  # c-cube-cap
			var w: WeaponType = weapon_types[id]
			if w.cube_capacity not in [0, MAX_CUBES_1H, MAX_CUBES_2H]:
				errors.append("weapon %s: bad cube capacity" % id)
		for id in rarities:  # c-rarity-range
			if (rarities[id] as RarityDef).index > Rarity.MYTHICAL:
				errors.append("rarity %s out of range" % id)
		for id in abilities:
			for s in (abilities[id] as Ability).applies:
				if not status_effects.has(s):
					errors.append("ability %s applies unknown status %s" % [id, s])
		for dict in [
			races,
			classes,
			specs,
			abilities,
			weapon_types,
			materials,
			creatures,
			landscapes,
			consumables,
			key_items
		]:
			for id in dict:  # c-versions-nonempty
				var row: Dictionary = (dict[id] as Entry).raw
				var tags: Variant = row.get("versions", row.get("v", []))
				if not _source_tags_valid(tags):
					errors.append("%s: missing or malformed source version tags" % id)
		var rosters := _object(_object(configs.get("creature-families")).get("landscape-rosters"))
		for land in rosters:  # c-roster-ids
			if not _identity_strings(rosters[land]):
				continue  # Raw shape diagnosed independently.
			for cid in rosters[land]:
				if not creatures.has(cid):
					errors.append("roster %s: unknown creature %s" % [land, cid])
		var generator_config: Variant = configs.get("generators")
		if not generator_config is Dictionary:
			errors.append("generators: required object missing or malformed")
			generator_config = {}
		var design_input: Variant = generator_config.get("design")
		if not design_input is Dictionary:
			errors.append("design: required object missing or malformed")
			design_input = {}
		var design: Dictionary = design_input
		_validate_initial_encounter_config(design)
		_validate_playable_sites(design)
		var terrain_input: Variant = design.get("terrain")
		if not terrain_input is Dictionary:
			errors.append("design.terrain: required object missing or malformed")
		else:
			var scales := {
				"lands-per-axis": 1024, "land-blocks": 16384, "zone-blocks": 64, "land-zones": 256
			}
			for field in scales:
				if not _is_selected_multiplier(terrain_input.get(field), scales[field]):
					errors.append(
						"design.terrain.%s: must equal selected %s" % [field, scales[field]]
					)
		var spawns_input: Variant = design.get("spawns", {})
		var ai_input: Variant = spawns_input.get("ai", {}) if spawns_input is Dictionary else {}
		var ai: Dictionary = ai_input if ai_input is Dictionary else {}
		if (
			_fields_valid(ai, "design.spawns.ai", {"number": "sim-radius aggro-range leash"})
			and (
				float(ai["sim-radius"])
				< float(ai.get("aggro-range", 0)) + float(ai.get("leash", 0))
			)
		):  # c-sim-radius
			errors.append("design.spawns.ai.sim-radius %s < aggro-range + leash" % ai["sim-radius"])
		var combat: Variant = design.get("combat")
		if not combat is Dictionary:
			errors.append("design.combat: required object missing or malformed")
		else:
			var innate_resistance: Variant = combat.get("creature-resistance")
			if (
				(not innate_resistance is float and not innate_resistance is int)
				or innate_resistance != 0
			):
				(
					errors
					. append(
						"design.combat.creature-resistance: must equal selected unequipped creature/NPC innate Resistance 0"
					)
				)
			if not _is_selected_multiplier(combat.get("armor-floor"), 0.1):
				errors.append("design.combat.armor-floor: must equal selected 0.1 hit-damage floor")
		var gear_hp: Variant = design.get("gear-hp")
		if not gear_hp is Dictionary:
			errors.append("design.gear-hp: required object missing or malformed")
		else:
			var hp_inputs := {"curve-mult": 5.0, "base": 2.0, "upgrade-step": 0.1}
			for field in hp_inputs:
				if not _is_selected_multiplier(gear_hp.get(field), hp_inputs[field]):
					errors.append(
						"design.gear-hp.%s: must equal selected %s" % [field, hp_inputs[field]]
					)
		var hp_materials := {"iron": 1.0, "cotton": 0.75, "linen": 0.5}
		for id in hp_materials:
			if (
				not materials.has(id)
				or not _is_selected_multiplier(
					(materials[id] as MaterialDef).raw.get("hp-bonus"), hp_materials[id]
				)
			):
				errors.append(
					(
						"material %s.raw.hp-bonus: must equal selected bonus %s"
						% [id, hp_materials[id]]
					)
				)
		var resistance_materials := {"iron": 0.85, "linen": 0.75, "cotton": 0.75, "silk": 1.0}
		for id in resistance_materials:
			if (
				not materials.has(id)
				or not _is_selected_multiplier(
					(materials[id] as MaterialDef).raw.get("resi-mult"), resistance_materials[id]
				)
			):
				errors.append(
					(
						"material %s.raw.resi-mult: must equal selected active multiplier %s"
						% [id, resistance_materials[id]]
					)
				)
		var slot_multipliers := {
			"chest": 1.0,
			"gloves": 0.5,
			"boots": 0.5,
			"shoulders": 0.5,
			"main-hand": 0.5,
			"off-hand": 0.5
		}
		var slot_config: Variant = configs.get("equipment-slots", {})
		var equipment_slots: Variant = (
			slot_config.get("slots", []) if slot_config is Dictionary else []
		)
		var found_slots: Dictionary = {}
		if equipment_slots is Array:
			for slot in equipment_slots:
				if slot is Dictionary and slot_multipliers.has(str(slot.get("id", ""))):
					var id := str(slot["id"])
					if found_slots.has(id):
						errors.append("equipment-slots.slots.%s: duplicate HP-bearing slot" % id)
					found_slots[id] = true
					if not _is_selected_multiplier(slot.get("hp-mult"), slot_multipliers[id]):
						(
							errors
							. append(
								(
									"equipment-slots.slots.%s.hp-mult: must equal selected multiplier %s"
									% [id, slot_multipliers[id]]
								)
							)
						)
		for id in slot_multipliers:
			if not found_slots.has(id):
				errors.append("equipment-slots.slots.%s: required HP-bearing slot missing" % id)
		var loot_start := errors.size()
		_selected_tree(
			design.get("loot"),
			{
				"coins": {"chance": 0.6, "base": 1, "per-level": 2},
				"gear-chance": 0.2,
				"consumable-chance": 0.15,
				"species-drop-chance": 0.5,
				"level-spread": 1,
				"boss-rarity-shift": 1,
				"rarity-weights":
				{"common": 60, "uncommon": 25, "rare": 10, "epic": 4, "legendary": 1},
				"gear-kinds":
				{"weapon": 4, "chest-armor": 2, "gloves": 2, "boots": 2, "shoulder-armor": 2},
				"consumable-pool": ["life-potion", "apple", "pineapple-slice"],
				"ground":
				{"lifetime-s": 60480, "pickup-radius": 2, "auto-pickup": ["coin"], "scatter": 1}
			},
			"design.loot"
		)
		if errors.size() == loot_start:
			var loot: Dictionary = design.loot
			for id in loot["rarity-weights"]:
				if not rarities.has(id) or rarities[id].index > Rarity.LEGENDARY:
					errors.append("design.loot.rarity-weights: bad rarity " + id)
			var types_input: Variant = configs.get("item-types")
			var types: Dictionary = types_input if types_input is Dictionary else {}
			var stack_cap: Variant = design.get("stack-cap", {})
			if not stack_cap is Dictionary:
				errors.append("design.stack-cap: object required")
				stack_cap = {}
			var stackable: Variant = stack_cap.get("stackable", [])
			if not stackable is Array:
				errors.append("design.stack-cap.stackable: array required")
				stackable = []
			for id in loot["gear-kinds"].keys() + stackable:
				if not types.has(id):
					errors.append("design.loot/stack-cap: unknown item-type %s" % str(id))
			for id in loot["consumable-pool"]:
				if not consumables.has(id):
					errors.append("design.loot.consumable-pool: unknown consumable " + id)
		for id in ["emerald", "sapphire", "ruby", "diamond", "glass-flask"]:
			if not _object(configs.get("ingredients")).has(id):
				errors.append("initial-encounters.mission-package: required ingredient " + id)
		if classes.size() != 4:
			errors.append("initial-encounters.rewards: require four classes")
		for id in ["warrior", "ranger", "rogue", "mage"]:
			if not classes.has(id):
				errors.append("initial-encounters.rewards: required class " + id)
				continue
			var cls: CharacterClass = classes[id]
			if not materials.has(cls.armor_material):
				errors.append("initial-encounters.rewards: illegal armor material for " + id)
			if cls.weapon_types.is_empty():
				errors.append("initial-encounters.rewards: empty weapon pool for " + id)
			for type_id in cls.weapon_types:
				if not weapon_types.has(type_id):
					continue  # ownership diagnostics below
				var raw: Variant = weapon_types[type_id].raw.get("material")
				if not raw is String or not materials.has(raw.split(" ")[0].split("|")[0]):
					errors.append(
						"initial-encounters.rewards: missing weapon material " + str(type_id)
					)
		var prog := _object(design.get("progression"))  # c-xp-config (D19)
		if _fields_valid(
			design.get("progression"),
			"design.progression",
			{"number": "kill-fraction gap-per-level", "pair": "gap-mult-range"}
		):
			var kf := float(prog["kill-fraction"])
			var r: Array = prog["gap-mult-range"]
			if kf <= 0.0 or kf > 1.0:
				errors.append("design.progression.kill-fraction out of (0,1]")
			if float(r[0]) < 0.0 or float(r[0]) > 1.0 or float(r[1]) < 1.0:
				errors.append("design.progression.gap-mult-range must bracket 1 with lo >= 0")
			if float(prog["gap-per-level"]) < 0.0:
				errors.append("design.progression.gap-per-level < 0")
		for id in specs:  # c-tree-shape (D20)
			var s: Specialization = specs[id]
			var ranks := {}
			var ults := 0
			var roots := {"pets": 0, "climbing": 0, "water": 0}
			var nodes := skill_tree(s.character_class, StringName(id))
			for a in nodes:
				var t: Dictionary = (a as Ability).alpha_tree
				var col := str(t["column"])
				if col == "class":
					ranks[int(t["rank"])] = ranks.get(int(t["rank"]), 0) + 1
					if int(t["needs"]) != (0 if int(t["rank"]) == 1 else 5):
						errors.append(
							(
								"skill-tree: %s class prerequisite must be 0 at rank 1, otherwise 5"
								% a.id
							)
						)
				elif col == "ultimate":
					ults += 1
				else:
					if int(t["needs"]) == 0:
						roots[col] = roots.get(col, 0) + 1
					if int(t["needs"]) != 0:
						var predecessors := 0
						for b in nodes:
							if (
								b.alpha_tree.column == col
								and b.raw.get("unlocks-next") is String
								and b.raw["unlocks-next"] == str(a.id)
							):
								predecessors += 1
						if int(t["needs"]) != 5 or predecessors != 1:
							errors.append(
								"skill-tree: %s needs 5 and one same-column predecessor" % a.id
							)
				var nxt := StringName(str((a as Ability).raw.get("unlocks-next", "")))
				if (
					nxt != &""
					and (
						not abilities.has(nxt)
						or abilities[nxt] not in nodes
						or str((abilities[nxt] as Ability).alpha_tree.get("column")) != col
					)
				):
					errors.append(
						"skill-tree: %s unlocks-next %s is not in column %s" % [a.id, nxt, col]
					)
			for r in [1, 2, 3]:
				if ranks.get(r, 0) != 1:
					errors.append(
						"skill-tree %s: %d class nodes of rank %d" % [id, ranks.get(r, 0), r]
					)
			if ults > 1 or (id == "assassin" and ults != 0):
				errors.append("skill-tree %s: %d ultimates" % [id, ults])
			if id == "assassin":
				var cam: Ability = abilities.get("camouflage")
				var sneak: Ability = abilities.get("sneak")
				if (
					cam not in nodes
					or cam.alpha_tree.column != "class"
					or cam.alpha_tree.get("rank") != 3
					or cam.alpha_tree.needs != 5
					or sneak not in nodes
					or sneak.alpha_tree.column != "class"
					or sneak.alpha_tree.get("rank") != 2
				):
					errors.append(
						"skill-tree assassin: one rank-3 Camouflage after 5 Sneak points required"
					)
			for col in roots:
				if roots[col] != 1:
					errors.append("skill-tree %s: column %s has %d roots" % [id, col, roots[col]])
		var ab_input: Variant = design.get("abilities")  # c-ability-runtime (D21)
		var ab: Dictionary = ab_input if ab_input is Dictionary else {}
		var runtimes := _array(ab.get("runtimes"))
		var stamina_input: Variant = _object(_object(design.get("movement")).get("stamina")).get(
			"max"
		)
		var stamina_max := (
			float(stamina_input)
			if _input_shape(stamina_input, "number", "design.movement.stamina.max")
			else 0.0
		)
		var seen := {}
		for id in specs:
			for a in skill_tree((specs[id] as Specialization).character_class, StringName(id)):
				var col := str((a as Ability).alpha_tree["column"])
				if col != "class" and col != "ultimate" or seen.has(a.id):
					continue
				seen[a.id] = true
				var r = ab.get(a.id)
				if not r is Dictionary or not (str(r.get("runtime")) in runtimes):
					errors.append("design.abilities.%s: missing or unknown runtime" % a.id)
					continue
				if not _ability_fields_valid(r, "design.abilities.%s" % a.id):
					continue
				if float(r.get("cooldown-s", 0)) <= 0.0:
					errors.append("design.abilities.%s: cooldown-s must be > 0" % a.id)
				for res in r.get("cost", {}):
					var v = r["cost"][res]
					var cap := 100.0 if str(res) == "mp" else stamina_max
					if not (
						str(v) == "all"
						or ((v is float or v is int) and float(v) >= 0.0 and float(v) <= cap)
					):
						errors.append(
							(
								"design.abilities.%s: cost %s = %s outside [0, %d] / 'all'"
								% [a.id, res, v, cap]
							)
						)
				match str(r["runtime"]):
					"dash":
						if float(r.get("distance", 0)) <= 0.0:
							errors.append("design.abilities.%s: dash distance must be > 0" % a.id)
						if r.has("strike") and float(r["strike"].get("radius", 0)) <= 0.0:
							errors.append("design.abilities.%s: strike radius must be > 0" % a.id)
						if r.has("throw"):
							errors.append_array(
								_shot_errors(r["throw"], "design.abilities.%s.throw" % a.id)
							)
					"projectile":
						errors.append_array(_shot_errors(r, "design.abilities.%s" % a.id))
					"burst", "channel":
						if float(r.get("radius", 0)) <= 0.0:
							errors.append("design.abilities.%s: radius must be > 0" % a.id)
						if str(r["runtime"]) == "channel" and float(r.get("duration-s", 0)) <= 0.0:
							errors.append("design.abilities.%s: duration-s must be > 0" % a.id)
					"buff":
						if float(r.get("duration-s", 0)) <= 0.0:
							errors.append("design.abilities.%s: duration-s must be > 0" % a.id)
					"heal":
						if float(r.get("cast-s", -1)) < 0.0 or float(r.get("heal-pct", 0)) <= 0.0:
							errors.append(
								(
									"design.abilities.%s: heal needs cast-s >= 0 and heal-pct > 0"
									% a.id
								)
							)
		# c-combat-burning-applications / c-combat-poison-applications: required selected inputs.
		var dot_config: Variant = design.get("status-effects")
		var se: Dictionary = {}
		if not dot_config is Dictionary:
			errors.append("design.status-effects: required object missing or malformed")
		else:
			se = dot_config
		for id in ["burning", "poison"]:
			var path: String = "design.status-effects." + id
			var row: Variant = se.get(id)
			if not row is Dictionary:
				errors.append(path + ": required object missing or malformed")
				continue
			var selected := (
				{"duration-s": 4.0, "tick-s": 0.5, "pct-of-hit": 0.1}
				if id == "burning"
				else {"duration-s": 5.0, "tick-s": 1.0, "pct-of-hit": 1.0}
			)
			for field in selected:
				var value: Variant = row.get(field)
				if (not value is float and not value is int) or value != selected[field]:
					errors.append(
						path + "." + field + ": must equal selected value " + str(selected[field])
					)
			if (
				(id == "poison" and row.get("as") != "burning")
				or (id == "burning" and row.has("as"))
			):
				errors.append(path + ".as: must route to burning DOT behavior")
		for id in se:
			if str(id).begins_with("_"):
				continue
			if not status_effects.has(id):
				errors.append("design.status-effects.%s is not a status-effect" % id)
			elif not se[id] is Dictionary:
				errors.append("design.status-effects.%s: malformed object" % id)
			elif se[id].has("as") and not se.has(str(se[id]["as"])):
				errors.append("design.status-effects.%s: `as` %s has no entry" % [id, se[id]["as"]])
		var moveset_input: Variant = design.get("movesets")  # c-moveset-config (D24)
		var mv: Dictionary = moveset_input if moveset_input is Dictionary else {}
		if mv.is_empty():
			errors.append("design.movesets: required nonempty object missing or malformed")
		if not mv.get("default") is Dictionary:
			errors.append("design.movesets.default: required object missing or malformed")
		var kinds_input: Variant = mv.get("kinds")
		var kinds: Array = kinds_input if kinds_input is Array else []
		if kinds.is_empty():
			errors.append("design.movesets.kinds: required nonempty array")
		for kind in kinds:
			if kind not in ["melee", "projectile", "beam", "at-cursor"]:
				errors.append("design.movesets.kinds: unknown or malformed kind " + str(kind))
		for id in mv:
			if str(id).begins_with("_") or str(id) == "kinds":
				continue
			if str(id) != "default" and not weapon_types.has(id):
				errors.append("design.movesets.%s is not a weapon-type" % id)
			if not mv[id] is Dictionary:
				errors.append("design.movesets.%s: entry object required" % id)
				continue
			var m: Dictionary = mv[id]
			if m.has("as"):
				var target: Variant = mv.get(m["as"]) if m["as"] is String else null
				if not target is Dictionary or target.has("as") or str(m["as"]).begins_with("_"):
					errors.append(
						"design.movesets.%s: `as` %s is not a plain entry" % [id, m["as"]]
					)
				continue
			for slot in ["m1", "m2"]:
				var s = m.get(slot)
				var where := "design.movesets.%s.%s" % [id, slot]
				if not s is Dictionary or not (str(s.get("kind")) in kinds):
					errors.append("%s: kind must be one of %s" % [where, kinds])
					continue
				if not _moveset_fields_valid(s, where):
					continue
				for sid in s.get("applies", []):
					if not se.has(sid):
						errors.append(
							"%s: applies %s has no design.status-effects entry" % [where, sid]
						)
				if float(s.get("damage-mult", 1)) <= 0.0:
					errors.append("%s: damage-mult must be > 0" % where)
				match str(s["kind"]):
					"melee":
						if (
							float(s.get("swing-mult", 1)) <= 0.0
							or float(s.get("radius-mult", 1)) <= 0.0
							or float(s.get("lunge", 0)) < 0.0
						):
							errors.append("%s: swing-mult, radius-mult > 0, lunge >= 0" % where)
						if s.has("finisher"):
							if not s["finisher"] is Dictionary:
								errors.append(where + ": finisher object required")
								continue
							var f: Dictionary = s["finisher"]
							if not _moveset_fields_valid(f, where + ".finisher"):
								continue
							if (
								int(f.get("every", 0)) < 2
								or float(f.get("chance", -1)) < 0.0
								or float(f.get("chance", -1)) > 1.0
							):
								errors.append("%s: finisher every >= 2, chance in [0,1]" % where)
							for sid in f.get("applies", []):
								if not se.has(sid):
									(
										errors
										. append(
											(
												"%s: finisher applies %s has no design.status-effects entry"
												% [where, sid]
											)
										)
									)
					"projectile":
						errors.append_array(_shot_errors(s, where))
					_:
						if float(s.get("range", 0)) <= 0.0 or float(s.get("radius", 0)) <= 0.0:
							errors.append("%s: range and radius must be > 0" % where)
		for cid in classes:
			for wt in (classes[cid] as CharacterClass).weapon_types:
				if not weapon_types.has(wt):
					continue  # c-weapon-class already diagnosed the missing reference.
				if (weapon_types[wt] as WeaponType).hands != Hands.OFFHAND and not mv.has(wt):
					errors.append(
						"design.movesets: class %s weapon-type %s has no entry" % [cid, wt]
					)
		var st_input: Variant = design.get("settlement")  # c-settlement-config (D22)
		if (
			_fields_valid(
				st_input,
				"design.settlement",
				{
					"number": "radius blend ring-radius no-hostiles-within",
					"strings": "buildings",
					"object": "npc style-by-landscape style-colors"
				}
			)
			and _fields_valid(st_input.npc, "design.settlement.npc", {"object": "roles"})
		):
			var st: Dictionary = st_input
			var building_config: Variant = configs.get("buildings")
			var bj: Dictionary = building_config if building_config is Dictionary else {}
			var building_rows: Variant = bj.get("buildings")
			if not building_rows is Dictionary:
				building_rows = {}
			var roles := _object(configs.get("npc-roles"))
			if float(st["radius"]) <= float(st["blend"]) or float(st["blend"]) < 0.0:
				errors.append("design.settlement: need radius > blend >= 0")
			if float(st["ring-radius"]) >= float(st["radius"]):
				errors.append("design.settlement.ring-radius must be < radius")
			if float(st["no-hostiles-within"]) < float(st["radius"]):
				errors.append("design.settlement.no-hostiles-within < radius")
			for b in st["buildings"]:
				if not building_rows.has(b):
					errors.append("design.settlement.buildings: unknown building %s" % b)
			for b in st["npc"]["roles"]:
				if not st["npc"]["roles"][b] is String or not roles.has(st["npc"]["roles"][b]):
					errors.append(
						(
							"design.settlement.npc.roles.%s: unknown npc-role %s"
							% [b, st["npc"]["roles"][b]]
						)
					)
			for id in landscapes:
				if (landscapes[id] as Landscape).gen.is_empty():
					continue
				var style = st["style-by-landscape"].get(id)
				if not style is String or not _object(bj.get("settlement-styles")).has(style):
					errors.append(
						(
							"design.settlement.style-by-landscape.%s: missing or unknown style %s"
							% [id, style]
						)
					)
				elif not (
					st["style-colors"].get(style) is Array
					and (st["style-colors"][style] as Array).size() == 2
				):
					errors.append("design.settlement.style-colors.%s: need [wall, roof]" % style)
			_selected_tree(
				st.get("shop"),
				{
					"stock": 8,
					"rarity-cap": "common",
					"level-spread": 1,
					"item-shop-pool": "design.loot.consumable-pool",
					"restock": "daily"
				},
				"design.settlement.shop"
			)
		var df := _object(design.get("defence"))  # c-defence-config (D23)
		var dg := _object(df.get("dodge"))
		if _fields_valid(
			df.get("dodge"),
			"design.defence.dodge",
			{"number": "stamina distance duration-s iframe-s", "object": "on-dodge"}
		):
			if float(dg["stamina"]) <= 0.0 or float(dg["stamina"]) > stamina_max:
				errors.append("design.defence.dodge.stamina outside (0, %d]" % stamina_max)
			if (
				float(dg["distance"]) <= 0.0
				or float(dg["duration-s"]) <= 0.0
				or float(dg["iframe-s"]) < 0.0
			):
				errors.append("design.defence.dodge: distance / duration-s > 0, iframe-s >= 0")
			for id in dg["on-dodge"]:
				if not abilities.has(id) or (abilities[id] as Ability).kind != AbilityKind.PASSIVE:
					errors.append("design.defence.dodge.on-dodge.%s is not a passive" % id)
		var bl := _object(df.get("block"))
		if _fields_valid(
			df.get("block"),
			"design.defence.block",
			{"number": "max power-per-hit damage-reduction front-dot regen-per-s guardian-mult"}
		):
			if float(bl["max"]) <= 0.0 or float(bl["power-per-hit"]) <= 0.0:
				errors.append("design.defence.block: max / power-per-hit must be > 0")
			if float(bl["damage-reduction"]) < 0.0 or float(bl["damage-reduction"]) > 1.0:
				errors.append("design.defence.block.damage-reduction outside [0,1]")
			if absf(float(bl["front-dot"])) > 1.0:
				errors.append("design.defence.block.front-dot outside [-1,1]")
			if float(bl["regen-per-s"]) < 0.0 or float(bl["guardian-mult"]) < 1.0:
				errors.append("design.defence.block: regen-per-s >= 0, guardian-mult >= 1")
		var sl := _object(df.get("stealth"))
		if _fields_valid(
			df.get("stealth"),
			"design.defence.stealth",
			{"number": "decay-per-s still-mult aggro-cut"}
		):
			if float(sl["decay-per-s"]) < 0.0 or float(sl["still-mult"]) < 1.0:
				errors.append("design.defence.stealth: decay-per-s >= 0, still-mult >= 1")
			if float(sl["aggro-cut"]) < 0.0 or float(sl["aggro-cut"]) > 1.0:
				errors.append("design.defence.stealth.aggro-cut outside [0,1]")
		for k in _object(df.get("enemy-hit")):
			var value: Variant = df["enemy-hit"][k]
			if (
				_input_shape(value, "number", "design.defence.enemy-hit." + str(k))
				and (value < 0 or value > 1)
			):
				errors.append("design.defence.enemy-hit.%s outside [0,1]" % k)
		for id in ab:
			if (
				ab[id] is Dictionary
				and ab[id].has("stealth-per-s")
				and _input_shape(
					ab[id]["stealth-per-s"],
					"number",
					"design.abilities." + str(id) + ".stealth-per-s"
				)
				and ab[id]["stealth-per-s"] < 0
			):
				errors.append("design.abilities.%s.stealth-per-s < 0" % id)
		var fl := _object(design.get("feel"))  # c-feel-config (D25)
		var hs := _object(fl.get("hit-stop"))
		var sh := _object(fl.get("shake"))
		var nb := _object(fl.get("numbers"))
		var im := _object(fl.get("impact"))
		var tr := _object(fl.get("trail"))
		var lv := _object(fl.get("level-up"))
		var ev := _object(fl.get("events"))
		var sfx := _object(fl.get("sfx"))
		var alpha_sfx := _array(_object(configs.get("audio")).get("sfx-alpha-ids"))
		if _fields_valid(
			fl.get("hit-stop"), "design.feel.hit-stop", {"number": "time-scale max-s"}
		):
			if float(hs["time-scale"]) <= 0.0 or float(hs["time-scale"]) >= 1.0:
				errors.append("design.feel.hit-stop.time-scale outside (0,1)")
			if float(hs["max-s"]) <= 0.0 or float(hs["max-s"]) > 1.0:
				errors.append("design.feel.hit-stop.max-s outside (0,1]")
		if _fields_valid(
			fl.get("shake"),
			"design.feel.shake",
			{"number": "decay-per-s max-offset shake-mult max-roll-deg"}
		):
			if float(sh["decay-per-s"]) <= 0.0:
				errors.append("design.feel.shake.decay-per-s must be > 0")
			if float(sh["max-offset"]) < 0.0:
				errors.append("design.feel.shake.max-offset must be >= 0")
			if float(sh["shake-mult"]) < 0.0:
				errors.append("design.feel.shake.shake-mult must be >= 0")
			if float(sh["max-roll-deg"]) < 0.0:
				errors.append("design.feel.shake.max-roll-deg must be >= 0")
		for id in [
			"hit",
			"crit",
			"kill",
			"hurt",
			"block",
			"dodge",
			"shoot",
			"impact",
			"level-up",
			"pickup",
			"coin"
		]:
			if not ev.has(id):
				errors.append("design.feel.events missing required event %s" % id)
		for id in ev:
			var event_path := "design.feel.events." + str(id)
			if not _input_shape(ev[id], "object", event_path):
				continue
			var e: Dictionary = ev[id]
			if not _optional_fields_valid(
				e, event_path, {"number": "hit-stop-s trauma", "string": "sfx"}
			):
				continue
			if (
				float(e.get("hit-stop-s", 0)) < 0.0
				or (
					(hs.get("max-s") is int or hs.get("max-s") is float)
					and float(e.get("hit-stop-s", 0)) > float(hs["max-s"])
				)
			):
				errors.append("design.feel.events.%s.hit-stop-s outside [0, max-s]" % id)
			if float(e.get("trauma", 0)) < 0.0 or float(e.get("trauma", 0)) > 1.0:
				errors.append("design.feel.events.%s.trauma outside [0,1]" % id)
			var sid := str(e.get("sfx", ""))
			if not alpha_sfx.has(sid):
				errors.append(
					(
						"design.feel.events.%s.sfx %s is not an audio.json sfx-alpha-ids entry"
						% [id, sid]
					)
				)
			elif not sfx.has(sid):
				errors.append(
					"design.feel.events.%s.sfx %s has no design.feel.sfx entry" % [id, sid]
				)

		for id in sfx:
			if not _fields_valid(
				sfx[id], "design.feel.sfx." + str(id), {"number": "hz len-s noise slide"}
			):
				continue
			var sd: Dictionary = sfx[id]
			if float(sd.get("hz", 0)) <= 0.0:
				errors.append("design.feel.sfx.%s.hz must be > 0" % id)
			if float(sd.get("len-s", 0)) <= 0.0 or float(sd.get("len-s", 0)) > 1.0:
				errors.append("design.feel.sfx.%s.len-s outside (0,1]" % id)
			if float(sd.get("noise", 0)) < 0.0 or float(sd.get("noise", 0)) > 1.0:
				errors.append("design.feel.sfx.%s.noise outside [0,1]" % id)

		if _fields_valid(
			fl.get("numbers"),
			"design.feel.numbers",
			{"number": "life-s crit-scale rise-blocks font-size"}
		):
			if float(nb["life-s"]) <= 0.0:
				errors.append("design.feel.numbers.life-s must be > 0")
			if float(nb["crit-scale"]) < 1.0:
				errors.append("design.feel.numbers.crit-scale must be >= 1")
			if float(nb["rise-blocks"]) <= 0.0:
				errors.append("design.feel.numbers.rise-blocks must be > 0")
			if int(nb["font-size"]) <= 0:
				errors.append("design.feel.numbers.font-size must be > 0")
		var colours := _object(nb.get("colours"))
		if not colours.has("hit"):
			errors.append("design.feel.numbers.colours: required hit fallback")
		for k in colours:
			_input_shape(colours[k], "colour", "design.feel.numbers.colours." + str(k))
		if _fields_valid(
			fl.get("impact"), "design.feel.impact", {"number": "impact-s impact-radius"}
		):
			if float(im["impact-s"]) <= 0.0:
				errors.append("design.feel.impact.impact-s must be > 0")
			if float(im["impact-radius"]) <= 0.0:
				errors.append("design.feel.impact.impact-radius must be > 0")
		if _fields_valid(fl.get("trail"), "design.feel.trail", {"number": "trail-s trail-every-s"}):
			if float(tr["trail-s"]) <= 0.0:
				errors.append("design.feel.trail.trail-s must be > 0")
			if float(tr["trail-every-s"]) <= 0.0:
				errors.append("design.feel.trail.trail-every-s must be > 0")
		if _fields_valid(
			fl.get("level-up"),
			"design.feel.level-up",
			{"number": "pop-s pop-scale", "string": "text"}
		):
			if float(lv["pop-s"]) <= 0.0:
				errors.append("design.feel.level-up.pop-s must be > 0")
			if float(lv["pop-scale"]) < 1.0:
				errors.append("design.feel.level-up.pop-scale must be >= 1")
			if str(lv["text"]).is_empty():
				errors.append("design.feel.level-up.text must not be empty")
		var cr := _object(design.get("creature-roles"))  # c-creature-roles (D26)
		if not cr.is_empty():
			var alpha_sfx2: Array = _array(_object(configs.get("audio")).get("sfx-alpha-ids"))
			var feel_sfx := _object(fl.get("sfx"))
			var role_kinds := ["melee", "ranged", "mage"]
			if str(cr.get("default", "")) not in role_kinds:
				errors.append("design.creature-roles.default must be one of %s" % [role_kinds])
			var ac := _object(cr.get("any-class"))
			var w_sum := 0.0
			for k in ac:
				if not _input_shape(ac[k], "number", "design.creature-roles.any-class." + str(k)):
					continue
				if str(k) not in role_kinds:
					errors.append(
						"design.creature-roles.any-class key %s must be one of %s" % [k, role_kinds]
					)
				if float(ac[k]) < 0.0:
					errors.append("design.creature-roles.any-class.%s must be >= 0" % k)
				w_sum += float(ac[k])
			if w_sum <= 0.0:
				errors.append("design.creature-roles.any-class weights must sum > 0")
			if str(_object(cr.get("melee")).get("kind", "")) != "melee":
				errors.append("design.creature-roles.melee.kind must be melee")
			for rid in ["ranged", "mage"]:
				errors.append_array(
					_role_errors(
						_object(cr.get(rid)),
						"design.creature-roles.%s" % rid,
						se,
						alpha_sfx2,
						feel_sfx
					)
				)
			var override_keys := [
				"range",
				"keep-away",
				"windup-s",
				"cooldown-s",
				"damage-mult",
				"shot",
				"applies",
				"sfx",
				"color"
			]
			for sid in _object(cr.get("species")):
				if not creatures.has(sid):
					errors.append("design.creature-roles.species.%s is not a creature" % sid)
					continue
				var ov_path := "design.creature-roles.species." + str(sid)
				if not _input_shape(cr["species"][sid], "object", ov_path):
					continue
				var ov: Dictionary = cr["species"][sid]
				if not _role_fields_valid(ov, ov_path):
					continue
				for k in ov:
					if not override_keys.has(k):
						errors.append(
							"design.creature-roles.species.%s: unknown override key %s" % [sid, k]
						)
				var role := str((creatures[sid] as Creature).combat_role)
				if role not in role_kinds:
					role = str(cr.get("default", "melee"))
				var merged: Dictionary = _object(cr.get(role)).duplicate(true)
				merged.merge(ov, true)
				if role == "melee":
					if str(merged.get("kind", "")) != "melee":
						errors.append(
							"design.creature-roles.species.%s (merged): kind must be melee" % sid
						)
				else:
					errors.append_array(
						_role_errors(
							merged,
							"design.creature-roles.species.%s (merged)" % sid,
							se,
							alpha_sfx2,
							feel_sfx
						)
					)
		var defaults := rulesets.values().filter(func(r: Ruleset) -> bool: return r.is_default)
		if defaults.size() != 1:
			errors.append("exactly one ruleset must be default (found %d)" % defaults.size())
		return errors.is_empty()
