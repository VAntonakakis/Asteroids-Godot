extends Control

func _ready() -> void:
	#hide the pause menu when the scene starts
	visible = false

func _on_resume_button_pressed() -> void:
	#resume the game after the button is pressed
	get_tree().paused = false
	visible = false

func _on_restart_button_pressed() -> void:
	#restart the game after the button is pressed
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	#go back to the main menu after the button is pressed
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
