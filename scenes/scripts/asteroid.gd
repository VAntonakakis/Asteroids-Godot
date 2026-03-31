class_name Asteroid extends Area2D

signal exploded(pos, size)

var movement_vector := Vector2(0,-1)

enum AsteroidSize{LARGE,MEDIUM,SMALL}
@export var size := AsteroidSize.LARGE 

var speed := 200 	

@onready var sprite = $Sprite2D	
@onready var cshape = $CollisionShape2D

func _ready():
	#give the asteroid a random starting rotation
	rotation = randf_range(0, 2*PI)
	
	#set speed, sprite and collision shape based on asteroid size
	match  size:
		AsteroidSize.LARGE:
			speed = randf_range(50,100)
			sprite.texture = preload("res://assets/texture/meteorBrown_big4.png")
			cshape.set_deferred("shape",preload("res://resources/asteroid_cshape_large.tres"))
		AsteroidSize.MEDIUM:
			speed = randf_range(100,150)
			sprite.texture = preload("res://assets/texture/meteorBrown_med1.png")
			cshape.set_deferred("shape",preload("res://resources/asteroid_cshape_medium.tres"))
		AsteroidSize.SMALL:
			speed = randf_range(100,200)
			sprite.texture = preload("res://assets/texture/meteorBrown_tiny1.png")
			cshape.set_deferred("shape",preload("res://resources/asteroid_cshape_small.tres"))
	print(speed)
	
func _physics_process(delta):
	#move the asteroid based on its rotation and speed
	global_position += movement_vector.rotated(rotation) * speed * delta
	
	#get asteroid radius from collision shape
	var radius = cshape.shape.radius
	var screen_size = get_viewport_rect().size  #get the screen size
	
	#if the asteroid goes above the screen teleport it at the bottom of the screen
	if (global_position.y + radius) < 0:
		global_position.y = (screen_size.y+radius)
	#if the asteroid goes bellow the screen teleport it at the top of the screen
	elif (global_position.y-radius) > screen_size.y:
		global_position.y = -radius	
		
	#if the asteroid goes outside of the right edge of the screen teleport it at the left edge
	if (global_position.x + radius) < 0:
		global_position.x = (screen_size.x+radius)
	#if the asteroid goes outside of the left edge of the screen teleport it at the right edge
	elif (global_position.x-radius) > screen_size.x:
		global_position.x = -radius 
		
func explode():
	#emit the exploded signal with the asteroid position and size
	emit_signal("exploded", global_position, size)
	#delete the asteroid after exploding
	queue_free()
