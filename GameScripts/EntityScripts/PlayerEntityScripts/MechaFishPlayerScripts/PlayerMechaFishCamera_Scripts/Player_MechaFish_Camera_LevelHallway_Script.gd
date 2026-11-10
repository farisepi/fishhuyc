extends Camera2D

@export var follow_speed: float = 5.0
@export var look_ahead: float = 20.0
@export var look_speed: float = 2.0
@export var max_look_offset: float = 50.0
@export var camera_zoom: Vector2 = Vector2(2.3, 2.3)
@export var follow_enabled: bool = true
@export var camera_offset: Vector2 = Vector2(0, 48.112)
## Насколько камера поднимается, когда рыба залезает НАВЕРХ (0 — совсем не поднимается, 1 — как раньше).
@export_range(0.0, 1.0) var climb_follow_ratio: float = 0.3
## Скорость, с которой «уровень пола» камеры подтягивается вверх, если рыба долго стоит наверху (px/с).
## 0 — камера не дрейфует вверх, пока рыба наверху.
@export var ground_rise_speed: float = 0.0
## Насколько рыба может быть выше обычного положения, прежде чем камера всё-таки поднимется
## (чтобы на высокой стопке ящиков рыба не уходила за верх кадра).
@export var max_rise_without_follow: float = 80.0
## Плавность следования по вертикали (меньше — плавнее).
@export var vertical_follow_speed: float = 3.0

var _ground_y: float = NAN

var look_offset: Vector2 = Vector2.ZERO

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	top_level = true
	enabled = true
	zoom = camera_zoom
	position_smoothing_enabled = false
	snap_to_target()

func get_follow_target() -> Vector2:
	var parent = get_parent()
	if not parent:
		return global_position
	var t = parent.global_position + look_offset + camera_offset
	if not is_nan(_ground_y) and parent.global_position.y < _ground_y:
		t.y = _ground_y - _cam_rise(_ground_y - parent.global_position.y) + look_offset.y + camera_offset.y
	return t

func snap_to_target() -> void:
	global_position = get_follow_target()
	var parent = get_parent()
	if parent:
		_ground_y = parent.global_position.y
	reset_smoothing()

func _process(delta):
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

	# по вертикали: вниз (падение, спуск) — следуем сразу, вверх (залезание на ящик) —
	# только частично, а «уровень пола» подтягивается медленно
	var py = parent.global_position.y
	if is_nan(_ground_y) or py > _ground_y:
		_ground_y = py
	else:
		_ground_y = move_toward(_ground_y, py, ground_rise_speed * delta)
	target.y = _ground_y - _cam_rise(_ground_y - py) + look_offset.y + camera_offset.y

	var weight = 1.0 - exp(-follow_speed * delta)
	var weight_y = 1.0 - exp(-vertical_follow_speed * delta)
	global_position.x = lerp(global_position.x, target.x, weight)
	global_position.y = lerp(global_position.y, target.y, weight_y)

## Сколько камера поднимается, если рыба на rise пикселей выше «пола».
func _cam_rise(rise: float) -> float:
	return max(rise * climb_follow_ratio, rise - max_rise_without_follow)
