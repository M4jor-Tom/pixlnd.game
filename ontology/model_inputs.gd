## Raw predicates shared by ingestion and validation; never convert or copy caller values.
extends RefCounted

const TYPED_STRINGS := {
	"materials": ["kind"],
	"rarities": ["color", "gem"],
	"creatures": ["family", "cat", "h", "tame", "role"],
	"pet-food": ["tames"],
	"landscapes": ["style"],
	"status-effects": ["kind"],
	"consumables": ["kind", "use", "station"],
	"key-items": ["group"]
}
const TYPED_NUMBERS := {
	"weapon-types": ["subtype", "damage-k", "combo-cap"],
	"materials": ["id"],
	"rarities": ["index", "stars"],
	"creatures": ["aid"],
	"pet-food": ["id"],
	"consumables": ["heal-mult", "duration-s"]
}
# These historical fields already have explicit null handling during typed ingestion.
const NULLABLE_NUMBERS := {
	"weapon-types": ["subtype", "combo-cap"],
	"materials": ["id"],
	"rarities": ["stars"],
	"creatures": ["aid"]
}
const TYPED_ARRAYS := {
	"creatures": ["lands", "drops"],
	"landscapes": ["hazards"],
	"status-effects": ["sources", "countered-by"]
}
const TYPED_BOOLS := {
	"materials": ["obtainable"],
	"rarities": ["named"],
	"creatures": ["ride", "boss", "bossable"],
	"pet-food": ["rideable", "shop"]
}
const TYPED_OBJECTS := {
	"landscapes": ["climate", "gen"], "rulesets": ["flags"], "consumables": ["recipe"]
}


static func object(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func array(value: Variant) -> Array:
	return value if value is Array else []


static func number(value: Variant) -> bool:
	return value is int or value is float


static func finite_number(value: Variant) -> bool:
	return number(value) and is_finite(float(value))


static func integer(value: Variant, minimum: int, maximum: float = INF) -> bool:
	if not finite_number(value):
		return false
	return float(value) == floor(float(value)) and value >= minimum and value <= maximum


static func strings(value: Variant) -> bool:
	if not value is Array:
		return false
	for item in value:
		if not item is String:
			return false
	return true


static func selected_multiplier(value: Variant, selected: float) -> bool:
	if not number(value):
		return false
	var converted := float(value)
	return not is_nan(converted) and not is_inf(converted) and converted == selected


static func matches(o, value: Variant, kind: String) -> bool:
	match kind:
		"object", "catalog":
			return value is Dictionary
		"array":
			return value is Array
		"strings":
			return o._identity_strings(value)
		"string":
			return value is String
		"bool":
			return value is bool
		"number":
			return finite_number(value)
	return structured_shape(o, value, kind)


static func structured_shape(o, value: Variant, kind: String) -> bool:
	match kind:
		"pair":
			return numeric_vector(value, 2, false)
		"colour":
			return numeric_vector(value, 3, true)
		"palette":
			return palette(o, value)
	return false


static func numeric_vector(value: Variant, size: int, colour: bool) -> bool:
	if not value is Array or value.size() != size:
		return false
	var valid := true
	for item in value:
		if not vector_component(item, colour):
			valid = false
	return valid


static func vector_component(value: Variant, colour: bool) -> bool:
	if not finite_number(value):
		return false
	return not colour or (value >= 0 and value <= 1)


static func palette(o, value: Variant) -> bool:
	if not o._identity_strings(value) or value.size() != 2:
		return false
	var valid := true
	for item in value:
		if not Color.html_is_valid(item):
			valid = false
	return valid


static func required_path(o, path: String, kind: String) -> bool:
	var value: Variant = o.configs
	for field in path.split("."):
		value = value.get(field) if value is Dictionary else null
	return o._input_shape(value, kind, path)


# Keep each shape call first: ordinary false continues, while a native error aborts this helper.
static func fields_valid(o, row: Variant, path: String, fields: Dictionary) -> bool:
	if not o._input_shape(row, "object", path):
		return false
	var valid := true
	for kind in fields:
		for field in str(fields[kind]).split(" ", false):
			valid = o._input_shape(row.get(field), kind, path + "." + field) and valid
	return valid


static func optional_fields_valid(o, row: Dictionary, path: String, fields: Dictionary) -> bool:
	var valid := true
	for kind in fields:
		for field in str(fields[kind]).split(" ", false):
			if row.has(field):
				valid = o._input_shape(row[field], kind, path + "." + field) and valid
	return valid


static func typed_fields_valid(o, name: String, row: Dictionary, path: String) -> bool:
	var start: int = o.errors.size()
	typed_strings(o, name, row, path)
	present_fields(o, row, path, TYPED_BOOLS.get(name, []), "bool")
	typed_numbers(o, name, row, path)
	present_fields(o, row, path, TYPED_ARRAYS.get(name, []), "strings")
	if name == "creatures" and row.get("group") != null:
		o._input_shape(row.group, "pair", path + ".group")
	present_fields(o, row, path, TYPED_OBJECTS.get(name, []), "object")
	if name == "rulesets" and row.has("default"):
		o._input_shape(row.default, "bool", path + ".default")
	return o.errors.size() == start


static func typed_strings(o, name: String, row: Dictionary, path: String) -> void:
	for field in TYPED_STRINGS.get(name, []):
		if row.has(field) and row[field] != null:
			o._input_shape(row[field], "string", path + "." + field)


static func typed_numbers(o, name: String, row: Dictionary, path: String) -> void:
	for field in TYPED_NUMBERS.get(name, []):
		if row.has(field):
			if row[field] == null and field in NULLABLE_NUMBERS.get(name, []):
				continue
			o._input_shape(row[field], "number", path + "." + field)


static func present_fields(o, row: Dictionary, path: String, fields: Array, kind: String) -> void:
	for field in fields:
		if row.has(field):
			o._input_shape(row[field], kind, path + "." + field)


static func typed_rows(o, name: String, data: Variant) -> Dictionary:
	var out := {}
	var path := name + (".foods" if name == "pet-food" else "")
	for id in o._rows(data):
		if o._typed_fields_valid(name, data[id], path + "." + str(id)):
			out[id] = data[id]
	return out


static func rows(data: Variant) -> Dictionary:
	var out := {}
	if not data is Dictionary:
		return out
	for key in data:
		if metadata_key(key):
			continue
		if data[key] is Dictionary:
			out[key] = data[key]
	return out


static func metadata_key(key: Variant) -> bool:
	return str(key).begins_with("$") or str(key).begins_with("_")
