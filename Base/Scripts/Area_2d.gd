extends Area2D

@export var target_offset: Vector2 = Vector2(0, -200)
@export var transition_speed: float = 3.0

var camera_target: Camera2D
var original_camera_pos: Vector2
var target_camera_pos: Vector2
var transitioning: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not transitioning or not camera_target:
		return
	
	camera_target.global_position = camera_target.global_position.lerp(
		target_camera_pos, 
		transition_speed * delta
	)
	
	if camera_target.global_position.distance_to(target_camera_pos) < 1.0:
		camera_target.global_position = target_camera_pos
		transitioning = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	
	camera_target = body.get_node_or_null("PlayerCamera") as Camera2D
	if not camera_target:
		return
	
	original_camera_pos = camera_target.global_position
	target_camera_pos = original_camera_pos + target_offset
	transitioning = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player") or not camera_target:
		return
	
	target_camera_pos = original_camera_pos
	transitioning = true
