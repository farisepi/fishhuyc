extends CanvasLayer

var slides = [
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide1.png"), "text": "У нас получилось. Эксперимент можно начинать."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide2.png"), "text": "Первый подопытный — крыса."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide3.png"), "text": "Чип сработал. Крыса забыла, кем была."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide4.png"), "text": "Вскоре подчинение охватило и другие виды."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide5.png"), "text": "Человечество наконец решило проблему нехватки энергии."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide6.png"), "text": "Животные перестали быть существами. Они стали инструментами."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide7.png"), "text": "Система казалась безупречной..."}
]

var current_index: int = 0
var bg: ColorRect
var image_display: TextureRect
var text_label: Label
var scientist_voice: AudioStreamPlayer
var intro_music: AudioStreamPlayer
var slide_timer: Timer
var is_fading: bool = false
var final_fade_started: bool = false
var typing: bool = false

var skip_bg: ColorRect
var skip_fill: ColorRect
var skip_label: Label
var skip_holding: bool = false
var skip_progress: float = 0.0
var skip_duration: float = 1.5

var custom_font: FontFile

func _ready() -> void:
	Global.intro_active = true
	
	intro_music = AudioStreamPlayer.new()
	intro_music.stream = load("res://Fish Slaves/Sounds/Music/IntroMusic/IntroMusic.mp3")
	intro_music.volume_db = 0.0
	intro_music.bus = "Music"
	add_child(intro_music)
	intro_music.play(0.5)
	
	custom_font = load("res://Fish Slaves/Textures/Font/Font.ttf")
	if custom_font:
		custom_font.fixed_size = 10
	
	scientist_voice = AudioStreamPlayer.new()
	scientist_voice.stream = load("res://Fish Slaves/Sounds/SFX/Act1SFX/ScienistSFX/Act1ScienistVoise.MP3")
	scientist_voice.volume_db = -10.0
	scientist_voice.pitch_scale = 0.9
	add_child(scientist_voice)
	
	_stop_main_menu_music()
	
	bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var screen_size = get_viewport().get_visible_rect().size
	
	image_display = TextureRect.new()
	image_display.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var image_width = screen_size.x * 0.45
	var image_height = screen_size.y * 0.45
	image_display.set_size(Vector2(image_width, image_height))
	image_display.position = Vector2(-image_width / 2, -image_height / 2 - (screen_size.y * 0.15))
	image_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_display.modulate = Color.WHITE
	add_child(image_display)
	
	text_label = Label.new()
	text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	text_label.offset_bottom = -200
	
	if custom_font:
		var big_font = custom_font.duplicate()
		big_font.fixed_size = 16
		text_label.add_theme_font_override("font", big_font)
		text_label.add_theme_font_size_override("font_size", 16)
	
	text_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(text_label)
	
	slide_timer = Timer.new()
	slide_timer.wait_time = 5.0
	slide_timer.one_shot = false
	slide_timer.timeout.connect(_on_slide_timer_timeout)
	add_child(slide_timer)
	
	_setup_skip_ui(screen_size)
	
	_show_slide(0)
	slide_timer.start()

func _setup_skip_ui(screen_size: Vector2) -> void:
	var skip_width = 140
	var skip_height = 20
	
	skip_bg = ColorRect.new()
	skip_bg.color = Color(0, 0, 0, 0.5)
	skip_bg.size = Vector2(skip_width, skip_height)
	skip_bg.position = Vector2(screen_size.x - skip_width - 5, 5)
	skip_bg.z_index = 500
	skip_bg.visible = false
	add_child(skip_bg)
	
	skip_fill = ColorRect.new()
	skip_fill.color = Color.GREEN
	skip_fill.size = Vector2(0, skip_height)
	skip_fill.position = Vector2(screen_size.x - skip_width - 5, 5)
	skip_fill.z_index = 501
	skip_fill.visible = false
	add_child(skip_fill)
	
	skip_label = Label.new()
	skip_label.text = "ПРОПУСТИТЬ"
	
	if custom_font:
		skip_label.add_theme_font_override("font", custom_font)
		skip_label.add_theme_font_size_override("font_size", 10)
	skip_label.add_theme_color_override("font_color", Color.WHITE)
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skip_label.size = Vector2(skip_width, skip_height)
	skip_label.position = Vector2(screen_size.x - skip_width - 5, 5)
	skip_label.z_index = 502
	skip_label.visible = false
	add_child(skip_label)

func _process(delta: float) -> void:
	if final_fade_started:
		return
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not skip_holding:
			skip_holding = true
			skip_progress = 0.0
			skip_bg.visible = true
			skip_fill.visible = true
			skip_label.visible = true
		
		skip_progress += delta
		var progress = skip_progress / skip_duration
		skip_fill.size.x = 130 * progress
		
		if skip_progress >= skip_duration:
			_skip_intro()
	else:
		if skip_holding:
			skip_holding = false
			skip_progress = 0.0
			skip_fill.size.x = 0
			skip_bg.visible = false
			skip_fill.visible = false
			skip_label.visible = false

func _skip_intro() -> void:
	if final_fade_started:
		return
	
	final_fade_started = true
	typing = false
	Global.intro_active = false
	
	if scientist_voice and scientist_voice.playing:
		scientist_voice.stop()
	
	if intro_music and intro_music.playing:
		var fade_tween = create_tween()
		fade_tween.tween_property(intro_music, "volume_db", -80.0, 1.0)
		await fade_tween.finished
		intro_music.stop()
	
	slide_timer.stop()
	
	Global.intro_completed = true
	
	UISounds.start_factory_ambience()
	
	# === ЧЁРНЫЙ ЭКРАН В ROOT (переживёт смену сцены) ===
	var root_black = ColorRect.new()
	root_black.color = Color.BLACK
	root_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_black.z_index = 4095
	get_tree().root.add_child(root_black)
	
	# Ждём 1 кадр — чёрный экран точно появился
	await get_tree().process_frame
	
	# Теперь переключаем сцену
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act1AquariumLevel.tscn")

func _stop_main_menu_music() -> void:
	if has_node("/root/GlobalMusic"):
		GlobalMusic.stop_music()
	for child in get_tree().root.get_children():
		if child is AudioStreamPlayer and child.playing:
			child.stop()

func _type_text(text: String, idx: int) -> void:
	if not is_inside_tree() or final_fade_started:
		return
	
	if idx >= text.length():
		typing = false
		return
	
	typing = true
	text_label.text += text[idx]
	
	if scientist_voice and not scientist_voice.playing:
		scientist_voice.pitch_scale = 0.7 + randf_range(-0.03, 0.03)
		scientist_voice.play()
	
	if not is_inside_tree() or final_fade_started:
		typing = false
		return
	
	var char_delay = 0.04
	
	if current_index == 6:
		var current_char = text[idx]
		if current_char == ".":
			char_delay = 0.35
		else:
			char_delay = 0.10
	
	await get_tree().create_timer(char_delay).timeout
	
	if not is_inside_tree() or not typing or final_fade_started:
		return
	
	_type_text(text, idx + 1)

func _show_slide(index: int) -> void:
	if index >= slides.size() or final_fade_started:
		return
	
	typing = false
	
	var slide = slides[index]
	
	is_fading = true
	var fade_out = create_tween()
	fade_out.tween_property(image_display, "modulate:a", 0.0, 0.3)
	fade_out.parallel().tween_property(text_label, "modulate:a", 0.0, 0.3)
	await fade_out.finished
	
	if final_fade_started:
		return
	
	if slide["image"] != null:
		image_display.texture = slide["image"]
	
	if scientist_voice and scientist_voice.playing:
		scientist_voice.stop()
	
	text_label.text = ""
	_type_text(slide["text"], 0)
	
	var fade_in = create_tween()
	fade_in.tween_property(image_display, "modulate:a", 1.0, 0.3)
	fade_in.parallel().tween_property(text_label, "modulate:a", 1.0, 0.3)
	await fade_in.finished
	is_fading = false

func _on_slide_timer_timeout() -> void:
	if is_fading or final_fade_started:
		return
	
	current_index += 1
	
	if current_index < slides.size():
		_show_slide(current_index)
	else:
		slide_timer.stop()
		_start_final_fade()

func _start_final_fade() -> void:
	if final_fade_started:
		return
	
	final_fade_started = true
	typing = false
	Global.intro_active = false
	
	if scientist_voice and scientist_voice.playing:
		scientist_voice.stop()
	
	if intro_music and intro_music.playing:
		var fade_tween = create_tween()
		fade_tween.tween_property(intro_music, "volume_db", -80.0, 1.0)
		await fade_tween.finished
		intro_music.stop()
	
	slide_timer.stop()
	
	if not is_inside_tree():
		return
	
	var final_fade = create_tween()
	final_fade.tween_property(image_display, "modulate:a", 0.0, 0.75)
	final_fade.parallel().tween_property(text_label, "modulate:a", 0.0, 0.75)
	await final_fade.finished
	
	Global.intro_completed = true
	
	UISounds.start_factory_ambience()
	
	# === ЧЁРНЫЙ ЭКРАН В ROOT ===
	var root_black = ColorRect.new()
	root_black.color = Color.BLACK
	root_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_black.z_index = 4095
	get_tree().root.add_child(root_black)
	
	await get_tree().process_frame
	
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act1AquariumLevel.tscn")

func _exit_tree() -> void:
	Global.intro_active = false
	if intro_music and intro_music.playing:
		intro_music.stop()
