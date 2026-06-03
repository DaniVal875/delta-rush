@tool
extends Node3D

@export_category("Controles del Mapa")
@export var crear_mapa: bool = false :
	set(value):
		crear_mapa = false # Se reinicia como si fuera un botón
		if value:
			crear_todo()

@export var eliminar_mapa: bool = false :
	set(value):
		eliminar_mapa = false # Se reinicia como si fuera un botón
		if value:
			eliminar_todo()

@export_category("Configuración de Piezas")
var escena_pared: PackedScene = preload("res://delta-rush/Mapa/Escenas/Mapa Procedural/Piezas del Mapa/ParedPista.tscn")
@export_range(3, 500) var numero_de_paredes: int = 192 
@export var radio: float = 320.0 

var escena_paredInterna: PackedScene = preload("res://delta-rush/Mapa/Escenas/Mapa Procedural/Piezas del Mapa/ParedInterna.tscn")
@export_range(3, 500) var numero_de_paredesInternas: int = 174 
@export var radioInterno: float = 290.0 

var escena_Suelo: PackedScene = preload("res://delta-rush/Mapa/Escenas/Mapa Procedural/Piezas del Mapa/BaseSuelo.tscn")
@export_range(3, 500) var numero_de_Suelos: int = 183 
@export var radioSuelo: float = 305.0 

var escena_Techo: PackedScene = preload("res://delta-rush/Mapa/Escenas/Mapa Procedural/Piezas del Mapa/BaseTecho.tscn")
@export_range(3, 500) var numero_de_Techos: int = 183 
@export var radioTecho: float = 305.0 

func _ready():
	# Si estamos corriendo el juego (no en el editor), lo generamos si está vacío
	if not Engine.is_editor_hint() and get_child_count() == 0:
		crear_todo()

# --- FUNCIONES PRINCIPALES ---

func crear_todo():
	eliminar_todo() # Evita duplicar el mapa si le das a crear varias veces
	generar_pista()
	generar_pistaInterna()
	generar_pistaSuelo()
	generar_pistaTecho()

func eliminar_todo():
	# Recorre todos los nodos instanciados y los elimina
	for hijo in get_children():
		hijo.queue_free()

# Esta función extra es OBLIGATORIA al usar @tool en Godot
# Le dice al editor que los nodos generados deben guardarse en la escena
func instanciar_y_guardar(nodo):
	add_child(nodo)
	if Engine.is_editor_hint() and get_tree():
		nodo.owner = get_tree().edited_scene_root

# --- FUNCIONES DE GENERACIÓN ---

func generar_pista():
	if escena_pared == null: return
	var angulo_paso = (2.0 * PI) / numero_de_paredes
	for i in range(numero_de_paredes):
		var angulo = i * angulo_paso
		var nueva_pared = escena_pared.instantiate()
		
		instanciar_y_guardar(nueva_pared) # Usamos la nueva función aquí
		
		var pos_x = cos(angulo) * radio
		var pos_z = sin(angulo) * radio
		nueva_pared.position = Vector3(pos_x, 0, pos_z)
		nueva_pared.rotation.y = -angulo + (PI / 2.0)

func generar_pistaInterna():
	if escena_paredInterna == null: return
	var angulo_paso = (2.0 * PI) / numero_de_paredesInternas
	for i in range(numero_de_paredesInternas):
		var angulo = i * angulo_paso
		var nueva_pared = escena_paredInterna.instantiate()
		
		instanciar_y_guardar(nueva_pared)
		
		var pos_x = cos(angulo) * radioInterno
		var pos_z = sin(angulo) * radioInterno
		nueva_pared.position = Vector3(pos_x, 0, pos_z)
		nueva_pared.rotation.y = -angulo + (PI / 2.0)

func generar_pistaSuelo():
	if escena_Suelo == null: return
	var angulo_paso = (2.0 * PI) / numero_de_Suelos
	for i in range(numero_de_Suelos):
		var angulo = i * angulo_paso
		var nuevo_suelo = escena_Suelo.instantiate()
		
		instanciar_y_guardar(nuevo_suelo)
		
		var pos_x = cos(angulo) * radioSuelo
		var pos_z = sin(angulo) * radioSuelo
		nuevo_suelo.position = Vector3(pos_x, 0, pos_z)
		nuevo_suelo.rotation.y = -angulo + (PI / 2.0)

func generar_pistaTecho():
	if escena_Techo == null: return
	var angulo_paso = (2.0 * PI) / numero_de_Techos
	for i in range(numero_de_Techos):
		var angulo = i * angulo_paso
		var nuevo_techo = escena_Techo.instantiate()
		
		instanciar_y_guardar(nuevo_techo)
		
		var pos_x = cos(angulo) * radioTecho
		var pos_z = sin(angulo) * radioTecho
		nuevo_techo.position = Vector3(pos_x, 0, pos_z)
		nuevo_techo.rotation.y = -angulo + (PI / 2.0)
