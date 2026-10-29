## gen-settlement (§6, D22): a land's village as engine nodes — box buildings with a prism roof on a ring around
## the square, facing it, one NPC (npc.gd) per service building at its door. Placement and the plateau live in
## world_gen.gd#village_at (height_at flattens the ground); `layout` is pure so tests check it without a scene.
## ponytail: no districts, rooms, villagers, schedules or animals (todo_implement.md); boxes until building assets.
extends RefCounted

const NPC := preload("res://game/entities/npc.gd")


## Pure nominal village-local scalar geometry. Logical world coordinates are added only as scalars.
static func local_layout(st: Dictionary) -> Array:
	var out: Array = []
	var ids: Array = st.buildings
	for i in ids.size():
		var angle := TAU * i / ids.size()
		var ux := cos(angle)
		var uz := sin(angle)
		var fp: Array = st.footprint.get(ids[i], st.footprint.default)
		var x := 0.5 + ux * float(st["ring-radius"])
		var z := 0.5 + uz * float(st["ring-radius"])
		out.append(
			{
				"id": StringName(ids[i]),
				"role": StringName(st.npc.roles.get(ids[i], "")),
				"centre": [x, z],
				"size": Vector3(fp[0], fp[1], fp[2]),
				"yaw": PI / 2.0 - angle,
				"axis": [uz, -ux],
				"outward": [ux, uz],
				"door": [x - ux * (float(fp[2]) / 2 + 1), z - uz * (float(fp[2]) / 2 + 1)]
			}
		)
	return out


## Logical positions are arrays, never far-world float32 vectors. All ordinary consumers use this layout.
static func layout(v: Dictionary, st: Dictionary) -> Array:
	var out := local_layout(st)
	for b in out:
		b.centre = [
			float(v.centre.x) + b.centre[0], float(v.height) + 1, float(v.centre.y) + b.centre[1]
		]
		b.door = [float(v.centre.x) + b.door[0], float(v.height) + 1, float(v.centre.y) + b.door[1]]
	return out


static func opening(st: Dictionary, index: int, width: float) -> Dictionary:
	var b: Dictionary = local_layout(st)[index]
	var offset: float = -b.centre[0] * b.axis[0] - b.centre[1] * b.axis[1]
	# The terminal ends beyond the selected back face. Portals are chosen against actual obstacles.
	var back: float = b.centre[0] * b.outward[0] + b.centre[1] * b.outward[1] + b.size.z / 2
	return {
		"gate_index": index,
		"gate_width": width,
		"gate_offset": offset,
		"direction": b.outward,
		"back": back
	}


## Local X intervals of the actual selected wall pieces, shared by builder and geometry queries.
static func walls(b: Dictionary, selected: bool, width: float, offset: float) -> Array:
	if not selected:
		return [[0.0, float(b.size.x)]]
	var out: Array = []
	for sign_ in [-1, 1]:
		var size_: float = (b.size.x - width) / 2 - sign_ * offset
		if size_ > 0:
			out.append([sign_ * (b.size.x / 2 - size_ / 2), size_])
	return out


static func obstacles(st: Dictionary, gate: Dictionary) -> Array:
	var out: Array = []
	var buildings := local_layout(st)
	for i in buildings.size():
		var b: Dictionary = buildings[i]
		for wall in walls(b, i == gate.gate_index, gate.gate_width, gate.gate_offset):
			out.append(
				{
					"centre":
					[b.centre[0] + b.axis[0] * wall[0], b.centre[1] + b.axis[1] * wall[0]],
					"axis": b.axis,
					"half": [wall[1] / 2, b.size.z / 2],
					"building": i
				}
			)
		if b.role != &"":
			out.append({"centre": b.door, "radius": 0.4, "building": i})
	return out


## Exact continuous OBB/OBB and OBB/circle test in bounded village-local scalar coordinates.
static func box_clear(
	c: Array, axis: Array, half: Array, obstacles_: Array, except: int = -1
) -> bool:
	for o in obstacles_:
		if o.building == except:
			continue
		var dx: float = o.centre[0] - c[0]
		var dz: float = o.centre[1] - c[1]
		if o.has("radius"):
			var x := maxf(0, absf(dx * axis[0] + dz * axis[1]) - half[0])
			var z := maxf(0, absf(-dx * axis[1] + dz * axis[0]) - half[1])
			if x * x + z * z < o.radius * o.radius:
				return false
			continue
		var separated := false
		for n in [axis, [-axis[1], axis[0]], o.axis, [-o.axis[1], o.axis[0]]]:
			var distance := absf(dx * n[0] + dz * n[1])
			var reach: float = (
				absf(axis[0] * n[0] + axis[1] * n[1]) * half[0]
				+ absf(-axis[1] * n[0] + axis[0] * n[1]) * half[1]
				+ absf(o.axis[0] * n[0] + o.axis[1] * n[1]) * o.half[0]
				+ absf(-o.axis[1] * n[0] + o.axis[0] * n[1]) * o.half[1]
			)
			if distance >= reach:
				separated = true
				break
		if not separated:
			return false
	return true


static func build(v: Dictionary, st: Dictionary, roles: Dictionary, frame = null) -> Node3D:
	var root := Node3D.new()
	root.name = "Village"
	var reference := [v.centre.x, 0, v.centre.y]
	root.position = (
		frame.to_local(reference) if frame != null else Vector3(reference[0], 0, reference[2])
	)
	var col: Array = st["style-colors"][String(v["style"])]
	var buildings := local_layout(st)
	for i in buildings.size():
		var b: Dictionary = buildings[i]
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = b["size"]
		m.mesh = box
		m.material_override = StandardMaterial3D.new()
		m.material_override.albedo_color = Color(col[0])
		m.position = Vector3(b.centre[0], float(v.height) + 1 + b.size.y / 2, b.centre[1])
		m.rotation.y = b["yaw"]
		var selected: bool = i == v.get("gate_index", -1)
		m.mesh = null
		for interval in walls(
			b, selected, float(v.get("gate_width", 0)), float(v.get("gate_offset", 0))
		):
			var wall := MeshInstance3D.new()
			var piece := BoxMesh.new()
			piece.size = Vector3(interval[1], b.size.y, b.size.z)
			wall.mesh = piece
			wall.material_override = m.material_override
			wall.position.x = interval[0]
			var body := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var sh := BoxShape3D.new()
			sh.size = piece.size
			cs.shape = sh
			body.add_child(cs)
			wall.add_child(body)
			m.add_child(wall)
		var roof := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(b["size"].x + 1.0, 2.0, b["size"].z + 1.0)
		roof.mesh = prism
		roof.material_override = StandardMaterial3D.new()
		roof.material_override.albedo_color = Color(col[1])
		roof.position = Vector3(0, b["size"].y / 2.0 + 1.0, 0)
		m.add_child(roof)
		root.add_child(m)
		if b["role"] != &"":
			var n := NPC.new(b["role"], str(roles[b["role"]]["name"]), Color(st["npc"]["color"]))
			n.position = Vector3(b.door[0], float(v.height) + 1, b.door[1])
			root.add_child(n)
	return root
