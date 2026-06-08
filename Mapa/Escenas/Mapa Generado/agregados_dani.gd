extends Node3D

@export var nodo_pizarra : Node3D # NUEVO: Para conectar tu pizarra sin errores

@onready var labelTiempo : Label = $CanvasLayer/Label 
@onready var colicionEbloqueo : CollisionShape3D = $Area_Empezar_Carrera/StaticBody3D/CollisionShape3D2
@onready var colicionSbloqueo : CollisionShape3D = $Area_Terminar_Carrera/StaticBody3D/CollisionShape3D2
@onready var paredVEntrada : MeshInstance3D = $Area_Empezar_Carrera/StaticBody3D/ParedVisual
@onready var paredVSalida : MeshInstance3D = $Area_Terminar_Carrera/StaticBody3D/ParedVisual

var tiempo_transcurrido : float = 0.0
var carrera_activa : bool = false

func _ready() -> void:
	$Portal/AnimatedSprite3D.play("default")

func _process(delta: float) -> void:
	if carrera_activa:
		tiempo_transcurrido += delta
		labelTiempo.text = "Tiempo: %.2f" % tiempo_transcurrido

func _on_area_empezar_carrera_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and not carrera_activa:
		carrera_activa = true
		tiempo_transcurrido = 0
		
		colicionEbloqueo.disabled = false
		colicionSbloqueo.disabled = true
		$AudioStreamPlayer.play()

func _on_area_terminar_carrera_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and carrera_activa:
		# 1. Cambiamos colisiones de las puertas
		colicionEbloqueo.disabled = true
		colicionSbloqueo.disabled = false
		
		# 2. Detenemos el reloj
		var tiempo_final = tiempo_transcurrido
		carrera_activa = false
		$AudioStreamPlayer.stop()
		
		# 3. Revisamos si rompió todos los targets
		var targets_restantes = get_tree().get_nodes_in_group("targets").size()
		
		if targets_restantes > 0:
			print("¡Vuelta inválida! Te faltaron " + str(targets_restantes) + " objetivos.")
		else:
			print("¡Circuito perfecto! Tiempo registrado: ", tiempo_final)
			
			# 4. Mandamos el tiempo a la pizarra de forma segura
			if nodo_pizarra:
				nodo_pizarra.registrar_nuevo_tiempo(tiempo_final)
			else:
				print("ERROR: ¡Falta arrastrar la pizarra al inspector de Agregados Dani!")
		reiniciar_pista()

func _on_portal_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		
		# 1. Explotamos los targets
		var targets_restantes = get_tree().get_nodes_in_group("targets")
		for target in targets_restantes:
			if target.has_method("on_bullet_hit"):
				target.on_bullet_hit(Vector3.ZERO, Vector3.ZERO, 0.0)
		
		# 3. Teletransportamos al jugador
		body.global_position = Vector3(296.8, 32.37, -60.12)

func reiniciar_pista() -> void:
	print("--- INTENTANDO REINICIAR PISTA ---")
	var elementos = get_tree().get_nodes_in_group("reiniciables")
	
	print("Nodos encontrados en el grupo 'reiniciables': ", elementos.size())
	
	for elemento in elementos:
		if elemento.has_method("reiniciar_elemento"):
			elemento.reiniciar_elemento()
		else:
			print("CUIDADO: El nodo " + elemento.name + " está en el grupo pero NO tiene la función.")
			
	tiempo_transcurrido = 0
	if labelTiempo:
		labelTiempo.text = "Tiempo: 0.00"
