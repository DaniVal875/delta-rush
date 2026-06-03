extends Node3D

@onready var particles: GPUParticles3D = $GPUParticles3D

func _ready() -> void:
	particles.emitting = true
	var tiempo_total = particles.lifetime + 0.1
	await get_tree().create_timer(tiempo_total).timeout
	queue_free()
