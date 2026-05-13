extends CanvasLayer

@onready var btn_reanudar = $PauseMenu/ColorRect/VBoxContainer/btnReanudar
@onready var btn_salir = $PauseMenu/ColorRect/VBoxContainer/btnSalirMenuPrincipal

func _ready():
	$PauseMenu.hide()
	$Mira.show()
	process_mode = Node.PROCESS_MODE_ALWAYS   # ← Muy importante

	# Conectar botones de forma segura
	if btn_reanudar:
		btn_reanudar.pressed.connect(_on_reanudar_pressed)
	if btn_salir:
		btn_salir.pressed.connect(_on_salir_pressed)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var paused = get_tree().paused
	get_tree().paused = not paused
	
	if not paused:        # Si estaba sin pausar → ahora pausamos
		$PauseMenu.show()
		$Mira.hide()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		$PauseMenu.hide()
		$Mira.show()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_reanudar_pressed():
	get_tree().paused = false
	$PauseMenu.hide()
	$Mira.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_salir_pressed():
	get_tree().paused = false
	# === CAMBIA ESTA RUTA por la correcta de tu menú principal ===
	get_tree().change_scene_to_file("res://delta-rush/UI/new-game-project/escenas/menu2.tscn")
	
