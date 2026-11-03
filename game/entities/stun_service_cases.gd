## Stun/death admission at real service endpoints; owning test retains its live fixture.
extends RefCounted
const NPC := preload("res://game/entities/npc.gd")


static func service(t, mode: String, role: StringName, keyboard: bool) -> void:
	await t.fixture()
	t.world.state_data.sites[t.supplier_id].completed = false
	var npc := NPC.new(role, str(role), Color.BLUE)
	npc.position = Vector3(1.5, 0, 0)
	if role == &"captive":
		npc.set_meta("encounter_site", t.supplier_id)
	t.root.add_child(npc)
	t.check(t.p._nearest_in_group("npcs", 3.0) == npc, "precondition: real service target " + role)
	t.reject_state(mode)
	var before: Dictionary = t.snapshot()
	if keyboard:
		await t.key_frame("interact")
	else:
		t.check(not t.p.talk_nearest(), mode + " direct Talk rejects " + role)
	t.check(
		t.snapshot() == before, mode + " service unchanged " + role + " keyboard=" + str(keyboard)
	)
	t.p.dead = false
	t.p.statuses.clear()
	t.p.inventory.coins = 100
	t.p.skill_tree.points = {&"smash": 1}
	t.p.skill_points = 0
	t.p.hp = 50.0
	t.p.spawn_point = Vector3(9, 0, 9)
	t.world.state_data.sites[t.supplier_id].completed = false
	t.shop_panel._open(false)
	await t.key_frame("interact")
	if not _service_result(t, role):
		return
	npc.free()
	t.cleanup()


static func _service_result(t, role: StringName) -> bool:
	match role:
		&"item-vendor":
			return _vendor_result(t)
		&"class-trainer":
			return _trainer_result(t)
		&"innkeeper":
			return _inn_result(t)
		&"captive":
			t.check(
				t.world.state_data.sites[t.supplier_id].completed and t.signals.talk > 0,
				"fresh E completes cleared rescue"
			)
	return true


static func _trainer_result(t) -> bool:
	t.check(
		(
			t.p.inventory.coins == 95
			and t.p.skill_tree.points.is_empty()
			and t.p.skill_points == 1
			and t.signals.skills > 0
		),
		"fresh E respecs at trainer"
	)
	return true


static func _vendor_result(t) -> bool:
	t.check(t.shop_panel._panel.visible and t.signals.talk > 0, "fresh E opens vendor")
	return true


static func _inn_result(t) -> bool:
	t.check(
		t.p.hp == t.p.max_hp and t.p.spawn_point != Vector3(9, 0, 9) and t.signals.notice > 0,
		"fresh E rests at inn"
	)
	return true
