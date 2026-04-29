extends Node3D

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 30.0
@export var projectile_damage: float = 10.0
@export var fire_interval: float = 0.25
@export var shoot_action: String = "shoot"

var can_shoot: bool = true
var owner_body: Node = null

func _ready() -> void:
	$FireCooldown.timeout.connect(_on_fire_cooldown_timeout)

func set_owner_body(new_owner: Node) -> void:
	owner_body = new_owner

func _process(_delta: float) -> void:
	if Input.is_action_pressed(shoot_action) and can_shoot:
		shoot()

func shoot() -> void:
	if projectile_scene == null:
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.setup(
		$Muzzle.global_transform,
		projectile_damage,
		projectile_speed,
		owner_body
	)

	can_shoot = false
	$FireCooldown.start(fire_interval)

func _on_fire_cooldown_timeout() -> void:
	can_shoot = true
