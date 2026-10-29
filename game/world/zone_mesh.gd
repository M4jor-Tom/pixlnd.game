## Heightfield mesh of one zone: a top quad per column, side quads down to lower neighbours and a
## flat water surface at sea level. Vertex colours carry the palette (c-block-rgb).
## ponytail: heightfield only, no caves/overhangs (terrain-features.json#overhang); revisit with a
## real voxel mesher when gen-terrain grows caves.
extends RefCounted


class Buf:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()

	## a→b→cc→d counter-clockwise seen from `normal`; emitted clockwise, Godot's front-face order.
	func quad(col: Color, normal: Vector3, a: Vector3, b: Vector3, cc: Vector3, d: Vector3) -> void:
		v.push_back(a)
		v.push_back(cc)
		v.push_back(b)
		v.push_back(a)
		v.push_back(d)
		v.push_back(cc)
		for i in 6:
			n.push_back(normal)
			c.push_back(col)

	func arrays() -> Array:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = n
		arrays[Mesh.ARRAY_COLOR] = c
		return arrays


static func build(gen, zc: Vector2i) -> ArrayMesh:
	return from_data(data(gen, zc))


## Resource creation stays on the publishing main thread.
static func from_data(surfaces: Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for surface in surfaces:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	return mesh


## Worker-safe packed vertex/normal/colour arrays, no SceneTree or shared Resource mutation.
static func data(gen, zc: Vector2i) -> Array:
	if not gen.valid_zone(zc):
		return []
	var n: int = gen.terrain["zone-blocks"]
	var ox := zc.x * n
	var oy := zc.y * n
	var w := n + 2  # heights with a 1-block border
	var min_block: int = gen.land_min * gen.land_blocks
	var max_block: int = (gen.land_max + 1) * gen.land_blocks - 1
	var hs := PackedInt32Array()
	hs.resize(w * w)
	for j in w:
		for i in w:
			hs[j * w + i] = gen.height_at(
				clampi(ox + i - 1, min_block, max_block), clampi(oy + j - 1, min_block, max_block)
			)
	var land := Buf.new()
	var water := Buf.new()
	var sea: int = gen.sea_level
	var water_col := Color(gen.terrain["water-color"])
	water_col.a = 0.7
	for j in n:
		for i in n:
			var h := hs[(j + 1) * w + i + 1]
			var dl := h - hs[(j + 1) * w + i]
			var dr := h - hs[(j + 1) * w + i + 2]  # -x, +x
			var df := h - hs[j * w + i + 1]
			var db := h - hs[(j + 2) * w + i + 1]  # -y, +y
			var slope := maxi(maxi(absi(dl), absi(dr)), maxi(absi(df), absi(db)))
			var c: Color = gen.column(ox + i, oy + j, h, slope)["color"]
			var x0 := float(i)
			var z0 := float(j)
			var top := float(h + 1)
			land.quad(
				c,
				Vector3.UP,
				Vector3(x0, top, z0),
				Vector3(x0, top, z0 + 1),
				Vector3(x0 + 1, top, z0 + 1),
				Vector3(x0 + 1, top, z0)
			)
			var side := c.darkened(0.25)
			if dl > 0:
				land.quad(
					side,
					Vector3.LEFT,
					Vector3(x0, top, z0),
					Vector3(x0, top - dl, z0),
					Vector3(x0, top - dl, z0 + 1),
					Vector3(x0, top, z0 + 1)
				)
			if dr > 0:
				land.quad(
					side,
					Vector3.RIGHT,
					Vector3(x0 + 1, top, z0 + 1),
					Vector3(x0 + 1, top - dr, z0 + 1),
					Vector3(x0 + 1, top - dr, z0),
					Vector3(x0 + 1, top, z0)
				)
			if df > 0:
				land.quad(
					side,
					Vector3.FORWARD,
					Vector3(x0 + 1, top, z0),
					Vector3(x0 + 1, top - df, z0),
					Vector3(x0, top - df, z0),
					Vector3(x0, top, z0)
				)
			if db > 0:
				land.quad(
					side,
					Vector3.BACK,
					Vector3(x0, top, z0 + 1),
					Vector3(x0, top - db, z0 + 1),
					Vector3(x0 + 1, top - db, z0 + 1),
					Vector3(x0 + 1, top, z0 + 1)
				)
			if h < sea:
				var y := float(sea + 1)
				water.quad(
					water_col,
					Vector3.UP,
					Vector3(x0, y, z0),
					Vector3(x0, y, z0 + 1),
					Vector3(x0 + 1, y, z0 + 1),
					Vector3(x0 + 1, y, z0)
				)
	var surfaces := [land.arrays()]
	if not water.v.is_empty():
		surfaces.append(water.arrays())  # surface 1 = water
	return surfaces
