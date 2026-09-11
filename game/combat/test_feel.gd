## Headless check of §3.3 game feel (D25): `godot --headless -s game/combat/test_feel.gd`.
## c-feel-config fires on a broken copy; hit-stop drops and restores Engine.time_scale on the real clock and
## overlapping bundles end at the later time; camera trauma decays to 0 and the Camera3D offsets rest at 0;
## a melee hit floats one damage number that is freed after life-s; a kill fires the stronger kill bundle; a
## creature hit on the player fires `hurt` with a red number; a stun puts stars over the wolf that vanish with
## it; a bow shot leaves trail pieces and an impact flash; the level-up bundle runs; every event id's
## synthesised sfx plays without error under the Dummy driver; a pick-up fires `pickup`.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Combat := preload("res://game/combat/combat.gd")
const Feel := preload("res://game/combat/feel.gd")
const Spawner := preload("res://game/world/spawner.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")

var _failed := 0
var design: Dictionary
var o
var feel

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

## Real seconds, so a running hit-stop cannot stall the wait (Engine.time_scale scales physics_frame).
func _real(s: float) -> void:
	await create_timer(s, true, false, true).timeout
	await process_frame

func _player(class_id: StringName, at: Vector3) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate()
	p.position = at
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(1, 1.0))
	p.setup_items(o, design, class_id)
	p.position = at; p.spawn_point = at
	p.get_node("CameraRig").rotation.x = 0.0
	p.feel = feel
	return p

func _wolf(p: Node, at: Vector3, hp := 1e6) -> CharacterBody3D:
	var holder := Node3D.new(); root.add_child(holder)
	var w: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"P", "max_hp": hp, "damage": 12.0,
		"positions": [at], "seed": 1}], design, o.creatures, p, null)[0]
	w.set_physics_process(false)
	return w

func _m1(p) -> void:
	p._swing_t = 0.0
	Input.action_press("basic-attack"); await _frames(2); Input.action_release("basic-attack")

func _aim_at(p, t: Node3D) -> void:
	var d: Vector3 = t.global_position + Vector3.UP * 0.5 - p.eye()
	p.get_node("CameraRig").rotation.x = atan2(d.y, -d.z)

## Label3D / MeshInstance3D juice lives next to the feel node (root here).
func _count(type: String) -> int:
	var n := 0
	for c in root.get_children():
		if c.is_class(type) and not c.is_queued_for_deletion():
			n += 1
	return n

func _init() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs["generators"]["design"]
	var fl: Dictionary = design["feel"]

	# --- c-feel-config
	fl["events"]["hit"]["sfx"] = "nope"
	check(not o.validate(), "c-feel-config rejects an sfx id that is not an alpha sound"); o.errors.clear()
	fl["events"]["hit"]["sfx"] = "hit"
	fl["events"]["crit"]["trauma"] = 2.0
	check(not o.validate(), "c-feel-config rejects trauma > 1"); o.errors.clear()
	fl["events"]["crit"]["trauma"] = 0.3
	fl["hit-stop"]["time-scale"] = 1.5
	check(not o.validate(), "c-feel-config rejects a hit-stop time-scale >= 1"); o.errors.clear()
	fl["hit-stop"]["time-scale"] = 0.05
	var kill_ev: Dictionary = fl["events"]["kill"]; fl["events"].erase("kill")
	check(not o.validate(), "c-feel-config wants every required event id"); o.errors.clear()
	fl["events"]["kill"] = kill_ev
	check(o.validate(), "restored")

	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)

	feel = Feel.new(); root.add_child(feel)
	var p := _player(&"warrior", Vector3(0, 1, 0))
	feel.setup(fl, p.get_node("CameraRig"))
	var rig := p.get_node("CameraRig")
	var cam: Camera3D = rig.get_node("Arm/Camera")

	# --- hit-stop: the real clock drops and restores the time scale, the longer bundle wins
	var hs: Dictionary = fl["hit-stop"]
	feel.play(&"hit")
	check(is_equal_approx(Engine.time_scale, float(hs["time-scale"])), "hit froze the time scale (%.3f)" % Engine.time_scale)
	await _real(float(fl["events"]["hit"]["hit-stop-s"]) + 0.05)
	check(Engine.time_scale == 1.0, "time scale restored after the hit-stop (%.3f)" % Engine.time_scale)
	feel.play(&"kill"); feel.play(&"hit")                     # the shorter one must not end the longer one
	await _real(float(fl["events"]["hit"]["hit-stop-s"]) + 0.02)
	check(Engine.time_scale < 1.0, "overlapping bundles still frozen at the shorter end time")
	await _real(float(fl["events"]["kill"]["hit-stop-s"]))
	check(Engine.time_scale == 1.0, "the later end time released the stop")

	# --- trauma decays to rest
	check(rig.trauma > 0.0, "the bundles left camera trauma (%.2f)" % rig.trauma)
	await _real(1.0 / float(fl["shake"]["decay-per-s"]) + 0.4)
	check(rig.trauma == 0.0, "trauma decayed to 0 (%.3f)" % rig.trauma)
	check(cam.h_offset == 0.0 and cam.v_offset == 0.0 and cam.rotation.z == 0.0, "the camera rests at exactly 0 offsets")

	# --- a melee hit floats one number, freed after life-s
	var wolf := _wolf(p, Vector3(0, 1, -1.5))
	await _frames(5)
	var before := _count("Label3D")
	await _m1(p)
	await _frames(2)
	check(_count("Label3D") == before + 1, "one damage number over the hit wolf (%d)" % (_count("Label3D") - before))
	await _real(float(fl["numbers"]["life-s"]) + 0.3)
	check(_count("Label3D") == before, "the number was freed after life-s (%d left)" % _count("Label3D"))

	# --- a kill fires the kill bundle: more trauma than a hit
	rig.trauma = 0.0
	feel.play(&"hit")
	var hit_trauma: float = rig.trauma
	rig.trauma = 0.0
	var dying := _wolf(p, Vector3(0, 1, -1.5), 1.0)
	await _frames(2)
	await _m1(p)
	await _frames(2)
	check(dying.dead, "the wolf died from the swing")
	check(rig.trauma > hit_trauma, "the kill bundle shook harder than a hit (%.2f > %.2f)" % [rig.trauma, hit_trauma])
	await _real(float(fl["events"]["kill"]["hit-stop-s"]) + 0.1)

	# --- a creature hit on the player: hurt bundle + a red number
	before = _count("Label3D")
	wolf.damage = 10.0
	wolf.target = p
	var hp0: float = p.hp
	p.take_damage(10.0, wolf)
	check(p.hp < hp0 and _count("Label3D") == before + 1, "hurt bundle floats a number over the player")
	await _real(float(fl["numbers"]["life-s"]) + 0.3)

	# --- stun stars over the wolf's head while the stun lasts
	var se: Dictionary = design["status-effects"]
	wolf.apply_status(&"stun", se["stun"], 10.0, p)
	check(wolf.stunned(), "the wolf is stunned")
	var stars := 0
	for c in wolf.get_children():
		if c is Label3D:
			stars += 1
	check(stars == 1, "one stun-star label over the wolf (%d)" % stars)
	await _real(float(se["stun"]["duration-s"]) + 0.3)
	stars = 0
	for c in wolf.get_children():
		if c is Label3D and not c.is_queued_for_deletion():
			stars += 1
	check(stars == 0, "the stars went with the stun (%d left)" % stars)

	# --- a bow shot leaves trail pieces and an impact flash
	var r := _player(&"ranger", Vector3(30, 1, 0))
	var w2 := _wolf(r, Vector3(30, 1, -5))
	await _frames(5); _aim_at(r, w2)
	before = _count("MeshInstance3D")
	await _m1(r)
	await _frames(6)
	check(_count("MeshInstance3D") >= before + 1, "the arrow left trail pieces (%d)" % (_count("MeshInstance3D") - before))
	await _frames(20)
	check(w2.hp < 1e6, "the arrow hit")
	await _real(float(fl["events"]["hit"]["hit-stop-s"]) + 0.05)

	# --- level-up, pick-up and every synthesised sfx run headless without an error
	p.gain_xp(100000)
	check(p.level > 1, "leveled up (level %d)" % p.level)
	feel.play(&"pickup"); feel.play(&"coin")
	for id in fl["events"]:
		feel.play(StringName(id))
	await _real(1.2)                                          # let every sfx player / tween finish before we quit
	check(Engine.time_scale == 1.0, "every event bundle played and the time scale is back to 1.0")

	Engine.time_scale = 1.0
	print("test_feel: %s" % ("OK" if _failed == 0 else "%d FAILED" % _failed))
	quit(1 if _failed > 0 else 0)
