extends Node3D

@export var color: Color = Color(0.132, 0.496, 0.78, 1.0)   # Amarillo cálido, ajústalo a tu gusto
@export var emission_energy: float = 3.0
@export var lifetime: float = 0.12                 # Segundos que dura la estela
@export var fade_speed: float = 8.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var timer: Timer = $Timer

var _material: StandardMaterial3D


func setup(from: Vector3, to: Vector3) -> void:
	var distance := from.distance_to(to)

	# --- Posición y orientación ---
	global_position = (from + to) / 2.0
	# look_at necesita que 'to' no sea igual a 'from'
	if distance > 0.001:
		look_at(to, Vector3.UP)

	# --- Mesh: cilindro delgado de longitud = distancia ---
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = distance
	cylinder.radial_segments = 6   # Pocas caras, es un efecto rápido

	# CylinderMesh apunta en Y, pero look_at orienta en -Z → corregir con rotación local
	mesh_instance.rotation_degrees.x = 90.0
	mesh_instance.mesh = cylinder

	# --- Material con emisión ---
	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	_material.emission_enabled = true
	_material.emission = color
	_material.emission_energy_multiplier = emission_energy
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.set_surface_override_material(0, _material)

	# --- Iniciar temporizador de vida ---
	timer.wait_time = lifetime
	timer.start()


func _process(delta: float) -> void:
	if _material == null:
		return
	# Desvanecer el alpha progresivamente hasta 0
	var a := _material.albedo_color.a
	_material.albedo_color.a = move_toward(a, 0.0, delta * fade_speed)
	_material.emission_energy_multiplier = move_toward(
		_material.emission_energy_multiplier, 0.0, delta * fade_speed * emission_energy
	)


func _on_timer_timeout() -> void:
	queue_free()
