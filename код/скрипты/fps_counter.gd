extends Label

func _ready() -> void:
	add_theme_font_size_override("font_size", 14)
	add_theme_color_override("font_color", Color.WHITE)
	position = Vector2(10, 10)
	visible = false

func _process(_delta: float) -> void:
	if visible:
		text = "FPS: " + str(Engine.get_frames_per_second())
