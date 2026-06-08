extends CanvasLayer

# Arrastra aquí tu cámara 3D desde el Inspector o búscala en el _ready
@export var camara_3d : Camera3D 

# Precalgamos la escena de la flechita que creamos antes
var escena_indicador = preload("res://delta-rush/UI/indicador_target.tscn")

# Diccionario para asociar cada Target 3D con su flecha 2D correspondientes
var marcadores_activos = {}

func _process(_delta: float) -> void:
	if not camara_3d:
		return

	# Obtener todos los targets que siguen vivos en el mapa
	var targets_vivos = get_tree().get_nodes_in_group("targets")

	# 1. Limpiar marcadores de targets que ya fueron destruidos
	for target in marcadores_activos.keys():
		if not is_instance_valid(target):
			marcadores_activos[target].queue_free()
			marcadores_activos.erase(target)

	# 2. Actualizar o crear marcadores para los que siguen de pie
	for target in targets_vivos:
		if not marcadores_activos.has(target):
			crear_nuevo_marcador(target)
		
		actualizar_posicion_marcador(target)

func crear_nuevo_marcador(target: Node3D):
	var nuevo_marcador = escena_indicador.instantiate()
	add_child(nuevo_marcador)
	marcadores_activos[target] = nuevo_marcador

# Pega esto en manejador_marcadores.gd reemplazando la función vieja

func actualizar_posicion_marcador(target: Node3D):
	# Validaciones de seguridad por si el target se borra en ese mismo frame
	if not is_instance_valid(target): return
	if not marcadores_activos.has(target): return
	
	var marcador = marcadores_activos[target]
	var icono = marcador.get_node("Icono")
	
	var pos_3d = target.global_position
	var is_front = not camara_3d.is_position_behind(pos_3d)
	var pos_2d = camara_3d.unproject_position(pos_3d)
	
	var screen_size = get_viewport().get_visible_rect().size
	var center = screen_size / 2.0
	var margin = 50.0
	
	# --- CASO 1: EN PANTALLA ---
	if is_front and pos_2d.x > 0 and pos_2d.x < screen_size.x and pos_2d.y > 0 and pos_2d.y < screen_size.y:
		# Usamos .position normal
		marcador.position = pos_2d - (marcador.size / 2.0)
		icono.rotation = 0 # No rotamos si lo estamos viendo de frente
		return
		
	# --- CASO 2: FUERA DE PANTALLA O DETRÁS ---
	# 1. Calculamos la dirección desde el centro de la pantalla hacia la proyección
	var direccion = (pos_2d - center).normalized()
	
	# 2. TRUCO CLAVE: Si el objeto está detrás de nosotros, invertimos la dirección
	if not is_front:
		direccion = -direccion
		
	# 3. Empujamos la flecha en esa dirección hasta salir de la pantalla
	var pos_borde = center + (direccion * 10000.0) 
	
	# 4. La "golpeamos" contra los bordes para que no se salga
	pos_borde.x = clamp(pos_borde.x, margin, screen_size.x - margin)
	pos_borde.y = clamp(pos_borde.y, margin, screen_size.y - margin)
	
	# Posicionamos y rotamos (usando .position)
	marcador.position = pos_borde - (marcador.size / 2.0)
	icono.rotation = direccion.angle()
