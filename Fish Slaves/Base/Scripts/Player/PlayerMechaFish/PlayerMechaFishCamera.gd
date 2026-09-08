extends Camera2D

@export var follow_speed: float = 1.5
@export var look_ahead: float = 20.0
@export var look_speed: float = 2.0
@export var max_look_offset: float = 50.0

var look_offset: Vector2 = Vector2.ZERO

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	zoom = Vector2(2.4, 2.4)

func _process(delta):
	var parent = get_parent()
	if not parent:
		return
	
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var target_look = dir * look_ahead
	
	if dir.length() > 0:
		look_offset = look_offset.lerp(target_look, look_speed * delta)
	else:
		look_offset = look_offset.lerp(Vector2.ZERO, look_speed * delta)
	
	look_offset.x = clamp(look_offset.x, -max_look_offset, max_look_offset)
	look_offset.y = clamp(look_offset.y, -max_look_offset, max_look_offset)
	
	var target = parent.global_position + look_offset
	global_position = global_position.lerp(target, follow_speed * delta)
