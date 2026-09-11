## Headless check of §3.3 game feel (D25): `godot --headless -s game/combat/test_feel.gd`.
## c-feel-config fires on a broken copy; hit-stop drops and restores Engine.time_scale on the real clock and
## overlapping bundles end at the later time; camera trauma decays to 0 and the Camera3D offsets rest at 0;
## a melee hit floats one damage number that is freed after life-s; a kill fires the stronger kill bundle; a
## creature hit on the player fires `hurt` with a red number sized to the HP actually lost; a dot tick floats the
## orange number and no second one; a stun puts stars over the wolf that vanish when the stun ends; a bow shot
## leaves trail pieces AND an impact flash of impact-radius; one AoE strike fires one bundle but a number per body;
## the HUD shows the level-up toast text and one buff icon that goes when the buff expires; every event id plays
## one sfx player that is freed again.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Combat := preload("res://game/combat/combat.gd")
const Feel := preload("res://game/combat/feel.gd")
const HUD := preload("res://game/meta/hud.gd")
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

## Juice spheres of exactly `radius`: the impact flash is impact-radius, a trail piece is much smaller.
func _spheres(radius: float) -> int:
	var n := 0
	for c in root.get_children():
		if c is MeshInstance3D and not c.is_queued_for_deletion() and c.mesh is SphereMesh and is_equal_approx(c.mesh.radius, radius):
			n += 1
	return n

func _stars_on(e: Node) -> int:
	var n := 0
	for c in e.get_children():
		if c is Label3D and not c.is_queued_for_deletion():
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
	var hit_col: Array = fl["numbers"]["colours"]["hit"]; fl["numbers"]["colours"].erase("hit")
	check(not o.validate(), "c-feel-config wants the hit colour (feel.gd's eager fallback)"); o.errors.clear()
	fl["numbers"]["colours"]["hit"] = hit_col
	var slide = fl["sfx"]["hit"]["slide"]; fl["sfx"]["hit"].erase("slide")
	check(not o.validate(), "c-feel-config wants a slide on every sfx"); o.errors.clear()
	fl["sfx"]["hit"]["slide"] = slide
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
	var hud: CanvasLayer = HUD.new(); root.add_child(hud); hud.bind(p, null)

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

	# --- one AoE strike: a number per body, but exactly ONE bundle (one sfx player)
	var pack: Array = []
	for i in 3:
		pack.append(_wolf(p, Vector3(-0.6 + 0.6 * i, 1, -1.2)))
	await _frames(4)
	before = _count("Label3D")
	var players: int = feel.get_child_count()
	var swept: int = p._strike(p.global_position + Vector3.UP, 3.0, 20.0, false)
	check(swept >= 3, "the sweep reached the whole pack (%d)" % swept)
	check(_count("Label3D") == before + swept, "one number per body hit (%d for %d bodies)" % [_count("Label3D") - before, swept])
	check(feel.get_child_count() == players + 1, "one bundle for the whole sweep, not one per body (%d)" % (feel.get_child_count() - players))
	for w in pack:
		w.queue_free()
	await _real(float(fl["numbers"]["life-s"]) + 0.3)

	# --- a creature hit on the player: hurt bundle + a red number of the HP actually lost
	before = _count("Label3D")
	wolf.damage = 10.0
	wolf.target = p
	var hp0: float = p.hp
	p.take_damage(10.0, wolf)
	check(p.hp < hp0 and _count("Label3D") == before + 1, "hurt bundle floats a number over the player")
	p.hp = 4.0                                                # a killing blow reports the HP lost, not the raw damage
	p.take_damage(1000.0, wolf)
	var last: Label3D = null
	for c in root.get_children():
		if c is Label3D and not c.is_queued_for_deletion():
			last = c
	check(last != null and last.text == "4", "the hurt number is what we lost, not the raw hit (%s)" % (last.text if last != null else "-"))
	p.dead = false; p.hp = p.max_hp
	await _real(float(fl["numbers"]["life-s"]) + 0.3)

	# --- a dot tick floats the orange number only: no hurt bundle, no second number
	before = _count("Label3D")
	players = feel.get_child_count()
	p.statuses[&"burning"] = {"left": 1.0, "tick": 0.0, "tick-s": 0.5, "dmg": 3.0, "from": wolf}
	p.tick_statuses(0.01)
	check(_count("Label3D") == before + 1, "a dot tick floats exactly one number (%d)" % (_count("Label3D") - before))
	check(feel.get_child_count() == players, "a dot tick fires no hurt bundle (%d extra)" % (feel.get_child_count() - players))
	p.statuses.clear()
	await _real(float(fl["numbers"]["life-s"]) + 0.3)

	# --- stun stars over the wolf's head, gone the moment the stun ends
	var se: Dictionary = design["status-effects"]
	wolf.apply_status(&"stun", se["stun"], 10.0, p)
	check(wolf.stunned(), "the wolf is stunned")
	check(_stars_on(wolf) == 1, "one stun-star label over the wolf (%d)" % _stars_on(wolf))
	wolf.tick_statuses(float(se["stun"]["duration-s"]) + 0.1)   # the wolf's physics is off: tick it by hand
	check(not wolf.stunned(), "the stun ended")
	await _frames(2)
	check(_stars_on(wolf) == 0, "the stars went with the stun (%d left)" % _stars_on(wolf))

	# --- a bow shot leaves trail pieces AND an impact flash of impact-radius
	var flash_r := float(fl["impact"]["impact-radius"])
	var r := _player(&"ranger", Vector3(30, 1, 0))
	var w2 := _wolf(r, Vector3(30, 1, -5))
	await _frames(5); _aim_at(r, w2)
	before = _count("MeshInstance3D")
	check(_spheres(flash_r) == 0, "no impact flash before the shot")
	await _m1(r)
	await _frames(6)
	check(_count("MeshInstance3D") >= before + 1, "the arrow left trail pieces (%d)" % (_count("MeshInstance3D") - before))
	var flashes := 0                                          # the flash fades out in impact-s, so watch for it
	for i in 30:
		await physics_frame
		flashes = maxi(flashes, _spheres(flash_r))
	check(w2.hp < 1e6, "the arrow hit")
	check(flashes >= 1, "the hit left an impact flash of impact-radius (%d)" % flashes)
	await _real(float(fl["events"]["hit"]["hit-stop-s"]) + 0.05)

	# --- the HUD: level-up toast text, then one buff icon that goes when the buff expires
	p.gain_xp(100000)
	check(p.level > 1, "leveled up (level %d)" % p.level)
	await process_frame
	check(hud._toast.text == str(fl["level-up"]["text"]), "the HUD toast shows the level-up text ('%s')" % hud._toast.text)
	p.abilities.buffs[&"war-frenzy"] = {"left": 0.2, "r": design["abilities"]["war-frenzy"]}
	await process_frame; await process_frame
	check(hud._buffs.get_child_count() == 1, "one buff icon on the HUD (%d)" % hud._buffs.get_child_count())
	p.abilities.tick(0.5)                                     # the buff expired
	await process_frame; await process_frame
	check(hud._buffs.get_child_count() == 0, "the icon went with the buff (%d left)" % hud._buffs.get_child_count())

	# --- every event id plays exactly one sfx player, freed again after len-s
	players = feel.get_child_count()
	var played := 0
	for id in fl["events"]:
		feel.play(StringName(id))
		played += 1
		check(feel.get_child_count() == players + played, "%s played one sfx player (%d)" % [id, feel.get_child_count() - players])
	await _real(1.2)                                          # let every sfx player / tween finish before we quit
	check(feel.get_child_count() == 0, "every sfx player was freed again (%d left)" % feel.get_child_count())
	check(Engine.time_scale == 1.0, "every event bundle played and the time scale is back to 1.0")

	Engine.time_scale = 1.0
	print("test_feel: %s" % ("OK" if _failed == 0 else "%d FAILED" % _failed))
	quit(1 if _failed > 0 else 0)
