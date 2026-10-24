## Physical views of the same authored playable components/route slabs used for occupancy and access.
## Logical populations belong to WorldState, never to these disposable streaming nodes.
extends RefCounted
const Gen := preload("res://game/world/encounter_gen.gd")
const ZoneMesh := preload("res://game/world/zone_mesh.gd")
const NPC := preload("res://game/entities/npc.gd")

static func box(out: Array, x: float, y: float, z: float, sx: float, sy: float, sz: float, turn: float = 0) -> void:
	if sx <= 0 or sy <= 0 or sz <= 0: return
	out.append({"centre":[x,y,z],"size":[sx,sy,sz],"yaw":turn})

static func local_box(out: Array, s: Dictionary, x: float, y: float, z: float, sx: float, sy: float, sz: float) -> void:
	var p := Gen.point(s,x,z)
	box(out,p.x,y,p.y,sx,sy,sz,-float(s.turn)*PI/2)

static func boxes(s: Dictionary, cfg: Dictionary) -> Array:
	var out: Array = []
	var rules: Dictionary = cfg[s.family]
	var height_: float = rules.ceiling if s.family == "ruins" else cfg["max-step"]
	var cells := {}
	for r in s.components:
		local_box(out,s,(r[0]+r[2])/2,s.floor-0.5,(r[1]+r[3])/2,r[2]-r[0],1,r[3]-r[1])
		if s.family == "ruins": local_box(out,s,(r[0]+r[2])/2,s.floor+height_+0.5,(r[1]+r[3])/2,r[2]-r[0],1,r[3]-r[1])
		for x in range(int(r[0]),int(r[2])):
			for z in range(int(r[1]),int(r[3])): cells[Vector2i(x,z)] = true
	var exit_width: float = rules.door[0] if s.family == "ruins" else rules["exit-width"]
	var first_z: float = s.components[0][1]; var last_z: float = s.components[0][3]
	for cell: Vector2i in cells:
		for dir: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if cells.has(cell+dir): continue
			var x := cell.x+0.5; var z := cell.y+0.5
			var open_front: bool = dir.y == -1 and cell.y == first_z and absf(x-s.entry[0]) < exit_width/2
			var open_back: bool = s.family != "ruins" and dir.y == 1 and cell.y+1 == last_z and absf(x) < exit_width/2
			if open_front or open_back:
				if s.family == "ruins": local_box(out,s,x,s.floor+rules.door[1]+(height_-rules.door[1])/2,cell.y,1,height_-rules.door[1],1)
				continue
			local_box(out,s,x+dir.x,s.floor+height_/2,z+dir.y,1,height_,1)
	if s.family == "ruins":
		# Narrow each passage/corridor join to the approved four-by-five doorway.
		for index in [1,3,5]:
			var r: Array = s.components[index]
			for z in [r[1],r[3]]: doorway(out,s,(r[0]+r[2])/2,z,r[2]-r[0],rules,false)
		var alcove: Array = s.components[-1]
		doorway(out,s,(alcove[1]+alcove[3])/2,alcove[0],alcove[3]-alcove[1],rules,true)
	return out

static func doorway(out: Array, s: Dictionary, middle: float, at: float, span: float, r: Dictionary, sideways: bool) -> void:
	var side: float = (span-r.door[0])/2
	for sign_ in [-1,1]:
		var c: float = middle+sign_*(r.door[0]/2.0+side/2)
		if sideways: local_box(out,s,at,s.floor+r.ceiling/2.0,c,1,r.ceiling,side)
		else: local_box(out,s,c,s.floor+r.ceiling/2.0,at,side,r.ceiling,1)
	if sideways: local_box(out,s,at,s.floor+(r.ceiling+r.door[1])/2.0,middle,1,r.ceiling-r.door[1],r.door[0])
	else: local_box(out,s,middle,s.floor+(r.ceiling+r.door[1])/2.0,at,r.door[0],r.ceiling-r.door[1],1)

## One mesh/trimesh per streamed structure, not one physics body per block/slab.
static func geometry(data: Array, origin: Array, colour: Color) -> MeshInstance3D:
	var buf := ZoneMesh.Buf.new()
	for b in data:
		var basis := Basis(Vector3.UP,b.yaw)
		var cardinal := roundi(float(b.yaw)/(PI/2))
		if is_equal_approx(float(b.yaw),cardinal*PI/2):
			# Trigonometric near-zero terms can move a boundary off its exact block at world corners.
			var x := Gen.rotate(1,0,-cardinal); var z := Gen.rotate(0,1,-cardinal)
			basis = Basis(Vector3(x.x,0,x.y),Vector3.UP,Vector3(z.x,0,z.y))
		var vertices: Array[Vector3] = []
		for corner in [Vector3(-1,-1,-1),Vector3(1,-1,-1),Vector3(1,-1,1),Vector3(-1,-1,1),Vector3(-1,1,-1),Vector3(1,1,-1),Vector3(1,1,1),Vector3(-1,1,1)]:
			# Round shared slab endpoints once, not centre/size separately (which opens tiny physics cracks).
			var x: float = float(b.centre[0])-float(origin[0])+basis.x.x*corner.x*float(b.size[0])/2+basis.z.x*corner.z*float(b.size[2])/2
			var y: float = float(b.centre[1])-float(origin[1])+corner.y*float(b.size[1])/2
			var z: float = float(b.centre[2])-float(origin[2])+basis.x.z*corner.x*float(b.size[0])/2+basis.z.z*corner.z*float(b.size[2])/2
			vertices.append(Vector3(x,y,z))
		for face in [[4,7,6,5,Vector3.UP],[0,1,2,3,Vector3.DOWN],[0,3,7,4,Vector3.LEFT],[1,5,6,2,Vector3.RIGHT],[0,4,5,1,Vector3.FORWARD],[3,2,6,7,Vector3.BACK]]:
			buf.quad(colour,basis*face[4],vertices[face[0]],vertices[face[1]],vertices[face[2]],vertices[face[3]])
	var mi := MeshInstance3D.new(); var mesh := ArrayMesh.new(); buf.commit(mesh); mi.mesh = mesh
	var mat := StandardMaterial3D.new(); mat.vertex_color_use_as_albedo = true; mat.vertex_color_is_srgb = true; mi.material_override = mat
	var body := StaticBody3D.new(); var shape := ConcavePolygonShape3D.new(); shape.set_faces(buf.v)
	var collision := CollisionShape3D.new(); collision.shape = shape; body.add_child(collision); mi.add_child(body)
	return mi

static func build(s: Dictionary, cfg: Dictionary, design: Dictionary, frame = null) -> Node3D:
	var root := Node3D.new(); root.name = s.family.capitalize()+str(s.ordinal)
	var reference := [s.centre[0],s.floor,s.centre[1]]
	root.position = frame.to_local(reference) if frame != null else Vector3(reference[0],reference[1],reference[2])
	root.add_child(geometry(boxes(s,cfg),reference,Color(design.terrain["sand-color"]).darkened(0.2)))
	if s.family == "supplier":
		var captive := NPC.new(&"captive","Captive supplier",Color(design.settlement.npc.color))
		captive.position = Vector3(float(s.captive[0])-reference[0],float(s.captive[1])-reference[1],float(s.captive[2])-reference[2])
		captive.set_meta("hostility","F"); root.add_child(captive)
	return root

static func roads(plan_: Dictionary, design: Dictionary, frame = null) -> Node3D:
	var root := Node3D.new(); root.name = "Access"
	var reference := [plan_.village.centre[0],plan_.village.height,plan_.village.centre[1]]
	root.position = frame.to_local(reference) if frame != null else Vector3(reference[0],reference[1],reference[2])
	var data: Array = []
	for road in plan_.routes:
		for s in road.steps: box(data,s.x,s.top-0.5,s.z,s.width,1,s.length,atan2(s.dx,s.dz))
	root.add_child(geometry(data,reference,Color(design.settlement["style-colors"][plan_.village.style][0])))
	return root
