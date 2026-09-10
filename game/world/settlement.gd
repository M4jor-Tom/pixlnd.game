## gen-settlement (§6, D22): a land's village as engine nodes — box buildings with a prism roof on a ring around
## the square, facing it, one NPC (npc.gd) per service building at its door. Placement and the plateau live in
## world_gen.gd#village_at (height_at flattens the ground); `layout` is pure so tests check it without a scene.
## ponytail: no districts, rooms, villagers, schedules or animals (todo_implement.md); boxes until building assets.
extends RefCounted

const NPC := preload("res://game/entities/npc.gd")

## [{id, role, centre: Vector3 (y = top of the ground block), size: Vector3 (w, h, d), yaw, door: Vector3}] — the
## door stands one block in front of the wall that faces the square.
static func layout(v: Dictionary, st: Dictionary) -> Array:
	var out: Array = []
	var ids: Array = st["buildings"]
	var rr := float(st["ring-radius"])
	var top := float(v["height"] + 1)
	for i in ids.size():
		var ang := TAU * i / ids.size()
		var fp: Array = st["footprint"].get(ids[i], st["footprint"]["default"])
		var size := Vector3(fp[0], fp[1], fp[2])
		var c := Vector3(v["centre"].x + 0.5 + cos(ang) * rr, top, v["centre"].y + 0.5 + sin(ang) * rr)
		var toward := Vector3(-cos(ang), 0, -sin(ang))                 # local -Z (the front) points at the square
		out.append({"id": StringName(ids[i]), "role": StringName(st["npc"]["roles"].get(ids[i], "")), "centre": c, "size": size,
			"yaw": PI / 2.0 - ang, "door": c + toward * (size.z / 2.0 + 1.0)})
	return out

static func build(v: Dictionary, st: Dictionary, roles: Dictionary) -> Node3D:
	var root := Node3D.new(); root.name = "Village"
	var col: Array = st["style-colors"][String(v["style"])]
	for b in layout(v, st):
		var m := MeshInstance3D.new()
		var box := BoxMesh.new(); box.size = b["size"]; m.mesh = box
		m.material_override = StandardMaterial3D.new(); m.material_override.albedo_color = Color(col[0])
		m.position = b["centre"] + Vector3(0, b["size"].y / 2.0, 0); m.rotation.y = b["yaw"]
		var body := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
		sh.size = b["size"]; cs.shape = sh; body.add_child(cs); m.add_child(body)
		var roof := MeshInstance3D.new(); var prism := PrismMesh.new()
		prism.size = Vector3(b["size"].x + 1.0, 2.0, b["size"].z + 1.0); roof.mesh = prism
		roof.material_override = StandardMaterial3D.new(); roof.material_override.albedo_color = Color(col[1])
		roof.position = Vector3(0, b["size"].y / 2.0 + 1.0, 0); m.add_child(roof)
		root.add_child(m)
		if b["role"] != &"":
			var n := NPC.new(b["role"], str(roles[b["role"]]["name"]), Color(st["npc"]["color"]))
			n.position = b["door"]
			root.add_child(n)
	return root
