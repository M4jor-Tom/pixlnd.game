## Successful empty heights still read sea/colour; native height failure must stop before them.
extends SceneTree
const MeshData := preload("res://game/world/zone_mesh.gd")
const ChildOutput := preload("res://ontology/callback_expectations_test_support.gd")
const PREFIX := ["valid", "terrain", "land_min", "land_blocks", "land_max", "land_blocks"]
const MISSING_SEA := "SCRIPT ERROR: Invalid access to property or key 'sea_level' on a base object of type 'RefCounted (Sampler)'."
const MISSING_HEIGHT := "SCRIPT ERROR: Invalid call. Nonexistent function 'height_at' in base 'RefCounted (Sampler)'."


class Sampler:
	extends RefCounted
	var n := -2
	var admitted := true
	var missing_sea := false
	var events: Array = []

	func valid_zone(_zone: Vector2i) -> bool:
		events.append("valid")
		return admitted

	func _get(property: StringName) -> Variant:
		events.append(str(property))
		match property:
			&"terrain":
				return {"zone-blocks": n, "water-color": "#204060"}
			&"land_min":
				return -1
			&"land_max":
				return 1
			&"land_blocks":
				return 64
			&"sea_level":
				return _sea_level()
		return null

	func _sea_level() -> Variant:
		return null if missing_sea else 4


class Heights:
	extends Sampler

	func height_at(x: int, z: int) -> int:
		events.append(["height", x, z])
		return 0


static func verify(test) -> void:
	var output: Array = []
	var status := OS.execute(
		"timeout",
		[
			"681",
			OS.get_executable_path(),
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"-s",
			"res://game/world/zone_mesh_boundary_cases.gd"
		],
		output,
		true
	)
	var text := "\n".join(output)
	var file := FileAccess.open(
		OS.get_environment("PIXLND_TEST_DIR").path_join("zone-mesh-boundary.log"), FileAccess.WRITE
	)
	file.store_string("exit=%d\n%s" % [status, text])
	file.close()
	var headers := ChildOutput.diagnostics(text)
	var records := ChildOutput.observations(text, "ZONE_BOUNDARY ")
	var empty_reads := PREFIX + ["sea_level", "terrain"]
	var height_reads := (
		PREFIX
		+ [
			["height", -1, -1],
			["height", 0, -1],
			["height", -1, 0],
			["height", 0, 0],
			"sea_level",
			"terrain"
		]
	)
	var expected := [
		["empty", true, 1, empty_reads],
		["zero-columns", true, 1, height_reads],
		["outside", false, 0, ["valid"]],
		["missing-sea", false, 0, PREFIX + ["sea_level"]],
		["missing-height", false, 0, PREFIX]
	]
	var serialized: Array = []
	for record in expected:
		serialized.append(JSON.stringify(record))
	test.check(status == 0, "zone boundary child completes")
	test.check(headers == [MISSING_SEA, MISSING_HEIGHT], "zone exact original native headers")
	test.check(records == serialized, "zone empty payload/reads/native-abort observations")


func run_case(mode: String) -> void:
	var gen := Sampler.new() if mode in ["missing-sea", "missing-height"] else Heights.new()
	if mode in ["zero-columns", "missing-height"]:
		gen.n = 0
	gen.admitted = mode != "outside"
	gen.missing_sea = mode == "missing-sea"
	var result := MeshData.data(gen, Vector2i.ZERO)
	var surface: Array = []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	surface[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	surface[Mesh.ARRAY_COLOR] = PackedColorArray()
	print("ZONE_BOUNDARY ", JSON.stringify([mode, result == [surface], result.size(), gen.events]))


func _init() -> void:
	for mode in ["empty", "zero-columns", "outside", "missing-sea", "missing-height"]:
		run_case(mode)
	quit()
