extends CharacterBody2D

@export var speed: float = 100.0
@export var gravity: float = 980.0

var active: bool = false

func _physics_process(delta):
	if not active:
		return
	
	var player = get_parent().get_parent().get_node_or_null("Mecha_Fish")
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist < 80:
			velocity.x = 0
			return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = -speed
	move_and_slide()
