extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0
func check(ok: bool, label: String) -> void:
	if not ok: failed += 1; printerr("FAIL: ",label)
func fresh(): return Model.Ontology.load_dir("res://ontology/instances")
func reject(path: Array, value: Variant, missing := false) -> void:
	var o = fresh(); var parent: Dictionary = o.configs.generators.design
	for part in path.slice(0,-1): parent = parent[part]
	if missing: parent.erase(path[-1])
	else: parent[path[-1]] = value
	o.errors.append("prior load error")
	check(not o.validate(),str(path)+" rejected")
	var diagnostics := "\n".join(o.errors)
	check("prior load error" in diagnostics and ("design."+".".join(path)) in diagnostics,str(path)+" cumulative diagnostic")
func walk(row: Dictionary, path: Array) -> void:
	for key in row:
		var p := path+[key]
		reject(p,null,true)
		for bad in [null,true,"bad",[],NAN,INF,-1,999]: reject(p,bad)
		if row[key] is Dictionary: walk(row[key],p)
func _init() -> void:
	var o = fresh(); check(o.validate(),"current data valid")
	var cfg: Dictionary = o.configs.generators.design["initial-encounters"]
	for key in ["special-profile","rubble","spikes","furnishings"]:
		check(cfg.get(key) is Dictionary,"required feature "+key)
		if cfg.get(key) is Dictionary: walk(cfg[key],["initial-encounters",key])
	var broken = fresh(); broken.configs["block-types"].alpha["6"].solid = false
	check(not broken.validate() and "initial-encounters.rubble.block-type" in "\n".join(broken.errors),"non-solid rubble definition rejected")
	var combined = fresh(); combined.errors.append("prior load error")
	combined.configs.generators.design["initial-encounters"].erase("spikes")
	combined.configs.generators.design["initial-encounters"].erase("special-profile")
	check(not combined.validate(),"independent missing feature sections rejected")
	for path in ["prior load error","design.initial-encounters.spikes","design.initial-encounters.special-profile"]:
		check(path in "\n".join(combined.errors),"combined missing diagnostics retain "+path)
	print("encounter feature config ok" if failed == 0 else "encounter feature config FAILED")
	quit(0 if failed == 0 else 1)
