extends StaticBody3D

var is_active: bool = false

func _ready() -> void:
	$GreenLight.visible = false
	$ResetTimer.timeout.connect(_on_reset_timer_timeout)

func on_projectile_hit(projectile: Node) -> void:
	if is_active:
		return

	is_active = true
	$GreenLight.visible = true
	$ResetTimer.start()

func _on_reset_timer_timeout() -> void:
	is_active = false
	$GreenLight.visible = false
