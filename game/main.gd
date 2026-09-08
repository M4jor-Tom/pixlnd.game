extends Node3D

func _ready() -> void:
	var o: OntologyDB.Model.Ontology = OntologyDB.data
	print("pixlnd: ruleset %s, %d creatures, %d abilities, pvp default %s" % [
		OntologyDB.ruleset.id, o.creatures.size(), o.abilities.size(), OntologyDB.design.get("pvp", {})])
