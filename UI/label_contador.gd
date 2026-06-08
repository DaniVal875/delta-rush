extends Label

# El total fijo de tu mapa
var total_targets : int = 45

func _process(_delta: float) -> void:
	# Contamos cuántos nodos siguen en el grupo
	var targets_vivos = get_tree().get_nodes_in_group("targets").size()
	
	# Calculamos cuántos hemos destruido
	var targets_destruidos = total_targets - targets_vivos
	
	# Actualizamos nuestro propio texto
	text = "OBJETIVOS: %d / %d" % [targets_destruidos, total_targets]
	
	# Cambiamos nuestro propio color dependiendo del progreso
	if targets_destruidos >= total_targets:
		add_theme_color_override("font_color", Color.GREEN)
	else:
		add_theme_color_override("font_color", Color.WHITE)
