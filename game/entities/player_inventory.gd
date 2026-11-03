## Item, progression and service operations; Player owns all state and public callbacks.
extends RefCounted

const Combat := preload("res://game/combat/combat.gd")
const Abilities := preload("res://game/combat/abilities.gd")
const Model := preload("res://ontology/model.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Inventory := preload("res://game/items/inventory.gd")
const Progression := preload("res://game/progression/progression.gd")
const SkillTree := preload("res://game/progression/skill_tree.gd")


static func setup_items(
	p, p_o, p_design: Dictionary, class_id: StringName = &"warrior", spec_id: StringName = &""
) -> void:
	p.o = p_o
	p.design = p_design
	var cls = p.o.classes[class_id]
	if spec_id == &"":
		spec_id = cls.specializations[0]  # c-spec-of-class: start as spec index 0
	p.spec = spec_id
	p.defence = p.design.get("defence", {})
	p.block_power = p.block_max()
	p.skill_tree = SkillTree.new(p.o, p.design["skill-point"], class_id, spec_id)
	p.abilities = Abilities.new(p, p.design["abilities"])
	p.special_mode = cls.special_attack_mode
	p.mp_passive = "passive" in str(cls.raw.get("mp-generation", []))
	p.prog = p.design["progression"]
	p.hp_mult = cls.hp_mult
	p.inventory = Inventory.new(p.o, p.design, class_id, func(): return p.level)
	var start: Dictionary = p.design["starting-inventory"]
	var starter: Dictionary = p.combat["starter-weapon"]
	var wt = p.o.weapon_types[cls.weapon_types[0]]
	var first := Items.generate(
		p._rng,
		&"weapon",
		wt.id,
		Items.weapon_material(wt),
		int(starter["level"]),
		int(starter["rarity"])
	)
	p.inventory.add(first)
	p.inventory.equip(first)
	for c in start["consumables"]:
		p.inventory.add(Item.stack(&"consumable", StringName(c), int(start["consumables"][c])))
	p.inventory.coins = int(start["coins"])
	p.inventory.changed.connect(p._refresh_gear)
	p._refresh_gear()
	p.hp = p.max_hp  # initialization alone starts full, including starter gear


static func _refresh_gear(p) -> void:
	var main = p.inventory.equipment.get(&"main-hand")
	p.weapon = {}
	p.moveset = {}
	if main == null:
		p._charge = -1.0
	if main != null:
		var wt = p.o.weapon_types[main.subtype]
		p.weapon = {
			"type": main.subtype,
			"damage": Items.damage(main, p.o) * float(p.combat["attack-power-mult"]),
			"combo_cap": wt.combo_cap if wt.combo_cap > 0 else int(p.combat["combo"]["default-cap"])
		}
		p.moveset = p.moveset_for(main.subtype)
	p.armor = 0.0
	p.resistance = 0.0
	p.max_hp = p._base_max_hp
	for slot in p.inventory.equipment:
		p.armor += Items.armor(p.inventory.equipment[slot], p.o)
		p.resistance += Items.resistance(p.inventory.equipment[slot], p.o)
		p.max_hp += Items.hp(p.inventory.equipment[slot], p.o)
	p.hp = minf(p.hp, p.max_hp)  # gear changes never heal or revive
	if not p.can_block():
		p.blocking = false  # removing the last eligible item ends its stance immediately


static func on_kill(p, creature_level: int) -> void:
	if p.prog.is_empty():  # tests that skip setup_items
		return
	p.gain_xp(Model.xp_for_kill(creature_level, p.level, p.prog))


static func gain_xp(p, amount: int) -> void:
	var s := Progression.settle(p.level, p.xp + amount)
	p.xp = s["xp"]
	if s["gained"] == 0:
		return
	p.level = s["level"]
	p.skill_points += s["gained"] * Model.SKILL_POINTS_PER_LEVEL
	p._base_max_hp = Combat.player_max_hp(p.level, p.hp_mult)
	p._refresh_gear()
	if p.prog["heal-on-level-up"]:
		p.hp = p.max_hp
	p.leveled_up.emit(p.level)
	p.skills_changed.emit()
	if p.feel != null:
		p.feel.play(&"level-up")


static func spend_skill(p, a) -> void:
	p.skill_points = p.skill_tree.spend(a, p.skill_points)
	p.skills_changed.emit()


static func use_class_skill(p, slot: int) -> bool:
	if p.skill_tree == null:
		return false
	var a = p.skill_tree.class_slot(slot)
	return a != null and p.skill_tree.spent(a.id) > 0 and p.abilities.use(a)


static func item_label(p, it) -> String:
	return Items.item_name(it, p.o, p.design)


static func pick_up(p, ground: Node3D) -> void:
	if ground.is_queued_for_deletion():
		return
	p.inventory.add(ground.item)
	p.picked_up.emit(ground.label)
	if p.feel != null:
		p.feel.play(&"coin" if ground.label.ends_with("copper") else &"pickup")
	ground.queue_free()


static func interact_nearest(p) -> bool:
	return p.talk_nearest() or p.pick_up_nearest()


static func talk_nearest(p) -> bool:
	if p.dead or p.stunned():
		return false
	var npc: Node3D = p._nearest_in_group(
		"npcs", float(p.design["settlement"]["npc"]["interact-radius"])
	)
	if npc == null:
		return false
	match npc.role:
		&"class-trainer":
			p.respec()
		&"innkeeper":
			p.rest()
		_:
			p.talked.emit(npc)
	return true


static func pick_up_nearest(p) -> bool:
	if p.dead or p.stunned():
		return false
	var best: Node3D = p._nearest_in_group(
		"ground-items", float(p.design["loot"]["ground"]["pickup-radius"])
	)
	if best == null:
		return false
	p.pick_up(best)
	return true


static func _nearest_in_group(p, group: StringName, radius: float) -> Node3D:
	var best: Node3D
	for n in p.get_tree().get_nodes_in_group(group):
		var d: float = n.global_position.distance_to(p.global_position)
		if d <= radius and not n.is_queued_for_deletion():
			best = n
			radius = d
	return best


static func respec(p) -> bool:
	var fee: int = int(p.design["settlement"]["trainer"]["respec-fee-per-level"]) * p.level
	if p.skill_tree.points.is_empty():
		p.notice.emit("Nothing to respec")
		return false
	if p.inventory.coins < fee:
		p.notice.emit("A respec costs %d copper" % fee)
		return false
	p.inventory.coins -= fee
	var n: int = p.skill_tree.respec()
	p.skill_points += n
	p.skills_changed.emit()
	p.inventory.changed.emit()
	p.notice.emit("Respec: %d points refunded for %d copper" % [n, fee])
	return true


static func rest(p) -> void:
	var inn: Dictionary = p.design["settlement"]["inn"]
	if inn["heal"]:
		p.hp = p.max_hp
		p.stamina = float(p.cfg["stamina"]["max"])
	if inn["sets-spawn"]:
		p._spawn_position = p.logical_position()
	p.notice.emit("Rested at the inn; you will respawn here")


static func use_item(p, it) -> bool:
	if p.dead or p.stunned():
		return false
	p.hp = minf(p.max_hp, p.hp + Items.heal(it, p.o))
	p.inventory.remove(it)
	return true


static func use_quick(p) -> bool:
	var it = p.inventory.first_consumable()
	return false if it == null else p.use_item(it)
