## Catches missing/unsafe selected HP validation, including hand slots and material rows.
extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1; printerr("FAIL: ", label)
func rejected(o, path: String, label: String) -> void:
	check(not o.validate(), label + " rejected")
	check(path in "\n".join(o.errors), label + " scoped diagnostic")
func fresh():
	return Model.Ontology.load_dir("res://ontology/instances")
func _init() -> void:
	var shipped = fresh()
	check(shipped.validate(), "shipped ontology passes")
	var selected := {"curve-mult": 5.0, "base": 2.0, "upgrade-step": 0.1}
	for value in [null, [], "hp", true, 1, {}]:
		var o = fresh()
		o.configs["generators"]["design"]["gear-hp"] = value
		rejected(o, "design.gear-hp", "missing/malformed HP input " + str(value))
	var missing = fresh()
	missing.configs["generators"]["design"].erase("gear-hp")
	rejected(missing, "design.gear-hp", "absent HP input")
	for key in selected:
		var o = fresh()
		o.configs["generators"]["design"]["gear-hp"] = selected.duplicate()
		o.configs["generators"]["design"]["gear-hp"].erase(key)
		rejected(o, "design.gear-hp." + key, "missing " + key)
		for value in [null, [], {}, "5", true, -1, 0, 0.2, INF, NAN]:
			o = fresh()
			o.configs["generators"]["design"]["gear-hp"] = selected.duplicate()
			o.configs["generators"]["design"]["gear-hp"][key] = value
			rejected(o, "design.gear-hp." + key, "invalid %s %s" % [key, value])
	for id in ["iron", "cotton", "linen"]:
		var o = fresh()
		o.materials.erase(id)
		rejected(o, "material %s.raw.hp-bonus" % id, "absent material " + id)
		o = fresh()
		o.materials[id].raw.erase("hp-bonus")
		rejected(o, "material %s.raw.hp-bonus" % id, "missing bonus " + id)
		for value in [null, [], {}, "1", true, -1, 0, 0.2, INF, NAN]:
			o = fresh()
			o.materials[id].raw["hp-bonus"] = value
			rejected(o, "material %s.raw.hp-bonus" % id, "invalid material %s %s" % [id, value])
	for id in ["chest", "gloves", "boots", "shoulders", "main-hand", "off-hand"]:
		for value in [null, [], {}, "0.5", true, -1, 0, 0.2, INF, NAN]:
			var o = fresh()
			for slot in o.configs["equipment-slots"]["slots"]:
				if slot["id"] == id: slot["hp-mult"] = value
			rejected(o, "equipment-slots.slots." + id, "invalid slot %s %s" % [id, value])
		for mode in ["absent", "missing", "duplicate", "malformed"]:
			var o = fresh()
			var slots: Array = o.configs["equipment-slots"]["slots"]
			for i in range(slots.size()):
				if slots[i]["id"] != id: continue
				match mode:
					"absent": slots.remove_at(i)
					"missing": slots[i].erase("hp-mult")
					"duplicate": slots.append(slots[i].duplicate())
					"malformed": slots[i] = "bad row"
				break
			rejected(o, "equipment-slots.slots." + id, mode + " slot " + id)
	for value in [null, [], {}, {"slots": null}, {"slots": {}}, {"slots": []}]:
		var o = fresh()
		o.configs["equipment-slots"] = value
		rejected(o, "equipment-slots.slots.main-hand", "malformed/missing slots " + str(value))
	var multiple = fresh()
	multiple.configs["generators"]["design"].erase("gear-hp")
	multiple.materials["iron"].raw.erase("hp-bonus")
	rejected(multiple, "design.gear-hp", "multiple errors")
	check("material iron.raw.hp-bonus" in "\n".join(multiple.errors), "selected errors accumulate")
	print("Gear HP config ok" if failed == 0 else "Gear HP config FAILED: %d" % failed)
	quit(0 if failed == 0 else 1)
