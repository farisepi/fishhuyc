extends Camera2D

var smooth_speed: float = 0.1
var max_offset: float = 50.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	var sens = Global.camera_sensitivity * 0.003
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	var center = viewport_size / 2
	
	var offset_amount = (mouse_pos - center) * sens
	offset_amount.x = clamp(offset_amount.x, -max_offset, max_offset)
	offset_amount.y = clamp(offset_amount.y, -max_offset, max_offset)
	
	var target = center + offset_amount
	position = position.lerp(target, smooth_speed)
