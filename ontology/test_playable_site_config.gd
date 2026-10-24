extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0
func check(ok: bool, label: String) -> void:
	if not ok: failed += 1; printerr("FAIL: ",label)
func fresh(): return Model.Ontology.load_dir("res://ontology/instances")
func reject(o, path: String) -> void:
	check(not o.validate() and path in "\n".join(o.errors),path+" rejected with diagnostic")
func _init() -> void:
	var o = fresh()
	check(o.validate(),"shipped data valid")
	var d: Dictionary = o.configs.generators.design
	check(d.get("initial-encounters") is Dictionary,"required playable site configuration")
	if d.get("initial-encounters") is Dictionary:
		var selected: Dictionary = d["initial-encounters"]
		for key in selected:
			if key.begins_with("_"): continue
			var absent = fresh(); absent.configs.generators.design["initial-encounters"].erase(key)
			reject(absent,"design.initial-encounters."+key)
			var changed = fresh(); changed.configs.generators.design["initial-encounters"][key] = null
			reject(changed,"design.initial-encounters."+key)
		for bad in [null,[],true,"invalid",{}]:
			var broken = fresh(); broken.configs.generators.design["initial-encounters"] = bad
			reject(broken,"design.initial-encounters")
		for key in ["distance-min","distance-max","separation","apron","path-width","max-step","dry-above-sea","hub-size","boss-hp-mult","boss-damage-mult"]:
			for bad in [true,"4",-1,NAN,INF,999]:
				var broken = fresh(); broken.configs.generators.design["initial-encounters"][key] = bad
				reject(broken,"design.initial-encounters."+key)
		for field in ["role-weights","boss-specials","spirits"]:
			var extra = fresh(); extra.configs.generators.design["initial-encounters"][field]["unapproved"] = 1
			reject(extra,"design.initial-encounters."+field+".unapproved")
		for field in ["ruins","camp","supplier","boss-height"]:
			for key in selected[field]:
				var broken = fresh(); broken.configs.generators.design["initial-encounters"][field][key] = null
				reject(broken,"design.initial-encounters."+field+"."+key)
		var combined = fresh(); combined.errors.append("prior error")
		combined.configs.generators.design["initial-encounters"].erase("hub-size")
		combined.configs.generators.design["initial-encounters"].erase("path-width")
		check(not combined.validate(),"cumulative rejection")
		for text in ["prior error","design.initial-encounters.hub-size","design.initial-encounters.path-width"]:
			check(text in "\n".join(combined.errors),text+" retained")
	print("playable site config ok" if failed == 0 else "playable site config FAILED")
	quit(0 if failed == 0 else 1)
