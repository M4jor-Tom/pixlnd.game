## Autoload `OntologyDB`: the ontology, loaded once, read-only.
## Typed entries come from ontology/model.gd; everything else (ui, keybinds, generators…) is in
## `data.configs[<file>]`. Runtime state never lives here (see game/README.md).
extends Node

# preload, not class_name: the class cache only exists after an editor scan, headless CI has none
const Model := preload("res://ontology/model.gd")

var data: Model.Ontology
var ruleset: Model.Ruleset  # the default ruleset (hybrid, D1)
var design: Dictionary  # generators.json#design: owner-designed tunables (D6/D11)


func _load_ontology() -> Model.Ontology:
	return Model.Ontology.load_dir("res://ontology/instances")


func _ready() -> void:
	data = _load_ontology()
	var ok := data.validate()
	if not ok or not data.errors.is_empty():
		_reject_ontology()
		return
	if not _select_ruleset():
		return
	design = data.configs.get("generators", {}).get("design", {})


func _reject_ontology() -> void:
	if data.errors.is_empty():
		push_error("ontology: validation failed without diagnostics")
	for e in data.errors:
		push_error("ontology: " + e)
	get_tree().quit(1)


func _select_ruleset() -> bool:
	for r in data.rulesets.values():
		if r.is_default:
			ruleset = r
	return true


func flag(name: String, default: Variant = false) -> Variant:
	return ruleset.flags.get(name, default)
