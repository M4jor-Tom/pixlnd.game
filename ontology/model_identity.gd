## Ordered identity validation.
extends RefCounted
const Inputs := preload("res://ontology/model_inputs.gd")


static func validate_progression(o, design: Dictionary) -> bool:
	var prog = o._object(design.get("progression"))  # c-xp-config (D19)
	if o._fields_valid(
		design.get("progression"),
		"design.progression",
		{"number": "kill-fraction gap-per-level", "pair": "gap-mult-range"}
	):
		progression_bounds(o, prog)
	return o._validate_skill_trees(design)


static func tree_field_errors(
	tree: Variant, path: String, integer: Callable, selected: Callable
) -> Array:
	if not tree is Dictionary or tree.is_empty():
		return [path + ": alpha-tree object required"]
	var out := []
	var raw_column: Variant = tree.get("column")
	var column: String = raw_column if raw_column is String else ""
	tree_position_errors(tree, path, column, out, integer, selected)
	tree_annotation_errors(tree, path, out)
	return out


static func tree_position_errors(
	tree: Dictionary,
	path: String,
	column: String,
	out: Array,
	integer: Callable,
	selected: Callable
) -> void:
	if column not in ["class", "ultimate", "pets", "climbing", "water"]:
		out.append(path + ".column: known column required")
	if not integer.call(tree.get("needs"), 0):
		out.append(path + ".needs: nonnegative integer required")
	tree_rank_errors(tree, path, column, out, integer, selected)


static func tree_rank_errors(
	tree: Dictionary,
	path: String,
	column: String,
	out: Array,
	integer: Callable,
	selected: Callable
) -> void:
	if column == "class" and not integer.call(tree.get("rank"), 1, 3):
		out.append(path + ".rank: integer 1..3 required")
	if column in ["pets", "climbing", "water"] and not integer.call(tree.get("skill-slot"), 0):
		out.append(path + ".skill-slot: nonnegative integer required")
	tree_ultimate_errors(tree, path, column, out, selected)


static func tree_annotation_errors(tree: Dictionary, path: String, out: Array) -> void:
	if tree.has("class") and not tree["class"] is String:
		out.append(path + ".class: string required")
	if tree.has("also-ultimate") and not tree["also-ultimate"] is bool:
		out.append(path + ".also-ultimate: boolean required")


static func row_errors(
	catalog: String,
	row: Variant,
	path: String,
	strings: Callable,
	integer: Callable,
	tree_errors: Callable
) -> Array:
	if not row is Dictionary or row.is_empty():
		return [path + ": row object required"]
	var out := []
	match catalog:
		"classes":
			class_row_errors(row, path, out, strings, integer)
		"specializations":
			specialization_row_errors(row, path, out, strings, integer)
		"abilities":
			ability_row_errors(row, path, out, strings, integer, tree_errors)
	return out


static func class_row_errors(
	row: Dictionary, path: String, out: Array, strings: Callable, integer: Callable
) -> void:
	class_array_errors(row, path, out, strings)
	for field in ["armor-material", "special-attack-mode"]:
		if not row.get(field) is String:
			out.append(path + "." + field + ": string required")
	class_scalar_errors(row, path, out, integer)


static func class_scalar_errors(
	row: Dictionary, path: String, out: Array, integer: Callable
) -> void:
	if row.get("special-attack-mode") not in ["charged", "instant"]:
		out.append(path + ".special-attack-mode: charged or instant required")
	if not integer.call(row.get("id-number"), 1, 4):
		out.append(path + ".id-number: integer 1..4 required")
	var hp: Variant = row.get("hp-mult")
	if not Inputs.finite_number(hp) or hp <= 0:
		out.append(path + ".hp-mult: finite positive number required")


static func specialization_row_errors(
	row: Dictionary, path: String, out: Array, strings: Callable, integer: Callable
) -> void:
	if not row.get("class") is String:
		out.append(path + ".class: string required")
	if not integer.call(row.get("index"), 0, 1):
		out.append(path + ".index: integer 0 or 1 required")
	for field in ["kit", "passives"]:
		specialization_version_errors(row, path, field, out, strings)


static func specialization_version_errors(
	row: Dictionary, path: String, field: String, out: Array, strings: Callable
) -> void:
	if not row.get(field) is Dictionary:
		out.append(path + "." + field + ": object required")
		return
	for version in ["A", "S"]:
		if not strings.call(row[field].get(version)):
			out.append(path + "." + field + "." + version + ": string array required")


static func ability_row_errors(
	row: Dictionary,
	path: String,
	out: Array,
	strings: Callable,
	integer: Callable,
	tree_errors: Callable
) -> void:
	if not row.get("owner") is String and not strings.call(row.get("owner")):
		out.append(path + ".owner: string or string array required")
	ability_object_errors(row, path, out)
	ability_optional_errors(row, path, out, strings, integer, tree_errors)


static func ability_optional_errors(
	row: Dictionary,
	path: String,
	out: Array,
	strings: Callable,
	integer: Callable,
	tree_errors: Callable
) -> void:
	if row.has("applies") and not strings.call(row["applies"]):
		out.append(path + ".applies: string array required")
	if row.has("alpha-id") and not integer.call(row["alpha-id"], 0):
		out.append(path + ".alpha-id: nonnegative integer required")
	ability_tree_errors(row, path, out, tree_errors)


# The first tree access remains in the facade; later property reads must stay after callbacks.
static func tree_node_visible(
	o, id, initial_tree: Dictionary, ability, class_id: StringName, spec_id: StringName
) -> bool:
	if initial_tree.is_empty() or not o._tree_field_errors(ability.alpha_tree, str(id)).is_empty():
		return false
	var tree_owner := StringName(
		str(ability.alpha_tree.get("class", ability.owner if ability.owner is String else ""))
	)
	return tree_owner in [&"all", class_id, spec_id]


static func spec_class_exists(o, id, character_class: StringName) -> bool:
	if not o.classes.has(character_class):
		o.errors.append("spec %s: unknown class %s" % [id, character_class])
		return false
	return true


static func spec_class_link(o, id, character_class: StringName, specializations: Array) -> void:
	if not specializations.has(StringName(id)):
		o.errors.append("class %s does not list spec %s" % [character_class, id])


static func spec_abilities(o, id, refs: Array) -> void:
	for ability in refs:
		if not o.abilities.has(ability):
			o.errors.append("spec %s: unknown ability %s" % [id, ability])


static func class_specializations(o, id, specializations: Array) -> void:
	if specializations.size() != 2 or specializations[0] == specializations[1]:
		o.errors.append("class %s: two distinct specializations required" % id)
	for i in specializations.size():
		class_specialization(o, id, specializations, i)


static func class_weapon_exists(o, id, weapon) -> bool:
	if not o.weapon_types.has(weapon):
		o.errors.append("class %s: unknown weapon-type %s" % [id, weapon])
		return false
	return true


static func class_weapon_owner(o, id, weapon, raw: Dictionary) -> void:
	if not raw.get("class") is String or raw.get("class") != str(id):
		o.errors.append("class %s: weapon-type %s must belong to class" % [id, weapon])


static func tamed_creature_exists(o, id, tames: StringName) -> bool:
	if not o.creatures.has(tames):
		o.errors.append("pet-food %s tames unknown creature %s" % [id, tames])
		return false
	return true


static func tame_pair(o, id, food, tame_food: StringName, entity_id: int) -> void:
	if tame_food != StringName(id):
		o.errors.append("pet-food %s ↔ creature %s tame mismatch" % [id, food.tames])
	if entity_id >= 0 and entity_id != food.subtype:
		o.errors.append("pet-food %s subtype %d != creature id %d" % [id, food.subtype, entity_id])


static func ability_statuses(o, id, applies: Array) -> void:
	for status in applies:
		if not o.status_effects.has(status):
			o.errors.append("ability %s applies unknown status %s" % [id, status])


static func catalog_tags(o, id, row: Dictionary) -> void:
	var tags: Variant = row.get("versions", row.get("v", []))
	if not o._source_tags_valid(tags):
		o.errors.append("%s: missing or malformed source version tags" % id)


static func validate_identity_catalogs(o) -> bool:
	var pairs = {
		"warrior": ["berserker", "guardian"],
		"ranger": ["sniper", "scout"],
		"mage": ["fire-mage", "water-mage"],
		"rogue": ["assassin", "ninja"]
	}
	var required = {"classes": pairs.keys(), "specializations": [], "abilities": ["camouflage"]}
	return identity_pairs(o, pairs, required)


static func tree_node_counts(
	o, a, t: Dictionary, col: String, nodes: Array, ranks: Dictionary, roots: Dictionary
) -> int:
	if col == "class":
		tree_class_node(o, a.id, t, ranks)
	elif col == "ultimate":
		return 1
	else:
		tree_shared_node(o, a.id, t, col, nodes, roots)
	return 0


static func tree_counts(o, id, ranks: Dictionary, ults: int) -> void:
	for r in [1, 2, 3]:
		if ranks.get(r, 0) != 1:
			o.errors.append("skill-tree %s: %d class nodes of rank %d" % [id, ranks.get(r, 0), r])
	if ults > 1 or (id == "assassin" and ults != 0):
		o.errors.append("skill-tree %s: %d ultimates" % [id, ults])


static func assassin_tree(o, nodes: Array, cam, sneak) -> void:
	if not assassin_camouflage(nodes, cam) or not assassin_sneak(nodes, sneak):
		o.errors.append("skill-tree assassin: one rank-3 Camouflage after 5 Sneak points required")


static func tree_next_exists(o, id, next: StringName, nodes: Array, column: String) -> bool:
	if next == &"":
		return false
	if not o.abilities.has(next) or o.abilities[next] not in nodes:
		o.errors.append("skill-tree: %s unlocks-next %s is not in column %s" % [id, next, column])
		return false
	return true


static func tree_next_column(o, id, next: StringName, tree: Dictionary, column: String) -> void:
	if str(tree.get("column")) != column:
		o.errors.append("skill-tree: %s unlocks-next %s is not in column %s" % [id, next, column])


static func tree_roots(o, id, roots: Dictionary) -> void:
	for column in roots:
		if roots[column] != 1:
			o.errors.append("skill-tree %s: column %s has %d roots" % [id, column, roots[column]])


static func identity_tree(o, id, tree: Dictionary, owner: Variant) -> void:
	if tree.is_empty():
		return
	o.errors.append_array(o._tree_field_errors(tree, "abilities." + str(id) + ".alpha-tree"))
	var tree_owner: Variant = tree.get("class", owner)
	if not known_tree_owner(o, tree_owner):
		o.errors.append("abilities.%s.alpha-tree.class: known tree owner required" % id)


static func tree_ultimate_errors(
	tree: Dictionary, path: String, column: String, out: Array, selected: Callable
) -> void:
	if column == "ultimate" and not selected.call(tree.get("needs"), 5):
		out.append(path + ".needs: ultimate requires 5 rank-3 points")


static func class_array_errors(
	row: Dictionary, path: String, out: Array, strings: Callable
) -> void:
	for field in ["weapon-types", "specializations"]:
		if not strings.call(row.get(field)):
			out.append(path + "." + field + ": string array required")


static func ability_object_errors(row: Dictionary, path: String, out: Array) -> void:
	for field in ["input", "cost"]:
		if row.has(field) and not row[field] is Dictionary:
			out.append(path + "." + field + ": object required")


static func ability_tree_errors(
	row: Dictionary, path: String, out: Array, tree_errors: Callable
) -> void:
	if row.has("alpha-tree"):
		out.append_array(tree_errors.call(row["alpha-tree"], path + ".alpha-tree"))
	if row.has("unlocks-next") and not row["unlocks-next"] is String:
		out.append(path + ".unlocks-next: string required")


static func class_specialization(o, id, specializations: Array, i: int) -> void:
	var sid = specializations[i]
	if not o.specs.has(sid):
		o.errors.append("class %s: unknown specialization %s" % [id, sid])
	elif o.specs[sid].character_class != StringName(id) or o.specs[sid].index != i:
		o.errors.append("class %s: specialization %s must be owned with index %d" % [id, sid, i])


static func identity_pairs(o, pairs: Dictionary, required: Dictionary) -> bool:
	for cid in pairs:
		for sid in pairs[cid]:
			required.specializations.append(sid)
			if o.specs.has(sid) and o.specs[sid].character_class != StringName(cid):
				o.errors.append("specializations.%s.class: must belong to %s" % [sid, cid])
	return identity_catalogs(o, required)


static func identity_catalogs(o, required: Dictionary) -> bool:
	for catalog in required:
		var raw: Variant = o.configs.get(catalog)
		var modeled: Dictionary = {
			"classes": o.classes, "specializations": o.specs, "abilities": o.abilities
		}[catalog]
		identity_catalog_requirements(o, catalog, raw, modeled, required[catalog])
		for id in modeled:
			o.errors.append_array(
				o._identity_row_errors(catalog, modeled[id].raw, catalog + "." + str(id))
			)
	return o._validate_identity_trees()


static func identity_catalog_requirements(
	o, catalog: String, raw: Variant, modeled: Dictionary, required: Array
) -> void:
	if not raw is Dictionary or o._rows(raw).is_empty():
		o.errors.append(catalog + ": required catalog object with rows")
	identity_raw_rows(o, catalog, raw)
	for id in required:
		if not required_identity_row(modeled, raw, id):
			o.errors.append(catalog + "." + id + ": required identity row")


static func identity_raw_rows(o, catalog: String, raw: Variant) -> void:
	if raw is Dictionary:
		for id in raw:
			if str(id).begins_with("_") or str(id).begins_with("$"):
				continue
			o.errors.append_array(o._identity_row_errors(catalog, raw[id], catalog + "." + str(id)))


static func tree_class_node(o, id, tree: Dictionary, ranks: Dictionary) -> void:
	ranks[int(tree["rank"])] = ranks.get(int(tree["rank"]), 0) + 1
	if int(tree["needs"]) != (0 if int(tree["rank"]) == 1 else 5):
		o.errors.append("skill-tree: %s class prerequisite must be 0 at rank 1, otherwise 5" % id)


static func tree_shared_node(
	o, id, tree: Dictionary, column: String, nodes: Array, roots: Dictionary
) -> void:
	if int(tree["needs"]) == 0:
		roots[column] = roots.get(column, 0) + 1
	if int(tree["needs"]) != 0:
		var predecessors := tree_predecessors(id, column, nodes)
		if int(tree["needs"]) != 5 or predecessors != 1:
			o.errors.append("skill-tree: %s needs 5 and one same-column predecessor" % id)


static func tree_predecessors(id, column: String, nodes: Array) -> int:
	var count := 0
	for node in nodes:
		if (
			node.alpha_tree.column == column
			and node.raw.get("unlocks-next") is String
			and node.raw["unlocks-next"] == str(id)
		):
			count += 1
	return count


static func assassin_camouflage(nodes: Array, cam) -> bool:
	return (
		cam in nodes
		and cam.alpha_tree.column == "class"
		and cam.alpha_tree.get("rank") == 3
		and cam.alpha_tree.needs == 5
	)


static func assassin_sneak(nodes: Array, sneak) -> bool:
	return (
		sneak in nodes and sneak.alpha_tree.column == "class" and sneak.alpha_tree.get("rank") == 2
	)


static func known_tree_owner(o, owner: Variant) -> bool:
	return owner is String and (owner == "all" or o.classes.has(owner) or o.specs.has(owner))


static func progression_bounds(o, prog: Dictionary) -> void:
	var kf = float(prog["kill-fraction"])
	var r: Array = prog["gap-mult-range"]
	if kf <= 0.0 or kf > 1.0:
		o.errors.append("design.progression.kill-fraction out of (0,1]")
	if float(r[0]) < 0.0 or float(r[0]) > 1.0 or float(r[1]) < 1.0:
		o.errors.append("design.progression.gap-mult-range must bracket 1 with lo >= 0")
	if float(prog["gap-per-level"]) < 0.0:
		o.errors.append("design.progression.gap-per-level < 0")


static func required_identity_row(modeled: Dictionary, raw: Variant, id) -> bool:
	return modeled.has(id) and raw is Dictionary and raw.get(id) is Dictionary
