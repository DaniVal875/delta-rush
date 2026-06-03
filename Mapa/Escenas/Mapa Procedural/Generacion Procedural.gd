extends Node3D

var escena_pared: PackedScene = preload("res://delta-rush/Mapa/Escenas/Mapa Procedural/Piezas del Mapa/ParedPista.tscn")
@export_range(3, 50) var numero_de_paredes: int = 192 # 6 por defecto para el hexágono
@export var radio: float = 320.0 # Distancia desde el centro

var escena_paredInterna: PackedScene = preload("res://delta-rush/Mapa/Escenas/Mapa Procedural/Piezas del Mapa/ParedInterna.tscn")
@export_range(3, 50) var numero_de_paredesInternas: int = 174 # 6 por defecto para el hexágono
@export var radioInterno: float = 290.0 # Distancia desde el centro

var escena_Suelo: PackedScene = preload("res://delta-rush/Mapa/Escenas/Mapa Procedural/Piezas del Mapa/BaseSuelo.tscn")
@export_range(3, 50) var numero_de_Suelos: int = 183 # 6 por defecto para el hexágono
@export var radioSuelo: float = 305.0 # Distancia desde el centro

var escena_Techo: PackedScene = preload("res://delta-rush/Mapa/Escenas/Mapa Procedural/Piezas del Mapa/BaseTecho.tscn")
@export_range(3, 50) var numero_de_Techos: int = 183 # 6 por defecto para el hexágono
@export var radioTecho: float = 305.0 # Distancia desde el centro

func _ready():
	generar_pista()
	generar_pistaInterna()
	generar_pistaSuelo()
	generar_pistaTecho()

func generar_pista():
	# Verificamos que hayas asignado la escena en el inspector
	if escena_pared == null:
		push_warning("¡Falta asignar la escena de la pared en el Inspector!")
		return
		
	# Calculamos el ángulo que habrá entre cada pared (en radianes)
	var angulo_paso = (2.0 * PI) / numero_de_paredes
	
	for i in range(numero_de_paredes):
		var angulo = i * angulo_paso
		
		# 1. Instanciar la pared
		var nueva_pared = escena_pared.instantiate()
		add_child(nueva_pared)
		
		# 2. Calcular la posición en el plano XZ usando seno y coseno
		var pos_x = cos(angulo) * radio
		var pos_z = sin(angulo) * radio
		
		nueva_pared.position = Vector3(pos_x, 0, pos_z)
		
		# 3. Rotar la pared para que conecte con las demás
		# Como en tu imagen la pared parece estar alineada en el eje X, 
		# le sumamos PI/2 (90 grados) para que sea tangente al círculo.
		nueva_pared.rotation.y = -angulo + (PI / 2.0)


func generar_pistaInterna():
	# Verificamos que hayas asignado la escena en el inspector
	if escena_paredInterna == null:
		push_warning("¡Falta asignar la escena de la pared en el Inspector!")
		return
		
	# Calculamos el ángulo que habrá entre cada pared (en radianes)
	var angulo_paso = (2.0 * PI) / numero_de_paredesInternas
	
	for i in range(numero_de_paredesInternas):
		var angulo = i * angulo_paso
		
		# 1. Instanciar la pared
		var nueva_pared = escena_paredInterna.instantiate()
		add_child(nueva_pared)
		
		# 2. Calcular la posición en el plano XZ usando seno y coseno
		var pos_x = cos(angulo) * radioInterno
		var pos_z = sin(angulo) * radioInterno
		
		nueva_pared.position = Vector3(pos_x, 0, pos_z)
		
		# 3. Rotar la pared para que conecte con las demás
		# Como en tu imagen la pared parece estar alineada en el eje X, 
		# le sumamos PI/2 (90 grados) para que sea tangente al círculo.
		nueva_pared.rotation.y = -angulo + (PI / 2.0)


func generar_pistaSuelo():
	# Verificamos que hayas asignado la escena en el inspector
	if escena_Suelo == null:
		push_warning("¡Falta asignar la escena de la pared en el Inspector!")
		return
		
	# Calculamos el ángulo que habrá entre cada pared (en radianes)
	var angulo_paso = (2.0 * PI) / numero_de_Suelos
	
	for i in range(numero_de_Suelos):
		var angulo = i * angulo_paso
		
		# 1. Instanciar la pared
		var nuevo_suelo = escena_Suelo.instantiate()
		add_child(nuevo_suelo)
		
		# 2. Calcular la posición en el plano XZ usando seno y coseno
		var pos_x = cos(angulo) * radioSuelo
		var pos_z = sin(angulo) * radioSuelo
		
		nuevo_suelo.position = Vector3(pos_x, 0, pos_z)
		
		# 3. Rotar la pared para que conecte con las demás
		# Como en tu imagen la pared parece estar alineada en el eje X, 
		# le sumamos PI/2 (90 grados) para que sea tangente al círculo.
		nuevo_suelo.rotation.y = -angulo + (PI / 2.0)


func generar_pistaTecho():
	# Verificamos que hayas asignado la escena en el inspector
	if escena_Techo == null:
		push_warning("¡Falta asignar la escena de la pared en el Inspector!")
		return
		
	# Calculamos el ángulo que habrá entre cada pared (en radianes)
	var angulo_paso = (2.0 * PI) / numero_de_Techos
	
	for i in range(numero_de_Techos):
		var angulo = i * angulo_paso
		
		# 1. Instanciar la pared
		var nuevo_techo = escena_Techo.instantiate()
		add_child(nuevo_techo)
		
		# 2. Calcular la posición en el plano XZ usando seno y coseno
		var pos_x = cos(angulo) * radioTecho
		var pos_z = sin(angulo) * radioTecho
		
		nuevo_techo.position = Vector3(pos_x, 0, pos_z)
		
		# 3. Rotar la pared para que conecte con las demás
		# Como en tu imagen la pared parece estar alineada en el eje X, 
		# le sumamos PI/2 (90 grados) para que sea tangente al círculo.
		nuevo_techo.rotation.y = -angulo + (PI / 2.0)
