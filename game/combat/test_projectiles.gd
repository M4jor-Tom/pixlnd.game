## Headless check of §3.3 movesets + projectiles (D24): `godot --headless -s game/combat/test_projectiles.gd`.
## c-moveset-config fires; a floor with frozen wolves: bow arrow flies and hits (combo, MP), a far arrow arcs into the floor
## (combo reset, freed), M2 volley count + splash, wand beam and staff at-cursor hit instantly, boomerang re-hits and
## returns, bracelet ball knocks down, dagger M2 poisons, greatsword finisher, longsword lunge, fire-missiles /
## shuriken-attack throw projectiles.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const Combat := preload("res://game/combat/combat.gd")
const Items := preload("res://game/items/items.gd")
const Spawner := preload("res://game/world/spawner.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")

var _failed := 0
var design: Dictionary
var o

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _player(class_id: StringName, spec: StringName, at: Vector3) -> CharacterBody3D:
	var p: CharacterBody3D = PLAYER.instantiate()
	p.position = at                                            # before add_child: a body born at the origin carries whoever stands there
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(1, 1.0))
	p.setup_items(o, design, class_id, spec)
	p.position = at; p.spawn_point = at
	p.get_node("CameraRig").rotation.x = 0.0                   # aim flat down -Z (rig is @onready)
	return p

func _wolf(p: Node, at: Vector3) -> CharacterBody3D:
	var holder := Node3D.new(); root.add_child(holder)
	var w: CharacterBody3D = Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"P", "max_hp": 1e6, "damage": 12.0,
		"positions": [at], "seed": 1}], design, o.creatures, p, null)[0]
	w.set_physics_process(false)
	return w

func _equip(p, type: StringName) -> void:
	var it = Items.generate(RandomNumberGenerator.new(), &"weapon", type, Items.weapon_material(o.weapon_types[type]), 1, 0)
	p.inventory.add(it); p.inventory.equip(it)

func _shots() -> int:
	var n := 0
	for c in root.get_children():
		if c.get("shot") != null:
			n += 1
	return n

func _m1(p) -> void:
	p._swing_t = 0.0
	Input.action_press("basic-attack"); await _frames(2); Input.action_release("basic-attack")

## Pitch the rig so the aim ray from the eye crosses the target (the player faces -Z, targets sit down -Z).
func _aim_at(p, t: Node3D) -> void:
	var d: Vector3 = t.global_position + Vector3.UP * 0.5 - p.eye()
	p.get_node("CameraRig").rotation.x = atan2(d.y, -d.z)

func _clear_shots() -> void:
	for c in root.get_children():
		if c.get("shot") != null:
			c.free()

func _m2(p) -> void:
	p.mp = 100.0
	Input.action_press("special-attack"); await _frames(2); Input.action_release("special-attack"); await _frames(1)

func _init() -> void:
	o = Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	design = o.configs["generators"]["design"]
	var mv: Dictionary = design["movesets"]
	mv["bow"]["m1"]["kind"] = "laser"
	check(not o.validate(), "c-moveset-config rejects an unknown kind"); o.errors.clear()
	mv["bow"]["m1"]["kind"] = "projectile"
	var saved = mv["wand"]; mv.erase("wand")
	check(not o.validate(), "c-moveset-config wants every class weapon-type"); o.errors.clear()
	mv["wand"] = saved
	mv["bow"]["m2"]["speed"] = 0
	check(not o.validate(), "c-moveset-config rejects speed 0"); o.errors.clear()
	mv["bow"]["m2"]["speed"] = 30.0
	check(o.validate(), "restored")
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)

	# --- ranger: bow arrow
	var p := _player(&"ranger", &"sniper", Vector3(0, 1, 0))
	var wolf := _wolf(p, Vector3(0, 1, -4))
	await _frames(5); _aim_at(p, wolf)
	check(p.moveset["m1"]["kind"] == "projectile", "bow moveset resolved: %s" % p.moveset["m1"].get("kind"))
	var hp0: float = wolf.hp
	await _m1(p)
	check(_shots() == 1, "one arrow in flight: %d" % _shots())
	await _frames(20)
	check(wolf.hp < hp0, "arrow hit the wolf")
	check(p.combo == 1 and p.mp > 0.0, "arrow counted for combo (%d) and MP (%.0f)" % [p.combo, p.mp])
	check(_shots() == 0, "arrow gone after the hit")
	# far target: gravity drops the arrow into the floor, the attack whiffs
	wolf.position = Vector3(0, 1, -60); await _frames(2); _aim_at(p, wolf)
	p.combo = 5
	await _m1(p)
	await _frames(200)
	check(_shots() == 0 and p.combo == 0, "far arrow arcs into the floor and resets the combo (%d)" % p.combo)
	wolf.position = Vector3(0, 1, -4); await _frames(2); _aim_at(p, wolf)
	# M2 volley
	await _m2(p)
	check(_shots() == 4, "bow M2 volley of 4: %d" % _shots())
	await _frames(120)
	check(_shots() == 0, "volley resolved")

	# --- mage: wand beam and staff at cursor are instant
	var m := _player(&"mage", &"fire-mage", Vector3(20, 1, 0))
	var w2 := _wolf(m, Vector3(20, 1, -8))
	await _frames(5); _aim_at(m, w2)
	_equip(m, &"wand")
	hp0 = w2.hp
	await _m1(m)
	check(w2.hp < hp0 and m.combo == 1, "wand beam hits at 8 blocks instantly")
	_equip(m, &"staff")
	hp0 = w2.hp
	await _m1(m)
	check(w2.hp < hp0, "staff burst lands where the aim hits")
	w2.position = Vector3(20, 1, -30); await _frames(2); _aim_at(m, w2)
	m.combo = 3
	await _m1(m)
	check(m.combo == 0, "staff beyond its 20-block range whiffs")
	w2.position = Vector3(20, 1, -8); await _frames(2); _aim_at(m, w2)
	# bracelet M2: splash ball knocks down
	_equip(m, &"bracelet")
	await _m2(m)
	await _frames(30)
	check(w2.stunned(), "bracelet ball knocked the wolf down")
	# fire-missiles: 4 projectiles from the ultimate
	w2.statuses.clear(); m.abilities.cooldowns.clear(); _clear_shots()
	check(m.abilities.use(o.abilities[&"fire-missiles"]), "fire-missiles used")
	check(_shots() == 4, "fire-missiles throws 4 fireballs: %d" % _shots())
	await _frames(40)
	check(w2.statuses.has(&"burning") and w2.stunned(), "fireballs burn and knock down")

	# --- ranger boomerang: pierces, ticks, returns
	_equip(p, &"boomerang")
	wolf.position = Vector3(0, 1, -3); await _frames(2); _aim_at(p, wolf); _clear_shots()
	hp0 = wolf.hp
	await _m1(p)
	await _frames(35)
	var ticks: float = (hp0 - wolf.hp) / (float(p.weapon["damage"]) * 0.5)
	check(ticks >= 1.5, "boomerang re-hit the wolf on its way out (%.1f ticks)" % ticks)
	check(_shots() == 1, "boomerang still flying")
	await _frames(150)
	check(_shots() == 0, "boomerang came back and vanished")

	# --- rogue: dagger M2 poison, longsword lunge
	var r := _player(&"rogue", &"ninja", Vector3(40, 1, 0))
	var w3 := _wolf(r, Vector3(40, 1, -1.5))
	await _frames(5); _aim_at(r, w3)
	check(r.moveset["m1"].get("swing-mult", 1.0) < 1.0, "dagger swings faster")
	await _m2(r)
	check(w3.statuses.has(&"burning") and w3.stunned(), "dagger ambush poisons and stuns")
	w3.statuses.clear()
	_equip(r, &"longsword")
	w3.position = Vector3(40, 1, -5.5); await _frames(2)
	hp0 = w3.hp
	await _m2(r)
	check(r.global_position.z < -2.0, "longsword M2 lunged forward (z %.1f)" % r.global_position.z)
	check(w3.hp < hp0 and w3.stunned(), "perforate hit and stunned")
	# shuriken-attack: throw then backflip
	r.stamina = 100.0; r.abilities.cooldowns.clear(); _clear_shots()
	check(r.abilities.use(o.abilities[&"shuriken-attack"]), "shuriken-attack used")
	check(_shots() == 5 and not r.abilities.dash.is_empty(), "5 shuriken thrown (%d) and the backflip runs" % _shots())
	await _frames(60)

	# --- warrior: greatsword finisher every 3rd hit
	var wa := _player(&"warrior", &"berserker", Vector3(60, 1, 0))
	var w4 := _wolf(wa, Vector3(60, 1, -2))
	await _frames(5)
	_equip(wa, &"greatsword")
	design["movesets"]["greatsword"]["m1"]["finisher"]["chance"] = 1.0
	await _m1(wa); await _m1(wa)
	check(wa.combo == 2 and not w4.stunned(), "two slow swings, no knockdown yet")
	await _m1(wa)
	check(w4.stunned(), "third swing knocks down")
	print("test_projectiles: %s" % ("OK" if _failed == 0 else "%d FAILED" % _failed))
	quit(1 if _failed > 0 else 0)
