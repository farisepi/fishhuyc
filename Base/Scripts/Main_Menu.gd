extends Node2D

@export var bubble_scene: PackedScene

@onready var play_btn: Button = $PlayButton
@onready var settings_btn: Button = $SettingsButton
@onready var achiv_btn: Button = $AchivmentsButton
@onready var discord_btn: Button = $DiscordButton
@onready var telegram_btn: Button = $TelegramButton
@onready var quit_btn: Button = $QuitButton
@onready var save_btn: Button = $SaveButton
@onready var fps_label: Label = $FPSCounter
@onready var logo_area: TextureRect = $LogoArea
@onready var logo: AnimatedSprite2D = $LogoArea/LogoAnimation

var logo_float_time: float = 0.0
var logo_original_y: float = 0.0
var logo_original_scale: Vector2 = Vector2.ONE
var can_click_logo: bool = true

func _ready() -> void:
	Fade.fade_in()

	GlobalMusic.play_music(
		preload("res://Sounds/Music/Temporary/Fish Slaves - Main menu.mp3")
	)

	var ui_sounds = get_node_or_null("/root/UISounds")

	if ui_sounds:
		if ui_sounds.has_method("stop_earthquake"):
			ui_sounds.stop_earthquake()

		if ui_sounds.has_method("stop_all_dialog"):
			ui_sounds.stop_all_dialog()

	_apply_fps_visibility()

	var buttons = [
		play_btn,
		settings_btn,
		achiv_btn,
		discord_btn,
		telegram_btn,
		quit_btn,
		save_btn
	]

	for btn in buttons:
		ButtonEffects.setup(btn)

	if not play_btn.pressed.is_connected(_on_play_button_pressed):
		play_btn.pressed.connect(_on_play_button_pressed)

	if not settings_btn.pressed.is_connected(_on_settings_button_pressed):
		settings_btn.pressed.connect(_on_settings_button_pressed)

	if not achiv_btn.pressed.is_connected(_on_achivments_button_pressed):
		achiv_btn.pressed.connect(_on_achivments_button_pressed)

	if not save_btn.pressed.is_connected(_on_save_button_pressed):
		save_btn.pressed.connect(_on_save_button_pressed)

	if not discord_btn.pressed.is_connected(_on_discord_button_pressed):
		discord_btn.pressed.connect(_on_discord_button_pressed)

	if not telegram_btn.pressed.is_connected(_on_telegram_button_pressed):
		telegram_btn.pressed.connect(_on_telegram_button_pressed)

	if not quit_btn.pressed.is_connected(_on_quit_button_pressed):
		quit_btn.pressed.connect(_on_quit_button_pressed)

	if logo:
		logo_original_y = logo.position.y
		logo_original_scale = logo.scale

	if logo_area:
		logo_area.mouse_entered.connect(_on_logo_mouse_entered)
		logo_area.mouse_exited.connect(_on_logo_mouse_exited)
		logo_area.gui_input.connect(_on_logo_gui_input)

	_reset_camera()
	call_deferred("_start_background_bubbles")

func _process(delta: float) -> void:
	if fps_label and fps_label.visible:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

	if logo:
		logo_float_time += delta * 0.5

		logo.position.y = (
			logo_original_y +
			sin(logo_float_time) * 2.0
		)

		logo.rotation = (
			sin(logo_float_time) * 0.005
		)

func _reset_camera() -> void:
	var cam = get_viewport().get_camera_2d()

	if cam:
		cam.enabled = false

		await get_tree().process_frame

		cam.enabled = true
		cam.set_process(true)

func _on_logo_mouse_entered() -> void:
	if not logo:
		return

	var tween = create_tween()

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(
		logo,
		"scale",
		logo_original_scale * 1.05,
		0.3
	)

func _on_logo_mouse_exited() -> void:
	if not logo:
		return

	var tween = create_tween()

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(
		logo,
		"scale",
		logo_original_scale,
		0.3
	)

func _on_logo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		
		if not can_click_logo:
			return
		
		can_click_logo = false
		
		var click_sound = AudioStreamPlayer.new()
		add_child(click_sound)
		click_sound.stream = preload("res://Sounds/SFX/Logo_Click.mp3")
		click_sound.volume_db = -18.0
		click_sound.pitch_scale = randf_range(0.98, 1.02)
		click_sound.play()
		
		_logo_jelly_effect()
		_spawn_logo_bubbles()
		
		await get_tree().create_timer(0.4).timeout
		
		can_click_logo = true

func _logo_jelly_effect() -> void:
	if not logo:
		return
	
	_kill_tween(logo, "jelly_tween")
	
	var hover_scale = logo_original_scale * 1.05
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(
		logo,
		"scale",
		Vector2(hover_scale.x * 0.96, hover_scale.y * 1.04),
		0.1
	)
	
	if logo_area.get_global_rect().has_point(get_global_mouse_position()):
		tween.tween_property(logo, "scale", hover_scale, 0.15)
	else:
		tween.tween_property(logo, "scale", logo_original_scale, 0.15)
	
	logo.set_meta("jelly_tween", tween)

func _spawn_logo_bubbles() -> void:
	if not bubble_scene:
		return

	var spawn_points = [
		Vector2(-250, 0),
		Vector2(-120, 0),
		Vector2(120, 0),
		Vector2(250, 0)
	]

	for point in spawn_points:

		for i in range(randi_range(1, 2)):

			var bubble = bubble_scene.instantiate()

			add_child(bubble)

			bubble.z_index = -5

			var offset = Vector2(
				randf_range(-35, 35),
				randf_range(-25, 25)
			)

			bubble.global_position = (
				logo.global_position +
				point +
				offset
			)

			var scale_value = randf_range(0.6, 1.5)

			bubble.scale = Vector2.ONE * scale_value

			bubble.speed = randf_range(40.0, 90.0)

			bubble.clickable = true

			bubble.modulate.a = 0.0

			var target_alpha = randf_range(0.01, 0.75)

			var alpha_tween = create_tween()

			alpha_tween.tween_property(
				bubble,
				"modulate:a",
				target_alpha,
				0.4
			)

			var dir = Vector2(
				randf_range(-1.5, 1.5),
				randf_range(-1.5, 1.5)
			).normalized()

			bubble.set_direction(dir)

			bubble.start_life(
				randf_range(2.0, 5.0)
			)

func _kill_tween(node: Node, key: String) -> void:
	if node.has_meta(key):

		var t: Tween = node.get_meta(key)

		if t and t.is_valid():
			t.kill()

func _apply_fps_visibility() -> void:
	var config = ConfigFile.new()

	config.load("user://settings.cfg")

	if fps_label:
		fps_label.visible = config.get_value(
			"graphics",
			"show_fps",
			false
		)

		fps_label.add_theme_font_size_override(
			"font_size",
			14
		)

		fps_label.add_theme_color_override(
			"font_color",
			Color.WHITE
		)

		fps_label.position = Vector2(10, 10)

		fps_label.z_index = 999

func _change_scene(path: String) -> void:
	Fade.fade_out()

	await get_tree().create_timer(0.3).timeout

	get_tree().change_scene_to_file(path)

func _on_play_button_pressed() -> void:
	Global.came_from = Global.MenuSource.MAIN_MENU
	Global.is_new_game = true      # Помечаем, что это НОВАЯ игра
	Global.intro_completed = false
	Global.prologue1_completed = false
	Global.prologue2_completed = false

	Fade.fade_out()

	await get_tree().create_timer(0.3).timeout

	# Идём в save_menu, как и было
	get_tree().change_scene_to_file("res://Base/Scenes/Save_Menu.tscn")

func _on_settings_button_pressed() -> void:
	Global.came_from = Global.MenuSource.MAIN_MENU

	_change_scene(
		"res://Base/Scenes/Settings_Menu.tscn"
	)

func _on_achivments_button_pressed() -> void:
	Global.came_from = Global.MenuSource.MAIN_MENU

	_change_scene(
		"res://Base/Scenes/Achievements_Menu.tscn"
	)

func _on_save_button_pressed() -> void:
	Global.came_from = Global.MenuSource.MAIN_MENU
	Global.is_new_game = false

	_change_scene(
		"res://Base/Scenes/Save_Menu.tscn"
	)

func _on_discord_button_pressed() -> void:
	OS.shell_open(
		"https://discord.gg/64CKW4kXrq"
	)

func _on_telegram_button_pressed() -> void:
	OS.shell_open(
		"https://t.me/fishslaves"
	)

func _on_quit_button_pressed() -> void:
	Fade.fade_out()

	await get_tree().create_timer(0.3).timeout

	get_tree().quit()

func _start_background_bubbles() -> void:
	while true:
		for i in range(randi_range(1, 2)):
			_make_menu_bubble()
		
		await get_tree().create_timer(
			randf_range(0.15, 0.35)
		).timeout

func _make_menu_bubble() -> void:
	if not bubble_scene:
		return
	
	var bubble = bubble_scene.instantiate()
	add_child(bubble)
	bubble.z_index = -10
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	bubble.global_position = Vector2(
		randf_range(0, viewport_size.x),
		randf_range(0, viewport_size.y)
	)
	
	var scale_value = randf_range(0.5, 1.4)
	bubble.scale = Vector2.ONE * scale_value
	bubble.speed = randf_range(10.0, 25.0)
	bubble.clickable = true
	bubble.modulate.a = 0.0
	
	var target_alpha = randf_range(0.01, 0.75)
	var alpha_tween = create_tween()
	alpha_tween.tween_property(bubble, "modulate:a", target_alpha, 1.0)
	
	bubble.set_direction(Vector2(randf_range(-0.3, 0.3), randf_range(-1.0, -0.2)))
	bubble.start_life(randf_range(6.0, 15.0))
