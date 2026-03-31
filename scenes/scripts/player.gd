# Player.gd
extends CharacterBody2D

signal laser_shot(laser)

@export var acceleration := 10.0           #player acceleration
@export var max_speed := 300.0             #player max speed
@export var rotation_speed := 150.0        #player rotation speed
@onready var muzzle = $Muzzle

var laser_scene = preload("res://scenes/laser.tscn")

var shoot_cd = false  #shoot cooldown
var rate_of_fire = 0.2 #laser rate of fire

func _process(delta):
	if Input.is_action_pressed("shoot"): #check if the spacebar is pressed
		if !shoot_cd:                #check if the shoot cooldown is flase
			shoot_cd = true          #make shoot cooldown true
			shoot_laser()            #shoot the laser
			await get_tree().create_timer(rate_of_fire).timeout #wait for rate of fire seconds
			shoot_cd = false         #make shoot cooldown false
		

func _physics_process(delta):
	var input_vector := Vector2(0, Input.get_axis("move_forward", "move_backward"))
	
	#move the player with the rotated degrees
	velocity += input_vector.rotated(rotation) * acceleration
	#limit the player max speed
	velocity = velocity.limit_length(max_speed)
	
	#calculate the rotation if d is pressed
	if Input.is_action_pressed("rotate_right"):
		rotate(deg_to_rad(rotation_speed*delta))
	#calculate the rotation if a is pressed
	if Input.is_action_pressed("rotate_left"):
		rotate(deg_to_rad(-rotation_speed*delta))
	
	#make inertia movement
	if input_vector.y == 0:
		velocity = velocity.move_toward(Vector2.ZERO, 5)
	
	move_and_slide()

	
	var screen_size = get_viewport_rect().size  #get the screen size
	
	#if the player goes above the screen telepot him at the bottom of the screen
	if global_position.y < 0:
		global_position.y = screen_size.y
	#if the player goes bellow the screen telepot him at the top of the screen
	elif global_position.y > screen_size.y:
		global_position.y = 0
		
	#if the player goes outside of the right edge of the screen teleport him at the left edge
	if global_position.x < 0:
		global_position.x = screen_size.x
	#if the player goes outside of the left edge of the screen teleport him at the right edge
	elif global_position.x > screen_size.x:
		global_position.x = 0

func shoot_laser():
	#create a new laser instance
	var l = laser_scene.instantiate()
	#set the laser position to the muzzle position
	l.global_position = muzzle.global_position
	#set the laser rotation based on the player rotation
	l.rotation = rotation
	#emit the laser_shot signal and send the laser instance
	emit_signal("laser_shot", l)
