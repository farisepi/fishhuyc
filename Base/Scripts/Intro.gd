extends CanvasLayer

var slides = [
	{"image": preload("res://Textures/Intro/1.png"), "text": "У нас получилось. Эксперимент можно начинать."},
	{"image": preload("res://Textures/Intro/2.png"), "text": "Первый подопытный — крыса."},
	{"image": preload("res://Textures/Intro/3.png"), "text": "Чип сработал. Крыса забыла, кем была."},
	{"image": preload("res://Textures/Intro/4.png"), "text": "Вскоре подчинение охватило и другие виды."},
	{"image": preload("res://Textures/Intro/5.png"), "text": "Человечество наконец решило проблему нехватки энергии."},
	{"image": preload("res://Textures/Intro/6.png"), "text": "Животные перестали быть существами. Они стали инструментами."},
	{"image": preload("res://Textures/Intro/7.png"), "text": "Система казалась безупречной..."}
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

# Таймер для строгого контроля длительности
var total_timer: Timer
var intro_duration: float = 31.0  # Строго 31 секунда

func _ready() -> void:
	# === МУЗЫКА — САМАЯ ПЕРВАЯ СТРОКА ===
	intro_music = AudioStreamPlayer.new()
	intro_music.stream = load("res://Sounds/Music/Intro_Music.mp3")
	intro_music.volume_db = 0.0
	intro_music.bus = "Music"
	add_child(intro_music)
	
	# Обрезаем начало на 0.5 секунды
	intro_music.play(0.5)  # Начинаем с 0.5 секунды
	
	# === ГОВОРИМ GLOBAL, ЧТО МЫ АКТИВНЫ ===
	Global.intro_active = true
	
	# Загружаем шрифт
	custom_font = load("res://Textures/Font/Bitcell_Font.ttf")
	if custom_font:
		custom_font.fixed_size = 10
	
	# Голос учёного
	scientist_voice = AudioStreamPlayer.new()
	scientist_voice.stream = load("res://Sounds/SFX/Scienist_Voise.MP3")
	scientist_voice.volume_db = -10.0
	scientist_voice.pitch_scale = 0.9
	scientist_voice.bus = "SFX"
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
	
	# === СОЗДАЁМ LABEL С РАЗМЕРОМ 16 ===
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
	
	# === ТАЙМЕР ДЛЯ СМЕНЫ СЛАЙДОВ (РОВНОЕ ВРЕМЯ) ===
	slide_timer = Timer.new()
	slide_timer.wait_time = 4.0  # КАЖДЫЙ СЛАЙД ПО 4 СЕКУНДЫ
	slide_timer.one_shot = false
	slide_timer.timeout.connect(_on_slide_timer_timeout)
	add_child(slide_timer)
	
	# === ГЛАВНЫЙ ТАЙМЕР — СТРОГО 31 СЕКУНДА ===
	total_timer = Timer.new()
	total_timer.wait_time = intro_duration
	total_timer.one_shot = true
	total_timer.timeout.connect(_on_total_timer_timeout)
	add_child(total_timer)
	total_timer.start()
	
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
	
	# Останавливаем всё
	if scientist_voice and scientist_voice.playing:
		scientist_voice.stop()
	
	if intro_music and intro_music.playing:
		intro_music.stop()
	
	slide_timer.stop()
	total_timer.stop()
	
	Global.intro_completed = true
	
	var black_rect = ColorRect.new()
	black_rect.color = Color.BLACK
	black_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black_rect.z_index = 1000
	black_rect.name = "IntroBlack"
	get_tree().root.add_child(black_rect)
	
	UISounds.start_factory_ambience()
	
	await get_tree().create_timer(0.5).timeout
	
	get_tree().change_scene_to_file("res://Base/Scenes/Level_1.tscn")

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
	
	# === НАСТРОЙКА СКОРОСТИ ПЕЧАТАНИЯ ===
	var char_delay = 0.04  # Обычные слайды — чуть быстрее (было 0.05)
	
	# Если это последний слайд (индекс 6) — оставляем медленным
	if current_index == 6:
		var current_char = text[idx]
		
		# Если это точка — печатаем МЕДЛЕННЕЕ
		if current_char == ".":
			char_delay = 0.35  # Пауза на точке
		else:
			char_delay = 0.10  # В 2.5 раза медленнее обычного
	
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

func _on_total_timer_timeout() -> void:
	# Строго 31 секунда прошла — завершаем интро
	if not final_fade_started:
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
		intro_music.stop()
	
	slide_timer.stop()
	total_timer.stop()
	
	if not is_inside_tree():
		return
	
	var final_fade = create_tween()
	final_fade.tween_property(image_display, "modulate:a", 0.0, 0.75)
	final_fade.parallel().tween_property(text_label, "modulate:a", 0.0, 0.75)
	await final_fade.finished
	
	Global.intro_completed = true
	
	var black_rect = ColorRect.new()
	black_rect.color = Color.BLACK
	black_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black_rect.z_index = 1000
	black_rect.name = "IntroBlack"
	get_tree().root.add_child(black_rect)
	
	UISounds.start_factory_ambience()
	
	await get_tree().create_timer(0.5).timeout
	
	get_tree().change_scene_to_file("res://Base/Scenes/Level_1.tscn")

func _exit_tree() -> void:
	Global.intro_active = false
	if intro_music and intro_music.playing:
		intro_music.stop()
