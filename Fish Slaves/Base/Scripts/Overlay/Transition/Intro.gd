extends CanvasLayer

var slides = [
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide1.png"), "text": "Он держал в руке то, что изменит всё."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide2.png"), "text": "Первой подопытной стала крыса."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide3.png"), "text": "Она больше не чувствовала себя собой."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide4.png"), "text": "Со временем очередь дошла до всех."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide5.png"), "text": "Так появилась новая рабочая сила."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide6.png"), "text": "Чип взял на себя то, что раньше решал мозг."},
	{"image": preload("res://Fish Slaves/Textures/Backgrounds/IntroSlides/IntroSlide7.png"), "text": "Система казалась безупречной..."}
]

const MUSIC_PATH = "res://Fish Slaves/Sounds/Music/IntroMusic/IntroMusic.mp3"
const MUSIC_LENGTH: float = 31.2
const SLIDES_TOTAL_BEFORE_7: float = 25.0
const FINAL_FADE_START_TIME: float = 29.0
const FINAL_FADE_TIME: float = 2.2

const SKIP_HOLD_TIME: float = 1.5
const SKIP_RETRACT_SPEED: float = 1.0 / 0.4

const TYPE_DELAY_DEFAULT: float = 0.04
const TYPE_DELAY_SLIDE7: float = 0.10
const TYPE_DELAY_SLIDE7_DOT: float = 0.35
const SLIDE_TRANSITION: float = 0.3

const PROGRESS_BG_PATH = "res://Fish Slaves/Textures/Interface/MenuButtons/Progressbar/AquariumProgressbar/AquariumProgressbar.png"
const PROGRESS_FULL_PATH = "res://Fish Slaves/Textures/Interface/MenuButtons/Progressbar/AquariumProgressbar/AquariumProgressbarFull.png"

const SKIP_WIDTH: float = 140.0
const SKIP_HEIGHT: float = 8.0
const MAX_DIM_ALPHA: float = 1.0

const MUSIC_NORMAL_DB: float = 0.0
const MUSIC_SILENT_DB: float = -80.0
const VOICE_NORMAL_DB: float = -10.0
const VOICE_SILENT_DB: float = -80.0

const SLIDE_FONT_SIZE: int = 16
const SKIP_FONT_SIZE: int = 7

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
var typing_generation: int = 0

var skip_bg: TextureRect
var skip_fill: TextureRect
var skip_label: Label
var skip_dim: ColorRect
var skip_progress: float = 0.0

var custom_font: FontFile
var slide_font: FontFile

var _start_time: float = 0.0

func _ready() -> void:
	if Global.intro_active:
		queue_free()
		return
	
	Global.intro_active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		Global._apply_audio_bus("Music", config.get_value("audio", "music_volume", 1.0))
	
	intro_music = AudioStreamPlayer.new()
	intro_music.stream = load(MUSIC_PATH)
	intro_music.volume_db = MUSIC_NORMAL_DB
	intro_music.bus = "Music"
	add_child(intro_music)
	intro_music.play(0.5)
	
	custom_font = load("res://Fish Slaves/Textures/Font/Font.ttf")
	slide_font = custom_font.duplicate() if custom_font else null
	if slide_font:
		slide_font.fixed_size = SLIDE_FONT_SIZE
	
	scientist_voice = AudioStreamPlayer.new()
	var voice_path = "res://Fish Slaves/Sounds/SFX/Act1SFX/ScientistSFX/Act1ScientistVoice.MP3"
	if ResourceLoader.exists(voice_path):
		scientist_voice.stream = load(voice_path)
	else:
		var fallback_path = "res://Fish Slaves/Sounds/SFX/Act1SFX/ScientistSFX/Act1ScientistVoise.MP3"
		if ResourceLoader.exists(fallback_path):
			scientist_voice.stream = load(fallback_path)
	scientist_voice.volume_db = VOICE_NORMAL_DB
	scientist_voice.pitch_scale = 0.9
	scientist_voice.bus = "SFX"
	add_child(scientist_voice)
	
	_stop_main_menu_music()
	
	_create_ui()
	
	var screen_size = get_viewport().get_visible_rect().size
	_setup_skip_ui(screen_size)
	
	_start_time = Time.get_ticks_msec() / 1000.0
	print("[INTRO] START at t=0.000, music=", MUSIC_LENGTH, "s, slides=", slides.size())
	print("[INTRO] slide 7 should start at t=", SLIDES_TOTAL_BEFORE_7)
	print("[INTRO] final fade should start at t=", FINAL_FADE_START_TIME)
	
	_show_slide(0)

func _log_time(prefix: String) -> void:
	var now = Time.get_ticks_msec() / 1000.0 - _start_time
	print("[INTRO] ", prefix, " at t=", "%.3f" % now)

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0 - _start_time

func _enforce_label_font() -> void:
	if not slide_font:
		return
	if text_label:
		text_label.add_theme_font_override("font", slide_font)
		text_label.add_theme_font_size_override("font_size", SLIDE_FONT_SIZE)
	if skip_label and custom_font:
		skip_label.add_theme_font_override("font", custom_font)
		skip_label.add_theme_font_size_override("font_size", SKIP_FONT_SIZE)

func _input(event: InputEvent) -> void:
	if final_fade_started:
		return
	get_viewport().set_input_as_handled()

func _create_ui() -> void:
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
	
	_enforce_label_font()
	
	text_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(text_label)
	
	slide_timer = Timer.new()
	slide_timer.one_shot = true
	slide_timer.timeout.connect(_on_slide_timer_timeout)
	add_child(slide_timer)

func _setup_skip_ui(screen_size: Vector2) -> void:
	var pos = Vector2(screen_size.x - SKIP_WIDTH - 5, 5)
	
	skip_dim = ColorRect.new()
	skip_dim.color = Color(0, 0, 0, 0)
	skip_dim.size = screen_size
	skip_dim.position = Vector2.ZERO
	skip_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_dim.z_index = 400
	add_child(skip_dim)
	
	skip_bg = TextureRect.new()
	skip_bg.texture = load(PROGRESS_BG_PATH)
	skip_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skip_bg.stretch_mode = TextureRect.STRETCH_SCALE
	skip_bg.size = Vector2(SKIP_WIDTH, SKIP_HEIGHT)
	skip_bg.position = pos
	skip_bg.z_index = 500
	skip_bg.visible = false
	add_child(skip_bg)
	
	skip_fill = TextureRect.new()
	skip_fill.texture = load(PROGRESS_FULL_PATH)
	skip_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skip_fill.stretch_mode = TextureRect.STRETCH_SCALE
	skip_fill.size = Vector2(0, SKIP_HEIGHT)
	skip_fill.position = pos
	skip_fill.z_index = 501
	skip_fill.visible = false
	skip_fill.clip_contents = true
	add_child(skip_fill)
	
	skip_label = Label.new()
	skip_label.text = "ПРОПУСТИТЬ"
	
	_enforce_label_font()
	
	skip_label.add_theme_color_override("font_color", Color.WHITE)
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skip_label.size = Vector2(SKIP_WIDTH, SKIP_HEIGHT + 6)
	skip_label.position = Vector2(pos.x, pos.y + 8)
	skip_label.z_index = 502
	skip_label.visible = false
	add_child(skip_label)

func _process(delta: float) -> void:
	_enforce_label_font()
	
	if final_fade_started:
		return
	
	var skip_input = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if skip_input:
		if not skip_bg.visible:
			skip_bg.visible = true
			skip_fill.visible = true
			skip_label.visible = true
		skip_progress += delta
		if skip_progress >= SKIP_HOLD_TIME:
			_skip_intro()
			return
	else:
		if skip_progress > 0.0:
			skip_progress = max(skip_progress - SKIP_RETRACT_SPEED * delta, 0.0)
		if skip_progress <= 0.0:
			skip_bg.visible = false
			skip_fill.visible = false
			skip_label.visible = false
	
	var progress = clamp(skip_progress / SKIP_HOLD_TIME, 0.0, 1.0)
	skip_fill.size.x = SKIP_WIDTH * progress
	skip_dim.color = Color(0, 0, 0, progress * MAX_DIM_ALPHA)
	
	if intro_music:
		intro_music.volume_db = lerp(MUSIC_NORMAL_DB, MUSIC_SILENT_DB, progress)
	if scientist_voice:
		scientist_voice.volume_db = lerp(VOICE_NORMAL_DB, VOICE_SILENT_DB, progress)

func _skip_intro() -> void:
	if final_fade_started:
		return
	
	final_fade_started = true
	typing = false
	typing_generation += 1
	Global.intro_active = false
	
	_log_time("SKIP")
	
	if scientist_voice and scientist_voice.playing:
		scientist_voice.stop()
	
	slide_timer.stop()
	
	if intro_music and intro_music.playing:
		intro_music.stop()
	
	Global.intro_completed = true
	UISounds.start_factory_ambience()
	
	_cleanup_menus()
	
	_log_time("CHANGE SCENE -> Act1")
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act1AquariumLevel.tscn")

func _cleanup_menus() -> void:
	var parent = get_parent()
	if parent and parent != get_tree().root and parent != get_tree().current_scene:
		if parent is CanvasLayer or parent is Control or parent is Node2D:
			parent.queue_free()
	
	for child in get_tree().root.get_children():
		if child == self:
			continue
		if child is CanvasLayer:
			var name_lower = String(child.name).to_lower()
			if name_lower.contains("save") or name_lower.contains("menu") or name_lower.contains("achievements") or name_lower.contains("settings"):
				child.queue_free()

func _create_root_black() -> ColorRect:
	for child in get_tree().root.get_children():
		if child is ColorRect and child.z_index == 4095:
			child.queue_free()
	
	var black = ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.z_index = 4095
	get_tree().root.add_child(black)
	return black

func _own_fade_and_change_scene() -> void:
	var black = _create_root_black()
	
	var tween = create_tween()
	tween.tween_property(black, "color:a", 1.0, FINAL_FADE_TIME)
	await tween.finished
	
	_log_time("CHANGE SCENE -> Act1")
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act1AquariumLevel.tscn")

func _stop_main_menu_music() -> void:
	if has_node("/root/GlobalMusic"):
		GlobalMusic.stop_music()
	for child in get_tree().root.get_children():
		if child is AudioStreamPlayer and child.playing:
			child.stop()

func _type_text(text: String, idx: int, generation: int) -> void:
	if not is_inside_tree() or final_fade_started:
		return
	if generation != typing_generation:
		return
	
	if idx >= text.length():
		typing = false
		return
	
	typing = true
	text_label.text += text[idx]
	
	if scientist_voice and not scientist_voice.playing and scientist_voice.stream:
		scientist_voice.pitch_scale = 0.7 + randf_range(-0.03, 0.03)
		scientist_voice.play()
	
	if not is_inside_tree() or final_fade_started:
		typing = false
		return
	if generation != typing_generation:
		return
	
	var char_delay: float = TYPE_DELAY_DEFAULT
	
	if current_index == slides.size() - 1:
		var current_char = text[idx]
		if current_char == ".":
			char_delay = TYPE_DELAY_SLIDE7_DOT
		else:
			char_delay = TYPE_DELAY_SLIDE7
	
	await get_tree().create_timer(char_delay).timeout
	
	if not is_inside_tree() or not typing or final_fade_started:
		return
	if generation != typing_generation:
		return
	
	_type_text(text, idx + 1, generation)

func _target_time_for_slide_start(index: int) -> float:
	if index < 6:
		return (SLIDES_TOTAL_BEFORE_7 / 6.0) * float(index)
	else:
		return SLIDES_TOTAL_BEFORE_7

func _show_slide(index: int) -> void:
	if index >= slides.size() or final_fade_started:
		return
	
	typing = false
	typing_generation += 1
	var generation = typing_generation
	
	var slide = slides[index]
	
	is_fading = true
	var fade_out = create_tween()
	fade_out.tween_property(image_display, "modulate:a", 0.0, SLIDE_TRANSITION)
	fade_out.parallel().tween_property(text_label, "modulate:a", 0.0, SLIDE_TRANSITION)
	await fade_out.finished
	
	if final_fade_started:
		return
	if generation != typing_generation:
		return
	
	if slide["image"] != null:
		image_display.texture = slide["image"]
	
	if scientist_voice and scientist_voice.playing:
		scientist_voice.stop()
	
	text_label.text = ""
	_type_text(slide["text"], 0, generation)
	
	var fade_in = create_tween()
	fade_in.tween_property(image_display, "modulate:a", 1.0, SLIDE_TRANSITION)
	fade_in.parallel().tween_property(text_label, "modulate:a", 1.0, SLIDE_TRANSITION)
	await fade_in.finished
	is_fading = false
	
	if final_fade_started:
		return
	if generation != typing_generation:
		return
	
	_log_time("SLIDE " + str(index + 1) + " shown (target=" + "%.3f" % _target_time_for_slide_start(index) + ")")
	
	var next_target: float
	if index + 1 < slides.size():
		next_target = _target_time_for_slide_start(index + 1)
	else:
		next_target = FINAL_FADE_START_TIME
	
	var remaining = next_target - _now()
	if remaining < 0.05:
		remaining = 0.05
	
	slide_timer.wait_time = remaining
	slide_timer.start()

func _on_slide_timer_timeout() -> void:
	if is_fading or final_fade_started:
		return
	
	_log_time("SLIDE " + str(current_index + 1) + " finished")
	
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
	typing_generation += 1
	Global.intro_active = false
	
	_log_time("ALL SLIDES DONE, starting final fade")
	
	if scientist_voice and scientist_voice.playing:
		scientist_voice.stop()
	
	slide_timer.stop()
	
	if intro_music and intro_music.playing:
		var music_tween = create_tween()
		music_tween.tween_property(intro_music, "volume_db", MUSIC_SILENT_DB, FINAL_FADE_TIME)
		music_tween.finished.connect(func():
			if intro_music:
				intro_music.stop()
		)
	
	if not is_inside_tree():
		return
	
	var final_fade = create_tween()
	final_fade.set_parallel(true)
	final_fade.tween_property(image_display, "modulate:a", 0.0, FINAL_FADE_TIME)
	final_fade.tween_property(text_label, "modulate:a", 0.0, FINAL_FADE_TIME)
	await final_fade.finished
	
	_cleanup_menus()
	
	Global.intro_completed = true
	UISounds.start_factory_ambience()
	
	_own_fade_and_change_scene()

func _exit_tree() -> void:
	Global.intro_active = false
	if intro_music and intro_music.playing:
		intro_music.stop()
