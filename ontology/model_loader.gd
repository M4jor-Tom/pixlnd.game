## Catalog-family ingestion dispatch. The facade retains raw storage and public constructors.
extends RefCounted
const Identity := preload("res://ontology/model_loader_identity.gd")
const Equipment := preload("res://ontology/model_loader_equipment.gd")
const World := preload("res://ontology/model_loader_world.gd")
const Items := preload("res://ontology/model_loader_items.gd")


static func ingest(
	o, name: String, data: Dictionary, types: Dictionary, vocabulary: Dictionary
) -> void:
	if name in ["races", "classes", "specializations", "abilities"]:
		identity(o, name, data, types, vocabulary)
	elif name in ["weapon-types", "materials", "rarities"]:
		equipment(o, name, data, types, vocabulary)
	elif name in ["creatures", "pet-food", "landscapes", "status-effects"]:
		world(o, name, data, types, vocabulary)
	else:
		items(o, name, data, types, vocabulary)


static func identity(
	o, name: String, data: Dictionary, types: Dictionary, vocabulary: Dictionary
) -> void:
	match name:
		"races":
			Identity.races(o, name, data, types, vocabulary)
		"classes":
			Identity.classes(o, name, data, types, vocabulary)
		"specializations":
			Identity.specializations(o, name, data, types, vocabulary)
		"abilities":
			Identity.abilities(o, name, data, types, vocabulary)


static func equipment(
	o, name: String, data: Dictionary, types: Dictionary, vocabulary: Dictionary
) -> void:
	match name:
		"weapon-types":
			Equipment.weapon_types(o, name, data, types, vocabulary)
		"materials":
			Equipment.materials(o, name, data, types, vocabulary)
		"rarities":
			Equipment.rarities(o, name, data, types, vocabulary)


static func world(
	o, name: String, data: Dictionary, types: Dictionary, vocabulary: Dictionary
) -> void:
	match name:
		"creatures":
			World.creatures(o, name, data, types, vocabulary)
		"pet-food":
			World.pet_food(o, name, data, types, vocabulary)
		"landscapes":
			World.landscapes(o, name, data, types, vocabulary)
		"status-effects":
			World.status_effects(o, name, data, types, vocabulary)


static func items(
	o, name: String, data: Dictionary, types: Dictionary, vocabulary: Dictionary
) -> void:
	match name:
		"consumables":
			Items.consumables(o, name, data, types, vocabulary)
		"key-items":
			Items.key_items(o, name, data, types, vocabulary)
		"rulesets":
			Items.rulesets(o, name, data, types, vocabulary)
