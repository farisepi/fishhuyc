extends ParallaxBackground

@export var speed: float = 100.0

func _process(delta: float) -> void:
	scroll_offset.x -= speed * delta
