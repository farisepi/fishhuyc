extends Camera2D

var smooth_speed: float = 0.1
var max_offset: float = 50.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Обновляем позицию через пару кадров после старта
	call_deferred("_update_position")

func _update_position():
	var viewport_size = get_viewport().get_visible_rect().size
	global_position = viewport_size / 2

func _process(_delta):
	var window_size = get_viewport().get_visible_rect().size
	var center = window_size / 2
	
	var sens = Global.camera_sensitivity * 0.003
	if sens <= 0.0:
		global_position = center
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var offset_amount = (mouse_pos - center) * sens
	offset_amount.x = clamp(offset_amount.x, -max_offset, max_offset)
	offset_amount.y = clamp(offset_amount.y, -max_offset, max_offset)
	
	var target = center + offset_amount
	global_position = global_position.lerp(target, smooth_speed)
