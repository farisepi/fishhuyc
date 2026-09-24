extends CanvasLayer

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
	background.color = Color(0, 0, 0, 0)
	container.modulate = Color(1, 1, 1, 0)
	set_process(false)

func show_tutorial():
	visible = true
	is_active = true
	can_dismiss = false
	appear_timer = 0.0
	background.color = Color(0, 0, 0, 0)
	container.modulate = Color(1, 1, 1, 0)
	set_process(true)

func hide_tutorial():
	visible = false
	is_active = false
	can_dismiss = false
	set_process(false)

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

	if pressed_confirm:
		get_viewport().set_input_as_handled()
		await _fade_out_and_close()

func _fade_out_and_close():
	can_dismiss = false
	var t = create_tween().set_parallel(true)
	t.tween_property(background, "color:a", 0.0, 0.5)
	t.tween_property(container, "modulate:a", 0.0, 0.5)
	await t.finished
	hide_tutorial()
