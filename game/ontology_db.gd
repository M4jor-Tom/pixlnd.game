## Autoload `OntologyDB`: the ontology, loaded once, read-only.
## Catalog rows are generated LinkML objects (game/domain/domain.gd); everything else (ui,
## keybinds, generators…) is raw in `data.configs[<file>]`. Instances are validated before the
## game runs (scripts/ontology_bind.py); a load diagnostic still refuses to boot.
## Runtime state never lives here (see game/README.md).
extends Node

# preload, not class_name: the class cache only exists after an editor scan, headless CI has none
const Domain := preload("res://game/domain/domain.gd")

var data: Domain.Ontology
var ruleset: Object  # the default ruleset row (hybrid, D1)
var design: Dictionary  # generators.json#design: owner-designed tunables (D6/D11)
var _flags := {}


func _load_ontology() -> Domain.Ontology:  # test seam: fail-closed fixtures override it
	return Domain.Ontology.load_dir()


func _ready() -> void:
	data = _load_ontology()
	ruleset = data.default_ruleset()
	if not data.errors.is_empty() or ruleset == null:
		for e in data.errors:
			push_error("ontology: " + e)
		if ruleset == null:
			push_error("ontology: no default ruleset")
		get_tree().quit(1)
		return
	_flags = Domain.flags(ruleset)
	design = data.configs.get("generators", {}).get("design", {})


func flag(name: String, default: Variant = false) -> Variant:
	return _flags.get(name, default)
