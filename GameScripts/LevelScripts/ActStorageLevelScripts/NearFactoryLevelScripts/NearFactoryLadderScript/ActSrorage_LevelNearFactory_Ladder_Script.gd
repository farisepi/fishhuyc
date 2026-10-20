extends Area2D

@export var climb_speed: float = 120.0

var player_inside: bool = false
var _shape: CollisionShape2D = null

func _ready():
	_shape = get_node_or_null("CollisionShape2D")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		if body.has_method("set_nearby_ladder"):
			body.set_nearby_ladder(self)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		if body.has_method("set_nearby_ladder"):
			body.set_nearby_ladder(null)

func get_top_y() -> float:
	if _shape and _shape.shape is RectangleShape2D:
		var half = _shape.shape.size.y / 2.0
		return global_position.y + _shape.position.y - half
	return global_position.y

func get_bottom_y() -> float:
	if _shape and _shape.shape is RectangleShape2D:
		var half = _shape.shape.size.y / 2.0
		return global_position.y + _shape.position.y + half
	return global_position.y
