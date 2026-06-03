extends CanvasLayer

var slides = [
	{"image": preload("res://Textures/Intro/1.png"), "text": "У нас получилось. Эксперимент можно начинать."},
	{"image": preload("res://Textures/Intro/2.png"), "text": "Первый подопытный — крыса."},
	{"image": preload("res://Textures/Intro/3.png"), "text": "Чип сработал. Крыса забыла, кем была."},
	{"image": preload("res://Textures/Intro/4.png"), "text": "Вскоре подчинение охватило и другие виды."},
	{"image": preload("res://Textures/Intro/5.jpg"), "text": "Человечество наконец решило проблему нехватки энергии."},
	{"image": preload("res://Textures/Intro/6.png"), "text": "Животные перестали быть существами. Они стали инструментами."},
	{"image": preload("res://Textures/Intro/7.png"), "text": "Система казалась безупречной."}
]

var current_index: int = 0
var bg: ColorRect
var image_display: TextureRect
var text_label: Label
var scientist_voice: AudioStreamPlayer
var intro_start_time: float = 0.0
var slide_timer: Timer
var is_fading: bool = false
var final_fade_started: bool = false
var typing: bool = false

func _ready() -> void:
	intro_start_time = Time.get_ticks_msec() / 1000.0
	
	scientist_voice = AudioStreamPlayer.new()
	scientist_voice.stream = load("res://Sounds/SFX/Scienist_Voise.MP3")
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
	text_label.add_theme_font_size_override("font_size", 40)
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	text_label.add_theme_constant_override("shadow_offset_x", 2)
	text_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(text_label)
	
	slide_timer = Timer.new()
	slide_timer.wait_time = 5.0
	slide_timer.one_shot = false
	slide_timer.timeout.connect(_on_slide_timer_timeout)
	add_child(slide_timer)
	
	_show_slide(0)
	slide_timer.start()

func _stop_main_menu_music() -> void:
	if has_node("/root/GlobalMusic"):
		GlobalMusic.stop_music()
	for child in get_tree().root.get_children():
		if child is AudioStreamPlayer and child.playing:
			child.stop()

func _type_text(text: String, idx: int) -> void:
	if not is_inside_tree():
		return
	
	if idx >= text.length():
		typing = false
		return
	
	typing = true
	text_label.text += text[idx]
	
	if scientist_voice and not scientist_voice.playing:
		scientist_voice.pitch_scale = 0.7 + randf_range(-0.03, 0.03)
		scientist_voice.play()
	
	if not is_inside_tree():
		typing = false
		return
	
	await get_tree().create_timer(0.04).timeout
	
	if not is_inside_tree() or not typing:
		return
	
	_type_text(text, idx + 1)

func _show_slide(index: int) -> void:
	if index >= slides.size():
		return
	
	typing = false
	
	var slide = slides[index]
	
	is_fading = true
	var fade_out = create_tween()
	fade_out.tween_property(image_display, "modulate:a", 0.0, 0.3)
	fade_out.parallel().tween_property(text_label, "modulate:a", 0.0, 0.3)
	await fade_out.finished
	
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
	final_fade_started = true
	typing = false
	
	var elapsed = Time.get_ticks_msec() / 1000.0 - intro_start_time
	var wait_time = 35.0 - elapsed
	if wait_time > 0:
		await get_tree().create_timer(wait_time).timeout
	
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

func _input(event: InputEvent) -> void:
	if event.is_pressed() and not is_fading and not final_fade_started:
		if slide_timer.is_stopped():
			_start_final_fade()
		else:
			slide_timer.stop()
			_on_slide_timer_timeout()
