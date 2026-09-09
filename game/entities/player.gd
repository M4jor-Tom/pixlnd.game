## player-character (§3.2) movement + §3.3 basic attack, combo, fall damage, death/respawn + §3.4 inventory,
## gear (main-hand damage, armor sum), pick-up (E), quick item (Q) + §3.5 XP, level-up, banked skill points (D19).
## Config dicts (design.movement / camera / combat / crit) are injected by main.gd: this script never
## names OntologyDB so headless tests (no autoloads) can drive it.
## ponytail: no climb/dodge/glide/special attack/block/stealth/MP yet (todo_implement.md).
extends "res://game/entities/entity.gd"

const Combat := preload("res://game/combat/combat.gd")
const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Inventory := preload("res://game/items/inventory.gd")
const Progression := preload("res://game/progression/progression.gd")

signal picked_up(label: String)
signal leveled_up(level: int)

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
func setup_items(p_o, p_design: Dictionary, class_id: StringName = &"warrior") -> void:
	o = p_o; design = p_design
	prog = design["progression"]; hp_mult = o.classes[class_id].hp_mult
	inventory = Inventory.new(o, design)
	var start: Dictionary = design["starting-inventory"]
	var starter: Dictionary = combat["starter-weapon"]
	var wt = o.weapon_types[o.classes[class_id].weapon_types[0]]
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
	if swimming:
		speed *= float(cfg["swim-mult"])
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
	step_up(Vector3(velocity.x, 0, velocity.z) * dt, float(cfg["step-up"]))
	var was_airborne := not is_on_floor()
	move_and_slide()
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
	if Input.is_action_just_pressed("basic-attack") and _swing_t <= 0.0:
		_swing()

## basic-attack: sphere in front of us (camera yaw); every entity inside takes weapon damage.
## A whiff resets the combo (c-combo-reset); a hit adds one, capped per weapon-type.
func _swing() -> void:
	var ba: Dictionary = combat["basic-attack"]
	_swing_t = float(ba["swing-s"])
	var forward := Basis(Vector3.UP, rig.rotation.y) * Vector3.FORWARD
	var shape := SphereShape3D.new(); shape.radius = float(ba["hit-radius"])
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), global_position + Vector3.UP + forward * float(ba["reach"]) * 0.6)
	q.exclude = [get_rid()]
	var hits := 0
	for r in get_world_3d().direct_space_state.intersect_shape(q, 8):
		var body: Object = r["collider"]
		if body.has_method("take_damage") and not body.get("dead"):
			var dmg := float(weapon["damage"]) * Combat.combo_mult(combo, combat) * Combat.crit_mult(crit_chance, _rng, crit)
			body.take_damage(Combat.after_armor(dmg, float(body.get("armor")), combat), self)
			hits += 1
	if hits > 0:
		combo = mini(combo + 1, int(weapon["combo_cap"]))
		_combo_t = float(combat["combo"]["expire-s"])
	else:
		combo = 0

func _on_died() -> void:
	velocity = Vector3.ZERO
	await get_tree().create_timer(float(combat["death"]["respawn-s"])).timeout
	global_position = spawn_point                            # c-no-death-penalty
	hp = max_hp; stamina = float(cfg["stamina"]["max"]); combo = 0
	dead = false
