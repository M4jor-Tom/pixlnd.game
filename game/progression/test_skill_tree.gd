## Headless check of §3.5 skill-tree (D6/D10/D20): `godot --headless -s game/progression/test_skill_tree.gd`.
## Tree shape for every spec, c-tree-shape fires, spend/unlock rule (c-skill-spend), per-point multipliers,
## key slots, then a floor with a player and a wolf: spend a point on Smash, key 1 hits, cooldown holds.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const SkillTree := preload("res://game/progression/skill_tree.gd")
const Combat := preload("res://game/combat/combat.gd")
const Spawner := preload("res://game/world/spawner.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const PLAYER := preload("res://game/entities/player.tscn")

var _failed := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
		printerr("  ✗ ", what)

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _ids(nodes: Array) -> Array:
	return nodes.map(func(a) -> StringName: return a.id)

func _init() -> void:
	var o := Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	var design: Dictionary = o.configs["generators"]["design"]
	# shape: shared columns + 3 class ranks + ≤1 ultimate, in screen order
	var ids := _ids(o.skill_tree(&"warrior", &"berserker"))
	check(ids == [&"pet-master", &"riding", &"climbing", &"hang-gliding", &"swimming", &"sailing", &"smash", &"cyclone", &"war-frenzy", &"rock-fist"], "berserker tree: %s" % [ids])
	check(_ids(o.skill_tree(&"warrior", &"guardian")).slice(8) == [&"bulwark", &"heroic-shout"], "guardian rank 3 + ultimate")
	check(_ids(o.skill_tree(&"rogue", &"assassin")).size() == 9 and _ids(o.skill_tree(&"rogue", &"ninja")).slice(6) == [&"intercept", &"sneak", &"shuriken-attack", &"ninjutsu"], "rogue trees (sneak via alpha-tree.class, assassin has no 4th)")
	check(_ids(o.skill_tree(&"mage", &"water-mage")).slice(6) == [&"healing-stream", &"mana-shield", &"teleport", &"bubbles"], "water-mage rank 1 is spec-specific")
	# c-tree-shape fires
	o.abilities["cyclone"].alpha_tree["rank"] = 3
	check(not o.validate(), "c-tree-shape rejects two rank-3 nodes")
	o.abilities["cyclone"].alpha_tree["rank"] = 2; o.errors.clear(); check(o.validate(), "restored")
	# spend / unlock (c-skill-spend)
	var t := SkillTree.new(o, design["skill-point"], &"warrior", &"berserker")
	var smash = o.abilities["smash"]; var cyclone = o.abilities["cyclone"]; var frenzy = o.abilities["war-frenzy"]
	var fist = o.abilities["rock-fist"]; var riding = o.abilities["riding"]; var pets = o.abilities["pet-master"]
	check(t.spend(smash, 0) == 0 and t.spent(&"smash") == 0, "empty bank spends nothing")
	check(not t.is_open(cyclone) and t.spend(cyclone, 9) == 9, "cyclone locked until 5 in smash")
	var bank := 9
	for i in 5:
		bank = t.spend(smash, bank)
	check(bank == 4 and t.spent(&"smash") == 5 and t.is_open(cyclone) and not t.is_open(frenzy), "5 in smash opens cyclone only")
	check(t.prerequisite(fist) == frenzy and t.prerequisite(riding) == pets and t.prerequisite(pets) == null, "prerequisites: ultimate ← rank 3, riding ← pet-master, roots none")
	check(t.spend(riding, bank) == bank, "riding locked until 5 in pet-master")
	check(is_equal_approx(t.effect_mult(&"smash"), 1.25) and is_equal_approx(t.cooldown_mult(&"smash"), 0.75), "5 points: effect ×1.25, cooldown ×0.75")
	t.points[&"smash"] = 20
	check(is_equal_approx(t.cooldown_mult(&"smash"), 0.25) and is_equal_approx(t.effect_mult(&"smash"), 2.0), "20 points: cooldown floor 0.25, effect uncapped ×2")
	check(t.class_slot(1) == smash and t.class_slot(4) == fist and SkillTree.new(o, design["skill-point"], &"rogue", &"assassin").class_slot(4) == null, "keys 1/4 → smash/rock-fist; assassin has no key 4")
	check(SkillTree.listed_cooldown(fist) == 20.0 and SkillTree.listed_cooldown(smash) < 0.0, "listed cooldown: rock-fist 20 s, smash none (S 0)")
	# scene: one point on Smash, key 1 strikes the wolf next to us, then the cooldown blocks a second strike
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	check(InputMap.has_action("skills-window"), "X bound from keybinds.json#hybrid.skills-window")
	var floor := StaticBody3D.new(); var cs := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100); cs.shape = box; floor.add_child(cs); floor.position.y = -0.5
	root.add_child(floor)
	var p: CharacterBody3D = PLAYER.instantiate()
	root.add_child(p)
	p.setup(design["movement"], design["camera"], &"normal")
	p.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(1, 1.3))
	p.setup_items(o, design)
	p.position = Vector3(0, 1, 0); p.spawn_point = p.position
	check(p.skill_tree.nodes.size() == 10, "player starts as warrior/berserker (spec index 0)")
	var holder := Node3D.new(); root.add_child(holder)
	var wolves := Spawner.populate(holder, [{"species": &"wolf", "level": 1, "hostility": &"H", "max_hp": 1e6, "damage": 0.0,
		"positions": [Vector3(0, 1, -2)], "seed": 1}], design, o.creatures, p, null)
	await _frames(5)
	check(not p.use_class_skill(1), "no points in smash → key 1 does nothing")
	p.skill_points = 1; p.spend_skill(smash)
	check(p.skill_points == 0 and p.skill_tree.spent(&"smash") == 1, "one banked point spent on smash")
	var hp0: float = wolves[0].hp
	check(p.use_class_skill(1), "key 1 strikes")
	var expected := Combat.after_armor(p.weapon["damage"] * 2.0 * 1.05, wolves[0].armor, design["combat"])
	check(is_equal_approx(hp0 - wolves[0].hp, expected), "strike = weapon × 2 × 1.05 after armor: %.1f vs %.1f" % [hp0 - wolves[0].hp, expected])
	check(not p.use_class_skill(1) and is_equal_approx(p._cooldowns[&"smash"], 10.0 * 0.95), "second strike blocked, cooldown 9.5 s: %s" % p._cooldowns)
	check(is_equal_approx(p.skill_tree.effect_mult(&"swimming"), 1.0), "swim speed unchanged with no swimming points")
	print("skill tree ok" if _failed == 0 else "skill tree FAILED (%d)" % _failed)
	quit(0 if _failed == 0 else 1)
