extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var is_crouching: bool = false

func _ready():
	sprite.play("idle")
	if camera:
		camera.zoom = Vector2(1.5, 1.5)  # Приближение
		camera.limit_left = 0
		camera.limit_right = 1920
		camera.limit_top = 0
		camera.limit_bottom = 360

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction > 0:
		sprite.scale.x = 1
	elif direction < 0:
		sprite.scale.x = -1
	
	if is_crouching:
		velocity.x = 0
		sprite.scale.y = 0.5
	else:
		velocity.x = direction * speed
		sprite.scale.y = 1.0
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity
	
	is_crouching = Input.is_action_pressed("crouch")
	
	move_and_slide()
