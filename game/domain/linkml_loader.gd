## Fills the generated LinkML classes (game/generated/domain) from bound instances JSON
## (game/generated/instances, written by scripts/ontology_bind.py, which already validated it).
## Keys route through each class's linkml_keys(), JSON numbers recover their primitive through
## linkml_scalar_types(), nested objects and typed collections follow the property type hints.
## Needs the global class cache: run `godot --headless --import` once on a fresh checkout.
extends RefCounted

const INSTANCES := "res://game/generated/instances/"

var errors: PackedStringArray = []
var _paths := {}  # global class name → script path
var _probes := {}  # union alternative class name → an empty instance, for its key/type maps


func _init() -> void:
	for c in ProjectSettings.get_global_class_list():
		_paths[c["class"]] = c["path"]


## Bound `<name>.json` as its `LinkML<Name>Source` object; unmodeled files stay raw data.
func load_file(name: String) -> Variant:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(INSTANCES + name + ".json"))
	if data == null:
		errors.append("%s: missing or unparsable bound instances file" % name)
		return null
	var cls := "LinkML%sSource" % "".join(Array(name.split("-")).map(_pascal))
	return fill(_new(cls), data, name) if _paths.has(cls) else data


func fill(obj: Object, data: Variant, path: String) -> Object:
	if not data is Dictionary:
		errors.append("%s: expected an object" % path)
		return obj
	var props := {}
	for p in obj.get_property_list():
		props[p["name"]] = p
	var keys: Dictionary = obj.linkml_keys()
	for key in data:
		var at := "%s.%s" % [path, key]
		if keys.has(key):
			_assign(obj, keys[key], props[keys[key]], data[key], at)
		elif "linkml_extra_slots" in obj:
			obj.linkml_extra_slots[key] = data[key]
		else:
			errors.append(at + ": key not in the schema")
	return obj


func _assign(obj: Object, field: String, prop: Dictionary, v: Variant, path: String) -> void:
	if v == null:
		return  # absent: keep the generated null / empty default
	match prop["type"]:
		TYPE_OBJECT:
			obj.set(field, fill(_new(prop["class_name"]), v, path))
		TYPE_ARRAY:
			_append_all(obj.get(field), prop["hint_string"], v, path)
		TYPE_DICTIONARY:
			_put_all(obj.get(field), prop["hint_string"].get_slice(";", 1), v, path)
		_:
			obj.set(field, _element(_scalar_type(obj, field, v, path), v, path))


## Declared primitive of a Variant field, or the union alternative an object value belongs to.
func _scalar_type(obj: Object, field: String, v: Variant, path: String) -> String:
	var unions: Dictionary = obj.linkml_union_classes()
	if v is Dictionary and unions.has(field):
		return _pick(unions[field], v, path)
	return obj.linkml_scalar_types().get(field, "")


func _append_all(out: Array, type_name: String, values: Array, path: String) -> void:
	for i in range(values.size()):
		out.append(_element(type_name, values[i], "%s[%d]" % [path, i]))


func _put_all(out: Dictionary, type_name: String, values: Dictionary, path: String) -> void:
	for k in values:
		out[k] = _element(type_name, values[k], "%s.%s" % [path, k])


func _element(type_name: String, v: Variant, path: String) -> Variant:
	match type_name:
		"int":
			return int(v)
		"float":
			return float(v)
		"PackedFloat64Array":
			return PackedFloat64Array(v)
		"PackedInt64Array":
			return PackedInt64Array(v)
		"PackedStringArray":
			return PackedStringArray(v)
	return fill(_new(type_name), v, path) if _paths.has(type_name) else v


## First union alternative (schema order) that accepts every key of `value` with its shape.
func _pick(alternatives: Array, value: Dictionary, path: String) -> String:
	for cls in alternatives:
		if _fits(cls, value):
			return cls
	errors.append(
		"%s: no union alternative of %s fits keys %s" % [path, alternatives, value.keys()]
	)
	return ""


## Every key is a field of `cls` (or `cls` takes extra slots), and no object value lands on a
## field declared as a primitive (tells a pair from a pair of pairs).
func _fits(cls: String, value: Dictionary) -> bool:
	if not _probes.has(cls):
		_probes[cls] = _new(cls)
	var probe: Object = _probes[cls]
	return (
		"linkml_extra_slots" in probe
		or value.keys().all(func(k): return _accepts(probe, k, value[k]))
	)


static func _accepts(probe: Object, key: String, v: Variant) -> bool:
	var field: Variant = probe.linkml_keys().get(key)
	return field != null and not (v is Dictionary and probe.linkml_scalar_types().has(field))


func _new(cls: String) -> Object:
	return load(_paths[cls]).new()


static func _pascal(word: String) -> String:
	return word.left(1).to_upper() + word.substr(1)
