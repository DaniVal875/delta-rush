extends Node3D

func _ready() -> void:
	# Nos aseguramos de que las partículas empiecen a emitir al aparecer
	$GPUParticles3D.emitting = true
	
	# Creamos un temporizador rápido desde el código para eliminar la escena
	# Le damos un poco más de tiempo que el "Lifetime" de las partículas (ej. 1.0 segundos)
	await get_tree().create_timer(1.0).timeout
	queue_free()
