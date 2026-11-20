## Design-config rejections moved from the game tests when the game stopped loading model.gd:
## c-ability-runtime, c-defence-config, c-moveset-config, c-feel-config, c-creature-roles,
## c-xp-config, c-tree-shape, c-loot-config and c-settlement-config. Each case resets its mutation.
extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0
var o


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func rejects(label: String) -> void:
	check(not o.validate(), label)
	o.errors.clear()


func _init() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	var design: Dictionary = o.configs["generators"]["design"]
	_abilities(design["abilities"])
	_defence(design["defence"])
	_movesets(design["movesets"])
	_feel(design["feel"])
	_creature_roles(design["creature-roles"])
	_singles(design)
	check(o.validate(), "restored")
	print("design config rejections ok" if failed == 0 else "design config FAILED: %d" % failed)
	quit(0 if failed == 0 else 1)


func _abilities(ab: Dictionary) -> void:
	var runtime = ab["smash"]["runtime"]
	ab["smash"]["runtime"] = "fly"
	rejects("c-ability-runtime rejects an unknown runtime")
	ab["smash"]["runtime"] = runtime
	ab["smash"]["cost"]["mp"] = 150
	rejects("c-ability-runtime rejects mp cost > 100")
	ab["smash"]["cost"].erase("mp")
	check(o.validate(), "abilities restored")


func _defence(df: Dictionary) -> void:
	var reduction = df["block"]["damage-reduction"]
	df["block"]["damage-reduction"] = 2.0
	rejects("c-defence-config rejects damage-reduction > 1")
	df["block"]["damage-reduction"] = reduction
	df["dodge"]["on-dodge"]["smash"] = {"mp": 1}
	rejects("c-defence-config rejects a non-passive on-dodge key")
	df["dodge"]["on-dodge"].erase("smash")


func _movesets(mv: Dictionary) -> void:
	var kind = mv["bow"]["m1"]["kind"]
	mv["bow"]["m1"]["kind"] = "laser"
	rejects("c-moveset-config rejects an unknown kind")
	mv["bow"]["m1"]["kind"] = kind
	var wand = mv["wand"]
	mv.erase("wand")
	rejects("c-moveset-config wants every class weapon-type")
	mv["wand"] = wand
	var speed = mv["bow"]["m2"]["speed"]
	mv["bow"]["m2"]["speed"] = 0
	rejects("c-moveset-config rejects speed 0")
	mv["bow"]["m2"]["speed"] = speed


func _feel(fl: Dictionary) -> void:
	var sfx = fl["events"]["hit"]["sfx"]
	fl["events"]["hit"]["sfx"] = "nope"
	rejects("c-feel-config rejects an sfx id that is not an alpha sound")
	fl["events"]["hit"]["sfx"] = sfx
	var trauma = fl["events"]["crit"]["trauma"]
	fl["events"]["crit"]["trauma"] = 2.0
	rejects("c-feel-config rejects trauma > 1")
	fl["events"]["crit"]["trauma"] = trauma
	var time_scale = fl["hit-stop"]["time-scale"]
	fl["hit-stop"]["time-scale"] = 1.5
	rejects("c-feel-config rejects a hit-stop time-scale >= 1")
	fl["hit-stop"]["time-scale"] = time_scale
	var kill_ev: Dictionary = fl["events"]["kill"]
	fl["events"].erase("kill")
	rejects("c-feel-config wants every required event id")
	fl["events"]["kill"] = kill_ev
	var hit_col: Array = fl["numbers"]["colours"]["hit"]
	fl["numbers"]["colours"].erase("hit")
	rejects("c-feel-config wants the hit colour (feel.gd's eager fallback)")
	fl["numbers"]["colours"]["hit"] = hit_col
	var slide = fl["sfx"]["hit"]["slide"]
	fl["sfx"]["hit"].erase("slide")
	rejects("c-feel-config wants a slide on every sfx")
	fl["sfx"]["hit"]["slide"] = slide


func _creature_roles(cr: Dictionary) -> void:
	var default = cr["default"]
	cr["default"] = "archer"
	rejects("c-creature-roles rejects a default that is not a role")
	cr["default"] = default
	var ranged = cr["any-class"]["ranged"]
	cr["any-class"]["ranged"] = -1.0
	rejects("c-creature-roles rejects a negative any-class weight")
	cr["any-class"]["ranged"] = ranged
	var speed = cr["ranged"]["shot"]["speed"]
	cr["ranged"]["shot"]["speed"] = 0
	rejects("c-creature-roles rejects a shot with speed 0")
	cr["ranged"]["shot"]["speed"] = speed
	var applies = cr["mage"]["applies"]
	cr["mage"]["applies"] = ["nope"]
	rejects("c-creature-roles rejects an applies id with no status-effect")
	cr["mage"]["applies"] = applies
	var sfx = cr["ranged"]["sfx"]
	cr["ranged"]["sfx"] = "nope"
	rejects("c-creature-roles rejects an sfx that is not an alpha sound")
	cr["ranged"]["sfx"] = sfx
	cr["species"]["nope"] = {"damage-mult": 2.0}
	rejects("c-creature-roles rejects a species override for an unknown creature")
	cr["species"].erase("nope")


func _singles(design: Dictionary) -> void:
	var prog: Dictionary = design["progression"]
	var fraction = prog["kill-fraction"]
	prog["kill-fraction"] = 1.5
	rejects("c-xp-config rejects kill-fraction > 1")
	prog["kill-fraction"] = fraction
	var tree: Dictionary = o.abilities["cyclone"].alpha_tree
	var rank = tree["rank"]
	tree["rank"] = 3
	rejects("c-tree-shape rejects two rank-3 nodes")
	tree["rank"] = rank
	var loot: Dictionary = design["loot"]
	var chance = loot["gear-chance"]
	loot["gear-chance"] = 2.0
	rejects("c-loot-config rejects a chance above 1")
	loot["gear-chance"] = chance
	var st: Dictionary = design["settlement"]
	var ring = st["ring-radius"]
	st["ring-radius"] = 99.0
	rejects("c-settlement-config rejects ring-radius ≥ radius")
	st["ring-radius"] = ring
