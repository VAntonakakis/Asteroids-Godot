extends Node

@onready var lasers = $Lasers
@onready var player = $Player
@onready var asteroids = $Asteroids
@onready var hud = $UI/hud
@onready var game_over_screen = $UI/GameOverScreen
@onready var player_spawn_pos = $PlayerSpawnPos
@onready var player_spawn_area = $PlayerSpawnPos/PlayerSpawnArea
@onready var pause_menu = $UI/PauseMenu
@onready var game_music = $GameMusic

var asteroid_scene = preload("res://scenes/asteroid.tscn")
var current_wave := 1 #current wave number
var asteroids_per_wave := 5 #how many large asteroids spawn in each wave
var wave_in_progress := false #check if a wave is currently active

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
	#connect the player slow motion signal to the game
	player.connect("slow_motion_state_changed", _on_player_slow_motion_state_changed)
	
	#init the score and lives
	game_over_screen.visible = false

	
	score = 0
	lives = 3
	
	#connect all existing asteroids to the exploded signal
	for asteroid in asteroids.get_children():
		asteroid.connect("exploded", _on_asteroid_exploded)
	
	start_wave()

func _process(delta):
	#if the pause key is pressed pause or unpause the game
	if Input.is_action_just_pressed("pause") and !game_over_screen.visible:
		if get_tree().paused:
			get_tree().paused = false
			pause_menu.visible = false
		else:
			#up the music volume when the game is paused
			game_music.volume_db = 0
			pause_menu.visible = true
			get_tree().paused = true

	#if the reset key is pressed reload the current scene
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

func _on_player_slow_motion_state_changed(active):
	#apply slow motion state to all current asteroids
	for asteroid in asteroids.get_children():
		asteroid.set_slow_motion(active)

func _on_player_laser_shot(laser):
	#add the spawned laser to the lasers container
	#laser sound
	$LaserSound.play()
	lasers.add_child(laser)

func _on_asteroid_exploded(pos, size):
	#ASTEROID HIT SOUND
	$AsteroidHitSound.play()
	
	#spawn 2 smaller asteroids when a large or medium asteroid explodes
	match size:
		Asteroid.AsteroidSize.LARGE:
			score += points / 2
			for i in range(2):
				spawn_asteroid(pos, Asteroid.AsteroidSize.MEDIUM)

		Asteroid.AsteroidSize.MEDIUM:
			score += points
			for i in range(2):
				spawn_asteroid(pos, Asteroid.AsteroidSize.SMALL)

		Asteroid.AsteroidSize.SMALL:
			score += 3 * points / 2
			#small asteroids do not split further
			pass

	print("Asteroid exploded. Remaining now: ", asteroids.get_child_count())
	call_deferred("check_wave_clear")

func spawn_asteroid(pos, size):
	#create a new asteroid instance
	var a = asteroid_scene.instantiate()
	#set the asteroid position
	a.global_position = pos
	#set the asteroid size
	a.size = size
	#connect the exploded signal of the new asteroid
	a.connect("exploded", _on_asteroid_exploded)
	#apply current slow motion state to the new asteroid
	a.set_slow_motion(player.slow_motion_active)
	#add the asteroid to the asteroids container
	asteroids.call_deferred("add_child", a)

func spawn_asteroid_random(size):
	#create a new asteroid instance
	var a = asteroid_scene.instantiate()
	var screen_size = get_viewport().get_visible_rect().size
	
	#keep generating random positions until the asteroid is not too close to the player
	var spawn_position := Vector2.ZERO
	while true:
		spawn_position = Vector2(
			randf_range(0, screen_size.x),
			randf_range(0, screen_size.y)
		)
		
		#if the asteroid is far enough from the player stop the loop
		if spawn_position.distance_to(player.global_position) > 200:
			break
	
	print("Spawned asteroid at: ", spawn_position)
	
	#set the asteroid position
	a.global_position = spawn_position
	#set the asteroid size
	a.size = size
	#connect the exploded signal of the new asteroid
	a.connect("exploded", _on_asteroid_exploded)
	#apply current slow motion state to the new asteroid
	a.set_slow_motion(player.slow_motion_active)
	#add the asteroid to the asteroids container
	asteroids.add_child(a)

func start_wave():
	#set the wave as active
	wave_in_progress = true
	print("Starting wave: ", current_wave, " with ", asteroids_per_wave, " asteroids")
	
	#spawn large asteroids for the current wave
	for i in range(asteroids_per_wave):
		spawn_asteroid_random(Asteroid.AsteroidSize.LARGE)
	
	#update the hud wave label if it exists
	if hud.has_method("update_wave"):
		hud.update_wave(current_wave)

func check_wave_clear():
	print("Checking wave clear. Asteroids count: ", asteroids.get_child_count())
	
	#if there are 1 to 3 asteroids left print their position and size for debugging
	if asteroids.get_child_count() > 0 and asteroids.get_child_count() <= 3:
		for a in asteroids.get_children():
			print("Remaining asteroid -> position: ", a.global_position, " size: ", a.size)
	
	#if there are no asteroids left and a wave is active start the next wave
	if asteroids.get_child_count() <= 2 and wave_in_progress:
		print("WAVE CLEARED")
		wave_in_progress = false
		#increase the number of asteroids based on the current wave
		asteroids_per_wave += current_wave
		
		#move to the next wave
		current_wave += 1
		
		#small delay before the next wave starts
		await get_tree().create_timer(1.5).timeout
		start_wave()

func _on_player_died():
	#remove one live from player each time he has a colision with an asteroid
	#player death sound
	$PlayerDies.play()
	lives -= 1
	player.global_position = player_spawn_pos.global_position
	
	if lives == 0:
		#if the player has 0 lives left make the game over screen visible
		await get_tree().create_timer(2).timeout
		game_over_screen.visible = true
	else:
		#respawn the player in the spawn area if there are not asteroids in it
		await get_tree().create_timer(1).timeout
		while !player_spawn_area.is_empty:
			await get_tree().create_timer(0.1).timeout
		player.respawn(player_spawn_pos.global_position)
