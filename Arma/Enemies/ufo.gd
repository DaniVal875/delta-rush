class_name Ufo
extends CharacterBody3D

@export_category("Combate")
@export var vida_maxima: float = 100.0
@export var rango_disparo: float = 8.0         # Distancia máxima para disparar
@export var cadencia_disparo: float = 2.0      # Segundos entre disparos
@export var spread_disparo: float = 0.15       # Imprecisión del disparo (más alto = menos preciso)
@export var projectile_scene: PackedScene      # Arrastra UfoProjectile.tscn aquí

@export_category("Movimiento")
@export var velocidad_maxima: float = 6.0
@export var aceleracion: float = 2.0          # Qué tan rápido alcanza velocidad máxima
@export var friccion: float = 3.0             # Qué tan rápido frena (el efecto "hielo")
@export var rango_persecucion: float = 10.0   # Distancia a la que empieza a moverse
@export var rango_detenerse: float = 4.0      # Distancia a la que se detiene
@export var altura_vuelo: float = 3.0         # Altura fija en Y que mantiene el ovni

@export var explosion_scene: PackedScene #Para la animación de la explosión al morir

@onready var health: HealthComponent = $HealthComponent


var _jugador: CharacterBody3D = null
var _velocidad_actual: Vector3 = Vector3.ZERO
var _temporizador_disparo: float = 0.0

var is_active: bool = true

# Memoria de posición para poder regresar a su lugar
var posicion_inicial: Vector3
var rotacion_inicial: Vector3


func _ready() -> void:
	# Guardamos dónde nació en el mapa
	posicion_inicial = global_position
	rotacion_inicial = global_rotation
	
	health.vida_maxima = vida_maxima
	health.vida_agotada.connect(_on_vida_agotada)
	
	# Aseguramos que pertenece a los grupos correctos desde el inicio
	if not is_in_group("ovnis"):
		add_to_group("ovnis")
	if not is_in_group("reiniciables"):
		add_to_group("reiniciables")
		
	await get_tree().process_frame
	var jugadores = get_tree().get_nodes_in_group("player")
	if jugadores.size() > 0:
		_jugador = jugadores[0]


func _physics_process(delta: float) -> void:
	if _jugador == null or not health.esta_vivo():
		return

	_manejar_altura(delta)
	_manejar_movimiento(delta)
	_manejar_disparo(delta)
	move_and_slide()


func _manejar_altura(delta: float) -> void:
	var diferencia_y = altura_vuelo - global_position.y
	velocity.y = diferencia_y * 5.0 * delta


func _manejar_movimiento(delta: float) -> void:
	var distancia := global_position.distance_to(_jugador.global_position)
	var direccion_deseada := Vector3.ZERO

	if distancia > rango_detenerse and distancia <= rango_persecucion:
		var dir := (_jugador.global_position - global_position)
		dir.y = 0.0
		direccion_deseada = dir.normalized()

	if direccion_deseada != Vector3.ZERO:
		_velocidad_actual = _velocidad_actual.move_toward(
			direccion_deseada * velocidad_maxima, aceleracion * delta
		)
	else:
		_velocidad_actual = _velocidad_actual.move_toward(Vector3.ZERO, friccion * delta)

	velocity.x = _velocidad_actual.x
	velocity.z = _velocidad_actual.z

	if _velocidad_actual.length() > 0.1:
		var objetivo := Vector3(_jugador.global_position.x, global_position.y, _jugador.global_position.z)
		look_at(objetivo, Vector3.UP)


func _manejar_disparo(delta: float) -> void:
	_temporizador_disparo -= delta
	if _temporizador_disparo > 0.0:
		return

	var distancia := global_position.distance_to(_jugador.global_position)
	if distancia > rango_disparo:
		return

	_temporizador_disparo = cadencia_disparo
	_disparar()


func _disparar() -> void:
	if projectile_scene == null:
		push_warning("Ufo: projectile_scene no asignado en el Inspector.")
		return

	# Dirección base hacia el jugador con imprecisión aplicada
	var dir_base := (_jugador.global_position - global_position).normalized()
	var spread_x := randf_range(-spread_disparo, spread_disparo)
	var spread_y := randf_range(-spread_disparo, spread_disparo)

	# Calcular ejes perpendiculares a la dirección para aplicar el spread
	var eje_derecho := dir_base.cross(Vector3.UP).normalized()
	var eje_arriba := dir_base.cross(eje_derecho).normalized()
	var dir_final := (dir_base + eje_derecho * spread_x + eje_arriba * spread_y).normalized()

	var proyectil = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proyectil)
	proyectil.setup(global_position, dir_final)


func on_bullet_hit(hit_position: Vector3, hit_normal: Vector3, dano: float) -> void:
	if health.esta_vivo():
		health.recibir_danio(dano)


func _on_vida_agotada() -> void:
	# 1. Ejecutar la explosión
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
		
	# 2. Lo sacamos del grupo temporalmente
	if is_in_group("ovnis"):
		remove_from_group("ovnis")
		
	# 3. Ocultamos exactamente tu nodo "UfoModel"
	if has_node("UfoModel"):
		$UfoModel.visible = false
		
	# 4. Desactivamos la colisión
	var shape_node := find_child("CollisionShape3D") as CollisionShape3D
	if shape_node:
		shape_node.set_deferred("disabled", true)


func reiniciar_elemento() -> void:
	is_active = true
	
	# 0. ¡Lo teletransportamos de regreso a donde nació en el mapa!
	global_position = posicion_inicial
	global_rotation = rotacion_inicial
	_velocidad_actual = Vector3.ZERO
	
	# 1. Le devolvemos la vida
	if health.has_method("reiniciar"):
		health.reiniciar()
	elif "vida_actual" in health:
		health.vida_actual = health.vida_maxima
		
	# 2. Volvemos a hacer visible tu nodo "UfoModel"
	if has_node("UfoModel"):
		$UfoModel.visible = true
		
	# 3. Reactivamos la colisión
	var shape_node := find_child("CollisionShape3D") as CollisionShape3D
	if shape_node:
		shape_node.set_deferred("disabled", false)
		
	# 4. Lo regresamos al grupo
	if not is_in_group("ovnis"):
		add_to_group("ovnis")
