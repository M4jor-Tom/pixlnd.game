## Selected Resistance inputs must fail closed; broader equipment validation remains separate.
extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1; printerr("FAIL: ", label)
func rejected(combat: Variant, path: String, label: String) -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	o.configs["generators"]["design"]["combat"] = combat
	check(not o.validate(), label + " rejected")
	check(path in "\n".join(o.errors), label + " has scoped diagnostic")
func rejected_floor(value: Variant, missing: bool, label: String) -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var combat: Dictionary = o.configs["generators"]["design"]["combat"]
	if missing: combat.erase("armor-floor")
	else: combat["armor-floor"] = value
	check(not o.validate(), label + " rejected")
	check("design.combat.armor-floor" in "\n".join(o.errors), label + " has scoped diagnostic")
func rejected_material(id: String, value: Variant, missing: bool, label: String) -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var raw: Dictionary = o.materials[id].raw
	if missing: raw.erase("resi-mult")
	else: raw["resi-mult"] = value
	var path := "material %s.raw.resi-mult" % id
	check(not o.validate(), label + " rejected")
	check(path in "\n".join(o.errors), label + " has scoped diagnostic")
func rejected_slot(id: String, value: Variant, missing: bool, label: String) -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	for slot in o.configs["equipment-slots"]["slots"]:
		if slot["id"] == id:
			if missing: slot.erase("hp-mult")
			else: slot["hp-mult"] = value
	var path := "equipment-slots.slots.%s.hp-mult" % id
	check(not o.validate(), label + " rejected")
	check(path in "\n".join(o.errors), label + " has scoped diagnostic")
func rejected_slot_config(config: Variant, label: String) -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	o.configs["equipment-slots"] = config
	check(not o.validate(), label + " rejected")
	check("equipment-slots.slots.chest" in "\n".join(o.errors), label + " has scoped diagnostic")
func _init() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "shipped ontology passes")
	var combat: Dictionary = o.configs["generators"]["design"]["combat"]
	var missing := combat.duplicate(true); missing.erase("creature-resistance")
	rejected(missing, "design.combat.creature-resistance", "missing creature Resistance")
	for value in [null, [], {}, "0", true, -1, 0.1, INF, NAN]:
		var invalid := combat.duplicate(true); invalid["creature-resistance"] = value
		rejected(invalid, "design.combat.creature-resistance", "invalid creature Resistance " + str(value))
	for value in [null, [], "combat", 1, true]:
		rejected(value, "design.combat", "malformed combat config " + str(value))
	var absent: Dictionary = o.configs["generators"]["design"].duplicate(true)
	absent.erase("combat")
	var missing_combat = Model.Ontology.load_dir("res://ontology/instances")
	missing_combat.configs["generators"]["design"] = absent
	check(not missing_combat.validate(), "missing combat config rejected")
	check("design.combat: required object missing or malformed" in missing_combat.errors, "missing combat config has scoped diagnostic")
	var multiple := combat.duplicate(true); multiple.erase("creature-resistance")
	var invalid = Model.Ontology.load_dir("res://ontology/instances")
	invalid.configs["generators"]["design"]["combat"] = multiple
	invalid.configs["generators"]["design"].erase("status-effects")
	check(not invalid.validate(), "multiple missing selected inputs rejected")
	check("design.combat.creature-resistance" in "\n".join(invalid.errors) and "design.status-effects" in "\n".join(invalid.errors), "errors accumulate across selected inputs")

	for value in [null, "0.1", true, -0.1, 0.2, INF, NAN]:
		rejected_floor(value, false, "invalid Resistance floor " + str(value))
	rejected_floor(null, true, "missing Resistance floor")
	var materials := {"iron": 0.85, "linen": 0.75, "cotton": 0.75, "silk": 1.0}
	for id in materials:
		rejected_material(id, null, true, "missing %s Resistance multiplier" % id)
		for value in [null, "bad", true, -0.1, 0.2, INF, NAN]:
			rejected_material(id, value, false, "invalid %s Resistance multiplier %s" % [id, value])
	var slots := {"chest": 1.0, "gloves": 0.5, "boots": 0.5, "shoulders": 0.5}
	for id in slots:
		rejected_slot(id, null, true, "missing %s armor slot multiplier" % id)
		for value in [null, "bad", true, -0.1, 0.2, INF, NAN]:
			rejected_slot(id, value, false, "invalid %s armor slot multiplier %s" % [id, value])
	var incomplete_slots: Array = o.configs["equipment-slots"]["slots"].duplicate(true)
	for i in range(incomplete_slots.size()):
		if incomplete_slots[i]["id"] == "chest":
			incomplete_slots.remove_at(i); break
	rejected_slot_config({"slots": incomplete_slots}, "missing active armor slot row")
	rejected_slot_config([], "malformed equipment-slots config")
	print("Resistance config ok" if failed == 0 else "Resistance config FAILED: %d" % failed)
	quit(0 if failed == 0 else 1)
