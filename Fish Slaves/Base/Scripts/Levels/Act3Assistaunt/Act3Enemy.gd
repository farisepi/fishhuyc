extends CharacterBody2D

var speed: float = 200.0
var gravity: float = 980.0

var player: CharacterBody2D = null
var stunned: bool = false

func _ready():
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1

func _physics_process(delta):
	if not player or stunned:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var dir = sign(player.global_position.x - global_position.x)
	velocity.x = dir * speed
	
	move_and_slide()

func stun():
	stunned = true
	await get_tree().create_timer(0.5).timeout
	stunned = false
