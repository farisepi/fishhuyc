extends ParallaxBackground

var speed: float = 0.0

func _process(delta: float) -> void:
	scroll_offset.x -= speed * delta
