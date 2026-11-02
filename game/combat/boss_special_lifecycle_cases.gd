## Stateless lifecycle cases. The SceneTree owns each real main until release completes.
extends RefCounted
const MAIN := preload("res://game/main.tscn")


static func release(t: SceneTree, main: Node) -> void:
	# Drain deferred saves and real-time feedback before retiring their owning scene.
	await t.process_frame
	await t.create_timer(0.3, true, false, true).timeout
	main.queue_free()
	await main.tree_exited
	await t.process_frame


static func open(t, path: String):
	var main = MAIN.instantiate()
	main.save_path = path
	t.root.add_child(main)
	t.stop(main)
	main.get_node("World").stream_sites()
	t.stop(main)
	return main


static func run(t, boss, p, w, layout, main, id):
	t.arm(boss, p, layout, "charge", 8)
	boss.special.advance(0)
	var old_left: float = boss.incarnation.special.left
	p.set_logical_position([layout.centre[0] + 1000, layout.floor, layout.centre[1]])
	boss._physics_process(0.5)
	t.check(boss.incarnation.special.left == old_left, "inactive simulation pauses special timer")
	t.arm(boss, p, layout, "charge", 8)
	boss.special.advance(0)
	boss.special.advance(1.2)
	boss.special.advance(0)
	t.check(
		boss.incarnation.special.phase == "charge", "zero simulation time cannot finish a charge"
	)
	boss.special.cancel()
	boss.incarnation.special.left = 0
	boss.incarnation.special.recovery = 0
	boss.special.advance(0)
	t.check(boss.incarnation.special.phase == "warning", "new warning before unload")
	var boss_id: String = boss.logical_id
	var path: String = main.save_path
	w.retire_views()
	var saved: Dictionary = w.state_data.sites[id].mobs[boss_id].special
	cancelled(t, saved, "unload cancels without replay")
	t.check(main.save_now(), "boss state saves")
	saved_negatives(t, main, w, p, id, boss_id)
	await release(t, main)
	main = open(t, path)
	w = main.get_node("World")
	boss = w.targeting.live[boss_id]
	cancelled(
		t,
		boss.incarnation.special,
		"cold main restart retains waiting remainder/no offline advance"
	)
	for phase in ["warning", "charge", "cooldown", "ready"]:
		main = await restart_phase(t, main, layout, boss_id, phase)
	return main


static func restart_phase(t, main, layout, boss_id: String, phase: String):
	var w = main.get_node("World")
	var p = main.get_node("Player")
	var boss = w.targeting.live[boss_id]
	t.arm(boss, p, layout, boss.special.kind, 8 if boss.special.kind == "charge" else 3)
	boss.special.advance(0)
	if phase == "charge":
		t.check(boss.special.kind == "charge", "fixed-seed camp exercises real execution restart")
		boss.special.advance(1.2)
	elif phase != "warning":
		boss.special.cancel()
		boss.incarnation.special.phase = phase
		boss.incarnation.special.left = 2.25 if phase == "ready" else 4.25
		boss.incarnation.special.recovery = 0.0 if phase == "ready" else 0.5
	var waiting: Dictionary = boss.incarnation.special.duplicate(true)
	var path: String = main.save_path
	t.check(main.save_now(), "save special lifecycle phase " + phase + str(main.save_data.errors))
	await release(t, main)
	main = open(t, path)
	var restored: Dictionary = main.get_node("World").targeting.live[boss_id].incarnation.special
	if phase in ["warning", "charge"]:
		cancelled(t, restored, "cold restart cancels saved " + phase + ", never replaying impact")
	else:
		t.check(restored == waiting, "waiting " + phase + " exact remainders survive cold restart")
	return main


static func cancelled(t, saved: Dictionary, label: String) -> void:
	t.check(saved.phase == "cooldown" and saved.left == 10 and saved.recovery == 0.8, label)
	t.check(
		saved.origin == [] and saved.endpoint == [] and saved.target == "",
		label + " clears snapshot"
	)


static func saved_negatives(t, main, w, p, id: String, boss_id: String) -> void:
	var data: Dictionary = main.save_data.capture(w.state_data, p)
	t.check(main.save_data.validate(data), "unmodified captured special save admitted")
	for field in ["phase", "left", "recovery", "origin", "endpoint", "target", "engaged"]:
		var bad := data.duplicate(true)
		bad.world.sites[id].mobs[boss_id].special.erase(field)
		t.check(not main.save_data.validate(bad), "missing saved special " + field + " rejected")
		for value in [null, [], {}, "bad", true, INF, -1]:
			saved_value(t, main, data, [id, boss_id, field], value)


static func saved_value(t, main, data: Dictionary, keys: Array, value) -> void:
	var field: String = keys[2]
	if field in ["origin", "endpoint"] and value is Array:
		return
	if field == "engaged" and value is bool:
		return
	var bad := data.duplicate(true)
	bad.world.sites[keys[0]].mobs[keys[1]].special[field] = value
	t.check(
		not main.save_data.validate(bad),
		"malformed saved special " + field + str(value) + " rejected"
	)
