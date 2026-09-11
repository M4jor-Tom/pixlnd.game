## game feel (§3.3 combat feedback + §3.7 hud-element, D25): one node that plays a feedback bundle per combat
## event from `design.feel` — hit-stop (Engine.time_scale for a real-time slice), camera trauma, a synthesised
## sound, a floating damage number, an impact flash — plus the stun stars, the projectile trail and the flash
## pieces other scripts ask for by hand. Every *design* number comes from the ontology; the literals left here are
## geometry and audio plumbing `design.feel` defines no key for — MIX_RATE, the buffer / free pads, the star head
## offset, the trail radius, and the flash / trail / star colours.
## Injected by main.gd (`feel.setup(design["feel"], player.get_node("CameraRig"))`, `player.feel = feel`); this
## script never names OntologyDB so headless tests can drive it.
## ponytail: sounds are synthesised sine+noise blips (no audio asset file exists yet); flashes / trails / stars are
## meshes and Label3Ds, not particles; the accessibility knob is `design.feel.shake.shake-mult`, no options screen;
## numbers draw over everything (no depth sort); bundles fire on the damage, not on a frame of a hit animation
## (there are none). All in todo_implement.md.
extends Node

const MIX_RATE := 22050.0                          # half rate is plenty for 0.05-0.4 s blips

var cfg: Dictionary = {}                           # design.feel
var camera: Node                                   # orbit_camera.gd (add_trauma), may be null in tests
var trail_every := 0.03                            # design.feel.trail.trail-every-s, read by projectile.gd
var _stop_end := -1.0                              # real seconds when the running hit-stop ends; < 0 = none
var _pcm: Dictionary = {}                          # sfx id → PackedVector2Array, baked once in setup

func setup(feel: Dictionary, p_camera: Node = null) -> void:
	cfg = feel
	camera = p_camera
	trail_every = float(cfg["trail"]["trail-every-s"])
	if camera != null:
		camera.shake = cfg["shake"]
	_pcm.clear()
	for id in cfg.get("sfx", {}):                  # bake every waveform here, never in the frame that plays it
		_pcm[StringName(id)] = _bake(cfg["sfx"][id])

## design.feel.events[event]: hit-stop + camera trauma + sound, and — when `at` is given — a damage number
## (`extra.amount`, `extra.kind` picks the colour) and an impact flash (`extra.radius`, 0 = the default).
func play(event: StringName, at := Vector3.INF, extra: Dictionary = {}) -> void:
	var e: Dictionary = cfg.get("events", {}).get(event, {})
	if e.is_empty():
		return
	hit_stop(float(e.get("hit-stop-s", 0.0)))
	if camera != null and is_instance_valid(camera):
		camera.add_trauma(float(e.get("trauma", 0.0)))
	sfx(StringName(str(e["sfx"])))
	if at == Vector3.INF:
		return
	if extra.has("amount"):
		number(at, float(extra["amount"]), StringName(str(extra.get("kind", &"hit"))))
	if extra.has("radius"):
		flash(at, float(extra["radius"]))

## Freeze at design.feel.hit-stop.time-scale for `s` real seconds, capped at max-s. Overlapping bundles never
## stack: the later end time wins, and _process (real clock, time_scale cannot stall it) restores 1.0.
func hit_stop(s: float) -> void:
	if s <= 0.0 or cfg.is_empty():
		return
	var hs: Dictionary = cfg["hit-stop"]
	_stop_end = maxf(_stop_end, _now() + minf(s, float(hs["max-s"])))
	Engine.time_scale = float(hs["time-scale"])

func _process(_dt: float) -> void:
	if _stop_end >= 0.0 and _now() >= _stop_end:
		_stop_end = -1.0
		Engine.time_scale = 1.0

func _exit_tree() -> void:
	_stop_end = -1.0
	Engine.time_scale = 1.0

## A floating damage number over `at` (design.feel.numbers): rises rise-blocks and fades over life-s.
func number(at: Vector3, amount: float, kind: StringName = &"hit") -> Label3D:
	var nb: Dictionary = cfg["numbers"]
	var l := _label("%d" % maxi(1, roundi(amount)), int(nb["font-size"]), _colour(kind))
	if kind == &"crit":
		l.scale *= float(nb["crit-scale"])
	_world().add_child(l)
	l.global_position = at
	var life := float(nb["life-s"])
	var tw := l.create_tween().set_ignore_time_scale(true).set_parallel(true)
	tw.tween_property(l, "global_position", at + Vector3.UP * float(nb["rise-blocks"]), life)
	tw.tween_property(l, "modulate:a", 0.0, life)
	tw.chain().tween_callback(l.queue_free)
	return l

## An impact sphere at `at` fading over impact-s; radius 0 = design.feel.impact.impact-radius.
func flash(at: Vector3, radius := 0.0) -> MeshInstance3D:
	var im: Dictionary = cfg["impact"]
	var m := _sphere(radius if radius > 0.0 else float(im["impact-radius"]), Color(1.0, 0.9, 0.5, 0.6))
	_world().add_child(m)
	m.global_position = at
	_fade(m, float(im["impact-s"]))
	return m

## One fading trail piece of a projectile (design.feel.trail), lives trail-s.
func trail(at: Vector3) -> MeshInstance3D:
	var m := _sphere(0.12, Color(1.0, 0.85, 0.3, 0.5))
	_world().add_child(m)
	m.global_position = at
	_fade(m, float(cfg["trail"]["trail-s"]))
	return m

## '✶ ✶ ✶' over a stunned entity's head (ui.json#hud.stun-stars, D25); entity.gd frees it when the stun ends.
func stars(e: Node3D) -> Label3D:
	var l := _label("✶ ✶ ✶", int(cfg["numbers"]["font-size"]), Color(1.0, 0.9, 0.3))
	var body := e.get_node_or_null("Body")
	l.position = Vector3.UP * ((body.mesh.height if body != null and body.mesh != null else 2.0) + 0.4)
	e.add_child(l)
	return l                                       # the caller frees it when the stun actually ends (entity.gd)

## design.feel.sfx[id] → PCM, once at setup: a sine at hz whose pitch multiplies by 2^slide across the sound,
## mixed with white noise by `noise`, linear fade-out. ponytail: placeholder until audio assets land.
func _bake(s: Dictionary) -> PackedVector2Array:
	var n := int(float(s["len-s"]) * MIX_RATE)
	var buf := PackedVector2Array(); buf.resize(n)
	var hz := float(s["hz"]); var noise := float(s["noise"]); var slide := float(s["slide"])
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		phase += TAU * hz * pow(2.0, slide * t) / MIX_RATE
		var v: float = lerpf(sin(phase), randf() * 2.0 - 1.0, noise) * (1.0 - t)
		buf[i] = Vector2(v, v)
	return buf

## Push the baked buffer into a throwaway player: no synthesis in the frame that plays the sound.
func sfx(id: StringName) -> void:
	var buf: PackedVector2Array = _pcm.get(id, PackedVector2Array())
	if buf.is_empty() or not is_inside_tree():             # a bundle fired before the tree started: no sound
		return
	var len_s := float(buf.size()) / MIX_RATE
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = len_s + 0.1
	var pl := AudioStreamPlayer.new()
	pl.stream = gen
	add_child(pl)
	pl.play()
	var pb: AudioStreamGeneratorPlayback = pl.get_stream_playback()
	if pb != null:                                 # null only if the audio server refused the player: silence, no crash
		pb.push_buffer(buf)
	_free_after(pl, len_s + 0.15)

func _colour(kind: StringName) -> Color:
	var cols: Dictionary = cfg["numbers"]["colours"]
	var c: Array = cols.get(kind, cols["hit"])
	return Color(c[0], c[1], c[2])

func _label(text: String, font_size: int, colour: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.modulate = colour
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true                         # ponytail: juice draws over the world, never depth-sorted
	return l

func _sphere(radius: float, colour: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new(); s.radius = radius; s.height = radius * 2.0
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	return m

func _fade(m: MeshInstance3D, secs: float) -> void:
	var tw := m.create_tween().set_ignore_time_scale(true)
	tw.tween_property(m.material_override, "albedo_color:a", 0.0, secs)
	tw.tween_callback(m.queue_free)

func _free_after(n: Node, secs: float) -> void:
	await get_tree().create_timer(secs, true, false, true).timeout
	if not is_inside_tree():                       # we were freed while the timer ran (scene exit / quit)
		return
	if is_instance_valid(n):
		n.queue_free()

## Juice lives beside us in world space (main.gd's root, or the test's tree root).
func _world() -> Node:
	return get_parent() if get_parent() != null else self

func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0
