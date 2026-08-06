# mecha_camera.gd
extends Camera2D

@export var mouse_influence: float = 0.05

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	zoom = Vector2(2.2, 2.2)
	limit_left = -1205
	limit_right = 3525
	limit_bottom = 500

func _process(_delta):
	var target = get_parent()
	if target:
		global_position.x = target.global_position.x + (get_viewport().get_mouse_position().x - get_viewport().get_visible_rect().size.x / 2) * mouse_influence
		global_position.y = target.global_position.y
