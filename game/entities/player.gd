## player-character (§3.2) movement + §3.3 basic attack, combo, fall damage, death/respawn, class abilities on keys 1-4,
## MP + M2 special attack (D21) + §3.4 inventory, gear (main-hand damage, armor sum), pick-up (E), quick item (Q)
## + §3.5 XP, level-up, skill points (D19), skill tree spending, swim speed per point (D20).
## Config dicts (design.movement / camera / combat / crit) are injected by main.gd: this script never
## names OntologyDB so headless tests (no autoloads) can drive it.
## ponytail: no climb/dodge/glide/block/stealth bar yet (todo_implement.md).
extends "res://game/entities/entity.gd"

const Combat := preload("res://game/combat/combat.gd")
const Abilities := preload("res://game/combat/abilities.gd")
const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Inventory := preload("res://game/items/inventory.gd")
const Progression := preload("res://game/progression/progression.gd")
const SkillTree := preload("res://game/progression/skill_tree.gd")

signal picked_up(label: String)
signal leveled_up(level: int)
signal skills_changed

var cfg: Dictionary = {}                                # design.movement
var combat: Dictionary = {}                             # design.combat
var crit: Dictionary = {}                               # design.crit
var weapon: Dictionary = {}                             # {type, damage, combo_cap}, derived from the main-hand item
var inventory                                           # Inventory, after setup_items
var o                                                   # the Ontology (items need weapon types, materials, names)
var design: Dictionary = {}                             # generators.json#design
var crit_chance := 0.0
var xp := 0
var skill_points := 0
var skill_tree                                          # SkillTree, after setup_items (D20)
var abilities                                           # Abilities runner, after setup_items (D21)
var mp := 0.0                                           # c-mp-range, design.resources.mp
var mp_passive := false                                 # classes.json mp-generation "passive …" (mage)
var special_mode: StringName = &"charged"               # classes.json special-attack-mode
var hp_mult := 1.0                                      # class hp-mult, for max HP on level-up
var prog: Dictionary = {}                               # design.progression
var combo := 0
var water_top := -INF                                   # y of the water surface (sea level + 1)
var ground_ready: Callable = func(_p: Vector3) -> bool: return true   # world: is the zone under us built?
var spawn_point := Vector3.ZERO
var stamina := 100.0
var _stamina_idle := 0.0
var _swing_t := 0.0
var _combo_t := 0.0
var _charge := -1.0                                     # M2 charge in MP; < 0 = not charging
var _fall_from := -INF
var _rng := RandomNumberGenerator.new()
@onready var rig: Node3D = $CameraRig

func setup(movement: Dictionary, camera: Dictionary, size_class: StringName) -> void:
	cfg = movement
	stamina = float(cfg["stamina"]["max"])
	var hb: Array = cfg["hitbox"][size_class]
	$Collision.shape.radius = hb[0]; $Collision.shape.height = hb[1]; $Collision.position.y = hb[1] / 2.0
	$Body.mesh.radius = hb[0]; $Body.mesh.height = hb[1]; $Body.position.y = hb[1] / 2.0
	floor_snap_length = float(cfg["step-up"]) + 0.2
	$CameraRig.setup(camera, hb[1], self)               # not `rig`: setup may run before _ready

func setup_combat(p_combat: Dictionary, p_crit: Dictionary, p_weapon: Dictionary, p_max_hp: float) -> void:
	combat = p_combat; crit = p_crit; weapon = p_weapon
	max_hp = p_max_hp; hp = p_max_hp
	if not died.is_connected(_on_died):
		died.connect(_on_died)

## design.starting-inventory (D18): the class starter weapon equipped + potions + coins; gear → weapon/armor.
func setup_items(p_o, p_design: Dictionary, class_id: StringName = &"warrior", spec_id: StringName = &"") -> void:
	o = p_o; design = p_design
	var cls = o.classes[class_id]
	if spec_id == &"":
		spec_id = cls.specializations[0]                          # c-spec-of-class: start as spec index 0
	skill_tree = SkillTree.new(o, design["skill-point"], class_id, spec_id)
	abilities = Abilities.new(self, design["abilities"])
	special_mode = cls.special_attack_mode
	mp_passive = "passive" in str(cls.raw.get("mp-generation", []))
	prog = design["progression"]; hp_mult = cls.hp_mult
	inventory = Inventory.new(o, design)
	var start: Dictionary = design["starting-inventory"]
	var starter: Dictionary = combat["starter-weapon"]
	var wt = o.weapon_types[cls.weapon_types[0]]
	var first := Items.generate(_rng, &"weapon", wt.id, Items.weapon_material(wt), int(starter["level"]), int(starter["rarity"]))
	inventory.add(first); inventory.equip(first)
	for c in start["consumables"]:
		inventory.add(Item.stack(&"consumable", StringName(c), int(start["consumables"][c])))
	inventory.coins = int(start["coins"])
	inventory.changed.connect(_refresh_gear)
	_refresh_gear()

## equips: main-hand item → weapon damage (gen-item-stats × attack-power-mult); armor = sum over worn gear.
func _refresh_gear() -> void:
	var main = inventory.equipment.get(&"main-hand")
	if main != null:
		var wt = o.weapon_types[main.subtype]
		weapon = {"type": main.subtype, "damage": Items.damage(main, o) * float(combat["attack-power-mult"]),
			"combo_cap": wt.combo_cap if wt.combo_cap > 0 else int(combat["combo"]["default-cap"])}
	armor = 0.0
	for slot in inventory.equipment:
		armor += Items.armor(inventory.equipment[slot], o)

## death of a creature we last hit → design.progression XP (D19), then level-up (c-level-up).
func on_kill(creature_level: int) -> void:
	if prog.is_empty():                                    # tests that skip setup_items
		return
	gain_xp(Model.xp_for_kill(creature_level, level, prog))

func gain_xp(amount: int) -> void:
	var s := Progression.settle(level, xp + amount)
	xp = s["xp"]
	if s["gained"] == 0:
		return
	level = s["level"]
	skill_points += s["gained"] * Model.SKILL_POINTS_PER_LEVEL
	max_hp = Combat.player_max_hp(level, hp_mult)
	if prog["heal-on-level-up"]:
		hp = max_hp
	leveled_up.emit(level)
	skills_changed.emit()

## c-skill-spend (D20): one banked point onto an open node of the tree.
func spend_skill(a) -> void:
	skill_points = skill_tree.spend(a, skill_points)
	skills_changed.emit()

## Keys 1-4 fire the class node that has points through its design.abilities runtime (D21).
func use_class_skill(slot: int) -> bool:
	if skill_tree == null:
		return false
	var a = skill_tree.class_slot(slot)
	return a != null and skill_tree.spent(a.id) > 0 and abilities.use(a)

## Buffs (bulwark) make us stun-immune; mana-shield absorbs first (D21).
func take_damage(amount: float, from: Node) -> void:
	if abilities != null:
		amount = abilities.absorb(amount * abilities.mult("damage-taken-mult"))
	super.take_damage(amount, from)

func stun_immune() -> bool:
	return abilities != null and abilities.flag("stun-immune")

func item_label(it) -> String:
	return Items.item_name(it, o, design)

func pick_up(ground: Node3D) -> void:
	if ground.is_queued_for_deletion():
		return
	inventory.add(ground.item)
	picked_up.emit(ground.label)
	ground.queue_free()

## pick-up (E): the nearest ground item within design.loot.ground.pickup-radius.
func pick_up_nearest() -> bool:
	var best: Node3D
	var best_d := float(design["loot"]["ground"]["pickup-radius"])
	for n in get_tree().get_nodes_in_group("ground-items"):
		var d: float = n.global_position.distance_to(global_position)
		if d <= best_d and not n.is_queued_for_deletion():
			best = n; best_d = d
	if best == null:
		return false
	pick_up(best)
	return true

## consumable: heal (consumable-heal) and spend one. ponytail: instant, no sit/channel time.
func use_item(it) -> void:
	hp = minf(max_hp, hp + Items.heal(it, o))
	inventory.remove(it)

## quick-item (Q): the first consumable stack. ponytail: no quick-select wheel yet.
func use_quick() -> bool:
	var it = inventory.first_consumable()
	if it == null:
		return false
	use_item(it)
	return true

func _physics_process(dt: float) -> void:
	if cfg.is_empty() or dead or not ground_ready.call(global_position):
		return
	var g := float(cfg["gravity"])
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (Basis(Vector3.UP, rig.rotation.y) * Vector3(input.x, 0, input.y)).normalized()
	var swimming := global_position.y < water_top - 0.5
	var speed := float(cfg["walk"])
	var st: Dictionary = cfg["stamina"]
	if Input.is_action_pressed("sprint") and dir != Vector3.ZERO and stamina > 0.0 and not swimming:
		speed *= float(cfg["sprint-mult"])
		stamina = maxf(0.0, stamina - float(st["sprint-drain"]) * dt)
		_stamina_idle = 0.0
	else:
		_stamina_idle += dt
		if _stamina_idle >= float(st["regen-delay-s"]):
			stamina = minf(float(st["max"]), stamina + float(st["regen"]) * dt)
	if abilities != null:
		speed *= abilities.mult("move-mult")                 # buffs + channel (D21)
	if swimming:
		speed *= float(cfg["swim-mult"]) * (skill_tree.effect_mult(&"swimming") if skill_tree != null else 1.0)   # swimming points (D20)
		velocity.y = float(cfg["swim-vertical"]) * (1.0 if Input.is_action_pressed("jump") else -0.3)
		_fall_from = -INF                                   # water breaks the fall
	else:
		velocity.y -= g * dt
		var jh: Dictionary = cfg["jump-height"]
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = sqrt(2.0 * g * float(jh["hold"]))
		elif velocity.y > 0.0 and not Input.is_action_pressed("jump"):
			velocity.y = minf(velocity.y, sqrt(2.0 * g * float(jh["tap"])))   # released early: tap height
	velocity.x = dir.x * speed; velocity.z = dir.z * speed
	if abilities != null and not abilities.dash.is_empty():
		var dv: Vector3 = abilities.dash_velocity()
		velocity.x = dv.x; velocity.z = dv.z
	step_up(Vector3(velocity.x, 0, velocity.z) * dt, float(cfg["step-up"]))
	var was_airborne := not is_on_floor()
	move_and_slide()
	if abilities != null:
		abilities.after_move(dt)
	_fall_damage(was_airborne)
	if not combat.is_empty():
		_combat_tick(dt)
	if inventory != null:
		if Input.is_action_just_pressed("pick-up"):
			pick_up_nearest()
		if Input.is_action_just_pressed("quick-item"):
			use_quick()

## design.movement.fall-damage: % of max HP per block beyond the free height.
func _fall_damage(was_airborne: bool) -> void:
	if not is_on_floor():
		_fall_from = maxf(_fall_from, global_position.y)
		return
	if was_airborne and _fall_from > -INF:
		var fd: Dictionary = cfg["fall-damage"]
		var drop := _fall_from - global_position.y - float(fd["from-blocks"])
		if drop > 0.0:
			take_damage(max_hp * float(fd["pct-max-hp-per-block"]) / 100.0 * drop, self)
	_fall_from = -INF

func _combat_tick(dt: float) -> void:
	_swing_t -= dt; _combo_t -= dt
	if _combo_t <= 0.0:
		combo = 0
	if abilities == null:
		if Input.is_action_just_pressed("basic-attack") and _swing_t <= 0.0:
			_swing()
		return
	abilities.tick(dt)
	if mp_passive:
		mp = minf(float(design["resources"]["mp"]["max"]), mp + float(design["resources"]["mp"]["mage-regen-per-s"]) * dt)
	for slot in 4:
		if Input.is_action_just_pressed("class-skill-%d" % (slot + 1)) or (slot == 3 and Input.is_action_just_pressed("ultimate")):
			use_class_skill(slot + 1)
	if abilities.busy():
		return
	if Input.is_action_just_pressed("basic-attack") and _swing_t <= 0.0:
		_swing()
	_special_tick(dt)

## special-attack (M2, D21): charged classes hold to reserve MP (HUD bar pink), release to spend it; instant classes
## press and spend everything. Damage and stun chance grow with the MP spent.
func _special_tick(dt: float) -> void:
	var sp: Dictionary = design["special-attack"]
	if special_mode == &"charged":
		if Input.is_action_just_pressed("special-attack") and mp >= float(sp["min-mp"]):
			_charge = 0.0
		if _charge >= 0.0:
			_charge = minf(mp, _charge + float(sp["charge-mp-per-s"]) * abilities.mult("charge-mult") * dt)
			if not Input.is_action_pressed("special-attack"):
				_special(_charge); _charge = -1.0
	elif Input.is_action_just_pressed("special-attack") and mp >= float(sp["min-mp"]):
		_special(mp)

func _special(charged: float) -> void:
	var sp: Dictionary = design["special-attack"]
	var f := charged / float(design["resources"]["mp"]["max"])
	mp -= charged
	var applies: Array = [&"stun"] if _rng.randf() < f * float(sp["stun-chance-at-full"]) else []
	if _strike(_front(), float(combat["basic-attack"]["hit-radius"]), float(weapon["damage"]) * (1.0 + f * (float(sp["damage-mult-at-full"]) - 1.0)), false, applies) == 0:
		combo = 0                                             # c-combo-reset

func _front() -> Vector3:
	var ba: Dictionary = combat["basic-attack"]
	return global_position + Vector3.UP + (Basis(Vector3.UP, rig.rotation.y) * Vector3.FORWARD) * float(ba["reach"]) * 0.6

## basic-attack: sphere in front of us (camera yaw); every entity inside takes weapon damage.
## A whiff resets the combo (c-combo-reset); a hit adds one, capped per weapon-type, and gives non-mages MP.
func _swing() -> void:
	var ba: Dictionary = combat["basic-attack"]
	_swing_t = float(ba["swing-s"]) * (abilities.mult("swing-mult") if abilities != null else 1.0)
	var hits := _strike(_front(), float(ba["hit-radius"]), float(weapon["damage"]), true)
	if hits > 0:
		combo = mini(combo + 1, int(weapon["combo_cap"]))
		_combo_t = float(combat["combo"]["expire-s"])
		if abilities != null and not mp_passive:
			mp = minf(float(design["resources"]["mp"]["max"]), mp + float(design["resources"]["mp"]["per-hit"]))
	else:
		combo = 0

## Live entities inside the sphere, nearest first.
func bodies_within(center: Vector3, radius: float) -> Array:
	var shape := SphereShape3D.new(); shape.radius = radius
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape; q.transform = Transform3D(Basis(), center); q.exclude = [get_rid()]
	var out: Array = []
	for r in get_world_3d().direct_space_state.intersect_shape(q, 16):
		var body: Object = r["collider"]
		if body.has_method("take_damage") and not body.get("dead"):
			out.append(body)
	out.sort_custom(func(x: Node3D, y: Node3D) -> bool: return x.global_position.distance_squared_to(global_position) < y.global_position.distance_squared_to(global_position))
	return out

func nearest_enemy(radius: float) -> Node3D:
	for b in bodies_within(global_position + Vector3.UP, radius):
		if b.get("hostility") != &"F":
			return b
	return null

## Every live entity inside the sphere takes `dmg` (buffs, crit, armor); the combo bonus only for the basic attack;
## `applies` = status-effect ids the hit carries (design.status-effects decides what they do).
func _strike(center: Vector3, radius: float, dmg: float, combo_bonus: bool, applies: Array = []) -> int:
	var hits := 0
	var chance: float = crit_chance + (abilities.add("crit-add") if abilities != null else 0.0)
	var se: Dictionary = design.get("status-effects", {})
	for body in bodies_within(center, radius):
		var d := dmg * (Combat.combo_mult(combo, combat) if combo_bonus else 1.0) * Combat.crit_mult(chance, _rng, crit)
		if abilities != null:
			d *= abilities.mult("damage-mult")
		d = Combat.after_armor(d, float(body.get("armor")), combat)
		if d > 0.0 or applies.has(&"taunt"):                   # taunt: a 0-damage hit sets the creature's target
			body.take_damage(d, self)
		for id in applies:
			if se.has(id) and body.has_method("apply_status"):
				body.apply_status(id, se[id], d, self)
		hits += 1
	return hits

func _on_died() -> void:
	velocity = Vector3.ZERO
	if abilities != null:
		abilities.reset()
	_charge = -1.0
	await get_tree().create_timer(float(combat["death"]["respawn-s"])).timeout
	global_position = spawn_point                            # c-no-death-penalty
	hp = max_hp; stamina = float(cfg["stamina"]["max"]); combo = 0
	dead = false
