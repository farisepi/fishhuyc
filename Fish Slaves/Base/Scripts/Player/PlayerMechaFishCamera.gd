extends Camera2D

var mouse_influence: float = 0.05
var smooth_speed: float = 0.1

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	zoom = Vector2(2, 2)
	
func _update_zoom():
	await get_tree().process_frame
	zoom = Vector2(2.2, 2.2)
