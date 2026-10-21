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

## Alpha level → power (+1..+100). domain/index.md §3.5 level-formula.
static func power_for_level(level: int) -> int:
	return int((101.0 * level - 81.0) / (level + 19.0))

## Alpha XP needed to leave `level`. cuwo common.py.
static func xp_to_next(level: int) -> int:
	return int(1050.0 - 1000.0 / (0.05 * (level - 1) + 1.0))

## D19: XP awarded to a player for a kill. design.progression.
static func xp_for_kill(creature_level: int, player_level: int, prog: Dictionary) -> int:
	var r: Array = prog["gap-mult-range"]
	var mult := clampf(1.0 + float(prog["gap-per-level"]) * (creature_level - player_level), float(r[0]), float(r[1]))
	return int(xp_to_next(creature_level) * float(prog["kill-fraction"]) * mult)

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
	## Legacy API name: numeric source entity ID (alpha or post-alpha), -1 = unrecorded.
	## JSON `aid` and this field keep their names; an ID alone does not establish version provenance.
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
	@export var combat_role: StringName = &""                  # D26: melee|ranged|mage|any-class|"" (parsed from `role`)

class PetFood extends Entry:
	@export var subtype := -1                                  # numeric source entity ID, including post-alpha
	@export var tames: StringName = &""                         # stable ontology creature ID
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
					var raw_h: Variant = data[id].get("hands")
					var h: String = raw_h if raw_h is String else ""
					w.hands = Hands.TWO_HANDED if h == "2h" else Hands.OFFHAND if h == "offhand" \
						else Hands.ONE_HANDED if h == "1h" or h == "1h dual (need two)" else Hands.NONE
					w.damage_k = int(data[id].get("damage-k", 0))
					var capacity: Variant = data[id].get("cube-capacity")
					w.cube_capacity = int(capacity) if capacity is int or capacity is float else 0
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
					var role_str := str(data[id].get("role", "") if data[id].get("role") != null else "")   # D26: first keyword wins
					if role_str.contains("any-class"): c.combat_role = &"any-class"
					elif role_str.contains("ranged"): c.combat_role = &"ranged"
					elif role_str.contains("mage"): c.combat_role = &"mage"
					elif role_str.contains("melee"): c.combat_role = &"melee"
					else: c.combat_role = &""
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

	## domain/index.md §5 load-time constraints. Returns true when no errors were added.
	## D20: the skill-tree nodes a (class, spec) pair can spend points on — the shared columns, the class
	## column (its spec-specific rank) and the spec's ultimate — in screen order. `alpha-tree.class` wins
	## over `owner` (sneak's owner is a per-version list).
	func skill_tree(class_id: StringName, spec_id: StringName) -> Array:
		var out: Array = []
		for id in abilities:
			var a: Ability = abilities[id]
			if a.alpha_tree.is_empty():
				continue
			var owner := StringName(str(a.alpha_tree.get("class", a.owner if a.owner is String else "")))
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
		if float(s.get("speed", 0)) <= 0.0 or float(s.get("radius", 0)) <= 0.0 or float(s.get("life-s", 0)) <= 0.0: out.append("%s: speed, radius, life-s must be > 0" % where)
		if int(s.get("count", 1)) < 1 or float(s.get("spread", 0)) < 0.0 or float(s.get("gravity", 0)) < 0.0 or float(s.get("splash", 0)) < 0.0: out.append("%s: count >= 1, spread / gravity / splash >= 0" % where)
		if s.get("pierce", false) and float(s.get("tick-s", 0)) <= 0.0: out.append("%s: pierce needs tick-s > 0" % where)
		return out

	## c-creature-roles (D26): a ranged/mage role dict from design.creature-roles (or a species-merged one).
	static func _role_errors(r: Dictionary, where: String, se: Dictionary, alpha_sfx: Array, feel_sfx: Dictionary) -> Array:
		var out: Array = []
		if str(r.get("kind", "")) != "projectile": out.append("%s: kind must be projectile" % where); return out
		if float(r.get("range", -1)) <= float(r.get("keep-away", -1)) or float(r.get("keep-away", -1)) < 0.0: out.append("%s: range must be > keep-away >= 0" % where)
		if float(r.get("windup-s", -1)) < 0.0: out.append("%s: windup-s must be >= 0" % where)
		if float(r.get("cooldown-s", 0)) <= 0.0: out.append("%s: cooldown-s must be > 0" % where)
		if float(r.get("damage-mult", 0)) <= 0.0: out.append("%s: damage-mult must be > 0" % where)
		out.append_array(_shot_errors(r.get("shot", {}), "%s.shot" % where))
		for sid in r.get("applies", []):
			if not se.has(sid): out.append("%s: applies %s has no design.status-effects entry" % [where, sid])
		var sfx_id := str(r.get("sfx", ""))
		if not alpha_sfx.has(sfx_id): out.append("%s: sfx %s is not an audio.json sfx-alpha-ids entry" % [where, sfx_id])
		elif not feel_sfx.has(sfx_id): out.append("%s: sfx %s has no design.feel.sfx entry" % [where, sfx_id])
		if not Color.html_is_valid(str(r.get("color", ""))): out.append("%s: color is not a valid html colour" % where)
		return out

	# c-slot-accepts / c-weapon-class / c-hands / c-cube-cap: selected equipment contract.
	func _validate_equipment() -> void:
		var slot_cfg: Variant = configs.get("equipment-slots")
		if not slot_cfg is Dictionary: errors.append("equipment-slots: required object missing or malformed")
		var slot_rows: Variant = slot_cfg.get("slots") if slot_cfg is Dictionary else null
		var item_type_config: Variant = configs.get("item-types")
		if not item_type_config is Dictionary: errors.append("item-types: required object missing or malformed")
		var item_types: Dictionary = item_type_config if item_type_config is Dictionary else {}
		var expected := {
			"unknown-0": [], "amulet": ["amulet"], "chest": ["chest-armor"], "gloves": ["gloves"],
			"boots": ["boots"], "shoulders": ["shoulder-armor"], "main-hand": ["weapon"],
			"off-hand": ["weapon"], "ring-left": ["ring"], "ring-right": ["ring"],
			"lamp": ["light"], "special": ["special"], "pet": ["pet-cage", "pet-food"]
		}
		var expected_indices := ["unknown-0", "amulet", "chest", "gloves", "boots", "shoulders", "main-hand", "off-hand", "ring-left", "ring-right", "lamp", "special", "pet"]
		var expected_subtypes := {"lamp": ["lamp"], "special": ["hang-glider", "boat"]}
		var seen_ids := {}; var seen_indices := {}
		if not slot_rows is Array or slot_rows.size() != 13:
			errors.append("equipment-slots.slots: exactly 13 slot rows required")
		else:
			for row in slot_rows:
				if not row is Dictionary:
					errors.append("equipment-slots.slots: malformed row")
					continue
				var id := str(row.get("id", "")); var index: Variant = row.get("index")
				if seen_ids.has(id): errors.append("equipment-slots.slots.%s: duplicate id" % id)
				seen_ids[id] = true
				if (not index is int and not index is float) or (index is float and (is_nan(index) or is_inf(index) or index != floorf(index))):
					errors.append("equipment-slots.slots.%s.index: integer required" % id)
				else:
					if seen_indices.has(int(index)): errors.append("equipment-slots.slots.%s: duplicate index" % id)
					seen_indices[int(index)] = true
					if id in expected_indices and index != expected_indices.find(id):
						errors.append("equipment-slots.slots.%s.index: selected mapping mismatch" % id)
				var accepts: Variant = row.get("accepts")
				if not accepts is Array:
					errors.append("equipment-slots.slots.%s.accepts: array required" % id)
					continue
				for type_id in accepts:
					if not item_types.has(type_id): errors.append("equipment-slots.slots.%s.accepts: unknown item-type %s" % [id, type_id])
					var type_row: Variant = item_types.get(type_id)
					var restrictions: Variant = row.get("accepts-subtypes", [])
					if restrictions is Array and not restrictions.is_empty() and type_row is Dictionary:
						var catalog: Variant = type_row.get("subtypes")
						if catalog is Dictionary:
							for subtype in restrictions:
								if not catalog.values().has(subtype): errors.append("equipment-slots.slots.%s: unknown subtype %s" % [id, subtype])
						elif catalog is String:
							errors.append("equipment-slots.slots.%s: subtype restrictions cannot resolve %s" % [id, catalog])
				var want: Array = expected.get(id, [])
				if accepts != want: errors.append("equipment-slots.slots.%s.accepts: selected mapping mismatch" % id)
				if expected_subtypes.has(id) and row.get("accepts-subtypes") != expected_subtypes[id]:
					errors.append("equipment-slots.slots.%s.accepts-subtypes: selected mapping mismatch" % id)
				if id == "pet" and row.get("accepts-conditions") != {"pet-food": "during-taming"}:
					errors.append("equipment-slots.slots.pet: pet-food must remain conditional during taming")
		for id in expected:
			if not seen_ids.has(id): errors.append("equipment-slots.slots.%s: required slot missing" % id)
		for index in range(13):
			if not seen_indices.has(index): errors.append("equipment-slots.slots: required index %d missing" % index)
		var extra: Variant = slot_cfg.get("extra") if slot_cfg is Dictionary else null
		var food_extra: Variant = extra.get("pet-food") if extra is Dictionary else null
		if not food_extra is Dictionary or food_extra.get("accepts") != ["pet-food"]:
			errors.append("equipment-slots.extra.pet-food: separate pet-food acceptance required")

		for id in weapon_types:
			var w: WeaponType = weapon_types[id]
			var raw: Dictionary = w.raw
			var class_owned := w.hands != Hands.NONE and w.character_class in classes
			for class_id in classes:
				if (classes[class_id] as CharacterClass).weapon_types.has(StringName(id)): class_owned = true
			if class_owned and (not raw.get("hands") is String or raw.get("hands") not in ["1h", "2h", "offhand", "1h dual (need two)"]):
				errors.append("weapon %s: hands must be a supported active weapon value" % id)
			if w.hands == Hands.NONE or raw.get("usable", true) == false:
				if class_owned: errors.append("weapon %s: active class weapon requires usable hands" % id)
				continue
			var owner: Variant = raw.get("class")
			if owner is String:
				if owner.is_empty(): errors.append("weapon %s: owning class required" % id)
				elif owner != "any":
					if not classes.has(owner): errors.append("weapon %s: unknown class %s" % [id, owner])
					elif not (classes[owner] as CharacterClass).weapon_types.has(StringName(id)):
						errors.append("weapon %s: class %s does not list weapon" % [id, owner])
			else:
				errors.append("weapon %s: owning class required" % id)
			if class_owned:
				var expected_capacity := MAX_CUBES_2H if w.hands in [Hands.TWO_HANDED, Hands.OFFHAND] else MAX_CUBES_1H
				if not _is_selected_multiplier(raw.get("cube-capacity"), expected_capacity): errors.append("weapon %s: capacity must match hands" % id)
				var material_text := str(raw.get("material", ""))
				if material_text.is_empty():
					errors.append("weapon %s: material required" % id)
				else:
					for option in material_text.split("|"):
						var material_id := StringName(option.strip_edges().split(" ")[0])
						if not materials.has(material_id): errors.append("weapon %s: unknown material %s" % [id, material_id])
		var wand: WeaponType = weapon_types.get(&"wand")
		if wand == null or wand.hands != Hands.TWO_HANDED or wand.cube_capacity != MAX_CUBES_2H or not (wand.raw.get("hands") is String and wand.raw["hands"] == "2h"):
			errors.append("weapon wand: selected mechanical 2h / 32-cube definition required")

		var recipe_cfg: Variant = configs.get("recipes")
		if not recipe_cfg is Dictionary: errors.append("recipes: required object missing or malformed")
		var gear_recipes: Variant = recipe_cfg.get("gear-weapons") if recipe_cfg is Dictionary else null
		if not gear_recipes is Dictionary: errors.append("recipes.gear-weapons: required object missing or malformed")
		var wand_recipe: Variant = gear_recipes.get("wand") if gear_recipes is Dictionary else null
		if not wand_recipe is Dictionary:
			errors.append("recipes.gear-weapons.wand: required recipe row missing")
		else:
			var inputs: Variant = wand_recipe.get("inputs")
			if not inputs is Dictionary or not ((inputs.get("wood-cube") is int or inputs.get("wood-cube") is float) and float(inputs.get("wood-cube")) == 20.0):
				errors.append("recipes.gear-weapons.wand.inputs.wood-cube: must be 20")
			if wand_recipe.get("station") != "workbench": errors.append("recipes.gear-weapons.wand.station: must be workbench")

	# c-control-references: only the selected Android first-slice input is enforced here.
	func _validate_android() -> void:
		var path := "controller-profiles.android"
		var profiles: Variant = configs.get("controller-profiles")
		if not profiles is Dictionary or not profiles.get("android") is Dictionary:
			errors.append(path + ": required object missing or malformed"); return
		var a: Dictionary = profiles["android"]
		var selected := {"deadzone-ratio": 0.15, "min-target-dp": 48, "look-deg-per-safe-width": 180}
		for field in selected:
			var value: Variant = a.get(field)
			var expected: float = selected[field]
			if (not value is float and not value is int) or value != expected:
				errors.append(path + "." + field + ": must equal selected policy " + str(expected))
		var actions: Variant = a.get("actions")
		var required := ["move", "look", "zoom", "sprint", "jump", "swim-ascent", "basic-attack", "special-attack", "block", "dodge", "class-skill-1", "class-skill-2", "class-skill-3", "class-skill-4", "interact", "pick-up", "quick-item", "inventory", "skills-window", "ui-cancel", "equip-item", "use-inventory-item", "spend-skill-point", "buy-item", "sell-item", "world-map"]
		if not actions is Array or actions.size() != required.size():
			errors.append(path + ".actions: required distinct first-slice action array"); return
		for action in required:
			if actions.count(action) != 1:
				errors.append(path + ".actions: required unique canonical action " + action)

	static func _is_selected_multiplier(value: Variant, selected: float) -> bool:
		if not value is int and not value is float:
			return false
		var number := float(value)
		return not is_nan(number) and not is_inf(number) and number == selected

	func validate() -> bool:
		var n := errors.size()
		_validate_equipment()
		_validate_android()
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
				elif not (weapon_types[w] as WeaponType).raw.get("class") is String or (weapon_types[w] as WeaponType).raw.get("class") != str(id):
					errors.append("class %s: weapon-type %s must belong to class" % [id, w])
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
		var generator_config: Variant = configs.get("generators")
		if not generator_config is Dictionary:
			errors.append("generators: required object missing or malformed")
			generator_config = {}
		var design_input: Variant = generator_config.get("design")
		if not design_input is Dictionary:
			errors.append("design: required object missing or malformed")
			design_input = {}
		var design: Dictionary = design_input
		var terrain_input: Variant = design.get("terrain")
		if not terrain_input is Dictionary:
			errors.append("design.terrain: required object missing or malformed")
		else:
			var scales := {"lands-per-axis": 1024, "land-blocks": 16384, "zone-blocks": 64, "land-zones": 256}
			for field in scales:
				if not _is_selected_multiplier(terrain_input.get(field), scales[field]):
					errors.append("design.terrain.%s: must equal selected %s" % [field, scales[field]])
		var spawns_input: Variant = design.get("spawns", {})
		var ai_input: Variant = spawns_input.get("ai", {}) if spawns_input is Dictionary else {}
		var ai: Dictionary = ai_input if ai_input is Dictionary else {}
		if ai.has("sim-radius") and float(ai["sim-radius"]) < float(ai.get("aggro-range", 0)) + float(ai.get("leash", 0)):   # c-sim-radius
			errors.append("design.spawns.ai.sim-radius %s < aggro-range + leash" % ai["sim-radius"])
		var combat: Variant = design.get("combat")
		if not combat is Dictionary:
			errors.append("design.combat: required object missing or malformed")
		else:
			var innate_resistance: Variant = combat.get("creature-resistance")
			if (not innate_resistance is float and not innate_resistance is int) or innate_resistance != 0:
				errors.append("design.combat.creature-resistance: must equal selected unequipped creature/NPC innate Resistance 0")
			if not _is_selected_multiplier(combat.get("armor-floor"), 0.1):
				errors.append("design.combat.armor-floor: must equal selected 0.1 hit-damage floor")
		var gear_hp: Variant = design.get("gear-hp")
		if not gear_hp is Dictionary:
			errors.append("design.gear-hp: required object missing or malformed")
		else:
			var hp_inputs := {"curve-mult": 5.0, "base": 2.0, "upgrade-step": 0.1}
			for field in hp_inputs:
				if not _is_selected_multiplier(gear_hp.get(field), hp_inputs[field]):
					errors.append("design.gear-hp.%s: must equal selected %s" % [field, hp_inputs[field]])
		var hp_materials := {"iron": 1.0, "cotton": 0.75, "linen": 0.5}
		for id in hp_materials:
			if not materials.has(id) or not _is_selected_multiplier((materials[id] as MaterialDef).raw.get("hp-bonus"), hp_materials[id]):
				errors.append("material %s.raw.hp-bonus: must equal selected bonus %s" % [id, hp_materials[id]])
		var resistance_materials := {"iron": 0.85, "linen": 0.75, "cotton": 0.75, "silk": 1.0}
		for id in resistance_materials:
			if not materials.has(id) or not _is_selected_multiplier((materials[id] as MaterialDef).raw.get("resi-mult"), resistance_materials[id]):
				errors.append("material %s.raw.resi-mult: must equal selected active multiplier %s" % [id, resistance_materials[id]])
		var slot_multipliers := {"chest": 1.0, "gloves": 0.5, "boots": 0.5, "shoulders": 0.5, "main-hand": 0.5, "off-hand": 0.5}
		var slot_config: Variant = configs.get("equipment-slots", {})
		var equipment_slots: Variant = slot_config.get("slots", []) if slot_config is Dictionary else []
		var found_slots: Dictionary = {}
		if equipment_slots is Array:
			for slot in equipment_slots:
				if slot is Dictionary and slot_multipliers.has(str(slot.get("id", ""))):
					var id := str(slot["id"])
					if found_slots.has(id): errors.append("equipment-slots.slots.%s: duplicate HP-bearing slot" % id)
					found_slots[id] = true
					if not _is_selected_multiplier(slot.get("hp-mult"), slot_multipliers[id]):
						errors.append("equipment-slots.slots.%s.hp-mult: must equal selected multiplier %s" % [id, slot_multipliers[id]])
		for id in slot_multipliers:
			if not found_slots.has(id):
				errors.append("equipment-slots.slots.%s: required HP-bearing slot missing" % id)
		var loot: Dictionary = design.get("loot", {})                     # c-loot-config (D18)
		if not loot.is_empty():
			var item_type_config: Variant = configs.get("item-types")
			var item_types: Dictionary = item_type_config if item_type_config is Dictionary else {}
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
		var prog: Dictionary = design.get("progression", {})               # c-xp-config (D19)
		if not prog.is_empty():
			var kf := float(prog["kill-fraction"]); var r: Array = prog["gap-mult-range"]
			if kf <= 0.0 or kf > 1.0: errors.append("design.progression.kill-fraction out of (0,1]")
			if float(r[0]) < 0.0 or float(r[0]) > 1.0 or float(r[1]) < 1.0: errors.append("design.progression.gap-mult-range must bracket 1 with lo >= 0")
			if float(prog["gap-per-level"]) < 0.0: errors.append("design.progression.gap-per-level < 0")
		for id in specs:                                                    # c-tree-shape (D20)
			var s: Specialization = specs[id]
			var ranks := {}; var ults := 0; var roots := {}
			for a in skill_tree(s.character_class, StringName(id)):
				var t: Dictionary = (a as Ability).alpha_tree
				var col := str(t["column"])
				if col == "class":
					ranks[int(t["rank"])] = ranks.get(int(t["rank"]), 0) + 1
					if int(t["rank"]) == 1 and int(t["needs"]) != 0: errors.append("skill-tree: rank-1 %s must have needs 0" % a.id)
				elif col == "ultimate":
					ults += 1
				else:
					if int(t["needs"]) == 0: roots[col] = roots.get(col, 0) + 1
					var nxt := StringName(str((a as Ability).raw.get("unlocks-next", "")))
					if nxt != &"" and (not abilities.has(nxt) or str((abilities[nxt] as Ability).alpha_tree.get("column")) != col):
						errors.append("skill-tree: %s unlocks-next %s is not in column %s" % [a.id, nxt, col])
			for r in [1, 2, 3]:
				if ranks.get(r, 0) != 1: errors.append("skill-tree %s: %d class nodes of rank %d" % [id, ranks.get(r, 0), r])
			if ults > 1: errors.append("skill-tree %s: %d ultimates" % [id, ults])
			for col in roots:
				if roots[col] != 1: errors.append("skill-tree %s: column %s has %d roots" % [id, col, roots[col]])
		var ab: Dictionary = design.get("abilities", {})                  # c-ability-runtime (D21)
		var runtimes: Array = ab.get("runtimes", [])
		var stamina_max := float(design.get("movement", {}).get("stamina", {}).get("max", 100))
		var seen := {}
		for id in specs:
			for a in skill_tree((specs[id] as Specialization).character_class, StringName(id)):
				var col := str((a as Ability).alpha_tree["column"])
				if col != "class" and col != "ultimate" or seen.has(a.id):
					continue
				seen[a.id] = true
				var r = ab.get(a.id)
				if not r is Dictionary or not (str(r.get("runtime")) in runtimes):
					errors.append("design.abilities.%s: missing or unknown runtime" % a.id); continue
				if float(r.get("cooldown-s", 0)) <= 0.0: errors.append("design.abilities.%s: cooldown-s must be > 0" % a.id)
				for res in r.get("cost", {}):
					var v = r["cost"][res]
					var cap := 100.0 if str(res) == "mp" else stamina_max
					if not (str(v) == "all" or ((v is float or v is int) and float(v) >= 0.0 and float(v) <= cap)):
						errors.append("design.abilities.%s: cost %s = %s outside [0, %d] / 'all'" % [a.id, res, v, cap])
				match str(r["runtime"]):
					"dash":
						if float(r.get("distance", 0)) <= 0.0: errors.append("design.abilities.%s: dash distance must be > 0" % a.id)
						if r.has("strike") and float(r["strike"].get("radius", 0)) <= 0.0: errors.append("design.abilities.%s: strike radius must be > 0" % a.id)
						if r.has("throw"): errors.append_array(_shot_errors(r["throw"], "design.abilities.%s.throw" % a.id))
					"projectile":
						errors.append_array(_shot_errors(r, "design.abilities.%s" % a.id))
					"burst", "channel":
						if float(r.get("radius", 0)) <= 0.0: errors.append("design.abilities.%s: radius must be > 0" % a.id)
						if str(r["runtime"]) == "channel" and float(r.get("duration-s", 0)) <= 0.0: errors.append("design.abilities.%s: duration-s must be > 0" % a.id)
					"buff":
						if float(r.get("duration-s", 0)) <= 0.0: errors.append("design.abilities.%s: duration-s must be > 0" % a.id)
					"heal":
						if float(r.get("cast-s", -1)) < 0.0 or float(r.get("heal-pct", 0)) <= 0.0: errors.append("design.abilities.%s: heal needs cast-s >= 0 and heal-pct > 0" % a.id)
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
				errors.append(path + ": required object missing or malformed"); continue
			var selected := {"duration-s": 4.0, "tick-s": 0.5, "pct-of-hit": 0.1} if id == "burning" else {"duration-s": 5.0, "tick-s": 1.0, "pct-of-hit": 1.0}
			for field in selected:
				var value: Variant = row.get(field)
				if (not value is float and not value is int) or value != selected[field]:
					errors.append(path + "." + field + ": must equal selected value " + str(selected[field]))
			if (id == "poison" and row.get("as") != "burning") or (id == "burning" and row.has("as")):
				errors.append(path + ".as: must route to burning DOT behavior")
		for id in se:
			if str(id).begins_with("_"): continue
			if not status_effects.has(id): errors.append("design.status-effects.%s is not a status-effect" % id)
			elif not se[id] is Dictionary: errors.append("design.status-effects.%s: malformed object" % id)
			elif se[id].has("as") and not se.has(str(se[id]["as"])): errors.append("design.status-effects.%s: `as` %s has no entry" % [id, se[id]["as"]])
		var mv: Dictionary = design.get("movesets", {})                    # c-moveset-config (D24)
		if not mv.is_empty():
			var kinds: Array = mv.get("kinds", [])
			for id in mv:
				if str(id).begins_with("_") or str(id) == "kinds": continue
				if str(id) != "default" and not weapon_types.has(id): errors.append("design.movesets.%s is not a weapon-type" % id)
				var m: Dictionary = mv[id]
				if m.has("as"):
					if not mv.has(str(m["as"])) or (mv[m["as"]] as Dictionary).has("as"): errors.append("design.movesets.%s: `as` %s is not a plain entry" % [id, m["as"]])
					continue
				for slot in ["m1", "m2"]:
					var s = m.get(slot)
					var where := "design.movesets.%s.%s" % [id, slot]
					if not s is Dictionary or not (str(s.get("kind")) in kinds): errors.append("%s: kind must be one of %s" % [where, kinds]); continue
					for sid in s.get("applies", []):
						if not se.has(sid): errors.append("%s: applies %s has no design.status-effects entry" % [where, sid])
					if float(s.get("damage-mult", 1)) <= 0.0: errors.append("%s: damage-mult must be > 0" % where)
					match str(s["kind"]):
						"melee":
							if float(s.get("swing-mult", 1)) <= 0.0 or float(s.get("radius-mult", 1)) <= 0.0 or float(s.get("lunge", 0)) < 0.0: errors.append("%s: swing-mult, radius-mult > 0, lunge >= 0" % where)
							if s.has("finisher"):
								var f: Dictionary = s["finisher"]
								if int(f.get("every", 0)) < 2 or float(f.get("chance", -1)) < 0.0 or float(f.get("chance", -1)) > 1.0: errors.append("%s: finisher every >= 2, chance in [0,1]" % where)
								for sid in f.get("applies", []):
									if not se.has(sid): errors.append("%s: finisher applies %s has no design.status-effects entry" % [where, sid])
						"projectile":
							errors.append_array(_shot_errors(s, where))
						_:
							if float(s.get("range", 0)) <= 0.0 or float(s.get("radius", 0)) <= 0.0: errors.append("%s: range and radius must be > 0" % where)
			for cid in classes:
				for wt in (classes[cid] as CharacterClass).weapon_types:
					if (weapon_types[wt] as WeaponType).hands != Hands.OFFHAND and not mv.has(wt): errors.append("design.movesets: class %s weapon-type %s has no entry" % [cid, wt])
		var st: Dictionary = design.get("settlement", {})                  # c-settlement-config (D22)
		if not st.is_empty():
			var bj: Dictionary = configs.get("buildings", {}); var roles: Dictionary = configs.get("npc-roles", {})
			if int(st["per-land"]) < 1: errors.append("design.settlement.per-land < 1")
			if float(st["radius"]) <= float(st["blend"]) or float(st["blend"]) < 0.0: errors.append("design.settlement: need radius > blend >= 0")
			if float(st["ring-radius"]) >= float(st["radius"]): errors.append("design.settlement.ring-radius must be < radius")
			if float(st["no-hostiles-within"]) < float(st["radius"]): errors.append("design.settlement.no-hostiles-within < radius")
			for b in st["buildings"]:
				if not bj.get("buildings", {}).has(b): errors.append("design.settlement.buildings: unknown building %s" % b)
			for b in st["npc"]["roles"]:
				if not roles.has(st["npc"]["roles"][b]): errors.append("design.settlement.npc.roles.%s: unknown npc-role %s" % [b, st["npc"]["roles"][b]])
			for id in landscapes:
				if (landscapes[id] as Landscape).gen.is_empty(): continue
				var style = st["style-by-landscape"].get(id)
				if style == null or not bj.get("settlement-styles", {}).has(style): errors.append("design.settlement.style-by-landscape.%s: missing or unknown style %s" % [id, style])
				elif not (st["style-colors"].get(style) is Array and (st["style-colors"][style] as Array).size() == 2): errors.append("design.settlement.style-colors.%s: need [wall, roof]" % style)
			var cap = st["shop"]["rarity-cap"]
			if not rarities.has(cap) or (rarities[cap] as RarityDef).index > Rarity.LEGENDARY: errors.append("design.settlement.shop.rarity-cap: bad rarity %s" % cap)
		var df: Dictionary = design.get("defence", {})                    # c-defence-config (D23)
		if not df.is_empty():
			var dg: Dictionary = df["dodge"]; var bl: Dictionary = df["block"]; var sl: Dictionary = df["stealth"]
			if float(dg["stamina"]) <= 0.0 or float(dg["stamina"]) > stamina_max: errors.append("design.defence.dodge.stamina outside (0, %d]" % stamina_max)
			if float(dg["distance"]) <= 0.0 or float(dg["duration-s"]) <= 0.0 or float(dg["iframe-s"]) < 0.0: errors.append("design.defence.dodge: distance / duration-s > 0, iframe-s >= 0")
			for id in dg["on-dodge"]:
				if not abilities.has(id) or (abilities[id] as Ability).kind != AbilityKind.PASSIVE: errors.append("design.defence.dodge.on-dodge.%s is not a passive" % id)
			if float(bl["max"]) <= 0.0 or float(bl["power-per-hit"]) <= 0.0: errors.append("design.defence.block: max / power-per-hit must be > 0")
			if float(bl["damage-reduction"]) < 0.0 or float(bl["damage-reduction"]) > 1.0: errors.append("design.defence.block.damage-reduction outside [0,1]")
			if absf(float(bl["front-dot"])) > 1.0: errors.append("design.defence.block.front-dot outside [-1,1]")
			if float(bl["regen-per-s"]) < 0.0 or float(bl["guardian-mult"]) < 1.0: errors.append("design.defence.block: regen-per-s >= 0, guardian-mult >= 1")
			if float(sl["decay-per-s"]) < 0.0 or float(sl["still-mult"]) < 1.0: errors.append("design.defence.stealth: decay-per-s >= 0, still-mult >= 1")
			if float(sl["aggro-cut"]) < 0.0 or float(sl["aggro-cut"]) > 1.0: errors.append("design.defence.stealth.aggro-cut outside [0,1]")
			for k in df["enemy-hit"]:
				if float(df["enemy-hit"][k]) < 0.0 or float(df["enemy-hit"][k]) > 1.0: errors.append("design.defence.enemy-hit.%s outside [0,1]" % k)
			for id in ab:
				if ab[id] is Dictionary and float(ab[id].get("stealth-per-s", 0.0)) < 0.0: errors.append("design.abilities.%s.stealth-per-s < 0" % id)
		var fl: Dictionary = design.get("feel", {})                        # c-feel-config (D25)
		if not fl.is_empty():
			var hs: Dictionary = fl["hit-stop"]; var sh: Dictionary = fl["shake"]; var nb: Dictionary = fl["numbers"]
			var im: Dictionary = fl["impact"]; var tr: Dictionary = fl["trail"]; var lv: Dictionary = fl["level-up"]
			var ev: Dictionary = fl["events"]; var sfx: Dictionary = fl["sfx"]
			var alpha_sfx: Array = configs.get("audio", {}).get("sfx-alpha-ids", [])
			if float(hs["time-scale"]) <= 0.0 or float(hs["time-scale"]) >= 1.0: errors.append("design.feel.hit-stop.time-scale outside (0,1)")
			if float(hs["max-s"]) <= 0.0 or float(hs["max-s"]) > 1.0: errors.append("design.feel.hit-stop.max-s outside (0,1]")
			if float(sh["decay-per-s"]) <= 0.0: errors.append("design.feel.shake.decay-per-s must be > 0")
			if float(sh["max-offset"]) < 0.0: errors.append("design.feel.shake.max-offset must be >= 0")
			if float(sh["shake-mult"]) < 0.0: errors.append("design.feel.shake.shake-mult must be >= 0")
			if float(sh["max-roll-deg"]) < 0.0: errors.append("design.feel.shake.max-roll-deg must be >= 0")
			for id in ["hit", "crit", "kill", "hurt", "block", "dodge", "shoot", "impact", "level-up", "pickup", "coin"]:
				if not ev.has(id): errors.append("design.feel.events missing required event %s" % id)
			for id in ev:
				var e: Dictionary = ev[id]
				if float(e.get("hit-stop-s", 0)) < 0.0 or float(e.get("hit-stop-s", 0)) > float(hs["max-s"]): errors.append("design.feel.events.%s.hit-stop-s outside [0, max-s]" % id)
				if float(e.get("trauma", 0)) < 0.0 or float(e.get("trauma", 0)) > 1.0: errors.append("design.feel.events.%s.trauma outside [0,1]" % id)
				var sid := str(e.get("sfx", ""))
				if not alpha_sfx.has(sid): errors.append("design.feel.events.%s.sfx %s is not an audio.json sfx-alpha-ids entry" % [id, sid])
				elif not sfx.has(sid): errors.append("design.feel.events.%s.sfx %s has no design.feel.sfx entry" % [id, sid])
			for id in sfx:
				var sd: Dictionary = sfx[id]
				if float(sd.get("hz", 0)) <= 0.0: errors.append("design.feel.sfx.%s.hz must be > 0" % id)
				if float(sd.get("len-s", 0)) <= 0.0 or float(sd.get("len-s", 0)) > 1.0: errors.append("design.feel.sfx.%s.len-s outside (0,1]" % id)
				if float(sd.get("noise", 0)) < 0.0 or float(sd.get("noise", 0)) > 1.0: errors.append("design.feel.sfx.%s.noise outside [0,1]" % id)
				if not sd.has("slide"): errors.append("design.feel.sfx.%s needs a slide" % id)
			if float(nb["life-s"]) <= 0.0: errors.append("design.feel.numbers.life-s must be > 0")
			if float(nb["crit-scale"]) < 1.0: errors.append("design.feel.numbers.crit-scale must be >= 1")
			if float(nb["rise-blocks"]) <= 0.0: errors.append("design.feel.numbers.rise-blocks must be > 0")
			if int(nb["font-size"]) <= 0: errors.append("design.feel.numbers.font-size must be > 0")
			if not nb["colours"].has("hit"): errors.append("design.feel.numbers.colours needs a hit entry (the fallback colour)")
			for k in nb["colours"]:
				var col: Array = nb["colours"][k]
				var bad_col: bool = col.size() != 3
				if not bad_col:
					for c in col:
						if float(c) < 0.0 or float(c) > 1.0: bad_col = true
				if bad_col: errors.append("design.feel.numbers.colours.%s must be a 3-array in [0,1]" % k)
			if float(im["impact-s"]) <= 0.0: errors.append("design.feel.impact.impact-s must be > 0")
			if float(im["impact-radius"]) <= 0.0: errors.append("design.feel.impact.impact-radius must be > 0")
			if float(tr["trail-s"]) <= 0.0: errors.append("design.feel.trail.trail-s must be > 0")
			if float(tr["trail-every-s"]) <= 0.0: errors.append("design.feel.trail.trail-every-s must be > 0")
			if float(lv["pop-s"]) <= 0.0: errors.append("design.feel.level-up.pop-s must be > 0")
			if float(lv["pop-scale"]) < 1.0: errors.append("design.feel.level-up.pop-scale must be >= 1")
			if str(lv["text"]).is_empty(): errors.append("design.feel.level-up.text must not be empty")
		var cr: Dictionary = design.get("creature-roles", {})              # c-creature-roles (D26)
		if not cr.is_empty():
			var alpha_sfx2: Array = configs.get("audio", {}).get("sfx-alpha-ids", [])
			var feel_sfx: Dictionary = fl.get("sfx", {})
			var role_kinds := ["melee", "ranged", "mage"]
			if str(cr.get("default", "")) not in role_kinds: errors.append("design.creature-roles.default must be one of %s" % [role_kinds])
			var ac: Dictionary = cr.get("any-class", {})
			var w_sum := 0.0
			for k in ac:
				if str(k) not in role_kinds: errors.append("design.creature-roles.any-class key %s must be one of %s" % [k, role_kinds])
				if float(ac[k]) < 0.0: errors.append("design.creature-roles.any-class.%s must be >= 0" % k)
				w_sum += float(ac[k])
			if w_sum <= 0.0: errors.append("design.creature-roles.any-class weights must sum > 0")
			if str(cr.get("melee", {}).get("kind", "")) != "melee": errors.append("design.creature-roles.melee.kind must be melee")
			for rid in ["ranged", "mage"]:
				errors.append_array(_role_errors(cr.get(rid, {}), "design.creature-roles.%s" % rid, se, alpha_sfx2, feel_sfx))
			var override_keys := ["range", "keep-away", "windup-s", "cooldown-s", "damage-mult", "shot", "applies", "sfx", "color"]
			for sid in cr.get("species", {}):
				if not creatures.has(sid): errors.append("design.creature-roles.species.%s is not a creature" % sid); continue
				var ov: Dictionary = cr["species"][sid]
				for k in ov:
					if not override_keys.has(k): errors.append("design.creature-roles.species.%s: unknown override key %s" % [sid, k])
				var role := str((creatures[sid] as Creature).combat_role)
				if role not in role_kinds: role = str(cr.get("default", "melee"))
				var merged: Dictionary = (cr.get(role, {}) as Dictionary).duplicate(true)
				merged.merge(ov, true)
				if role == "melee":
					if str(merged.get("kind", "")) != "melee": errors.append("design.creature-roles.species.%s (merged): kind must be melee" % sid)
				else:
					errors.append_array(_role_errors(merged, "design.creature-roles.species.%s (merged)" % sid, se, alpha_sfx2, feel_sfx))
		var defaults := rulesets.values().filter(func(r: Ruleset) -> bool: return r.is_default)
		if defaults.size() != 1: errors.append("exactly one ruleset must be default (found %d)" % defaults.size())
		return errors.size() == n
