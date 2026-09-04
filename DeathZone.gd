extends Area2D

@export var kill_player: bool = true

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and kill_player:
		if body.has_method("die"):
			body.die()
		else:
			print("игрок не имеет метода die()")
