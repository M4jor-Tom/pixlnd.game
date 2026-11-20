## Expected-native-error child: mutation after a successful representation check must not
## let a new predicate's default false continue the original validator's remaining phases.
extends SceneTree
const Domain := preload("res://game/domain/domain.gd")


class MutationSave:
	extends "res://game/world/save_data.gd"
	var site: Dictionary
	var volume: Array
	var mode := ""
	var later := false
	var vendor_count := 0
	var rarity_count := 0
	var item_row: Dictionary
	static var target: Dictionary
	static var armed := false

	static func number(value: Variant, minimum: float = 0) -> bool:
		var result := super.number(value, minimum)
		if armed and value == 137:
			armed = false
			target.max_hp = "bad"
		return result

	func require(ok: bool, path: String) -> bool:
		_mutate_checked_row(path)
		if _later_path(path):
			later = true
		if mode == "supplier" and path == "world.vendor.identity":
			vendor_count += 1
			later = vendor_count > 1
		return super.require(ok, path)

	func position(value: Variant, path: String) -> bool:
		var result := super.position(value, path)
		if mode == "volume" and path == "world.site.volume.max":
			volume[0] = {}
		return result

	func _mutate_checked_row(path: String) -> void:
		match mode:
			"stack":
				_stack_check(path)
			"room":
				if path == "world.site.guard.room_cycle":
					site.cycle = "bad"

	func _stack_check(path: String) -> void:
		if path == "item.rarity":
			rarity_count += 1
			if rarity_count == 2:
				item_row.count = "bad"
		elif path in ["item.stack", "item.power", "item.weapon/material"]:
			later = true

	func _later_path(path: String) -> bool:
		match mode:
			"room":
				return path == "world.site.spirit cardinality"
			"volume":
				return path == "world.vendors"
			"mob":
				return path == "mob.hostility/role"
			"pending":
				return path == "world.site.kill.incarnation cycle"
		return false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or not args[0].is_absolute_path():
		quit(2)
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var o := Domain.Ontology.load_dir()
	var save := MutationSave.new(o, o.configs.generators.design)
	save.mode = args[1]
	var id: String = data.world.sites.keys().filter(func(k): return data.world.sites[k].family == "ruins")[0]
	var site: Dictionary = data.world.sites[id]
	save.site = site
	if not _case(save, data, site):
		quit(2)
		return
	print("BOUNDARY ", save.mode, " later=", save.later)
	quit(0)


func _room(save, data: Dictionary, site: Dictionary) -> void:
	var layout: Dictionary = data.world.lands["0,0"].sites.filter(func(s): return s.family == "ruins")[0]
	var stable: Dictionary = layout.assignments.filter(func(a): return a.spirit != "")[0]
	layout.assignments = [stable]
	var selected: Dictionary = site.mobs[site.id + "/" + stable.key]
	site.mobs = {site.id + "/" + stable.key: selected}
	site.spirit_levels = {stable.key: selected.level}
	stable.boss = false
	selected.room_cycle = site.cycle
	save.validate_site_content(site, layout, float(data.world.clock))


func _case(save, data: Dictionary, site: Dictionary) -> bool:
	match save.mode:
		"room":
			_room(save, data, site)
		"volume":
			data.world.lands = {}
			data.world.sites = {site.id: site}
			save.volume = site.volumes[0]
			save.validate_world(data.world)
		"mob":
			var selected: Dictionary = site.mobs.values()[0]
			selected.max_hp = 137
			selected.hp = 137
			MutationSave.target = selected
			MutationSave.armed = true
			save.validate_mob(selected, "mob")
		"supplier":
			_supplier(save, data)
		"stack":
			_stack(save)
		"pending":
			_pending(save, data)
		_:
			return false
	return true


func _supplier(save, data: Dictionary) -> void:
	var id: String = data.world.sites.keys().filter(func(k): return k.ends_with("supplier/0"))[0]
	data.world.sites[id].completed = "bad"
	data.world.vendors = {
		"0,0/weapon-vendor": {"day": 0, "ceiling": 0, "level": 1, "items": []},
		"0,0/armor-vendor": {"day": 0, "ceiling": 0, "level": 1, "items": []}
	}
	save.validate_vendors(data.world)


func _pending(save, data: Dictionary) -> void:
	var id: String = data.world.sites.keys().filter(func(k): return k.ends_with("supplier/0"))[0]
	var site: Dictionary = data.world.sites[id]
	var layout: Dictionary = data.world.lands["0,0"].sites.filter(func(s): return s.family == "supplier" and s.ordinal == 0)[0]
	var boss: Dictionary = layout.assignments.filter(func(a): return a.boss)[0]
	site.completed = "bad"
	site.cleared = true
	site.rewards = {
		"mission/0":
		{
			"level": site.mobs[id + "/" + boss.key].level,
			"delivered": false,
			"payload": [],
			"classes": [],
			"class_id": ""
		}
	}
	save.validate_rewards(site, layout)


func _stack(save) -> void:
	save.item_row = {
		"type": "weapon",
		"subtype": "sword",
		"material": "iron",
		"rarity": 0,
		"level": 1,
		"upgrade_count": 0,
		"modifier": 0,
		"minus_modifier": 0,
		"count": 1
	}
	var result: bool = save.validate_item(save.item_row, "item")
	print("ITEM_RESULT ", result, " errors=", JSON.stringify(save.errors))
