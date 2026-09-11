## §3.3 projectile (D24): one shot of a `design.movesets` projectile moveset, an ability `projectile` runtime or a dash
## `throw`. Flies under its own gravity, sweeps a ray along each tick's path (terrain and bodies), and damages through
## the shooter's `_strike` so crit / armor / status / stealth rules stay in one place. A volley shares one `attack`
## dict: the first landed hit counts for combo / MP once, and the combo resets only when every shot landed nothing
## (c-combo-reset). D25: it drops a fading trail piece every design.feel.trail.trail-every-s and plays the `impact`
## bundle (sound, trauma, flash sphere at the splash radius) when it lands or hits the ground.
## D26: `fire()` spawns a volley for any shooter — the player's `_fire` and a creature's `_shoot` share it, and
## `shot.color` tints the sphere (creature roles are tinted by `design.creature-roles.<role>.color`).
## ponytail: still a small coloured sphere, no model and no particles (todo_implement.md).
extends Node3D

var shooter                             # the player or a ranged / mage creature (has _strike, bodies_within, _landed, feel, dead)
var shot: Dictionary = {}               # the moveset / runtime dict (speed, gravity, radius, life-s, splash, pierce, tick-s, return)
var vel := Vector3.ZERO
var dmg := 0.0
var combo_bonus := false
var applies: Array = []
var attack: Dictionary = {}             # {"hits", "live"} shared by the volley
var _t := 0.0
var _tick := 0.0
var _trail := 0.0
var _returning := false

## `count` shots fanned by `spread` radians around `dir`, sharing one attack record: the whole volley
## counts once for combo / MP. Any shooter with `_strike` / `bodies_within` / `_landed` / `feel` can fire
## (the player from `_fire`, a ranged / mage creature from `_shoot`, D26).
static func fire(shooter, from: Vector3, dir: Vector3, s: Dictionary, dmg: float, combo_bonus: bool, applies: Array) -> Array:
	var count := int(s.get("count", 1))
	var attack := {"hits": 0, "live": count}
	var out: Array = []
	for i in count:
		var pr = new()
		pr.shooter = shooter; pr.shot = s; pr.dmg = dmg; pr.combo_bonus = combo_bonus; pr.applies = applies; pr.attack = attack
		pr.vel = dir.rotated(Vector3.UP, float(s.get("spread", 0.0)) * (i - (count - 1) / 2.0)) * float(s["speed"])
		shooter.get_parent().add_child(pr)
		pr.global_position = from
		out.append(pr)
	return out

func _ready() -> void:
	var m := MeshInstance3D.new(); var s := SphereMesh.new()
	s.radius = 0.15; s.height = 0.3; m.mesh = s
	m.material_override = StandardMaterial3D.new(); m.material_override.albedo_color = Color(str(shot.get("color", "#ffd94d")))
	add_child(m)

func _physics_process(dt: float) -> void:
	if shooter == null or not is_instance_valid(shooter) or shooter.dead:
		_end(); return
	var life := float(shot["life-s"])
	_t += dt; _tick -= dt; _trail -= dt
	var f = shooter.feel
	if f != null and _trail <= 0.0:
		_trail = f.trail_every
		f.trail(global_position)
	if shot.get("return", false) and not _returning and _t >= life * 0.5:
		_returning = true
	if _returning:
		var to: Vector3 = shooter.global_position + Vector3.UP - global_position
		if to.length() < 1.0:
			_end(); return
		vel = to.normalized() * float(shot["speed"])
	else:
		vel.y -= float(shot.get("gravity", 0.0)) * dt
	var prev := global_position
	var next := prev + vel * dt
	var q := PhysicsRayQueryParameters3D.create(prev, next, 0xFFFFFFFF, [shooter.get_rid()])
	var ray: Dictionary = shooter.get_world_3d().direct_space_state.intersect_ray(q)
	var solid: bool = not ray.is_empty() and not (ray["collider"] as Object).has_method("take_damage")
	global_position = ray["position"] if not ray.is_empty() else next
	var radius := float(shot["radius"])
	if shot.get("pierce", false):                          # boomerang: re-hit every tick-s, only terrain stops it
		if _tick <= 0.0:
			_tick = float(shot["tick-s"])
			_hit(shooter._strike(global_position, radius, dmg, combo_bonus, applies))
		if solid or _t >= life:
			if solid:
				_impact(0.0)
			_end()
		return
	var splash := float(shot.get("splash", 0.0))
	if splash > 0.0:
		if not ray.is_empty() or not shooter.bodies_within(global_position, radius).is_empty():
			_hit(shooter._strike(global_position, splash, dmg, combo_bonus, applies))
			_impact(splash); _end()
		elif _t >= life:
			_end()
		return
	var hits: int = shooter._strike(global_position, radius, dmg, combo_bonus, applies)
	_hit(hits)
	if hits > 0 or solid:
		_impact(0.0)
	if hits > 0 or solid or _t >= life:
		_end()

## D25 `impact` bundle where the shot landed; radius 0 = design.feel.impact.impact-radius.
func _impact(radius: float) -> void:
	if shooter != null and is_instance_valid(shooter) and shooter.feel != null:
		shooter.feel.play(&"impact", global_position, {"radius": radius})

func _hit(hits: int) -> void:
	if hits <= 0:
		return
	if attack["hits"] == 0:
		shooter._landed(combo_bonus)
	attack["hits"] += hits

func _end() -> void:
	if not attack.is_empty():
		attack["live"] -= 1
		if attack["live"] <= 0 and attack["hits"] == 0 and shooter != null and is_instance_valid(shooter) and shooter.get("combo") != null:
			shooter.combo = 0                              # c-combo-reset: the whole attack whiffed
		attack = {}
	queue_free()
