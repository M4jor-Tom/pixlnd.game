extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func fresh():
	return Model.Ontology.load_dir("res://ontology/instances")


func reject(path: Array, value: Variant, missing := false) -> void:
	var o = fresh()
	var parent: Dictionary = o.configs.generators.design
	for part in path.slice(0, -1):
		parent = parent[part]
	if missing:
		parent.erase(path[-1])
	else:
		parent[path[-1]] = value
	o.errors.append("prior load error")
	check(not o.validate(), str(path) + " rejected")
	check(
		"prior load error" in o.errors and "design." + ".".join(path) in "\n".join(o.errors),
		str(path) + " cumulative diagnostic"
	)


func walk(row: Dictionary, path: Array) -> void:
	for key in row:
		if key.begins_with("_"):
			continue
		var p := path + [key]
		reject(p, null, true)
		for bad in [null, true, "bad", [], NAN, INF, -1, 999]:
			reject(p, bad)
		if row[key] is Dictionary:
			walk(row[key], p)


func _init() -> void:
	var o = fresh()
	check(o.validate(), "current config valid")
	var prior = fresh()
	prior.errors.append("prior load error")
	check(not prior.validate(), "prior load error alone prevents validation success")
	check(
		prior.errors == PackedStringArray(["prior load error"]),
		"valid data retains the exact prior diagnostic without adding errors"
	)
	var d: Dictionary = o.configs.generators.design
	check(
		d["initial-encounters"].get("mission-package") is Dictionary,
		"mission package inputs required"
	)
	if d["initial-encounters"].get("mission-package") is Dictionary:
		walk(d["initial-encounters"]["mission-package"], ["initial-encounters", "mission-package"])
	for key in ["loot"]:
		walk(d[key], [key])
	for key in ["stock", "rarity-cap", "level-spread", "restock"]:
		reject(["settlement", "shop", key], null, true)
		for bad in [null, true, [], NAN, INF, -1, 999, "bad"]:
			reject(["settlement", "shop", key], bad)
	var broken = fresh()
	broken.configs.generators.design.erase("loot")
	broken.configs.generators.design.settlement.erase("shop")
	check(not broken.validate(), "whole reward/shop parents required")
	for part in ["design.loot", "design.settlement.shop"]:
		check(part in "\n".join(broken.errors), "missing whole " + part)
	for gem in ["emerald", "sapphire", "ruby", "diamond"]:
		broken = fresh()
		broken.configs.ingredients.erase(gem)
		check(not broken.validate() and gem in "\n".join(broken.errors), "required gem " + gem)
	var illegal = fresh()
	illegal.classes[&"mage"].armor_material = &"unknown"
	check(
		not illegal.validate() and "illegal armor material" in "\n".join(illegal.errors),
		"illegal class armor material rejected"
	)
	illegal = fresh()
	illegal.weapon_types[&"wand"].raw.material = null
	check(
		not illegal.validate() and "missing weapon material wand" in "\n".join(illegal.errors),
		"malformed weapon material rejected"
	)
	print("encounter rewards config ok" if failed == 0 else "encounter rewards config FAILED")
	quit(0 if failed == 0 else 1)
