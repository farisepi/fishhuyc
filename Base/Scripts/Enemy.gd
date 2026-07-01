# enemy.gd
extends CharacterBody2D

@export var speed: float = 100.0
@export var gravity: float = 980.0

var color_rect: ColorRect

func _ready():
	color_rect = ColorRect.new()
	color_rect.color = Color(0.8, 0.2, 0.2)
	color_rect.size = Vector2(30, 50)
	color_rect.position = Vector2(-15, -25)
	add_child(color_rect)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var player = get_parent().get_node_or_null("Mecha_Fish")
	if player:
		var dir = 1 if player.global_position.x > global_position.x else -1
		velocity.x = dir * speed
		color_rect.scale.x = dir
	else:
		velocity.x = 0
	
	move_and_slide()
