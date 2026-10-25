## Matched once-localized/live native action controls; actual player callbacks and current design only.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const PLAYER := preload("res://game/entities/player.tscn")
const Frame := preload("res://game/world/local_frame.gd")
const Items := preload("res://game/items/items.gd")
const Item := preload("res://game/items/item.gd")
const Feel := preload("res://game/combat/feel.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
var failed := 0


class Preparation:
	extends Node
	var p
	var live := true
	var calls := 0
	var jump_at := -1
	var jump_release := -1
	var jump_height := 0.0
	var jump_record: Dictionary = {}

	func _physics_process(_dt: float) -> void:
		calls += 1
		if calls == jump_at:
			jump_record = {
				"frame": Engine.get_physics_frames(),
				"floor": p.is_on_floor(),
				"position": p.logical_position(),
				"velocity": p.velocity,
				"dodge": p._dodge.duplicate(),
				"origin": p.frame.origin.duplicate()
			}
			Input.action_press("jump")
		if calls == jump_release:
			Input.action_release("jump")
		jump_height = maxf(jump_height, p.position.y)
		if live:
			p.frame.prepare(p)


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var d: Dictionary = o.configs.generators.design
	InputMapBuilder.build(o.configs.keybinds.hybrid)
	var results: Array = []
	for anchor in [[63.5, 0.0, 63.5], [8380415.5, 0.0, -8380416.5], [-8380416.5, 0.0, 8380415.5]]:
		for live in [false, true]:
			var space := SubViewport.new()
			space.own_world_3d = true
			root.add_child(space)
			var frame := Frame.new(int(d.terrain["zone-blocks"]))
			frame.set_origin(anchor)
			var floor_ := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(512, 1, 512)
			cs.shape = box
			floor_.add_child(cs)
			floor_.position = Vector3(0, -0.5, 0)
			space.add_child(floor_)
			frame.track(floor_)
			var p = PLAYER.instantiate()
			space.add_child(p)
			p.setup(d.movement, d.camera, &"normal")
			p.setup_combat(d.combat, d.crit, {}, 100)
			p.setup_items(o, d, &"mage", &"fire-mage")
			p.skill_tree.points[&"teleport"] = 5
			frame.place_entity(p, anchor, true)
			var prep := Preparation.new()
			prep.p = p
			prep.live = live
			prep.process_physics_priority = -1
			space.add_child(prep)
			for i in 20:
				await physics_frame
			var before: Array = p.logical_position()
			p.get_node("CameraRig").rotation.y = -PI / 2
			p.mp = 100
			check(p.use_class_skill(3), "actual Teleport dash accepted")
			var cooldown: float = p.abilities.cooldowns[&"teleport"]
			check(
				(
					p.mp == 0
					and is_equal_approx(cooldown, 10 * p.skill_tree.cooldown_mult(&"teleport"))
				),
				"cost/cooldown unchanged"
			)
			for i in 60:
				await physics_frame
			var after: Array = p.logical_position()
			check(
				absf(float(after[0]) - before[0] - 20.0) < 0.1 and p.abilities.dash.is_empty(),
				"live/once far Teleport retains existing20-block distance"
			)
			check(not live or frame.transactions > 0, "actual committed dash crosses frame")
			# Continuous movement modes cross/reverse the same active frame without new inputs/cost rules.
			Input.action_press("move_forward")
			Input.action_press("sprint")
			var stamina: float = p.stamina
			for i in 60:
				await physics_frame
			Input.action_release("sprint")
			Input.action_release("move_forward")
			check(p.stamina < stamina, "sprint retains ordinary stamina drain")
			var hp: float = p.hp
			check(p.dodge(Vector3.LEFT), "committed dodge accepted")
			for i in 30:
				await physics_frame
			check(
				p.hp == hp and p._dodge.is_empty(),
				"frame crossing does not add dodge damage or extend duration"
			)
			prep.jump_height = 0.0
			prep.jump_at = prep.calls + 1
			prep.jump_release = prep.calls + 16
			for i in 18:
				await physics_frame
			check(prep.jump_height > 0.5, "scheduled native jump remains physical")
			for i in 70:
				await physics_frame
			p.water_top = 1000.0
			Input.action_press("move_forward")
			for i in 30:
				await physics_frame
			Input.action_release("move_forward")
			p.water_top = -INF
			var holder := Node3D.new()
			space.add_child(holder)
			frame.track(holder)
			var rng := RandomNumberGenerator.new()
			rng.seed = 1
			var coins: int = p.inventory.coins
			Items.spawn_drops(holder, p.global_position, [Item.stack(&"coin", &"", 5)], rng, o, d)
			var feel := Feel.new()
			holder.add_child(feel)
			feel.setup(d.feel)
			feel.frame = frame
			var label = feel.number(p.head(), 17)
			var number_position: Array = frame.to_logical(label.global_position)
			frame.shift_to([frame.origin[0] + 64, frame.origin[1]])
			for i in 4:
				await physics_frame
			check(
				p.inventory.coins == coins + 5,
				"Area pickup remains exactly once through frame translations"
			)
			var raised: Array = frame.to_logical(label.global_position)
			check(
				(
					raised[0] == number_position[0]
					and raised[2] == number_position[2]
					and raised[1] > number_position[1]
				),
				"floating number tween changes only Y across frame translations"
			)
			results.append(
				{
					"anchor": anchor,
					"live": live,
					"logical": p.logical_position(),
					"stamina": p.stamina,
					"mp": p.mp,
					"hp": p.hp,
					"cooldown": p.abilities.cooldowns[&"teleport"],
					"callbacks": prep.calls,
					"transactions": frame.transactions,
					"jump": prep.jump_record,
					"jump_height": prep.jump_height
				}
			)
			space.free()
	print("action frame controls ", results)
	print("local frame actions ok" if not failed else "local frame actions FAILED")
	quit(0 if not failed else 1)
