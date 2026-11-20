extends SceneTree
const State := preload("res://game/world/world_state.gd")
const Domain := preload("res://game/domain/domain.gd")
var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	var o = Domain.Ontology.load_dir()
	var d: Dictionary = o.configs.generators.design
	var s = State.new(d, 26879)
	check(s.clock == 7 * 3600, "fresh 07:00")
	check(s.world_id != State.new(d, 26879).world_id, "same seed independent saved identity")
	_clock_cases(s, d)
	print("encounter clock ok" if failed == 0 else "encounter clock FAILED %d" % failed)
	quit(0 if failed == 0 else 1)


func _receipt_callbacks(s, id: String, site: Dictionary) -> void:
	var observed: Array = []
	s.changed.connect(func(): observed.append(site.rewards.duplicate(true)))
	var payload := [{"count": 1}]
	check(s.issue_reward(id, "kill/0/probe", payload), "first receipt issues")
	check(
		observed == [{"kill/0/probe": {"payload": [{"count": 1}], "delivered": false}}],
		"receipt exists before synchronous changed callback"
	)
	payload[0].count = 9
	check(site.rewards["kill/0/probe"].payload == [{"count": 1}], "receipt owns copied payload")
	check(not s.issue_reward(id, "kill/0/probe", []), "duplicate receipt does not issue")
	check(observed.size() == 1, "duplicate receipt does not notify")


func _rescue_completion(s, refreshed: Array, completed: Array) -> void:
	var r: String = s.site_id(Vector2i.ZERO, "supplier", 0)
	var rescue: Dictionary = s.register_site(r, "supplier", [[0, 0, 0, 2, 2, 2]])
	rescue.pending = true
	rescue.cleared = true
	s.complete_on_exit = func(key):
		if key == r:
			rescue.completed = true
			completed.append(key)
	s.advance(0, [])
	check(
		completed.has(r) and not refreshed.has(r) and not rescue.pending,
		"rescue completion before refresh; one-time stays clear"
	)


func _restore_clock(s, d: Dictionary, id: String) -> void:
	var before: float = s.clock
	var restored = State.new(d, 26879)
	restored.restore(s.snapshot())
	check(restored.clock == before, "restore never uses wall time")
	check(restored.site_id(Vector2i.ZERO, "ruins", 0) == id, "stable saved site identity")


func _clock_cases(s, d: Dictionary) -> void:
	var id: String = s.site_id(Vector2i.ZERO, "ruins", 0)
	var site: Dictionary = s.register_site(id, "ruins", [[0, 0, 0, 2, 2, 2], [4, 0, 0, 6, 2, 2]])
	site.mobs = {"guard": {"dead": true, "level": 1}, "survivor": {"dead": false, "level": 2}}
	var refreshed: Array = []
	var completed: Array = []
	var refresh_entry: Array = []
	s.refresh_site = func(key):
		refreshed.append(key)
		return true
	s.complete_on_exit = func(key): completed.append(key)
	s.clock = 86400 - 1
	s.advance(0.1, [Vector3(2, 2, 2)])
	check(site.pending and refreshed.is_empty(), "closed corner occupied at midnight")
	s.advance(86400 / 10.0 * 3, [Vector3(0, 1, 1), Vector3(7, 1, 1)])
	check(
		site.pending and refreshed.is_empty(), "all players outside required; missed days coalesce"
	)
	_safe_refresh(s, site, refreshed, refresh_entry, id)
	_rescue_completion(s, refreshed, completed)
	_restore_clock(s, d, id)
	_receipt_callbacks(s, id, site)


func _safe_refresh(s, site: Dictionary, refreshed: Array, refresh_entry: Array, id: String) -> void:
	s.refresh_site = func(_key): return false
	s.advance(0, [])
	check(site.pending, "unavailable generation context does not consume pending renewal")
	s.refresh_site = func(key):
		refresh_entry.append([site.pending, site.cycle])
		refreshed.append(key)
		return true
	s.advance(0, [Vector3(3, 1, 1)])
	check(refresh_entry == [[true, 0]] and site.cycle == 1, "cycle commits after refresh returns")
	check(not site.pending and refreshed == [id], "gap outside union; one safe refresh no grace")
	check(
		site.mobs.survivor.level == 2 and not site.mobs.survivor.dead,
		"clock does not touch survivor"
	)
	check(site.mobs.guard.dead, "site owner alone materializes new incarnation")
