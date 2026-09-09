extends Node3D

const InputMapBuilder := preload("res://game/meta/input_map.gd")
const Combat := preload("res://game/combat/combat.gd")
const InventoryPanel := preload("res://game/items/inventory_panel.gd")
const SkillPanel := preload("res://game/progression/skill_panel.gd")

func _ready() -> void:
	var o: OntologyDB.Model.Ontology = OntologyDB.data
	var design: Dictionary = OntologyDB.design
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var world := $World; var player := $Player
	world.target = player
	world.design = design; world.creatures = o.creatures
	world.rosters = o.configs["creature-families"]["landscape-rosters"]
	world.ontology = o
	# ponytail: every hero is a level-1 human warrior until character creation (player-character) lands
	var cls: OntologyDB.Model.CharacterClass = o.classes["warrior"]
	player.setup(design["movement"], design["camera"], o.races["human"].size_class)
	player.setup_combat(design["combat"], design["crit"], {}, Combat.player_max_hp(player.level, cls.hp_mult))
	player.setup_items(o, design, cls.id)                  # starting inventory → weapon / armor
	var panel: CanvasLayer = InventoryPanel.new(); add_child(panel); panel.bind(player)
	var skills: CanvasLayer = SkillPanel.new(); add_child(skills); skills.bind(player)
	player.water_top = world.gen.sea_level + 1.0
	player.ground_ready = world.has_ground
	# ponytail: spawn at the centre of land (0,0); world.spawn-rule (near village) comes with settlements
	var mid: int = world.gen.land_blocks / 2
	player.position = Vector3(mid, world.gen.height_at(mid, mid) + 2.0, mid)
	player.spawn_point = player.position
	$HUD.bind(player, world)
	var land = world.gen.land_of_block(mid, mid)
	print("pixlnd: ruleset %s, %d creatures, %d abilities; seed %d, land '%s' (%s, %s); %s dmg %.0f, hp %.0f, level %d" % [
		OntologyDB.ruleset.id, o.creatures.size(), o.abilities.size(), world.world_seed, land.name, land.landscape, land.danger_tier,
		player.weapon["type"], player.weapon["damage"], player.max_hp, player.level])
