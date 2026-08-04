extends Node3D
class_name Projectile
## A ki blast: travels in 3D, carves terrain on ground impact, damages the
## opponent on contact.

var vel : Vector3
var owner_fig : Fighter
var target_fig : Fighter
var dmg : float = 11.0
var col : Color = Color.WHITE
var rad : float = 0.7
var carve_r : float = 3.0
var life : float = 1.8
var terrain : Terrain

func setup(pos: Vector3, v: Vector3, o: Fighter, t: Fighter, d: float, c: Color, r: float, cr: float, terr: Terrain) -> void:
	position = pos
	vel = v
	owner_fig = o
	target_fig = t
	dmg = d
	col = c
	rad = r
	carve_r = cr
	terrain = terr

func _ready() -> void:
	var m := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = rad
	sphere.height = rad * 2.0
	m.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.0
	m.material_override = mat
	add_child(m)
	var glow := OmniLight3D.new()
	glow.light_color = col
	glow.light_energy = 2.2
	glow.omni_range = 8.0
	add_child(glow)

func _physics_process(delta: float) -> void:
	life -= delta
	position += vel * delta
	if life <= 0.0 or position.x < terrain.AX0 or position.x > terrain.AX1 \
			or position.z < terrain.AZ0 or position.z > terrain.AZ1:
		queue_free()
		return
	if position.y < terrain.height_at(position.x, position.z):
		terrain.carve(position.x, position.z, carve_r, 1.4)
		_boom()
		queue_free()
		return
	if is_instance_valid(target_fig) and position.distance_to(target_fig.global_position) < rad + 1.4:
		if target_fig.has_method("hurt"):
			var ks : float = owner_fig.knock_scale() if is_instance_valid(owner_fig) else 1.0
			var kb := vel.normalized() * (16.0 * ks) + Vector3.UP * 3.0
			target_fig.hurt(dmg, kb, target_fig.blocking)
		queue_free()

func _boom() -> void:
	if owner_fig and owner_fig.get_parent() and owner_fig.get_parent().has_method("spawn_burst"):
		owner_fig.get_parent().spawn_burst(position, col)
