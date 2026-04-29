extends CharacterBody3D

signal estado_cambiado(nuevo_estado)

enum EstadoMovimiento { SUELO, AIRE, CORRER_PARED, DESLIZARSE, AGACHADO }
var estado_actual: EstadoMovimiento = EstadoMovimiento.SUELO

@export_category("Movimiento")
@export var velocidad_caminar: float = 8.0
@export var velocidad_correr: float = 14.0
@export var velocidad_agachado: float = 4.0 
@export var sensibilidad_raton: float = 0.002
@export var sensibilidad_mando: float = 3.0 

@export_category("Apuntar")
@export var fov_normal: float = 75.0 
@export var fov_apuntar: float = 50.0    
@export var velocidad_apuntar: float = 15.0  
@export var multiplicador_sensibilidad_apuntar: float = 0.5 

@export_category("Deslizamiento")
@export var impulso_deslizamiento: float = 5.0 
@export var friccion_deslizamiento: float = 2.0 
@export var altura_cabeza_parado: float = 0.6
@export var altura_cabeza_agachado: float = 0.0

@export_category("Correr en Pared")
@export var velocidad_base_correr_pared: float = 14.0
@export var velocidad_maxima_correr_pared: float = 24.0 
@export var aceleracion_correr_pared: float = 8.0 
@export var tiempo_maximo_correr_pared: float = 3.0

@export_category("Movilidad Aerea")
@export var fuerza_salto: float = 7.5
@export var impulso_doble_salto: float = 12.0 

@export_category("Fisicas")
@export var multiplicador_gravedad: float = 1.5 
@export var gravedad_correr_pared: float = 1.0 
@export var angulo_inclinacion_camara: float = 0.25 

@onready var forma_parado: CollisionShape3D = $StandingShape
@onready var forma_agachado: CollisionShape3D = $CrouchShape
@onready var detector_techo: RayCast3D = $CeilingCheck 
@onready var cabeza: Node3D = $Head
@onready var camara: Camera3D = $Head/Camera3D
@onready var rayo_izquierdo: RayCast3D = $WallRayLeft
@onready var rayo_derecho: RayCast3D = $WallRayRight

var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity") * multiplicador_gravedad
var normal_pared: Vector3 = Vector3.ZERO
var corriendo_pared_izquierda: bool = false
var vector_deslizamiento: Vector3 = Vector3.ZERO 

var velocidad_actual: float = velocidad_caminar 
var doble_salto_usado: bool = false 
var temporizador_correr_pared: float = 0.0 
var esta_corriendo: bool = false 

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var sens_actual = sensibilidad_raton
		if Input.is_action_pressed("aim"):
			sens_actual *= multiplicador_sensibilidad_apuntar
			
		rotate_y(-event.relative.x * sens_actual)
		cabeza.rotate_x(-event.relative.y * sens_actual)
		cabeza.rotation.x = clamp(cabeza.rotation.x, -PI/2, PI/2)

func _physics_process(delta: float) -> void:
	var direccion_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if estado_actual == EstadoMovimiento.CORRER_PARED:
		temporizador_correr_pared += delta

	_manejar_camara_mando(delta)
	_actualizar_estado()
	_manejar_gravedad(delta)
	_manejar_saltos()
	_manejar_movimiento(direccion_input, delta)
	_manejar_postura(delta) 
	_manejar_inclinacion_camara(delta)
	_manejar_apuntado(delta)
	
	move_and_slide()

func _manejar_camara_mando(delta: float) -> void:
	var direccion_mirada := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if direccion_mirada != Vector2.ZERO:
		var sens_actual = sensibilidad_mando
		if Input.is_action_pressed("aim"):
			sens_actual *= multiplicador_sensibilidad_apuntar
			
		rotate_y(-direccion_mirada.x * sens_actual * delta)
		cabeza.rotate_x(-direccion_mirada.y * sens_actual * delta)
		cabeza.rotation.x = clamp(cabeza.rotation.x, -PI/2, PI/2)

func _actualizar_estado() -> void:
	if is_on_floor():
		doble_salto_usado = false
		temporizador_correr_pared = 0.0
		
		var quiere_agacharse = Input.is_action_pressed("crouch")
		var puede_pararse = not detector_techo.is_colliding()
		
		if quiere_agacharse or not puede_pararse:
			if velocidad_actual > velocidad_caminar * 0.5 and estado_actual not in [EstadoMovimiento.DESLIZARSE, EstadoMovimiento.AGACHADO]:
				velocidad_actual += impulso_deslizamiento
				vector_deslizamiento = (-global_transform.basis.z).normalized() 
				_establecer_estado(EstadoMovimiento.DESLIZARSE)
			elif estado_actual == EstadoMovimiento.DESLIZARSE and velocidad_actual <= velocidad_agachado:
				_establecer_estado(EstadoMovimiento.AGACHADO)
			elif estado_actual != EstadoMovimiento.DESLIZARSE:
				_establecer_estado(EstadoMovimiento.AGACHADO)
		else:
			_establecer_estado(EstadoMovimiento.SUELO)
			
	elif _puede_correr_pared():
		doble_salto_usado = false 
		if estado_actual != EstadoMovimiento.CORRER_PARED:
			velocidad_actual = max(velocidad_actual, velocidad_base_correr_pared)
		_establecer_estado(EstadoMovimiento.CORRER_PARED)
	else:
		_establecer_estado(EstadoMovimiento.AIRE)

func _establecer_estado(nuevo_estado: EstadoMovimiento) -> void:
	if estado_actual == nuevo_estado: return
	estado_actual = nuevo_estado
	estado_cambiado.emit(estado_actual)

func _puede_correr_pared() -> bool:
	if is_on_floor(): return false
	if not Input.is_action_pressed("move_forward"): return false
	if temporizador_correr_pared >= tiempo_maximo_correr_pared: return false
	if Input.is_action_pressed("crouch"): return false 
	
	if rayo_izquierdo.is_colliding():
		normal_pared = rayo_izquierdo.get_collision_normal()
		corriendo_pared_izquierda = true
		return true
	elif rayo_derecho.is_colliding():
		normal_pared = rayo_derecho.get_collision_normal()
		corriendo_pared_izquierda = false
		return true
		
	return false

func _manejar_gravedad(delta: float) -> void:
	if estado_actual in [EstadoMovimiento.SUELO, EstadoMovimiento.DESLIZARSE, EstadoMovimiento.AGACHADO]:
		return
	elif estado_actual == EstadoMovimiento.CORRER_PARED:
		velocity.y -= gravedad_correr_pared * delta
	else:
		velocity.y -= gravedad * delta

func _manejar_saltos() -> void:
	if Input.is_action_just_pressed("jump"):
		if estado_actual in [EstadoMovimiento.AGACHADO, EstadoMovimiento.DESLIZARSE] and detector_techo.is_colliding():
			return 
			
		if estado_actual == EstadoMovimiento.CORRER_PARED:
			velocity.y = fuerza_salto
			var direccion_salto: Vector3 = normal_pared * velocidad_correr
			velocity.x = direccion_salto.x
			velocity.z = direccion_salto.z
			temporizador_correr_pared = 0.0
			
		elif estado_actual in [EstadoMovimiento.DESLIZARSE, EstadoMovimiento.AGACHADO, EstadoMovimiento.SUELO]:
			velocity.y = fuerza_salto
			
		elif not is_on_floor() and not doble_salto_usado:
			doble_salto_usado = true
			velocity.y = fuerza_salto
			
			var frente_jugador := -cabeza.global_transform.basis.z
			frente_jugador.y = 0 
			velocity += frente_jugador.normalized() * impulso_doble_salto

func _manejar_movimiento(direccion_input: Vector2, delta: float) -> void:
	if Input.is_action_just_pressed("sprint") and direccion_input != Vector2.ZERO:
		esta_corriendo = true
	if direccion_input == Vector2.ZERO:
		esta_corriendo = false

	if estado_actual == EstadoMovimiento.CORRER_PARED:
		velocidad_actual = move_toward(velocidad_actual, velocidad_maxima_correr_pared, aceleracion_correr_pared * delta)
		
		var frente_pared := Vector3.UP.cross(normal_pared).normalized()
		var frente_jugador := -global_transform.basis.z
		
		if frente_pared.dot(frente_jugador) < 0:
			frente_pared = -frente_pared
			
		var velocidad_objetivo: Vector3 = frente_pared * velocidad_actual
		
		velocity.x = velocidad_objetivo.x - (normal_pared.x * 2.0)
		velocity.z = velocidad_objetivo.z - (normal_pared.z * 2.0)
		
	elif estado_actual == EstadoMovimiento.DESLIZARSE:
		velocidad_actual = lerpf(velocidad_actual, 0.0, friccion_deslizamiento * delta)
		
		var direccion := (transform.basis * Vector3(direccion_input.x, 0, direccion_input.y)).normalized()
		var direccion_deslizamiento: Vector3 = vector_deslizamiento.lerp(direccion, 2.0 * delta).normalized()
		
		velocity.x = direccion_deslizamiento.x * velocidad_actual
		velocity.z = direccion_deslizamiento.z * velocidad_actual
		
	elif estado_actual == EstadoMovimiento.AGACHADO:
		var direccion := (transform.basis * Vector3(direccion_input.x, 0, direccion_input.y)).normalized()
		velocidad_actual = lerpf(velocidad_actual, velocidad_agachado, 15.0 * delta)
		velocity.x = direccion.x * velocidad_actual
		velocity.z = direccion.z * velocidad_actual
		
	else:
		var direccion := (transform.basis * Vector3(direccion_input.x, 0, direccion_input.y)).normalized()
		var velocidad_objetivo_esperada = velocidad_correr if esta_corriendo else velocidad_caminar
		
		var aceleracion = 5.0 if velocidad_actual > velocidad_objetivo_esperada else 15.0
		velocidad_actual = lerpf(velocidad_actual, velocidad_objetivo_esperada, aceleracion * delta)
		
		var velocidad_objetivo: Vector3 = direccion * velocidad_actual
		var aceleracion_suelo := 15.0 if is_on_floor() else 3.0 
		
		if direccion == Vector3.ZERO and is_on_floor():
			aceleracion_suelo = 12.0 
			
		velocity.x = lerpf(velocity.x, velocidad_objetivo.x, aceleracion_suelo * delta)
		velocity.z = lerpf(velocity.z, velocidad_objetivo.z, aceleracion_suelo * delta)

func _manejar_postura(delta: float) -> void:
	var esta_agachado = estado_actual in [EstadoMovimiento.DESLIZARSE, EstadoMovimiento.AGACHADO]
	
	var altura_objetivo_cabeza = altura_cabeza_agachado if esta_agachado else altura_cabeza_parado
	cabeza.position.y = lerpf(cabeza.position.y, altura_objetivo_cabeza, 10.0 * delta)
	
	if esta_agachado and not forma_parado.disabled:
		forma_parado.set_deferred("disabled", true)
		forma_agachado.set_deferred("disabled", false)
	elif not esta_agachado and forma_parado.disabled:
		forma_parado.set_deferred("disabled", false)
		forma_agachado.set_deferred("disabled", true)

func _manejar_inclinacion_camara(delta: float) -> void:
	var inclinacion_objetivo := 0.0
	
	if estado_actual == EstadoMovimiento.CORRER_PARED:
		inclinacion_objetivo = angulo_inclinacion_camara if corriendo_pared_izquierda else -angulo_inclinacion_camara
	elif estado_actual == EstadoMovimiento.DESLIZARSE:
		inclinacion_objetivo = randf_range(-0.02, 0.02) 
		
	camara.rotation.z = lerp_angle(camara.rotation.z, inclinacion_objetivo, 10.0 * delta)

func _manejar_apuntado(delta: float) -> void:
	var esta_apuntando = Input.is_action_pressed("aim")
	var fov_objetivo = fov_apuntar if esta_apuntando else fov_normal
	
	camara.fov = lerpf(camara.fov, fov_objetivo, velocidad_apuntar * delta)
