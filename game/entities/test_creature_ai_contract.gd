extends SceneTree
const Model := preload("res://ontology/model.gd")
const Spawner := preload("res://game/world/spawner.gd")
const Authority := preload("res://game/combat/targeting.gd")
const PLAYER := preload("res://game/entities/player.tscn")
var failed := 0
func check(ok: bool, what: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", what)
func _init() -> void: call_deferred("run")
func run() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var d: Dictionary = o.configs["generators"]["design"]
	var players: Array = []
	for id in ["a", "b", "c"]:
		var p = PLAYER.instantiate(); root.add_child(p)
		p.logical_id = id
		p.setup(d.movement, d.camera, &"normal")
		p.setup_combat(d.combat, d.crit, {}, 100)
		p.setup_items(o, d)
		p.set_physics_process(false); players.append(p)
	var a = players[0]; var b = players[1]; var c = players[2]
	var authority = Authority.new(); root.add_child(authority)
	authority.configure(d, func(): return players)
	authority.set_physics_process(false)
	var holder := Node3D.new(); root.add_child(holder)
	var groups := [{"species": &"wolf", "level": 1, "hostility": &"H", "max_hp": 200.0, "damage": 12.0, "positions": [Vector3.ZERO, Vector3(1,0,0)], "seed": 1},
		{"species": &"wolf", "level": 1, "hostility": &"N", "max_hp": 200.0, "damage": 12.0, "positions": [Vector3(2,0,0)], "seed": 1}] # identical RNG seeds still identify distinct generated packs
	var made = Spawner.populate(holder, groups, d, o.creatures, a, null, authority, "test")
	for m in made: m.set_physics_process(false)
	var m = made[0]; var mate = made[1]; var neutral = made[2]
	check(m.pack_id != neutral.pack_id,"pack identity uses generation ordinal, not a possibly colliding random seed")
	# Current pack sightings can reach around cover, but never persist or provoke a separate neutral pack.
	a.position = Vector3(10,0,0); b.position = Vector3(100,0,100); c.position = b.position
	m.position = Vector3.ZERO; mate.position = Vector3(10,0,5)
	var wall := StaticBody3D.new(); var collision := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(0.5,5,4); collision.shape = box; wall.add_child(collision); wall.position = Vector3(5,2,0); root.add_child(wall)
	await physics_frame
	check(not m.detects(a) and mate.detects(a) and authority.select(m) == a,"pack shares current sighting around cover")
	check(authority.select(neutral) == null and authority.record(m).threat.is_empty(),"sighting neither copies threat nor provokes another pack")
	mate.position = Vector3(100,0,0)
	check(authority.select(m) == null,"pack sighting disappears when final observer loses it")
	wall.free(); await physics_frame
	a.position = Vector3(-2,0,0); b.position = Vector3(2,0,0)
	authority.record(m).current = ""
	var zero_target = authority.select(m)
	check(zero_target in [a,b],"equal nearest zero-threat fallback")
	var other = b if zero_target == a else a
	other.position = Vector3(0,0,0.5)
	check(authority.select(m) == zero_target and authority.record(m).order.is_empty(),"zero-threat target retained without reroll or engagement order")
	a.position = Vector3.ZERO; b.position = Vector3.ZERO; c.position = Vector3.ZERO; mate.position = Vector3(1,0,0)
	authority.arrive(m)
	authority.taunt([a]); a.position.x = 40; authority.flush_taunts()
	check(authority.record(m).taunt == "a" and authority.select(m) == a,"taunt reach sampled at casting, not deferred resolution")
	authority.taunt([b]); authority.flush_taunts()
	check(authority.record(m).taunt == "b","latest successful taunt replaces previous one")
	a.position.x = 0; authority._rng.seed = 42
	var split := false
	for i in 20:
		authority.taunt([a,b]); authority.flush_taunts()
		if authority.record(m).taunt != authority.record(mate).taunt: split = true
	check(split,"simultaneous taunts choose independently per mob, not per pack")
	authority.advance(3); authority.arrive(m); authority.arrive(mate)
	m.take_damage(1.0, a)
	check(is_equal_approx(authority.record(m).threat.a, 0.5), "actual percentage fractional gain")
	check(authority.record(mate).threat.is_empty(), "pack never copies threat")
	authority.advance(0.25)
	check(is_equal_approx(authority.record(m).threat.a, 0.25), "continuous fighting decay")
	m.take_damage(0.5, b)
	check(authority.select(m) == a, "current highest tie retained")
	authority.record(m).current = ""
	check(authority.select(m) == a, "positive tie earliest engagement")
	authority.advance(1)
	check(authority.record(m).order.is_empty(), "zero erases order")
	m.take_damage(2, b); m.take_damage(2, a); authority.record(m).current = ""
	check(authority.select(m) == b, "fresh order after zero")
	a.stealth = 1.0; var before: Dictionary = authority.record(m).threat.duplicate()
	m.take_damage(5, a)
	check(authority.record(m).threat == before, "full stealth checked at landing")
	# DOT checks the source's current stealth independently for each landed tick.
	m.apply_status(&"burning",d["status-effects"].burning,10,a)
	var stealth_threat: Dictionary = authority.record(m).threat.duplicate()
	m.tick_statuses(0.5)
	check(authority.record(m).threat == stealth_threat,"full-stealth DOT tick adds no threat")
	a.stealth = 0
	m.tick_statuses(0.5)
	check(authority.record(m).threat.a > stealth_threat.a,"later non-full-stealth DOT tick earns its actual loss")
	m.statuses.clear()
	# Block positive loss, absorption zero, overkill clamp at the shared damage seam.
	var losses: Array = []
	a.damaged.connect(func(amount, _from): losses.append(amount))
	a.blocking = true; a.block_power = a.block_max(); m.position = Vector3(0,0,-1)
	var hp0: float = a.hp; a.take_damage(10, m)
	check(losses.size() == 1 and is_equal_approx(losses[-1], hp0-a.hp) and losses[-1] > 0 and losses[-1] < 10, "blocked positive actual HP loss")
	a.blocking = false; a.abilities.buffs[&"test"] = {"left": 10, "r": {}, "pool": 100.0}
	a.take_damage(10, m); check(losses[-1] == 0, "fully absorbed zero HP loss")
	a.abilities.buffs.clear(); a._iframes = 1; var count := losses.size(); a.take_damage(10,m)
	check(losses.size() == count, "dodged zero HP loss")
	a._iframes = 0
	neutral.take_damage(1, a)
	check(authority.record(neutral).provoked.has("a") and not authority.record(neutral).provoked.has("b"), "neutral aggressor specific")
	authority.taunt([b]); authority.flush_taunts()
	check(authority.select(neutral) == b and not authority.record(neutral).provoked.has("b"), "taunt forces without provocation")
	b.position.x = 40
	check(authority.select(neutral) == b, "taunt survives radius departure")
	authority.advance(3); check(authority.select(neutral) != b, "expiry excludes uninvolved neutral caster")
	b.position.x = 0
	authority.taunt([a,b]); authority.flush_taunts()
	check(authority.record(m).taunt in ["a","b"], "simultaneous eligible winner")
	m.position = Vector3(31,0,0); m.state = m.State.CHASE; m._tick(0)
	check(m.state == m.State.RETURN or authority.record(m).returning, "leash overrides taunt")
	m.state = m.State.RETURN; m.hp = 100
	m.take_damage(10, b, &"poison"); check(is_equal_approx(m.hp,99), "return DOT receives 90 percent reduction")
	m._tick(0); check(is_equal_approx(Vector2(m.velocity.x,m.velocity.z).length(),13), "return speed x2")
	authority.taunt([a]); authority.flush_taunts(); check(authority.record(m).taunt == "", "return rejects taunt")
	m.apply_status(&"stun",d["status-effects"].stun,0,b)
	check(m.stunned(),"protected return still accepts crowd control")
	m.position = m.home; m.state = m._tick(0)
	check(m.hp == m.max_hp and authority.record(m).threat.is_empty(), "home full heal and own wipe")
	m.take_damage(1,b); players.erase(b); authority.advance(0.1)
	check(authority.record(m).threat.has("b") and authority.select(m) != b, "absence retains threat but not targeting")
	var absent_before: float = authority.record(m).threat.b
	m.take_damage(1,b,&"poison")
	check(authority.record(m).threat.b > absent_before and authority.select(m) != b,"known absent DOT source still earns actual-damage threat, without becoming targetable")
	players.append(b); b.take_damage(1e9,m)
	check(not authority.record(m).threat.has("b"), "player death immediate world-wide wipe")
	# Finisher receives XP independently of current target.
	var final_losses: Array = []
	m.damaged.connect(func(loss,_source): final_losses.append(loss))
	m.hp = 1; var xp0: int = c.xp; m.target = a; m.take_damage(999,c)
	check(final_losses[-1] == 1,"overkill reports only remaining HP removed")
	check(c.xp > xp0 and m.last_attacker == c, "finisher not selected target receives XP")
	check(losses.all(func(x): return x >= 0), "nonnegative actual damage")
	# The fallback authority may outlive a departed player; a captured freed Node is not a safe guard.
	var gone = PLAYER.instantiate(); root.add_child(gone); gone.set_physics_process(false)
	var fallback_holder := Node3D.new(); root.add_child(fallback_holder)
	var fallback_mob = Spawner.populate(fallback_holder,[groups[0]],d,o.creatures,gone)[0]
	var fallback: Node = fallback_mob.targeting
	for node in fallback.live.values(): node.set_physics_process(false)
	gone.free()
	check(fallback.party().is_empty(),"freed fallback player yields an empty provider")
	fallback.advance(0.1)
	check(fallback.select(fallback_mob) == null,"freed fallback player is never eligible")
	await physics_frame
	await physics_frame
	fallback_holder.free()
	print("creature AI contract ok" if failed == 0 else "creature AI contract FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
