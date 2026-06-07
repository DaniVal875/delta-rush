class_name Weapon
extends Node3D

@export var ray_range: float = 100.0
@export var bullet_trail_scene: PackedScene
@export var cadencia: float = 0.1 
@export var dano: float = 25.0

@export_category("Disparo Dinámico (Bloom)")
@export var balas_precisas: int = 5 # Cuántas balas van perfectas antes de perder precisión
@export var balas_para_max_dispersion: int = 15 # A las cuántas balas se alcanza el descontrol máximo
@export var spread_maximo: float = 0.08 # Qué tan desviadas pueden llegar a ir las balas al máximo
@export var multiplicador_retroceso_max: float = 3.0 # Cuántas veces más fuerte será el retroceso al tope
@export var tiempo_enfriamiento_rafaga: float = 0.3 # Segundos sin disparar para reiniciar la precisión a 0

@export_category("Retroceso Visual Base")
@export var fuerza_retroceso_z: float = 0.15 # Qué tanto se hace hacia atrás
@export var fuerza_levantamiento_x: float = 0.05 # Qué tanto se levanta el cañón
@export var tiempo_patada: float = 0.05 # Lo rápido que da el golpe
@export var tiempo_recuperacion: float = 0.2 # Lo que tarda en volver a su lugar

@onready var particulas_fogonazo: GPUParticles3D = $GunModel/Muzzle/Fogonazo
@onready var luz_fogonazo: OmniLight3D = $GunModel/Muzzle/LuzFogonazo
@onready var muzzle: Marker3D = $GunModel/Muzzle

var _temporizador_disparo: float = 0.0
var energia_luz_maxima: float = 10.0

# Variables internas para controlar el descontrol del arma
var balas_disparadas_rafaga: int = 0
var tiempo_sin_disparar: float = 0.0

var posicion_original: Vector3
var rotacion_original: Vector3
var tween_retroceso: Tween

func _ready() -> void:
	luz_fogonazo.visible = false
	particulas_fogonazo.emitting = false
	posicion_original = position
	rotacion_original = rotation

func _process(delta: float) -> void:
	if _temporizador_disparo > 0.0:
		_temporizador_disparo -= delta
		
	# Sistema de enfriamiento: Si el jugador deja de disparar, el arma recupera la precisión
	tiempo_sin_disparar += delta
	if tiempo_sin_disparar >= tiempo_enfriamiento_rafaga:
		balas_disparadas_rafaga = 0

func shoot(ray_origin: Vector3, ray_basis: Basis, delta: float) -> void:
	if _temporizador_disparo > 0.0:
		return
	
	_temporizador_disparo = cadencia
	
	# 1. Actualizar el estado de la ráfaga
	tiempo_sin_disparar = 0.0
	balas_disparadas_rafaga += 1
	
	# 2. Calcular factor de descontrol (0.0 = perfecto, 1.0 = descontrol total)
	var factor_descontrol: float = 0.0
	if balas_disparadas_rafaga > balas_precisas:
		var balas_extra = balas_disparadas_rafaga - balas_precisas
		var rango_para_maximo = max(1, balas_para_max_dispersion - balas_precisas)
		# clampf asegura que el valor nunca pase de 1.0 (100% de descontrol)
		factor_descontrol = clampf(float(balas_extra) / float(rango_para_maximo), 0.0, 1.0)
		
	# 3. Calcular los valores dinámicos para este disparo en específico
	var spread_actual = lerpf(0.0, spread_maximo, factor_descontrol)
	var multiplicador_recoil = lerpf(1.0, multiplicador_retroceso_max, factor_descontrol)
	
	var hit_point := _cast_ray(ray_origin, ray_basis, spread_actual)
	_spawn_trail(muzzle.global_position, hit_point)
	_activar_efecto_disparo()
	_animar_retroceso(multiplicador_recoil)
	$AudioStreamPlayer.play()

# Ahora la función recibe el spread_actual como parámetro
func _cast_ray(ray_origin: Vector3, ray_basis: Basis, spread_actual: float) -> Vector3:
	var base_dir: Vector3 = -ray_basis.z

	var spread_x := randf_range(-spread_actual, spread_actual)
	var spread_y := randf_range(-spread_actual, spread_actual)
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
	get_tree().current_scene.add_child(trail)
	trail.setup(from, to)

func _activar_efecto_disparo() -> void:
	particulas_fogonazo.restart() 
	particulas_fogonazo.emitting = true
	
	luz_fogonazo.light_energy = energia_luz_maxima
	luz_fogonazo.visible = true
	
	var tween = create_tween()
	tween.tween_property(luz_fogonazo, "light_energy", 0.0, 0.05) 
	tween.tween_callback(func(): luz_fogonazo.visible = false)

# Ahora la función recibe un multiplicador para hacer el retroceso más violento
func _animar_retroceso(multiplicador: float) -> void:
	if tween_retroceso and tween_retroceso.is_running():
		tween_retroceso.kill()
		
	tween_retroceso = create_tween()
	
	# Multiplicamos la fuerza base por nuestro nivel de descontrol
	var pos_objetivo = posicion_original + Vector3(0, 0, fuerza_retroceso_z * multiplicador) 
	var rot_objetivo = rotacion_original + Vector3(fuerza_levantamiento_x * multiplicador, 0, 0)
	
	tween_retroceso.tween_property(self, "position", pos_objetivo, tiempo_patada).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_retroceso.parallel().tween_property(self, "rotation", rot_objetivo, tiempo_patada).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween_retroceso.tween_property(self, "position", posicion_original, tiempo_recuperacion).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween_retroceso.parallel().tween_property(self, "rotation", rotacion_original, tiempo_recuperacion).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
