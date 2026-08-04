extends Node3D
## Game root: builds the 3D world (sky, sun, camera, terrain, fighters), the HUD
## and touch controls, then runs the title / playing / K.O. state machine and the
## per-frame update loop. Mirrors the web build.

var terrain : Terrain
var p1 : Fighter
var p2 : Fighter
var cam : Camera3D
var hud : Hud

var state := "title"
var winner : Fighter
var ko_timer := 0.0
var intro_t := 0.0
var shake := 0.0
var cam_eye := Vector3(0, 24, -20)
var cam_tgt := Vector3(0, 4, 36)

# keyboard edge flags
var punch_q := false
var blast_q := false
var transform_q := false
var start_q := false

# touch state
var touch := {"mx": 0.0, "mz": 0.0, "charge": false, "block": false, "beam": false,
	"punch_q": false, "blast_q": false}
var _stick : ColorRect

func _ready() -> void:
	_build_world()
	_build_hud()
	_build_touch()
	_place_fighters()
	get_viewport().size_changed.connect(_layout_touch)
	call_deferred("_layout_touch")

func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.14, 0.11, 0.26)
	psm.sky_horizon_color = Color(0.86, 0.52, 0.42)
	psm.ground_horizon_color = Color(0.5, 0.36, 0.36)
	psm.ground_bottom_color = Color(0.18, 0.13, 0.14)
	psm.sun_angle_max = 8.0
	sky.sky_material = psm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.6, 0.36, 0.45)
	env.fog_density = 0.006
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-42), deg_to_rad(35), 0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.92, 0.82)
	sun.shadow_enabled = true
	add_child(sun)

	cam = Camera3D.new()
	cam.fov = 60.0
	cam.far = 400.0
	cam.current = true
	add_child(cam)

	terrain = Terrain.new()
	add_child(terrain)

	p1 = Fighter.new()
	p1.setup(self, terrain, false, "YOU", Color(0.25, 0.48, 1.0), Color(1.0, 0.82, 0.23), Color(0.56, 0.96, 1.0))
	add_child(p1)
	p2 = Fighter.new()
	p2.setup(self, terrain, true, "RIVAL", Color(1.0, 0.30, 0.37), Color(1.0, 0.60, 0.23), Color(1.0, 0.62, 0.94))
	add_child(p2)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)

func _make_btn(txt: String, hold: bool, setter: Callable, unsetter: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(86, 86)
	b.size = Vector2(86, 86)
	b.focus_mode = Control.FOCUS_NONE
	b.modulate = Color(1, 1, 1, 0.65)
	if hold:
		b.button_down.connect(setter)
		b.button_up.connect(unsetter)
	else:
		b.pressed.connect(setter)
	return b

var _btns := {}
func _build_touch() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_stick = ColorRect.new()
	_stick.color = Color(0.55, 0.63, 0.86, 0.10)
	_stick.custom_minimum_size = Vector2(190, 190)
	_stick.size = Vector2(190, 190)
	_stick.gui_input.connect(_on_stick_input)
	layer.add_child(_stick)
	_btns["punch"] = _make_btn("PUNCH", false, _t_punch, Callable())
	_btns["blast"] = _make_btn("BLAST", false, _t_blast, Callable())
	_btns["charge"] = _make_btn("CHARGE", true, _t_charge_on, _t_charge_off)
	_btns["block"] = _make_btn("BLOCK", true, _t_block_on, _t_block_off)
	_btns["beam"] = _make_btn("BEAM", true, _t_beam_on, _t_beam_off)
	for k in _btns:
		layer.add_child(_btns[k])

func _t_punch() -> void: touch.punch_q = true; start_q = true
func _t_blast() -> void: touch.blast_q = true; start_q = true
func _t_charge_on() -> void: touch.charge = true; start_q = true
func _t_charge_off() -> void: touch.charge = false
func _t_block_on() -> void: touch.block = true; start_q = true
func _t_block_off() -> void: touch.block = false
func _t_beam_on() -> void: touch.beam = true; start_q = true
func _t_beam_off() -> void: touch.beam = false

func _layout_touch() -> void:
	var vs := get_viewport().get_visible_rect().size
	_stick.position = Vector2(40, vs.y - 230)
	_btns["punch"].position = Vector2(vs.x - 190, vs.y - 250)
	_btns["blast"].position = Vector2(vs.x - 100, vs.y - 160)
	_btns["charge"].position = Vector2(vs.x - 190, vs.y - 100)
	_btns["block"].position = Vector2(vs.x - 280, vs.y - 160)
	_btns["beam"].position = Vector2(vs.x - 145, vs.y - 175)

func _on_stick_input(ev: InputEvent) -> void:
	var pos := Vector2.ZERO
	var active := false
	if ev is InputEventScreenDrag:
		pos = ev.position; active = true
	elif ev is InputEventScreenTouch:
		if ev.pressed: pos = ev.position; active = true
		else: touch.mx = 0.0; touch.mz = 0.0; return
	elif ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT):
		pos = ev.position; active = true
	elif ev is InputEventMouseButton:
		if ev.pressed: pos = ev.position; active = true
		else: touch.mx = 0.0; touch.mz = 0.0; return
	if active:
		var c := _stick.size * 0.5
		var d := (pos - c) / (_stick.size.x * 0.5)
		d = d.limit_length(1.0)
		touch.mx = d.x
		touch.mz = -d.y

func _place_fighters() -> void:
	_reset_fighter(p1, -12.0)
	_reset_fighter(p2, 12.0)

func _reset_fighter(f: Fighter, x: float) -> void:
	var z := Fighter.PLANE_Z
	var y := terrain.height_at(x, z) + Fighter.RADIUS + Fighter.HOVER
	f.reset(Vector3(x, y, z), f.is_cpu)

func new_match() -> void:
	terrain.build_heights()
	terrain.rebuild()
	for c in get_children():
		if c is Projectile:
			c.queue_free()
	_place_fighters()
	winner = null
	ko_timer = 0.0
	intro_t = 1.1
	state = "playing"

func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_J: punch_q = true
			KEY_K: blast_q = true
			KEY_T: transform_q = true
			KEY_SPACE: start_q = true
	# Xbox-style gamepad edge buttons
	elif ev is InputEventJoypadButton and ev.pressed:
		match ev.button_index:
			JOY_BUTTON_A: punch_q = true; start_q = true
			JOY_BUTTON_X: blast_q = true
			JOY_BUTTON_Y: transform_q = true
			JOY_BUTTON_START: start_q = true

func _p1_input() -> Dictionary:
	var mx := 0.0
	var mz := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mx -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mx += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mz += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mz -= 1.0
	# Xbox-style gamepad: left stick + d-pad move (X + fly up/down)
	var gx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var gy := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(gx) > 0.2: mx += gx
	if absf(gy) > 0.2: mz += -gy
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT): mx -= 1.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT): mx += 1.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP): mz += 1.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN): mz -= 1.0
	mx = clampf(mx + touch.mx, -1.0, 1.0)
	mz = clampf(mz + touch.mz, -1.0, 1.0)
	var g_charge := Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > 0.4
	var g_block := Input.is_joy_button_pressed(0, JOY_BUTTON_B)
	var g_beam := Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.4
	return {
		"mx": mx, "mz": mz,
		"charge": Input.is_key_pressed(KEY_L) or touch.charge or g_charge,
		"block": Input.is_key_pressed(KEY_SHIFT) or touch.block or g_block,
		"beam": Input.is_key_pressed(KEY_I) or touch.beam or g_beam,
		"punch": punch_q or touch.punch_q,
		"blast": blast_q or touch.blast_q,
		"transform": transform_q,
	}

func _process(delta: float) -> void:
	if shake > 0.0: shake = maxf(0.0, shake - delta * 1.6)
	if state == "playing":
		if intro_t > 0.0: intro_t -= delta
		var i1 : Dictionary = {} if intro_t > 0.0 else _p1_input()
		var i2 : Dictionary = {} if intro_t > 0.0 else p2.ai_input(p1, delta)
		p1.tick(delta, i1, p2)
		p2.tick(delta, i2, p1)
		if not p1.is_alive() or not p2.is_alive():
			state = "ko"
			winner = p1 if p1.is_alive() else p2
			ko_timer = 0.0
			shake = 0.7
	elif state == "ko":
		ko_timer += delta
	_update_camera(delta)
	punch_q = false; blast_q = false; transform_q = false
	touch.punch_q = false; touch.blast_q = false
	if start_q:
		start_q = false
		if state == "title": new_match()
		elif state == "ko" and ko_timer > 0.8: new_match()
	hud.p1 = p1; hud.p2 = p2; hud.state = state; hud.winner = winner
	hud.ko_timer = ko_timer; hud.intro_t = intro_t
	hud.queue_redraw()

func _update_camera(delta: float) -> void:
	# front-facing camera on the X-Y play plane (2.5D), following mid X and Y
	var mid := (p1.global_position + p2.global_position) * 0.5
	var sep : float = clampf(Vector2(p1.global_position.x - p2.global_position.x, p1.global_position.y - p2.global_position.y).length(), 10.0, 60.0)
	var des_eye := Vector3(mid.x, mid.y + 3.0 + sep * 0.12, Fighter.PLANE_Z - (22.0 + sep * 0.85))
	var des_tgt := Vector3(mid.x, mid.y * 0.7 + 2.0, Fighter.PLANE_Z)
	var k : float = 1.0 - exp(-3.5 * delta)
	cam_eye = cam_eye.lerp(des_eye, k)
	cam_tgt = cam_tgt.lerp(des_tgt, k)
	var off := Vector3.ZERO
	if shake > 0.0:
		off = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake
	cam.global_position = cam_eye + off
	cam.look_at(cam_tgt, Vector3.UP)

# ---- effects called from Fighter / Projectile ----
func spawn_burst(pos: Vector3, col: Color) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.6
	s.height = 1.2
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = col
	m.material_override = mat
	m.position = pos
	add_child(m)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3(4, 4, 4), 0.3)
	tw.tween_property(mat, "albedo_color", Color(col.r, col.g, col.b, 0.0), 0.3)
	tw.chain().tween_callback(m.queue_free)

func on_transform(f: Fighter) -> void:
	shake = 0.6
	spawn_burst(f.global_position + Vector3.UP, f.aura_color())
