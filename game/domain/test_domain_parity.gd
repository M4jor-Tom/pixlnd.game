## Migration oracle: the generated-domain facade exposes the same catalogs and derived values as
## ontology/model.gd. Delete together with model.gd once the game no longer uses it.
## timeout 300 nix develop -c godot --headless -s game/domain/test_domain_parity.gd
extends SceneTree

const Domain := preload("res://game/domain/domain.gd")
const Model := preload("res://ontology/model.gd")
const CATALOGS := [
	"races",
	"classes",
	"specs",
	"abilities",
	"weapon_types",
	"materials",
	"rarities",
	"creatures",
	"pet_foods",
	"landscapes",
	"status_effects",
	"consumables",
	"key_items",
	"rulesets"
]

var failures: PackedStringArray = []


func check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func _init() -> void:
	var old := Model.Ontology.load_dir("res://ontology/instances")
	var new := Domain.Ontology.load_dir()
	check(new.errors.is_empty(), "facade errors: %s" % [new.errors])
	_catalog_ids(old, new)
	_creatures(old, new)
	_equipment(old, new)
	_skill_trees(old, new)
	_flags(old, new)
	for f in failures.slice(0, 30):
		printerr("  ✗ ", f)
	var verdict := "DOMAIN_PARITY_OK"
	if not failures.is_empty():
		verdict = "DOMAIN_PARITY %d failures" % failures.size()
	print(verdict)
	quit(0 if failures.is_empty() else 1)


func _catalog_ids(old, new) -> void:
	for catalog in CATALOGS:
		var a: Array = old.get(catalog).keys()
		var b: Array = new.get(catalog).keys()
		a.sort()
		b.sort()
		check(a == b, "%s ids differ: %s vs %s" % [catalog, a, b])


func _creatures(old, new) -> void:
	for id in old.creatures:
		var o: Model.Creature = old.creatures[id]
		var n: Object = new.creatures[id]
		var aid: int = n.slot_aid if n.slot_aid != null else -1
		var cat: String = str(n.slot_cat if n.slot_cat != null else "unused")
		var old_cat: String = Model.CreatureCategory.keys()[o.category]
		check(Domain.id_of(n) == id, "creature %s id" % id)
		check(o.alpha_entity_id == aid, "creature %s aid" % id)
		check(o.combat_role == Domain.combat_role(n), "creature %s role" % id)
		check(o.hostility == Domain.hostility(n), "creature %s hostility" % id)
		check(old_cat.to_lower().replace("_", "-") == cat, "creature %s cat" % id)


func _equipment(old, new) -> void:
	for id in old.weapon_types:
		var n: Object = new.weapon_types[id]
		var k: int = n.slot_damage_k if n.slot_damage_k != null else 0
		check(int(old.weapon_types[id].hands) == int(Domain.hands(n)), "weapon %s hands" % id)
		check(old.weapon_types[id].damage_k == k, "weapon %s k" % id)
	for id in old.rarities:
		check(old.rarities[id].index == new.rarities[id].slot_index, "rarity %s index" % id)
	for id in old.consumables:
		var hm: Variant = new.consumables[id].slot_heal_mult
		check(old.consumables[id].heal_mult == int(hm if hm != null else 0), "consumable %s" % id)


func _skill_trees(old, new) -> void:
	for cid in old.classes:
		for sid in old.classes[cid].specializations:
			var a: Array = old.skill_tree(cid, sid).map(func(x): return x.id)
			var b: Array = new.skill_tree(cid, sid).map(func(x): return Domain.id_of(x))
			check(a == b, "skill tree %s/%s: %s vs %s" % [cid, sid, a, b])


func _flags(old, new) -> void:
	var flags := Domain.flags(new.default_ruleset())
	for r in old.rulesets.values():
		if r.is_default:
			check(r.flags == flags, "default ruleset flags: %s vs %s" % [r.flags, flags])
