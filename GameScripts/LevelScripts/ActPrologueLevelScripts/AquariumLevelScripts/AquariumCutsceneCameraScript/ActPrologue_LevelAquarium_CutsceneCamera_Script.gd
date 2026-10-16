extends Camera2D

var decay_speed: float = 0.3
var max_offset: Vector2 = Vector2(25, 15)
var trauma: float = 0.0
var external_offset: Vector2 = Vector2.ZERO

var target_offset: Vector2 = Vector2.ZERO
var smooth_offset: Vector2 = Vector2.ZERO
var look_amount: float = 30.0
var look_speed: float = 4.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

func set_external_offset(off: Vector2) -> void:
	external_offset = off

func _process(delta: float) -> void:
	var trauma_offset = Vector2.ZERO
	if trauma > 0:
		var shake = trauma * trauma
		trauma_offset = Vector2(
			randf_range(-shake * max_offset.x, shake * max_offset.x),
			randf_range(-shake * max_offset.y, shake * max_offset.y)
		)
		trauma = max(trauma - decay_speed * delta, 0.0)
	
	var parent = get_parent()
	if parent:
		var input_dir = Vector2.ZERO
		input_dir.x = Input.get_axis("ui_left", "ui_right")
		input_dir.y = Input.get_axis("ui_up", "ui_down")
		target_offset = input_dir * look_amount
		smooth_offset = smooth_offset.lerp(target_offset, look_speed * delta)
	
	offset = trauma_offset + external_offset + smooth_offset
