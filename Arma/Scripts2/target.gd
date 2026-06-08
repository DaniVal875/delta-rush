extends StaticBody3D

var is_active: bool = false

# Ruta de tu escena de partículas
var escena_explosion = preload("res://delta-rush/Mapa/Target/explosion_target.tscn")

func _ready() -> void:
	# El estado base/espera ahora es VERDE
	$GreenLight.light_color = Color.GREEN
	$GreenLight.visible = true
	_ajustar_rango_luz()
	
	# Nos aseguramos de que esté en los grupos correctos
	if not is_in_group("targets"):
		add_to_group("targets")
	if not is_in_group("reiniciables"):
		add_to_group("reiniciables")

func on_bullet_hit(hit_position: Vector3, hit_normal: Vector3, dano: float) -> void:
	if is_active:
		return
	is_active = true
	
	# 1. Lo sacamos del grupo inmediatamente para que cuente en la UI
	if is_in_group("targets"):
		remove_from_group("targets")
	
	# 2. Ejecutar la explosión
	_crear_explosion()
	
	# 3. Desactivar y ocultar el target (¡SIN DESTRUIRLO!)
	$GreenLight.visible = false
	$"target-large".visible = false
	
	if has_node("MeshInstance3D"):
		$MeshInstance3D.visible = false
		
	var shape_node := find_child("CollisionShape3D") as CollisionShape3D
	if shape_node:
		shape_node.set_deferred("disabled", true)

func _crear_explosion() -> void:
	var exp = escena_explosion.instantiate()
	get_tree().current_scene.add_child(exp) 
	exp.global_position = global_position
	
	# ¡El queue_free() se ha ido para siempre!

func _ajustar_rango_luz() -> void:
	var shape_node := find_child("CollisionShape3D") as CollisionShape3D
	if shape_node == null or shape_node.shape == null:
		return

	var tamanio := 1.0

	if shape_node.shape is BoxShape3D:
		tamanio = shape_node.shape.size.length()
	elif shape_node.shape is SphereShape3D:
		tamanio = shape_node.shape.radius * 2.0
	elif shape_node.shape is CapsuleShape3D:
		tamanio = shape_node.shape.height
		
	tamanio *= global_transform.basis.get_scale().length() / sqrt(3.0)
	$GreenLight.omni_range = tamanio * 2.0

func reiniciar_elemento() -> void:
	is_active = false
	
	# Al reiniciarse, vuelve a encenderse en VERDE
	$GreenLight.light_color = Color.GREEN
	$GreenLight.visible = true
	$"target-large".visible = true
	
	# Volvemos a mostrar el modelo 3D
	if has_node("MeshInstance3D"):
		$MeshInstance3D.visible = true
		
	# Reactivamos la colisión física
	var shape_node := find_child("CollisionShape3D") as CollisionShape3D
	if shape_node:
		shape_node.set_deferred("disabled", false)
	
	# Regresa al grupo para que cuente en la nueva vuelta
	if not is_in_group("targets"):
		add_to_group("targets")
