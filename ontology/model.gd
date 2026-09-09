## Cube World rebuild — typed model derived from ontology/domain.md (Godot 4.7, GDScript 2.0).
##
## One inner Resource class per enumerable ontology class; enums for closed vocabularies;
## `Ontology.load_dir()` reads ontology/instances/*.json into typed resources and
## `Ontology.validate()` enforces the load-time constraints of domain.md §5.
## Runtime-generated content (terrain, bosses, names…) is NOT modelled here: see §6 generators
## and instances/generators.json, which is loaded as a plain Dictionary.
##
## Sync rule: change domain.md first, then this file, then instances/.
extends RefCounted
class_name CubeWorldModel

# --- closed vocabularies -----------------------------------------------------------------

enum Version { A, S, OMEGA, X }                  # alpha 0.1.x, steam 1.0, omega (announced), cut
enum Hostility { FRIENDLY_PLAYER = 0, HOSTILE = 1, FRIENDLY = 2, NAMED_FRIENDLY = 3, TARGET = 6 }
enum ClassType { NONE = 0, WARRIOR = 1, RANGER = 2, MAGE = 3, ROGUE = 4 }   # cuwo ids
enum Rarity { WORN = -1, COMMON = 0, UNCOMMON = 1, RARE = 2, EPIC = 3, LEGENDARY = 4, MYTHICAL = 5 }
enum AbilityKind { ACTIVE, PASSIVE, SHARED_PASSIVE, MOVEMENT }
enum CreatureCategory { ANIMAL, INSECT, AQUATIC, PLANT_CREATURE, MONSTER, UNDEAD, DEMON, ELEMENTAL,
	HUMANOID, BOSS_SPECIES, STATIC_TARGET, UNUSED }
enum Hands { ONE_HANDED, TWO_HANDED, OFFHAND, NONE }
enum MissionTier { WHITE, GREEN, BLUE, PURPLE, YELLOW }

const VERSION_TAGS := {"A": Version.A, "S": Version.S, "Ω": Version.OMEGA, "X": Version.X}
const MAX_CUBES_1H := 16
const MAX_CUBES_2H := 32
const MP_MAX := 100.0
const SKILL_POINTS_PER_LEVEL := 2
const BLOCK_NATIVE_UNITS := 65536

# --- helpers ---------------------------------------------------------------------------------

## Alpha level → power (+1..+100). domain.md §3.5 level-formula.
static func power_for_level(level: int) -> int:
	return int((101.0 * level - 81.0) / (level + 19.0))

## Alpha XP needed to leave `level`. cuwo common.py.
static func xp_to_next(level: int) -> int:
	return int(1050.0 - 1000.0 / (0.05 * (level - 1) + 1.0))

## Alpha item/character base curve. stats.json#alpha-item-stat-formulas.
static func stat_curve(n: float, rarity: int) -> float:
	return pow(2.0, (1.0 - 1.0 / ((n - 1.0) * 0.05 + 1.0)) * 3.0) * pow(2.0, rarity * 0.25)

# --- resource classes (one per enumerable ontology class) ------------------------------

class Entry extends Resource:                    # common base: stable id + versions
	@export var id: StringName = &""
	@export var display_name: String = ""
	@export var versions: Array[Version] = []
	@export var raw: Dictionary = {}              # untouched JSON row for fields not typed yet

	## Parse a version tag list like ["A","S"]; unknown tags (e.g. "A?", "S?") map to their base.
	static func parse_versions(tags: Variant) -> Array[Version]:
		var out: Array[Version] = []
		for t in (tags if tags is Array else []):
			var key: String = str(t).trim_suffix("?")
			if VERSION_TAGS.has(key):
				out.append(VERSION_TAGS[key])
		return out

class Race extends Entry:
	@export var playable := true
	@export var size_class: StringName = &"normal"

class CharacterClass extends Entry:
	@export var id_number: ClassType = ClassType.NONE
	@export var weapon_types: Array[StringName] = []
	@export var armor_material: StringName = &""
	@export var specializations: Array[StringName] = []
	@export var special_attack_mode: StringName = &"charged"   # charged | instant
	@export var hp_mult := 1.0                                  # D15: stats.json#player-hp class multiplier

class Specialization extends Entry:
	@export var character_class: StringName = &""
	@export var index := 0                                     # cuwo spec byte
	@export var kit_a: Array[StringName] = []
	@export var kit_s: Array[StringName] = []
	@export var passives_a: Array[StringName] = []
	@export var passives_s: Array[StringName] = []

class Ability extends Entry:
	@export var kind: AbilityKind = AbilityKind.ACTIVE
	@export var owner: Variant                                 # class / spec id, "all", or Array
	@export var input: Dictionary = {}                         # {"A": "1", "S": "r"}
	@export var cost: Dictionary = {}
	@export var cooldown_s: Variant
	@export var duration_s: Variant
	@export var effect: String = ""
	@export var applies: Array[StringName] = []                # status-effect ids
	@export var alpha_ability_id := -1
	@export var alpha_tree: Dictionary = {}                    # {column, rank, needs, skill-slot}

class WeaponType extends Entry:
	@export var subtype := -1
	@export var character_class: StringName = &""
	@export var hands: Hands = Hands.NONE
	@export var damage_k := 0
	@export var cube_capacity := 0
	@export var combo_cap := -1                                # -1 = undocumented

class MaterialDef extends Entry:            # MaterialDef: "Material" hides the native class
	@export var material_id := -1
	@export var kind: StringName = &""
	@export var obtainable := true

class RarityDef extends Entry:
	@export var index: Rarity = Rarity.COMMON
	@export var color: StringName = &""
	@export var stars := 0
	@export var gem: StringName = &""
	@export var named := false

class Creature extends Entry:
	@export var alpha_entity_id := -1
	@export var family: StringName = &""
	@export var category: CreatureCategory = CreatureCategory.ANIMAL
	@export var hostility: StringName = &"P"                   # P N H V F (+ notes)
	@export var lands: Array[StringName] = []
	@export var group_size := Vector2i(1, 1)
	@export var tame_food: StringName = &""                    # "" = untameable
	@export var rideable := false
	@export var boss_species := false
	@export var boss_capable := false
	@export var drops: Array[StringName] = []

class PetFood extends Entry:
	@export var subtype := -1                                  # == creature id it tames
	@export var tames: StringName = &""
	@export var rideable := false
	@export var shop := false

class Landscape extends Entry:
	@export var climate: Dictionary = {}
	@export var hazards: Array[StringName] = []
	@export var dungeon_types: Array[StringName] = []
	@export var style: String = ""
	@export var gen: Dictionary = {}                            # D12: relief, base, surface, top, cliff

class StatusEffect extends Entry:
	@export var kind: StringName = &""
	@export var sources: Array[StringName] = []
	@export var countered_by: Array[StringName] = []

class Consumable extends Entry:
	@export var kind: StringName = &""                         # food | potion | elixir | beverage | bomb
	@export var use: StringName = &""                          # sit | channel | throw
	@export var heal_mult := 0
	@export var duration_s := 0
	@export var recipe: Dictionary = {}
	@export var station: String = ""

class KeyItem extends Entry:
	@export var group: StringName = &""

class Ruleset extends Entry:
	@export var flags: Dictionary = {}
	@export var is_default := false

# --- loader + constraint checker -----------------------------------------------------------

class Ontology extends RefCounted:
	var races := {}; var classes := {}; var specs := {}; var abilities := {}
	var weapon_types := {}; var materials := {}; var rarities := {}
	var creatures := {}; var pet_foods := {}; var landscapes := {}
	var status_effects := {}; var consumables := {}; var key_items := {}; var rulesets := {}
	var configs := {}          # every other instances file, verbatim (ui, keybinds, generators…)
	var errors: PackedStringArray = []

	static func load_dir(dir_path: String) -> Ontology:
		var o := Ontology.new()
		var dir := DirAccess.open(dir_path)
		if dir == null:
			o.errors.append("cannot open %s" % dir_path); return o
		for file in dir.get_files():
			if not file.ends_with(".json"): continue
			var text := FileAccess.get_file_as_string(dir_path.path_join(file))
			var data: Variant = JSON.parse_string(text)
			if data == null:
				o.errors.append("invalid JSON: %s" % file); continue
			o._ingest(file.get_basename(), data)
		return o

	func _rows(data: Dictionary) -> Dictionary:               # skip "$schema", "_doc", "_x" keys
		var out := {}
		for k in data:
			if str(k).begins_with("$") or str(k).begins_with("_"): continue
			if data[k] is Dictionary: out[k] = data[k]
		return out

	func _fill(e: Entry, id: String, row: Dictionary) -> void:
		e.id = StringName(id)
		e.display_name = str(row.get("name", id))
		e.versions = Entry.parse_versions(row.get("versions", row.get("v", [])))
		e.raw = row

	func _ingest(name: String, data: Variant) -> void:
		if not data is Dictionary: configs[name] = data; return
		match name:
			"races":
				for id in _rows(data):
					var r := Race.new(); _fill(r, id, data[id])
					r.playable = bool(data[id].get("playable", false))
					r.size_class = StringName(str(data[id].get("size-class", "normal")))
					races[id] = r
			"classes":
				for id in _rows(data):
					var c := CharacterClass.new(); _fill(c, id, data[id])
					c.id_number = int(data[id].get("id-number", 0)) as ClassType
					c.weapon_types.assign(data[id].get("weapon-types", []))
					c.armor_material = StringName(str(data[id].get("armor-material", "")))
					c.specializations.assign(data[id].get("specializations", []))
					c.special_attack_mode = StringName(str(data[id].get("special-attack-mode", "charged")))
					c.hp_mult = float(data[id].get("hp-mult", 1.0))
					classes[id] = c
			"specializations":
				for id in _rows(data):
					var s := Specialization.new(); _fill(s, id, data[id])
					s.character_class = StringName(str(data[id].get("class", "")))
					s.index = int(data[id].get("index", 0))
					s.kit_a.assign(data[id].get("kit", {}).get("A", []))
					s.kit_s.assign(data[id].get("kit", {}).get("S", []))
					s.passives_a.assign(data[id].get("passives", {}).get("A", []))
					s.passives_s.assign(data[id].get("passives", {}).get("S", []))
					specs[id] = s
			"abilities":
				for id in _rows(data):
					var a := Ability.new(); _fill(a, id, data[id])
					a.kind = {"active": AbilityKind.ACTIVE, "passive": AbilityKind.PASSIVE,
						"shared-passive": AbilityKind.SHARED_PASSIVE, "movement": AbilityKind.MOVEMENT
						}.get(str(data[id].get("kind", "active")), AbilityKind.ACTIVE)
					a.owner = data[id].get("owner"); a.input = data[id].get("input", {})
					a.cost = data[id].get("cost", {}); a.cooldown_s = data[id].get("cooldown-s")
					a.duration_s = data[id].get("duration-s"); a.effect = str(data[id].get("effect", ""))
					a.applies.assign(data[id].get("applies", []))
					a.alpha_ability_id = int(data[id].get("alpha-id", -1))
					a.alpha_tree = data[id].get("alpha-tree", {})
					abilities[id] = a
			"weapon-types":
				for id in _rows(data):
					var w := WeaponType.new(); _fill(w, id, data[id])
					w.subtype = int(data[id].get("subtype", -1) if data[id].get("subtype") != null else -1)
					w.character_class = StringName(str(data[id].get("class", "")))
					var h := str(data[id].get("hands", ""))
					w.hands = Hands.TWO_HANDED if h.begins_with("2h") else Hands.OFFHAND if h == "offhand" \
						else Hands.ONE_HANDED if h.begins_with("1h") else Hands.NONE
					w.damage_k = int(data[id].get("damage-k", 0)); w.cube_capacity = int(data[id].get("cube-capacity", 0))
					w.combo_cap = int(data[id].get("combo-cap", -1) if data[id].get("combo-cap") != null else -1)
					weapon_types[id] = w
			"materials":
				for id in _rows(data):
					var m := MaterialDef.new(); _fill(m, id, data[id])
					m.material_id = int(data[id].get("id", -1) if data[id].get("id") != null else -1)
					m.kind = StringName(str(data[id].get("kind", ""))); m.obtainable = bool(data[id].get("obtainable", true))
					materials[id] = m
			"rarities":
				for id in _rows(data):
					if not data[id].has("index"): continue
					var r := RarityDef.new(); _fill(r, id, data[id])
					r.index = int(data[id]["index"]) as Rarity; r.color = StringName(str(data[id].get("color", "")))
					r.stars = int(data[id].get("stars", 0) if data[id].get("stars") != null else 0)
					r.gem = StringName(str(data[id].get("gem", "") if data[id].get("gem") != null else ""))
					r.named = bool(data[id].get("named", false))
					rarities[id] = r
			"creatures":
				for id in _rows(data):
					var c := Creature.new(); _fill(c, id, data[id])
					c.alpha_entity_id = int(data[id].get("aid", -1) if data[id].get("aid") != null else -1)
					c.family = StringName(str(data[id].get("family", "")))
					c.category = {"animal": CreatureCategory.ANIMAL, "insect": CreatureCategory.INSECT,
						"aquatic": CreatureCategory.AQUATIC, "plant-creature": CreatureCategory.PLANT_CREATURE,
						"monster": CreatureCategory.MONSTER, "undead": CreatureCategory.UNDEAD,
						"demon": CreatureCategory.DEMON, "elemental": CreatureCategory.ELEMENTAL,
						"humanoid": CreatureCategory.HUMANOID, "boss-species": CreatureCategory.BOSS_SPECIES,
						"static-target": CreatureCategory.STATIC_TARGET
						}.get(str(data[id].get("cat", "unused")), CreatureCategory.UNUSED)
					c.hostility = StringName(str(data[id].get("h", "P")).left(1))    # "P (rarely H)" → base letter
					c.lands.assign(data[id].get("lands", []))
					var g: Variant = data[id].get("group")
					if g is Array and g.size() == 2: c.group_size = Vector2i(int(g[0]), int(g[1]))
					c.tame_food = StringName(str(data[id].get("tame", "") if data[id].get("tame") != null else ""))
					c.rideable = data[id].get("ride", false) == true
					c.boss_species = bool(data[id].get("boss", false)); c.boss_capable = bool(data[id].get("bossable", false))
					c.drops.assign(data[id].get("drops", []))
					creatures[id] = c
			"pet-food":
				for id in _rows(data.get("foods", {})):
					var row: Dictionary = data["foods"][id]
					var f := PetFood.new(); _fill(f, id, row)
					if f.versions.is_empty(): f.versions = [Version.A, Version.S]
					f.subtype = int(row.get("id", -1)); f.tames = StringName(str(row.get("tames", "")))
					f.rideable = row.get("rideable", false) == true; f.shop = bool(row.get("shop", false))
					pet_foods[id] = f
			"landscapes":
				for id in _rows(data):
					var l := Landscape.new(); _fill(l, id, data[id])
					l.climate = data[id].get("climate", {}); l.hazards.assign(data[id].get("hazards", []))
					l.dungeon_types.assign(data[id].get("dungeons", [])); l.style = str(data[id].get("style", ""))
					l.gen = data[id].get("gen", {})
					landscapes[id] = l
			"status-effects":
				for id in _rows(data):
					if not data[id].has("kind"): continue
					var s := StatusEffect.new(); _fill(s, id, data[id])
					s.kind = StringName(str(data[id]["kind"])); s.sources.assign(data[id].get("sources", []))
					s.countered_by.assign(data[id].get("countered-by", []))
					status_effects[id] = s
			"consumables":
				for id in _rows(data):
					if not data[id].has("kind"): continue
					var c := Consumable.new(); _fill(c, id, data[id])
					c.kind = StringName(str(data[id]["kind"])); c.use = StringName(str(data[id].get("use", "")))
					c.heal_mult = int(data[id].get("heal-mult", 0)); c.duration_s = int(data[id].get("duration-s", 0))
					c.recipe = data[id].get("recipe", {}) if data[id].get("recipe") is Dictionary else {}
					c.station = str(data[id].get("station", ""))
					consumables[id] = c
			"key-items":
				for id in _rows(data):
					if not data[id].has("group"): continue
					var k := KeyItem.new(); _fill(k, id, data[id]); k.group = StringName(str(data[id]["group"]))
					key_items[id] = k
			"rulesets":
				for id in _rows(data):
					var r := Ruleset.new(); _fill(r, id, data[id])
					r.flags = data[id].get("flags", {}); r.is_default = bool(data[id].get("default", false))
					rulesets[id] = r
			_:
				configs[name] = data

	## domain.md §5 load-time constraints. Returns true when no errors were added.
	func validate() -> bool:
		var n := errors.size()
		for id in specs:                                                    # c-spec-of-class
			var s: Specialization = specs[id]
			if not classes.has(s.character_class): errors.append("spec %s: unknown class %s" % [id, s.character_class])
			elif not (classes[s.character_class] as CharacterClass).specializations.has(StringName(id)):
				errors.append("class %s does not list spec %s" % [s.character_class, id])
			for a in s.kit_a + s.kit_s + s.passives_a + s.passives_s:
				if not abilities.has(a): errors.append("spec %s: unknown ability %s" % [id, a])
		for id in classes:
			for w in (classes[id] as CharacterClass).weapon_types:
				if not weapon_types.has(w): errors.append("class %s: unknown weapon-type %s" % [id, w])
		for id in pet_foods:                                                # c-food-id + tamed-by
			var f: PetFood = pet_foods[id]
			if not creatures.has(f.tames): errors.append("pet-food %s tames unknown creature %s" % [id, f.tames]); continue
			var c: Creature = creatures[f.tames]
			if c.tame_food != StringName(id): errors.append("pet-food %s ↔ creature %s tame mismatch" % [id, f.tames])
			if c.alpha_entity_id >= 0 and c.alpha_entity_id != f.subtype:
				errors.append("pet-food %s subtype %d != creature id %d" % [id, f.subtype, c.alpha_entity_id])
		for id in creatures:
			var c: Creature = creatures[id]
			if c.tame_food != &"" and not pet_foods.has(c.tame_food): errors.append("creature %s: unknown food %s" % [id, c.tame_food])
		for id in weapon_types:                                             # c-cube-cap
			var w: WeaponType = weapon_types[id]
			if w.cube_capacity not in [0, MAX_CUBES_1H, MAX_CUBES_2H]: errors.append("weapon %s: bad cube capacity" % id)
		for id in rarities:                                                 # c-rarity-range
			if (rarities[id] as RarityDef).index > Rarity.MYTHICAL: errors.append("rarity %s out of range" % id)
		for id in abilities:
			for s in (abilities[id] as Ability).applies:
				if not status_effects.has(s): errors.append("ability %s applies unknown status %s" % [id, s])
		for dict in [races, classes, specs, abilities, weapon_types, materials, creatures, landscapes, consumables, key_items]:
			for id in dict:                                                 # c-versions-nonempty
				if (dict[id] as Entry).versions.is_empty(): errors.append("%s has no version tag" % id)
		var rosters: Dictionary = configs.get("creature-families", {}).get("landscape-rosters", {})
		for land in rosters:                                                # c-roster-ids
			for cid in rosters[land]:
				if not creatures.has(cid): errors.append("roster %s: unknown creature %s" % [land, cid])
		var ai: Dictionary = configs.get("generators", {}).get("design", {}).get("spawns", {}).get("ai", {})
		if ai.has("sim-radius") and float(ai["sim-radius"]) < float(ai.get("aggro-range", 0)) + float(ai.get("leash", 0)):   # c-sim-radius
			errors.append("design.spawns.ai.sim-radius %s < aggro-range + leash" % ai["sim-radius"])
		var design: Dictionary = configs.get("generators", {}).get("design", {})
		var loot: Dictionary = design.get("loot", {})                     # c-loot-config (D18)
		if not loot.is_empty():
			var item_types: Dictionary = configs.get("item-types", {})
			for k in ["gear-chance", "consumable-chance", "species-drop-chance"]:
				if float(loot[k]) < 0.0 or float(loot[k]) > 1.0: errors.append("design.loot.%s out of [0,1]" % k)
			if float(loot["coins"]["chance"]) < 0.0 or float(loot["coins"]["chance"]) > 1.0: errors.append("design.loot.coins.chance out of [0,1]")
			if int(loot["level-spread"]) < 0: errors.append("design.loot.level-spread < 0")
			var wsum := 0.0
			for r in loot["rarity-weights"]:
				if not rarities.has(r) or (rarities[r] as RarityDef).index > Rarity.LEGENDARY: errors.append("design.loot.rarity-weights: bad rarity %s" % r)
				wsum += float(loot["rarity-weights"][r])
			if wsum <= 0.0: errors.append("design.loot.rarity-weights sum to 0")
			for t in loot["gear-kinds"].keys() + design.get("stack-cap", {}).get("stackable", []):
				if not item_types.has(t): errors.append("design.loot/stack-cap: unknown item-type %s" % t)
			for c in loot["consumable-pool"]:
				if not consumables.has(c): errors.append("design.loot.consumable-pool: unknown consumable %s" % c)
		var defaults := rulesets.values().filter(func(r: Ruleset) -> bool: return r.is_default)
		if defaults.size() != 1: errors.append("exactly one ruleset must be default (found %d)" % defaults.size())
		return errors.size() == n
