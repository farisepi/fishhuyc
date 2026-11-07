extends CanvasLayer

# QTE "нажми SHIFT вовремя": внешнее кольцо сжимается к целевому кольцу.
# Нажал, когда кольца совпали — успех. Рано/поздно — провал.
# Всё считается в РЕАЛЬНОМ времени, поэтому работает при любом Engine.time_scale.

signal qte_result(success: bool)
signal qte_hit

@onready var backdrop: ColorRect = $QTE/Backdrop
@onready var outer_circle: ColorRect = $QTE/OuterCircle
@onready var target_circle: ColorRect = $QTE/TargetCircle
@onready var shift_label: Label = $QTE/ShiftLabel

const OUTER_START_R: float = 120.0
const OUTER_END_R: float = 14.0
const TARGET_R: float = 42.0
const HIT_TOLERANCE: float = 16.0       # +- пикселей радиуса вокруг цели
const DEFAULT_DURATION: float = 1.3     # реальные секунды
const SLOWMO_SCALE: float = 0.25

var is_active: bool = false
var can_press: bool = false
var qte_timer: float = 0.0
var result_sent: bool = false

var _duration: float = DEFAULT_DURATION
var _manage_time_scale: bool = true
var _center: Vector2 = Vector2.ZERO
var _outer_r: float = OUTER_START_R
var _alpha: float = 1.0
var _result_color: Color = Color(0, 0, 0, 0)
var _flash: float = 0.0
var _last_ticks: int = 0
var _pulse_t: float = 0.0
var _canvas: Control = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_process(false)
	set_process_input(false)

	outer_circle.visible = false
	target_circle.visible = false

	_canvas = Control.new()
	_canvas.name = "CircleCanvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_on_canvas_draw)
	$QTE.add_child(_canvas)
	$QTE.move_child(_canvas, shift_label.get_index())

	shift_label.add_theme_font_size_override("font_size", 22)
	shift_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	shift_label.add_theme_constant_override("outline_size", 6)

# duration — сколько реальных секунд сжимается кольцо.
# manage_time_scale = false, если slow-mo уже контролирует катсцена.
func show_qte(duration: float = DEFAULT_DURATION, manage_time_scale: bool = true, screen_pos: Vector2 = Vector2(-1, -1)):
	visible = true
	show()
	is_active = true
	can_press = true
	result_sent = false
	qte_timer = 0.0
	_duration = max(duration, 0.3)
	_manage_time_scale = manage_time_scale
	_alpha = 1.0
	_flash = 0.0
	_result_color = Color(0, 0, 0, 0)
	_outer_r = OUTER_START_R
	_last_ticks = Time.get_ticks_msec()

	if screen_pos.x < 0:
		_center = get_viewport().get_visible_rect().size / 2.0 + Vector2(0, 110)
	else:
		_center = screen_pos

	backdrop.color = Color(0, 0, 0, 0.0)
	var bt = create_tween()
	bt.set_ignore_time_scale(true)
	bt.tween_property(backdrop, "color:a", 0.35, 0.2)

	shift_label.size = Vector2(120, 44)
	shift_label.position = _center - shift_label.size / 2.0
	shift_label.modulate = Color(1, 1, 1, 1)

	if _manage_time_scale:
		Engine.time_scale = SLOWMO_SCALE

	set_process(true)
	set_process_input(true)

func _real_delta() -> float:
	var now = Time.get_ticks_msec()
	var d = (now - _last_ticks) / 1000.0
	_last_ticks = now
	return clamp(d, 0.0, 0.1)

func _process(_delta):
	var rd = _real_delta()
	_pulse_t += rd
	_flash = move_toward(_flash, 0.0, rd * 3.0)

	if is_active and not result_sent:
		qte_timer += rd
		var t = clamp(qte_timer / _duration, 0.0, 1.0)
		# ease-in: сначала медленно, к концу быстрее — легче прочитать момент
		_outer_r = lerp(OUTER_START_R, OUTER_END_R, t * t * 0.35 + t * 0.65)
		if _outer_r < TARGET_R - HIT_TOLERANCE:
			_finish(false)

	_canvas.queue_redraw()

func _in_window() -> bool:
	return abs(_outer_r - TARGET_R) <= HIT_TOLERANCE

func _input(event):
	if not is_active or not can_press or result_sent:
		return
	if event.is_action_pressed("Run") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_finish(_in_window())

func _on_canvas_draw():
	if not visible:
		return
	var a = _alpha
	var c = _center
	var in_win = _in_window() and not result_sent

	# центр
	_canvas.draw_circle(c, TARGET_R - 6.0, Color(0.06, 0.06, 0.08, 0.85 * a))

	# целевое кольцо (подсвечивается, когда пора жать)
	var tcol = Color(1, 1, 1, 0.75 * a)
	if in_win:
		tcol = Color(0.4, 1.0, 0.5, a)
	if _result_color.a > 0.0:
		tcol = _result_color
		tcol.a *= a
	_canvas.draw_arc(c, TARGET_R, 0, TAU, 72, tcol, 4.0, true)

	# окно попадания — едва заметная полоса
	_canvas.draw_arc(c, TARGET_R, 0, TAU, 72, Color(1, 1, 1, 0.08 * a), HIT_TOLERANCE * 2.0, true)

	# сжимающееся кольцо
	if not result_sent:
		var k = clamp((OUTER_START_R - _outer_r) / (OUTER_START_R - TARGET_R), 0.0, 1.0)
		var ocol = Color(1.0, lerp(0.9, 0.55, k), lerp(0.6, 0.2, k), lerp(0.35, 1.0, k) * a)
		_canvas.draw_arc(c, _outer_r, 0, TAU, 72, ocol, 3.0, true)

	# вспышка результата
	if _flash > 0.0 and _result_color.a > 0.0:
		var fc = _result_color
		fc.a = _flash * 0.5 * a
		_canvas.draw_circle(c, TARGET_R + (1.0 - _flash) * 40.0, fc)

func _finish(success: bool):
	if result_sent:
		return
	result_sent = true
	can_press = false
	set_process_input(false)

	_result_color = Color(0.3, 1.0, 0.45, 1.0) if success else Color(1.0, 0.25, 0.25, 1.0)
	_flash = 1.0

	if _manage_time_scale:
		Engine.time_scale = 1.0

	is_active = false
	if success:
		qte_hit.emit()
	# результат отдаём СРАЗУ, чтобы катсцена реагировала в тот же кадр
	qte_result.emit(success)

	var fade = create_tween().set_parallel(true)
	fade.set_ignore_time_scale(true)
	fade.tween_property(backdrop, "color:a", 0.0, 0.3)
	fade.tween_property(self, "_alpha", 0.0, 0.3).set_delay(0.15)
	fade.tween_property(shift_label, "modulate:a", 0.0, 0.3).set_delay(0.15)
	await fade.finished

	set_process(false)
	visible = false

func hide_qte():
	visible = false
	is_active = false
	can_press = false
	result_sent = false
	if _manage_time_scale:
		Engine.time_scale = 1.0
	set_process(false)
	set_process_input(false)
