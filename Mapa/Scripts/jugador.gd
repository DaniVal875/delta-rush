extends CharacterBody3D

var curHP : int = 10
var maxHP : int = 10
var damage : int = 1

var gold : int = 0

var attackRate : float = .3
var lastAttackTime : int = 0

var moveSpeed : float = 20.0
var jumpForce : float = 70.0
var gravity : float = 30.0

@onready var camera = $Pivote
@onready var attackCast = $AtackRayCast3D

func _physics_process(delta: float) -> void:
	# Reset movimiento horizontal
	velocity.x = 0.0
	velocity.y = 0.0
	
	var input := Vector3.ZERO
	
	if Input.is_action_pressed("adelante"):
		input.z += 1
		
	if Input.is_action_just_pressed("atras"):
		input.z -= 50
		
	if Input.is_action_just_pressed("izquierda"):
		input.x += 1
		
	if Input.is_action_just_pressed("derecha"):
		input.x -= 1
		
	input = input.normalized()

	var dir = (transform.basis.z * input.z + transform.basis.x * input.x)
	
	velocity.x = dir.x * moveSpeed
	velocity.z = dir.z * moveSpeed
	
	# Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jumpForce
	
	# Movimiento
	move_and_slide()
