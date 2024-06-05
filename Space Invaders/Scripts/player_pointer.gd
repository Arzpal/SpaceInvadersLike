extends Node2D

const MAX_SPEED = 37000.0

@export var player: CharacterBody2D
@export var movement_speed = 6

@onready var pointing_timer = $PointingTimer

var player_pos: Vector2
var pointer_pos: Vector2
var pointing = false
var delta_time

func _ready():
	if !player: return
	position = player.position

func _physics_process(delta):
	
	if !player: return
	
	player_pos = player.global_position
	pointer_pos = player.get_node("Marker2D").global_position
	
	if player.is_targeting:
		if !pointing_timer.is_stopped(): pointing_timer.stop()
		changing_pointing_state(true)
	elif !player.is_targeting && pointing:
		if pointing_timer.is_stopped(): pointing_timer.start()
	if player.direction != Vector2.ZERO && !player.is_targeting:
		if !pointing_timer.is_stopped(): pointing_timer.stop()
		changing_pointing_state(false)
	
	delta_time = delta
	moving_cam(pointing)

func moving_cam(is_pointing):
	var target_pos: Vector2
	
	if is_pointing:
		target_pos = pointer_pos
	else:
		target_pos = player_pos
	
	var moving_pos = Vector2(lerp(global_position.x, target_pos.x, delta_time * movement_speed), lerp(global_position.y, target_pos.y, delta_time * movement_speed))
	
	global_position = moving_pos

func changing_pointing_state(is_pointing):
	pointing = is_pointing
