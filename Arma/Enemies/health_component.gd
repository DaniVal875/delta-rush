class_name HealthComponent
extends Node

signal vida_agotada
signal vida_cambiada(vida_actual: float, vida_maxima: float)

@export var vida_maxima: float = 100.0

var vida_actual: float


func _ready() -> void:
	vida_actual = vida_maxima


func recibir_danio(cantidad: float) -> void:
	if vida_actual <= 0.0:
		return

	vida_actual = max(vida_actual - cantidad, 0.0)
	vida_cambiada.emit(vida_actual, vida_maxima)

	if vida_actual == 0.0:
		vida_agotada.emit()


func esta_vivo() -> bool:
	return vida_actual > 0.0
