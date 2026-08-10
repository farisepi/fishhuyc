extends Camera2D
@export var decay_speed: float = 0.3
@export var max_offset: Vector2 = Vector2(25, 15)
var trauma: float = 0.0
var external_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

func set_external_offset(off: Vector2) -> void:
	external_offset = off

func _process(_delta: float) -> void:
	var trauma_offset = Vector2.ZERO
	if trauma > 0:
		var shake = trauma * trauma
		trauma_offset = Vector2(
			randf_range(-shake * max_offset.x, shake * max_offset.x),
			randf_range(-shake * max_offset.y, shake * max_offset.y)
		)
	offset = trauma_offset + external_offset
