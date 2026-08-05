# mecha_camera.gd
extends Camera2D

@export var mouse_influence: float = 0.15

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	zoom = Vector2(2.3, 2.3)
	limit_left = -100000
	limit_right = 100000
	limit_top = -6000
	limit_bottom = 2000

func _process(_delta):
	var target = get_parent()
	if target:
		var view_size = get_viewport().get_visible_rect().size
		var mouse_pos = get_viewport().get_mouse_position()
		var center = view_size / 2
		var offset = (mouse_pos - center) * mouse_influence
		global_position = target.global_position + offset
