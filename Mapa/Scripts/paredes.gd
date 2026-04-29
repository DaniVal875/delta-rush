@tool
extends GridMap

@export_group("Acciones")
@export var subir_paredes: bool = false:
	set(valor):
		if valor:
			generar_altura_segura()
			subir_paredes = false

@export var limpiar_altura: bool = false:
	set(valor):
		if valor:
			borrar_niveles_superiores()
			limpiar_altura = false

@export_group("Configuración")
@export var pisos_totales: int = 2

func generar_altura_segura():
	var celdas = get_used_cells()
	
	if celdas.size() == 0:
		print("No hay nada dibujado en este GridMap.")
		return
		
	print("Iniciando copia de ", celdas.size(), " celdas...")
	
	for celda in celdas:
		var id = get_cell_item(celda)
		var rot = get_cell_item_orientation(celda)
		
		# Solo tomamos como base las del suelo (Y=0)
		if celda.y == 0:
			for i in range(1, pisos_totales):
				var n_pos = Vector3i(celda.x, i, celda.z)
				set_cell_item(n_pos, id, rot)
	
	print("¡Paredes elevadas!")

func borrar_niveles_superiores():
	var celdas = get_used_cells()
	var contador = 0
	
	for celda in celdas:
		# Si la celda está por encima del suelo, la borramos
		if celda.y > 0:
			set_cell_item(celda, -1) # -1 elimina el objeto en esa celda
			contador += 1
			
	print("Se han eliminado ", contador, " bloques superiores.")
