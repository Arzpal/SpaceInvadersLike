extends CharacterBody2D

const MAX_SPEED = 37000.0
@export var player: CharacterBody2D
var speed_variable= Vector2.ONE
var distances: Vector2
@export var speed_levels = [1.0, 10.0]

func _ready():
	if !player: return
	position = player.position

func _physics_process(delta):
	
	if !player: return
	
	velocity = player.velocity
	
	resolve_distances()
	
	#if the player is moving toward the horizontal direction it wants
	if sign(player.direction.x) == sign(velocity.x):
		velocity.x *= speed_variable.x
	#same with vertical logic
	if sign(player.direction.y) == sign(player.velocity.y):
		velocity.y *= speed_variable.y
		
	
	var to_player = Vector2(global_position.x, global_position.y)
	
	#if it wants to change into opposite direction
	if player.last_direction.x > 0 && player.position.x > position.x || player.last_direction.x < 0 && player.position.x < position.x:
		to_player.x = lerp(global_position.x, player.global_position.x, delta * 3)
	#same with vertical logic
	if player.last_direction.y < 0 && player.position.y > position.y || player.last_direction.y > 0 && player.position.y < position.y:
		to_player.y = lerp(global_position.y, player.global_position.y, delta * 3)
	
	#verify that doesnt go beyond MAX_SPEED
	velocity = Vector2(clamp(velocity.x, -MAX_SPEED * delta, MAX_SPEED * delta)
		, clamp(velocity.y, -MAX_SPEED * delta, MAX_SPEED * delta))
	
	
	if player.direction.x == 0 && distances.x >= 10:
		to_player.x = lerp(global_position.x, player.global_position.x, delta)
	
	if player.direction.y == 0 && distances.y >= 10:
		to_player.y = lerp(global_position.y, player.global_position.y, delta)
	
	global_position = to_player
	
	move_and_slide()

func resolve_distances():
	distances.x = abs(player.global_position.x - global_position.x)
	distances.y = abs(player.global_position.y - global_position.y)
	
	if distances.x > 250:
		speed_variable.x = speed_levels[0]
	else:
		speed_variable.x = speed_levels[1]
	
	
	if distances.y > 250:
		speed_variable.y = speed_levels[0]
	else:
		speed_variable.y = speed_levels[1]
	
