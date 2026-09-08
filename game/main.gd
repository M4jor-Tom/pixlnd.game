extends Node3D

const InputMapBuilder := preload("res://game/meta/input_map.gd")

func _ready() -> void:
	var o: OntologyDB.Model.Ontology = OntologyDB.data
	InputMapBuilder.build(o.configs["keybinds"]["hybrid"])
	var world := $World; var player := $Player
	world.target = player
	world.spawns = OntologyDB.design["spawns"]; world.creatures = o.creatures
	world.rosters = o.configs["creature-families"]["landscape-rosters"]
	player.setup(OntologyDB.design["movement"], OntologyDB.design["camera"], o.races["human"].size_class)
	player.water_top = world.gen.sea_level + 1.0
	player.ground_ready = world.has_ground
	# ponytail: spawn at the centre of land (0,0); world.spawn-rule (near village) comes with settlements
	var mid: int = world.gen.land_blocks / 2
	player.position = Vector3(mid, world.gen.height_at(mid, mid) + 2.0, mid)
	var land = world.gen.land_of_block(mid, mid)
	print("pixlnd: ruleset %s, %d creatures, %d abilities; seed %d, land '%s' (%s)" % [
		OntologyDB.ruleset.id, o.creatures.size(), o.abilities.size(), world.world_seed, land.name, land.landscape])
