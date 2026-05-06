extends Control


func _on_btn_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://delta-rush/main.tscn")


func _on_btn_salir_pressed() -> void:
	get_tree().quit()
