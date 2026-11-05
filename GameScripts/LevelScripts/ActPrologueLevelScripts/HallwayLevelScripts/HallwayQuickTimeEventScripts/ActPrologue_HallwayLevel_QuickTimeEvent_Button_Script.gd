extends CanvasLayer

# QTE "быстро жми E". Кнопка рисуется кодом: круг + кольцо прогресса + кольцо таймера.
# Старые ButtonBG / ProgressRing из сцены скрываются (они были квадратные).

signal qte_result(success: bool)

@onready var backdrop: ColorRect = $Root/Backdrop
@onready var button_bg: ColorRect = $Root/ButtonBG
@onready var progress_ring: TextureProgressBar = $Root/ProgressRing
@onready var e_label: Label = $Root/ELabel

const REQUIRED_PRESSES: int = 8
const TIME_LIMIT: float = 5.0          # в РЕАЛЬНЫХ секундах (не зависит от slow-mo)
const SLOWMO_SCALE: float = 0.4
const RADIUS: float = 34.0
const SHAKE_OFFSET: float = 5.0

const COL_FILL := Color(0.07, 0.07, 0.09, 0.88)
const COL_TRACK := Color(1, 1, 1, 0.18)
const COL_PROGRESS := Color(1.0, 0.78, 0.25, 1.0)
const COL_TIMER := Color(1, 1, 1, 0.55)
const COL_TIMER_LOW := Color(1.0, 0.3, 0.25, 0.9)
const COL_OK := Color(0.3, 1.0, 0.45, 1.0)
const COL_FAIL := Color(1.0, 0.25, 0.25, 1.0)

var is_active: bool = false
var can_press: bool = false
var press_count: int = 0
var qte_timer: float = 0.0
var result_sent: bool = false

var pressed_callback: Callable = Callable()

var _world_pos: Vector2 = Vector2.ZERO
var _center: Vector2 = Vector2.ZERO
var _shake: Vector2 = Vector2.ZERO
var _punch: float = 0.0
var _pulse_t: float = 0.0
var _appear: float = 0.0
var _result_color: Color = Color(0, 0, 0, 0)
var _alpha: float = 1.0
var _shown_progress: float = 0.0
var _last_ticks: int = 0

var _canvas: Control = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	hide()
	set_process(false)
	set_process_input(false)

	if button_bg:
		button_bg.visible = false
	if progress_ring:
		progress_ring.visible = false

	_canvas = Control.new()
	_canvas.name = "CircleCanvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_on_canvas_draw)
	$Root.add_child(_canvas)
	$Root.move_child(_canvas, e_label.get_index())

	e_label.add_theme_font_size_override("font_size", 30)
	e_label.add_theme_color_override("font_color", Color.WHITE)
	e_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	e_label.add_theme_constant_override("outline_size", 6)
	e_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	e_label.pivot_offset = Vector2(30, 30)

func set_pressed_callback(cb: Callable):
	pressed_callback = cb

func show_qte_at(world_pos: Vector2):
	visible = true
	show()
	is_active = true
	can_press = false
	press_count = 0
	qte_timer = 0.0
	result_sent = false
	_world_pos = world_pos
	_shake = Vector2.ZERO
	_punch = 0.0
	_appear = 0.0
	_alpha = 1.0
	_shown_progress = 0.0
	_result_color = Color(0, 0, 0, 0)
	_last_ticks = Time.get_ticks_msec()

	backdrop.color = Color(0, 0, 0, 0)
	e_label.modulate = Color(1, 1, 1, 1)
	_update_center()

	Engine.time_scale = SLOWMO_SCALE

	can_press = true
	set_process(true)
	set_process_input(true)

func _update_center():
	# точный перевод мир -> экран (учитывает зум, смещение и позицию камеры)
	_center = get_viewport().get_canvas_transform() * _world_pos
	var c = _center + _shake
	var s = 60.0
	e_label.size = Vector2(s, s)
	e_label.position = c - Vector2(s / 2.0, s / 2.0)
	var k = _appear_scale() * (1.0 + _punch * 0.18)
	e_label.scale = Vector2(k, k)

func _appear_scale() -> float:
	var t = clamp(_appear / 0.18, 0.0, 1.0)
	# небольшой overshoot при появлении
	return lerp(0.4, 1.0, t) + sin(t * PI) * 0.12

func hide_qte():
	visible = false
	hide()
	is_active = false
	can_press = false
	result_sent = false
	Engine.time_scale = 1.0
	set_process(false)
	set_process_input(false)

func _real_delta() -> float:
	var now = Time.get_ticks_msec()
	var d = (now - _last_ticks) / 1000.0
	_last_ticks = now
	return clamp(d, 0.0, 0.1)

func _process(_delta):
	var rd = _real_delta()
	_pulse_t += rd
	_appear += rd
	_punch = move_toward(_punch, 0.0, rd * 6.0)
	_shake = _shake.move_toward(Vector2.ZERO, rd * 80.0)
	_shown_progress = lerp(_shown_progress, float(press_count) / REQUIRED_PRESSES, clamp(rd * 18.0, 0.0, 1.0))

	if is_active and not result_sent:
		qte_timer += rd
		if qte_timer >= TIME_LIMIT:
			_finish(false)

	_update_center()
	_canvas.queue_redraw()

func _input(event):
	if not is_active or not can_press or result_sent:
		return

	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		press_count += 1
		_punch = 1.0
		_shake = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * SHAKE_OFFSET

		if pressed_callback.is_valid():
			pressed_callback.call()

		if press_count >= REQUIRED_PRESSES:
			_finish(true)

func _on_canvas_draw():
	if not visible:
		return
	var c = _center + _shake
	var k = _appear_scale() * (1.0 + _punch * 0.18)
	var r = RADIUS * k
	var a = _alpha

	# пульсирующее свечение-приглашение
	var pulse = 0.5 + 0.5 * sin(_pulse_t * 7.0)
	var glow_r = r + 8.0 + pulse * 6.0
	_canvas.draw_arc(c, glow_r, 0, TAU, 64, Color(1, 0.85, 0.4, (0.12 + 0.18 * pulse) * a), 3.0, true)

	# основной круг
	var fill = COL_FILL
	fill.a *= a
	_canvas.draw_circle(c, r, fill)

	# вспышка результата
	if _result_color.a > 0.0:
		var rc = _result_color
		rc.a *= a * 0.55
		_canvas.draw_circle(c, r, rc)

	# дорожка и прогресс нажатий
	var ring_r = r - 5.0
	var track = COL_TRACK
	track.a *= a
	_canvas.draw_arc(c, ring_r, 0, TAU, 64, track, 5.0, true)
	if _shown_progress > 0.001:
		var pc = COL_PROGRESS if _result_color.a <= 0.0 else _result_color
		pc.a *= a
		_canvas.draw_arc(c, ring_r, -PI / 2.0, -PI / 2.0 + TAU * _shown_progress, 64, pc, 5.0, true)

	# внешнее тонкое кольцо — оставшееся время
	if not result_sent:
		var left = clamp(1.0 - qte_timer / TIME_LIMIT, 0.0, 1.0)
		var tc = COL_TIMER if left > 0.3 else COL_TIMER_LOW
		tc.a *= a
		_canvas.draw_arc(c, r + 4.0, -PI / 2.0, -PI / 2.0 + TAU * left, 64, tc, 2.0, true)

func _finish(success: bool):
	if result_sent:
		return
	result_sent = true
	can_press = false
	set_process_input(false)

	_result_color = COL_OK if success else COL_FAIL
	_punch = 1.0

	Engine.time_scale = 1.0

	is_active = false
	qte_result.emit(success)

	var fade = create_tween().set_parallel(true)
	fade.set_ignore_time_scale(true)
	fade.tween_property(self, "_alpha", 0.0, 0.35).set_delay(0.15)
	fade.tween_property(e_label, "modulate:a", 0.0, 0.35).set_delay(0.15)
	await fade.finished

	set_process(false)
	visible = false
	hide()
