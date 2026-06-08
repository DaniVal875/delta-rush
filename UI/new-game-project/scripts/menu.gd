extends Control

@onready var boton_jugar = $VBoxContainer/btnJugar

func _ready():
	# Le damos el foco al botón apenas carga la escena
	boton_jugar.grab_focus()

func _on_btn_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://delta-rush/main.tscn")


func _on_btn_salir_pressed() -> void:
	get_tree().quit()
