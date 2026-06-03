extends StaticBody3D

var is_active: bool = false

func _ready() -> void:
	$GreenLight.light_color = Color.RED
	$GreenLight.visible = true
	_ajustar_rango_luz()

func on_bullet_hit(hit_position: Vector3, hit_normal: Vector3, dano: float) -> void:
	if is_active:
		return
	is_active = true
	$GreenLight.light_color = Color.GREEN

func _ajustar_rango_luz() -> void:
	# Obtener el tamaño del CollisionShape para escalar el rango de la luz
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
		
	# Multiplicar por la escala global para considerar instancias redimensionadas
	tamanio *= global_transform.basis.get_scale().length() / sqrt(3.0)
	
	$GreenLight.omni_range = tamanio * 2.0
