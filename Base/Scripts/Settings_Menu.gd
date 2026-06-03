extends Control

@onready var graphics_tab: Button = $GeneralTab
@onready var audio_tab: Button = $AudioTab
@onready var controls_tab: Button = $ControlsTab

@onready var graphics_page: Control = $GraphicsPage
@onready var audio_page: Control = $AudioPage
@onready var controls_page: Control = $ControlsPage

@onready var fullscreen_btn: Button = $GraphicsPage/FullscreenButton
@onready var resolution_option: OptionButton = $GraphicsPage/ResolutionButton
@onready var language_option: OptionButton = $GraphicsPage/LanguageOption
@onready var fps_check = $GraphicsPage/FPSCheck
@onready var camera_sensitivity_slider: HSlider = $GraphicsPage/CameraSensitivitySlider

@onready var music_slider: HSlider = $AudioPage/MusicSlider
@onready var sfx_slider: HSlider = $AudioPage/SFXSlider
@onready var ambience_slider: HSlider = $AudioPage/AmbienceSlider
@onready var ui_sound_check = $AudioPage/UISoundCheck

@onready var move_up_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer/MoveUpButton
@onready var move_down_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer2/MoveDownButton
@onready var move_left_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer3/MoveLeftButton
@onready var move_right_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer4/MoveRightButton
@onready var jump_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer5/JumpButton
@onready var interact_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer6/InteractButton
@onready var inventory_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer8/InventoryButton
@onready var pause_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer7/PauseButton

@onready var apply_btn: Button = find_child("ApplyButton", true, false)
@onready var default_btn: Button = find_child("DefaultButton", true, false)
@onready var back_btn: Button = find_child("BackButton", true, false)

@onready var fps_label: Label = $FPSCounter

var config: ConfigFile = ConfigFile.new()
const CONFIG_PATH: String = "user://settings.cfg"

func _ready() -> void:
	if Global.came_from == Global.MenuSource.MAIN_MENU:
		Fade.fade_in()
	else:
		Fade.modulate.a = 0.0
	
	config.load(CONFIG_PATH)
	Global.camera_sensitivity = config.get_value("camera", "sensitivity", 0.0)
	InputRebind.keybinds_updated.connect(update_key_labels)
	
	_apply_fps_visibility()
	_setup_ui()
	_connect_signals()
	setup_options()
	load_settings()
	update_key_labels()
	show_page(0)

func _process(_delta: float) -> void:
	if fps_label and fps_label.visible:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

func _apply_fps_visibility() -> void:
	config.load(CONFIG_PATH)
	if fps_label:
		fps_label.visible = config.get_value("graphics", "show_fps", false)
		fps_label.add_theme_font_size_override("font_size", 14)
		fps_label.add_theme_color_override("font_color", Color.WHITE)
		fps_label.position = Vector2(10, 10)
		fps_label.z_index = 200

func _setup_ui() -> void:
	var buttons: Array[Button] = [
		graphics_tab, audio_tab, controls_tab, fullscreen_btn,
		move_up_btn, move_down_btn, move_left_btn, move_right_btn,
		interact_btn, jump_btn, inventory_btn, pause_btn
	]
	
	if apply_btn: buttons.append(apply_btn)
	if default_btn: buttons.append(default_btn)
	if back_btn: buttons.append(back_btn)
	
	for btn in buttons:
		if btn:
			ButtonEffects.setup(btn)

func _connect_signals() -> void:
	if graphics_tab: graphics_tab.pressed.connect(func(): show_page(0))
	if audio_tab: audio_tab.pressed.connect(func(): show_page(1))
	if controls_tab: controls_tab.pressed.connect(func(): show_page(2))
	if back_btn: back_btn.pressed.connect(_on_back_pressed)
	if fullscreen_btn: fullscreen_btn.pressed.connect(_on_fullscreen)
	if apply_btn: apply_btn.pressed.connect(save_settings)
	if default_btn: default_btn.pressed.connect(_show_reset_confirm)
	if language_option: language_option.item_selected.connect(_on_language_selected)
	
	if move_up_btn: move_up_btn.pressed.connect(func(): _start_rebind("ui_up"))
	if move_down_btn: move_down_btn.pressed.connect(func(): _start_rebind("ui_down"))
	if move_left_btn: move_left_btn.pressed.connect(func(): _start_rebind("ui_left"))
	if move_right_btn: move_right_btn.pressed.connect(func(): _start_rebind("ui_right"))
	if interact_btn: interact_btn.pressed.connect(func(): _start_rebind("interact"))
	if jump_btn: jump_btn.pressed.connect(func(): _start_rebind("jump"))
	if inventory_btn: inventory_btn.pressed.connect(func(): _start_rebind("inventory"))
	if pause_btn: pause_btn.pressed.connect(func(): _start_rebind("ui_cancel"))

func setup_options() -> void:
	if resolution_option:
		resolution_option.clear()
		resolution_option.add_item("1920x1080")
		resolution_option.add_item("1280x720")
		resolution_option.add_item("854x480")
	
	if language_option:
		language_option.clear()
		language_option.add_item("Русский")
		language_option.add_item("English")

func load_settings() -> void:
	var err = config.load(CONFIG_PATH)
	if err != OK:
		apply_defaults()
		save_settings()
		return
	
	if resolution_option:
		resolution_option.select(config.get_value("graphics", "resolution", 1))
	if language_option:
		var locale = config.get_value("language", "locale", "ru")
		language_option.select(0 if locale == "ru" else 1)
	if fps_check:
		fps_check.button_pressed = config.get_value("graphics", "show_fps", false)
	if camera_sensitivity_slider:
		camera_sensitivity_slider.value = config.get_value("camera", "sensitivity", 0.2)
	
	if music_slider:
		music_slider.value = config.get_value("audio", "music_volume", 0.2)
	if sfx_slider:
		sfx_slider.value = config.get_value("audio", "sfx_volume", 0.2)
	if ambience_slider:
		ambience_slider.value = config.get_value("audio", "ambience_volume", 0.2)
	if ui_sound_check:
		ui_sound_check.button_pressed = config.get_value("audio", "ui_sounds", true)
	
	if fullscreen_btn:
		fullscreen_btn.text = "Полный экран"
	
	apply_audio_volumes()
	apply_graphics_settings()
	apply_camera_settings()
	apply_fps_visibility()

func apply_defaults() -> void:
	if resolution_option: resolution_option.select(1)
	if language_option: language_option.select(0)
	if fps_check: fps_check.button_pressed = false
	if camera_sensitivity_slider: camera_sensitivity_slider.value = 0.2
	
	if music_slider: music_slider.value = 0.2
	if sfx_slider: sfx_slider.value = 0.2
	if ambience_slider: ambience_slider.value = 0.2
	if ui_sound_check: ui_sound_check.button_pressed = true

func _show_reset_confirm() -> void:
	var page = _get_current_page()
	var title = ""
	var text = ""
	
	match page:
		0:
			title = "Сброс графики"
			text = "Сбросить настройки графики по умолчанию?"
		1:
			title = "Сброс аудио"
			text = "Сбросить настройки звука по умолчанию?"
		2:
			title = "Сброс управления"
			text = "Сбросить управление по умолчанию?"
	
	var menu = AcceptDialog.new()
	menu.title = title
	menu.dialog_text = text
	menu.add_button("Сбросить", true, "yes")
	menu.add_cancel_button("Отмена")
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(100, 40)
	
	menu.custom_action.connect(func(action):
		if action == "yes":
			match page:
				0:
					if resolution_option: resolution_option.select(1)
					if language_option: language_option.select(0)
					if fps_check: fps_check.button_pressed = false
					if camera_sensitivity_slider: camera_sensitivity_slider.value = 0.2
				1:
					if music_slider: music_slider.value = 0.2
					if sfx_slider: sfx_slider.value = 0.2
					if ambience_slider: ambience_slider.value = 0.2
					if ui_sound_check: ui_sound_check.button_pressed = true
				2:
					_reset_controls_only()
			save_settings()
			load_settings()
		menu.hide()
		menu.queue_free()
	)
	
	add_child(menu)
	menu.popup_centered()

func _get_current_page() -> int:
	if graphics_page and graphics_page.visible: return 0
	if audio_page and audio_page.visible: return 1
	if controls_page and controls_page.visible: return 2
	return 0

func _reset_controls_only() -> void:
	var defaults = {
		"ui_up": KEY_W, "ui_down": KEY_S, "ui_left": KEY_A, "ui_right": KEY_D,
		"interact": KEY_E, "jump": KEY_SPACE, "inventory": KEY_TAB, "ui_cancel": KEY_ESCAPE
	}
	for action in defaults.keys():
		for e in InputMap.action_get_events(action).duplicate():
			InputMap.action_erase_event(action, e)
		var event = InputEventKey.new()
		event.keycode = defaults[action]
		InputMap.action_add_event(action, event)
	InputRebind.save_keybinds()
	update_key_labels()

func save_settings() -> void:
	if resolution_option: config.set_value("graphics", "resolution", resolution_option.selected)
	if language_option: config.set_value("language", "locale", "ru" if language_option.selected == 0 else "en")
	if fps_check: config.set_value("graphics", "show_fps", fps_check.button_pressed)
	if camera_sensitivity_slider: config.set_value("camera", "sensitivity", camera_sensitivity_slider.value)
	
	if music_slider: config.set_value("audio", "music_volume", music_slider.value)
	if sfx_slider: config.set_value("audio", "sfx_volume", sfx_slider.value)
	if ambience_slider: config.set_value("audio", "ambience_volume", ambience_slider.value)
	if ui_sound_check: config.set_value("audio", "ui_sounds", ui_sound_check.button_pressed)
	
	config.save(CONFIG_PATH)
	apply_audio_volumes()
	apply_graphics_settings()
	apply_camera_settings()
	apply_fps_visibility()

func apply_fps_visibility() -> void:
	if fps_label:
		fps_label.visible = fps_check.button_pressed if fps_check else false

func apply_audio_volumes() -> void:
	if music_slider: _apply_volume("Master", music_slider.value)
	if sfx_slider: _apply_volume("SFX", sfx_slider.value)
	if ambience_slider: _apply_volume("Ambience", ambience_slider.value)

func apply_camera_settings() -> void:
	if camera_sensitivity_slider:
		Global.camera_sensitivity = camera_sensitivity_slider.value

func apply_graphics_settings() -> void:
	if resolution_option:
		match resolution_option.selected:
			0: get_window().size = Vector2i(1920, 1080)
			1: get_window().size = Vector2i(1280, 720)
			2: get_window().size = Vector2i(854, 480)
		get_window().move_to_center()

func _apply_volume(bus_name: String, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, lerp(-30.0, 10.0, value))

func show_page(index: int) -> void:
	if graphics_page: graphics_page.visible = (index == 0)
	if audio_page: audio_page.visible = (index == 1)
	if controls_page: controls_page.visible = (index == 2)
	
	if graphics_tab: graphics_tab.modulate = Color.WHITE if index == 0 else Color.GRAY
	if audio_tab: audio_tab.modulate = Color.WHITE if index == 1 else Color.GRAY
	if controls_tab: controls_tab.modulate = Color.WHITE if index == 2 else Color.GRAY

func _on_fullscreen() -> void:
	if not fullscreen_btn:
		return
	if fullscreen_btn.text == "Полный экран":
		fullscreen_btn.text = "Оконный режим"
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		fullscreen_btn.text = "Полный экран"
		get_window().mode = Window.MODE_WINDOWED

func _on_language_selected(index: int) -> void:
	TranslationServer.set_locale("ru" if index == 0 else "en")

func update_key_labels() -> void:
	_update_button_label(move_up_btn, "ui_up")
	_update_button_label(move_down_btn, "ui_down")
	_update_button_label(move_left_btn, "ui_left")
	_update_button_label(move_right_btn, "ui_right")
	_update_button_label(interact_btn, "interact")
	_update_button_label(jump_btn, "jump")
	_update_button_label(inventory_btn, "inventory")
	_update_button_label(pause_btn, "ui_cancel")

func _update_button_label(btn: Button, action: String) -> void:
	if not btn:
		return
	btn.text = InputRebind.get_key_text(action)

func _start_rebind(action: String) -> void:
	InputRebind.start_rebind(action)

func _on_back_pressed() -> void:
	save_settings()
	
	if Global.came_from == Global.MenuSource.GAME:
		Global.just_returned_from_settings = true
		var tree = get_tree()
		if tree: tree.change_scene_to_file("res://код/сцены/пролог.tscn")
		return
	
	Fade.fade_out()
	await get_tree().create_timer(0.3).timeout
	var current_tree = get_tree()
	if not current_tree: return
	current_tree.change_scene_to_file("res://Base/Scenes/Main_Menu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and InputRebind.rebinding_action.is_empty():
		_on_back_pressed()
		
		
		
