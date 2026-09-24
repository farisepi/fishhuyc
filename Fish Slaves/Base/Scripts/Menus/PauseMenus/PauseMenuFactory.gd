extends CanvasLayer

@onready var continue_btn: Button = $ContinueButton
@onready var settings_btn: Button = $SettingsButton
@onready var save_btn: Button = $SaveButton
@onready var exit_btn: Button = $ExitButton
@onready var restart_btn: Button = get_node_or_null("RestartButton")

var _bg_rect: ColorRect
var _framing: Sprite2D
var _buttons: Array[Button] = []
var _anim_tween: Tween
var _is_closing: bool = false
var _transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_bg_rect = get_node_or_null("ColorRect")
	_framing = get_node_or_null("Framing")
	
	_buttons.clear()
	for child in get_children():
		if child is Button:
			_buttons.append(child)
	
	for btn in _buttons:
		ButtonEffects.setup(btn)
	
	# Сигналы уже подключены в .tscn — НЕ дублируем
	
	if _bg_rect:
		_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_bg_rect.offset_left = 0
		_bg_rect.offset_top = 0
		_bg_rect.offset_right = 0
		_bg_rect.offset_bottom = 0
		_bg_rect.modulate.a = 0.0
		_bg_rect.visible = true
		_bg_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if _framing:
		_framing.modulate.a = 0.0
	
	for btn in _buttons:
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.85, 0.85)
		btn.pivot_offset = btn.size / 2.0
	
	hide()

func show_menu() -> void:
	_is_closing = false
	show()
	# Принудительно растягиваем фон при каждом показе
	if _bg_rect:
		_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_bg_rect.offset_left = 0
		_bg_rect.offset_top = 0
		_bg_rect.offset_right = 0
		_bg_rect.offset_bottom = 0
		_bg_rect.modulate.a = 0.0
		_bg_rect.visible = true
	if _framing:
		_framing.modulate.a = 0.0
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.modulate.a = 0.0
			btn.scale = Vector2(0.85, 0.85)
			btn.pivot_offset = btn.size / 2.0
	_animate_in()

func _animate_in() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	
	_anim_tween = create_tween()
	_anim_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_anim_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	if _bg_rect:
		_anim_tween.tween_property(_bg_rect, "modulate:a", 1.0, 0.15)
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
	# Жёсткий сброс
	if _bg_rect:
		_bg_rect.modulate.a = 0.0
	if _framing:
		_framing.modulate.a = 0.0
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.modulate.a = 0.0
	_is_closing = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		var level = get_tree().current_scene
		if level and level.has_method("_toggle_pause"):
			level._toggle_pause()

func _is_factory_level() -> bool:
	var scene_path = get_tree().current_scene.scene_file_path
	return "Act2" in scene_path or "Act3" in scene_path or "Factory" in scene_path

func _transition_to(scene_path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	UISounds.stop_everything_gameplay()
	
	# Жёсткий сброс перед скрытием
	if _bg_rect:
		_bg_rect.modulate.a = 0.0
	if _framing:
		_framing.modulate.a = 0.0
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.modulate.a = 0.0
	hide()
	
	await get_tree().create_timer(0.05).timeout
	Global.goto_scene(scene_path)

func _on_continue_pressed() -> void:
	UISounds.play_click()
	GlobalMusic.restore_volume()
	UISounds.restore_ambience()
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

func _on_restart_pressed() -> void:
	UISounds.play_click()
	_load_last_save()

func _load_last_save() -> void:
	var save_dir = "user://saves/"
	if not DirAccess.dir_exists_absolute(save_dir):
		_restart_current_scene()
		return
	
	var dir = DirAccess.open(save_dir)
	if not dir:
		_restart_current_scene()
		return
	
	var latest_time = 0
	var latest_path = ""
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("save_") and file_name.ends_with(".cfg"):
			var path = save_dir + file_name
			var t = FileAccess.get_modified_time(path)
			if t > latest_time:
				latest_time = t
				latest_path = path
		file_name = dir.get_next()
	dir.list_dir_end()
	
	if latest_path == "":
		_restart_current_scene()
		return
	
	var config = ConfigFile.new()
	if config.load(latest_path) != OK:
		_restart_current_scene()
		return
	
	var scene = config.get_value("save", "scene", "")
	var px = config.get_value("save", "player_x", 0.0)
	var py = config.get_value("save", "player_y", 0.0)
	
	if scene == "":
		_restart_current_scene()
		return
	
	Global.player_position = Vector2(px, py)
	Global.chatter_queue_state = config.get_value("save", "chatter_queue", [])
	Global.chatter_current_text = config.get_value("save", "chatter_text", "")
	Global.chatter_char_index = config.get_value("save", "chatter_index", 0)
	
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Global.goto_scene(scene)

func _restart_current_scene() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var current = get_tree().current_scene.scene_file_path
	Global.goto_scene(current)
