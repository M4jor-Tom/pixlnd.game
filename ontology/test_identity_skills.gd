## Identity/catalog ingestion, bidirectional ownership and selected skill-tree contracts.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Skills := preload("res://game/progression/skill_tree.gd")
var failed := 0
var rejected := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func fresh():
	return Model.Ontology.load_dir("res://ontology/instances")


func reject(o, path: String) -> void:
	rejected += 1
	check(not o.validate(), path + " fails independently")
	check(path in "\n".join(o.errors), path + " diagnosed independently")
	o.errors.append("prior load diagnostic")
	for ruleset in o.rulesets.values():
		ruleset.is_default = false
	check(not o.validate(), path + " rejected")
	var text := "\n".join(o.errors)
	check("prior load diagnostic" in text, path + " retains prior error")
	check("exactly one ruleset must be default" in text, path + " continues validation")


func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()


func ingestion(scratch: String) -> void:
	for catalog in ["classes", "specializations", "abilities"]:
		var path := scratch.path_join(catalog + ".json")
		var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		DirAccess.remove_absolute(path)
		reject(Model.Ontology.load_dir(scratch), catalog)
		for bad in [null, true, 42, "bad", [], {}, {"_doc": "metadata only"}]:
			write_json(path, bad)
			reject(Model.Ontology.load_dir(scratch), catalog)
		var id: String = {
			"classes": "warrior", "specializations": "assassin", "abilities": "camouflage"
		}[catalog]
		for bad in [null, true, 42, "bad", [], {}]:
			var raw := original.duplicate(true)
			raw[id] = bad
			write_json(path, raw)
			reject(Model.Ontology.load_dir(scratch), catalog + "." + id)
		var fields: Dictionary = {
			"classes":
			{
				"specializations": [null, "berserker", ["berserker", {}]],
				"weapon-types": [null, "sword", [{}]],
				"armor-material": [null, []],
				"special-attack-mode": [null, "unknown"],
				"id-number": [true, "1", 1.5],
				"hp-mult": [true, "1", 0]
			},
			"specializations":
			{
				"class": [null, []],
				"index": [null, true, "0", -1, 2, 0.5],
				"kit": [null, [], {"A": [{}], "S": []}],
				"passives": [null, [], {"A": [], "S": 42}]
			},
			"abilities":
			{
				"owner": [null, 42, [{}]],
				"input": [null, []],
				"cost": [null, []],
				"applies": [null, 42, [{}]],
				"alpha-tree": [null, [], {}, {"column": "class"}],
				"alpha-id": [true, "1", 1.5],
				"unlocks-next": [null, []]
			}
		}[catalog]
		for field in fields:
			for bad in fields[field]:
				var raw := original.duplicate(true)
				raw[id][field] = bad
				write_json(path, raw)
				reject(Model.Ontology.load_dir(scratch), catalog + "." + id + "." + field)
			if catalog == "classes" or catalog == "specializations" or field == "owner":
				var raw := original.duplicate(true)
				raw[id].erase(field)
				write_json(path, raw)
				reject(Model.Ontology.load_dir(scratch), catalog + "." + id + "." + field)
		# Nonmetadata malformed rows must not disappear, even when required rows remain.
		var raw := original.duplicate(true)
		raw["malformed-extra"] = 42
		write_json(path, raw)
		reject(Model.Ontology.load_dir(scratch), catalog + ".malformed-extra")
		write_json(path, original)
		check(Model.Ontology.load_dir(scratch).validate(), "restored " + catalog)


func ownership() -> void:
	for catalog in ["classes", "specializations", "abilities"]:
		var o = fresh()
		o.configs.erase(catalog)
		reject(o, catalog)
		for bad in [null, true, 42, "bad", [], {}, {"_doc": "metadata only"}]:
			o = fresh()
			o.configs[catalog] = bad
			reject(o, catalog)
	for refs in [
		[],
		["berserker"],
		["berserker", "guardian", "guardian"],
		["berserker", "berserker"],
		["berserker", "unknown"],
		["guardian", "berserker"]
	]:
		var o = fresh()
		o.classes.warrior.specializations.assign(refs)
		reject(o, "class warrior")
	var o = fresh()
	o.specs.guardian.character_class = &"mage"
	reject(o, "specializations.guardian.class")
	o = fresh()
	o.specs.guardian.character_class = &"unknown"
	reject(o, "spec guardian")
	o = fresh()
	o.classes.warrior.specializations.assign([&"berserker", &"scout"])
	reject(o, "does not list spec guardian")
	for index in [0, 2, -1]:
		o = fresh()
		o.specs.guardian.index = index
		reject(o, "class warrior")
	for bad in [true, "0", 0.5, -1, 2, NAN, INF]:
		o = fresh()
		o.specs.assassin.raw.index = bad
		reject(o, "specializations.assassin.index")
	for table in ["classes", "specs"]:
		o = fresh()
		o[table].erase("warrior" if table == "classes" else "assassin")
		reject(o, "classes.warrior" if table == "classes" else "specializations.assassin")
	for bad in [NAN, INF, true]:
		o = fresh()
		o.classes.warrior.raw["hp-mult"] = bad
		reject(o, "classes.warrior.hp-mult")


func trees() -> void:
	for field in ["column", "rank", "needs"]:
		var o = fresh()
		o.abilities.camouflage.alpha_tree.erase(field)
		reject(o, "abilities.camouflage.alpha-tree." + field)
		for bad in [null, true, [], {}, "unknown", -1, 0.5, NAN, INF]:
			o = fresh()
			o.abilities.camouflage.alpha_tree[field] = bad
			reject(o, "abilities.camouflage.alpha-tree." + field)
	for bad in [null, true, "0", -1, 0.5, NAN, INF]:
		var o = fresh()
		o.abilities["pet-master"].alpha_tree["skill-slot"] = bad
		reject(o, "abilities.pet-master.alpha-tree.skill-slot")
	for bad in [null, true, "5", [], {}, -1, 0.5, NAN, INF]:
		var o = fresh()
		o.abilities["rock-fist"].alpha_tree.needs = bad
		reject(o, "abilities.rock-fist.alpha-tree.needs")
	for bad in [null, true, 42, [], {}]:
		var o = fresh()
		o.abilities["pet-master"].raw["unlocks-next"] = bad
		reject(o, "abilities.pet-master.unlocks-next")
	var o = fresh()
	o.abilities["pet-master"].alpha_tree.erase("skill-slot")
	reject(o, "abilities.pet-master.alpha-tree.skill-slot")
	for col in ["pets", "climbing", "water"]:
		o = fresh()
		for a in o.abilities.values():
			if a.alpha_tree.get("column") == col:
				a.alpha_tree.needs = 5
		reject(o, "skill-tree")
		o = fresh()
		for id in o.abilities.keys():
			if o.abilities[id].alpha_tree.get("column") == col:
				o.abilities.erase(id)
		reject(o, "skill-tree")
	o = fresh()
	o.abilities.riding.alpha_tree.needs = 0
	reject(o, "skill-tree")
	for target in ["climbing", "unknown", "basic-attack", "rock-fist"]:
		o = fresh()
		o.abilities["pet-master"].raw["unlocks-next"] = target
		reject(o, "skill-tree")
	o = fresh()
	o.abilities.smash.raw["unlocks-next"] = "climbing"
	reject(o, "skill-tree")
	o = fresh()
	o.abilities.riding.alpha_tree["class"] = "warrior"
	reject(o, "skill-tree")
	o = fresh()
	o.abilities.smash.alpha_tree.needs = 1
	reject(o, "skill-tree")
	o = fresh()
	o.abilities.cyclone.alpha_tree.rank = 1
	reject(o, "skill-tree")
	o = fresh()
	o.abilities.erase("smash")
	reject(o, "skill-tree")
	o = fresh()
	o.abilities["heroic-shout"].owner = "warrior"
	reject(o, "skill-tree berserker")
	# Existing runtime data prevents a missing-runtime error from masking this new rule.
	o = fresh()
	o.abilities["rock-fist"].owner = "assassin"
	reject(o, "skill-tree assassin")
	for change in ["replacement", "missing", "rank2", "root", "column"]:
		o = fresh()
		match change:
			"replacement":
				o.abilities["shuriken-attack"].owner = "assassin"
				o.abilities.camouflage.owner = "ninja"
			"missing":
				o.abilities.erase("camouflage")
			"rank2":
				o.abilities.camouflage.alpha_tree.rank = 2
			"root":
				o.abilities.camouflage.alpha_tree.needs = 0
			"column":
				o.abilities.camouflage.alpha_tree.column = "ultimate"
		reject(o, "skill-tree assassin")
	for bad in [null, 1, "true", []]:
		o = fresh()
		o.abilities.camouflage.alpha_tree["also-ultimate"] = bad
		reject(o, "abilities.camouflage.alpha-tree.also-ultimate")
	o = fresh()
	o.abilities.sneak.alpha_tree["class"] = "unknown"
	reject(o, "abilities.sneak.alpha-tree.class")
	o = fresh()
	o.abilities.camouflage.alpha_tree.needs = 0
	o.classes.warrior.specializations.reverse()
	reject(o, "skill-tree assassin")
	check(
		"class warrior" in "\n".join(o.errors), "independent identity and tree defects accumulate"
	)


func positives() -> void:
	var o = fresh()
	check(o.validate(), "canonical identity validates")
	for id in o.specs:
		var s = o.specs[id]
		var tree := Skills.new(
			o, o.configs.generators.design["skill-point"], s.character_class, StringName(id)
		)
		check(tree.nodes.size() == (9 if id == "assassin" else 10), id + " node count")
		for rank in [1, 2, 3]:
			check(tree.class_slot(rank) != null, id + " class rank " + str(rank))
		var ultimate: Variant = (
			{
				"berserker": &"rock-fist",
				"guardian": &"heroic-shout",
				"sniper": &"shadow-shooter",
				"scout": &"quicksand-trap",
				"fire-mage": &"fire-missiles",
				"water-mage": &"bubbles",
				"ninja": &"ninjutsu"
			}
			. get(id)
		)
		check((tree.class_slot(4) == null) == (id == "assassin"), id + " ultimate unchanged")
		if ultimate != null:
			check(tree.class_slot(4).id == ultimate, id + " selected ultimate preserved")
		for a in tree.nodes:
			if a.alpha_tree.needs == 0:
				check(tree.prerequisite(a) == null, str(a.id) + " is a root")
			else:
				check(tree.prerequisite(a) != null, str(a.id) + " has a prerequisite")
	var assassin := Skills.new(o, {}, &"rogue", &"assassin")
	check(assassin.class_slot(3).id == &"camouflage", "Camouflage only in slot 3")
	check(assassin.prerequisite(assassin.class_slot(3)).id == &"sneak", "Camouflage needs Sneak")
	check(assassin.nodes.count(o.abilities.camouflage) == 1, "one Camouflage investment")
	check(o.abilities.camouflage.alpha_tree["also-ultimate"] == true, "source identity retained")
	check(
		o.abilities.sneak in o.skill_tree(&"rogue", &"ninja"),
		"Sneak tree class overrides source owner list"
	)
	check(
		o.abilities["healing-stream"] in o.skill_tree(&"mage", &"water-mage"),
		"Water Mage rank 1 retained"
	)
	check(o.classes.size() == 4 and not o.classes.has("_paladin"), "class metadata is not content")


func _init() -> void:
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if not directory.is_absolute_path() or not DirAccess.dir_exists_absolute(directory):
		printerr("PIXLND_TEST_DIR must name an existing isolated absolute directory")
		quit(1)
		return
	var scratch := directory.path_join("identity-skills")
	check(DirAccess.make_dir_recursive_absolute(scratch) == OK, "scratch created")
	for file in DirAccess.open("res://ontology/instances").get_files():
		if file.ends_with(".json"):
			check(
				(
					DirAccess.copy_absolute(
						ProjectSettings.globalize_path("res://ontology/instances/" + file),
						scratch.path_join(file)
					)
					== OK
				),
				"copied " + file
			)
	positives()
	ingestion(scratch)
	ownership()
	trees()
	print("identity skills: %d negative cases, %d failures" % [rejected, failed])
	quit(0 if failed == 0 else 1)
