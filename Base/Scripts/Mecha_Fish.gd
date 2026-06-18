extends CharacterBody2D

@export var run_speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = -run_speed
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	move_and_slide()
