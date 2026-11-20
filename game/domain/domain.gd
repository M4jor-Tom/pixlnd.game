## Game-side domain layer over the generated LinkML classes (game/generated/domain), replacing
## ontology/model.gd: catalog rows are generated `LinkML*SourceRow` objects keyed by their stable
## ontology id; every other instances file stays raw in `configs`. Shape, version tags and
## references are validated before the game runs (scripts/ontology_bind.py and its hooks).
## Engine scripts preload this file, never a class_name (headless has no cache before import).
extends RefCounted

const Loader := preload("res://game/domain/linkml_loader.gd")

enum Hands { ONE_HANDED, TWO_HANDED, OFFHAND, NONE }
enum Rarity { WORN = -1, COMMON = 0, UNCOMMON = 1, RARE = 2, EPIC = 3, LEGENDARY = 4, MYTHICAL = 5 }

const MAX_CUBES_1H := 16
const MAX_CUBES_2H := 32
const MP_MAX := 100.0
const SKILL_POINTS_PER_LEVEL := 2
const BLOCK_NATIVE_UNITS := 65536

# --- formulas (domain/index.md §3.5 level-formula, stats.json#alpha-item-stat-formulas) ----------


## Alpha level → power (+1..+100).
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


## Alpha item/character base curve.
static func stat_curve(n: float, rarity: int) -> float:
	return pow(2.0, (1.0 - 1.0 / ((n - 1.0) * 0.05 + 1.0)) * 3.0) * pow(2.0, rarity * 0.25)


# --- derived views of generated rows -------------------------------------------------------------


## Stable ontology id of a catalog row (its source entry key).
static func id_of(row: Object) -> StringName:
	return row.get_meta(&"id", &"")


## Weapon row `hands` text → Hands.
static func hands(weapon: Object) -> Hands:
	match str(weapon.slot_hands):
		"2h":
			return Hands.TWO_HANDED
		"offhand":
			return Hands.OFFHAND
		"1h", "1h dual (need two)":
			return Hands.ONE_HANDED
	return Hands.NONE


## D26: creature row `role` text → melee | ranged | mage | any-class | "".
static func combat_role(creature: Object) -> StringName:
	var role := str(creature.slot_role if creature.slot_role != null else "")
	for kind in ["any-class", "ranged", "mage", "melee"]:
		if role.contains(kind):
			return StringName(kind)
	return &""


## Creature row hostility base letter: "P (rarely H)" → "P".
static func hostility(creature: Object) -> StringName:
	return StringName(str(creature.slot_h if creature.slot_h != null else "P").left(1))


## Creature row `group` [min, max] → Vector2i; absent = (1, 1), as the old typed model.
static func group_size(creature: Object) -> Vector2i:
	var g: Variant = creature.slot_group
	return Vector2i(int(g[0]), int(g[1])) if g is Array and g.size() == 2 else Vector2i(1, 1)


## Ruleset row flags (bound as key/value entries) → {flag: value}.
static func flags(ruleset: Object) -> Dictionary:
	var out := {}
	for entry in ruleset.slot_flags:
		out[entry.slot_key] = entry.slot_value
	return out


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
	var configs := {}  # every instances file, raw (ui, keybinds, generators…)
	var errors: PackedStringArray = []

	## Raw files from `dir_path` into configs; catalogs from the bound, validated copies.
	static func load_dir(dir_path := "res://ontology/instances") -> Ontology:
		var o := Ontology.new()
		for file in DirAccess.get_files_at(dir_path):
			if file.ends_with(".json"):
				var text := FileAccess.get_file_as_string(dir_path.path_join(file))
				o.configs[file.get_basename()] = JSON.parse_string(text)
		var loader := Loader.new()
		o.races = _rows(loader.load_file("races"))
		o.classes = _rows(loader.load_file("classes"))
		o.specs = _rows(loader.load_file("specializations"))
		o.abilities = _rows(loader.load_file("abilities"))
		o.weapon_types = _rows(loader.load_file("weapon-types"))
		o.materials = _rows(loader.load_file("materials"))
		o.rarities = _rows(loader.load_file("rarities"), func(r): return r.slot_index != null)
		o.creatures = _rows(loader.load_file("creatures"))
		o.pet_foods = _rows(loader.load_file("pet-food").slot_foods)
		o.landscapes = _rows(loader.load_file("landscapes"))
		o.status_effects = _rows(
			loader.load_file("status-effects"), func(r): return r.slot_kind != null
		)
		o.consumables = _rows(loader.load_file("consumables"), func(r): return r.slot_kind != null)
		o.key_items = _rows(
			loader.load_file("key-items"),
			func(r): return "slot_group" in r and r.slot_group != null
		)
		o.rulesets = _rows(loader.load_file("rulesets"))
		o.errors.append_array(loader.errors)
		return o

	static func _rows(root: Object, keep: Callable = func(_r): return true) -> Dictionary:
		var out := {}
		for entry in root.slot_entries:
			if keep.call(entry.slot_value):
				entry.slot_value.set_meta(&"id", StringName(entry.slot_key))
				out[entry.slot_key] = entry.slot_value
		return out

	## The default ruleset (exactly one, enforced by the schema checks).
	func default_ruleset() -> Object:
		for r in rulesets.values():
			if r.slot_default == true:
				return r
		return null

	## D20: the skill-tree nodes a (class, spec) pair can spend points on — the shared columns, the
	## class column (its spec-specific rank) and the spec's ultimate — in screen order.
	## `alpha-tree.class` wins over `owner` (sneak's owner is a per-version list).
	func skill_tree(class_id: StringName, spec_id: StringName) -> Array:
		var out: Array = abilities.values().filter(
			func(a): return _tree_owner(a) in ["all", class_id, spec_id]
		)
		out.sort_custom(func(x, y): return _tree_key(x) < _tree_key(y))
		return out

	## Tree owner of an ability row; "" when it has no tree position or no single owner.
	static func _tree_owner(a: Object) -> String:
		var t: Object = a.slot_alpha_tree
		if t == null:
			return ""
		var owner: Variant = t.slot_class if t.slot_class != null else a.slot_owner
		return owner if owner is String else ""

	static func _tree_key(a: Object) -> int:
		var t: Object = a.slot_alpha_tree
		if t.slot_column == "class":
			return 100 + int(t.slot_rank if t.slot_rank != null else 0)
		return 104 if t.slot_column == "ultimate" else int(t.slot_skill_slot)
