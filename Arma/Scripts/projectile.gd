extends Area3D

@export var speed: float = 30.0
@export var damage: float = 10.0
@export var life_time: float = 3.0

var direction: Vector3 = Vector3.ZERO
var shooter: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$LifeTimer.timeout.connect(_on_life_timer_timeout)

func setup(start_transform: Transform3D, projectile_damage: float, projectile_speed: float, owner_shooter: Node = null) -> void:
	global_transform = start_transform
	scale = Vector3.ONE
	damage = projectile_damage
	speed = projectile_speed
	shooter = owner_shooter
	direction = -global_transform.basis.z.normalized()
	$LifeTimer.start(life_time)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)

	if body.has_method("on_projectile_hit"):
		body.on_projectile_hit(self)

	queue_free()

func _on_life_timer_timeout() -> void:
	queue_free()
