extends CharacterBody2D

@export var speed: float = 100.0
@export var gravity: float = 980.0

var active: bool = false

func _physics_process(delta):
	if not active:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = -speed
	move_and_slide()
