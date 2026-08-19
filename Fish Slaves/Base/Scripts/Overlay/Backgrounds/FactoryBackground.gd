extends ParallaxBackground

var layer7_speed: float = 30.0

@onready var layer7: Node2D = $ParallaxLayer7
@onready var layer7_clone: Node2D = $ParallaxLayer7Clone

func _ready() -> void:
	if layer7 and layer7_clone:
		layer7_clone.position.x = 1152

func _process(delta: float) -> void:
	if layer7 and layer7_clone:
		# Абсолютное движение, НАХУЙ КАМЕРУ
		var move = layer7_speed * delta
		layer7.position.x -= move
		layer7_clone.position.x -= move
		
		if layer7.position.x <= -1152:
			layer7.position.x = layer7_clone.position.x + 1152
		
		if layer7_clone.position.x <= -1152:
			layer7_clone.position.x = layer7.position.x + 1152
