## Real screen events -> native widgets -> owned, unbuffered Android requests.
extends SceneTree
const Model := preload("res://ontology/model.gd")
var failed := 0
var a


func check(ok: bool, what: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", what)


func touch(id: int, pos: Vector2, down: bool, canceled := false) -> void:
	var e := InputEventScreenTouch.new()
	e.index = id
	e.position = pos
	e.pressed = down
	e.canceled = canceled
	a.handle_touch(e)


func drag(id: int, pos: Vector2, delta: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = id
	e.position = pos
	e.relative = delta
	a.handle_touch(e)


func _init() -> void:
	run.call_deferred()


func run() -> void:
	check(
		ResourceLoader.exists("res://game/meta/android_touch.gd"), "native Android adapter exists"
	)
	if failed:
		quit(1)
		return
	a = load("res://game/meta/android_touch.gd").new()
	root.add_child(a)
	var o = Model.Ontology.load_dir("res://ontology/instances")
	a.setup(o.configs["controller-profiles"]["android"], null, null, null, null)
	a.set_layout(Rect2(20, 10, 1240, 700), Vector2.ONE)
	await process_frame
	var center: Vector2 = a.stick_rect.get_center()
	var r: float = a.stick_rect.size.x / 2
	touch(0, center, true)
	drag(0, center + Vector2(r * .15, 0), Vector2(r * .15, 0))
	check(a.take_frame()["move"] == Vector2.ZERO, "inclusive .15R boundary neutral")
	drag(0, center + Vector2(r * .1501, 0), Vector2(.0001 * r, 0))
	check(
		a.take_frame()["move"].is_equal_approx(Vector2.RIGHT),
		"outside threshold full walking direction"
	)
	drag(0, center + Vector2(r * .6, -r * .6), Vector2.ZERO)
	check(
		a.take_frame()["move"].is_equal_approx(Vector2(1, -1).normalized()), "diagonal normalized"
	)
	var basic: Vector2 = a.targets["basic-attack"].get_center()
	touch(1, basic, true)
	check(a.buttons["basic-attack"].is_pressed(), "native TouchScreenButton actually pressed")
	var look := Vector2(850, 200)
	touch(2, look, true)
	drag(2, look + Vector2(20, -10), Vector2(20, -10))
	var frame: Dictionary = a.take_frame()
	check(
		(
			frame["move"].length() > .99
			and frame["look"] == Vector2(20, -10)
			and frame["requests"].size() == 1
		),
		"three simultaneous independent streams"
	)
	check(a.take_frame()["requests"].is_empty(), "triggers drained, not repeated")
	touch(3, basic, true)
	touch(1, basic, false)
	drag(3, basic, Vector2.ZERO)
	check(a.take_frame()["requests"].is_empty(), "occupied extra finger cannot take over")
	touch(3, basic, false)
	touch(4, a.targets["special-attack"].get_center(), true)
	drag(4, look, Vector2.ZERO)
	drag(4, a.targets["special-attack"].get_center(), Vector2.ZERO)
	touch(4, a.targets["special-attack"].get_center(), false)
	frame = a.take_frame()
	check(
		(
			not frame["held"].get("special-attack", false)
			and frame["requests"].all(func(q): return q.phase != "release")
		),
		"slide out/back cancels special without normal completion"
	)
	check(not a.buttons["special-attack"].is_pressed(), "canceled native button reset")
	var sp: Vector2 = a.targets["special-attack"].get_center()
	touch(4, sp, true)
	touch(4, sp, false)
	frame = a.take_frame()
	check(
		(
			frame["requests"].size() == 2
			and frame["requests"][0].phase == "start"
			and frame["requests"][1].phase == "release"
		),
		"normal inside release distinct from cancel"
	)
	touch(5, sp, true)
	touch(5, sp, false, true)
	check(
		a.take_frame()["requests"].all(func(q): return q.phase != "release"),
		"OS canceled release never fires"
	)
	a.cancel_all()
	frame = a.take_frame()
	check(
		(
			frame["move"] == Vector2.ZERO
			and frame["look"] == Vector2.ZERO
			and frame["requests"].is_empty()
			and frame["held"].is_empty()
		),
		"interruption clears all unfinished state"
	)
	drag(0, center + Vector2(r, 0), Vector2(r, 0))
	check(a.take_frame()["move"] == Vector2.ZERO, "late surviving finger cannot resume")
	touch(0, center, false)
	touch(0, center, true)
	drag(0, center + Vector2(r, 0), Vector2(r, 0))
	check(a.take_frame()["move"].length() > .99, "fresh touch works after interruption")
	a._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(a.take_frame()["move"] == Vector2.ZERO, "focus loss cancels")
	for safe in [
		Rect2(40, 0, 1200, 720),
		Rect2(0, 0, 1200, 720),
		Rect2(80, 0, 1840, 1080),
		Rect2(0, 0, 960, 540)
	]:
		a.set_layout(safe, Vector2.ONE)
		for key in a.targets:
			var rect: Rect2 = a.targets[key]
			check(
				safe.encloses(rect) and rect.size.x >= 48 and rect.size.y >= 48,
				"safe minimum target " + key
			)
			for other in a.targets:
				if other != key:
					check(not rect.intersects(a.targets[other]), "no overlap " + key + "/" + other)
	# Root input propagation (the production _input path), not only adapter calls.
	a.set_layout(Rect2(0, 0, 960, 540), Vector2.ONE)
	var event := InputEventScreenTouch.new()
	event.index = 20
	event.position = a.targets["basic-attack"].get_center()
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	check(
		a.buttons["basic-attack"].is_pressed() and a.take_frame()["requests"].size() == 1,
		"real root screen event reaches native widget once"
	)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	for notification in [
		Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT
	]:
		touch(21, a.targets["special-attack"].get_center(), true)
		a._notification(notification)
		check(
			a.take_frame()["requests"].is_empty() and not a.buttons["special-attack"].is_pressed(),
			"lifecycle cancellation " + str(notification)
		)
		touch(21, Vector2.ZERO, false)
	a.set_layout(Rect2(0, 0, 960, 540), Vector2(.5, .75))
	for rect in a.targets.values():
		check(
			rect.size.x / .5 >= 48 and rect.size.y / .75 >= 48 and a.safe.encloses(rect),
			"nonuniform viewport dp scaling"
		)
	for canceled in [false, true]:
		a.set_layout(Rect2(0, 0, 960, 540), Vector2.ONE)
		basic = a.targets["basic-attack"].get_center()
		sp = a.targets["special-attack"].get_center()
		touch(30, basic, true)
		touch(31, sp, true)
		a.take_frame()
		a.set_layout(Rect2(), Vector2.ONE)
		touch(30, basic, false, canceled)
		touch(32, basic, true)
		drag(31, sp, Vector2.ONE)
		frame = a.take_frame()
		check(
			(
				frame["requests"].is_empty()
				and frame["held"].is_empty()
				and not a.buttons["special-attack"].is_pressed()
			),
			"invalid layout accepts no gameplay or native completion"
		)
		a.set_layout(Rect2(0, 0, 960, 540), Vector2.ONE)
		touch(31, sp, true)
		drag(31, sp, Vector2.ONE)
		drag(32, basic, Vector2.ONE)
		touch(32, basic, false)
		check(
			a.take_frame()["requests"].is_empty() and not a.buttons["special-attack"].is_pressed(),
			"still-held and invalid-layout touches cannot rearm or transfer"
		)
		touch(30, basic, true)
		frame = a.take_frame()
		check(
			(
				frame["requests"].size() == 1
				and frame["requests"][0].action == "basic-attack"
				and a.buttons["basic-attack"].is_pressed()
			),
			(
				"fresh same-index touch works after invalid-layout terminal release (canceled=%s)"
				% canceled
			)
		)
		touch(30, basic, false)
		touch(31, sp, false)
		touch(31, sp, true)
		check(
			a.take_frame()["held"].get("special-attack", false),
			"held tombstone ends only after physical release and fresh touch"
		)
		touch(31, sp, false, true)
		a.take_frame()
	for notification in [
		Node.NOTIFICATION_APPLICATION_FOCUS_OUT,
		Node.NOTIFICATION_APPLICATION_PAUSED,
		Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT
	]:
		touch(40, basic, true)
		a.take_frame()
		a._notification(notification)
		drag(40, basic, Vector2.ONE)
		check(
			a.take_frame()["requests"].is_empty() and not a.buttons["basic-attack"].is_pressed(),
			"F1 ended OS stream ignores old drag"
		)
		# No old up is delivered: this down belongs to the new OS touch stream.
		touch(40, basic, true)
		check(
			a.take_frame()["requests"].size() == 1 and a.buttons["basic-attack"].is_pressed(),
			"F1 fresh same-index down after ended OS stream " + str(notification)
		)
		touch(41, basic, true)
		check(a.take_frame()["requests"].is_empty(), "F1 extra finger on fresh owner ignored")
		touch(40, basic, false)
		drag(41, basic, Vector2.ONE)
		check(
			a.take_frame()["requests"].is_empty() and not a.buttons["basic-attack"].is_pressed(),
			"F1 occupied extra finger never transfers"
		)
		touch(41, basic, false)
	a.set_layout(Rect2(0, 0, 2500, 720), Vector2(4, 1))
	check(
		a._layout_valid and a.stick_rect.size.x / 4 >= 48 and a.stick_rect.size.y >= 48,
		"F5 joystick minimum dp on both axes"
	)
	check(
		(
			a.safe.encloses(a.stick_rect)
			and a.targets.values().all(func(rect): return not rect.intersects(a.stick_rect))
		),
		"F5 joystick safe and nonoverlapping"
	)
	center = a.stick_rect.get_center()
	r = a.stick_rect.size.x / 2
	touch(42, center, true)
	drag(42, center + Vector2(r * .6, 0), Vector2(r * .6, 0))
	check(
		a.take_frame()["move"].is_equal_approx(Vector2.RIGHT),
		"F5 resized native joystick still moves"
	)
	touch(42, center, false)
	a.back()
	check(a.take_frame()["requests"].is_empty(), "Back without panel consumed")
	a.free()
	print("android touch ok" if failed == 0 else "android touch FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
