extends Node3D

func _ready() -> void:
	$World.target = $FlyCamera
	var o: OntologyDB.Model.Ontology = OntologyDB.data
	var land = $World.gen.land_of_block(0, 0)
	print("pixlnd: ruleset %s, %d creatures, %d abilities; seed %d, origin land '%s' (%s)" % [
		OntologyDB.ruleset.id, o.creatures.size(), o.abilities.size(), $World.world_seed, land.name, land.landscape])
	# ponytail: camera starts above the origin column; world.spawn-rule (near village) comes with settlements
	var mid: int = $World.gen.land_blocks / 2
	$FlyCamera.position = Vector3(mid, $World.gen.height_at(mid, mid) + 60, mid)
