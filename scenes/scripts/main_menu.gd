extends Control


func _on_start_button_pressed():
	#get inside the game scene when the start button is pressed
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit_button_pressed():
	#close the game when the quit button is pressed
	get_tree().quit()
