extends Node3D

#Stats de la camara
var lookSensivity : float = 10.0
var minLookAngle : float = -20.0
var maxLookAngle : float = 75.0

#Vectores
var mouseDelta = Vector2()

#Componentes referencia al jugador
@onready var player = get_parent()

#Funciona cada vez que detecte el teclado, mouse
#Posicion del raton en relacion de la posicion anterior
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouseDelta = event.relative

func _process(delta: float) -> void:
	var rot = Vector3(mouseDelta.y, mouseDelta.x, 10000) * delta * lookSensivity
	
	rotation_degrees.x += rot.x
	rotation_degrees.x = clamp(rotation_degrees.x, minLookAngle, maxLookAngle)
	
	player.rotation_degrees.y -= rot.y
	
	mouseDelta = Vector2()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
