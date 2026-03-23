extends Node

@onready var lasers = $Lasers
@onready var player = $Player
@onready var asteroids = $Asteroids

var asteroid_scene = preload("res://scenes/asteroid.tscn")

func _ready():
	#connect the player laser signal to the game
	player.connect("laser_shot", _on_player_laser_shot)
	
	#connect all existing asteroids to the exploded signal
	for asteroid in asteroids.get_children():
		asteroid.connect("exploded", _on_asteroid_exploded)

func _process(delta):
	#if the reset key is pressed reload the current scene
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

func _on_player_laser_shot(laser):
	#add the spawned laser to the lasers container
	lasers.add_child(laser)

func _on_asteroid_exploded(pos, size):
	#spawn 2 smaller asteroids when a large or medium asteroid explodes
	for i in range(2):
		match size:
			Asteroid.AsteroidSize.LARGE:
				spawn_asteroid(pos, Asteroid.AsteroidSize.MEDIUM)
			Asteroid.AsteroidSize.MEDIUM:
				spawn_asteroid(pos, Asteroid.AsteroidSize.SMALL )
			Asteroid.AsteroidSize.SMALL:
				#small asteroids do not split further
				pass
	  
func spawn_asteroid(pos,size):
	#create a new asteroid instance
	var a = asteroid_scene.instantiate()
	#set the asteroid position
	a.global_position = pos 
	#set the asteroid size
	a.size = size
	#connect the exploded signal of the new asteroid
	a.connect("exploded",_on_asteroid_exploded)
	#add the asteroid to the asteroids container
	asteroids.call_deferred("add_child", a)
