class_name Weapon
extends Node3D

@export var ray_range: float = 100.0
@export var spread_radius: float = 0.02
@export var bullet_trail_scene: PackedScene
@export var cadencia: float = 1
@export var dano: float = 25.0

@onready var muzzle: Marker3D = $GunModel/Muzzle
var _temporizador_disparo: float = 0.0

func shoot(ray_origin: Vector3, ray_basis: Basis, delta: float) -> void:
	_temporizador_disparo -= delta
	if _temporizador_disparo > 0.0:
		return

	# Solo llega aquí cuando el temporizador llegó a 0
	_temporizador_disparo = cadencia
	var hit_point := _cast_ray(ray_origin, ray_basis)
	_spawn_trail(muzzle.global_position, hit_point)


func _cast_ray(ray_origin: Vector3, ray_basis: Basis) -> Vector3:
	var base_dir: Vector3 = -ray_basis.z

	var spread_x := randf_range(-spread_radius, spread_radius)
	var spread_y := randf_range(-spread_radius, spread_radius)
	var final_dir: Vector3 = (base_dir + ray_basis.x * spread_x + ray_basis.y * spread_y).normalized()

	var ray_end: Vector3 = ray_origin + final_dir * ray_range
	var space := get_world_3d().direct_space_state

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result := space.intersect_ray(query)

	if result:
		if result["collider"].has_method("on_bullet_hit"):
			result["collider"].on_bullet_hit(result["position"], result["normal"], dano)
		return result["position"]

	return ray_end


func _spawn_trail(from: Vector3, to: Vector3) -> void:
	if bullet_trail_scene == null:
		push_warning("Weapon: bullet_trail_scene no asignado en el Inspector.")
		return

	var trail = bullet_trail_scene.instantiate()

	# Se agrega a la escena raíz, NO como hijo del arma.
	# Si fuera hijo del arma, heredaría su transformada y la estela
	# se movería junto con el jugador mientras está visible.
	get_tree().current_scene.add_child(trail)

	trail.setup(from, to)
