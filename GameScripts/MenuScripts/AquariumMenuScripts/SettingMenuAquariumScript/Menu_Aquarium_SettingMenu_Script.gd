extends Control
const STYLED_DIALOG := preload("res://GameScripts/UIScripts/MenuDialogScripts/Menu_StyledDialog.gd")

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
@onready var inspect_btn: Button = get_node_or_null("ControlsPage/ScrollContainer/ContentGrid/InspectButton")
@onready var journal_btn: Button = get_node_or_null("ControlsPage/ScrollContainer/ContentGrid/JournalButton")

@onready var apply_btn: Button = find_child("ApplyButton", true, false)
@onready var default_btn: Button = find_child("DefaultButton", true, false)
@onready var back_btn: Button = find_child("BackButton", true, false)

@onready var fps_label: Label = $FPSCounter

var config: ConfigFile = ConfigFile.new()
const CONFIG_PATH: String = "user://settings.cfg"

const POPUP_MENU_TEXTURE_PATH: String = "res://GameAssets/Sprites/UserInterfaceSprites/AquariumMenuSprites/AquariumMenuButtonTextures/FallingButtonTextures/Menu_Aquarium_Button_Falling_Falled_Texture.png"
const ARROW_TEXTURE_PATH: String = "res://GameAssets/Sprites/UserInterfaceSprites/AquariumMenuSprites/AquariumMenuButtonTextures/FallingButtonTextures/Menu_Aquarium_Button_Falling_Arrow_Texture.png"

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
var current_popup = null

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

const BubbleScript = preload("res://GameScripts/EntityScripts/BubbleEntityScripts/Bubble_Script.gd")
var bubble_scene: PackedScene = preload("res://GameScenes/EntityScenes/BubbleEntityScenes/Bubble_Scene.tscn")

var _suppress_switch_sound: bool = false

func _ready() -> void:
	MenuHeader.style_scrolls.call_deferred(self, true, true)   # the game's scroll line + scroller
	if not has_meta("overlay"):
		if is_instance_valid(Fade) and Fade.has_method("fade_in"):
			Fade.fade_in()
		UISounds.stop_everything_gameplay()
	
	if Global.came_from == Global.MenuSource.GAME:
		pass
	else:
		GlobalMusic.play_menu_music()
	
	config.load(CONFIG_PATH)
	Global.camera_sensitivity = config.get_value("camera", "sensitivity", 0.0)
	InputRebind.keybinds_updated.connect(update_key_labels)
	
	_apply_fps_visibility()
	_relayout()
	_setup_ui()
	_setup_dropdowns()
	_connect_signals()
	setup_options()
	setup_audio_options()
	
	_suppress_switch_sound = true
	load_settings()
	_suppress_switch_sound = false
	
	update_key_labels()
	show_page(0)
	
	_create_percent_labels()
	
	_create_brightness_layer_deferred()
	_apply_brightness_deferred()
	
	has_unsaved_changes = false
	
	call_deferred("_start_background_bubbles")

func _process(_delta: float) -> void:
	if fps_label and fps_label.visible:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

func _mark_unsaved() -> void:
	has_unsaved_changes = true

func _setup_dropdowns() -> void:
	resolution_dropdown = _create_dropdown(resolution_button, "resolution")
	if fps_button:
		fps_dropdown = _create_dropdown(fps_button, "fps")
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
	container.add_theme_stylebox_override("panel", MenuHeader.dropdown_panel_style(_accent_col()))
	
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
	elif button == fps_button:
		fps_arrow = arrow

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
	
	UISounds.play_option_open()
	container.position = Vector2(button.global_position.x, button.global_position.y + button.size.y)
	container.size = Vector2(button.size.x, 0)
	container.custom_minimum_size = Vector2(button.size.x, 0)
	container.visible = true
	
	await get_tree().process_frame
	var vbox = container.get_node_or_null("VBox")
	if vbox:
		var total_height = vbox.size.y + 12
		container.size = Vector2(button.size.x, total_height)
		var vh = get_viewport().get_visible_rect().size.y
		if container.position.y + total_height > vh - 4:
			container.position.y = max(4.0, button.global_position.y - total_height)
	_flip_arrow(button, true)

func _close_dropdown(container: Control) -> void:
	if not container:
		return
	UISounds.play_option_close()
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
	if fps_dropdown and fps_dropdown.visible:
		_close_dropdown(fps_dropdown)

func _flip_arrow(button: Button, flipped: bool) -> void:
	var arrow: TextureRect = null
	if button == resolution_button:
		arrow = resolution_arrow
	elif button == language_button:
		arrow = language_arrow
	elif button == dynamic_range_button:
		arrow = dynamic_range_arrow
	elif button == fps_button:
		arrow = fps_arrow
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
			btn.add_theme_color_override("font_color", _accent_col())
			btn.add_theme_color_override("font_hover_color", _accent_col())
		else:
			btn.add_theme_color_override("font_color", Color(0.62, 0.63, 0.67))
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var normal_bg = StyleBoxFlat.new()
		normal_bg.bg_color = Color(0, 0, 0, 0)
		normal_bg.content_margin_left = 6
		normal_bg.content_margin_right = 6
		var hover_bg = StyleBoxFlat.new()
		hover_bg.bg_color = Color(_accent_col(), 0.16)
		hover_bg.content_margin_left = 6
		hover_bg.content_margin_right = 6
		btn.add_theme_stylebox_override("normal", normal_bg)
		btn.add_theme_stylebox_override("hover", hover_bg)
		btn.add_theme_stylebox_override("pressed", hover_bg)
		btn.add_theme_stylebox_override("focus", normal_bg)
		btn.add_theme_font_size_override("font_size", 16)
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
		"fps":
			fps_selected = index
			_update_button_text(fps_button, fps_items, fps_selected)
			_populate_dropdown(container, fps_items, fps_selected, "fps")
			Global.fps_limit = FPS_VALUES[index]
			Global.apply_frame_pacing()
			_mark_unsaved()
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

func _create_brightness_layer_deferred() -> void:
	# shared overlay owned by Global (it used to stack a new layer on every visit)
	current_brightness_layer = Global.ensure_brightness_layer()

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

func setup_audio_options() -> void:
	dynamic_range_items = [tr("Высокий"), tr("Стандартный"), tr("Низкий")]
	dynamic_range_selected = 1
	_populate_dropdown(dynamic_range_dropdown, dynamic_range_items, dynamic_range_selected, "dynamic_range")
	_update_button_text(dynamic_range_button, dynamic_range_items, dynamic_range_selected)

func _on_dynamic_range_selected(index: int) -> void:
	_populate_dropdown(dynamic_range_dropdown, dynamic_range_items, index, "dynamic_range")
	_mark_unsaved()

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
	_apply_brightness_value()
	_mark_unsaved()

func _on_camera_sensitivity_changed(value: float) -> void:
	_update_percent_label(camera_sensitivity_percent_label, camera_sensitivity_slider)
	Global.camera_sensitivity = value
	_mark_unsaved()

func _on_music_slider_changed(value: float) -> void:
	_update_percent_label(music_percent_label, music_slider)
	Global._apply_audio_bus("Music", value)
	_mark_unsaved()

func _on_sfx_slider_changed(value: float) -> void:
	_update_percent_label(sfx_percent_label, sfx_slider)
	Global._apply_audio_bus("SFX", value)
	_mark_unsaved()

func _on_ambience_slider_changed(value: float) -> void:
	_update_percent_label(ambience_percent_label, ambience_slider)
	Global._apply_audio_bus("Ambience", value)
	_mark_unsaved()

func _on_master_slider_changed(value: float) -> void:
	_update_percent_label(master_percent_label, master_slider)
	Global._apply_audio_bus("Master", value)
	_mark_unsaved()

func _on_ui_slider_changed(value: float) -> void:
	_update_percent_label(ui_percent_label, ui_slider)
	Global._apply_audio_bus("UI", value)
	_mark_unsaved()

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

func _hide_all_decorations(node: Node, should_hide: bool) -> void:
	if not node or not is_instance_valid(node):
		return
	for child in node.get_children():
		if not child or not is_instance_valid(child):
			continue
		if child is Button:
			for btn_child in child.get_children():
				if btn_child.name == "Seaweed" or btn_child.name == "Rust":
					btn_child.visible = not should_hide
		elif child.name == "Seaweed" or child.name == "Rust":
			child.visible = not should_hide
		else:
			_hide_all_decorations(child, should_hide)

func _apply_fps_visibility() -> void:
	config.load(CONFIG_PATH)
	if fps_label:
		fps_label.visible = config.get_value("graphics", "show_fps", false)
		fps_label.add_theme_font_size_override("font_size", 14)
		fps_label.add_theme_color_override("font_color", Color.WHITE)
		fps_label.position = Vector2(10, 10)
		fps_label.z_index = 200

func _setup_ui() -> void:
	var controls: Array[Control] = [
		graphics_tab, audio_tab, controls_tab,
		move_up_btn, move_down_btn, move_left_btn, move_right_btn,
		jump_btn, interact_btn, inventory_btn, pause_btn,
		resolution_button, language_button, dynamic_range_button,
		fps_check, fullscreen_check, vsync_check, effects_check, interface_attributes_check,
		music_slider, sfx_slider, ambience_slider, master_slider, ui_slider,
		camera_sensitivity_slider, brightness_slider
	]
	if inspect_btn: controls.append(inspect_btn)
	if journal_btn: controls.append(journal_btn)
	if apply_btn: controls.append(apply_btn)
	if default_btn: controls.append(default_btn)
	if back_btn: controls.append(back_btn)
	
	var silent_click: Callable = Callable()
	var click_targets: Array = [
		resolution_button, language_button, dynamic_range_button,
		fps_check, fullscreen_check, vsync_check, effects_check, interface_attributes_check
	]
	for control in controls:
		if control:
			if control in click_targets:
				ButtonEffects.setup(control, silent_click)
			else:
				ButtonEffects.setup(control)

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
	if inspect_btn: inspect_btn.pressed.connect(func(): _start_rebind("inspect"))
	if journal_btn: journal_btn.pressed.connect(func(): _start_rebind("journal"))

func _default_resolution() -> int:
	return Global.saved_resolution_index(ConfigFile.new())

## F11 / Alt+Enter pressed somewhere: just show it on the checkbox.
func _on_global_fullscreen(on: bool) -> void:
	if fullscreen_check and fullscreen_check.button_pressed != on:
		_suppress_switch_sound = true
		fullscreen_check.set_pressed_no_signal(on)
		_suppress_switch_sound = false

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed != Global.is_fullscreen():
		Global.set_fullscreen(pressed, resolution_selected)
	if not _suppress_switch_sound:
		if pressed: UISounds.play_switch_on()
		else: UISounds.play_switch_off()
	_mark_unsaved()

func _on_vsync_toggled(pressed: bool) -> void:
	Global.set_vsync(pressed)
	if not _suppress_switch_sound:
		if pressed: UISounds.play_switch_on()
		else: UISounds.play_switch_off()
	_mark_unsaved()

func _on_effects_toggled(pressed: bool) -> void:
	Global.atmospheric_effects_enabled = pressed
	if not pressed:
		_remove_all_bubbles()
	if not _suppress_switch_sound:
		if pressed: UISounds.play_switch_on()
		else: UISounds.play_switch_off()
	_mark_unsaved()

func _on_interface_attributes_toggled(pressed: bool) -> void:
	Global.interface_attributes_enabled = pressed
	Global.button_effects_enabled = pressed
	if not pressed:
		var scene = get_tree().current_scene if get_tree() else null
		_hide_all_decorations(scene, true)
	else:
		var scene = get_tree().current_scene if get_tree() else null
		if scene:
			Global._force_apply_seaweed(scene)
	if not _suppress_switch_sound:
		if pressed: UISounds.play_switch_on()
		else: UISounds.play_switch_off()
	_mark_unsaved()

func _on_fps_toggled(pressed: bool) -> void:
	if fps_label:
		fps_label.visible = pressed
	if not _suppress_switch_sound:
		if pressed: UISounds.play_switch_on()
		else: UISounds.play_switch_off()
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

func setup_options() -> void:
	resolution_items = Global.resolution_names()
	fps_items = _fps_names()
	fps_selected = 0
	_populate_dropdown(fps_dropdown, fps_items, fps_selected, "fps")
	_update_button_text(fps_button, fps_items, fps_selected)
	resolution_selected = _default_resolution()
	fps_selected = 0
	_populate_dropdown(fps_dropdown, fps_items, fps_selected, "fps")
	_update_button_text(fps_button, fps_items, fps_selected)
	if not Global.fullscreen_changed.is_connected(_on_global_fullscreen):
		Global.fullscreen_changed.connect(_on_global_fullscreen)
	_populate_dropdown(resolution_dropdown, resolution_items, resolution_selected, "resolution")
	_update_button_text(resolution_button, resolution_items, resolution_selected)
	language_items = ["Русский", "English"]
	language_selected = 0
	_populate_dropdown(language_dropdown, language_items, language_selected, "language")
	_update_button_text(language_button, language_items, language_selected)

func load_settings() -> void:
	var err = config.load(CONFIG_PATH)
	if err != OK:
		apply_defaults()
		save_settings()
		return
	resolution_selected = Global.saved_resolution_index(config)
	fps_selected = _fps_index(int(config.get_value("graphics", "fps_limit", 0)))
	_populate_dropdown(fps_dropdown, fps_items, fps_selected, "fps")
	_update_button_text(fps_button, fps_items, fps_selected)
	_populate_dropdown(resolution_dropdown, resolution_items, resolution_selected, "resolution")
	_update_button_text(resolution_button, resolution_items, resolution_selected)
	var locale = config.get_value("language", "locale", "ru")
	language_selected = 0 if locale == "ru" else 1
	_populate_dropdown(language_dropdown, language_items, language_selected, "language")
	_update_button_text(language_button, language_items, language_selected)
	if fps_check: fps_check.button_pressed = config.get_value("graphics", "show_fps", false)
	if fullscreen_check: fullscreen_check.button_pressed = config.get_value("graphics", "fullscreen", false)
	if vsync_check: vsync_check.button_pressed = config.get_value("graphics", "vsync", true)
	if effects_check: effects_check.button_pressed = config.get_value("graphics", "effects", true)
	if interface_attributes_check: interface_attributes_check.button_pressed = config.get_value("graphics", "interface_attributes", true)
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
	if music_slider: music_slider.value = config.get_value("audio", "music_volume", 1.0)
	if sfx_slider: sfx_slider.value = config.get_value("audio", "sfx_volume", 1.0)
	if ambience_slider: ambience_slider.value = config.get_value("audio", "ambience_volume", 1.0)
	if master_slider: master_slider.value = config.get_value("audio", "master_volume", 1.0)
	if ui_slider: ui_slider.value = config.get_value("audio", "ui_volume", 1.0)
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
	resolution_selected = _default_resolution()
	fps_selected = 0
	_populate_dropdown(fps_dropdown, fps_items, fps_selected, "fps")
	_update_button_text(fps_button, fps_items, fps_selected)
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
			title = tr("Сброс графики")
			text = tr("Сбросить настройки графики по умолчанию?")
		1:
			title = tr("Сброс аудио")
			text = tr("Сбросить настройки звука по умолчанию?")
		2:
			title = tr("Сброс управления")
			text = tr("Сбросить управление по умолчанию?")
	
	var menu = STYLED_DIALOG.new()
	menu.style = "aquarium"
	menu.title = title
	menu.dialog_text = text
	menu.add_button(tr("Сбросить"), true, "yes")
	menu.add_cancel_button(tr("Отмена"))
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(100, 40)
	menu.custom_action.connect(func(action):
		if action == "yes":
			_suppress_switch_sound = true
			match page:
				0:
					resolution_selected = _default_resolution()
					fps_selected = 0
					_populate_dropdown(fps_dropdown, fps_items, fps_selected, "fps")
					_update_button_text(fps_button, fps_items, fps_selected)
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
			_suppress_switch_sound = false
		_close_current_popup()
	)
	menu.close_requested.connect(_close_current_popup)
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

func _show_unsaved_confirm() -> void:
	_close_current_popup()
	var menu = STYLED_DIALOG.new()
	menu.style = "aquarium"
	menu.title = tr("Несохранённые изменения")
	menu.dialog_text = tr("Вы действительно хотите выйти, не сохранив изменения?")
	menu.add_button(tr("Да"), true, "yes")
	menu.add_button(tr("Нет"), true, "no")
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
	_suppress_switch_sound = true
	load_settings()
	_suppress_switch_sound = false

func _get_current_page() -> int:
	if graphics_page and graphics_page.visible: return 0
	if audio_page and audio_page.visible: return 1
	if controls_page and controls_page.visible: return 2
	return 0

func _reset_controls_only() -> void:
	var defaults = {
		"ui_up": KEY_W, "ui_down": KEY_S, "ui_left": KEY_A, "ui_right": KEY_D,
		"interact": KEY_E, "jump": KEY_SPACE, "inventory": KEY_TAB, "ui_cancel": KEY_ESCAPE,
		"inspect": KEY_I, "journal": KEY_J
	}
	for action in defaults.keys():
		if not InputMap.has_action(action):
			continue
		for e in InputMap.action_get_events(action).duplicate():
			InputMap.action_erase_event(action, e)
		var event = InputEventKey.new()
		event.keycode = defaults[action]
		InputMap.action_add_event(action, event)
	InputRebind.save_keybinds()
	update_key_labels()

func save_settings() -> void:
	config.set_value("graphics", "resolution", resolution_selected)
	config.set_value("graphics", "resolution_size", Global.resolution_size_text(resolution_selected))
	config.set_value("graphics", "fps_limit", FPS_VALUES[fps_selected])
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
	# what the checkbox says is what you get (also from the editor)
	var fs = fullscreen_check.button_pressed if fullscreen_check else Global.is_fullscreen()
	if fs != Global.is_fullscreen() or not fs:
		Global.set_fullscreen(fs, resolution_selected)
	Global.fps_limit = FPS_VALUES[fps_selected]
	if vsync_check:
		Global.set_vsync(vsync_check.button_pressed)

func _apply_volume(bus_name: String, value: float) -> void:
	Global._apply_audio_bus(bus_name, value)

func show_page(index: int) -> void:
	if graphics_page: graphics_page.visible = (index == 0)
	if audio_page: audio_page.visible = (index == 1)
	if controls_page: controls_page.visible = (index == 2)
	if graphics_tab: graphics_tab.modulate = Color.WHITE if index == 0 else Color.GRAY
	if audio_tab: audio_tab.modulate = Color.WHITE if index == 1 else Color.GRAY
	if controls_tab: controls_tab.modulate = Color.WHITE if index == 2 else Color.GRAY
	_style_tabs(index)
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
	_update_button_label(inspect_btn, "inspect")
	_update_button_label(journal_btn, "journal")

func _update_button_label(btn: Button, action: String) -> void:
	if not btn:
		return
	btn.text = InputRebind.get_key_text(action)

func _start_rebind(action: String) -> void:
	if InputRebind.rebinding_action != "":
		InputRebind.cancel_rebind()
	update_key_labels()
	InputRebind.start_rebind(action)
	var btn = _rebind_button(action)
	if btn:
		btn.release_focus()
		_rebind_blink(btn, action)

func _rebind_button(action: String) -> Button:
	return {"ui_up": move_up_btn, "ui_down": move_down_btn, "ui_left": move_left_btn,
		"ui_right": move_right_btn, "interact": interact_btn, "jump": jump_btn,
		"inventory": inventory_btn, "ui_cancel": pause_btn, "inspect": inspect_btn,
		"journal": journal_btn}.get(action, null)

## While waiting for a key the button blinks "..." in the accent colour.
func _rebind_blink(btn: Button, action: String) -> void:
	var acc = _accent_col()
	while is_inside_tree() and InputRebind.rebinding_action == action:
		var on = (Time.get_ticks_msec() / 350) % 2 == 0
		btn.text = "[ ? ]" if on else "[   ]"
		btn.add_theme_color_override("font_color", acc)
		await get_tree().process_frame
	if is_instance_valid(btn):
		btn.remove_theme_color_override("font_color")
	update_key_labels()

func _exit_to_main_menu() -> void:
	if has_meta("overlay"):
		# opened over the paused game from its pause menu: just close
		var host = get_parent()
		if host is CanvasLayer:
			host.queue_free()
		else:
			queue_free()
		return
	if Global.came_from == Global.MenuSource.GAME:
		Global.just_returned_from_settings = true
		var target = Global.scene_to_save
		if target == "" or "SettingsMenu" in target:
			target = "res://GameScenes/LevelScenes/ActPrologueLevelScenes/AquariumLevelScenes/AquariumMainLevelScene/ActPrologue_LevelAquarium_Scene.tscn"
		Global.goto_scene(target)
		return
	Global.goto_scene("res://GameScenes/MenuScenes/AquariumMenuScenes/AquariumMainMenuScene/Menu_Aquarium_MainMenu_Scene.tscn")

func _on_back_pressed() -> void:
	if has_unsaved_changes:
		_show_unsaved_confirm()
	else:
		_exit_to_main_menu()

func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if event.is_action_pressed("ui_cancel") and InputRebind.rebinding_action.is_empty():
		var vp = get_viewport()
		if current_popup:
			_close_current_popup()
			if vp: vp.set_input_as_handled()
		elif _any_dropdown_open():
			_close_all_dropdowns()
			if vp: vp.set_input_as_handled()
		else:
			_on_back_pressed()
			if vp: vp.set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if _any_dropdown_open():
			var mouse_pos = get_global_mouse_position()
			var clicked_inside = false
			for dd in [resolution_dropdown, language_dropdown, dynamic_range_dropdown, fps_dropdown]:
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
		(dynamic_range_dropdown and dynamic_range_dropdown.visible) or \
		(fps_dropdown and fps_dropdown.visible)

func _start_background_bubbles() -> void:
	# the bubbles from the previous aquarium menu carry over; a fresh set only the first time
	if not BubbleScript.restore_menu_bubbles(self, bubble_scene, false):
		for i in range(randi_range(3, 6)):
			_make_menu_bubble()
	_spawn_next_bubble()

func _exit_tree() -> void:
	BubbleScript.save_menu_bubbles(self)

func _spawn_next_bubble() -> void:
	if not bubble_scene:
		return
	if not is_inside_tree():
		return
	var timer = get_tree().create_timer(randf_range(0.15, 0.35))
	timer.timeout.connect(_on_bubble_spawn_timer)

func _on_bubble_spawn_timer() -> void:
	if not is_inside_tree():
		return
	for i in range(randi_range(1, 2)):
		_make_menu_bubble()
	_spawn_next_bubble()

func _make_menu_bubble() -> void:
	if not bubble_scene:
		return
	var viewport = get_viewport()
	if not viewport:
		return
	var viewport_size = viewport.get_visible_rect().size
	var bubble = bubble_scene.instantiate()
	add_child(bubble)
	bubble.set_meta("menu_bg", true)
	bubble.z_index = -10
	bubble.global_position = Vector2(randf_range(0, viewport_size.x), randf_range(0, viewport_size.y))
	bubble.scale = Vector2.ONE * randf_range(0.5, 1.4)
	bubble.speed = randf_range(10.0, 25.0)
	bubble.clickable = false
	bubble.modulate.a = 0.0
	var alpha_tween = create_tween()
	alpha_tween.tween_property(bubble, "modulate:a", randf_range(0.01, 0.75), 1.0)
	bubble.set_direction(Vector2(randf_range(-0.3, 0.3), randf_range(-1.0, -0.2)))
	bubble.start_life(randf_range(6.0, 15.0))


# ---------------------------------------------------------------- layout (built at start)
## A big title like in the pause menu, quiet text tabs, and the general page in two columns
## with small section headers: ЭКРАН | ИЗОБРАЖЕНИЕ + ИГРА. Also adds the frame-rate row.
var fps_button: Button = null
var fps_dropdown: Control = null
var fps_arrow: TextureRect = null
var fps_items: Array[String] = []
var fps_selected: int = 0
const FPS_VALUES: Array[int] = [0, 30, 60, 75, 120, 144, 165, 240, -1]
var _tab_bar: ColorRect = null
var _tab_index: int = 0

func _accent_col() -> Color:
	return MenuHeader.accent_for(self)

func _relayout() -> void:
	var acc = _accent_col()
	# rebind buttons never keep the focus: Space / Enter must not press them again
	for b in [move_up_btn, move_down_btn, move_left_btn, move_right_btn, interact_btn, jump_btn, inventory_btn, pause_btn, inspect_btn, journal_btn]:
		if b:
			b.focus_mode = Control.FOCUS_NONE
	MenuHeader.attach(self, tr("НАСТРОЙКИ"), acc, 30.0, 32)
	# tabs: plain words in a row, the active one lit
	var tabs = [graphics_tab, audio_tab, controls_tab]
	for i in range(tabs.size()):
		var b: Button = tabs[i]
		if b == null:
			continue
		MenuHeader.style_tab(b, acc)
		b.position = Vector2(576 - 255 + i * 170, 86)
		b.size = Vector2(170, 34)
	_tab_bar = ColorRect.new()
	_tab_bar.color = acc
	_tab_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tab_bar.size = Vector2(0, 2)
	_tab_bar.position = Vector2(576, 120)
	add_child(_tab_bar)
	var top_line = get_node_or_null("DividingLine2")
	if top_line:
		top_line.position.y = 132
		top_line.color = Color(acc, 0.35)
		top_line.size.y = 2
	if controls_page:
		controls_page.position.y += 12.0
	var bot_line = get_node_or_null("DividingLine1")
	if bot_line:
		bot_line.color = Color(acc, 0.35)
		bot_line.size.y = 2
	# the frame-rate dropdown: a copy of the resolution one
	if resolution_button and fps_button == null:
		fps_button = resolution_button.duplicate()
		fps_button.name = "FPSLimitButton"
		graphics_page.add_child(fps_button)
		var fl = get_node_or_null("GraphicsPage/ResolutionLabel").duplicate()
		fl.name = "FPSLimitLabel"
		fl.text = "Частота кадров"
		graphics_page.add_child(fl)
		if Engine.has_singleton("ButtonEffects") or has_node("/root/ButtonEffects"):
			ButtonEffects.setup(fps_button, Callable())
	# two columns, page coordinates (the page sits at +8, +8)
	var o = Vector2(8, 8)
	var lx = 120.0 - o.x
	var lend = 536.0 - o.x
	var rx = 616.0 - o.x
	var rend = 1032.0 - o.x
	var y0 = 184.0 - o.y
	var step = 44.0
	MenuHeader.section(graphics_page, tr("ЭКРАН"), acc, Vector2(lx, 150 - o.y), lend - lx)
	MenuHeader.section(graphics_page, tr("ИЗОБРАЖЕНИЕ"), acc, Vector2(rx, 150 - o.y), rend - rx)
	var left = [["ResolutionLabel", "ResolutionButton"], ["FPSLimitLabel", "FPSLimitButton"],
		["FullScreenLabel", "FullScreenCheck"], ["V-SyncLabel", "VSyncCheck"], ["FPSLabel", "FPSCheck"]]
	for i in range(left.size()):
		_place_row(left[i][0], left[i][1], lx, lend, y0 + i * step)
	var right = [["BrightnessLabel", "BrightnessSlider"], ["EffectsLabel", "EffectsCheck"],
		["IntarfaceAtributesLabel", "InterfaceAttributesCheck"]]
	for i in range(right.size()):
		_place_row(right[i][0], right[i][1], rx, rend, y0 + i * step)
	var gy = y0 + 3 * step + 14.0
	MenuHeader.section(graphics_page, tr("ИГРА"), acc, Vector2(rx, gy), rend - rx)
	_place_row("LanguageLabel", "LanguageOption", rx, rend, gy + 36.0)
	_place_row("CameraSensivityLabel", "CameraSensitivitySlider", rx, rend, gy + 36.0 + step)

func _place_row(label_name: String, ctrl_name: String, x0: float, x1: float, y: float) -> void:
	var l = graphics_page.get_node_or_null(label_name) as Label
	var c = graphics_page.get_node_or_null(ctrl_name) as Control
	if l:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position = Vector2(x0, y)
		l.size = Vector2(220, 36)
	if c == null:
		return
	if c is HSlider:
		c.size = Vector2(170, 36)
		c.position = Vector2(x1 - 52 - 170, y)
	elif c is CheckButton:
		c.position = Vector2(x1 - c.size.x, y + (36 - c.size.y) * 0.5)
	elif c is Button:
		var w = 216.0
		var sp = c.get_node_or_null("Rust") as Sprite2D
		if sp:
			sp.scale *= Vector2(w / max(1.0, c.size.x), 34.0 / max(1.0, c.size.y))
			sp.position = Vector2(w, 34) * 0.5
		c.size = Vector2(w, 34)
		c.position = Vector2(x1 - w, y + 1)

func _style_tabs(index: int) -> void:
	_tab_index = index
	var acc = _accent_col()
	var tabs = [graphics_tab, audio_tab, controls_tab]
	for i in range(tabs.size()):
		if tabs[i]:
			MenuHeader.set_tab_active(tabs[i], i == index, acc)
	var b: Button = tabs[index] if index < tabs.size() else null
	if _tab_bar and b:
		var f = b.get_theme_font("font")
		var tw = f.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x if f else 80.0
		var tw2 = create_tween().set_parallel(true)
		tw2.tween_property(_tab_bar, "position:x", b.position.x + (b.size.x - tw) * 0.5, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw2.tween_property(_tab_bar, "size:x", tw, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _fps_names() -> Array[String]:
	var out: Array[String] = []
	for v in FPS_VALUES:
		if v == 0:
			out.append(tr("Авто (%d Гц)") % int(round(Global.screen_hz())))
		elif v < 0:
			out.append(tr("Без лимита"))
		else:
			out.append("%d FPS" % v)
	return out

func _fps_index(v: int) -> int:
	var i = FPS_VALUES.find(v)
	return i if i >= 0 else 0
