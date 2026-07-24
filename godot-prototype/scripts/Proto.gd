extends Node3D
## KI BLOBS — first 3D prototype.
## The minimal, high-confidence starting point: a controllable fighter flying
## over a 3D heightmap arena, a target dummy, a follow camera, and a simple
## blast. Everything is built in code from one node, so there's nothing fragile
## to break. Grow it from here (see godot/ for the full-feature version).

# --- arena / terrain ---
const GX := 24
const GZ := 24
const AX0 := -30.0
const AX1 := 30.0
const AZ0 := 0.0
const AZ1 := 60.0
var heights : PackedFloat32Array

# --- player ---
const ACCEL := 60.0
const MAXSPD := 16.0
const DRAG := 3.0
const GRAV := 14.0
const LIFT := 26.0
const RADIUS := 1.2

var player : Node3D
var vel := Vector3.ZERO
var facing := Vector3(0, 0, 1)
var cam : Camera3D
var cam_pos := Vector3(0, 14, -16)
var blasts : Array = []

func _ready() -> void:
	_build_world()
	_build_terrain()
	player = _make_fighter(Color(0.25, 0.48, 1.0))
	player.position = Vector3(-6, 8, 22)
	add_child(player)
	var dummy := _make_fighter(Color(1.0, 0.30, 0.37))
	dummy.position = Vector3(8, _height_at(8, 34) + RADIUS + 4.0, 34)
	add_child(dummy)
	_build_hud()

# ---------------- world ----------------
func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.16, 0.12, 0.30)
	psm.sky_horizon_color = Color(0.88, 0.54, 0.42)
	psm.ground_horizon_color = Color(0.5, 0.36, 0.36)
	psm.ground_bottom_color = Color(0.2, 0.15, 0.15)
	sky.sky_material = psm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-45), deg_to_rad(35), 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	cam = Camera3D.new()
	cam.fov = 62.0
	cam.current = true
	add_child(cam)

# ---------------- terrain ----------------
func _gx(i: int) -> float: return AX0 + (AX1 - AX0) * float(i) / GX
func _gz(j: int) -> float: return AZ0 + (AZ1 - AZ0) * float(j) / GZ
func _hi(i: int, j: int) -> int: return j * (GX + 1) + i

func _build_terrain() -> void:
	heights = PackedFloat32Array()
	heights.resize((GX + 1) * (GZ + 1))
	var hills := [Vector4(-14, 18, 8, 6), Vector4(12, 30, 9, 7), Vector4(-4, 44, 8, 5)]
	for j in range(GZ + 1):
		for i in range(GX + 1):
			var x := _gx(i)
			var z := _gz(j)
			var h := 0.3
			for hh in hills:
				var dx : float = x - hh.x
				var dz : float = z - hh.y
				h += hh.w * exp(-((dx * dx + dz * dz) / (2.0 * hh.z * hh.z)))
			heights[_hi(i, j)] = h
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(GZ):
		for i in range(GX):
			var p00 := Vector3(_gx(i), heights[_hi(i, j)], _gz(j))
			var p10 := Vector3(_gx(i + 1), heights[_hi(i + 1, j)], _gz(j))
			var p11 := Vector3(_gx(i + 1), heights[_hi(i + 1, j + 1)], _gz(j + 1))
			var p01 := Vector3(_gx(i), heights[_hi(i, j + 1)], _gz(j + 1))
			var avg := (p00.y + p10.y + p11.y + p01.y) * 0.25
			var col := Color(0.55, 0.42, 0.28) if avg < 3.0 else Color(0.45, 0.55, 0.3)
			if avg > 6.0: col = Color(0.7, 0.66, 0.52)
			for v in [p00, p01, p11, p00, p11, p10]:
				st.set_color(col)
				st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	add_child(mi)

func _height_at(x: float, z: float) -> float:
	var fx : float = clampf((x - AX0) / (AX1 - AX0) * GX, 0.0, GX - 0.001)
	var fz : float = clampf((z - AZ0) / (AZ1 - AZ0) * GZ, 0.0, GZ - 0.001)
	var i := int(fx)
	var j := int(fz)
	var tx := fx - i
	var tz := fz - j
	var a := heights[_hi(i, j)]
	var b := heights[_hi(i + 1, j)]
	var c := heights[_hi(i, j + 1)]
	var d := heights[_hi(i + 1, j + 1)]
	return (a * (1.0 - tx) + b * tx) * (1.0 - tz) + (c * (1.0 - tx) + d * tx) * tz

# ---------------- fighter mesh ----------------
func _make_fighter(col: Color) -> Node3D:
	var root := Node3D.new()
	var torso := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.6
	cap.height = 1.8
	torso.mesh = cap
	torso.position = Vector3(0, 0.4, 0)
	torso.material_override = _flat(col)
	root.add_child(torso)
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.55
	hs.height = 1.1
	head.mesh = hs
	head.position = Vector3(0, 1.6, 0)
	head.material_override = _flat(col.lightened(0.1))
	root.add_child(head)
	for sx in [-0.2, 0.2]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.1
		es.height = 0.2
		eye.mesh = es
		eye.position = Vector3(sx, 1.66, -0.45)
		eye.material_override = _flat(Color(0.08, 0.1, 0.14))
		root.add_child(eye)
	return root

func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	return m

# ---------------- loop ----------------
func _process(delta: float) -> void:
	_move_player(delta)
	_step_blasts(delta)
	_update_camera(delta)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_J:
		_shoot()

func _move_player(delta: float) -> void:
	var mx := 0.0
	var mz := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mx -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mx += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mz += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mz -= 1.0
	vel.x += mx * ACCEL * delta
	vel.z += mz * ACCEL * delta
	# vertical: Space = up, Shift = down, gravity otherwise
	if Input.is_key_pressed(KEY_SPACE): vel.y += LIFT * delta
	elif Input.is_key_pressed(KEY_SHIFT): vel.y -= LIFT * delta
	else: vel.y -= GRAV * delta
	var dr : float = exp(-DRAG * delta)
	vel.x *= dr
	vel.z *= dr
	var flat := Vector2(vel.x, vel.z)
	if flat.length() > MAXSPD:
		flat = flat.normalized() * MAXSPD
		vel.x = flat.x
		vel.z = flat.y
	vel.y = clampf(vel.y, -MAXSPD, MAXSPD)
	player.position += vel * delta
	player.position.x = clampf(player.position.x, AX0 + RADIUS, AX1 - RADIUS)
	player.position.z = clampf(player.position.z, AZ0 + RADIUS, AZ1 - RADIUS)
	var gy := _height_at(player.position.x, player.position.z) + RADIUS
	if player.position.y < gy:
		player.position.y = gy
		vel.y = maxf(vel.y, 0.0)
	if flat.length() > 1.0:
		facing = Vector3(vel.x, 0, vel.z).normalized()
		player.look_at(player.position + facing, Vector3.UP)

func _shoot() -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.4
	s.height = 0.8
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.8, 1.0)
	mat.albedo_color = Color(0.6, 0.85, 1.0)
	m.material_override = mat
	m.position = player.position + facing * (RADIUS + 0.5) + Vector3.UP * 0.6
	add_child(m)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.5, 0.8, 1.0)
	glow.omni_range = 6.0
	m.add_child(glow)
	blasts.append({"node": m, "vel": facing * 40.0, "life": 2.0})

func _step_blasts(delta: float) -> void:
	for b in blasts:
		b.node.position += b.vel * delta
		b.life -= delta
		if b.node.position.y < _height_at(b.node.position.x, b.node.position.z):
			b.life = 0.0
	var keep : Array = []
	for b in blasts:
		if b.life > 0.0:
			keep.append(b)
		else:
			b.node.queue_free()
	blasts = keep

func _update_camera(delta: float) -> void:
	var target := player.position
	var desired := target + Vector3(0, 8, -14)
	cam_pos = cam_pos.lerp(desired, 1.0 - exp(-4.0 * delta))
	cam.global_position = cam_pos
	cam.look_at(target + Vector3.UP * 1.5, Vector3.UP)

# ---------------- hud ----------------
func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "KI BLOBS — 3D prototype\nMove: WASD / Arrows   Up: Space   Down: Shift   Blast: J"
	label.position = Vector2(18, 14)
	label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	layer.add_child(label)
