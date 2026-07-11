# enemy.gd
extends CharacterBody2D

@export var speed: float = 150.0
@export var gravity: float = 980.0

var player: CharacterBody2D = null
var stunned: bool = false

func _ready():
	# Убираем коллизию с препятствиями — слой 1 только для пола
	collision_mask = 1  # Только пол (Layer 1)

func _physics_process(delta):
	if not player:
		return
	
	if stunned:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var dir = 1 if player.global_position.x > global_position.x else -1
	velocity.x = dir * speed
	
	move_and_slide()

func stun():
	stunned = true
	await get_tree().create_timer(0.5).timeout
	stunned = false
