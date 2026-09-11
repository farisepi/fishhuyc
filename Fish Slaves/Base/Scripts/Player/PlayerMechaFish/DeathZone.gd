extends Area2D

signal player_died

@export var death_delay: float = 0.5

var is_triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if is_triggered:
		return
	if body.is_in_group("player"):
		print("игрок вошёл в DeathZone!")
		is_triggered = true
		
		if body.has_method("die"):
			print("вызываю die() у игрока")
			body.die()

func reset():
	is_triggered = false
