extends Camera2D

var target_position: Vector2
var follow_speed: float = 1.2          # ← ОЧЕНЬ МЕДЛЕННО
var look_ahead_distance: float = 20.0
var look_ahead_speed: float = 4.0
var look_offset: Vector2 = Vector2.ZERO

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	zoom = Vector2(2.4, 2.4)
	target_position = global_position

func _process(delta):
	var parent = get_parent()
	if not parent:
		return
	
	target_position = parent.global_position
	
	var direction = _get_input_direction()
	if direction.length() > 0:
		var target_look = direction * look_ahead_distance
		look_offset = look_offset.lerp(target_look, look_ahead_speed * delta)
	else:
		look_offset = look_offset.lerp(Vector2.ZERO, look_ahead_speed * delta)
	
	# ==========================================
	# МЕДЛЕННОЕ СЛЕДОВАНИЕ С ЗАДЕРЖКОЙ
	# ==========================================
	var target = target_position + look_offset
	global_position = global_position.lerp(target, follow_speed * delta)

func _get_input_direction() -> Vector2:
	var dir = Vector2.ZERO
	dir.x = Input.get_axis("ui_left", "ui_right")
	dir.y = Input.get_axis("ui_up", "ui_down")
	return dir.normalized()
