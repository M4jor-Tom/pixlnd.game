## Every bound instances file loads into the generated classes without diagnostics.
## timeout 300 nix develop -c godot --headless -s game/domain/test_linkml_loader.gd
extends SceneTree

const Loader := preload("res://game/domain/linkml_loader.gd")


func _init() -> void:
	var loader := Loader.new()
	var roots := _load_all(loader)
	var skeleton := _entry(loader.load_file("creatures"), "skeleton")
	var ok: bool = loader.errors.is_empty() and roots == 41 and _skeleton_ok(skeleton)
	for e in loader.errors.slice(0, 20):
		printerr("  ✗ ", e)
	print("linkml loader: %d roots, %d errors" % [roots, loader.errors.size()])
	print("LINKML_LOADER_OK" if ok else "LINKML_LOADER FAILED")
	quit(0 if ok else 1)


func _load_all(loader: Loader) -> int:
	var roots := 0
	for file in DirAccess.get_files_at(Loader.INSTANCES):
		if file.ends_with(".json") and loader.load_file(file.get_basename()) is Object:
			roots += 1
	return roots


func _entry(root: Object, key: String) -> Object:
	for entry in root.slot_entries:
		if entry.slot_key == key:
			return entry.slot_value
	return null


func _skeleton_ok(skeleton: Object) -> bool:
	if skeleton == null:
		return false
	var typed: bool = typeof(skeleton.slot_aid) == TYPE_INT and skeleton.slot_aid == 17
	return typed and skeleton.slot_cat == "undead" and skeleton.slot_lands.has("graveyards")
