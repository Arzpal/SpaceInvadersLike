extends RigidBody2D

const SPEED_DELTA = 10000.0
@export var speed_variable = 5
var speed_dir: float

var spawn_pos: Vector2
var spawn_rot: float

var dead = false

@export var timer_delay = 0.0
@onready var timer = $Timer

@onready var hitbox = $Hitbox

@onready var animated_sprite_2d = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	global_position = spawn_pos
	global_rotation = spawn_rot
	timer.wait_time = timer_delay
	timer.start()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var speed = SPEED_DELTA * delta * speed_variable
	var speed_normalized_dir = Vector2(cos(speed_dir), sin(speed_dir))
	var speed_movement = Vector2(speed_normalized_dir.x * speed, speed_normalized_dir.y * speed)
	set_axis_velocity(speed_movement)

func on_hitbox_impact():
	hitbox.set_deferred("disabled", true)
	speed_variable = 0
	linear_velocity = Vector2(0,0)
	animated_sprite_2d.play("Explosion")
	await animated_sprite_2d.animation_finished
	queue_free()
