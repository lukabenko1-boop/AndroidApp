extends Node3D
class_name Fighter
## A stick-figure ki fighter (2.5D, Lemming-Ball-Z-style). Ports the web build:
## two-axis flight (X + altitude) on a locked depth plane, melee, ki blasts,
## chargeable beams, ki charging with power tiers -> SURGE, named transformations
## (Base/Ascended/Super) with per-form aura colours, blocking, slams, and an FSM AI.

const ACCEL := 95.0
const MAXSPD := 20.0
const DRAG := 3.2
const GRAV := 22.0
const PLANE_Z := 14.0   # fighters are locked to this depth plane (2.5D like Lemming Ball Z)
const HOVER := 5.0
const ALTK := 5.2
const KI_MAX := 100.0
const HP_MAX := 100.0
const BLAST_COST := 20.0
const CHARGE_RATE := 44.0
const REGEN := 6.0
const OC_RATE := 40.0
const OC_DECAY := 7.0
const MELEE_DMG := 9.0
const BLAST_DMG := 11.0
const BLOCK_MUL := 0.26
const MELEE_CD := 0.32
const BLAST_CD := 0.40
const MELEE_RANGE := 6.5
const HITSTUN := 0.22
const MELEE_KNOCK := 20.0
const BLAST_SPD := 36.0
const BLAST_R := 0.7
const SLAM_SPD := 13.0
const SLAM_K := 0.9
const BEAM_MIN := 24.0
const BEAM_COST := 40.0
const BEAM_DPS := 52.0
const BEAM_DUR := 0.5
const BEAM_THICK := 0.9
const BEAM_CHRATE := 0.85
const BEAM_KNOCK := 15.0
const BEAM_RANGE := 110.0
const RADIUS := 1.4
const TIER_MUL := 0.12
const SURGE_MUL := 0.35
# LBZ-style power level: damage & knockback scale with powerlevel/2
const POWER_BASE := 2.0
const POWER_CAP := 5.4
const POWER_GAIN := 1.15
const POWER_DECAY := 0.35
const POWER_MUL_CAP := 3.6
const WALL_SLAM_K := 0.9

const FORMS := [
	{"n": "", "spd": 1.0, "drain": 0.0, "pmul": 1.0},
	{"n": "ASCENDED", "spd": 1.16, "drain": 8.0, "pmul": 1.45},
	{"n": "SUPER", "spd": 1.32, "drain": 14.0, "pmul": 1.95},
]

# identity
var base_color : Color
var tc1 : Color
var tc2 : Color
var fighter_name : String
var is_cpu : bool
var game : Node
var terrain : Terrain

# state
var vel := Vector3.ZERO
var hp := HP_MAX
var ki := KI_MAX * 0.4
var melee_cd := 0.0
var blast_cd := 0.0
var beam_cd := 0.0
var transform_cd := 0.0
var hitstun := 0.0
var flash := 0.0
var punch_anim := 0.0
var charging := false
var blocking := false
var charge_time := 0.0
var tier := 0
var overcharge := 0.0
var power := POWER_BASE
var form := 0
var form_timer := 0.0
var beam_state := "none"   # none / charging / firing
var beam_charge := 0.0
var beam_time := 0.0
var beam_pow := 0.0

# ai
var _ai_think := 0.0
var _ai_mode := "idle"
var _ai_jx := 0.0
var _ai_charge_t := 0.0
var _ai_beam_t := 0.0

# nodes
var _head : MeshInstance3D
var _hair : MeshInstance3D
var _arm_l : Node3D
var _arm_r : Node3D
var _leg_l : Node3D
var _leg_r : Node3D
var _aura_mesh : MeshInstance3D
var _aura_light : OmniLight3D
var _beam_mesh : MeshInstance3D
var _body_mat : StandardMaterial3D
var _aura_mat : StandardMaterial3D
var _hair_mat : StandardMaterial3D
var _beam_mat : StandardMaterial3D

func setup(g: Node, terr: Terrain, cpu: bool, nm: String, col: Color, t1: Color, t2: Color) -> void:
	game = g
	terrain = terr
	is_cpu = cpu
	fighter_name = nm
	base_color = col
	tc1 = t1
	tc2 = t2

func is_alive() -> bool: return hp > 0.0

func aura_color() -> Color:
	if form == 2: return tc2
	if form == 1: return tc1
	if overcharge > 2.0: return Color(1.0, 0.88, 0.44)
	return base_color

func power_level() -> float:
	return power * FORMS[form].pmul + (0.6 if overcharge > 2.0 else 0.0)

func atk_mul() -> float:
	return clampf(power_level() / 2.0, 1.0, POWER_MUL_CAP)

func knock_scale() -> float:
	return 0.6 + 0.42 * atk_mul()

func strength() -> float:
	return (0.6 + beam_pow) * atk_mul()

func _ready() -> void:
	_build_body()

func _mat(c: Color, rough := 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _capsule(r: float, h: float, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = h
	mi.mesh = cap
	mi.material_override = _mat(c)
	return mi

func _limb(shoulder: Vector3, length: float, r: float, c: Color) -> Node3D:
	# pivot at the shoulder/hip; capsule hangs down -Y so rotating the pivot swings it
	var pivot := Node3D.new()
	pivot.position = shoulder
	var cap := _capsule(r, length, c)
	cap.position = Vector3(0, -length * 0.5, 0)
	pivot.add_child(cap)
	add_child(pivot)
	return pivot

func _build_body() -> void:
	_body_mat = _mat(base_color, 0.45)
	var dark := base_color.darkened(0.35)
	# ---- STICK FIGURE ----
	# spine (thin)
	var spine := _capsule(0.09, 1.3, base_color)
	spine.position = Vector3(0, 0.95, 0)
	spine.material_override = _body_mat
	add_child(spine)
	# head (small)
	_head = MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.42
	hs.height = 0.84
	_head.mesh = hs
	_head.position = Vector3(0, 2.0, 0)
	_head.material_override = _mat(base_color.lightened(0.14), 0.4)
	add_child(_head)
	# hair (cone) — recoloured on transform
	_hair = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.26
	cone.height = 0.6
	_hair.mesh = cone
	_hair.position = Vector3(0, 2.5, -0.04)
	_hair.rotation = Vector3(-0.3, 0, 0)
	_hair_mat = _mat(dark, 0.5)
	_hair.material_override = _hair_mat
	add_child(_hair)
	# eyes (front = -Z)
	for sx in [-0.16, 0.16]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.09
		es.height = 0.18
		eye.mesh = es
		eye.position = Vector3(sx, 2.05, -0.36)
		eye.material_override = _mat(Color(0.08, 0.1, 0.14), 0.3)
		add_child(eye)
	# limbs (thin sticks, in the fighter's colour)
	_arm_l = _limb(Vector3(-0.12, 1.55, 0), 0.95, 0.08, base_color)
	_arm_r = _limb(Vector3(0.12, 1.55, 0), 0.95, 0.08, base_color)
	_leg_l = _limb(Vector3(-0.12, 0.35, 0), 1.05, 0.09, base_color)
	_leg_r = _limb(Vector3(0.12, 0.35, 0), 1.05, 0.09, base_color)
	# aura sphere (emissive, additive)
	_aura_mesh = MeshInstance3D.new()
	var as3 := SphereMesh.new()
	as3.radius = 1.9
	as3.height = 3.8
	_aura_mesh.mesh = as3
	_aura_mesh.position = Vector3(0, 1.1, 0)
	_aura_mat = StandardMaterial3D.new()
	_aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aura_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_aura_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aura_mat.albedo_color = Color(1, 1, 1, 0.0)
	_aura_mesh.material_override = _aura_mat
	add_child(_aura_mesh)
	_aura_light = OmniLight3D.new()
	_aura_light.position = Vector3(0, 1.2, 0)
	_aura_light.light_energy = 0.0
	_aura_light.omni_range = 9.0
	add_child(_aura_light)
	# beam (world-space)
	_beam_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = BEAM_THICK
	cyl.bottom_radius = BEAM_THICK
	cyl.height = 1.0
	_beam_mesh.mesh = cyl
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.emission_enabled = true
	_beam_mesh.material_override = _beam_mat
	_beam_mesh.top_level = true
	_beam_mesh.visible = false
	add_child(_beam_mesh)

func reset(pos: Vector3, face_cpu: bool) -> void:
	global_position = pos
	vel = Vector3.ZERO
	hp = HP_MAX
	ki = KI_MAX * 0.4
	melee_cd = 0.0; blast_cd = 0.0; beam_cd = 0.0; transform_cd = 0.0
	hitstun = 0.0; flash = 0.0; punch_anim = 0.0
	charging = false; blocking = false; charge_time = 0.0; tier = 0; overcharge = 0.0
	form = 0; form_timer = 0.0
	power = POWER_BASE
	beam_state = "none"; beam_charge = 0.0; beam_time = 0.0; beam_pow = 0.0

func dir_to(o: Fighter) -> Vector3:
	return (o.global_position - global_position).normalized()

func hurt(d: float, kb: Vector3, blocked: bool) -> void:
	var m := BLOCK_MUL if blocked else 1.0
	hp = maxf(0.0, hp - d * m)
	vel += kb * (0.3 if blocked else 1.0)
	hitstun = 0.08 if blocked else HITSTUN
	flash = 0.12
	if game.has_method("spawn_burst"):
		game.spawn_burst(global_position + Vector3.UP, Color(1, 0.82, 0.48) if not blocked else Color(0.74, 0.82, 1))

func do_melee(o: Fighter) -> void:
	if melee_cd > 0.0 or hitstun > 0.0: return
	melee_cd = MELEE_CD
	punch_anim = 0.2
	if global_position.distance_to(o.global_position) < MELEE_RANGE:
		var d := dir_to(o)
		o.hurt(MELEE_DMG * atk_mul(), d * (MELEE_KNOCK * knock_scale()) + Vector3.UP * 5.0, o.blocking)

func do_blast(o: Fighter) -> void:
	if blast_cd > 0.0 or hitstun > 0.0 or ki < BLAST_COST: return
	blast_cd = BLAST_CD
	ki -= BLAST_COST
	var su := overcharge > 2.0 or form > 0
	var d := dir_to(o)
	var p := Projectile.new()
	p.setup(global_position + d * (RADIUS + 0.6) + Vector3.UP, d * BLAST_SPD, self, o,
		BLAST_DMG * atk_mul(), aura_color() if su else base_color,
		BLAST_R * (1.5 if su else 1.0), 3.0 * (1.6 if su else 1.0), terrain)
	game.add_child(p)
	if overcharge > 2.0: overcharge = maxf(0.0, overcharge - 26.0)

func fire_beam(o: Fighter) -> void:
	beam_state = "firing"
	beam_pow = beam_charge
	beam_time = BEAM_DUR * (0.7 + beam_charge * 1.1)
	ki = maxf(0.0, ki - BEAM_COST * (0.4 + beam_charge * 0.6))
	beam_cd = 0.6

func try_transform() -> void:
	if form >= 2 or transform_cd > 0.0: return
	form += 1
	overcharge = 0.0
	form_timer = 9.0 - form * 1.5
	transform_cd = 0.6
	ki = KI_MAX
	power = minf(POWER_CAP, power + 1.4)   # transform spikes power level
	terrain.carve(global_position.x, global_position.z, RADIUS * 3.0, 1.5)
	if game.has_method("on_transform"):
		game.on_transform(self)

func control(inp: Dictionary, o: Fighter, delta: float) -> void:
	charging = false
	blocking = false
	var want_beam : bool = inp.get("beam", false) and hitstun <= 0.0 and beam_cd <= 0.0
	if beam_state == "firing":
		pass
	elif want_beam and (beam_state == "charging" or ki >= BEAM_MIN):
		beam_state = "charging"
		beam_charge = minf(1.0, beam_charge + BEAM_CHRATE * delta)
		ki = maxf(0.0, ki - 6.0 * delta)
	else:
		if beam_state == "charging":
			if beam_charge >= 0.25: fire_beam(o)
			else: beam_state = "none"; beam_charge = 0.0
		charging = inp.get("charge", false) and hitstun <= 0.0
		blocking = inp.get("block", false) and not charging and hitstun <= 0.0
	var sm : float = FORMS[form].spd
	var slow := 0.14 if beam_state != "none" else (0.18 if charging else (0.4 if blocking else 1.0))
	vel.x += inp.get("mx", 0.0) * slow * ACCEL * sm * delta
	vel.y += inp.get("mz", 0.0) * slow * ACCEL * sm * delta   # second axis = altitude (2.5D)
	if beam_state == "none":
		if inp.get("punch", false): do_melee(o)
		if inp.get("blast", false): do_blast(o)
	if inp.get("transform", false) and overcharge >= 60.0: try_transform()

func tick(delta: float, inp: Dictionary, o: Fighter) -> void:
	melee_cd = maxf(0.0, melee_cd - delta)
	blast_cd = maxf(0.0, blast_cd - delta)
	beam_cd = maxf(0.0, beam_cd - delta)
	transform_cd = maxf(0.0, transform_cd - delta)
	hitstun = maxf(0.0, hitstun - delta)
	flash = maxf(0.0, flash - delta)
	punch_anim = maxf(0.0, punch_anim - delta)
	if beam_state == "firing":
		beam_time -= delta
		if beam_time <= 0.0:
			beam_state = "none"; beam_charge = 0.0
	var use_inp := inp
	if hitstun > 0.0:
		use_inp = {}
	control(use_inp, o, delta)
	# charge / surge
	if charging:
		charge_time += delta
		tier = 3 if charge_time > 2.8 else (2 if charge_time > 1.4 else (1 if charge_time > 0.5 else 0))
		ki += CHARGE_RATE * delta
		if ki >= KI_MAX:
			ki = KI_MAX
			overcharge = minf(100.0, overcharge + OC_RATE * delta)
		power = minf(POWER_CAP, power + POWER_GAIN * delta)   # charging raises power level
		if tier >= 2:
			var dd := dir_to(o)
			if global_position.distance_to(o.global_position) < 12.0:
				o.vel -= dd * 14.0 * delta
	else:
		charge_time = 0.0
		tier = 0
		ki = minf(KI_MAX, ki + REGEN * delta)
		power = maxf(POWER_BASE, power - POWER_DECAY * delta)   # power bleeds back down
		overcharge = maxf(0.0, overcharge - OC_DECAY * delta)
	# form drain
	if form > 0:
		form_timer -= delta
		ki = maxf(0.0, ki - FORMS[form].drain * delta)
		if form_timer <= 0.0 or ki <= 0.0:
			form = 0
	# physics: two-axis flight (X + altitude Y); LBZ momentum — knockback carries while stunned
	var dr : float = exp(-(DRAG * 0.4 if hitstun > 0.0 else DRAG) * delta)
	vel.x *= dr
	vel.y *= dr
	vel.y -= GRAV * delta
	var hs := Vector2(vel.x, vel.y).length()
	var mx : float = (MAXSPD + (30.0 if hitstun > 0.0 else 0.0)) * FORMS[form].spd
	if hs > mx:
		vel.x *= mx / hs
		vel.y *= mx / hs
	vel.z = 0.0
	global_position.z = PLANE_Z
	var gy := terrain.height_at(global_position.x, PLANE_Z)
	global_position.x += vel.x * delta
	global_position.y += vel.y * delta
	# bounds — wall slam takes damage + bounce
	if global_position.x < terrain.AX0 + RADIUS:
		global_position.x = terrain.AX0 + RADIUS
		if vel.x < -SLAM_SPD: hp = maxf(0.0, hp - (-vel.x - SLAM_SPD) * WALL_SLAM_K)
		vel.x *= -0.5
	elif global_position.x > terrain.AX1 - RADIUS:
		global_position.x = terrain.AX1 - RADIUS
		if vel.x > SLAM_SPD: hp = maxf(0.0, hp - (vel.x - SLAM_SPD) * WALL_SLAM_K)
		vel.x *= -0.5
	if global_position.y > 46.0:
		global_position.y = 46.0
		vel.y = -absf(vel.y) * 0.3
	# terrain floor + slam
	if global_position.y < gy + RADIUS:
		var imp := -vel.y
		global_position.y = gy + RADIUS
		if imp > SLAM_SPD:
			terrain.carve(global_position.x, PLANE_Z, RADIUS * 2.0, 1.4)
			hp = maxf(0.0, hp - (imp - SLAM_SPD) * SLAM_K)
			vel.y = imp * 0.42
		else:
			vel.y = absf(vel.y) * 0.3
		vel.x *= 0.85
	# face opponent (profile to the front camera)
	var flat := Vector3(o.global_position.x, global_position.y, o.global_position.z)
	if global_position.distance_to(flat) > 0.2:
		look_at(flat, Vector3.UP)
	_animate(delta)
	_resolve_beam(o, delta)

func _lerp_rot(pivot: Node3D, target: Vector3, delta: float) -> void:
	pivot.rotation = pivot.rotation.lerp(target, clampf(delta * 12.0, 0.0, 1.0))

func _animate(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# arm/leg targets by state (local pivot euler)
	var aL := Vector3(0.15, 0, 0.25)
	var aR := Vector3(0.15, 0, -0.25)
	var lL := Vector3(0.1, 0, 0.08)
	var lR := Vector3(-0.1, 0, -0.08)
	if punch_anim > 0.0:
		aR = Vector3(-1.5, 0, -0.05)
	elif blocking:
		aL = Vector3(-1.1, 0, 0.4); aR = Vector3(-1.1, 0, -0.4)
	elif beam_state != "none":
		aL = Vector3(-1.4, 0, 0.15); aR = Vector3(-1.4, 0, -0.15)
	elif charging:
		aL = Vector3(0.7, 0, 0.5); aR = Vector3(0.7, 0, -0.5)
	elif Vector2(vel.x, vel.y).length() > 6.0:
		var s := sin(t * 10.0) * 0.5
		aL = Vector3(0.2 + s, 0, 0.2); aR = Vector3(0.2 - s, 0, -0.2)
		lL = Vector3(0.3 - s, 0, 0.08); lR = Vector3(0.3 + s, 0, -0.08)
	_lerp_rot(_arm_l, aL, delta)
	_lerp_rot(_arm_r, aR, delta)
	_lerp_rot(_leg_l, lL, delta)
	_lerp_rot(_leg_r, lR, delta)
	# aura
	var su := charging or overcharge > 2.0 or form > 0
	var col := aura_color()
	var a := 0.0
	if charging: a = 0.28 + 0.12 * tier + 0.08 * sin(t * 20.0)
	elif form > 0: a = 0.3
	elif overcharge > 2.0: a = 0.24
	_aura_mat.albedo_color = Color(col.r, col.g, col.b, a)
	_aura_light.light_color = col
	_aura_light.light_energy = (2.0 if form > 0 else (1.4 if su else 0.0)) + (0.6 * tier if charging else 0.0)
	var asc := 1.0 + 0.12 * tier + (0.35 if form > 0 else 0.0)
	_aura_mesh.scale = Vector3(asc, asc, asc)
	# hair colour/size with form
	_hair_mat.albedo_color = col if form > 0 else base_color.darkened(0.3)
	_hair.scale = Vector3(1, 1.0 + form * 0.5, 1)

func _resolve_beam(o: Fighter, delta: float) -> void:
	if beam_state != "firing":
		_beam_mesh.visible = false
		return
	var d := dir_to(o)
	var muzzle := global_position + d * (RADIUS + 0.6) + Vector3.UP * 0.4
	var length := BEAM_RANGE
	# carve terrain along the beam
	var tt := 0.0
	while tt < length:
		var pp := muzzle + d * tt
		if pp.y <= terrain.height_at(pp.x, pp.z) + BEAM_THICK:
			terrain.carve(pp.x, pp.z, BEAM_THICK * 1.6, BEAM_THICK)
		tt += 1.4
	# damage opponent by distance to the ray
	var rel := o.global_position - muzzle
	var proj := clampf(rel.dot(d), 0.0, length)
	var closest := muzzle + d * proj
	if o.global_position.distance_to(closest) < BEAM_THICK + RADIUS:
		var dmg : float = BEAM_DPS * (0.6 + beam_pow) * atk_mul() * delta
		o.hp = maxf(0.0, o.hp - dmg * (BLOCK_MUL if o.blocking else 1.0))
		o.vel += d * BEAM_KNOCK * delta
		o.hitstun = maxf(o.hitstun, 0.05)
	# visual
	var col := aura_color()
	var mid := muzzle + d * (length * 0.5)
	var cyl := _beam_mesh.mesh as CylinderMesh
	var thick : float = BEAM_THICK * (0.7 + beam_pow * 0.9)
	cyl.top_radius = thick
	cyl.bottom_radius = thick
	cyl.height = length
	_beam_mat.emission = col
	_beam_mat.albedo_color = col
	var q := Quaternion(Vector3.UP, d)
	_beam_mesh.global_transform = Transform3D(Basis(q), mid)
	_beam_mesh.visible = true

# ---------------- AI ----------------
func ai_input(o: Fighter, delta: float) -> Dictionary:
	var inp := {"mx": 0.0, "mz": 0.0, "charge": false, "block": false, "beam": false,
		"punch": false, "blast": false, "transform": false}
	var dx := o.global_position.x - global_position.x
	var dy := o.global_position.y - global_position.y
	var dist := global_position.distance_to(o.global_position)
	var tX : float = signf(dx) if dx != 0.0 else 1.0
	var tY : float = signf(dy) if dy != 0.0 else 1.0
	# LBZ-style: fight relative to power level. Second axis (mz) drives altitude.
	var my_p := power_level()
	var op_p := o.power_level()
	var weak := op_p > my_p * 1.3
	var strong := my_p > op_p * 1.25
	if overcharge >= 100.0 and form < 2:
		inp.transform = true   # always cash in a ready transform
	if _ai_charge_t > 0.0:
		_ai_charge_t -= delta
		if dist < 14.0: inp.mx = -tX; inp.mz = 0.4
		else: inp.charge = true; inp.mz = 0.15
		return inp
	if _ai_beam_t > 0.0:
		_ai_beam_t -= delta
		inp.beam = true
		inp.mz = tY * 0.6 if absf(dy) > 4.0 else 0.1
		if dist < 18.0: inp.mx = -tX * 0.5
		return inp
	if _ai_think <= 0.0:
		_ai_think = (0.2 if strong else 0.3) + randf() * 0.35
		_ai_jx = (randf() * 2.0 - 1.0) * 0.7
		var r := randf()
		if ki < BLAST_COST and dist > 22.0: _ai_mode = "charge"
		elif weak and ki > 58.0 and r < 0.5 and dist > 16.0:
			_ai_charge_t = 0.8 + randf() * 0.9; _ai_mode = "idle"   # out-powered: retreat & power up
		elif not strong and overcharge < 3.0 and ki > 72.0 and r < 0.22 and dist > 20.0:
			_ai_charge_t = 0.7 + randf() * 0.7; _ai_mode = "idle"
		elif dist > 20.0 and r < (0.42 if strong else 0.3) and ki > BEAM_MIN + 12.0:
			_ai_beam_t = 0.6 + randf() * 0.5; _ai_mode = "idle"
		elif dist > 34.0: _ai_mode = "approach" if r < 0.6 else "blast"
		elif dist < 11.0: _ai_mode = ("melee" if r < 0.85 else "reposition") if strong else ("melee" if r < 0.6 else "reposition")
		else: _ai_mode = "blast" if r < 0.5 else "approach"
	match _ai_mode:
		"charge":
			inp.charge = ki < KI_MAX * 0.9
			inp.mz = 0.2
			if dist < 15.0: inp.mx = -tX; inp.charge = false
		"approach": inp.mx = tX; inp.mz = tY if absf(dy) > 3.0 else 0.2
		"blast":
			inp.mx = -tX * 0.5 if dist < 22.0 else _ai_jx
			inp.mz = tY if absf(dy) > 3.0 else 0.15
			if blast_cd <= 0.0 and randf() < 0.5: inp.blast = true
		"melee":
			inp.mx = tX; inp.mz = tY if absf(dy) > 2.0 else 0.2
			if dist < MELEE_RANGE and melee_cd <= 0.0: inp.punch = true
			if randf() < 0.15: inp.block = true
		"reposition": inp.mx = -tX + _ai_jx; inp.mz = 0.3
	return inp
