extends Node3D

@export var color: Color = Color("0087ff")   # Amarillo cálido, ajústalo a tu gusto
@export var emission_energy: float = 3.0
@export var lifetime: float = 0.12                 # Segundos que dura la estela

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
# Ya no necesitamos el Timer porque usaremos un Tween, pero puedes dejar el nodo ahí sin problema.

var _material: StandardMaterial3D

func setup(from: Vector3, to: Vector3) -> void:
	var distance := from.distance_to(to)

	# 1. Poner el nodo padre EXACTAMENTE en el punto de impacto (to)
	global_position = to
	
	# 2. Hacer que mire hacia el punto de origen (from)
	if distance > 0.001:
		look_at(from, Vector3.UP)

	# --- Mesh: cilindro delgado de longitud = distancia ---
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = distance
	cylinder.radial_segments = 6   # Pocas caras, es un efecto rápido

	# 3. Rotar el cilindro y desfasarlo hacia atrás para que cubra la distancia exacta
	mesh_instance.rotation_degrees.x = 90.0
	# Lo movemos en Z negativo la mitad de su tamaño para que la base toque el punto de impacto y la punta toque el arma
	mesh_instance.position.z = -distance / 2.0
	mesh_instance.mesh = cylinder

	# --- Material con emisión ---
	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	_material.emission_enabled = true
	_material.emission = color
	_material.emission_energy_multiplier = emission_energy
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.set_surface_override_material(0, _material)

	# --- Iniciar la animación combinada (Escala y Transparencia) ---
	var tween = create_tween()
	tween.set_parallel(true) # Hace que todas las animaciones siguientes ocurran al mismo tiempo
	
	# Efecto de recogimiento: Encogemos la escala Z hacia 0 (se "traga" la bala hacia la pared)
	tween.tween_property(self, "scale:z", 0.0, lifetime).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# Desvanecemos el alpha y la emisión progresivamente hasta 0
	tween.tween_property(_material, "albedo_color:a", 0.0, lifetime)
	tween.tween_property(_material, "emission_energy_multiplier", 0.0, lifetime)
	
	# Cuando el tween termine (es decir, pase el 'lifetime'), destruimos la escena
	tween.chain().tween_callback(queue_free)

# Dejamos esta función vacía por si todavía tienes conectado el Timer del nodo para que no tire error
func _on_timer_timeout() -> void:
	pass
