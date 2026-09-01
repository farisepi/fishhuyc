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

@onready var move_up_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer/MoveUpButton
@onready var move_down_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer2/MoveDownButton
@onready var move_left_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer3/MoveLeftButton
@onready var move_right_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer4/MoveRightButton
@onready var jump_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer5/JumpButton
@onready var interact_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer6/InteractButton
@onready var inventory_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer8/InventoryButton
@onready var pause_btn = $ControlsPage/ScrollContainer/VBoxContainer/HBoxContainer7/PauseButton
@onready var controls_grid: GridContainer = $ControlsPage/ScrollContainer/VBoxContainer
@onready var apply_btn: Button = find_child("ApplyButton", true, false)
@onready var default_btn: Button = find_child("DefaultButton", true, false)
@onready var back_btn: Button = find_child("BackButton", true, false)

@onready var fps_label: Label = $FPSCounter

var config: ConfigFile = ConfigFile.new()
const CONFIG_PATH: String = "user://settings.cfg"

# Путь к текстуре для выпадающего меню
const POPUP_MENU_TEXTURE_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/FallMenuMenuButtons/FallMenuAquariumMenuButtons/FalledFallingAquariumMenuButton/FalledFallingAquariumMenuButton.png"
# Пути к текстурам для кружочков (радиокнопок)
const UNCHECKED_ICON_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/FactoryMenuSliders/FactoryMenuHandle/FactoryMenuHandle.png"
const CHECKED_ICON_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuHandle/AquariumMenuHandle.png"

# Пути к текстурам для ползунков
const SLIDER_HANDLE_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuHandle/AquariumMenuHandle.png"
const SLIDER_EMPTY_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuSliders/AquariumMenuSlider.png"
const SLIDER_FULL_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuSliders/AquariumMenuFullSlider.png"

# Пути к текстурам для свитча
const SWITCH_OFF_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSwitchs/AquariumMenuSwitchs/AquariumSwitchOff/AquariumSwitchOff.png"
const SWITCH_ON_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSwitchs/AquariumMenuSwitchs/AquariumSwitchOn/AquariumSwitchOn.png"

func _ready() -> void:
	if Global.came_from == Global.MenuSource.GAME:
		if is_instance_valid(Fade):
			Fade.modulate.a = 0.0
	else:
		Fade.fade_in()
	
	GlobalMusic.play_menu_music()
	
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
	
	# Применяем текстуру к выпадающим меню
	_apply_popup_textures()
	
	# Применяем текстуры к ползункам
	_apply_slider_textures()
	
	# Применяем текстуры к свитчам
	_apply_switch_textures()
	if controls_grid:
		controls_grid.columns = 2

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
		interact_btn, jump_btn, inventory_btn, pause_btn,
		resolution_option, language_option
	]
	
	if apply_btn: buttons.append(apply_btn)
	if default_btn: buttons.append(default_btn)
	if back_btn: buttons.append(back_btn)
	
	for btn in buttons:
		if btn:
			ButtonEffects.setup(btn)

func _setup_option_button_effects(opt_btn: OptionButton) -> void:
	if not opt_btn:
		return
	
	var original_alpha = opt_btn.modulate.a
	var original_scale = Vector2.ONE
	
	# Эффект при наведении (как в ButtonEffects)
	opt_btn.mouse_entered.connect(func():
		# Останавливаем idle анимацию
		if opt_btn.has_meta("idle_tween"):
			var t: Tween = opt_btn.get_meta("idle_tween")
			if t and t.is_valid():
				t.kill()
		
		# Анимация изменения цвета (как в ButtonEffects)
		var color_tween = opt_btn.create_tween()
		color_tween.set_loops()
		color_tween.tween_property(opt_btn, "modulate", Color(0.75, 0.88, 1.0, original_alpha), 1.2).set_ease(Tween.EASE_IN_OUT)
		color_tween.tween_property(opt_btn, "modulate", Color(0.55, 0.72, 1.0, original_alpha), 1.2).set_ease(Tween.EASE_IN_OUT)
		opt_btn.set_meta("color_tween", color_tween)
		
		# Jelly анимация
		var jelly = opt_btn.create_tween()
		jelly.set_loops()
		jelly.tween_property(opt_btn, "scale", Vector2(1.04, 0.96), 0.4).set_ease(Tween.EASE_IN_OUT)
		jelly.tween_property(opt_btn, "scale", Vector2(0.96, 1.04), 0.4).set_ease(Tween.EASE_IN_OUT)
		opt_btn.set_meta("jelly_tween", jelly)
		
		# Пузырьки (как в ButtonEffects)
		_spawn_option_bubbles(opt_btn)
	)
	
	# Эффект при уходе мыши
	opt_btn.mouse_exited.connect(func():
		# Убиваем все анимации
		if opt_btn.has_meta("color_tween"):
			var t: Tween = opt_btn.get_meta("color_tween")
			if t and t.is_valid():
				t.kill()
		if opt_btn.has_meta("jelly_tween"):
			var t: Tween = opt_btn.get_meta("jelly_tween")
			if t and t.is_valid():
				t.kill()
		
		# Возвращаем в исходное состояние
		opt_btn.scale = Vector2.ONE
		
		# Плавный возврат цвета
		var settle = opt_btn.create_tween()
		settle.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		settle.tween_property(opt_btn, "modulate", Color(1.0, 1.0, 1.0, original_alpha), 0.4)
		
		# Запускаем idle анимацию
		var idle_tween = opt_btn.create_tween()
		idle_tween.set_loops()
		idle_tween.tween_property(opt_btn, "scale", Vector2(1.01, 1.01), 2.5).set_ease(Tween.EASE_IN_OUT)
		idle_tween.tween_property(opt_btn, "scale", Vector2(0.99, 0.99), 2.5).set_ease(Tween.EASE_IN_OUT)
		opt_btn.set_meta("idle_tween", idle_tween)
	)
	
	# Запускаем idle анимацию
	var idle_tween = opt_btn.create_tween()
	idle_tween.set_loops()
	idle_tween.tween_property(opt_btn, "scale", Vector2(1.01, 1.01), 2.5).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(opt_btn, "scale", Vector2(0.99, 0.99), 2.5).set_ease(Tween.EASE_IN_OUT)
	opt_btn.set_meta("idle_tween", idle_tween)

func _spawn_option_bubbles(opt_btn: OptionButton) -> void:
	var container = opt_btn.get_parent()
	if not container:
		return
	
	var btn_pos = opt_btn.global_position
	var btn_width = opt_btn.size.x
	
	for _i in range(2):
		var bubble = ColorRect.new()
		bubble.color = Color(1.0, 1.0, 1.0, 0.4)
		bubble.size = Vector2(4, 4)
		bubble.position = btn_pos + Vector2(randf_range(5, btn_width - 5), opt_btn.size.y - 5)
		container.add_child(bubble)
		
		var t = opt_btn.create_tween()
		t.set_ease(Tween.EASE_IN_OUT)
		t.tween_property(bubble, "position:y", bubble.position.y - 50, 1.5)
		t.parallel().tween_property(bubble, "position:x", bubble.position.x + randf_range(-8, 8), 1.5)
		t.parallel().tween_property(bubble, "modulate:a", 0.0, 1.5)
		t.parallel().tween_property(bubble, "scale", Vector2(0.5, 0.5), 1.5)
		t.finished.connect(bubble.queue_free)

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

# Применяет текстуру ко всем выпадающим меню
func _apply_popup_textures() -> void:
	# Загружаем текстуру фона
	var texture = load(POPUP_MENU_TEXTURE_PATH)
	if not texture:
		print("Ошибка: текстура не найдена по пути: ", POPUP_MENU_TEXTURE_PATH)
		return
	
	# Применяем к resolution_option
	if resolution_option:
		_apply_texture_to_option_button(resolution_option, texture)
	
	# Применяем к language_option
	if language_option:
		_apply_texture_to_option_button(language_option, texture)

# Применяет текстуру к одному OptionButton
func _apply_texture_to_option_button(option_btn: OptionButton, texture: Texture2D) -> void:
	# Получаем PopupMenu (выпадающее меню)
	var popup = option_btn.get_popup()
	if not popup:
		return
	
	# Загружаем иконки для кружочков
	var unchecked_icon = load(UNCHECKED_ICON_PATH)
	var checked_icon = load(CHECKED_ICON_PATH)
	
	# Создаем увеличенные иконки
	var unchecked_scaled = _scale_texture_pixel_art(unchecked_icon, 2.0) if unchecked_icon else null
	var checked_scaled = _scale_texture_pixel_art(checked_icon, 2.0) if checked_icon else null
	
	# 1. НАСТРАИВАЕМ ФОН МЕНЮ
	var panel_style = StyleBoxTexture.new()
	panel_style.texture = texture
	popup.add_theme_stylebox_override("panel", panel_style)
	
	# 2. ПОЛНОСТЬЮ УБИРАЕМ ВСЕ СТАНДАРТНЫЕ РАДИОКНОПКИ
	# Делаем их невидимыми через StyleBoxEmpty
	var empty_style = StyleBoxEmpty.new()
	popup.add_theme_stylebox_override("radio_checked", empty_style)
	popup.add_theme_stylebox_override("radio_unchecked", empty_style)
	popup.add_theme_stylebox_override("check", empty_style)
	
	# Отключаем радиокнопки для всех пунктов
	for i in range(popup.item_count):
		popup.set_item_as_radio_checkable(i, false)
	
	# 3. УСТАНАВЛИВАЕМ СВОИ ИКОНКИ КАК ОБЫЧНЫЕ ИКОНКИ ПУНКТОВ
	for i in range(popup.item_count):
		if popup.is_item_checked(i):
			if checked_scaled:
				popup.set_item_icon(i, checked_scaled)
		else:
			if unchecked_scaled:
				popup.set_item_icon(i, unchecked_scaled)
	
	# 4. СОЗДАЕМ СТИЛИ ДЛЯ ФОНА ПУНКТОВ
	var normal_style = StyleBoxTexture.new()
	normal_style.texture = texture
	
	var selected_style = StyleBoxTexture.new()
	selected_style.texture = texture
	selected_style.modulate_color = Color(0.5, 0.5, 0.5, 1.0)
	
	var hover_style = StyleBoxTexture.new()
	hover_style.texture = texture
	hover_style.modulate_color = Color(0.8, 0.8, 0.8, 1.0)
	
	popup.add_theme_stylebox_override("normal", normal_style)
	popup.add_theme_stylebox_override("selected", selected_style)
	popup.add_theme_stylebox_override("hover", hover_style)
	
	# 5. НАСТРАИВАЕМ РАЗМЕРЫ И ОТСТУПЫ
	popup.add_theme_constant_override("item_height", 50)   
	popup.add_theme_constant_override("item_icon_size", 48) 
	popup.add_theme_constant_override("h_separation", 20)  # Отступ между иконкой и текстом
	popup.add_theme_constant_override("item_padding", 25)  # УВЕЛИЧЕНО: двигаем правее
	popup.add_theme_constant_override("icon_max_width", 48)
	
	# Настраиваем шрифт для пунктов
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", Color.WHITE)
	popup.add_theme_color_override("font_color_hover", Color.YELLOW)
	
	# 6. УБИРАЕМ ИКОНКУ С САМОЙ КНОПКИ
	option_btn.icon = null

# Функция масштабирования для пиксельных текстур (без сглаживания)
func _scale_texture_pixel_art(texture: Texture2D, scale: float) -> Texture2D:
	if not texture:
		return null
	
	# Получаем изображение из текстуры
	var image = texture.get_image()
	
	# Вычисляем новые размеры
	var new_width = int(image.get_width() * scale)
	var new_height = int(image.get_height() * scale)
	
	# Увеличиваем изображение без сглаживания (для пиксель-арта)
	image.resize(new_width, new_height, Image.INTERPOLATE_NEAREST)
	
	# Создаём новую текстуру из увеличенного изображения
	var new_texture = ImageTexture.create_from_image(image)
	
	# Возвращаем готовую текстуру
	return new_texture

# Создает осветленную копию текстуры на 25%
func _create_highlighted_texture(texture: Texture2D) -> Texture2D:
	if not texture:
		return null
	
	var image = texture.get_image()
	
	# Осветляем каждый пиксель на 25%
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var color = image.get_pixel(x, y)
			color.r = min(color.r * 1.25, 1.0)
			color.g = min(color.g * 1.25, 1.0)
			color.b = min(color.b * 1.25, 1.0)
			image.set_pixel(x, y, color)
	
	var new_texture = ImageTexture.create_from_image(image)
	return new_texture

# Применяет текстуры ко всем ползункам
func _apply_slider_textures() -> void:
	# Загружаем текстуры
	var handle_texture = load(SLIDER_HANDLE_PATH)
	var empty_texture = load(SLIDER_EMPTY_PATH)
	var full_texture = load(SLIDER_FULL_PATH)
	
	if not handle_texture:
		print("Ошибка: текстура ручки не найдена по пути: ", SLIDER_HANDLE_PATH)
		return
	if not empty_texture:
		print("Ошибка: текстура пустого слайдера не найдена по пути: ", SLIDER_EMPTY_PATH)
		return
	if not full_texture:
		print("Ошибка: текстура заполненного слайдера не найдена по пути: ", SLIDER_FULL_PATH)
		return
	
	# Создаем увеличенную текстуру ручки (в 2 раза)
	var handle_scaled = _scale_texture_pixel_art(handle_texture, 2.0)
	if not handle_scaled:
		handle_scaled = handle_texture
	
	# Создаем осветленную версию ручки (на 25%)
	var handle_highlighted = _create_highlighted_texture(handle_scaled)
	
	# Создаем стили для ползунка
	var slider_style = StyleBoxTexture.new()
	slider_style.texture = empty_texture
	slider_style.content_margin_left = 4
	slider_style.content_margin_right = 4
	slider_style.content_margin_top = 4
	slider_style.content_margin_bottom = 4
	
	var slider_hover_style = StyleBoxTexture.new()
	slider_hover_style.texture = empty_texture
	slider_hover_style.content_margin_left = 4
	slider_hover_style.content_margin_right = 4
	slider_hover_style.content_margin_top = 4
	slider_hover_style.content_margin_bottom = 4
	slider_hover_style.modulate_color = Color(1.25, 1.25, 1.25, 1.0)
	
	var slider_pressed_style = StyleBoxTexture.new()
	slider_pressed_style.texture = empty_texture
	slider_pressed_style.content_margin_left = 4
	slider_pressed_style.content_margin_right = 4
	slider_pressed_style.content_margin_top = 4
	slider_pressed_style.content_margin_bottom = 4
	slider_pressed_style.modulate_color = Color(1.25, 1.25, 1.25, 1.0)
	
	# Стили для заполненной части
	var slider_full_style = StyleBoxTexture.new()
	slider_full_style.texture = full_texture
	slider_full_style.content_margin_left = 4
	slider_full_style.content_margin_right = 4
	slider_full_style.content_margin_top = 4
	slider_full_style.content_margin_bottom = 4
	
	var slider_full_hover_style = StyleBoxTexture.new()
	slider_full_hover_style.texture = full_texture
	slider_full_hover_style.content_margin_left = 4
	slider_full_hover_style.content_margin_right = 4
	slider_full_hover_style.content_margin_top = 4
	slider_full_hover_style.content_margin_bottom = 4
	slider_full_hover_style.modulate_color = Color(1.25, 1.25, 1.25, 1.0)
	
	var slider_full_pressed_style = StyleBoxTexture.new()
	slider_full_pressed_style.texture = full_texture
	slider_full_pressed_style.content_margin_left = 4
	slider_full_pressed_style.content_margin_right = 4
	slider_full_pressed_style.content_margin_top = 4
	slider_full_pressed_style.content_margin_bottom = 4
	slider_full_pressed_style.modulate_color = Color(1.25, 1.25, 1.25, 1.0)
	
	# Список всех ползунков
	var sliders = [
		camera_sensitivity_slider,
		music_slider,
		sfx_slider,
		ambience_slider
	]
	
	for slider in sliders:
		if not slider:
			continue
		
		# Применяем стили к ползунку
		slider.add_theme_stylebox_override("slider", slider_style)
		slider.add_theme_stylebox_override("slider_highlighted", slider_hover_style)
		slider.add_theme_stylebox_override("slider_pressed", slider_pressed_style)
		
		# Применяем стили к заполненной части
		slider.add_theme_stylebox_override("grabber_area", slider_full_style)
		slider.add_theme_stylebox_override("grabber_area_highlighted", slider_full_hover_style)
		slider.add_theme_stylebox_override("grabber_area_pressed", slider_full_pressed_style)
		
		# Применяем иконки ручки
		slider.add_theme_icon_override("grabber", handle_scaled)
		slider.add_theme_icon_override("grabber_highlighted", handle_highlighted if handle_highlighted else handle_scaled)
		slider.add_theme_icon_override("grabber_pressed", handle_highlighted if handle_highlighted else handle_scaled)
		slider.add_theme_icon_override("grabber_disabled", handle_scaled)
		
		# Настраиваем размер ручки
		slider.add_theme_constant_override("grabber_size", int(handle_scaled.get_height()))
		slider.add_theme_constant_override("grabber_offset", 0)
		
		# Увеличиваем высоту слайдера
		slider.custom_minimum_size = Vector2(slider.custom_minimum_size.x, 55)

# Применяет текстуры к свитчам
func _apply_switch_textures() -> void:
	# Загружаем текстуры
	var switch_off = load(SWITCH_OFF_PATH)
	var switch_on = load(SWITCH_ON_PATH)
	
	if not switch_off:
		print("Ошибка: текстура выключенного свитча не найдена по пути: ", SWITCH_OFF_PATH)
		return
	if not switch_on:
		print("Ошибка: текстура включенного свитча не найдена по пути: ", SWITCH_ON_PATH)
		return
	
	# Создаем осветленные версии для состояний (на 25%)
	var switch_off_highlighted = _create_highlighted_texture(switch_off)
	var switch_on_highlighted = _create_highlighted_texture(switch_on)
	
	# Список всех свитчей
	var switches = [
		fps_check
	]
	
	for switch in switches:
		if not switch:
			continue
		
		# Применяем текстуры для свитча
		switch.add_theme_icon_override("unchecked", switch_off)
		switch.add_theme_icon_override("checked", switch_on)
		
		# Для состояния наведения используем осветленные текстуры
		switch.add_theme_icon_override("unchecked_highlighted", switch_off_highlighted if switch_off_highlighted else switch_off)
		switch.add_theme_icon_override("checked_highlighted", switch_on_highlighted if switch_on_highlighted else switch_on)
		
		# Увеличиваем размер свитча
		switch.custom_minimum_size = Vector2(40, 40)

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
		GlobalMusic.resume_level_music()
		var tree = get_tree()
		if tree: tree.change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act1AquariumLevel.tscn")
		return
	
	Fade.fade_out()
	await get_tree().create_timer(0.3).timeout
	var current_tree = get_tree()
	if not current_tree: return
	current_tree.change_scene_to_file("res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuAquarium.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and InputRebind.rebinding_action.is_empty():
		_on_back_pressed()
