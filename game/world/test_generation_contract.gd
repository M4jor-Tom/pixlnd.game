## Literal extraction anchors: ordered plans/mesh arrays, RNG state, overwrite and exact contact.
extends SceneTree
const Model := preload("res://ontology/model.gd")
const Gen := preload("res://game/world/world_gen.gd")
const Spawner := preload("res://game/world/spawner.gd")
const Encounters := preload("res://game/world/encounter_gen.gd")
const Settlement := preload("res://game/world/settlement.gd")
const MeshData := preload("res://game/world/zone_mesh.gd")
const Targeting := preload("res://game/combat/targeting.gd")
var failed := 0


class RecordingGen:
	extends "res://game/world/world_gen.gd"
	var streams: Array = []

	func creature_level(land: Land, lo: int, hi: int, rng: RandomNumberGenerator) -> int:
		streams.append(rng)
		return super.creature_level(land, lo, hi, rng)


class ColumnGen:
	var terrain := {"zone-blocks": 1, "water-color": "#204060"}
	var land_min := -1
	var land_max := 1
	var land_blocks := 64
	var sea_level := 4

	func valid_zone(_zone: Vector2i) -> bool:
		return true

	func height_at(x: int, z: int) -> int:
		return 3 if x == 0 and z == 0 else 0

	func column(_x: int, _z: int, _height: int, _slope: int) -> Dictionary:
		return {"color": Color("#80a0c0")}


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func anchor(value, expected: String, label: String) -> void:
	var digest := var_to_bytes(value).hex_encode().sha256_text()
	print("ANCHOR ", label, " ", digest)
	check(digest == expected, label)


func spawn_stream(o, d: Dictionary) -> void:
	var design := d.duplicate(true)
	design.settlement = {}
	design.spawns["groups-per-zone"] = [2, 2]
	var a := RecordingGen.new(26879, design, o.landscapes)
	var b := RecordingGen.new(26879, design, o.landscapes)
	for gen in [a, b]:
		gen._h_base = 255
		gen._h_amp = 0
	var coords := [Vector2i.ZERO, Vector2i(-8, 4), Vector2i(19, -23)]
	var reversed := coords.duplicate()
	reversed.reverse()
	var cold := {}
	for zone in reversed:
		var land = b.land_of_block(zone.x * 64 + 32, zone.y * 64 + 32)
		var plan_ := Spawner.plan(
			b, zone, design, o.creatures, {land.landscape: ["skeleton"]}, 6, 10
		)
		cold[zone] = [plan_, b.streams[-1].state]
	var observations := []
	for zone in coords:
		var land = a.land_of_block(zone.x * 64 + 32, zone.y * 64 + 32)
		var plan_ := Spawner.plan(
			a, zone, design, o.creatures, {land.landscape: ["skeleton"]}, 6, 10
		)
		check(
			var_to_bytes(plan_) == var_to_bytes(cold[zone][0]), "complete cold reversed spawn plan"
		)
		check(a.streams[-1].state == cold[zone][1], "cold reversed final RNG state")
		check(plan_.size() == 2, "two admitted any-class groups")
		observations.append([plan_, a.streams[-1].state])
		check(a.streams[-1] == a.streams[-2], "both groups consume the same zone RNG object")
	anchor(
		observations,
		"15ce4e9095c64b85e9e4ea4356f84a646a834b1705fe6b9f8fea4a33c3a714c9",
		"spawn plans and final zone RNG"
	)


func assignments(o, d: Dictionary) -> void:
	var g := Gen.new(26879, d, o.landscapes)
	var land = g.land_at(Vector2i.ZERO)
	var sites := []
	for family in ["ruins", "camp", "supplier"]:
		sites.append(
			Encounters.make_site(g, land, Vector2i(8192, 8192), 3, family, 0, g.encounter_config)
		)
	anchor(
		sites,
		"414863615e26190c7137f415dc0ffa6f4fc0ec1b3dde58c22097aec2f5b1796a",
		"complete site layout and ordered assignments"
	)
	var site := {"centre": [0, 0], "turn": 0, "floor": 101, "family": "ruins", "assignments": []}
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for boss in [false, true, true]:
		Encounters.assignment(site, "p", 0, 1, 2, 3, boss, "mage", rng, g.encounter_config)
	anchor(
		[site, rng.state],
		"0e0cda281c5112c71915012fc75dd489eb31acfb82449ca47567abc311c7b9ef",
		"guard boss special spirit RNG state"
	)


func supports(o, d: Dictionary) -> void:
	var g := Gen.new(1, d, o.landscapes)
	var plan_ := {
		"village": {"hub": true, "centre": [0, 0], "height": 30},
		"sites":
		[
			{"floor": 50, "volumes": [[-2, 50, -2, 2, 60, 2]]},
			{"floor": 70, "volumes": [[0, 70, 0, 4, 80, 4]]}
		]
	}
	var patches := g.support_patches(plan_)
	check(patches[Vector2i(-31, -31)] == 30, "hub writes first")
	check(patches[Vector2i(-2, -2)] == 69, "later site apron overwrites earlier physical cut")
	check(patches[Vector2i.ZERO] == 68, "later physical floor overwrites its apron")
	check(patches[Vector2i(4, 4)] == 69, "volume max excluded, apron retained")
	anchor(
		patches,
		"b08444a3a2a007ca022050d4709972ab4334b6c0747e9afadcc2bad89f5d9bb9",
		"ordered support dictionary"
	)


func contacts() -> void:
	var box := {"building": 0, "centre": [4.0, 0.0], "axis": [1.0, 0.0], "half": [2.0, 2.0]}
	check(Settlement.box_clear([0.0, 0.0], [1.0, 0.0], [2.0, 2.0], [box]), "OBB contact is clear")
	box.centre[0] = 3.999
	check(
		not Settlement.box_clear([0.0, 0.0], [1.0, 0.0], [2.0, 2.0], [box]),
		"OBB penetration blocks"
	)
	check(
		Settlement.box_clear([0.0, 0.0], [1.0, 0.0], [2.0, 2.0], [box], 0),
		"except building retained"
	)
	var circle := {"building": 0, "centre": [3.0, 0.0], "radius": 1.0}
	check(
		Settlement.box_clear([0.0, 0.0], [1.0, 0.0], [2.0, 2.0], [circle]),
		"circle contact is clear"
	)
	circle.centre[0] = 2.999
	check(
		not Settlement.box_clear([0.0, 0.0], [1.0, 0.0], [2.0, 2.0], [circle]),
		"circle penetration blocks"
	)


func mesh_columns() -> void:
	var surfaces := MeshData.data(ColumnGen.new(), Vector2i.ZERO)
	check(surfaces.size() == 2, "land before water")
	var vertices: PackedVector3Array = surfaces[0][Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = surfaces[0][Mesh.ARRAY_NORMAL]
	check(vertices.size() == 30, "top then four exposed sides")
	check(normals[0] == Vector3.UP and normals[6] == Vector3.LEFT, "top then left emission")
	check(
		(
			normals[12] == Vector3.RIGHT
			and normals[18] == Vector3.FORWARD
			and normals[24] == Vector3.BACK
		),
		"right forward back emission"
	)
	for i in range(0, vertices.size(), 3):
		check(
			(
				(vertices[i + 1] - vertices[i]).cross(vertices[i + 2] - vertices[i]).dot(normals[i])
				< 0
			),
			"clockwise triangles"
		)
	anchor(
		surfaces,
		"784f313bb48fb3b3d579cbf2c483596dc0b2ffab008203f2310082a4d36bf58f",
		"complete ordered mesh vertex normal color arrays"
	)


func _init() -> void:
	var o = Model.Ontology.load_dir("res://ontology/instances")
	var d: Dictionary = o.configs.generators.design
	spawn_stream(o, d)
	assignments(o, d)
	supports(o, d)
	contacts()
	mesh_columns()
	preload("res://game/world/zone_mesh_boundary_cases.gd").verify(self)
	population(o, d)
	print("generation contract ok" if failed == 0 else "generation contract FAILED")
	quit(0 if failed == 0 else 1)


func population(o, d: Dictionary) -> void:
	var parent := Node3D.new()
	root.add_child(parent)
	var authority := Targeting.new()
	parent.add_child(authority)
	authority.configure(d, func(): return [])
	var group := {
		"species": &"wolf",
		"level": 6,
		"max_hp": 123.0,
		"damage": 4.0,
		"hostility": &"H",
		"role": "melee",
		"seed": 77,
		"positions": [Vector3(1, 1, 0), Vector3(10, 1, 0), Vector3(20, 1, 0)]
	}
	var corpse := {
		"species": "wolf",
		"level": 3,
		"max_hp": 99.0,
		"hp": 0.0,
		"damage": 2.0,
		"hostility": "H",
		"role": "melee",
		"home": [20.0, 1.0, 0.0],
		"position": [23.0, 1.0, 0.0],
		"seed": 79,
		"pack": "probe/0",
		"dead": true,
		"eligible": true,
		"cycle": 2,
		"combat": Targeting.fresh()
	}
	var frozen := corpse.duplicate(true)
	var saved := {"probe/0/2": corpse}
	var visits := []
	var ready := func(at):
		visits.append(at.duplicate())
		group.level = 9
		group.max_hp = 555.0
		if at[0] == 20:
			saved["probe/0/2"] = {"replacement": true}
		return at[0] != 1
	var made := Spawner.populate(
		parent, [group], d, o.creatures, null, null, authority, "probe", saved, ready
	)
	check(
		visits == [[1.0, 1.0, 0.0], [10.0, 1.0, 0.0], [20.0, 1.0, 0.0]],
		"support callback order and dead home destination"
	)
	check(
		saved.keys() == ["probe/0/2", "probe/0/1"],
		"unsupported member never inserts an incarnation"
	)
	check(made.size() == 2, "only supported members materialize")
	if made.size() == 2:
		check(
			made[0].logical_id == "probe/0/1" and made[1].logical_id == "probe/0/2",
			"support retries retain compact plan indices"
		)
		check(made[0].level == 9 and made[0].hp == 555, "fresh stats reread after support callback")
		check(
			made[1].incarnation.cycle == 3 and made[1].hp == 555,
			"eligible corpse renews once after support callback"
		)
	check(
		corpse == frozen, "renewal duplicates captured corpse, even if callback replaces saved slot"
	)
	check(
		saved["probe/0/2"].position == [20.0, 1.0, 0.0],
		"renewal retains captured home alias, not replaced slot"
	)
	parent.free()
