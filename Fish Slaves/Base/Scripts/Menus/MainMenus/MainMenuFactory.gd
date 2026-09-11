extends Node2D

@onready var play_btn: Button = $PlayButton
@onready var settings_btn: Button = $SettingsButton
@onready var achiv_btn: Button = $AchivmentsButton
@onready var discord_btn: Button = $DiscordButton
@onready var telegram_btn: Button = $TelegramButton
@onready var tiktok_btn: Button = $TikTokButton
@onready var quit_btn: Button = $QuitButton
@onready var save_btn: Button = $SaveButton
@onready var fps_label: Label = $FPSCounter
@onready var logo_area: TextureRect = $LogoArea
@onready var logo: AnimatedSprite2D = $LogoArea/LogoAnimation
@onready var menu_music: AudioStreamPlayer = $MenuMusic

var logo_float_time: float = 0.0
var logo_original_y: float = 0.0
var logo_original_scale: Vector2 = Vector2.ONE
var can_click_logo: bool = true

func _ready() -> void:
	if is_instance_valid(Fade):
		Fade.fade_in()
	var cam = get_viewport().get_camera_2d()
	if cam:
		cam.position = get_viewport().get_visible_rect().size / 2
	
	GlobalMusic.play_menu_music()

	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		_apply_volume("Master", config.get_value("audio", "music_volume", 0.2))
		_apply_volume("SFX", config.get_value("audio", "sfx_volume", 0.2))
		_apply_volume("Ambience", config.get_value("audio", "ambience_volume", 0.2))
		Global.camera_sensitivity = config.get_value("camera", "sensitivity", 0.0)
		if config.has_section_key("graphics", "resolution"):
			var res = config.get_value("graphics", "resolution", 1)
			match res:
				0: get_window().size = Vector2i(1920, 1080)
				1: get_window().size = Vector2i(1280, 720)
				2: get_window().size = Vector2i(854, 480)
			get_window().move_to_center()
		if config.has_section_key("language", "locale"):
			var locale = config.get_value("language", "locale", "ru")
			TranslationServer.set_locale(locale)
		if config.has_section_key("graphics", "show_fps"):
			Global.show_fps = config.get_value("graphics", "show_fps", false)

	var ui_sounds = get_node_or_null("/root/UISounds")
	if ui_sounds:
		if ui_sounds.has_method("stop_earthquake"):
			ui_sounds.stop_earthquake()
		if ui_sounds.has_method("stop_all_dialog"):
			ui_sounds.stop_all_dialog()

	_apply_fps_visibility()

	var buttons = [play_btn, settings_btn, achiv_btn, discord_btn, telegram_btn, tiktok_btn, quit_btn, save_btn]
	for btn in buttons:
		if btn != null:
			ButtonEffects.setup(btn)

	if tiktok_btn != null:
		if not tiktok_btn.pressed.is_connected(_on_tiktok_button_pressed):
			tiktok_btn.pressed.connect(_on_tiktok_button_pressed)

	if logo:
		logo_original_y = logo.position.y
		logo_original_scale = logo.scale

	if logo_area:
		logo_area.mouse_entered.connect(_on_logo_mouse_entered)
		logo_area.mouse_exited.connect(_on_logo_mouse_exited)
		logo_area.gui_input.connect(_on_logo_gui_input)

func _apply_volume(bus_name: String, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, lerp(-30.0, 10.0, value))

func _process(delta: float) -> void:
	if fps_label and fps_label.visible:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	if logo:
		logo_float_time += delta * 0.5
		logo.position.y = logo_original_y + sin(logo_float_time) * 2.0
		logo.rotation = sin(logo_float_time) * 0.005

func _on_logo_mouse_entered() -> void:
	if not logo:
		return
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(logo, "scale", logo_original_scale * 1.05, 0.3)

func _on_logo_mouse_exited() -> void:
	if not logo:
		return
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(logo, "scale", logo_original_scale, 0.3)

func _on_logo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not can_click_logo:
			return
		can_click_logo = false
		var click_sound = AudioStreamPlayer.new()
		add_child(click_sound)
		click_sound.stream = preload("res://Fish Slaves/Sounds/SFX/MenuSFX/MainMenuAquariumLogoClick.mp3")
		click_sound.volume_db = -18.0
		click_sound.pitch_scale = randf_range(0.98, 1.02)
		click_sound.play()
		_logo_jelly_effect()
		_spawn_logo_boxes()
		await get_tree().create_timer(2.5).timeout
		can_click_logo = true

func _logo_jelly_effect() -> void:
	if not logo:
		return
	_kill_tween(logo, "jelly_tween")
	var hover_scale = logo_original_scale * 1.05
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(logo, "scale", Vector2(hover_scale.x * 0.96, hover_scale.y * 1.04), 0.1)
	if logo_area.get_global_rect().has_point(get_global_mouse_position()):
		tween.tween_property(logo, "scale", hover_scale, 0.15)
	else:
		tween.tween_property(logo, "scale", logo_original_scale, 0.15)
	logo.set_meta("jelly_tween", tween)

func _kill_tween(node: Node, key: String) -> void:
	if node.has_meta(key):
		var t: Tween = node.get_meta(key)
		if t and t.is_valid():
			t.kill()

func _apply_fps_visibility() -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	if fps_label:
		fps_label.visible = config.get_value("graphics", "show_fps", false)
		fps_label.add_theme_font_size_override("font_size", 14)
		fps_label.add_theme_color_override("font_color", Color.WHITE)
		fps_label.position = Vector2(10, 10)
		fps_label.z_index = 999

func _goto_scene(path: String) -> void:
	if is_instance_valid(Fade):
		Fade.fade_out()
		await get_tree().create_timer(0.3).timeout
	Global.goto_scene(path)

func _on_play_button_pressed() -> void:
	UISounds.play_click()
	Global.came_from = Global.MenuSource.MAIN_MENU
	Global.is_new_game = true
	Global.intro_completed = false
	Global.prologue1_completed = false
	Global.prologue2_completed = false
	_goto_scene("res://Fish Slaves/Base/Scenes/Menus/SaveMenus/SavesMenuFactory.tscn")

func _on_settings_button_pressed() -> void:
	UISounds.play_click()
	Global.came_from = Global.MenuSource.MAIN_MENU
	_goto_scene("res://Fish Slaves/Base/Scenes/Menus/SettingMenus/SettingsMenuFactory.tscn")

func _on_achivments_button_pressed() -> void:
	UISounds.play_click()
	Global.came_from = Global.MenuSource.MAIN_MENU
	_goto_scene("res://Fish Slaves/Base/Scenes/Menus/AchievementMenus/AchievementsMenuFactory.tscn")

func _on_save_button_pressed() -> void:
	UISounds.play_click()
	Global.came_from = Global.MenuSource.MAIN_MENU
	Global.is_new_game = false
	_goto_scene("res://Fish Slaves/Base/Scenes/Menus/SaveMenus/SavesMenuFactory.tscn")

func _on_discord_button_pressed() -> void:
	UISounds.play_click()
	OS.shell_open("https://discord.gg/64CKW4kXrq")

func _on_telegram_button_pressed() -> void:
	UISounds.play_click()
	OS.shell_open("https://t.me/fishslaves")

func _on_tiktok_button_pressed() -> void:
	UISounds.play_click()
	OS.shell_open("https://www.tiktok.com/@fish.slaves.official")

func _on_quit_button_pressed() -> void:
	UISounds.play_click()
	if is_instance_valid(Fade):
		Fade.fade_out()
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()

# ==================== ЭФФЕКТ ОТ КЛИКА НА ЛОГО ====================

func _spawn_logo_boxes() -> void:
	var box_texture = load("res://Fish Slaves/Textures/Backgrounds/MainMenuBackgrounds/MainMenuFactoryBackground/FactoryBackgroundLayer7Box.png")
	if not box_texture:
		return
	
	var canvas = CanvasLayer.new()
	canvas.layer = 199
	add_child(canvas)
	
	var view_size = get_viewport().get_visible_rect().size
	
	for i in range(3):
		_create_falling_box(canvas, box_texture, view_size)
	
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(canvas):
		canvas.queue_free()

func _create_falling_box(canvas: CanvasLayer, box_texture: Texture2D, view_size: Vector2) -> void:
	var box = Area2D.new()
	box.input_pickable = true
	box.z_index = 50
	canvas.add_child(box)
	
	var spr = Sprite2D.new()
	spr.texture = box_texture
	var s = randf_range(0.6, 1.5)
	spr.scale = Vector2(2.0, 2.0) * s
	box.add_child(spr)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(spr.texture.get_width() * s, spr.texture.get_height() * s)
	col.shape = shape
	box.add_child(col)
	
	box.position = Vector2(randf_range(0, view_size.x), -100.0 - randf_range(0, 150))
	box.rotation = randf_range(-0.6, 0.6)
	
	var fall_duration = randf_range(1.4, 2.0)
	var target_y = view_size.y + 150.0
	var sway_x = randf_range(-70.0, 70.0)
	
	box.input_event.connect(func(_v, event, _idx):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_on_caught_box(box, spr)
	)
	
	var tween = box.create_tween()
	tween.set_parallel(true)
	tween.tween_property(box, "position:y", target_y, fall_duration).set_ease(Tween.EASE_IN)
	tween.tween_property(box, "position:x", box.position.x + sway_x, fall_duration)
	tween.tween_property(box, "rotation", box.rotation + randf_range(-3.0, 3.0), fall_duration)

func _on_caught_box(box: Area2D, spr: Sprite2D) -> void:
	if not is_instance_valid(box):
		return
	
	box.set_deferred("input_pickable", false)
	
	var catch_tween = create_tween()
	catch_tween.set_parallel(true)
	catch_tween.tween_property(box, "scale", Vector2(0.3, 0.3), 0.3).set_ease(Tween.EASE_IN)
	catch_tween.tween_property(box, "modulate:a", 0.0, 0.3)
	catch_tween.tween_property(box, "position:y", box.position.y - 80, 0.3).set_ease(Tween.EASE_OUT)
	
	await catch_tween.finished
	if is_instance_valid(box):
		box.queue_free()
	
	# Запоминаем — была ли ачивка уже получена
	var was_unlocked = Achievements.acrobat_unlocked
	Achievements.unlock_acrobat()
	
	# Показываем уведомление только если ачивка только что открылась
	if not was_unlocked:
		_show_acrobat_achievement()

# ==================== АЧИВКА "АКРОБАТ" ====================

func _show_acrobat_achievement() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	add_child(canvas)
	
	var ctrl = Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ctrl)
	
	var view_size = get_viewport().get_visible_rect().size
	var bg = ColorRect.new()
	bg.color = Color(0.35, 0.15, 0.1, 0.85)
	bg.size = Vector2(320, 60)
	bg.position = Vector2(view_size.x, 10)
	ctrl.add_child(bg)
	
	var icon = Label.new()
	icon.text = "★"
	icon.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	icon.add_theme_font_size_override("font_size", 28)
	icon.position = Vector2(view_size.x + 15, 20)
	icon.size = Vector2(40, 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ctrl.add_child(icon)
	
	var header = Label.new()
	header.text = "ДОСТИЖЕНИЕ"
	header.add_theme_color_override("font_color", Color(1, 0.7, 0.5, 0.9))
	header.add_theme_font_size_override("font_size", 18)
	header.position = Vector2(view_size.x + 65, 18)
	ctrl.add_child(header)
	
	var l = Label.new()
	l.text = "Акробат"
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	l.add_theme_font_size_override("font_size", 36)
	l.position = Vector2(view_size.x + 65, 35)
	ctrl.add_child(l)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(bg, "position:x", view_size.x - 330, 0.4)
	tween.parallel().tween_property(icon, "position:x", view_size.x - 305, 0.4)
	tween.parallel().tween_property(header, "position:x", view_size.x - 255, 0.4)
	tween.parallel().tween_property(l, "position:x", view_size.x - 255, 0.4)
	
	await get_tree().create_timer(3.5).timeout
	
	var tween2 = create_tween()
	tween2.set_ease(Tween.EASE_IN)
	tween2.tween_property(bg, "position:x", view_size.x, 0.3)
	tween2.parallel().tween_property(icon, "position:x", view_size.x + 15, 0.3)
	tween2.parallel().tween_property(header, "position:x", view_size.x + 65, 0.3)
	tween2.parallel().tween_property(l, "position:x", view_size.x + 65, 0.3)
	await tween2.finished
	
	canvas.queue_free()

# ==================== АЧИВКА "БУНТАРЬ" ====================

func _show_rebel_achievement() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	add_child(canvas)
	
	var ctrl = Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ctrl)
	
	var view_size = get_viewport().get_visible_rect().size
	var bg = ColorRect.new()
	bg.color = Color(0.35, 0.15, 0.1, 0.85)
	bg.size = Vector2(320, 60)
	bg.position = Vector2(view_size.x, 10)
	ctrl.add_child(bg)
	
	var icon = Label.new()
	icon.text = "★"
	icon.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	icon.add_theme_font_size_override("font_size", 28)
	icon.position = Vector2(view_size.x + 15, 20)
	icon.size = Vector2(40, 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ctrl.add_child(icon)
	
	var header = Label.new()
	header.text = "ДОСТИЖЕНИЕ"
	header.add_theme_color_override("font_color", Color(1, 0.7, 0.5, 0.9))
	header.add_theme_font_size_override("font_size", 18)
	header.position = Vector2(view_size.x + 65, 18)
	ctrl.add_child(header)
	
	var l = Label.new()
	l.text = "Бунтарь"
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	l.add_theme_font_size_override("font_size", 36)
	l.position = Vector2(view_size.x + 65, 35)
	ctrl.add_child(l)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(bg, "position:x", view_size.x - 330, 0.4)
	tween.parallel().tween_property(icon, "position:x", view_size.x - 305, 0.4)
	tween.parallel().tween_property(header, "position:x", view_size.x - 255, 0.4)
	tween.parallel().tween_property(l, "position:x", view_size.x - 255, 0.4)
	
	_spawn_falling_boxes()
	
	await get_tree().create_timer(3.5).timeout
	
	var tween2 = create_tween()
	tween2.set_ease(Tween.EASE_IN)
	tween2.tween_property(bg, "position:x", view_size.x, 0.3)
	tween2.parallel().tween_property(icon, "position:x", view_size.x + 15, 0.3)
	tween2.parallel().tween_property(header, "position:x", view_size.x + 65, 0.3)
	tween2.parallel().tween_property(l, "position:x", view_size.x + 65, 0.3)
	await tween2.finished
	
	canvas.queue_free()

func _spawn_falling_boxes() -> void:
	var box_texture = load("res://Fish Slaves/Textures/Backgrounds/MainMenuBackgrounds/MainMenuFactoryBackground/FactoryBackgroundLayer7Box.png")
	if not box_texture:
		return
	
	var canvas = CanvasLayer.new()
	canvas.layer = 199
	add_child(canvas)
	
	var view_size = get_viewport().get_visible_rect().size
	
	for i in range(12):
		var spr = Sprite2D.new()
		spr.texture = box_texture
		spr.scale = Vector2(2.0, 2.0) * randf_range(0.6, 1.5)
		spr.position = Vector2(randf_range(0, view_size.x), -100.0 - randf_range(0, 200))
		spr.rotation = randf_range(-0.6, 0.6)
		canvas.add_child(spr)
		
		var fall_duration = randf_range(1.2, 2.5)
		var target_y = view_size.y + 150.0
		var sway_x = randf_range(-60.0, 60.0)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(spr, "position:y", target_y, fall_duration).set_ease(Tween.EASE_IN)
		tween.tween_property(spr, "position:x", spr.position.x + sway_x, fall_duration)
		tween.tween_property(spr, "rotation", spr.rotation + randf_range(-2.0, 2.0), fall_duration)
		
		var delay = randf_range(0.0, 1.5)
		await get_tree().create_timer(delay).timeout
	
	await get_tree().create_timer(4.5).timeout
	canvas.queue_free()
