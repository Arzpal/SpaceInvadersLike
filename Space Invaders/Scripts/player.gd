extends CharacterBody2D

#movement
const SPEED = 1000.0
const MAX_SPEED = 50000.0
var isMoving = false
@onready var fire = $Fire

#rotation
var rotation_dir: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.ZERO
var both_pressed = false
@export var delay_time = 0.2
@onready var rotation_delay = $RotationDelay

#shoot
@export var bullet_scene: PackedScene
@onready var bullet_position = $BulletPosition
@onready var shooting = $Shooting

#damage
@onready var ship_sprite = $ShipSprite
@onready var death_timer = $Hurtbox/DeathTimer
@onready var hurtbox = $Hurtbox

func _ready():
	rotation_delay.wait_time = delay_time

func _physics_process(delta):
	movement_rotation(delta)
	if Input.is_action_just_pressed("shoot"):
		shoot()

func movement_rotation(delta):
	var direction = Vector2(
		Input.get_axis("m_left", "m_right"),
		Input.get_axis("m_up", "m_down"))
	
	if abs(direction.x) == 1 && abs(direction.y) == 1:
		both_pressed = true
	
	if direction != Vector2.ZERO:
		velocity += last_direction * SPEED * delta
		if !fire.is_playing():
			fire.play("Fire")
	else:
		velocity -= velocity * delta
		if abs(velocity.x) < 3 : velocity.x = 0
		if abs(velocity.y) < 3 : velocity.y = 0
		fire.play("Idle")
		fire.stop()
	
	velocity = Vector2(clamp(velocity.x, -MAX_SPEED * delta, MAX_SPEED * delta), clamp(velocity.y, -MAX_SPEED * delta, MAX_SPEED * delta))
	
	if !both_pressed && direction != Vector2.ZERO: #if just touching one button
		last_direction = direction.normalized()
	elif both_pressed && direction.x * direction.y == 0 && abs(direction.x) + abs(direction.y) != 0: #if one of them has been released
		if(rotation_delay.is_stopped()):
			rotation_delay.start()
	elif direction != Vector2.ZERO:
		last_direction = direction.normalized()
	
	_rotate_direction()
	move_and_slide()

func _rotate_direction():
	# Use last_direction if the timer is active
	if rotation_delay.is_stopped():
		rotation_dir = last_direction
	
	rotation_degrees = atan2(rotation_dir.x, -rotation_dir.y) * 180 / PI

func _on_rotation_delay_timeout():
	both_pressed = false
	rotation_dir = last_direction

func shoot():
	var bullet = bullet_scene.instantiate()
	if shooting.is_playing(): shooting.stop()
	shooting.play("Fire")
	bullet.spawn_pos = bullet_position.global_position
	bullet.spawn_rot = bullet_position.global_rotation
	bullet.speed_dir = rotation_dir
	bullet_position.add_child(bullet)

func _on_hurt():
	velocity.x /= 2
	velocity.y /= 2
	
	ship_sprite.play("Hurt")
	fire.hide()
	hurtbox.set_deferred("monitoring", false)
	Engine.time_scale = 0.7
	ship_sprite.speed_scale = 1.3
	await ship_sprite.animation_finished
	ship_sprite.speed_scale = 1
	#make animation to semi vulnerability
	hurtbox.set_deferred("monitoring", true)
	Engine.time_scale = 1
	fire.show()
	ship_sprite.play("Idle")

func _on_death():
	ship_sprite.play("Death")
	fire.hide()
	Engine.time_scale = 0.5
	ship_sprite.speed_scale = 1.5
	hurtbox.set_deferred("monitoring", false)
	#collision_shape_2d.disabled = true
	await ship_sprite.animation_finished
	death_timer.start()

func _on_death_timer_timeout():
	Engine.time_scale = 1
	get_tree().reload_current_scene()
