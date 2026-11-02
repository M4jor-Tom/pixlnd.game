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

var shooter  # the player or a ranged / mage creature (has _strike, bodies_within, _landed, feel, dead)
var shot: Dictionary = {}  # the moveset / runtime dict (speed, gravity, radius, life-s, splash, pierce, tick-s, return)
var vel := Vector3.ZERO
var dmg := 0.0
var attack_type: StringName = &"physical"
var combo_bonus := false
var applies: Array = []
var attack: Dictionary = {}  # {"hits", "live"} shared by the volley
var _t := 0.0
var _tick := 0.0
var _trail := 0.0
var _returning := false


## `count` shots fanned by `spread` radians around `dir`, sharing one attack record: the whole volley
## counts once for combo / MP. Any shooter with `_strike` / `bodies_within` / `_landed` / `feel` can fire
## (the player from `_fire`, a ranged / mage creature from `_shoot`, D26).
static func fire(
	shooter,
	from: Vector3,
	dir: Vector3,
	s: Dictionary,
	dmg: float,
	combo_bonus: bool,
	applies: Array,
	attack_type: StringName
) -> Array:
	var count := int(s.get("count", 1))
	var attack := {"hits": 0, "live": count}
	if shooter.get("weapon") is Dictionary:
		attack["weapon"] = shooter.weapon.duplicate()
	var out: Array = []
	for i in count:
		var pr = new()
		pr.shooter = shooter
		pr.shot = s
		pr.dmg = dmg
		pr.attack_type = attack_type
		pr.combo_bonus = combo_bonus
		pr.applies = applies
		pr.attack = attack
		pr.vel = (
			dir.rotated(Vector3.UP, float(s.get("spread", 0.0)) * (i - (count - 1) / 2.0))
			* float(s["speed"])
		)
		pr.position = (
			shooter.get_parent().to_local(from) if shooter.get_parent() is Node3D else from
		)
		shooter.get_parent().add_child(pr)
		if shooter.frame != null:
			shooter.frame.track(pr)
		out.append(pr)
	return out


func _ready() -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.15
	s.height = 0.3
	m.mesh = s
	m.material_override = StandardMaterial3D.new()
	m.material_override.albedo_color = Color(str(shot.get("color", "#ffd94d")))
	add_child(m)


func _physics_process(dt: float) -> void:
	var alive = _shooter_alive()
	if alive == null:
		return
	if not alive:
		_end()
		return
	_advance_flight(dt)


## D25 `impact` bundle where the shot landed; radius 0 = design.feel.impact.impact-radius.
func _impact(radius: float) -> void:
	if shooter != null and is_instance_valid(shooter) and shooter.feel != null:
		shooter.feel.play(&"impact", global_position, {"radius": radius})


func _hit(hits: int) -> void:
	if hits <= 0:
		return
	if attack["hits"] == 0:
		if attack.has("weapon"):
			shooter._landed(combo_bonus, attack["weapon"])
		else:
			shooter._landed(combo_bonus)
	attack["hits"] += hits


func _end() -> void:
	if not attack.is_empty():
		if not _retire_attack():
			return
		attack = {}
	queue_free()


func _motion(dt: float, life: float) -> bool:
	if shot.get("return", false) and not _returning and _t >= life * 0.5:
		_returning = true
	if _returning:
		var to: Vector3 = shooter.global_position + Vector3.UP - global_position
		if to.length() < 1.0:
			_end()
			return false
		vel = to.normalized() * float(shot["speed"])
	else:
		vel.y -= float(shot.get("gravity", 0.0)) * dt
	return true


func _pierce_contact(radius: float, solid: bool, life: float) -> void:
	if _tick <= 0.0:
		_tick = float(shot["tick-s"])
		_hit(shooter._strike(global_position, radius, dmg, combo_bonus, applies, attack_type))
	if solid or _t >= life:
		if solid:
			_impact(0.0)
		_end()


func _splash_contact(radius: float, splash: float, ray: Dictionary, life: float) -> void:
	if not ray.is_empty() or not shooter.bodies_within(global_position, radius).is_empty():
		_hit(shooter._strike(global_position, splash, dmg, combo_bonus, applies, attack_type))
		_impact(splash)
		_end()
	elif _t >= life:
		_end()


func _ordinary_contact(radius: float, solid: bool, life: float) -> void:
	# Snapshot contact before a lethal strike removes it; props consume shots without combat rewards.
	var contact: bool = not shooter.bodies_within(global_position, radius).is_empty()
	var hits: int = shooter._strike(
		global_position, radius, dmg, combo_bonus, applies, attack_type, 1
	)
	_hit(hits)
	if contact or solid:
		_impact(0.0)
	if contact or solid or _t >= life:
		_end()


func _retire_attack() -> bool:
	attack["live"] -= 1
	if (
		attack["live"] <= 0
		and attack["hits"] == 0
		and shooter != null
		and is_instance_valid(shooter)
		and shooter.get("combo") != null
	):
		shooter.combo = 0  # c-combo-reset: the whole attack whiffed
	return true


func _contacts(dt: float, life: float) -> void:
	var prev := global_position
	var next := prev + vel * dt
	var q := PhysicsRayQueryParameters3D.create(prev, next, 0xFFFFFFFF, [shooter.get_rid()])
	var ray: Dictionary = shooter.get_world_3d().direct_space_state.intersect_ray(q)
	var solid: bool = (
		not ray.is_empty() and not (ray["collider"] as Object).has_method("take_damage")
	)
	global_position = ray["position"] if not ray.is_empty() else next
	var radius := float(shot["radius"])
	_contact_family(radius, solid, life, ray)


func _timers(dt: float) -> bool:
	_t += dt
	_tick -= dt
	_trail -= dt
	var f = shooter.feel
	if f != null and _trail <= 0.0:
		_trail = f.trail_every
		f.trail(global_position)
	return true


func _contact_family(radius: float, solid: bool, life: float, ray: Dictionary) -> void:
	if shot.get("pierce", false):
		_pierce_contact(radius, solid, life)
		return
	var splash := float(shot.get("splash", 0.0))
	if splash > 0.0:
		_splash_contact(radius, splash, ray, life)
		return
	_ordinary_contact(radius, solid, life)


func _shooter_alive():
	if shooter == null or not is_instance_valid(shooter):
		return false
	return not shooter.dead


func _advance_flight(dt: float) -> void:
	var life := float(shot["life-s"])
	if not _timers(dt):
		return
	if not _motion(dt, life):
		return
	_contacts(dt, life)
