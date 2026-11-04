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


const Loader := preload("res://ontology/model_loader.gd")

const Catalogs := preload("res://ontology/model_catalogs.gd")
const World := preload("res://ontology/model_world.gd")
const Encounters := preload("res://ontology/model_encounters.gd")
const Combat := preload("res://ontology/model_combat.gd")
const Equipment := preload("res://ontology/model_equipment.gd")
const Identity := preload("res://ontology/model_identity.gd")
const Roles := preload("res://ontology/model_roles.gd")

# --- loader + constraint checker -----------------------------------------------------------


class Ontology:
	extends "res://ontology/model_ontology.gd"

	static func load_dir(dir_path: String) -> Ontology:
		var o := Ontology.new()
		var dir := DirAccess.open(dir_path)
		if dir == null:
			o.errors.append("cannot open %s" % dir_path)
			return o
		for file in dir.get_files():
			load_file(o, dir_path, file)
		return o

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
		var types := {
			"Race": Race,
			"CharacterClass": CharacterClass,
			"Specialization": Specialization,
			"Ability": Ability,
			"WeaponType": WeaponType,
			"MaterialDef": MaterialDef,
			"RarityDef": RarityDef,
			"Creature": Creature,
			"PetFood": PetFood,
			"Landscape": Landscape,
			"StatusEffect": StatusEffect,
			"Consumable": Consumable,
			"KeyItem": KeyItem,
			"Ruleset": Ruleset
		}
		var vocabulary := {
			"AbilityKind": AbilityKind, "Hands": Hands, "CreatureCategory": CreatureCategory
		}
		Loader.ingest(self, name, data, types, vocabulary)

	## domain/index.md §5 load-time constraints. Returns true when no errors were added.
	## D20: the skill-tree nodes a (class, spec) pair can spend points on — the shared columns, the class
	## column (its spec-specific rank) and the spec's ultimate — in screen order. `alpha-tree.class` wins
	## over `owner` (sneak's owner is a per-version list).
	func skill_tree(class_id: StringName, spec_id: StringName) -> Array:
		var out: Array = []
		for id in abilities:
			var a: Ability = abilities[id]
			if Identity.tree_node_visible(self, id, a.alpha_tree, a, class_id, spec_id):
				out.append(a)
		out.sort_custom(func(x: Ability, y: Ability) -> bool: return _tree_key(x) < _tree_key(y))
		return out

	static func _tree_key(a: Ability) -> int:
		var t := a.alpha_tree
		if str(t["column"]) == "class":
			return 100 + int(t.get("rank", 0))
		return 104 if str(t["column"]) == "ultimate" else int(t.get("skill-slot", 0))

	## c-moveset-config / c-ability-runtime (D24): a projectile shot (moveset, ultimate or dash `throw`).
	## c-creature-roles (D26): a ranged/mage role dict from design.creature-roles (or a species-merged one).
	# c-slot-accepts / c-weapon-class / c-hands / c-cube-cap: selected equipment contract.
	func _validate_equipment_weapons() -> bool:
		for id in weapon_types:
			var w: WeaponType = weapon_types[id]
			var raw: Dictionary = w.raw
			var class_owned := Equipment.class_owned(
				w.hands, Hands.NONE, w.character_class, classes
			)
			for class_id in classes:
				class_owned = Equipment.class_lists_weapon(
					class_owned, (classes[class_id] as CharacterClass).weapon_types, id
				)
			var active := Equipment.weapon_active(self, id, raw, class_owned, w.hands, Hands.NONE)
			if Equipment.weapon_owner_exists(self, id, raw, active):
				var owner: Variant = raw.get("class")
				Equipment.weapon_owner_lists(
					self, id, owner, (classes[owner] as CharacterClass).weapon_types
				)
			if active:
				Equipment.weapon_capacity_material(
					self, id, raw, class_owned, w.hands, Hands, MAX_CUBES_1H, MAX_CUBES_2H
				)
		return _validate_wand_definition()

	func _validate_wand_definition() -> bool:
		var wand: WeaponType = weapon_types.get(&"wand")
		return Equipment.wand_definition(self, wand, Hands.TWO_HANDED, MAX_CUBES_2H)

	# c-control-references: only the selected Android first-slice input is enforced here.
	# Current selected encounter inputs, not a default or a legacy schema.
	func _validate_hybrid_count() -> bool:
		var hybrid: Ruleset = rulesets.get(&"ruleset-hybrid")
		if hybrid == null:
			errors.append("rulesets.ruleset-hybrid: required object missing or malformed")
			return true
		return Encounters.hybrid_flags(self, hybrid.raw)

	# Guard only fields consumed by the moveset numeric/reference checks below.
	# Finite required identity boundary; raw metadata is not a race row.
	# Only district buildings and landscape dungeon/POI IDs, not descriptive world strings.
	static func _tree_field_errors(tree: Variant, path: String) -> Array:
		return Identity.tree_field_errors(tree, path, _identity_integer, _is_selected_multiplier)

	static func _identity_row_errors(catalog: String, row: Variant, path: String) -> Array:
		return Identity.row_errors(
			catalog, row, path, _identity_strings, _identity_integer, _tree_field_errors
		)

	func _validate_identity_trees() -> bool:
		for id in abilities:
			var a: Ability = abilities[id]
			Identity.identity_tree(self, id, a.alpha_tree, a)
		return true

	func validate() -> bool:
		_validate_required_inputs()
		_validate_identity()
		_validate_races()
		_validate_world_references()
		_validate_equipment()
		_validate_android()
		_validate_provenance()
		Equipment.apple_input(self)
		var apple: Consumable = consumables.get(&"apple")
		if apple == null:
			errors.append("consumables.apple: required loaded consumable")
		else:
			Equipment.apple_loaded(self, apple.raw, apple.heal_mult)
		return _validate_spec_links()

	func _validate_spec_links() -> bool:
		for id in specs:
			var s: Specialization = specs[id]
			if Identity.spec_class_exists(self, id, s.character_class):
				Identity.spec_class_link(
					self,
					id,
					s.character_class,
					(classes[s.character_class] as CharacterClass).specializations
				)
			Identity.spec_abilities(self, id, s.kit_a + s.kit_s + s.passives_a + s.passives_s)
		return _validate_class_links()

	func _validate_class_links() -> bool:
		for id in classes:
			var c: CharacterClass = classes[id]
			Identity.class_specializations(self, id, c.specializations)
			for w in c.weapon_types:
				if Identity.class_weapon_exists(self, id, w):
					Identity.class_weapon_owner(self, id, w, (weapon_types[w] as WeaponType).raw)
		return _validate_food_links()

	func _validate_food_links() -> bool:
		for id in pet_foods:
			var f: PetFood = pet_foods[id]
			if Identity.tamed_creature_exists(self, id, f.tames):
				var c: Creature = creatures[f.tames]
				Identity.tame_pair(self, id, f, c.tame_food, c.alpha_entity_id)
		return _validate_creature_foods()

	func _validate_creature_foods() -> bool:
		for id in creatures:
			var c: Creature = creatures[id]
			if c.tame_food != &"" and not pet_foods.has(c.tame_food):
				errors.append("creature %s: unknown food %s" % [id, c.tame_food])
		return _validate_capacities()

	func _validate_capacities() -> bool:
		for id in weapon_types:  # c-cube-cap
			var w: WeaponType = weapon_types[id]
			if w.cube_capacity not in [0, MAX_CUBES_1H, MAX_CUBES_2H]:
				errors.append("weapon %s: bad cube capacity" % id)
		return _validate_rarity_range()

	func _validate_rarity_range() -> bool:
		for id in rarities:  # c-rarity-range
			if (rarities[id] as RarityDef).index > Rarity.MYTHICAL:
				errors.append("rarity %s out of range" % id)
		return _validate_ability_statuses()

	func _validate_ability_statuses() -> bool:
		for id in abilities:
			Identity.ability_statuses(self, id, (abilities[id] as Ability).applies)
		return _validate_catalog_tags()

	func _validate_catalog_tags() -> bool:
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
				Identity.catalog_tags(self, id, row)
		return Catalogs.validate_rosters(self)

	func _validate_hp_materials(design: Dictionary) -> bool:
		var hp_materials := {"iron": 1.0, "cotton": 0.75, "linen": 0.5}
		for id in hp_materials:
			if materials.has(id):
				Equipment.material_multiplier(
					self,
					id,
					(materials[id] as MaterialDef).raw,
					"hp-bonus",
					hp_materials[id],
					"bonus"
				)
			else:
				Equipment.missing_material_multiplier(
					self, id, "hp-bonus", hp_materials[id], "bonus"
				)
		return _validate_resistance_materials(design)

	func _validate_resistance_materials(design: Dictionary) -> bool:
		var resistance_materials := {"iron": 0.85, "linen": 0.75, "cotton": 0.75, "silk": 1.0}
		for id in resistance_materials:
			if materials.has(id):
				Equipment.material_multiplier(
					self,
					id,
					(materials[id] as MaterialDef).raw,
					"resi-mult",
					resistance_materials[id],
					"active multiplier"
				)
			else:
				Equipment.missing_material_multiplier(
					self, id, "resi-mult", resistance_materials[id], "active multiplier"
				)
		return Equipment.validate_hp_slots(self, design)

	func _validate_loot(design: Dictionary) -> bool:
		return Equipment.validate_loot(self, design, Rarity.LEGENDARY)

	func _validate_reward_catalogs(design: Dictionary) -> bool:
		Equipment.reward_prerequisites(self)
		for id in ["warrior", "ranger", "rogue", "mage"]:
			if Equipment.reward_class_exists(self, id):
				var cls: CharacterClass = classes[id]
				Equipment.reward_class(self, id, cls.armor_material, cls.weapon_types)
		return Identity.validate_progression(self, design)

	func _validate_skill_trees(design: Dictionary) -> bool:
		for id in specs:
			var s: Specialization = specs[id]
			var ranks := {}
			var ults := 0
			var roots := {"pets": 0, "climbing": 0, "water": 0}
			var nodes := skill_tree(s.character_class, StringName(id))
			for a in nodes:
				var t: Dictionary = (a as Ability).alpha_tree
				var col := str(t["column"])
				ults += Identity.tree_node_counts(self, a, t, col, nodes, ranks, roots)
				var nxt := StringName(str((a as Ability).raw.get("unlocks-next", "")))
				if Identity.tree_next_exists(self, a.id, nxt, nodes, col):
					Identity.tree_next_column(
						self, a.id, nxt, (abilities[nxt] as Ability).alpha_tree, col
					)
			Identity.tree_counts(self, id, ranks, ults)
			_check_assassin_tree(id, nodes)
			Identity.tree_roots(self, id, roots)
		return _validate_ability_runtimes(design)

	func _check_assassin_tree(id, nodes: Array) -> void:
		if id == "assassin":
			var cam: Ability = abilities.get("camouflage")
			var sneak: Ability = abilities.get("sneak")
			Identity.assassin_tree(self, nodes, cam, sneak)

	func _validate_runtime_tree(
		id, ab: Dictionary, stamina_max: float, runtimes: Array, seen: Dictionary
	) -> bool:
		for a in skill_tree((specs[id] as Specialization).character_class, StringName(id)):
			var col := str((a as Ability).alpha_tree["column"])
			if not Combat.process_runtime_node(self, a, col, seen, ab, stamina_max, runtimes):
				return false
		return true

	func _validate_moveset_coverage(
		design: Dictionary, ab: Dictionary, stamina_max: float, se: Dictionary, mv: Dictionary
	) -> bool:
		for cid in classes:
			for wt in (classes[cid] as CharacterClass).weapon_types:
				if weapon_types.has(wt):
					Combat.moveset_coverage(
						self, cid, wt, (weapon_types[wt] as WeaponType).hands, Hands.OFFHAND, mv
					)
		return World.validate_settlement_runtime(self, design, ab, stamina_max, se)

	func _validate_settlement_landscapes(
		design: Dictionary,
		ab: Dictionary,
		stamina_max: float,
		se: Dictionary,
		st: Dictionary,
		bj: Dictionary
	) -> bool:
		for id in landscapes:
			if (landscapes[id] as Landscape).gen.is_empty():
				continue
			World.settlement_landscape(self, id, st, bj)
		World.settlement_shop(self, st)
		return _validate_defence(design, ab, stamina_max, se)

	func _validate_dodge_passives(
		design: Dictionary,
		ab: Dictionary,
		_stamina_max: float,
		se: Dictionary,
		df: Dictionary,
		dg: Dictionary
	) -> bool:
		for id in dg["on-dodge"]:
			if Combat.dodge_ability_exists(self, id):
				Combat.dodge_ability_kind(
					self, id, (abilities[id] as Ability).kind, AbilityKind.PASSIVE
				)
		return Combat.validate_defence_block(self, design, ab, se, df)

	# True means row processing completed, including ordinary invalid/skipped rows.
	# A native abort implicitly returns false, so the enclosing loop must stop.
	func _process_species_row(
		cr: Dictionary, sid, se: Dictionary, alpha_sfx: Array, feel_sfx: Dictionary, kinds: Array
	) -> bool:
		if creatures.has(sid):
			var path := "design.creature-roles.species." + str(sid)
			if _input_shape(cr["species"][sid], "object", path):
				var ov: Dictionary = cr["species"][sid]
				if _role_fields_valid(ov, path):
					Roles.species_keys(self, sid, ov)
					var role := str((creatures[sid] as Creature).combat_role)
					Roles.species_role(self, cr, sid, ov, role, kinds, se, alpha_sfx, feel_sfx)
		else:
			errors.append("design.creature-roles.species.%s is not a creature" % sid)
		return true

	func _validate_defaults() -> bool:
		var defaults := rulesets.values().filter(func(r: Ruleset) -> bool: return r.is_default)
		if defaults.size() != 1:
			errors.append("exactly one ruleset must be default (found %d)" % defaults.size())
		return errors.is_empty()
