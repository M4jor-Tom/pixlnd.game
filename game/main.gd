extends Node3D

const Model := preload("res://ontology/model.gd")
const InputMapBuilder := preload("res://game/meta/input_map.gd")
const Combat := preload("res://game/combat/combat.gd")
const InventoryPanel := preload("res://game/items/inventory_panel.gd")
const SkillPanel := preload("res://game/progression/skill_panel.gd")
const ShopPanel := preload("res://game/items/shop_panel.gd")
const AndroidTouch := preload("res://game/meta/android_touch.gd")
const Feel := preload("res://game/combat/feel.gd")
const WorldState := preload("res://game/world/world_state.gd")
const SaveData := preload("res://game/world/save_data.gd")
const LocalFrame := preload("res://game/world/local_frame.gd")
const WorldMap := preload("res://game/world/world_map.gd")

@export var save_path := "user://world.json"
var frame
var state_data
var save_data
var _hero: Node3D
var _world: Node3D
var _saving := false
var _started := false


func _ready() -> void:
	var db := get_node("/root/OntologyDB")
	var o: Model.Ontology = db.data
	var design: Dictionary = db.design
	if not OS.has_feature("android"):
		InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var world := $World
	var player := $Player
	_hero = player
	_world = world
	frame = LocalFrame.new(int(design.terrain["zone-blocks"]))
	set_meta("local_frame", frame)
	world.frame = frame
	player.frame = frame
	player.relocate = relocate_player
	process_physics_priority = -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-path="):
			save_path = arg.trim_prefix("--save-path=")
	save_data = SaveData.new(o, design)
	var loaded := {}
	if FileAccess.file_exists(save_path):
		loaded = save_data.load_file(save_path)
		if loaded.is_empty():
			printerr("Save rejected; original untouched: ", save_data.errors)
			get_tree().quit(1)
			return
	var world_seed: int = int(design.terrain["seed-default"])
	state_data = WorldState.new(design, world_seed)
	if not loaded.is_empty():
		state_data.restore(loaded.world)
	# Character creation/import UI is separate. Only a genuinely fresh save receives the starting kit.
	var class_id := &"warrior"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--class=") and o.classes.has(arg.trim_prefix("--class=")):
			class_id = StringName(arg.trim_prefix("--class="))
	if not loaded.is_empty():
		class_id = StringName(loaded.character.class_id)
	var cls: Model.CharacterClass = o.classes[class_id]
	player.setup(design["movement"], design["camera"], o.races["human"].size_class)
	player.setup_combat(
		design["combat"], design["crit"], {}, Combat.player_max_hp(player.level, cls.hp_mult)
	)
	player.setup_items(
		o, design, cls.id, StringName(loaded.character.spec) if not loaded.is_empty() else &""
	)  # starting inventory → weapon / armor
	player.logical_id = Crypto.new().generate_random_bytes(16).hex_encode()
	world.target = player
	world.configure(o, design, state_data, connected_party)
	world.generation_failed.connect(
		func(diagnostic):
			printerr(diagnostic)
			get_tree().quit(1)
	)
	player.targeting = world.targeting
	var feel := Feel.new()
	add_child(feel)  # D25: juice spawns beside us, in world space
	feel.setup(design["feel"], player.get_node("CameraRig"))
	player.feel = feel
	feel.frame = frame
	var panel: CanvasLayer = InventoryPanel.new()
	add_child(panel)
	var skills: CanvasLayer = SkillPanel.new()
	add_child(skills)
	var shop: CanvasLayer = ShopPanel.new()
	add_child(shop)
	var touch: Node = null
	if OS.has_feature("android"):
		touch = AndroidTouch.new()
		add_child(touch)
		touch.setup(o.configs["controller-profiles"]["android"], player, panel, skills, shop)
	panel.bind(player, touch)
	skills.bind(player, touch)
	shop.bind(player, world, touch)
	player.talked.connect(world.on_talked)
	if touch != null:
		touch.set_layout(touch.safe, touch.pixels_per_dp)
	player.water_top = world.gen.sea_level + 1.0
	player.ground_ready = world.has_ground
	var edge := float(world.gen.land_min * world.gen.land_blocks)
	player.world_min = Vector2(edge, edge)
	player.world_max = Vector2(-edge, -edge)
	var map := WorldMap.new()
	add_child(map)
	map.bind(player, touch)
	# Joint generation guarantees the real village square, including an all-sea dry hub.
	var mid: int = world.gen.land_blocks / 2
	var village: Dictionary = world.gen.village_at(world.gen.land_at(Vector2i.ZERO))
	if village.is_empty():
		printerr("\n".join(world.gen.diagnostics))
		get_tree().quit(1)
		return
	var sq: Vector2i = village.centre
	if loaded.is_empty():
		var spawn := [sq.x + 0.5, village.height + 2.0, sq.y + 0.5]
		frame.set_origin(spawn)
		frame.place_entity(player, spawn, true)
		player.set_logical_respawn(spawn)
	else:
		frame.set_origin(loaded.world.characters[loaded.character.id].position)
		save_data.restore_player(player, loaded.character, loaded.world)
	if not world.ensure_land(
		world.gen.land_of_block(
			floori(float(player.logical_position()[0])), floori(float(player.logical_position()[2]))
		)
	):
		return
	player.inventory.changed.connect(request_save)
	player.skills_changed.connect(request_save)
	player.died.connect(request_save)
	world.state_changed.connect(request_save)
	_started = true
	get_tree().auto_accept_quit = false
	if loaded.is_empty():
		request_save()
	$HUD.bind(player, world)
	if touch != null:
		$HUD.bind_touch(touch)
	var land = world.gen.land_of_block(mid, mid)
	var equipped := (
		"unarmed"
		if player.weapon.is_empty()
		else "%s dmg %.0f" % [player.weapon["type"], player.weapon["damage"]]
	)
	print(
		(
			"pixlnd: ruleset %s, %d creatures, %d abilities; seed %d, land '%s' (%s, %s), village '%s'; %s, hp %.0f, level %d"
			% [
				db.ruleset.id,
				o.creatures.size(),
				o.abilities.size(),
				world.world_seed,
				land.name,
				land.landscape,
				land.danger_tier,
				village.get("name", "-"),
				equipped,
				player.max_hp,
				player.level
			]
		)
	)


## A bound lookup, not a captured Node: a departed character is absent, never an invalid lambda capture.
func connected_party() -> Array:
	return [_hero] if is_instance_valid(_hero) else []


## Lifecycle/meaningful state transitions only: no wall-clock autosave cadence or crash-recovery promise.
func request_save() -> void:
	if not _started or _saving:
		return
	_saving = true
	call_deferred("_save_deferred")


func _save_deferred() -> void:
	_saving = false
	if not save_now():
		printerr("Save failed; original untouched: ", save_data.errors)
		get_tree().quit(1)


func save_now() -> bool:
	if not _started:
		return true
	_world.capture_mobs()
	return save_data.write_atomic(save_path, save_data.capture(state_data, _hero))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit(0 if save_now() else 1)


func _exit_tree() -> void:
	# Includes engine --quit/--quit-after and test-driven graceful shutdown.
	if _started and is_instance_valid(_hero) and is_instance_valid(_world):
		if not save_now():
			printerr("Shutdown save failed: ", save_data.errors)
			get_tree().quit(1)


## Complete native-frame preparation precedes World, Targeting and every automatic actor callback.
func _physics_process(_dt: float) -> void:
	if _started:
		frame.prepare(_hero)


func relocate_player(point: Array) -> void:
	_world.retire_views()
	frame.set_origin(point)
	frame.place_entity(_hero, point, true)
