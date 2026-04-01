extends Control

func _on_restart_button_pressed() -> void:
	#restart the game after the button is pressed
	get_tree().reload_current_scene()
