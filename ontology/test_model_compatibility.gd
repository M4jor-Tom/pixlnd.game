## Refactor characterization: public types, aliases and ordered cumulative diagnostics.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const SchemaProbe := preload("res://ontology/schema_probe_test_support.gd")
const CallbackCases := preload("res://ontology/callback_expectations_test_support.gd")
const SpeciesBoundary := preload("res://ontology/validation_boundary_test_support.gd")
const RoleBoundary := preload("res://ontology/role_boundary_test_support.gd")
var failed := 0


class DerivedOntology:
	extends Model.Ontology
	var calls := 0

	func validate() -> bool:
		calls += 1
		return super.validate()


class PredicateOverrides:
	extends Model.Ontology

	static func _identity_strings(_value: Variant) -> bool:
		return false

	static func _source_tags_valid(_value: Variant) -> bool:
		return false

	static func _within_source(_path: String, _scope: String) -> bool:
		return false


class ShapeSpy:
	extends Model.Ontology
	var paths: PackedStringArray = []

	func _input_shape(value: Variant, kind: String, path: String) -> bool:
		paths.append(path)
		return super._input_shape(value, kind, path)


class ChannelMutation:
	extends Model.Ontology
	var row: Dictionary = {}

	func _input_shape(value: Variant, kind: String, path: String) -> bool:
		var valid := super._input_shape(value, kind, path)
		if path == "ability.turns-per-s":
			row["turns-per-s"] = 0
		return valid


class AnnotationKey:
	extends RefCounted
	var calls := 0

	func _to_string() -> String:
		calls += 1
		return "key"


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	check_enums()
	check_defaults()
	check_aliases()
	check_shapes()
	check_typed_shape_order()
	check_field_group_order()
	check_unused_kind_keys()
	check_ability_callbacks()
	preload("res://ontology/identity_late_read_cases.gd").run(self)
	preload("res://ontology/completion_boundary_cases.gd").verify(self)
	preload("res://ontology/diagnostic_header_cases.gd").run(self)
	check_schema_abort_and_continuation()
	check_callback_boundaries()
	check_species_completion_boundaries()
	check_role_array_boundaries()
	check_predicate_overrides()
	check_ordered_diagnostics()
	check_provenance_order()
	check_annotation_key_callbacks()
	print("model compatibility ok" if failed == 0 else "model compatibility FAILED (%d)" % failed)
	quit(0 if failed == 0 else 1)


func check_enums() -> void:
	check(Model.Version == {"A": 0, "S": 1, "OMEGA": 2, "X": 3}, "Version values")
	check(
		(
			Model.Hostility
			== {"FRIENDLY_PLAYER": 0, "HOSTILE": 1, "FRIENDLY": 2, "NAMED_FRIENDLY": 3, "TARGET": 6}
		),
		"Hostility values"
	)
	check(
		Model.ClassType == {"NONE": 0, "WARRIOR": 1, "RANGER": 2, "MAGE": 3, "ROGUE": 4},
		"ClassType values"
	)
	check(
		(
			Model.Rarity
			== {
				"WORN": -1,
				"COMMON": 0,
				"UNCOMMON": 1,
				"RARE": 2,
				"EPIC": 3,
				"LEGENDARY": 4,
				"MYTHICAL": 5
			}
		),
		"Rarity values"
	)
	check(
		Model.Hands == {"ONE_HANDED": 0, "TWO_HANDED": 1, "OFFHAND": 2, "NONE": 3}, "Hands values"
	)
	check(
		Model.AbilityKind == {"ACTIVE": 0, "PASSIVE": 1, "SHARED_PASSIVE": 2, "MOVEMENT": 3},
		"AbilityKind values"
	)
	check(
		Model.MissionTier == {"WHITE": 0, "GREEN": 1, "BLUE": 2, "PURPLE": 3, "YELLOW": 4},
		"MissionTier values"
	)
	check(
		(
			Model.CreatureCategory
			== {
				"ANIMAL": 0,
				"INSECT": 1,
				"AQUATIC": 2,
				"PLANT_CREATURE": 3,
				"MONSTER": 4,
				"UNDEAD": 5,
				"DEMON": 6,
				"ELEMENTAL": 7,
				"HUMANOID": 8,
				"BOSS_SPECIES": 9,
				"STATIC_TARGET": 10,
				"UNUSED": 11
			}
		),
		"CreatureCategory values"
	)
	check(Model.VERSION_TAGS == {"A": 0, "S": 1, "Ω": 2, "X": 3}, "confirmed tag mapping")
	check(
		(
			[
				Model.MAX_CUBES_1H,
				Model.MAX_CUBES_2H,
				Model.MP_MAX,
				Model.SKILL_POINTS_PER_LEVEL,
				Model.BLOCK_NATIVE_UNITS
			]
			== [16, 32, 100.0, 2, 65536]
		),
		"public constants"
	)


func check_defaults() -> void:
	var cases := [
		[Model.Entry, {}],
		[Model.Race, {"playable": true, "size_class": &"normal"}],
		[
			Model.CharacterClass,
			{
				"id_number": 0,
				"weapon_types": [],
				"armor_material": &"",
				"specializations": [],
				"special_attack_mode": &"charged",
				"hp_mult": 1.0
			}
		],
		[
			Model.Specialization,
			{
				"character_class": &"",
				"index": 0,
				"kit_a": [],
				"kit_s": [],
				"passives_a": [],
				"passives_s": []
			}
		],
		[
			Model.Ability,
			{
				"kind": 0,
				"owner": null,
				"input": {},
				"cost": {},
				"cooldown_s": null,
				"duration_s": null,
				"effect": "",
				"applies": [],
				"alpha_ability_id": -1,
				"alpha_tree": {}
			}
		],
		[
			Model.WeaponType,
			{
				"subtype": -1,
				"character_class": &"",
				"hands": 3,
				"damage_k": 0,
				"cube_capacity": 0,
				"combo_cap": -1
			}
		],
		[Model.MaterialDef, {"material_id": -1, "kind": &"", "obtainable": true}],
		[Model.RarityDef, {"index": 0, "color": &"", "stars": 0, "gem": &"", "named": false}],
		[
			Model.Creature,
			{
				"alpha_entity_id": -1,
				"family": &"",
				"category": 0,
				"hostility": &"P",
				"lands": [],
				"group_size": Vector2i(1, 1),
				"tame_food": &"",
				"rideable": false,
				"boss_species": false,
				"boss_capable": false,
				"drops": [],
				"combat_role": &""
			}
		],
		[Model.PetFood, {"subtype": -1, "tames": &"", "rideable": false, "shop": false}],
		[
			Model.Landscape,
			{"climate": {}, "hazards": [], "dungeon_types": [], "style": "", "gen": {}}
		],
		[Model.StatusEffect, {"kind": &"", "sources": [], "countered_by": []}],
		[
			Model.Consumable,
			{"kind": &"", "use": &"", "heal_mult": 0, "duration_s": 0, "recipe": {}, "station": ""}
		],
		[Model.KeyItem, {"group": &""}],
		[Model.Ruleset, {"flags": {}, "is_default": false}]
	]
	for pair in cases:
		check_resource_defaults(pair[0], pair[1])


func check_resource_defaults(type, expected: Dictionary) -> void:
	var resource = type.new()
	check(resource is Model.Entry, "concrete public Entry identity")
	var base := {"id": &"", "display_name": "", "versions": [], "source_tags": [], "raw": {}}
	base.merge(expected)
	for field in base:
		check(resource.get(field) == base[field], "default " + field)


func check_aliases() -> void:
	var o := Model.Ontology.new()
	var row := {"versions": ["A?", "S"], "climate": {}, "gen": {"base": 1}}
	var raw := {"sample": row}
	o._ingest("landscapes", raw)
	check(is_same(o.configs.landscapes, raw), "config Dictionary alias")
	check(is_same(o.landscapes.sample.raw, row), "Entry raw Dictionary alias")
	check(is_same(o.landscapes.sample.gen, row.gen), "typed nested Dictionary alias")
	row.gen.base = 2
	check(o.landscapes.sample.gen.base == 2, "raw mutation reaches typed field")
	check(o.landscapes.sample.versions == [Model.Version.S], "qualified tags not promoted")
	check(o.landscapes.sample.source_tags == ["A?", "S"], "exact tags retained")
	o._ingest("landscapes", [])
	check(o.configs.landscapes == [], "malformed raw replaces config")
	check(o.landscapes.has("sample"), "reingest does not reset modeled catalog")


func check_shapes() -> void:
	var cases := {
		"object": [[{}, true], [null, false], [[], false]],
		"catalog": [[{}, true], [null, false]],
		"array": [[[], true], [{}, false]],
		"strings": [[[], true], [[""], true], [[&"text"], false], [[null], false]],
		"string": [["", true], [&"text", false]],
		"bool": [[true, true], [0, false]],
		"number": [[0, true], [-1.5, true], [NAN, false], [INF, false], ["1", false]],
		"pair": [[[1, 2.0], true], [[-4, 3], true], [[INF, 2], false], [[1, 2, 3], false]],
		"colour": [[[0, 0.5, 1], true], [[0, 1, 1.01], false], [[0, "0", 1], false]],
		"palette": [[["#fff", "#112233"], true], [["#ggg", "#000"], false], [["#fff"], false]],
		"unknown": [[{}, false]]
	}
	for kind in cases:
		for pair in cases[kind]:
			check_shape(kind, pair[0], pair[1])


func check_shape(kind: String, value: Variant, valid: bool) -> void:
	var o := Model.Ontology.new()
	o.errors.append("prior")
	check(o._input_shape(value, kind, "generators.design.sample") == valid, "shape " + kind)
	var expected := PackedStringArray(["prior"])
	if not valid:
		expected.append("design.sample: required " + kind + " missing or malformed")
	check(o.errors == expected, "one ordered shape diagnostic " + kind)


func check_typed_shape_order() -> void:
	var o := ShapeSpy.new()
	var row := {
		"family": 9,
		"cat": "animal",
		"h": false,
		"tame": null,
		"role": {},
		"ride": "false",
		"boss": true,
		"bossable": 2,
		"aid": "1",
		"lands": [null],
		"drops": false,
		"group": [1, INF]
	}
	o.errors.append("prior")
	check(
		not o._typed_fields_valid("creatures", row, "creatures.sample"),
		"typed shapes reject cumulatively"
	)
	var fields := "family cat h role ride boss bossable aid lands drops group".split(" ")
	var expected: PackedStringArray = []
	for field in fields:
		expected.append("creatures.sample." + field)
	check(o.paths == expected, "typed string/bool/number/array/group validation order")
	check(
		(
			o.errors
			== PackedStringArray(
				[
					"prior",
					"creatures.sample.family: required string missing or malformed",
					"creatures.sample.h: required string missing or malformed",
					"creatures.sample.role: required string missing or malformed",
					"creatures.sample.ride: required bool missing or malformed",
					"creatures.sample.bossable: required bool missing or malformed",
					"creatures.sample.aid: required number missing or malformed",
					"creatures.sample.lands: required strings missing or malformed",
					"creatures.sample.drops: required strings missing or malformed",
					"creatures.sample.group: required pair missing or malformed"
				]
			)
		),
		"typed shape errors retain prior errors and continue"
	)


func check_field_group_order() -> void:
	var o := ShapeSpy.new()
	var fields := {"number": "x y", "strings": "refs"}
	check(not o._fields_valid({}, "row", fields), "missing required fields rejected")
	check(
		o.paths == PackedStringArray(["row", "row.x", "row.y", "row.refs"]),
		"required field group order"
	)
	o.paths.clear()
	check(
		not o._optional_fields_valid({"x": "bad", "refs": [1]}, "optional", fields),
		"optional malformed fields rejected"
	)
	check(
		o.paths == PackedStringArray(["optional.x", "optional.refs"]),
		"optional fields skip omissions without failing fast"
	)


func check_unused_kind_keys() -> void:
	var o := Model.Ontology.new()
	var key := AnnotationKey.new()
	o.errors.append("prior")
	check(o._fields_valid({}, "probe", {key: ""}), "empty required kind group tolerated")
	check(
		o._optional_fields_valid({}, "probe", {key: "absent"}),
		"omitted optional kind group tolerated"
	)
	check(o.errors == PackedStringArray(["prior"]), "unused kind keys leave errors unchanged")
	check(key.calls == 0, "unused kind keys are not stringified")


func check_ability_callbacks() -> void:
	var o := Model.Ontology.new()
	var key := AnnotationKey.new()
	check(o._ability_fields_valid({"cost": {key: "all"}}, "ability"), "all-cost shape accepted")
	check(key.calls == 0, "all-cost keys are not eagerly stringified")
	var mutation := ChannelMutation.new()
	mutation.row = {"runtime": "channel", "turns-per-s": 1, "drain-per-s": 0}
	check(
		not mutation._ability_fields_valid(mutation.row, "ability"),
		"channel numeric guard observes shape-callback mutation"
	)
	check(
		mutation.errors == PackedStringArray(["ability.turns-per-s: must be > 0"]),
		"channel callback mutation retains original diagnostic"
	)


func check_schema_abort_and_continuation() -> void:
	var output: Array = []
	var status := OS.execute(
		"timeout",
		[
			"30",
			OS.get_executable_path(),
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"-s",
			"res://ontology/schema_probe_test_support.gd"
		],
		output,
		true
	)
	var text := "\n".join(output)
	var actual: Array = []
	for line in text.split("\n"):
		if line.begins_with("RESULT "):
			actual.append(line.trim_prefix("RESULT "))
	var expected: Array = []
	for observation in SchemaProbe.EXPECTED:
		expected.append(JSON.stringify(observation, "", false, true))
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if directory.is_absolute_path() and DirAccess.dir_exists_absolute(directory):
		var file := FileAccess.open(
			directory.path_join("schema-boundary-probe.log"), FileAccess.WRITE
		)
		file.store_string("exit=%d\n%s" % [status, text])
	check(status == 0, "schema probe child completes")
	check(
		(
			CallbackCases.observations(text, "SCRIPT ERROR:")
			== [
				"SCRIPT ERROR: Invalid type in function '_input_shape' in base 'RefCounted (ShapeSpy)'. Cannot convert argument 2 from Object to String.",
				"SCRIPT ERROR: Invalid type in function '_input_shape' in base 'RefCounted (ShapeSpy)'. Cannot convert argument 2 from Object to String."
			]
		),
		"only exact active malformed kinds reach native boundary"
	)
	check(actual == expected, "schema abort, continuation and callback observations")


func check_predicate_overrides() -> void:
	var o := PredicateOverrides.new()
	check(
		not o._input_shape(["x"], "strings", "sample"), "shape dispatches static subclass predicate"
	)
	check(
		not o._source_annotation_valid("sample", "versions", ["A"]),
		"annotation dispatches static subclass predicate"
	)
	check(
		o._source_annotation_errors({"versions": ["A"]}) == PackedStringArray(["versions"]),
		"recursive annotations dispatch subclass predicate"
	)
	o.configs["item-types"] = {"none": {"versions": ["A"], "value": 3}}
	check(
		o.source_at("item-types.none.value") == {"tags": [], "origin": "", "status": "unresolved"},
		"source scopes dispatch subclass predicate"
	)


func check_ordered_diagnostics() -> void:
	var loaded := Model.Ontology.load_dir("res://ontology/instances")
	var o := DerivedOntology.new()
	for field in [
		"races",
		"classes",
		"specs",
		"abilities",
		"weapon_types",
		"materials",
		"rarities",
		"creatures",
		"pet_foods",
		"landscapes",
		"status_effects",
		"consumables",
		"key_items",
		"rulesets",
		"configs"
	]:
		o.set(field, loaded.get(field))
	o.errors.append("prior loader diagnostic")
	o.configs["controller-profiles"].android["deadzone-ratio"] = -1
	o.configs["block-types"].alpha["0"].versions = ["Q"]
	o.consumables.apple.heal_mult = 19
	o.rulesets["ruleset-hybrid"].is_default = false
	var expected := PackedStringArray(
		[
			"prior loader diagnostic",
			"controller-profiles.android.deadzone-ratio: must equal selected policy 0.15",
			"block-types.alpha.0.versions: malformed source version tags",
			"consumables.apple.heal-mult: loaded coefficient must equal 20",
			"exactly one ruleset must be default (found 0)"
		]
	)
	check(not o.validate(), "subclass validation fails")
	check(o.errors == expected, "exact phase diagnostic order")
	check(not o.validate(), "repeated validation fails")
	expected.append_array(expected.slice(1))
	check(o.errors == expected, "prior errors retained and repeated diagnostics appended")
	check(o.calls == 2 and o is Model.Ontology, "concrete subclass dispatch")


func check_annotation_key_callbacks() -> void:
	var o := Model.Ontology.new()
	var key := AnnotationKey.new()
	var raw := {key: 1}
	check(o._source_annotation_errors(raw).is_empty(), "scalar key has no annotation errors")
	check(key.calls == 0, "scalar keys are not stringified")
	raw[key] = {"versions": [], "v": null}
	check(
		o._source_annotation_errors(raw) == PackedStringArray(["key.versions", "key.v"]),
		"object-key diagnostic order"
	)
	check(key.calls == 2, "diagnostic key stringified once per issue")


func check_provenance_order() -> void:
	var o := Model.Ontology.new()
	var raw := {"v": ["bad"], "versions": [], "nested": [{"v": null}, {"versions": [42]}]}
	check(
		(
			o._source_annotation_errors(raw)
			== PackedStringArray(["versions", "v", "nested.0.v", "nested.1.versions"])
		),
		"annotation fields precede ordered nested traversal"
	)
	o.configs["item-types"] = {"none": {"versions": ["A?"], "v": ["S"], "nested": [{"value": 3}]}}
	var source: Dictionary = o.source_at("item-types.none.nested.0.value")
	check(
		source == {"tags": ["A?"], "origin": "item-types.none", "status": "explicit"},
		"nearest annotation and versions precedence"
	)
	source.tags.append("X")
	check(o.configs["item-types"].none.versions == ["A?"], "resolved tags copied, not aliased")
	check(
		(
			o.source_at("item-types.none.nested.-1")
			== {"tags": [], "origin": "", "status": "unresolved"}
		),
		"out-of-range path unresolved"
	)


func check_callback_boundaries() -> void:
	for first in range(0, CallbackCases.CASES.size(), 8):
		var actual := CallbackCases.capture_group(first)
		check(actual[0] == 0, "callback child completes %d" % first)
		check(
			actual[1] == CallbackCases.expected_group(first, "PROBE "),
			"callback read/alias/error observations %d" % first
		)
		check(
			actual[2] == CallbackCases.expected_group(first, "SCRIPT ERROR:"),
			"callback native failure messages %d" % first
		)


func check_species_completion_boundaries() -> void:
	var actual := CallbackCases.capture_species()
	var expected: Array = []
	for record in SpeciesBoundary.EXPECTED:
		expected.append(JSON.stringify(record, "", false, true))
	check(actual[0] == 0, "species completion child completes")
	check(actual[1] == expected, "species completion/capture/iterator observations")
	check(actual[2] == Array(SpeciesBoundary.HEADERS), "species original native boundaries")


func check_role_array_boundaries() -> void:
	var actual := CallbackCases.capture_role()
	var expected: Array = []
	for record in RoleBoundary.EXPECTED + CallbackCases.RUNTIME_EXPECTED:
		expected.append(JSON.stringify(record, "", false, true))
	check(actual[0] == 0, "role/shot child completes")
	check(actual[1] == expected, "role/shot Array ownership and static dispatch")
	check(actual[2] == Array(RoleBoundary.HEADERS), "role/shot original native boundaries")
