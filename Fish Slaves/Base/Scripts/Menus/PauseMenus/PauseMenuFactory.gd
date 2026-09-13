extends CanvasLayer

@onready var continue_btn: Button = $ContinueButton
@onready var settings_btn: Button = $SettingsButton
@onready var save_btn: Button = $SaveButton
@onready var exit_btn: Button = $ExitButton

var _bg_rect: ColorRect
var _framing: Sprite2D
var _buttons: Array[Button] = []
var _anim_tween: Tween
var _is_closing: bool = false
var _transitioning: bool = false

func _ready() -> void:
	_bg_rect = get_node_or_null("ColorRect")
	_framing = get_node_or_null("Framing")
	
	_buttons.clear()
	for child in get_children():
		if child is Button:
			_buttons.append(child)
	
	for btn in _buttons:
		ButtonEffects.setup(btn)
	
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	if _bg_rect:
		_bg_rect.modulate.a = 0.0
	if _framing:
		_framing.modulate.a = 0.0
	
	for btn in _buttons:
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.85, 0.85)
		btn.pivot_offset = btn.size / 2.0

func show_menu() -> void:
	_is_closing = false
	show()
	_animate_in()

func _animate_in() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	
	if _bg_rect:
		_bg_rect.modulate.a = 0.0
	if _framing:
		_framing.modulate.a = 0.0
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.modulate.a = 0.0
			btn.scale = Vector2(0.85, 0.85)
			btn.pivot_offset = btn.size / 2.0
	
	_anim_tween = create_tween()
	_anim_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_anim_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	if _bg_rect:
		_anim_tween.tween_property(_bg_rect, "modulate:a", 0.5, 0.15)
	if _framing:
		_anim_tween.parallel().tween_property(_framing, "modulate:a", 1.0, 0.2)
	
	for i in range(_buttons.size()):
		var btn = _buttons[i]
		if not is_instance_valid(btn):
			continue
		_anim_tween.parallel().tween_property(btn, "modulate:a", 1.0, 0.15).set_delay(0.02 + i * 0.03)
		_anim_tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.2).set_delay(0.02 + i * 0.03).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_menu() -> void:
	if _is_closing:
		return
	_is_closing = true
	
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	
	_anim_tween = create_tween()
	_anim_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_anim_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	for btn in _buttons:
		if is_instance_valid(btn):
			_anim_tween.parallel().tween_property(btn, "modulate:a", 0.0, 0.1)
			_anim_tween.parallel().tween_property(btn, "scale", Vector2(0.9, 0.9), 0.1)
	
	if _bg_rect:
		_anim_tween.parallel().tween_property(_bg_rect, "modulate:a", 0.0, 0.15)
	if _framing:
		_anim_tween.parallel().tween_property(_framing, "modulate:a", 0.0, 0.15)
	
	await _anim_tween.finished
	hide()
	_is_closing = false

func _transition_to(scene_path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hide()
	
	await get_tree().process_frame
	Global.goto_scene(scene_path)

func _on_continue_pressed() -> void:
	UISounds.play_click()
	GlobalMusic.restore_volume()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	var level = get_tree().current_scene
	if level and level.has_method("_resume_after_pause"):
		level._resume_after_pause()
	
	hide_menu()

func _on_save_pressed() -> void:
	UISounds.play_click()
	Global.came_from = Global.MenuSource.GAME
	Global.scene_to_save = get_tree().current_scene.scene_file_path
	Global.player_position = Vector2.ZERO
	_transition_to("res://Fish Slaves/Base/Scenes/Menus/SaveMenus/SavesMenuFactory.tscn")

func _on_settings_pressed() -> void:
	UISounds.play_click()
	Global.came_from = Global.MenuSource.GAME
	Global.scene_to_save = get_tree().current_scene.scene_file_path
	_transition_to("res://Fish Slaves/Base/Scenes/Menus/SettingMenus/SettingsMenuFactory.tscn")

func _on_exit_pressed() -> void:
	UISounds.play_click()
	_transition_to("res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuFactory.tscn")
