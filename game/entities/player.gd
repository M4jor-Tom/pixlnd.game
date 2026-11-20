## player-character (§3.2) movement + §3.3 basic attack, combo, fall damage, death/respawn, class abilities on keys 1-4,
## MP + M2 special attack (D21) + §3.4 inventory, gear (damage, HP, armor, Resistance), pick-up (E), quick item (Q)
## + §3.5 XP, level-up, skill points (D19), skill tree spending, swim speed per point (D20).
## + D22: E talks to the nearest NPC (vendor → `talked`, trainer respec, inn rest) before picking up.
## + D23 defence (design.defence): M3 dodge roll with i-frames, M2-held block with block-power, the stealth bar, and
##   creature hits stunning / knocking us back (statuses tick here too).
## Config dicts (design.movement / camera / combat / crit) are injected by main.gd: this script never
## names OntologyDB so headless tests (no autoloads) can drive it.
## + D24 movesets (design.movesets): M1 / M2 per main-hand weapon-type — melee sphere variants, projectiles
##   (combat/projectile.gd), beams and at-cursor bursts along the camera aim.
## + D25 game feel: every hit / crit / kill / hurt / block / dodge / shoot / level-up / pick-up plays its
##   `design.feel` bundle through `feel` (combat/feel.gd), injected by main.gd; null in tests that skip it.
## ponytail: no climb/glide yet; dodge has no crit window, stealth ignores darkness (todo_implement.md).
extends "res://game/entities/entity.gd"

const Combat := preload("res://game/combat/combat.gd")
const Projectile := preload("res://game/combat/projectile.gd")
const Abilities := preload("res://game/combat/abilities.gd")
const Domain := preload("res://game/domain/domain.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Inventory := preload("res://game/items/inventory.gd")
const Progression := preload("res://game/progression/progression.gd")
const SkillTree := preload("res://game/progression/skill_tree.gd")

const PlayerInventory := preload("res://game/entities/player_inventory.gd")
const PlayerStrikes := preload("res://game/entities/player_strikes.gd")
const PlayerAttacks := preload("res://game/entities/player_attacks.gd")
const PlayerDefence := preload("res://game/entities/player_defence.gd")
const PlayerMotion := preload("res://game/entities/player_motion.gd")

signal picked_up(label: String)
signal leveled_up(level: int)
signal skills_changed
signal talked(npc: Node)  # E at an NPC (D22); panels listen for vendor roles
signal notice(text: String)  # HUD toast

var targeting: Node  # injected canonical world/party authority
var cfg: Dictionary = {}  # design.movement
var combat: Dictionary = {}  # design.combat
var crit: Dictionary = {}  # design.crit
var weapon: Dictionary = {}  # {type, damage, combo_cap}, derived from the main-hand item
const DEFAULT_MOVESET := {"m1": {"kind": "melee"}, "m2": {"kind": "melee"}}
const HIT_TIERS: Array[StringName] = [&"hit", &"crit", &"kill"]  # D25 bundle strength, weakest first
var moveset: Dictionary = DEFAULT_MOVESET  # design.movesets entry of the main-hand weapon-type (D24)
var _m1_hits := 0  # landed M1 hits in a row (melee finisher counter)
var inventory  # Inventory, after setup_items
var o  # the Ontology (items need weapon types, materials, names)
var design: Dictionary = {}  # generators.json#design
var crit_chance := 0.0
var xp := 0
var skill_points := 0
var skill_tree  # SkillTree, after setup_items (D20)
var abilities  # Abilities runner, after setup_items (D21)
var mp := 0.0  # c-mp-range, design.resources.mp
var mp_passive := false  # classes.json mp-generation "passive …" (mage)
var special_mode: StringName = &"charged"  # classes.json special-attack-mode
var hp_mult := 1.0  # class hp-mult, for max HP on level-up
var _base_max_hp: float  # injected class-scaled base, without gear
var prog: Dictionary = {}  # design.progression
var combo := 0
var water_top := -INF  # y of the water surface (sea level + 1)
var ground_ready: Callable = func(_p: Vector3) -> bool: return true  # world: is the zone under us built?
var world_min := Vector2(-INF, -INF)
var world_max := Vector2(INF, INF)  # exclusive; set from finite world design
var _motion_remainder_x := 0.0
var _motion_remainder_z := 0.0
var relocate: Callable
var _spawn_position := [0.0, 0.0, 0.0]
var spawn_point: Vector3:
	get:
		return (
			frame.to_local(_spawn_position)
			if frame != null
			else Vector3(_spawn_position[0], _spawn_position[1], _spawn_position[2])
		)
	set(v):
		_spawn_position = (
			frame.to_logical(v) if frame != null else [float(v.x), float(v.y), float(v.z)]
		)


func logical_respawn() -> Array:
	return _spawn_position.duplicate()


func set_logical_respawn(p: Array) -> void:
	_spawn_position = p.duplicate()


var touch_input: Node = null  # null preserves the keyboard/mouse adapter
var _touch_frame := {}
var _touch_jump := false
var ui_open := false  # panel owns input, not simulation time
var map_open := false  # selected map gates new requests, not simulation
var stamina := 100.0
var _stamina_idle := 0.0
var _swing_t := 0.0
var _combo_t := 0.0
var _charge := -1.0  # M2 charge in MP; < 0 = not charging
var spec: StringName = &""  # specialization id (passives decide dodge rewards, guardian block)
var defence: Dictionary = {}  # design.defence (D23)
var block_power := 0.0
var blocking := false
var stealth := 0.0  # 0..1 bar
var _dodge: Dictionary = {}  # {"dir", "left"} while rolling
var _iframes := 0.0
var _dodge_cd := 0.0
var _push := Vector3.ZERO  # knockback carried across ticks (input rewrites velocity.x/z)
var _hit_stealth := 0.0  # stealth the last _strike was thrown at (MP bonus reads it)
const PUSH_DECAY := 30.0  # ponytail: blocks/s² a knockback fades at; make it a design key if it needs tuning
var _fall_from := -INF
var _rng := RandomNumberGenerator.new()
@onready var rig: Node3D = $CameraRig


func setup(movement: Dictionary, camera: Dictionary, size_class: StringName) -> void:
	cfg = movement
	stamina = float(cfg["stamina"]["max"])
	var hb: Array = cfg["hitbox"][size_class]
	$Collision.shape.radius = hb[0]
	$Collision.shape.height = hb[1]
	$Collision.position.y = hb[1] / 2.0
	$Body.mesh.radius = hb[0]
	$Body.mesh.height = hb[1]
	$Body.position.y = hb[1] / 2.0
	floor_snap_length = float(cfg["step-up"]) + 0.2
	$CameraRig.setup(camera, hb[1], self)  # not `rig`: setup may run before _ready


func setup_combat(
	p_combat: Dictionary, p_crit: Dictionary, p_weapon: Dictionary, p_max_hp: float
) -> void:
	combat = p_combat
	crit = p_crit
	weapon = p_weapon
	_base_max_hp = p_max_hp
	max_hp = p_max_hp
	hp = p_max_hp
	if not died.is_connected(_on_died):
		died.connect(_on_died)


## design.starting-inventory (D18): the class starter weapon equipped + potions + coins; gear → weapon/armor.
func setup_items(
	p_o, p_design: Dictionary, class_id: StringName = &"warrior", spec_id: StringName = &""
) -> void:
	PlayerInventory.setup_items(self, p_o, p_design, class_id, spec_id)


## equips: main-hand damage; HP, armor and Resistance sum the worn gear stats once.
func _refresh_gear() -> void:
	PlayerInventory._refresh_gear(self)


## death of a creature we last hit → design.progression XP (D19), then level-up (c-level-up).
func on_kill(creature_level: int) -> void:
	PlayerInventory.on_kill(self, creature_level)


func gain_xp(amount: int) -> void:
	PlayerInventory.gain_xp(self, amount)


## c-skill-spend (D20): one banked point onto an open node of the tree.
func spend_skill(a) -> void:
	PlayerInventory.spend_skill(self, a)


## Keys 1-4 fire the class node that has points through its design.abilities runtime (D21).
func use_class_skill(slot: int) -> bool:
	return PlayerInventory.use_class_skill(self, slot)


## D23: a dodge ignores the hit, a front block (design.defence.block) cuts it, spends block-power and gives MP;
## then buffs (bulwark) make us stun-immune and mana-shield absorbs first (D21).
func take_damage(amount: float, from: Node, status: StringName = &"") -> bool:
	if _iframes > 0.0 and status != &"poison":  # D26: scheduled poison damage is not dodged
		return false
	var blocked := blocks_from(from)
	if blocked:
		var bl: Dictionary = defence["block"]
		amount *= 1.0 - float(bl["damage-reduction"])
		block_power = maxf(0.0, block_power - float(bl["power-per-hit"]))
		mp = minf(float(design["resources"]["mp"]["max"]), mp + float(bl["mp-per-block"]))  # D11 block-reward
	if abilities != null:
		amount = abilities.absorb(amount * abilities.mult("damage-taken-mult"))
	var before := hp
	super.take_damage(amount, from)
	if not _damage_feedback(blocked, before):
		return false
	return blocked  # preserve this hit's result even if it emptied the bar


## Spikes intentionally bypass dodge/block, then share ordinary reduction/absorption and actual HP loss.
func take_hazard_damage(raw: float, from: Node) -> void:
	var amount := Combat.after_defence(raw, armor, resistance, Combat.PHYSICAL, combat)
	if abilities != null:
		amount = abilities.absorb(amount * abilities.mult("damage-taken-mult"))
	var before := hp
	super.take_damage(amount, from)
	if feel != null and before > hp:
		feel.play(&"hurt", head(), {"amount": before - hp, "kind": &"hurt"})


## Dodged or blocked hits carry no status (D23) — except poison, which a dodge never avoids (D26, status-effects.json);
## knockback goes through _push so input does not erase it next tick.
func apply_status(id: StringName, cfg: Dictionary, hit: float, from: Node) -> void:
	if dead or (_iframes > 0.0 and id != &"poison") or blocks_from(from):  # D23 i-frames, D26: dodge never avoids poison
		return
	if StringName(str(cfg.get("as", id))) == &"knockback":
		var d: Vector3 = global_position - (from as Node3D).global_position
		d.y = 0.0
		_push = d.normalized() * float(cfg["impulse"])
		velocity.y += float(cfg["impulse"]) * 0.25
		return
	super.apply_status(id, cfg, hit, from)
	if stunned():
		_charge = -1.0  # stun interrupts charges


func passives() -> Array:
	return PlayerDefence.passives(self)


func _cyclone() -> bool:
	return PlayerDefence._cyclone(self)


## block: a shield in the off-hand, any weapon as guardian (barricade), or during cyclone.
func can_block() -> bool:
	return PlayerDefence.can_block(self)


func block_max() -> float:
	return PlayerDefence.block_max(self)


## Is this attacker's hit blocked: blocking, and it stands in the front cone (every direction during cyclone).
func blocks_from(from: Node) -> bool:
	return PlayerDefence.blocks_from(self, from)


## dodge (M3 while moving, c-dodge-cost): roll `dir`, i-frames, stamina; passives reward it (elusiveness MP, way-of-the-shadows stealth).
func dodge(dir: Vector3) -> bool:
	return PlayerDefence.dodge(self, dir)


## Per tick: dodge timers, the block state + block-power regen, the stealth bar (design.defence).
func _defence_tick(dt: float, dir: Vector3, still: bool) -> void:
	PlayerDefence._defence_tick(self, dt, dir, still)


func stun_immune() -> bool:
	return PlayerDefence.stun_immune(self)


func item_label(it) -> String:
	return PlayerInventory.item_label(self, it)


func pick_up(ground: Node3D) -> void:
	PlayerInventory.pick_up(self, ground)


## interact (E, D22): the nearest NPC within design.settlement.npc.interact-radius wins over ground items.
func interact_nearest() -> bool:
	return PlayerInventory.interact_nearest(self)


func talk_nearest() -> bool:
	return PlayerInventory.talk_nearest(self)


## pick-up (E): the nearest ground item within design.loot.ground.pickup-radius.
func pick_up_nearest() -> bool:
	return PlayerInventory.pick_up_nearest(self)


func _nearest_in_group(group: StringName, radius: float) -> Node3D:
	return PlayerInventory._nearest_in_group(self, group, radius)


## class trainer (skill-tree, D22): every spent point back to the bank for respec-fee-per-level × level copper.
func respec() -> bool:
	return PlayerInventory.respec(self)


## innkeeper (D22): full heal, the respawn point moves here. ponytail: no time skip (no game clock yet).
func rest() -> void:
	PlayerInventory.rest(self)


## consumable: heal (consumable-heal) and spend one. ponytail: instant, no sit/channel time.
func use_item(it) -> bool:
	return PlayerInventory.use_item(self, it)


## quick-item (Q): the first consumable stack. ponytail: no quick-select wheel yet.
func use_quick() -> bool:
	return PlayerInventory.use_quick(self)


func _physics_process(dt: float) -> void:
	PlayerMotion._physics_process(self, dt, PUSH_DECAY)


## design.movement.fall-damage: % of max HP per block beyond the free height.
## Preserve normal movement except when a far-away Vector3 cannot represent this tick's displacement.
func _apply_world_precision(dt: float) -> void:
	PlayerMotion._apply_world_precision(self, dt)


func _precision_axis(
	position: float, speed: float, dt: float, minimum: float, maximum: float, remainder: float
) -> Array:
	return PlayerMotion._precision_axis(position, speed, dt, minimum, maximum, remainder)


## Keep the player center inside the half-open horizontal world; preserve vertical motion.
func _enforce_world_boundary() -> void:
	PlayerMotion._enforce_world_boundary(self)


func _fall_damage(was_airborne: bool) -> void:
	PlayerMotion._fall_damage(self, was_airborne)


func _combat_time_tick(dt: float) -> void:
	PlayerAttacks._combat_time_tick(self, dt)


func _combat_tick(dt: float) -> void:
	PlayerAttacks._combat_tick(self, dt)


func cancel_touch_requests() -> void:
	_charge = -1.0
	blocking = false
	_touch_jump = false
	_motion_remainder_x = 0.0
	_motion_remainder_z = 0.0


func _apply_touch_request(request: Dictionary, dir: Vector3) -> void:
	PlayerAttacks._apply_touch_request(self, request, dir)


## special-attack (M2, D21): charged classes hold to reserve MP (HUD bar pink), release to spend it; instant classes
## press and spend everything. Damage and stun chance grow with the MP spent.
func _special_tick(dt: float) -> void:
	PlayerAttacks._special_tick(self, dt)


## special-attack through the weapon's M2 moveset (D24): the charge fraction scales damage and rolls the stun, the
## moveset adds its own statuses (dagger poison, fist knockdown …).
func _special(charged: float) -> void:
	PlayerAttacks._special(self, charged)


func _front() -> Vector3:
	return PlayerAttacks._front(self)


## Camera aim: the rig carries pitch and yaw, so its forward is where the cursor points (D24 shots, beams).
func aim() -> Vector3:
	return PlayerAttacks.aim(self)


func eye() -> Vector3:
	return PlayerAttacks.eye(self)


## design.movesets entry for a weapon-type (`as` copies another, missing = default). Empty design = tests without items.
func moveset_for(type: StringName) -> Dictionary:
	return PlayerAttacks.moveset_for(self, type, DEFAULT_MOVESET)


## basic-attack through the weapon's M1 moveset (D24). Melee: sphere in front of us (camera yaw); a whiff resets the
## combo (c-combo-reset), a hit adds one (capped per weapon-type) and gives non-mages MP; a `finisher` rolls its
## statuses on every `every`-th landed hit. Shots report back through combat/projectile.gd.
func _swing() -> void:
	PlayerAttacks._swing(self)


## One attack of any moveset kind; returns the hits landed, or -1 while shots are still flying.
func _attack(m: Dictionary, dmg: float, combo_bonus: bool, applies: Array) -> int:
	return PlayerAttacks._attack(self, m, dmg, combo_bonus, applies)


## Where the aim ray lands within `range` (the ray end when it hits nothing).
func _aim_point(range: float) -> Vector3:
	return PlayerAttacks._aim_point(self, range)


## `count` projectiles fanned by `spread` radians around the aim, sharing one attack record (projectile.gd).
func _fire(
	s: Dictionary,
	dmg: float,
	combo_bonus: bool,
	applies: Array,
	from := Vector3.INF,
	attack_type: StringName = Combat.PHYSICAL
) -> Array:
	return PlayerAttacks._fire(self, s, dmg, combo_bonus, applies, from, attack_type)


## A landed attack: +1 combo (capped per weapon-type), the M1 finisher counter, MP for non-mages on basic hits.
func _landed(combo_bonus: bool, committed_weapon: Dictionary = {}) -> void:
	PlayerAttacks._landed(self, combo_bonus, committed_weapon)


## Live entities inside the sphere, nearest first.
func bodies_within(center: Vector3, radius: float) -> Array:
	return PlayerAttacks.bodies_within(self, center, radius)


func nearest_enemy(radius: float) -> Node3D:
	return PlayerAttacks.nearest_enemy(self, radius)


## Live entities take `dmg` after exactly one equipment defence; hit-derived DOT receives this adjusted hit amount.
func _strike(
	center: Vector3,
	radius: float,
	dmg: float,
	combo_bonus: bool,
	applies: Array = [],
	attack_type: StringName = Combat.PHYSICAL,
	target_limit: int = 0,
	contacts: Variant = null,
	continuing: Callable = Callable()
) -> int:
	return PlayerStrikes._strike(
		self,
		HIT_TIERS,
		center,
		radius,
		dmg,
		combo_bonus,
		applies,
		attack_type,
		target_limit,
		contacts,
		continuing
	)


func weapon_attack_type() -> StringName:
	return PlayerAttacks.weapon_attack_type(self)


func ability_attack_type(a) -> StringName:
	return PlayerAttacks.ability_attack_type(self, a)


func _on_died() -> void:
	_motion_remainder_x = 0.0
	_motion_remainder_z = 0.0
	if touch_input != null:
		touch_input.cancel_all()
	velocity = Vector3.ZERO
	if abilities != null:
		abilities.reset()
	_charge = -1.0
	_dodge = {}
	_push = Vector3.ZERO
	blocking = false
	stealth = 0.0
	statuses.clear()
	clear_stars()  # the stun went with the statuses (D25)
	block_power = block_max()
	await get_tree().create_timer(float(combat["death"]["respawn-s"])).timeout
	if relocate.is_valid():
		relocate.call(_spawn_position)
	else:
		set_logical_position(_spawn_position)  # c-no-death-penalty
	hp = max_hp
	stamina = float(cfg["stamina"]["max"])
	combo = 0
	dead = false


func _damage_feedback(blocked: bool, before: float) -> bool:
	if feel != null and not dot_tick:  # D25 feedback; a dot tick floats its number only
		if blocked:
			feel.play(&"block", head())
		elif before > hp:
			feel.play(&"hurt", head(), {"amount": before - hp, "kind": &"hurt"})  # what we actually lost
	return true
