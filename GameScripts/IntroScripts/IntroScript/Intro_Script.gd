extends CanvasLayer

var slides = [
	{"image": preload("res://GameAssets/Sprites/UserInterfaceSprites/IntroSlideSprites/Intro_Slide1_Texture.png"), "text": tr("Он держал в руке то, что изменит всё.")},
	{"image": preload("res://GameAssets/Sprites/UserInterfaceSprites/IntroSlideSprites/Intro_Slide2_Texture.png"), "text": tr("Первой подопытной стала крыса.")},
	{"image": preload("res://GameAssets/Sprites/UserInterfaceSprites/IntroSlideSprites/Intro_Slide3_Texture.png"), "text": tr("Она больше не чувствовала себя собой.")},
	{"image": preload("res://GameAssets/Sprites/UserInterfaceSprites/IntroSlideSprites/Intro_Slide4_Texture.png"), "text": tr("Со временем очередь дошла до всех.")},
	{"image": preload("res://GameAssets/Sprites/UserInterfaceSprites/IntroSlideSprites/Intro_Slide5_Texture.png"), "text": tr("Так появилась новая рабочая сила.")},
	{"image": preload("res://GameAssets/Sprites/UserInterfaceSprites/IntroSlideSprites/Intro_Slide6_Texture.png"), "text": tr("Чип взял на себя то, что раньше решал мозг.")},
	{"image": preload("res://GameAssets/Sprites/UserInterfaceSprites/IntroSlideSprites/Intro_Slide7_Texture.png"), "text": tr("Система казалась безупречной...")}
]

const MUSIC_PATH = "res://GameAssets/Audio/MusicTracks/IntroMusic/Intro_Music.mp3"
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

const PROGRESS_BG_PATH = "res://GameAssets/Sprites/UserInterfaceSprites/AquariumMenuUITextures/ProgressBarTextures/Menu_Aquarium_Progressbar_Empty_Texture.png"
const PROGRESS_FULL_PATH = "res://GameAssets/Sprites/UserInterfaceSprites/AquariumMenuUITextures/ProgressBarTextures/Menu_Aquarium_Progressbar_Fullness_Texture.png"

const SKIP_WIDTH: float = 140.0
const SKIP_HEIGHT: float = 8.0
const MAX_DIM_ALPHA: float = 1.0

const MUSIC_NORMAL_DB: float = -13.0
const MUSIC_SILENT_DB: float = -80.0
const VOICE_NORMAL_DB: float = -14.0
const VOICE_SILENT_DB: float = -80.0

const SLIDE_FONT_SIZE: int = 16
const SKIP_FONT_SIZE: int = 7

var current_index: int = 0
var bg: ColorRect
var image_display: TextureRect
var text_label: RichTextLabel
var _typed: String = ""
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
	
	custom_font = load("res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf")
	slide_font = custom_font.duplicate() if custom_font else null
	if slide_font:
		slide_font.fixed_size = SLIDE_FONT_SIZE
	
	scientist_voice = AudioStreamPlayer.new()
	var voice_path = "res://GameAssets/Audio/SoundEffects/NPCVoiceSounds/ScientistVoiceSounds/NPC_Scientist_Voiсe_SoundEffect.mp3"
	if ResourceLoader.exists(voice_path):
		scientist_voice.stream = load(voice_path)
	else:
		var fallback_path = "res://GameAssets/Audio/SoundEffects/NPCVoiceSounds/ScientistVoiceSounds/NPC_Scientist_Voiсe_SoundEffect.mp3"
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
	
	# the aquarium is loaded in the background while the slides play, so the change at the
	# end is instant (it used to freeze for a moment and the fade jumped)
	ResourceLoader.load_threaded_request(AQUARIUM_SCENE)
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
	if text_label and not text_label.has_theme_font_override("normal_font"):
		text_label.add_theme_font_override("normal_font", slide_font)
		text_label.add_theme_font_size_override("normal_font_size", SLIDE_FONT_SIZE)

func _input(_event: InputEvent) -> void:
	if final_fade_started:
		return
	_input_skip_hint(_event)
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
	image_display.pivot_offset = image_display.size * 0.5
	add_child(image_display)
	_setup_intro_fx(screen_size)
	
	# rich text: the letters tremble a little (an old, nervous projector)
	text_label = RichTextLabel.new()
	text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_label.bbcode_enabled = true
	text_label.scroll_active = false
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	text_label.offset_bottom = -200
	text_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	_enforce_label_font()
	
	text_label.add_theme_color_override("default_color", Color.WHITE)
	add_child(text_label)
	
	slide_timer = Timer.new()
	slide_timer.one_shot = true
	slide_timer.timeout.connect(_on_slide_timer_timeout)
	add_child(slide_timer)

func _setup_skip_ui(screen_size: Vector2) -> void:
	skip_dim = ColorRect.new()
	skip_dim.color = Color(0, 0, 0, 0)
	skip_dim.size = screen_size
	skip_dim.position = Vector2.ZERO
	skip_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_dim.z_index = 400
	add_child(skip_dim)
	_skip_ui = Control.new()
	_skip_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_ui.size = Vector2(300, 44)
	_skip_ui.position = Vector2(screen_size.x - 300 - 8, 8)   # top-right, where it always was
	_skip_ui.z_index = 500
	_skip_ui.modulate.a = 0.0
	_skip_ui.draw.connect(_draw_skip)
	add_child(_skip_ui)
	_skip_font = ResourceLoader.load("res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf", "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
	if _skip_font:
		_skip_font.fixed_size = 0

var _skip_ui: Control = null
var _skip_font: FontFile = null
var _skip_show: float = 0.0     # seconds the hint stays after the last mouse move / press

## Bottom-right: a ring fills around a little "ЛКМ" cap while the button is held, the text
## next to it says what will happen; it shows up on any mouse move or press and fades away.
func _draw_skip() -> void:
	var c = _skip_ui
	var sz = c.size
	var p = clamp(skip_progress / SKIP_HOLD_TIME, 0.0, 1.0)
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.55))
	var ctr = Vector2(26, sz.y * 0.5)
	c.draw_arc(ctr, 16.0, 0, TAU, 40, Color(1, 1, 1, 0.18), 3.0)
	if p > 0.0:
		c.draw_arc(ctr, 16.0, -PI * 0.5, -PI * 0.5 + TAU * p, 40, Color(1, 1, 1, 0.95), 3.0)
		c.draw_circle(ctr + Vector2(cos(-PI * 0.5 + TAU * p), sin(-PI * 0.5 + TAU * p)) * 16.0, 2.5, Color.WHITE)
	if _skip_font:
		var kc = Color(1, 1, 1, 0.9 if p > 0.0 else 0.75)
		var kw = _skip_font.get_string_size(tr("ЛКМ"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		c.draw_string(_skip_font, Vector2(ctr.x - kw * 0.5, ctr.y + 3.0), tr("ЛКМ"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, kc)
		var txt = tr("ПРОПУСКАЮ...") if p > 0.0 else tr("ЗАЖМИ — ПРОПУСТИТЬ")
		c.draw_string(_skip_font, Vector2(50, sz.y * 0.5 + 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.92))

func _input_skip_hint(_event: InputEvent) -> void:
	pass   # the hint shows only while the mouse button is held (and once at the start)

var _blink_t: float = 0.0   # time since the intro started: the hint is shown once at the start

func _process(delta: float) -> void:
	_enforce_label_font()
	_process_intro_fx()
	
	if final_fade_started:
		return
	
	var skip_input = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if skip_input:
		skip_progress += delta
		if skip_progress >= SKIP_HOLD_TIME:
			_skip_intro()
			return
	else:
		if skip_progress > 0.0:
			skip_progress = max(skip_progress - SKIP_RETRACT_SPEED * delta, 0.0)
	_blink_t += delta
	
	var progress = clamp(skip_progress / SKIP_HOLD_TIME, 0.0, 1.0)
	skip_dim.color = Color(0, 0, 0, progress * 0.6)
	if _skip_ui:
		# at the start it fades in, stays a moment and fades out; later it fades in while
		# the button is held and fades out after
		var target = 1.0 if (skip_input or progress > 0.0 or (_blink_t > 0.3 and _blink_t < 3.0)) else 0.0
		var speed = 2.5 if target > _skip_ui.modulate.a else 1.6
		_skip_ui.modulate.a = move_toward(_skip_ui.modulate.a, target, delta * speed)
		_skip_ui.queue_redraw()
	
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
	
	_cleanup_menus()
	
	_go_to_aquarium(0.45)

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
	_go_to_aquarium(FINAL_FADE_TIME)

const AQUARIUM_SCENE := "res://GameScenes/LevelScenes/ActPrologueLevelScenes/AquariumLevelScenes/AquariumMainLevelScene/ActPrologue_LevelAquarium_Scene.tscn"

## Overlay that outlives the intro: it waits until the aquarium has really drawn a few
## frames, then fades out at a steady pace (long frames from the change do not make it jump).
const _HANDOFF_SRC := """extends CanvasLayer
var _id := 0
var _frames := 0
var _a := 1.0
var go := false
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(delta):
	if not go:
		return
	var sc = get_tree().current_scene
	if sc == null or sc.get_instance_id() == _id:
		return
	_frames += 1
	if _frames < 6:
		return
	_a = max(0.0, _a - min(delta, 1.0 / 30.0) / 1.1)
	get_node("Black").color.a = _a * _a * (3.0 - 2.0 * _a)
	if _a <= 0.0:
		queue_free()
"""

func _go_to_aquarium(fade_time: float) -> void:
	var layer = CanvasLayer.new()
	layer.layer = 1100
	var src = GDScript.new()
	src.source_code = _HANDOFF_SRC
	if src.reload() == OK:
		layer.set_script(src)
	var black = ColorRect.new()
	black.name = "Black"
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	get_tree().root.add_child(layer)
	if layer.get_script():
		layer.set("_id", get_tree().current_scene.get_instance_id() if get_tree().current_scene else 0)
	# everything (picture, words, grain, music) goes down together under the black
	var tw = create_tween().set_parallel(true)
	tw.tween_property(black, "color:a", 1.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if intro_music and intro_music.playing:
		tw.tween_property(intro_music, "volume_db", MUSIC_SILENT_DB, fade_time)
	await tw.finished
	if intro_music:
		intro_music.stop()
	# the scene is (almost always) ready by now; if not, wait for it under the black
	var packed: PackedScene = null
	while true:
		var st = ResourceLoader.load_threaded_get_status(AQUARIUM_SCENE)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			packed = ResourceLoader.load_threaded_get(AQUARIUM_SCENE)
			break
		if st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			break
		await get_tree().process_frame
	_log_time("CHANGE SCENE -> Act1")
	if layer.get_script():
		layer.set("go", true)
	else:
		var t = black.create_tween()
		t.tween_interval(0.35)
		t.tween_property(black, "color:a", 0.0, 0.8)
		t.tween_callback(layer.queue_free)
	if packed:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(AQUARIUM_SCENE)

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
	_set_typed(_typed + text[idx])
	
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

func _set_typed(s: String) -> void:
	_typed = s
	if text_label:
		text_label.text = "[shake rate=7.0 level=3 connected=1]" + s.replace("[", "[lb]") + "[/shake]"

func _target_time_for_slide_start(index: int) -> float:
	if index < 6:
		return (SLIDES_TOTAL_BEFORE_7 / 6.0) * float(index)
	else:
		return SLIDES_TOTAL_BEFORE_7

## ---------------------------------------------------------------- intro effects
## Old-film look: every slide slowly pushes in (Ken Burns), a slide change comes with a short
## colour-split glitch, a soft vignette, flickering film grain, a thin frame around the
## picture and dust drifting in the projector light.
const IMAGE_FX := """
shader_type canvas_item;
uniform float split = 0.0;
uniform float flicker = 0.0;
void fragment() {
	vec2 off = vec2(0.006 * split, 0.0);
	vec4 c = texture(TEXTURE, UV);
	c.r = texture(TEXTURE, UV + off).r;
	c.b = texture(TEXTURE, UV - off).b;
	vec2 cc = UV - 0.5;
	c.rgb *= 1.0 - 0.45 * smoothstep(0.3, 0.75, length(cc));
	c.rgb *= 1.0 - flicker;
	COLOR = c * COLOR;
}
"""
const FILM_FX := """
shader_type canvas_item;
uniform float strength = 1.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 cc = UV - 0.5;
	float vig = smoothstep(0.35, 0.85, length(cc * vec2(1.2, 1.0)));
	vec2 gp = floor(FRAGCOORD.xy / 3.0);
	float g = h(gp + floor(TIME * 18.0) * 7.31);
	float a = vig * 0.75 + (g - 0.5) * 0.08;
	COLOR = vec4(vec3(0.0), clamp(a, 0.0, 1.0) * strength);
}
"""
var _img_mat: ShaderMaterial = null
var _kb_tw: Tween = null
var _frame: Control = null

func _setup_intro_fx(screen_size: Vector2) -> void:
	_img_mat = ShaderMaterial.new()
	var s1 = Shader.new()
	s1.code = IMAGE_FX
	_img_mat.shader = s1
	image_display.material = _img_mat
	image_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# (no frame around the picture and no film scratches any more - asked to remove them)
	# drifting dust in the projector light
	var dust = CPUParticles2D.new()
	var img = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	dust.texture = ImageTexture.create_from_image(img)
	dust.amount = 40
	dust.lifetime = 7.0
	dust.preprocess = 7.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = screen_size * 0.5
	dust.position = screen_size * 0.5
	dust.direction = Vector2(0.3, -1)
	dust.spread = 180.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 3.0
	dust.initial_velocity_max = 10.0
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.5, Color(1, 0.95, 0.85, 0.35))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	dust.color_ramp = g
	add_child(dust)
	# grain + vignette over everything (the skip bar is added later, stays on top)
	var film = ColorRect.new()
	film.mouse_filter = Control.MOUSE_FILTER_IGNORE
	film.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fm = ShaderMaterial.new()
	var s2 = Shader.new()
	s2.code = FILM_FX
	fm.shader = s2
	film.material = fm
	add_child(film)


func _process_intro_fx() -> void:
	if _img_mat:
		# projector flicker
		_img_mat.set_shader_parameter("flicker", 0.04 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 37.0)) * randf())
	if _frame:
		_frame.queue_redraw()


func _slide_fx() -> void:
	if image_display == null:
		return
	image_display.pivot_offset = image_display.size * 0.5
	if _kb_tw and _kb_tw.is_valid():
		_kb_tw.kill()
	image_display.scale = Vector2.ONE
	_kb_tw = create_tween().set_parallel(true)
	_kb_tw.tween_property(image_display, "scale", Vector2(1.07, 1.07), 4.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _img_mat:
		_img_mat.set_shader_parameter("split", 1.0)
		var g = create_tween()
		g.tween_method(func(v): _img_mat.set_shader_parameter("split", v), 1.0, 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


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
	_slide_fx()
	
	if scientist_voice and scientist_voice.playing:
		scientist_voice.stop()
	
	_set_typed("")
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
	# the film grain, vignette and dust go down together with the picture
	for c in get_children():
		if c is CanvasItem and c != image_display and c != text_label and c != bg and c != _skip_ui:
			final_fade.tween_property(c, "modulate:a", 0.0, FINAL_FADE_TIME)
	await final_fade.finished
	
	_cleanup_menus()
	
	Global.intro_completed = true
	UISounds.start_factory_ambience()
	
	_go_to_aquarium(0.3)

func _exit_tree() -> void:
	Global.intro_active = false
	if intro_music and intro_music.playing:
		intro_music.stop()
