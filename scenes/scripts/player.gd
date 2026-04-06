# Player.gd
class_name Player extends CharacterBody2D

signal laser_shot(laser)
signal Died
signal slow_motion_state_changed(active)

@export var acceleration := 10.0           #player acceleration
@export var max_speed := 300.0             #player max speed
@export var rotation_speed := 150.0        #player rotation speed
@onready var muzzle = $Muzzle
@onready var cshape = $CollisionShape2D
@onready var sprite = $Sprite2D
@onready var hud = $"../UI/hud"

var laser_scene = preload("res://scenes/laser.tscn")

var shoot_cd = false  #shoot cooldown
var rate_of_fire = 0.2 #laser rate of fire

var alive = true

var slow_motion_energy := 100.0 #current slow motion energy
var max_slow_motion_energy := 100.0 #maximum slow motion energy
var slow_motion_drain := 6.0 #how fast the slow motion energy drains
var slow_motion_recharge := 3.0 #how fast the slow motion energy recharges
var slow_motion_active := false #check if slow motion is active


func _ready():
	#initialize the slow motion bar
	hud.update_slow_motion_bar(slow_motion_energy)

func _process(delta):
	#if the player dies stop moving and disable slow motion
	if !alive:
		disable_slow_motion()
		return
	
	#check if the slow motion button is pressed and there is energy left
	if Input.is_action_pressed("slow_motion") and slow_motion_energy > 0:
		enable_slow_motion()
		#drain slow motion energy while the ability is active
		slow_motion_energy -= slow_motion_drain * delta
		slow_motion_energy = max(slow_motion_energy, 0)
	else:
		disable_slow_motion()
		#recharge slow motion energy when the ability is not active
		slow_motion_energy += slow_motion_recharge * delta
		slow_motion_energy = min(slow_motion_energy, max_slow_motion_energy)
	
	#update the slow motion energy bar in the hud
	hud.update_slow_motion_bar(slow_motion_energy)
		
	if Input.is_action_pressed("shoot"): #check if the spacebar is pressed
		if !shoot_cd:                #check if the shoot cooldown is flase
			shoot_cd = true          #make shoot cooldown true
			shoot_laser()            #shoot the laser
			await get_tree().create_timer(rate_of_fire).timeout #wait for rate of fire seconds
			shoot_cd = false         #make shoot cooldown false

func _physics_process(delta):
	#if the player dies stop moving
	if !alive:
		return
		
	var input_vector := Vector2(0, Input.get_axis("move_forward", "move_backward"))
	
	#move the player with the rotated degrees
	velocity += input_vector.rotated(rotation) * acceleration
	#limit the player max speed
	velocity = velocity.limit_length(max_speed)
	
	#calculate the rotation if d is pressed
	if Input.is_action_pressed("rotate_right"):
		rotate(deg_to_rad(rotation_speed * delta))
	#calculate the rotation if a is pressed
	if Input.is_action_pressed("rotate_left"):
		rotate(deg_to_rad(-rotation_speed * delta))
	
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

func enable_slow_motion():
	#if slow motion is not already active activate it
	if !slow_motion_active:
		slow_motion_active = true
		emit_signal("slow_motion_state_changed", true)

func disable_slow_motion():
	#if slow motion is active disable it
	if slow_motion_active:
		slow_motion_active = false
		emit_signal("slow_motion_state_changed", false)

func die():
	# if the player is alive kill him 
	if alive == true:
		alive = false
		sprite.visible = false
		cshape.set_deferred("disabled", true)
		#disable slow motion when the player dies
		disable_slow_motion()
		emit_signal("Died")

func respawn(pos):
	if alive == false:
		#if the player is dead revive him.
		alive = true
		global_position = pos
		velocity = Vector2.ZERO
		sprite.visible = true
		cshape.set_deferred("disabled", false)
