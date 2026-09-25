extends CanvasLayer

signal qte_result(success: bool)

@onready var backdrop: ColorRect = $QTE/Backdrop
@onready var outer_circle: ColorRect = $QTE/OuterCircle
@onready var target_circle: ColorRect = $QTE/TargetCircle
@onready var shift_label: Label = $QTE/ShiftLabel

const OUTER_START_SIZE: float = 220.0
const OUTER_END_SIZE: float = 30.0
const TARGET_SIZE: float = 70.0
const HIT_WINDOW_MIN: float = 50.0
const HIT_WINDOW_MAX: float = 110.0
const QTE_DURATION: float = 0.3
const SLOWMO_SCALE: float = 0.25

var is_active: bool = false
var can_press: bool = false
var qte_timer: float = 0.0
var result_sent: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_process(false)
	set_process_input(false)

func show_qte():
	visible = true
	is_active = true
	can_press = false
	result_sent = false
	qte_timer = 0.0

	var screen_center = get_viewport().get_visible_rect().size / 2.0 + Vector2(0, 150)

	backdrop.color = Color(0, 0, 0, 0)

	outer_circle.size = Vector2(OUTER_START_SIZE, OUTER_START_SIZE)
	outer_circle.position = screen_center - Vector2(OUTER_START_SIZE / 2.0, OUTER_START_SIZE / 2.0)
	outer_circle.pivot_offset = Vector2(OUTER_START_SIZE / 2.0, OUTER_START_SIZE / 2.0)
	outer_circle.modulate = Color(1, 1, 1, 0)

	target_circle.size = Vector2(TARGET_SIZE, TARGET_SIZE)
	target_circle.position = screen_center - Vector2(TARGET_SIZE / 2.0, TARGET_SIZE / 2.0)
	target_circle.modulate = Color(1, 1, 1, 0)

	shift_label.size = Vector2(70, 30)
	shift_label.position = screen_center - Vector2(35, 15)
	shift_label.modulate = Color(1, 1, 1, 0)

	Engine.time_scale = SLOWMO_SCALE

	var fade = create_tween().set_parallel(true)
	fade.tween_property(backdrop, "color:a", 0.55, 0.25)
	fade.tween_property(outer_circle, "modulate:a", 1.0, 0.25)
	fade.tween_property(target_circle, "modulate:a", 1.0, 0.25)
	fade.tween_property(shift_label, "modulate:a", 1.0, 0.25)
	await fade.finished

	can_press = true
	set_process(true)
	set_process_input(true)

func _process(delta):
	if not is_active or result_sent:
		return

	qte_timer += delta
	var t = clamp(qte_timer / QTE_DURATION, 0.0, 1.0)
	var screen_center = get_viewport().get_visible_rect().size / 2.0 + Vector2(0, 150)
	var new_size = lerp(OUTER_START_SIZE, OUTER_END_SIZE, t)
	outer_circle.size = Vector2(new_size, new_size)
	outer_circle.position = screen_center - Vector2(new_size / 2.0, new_size / 2.0)
	outer_circle.pivot_offset = Vector2(new_size / 2.0, new_size / 2.0)

	if qte_timer >= QTE_DURATION and not result_sent:
		_finish(false)

func _input(event):
	if not is_active or not can_press or result_sent:
		return

	if event.is_action_pressed("Run"):
		get_viewport().set_input_as_handled()
		var current_size = outer_circle.size.x
		if current_size >= HIT_WINDOW_MIN and current_size <= HIT_WINDOW_MAX:
			_finish(true)
		else:
			_finish(false)

func _finish(success: bool):
	if result_sent:
		return
	result_sent = true
	can_press = false
	set_process(false)
	set_process_input(false)

	if success:
		target_circle.color = Color(0.2, 1.0, 0.3, 0.55)
	else:
		target_circle.color = Color(1.0, 0.2, 0.2, 0.55)

	Engine.time_scale = 1.0

	var fade = create_tween().set_parallel(true)
	fade.tween_property(backdrop, "color:a", 0.0, 0.35)
	fade.tween_property(outer_circle, "modulate:a", 0.0, 0.35)
	fade.tween_property(target_circle, "modulate:a", 0.0, 0.35)
	fade.tween_property(shift_label, "modulate:a", 0.0, 0.35)
	await fade.finished

	visible = false
	is_active = false
	qte_result.emit(success)

func hide_qte():
	visible = false
	is_active = false
	can_press = false
	result_sent = false
	Engine.time_scale = 1.0
	set_process(false)
	set_process_input(false)
