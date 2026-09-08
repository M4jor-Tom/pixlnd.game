## Headless check of gen-spawns + creature FSM (D14): `godot --headless -s game/entities/test_creatures.gd`.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
const Spawner := preload("res://game/world/spawner.gd")

var _failed := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _init() -> void:
	var o := Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	var design: Dictionary = o.configs["generators"]["design"]
	var spawns: Dictionary = design["spawns"]
	var rosters: Dictionary = o.configs["creature-families"]["landscape-rosters"]
	var a := WorldGen.new(26879, design, o.landscapes)
	var b := WorldGen.new(26879, design, o.landscapes)
	var groups := 0; var lands_seen := {}; var lvl1_hostile_hp: Array = []
	for zx in range(-40, 41, 8):
		for zy in range(-40, 41, 8):
			var zc := Vector2i(zx * 32, zy * 32)                       # spread over many lands
			var pa := Spawner.plan(a, zc, design, o.creatures, rosters, 1)
			var pb := Spawner.plan(b, zc, design, o.creatures, rosters, 1)
			check(var_to_str(pa) == var_to_str(pb), "same seed → same spawns at %s" % zc)
			check(pa.size() <= int(spawns["groups-per-zone"][1]), "≤ max groups per zone")
			var land = a.land_of_block(zc.x * 64 + 32, zc.y * 64 + 32)
			lands_seen[land.landscape] = true
			check(land.danger_tier in ["safe", "normal", "dangerous"], "land has a danger tier")
			for g in pa:
				groups += 1
				check(g["species"] in rosters[land.landscape], "%s is in the %s roster" % [g["species"], land.landscape])
				var c: Model.Creature = o.creatures[g["species"]]
				var gs := c.group_size if c.group_size != Vector2i(1, 1) else Vector2i(1, 3)
				check(g["positions"].size() >= 1 and g["positions"].size() <= gs.y, "group size within %s: %d" % [gs, g["positions"].size()])
				check(g["level"] >= 1 and g["level"] <= 6, "level in the solo band 1..6: %d" % g["level"])
				check(g["hostility"] in ["H", "N", "P", "F"], "hostility resolved: %s" % g["hostility"])
				if g["level"] == 1: lvl1_hostile_hp.append(g["max_hp"])
	check(groups > 20, "spawns exist: %d groups" % groups)
	for hpv in lvl1_hostile_hp:
		check(hpv >= 150.0 and hpv <= 250.0, "level-1 HP calibrated 150–250: %.0f" % hpv)
	# FSM on a flat floor: a hostile chases a target inside aggro range, a passive one does not
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)
	var target := Node3D.new(); root.add_child(target); target.position = Vector3(8, 0, 0)
	var plan_ := [{"species": &"wolf", "level": 1, "hostility": &"H", "max_hp": 200.0, "damage": 12.0, "positions": [Vector3(0, 1, 0)], "seed": 1},
		{"species": &"sheep", "level": 1, "hostility": &"P", "max_hp": 200.0, "damage": 12.0, "positions": [Vector3(0, 1, 30)], "seed": 2},
		{"species": &"wolf", "level": 1, "hostility": &"H", "max_hp": 200.0, "damage": 12.0, "positions": [Vector3(0, 1, -90)], "seed": 3}]   # beyond sim-radius (80)
	var holder := Node3D.new(); root.add_child(holder)
	var made: Array = Spawner.populate(holder, plan_, design, o.creatures, target)
	var wolf: CharacterBody3D = made[0]; var sheep: CharacterBody3D = made[1]; var far: CharacterBody3D = made[2]
	var far_start: Vector3 = far.position
	var sheep_start: Vector3 = sheep.position                 # holder is at the origin; not in tree yet
	for i in 120:
		await physics_frame
	check(wolf.state in [wolf.State.CHASE, wolf.State.ATTACK], "hostile wolf chases: state %d" % wolf.state)
	check(wolf.global_position.distance_to(target.global_position) < 3.0, "wolf reached the target: %.1f" % wolf.global_position.distance_to(target.global_position))
	check(sheep.state != sheep.State.CHASE, "passive sheep never chases")
	for i in 300:
		await physics_frame
	check(sheep.position.distance_to(sheep_start) > 0.5, "sheep wanders: moved %.1f" % sheep.position.distance_to(sheep_start))
	check(far.state == far.State.IDLE and far.position == far_start, "creature beyond sim-radius is frozen (c-sim-radius): state %d, moved %.1f" % [far.state, far.position.distance_to(far_start)])
	print("creatures: %d groups over %d landscapes %s" % [groups, lands_seen.size(), lands_seen.keys()])
	print("creatures ok" if _failed == 0 else "creatures FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
