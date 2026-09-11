extends Control

@onready var graphics_tab: Button = $GeneralTab
@onready var audio_tab: Button = $AudioTab
@onready var controls_tab: Button = $ControlsTab

@onready var graphics_page: Control = $GraphicsPage
@onready var audio_page: Control = $AudioPage
@onready var controls_page: Control = $ControlsPage

@onready var resolution_button: Button = $GraphicsPage/ResolutionButton
@onready var language_button: Button = $GraphicsPage/LanguageOption
@onready var dynamic_range_button: Button = $AudioPage/DynamicRangeOption

@onready var fps_check = $GraphicsPage/FPSCheck
@onready var camera_sensitivity_slider: HSlider = $GraphicsPage/CameraSensitivitySlider
@onready var brightness_slider: HSlider = $GraphicsPage/BrightnessSlider
@onready var fullscreen_check = $GraphicsPage/FullScreenCheck
@onready var vsync_check = $GraphicsPage/VSyncCheck
@onready var effects_check = $GraphicsPage/EffectsCheck
@onready var interface_attributes_check = $GraphicsPage/InterfaceAttributesCheck

@onready var music_slider: HSlider = $AudioPage/MusicSlider
@onready var sfx_slider: HSlider = $AudioPage/SFXSlider
@onready var ambience_slider: HSlider = $AudioPage/AmbienceSlider
@onready var master_slider: HSlider = $AudioPage/MasterSlider
@onready var ui_slider: HSlider = $AudioPage/UISlider

@onready var move_up_btn: Button = $ControlsPage/ScrollContainer/ContentGrid/MoveUpButton
@onready var move_down_btn: Button = $ControlsPage/ScrollContainer/ContentGrid/MoveDownButton
@onready var move_left_btn: Button = $ControlsPage/ScrollContainer/ContentGrid/MoveLeftButton
@onready var move_right_btn: Button = $ControlsPage/ScrollContainer/ContentGrid/MoveRightButton
@onready var jump_btn: Button = $ControlsPage/ScrollContainer/ContentGrid/JumpButton
@onready var interact_btn: Button = $ControlsPage/ScrollContainer/ContentGrid/InteractButton
@onready var inventory_btn: Button = $ControlsPage/ScrollContainer/ContentGrid/InventoryButton
@onready var pause_btn: Button = $ControlsPage/ScrollContainer/ContentGrid/PauseButton

@onready var apply_btn: Button = find_child("ApplyButton", true, false)
@onready var default_btn: Button = find_child("DefaultButton", true, false)
@onready var back_btn: Button = find_child("BackButton", true, false)

@onready var fps_label: Label = $FPSCounter

var config: ConfigFile = ConfigFile.new()
const CONFIG_PATH: String = "user://settings.cfg"

const POPUP_MENU_TEXTURE_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/FallMenuMenuButtons/FallMenuAquariumMenuButtons/FalledFallingAquariumMenuButton/FalledFallingAquariumMenuButton.png"
const ARROW_TEXTURE_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/FallMenuMenuButtons/FallMenuAquariumMenuButtons/FallMenuArrowAquarium/Arrow.png"

const SLIDER_HANDLE_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuHandle/AquariumMenuHandle.png"
const SLIDER_HANDLE_HOVER_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuHandle/AquariumMenuHandleHover.png"
const SLIDER_HANDLE_PRESSED_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuHandle/AquariumMenuHandlePressed.png"

const SLIDER_EMPTY_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuSliders/AquariumMenuSlider/AquariumMenuSlider.png"
const SLIDER_EMPTY_HOVER_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuSliders/AquariumMenuSlider/AquariumMenuSliderHover.png"
const SLIDER_EMPTY_PRESSED_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuSliders/AquariumMenuSlider/AquariumMenuSliderPressed.png"

const SLIDER_FULL_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuSliders/AquariumMenuFullSlider/AquariumMenuFullSlider.png"
const SLIDER_FULL_HOVER_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuSliders/AquariumMenuFullSlider/AquariumMenuFullSliderHover.png"
const SLIDER_FULL_PRESSED_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSliders/AquariumMenuSliders/AquariumMenuSliders/AquariumMenuFullSlider/AquariumMenuFullSliderPressed.png"

const SWITCH_ON_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSwitchs/AquariumMenuSwitchs/AquariumSwitchOn/AquariumSwitchOn.png"
const SWITCH_ON_HOVER_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSwitchs/AquariumMenuSwitchs/AquariumSwitchOn/AquariumSwitchOnHover.png"
const SWITCH_ON_PRESSED_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSwitchs/AquariumMenuSwitchs/AquariumSwitchOn/AquariumSwitchOnPressed.png"

const SWITCH_OFF_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSwitchs/AquariumMenuSwitchs/AquariumSwitchOff/AquariumSwitchOff.png"
const SWITCH_OFF_HOVER_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSwitchs/AquariumMenuSwitchs/AquariumSwitchOff/AquariumSwitchOffHover.png"
const SWITCH_OFF_PRESSED_PATH: String = "res://Fish Slaves/Textures/Interface/MenuButtons/MenuSwitchs/AquariumMenuSwitchs/AquariumSwitchOff/AquariumSwitchOffPressed.png"

var current_brightness_layer: ColorRect = null

const BRIGHTNESS_MIN: float = 0.0
const BRIGHTNESS_MAX: float = 1.0

var brightness_percent_label: Label = null
var camera_sensitivity_percent_label: Label = null
var music_percent_label: Label = null
var sfx_percent_label: Label = null
var ambience_percent_label: Label = null
var master_percent_label: Label = null
var ui_percent_label: Label = null

var has_unsaved_changes: bool = false
var current_popup: AcceptDialog = null

var resolution_items: Array[String] = []
var language_items: Array[String] = []
var dynamic_range_items: Array[String] = []

var resolution_selected: int = 0
var language_selected: int = 0
var dynamic_range_selected: int = 1

var resolution_dropdown: Control = null
var language_dropdown: Control = null
var dynamic_range_dropdown: Control = null

var resolution_arrow: TextureRect = null
var language_arrow: TextureRect = null
var dynamic_range_arrow: TextureRect = null

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
	_setup_dropdowns()
	_connect_signals()
	setup_options()
	setup_audio_options()
	load_settings()
	update_key_labels()
	show_page(0)
	
	_apply_slider_textures()
	_apply_switch_textures()
	
	_create_percent_labels()
	
	_create_brightness_layer_deferred()
	_apply_brightness_deferred()
	
	has_unsaved_changes = false

func _process(_delta: float) -> void:
	if fps_label and fps_label.visible:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

func _mark_unsaved() -> void:
	has_unsaved_changes = true

# ==================== КАСТОМНЫЕ ВЫПАДАЮЩИЕ МЕНЮ ====================

func _setup_dropdowns() -> void:
	resolution_dropdown = _create_dropdown(resolution_button, "resolution")
	language_dropdown = _create_dropdown(language_button, "language")
	dynamic_range_dropdown = _create_dropdown(dynamic_range_button, "dynamic_range")

func _create_dropdown(button: Button, id: String) -> Control:
	if not button:
		return null
	
	var container = Panel.new()
	container.name = button.name + "Dropdown"
	container.visible = false
	container.z_index = 100
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var bg = StyleBoxTexture.new()
	bg.texture = load(POPUP_MENU_TEXTURE_PATH)
	container.add_theme_stylebox_override("panel", bg)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.offset_left = 6
	vbox.offset_right = -6
	vbox.offset_top = 6
	vbox.offset_bottom = -6
	
	container.add_child(vbox)
	
	add_child(container)
	
	_create_arrow_for_button(button)
	
	container.set_meta("id", id)
	container.set_meta("button", button)
	
	button.pressed.connect(_on_dropdown_button_pressed.bind(container))
	
	return container

func _create_arrow_for_button(button: Button) -> void:
	if not button:
		return
	
	var arrow = TextureRect.new()
	arrow.name = "Arrow"
	arrow.texture = load(ARROW_TEXTURE_PATH)
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.size = Vector2(24, 24)
	arrow.pivot_offset = Vector2(12, 12)
	arrow.position = Vector2(button.size.x - 34, button.size.y / 2.0 - 12)
	
	button.add_child(arrow)
	
	if button == resolution_button:
		resolution_arrow = arrow
	elif button == language_button:
		language_arrow = arrow
	elif button == dynamic_range_button:
		dynamic_range_arrow = arrow

func _on_dropdown_button_pressed(container: Control) -> void:
	if not container:
		return
	
	if container.visible:
		_close_dropdown(container)
		return
	
	_close_all_dropdowns()
	_open_dropdown(container)

func _open_dropdown(container: Control) -> void:
	if not container:
		return
	
	var button: Button = container.get_meta("button")
	if not button:
		return
	
	container.position = Vector2(button.global_position.x, button.global_position.y + button.size.y)
	container.size = Vector2(button.size.x, 0)
	container.custom_minimum_size = Vector2(button.size.x, 0)
	
	container.visible = true
	
	await get_tree().process_frame
	var vbox = container.get_node_or_null("VBox")
	if vbox:
		var total_height = vbox.size.y + 12
		container.size = Vector2(button.size.x, total_height)
	
	_flip_arrow(button, true)

func _close_dropdown(container: Control) -> void:
	if not container:
		return
	
	container.visible = false
	
	var button: Button = container.get_meta("button")
	if button:
		_flip_arrow(button, false)

func _close_all_dropdowns() -> void:
	if resolution_dropdown and resolution_dropdown.visible:
		_close_dropdown(resolution_dropdown)
	if language_dropdown and language_dropdown.visible:
		_close_dropdown(language_dropdown)
	if dynamic_range_dropdown and dynamic_range_dropdown.visible:
		_close_dropdown(dynamic_range_dropdown)

func _flip_arrow(button: Button, flipped: bool) -> void:
	var arrow: TextureRect = null
	
	if button == resolution_button:
		arrow = resolution_arrow
	elif button == language_button:
		arrow = language_arrow
	elif button == dynamic_range_button:
		arrow = dynamic_range_arrow
	
	if not arrow or not is_instance_valid(arrow):
		return
	
	arrow.scale.y = -1 if flipped else 1

func _populate_dropdown(container: Control, items: Array[String], selected: int, id: String) -> void:
	if not container:
		return
	
	var vbox = container.get_node_or_null("VBox")
	if not vbox:
		return
	
	for child in vbox.get_children():
		child.queue_free()
	
	for i in range(items.size()):
		var btn = Button.new()
		btn.text = items[i]
		btn.custom_minimum_size = Vector2(0, 20)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if i == selected:
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
		else:
			btn.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
			btn.add_theme_color_override("font_hover_color", Color(0.7, 0.7, 0.7))
		
		var normal_bg = StyleBoxFlat.new()
		normal_bg.bg_color = Color(0, 0, 0, 0.07)
		normal_bg.content_margin_left = 6
		normal_bg.content_margin_right = 6
		
		var hover_bg = StyleBoxFlat.new()
		hover_bg.bg_color = Color(0, 0, 0, 0.35)
		hover_bg.content_margin_left = 6
		hover_bg.content_margin_right = 6
		
		btn.add_theme_stylebox_override("normal", normal_bg)
		btn.add_theme_stylebox_override("hover", hover_bg)
		btn.add_theme_stylebox_override("pressed", hover_bg)
		btn.add_theme_stylebox_override("focus", normal_bg)
		
		btn.add_theme_font_size_override("font_size", 18)
		
		btn.pressed.connect(_on_dropdown_item_selected.bind(i, id, container))
		
		vbox.add_child(btn)

func _on_dropdown_item_selected(index: int, id: String, container: Control) -> void:
	match id:
		"resolution":
			resolution_selected = index
			_update_button_text(resolution_button, resolution_items, resolution_selected)
			_populate_dropdown(container, resolution_items, resolution_selected, "resolution")
			_on_resolution_selected(index)
		"language":
			language_selected = index
			_update_button_text(language_button, language_items, language_selected)
			_populate_dropdown(container, language_items, language_selected, "language")
			_on_language_selected(index)
		"dynamic_range":
			dynamic_range_selected = index
			_update_button_text(dynamic_range_button, dynamic_range_items, dynamic_range_selected)
			_populate_dropdown(container, dynamic_range_items, dynamic_range_selected, "dynamic_range")
			_on_dynamic_range_selected(index)
	
	_close_dropdown(container)

func _update_button_text(button: Button, items: Array[String], selected: int) -> void:
	if not button or items.is_empty():
		return
	if selected < 0 or selected >= items.size():
		return
	button.text = items[selected]
	
	var arrow = button.get_node_or_null("Arrow")
	if arrow:
		arrow.position = Vector2(button.size.x - 34, button.size.y / 2.0 - 12)

# ==================== ЯРКОСТЬ ====================

func _create_brightness_layer_deferred() -> void:
	if current_brightness_layer and is_instance_valid(current_brightness_layer):
		return
	
	current_brightness_layer = ColorRect.new()
	current_brightness_layer.name = "BrightnessLayer"
	current_brightness_layer.color = Color(0, 0, 0, 0)
	current_brightness_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_brightness_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	current_brightness_layer.z_index = 1000
	
	var canvas = CanvasLayer.new()
	canvas.name = "BrightnessCanvas"
	canvas.layer = 100
	canvas.add_child(current_brightness_layer)
	
	get_tree().root.add_child.call_deferred(canvas)

func _apply_brightness_deferred() -> void:
	if not brightness_slider:
		return
	
	if not current_brightness_layer or not is_instance_valid(current_brightness_layer):
		await get_tree().process_frame
		if not current_brightness_layer or not is_instance_valid(current_brightness_layer):
			return
	
	_apply_brightness_value()

func _apply_brightness_value() -> void:
	if not brightness_slider or not current_brightness_layer:
		return
	
	var value = brightness_slider.value
	value = clamp(value, 0.0, 1.0)
	
	var overlay_alpha = lerp(0.75, 0.0, value)
	
	if current_brightness_layer and is_instance_valid(current_brightness_layer):
		current_brightness_layer.color = Color(0, 0, 0, overlay_alpha)
		current_brightness_layer.visible = overlay_alpha > 0.001

func _apply_brightness() -> void:
	_apply_brightness_value()

# ==================== АУДИО ОПЦИИ ====================

func setup_audio_options() -> void:
	dynamic_range_items = ["Высокий", "Стандартный", "Низкий"]
	dynamic_range_selected = 1
	_populate_dropdown(dynamic_range_dropdown, dynamic_range_items, dynamic_range_selected, "dynamic_range")
	_update_button_text(dynamic_range_button, dynamic_range_items, dynamic_range_selected)

func _on_dynamic_range_selected(index: int) -> void:
	_populate_dropdown(dynamic_range_dropdown, dynamic_range_items, index, "dynamic_range")
	_mark_unsaved()

# ==================== ПРОЦЕНТЫ ДЛЯ ПОЛЗУНКОВ ====================

func _create_percent_labels() -> void:
	brightness_percent_label = _create_percent_label(brightness_slider)
	camera_sensitivity_percent_label = _create_percent_label(camera_sensitivity_slider)
	music_percent_label = _create_percent_label(music_slider)
	sfx_percent_label = _create_percent_label(sfx_slider)
	ambience_percent_label = _create_percent_label(ambience_slider)
	master_percent_label = _create_percent_label(master_slider)
	ui_percent_label = _create_percent_label(ui_slider)
	
	if brightness_slider:
		brightness_slider.value_changed.connect(_on_brightness_slider_changed)
	if camera_sensitivity_slider:
		camera_sensitivity_slider.value_changed.connect(_on_camera_sensitivity_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_slider_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	if ambience_slider:
		ambience_slider.value_changed.connect(_on_ambience_slider_changed)
	if master_slider:
		master_slider.value_changed.connect(_on_master_slider_changed)
	if ui_slider:
		ui_slider.value_changed.connect(_on_ui_slider_changed)
	
	_update_all_percent_labels()

func _create_percent_label(slider: HSlider) -> Label:
	if not slider:
		return null
	
	var label = Label.new()
	label.name = "PercentLabel"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 10
	label.custom_minimum_size = Vector2(60, 0)
	
	label.position = Vector2(slider.position.x + slider.size.x + 10, slider.position.y)
	label.size = Vector2(60, slider.size.y)
	
	slider.get_parent().add_child(label)
	
	return label

func _update_all_percent_labels() -> void:
	_update_percent_label(brightness_percent_label, brightness_slider)
	_update_percent_label(camera_sensitivity_percent_label, camera_sensitivity_slider)
	_update_percent_label(music_percent_label, music_slider)
	_update_percent_label(sfx_percent_label, sfx_slider)
	_update_percent_label(ambience_percent_label, ambience_slider)
	_update_percent_label(master_percent_label, master_slider)
	_update_percent_label(ui_percent_label, ui_slider)

func _update_percent_label(label: Label, slider: HSlider) -> void:
	if not label or not slider:
		return
	
	if slider == brightness_slider:
		var percent = int(slider.value * 100)
		label.text = str(percent) + "%"
	else:
		var percent = int((slider.value / slider.max_value) * 100)
		label.text = str(percent) + "%"
	
	label.position = Vector2(slider.position.x + slider.size.x + 10, slider.position.y)
	label.size = Vector2(60, slider.size.y)

func _on_brightness_slider_changed(_value: float) -> void:
	_update_percent_label(brightness_percent_label, brightness_slider)
	_mark_unsaved()

func _on_camera_sensitivity_changed(value: float) -> void:
	_update_percent_label(camera_sensitivity_percent_label, camera_sensitivity_slider)
	Global.camera_sensitivity = value
	_mark_unsaved()

func _on_music_slider_changed(_value: float) -> void:
	_update_percent_label(music_percent_label, music_slider)
	_mark_unsaved()

func _on_sfx_slider_changed(_value: float) -> void:
	_update_percent_label(sfx_percent_label, sfx_slider)
	_mark_unsaved()

func _on_ambience_slider_changed(_value: float) -> void:
	_update_percent_label(ambience_percent_label, ambience_slider)
	_mark_unsaved()

func _on_master_slider_changed(_value: float) -> void:
	_update_percent_label(master_percent_label, master_slider)
	_mark_unsaved()

func _on_ui_slider_changed(_value: float) -> void:
	_update_percent_label(ui_percent_label, ui_slider)
	_mark_unsaved()

# ==================== АТМОСФЕРНЫЕ ЭФФЕКТЫ ====================

func _remove_all_bubbles() -> void:
	var tree = get_tree()
	if not tree:
		return
	_remove_bubbles_recursive(tree.root)

func _remove_bubbles_recursive(node: Node) -> void:
	if not node or not is_instance_valid(node):
		return
	
	for child in node.get_children():
		if not child or not is_instance_valid(child):
			continue
		
		if child.name.to_lower().contains("bubble"):
			child.queue_free()
		else:
			_remove_bubbles_recursive(child)

# ==================== АТРИБУТЫ ИНТЕРФЕЙСА ====================

func _hide_all_decorations(node: Node, hide: bool) -> void:
	if not node or not is_instance_valid(node):
		return
	
	for child in node.get_children():
		if not child or not is_instance_valid(child):
			continue
		
		if child is Button:
			for btn_child in child.get_children():
				if btn_child.name == "Seaweed" or btn_child.name == "Rust":
					btn_child.visible = not hide
		elif child.name == "Seaweed" or child.name == "Rust":
			child.visible = not hide
		else:
			_hide_all_decorations(child, hide)

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
		graphics_tab, audio_tab, controls_tab,
		move_up_btn, move_down_btn, move_left_btn, move_right_btn,
		jump_btn, interact_btn, inventory_btn, pause_btn,
		resolution_button, language_button, dynamic_range_button
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
	if apply_btn: apply_btn.pressed.connect(save_settings)
	if default_btn: default_btn.pressed.connect(_show_reset_confirm)
	
	if fullscreen_check: fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if vsync_check: vsync_check.toggled.connect(_on_vsync_toggled)
	if effects_check: effects_check.toggled.connect(_on_effects_toggled)
	if interface_attributes_check: interface_attributes_check.toggled.connect(_on_interface_attributes_toggled)
	if fps_check: fps_check.toggled.connect(_on_fps_toggled)
	
	if brightness_slider: brightness_slider.value_changed.connect(_on_brightness_changed)
	
	if move_up_btn: move_up_btn.pressed.connect(func(): _start_rebind("ui_up"))
	if move_down_btn: move_down_btn.pressed.connect(func(): _start_rebind("ui_down"))
	if move_left_btn: move_left_btn.pressed.connect(func(): _start_rebind("ui_left"))
	if move_right_btn: move_right_btn.pressed.connect(func(): _start_rebind("ui_right"))
	if interact_btn: interact_btn.pressed.connect(func(): _start_rebind("interact"))
	if jump_btn: jump_btn.pressed.connect(func(): _start_rebind("jump"))
	if inventory_btn: inventory_btn.pressed.connect(func(): _start_rebind("inventory"))
	if pause_btn: pause_btn.pressed.connect(func(): _start_rebind("ui_cancel"))

# ==================== ОБРАБОТЧИКИ СВИТЧЕЙ ====================

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
	_mark_unsaved()

func _on_vsync_toggled(pressed: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if pressed else DisplayServer.VSYNC_DISABLED
	)
	_mark_unsaved()

func _on_effects_toggled(pressed: bool) -> void:
	Global.atmospheric_effects_enabled = pressed
	if not pressed:
		_remove_all_bubbles()
	_mark_unsaved()

func _on_interface_attributes_toggled(pressed: bool) -> void:
	Global.interface_attributes_enabled = pressed
	Global.button_effects_enabled = pressed
	
	if not pressed:
		_hide_all_decorations(get_tree().current_scene if get_tree() else null, true)
	else:
		Global._force_apply_seaweed(get_tree().current_scene if get_tree() else null)
	_mark_unsaved()

func _on_fps_toggled(pressed: bool) -> void:
	if fps_label:
		fps_label.visible = pressed
	_mark_unsaved()

func _on_resolution_selected(index: int) -> void:
	_populate_dropdown(resolution_dropdown, resolution_items, index, "resolution")
	_mark_unsaved()

func _on_language_selected(index: int) -> void:
	_populate_dropdown(language_dropdown, language_items, index, "language")
	TranslationServer.set_locale("ru" if index == 0 else "en")
	_mark_unsaved()

func _on_brightness_changed(_value: float) -> void:
	_apply_brightness_value()
	_mark_unsaved()

# ==================== ВЫПАДАЮЩИЕ МЕНЮ ====================

func setup_options() -> void:
	resolution_items = ["1920x1080", "1280x720", "854x480"]
	resolution_selected = 0
	_populate_dropdown(resolution_dropdown, resolution_items, resolution_selected, "resolution")
	_update_button_text(resolution_button, resolution_items, resolution_selected)
	
	language_items = ["Русский", "English"]
	language_selected = 0
	_populate_dropdown(language_dropdown, language_items, language_selected, "language")
	_update_button_text(language_button, language_items, language_selected)

# ==================== ТЕКСТУРЫ ПОЛЗУНКОВ ====================

func _apply_slider_textures() -> void:
	var handle_texture = load(SLIDER_HANDLE_PATH)
	var handle_hover = load(SLIDER_HANDLE_HOVER_PATH)
	var handle_pressed = load(SLIDER_HANDLE_PRESSED_PATH)
	
	var empty_texture = load(SLIDER_EMPTY_PATH)
	var empty_hover = load(SLIDER_EMPTY_HOVER_PATH)
	var empty_pressed = load(SLIDER_EMPTY_PRESSED_PATH)
	
	var full_texture = load(SLIDER_FULL_PATH)
	var full_hover = load(SLIDER_FULL_HOVER_PATH)
	var full_pressed = load(SLIDER_FULL_PRESSED_PATH)
	
	if not handle_texture or not empty_texture or not full_texture:
		return
	
	var handle_scaled = _scale_texture_pixel_art(handle_texture, 2.0)
	var handle_hover_scaled = _scale_texture_pixel_art(handle_hover, 2.0) if handle_hover else handle_scaled
	var handle_pressed_scaled = _scale_texture_pixel_art(handle_pressed, 2.0) if handle_pressed else handle_scaled
	
	var slider_style = StyleBoxTexture.new()
	slider_style.texture = empty_texture
	slider_style.content_margin_left = 4
	slider_style.content_margin_right = 4
	slider_style.content_margin_top = 4
	slider_style.content_margin_bottom = 4
	
	var slider_hover_style = StyleBoxTexture.new()
	slider_hover_style.texture = empty_hover if empty_hover else empty_texture
	slider_hover_style.content_margin_left = 4
	slider_hover_style.content_margin_right = 4
	slider_hover_style.content_margin_top = 4
	slider_hover_style.content_margin_bottom = 4
	
	var slider_pressed_style = StyleBoxTexture.new()
	slider_pressed_style.texture = empty_pressed if empty_pressed else empty_texture
	slider_pressed_style.content_margin_left = 4
	slider_pressed_style.content_margin_right = 4
	slider_pressed_style.content_margin_top = 4
	slider_pressed_style.content_margin_bottom = 4
	
	var slider_full_style = StyleBoxTexture.new()
	slider_full_style.texture = full_texture
	slider_full_style.content_margin_left = 4
	slider_full_style.content_margin_right = 4
	slider_full_style.content_margin_top = 4
	slider_full_style.content_margin_bottom = 4
	
	var slider_full_hover_style = StyleBoxTexture.new()
	slider_full_hover_style.texture = full_hover if full_hover else full_texture
	slider_full_hover_style.content_margin_left = 4
	slider_full_hover_style.content_margin_right = 4
	slider_full_hover_style.content_margin_top = 4
	slider_full_hover_style.content_margin_bottom = 4
	
	var slider_full_pressed_style = StyleBoxTexture.new()
	slider_full_pressed_style.texture = full_pressed if full_pressed else full_texture
	slider_full_pressed_style.content_margin_left = 4
	slider_full_pressed_style.content_margin_right = 4
	slider_full_pressed_style.content_margin_top = 4
	slider_full_pressed_style.content_margin_bottom = 4
	
	var sliders = [
		camera_sensitivity_slider,
		brightness_slider,
		music_slider,
		sfx_slider,
		ambience_slider,
		master_slider,
		ui_slider
	]
	
	for slider in sliders:
		if not slider:
			continue
		
		slider.add_theme_stylebox_override("slider", slider_style)
		slider.add_theme_stylebox_override("slider_highlighted", slider_hover_style)
		slider.add_theme_stylebox_override("slider_pressed", slider_pressed_style)
		
		slider.add_theme_stylebox_override("grabber_area", slider_full_style)
		slider.add_theme_stylebox_override("grabber_area_highlighted", slider_full_hover_style)
		slider.add_theme_stylebox_override("grabber_area_pressed", slider_full_pressed_style)
		
		slider.add_theme_icon_override("grabber", handle_scaled)
		slider.add_theme_icon_override("grabber_highlighted", handle_hover_scaled)
		slider.add_theme_icon_override("grabber_pressed", handle_pressed_scaled)
		slider.add_theme_icon_override("grabber_disabled", handle_scaled)
		
		if handle_scaled:
			slider.add_theme_constant_override("grabber_size", int(handle_scaled.get_height()))
		else:
			slider.add_theme_constant_override("grabber_size", 32)
		slider.add_theme_constant_override("grabber_offset", 0)
		
		slider.custom_minimum_size = Vector2(slider.custom_minimum_size.x, 40)

# ==================== ТЕКСТУРЫ СВИТЧЕЙ ====================

func _apply_switch_textures() -> void:
	var switch_on = load(SWITCH_ON_PATH)
	var switch_on_hover = load(SWITCH_ON_HOVER_PATH)
	var switch_on_pressed = load(SWITCH_ON_PRESSED_PATH)
	
	var switch_off = load(SWITCH_OFF_PATH)
	var switch_off_hover = load(SWITCH_OFF_HOVER_PATH)
	var switch_off_pressed = load(SWITCH_OFF_PRESSED_PATH)
	
	if not switch_on or not switch_off:
		return
	
	var switch_on_scaled = _scale_texture_pixel_art(switch_on, 1.4)
	var switch_on_hover_scaled = _scale_texture_pixel_art(switch_on_hover, 1.4) if switch_on_hover else switch_on_scaled
	var switch_on_pressed_scaled = _scale_texture_pixel_art(switch_on_pressed, 1.4) if switch_on_pressed else switch_on_scaled
	
	var switch_off_scaled = _scale_texture_pixel_art(switch_off, 1.4)
	var switch_off_hover_scaled = _scale_texture_pixel_art(switch_off_hover, 1.4) if switch_off_hover else switch_off_scaled
	var switch_off_pressed_scaled = _scale_texture_pixel_art(switch_off_pressed, 1.4) if switch_off_pressed else switch_off_scaled
	
	var switches = [
		fps_check,
		fullscreen_check,
		vsync_check,
		effects_check,
		interface_attributes_check
	]
	
	for switch in switches:
		if not switch:
			continue
		
		switch.add_theme_icon_override("unchecked", switch_off_scaled if switch_off_scaled else switch_off)
		switch.add_theme_icon_override("checked", switch_on_scaled if switch_on_scaled else switch_on)
		
		switch.add_theme_icon_override("unchecked_highlighted", switch_off_hover_scaled if switch_off_hover_scaled else switch_off)
		switch.add_theme_icon_override("checked_highlighted", switch_on_hover_scaled if switch_on_hover_scaled else switch_on)
		
		switch.add_theme_icon_override("unchecked_pressed", switch_off_pressed_scaled if switch_off_pressed_scaled else switch_off)
		switch.add_theme_icon_override("checked_pressed", switch_on_pressed_scaled if switch_on_pressed_scaled else switch_on)
		
		switch.scale = Vector2.ONE
		switch.custom_minimum_size = Vector2(44, 44)

# ==================== ЗАГРУЗКА / СОХРАНЕНИЕ ====================

func load_settings() -> void:
	var err = config.load(CONFIG_PATH)
	if err != OK:
		apply_defaults()
		save_settings()
		return
	
	resolution_selected = config.get_value("graphics", "resolution", 0)
	_populate_dropdown(resolution_dropdown, resolution_items, resolution_selected, "resolution")
	_update_button_text(resolution_button, resolution_items, resolution_selected)
	
	var locale = config.get_value("language", "locale", "ru")
	language_selected = 0 if locale == "ru" else 1
	_populate_dropdown(language_dropdown, language_items, language_selected, "language")
	_update_button_text(language_button, language_items, language_selected)
	
	if fps_check:
		fps_check.button_pressed = config.get_value("graphics", "show_fps", false)
	if fullscreen_check:
		fullscreen_check.button_pressed = config.get_value("graphics", "fullscreen", false)
	if vsync_check:
		vsync_check.button_pressed = config.get_value("graphics", "vsync", true)
	if effects_check:
		effects_check.button_pressed = config.get_value("graphics", "effects", true)
	if interface_attributes_check:
		interface_attributes_check.button_pressed = config.get_value("graphics", "interface_attributes", true)
	
	if camera_sensitivity_slider:
		camera_sensitivity_slider.max_value = 1.0
		camera_sensitivity_slider.step = 0.01
		camera_sensitivity_slider.value = config.get_value("camera", "sensitivity", 0.0)
		Global.camera_sensitivity = camera_sensitivity_slider.value
	
	if brightness_slider:
		brightness_slider.min_value = BRIGHTNESS_MIN
		brightness_slider.max_value = BRIGHTNESS_MAX
		brightness_slider.step = 0.01
		brightness_slider.value = config.get_value("graphics", "brightness", 1.0)
	
	if music_slider:
		music_slider.value = config.get_value("audio", "music_volume", 1.0)
	if sfx_slider:
		sfx_slider.value = config.get_value("audio", "sfx_volume", 1.0)
	if ambience_slider:
		ambience_slider.value = config.get_value("audio", "ambience_volume", 1.0)
	if master_slider:
		master_slider.value = config.get_value("audio", "master_volume", 1.0)
	if ui_slider:
		ui_slider.value = config.get_value("audio", "ui_volume", 1.0)
	
	dynamic_range_selected = config.get_value("audio", "dynamic_range", 1)
	_populate_dropdown(dynamic_range_dropdown, dynamic_range_items, dynamic_range_selected, "dynamic_range")
	_update_button_text(dynamic_range_button, dynamic_range_items, dynamic_range_selected)
	
	Global.atmospheric_effects_enabled = effects_check.button_pressed if effects_check else true
	Global.interface_attributes_enabled = interface_attributes_check.button_pressed if interface_attributes_check else true
	Global.button_effects_enabled = interface_attributes_check.button_pressed if interface_attributes_check else true
	
	apply_audio_volumes()
	apply_graphics_settings()
	_apply_brightness_value()
	apply_fps_visibility()
	
	_update_all_percent_labels()

func apply_defaults() -> void:
	resolution_selected = 0
	_populate_dropdown(resolution_dropdown, resolution_items, resolution_selected, "resolution")
	_update_button_text(resolution_button, resolution_items, resolution_selected)
	
	language_selected = 0
	_populate_dropdown(language_dropdown, language_items, language_selected, "language")
	_update_button_text(language_button, language_items, language_selected)
	
	if brightness_slider: 
		brightness_slider.min_value = BRIGHTNESS_MIN
		brightness_slider.max_value = BRIGHTNESS_MAX
		brightness_slider.value = 1.0
	if camera_sensitivity_slider:
		camera_sensitivity_slider.max_value = 1.0
		camera_sensitivity_slider.value = 0.0
	if fullscreen_check: fullscreen_check.button_pressed = false
	if vsync_check: vsync_check.button_pressed = true
	if fps_check: fps_check.button_pressed = false
	if effects_check: effects_check.button_pressed = true
	if interface_attributes_check: interface_attributes_check.button_pressed = true
	
	if music_slider: music_slider.value = 1.0
	if sfx_slider: sfx_slider.value = 1.0
	if ambience_slider: ambience_slider.value = 1.0
	if master_slider: master_slider.value = 1.0
	if ui_slider: ui_slider.value = 1.0
	
	dynamic_range_selected = 1
	_populate_dropdown(dynamic_range_dropdown, dynamic_range_items, dynamic_range_selected, "dynamic_range")
	_update_button_text(dynamic_range_button, dynamic_range_items, dynamic_range_selected)

# ==================== ДИАЛОГИ ====================

func _close_current_popup() -> void:
	if current_popup and is_instance_valid(current_popup):
		current_popup.hide()
		current_popup.queue_free()
		current_popup = null

func _show_reset_confirm() -> void:
	_close_current_popup()
	
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
					resolution_selected = 0
					_populate_dropdown(resolution_dropdown, resolution_items, resolution_selected, "resolution")
					_update_button_text(resolution_button, resolution_items, resolution_selected)
					language_selected = 0
					_populate_dropdown(language_dropdown, language_items, language_selected, "language")
					_update_button_text(language_button, language_items, language_selected)
					if fps_check: fps_check.button_pressed = false
					if fullscreen_check: fullscreen_check.button_pressed = false
					if vsync_check: vsync_check.button_pressed = true
					if effects_check: effects_check.button_pressed = true
					if interface_attributes_check: interface_attributes_check.button_pressed = true
					if camera_sensitivity_slider: camera_sensitivity_slider.value = 0.0
					if brightness_slider: brightness_slider.value = 1.0
				1:
					if music_slider: music_slider.value = 1.0
					if sfx_slider: sfx_slider.value = 1.0
					if ambience_slider: ambience_slider.value = 1.0
					if master_slider: master_slider.value = 1.0
					if ui_slider: ui_slider.value = 1.0
					dynamic_range_selected = 1
					_populate_dropdown(dynamic_range_dropdown, dynamic_range_items, dynamic_range_selected, "dynamic_range")
					_update_button_text(dynamic_range_button, dynamic_range_items, dynamic_range_selected)
				2:
					_reset_controls_only()
			save_settings()
			load_settings()
		_close_current_popup()
	)
	menu.close_requested.connect(_close_current_popup)
	
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

func _show_unsaved_confirm() -> void:
	_close_current_popup()
	
	var menu = AcceptDialog.new()
	menu.title = "Несохранённые изменения"
	menu.dialog_text = "Вы действительно хотите выйти, не сохранив изменения?"
	menu.add_button("Да", true, "yes")
	menu.add_button("Нет", true, "no")
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(100, 40)
	
	menu.custom_action.connect(func(action):
		_close_current_popup()
		if action == "yes":
			_revert_to_last_saved()
			_exit_to_main_menu()
	)
	menu.close_requested.connect(_close_current_popup)
	
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

func _revert_to_last_saved() -> void:
	config.load(CONFIG_PATH)
	load_settings()

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
	config.set_value("graphics", "resolution", resolution_selected)
	config.set_value("language", "locale", "ru" if language_selected == 0 else "en")
	if fps_check: config.set_value("graphics", "show_fps", fps_check.button_pressed)
	if fullscreen_check: config.set_value("graphics", "fullscreen", fullscreen_check.button_pressed)
	if vsync_check: config.set_value("graphics", "vsync", vsync_check.button_pressed)
	if effects_check: config.set_value("graphics", "effects", effects_check.button_pressed)
	if interface_attributes_check: config.set_value("graphics", "interface_attributes", interface_attributes_check.button_pressed)
	if camera_sensitivity_slider: config.set_value("camera", "sensitivity", camera_sensitivity_slider.value)
	if brightness_slider: config.set_value("graphics", "brightness", brightness_slider.value)
	
	if music_slider: config.set_value("audio", "music_volume", music_slider.value)
	if sfx_slider: config.set_value("audio", "sfx_volume", sfx_slider.value)
	if ambience_slider: config.set_value("audio", "ambience_volume", ambience_slider.value)
	if master_slider: config.set_value("audio", "master_volume", master_slider.value)
	if ui_slider: config.set_value("audio", "ui_volume", ui_slider.value)
	
	config.set_value("audio", "dynamic_range", dynamic_range_selected)
	
	config.save(CONFIG_PATH)
	apply_audio_volumes()
	apply_graphics_settings()
	_apply_brightness_value()
	apply_fps_visibility()
	
	if camera_sensitivity_slider:
		Global.camera_sensitivity = camera_sensitivity_slider.value
	
	Global.atmospheric_effects_enabled = effects_check.button_pressed if effects_check else true
	Global.interface_attributes_enabled = interface_attributes_check.button_pressed if interface_attributes_check else true
	Global.button_effects_enabled = interface_attributes_check.button_pressed if interface_attributes_check else true
	
	has_unsaved_changes = false

# ==================== ПРИМЕНЕНИЕ НАСТРОЕК ====================

func apply_fps_visibility() -> void:
	if fps_label:
		fps_label.visible = fps_check.button_pressed if fps_check else false

func apply_audio_volumes() -> void:
	if master_slider: _apply_volume("Master", master_slider.value)
	if music_slider: _apply_volume("Music", music_slider.value)
	if sfx_slider: _apply_volume("SFX", sfx_slider.value)
	if ambience_slider: _apply_volume("Ambience", ambience_slider.value)
	if ui_slider: _apply_volume("UI", ui_slider.value)

func apply_graphics_settings() -> void:
	match resolution_selected:
		0: get_window().size = Vector2i(1920, 1080)
		1: get_window().size = Vector2i(1280, 720)
		2: get_window().size = Vector2i(854, 480)
	get_window().move_to_center()
	
	if fullscreen_check:
		if fullscreen_check.button_pressed:
			get_window().mode = Window.MODE_FULLSCREEN
		else:
			get_window().mode = Window.MODE_WINDOWED
	
	if vsync_check:
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync_check.button_pressed else DisplayServer.VSYNC_DISABLED
		)

func _apply_volume(bus_name: String, value: float) -> void:
	Global._apply_audio_bus(bus_name, value)

func _scale_texture_pixel_art(texture: Texture2D, scale: float) -> Texture2D:
	if not texture:
		return null
	
	var image = texture.get_image()
	var new_width = int(image.get_width() * scale)
	var new_height = int(image.get_height() * scale)
	image.resize(new_width, new_height, Image.INTERPOLATE_NEAREST)
	var new_texture = ImageTexture.create_from_image(image)
	return new_texture

func show_page(index: int) -> void:
	if graphics_page: graphics_page.visible = (index == 0)
	if audio_page: audio_page.visible = (index == 1)
	if controls_page: controls_page.visible = (index == 2)
	
	if graphics_tab: graphics_tab.modulate = Color.WHITE if index == 0 else Color.GRAY
	if audio_tab: audio_tab.modulate = Color.WHITE if index == 1 else Color.GRAY
	if controls_tab: controls_tab.modulate = Color.WHITE if index == 2 else Color.GRAY
	
	_close_all_dropdowns()
	_update_all_percent_labels()

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

func _exit_to_main_menu() -> void:
	if Global.came_from == Global.MenuSource.GAME:
		Global.just_returned_from_settings = true
		GlobalMusic.resume_level_music()
		var tree = get_tree()
		if tree: tree.change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act1AquariumLevel.tscn")
		return
	
	Fade.fade_out()
	await get_tree().create_timer(0.3).timeout
	var current_tree = get_tree()
	if current_tree: current_tree.change_scene_to_file("res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuAquarium.tscn")

func _on_back_pressed() -> void:
	if has_unsaved_changes:
		_show_unsaved_confirm()
	else:
		_exit_to_main_menu()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and InputRebind.rebinding_action.is_empty():
		if current_popup:
			_close_current_popup()
			get_viewport().set_input_as_handled()
		elif _any_dropdown_open():
			_close_all_dropdowns()
			get_viewport().set_input_as_handled()
		else:
			_on_back_pressed()
	elif event is InputEventMouseButton and event.pressed:
		if _any_dropdown_open():
			var mouse_pos = get_global_mouse_position()
			var clicked_inside = false
			
			for dd in [resolution_dropdown, language_dropdown, dynamic_range_dropdown]:
				if dd and dd.visible:
					if dd.get_global_rect().has_point(mouse_pos):
						clicked_inside = true
						break
					var btn: Button = dd.get_meta("button")
					if btn and btn.get_global_rect().has_point(mouse_pos):
						clicked_inside = true
						break
			
			if not clicked_inside:
				_close_all_dropdowns()

func _any_dropdown_open() -> bool:
	return (resolution_dropdown and resolution_dropdown.visible) or \
		(language_dropdown and language_dropdown.visible) or \
		(dynamic_range_dropdown and dynamic_range_dropdown.visible)
