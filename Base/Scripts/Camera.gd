extends Camera2D

var smooth_speed: float = 0.1
var max_offset_x: float = 50.0
var max_offset_y: float = 80.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Центр экрана, а не Vector2.ZERO
	var viewport_size = get_viewport().get_visible_rect().size
	position = viewport_size / 2

func _process(_delta):
	var sens = Global.camera_sensitivity * 0.01
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2
	
	if sens <= 0.0:
		position = center
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	var offset_amount = (mouse_pos - center) * sens
	offset_amount.x = clamp(offset_amount.x, -max_offset_x, max_offset_x)
	offset_amount.y = clamp(offset_amount.y, -max_offset_y, max_offset_y)
	
	var target = center + offset_amount
	position = position.lerp(target, smooth_speed)
	
