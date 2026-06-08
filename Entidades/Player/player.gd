extends CharacterBody3D

signal estado_cambiado(nuevo_estado)

enum EstadoMovimiento { SUELO, AIRE, CORRER_PARED, DESLIZARSE, AGACHADO }
var estado_actual: EstadoMovimiento = EstadoMovimiento.SUELO

@export_category("Movimiento")
@export var velocidad_caminar: float = 8.0
@export var velocidad_correr: float = 14.0
@export var velocidad_agachado: float = 2.0 
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
@export var altura_cabeza_agachado: float = -0.6

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

@export_category("Impacto")
@export var multiplicador_ralentizacion: float = 0.3 
@export var duracion_ralentizacion: float = 1.5       
@export var fuerza_temblor: float = 1.5      
@export var reduccion_temblor: float = 3.0

@export_category("Audio")
@export var tiempo_paso_caminar: float = 0.4
@export var tiempo_paso_correr: float = 0.25

@export_category("Animación Arma")
@export var offset_corriendo: Vector3 = Vector3(0.1, -0.15, 0.0)
@export var offset_aire: Vector3 = Vector3(0.0, -0.15, 0.05) 
@export var offset_pared: Vector3 = Vector3(0.15, -0.1, 0.0) 
@export var velocidad_movimiento_arma: float = 12.0

@export_group("Balanceo (Bobbing)")
@export var velocidad_balanceo_caminar: float = 16.0
@export var intensidad_balanceo_caminar: float = 0.015 # Un movimiento sutil
@export var velocidad_balanceo_correr: float = 22.0    # Más rápido
@export var intensidad_balanceo_correr: float = 0.045  # Más agresivo

@export_group("Rotación y Sway")
@export var sway_raton: float = 0.002
@export var sway_mando: float = 0.05  # <-- NUEVA VARIABLE AQUÍ
@export var sway_maximo: float = 0.1
@export var velocidad_recuperacion_sway: float = 12.0
@export var inclinacion_pared: float = 0.35 # Qué tanto se acuesta el arma en la pared
@export var rotacion_aire: Vector3 = Vector3(-0.15, 0.0, 0.0) # Se inclina un poco al saltar
@export var velocidad_rotacion_arma: float = 12.0

@export_category("Aim Assist (Mando)")
@export var aim_assist_activado: bool = true
@export var multiplicador_aim_assist: float = 0.4 # Reduce la sensibilidad al 40% al apuntar a un enemigo

@onready var detector_aim_assist: ShapeCast3D = $Head/Camera3D/DetectorAimAssist

# Asegúrate de agregar estas dos junto a tus otras variables privadas (las que tienen guion bajo)
var _rotacion_inicial_arma: Vector3
var _sway_actual: Vector2 = Vector2.ZERO

var _posicion_inicial_arma: Vector3
var _tiempo_balanceo: float = 0.0


@onready var reproductor_pasos: AudioStreamPlayer = $Sonidos/SonidoPasos
@onready var reproductor_aire: AudioStreamPlayer = $Sonidos/SonidoAirePared
@onready var reproductor_salto_normal: AudioStreamPlayer = $Sonidos/SonidoSaltoNormal
@onready var reproductor_salto_impulso: AudioStreamPlayer = $Sonidos/SonidoSaltoImpulso 
@onready var reproductor_deslizamiento: AudioStreamPlayer = $Sonidos/SonidoDeslizamiento
@onready var reproductor_golpe: AudioStreamPlayer = $Sonidos/SonidoGolpe

@onready var pantalla_aturdido: Control = $UI_Usuario/EfectoAturdido
var temporizador_pasos: float = 0.0

@onready var forma_parado: CollisionShape3D = $StandingShape
@onready var forma_agachado: CollisionShape3D = $CrouchShape
@onready var detector_techo: RayCast3D = $CeilingCheck 
@onready var cabeza: Node3D = $Head
@onready var camara: Camera3D = $Head/Camera3D
@onready var arma: Weapon = $Head/Camera3D/WeaponHolder/Weapon
@onready var rayo_izquierdo: RayCast3D = $WallRayLeft
@onready var rayo_derecho: RayCast3D = $WallRayRight

@onready var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity") * multiplicador_gravedad
var normal_pared: Vector3 = Vector3.ZERO
var corriendo_pared_izquierda: bool = false
var vector_deslizamiento: Vector3 = Vector3.ZERO 

var velocidad_actual: float = velocidad_caminar 
var saltos_aereos_realizados: int = 0 
var temporizador_correr_pared: float = 0.0 
var esta_corriendo: bool = false 

var ultima_pared_lado: int = 0  # 0 = ninguna, 1 = izquierda, 2 = derecha

var _temporizador_impacto: float = 0.0
var _esta_ralentizado: bool = false
var _nivel_temblor: float = 0.0 # Controla la intensidad del shake

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	
	if arma:
		_posicion_inicial_arma = arma.position
		_rotacion_inicial_arma = arma.rotation # Guardamos la rotación base

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
	_manejar_impacto(delta)
	_manejar_sonido_pasos()
	_manejar_sonido_pared()
	_manejar_sonido_deslizamiento()
	_manejar_animacion_arma(delta)
	
	move_and_slide()
	
	# Disparo automático al mantener pulsado
	if Input.is_action_pressed("shoot"):
		arma.shoot(camara.global_position, camara.global_transform.basis, delta)


func _manejar_camara_mando(delta: float) -> void:
	var direccion_mirada := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if direccion_mirada != Vector2.ZERO:
		var sens_actual = sensibilidad_mando
		
		# 1. Reducción normal por apuntar (ADS)
		if Input.is_action_pressed("aim"):
			sens_actual *= multiplicador_sensibilidad_apuntar
			
		# 2. --- Lógica de Fricción / Aim Assist ---
		if aim_assist_activado and detector_aim_assist.is_colliding():
			# Obtenemos el primer objeto con el que choca
			var objetivo = detector_aim_assist.get_collider(0)
			
			
			# Comprobamos si pertenece al grupo correcto
			if objetivo and objetivo.is_in_group("reiniciables"):
				sens_actual *= multiplicador_aim_assist
				
		# Aplicamos la rotación con la sensibilidad ya calculada
		rotate_y(-direccion_mirada.x * sens_actual * delta)
		cabeza.rotate_x(-direccion_mirada.y * sens_actual * delta)
		cabeza.rotation.x = clamp(cabeza.rotation.x, -PI/2, PI/2)
		
		# --- Calculamos el sway del arma para el mando ---
		if arma and not Input.is_action_pressed("aim"):
			_sway_actual.x -= direccion_mirada.x * sway_mando
			_sway_actual.y -= direccion_mirada.y * sway_mando
			_sway_actual.x = clamp(_sway_actual.x, -sway_maximo, sway_maximo)
			_sway_actual.y = clamp(_sway_actual.y, -sway_maximo, sway_maximo)

func _actualizar_estado() -> void:
	if is_on_floor():
		saltos_aereos_realizados = 0
		temporizador_correr_pared = 0.0
		ultima_pared_lado = 0
		
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
		saltos_aereos_realizados = 0 
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
	if Input.is_action_pressed("crouch"): return false 
	if _esta_ralentizado: return false
	
	# 1. Detectar qué lado está colisionando en este frame
	var lado_detectado: int = 0
	var normal_detectada: Vector3 = Vector3.ZERO
	
	if rayo_izquierdo.is_colliding():
		lado_detectado = 1 # Izquierda
		normal_detectada = rayo_izquierdo.get_collision_normal()
	elif rayo_derecho.is_colliding():
		lado_detectado = 2 # Derecha
		normal_detectada = rayo_derecho.get_collision_normal()
	
	# Si no está tocando ninguna pared, no puede correr
	if lado_detectado == 0:
		return false
		
	# 2. SISTEMA DE ENCADENAMIENTO FRENÉTICO
	if lado_detectado != ultima_pared_lado:
		temporizador_correr_pared = 0.0
		ultima_pared_lado = lado_detectado
		
	# 3. Validar si se le acabó el tiempo en ESTA pared
	if temporizador_correr_pared >= tiempo_maximo_correr_pared:
		return false
		
	# Si pasó todas las condiciones, aplicamos los datos para el movimiento
	normal_pared = normal_detectada
	corriendo_pared_izquierda = (lado_detectado == 1)
	return true

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
			reproductor_salto_normal.play() # Sonido normal al impulsarse desde la pared
			
		elif estado_actual in [EstadoMovimiento.DESLIZARSE, EstadoMovimiento.AGACHADO, EstadoMovimiento.SUELO]:
			velocity.y = fuerza_salto
			reproductor_salto_normal.play() # Sonido normal para el primer salto desde el suelo
			
		elif not is_on_floor() and saltos_aereos_realizados < 2:
			saltos_aereos_realizados += 1
			velocity.y = fuerza_salto
			
			# Si es el segundo salto en el aire (el tercer salto en total)
			if saltos_aereos_realizados == 2:
				var frente_jugador := -cabeza.global_transform.basis.z
				frente_jugador.y = 0 
				velocity += frente_jugador.normalized() * impulso_doble_salto
				
				reproductor_salto_impulso.play() # <-- Sonido especial de explosión/propulsor
			else:
				reproductor_salto_normal.play() # <-- Sonido normal para el segundo salto

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
		var factor := multiplicador_ralentizacion if _esta_ralentizado else 1.0
		var velocidad_objetivo_esperada = (velocidad_correr if esta_corriendo else velocidad_caminar) * factor
		
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
		inclinacion_objetivo = -angulo_inclinacion_camara if corriendo_pared_izquierda else angulo_inclinacion_camara
	elif estado_actual == EstadoMovimiento.DESLIZARSE:
		inclinacion_objetivo = randf_range(-0.02, 0.02) 
		
	camara.rotation.z = lerp_angle(camara.rotation.z, inclinacion_objetivo, 10.0 * delta)

func _manejar_apuntado(delta: float) -> void:
	var esta_apuntando = Input.is_action_pressed("aim")
	var fov_objetivo = fov_apuntar if esta_apuntando else fov_normal
	
	camara.fov = lerpf(camara.fov, fov_objetivo, velocidad_apuntar * delta)

func recibir_impacto() -> void:
	_temporizador_impacto = duracion_ralentizacion
	_esta_ralentizado = true
	_nivel_temblor = fuerza_temblor # Inicia el shake de la cámara
	
	# Reproduce el sonido de impacto si no está sonando ya
	if not reproductor_golpe.playing:
		reproductor_golpe.play()
		
	# Muestra el efecto visual de aturdimiento en pantalla
	pantalla_aturdido.visible = true
	pantalla_aturdido.modulate.a = 1.0 # Opacidad al máximo

func _manejar_impacto(delta: float) -> void:
	# 1. --- Manejar el Temblor (Screenshake) ---
	if _nivel_temblor > 0.0:
		_nivel_temblor = move_toward(_nivel_temblor, 0.0, reduccion_temblor * delta)
		# Usamos h_offset y v_offset de la cámara para no afectar tu código de apuntado
		var temblor_actual = _nivel_temblor * _nivel_temblor # Suaviza la curva del temblor
		camara.h_offset = randf_range(-0.1, 0.1) * temblor_actual
		camara.v_offset = randf_range(-0.1, 0.1) * temblor_actual
	else:
		camara.h_offset = 0.0
		camara.v_offset = 0.0

	# 2. --- Manejar el tiempo y la Interfaz Visual ---
	if not _esta_ralentizado:
		return
		
	_temporizador_impacto -= delta
	
	# Hace que el contorno desaparezca suavemente mientras se pasa el aturdimiento
	pantalla_aturdido.modulate.a = _temporizador_impacto / duracion_ralentizacion
	
	if _temporizador_impacto <= 0.0:
		_esta_ralentizado = false
		pantalla_aturdido.visible = false # Apaga el efecto al terminar

func _manejar_sonido_pasos() -> void:
	# Calculamos si el personaje realmente se está desplazando
	var velocidad_horizontal = Vector2(velocity.x, velocity.z).length()
	
	# Verificamos si tocamos el suelo y nos movemos
	var deberia_sonar = estado_actual in [EstadoMovimiento.SUELO, EstadoMovimiento.AGACHADO] and velocidad_horizontal > 1.0
	
	if deberia_sonar:
		# Si deberia sonar y no está sonando, le damos play
		if not reproductor_pasos.playing:
			reproductor_pasos.play()
			
		# Modificamos la velocidad del audio (pitch) según el estado para que coincida con la animación/velocidad
		if esta_corriendo:
			reproductor_pasos.pitch_scale = 1.4 # Suena más rápido al correr
		elif estado_actual == EstadoMovimiento.AGACHADO:
			reproductor_pasos.pitch_scale = 0.7 # Suena más lento al ir agachado
		else:
			reproductor_pasos.pitch_scale = 1.0 # Velocidad normal al caminar
	else:
		# Si nos detenemos, saltamos o corremos por la pared, detenemos el audio de pisadas
		if reproductor_pasos.playing:
			reproductor_pasos.stop()

func _manejar_sonido_pared() -> void:
	if estado_actual == EstadoMovimiento.CORRER_PARED:
		# Si estamos corriendo en la pared y el sonido no ha empezado, lo activamos
		if not reproductor_aire.playing:
			reproductor_aire.play()
	else:
		# En cualquier otro estado (suelo, aire, deslizarse), el sonido se apaga
		if reproductor_aire.playing:
			reproductor_aire.stop()

func _manejar_sonido_deslizamiento() -> void:
	if estado_actual == EstadoMovimiento.DESLIZARSE:
		if not reproductor_deslizamiento.playing:
			reproductor_deslizamiento.play()
		
		# Dinámico: Modifica el pitch según la velocidad actual para que se sienta el frenado
		# Evitamos la división por cero usando un clamp
		var factor_velocidad = clamp(velocidad_actual / velocidad_correr, 0.5, 1.2)
		reproductor_deslizamiento.pitch_scale = factor_velocidad
	else:
		if reproductor_deslizamiento.playing:
			reproductor_deslizamiento.stop()

func _manejar_animacion_arma(delta: float) -> void:
	if not arma: 
		return
		
	var esta_apuntando = Input.is_action_pressed("aim")
	var esta_disparando = Input.is_action_pressed("shoot")
	
	var posicion_objetivo: Vector3 = _posicion_inicial_arma
	var rotacion_objetivo: Vector3 = _rotacion_inicial_arma
	
	var velocidad_horizontal = Vector2(velocity.x, velocity.z).length()
	var se_esta_moviendo = velocidad_horizontal > 1.0
	
	if esta_apuntando or esta_disparando:
		_tiempo_balanceo = 0.0
		posicion_objetivo = _posicion_inicial_arma
		rotacion_objetivo = _rotacion_inicial_arma
		
	elif estado_actual == EstadoMovimiento.CORRER_PARED:
		_tiempo_balanceo = 0.0
		var direccion_lado = 1.0 if corriendo_pared_izquierda else -1.0
		
		# Movemos y rotamos (inclinamos) el arma hacia el lado contrario de la pared
		posicion_objetivo = _posicion_inicial_arma + Vector3(offset_pared.x * direccion_lado, offset_pared.y, offset_pared.z)
		rotacion_objetivo.z = _rotacion_inicial_arma.z + (inclinacion_pared * direccion_lado)
		
	elif estado_actual == EstadoMovimiento.AIRE:
		_tiempo_balanceo = 0.0
		posicion_objetivo = _posicion_inicial_arma + offset_aire
		rotacion_objetivo = _rotacion_inicial_arma + rotacion_aire
		
	elif is_on_floor() and se_esta_moviendo:
		var vel_bal = velocidad_balanceo_correr if esta_corriendo else velocidad_balanceo_caminar
		var int_bal = intensidad_balanceo_correr if esta_corriendo else intensidad_balanceo_caminar
		
		if esta_corriendo:
			posicion_objetivo = _posicion_inicial_arma + offset_corriendo
			# Le damos una ligera inclinación general hacia abajo y al centro al correr
			rotacion_objetivo.x = _rotacion_inicial_arma.x - 0.05 
			rotacion_objetivo.y = _rotacion_inicial_arma.y + 0.1
		else:
			posicion_objetivo = _posicion_inicial_arma
			
		_tiempo_balanceo += delta * vel_bal
		
		# Movimiento posicional (bobbing)
		posicion_objetivo.y += sin(_tiempo_balanceo) * int_bal
		posicion_objetivo.x += cos(_tiempo_balanceo * 0.5) * (int_bal * 1.5)
		
		# Rotación rítmica (para que el arma se contonee al caminar/correr)
		rotacion_objetivo.z += cos(_tiempo_balanceo * 0.5) * (int_bal * 1.5)
		rotacion_objetivo.x += sin(_tiempo_balanceo) * (int_bal * 0.8)
		
	else:
		_tiempo_balanceo = 0.0
		
	# --- APLICAR EL SWAY (RETRASO DEL RATÓN) ---
	# Sumamos el desfase del ratón a la rotación que ya calculamos
	rotacion_objetivo.x += _sway_actual.y # Eje Y del ratón mueve la rotación X (arriba/abajo)
	rotacion_objetivo.y += _sway_actual.x # Eje X del ratón mueve la rotación Y (izquierda/derecha)
	
	# El sway regresa a cero gradualmente para que el arma se centre sola
	_sway_actual = _sway_actual.lerp(Vector2.ZERO, velocidad_recuperacion_sway * delta)
		
	# --- APLICAR LAS INTERPOLACIONES FINALES ---
	# Posición suave
	arma.position = arma.position.lerp(posicion_objetivo, velocidad_movimiento_arma * delta)
	
	# Rotación suave (Usamos lerp_angle para los ángulos, es más seguro que lerp normal)
	arma.rotation.x = lerp_angle(arma.rotation.x, rotacion_objetivo.x, velocidad_rotacion_arma * delta)
	arma.rotation.y = lerp_angle(arma.rotation.y, rotacion_objetivo.y, velocidad_rotacion_arma * delta)
	arma.rotation.z = lerp_angle(arma.rotation.z, rotacion_objetivo.z, velocidad_rotacion_arma * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var sens_actual = sensibilidad_raton
		if Input.is_action_pressed("aim"):
			sens_actual *= multiplicador_sensibilidad_apuntar
			
		rotate_y(-event.relative.x * sens_actual)
		cabeza.rotate_x(-event.relative.y * sens_actual)
		cabeza.rotation.x = clamp(cabeza.rotation.x, -PI/2, PI/2)
		
		# --- NUEVO: Calculamos el sway del arma ---
		if arma and not Input.is_action_pressed("aim"):
			_sway_actual.x -= event.relative.x * sway_raton
			_sway_actual.y -= event.relative.y * sway_raton
			_sway_actual.x = clamp(_sway_actual.x, -sway_maximo, sway_maximo)
			_sway_actual.y = clamp(_sway_actual.y, -sway_maximo, sway_maximo)
