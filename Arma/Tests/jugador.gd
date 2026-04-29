extends CharacterBody3D

var curHP : int = 10
var maxHP : int = 10
var damage : int = 1

var gold : int = 0

var attackRate : float = .3
var lastAttackTime : int = 0

var moveSpeed : float = 8.0
var jumpForce : float = 10.0
var gravity : float = 12.0

@onready var camera = $Pivote
@onready var attackCast = $AttackRayCast3D

func _physics_process(delta: float) -> void:
	# Reset movimiento horizontal
	velocity.x = 0.0
	velocity.z = 0.0
	
	var input := Vector3.ZERO
	
	if Input.is_action_pressed("ui_up"):
		input.z -= 1
	
	if Input.is_action_pressed("ui_down"):
		input.z += 1

	if Input.is_action_pressed("ui_left"):
		input.x -= 1
		
	if Input.is_action_pressed("ui_right"):
		input.x += 1
		
	input = input.normalized()
	
	var dir = (transform.basis.z * input.z + transform.basis.x * input.x)
	
	velocity.x = dir.x * moveSpeed
	velocity.z = dir.z * moveSpeed
	
	# Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y += jumpForce
		
	# Movimiento
	move_and_slide()

#@onready var weapon = $WeaponSocket/Weapon

#func _ready() -> void:
#	weapon.set_owner_body(self)
