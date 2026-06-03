extends CharacterBody3D

@export var velocidad: float = 10.0
@export var vida_maxima: float = 5.0       # Segundos antes de desaparecer solo

var _direccion: Vector3 = Vector3.ZERO


func setup(origen: Vector3, direccion: Vector3) -> void:
	global_position = origen
	_direccion = direccion
	$Timer.wait_time = vida_maxima
	$Timer.start()
	
	# Orientar el frente del proyectil hacia la direccion del vuelo
	if direccion.length() > 0.001:
		look_at(global_position + direccion, Vector3.UP)


func _physics_process(_delta: float) -> void:
	velocity = _direccion * velocidad
	var colision := move_and_collide(velocity * _delta)

	if colision:
		var golpeado = colision.get_collider()
		if golpeado.is_in_group("player"):
			golpeado.recibir_impacto()
		queue_free()


func _on_timer_timeout() -> void:
	queue_free()
