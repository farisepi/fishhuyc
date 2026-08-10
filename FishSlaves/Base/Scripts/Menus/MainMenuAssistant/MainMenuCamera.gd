extends Camera2D

var smooth_speed: float = 0.1
var max_offset: float = 50.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var window_size = DisplayServer.window_get_size()
	position = Vector2(window_size.x / 2, window_size.y / 2)

func _process(_delta):
	var sens = Global.camera_sensitivity * 0.003
	var window_size = DisplayServer.window_get_size()
	var center = Vector2(window_size.x / 2, window_size.y / 2)
	
	if sens <= 0.0:
		position = center
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var offset_amount = (mouse_pos - center) * sens
	offset_amount.x = clamp(offset_amount.x, -max_offset, max_offset)
	offset_amount.y = clamp(offset_amount.y, -max_offset, max_offset)
	
	var target = center + offset_amount
	position = position.lerp(target, smooth_speed)
