## Headless check of §3.2 creature combat-roles (D26): `godot --headless -s game/entities/test_creature_roles.gd`.
## c-creature-roles fires on six broken copies; `role` text parses to a combat-role; gen-spawns gives every group a
## role (any-class rolled, deterministic); a ranged skeleton keeps its distance, needs line of sight and shoots the
## player; a mage skeleton splashes and sets us burning (orange dot numbers); a spitter's poison lands through a
## dodge; a creature shot never damages a creature; a blocked shot carries no status; a landed shot rolls
## design.defence.enemy-hit.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Combat := preload("res://game/combat/combat.gd")
const Feel := preload("res://game/combat/feel.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
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

## Real seconds, so a hurt bundle's hit-stop cannot stall the wait (Engine.time_scale scales physics_frame).
func _real(s: float) -> void:
	await create_timer(s, true, false, true).timeout
	await process_frame

func _player(at: Vector3) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate()
	p.position = at
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(1, 1.0))
	p.setup_items(o, design, &"warrior")
	p.position = at; p.spawn_point = at
	p.get_node("CameraRig").rotation.x = 0.0
	p.feel = feel
	return p

## One creature of `species` with `role` forced, spawned through the real spawner (so it gets `role_cfg`).
func _spawn(species: StringName, role: StringName, at: Vector3, target: Node3D, hostility := &"H", dmg := 20.0) -> CharacterBody3D:
	var holder := Node3D.new(); root.add_child(holder)
	return Spawner.populate(holder, [{"species": species, "level": 1, "hostility": hostility, "max_hp": 1e6,
		"damage": dmg, "positions": [at], "role": role, "seed": 1}], design, o.creatures, target, null)[0]

## Shots in flight from this creature (projectile.gd adds them beside the shooter).
func _shots(c: Node) -> int:
	var n := 0
	for ch in c.get_parent().get_children():
		if ch != c and not ch.is_queued_for_deletion() and ch.get("shot") != null:
			n += 1
	return n

## Watch for `secs` real seconds; returns the most shots ever in flight at once (they free themselves on impact).
func _watch(c: Node, secs: float) -> int:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	var seen := 0
	while Time.get_ticks_msec() < end:
		await process_frame
		seen = maxi(seen, _shots(c))
	return seen

## Live damage numbers beside the feel node, optionally only those of one design.feel.numbers colour.
func _labels(colour := Color.TRANSPARENT) -> int:
	var n := 0
	for c in root.get_children():
		var rgb := Color(c.modulate.r, c.modulate.g, c.modulate.b) if c is Label3D else Color.BLACK   # alpha fades out
		if c is Label3D and not c.is_queued_for_deletion() and (colour.a == 0.0 or rgb.is_equal_approx(colour)):
			n += 1
	return n

func _init() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs["generators"]["design"]
	var cr: Dictionary = design["creature-roles"]

	# --- c-creature-roles: every key the engine reads is guarded
	cr["default"] = "archer"
	check(not o.validate(), "c-creature-roles rejects a default that is not a role"); o.errors.clear()
	cr["default"] = "melee"
	cr["any-class"]["ranged"] = -1.0
	check(not o.validate(), "c-creature-roles rejects a negative any-class weight"); o.errors.clear()
	cr["any-class"]["ranged"] = 0.3
	var speed = cr["ranged"]["shot"]["speed"]; cr["ranged"]["shot"]["speed"] = 0
	check(not o.validate(), "c-creature-roles rejects a shot with speed 0"); o.errors.clear()
	cr["ranged"]["shot"]["speed"] = speed
	cr["mage"]["applies"] = ["nope"]
	check(not o.validate(), "c-creature-roles rejects an applies id with no status-effect"); o.errors.clear()
	cr["mage"]["applies"] = ["burning"]
	cr["ranged"]["sfx"] = "nope"
	check(not o.validate(), "c-creature-roles rejects an sfx that is not an alpha sound"); o.errors.clear()
	cr["ranged"]["sfx"] = "swing"
	cr["species"]["nope"] = {"damage-mult": 2.0}
	check(not o.validate(), "c-creature-roles rejects a species override for an unknown creature"); o.errors.clear()
	cr["species"].erase("nope")
	check(o.validate(), "restored")

	# --- role parsing: the first keyword in the creatures.json `role` text wins
	check(o.creatures["djinn"].combat_role == &"mage", "'mage (bracelets)' → mage")
	check(o.creatures["hell-demon"].combat_role == &"any-class", "'any-class melee+ranged' → any-class")
	check(o.creatures["demon-marauder"].combat_role == &"melee", "'melee + fire magic' → melee")
	check(o.creatures["seeker"].combat_role == &"mage", "'fire mage' → mage")
	check(o.creatures["minotaur"].combat_role == &"melee", "'melee dual-wield' → melee")
	check(o.creatures["spitter"].combat_role == &"ranged", "'ranged' → ranged")
	check(o.creatures["old-man"].combat_role == &"", "'quest giver / vendor (concept)' → unset")
	check(o.creatures["wolf"].combat_role == &"", "no role key → unset")

	# --- gen-spawns: a role per group, any-class rolled, deterministic
	var rosters: Dictionary = o.configs["creature-families"]["landscape-rosters"]
	var skel: Dictionary = {}                                 # an any-class group
	var plain: Dictionary = {}                                # a group of a species with no role text
	var at_seed := 0; var at_zone := Vector2i.ZERO            # a zone whose FIRST group is any-class, with a second behind it
	var many_seed := 0; var many_zone := Vector2i.ZERO
	for s in range(1, 60):
		var gen := WorldGen.new(s, design, o.landscapes)
		for zx in range(-3, 4):
			for zy in range(-3, 4):
				var zc := Vector2i(zx * 16, zy * 16)
				var p_ := Spawner.plan(gen, zc, design, o.creatures, rosters, 1)
				for g in p_:
					if g["species"] == &"skeleton" and skel.is_empty():
						skel = g; at_seed = s; at_zone = zc
					elif plain.is_empty() and str((o.creatures[g["species"]] as Model.Creature).combat_role) == "":
						plain = g
				if many_seed == 0 and p_.size() >= 2 and str(p_[0]["role"]) != "melee" \
						and str((o.creatures[p_[0]["species"]] as Model.Creature).combat_role) == "any-class":
					many_seed = s; many_zone = zc
		if not skel.is_empty() and not plain.is_empty() and many_seed != 0:
			break
	check(not skel.is_empty(), "found a skeleton (any-class) group in a plan")
	check(str(skel.get("role", "")) in ["melee", "ranged", "mage"], "the any-class group rolled a role: %s" % skel.get("role", "-"))
	check(not plain.is_empty() and str(plain.get("role", "")) == "melee", "a species with no role plans as melee: %s" % plain.get("role", "-"))
	var a := Spawner.plan(WorldGen.new(at_seed, design, o.landscapes), at_zone, design, o.creatures, rosters, 1)
	var b := Spawner.plan(WorldGen.new(at_seed, design, o.landscapes), at_zone, design, o.creatures, rosters, 1)
	check(var_to_str(a) == var_to_str(b), "same seed → same roles")

	# --- the role roll must not touch the shared zone rng: the same zone planned with every any-class species
	# forced to melee (no roll at all) must give byte-identical groups apart from `role`.
	check(many_seed != 0, "found a zone with ≥ 2 groups behind an any-class first group")
	var any_plan := Spawner.plan(WorldGen.new(many_seed, design, o.landscapes), many_zone, design, o.creatures, rosters, 1)
	var was: Dictionary = {}
	for id in o.creatures:
		if (o.creatures[id] as Model.Creature).combat_role == &"any-class":
			was[id] = &"any-class"; (o.creatures[id] as Model.Creature).combat_role = &"melee"
	var melee_plan := Spawner.plan(WorldGen.new(many_seed, design, o.landscapes), many_zone, design, o.creatures, rosters, 1)
	for id in was:
		(o.creatures[id] as Model.Creature).combat_role = was[id]
	check(any_plan.size() == melee_plan.size(), "same group count with and without the role roll (%d / %d)" % [any_plan.size(), melee_plan.size()])
	var rolled := false
	for i in mini(any_plan.size(), melee_plan.size()):
		var x: Dictionary = (any_plan[i] as Dictionary).duplicate(true); var y: Dictionary = (melee_plan[i] as Dictionary).duplicate(true)
		rolled = rolled or str(x["role"]) != str(y["role"])
		x.erase("role"); y.erase("role")
		check(var_to_str(x) == var_to_str(y), "group %d: species / positions / level / hp / seed untouched by the role roll" % i)
	check(rolled, "…and the any-class group did roll a role other than melee at this seed")

	# --- runtime: flat floor, the player and creatures at distinct positions
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)
	feel = Feel.new(); root.add_child(feel)
	var p := _player(Vector3(0, 1, 0))
	feel.setup(design["feel"], p.get_node("CameraRig"))
	await _real(0.2)

	# --- a ranged creature shoots from range and keeps its distance
	var rng_cfg: Dictionary = cr["ranged"]
	var keep := float(rng_cfg["keep-away"])
	var sk := _spawn(&"skeleton", &"ranged", Vector3(0, 1, -10), p)
	check(sk.role == &"ranged" and str(sk.role_cfg["kind"]) == "projectile", "the spawner injected the ranged role_cfg")
	var hp0: float = p.hp
	var nearest := 1e9
	var flew := 0
	var end := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < end:
		await process_frame
		flew = maxi(flew, _shots(sk))
		nearest = minf(nearest, sk.global_position.distance_to(p.global_position))
	check(p.hp < hp0, "the ranged skeleton hit the player from range (%.0f → %.0f)" % [hp0, p.hp])
	check(flew >= 1, "a shot was in flight (%d)" % flew)
	check(_shots(sk) == 0, "the shot freed itself after landing (%d left)" % _shots(sk))
	check(nearest >= keep - 1.0, "it never closed to melee: nearest %.1f blocks (keep-away %.0f)" % [nearest, keep])

	# --- too close: it backs off again
	p.global_position = sk.global_position + Vector3(0, 0, 2)
	await _real(2.0)
	check(sk.global_position.distance_to(p.global_position) >= keep - 1.0,
		"it backed off to keep-away: %.1f" % sk.global_position.distance_to(p.global_position))
	sk.get_parent().queue_free()
	p.global_position = Vector3(0, 1, 0); p.hp = p.max_hp; p.statuses.clear()
	await _real(0.2)

	# --- line of sight: a wall stops the shots, removing it lets them through
	var wall := StaticBody3D.new(); var wcs := CollisionShape3D.new(); var wbox := BoxShape3D.new()
	wbox.size = Vector3(20, 6, 1); wcs.shape = wbox; wall.add_child(wcs); wall.position = Vector3(0, 3, -5)
	root.add_child(wall)
	var sk2 := _spawn(&"skeleton", &"ranged", Vector3(0, 1, -10), p)   # inside design.spawns.ai.aggro-range
	check(await _watch(sk2, 2.5) == 0, "no shot without line of sight")
	check(is_equal_approx(p.hp, p.max_hp), "…and the player is untouched behind the wall")
	wall.queue_free()
	check(await _watch(sk2, 3.0) >= 1, "a shot comes once the wall is gone")
	sk2.get_parent().queue_free()
	p.global_position = Vector3(0, 1, 0); p.hp = p.max_hp; p.statuses.clear()
	await _real(0.2)

	# --- a mage creature: splash damage + burning, and the burning ticks orange numbers
	var mg := _spawn(&"skeleton", &"mage", Vector3(0, 1, -8), p)
	hp0 = p.hp
	end = Time.get_ticks_msec() + 3500
	while Time.get_ticks_msec() < end and not p.statuses.has(&"burning"):
		await process_frame
	check(p.hp < hp0, "the mage shot hit the player (%.0f → %.0f)" % [hp0, p.hp])
	check(p.statuses.has(&"burning"), "the mage shot set the player burning (%s)" % [p.statuses.keys()])
	mg.set_physics_process(false)                             # no second shot while we count the dot numbers
	var dot: Array = design["feel"]["numbers"]["colours"]["dot"]
	var before := _labels(Color(dot[0], dot[1], dot[2]))
	await _real(float(design["status-effects"]["burning"]["tick-s"]) + 0.2)
	check(_labels(Color(dot[0], dot[1], dot[2])) > before, "the burning ticks float orange dot numbers (%d new)" % (_labels(Color(dot[0], dot[1], dot[2])) - before))
	mg.get_parent().queue_free()
	p.hp = p.max_hp; p.statuses.clear(); p.clear_stars()
	await _real(0.2)

	# --- a spitter's poison lands through a dodge (status-effects.json: never avoided by dodge)
	var sp := _spawn(&"spitter", &"ranged", Vector3(0, 1, -3), p)
	sp.set_physics_process(false)
	check(sp.role_cfg["applies"] == ["poison"], "the spitter species override applies poison (%s)" % [sp.role_cfg.get("applies")])
	await _real(0.2)
	p._iframes = 1.0
	hp0 = p.hp
	var hit: int = sp._strike(p.global_position + Vector3.UP, 1.0, 10.0, false, [&"poison"])
	check(hit == 1 and is_equal_approx(p.hp, hp0), "the dodged shot did no damage (%d hit, %.0f hp)" % [hit, p.hp])
	check(p.statuses.has(&"burning") and is_equal_approx(float(p.statuses[&"burning"]["dmg"]), 10.0),
		"…but the poison landed through the i-frames (%s)" % [p.statuses.keys()])
	p._iframes = 0.0; p.statuses.clear(); p.hp = p.max_hp

	# --- design.defence.enemy-hit rolls on a landed shot
	var kb = design["defence"]["enemy-hit"]["knockback-chance"]
	design["defence"]["enemy-hit"]["knockback-chance"] = 1.0
	p._push = Vector3.ZERO
	sp._strike(p.global_position + Vector3.UP, 1.0, 10.0, false, [])
	check(p._push.length() > 0.0, "a landed shot rolls enemy-hit knockback (%.1f)" % p._push.length())
	design["defence"]["enemy-hit"]["knockback-chance"] = kb
	p._push = Vector3.ZERO; p.statuses.clear(); p.clear_stars(); p.hp = p.max_hp

	# --- a blocked shot carries no status
	p.global_position = Vector3(0, 1, 0)
	sp.global_position = Vector3(0, 1, -3)                    # in front: the rig looks down -Z
	await _real(0.2)
	p.blocking = true
	sp._strike(p.global_position + Vector3.UP, 1.0, 10.0, false, [&"burning"])
	check(not p.statuses.has(&"burning"), "a blocked shot carries no status")
	p.blocking = false
	sp.get_parent().queue_free()
	p.hp = p.max_hp; p.statuses.clear()

	# --- no friendly fire: a wolf between the shooter and us keeps its HP (the shot never comes, or stops on it)
	var wolf := _spawn(&"wolf", &"melee", Vector3(0, 1, -5), p, &"P")
	wolf.set_physics_process(false)
	var sk3 := _spawn(&"skeleton", &"ranged", Vector3(0, 1, -10), p)
	var whp: float = wolf.hp
	await _real(3.0)
	check(is_equal_approx(wolf.hp, whp), "the wolf in the line of fire took nothing (%.0f)" % (whp - wolf.hp))
	sk3.get_parent().queue_free(); wolf.get_parent().queue_free()
	p.hp = p.max_hp; p.statuses.clear()
	await _real(0.2)

	# --- …and a mage splash that swallows a creature beside us damages only the player
	var pal := _spawn(&"wolf", &"melee", Vector3(1.5, 1, 0), p, &"P")
	pal.set_physics_process(false)
	var mg2 := _spawn(&"skeleton", &"mage", Vector3(0, 1, -8), p)
	whp = pal.hp
	hp0 = p.hp
	end = Time.get_ticks_msec() + 3500
	while Time.get_ticks_msec() < end and is_equal_approx(p.hp, hp0):
		await process_frame
	check(p.hp < hp0, "the mage splash hit the player (%.0f → %.0f)" % [hp0, p.hp])
	check(is_equal_approx(pal.hp, whp), "the wolf inside the same splash took nothing (%.0f)" % (whp - pal.hp))
	mg2.get_parent().queue_free(); pal.get_parent().queue_free()

	await _real(0.5)
	Engine.time_scale = 1.0
	print("test_creature_roles: %s" % ("OK" if _failed == 0 else "%d FAILED" % _failed))
	quit(1 if _failed > 0 else 0)
