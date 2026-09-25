extends CanvasLayer

signal tutorial_closed

@onready var background: ColorRect = $Background
@onready var container: Control = $Container
@onready var shift_image: TextureRect = $Container/ShiftImage
@onready var shift_label: Label = $Container/ShiftLabel
@onready var hint_label: Label = $Container/HintLabel

var is_active: bool = false
var can_dismiss: bool = false
var appear_timer: float = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	hide()
	background.color = Color(0, 0, 0, 0)
	container.modulate = Color(1, 1, 1, 0)
	set_process(false)
	set_process_input(false)

func show_tutorial():
	visible = true
	show()
	is_active = true
	can_dismiss = false
	appear_timer = 0.0
	background.color = Color(0, 0, 0, 0)
	container.modulate = Color(1, 1, 1, 0)
	Engine.time_scale = 0.0
	set_process(true)
	set_process_input(true)

func hide_tutorial():
	visible = false
	hide()
	is_active = false
	can_dismiss = false
	Engine.time_scale = 1.0
	set_process(false)
	set_process_input(false)

func _process(delta):
	if not is_active:
		return

	appear_timer += delta

	var bg_alpha = clamp(appear_timer / 0.8, 0.0, 0.55)
	background.color = Color(0, 0, 0, bg_alpha)

	var cont_alpha = clamp((appear_timer - 0.3) / 0.8, 0.0, 1.0)
	container.modulate = Color(1, 1, 1, cont_alpha)

	if appear_timer >= 1.2:
		can_dismiss = true
		set_process(false)

func _input(event: InputEvent) -> void:
	if not is_active or not can_dismiss:
		return

	var pressed_confirm = false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			pressed_confirm = true
	if event.is_action_pressed("Run"):
		pressed_confirm = true

	if pressed_confirm:
		get_viewport().set_input_as_handled()
		_close_tutorial()

func _close_tutorial():
	if not can_dismiss:
		return
	can_dismiss = false
	set_process_input(false)

	Engine.time_scale = 1.0

	var t = create_tween().set_parallel(true)
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(background, "color:a", 0.0, 0.5)
	t.tween_property(container, "modulate:a", 0.0, 0.5)
	await t.finished

	hide_tutorial()
	tutorial_closed.emit()
