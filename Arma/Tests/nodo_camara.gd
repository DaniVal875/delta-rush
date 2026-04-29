extends Node3D

#Stats de la camara
var lookSensitivity : float = 15.0
var minLookAngle : float = -90.0
var maxLookAngle : float = 90.0

#Vectores
var mouseDelta = Vector2()

#Componentes referencias al jugador
@onready var player = get_parent()

#funciona cada vez que detecte el teclado, mouse
#Posición del ratón en relación de la posición anterior

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouseDelta = event.relative
		
func _process(delta: float) -> void:
	var rot = Vector3(mouseDelta.y, mouseDelta.x, 0) * delta * lookSensitivity
	
	rotation_degrees.x += rot.x
	rotation_degrees.x = clamp(rotation_degrees.x, minLookAngle, maxLookAngle)
	
	player.rotation_degrees.y -= rot.y
	
	mouseDelta = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
