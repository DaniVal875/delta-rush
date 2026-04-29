extends CharacterBody3D

# ==========================================================
# 1. EVENTOS Y MÁQUINA DE ESTADOS
# ==========================================

# Definimos una señal para avisar a otros nodos (interfaz, sonidos) cuando el estado cambie.
signal estado_cambiado(nuevo_estado)

# Usamos un enumerador para gestionar los estados. Esto evita errores de escritura
# y hace que el código sea mucho más legible.
enum EstadoMovimiento { SUELO, AIRE, CORRER_PARED, DESLIZARSE, AGACHADO }
var estado_actual: EstadoMovimiento = EstadoMovimiento.SUELO # Estado inicial.

# ==========================================================
# 2. VARIABLES DEL INSPECTOR (@export)
# ==========================================

@export_category("Movimiento")
@export var velocidad_caminar: float = 8.0
@export var velocidad_correr: float = 14.0
@export var velocidad_agachado: float = 4.0 
@export var sensibilidad_raton: float = 0.002
@export var sensibilidad_mando: float = 3.0 # Sensibilidad específica para los sticks de Xbox/PS.

@export_category("Apuntar")
@export var fov_normal: float = 75.0 # Campo de visión estándar.
@export var fov_apuntar: float = 50.0 # Campo de visión reducido (zoom).
@export var velocidad_apuntar: float = 15.0 # Qué tan rápido se hace la transición de zoom.
@export var multiplicador_sensibilidad_apuntar: float = 0.5 # Reduce la sensibilidad al 50% al apuntar.

@export_category("Deslizamiento")
@export var impulso_deslizamiento: float = 5.0 # Fuerza extra al iniciar el slide.
@export var friccion_deslizamiento: float = 2.0 # Qué tan rápido te detienes al deslizarte.
@export var altura_cabeza_parado: float = 0.6
@export var altura_cabeza_agachado: float = 0.0

@export_category("Correr en Pared")
@export var velocidad_base_correr_pared: float = 14.0
@export var velocidad_maxima_correr_pared: float = 24.0 
@export var aceleracion_correr_pared: float = 8.0 
@export var tiempo_maximo_correr_pared: float = 2.0 # Límite de 3 segundos para el wall-run.

@export_category("Movilidad Aerea")
@export var fuerza_salto: float = 7.5
@export var impulso_doble_salto: float = 12.0 # Impulso horizontal para ganar momentum.

@export_category("Fisicas")
@export var multiplicador_gravedad: float = 1.5 
@export var gravedad_correr_pared: float = 1.0 # Gravedad reducida para aguantar más en la pared.
@export var angulo_inclinacion_camara: float = 0.25 

# ==========================================================
# 3. REFERENCIAS A NODOS HIJOS
# ==========================================

@onready var forma_parado: CollisionShape3D = $StandingShape
@onready var forma_agachado: CollisionShape3D = $CrouchShape
@onready var detector_techo: RayCast3D = $CeilingCheck # Rayo para no pararse si hay algo arriba.
@onready var cabeza: Node3D = $Head
@onready var camara: Camera3D = $Head/Camera3D
@onready var rayo_izquierdo: RayCast3D = $WallRayLeft
@onready var rayo_derecho: RayCast3D = $WallRayRight

# ==========================================================
# 4. VARIABLES DE CONTROL INTERNO
# ==========================================

# Calculamos la gravedad final multiplicando la del proyecto por nuestro factor.
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity") * multiplicador_gravedad
var normal_pared: Vector3 = Vector3.ZERO # Almacena la dirección de la pared detectada.
var corriendo_pared_izquierda: bool = false # Para saber hacia dónde inclinar la cámara.
var vector_deslizamiento: Vector3 = Vector3.ZERO # Dirección fija durante el deslizamiento.

var velocidad_actual: float = velocidad_caminar 
var doble_salto_usado: bool = false # Control de salto único en el aire.
var temporizador_correr_pared: float = 0.0 # Cronómetro para el wall-run.
var esta_corriendo: bool = false # Estado del sprint "toggle".

# ==========================================================
# 5. FUNCIONES PRINCIPALES (CICLO DE VIDA)
# ==========================================

func _ready() -> void:
	# Capturamos el ratón para que no se salga de la ventana de juego.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Manejamos la rotación con el ratón.
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var sens_actual = sensibilidad_raton
		# Si estamos apuntando, aplicamos el multiplicador para ser más precisos.
		if Input.is_action_pressed("aim"):
			sens_actual *= multiplicador_sensibilidad_apuntar
			
		# Rotamos el cuerpo (Y) y la cabeza (X) por separado.
		rotate_y(-event.relative.x * sens_actual)
		cabeza.rotate_x(-event.relative.y * sens_actual)
		# Limitamos la rotación vertical para no dar vueltas completas.
		cabeza.rotation.x = clamp(cabeza.rotation.x, -PI/2, PI/2)

func _physics_process(delta: float) -> void:
	# Obtenemos la entrada de movimiento (WASD o Stick Izquierdo).
	var direccion_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Si estamos en la pared, el cronómetro avanza.
	if estado_actual == EstadoMovimiento.CORRER_PARED:
		temporizador_correr_pared += delta

	# Ejecutamos toda la lógica modular en orden frame a frame.
	_manejar_camara_mando(delta)
	_actualizar_estado()
	_manejar_gravedad(delta)
	_manejar_saltos()
	_manejar_movimiento(direccion_input, delta)
	_manejar_postura(delta)
	_manejar_inclinacion_camara(delta)
	_manejar_apuntado(delta)
	
	# move_and_slide procesa las colisiones y el movimiento físico final.
	move_and_slide()

# ==========================================================
# 6. MÓDULOS DE LÓGICA (DESGLOSE)
# ==========================================

# Rotación de cámara específica para sticks analógicos.
func _manejar_camara_mando(delta: float) -> void:
	var direccion_mirada := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if direccion_mirada != Vector2.ZERO:
		var sens_actual = sensibilidad_mando
		if Input.is_action_pressed("aim"):
			sens_actual *= multiplicador_sensibilidad_apuntar
			
		# Multiplicamos por delta para que el giro sea igual a cualquier FPS.
		rotate_y(-direccion_mirada.x * sens_actual * delta)
		cabeza.rotate_x(-direccion_mirada.y * sens_actual * delta)
		cabeza.rotation.x = clamp(cabeza.rotation.x, -PI/2, PI/2)

# El "cerebro" que decide qué estamos haciendo según el entorno.
func _actualizar_estado() -> void:
	if is_on_floor():
		# Reseteamos habilidades al tocar suelo.
		doble_salto_usado = false
		temporizador_correr_pared = 0.0
		
		var quiere_agacharse = Input.is_action_pressed("crouch")
		var puede_pararse = not detector_techo.is_colliding()
		
		if quiere_agacharse or not puede_pararse:
			# Si vienes rápido, entras en deslizamiento.
			if velocidad_actual > velocidad_caminar * 0.5 and estado_actual not in [EstadoMovimiento.DESLIZARSE, EstadoMovimiento.AGACHADO]:
				velocidad_actual += impulso_deslizamiento
				vector_deslizamiento = (-global_transform.basis.z).normalized() 
				_establecer_estado(EstadoMovimiento.DESLIZARSE)
			# Si pierdes velocidad, pasas a estar agachado.
			elif estado_actual == EstadoMovimiento.DESLIZARSE and velocidad_actual <= velocidad_agachado:
				_establecer_estado(EstadoMovimiento.AGACHADO)
			elif estado_actual != EstadoMovimiento.DESLIZARSE:
				_establecer_estado(EstadoMovimiento.AGACHADO)
		else:
			_establecer_estado(EstadoMovimiento.SUELO)
			
	elif _puede_correr_pared():
		doble_salto_usado = false # La pared recarga el doble salto.
		if estado_actual != EstadoMovimiento.CORRER_PARED:
			velocidad_actual = max(velocidad_actual, velocidad_base_correr_pared)
		_establecer_estado(EstadoMovimiento.CORRER_PARED)
	else:
		_establecer_estado(EstadoMovimiento.AIRE)

# Cambia la etiqueta del estado y emite la señal.
func _establecer_estado(nuevo_estado: EstadoMovimiento) -> void:
	if estado_actual == nuevo_estado: return
	estado_actual = nuevo_estado
	estado_cambiado.emit(estado_actual)

# Reglas de validación para el Wall-Run.
func _puede_correr_pared() -> bool:
	if is_on_floor(): return false
	if not Input.is_action_pressed("move_forward"): return false
	if temporizador_correr_pared >= tiempo_maximo_correr_pared: return false
	if Input.is_action_pressed("crouch"): return false 
	
	# Usamos los RayCasts laterales para detectar la geometría.
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
		# No saltar si el techo está pegado a la cabeza.
		if estado_actual in [EstadoMovimiento.AGACHADO, EstadoMovimiento.DESLIZARSE] and detector_techo.is_colliding():
			return 
			
		if estado_actual == EstadoMovimiento.CORRER_PARED:
			velocity.y = fuerza_salto
			# Saltamos hacia afuera de la pared usando su normal.
			var direccion_salto: Vector3 = normal_pared * velocidad_correr
			velocity.x = direccion_salto.x
			velocity.z = direccion_salto.z
			temporizador_correr_pared = 0.0
			
		elif estado_actual in [EstadoMovimiento.DESLIZARSE, EstadoMovimiento.AGACHADO, EstadoMovimiento.SUELO]:
			velocity.y = fuerza_salto
			
		elif not is_on_floor() and not doble_salto_usado:
			doble_salto_usado = true
			velocity.y = fuerza_salto
			# Impulso de velocidad horizontal al hacer doble salto.
			var frente_jugador := -cabeza.global_transform.basis.z
			frente_jugador.y = 0 
			velocity += frente_jugador.normalized() * impulso_doble_salto

func _manejar_movimiento(direccion_input: Vector2, delta: float) -> void:
	# [TOGGLE SPRINT]: Evitamos sondear la acción continuamente. 
	# La bandera se levanta en el frame del "press" y se limpia solo al soltar el vector director.
	if Input.is_action_just_pressed("sprint") and direccion_input != Vector2.ZERO:
		esta_corriendo = true
	if direccion_input == Vector2.ZERO:
		esta_corriendo = false

	if estado_actual == EstadoMovimiento.CORRER_PARED:
		# 'move_toward' es una interpolación lineal estricta. 
		# Garantiza aceleración constante independiente del framerate, a diferencia de lerp.
		velocidad_actual = move_toward(velocidad_actual, velocidad_maxima_correr_pared, aceleracion_correr_pared * delta)
		
		# [ÁLGEBRA LINEAL - CROSS PRODUCT]: El producto cruz entre el vector Y global (UP) y la normal de la pared 
		# genera un vector ortogonal perfecto que es tangente a la malla de colisión.
		var frente_pared := Vector3.UP.cross(normal_pared).normalized()
		# En la convención de Godot/OpenGL, -Z representa el "forward" local del Transform.
		var frente_jugador := -global_transform.basis.z 
		
		# [PRODUCTO PUNTO]: Si el dot product es < 0, el ángulo entre los vectores es mayor a 90°.
		# Significa que el cross product generó el vector apuntando hacia atrás de la cámara. Lo invertimos.
		if frente_pared.dot(frente_jugador) < 0:
			frente_pared = -frente_pared
			
		var velocidad_objetivo: Vector3 = frente_pared * velocidad_actual
		
		# [FUERZA CENTRÍPETA ARTIFICIAL]: Restar la normal empuja el KinematicBody activamente contra la pared.
		# Esto mitiga los errores de coma flotante que harían que is_on_wall() o los RayCasts fallen en el siguiente tick físico.
		velocity.x = velocidad_objetivo.x - (normal_pared.x * 2.0)
		velocity.z = velocidad_objetivo.z - (normal_pared.z * 2.0)
		
	elif estado_actual == EstadoMovimiento.DESLIZARSE:
		# 'lerpf' crea un decaimiento asintótico. Genera una curva de fricción exponencial, no lineal.
		velocidad_actual = lerpf(velocidad_actual, 0.0, friccion_deslizamiento * delta)
		
		# [MATRIZ DE TRANSFORMACIÓN]: Multiplicar la base (basis) por el input convierte las 
		# coordenadas locales de entrada (WASD) al espacio global del mundo 3D.
		var direccion := (transform.basis * Vector3(direccion_input.x, 0, direccion_input.y)).normalized()
		
		# Hacemos un lerp vectorial entre la inercia guardada y el input actual para permitir
		# un "steering" (control de trayectoria) ligero sin romper el momentum principal.
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
		
		# [CONSERVACIÓN DE MOMENTUM]: Ponderamos el factor de interpolación dinámicamente.
		# Si la velocidad actual es mayor a la esperada (ej. saliendo de un wall-run o slide jump),
		# la desaceleración es lenta (5.0). Si acelera de 0 a sprint, la respuesta es rápida (15.0).
		var aceleracion = 5.0 if velocidad_actual > velocidad_objetivo_esperada else 15.0
		velocidad_actual = lerpf(velocidad_actual, velocidad_objetivo_esperada, aceleracion * delta)
		
		var velocidad_objetivo: Vector3 = direccion * velocidad_actual
		
		# Diferenciamos la aceleración si está en el aire para limitar/permitir el "air strafing" (control aéreo).
		var aceleracion_suelo := 15.0 if is_on_floor() else 3.0 
		
		if direccion == Vector3.ZERO and is_on_floor():
			# Frenado estático duro. Evita el efecto de "patinaje sobre hielo" endémico de los CharacterBody3D.
			aceleracion_suelo = 12.0 
			
		# Aplicamos el resultado al vector de velocidad del motor. 'move_and_slide' hará el cálculo de colisiones.
		velocity.x = lerpf(velocity.x, velocidad_objetivo.x, aceleracion_suelo * delta)
		velocity.z = lerpf(velocity.z, velocidad_objetivo.z, aceleracion_suelo * delta)

func _manejar_postura(delta: float) -> void:
	var esta_agachado = estado_actual in [EstadoMovimiento.DESLIZARSE, EstadoMovimiento.AGACHADO]
	
	# Transición suave de la cámara.
	var altura_objetivo_cabeza = altura_cabeza_agachado if esta_agachado else altura_cabeza_parado
	cabeza.position.y = lerpf(cabeza.position.y, altura_objetivo_cabeza, 10.0 * delta)
	
	# set_deferred para cambiar colisiones de forma segura entre hilos.
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
		# Pequeño efecto de vibración aleatoria al deslizar.
		inclinacion_objetivo = randf_range(-0.02, 0.02) 
		
	camara.rotation.z = lerp_angle(camara.rotation.z, inclinacion_objetivo, 10.0 * delta)

func _manejar_apuntado(delta: float) -> void:
	var esta_apuntando = Input.is_action_pressed("aim")
	var fov_objetivo = fov_apuntar if esta_apuntando else fov_normal
	
	# Interpolamos el FOV de la cámara.
	camara.fov = lerpf(camara.fov, fov_objetivo, velocidad_apuntar * delta)
