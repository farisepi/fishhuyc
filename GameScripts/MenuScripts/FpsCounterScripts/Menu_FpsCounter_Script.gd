extends Label

func _ready() -> void:
	add_theme_font_size_override("font_size", 14)
	add_theme_color_override("font_color", Color.WHITE)
	position = Vector2(10, 10)
	z_index = 500
	
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		visible = cfg.get_value("graphics", "show_fps", false)
	else:
		visible = false

func _process(_delta: float) -> void:
	if visible:
		text = "FPS: " + str(Engine.get_frames_per_second())
