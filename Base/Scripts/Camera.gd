# camera.gd
extends Camera2D

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	var target = get_parent()
	if target:
		global_position = target.global_position
