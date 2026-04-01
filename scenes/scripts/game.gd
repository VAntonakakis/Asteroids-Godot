extends Node

@onready var lasers = $Lasers
@onready var player = $Player
@onready var asteroids = $Asteroids
@onready var hud = $UI/hud
@onready var game_over_screen = $UI/GameOverScreen
@onready var player_spawn_pos = $PlayerSpawnPos

var asteroid_scene = preload("res://scenes/asteroid.tscn")

var score := 0: #game score
	set(value):
		score = value
		hud.score = score

var lives: int: #game lives
	set(value):
		lives = value
		hud.init_lives(lives)
var points := 50 #base points


func _ready():
	#connect the player laser signal to the game
	player.connect("laser_shot", _on_player_laser_shot)
	#connect the player died signal to the game
	player.connect("Died", _on_player_died)
	#init the score and lives
	game_over_screen.visible = false
	score = 0
	lives = 3
	
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
				score += points / 2
				spawn_asteroid(pos, Asteroid.AsteroidSize.MEDIUM)
			Asteroid.AsteroidSize.MEDIUM:
				score += points
				spawn_asteroid(pos, Asteroid.AsteroidSize.SMALL )
			Asteroid.AsteroidSize.SMALL:
				score += 3 * points / 2
				#small asteroids do not split further
				pass
	#print(score)
	  
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

func _on_player_died():
	#remove one live from player each time he has a colision with an asteroid
	lives -= 1
	if lives == 0:
		#if the player has 0 lives left make the game over screen visible
		await get_tree().create_timer(2).timeout
		game_over_screen.visible = true
	else:
		#respawn the player in the center of the map
		await get_tree().create_timer(1).timeout
		player.respawn(player_spawn_pos.global_position)
