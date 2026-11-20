extends SceneTree
const Domain := preload("res://game/domain/domain.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const Spawner := preload("res://game/world/spawner.gd")
const HUD := preload("res://game/meta/hud.gd")
const InputBuilder := preload("res://game/meta/input_map.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var o = Domain.Ontology.load_dir()
	var d: Dictionary = o.configs.generators.design
	InputBuilder.build(o.configs.keybinds.hybrid)
	if not _all_specs(o, d):
		return
	# Committed damaging effects keep their original weapon payload after unequip.
	var p = PLAYER.instantiate()
	root.add_child(p)
	p.setup(d.movement, d.camera, &"normal")
	p.setup_combat(d.combat, d.crit, {}, 100)
	p.setup_items(o, d)
	p.set_physics_process(false)
	var holder := Node3D.new()
	root.add_child(holder)
	var m = (
		Spawner
		. populate(
			holder,
			[
				{
					"species": &"wolf",
					"level": 1,
					"hostility": &"H",
					"max_hp": 1e6,
					"damage": 0,
					"positions": [Vector3(0, 0, -1)],
					"seed": 1
				}
			],
			d,
			o.creatures,
			p
		)[0]
	)
	m.set_physics_process(false)
	await physics_frame
	if not (_committed_actions(o, d, p, m) and _strike_result_boundaries(d)):
		return
	_finish()


func _spec_case(o, d: Dictionary, spec_id: StringName) -> bool:
	var class_id: StringName = o.specs[spec_id].slot_class
	var p = PLAYER.instantiate()
	root.add_child(p)
	p.setup(d.movement, d.camera, &"normal")
	p.setup_combat(d.combat, d.crit, {}, 100)
	p.setup_items(o, d, class_id, spec_id)
	p.set_physics_process(false)
	var original = p.inventory.equipment[&"main-hand"]
	var armed: Dictionary = p.weapon.duplicate()
	p.inventory.unequip(&"main-hand")
	check(
		p.weapon.is_empty() and p.moveset.is_empty(),
		"removed weapon clears derived attack state " + str(class_id)
	)
	return (
		_unarmed_requests(p, class_id)
		and _independent_skills(p)
		and _restore_weapon(p, original, armed, class_id)
	)


func _unarmed_requests(p, class_id: StringName) -> bool:
	p.mp = 80
	p.stamina = 100
	p.combo = 4
	p._combo_t = 2
	p._swing_t = 0
	p._swing()
	p._special(50)
	p._special_tick(0.1)
	p._apply_touch_request({"action": "basic-attack", "phase": "start"}, Vector3.ZERO)
	p._apply_touch_request({"action": "special-attack", "phase": "start"}, Vector3.ZERO)
	var no_spend = (
		p.mp == 80
		and p.stamina == 100
		and p.combo == 4
		and p._combo_t == 2
		and p._swing_t == 0
		and p._charge < 0
	)
	check(no_spend, "unarmed basic/special desktop/touch no spend " + str(class_id))
	return true


func _independent_skills(p) -> bool:
	for a in p.skill_tree.nodes:
		var r: Dictionary = p.abilities.runtime(a)
		if r.is_empty():
			continue
		if not _skill_case(p, a, r):
			return false
	return true


func _skill_case(p, a, r: Dictionary) -> bool:
	p.abilities.reset()
	p.abilities.cooldowns.clear()
	p.mp = 100
	p.stamina = 100
	p.combo = 4
	var damaging_value = _weapon_skill(r)
	if damaging_value == null:
		return false
	var damaging: bool = damaging_value
	var used: bool = p.abilities.use(a)
	check(used != damaging, "class request eligibility " + str(Domain.id_of(a)))
	return _skill_spend(p, a, damaging) and _independent_benefit(p, a, r)


func _restore_weapon(p, original, armed: Dictionary, class_id: StringName) -> bool:
	p.abilities.reset()
	p.abilities.cooldowns.clear()
	check(
		p.inventory.equip(original) and p.weapon == armed,
		"reequip restores attacks " + str(class_id)
	)
	p.queue_free()
	return true


func _committed_actions(o, d: Dictionary, p, m) -> bool:
	p.stamina = 100
	check(p.abilities.use(o.abilities[&"cyclone"]), "armed channel committed")
	p.inventory.unequip(&"main-hand")
	var hp0: float = m.hp
	p.abilities.tick(1.0)  # next front pass, after the committed weapon was unequipped
	check(m.hp < hp0 and p.combo > 0, "committed channel damages and lands without weapon")
	p.abilities.reset()
	p.stamina = 100
	var weapon = p.inventory.entries.filter(func(it): return it.type == &"weapon")[0]
	return (
		_committed_dash(o, p, m, weapon)
		and _committed_flight(d, p, weapon)
		and _unarmed_shout(o, d, p, m)
	)


func _committed_dash(o, p, m, weapon) -> bool:
	p.inventory.equip(weapon)
	check(p.abilities.use(o.abilities[&"smash"]), "armed dash committed")
	p.inventory.unequip(&"main-hand")
	var hp0: float = m.hp
	p.abilities.after_move(1)
	check(m.hp < hp0, "committed dash strike survives unequip")
	return true


func _committed_flight(d: Dictionary, p, weapon) -> bool:
	# Already-fired projectile may still land and award combo with its committed cap.
	p.inventory.equip(weapon)
	var shots: Array = p._fire(d.movesets.bow.m1, 40, true, [], Vector3(0, 1, -1))
	for shot in shots:
		shot.set_physics_process(false)
	p.inventory.unequip(&"main-hand")
	p.combo = 4
	shots[0]._hit(1)
	check(p.combo == 5, "in-flight hit has captured combo cap")
	for shot in shots:
		shot.queue_free()
	return true


func _unarmed_shout(o, d: Dictionary, p, m) -> bool:
	p.setup_items(o, d, &"warrior", &"guardian")
	p.inventory.unequip(&"main-hand")
	p.combo = 4
	p.hp = 10
	check(p.abilities.use(o.abilities[&"heroic-shout"]), "unarmed taunt request available")
	p.targeting.flush_taunts()
	p.abilities.tick(0.5)
	check(
		p.targeting.record(m).taunt_left == 3 and p.hp > 10 and p.combo == 4,
		"unarmed shout still taunts/heals without combo mutation"
	)
	var hud = HUD.new()
	root.add_child(hud)
	hud.bind(p, null)
	hud._process(0)
	check(p.weapon.is_empty(), "HUD accepts absent weapon")
	return true


func _finish() -> void:
	print("unarmed ok" if failed == 0 else "unarmed FAILED %d" % failed)
	quit(0 if failed == 0 else 1)


func _weapon_skill(r: Dictionary):
	if r.runtime in ["buff", "heal"]:
		return false
	return (
		r.runtime == "projectile"
		or float(r.get("damage-mult", 0)) > 0
		or r.has("throw")
		or r.get("strike", {}).has("damage-mult")
	)


func _skill_spend(p, a, damaging: bool) -> bool:
	if damaging:
		check(
			p.mp == 100 and p.stamina == 100 and p.combo == 4 and p.abilities.cooldowns.is_empty(),
			"weapon skill no spend " + str(Domain.id_of(a))
		)
	return true


func _independent_benefit(p, a, r: Dictionary) -> bool:
	if r.runtime == "buff":
		check(
			p.abilities.buffs.has(Domain.id_of(a)),
			"independent buff applied unarmed " + str(Domain.id_of(a))
		)
	if r.runtime == "heal":
		p.hp = 10
		p.abilities.tick(float(r["cast-s"]))
		check(p.hp > 10, "independent heal resolves unarmed")
	return true


# Scripted contacts exercise the real Entity contract and synchronous callback seam.
class StrikeBody:
	extends "res://game/entities/entity.gd"
	var trace: Array
	var head_calls := 0
	var status_count := 0
	var after_damage: Callable
	var blocked := false

	func take_damage(amount: float, from: Node, status: StringName = &"") -> bool:
		trace.append(str(name) + ":damage")
		super.take_damage(amount, from, status)
		if after_damage.is_valid():
			after_damage.call()
		return blocked

	func head() -> Vector3:
		head_calls += 1
		trace.append(str(name) + ":head")
		return global_position + Vector3(head_calls, 1, 0)

	func apply_status(_id: StringName, _cfg: Dictionary, _hit: float, _from: Node) -> void:
		status_count += 1
		trace.append(str(name) + ":status")
		position.x += 100  # The winning head position must already have been captured.


class StrikeProp:
	extends Node3D
	var trace: Array
	var hp := 30.0

	func take_direct_damage(amount: float, _from: Node) -> void:
		trace.append("prop")
		hp -= amount


class StrikeFeel:
	extends Node
	var trace: Array
	var plays := []

	func number(_at: Vector3, _amount: float, _kind: StringName) -> void:
		trace.append("number")

	func play(tier: StringName, at := Vector3.ZERO) -> void:
		trace.append("play")
		plays.append([tier, at])


func _strike_fixture(d: Dictionary, trace: Array):
	var p = PLAYER.instantiate()
	root.add_child(p)
	p.setup(d.movement, d.camera, &"normal")
	p.setup_combat(d.combat, d.crit, {}, 260.0)
	p.set_physics_process(false)
	p.design = d
	p._rng.seed = 9137
	p.stealth = 0.4
	p.combo = 4
	p._m1_hits = 7
	p.mp = 80
	var feel := StrikeFeel.new()
	feel.trace = trace
	root.add_child(feel)
	p.feel = feel
	return p


func _strike_body(trace: Array, tag: String, at: Vector3, health: float):
	var body := StrikeBody.new()
	body.name = tag
	body.trace = trace
	body.hp = health
	root.add_child(body)
	body.position = at
	return body


func _strike_result_boundaries(d: Dictionary) -> bool:
	return (
		_strike_feedback(d)
		and _strike_early_cancel(d)
		and _strike_prebreak(d)
		and _strike_block_zero(d)
	)


func _strike_feedback(d: Dictionary) -> bool:
	var trace := []
	var p = _strike_fixture(d, trace)
	var first = _strike_body(trace, "first", Vector3.ZERO, 30)
	var second = _strike_body(trace, "second", Vector3(10, 0, 0), 5)
	var dead_body = _strike_body(trace, "dead", Vector3.ZERO, 30)
	dead_body.dead = true
	var prop := StrikeProp.new()
	prop.trace = trace
	root.add_child(prop)
	var hits: int = p._strike(
		Vector3.ZERO, 1, 10, false, [&"stun"], &"physical", 0, [prop, dead_body, first, second]
	)
	check(
		(
			[hits, prop.hp, first.hp, second.hp, first.status_count, second.status_count]
			== [2, 20.0, 20.0, 0.0, 1, 1]
		),
		"T8 contact kinds and literal damage/counts"
	)
	check(
		(
			trace
			== [
				"prop",
				"first:damage",
				"first:head",
				"number",
				"first:head",
				"first:status",
				"second:damage",
				"second:head",
				"number",
				"second:head",
				"second:status",
				"play"
			]
		),
		"T8 head/feedback/status order"
	)
	check(
		p.feel.plays == [[&"kill", Vector3(12, 1, 0)]],
		"T8 strongest feedback captures head before status mutation"
	)
	check(
		[p.combo, p._m1_hits, p.mp, p.stealth] == [4, 7, 80.0, 0.0],
		"T8 strike never settles combo or basic rewards"
	)
	for body in [first, second, dead_body, prop, p.feel, p]:
		body.free()
	return true


func _strike_early_cancel(d: Dictionary) -> bool:
	var trace := []
	var p = _strike_fixture(d, trace)
	var first = _strike_body(trace, "first", Vector3.ZERO, 30)
	var second = _strike_body(trace, "second", Vector3.ZERO, 30)
	var active := {"yes": true}
	second.after_damage = func(): active.yes = false
	var continuing := func(): return active.yes
	var hits: int = p._strike(
		Vector3.ZERO, 1, 10, false, [&"stun"], &"physical", 0, [first, second], continuing
	)
	check(
		[hits, first.status_count, second.status_count, p.stealth] == [2, 1, 0, 0.4],
		"T8 post-damage cancellation is terminal, not a loop break"
	)
	check(p.feel.plays == [], "T8 cancellation skips the earlier contact's epilogue bundle")
	check(
		(
			trace
			== [
				"first:damage",
				"first:head",
				"number",
				"first:head",
				"first:status",
				"second:damage"
			]
		),
		"T8 cancellation immediately after damage skips second feedback/status"
	)
	for body in [first, second, p.feel, p]:
		body.free()
	return true


func _strike_prebreak(d: Dictionary) -> bool:
	var trace := []
	var p = _strike_fixture(d, trace)
	var first = _strike_body(trace, "first", Vector3.ZERO, 30)
	var second = _strike_body(trace, "second", Vector3.ZERO, 30)
	var continuing := func(): return first.status_count == 0
	var hits: int = p._strike(
		Vector3.ZERO, 1, 10, false, [&"stun"], &"physical", 0, [first, second], continuing
	)
	check(
		[hits, second.hp, p.stealth] == [1, 30.0, 0.0],
		"T8 pre-contact break keeps prior hit and runs epilogue"
	)
	check(
		p.feel.plays == [[&"hit", Vector3(2, 1, 0)]], "T8 pre-contact break plays captured feedback"
	)
	for body in [first, second, p.feel, p]:
		body.free()
	return true


func _strike_block_zero(d: Dictionary) -> bool:
	for damage in [10, 0]:
		var trace := []
		var p = _strike_fixture(d, trace)
		var body = _strike_body(trace, "body", Vector3.ZERO, 30)
		body.blocked = true
		var hits: int = p._strike(Vector3.ZERO, 1, damage, false, [&"stun"], &"physical", 0, [body])
		check(
			[hits, body.hp, body.status_count] == ([1, 20.0, 0] if damage == 10 else [1, 30.0, 1]),
			"T8 blocked versus zero-damage status boundary"
		)
		for node in [body, p.feel, p]:
			node.free()
	return true


func _all_specs(o, d: Dictionary) -> bool:
	for spec_id in o.specs:
		if not _spec_case(o, d, spec_id):
			return false
	return true
