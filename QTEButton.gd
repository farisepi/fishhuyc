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
const ABOVE_PLAYER_OFFSET: Vector2 = Vector2(0, -120)

var is_active: bool = false
var can_press: bool = false
var press_count: int = 0
var qte_timer: float = 0.0
var result_sent: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	hide()
	set_process(false)
	set_process_input(false)

func show_qte_at(world_pos: Vector2):
	print("[QTEButton] show_qte_at вызван, pos=", world_pos)
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

	var center = screen_pos

	var bg_size = RING_SIZE * 0.65
	button_bg.size = Vector2(bg_size, bg_size)
	button_bg.position = center - Vector2(bg_size / 2.0, bg_size / 2.0)
	button_bg.modulate = Color(1, 1, 1, 0)

	progress_ring.size = Vector2(RING_SIZE, RING_SIZE)
	progress_ring.position = center - Vector2(RING_SIZE / 2.0, RING_SIZE / 2.0)
	progress_ring.modulate = Color(1, 1, 1, 0)

	var label_size = RING_SIZE * 0.5
	e_label.size = Vector2(label_size, label_size)
	e_label.position = center - Vector2(label_size / 2.0, label_size / 2.0)
	e_label.modulate = Color(1, 1, 1, 0)

	Engine.time_scale = SLOWMO_SCALE

	var fade = create_tween().set_parallel(true)
	fade.tween_property(backdrop, "color:a", 0.4, 0.2)
	fade.tween_property(button_bg, "modulate:a", 1.0, 0.2)
	fade.tween_property(progress_ring, "modulate:a", 1.0, 0.2)
	fade.tween_property(e_label, "modulate:a", 1.0, 0.2)
	await fade.finished

	can_press = true
	set_process(true)
	set_process_input(true)

func _process(delta):
	if not is_active or result_sent:
		return

	qte_timer += delta

	if qte_timer >= TIME_LIMIT and not result_sent:
		_finish(false)

func _input(event):
	print("[QTEButton] _input, active=", is_active, " can_press=", can_press, " result_sent=", result_sent, " event=", event)
	if not is_active or not can_press or result_sent:
		return

	if event.is_action_pressed("interact"):
		print("[QTEButton] E нажата, count=", press_count + 1)
	if not is_active or not can_press or result_sent:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		press_count += 1
		progress_ring.value = press_count

		var pulse = create_tween()
		pulse.tween_property(button_bg, "modulate", Color(1.4, 1.4, 1.4, 1), 0.05)
		pulse.tween_property(button_bg, "modulate", Color(1, 1, 1, 1), 0.1)

		if press_count >= REQUIRED_PRESSES:
			_finish(true)

func _finish(success: bool):
	print("[QTEButton] _finish success=", success)
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

	var fade = create_tween().set_parallel(true)
	fade.tween_property(backdrop, "color:a", 0.0, 0.35)
	fade.tween_property(button_bg, "modulate:a", 0.0, 0.35)
	fade.tween_property(progress_ring, "modulate:a", 0.0, 0.35)
	fade.tween_property(e_label, "modulate:a", 0.0, 0.35)
	await fade.finished

	visible = false
	hide()
	is_active = false
	qte_result.emit(success)

func hide_qte():
	visible = false
	hide()
	is_active = false
	can_press = false
	result_sent = false
	Engine.time_scale = 1.0
	set_process(false)
	set_process_input(false)
