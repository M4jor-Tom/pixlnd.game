## Headless ontology check: `godot --headless -s ontology/validate.gd` (run from repo root
## from the repo root, no project.godot needed; toolchain: `nix develop`).
## Exits non-zero when instances violate domain.md §5 load-time constraints.
extends SceneTree

const Model := preload("res://ontology/model.gd")  # preload: class_name needs a project.godot, this does not

func _init() -> void:
	var o := Model.Ontology.load_dir("res://ontology/instances")
	var ok := o.validate()
	print("ontology: %d races, %d classes, %d specs, %d abilities, %d weapon types, %d materials, %d creatures, %d pet foods, %d landscapes, %d rulesets" % [
		o.races.size(), o.classes.size(), o.specs.size(), o.abilities.size(), o.weapon_types.size(),
		o.materials.size(), o.creatures.size(), o.pet_foods.size(), o.landscapes.size(), o.rulesets.size()])
	for e in o.errors:
		printerr("  ✗ ", e)
	print("ontology valid" if ok and o.errors.is_empty() else "ontology INVALID (%d errors)" % o.errors.size())
	quit(0 if o.errors.is_empty() else 1)
