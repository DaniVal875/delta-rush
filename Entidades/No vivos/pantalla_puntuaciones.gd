extends Node3D

@onready var grid_puntuaciones = $SubViewport/Control/VBoxContainer/GridContainer

# Lista de puntuaciones predeterminadas (Fantasmas)
var tabla_records = [
	{"nombre": "T. Lastimosa", "tiempo": 91.10},
	{"nombre": "Dani REY", "tiempo": 94.45},
	{"nombre": "Zared", "tiempo": 98.20},
	{"nombre": "E. Tostado", "tiempo": 102.15},
	{"nombre": "R. Hakik", "tiempo": 107.80},
	{"nombre": "Pollo Asado", "tiempo": 112.50},
	{"nombre": "Vidal", "tiempo": 118.30},
	{"nombre": "El Greñas", "tiempo": 124.90},
	{"nombre": "Pachito", "tiempo": 130.15},
	{"nombre": "Jando", "tiempo": 136.40},
	{"nombre": "Eduardo", "tiempo": 142.85},
	{"nombre": "Cletoo", "tiempo": 149.60},
	{"nombre": "El Gringo", "tiempo": 156.20},
	{"nombre": "C. Lemer", "tiempo": 163.05},
	{"nombre": "Hayabusa", "tiempo": 169.30},
	{"nombre": "TU", "tiempo": 0.0} 
]

func _ready():
	actualizar_pizarra()

func actualizar_pizarra():
	for n in grid_puntuaciones.get_children():
		n.queue_free()
	
	tabla_records.sort_custom(func(a, b): 
		if a["tiempo"] <= 0: return false
		if b["tiempo"] <= 0: return true
		return a["tiempo"] < b["tiempo"]
	)

	for i in range(tabla_records.size()):
		var record = tabla_records[i]
		
		crear_label_en_grid("%02d" % (i + 1), Color.GRAY)
		
		# Verificamos exactamente "TU" para pintarlo de Cyan
		var color_nombre = Color.CYAN if record["nombre"] == "TU" else Color.WHITE
		crear_label_en_grid(record["nombre"], color_nombre)
		
		if record["tiempo"] > 0:
			crear_label_en_grid("%.2f" % record["tiempo"], Color.GOLD)
		else:
			crear_label_en_grid("--:--", Color.DARK_GRAY)


var fuente_pizarra = preload("res://delta-rush/Assets Compartidos/Estilo de texto/mono_2/' Mono Bold.ttf")

func crear_label_en_grid(texto: String, color: Color):
	var lbl = Label.new()
	lbl.text = texto
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_override("font", fuente_pizarra)
	lbl.add_theme_font_size_override("font_size", 40) 
	grid_puntuaciones.add_child(lbl)

func registrar_nuevo_tiempo(nuevo_tiempo: float):
	for record in tabla_records:
		# Buscamos exactamente "TU" para actualizar el récord
		if record["nombre"] == "TU":
			if record["tiempo"] == 0.0 or nuevo_tiempo < record["tiempo"]:
				record["tiempo"] = nuevo_tiempo
	
	actualizar_pizarra()
