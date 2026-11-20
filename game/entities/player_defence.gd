## Defence updates; Player retains all stance, resource and timer state.
extends RefCounted

const Domain := preload("res://game/domain/domain.gd")


static func passives(p) -> Array:
	if p.o == null or p.spec == &"":
		return []
	var s = p.o.specs[p.spec]
	return s.slot_passives.slot_a + s.slot_passives.slot_s


static func _cyclone(p) -> bool:
	return (
		p.abilities != null
		and not p.abilities.channel.is_empty()
		and Domain.id_of(p.abilities.channel["a"]) == &"cyclone"
	)


static func can_block(p) -> bool:
	if p.defence.is_empty():
		return false
	var off = p.inventory.equipment.get(&"off-hand") if p.inventory != null else null
	var armed: bool = not p.weapon.is_empty() or off != null
	return _block_equipment(p, armed, off)


static func block_max(p) -> float:
	if p.defence.is_empty():
		return 0.0
	return (
		float(p.defence["block"]["max"])
		* (float(p.defence["block"]["guardian-mult"]) if p.passives().has(&"barricade") else 1.0)
	)


static func blocks_from(p, from: Node) -> bool:
	if not p.blocking or p.block_power <= 0.0 or not from is Node3D or from == p:
		return false
	return _front_block(p, from)


static func dodge(p, dir: Vector3) -> bool:
	var dg: Dictionary = p.defence["dodge"]
	if not _dodge_ready(p, dir, dg):
		return false
	p.stamina -= float(dg["stamina"])
	p._stamina_idle = 0.0
	p._dodge = {"dir": dir, "left": float(dg["duration-s"])}
	p._iframes = float(dg["iframe-s"])
	p._dodge_cd = float(dg["cooldown-s"]) + float(dg["duration-s"])
	if not _dodge_rewards(p, dg):
		return false
	if p.feel != null:
		p.feel.play(&"dodge")
	return true


static func _defence_tick(p, dt: float, dir: Vector3, still: bool) -> void:
	if not _dodge_tick(p, dt, dir):
		return
	if not _block_tick(p, dt):
		return
	_stealth_tick(p, dt, still)


static func _dodge_tick(p, dt: float, dir: Vector3) -> bool:
	if not _dodge_timers(p, dt):
		return false
	return _desktop_dodge(p, dir)


static func _block_tick(p, dt: float) -> bool:
	var bl: Dictionary = p.defence["block"]
	var cyc: bool = p._cyclone()
	var requested = _blocking(p, cyc)
	if requested == null:
		return false
	p.blocking = requested
	if not p.blocking or cyc:
		p.block_power = minf(
			p.block_max(),
			(
				p.block_power
				+ float(bl["regen-per-s"]) * (float(bl["cyclone-regen-mult"]) if cyc else 1.0) * dt
			)
		)
	return true


static func _stealth_tick(p, dt: float, still: bool) -> void:
	var sl: Dictionary = p.defence["stealth"]
	if p.abilities != null and p.abilities.flag("stealth-full"):
		p.stealth = 1.0
	else:
		var generated = _stealth_generation(p, sl, still)
		if generated == null:
			return
		var gen: float = generated
		p.stealth = clampf(
			p.stealth + (gen if gen > 0.0 else -float(sl["decay-per-s"])) * dt, 0.0, 1.0
		)


static func stun_immune(p) -> bool:
	return p.abilities != null and p.abilities.flag("stun-immune")


static func _block_equipment(p, armed: bool, off) -> bool:
	return (
		p._cyclone()
		or (armed and p.passives().has(&"barricade"))
		or (off != null and off.subtype == &"shield")
	)


static func _front_block(p, from: Node) -> bool:
	if p._cyclone():
		return true
	var d: Vector3 = (from as Node3D).global_position - p.global_position
	d.y = 0.0
	return (
		d.normalized().dot(Basis(Vector3.UP, p.rig.rotation.y) * Vector3.FORWARD)
		>= float(p.defence["block"]["front-dot"])
	)


static func _dodge_rewards(p, dg: Dictionary) -> bool:
	for id in dg["on-dodge"]:
		if p.passives().has(StringName(id)):
			p.mp = minf(
				float(p.design["resources"]["mp"]["max"]),
				p.mp + float(dg["on-dodge"][id].get("mp", 0))
			)
			p.stealth = minf(1.0, p.stealth + float(dg["on-dodge"][id].get("stealth", 0)))
	return true


static func _dodge_motion_ready(p, dir: Vector3) -> bool:
	return not (dir == Vector3.ZERO or not p._dodge.is_empty() or p._dodge_cd > 0.0 or p.blocking)


static func _dodge_ready(p, dir: Vector3, dg: Dictionary) -> bool:
	if not _dodge_motion_ready(p, dir):
		return false
	if p.stunned() or p.stamina < float(dg["stamina"]):
		return false
	return not (p.abilities != null and p.abilities.busy())


static func _blocking(p, cyc: bool):
	if not (p.can_block() and p.block_power > 0.0):
		return false
	if cyc:
		return true
	return _held_block(p)


static func _held_block(p):
	if p.ui_open or p.map_open:
		return false
	var held = _block_input(p)
	if held == null:
		return null
	return held and not p.stunned()


static func _block_input(p):
	return not not (
		Input.is_action_pressed("special-attack")
		if p.touch_input == null
		else p._touch_frame.get("held", {}).get("block", false)
	)


static func _dodge_timers(p, dt: float) -> bool:
	p._iframes -= dt
	p._dodge_cd -= dt
	if not p._dodge.is_empty():
		p._dodge["left"] -= dt
		if p._dodge["left"] <= 0.0:
			p._dodge = {}
	return true


static func _desktop_dodge(p, dir: Vector3) -> bool:
	if _dodge_input_context(p) and Input.is_action_just_pressed("dodge"):
		p.dodge(dir)
	return true


static func _stealth_generation(p, sl: Dictionary, still: bool):
	return (
		(p.abilities.add("stealth-per-s") if p.abilities != null else 0.0)
		* (float(sl["still-mult"]) if still else 1.0)
	)


static func _dodge_input_context(p) -> bool:
	return p.touch_input == null and not p.ui_open and not p.map_open
