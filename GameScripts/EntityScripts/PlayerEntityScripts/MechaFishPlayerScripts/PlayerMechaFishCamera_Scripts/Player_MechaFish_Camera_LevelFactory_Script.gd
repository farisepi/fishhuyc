extends Camera2D

@export var follow_speed: float = 1.5
@export var look_ahead: float = 20.0
@export var look_speed: float = 2.0
@export var max_look_offset: float = 50.0
@export var camera_zoom: Vector2 = Vector2(2.3, 2.3)
@export var follow_enabled: bool = true
@export var camera_offset: Vector2 = Vector2(0, -42)

var look_offset: Vector2 = Vector2.ZERO
var bounds: Rect2 = Rect2()
var breath_offset: Vector2 = Vector2.ZERO

var trauma: float = 0.0
var trauma_decay: float = 2.0
var trauma_max_offset: float = 24.0
var _shake_offset: Vector2 = Vector2.ZERO

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	top_level = true
	enabled = true
	zoom = camera_zoom
	position_smoothing_enabled = false

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func snap_to(target: Vector2) -> void:
	look_offset = Vector2.ZERO
	global_position = _clamped(target + camera_offset)

func _clamped(p: Vector2) -> Vector2:
	if bounds.size.x <= 0.0 or not is_inside_tree():
		return p
	var half = get_viewport_rect().size / zoom / 2.0
	p.x = clamp(p.x, bounds.position.x + half.x, max(bounds.position.x + half.x, bounds.end.x - half.x))
	p.y = clamp(p.y, bounds.position.y + half.y, max(bounds.position.y + half.y, bounds.end.y - half.y))
	return p

func smooth_to(target: Vector2, duration: float = 0.2) -> void:
	if not is_inside_tree():
		return
	var to = target + look_offset + camera_offset
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "global_position", to, duration)

func _process(delta):
	if trauma > 0.0:
		trauma = max(trauma - trauma_decay * delta, 0.0)
		var shake = trauma * trauma
		_shake_offset = Vector2(
			randf_range(-1.0, 1.0) * shake * trauma_max_offset,
			randf_range(-1.0, 1.0) * shake * trauma_max_offset
		)
	else:
		_shake_offset = Vector2.ZERO

	offset = _shake_offset + breath_offset

	if not follow_enabled:
		return
	var parent = get_parent()
	if not parent:
		return

	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var target_look = dir * look_ahead

	if dir.length() > 0:
		look_offset = look_offset.lerp(target_look, look_speed * delta)
	else:
		look_offset = look_offset.lerp(Vector2.ZERO, look_speed * delta)

	look_offset.x = clamp(look_offset.x, -max_look_offset, max_look_offset)
	look_offset.y = clamp(look_offset.y, -max_look_offset, max_look_offset)

	var target = parent.global_position + look_offset + camera_offset
	global_position = _clamped(global_position.lerp(target, follow_speed * delta))
