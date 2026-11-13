extends Area2D


signal player_died

@export var death_delay: float = 0.5
@export var edge_forgiveness: float = 8.0

var is_triggered: bool = false
var _candidate: Node2D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		_candidate = body

func _on_body_exited(body: Node2D):
	if body == _candidate:
		_candidate = null

func _get_rect() -> Rect2:
	var col = get_node_or_null("CollisionShape2D")
	if col and col.shape is RectangleShape2D:
		var hs = col.shape.size / 2.0
		return Rect2(col.global_position - hs, col.shape.size)
	return Rect2(global_position, Vector2(198, 72))

func _physics_process(_delta):
	if is_triggered or _candidate == null:
		return
	if not is_instance_valid(_candidate):
		_candidate = null
		return
	if _candidate.get("is_dead") == true or _candidate.get("is_falling_into_pit") == true:
		return
	if _candidate.get("is_vaulting") == true or _candidate.get("is_climbing_animation") == true:
		return
	var r = _get_rect()
	var x = _candidate.global_position.x
	if x < r.position.x + edge_forgiveness or x > r.end.x - edge_forgiveness:
		return
	if _candidate is CharacterBody2D and not _candidate.is_on_floor():
		return
	_trigger(_candidate)

func _trigger(body: Node2D):
	is_triggered = true
	player_died.emit()
	if body.has_method("fall_into_pit"):
		body.fall_into_pit(self)
	elif body.has_method("die"):
		body.die()

func reset():
	is_triggered = false
	_candidate = null
