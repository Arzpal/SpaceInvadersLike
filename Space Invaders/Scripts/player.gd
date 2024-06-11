extends CharacterBody2D

#movement
const MAX_SPEED = 25000.0
const DELTA_SPEED = 100
var is_moving = false
@export var moving_speed = 10.0
@onready var fire = $Fire
var direction: Vector2

#rotation
var rot_dir: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.ZERO
var both_pressed = false
@export var delay_time = 0.2
@onready var rot_delay = $RotationDelay

#shoot
@export var regular_blt_sc: PackedScene
@export var charged_blt_sc: PackedScene
@onready var reg_blt_pos1 = $BulletPosition1
@onready var reg_blt_pos2 = $BulletPosition2
var is_targeting = false

#charging shoot
@onready var shooting = $Shooting
var charging_speed = 0.0
var charged_limit = 3

#damage
@onready var ship_sprite = $ShipSprite
@onready var death_timer = $Hurtbox/DeathTimer
@onready var hurtbox = $Hurtbox

func _ready():
	rot_delay.wait_time = delay_time

func _physics_process(delta):
	movement_rotation(delta)
	
	if Input.is_action_pressed("shoot") && !is_moving:
		on_shooting_rotation(delta)
	if Input.is_action_just_released("shoot") && !is_moving:
		shoot()

func movement_rotation(delta):
	direction = Vector2(
		Input.get_axis("m_left", "m_right"),
		Input.get_axis("m_up", "m_down"))
	
	#checking if both direction axis are changing
	if abs(direction.x) == 1 && abs(direction.y) == 1:
		both_pressed = true
	
	direction = direction.normalized()
	
	#executing movement if new direction and if not targeting
	if direction != Vector2.ZERO && !is_targeting:
		velocity += last_direction * moving_speed * DELTA_SPEED * delta
		is_moving = true
		if !fire.is_playing():
			fire.play("Fire")
		#reducing previous movement on an axis the player is not moving anymore
		if direction.x == 0:
			velocity.x = lerp(velocity.x, 0.0, delta * 2)
		elif direction.y == 0:
			velocity.y = lerp(velocity.y, 0.0, delta * 2)
	
	#reducing if not new direction
	elif direction == Vector2.ZERO:
		velocity -= velocity * delta * 1.25
		is_moving = false
		if abs(velocity.x) < 3 : velocity.x = 0
		if abs(velocity.y) < 3 : velocity.y = 0
		fire.play("Idle")
		fire.stop()
	
	#verify that doesnt go beyond MAX_SPEED
	velocity = Vector2(clamp(velocity.x, -MAX_SPEED * delta, MAX_SPEED * delta)
		, clamp(velocity.y, -MAX_SPEED * delta, MAX_SPEED * delta))
	
	#if one of them has been released
	if both_pressed && direction.x * direction.y == 0 && abs(direction.x) + abs(direction.y) != 0: 
		if(rot_delay.is_stopped()):
			rot_delay.start()
	#if just touching one button or none
	elif direction != Vector2.ZERO: 
		last_direction = direction.normalized()
	
	_rotate_direction()
	move_and_slide()

#rotate direction in general
func _rotate_direction():
	if !is_moving: return
	
	# Use last_direction if the timer is active
	if rot_delay.is_stopped():
		rot_dir = last_direction
	
	rotation_degrees = atan2(rot_dir.x, -rot_dir.y) * 180 / PI

#preserves last direction in case the intention was to maintain diagonally
func _on_rotation_delay_timeout():
	both_pressed = false
	rot_dir = last_direction

#rotates towards mouse while targeting
func on_shooting_rotation(delta):
	is_targeting = true
	# Calculate the direction vector from the object to the mouse
	var rotation_dir = (get_global_mouse_position() - global_position).normalized()
	var godot_adjusted_dir = Vector2(-rotation_dir.y, rotation_dir.x)
	look_at(global_position + godot_adjusted_dir)
	var shoot_anim_name = ""
	var ship_anim_name = ""
	if charging_speed < charged_limit:
		charging_speed += delta
		shoot_anim_name = "Charge1"
		if charging_speed < charged_limit / 3: ship_anim_name = "Idle"
		else: ship_anim_name = "Charging1"
	else:
		shoot_anim_name = "Charge2"
		ship_anim_name = "Charging2"
	shooting.play(shoot_anim_name)
	ship_sprite.play(ship_anim_name)
	

#play shooting animation, throws the bullet and provides it with the direction to go
func shoot():
	is_targeting = false
	
	if charging_speed < charged_limit:
		var bullet1 = regular_blt_sc.instantiate()
		var bullet2 = regular_blt_sc.instantiate() 
		if shooting.is_playing(): shooting.stop()
		shooting.play("Fire1")
		assign_bullet_rot(bullet1, reg_blt_pos1)
		assign_bullet_rot(bullet2, reg_blt_pos2)
	else:
		var charged_bullet = charged_blt_sc.instantiate()
		if shooting.is_playing(): shooting.stop()
		shooting.play("Fire2")
		assign_bullet_rot(charged_bullet, shooting)
	
	charging_speed = 0
	ship_sprite.play("Idle")

func assign_bullet_rot(bullet, bullet_pos):
	bullet.spawn_pos = bullet_pos.global_position
	bullet.spawn_rot = bullet_pos.global_rotation
	bullet.speed_dir = global_rotation - PI / 2
	
	bullet_pos.add_child(bullet)

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
	Engine.time_scale = 1
	ship_sprite.play("AfterHurt")
	fire.show()
	await ship_sprite.animation_finished
	hurtbox.set_deferred("monitoring", true)
	ship_sprite.play("Idle")

func _on_death():
	ship_sprite.play("Death")
	is_moving = true
	is_targeting = true
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
