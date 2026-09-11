## player-character (§3.2) movement + §3.3 basic attack, combo, fall damage, death/respawn, class abilities on keys 1-4,
## MP + M2 special attack (D21) + §3.4 inventory, gear (main-hand damage, armor sum), pick-up (E), quick item (Q)
## + §3.5 XP, level-up, skill points (D19), skill tree spending, swim speed per point (D20).
## + D22: E talks to the nearest NPC (vendor → `talked`, trainer respec, inn rest) before picking up.
## + D23 defence (design.defence): M3 dodge roll with i-frames, M2-held block with block-power, the stealth bar, and
##   creature hits stunning / knocking us back (statuses tick here too).
## Config dicts (design.movement / camera / combat / crit) are injected by main.gd: this script never
## names OntologyDB so headless tests (no autoloads) can drive it.
## + D24 movesets (design.movesets): M1 / M2 per main-hand weapon-type — melee sphere variants, projectiles
##   (combat/projectile.gd), beams and at-cursor bursts along the camera aim.
## ponytail: no climb/glide yet; dodge has no crit window, stealth ignores darkness (todo_implement.md).
extends "res://game/entities/entity.gd"

const Combat := preload("res://game/combat/combat.gd")
const Projectile := preload("res://game/combat/projectile.gd")
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
signal talked(npc: Node)                                # E at an NPC (D22); panels listen for vendor roles
signal notice(text: String)                             # HUD toast

var cfg: Dictionary = {}                                # design.movement
var combat: Dictionary = {}                             # design.combat
var crit: Dictionary = {}                               # design.crit
var weapon: Dictionary = {}                             # {type, damage, combo_cap}, derived from the main-hand item
const DEFAULT_MOVESET := {"m1": {"kind": "melee"}, "m2": {"kind": "melee"}}
var moveset: Dictionary = DEFAULT_MOVESET               # design.movesets entry of the main-hand weapon-type (D24)
var _m1_hits := 0                                       # landed M1 hits in a row (melee finisher counter)
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
var ui_open := false                                    # a panel owns the mouse: no moving, fighting or talking
var stamina := 100.0
var _stamina_idle := 0.0
var _swing_t := 0.0
var _combo_t := 0.0
var _charge := -1.0                                     # M2 charge in MP; < 0 = not charging
var spec: StringName = &""                              # specialization id (passives decide dodge rewards, guardian block)
var defence: Dictionary = {}                            # design.defence (D23)
var block_power := 0.0
var blocking := false
var stealth := 0.0                                      # 0..1 bar
var _dodge: Dictionary = {}                             # {"dir", "left"} while rolling
var _iframes := 0.0
var _dodge_cd := 0.0
var _push := Vector3.ZERO                               # knockback carried across ticks (input rewrites velocity.x/z)
var _hit_stealth := 0.0                                 # stealth the last _strike was thrown at (MP bonus reads it)
const PUSH_DECAY := 30.0                                # ponytail: blocks/s² a knockback fades at; make it a design key if it needs tuning
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
	spec = spec_id; defence = design.get("defence", {})
	block_power = block_max()
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
		moveset = moveset_for(main.subtype)
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

## D23: a dodge ignores the hit, a front block (design.defence.block) cuts it, spends block-power and gives MP;
## then buffs (bulwark) make us stun-immune and mana-shield absorbs first (D21).
func take_damage(amount: float, from: Node) -> void:
	if _iframes > 0.0:
		return
	if blocks_from(from):
		var bl: Dictionary = defence["block"]
		amount *= 1.0 - float(bl["damage-reduction"])
		block_power = maxf(0.0, block_power - float(bl["power-per-hit"]))
		mp = minf(float(design["resources"]["mp"]["max"]), mp + float(bl["mp-per-block"]))   # D11 block-reward
	if abilities != null:
		amount = abilities.absorb(amount * abilities.mult("damage-taken-mult"))
	super.take_damage(amount, from)

## Dodged or blocked hits carry no status (D23); knockback goes through _push so input does not erase it next tick.
func apply_status(id: StringName, cfg: Dictionary, hit: float, from: Node) -> void:
	if _iframes > 0.0 or blocks_from(from):
		return
	if StringName(str(cfg.get("as", id))) == &"knockback":
		var d: Vector3 = global_position - (from as Node3D).global_position; d.y = 0.0
		_push = d.normalized() * float(cfg["impulse"]); velocity.y += float(cfg["impulse"]) * 0.25
		return
	super.apply_status(id, cfg, hit, from)
	if stunned():
		_charge = -1.0                                        # stun interrupts charges

func passives() -> Array:
	if o == null or spec == &"":
		return []
	var s = o.specs[spec]
	return s.passives_a + s.passives_s

func _cyclone() -> bool:
	return abilities != null and not abilities.channel.is_empty() and abilities.channel["a"].id == &"cyclone"

## block: a shield in the off-hand, any weapon as guardian (barricade), or during cyclone.
func can_block() -> bool:
	if defence.is_empty():
		return false
	var off = inventory.equipment.get(&"off-hand") if inventory != null else null
	return _cyclone() or passives().has(&"barricade") or (off != null and off.subtype == &"shield")

func block_max() -> float:
	if defence.is_empty():
		return 0.0
	return float(defence["block"]["max"]) * (float(defence["block"]["guardian-mult"]) if passives().has(&"barricade") else 1.0)

## Is this attacker's hit blocked: blocking, and it stands in the front cone (every direction during cyclone).
func blocks_from(from: Node) -> bool:
	if not blocking or not from is Node3D or from == self:
		return false
	if _cyclone():
		return true
	var d: Vector3 = (from as Node3D).global_position - global_position; d.y = 0.0
	return d.normalized().dot(Basis(Vector3.UP, rig.rotation.y) * Vector3.FORWARD) >= float(defence["block"]["front-dot"])

## dodge (M3 while moving, c-dodge-cost): roll `dir`, i-frames, stamina; passives reward it (elusiveness MP, way-of-the-shadows stealth).
func dodge(dir: Vector3) -> bool:
	var dg: Dictionary = defence["dodge"]
	if dir == Vector3.ZERO or not _dodge.is_empty() or _dodge_cd > 0.0 or blocking or stunned() or stamina < float(dg["stamina"]) or (abilities != null and abilities.busy()):
		return false
	stamina -= float(dg["stamina"]); _stamina_idle = 0.0
	_dodge = {"dir": dir, "left": float(dg["duration-s"])}
	_iframes = float(dg["iframe-s"]); _dodge_cd = float(dg["cooldown-s"]) + float(dg["duration-s"])
	for id in dg["on-dodge"]:
		if passives().has(StringName(id)):
			mp = minf(float(design["resources"]["mp"]["max"]), mp + float(dg["on-dodge"][id].get("mp", 0)))
			stealth = minf(1.0, stealth + float(dg["on-dodge"][id].get("stealth", 0)))
	return true

## Per tick: dodge timers, the block state + block-power regen, the stealth bar (design.defence).
func _defence_tick(dt: float, dir: Vector3, still: bool) -> void:
	_iframes -= dt; _dodge_cd -= dt
	if not _dodge.is_empty():
		_dodge["left"] -= dt
		if _dodge["left"] <= 0.0:
			_dodge = {}
	if Input.is_action_just_pressed("dodge"):
		dodge(dir)
	var bl: Dictionary = defence["block"]
	var cyc := _cyclone()
	blocking = can_block() and block_power > 0.0 and (cyc or (Input.is_action_pressed("special-attack") and not stunned()))
	if not blocking or cyc:
		block_power = minf(block_max(), block_power + float(bl["regen-per-s"]) * (float(bl["cyclone-regen-mult"]) if cyc else 1.0) * dt)
	var sl: Dictionary = defence["stealth"]
	if abilities != null and abilities.flag("stealth-full"):
		stealth = 1.0
	else:
		var gen: float = (abilities.add("stealth-per-s") if abilities != null else 0.0) * (float(sl["still-mult"]) if still else 1.0)
		stealth = clampf(stealth + (gen if gen > 0.0 else -float(sl["decay-per-s"])) * dt, 0.0, 1.0)

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

## interact (E, D22): the nearest NPC within design.settlement.npc.interact-radius wins over ground items.
func interact_nearest() -> bool:
	var npc := _nearest_in_group("npcs", float(design["settlement"]["npc"]["interact-radius"]))
	if npc == null:
		return pick_up_nearest()
	match npc.role:
		&"class-trainer": respec()
		&"innkeeper": rest()
		_: talked.emit(npc)
	return true

## pick-up (E): the nearest ground item within design.loot.ground.pickup-radius.
func pick_up_nearest() -> bool:
	var best := _nearest_in_group("ground-items", float(design["loot"]["ground"]["pickup-radius"]))
	if best == null:
		return false
	pick_up(best)
	return true

func _nearest_in_group(group: StringName, radius: float) -> Node3D:
	var best: Node3D
	for n in get_tree().get_nodes_in_group(group):
		var d: float = n.global_position.distance_to(global_position)
		if d <= radius and not n.is_queued_for_deletion():
			best = n; radius = d
	return best

## class trainer (skill-tree, D22): every spent point back to the bank for respec-fee-per-level × level copper.
func respec() -> bool:
	var fee := int(design["settlement"]["trainer"]["respec-fee-per-level"]) * level
	if skill_tree.points.is_empty():
		notice.emit("Nothing to respec"); return false
	if inventory.coins < fee:
		notice.emit("A respec costs %d copper" % fee); return false
	inventory.coins -= fee
	var n: int = skill_tree.respec()
	skill_points += n
	skills_changed.emit(); inventory.changed.emit()
	notice.emit("Respec: %d points refunded for %d copper" % [n, fee])
	return true

## innkeeper (D22): full heal, the respawn point moves here. ponytail: no time skip (no game clock yet).
func rest() -> void:
	var inn: Dictionary = design["settlement"]["inn"]
	if inn["heal"]:
		hp = max_hp; stamina = float(cfg["stamina"]["max"])
	if inn["sets-spawn"]:
		spawn_point = global_position
	notice.emit("Rested at the inn; you will respawn here")

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
	if cfg.is_empty() or dead or ui_open or not ground_ready.call(global_position):
		return
	var g := float(cfg["gravity"])
	tick_statuses(dt)
	var input := Vector2.ZERO if stunned() else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (Basis(Vector3.UP, rig.rotation.y) * Vector3(input.x, 0, input.y)).normalized()
	if not defence.is_empty():
		_defence_tick(dt, dir, input == Vector2.ZERO)
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
	if blocking and not _cyclone():
		speed *= float(defence["block"]["move-mult"])
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
	if not _dodge.is_empty():
		var roll: Vector3 = _dodge["dir"] * float(defence["dodge"]["distance"]) / float(defence["dodge"]["duration-s"])
		velocity.x = roll.x; velocity.z = roll.z
		_fall_from = -INF                                   # the roll's landing does no fall damage
	velocity.x += _push.x; velocity.z += _push.z
	_push = _push.move_toward(Vector3.ZERO, PUSH_DECAY * dt)
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
		if Input.is_action_just_pressed("interact"):
			interact_nearest()
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
	if stunned():                                           # D23: cannot act (abilities and cooldowns still tick)
		_charge = -1.0
		return
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

## special-attack through the weapon's M2 moveset (D24): the charge fraction scales damage and rolls the stun, the
## moveset adds its own statuses (dagger poison, fist knockdown …).
func _special(charged: float) -> void:
	var sp: Dictionary = design["special-attack"]
	var f := charged / float(design["resources"]["mp"]["max"])
	mp -= charged
	var m: Dictionary = moveset["m2"]
	var applies: Array = m.get("applies", []).duplicate()
	if _rng.randf() < f * float(sp["stun-chance-at-full"]):
		applies.append(&"stun")
	_attack(m, float(weapon["damage"]) * (1.0 + f * (float(sp["damage-mult-at-full"]) - 1.0)), false, applies)

func _front() -> Vector3:
	var ba: Dictionary = combat["basic-attack"]
	return global_position + Vector3.UP + (Basis(Vector3.UP, rig.rotation.y) * Vector3.FORWARD) * float(ba["reach"]) * 0.6

## Camera aim: the rig carries pitch and yaw, so its forward is where the cursor points (D24 shots, beams).
func aim() -> Vector3:
	return -rig.global_transform.basis.z

func eye() -> Vector3:
	return global_position + Vector3.UP * rig.position.y

## design.movesets entry for a weapon-type (`as` copies another, missing = default). Empty design = tests without items.
func moveset_for(type: StringName) -> Dictionary:
	var mv: Dictionary = design.get("movesets", {})
	var m: Dictionary = mv.get(type, mv.get("default", DEFAULT_MOVESET))
	return mv[m["as"]] if m.has("as") else m

## basic-attack through the weapon's M1 moveset (D24). Melee: sphere in front of us (camera yaw); a whiff resets the
## combo (c-combo-reset), a hit adds one (capped per weapon-type) and gives non-mages MP; a `finisher` rolls its
## statuses on every `every`-th landed hit. Shots report back through combat/projectile.gd.
func _swing() -> void:
	var ba: Dictionary = combat["basic-attack"]
	var m: Dictionary = moveset["m1"]
	_swing_t = float(ba["swing-s"]) * float(m.get("swing-mult", 1.0)) * (abilities.mult("swing-mult") if abilities != null else 1.0)
	var applies: Array = m.get("applies", []).duplicate()
	if m.has("finisher"):
		var fin: Dictionary = m["finisher"]
		if (_m1_hits + 1) % int(fin["every"]) == 0 and _rng.randf() < float(fin["chance"]):
			applies.append_array(fin["applies"])
	var hits := _attack(m, float(weapon["damage"]), true, applies)
	if hits == 0:
		_m1_hits = 0

## One attack of any moveset kind; returns the hits landed, or -1 while shots are still flying.
func _attack(m: Dictionary, dmg: float, combo_bonus: bool, applies: Array) -> int:
	var ba: Dictionary = combat["basic-attack"]
	dmg *= float(m.get("damage-mult", 1.0))
	var hits := 0
	match str(m.get("kind", "melee")):
		"projectile":
			_fire(m, dmg, combo_bonus, applies)
			return -1
		"beam", "at-cursor":
			hits = _strike(_aim_point(float(m["range"])), float(m["radius"]), dmg, combo_bonus, applies)
		_:
			var lunge := float(m.get("lunge", 0.0))
			if lunge > 0.0:
				move_and_collide((Basis(Vector3.UP, rig.rotation.y) * Vector3.FORWARD) * lunge)   # ponytail: instant lunge, no animation
			var center: Vector3 = global_position + Vector3.UP if m.get("around", false) else _front()
			hits = _strike(center, float(ba["hit-radius"]) * float(m.get("radius-mult", 1.0)), dmg, combo_bonus, applies)
	if hits > 0:
		_landed(combo_bonus)
	else:
		combo = 0                                             # c-combo-reset
	return hits

## Where the aim ray lands within `range` (the ray end when it hits nothing).
func _aim_point(range: float) -> Vector3:
	var from := eye()
	var q := PhysicsRayQueryParameters3D.create(from, from + aim() * range, 0xFFFFFFFF, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	return hit["position"] if not hit.is_empty() else from + aim() * range

## `count` projectiles fanned by `spread` radians around the aim, sharing one attack record (projectile.gd).
func _fire(s: Dictionary, dmg: float, combo_bonus: bool, applies: Array, from := Vector3.INF) -> Array:
	if from == Vector3.INF:
		from = eye()
	var count := int(s.get("count", 1))
	var attack := {"hits": 0, "live": count}
	var out: Array = []
	for i in count:
		var pr := Projectile.new()
		pr.shooter = self; pr.shot = s; pr.dmg = dmg; pr.combo_bonus = combo_bonus; pr.applies = applies; pr.attack = attack
		pr.vel = aim().rotated(Vector3.UP, float(s.get("spread", 0.0)) * (i - (count - 1) / 2.0)) * float(s["speed"])
		get_parent().add_child(pr)
		pr.global_position = from
		out.append(pr)
	return out

## A landed attack: +1 combo (capped per weapon-type), the M1 finisher counter, MP for non-mages on basic hits.
func _landed(combo_bonus: bool) -> void:
	combo = mini(combo + 1, int(weapon["combo_cap"]))
	_combo_t = float(combat["combo"]["expire-s"])
	if not combo_bonus:
		return
	_m1_hits += 1
	if abilities != null and not mp_passive:
		var bonus := 1.0 + _hit_stealth * float(defence["stealth"]["mp-mult-at-full"]) if not defence.is_empty() else 1.0
		mp = minf(float(design["resources"]["mp"]["max"]), mp + float(design["resources"]["mp"]["per-hit"]) * bonus)

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

## Every live entity inside the sphere takes `dmg` (buffs, crit, stealth, armor); the combo bonus only for the basic attack;
## `applies` = status-effect ids the hit carries (design.status-effects decides what they do). A landed hit spends the
## stealth bar unless a stealth-full buff pins it (D23).
func _strike(center: Vector3, radius: float, dmg: float, combo_bonus: bool, applies: Array = []) -> int:
	var hits := 0
	var chance: float = crit_chance + (abilities.add("crit-add") if abilities != null else 0.0)
	var se: Dictionary = design.get("status-effects", {})
	_hit_stealth = stealth
	if not defence.is_empty():
		var sl: Dictionary = defence["stealth"]
		dmg *= 1.0 + stealth * float(sl["attack-mult-at-full"]); chance += stealth * float(sl["crit-add-at-full"])
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
	if hits > 0 and not (abilities != null and abilities.flag("stealth-full")):
		stealth = 0.0
	return hits

func _on_died() -> void:
	velocity = Vector3.ZERO
	if abilities != null:
		abilities.reset()
	_charge = -1.0; _dodge = {}; _push = Vector3.ZERO; blocking = false; stealth = 0.0; statuses.clear()
	block_power = block_max()
	await get_tree().create_timer(float(combat["death"]["respawn-s"])).timeout
	global_position = spawn_point                            # c-no-death-penalty
	hp = max_hp; stamina = float(cfg["stamina"]["max"]); combo = 0
	dead = false
