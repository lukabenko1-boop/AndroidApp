extends MeshInstance3D
class_name Terrain
## Destructible 3D heightmap terrain.
## Mirrors the web build's heightmap: blasts/beams/slams carve real craters in
## the X/Z plane; the mesh is rebuilt (throttled to once per frame) and lit by
## the scene's DirectionalLight3D. Albedo comes from per-vertex height/slope
## colours (dirt -> grass -> rock).

const GX := 40
const GZ := 36
const AX0 := -44.0
const AX1 := 44.0
const AZ0 := 0.0
const AZ1 := 74.0

var heights : PackedFloat32Array
var _dirty := false
var _mat : StandardMaterial3D

func _gx(i: int) -> float: return AX0 + (AX1 - AX0) * float(i) / GX
func _gz(j: int) -> float: return AZ0 + (AZ1 - AZ0) * float(j) / GZ
func _idx(i: int, j: int) -> int: return j * (GX + 1) + i

func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.vertex_color_use_as_albedo = true
	_mat.roughness = 0.96
	_mat.metallic = 0.0
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = _mat
	build_heights()
	rebuild()

func build_heights() -> void:
	heights = PackedFloat32Array()
	heights.resize((GX + 1) * (GZ + 1))
	# a handful of gaussian hills across the large arena
	var hills := [
		Vector4(-28.0, 16.0, 10.0, 7.0), Vector4(20.0, 24.0, 9.5, 5.5),
		Vector4(-6.0, 11.0, 8.0, 4.2), Vector4(28.0, 38.0, 11.0, 8.5),
		Vector4(-30.0, 48.0, 9.5, 6.4), Vector4(10.0, 56.0, 12.0, 7.4),
		Vector4(-16.0, 66.0, 10.5, 6.8), Vector4(34.0, 68.0, 10.0, 5.6),
	]
	for j in range(GZ + 1):
		for i in range(GX + 1):
			var x := _gx(i)
			var z := _gz(j)
			var h := 0.4
			for hh in hills:
				var dx : float = x - hh.x
				var dz : float = z - hh.y
				h += hh.w * exp(-((dx * dx + dz * dz) / (2.0 * hh.z * hh.z)))
			h += sin(x * 0.4) * cos(z * 0.34) * 0.5
			heights[_idx(i, j)] = h

func height_at(x: float, z: float) -> float:
	var fx : float = clampf((x - AX0) / (AX1 - AX0) * GX, 0.0, GX - 0.001)
	var fz : float = clampf((z - AZ0) / (AZ1 - AZ0) * GZ, 0.0, GZ - 0.001)
	var i := int(fx)
	var j := int(fz)
	var tx := fx - i
	var tz := fz - j
	var a := heights[_idx(i, j)]
	var b := heights[_idx(i + 1, j)]
	var c := heights[_idx(i, j + 1)]
	var d := heights[_idx(i + 1, j + 1)]
	return (a * (1.0 - tx) + b * tx) * (1.0 - tz) + (c * (1.0 - tx) + d * tx) * tz

func carve(cx: float, cz: float, radius: float, depth: float) -> void:
	var changed := false
	for j in range(GZ + 1):
		for i in range(GX + 1):
			var dx := _gx(i) - cx
			var dz := _gz(j) - cz
			var d2 := dx * dx + dz * dz
			if d2 < radius * radius:
				var f := 1.0 - sqrt(d2) / radius
				var k := _idx(i, j)
				var nh : float = maxf(-3.0, heights[k] - depth * f)
				if nh < heights[k]:
					heights[k] = nh
					changed = true
	if changed:
		_dirty = true

func _process(_delta: float) -> void:
	if _dirty:
		_dirty = false
		rebuild()

func _vcolor(h: float, slope: float) -> Color:
	var base : Color
	if h < 0.4: base = Color(0.36, 0.27, 0.18)
	elif h < 2.5: base = Color(0.58, 0.42, 0.26)
	elif h < 6.0: base = Color(0.44, 0.55, 0.28)
	elif h < 10.0: base = Color(0.62, 0.57, 0.40)
	else: base = Color(0.78, 0.75, 0.64)
	if slope > 0.55:
		base = base.lerp(Color(0.5, 0.47, 0.42), clampf((slope - 0.55) * 1.8, 0.0, 0.7))
	return base

func rebuild() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(GZ):
		for i in range(GX):
			var x0 := _gx(i)
			var x1 := _gx(i + 1)
			var z0 := _gz(j)
			var z1 := _gz(j + 1)
			var h00 := heights[_idx(i, j)]
			var h10 := heights[_idx(i + 1, j)]
			var h11 := heights[_idx(i + 1, j + 1)]
			var h01 := heights[_idx(i, j + 1)]
			var p00 := Vector3(x0, h00, z0)
			var p10 := Vector3(x1, h10, z0)
			var p11 := Vector3(x1, h11, z1)
			var p01 := Vector3(x0, h01, z1)
			var avg := (h00 + h10 + h11 + h01) * 0.25
			var nrm := (p10 - p00).cross(p01 - p00)
			var slope : float = 1.0 - clampf(absf(nrm.normalized().y), 0.0, 1.0)
			var col := _vcolor(avg, slope)
			# two triangles (CCW so normals face up)
			for v in [p00, p01, p11, p00, p11, p10]:
				st.set_color(col)
				st.add_vertex(v)
	st.generate_normals()
	mesh = st.commit()
