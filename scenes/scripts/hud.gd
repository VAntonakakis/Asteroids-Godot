extends Control

@onready var score = $Score:
	set(value):
		score.text = "SCORE: " + str(value)

var uilife_scene = preload("res://scenes/ui_life.tscn")
@onready var lives = $Lives
@onready var wave = $Wave
@onready var slow_motion_bar = $SlowMotionBar

#clear the queue and initialize the lives
func init_lives(amount):
	for ul in lives.get_children():
		ul.queue_free()
	for i in amount:
		var ul = uilife_scene.instantiate()
		lives.add_child(ul)

func update_wave(amount):
	wave.text = "WAVE: " + str(amount)

func update_slow_motion_bar(amount):
	#update the slow motion energy bar
	slow_motion_bar.value = amount
