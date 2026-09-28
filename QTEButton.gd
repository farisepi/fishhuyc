extends CanvasLayer

signal qte_result(success: bool)

@onready var backdrop: ColorRect = $Root/Backdrop
@onready var button_bg: ColorRect = $Root/ButtonBG
@onready var progress_ring: TextureProgressBar = $Root/ProgressRing
@onready var e_label: Label = $Root/ELabel

const REQUIRED_PRESSES: int = 8
const TIME_LIMIT: float = 8.0
const SLOWMO_SCALE: float = 0.4
const RING_SIZE: float = 90.0
const SHAKE_OFFSET: float = 6.0
const SHAKE_STEP_TIME: float = 0.025

var is_active: bool = false
var can_press: bool = false
var press_count: int = 0
var qte_timer: float = 0.0
var result_sent: bool = false

var pressed_callback: Callable = Callable()

var _center: Vector2 = Vector2.ZERO
var _ring_size: float = 0.0
var _bg_size: float = 0.0
var _label_size: float = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	hide()
	set_process(false)
	set_process_input(false)

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

	progress_ring.max_value = REQUIRED_PRESSES
	progress_ring.value = 0

	backdrop.color = Color(0, 0, 0, 0)

	var cam = get_viewport().get_camera_2d()
	var screen_pos = world_pos
	if cam:
		screen_pos = (world_pos - cam.global_position) * cam.zoom + get_viewport().get_visible_rect().size / 2.0

	_center = screen_pos
	_ring_size = RING_SIZE
	_bg_size = RING_SIZE * 0.65
	_label_size = RING_SIZE * 0.5

	_update_positions(Vector2.ZERO)

	button_bg.modulate = Color(1, 1, 1, 1)
	progress_ring.modulate = Color(1, 1, 1, 1)
	e_label.modulate = Color(1, 1, 1, 1)

	Engine.time_scale = SLOWMO_SCALE

	can_press = true
	set_process(true)
	set_process_input(true)

func _update_positions(offset: Vector2):
	var center = _center + offset
	button_bg.size = Vector2(_bg_size, _bg_size)
	button_bg.position = center - Vector2(_bg_size / 2.0, _bg_size / 2.0)
	progress_ring.size = Vector2(_ring_size, _ring_size)
	progress_ring.position = center - Vector2(_ring_size / 2.0, _ring_size / 2.0)
	e_label.size = Vector2(_label_size, _label_size)
	e_label.position = center - Vector2(_label_size / 2.0, _label_size / 2.0)

func hide_qte():
	visible = false
	hide()
	is_active = false
	can_press = false
	result_sent = false
	Engine.time_scale = 1.0
	set_process(false)
	set_process_input(false)

func _process(delta):
	if not is_active or result_sent:
		return

	qte_timer += delta

	if qte_timer >= TIME_LIMIT and not result_sent:
		_finish(false)

func _input(event):
	if not is_active or not can_press or result_sent:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		press_count += 1
		progress_ring.value = press_count

		_shake_button()
		_shake_ring()

		if pressed_callback.is_valid():
			pressed_callback.call()

		if press_count >= REQUIRED_PRESSES:
			_finish(true)

func _shake_button():
	var t = create_tween()
	t.set_trans(Tween.TRANS_LINEAR)
	var dirs = [SHAKE_OFFSET, -SHAKE_OFFSET, SHAKE_OFFSET * 0.6, -SHAKE_OFFSET * 0.6, 0.0]
	for d in dirs:
		t.tween_callback(_update_positions.bind(Vector2(d, 0)))
		t.tween_interval(SHAKE_STEP_TIME)

func _shake_ring():
	var t = create_tween()
	t.set_trans(Tween.TRANS_LINEAR)
	var dirs = [-SHAKE_OFFSET, SHAKE_OFFSET, -SHAKE_OFFSET * 0.6, SHAKE_OFFSET * 0.6, 0.0]
	for d in dirs:
		t.tween_callback(_update_positions.bind(Vector2(d, 0)))
		t.tween_interval(SHAKE_STEP_TIME)

func _finish(success: bool):
	if result_sent:
		return
	result_sent = true
	can_press = false
	set_process(false)
	set_process_input(false)

	if success:
		button_bg.color = Color(0.2, 1.0, 0.3, 0.85)
	else:
		button_bg.color = Color(1.0, 0.2, 0.2, 0.85)

	Engine.time_scale = 1.0

	is_active = false
	qte_result.emit(success)

	var fade = create_tween().set_parallel(true)
	fade.tween_property(backdrop, "color:a", 0.0, 0.35)
	fade.tween_property(button_bg, "modulate:a", 0.0, 0.35)
	fade.tween_property(progress_ring, "modulate:a", 0.0, 0.35)
	fade.tween_property(e_label, "modulate:a", 0.0, 0.35)
	await fade.finished

	visible = false
	hide()
