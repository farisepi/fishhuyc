extends CanvasLayer

@onready var continue_btn: Button = $ContinueButton
@onready var settings_btn: Button = $SettingsButton
@onready var save_btn: Button = $SaveButton
@onready var exit_btn: Button = $ExitButton
@onready var restart_btn: Button = get_node_or_null("RestartButton")

var _bg_rect: ColorRect
var _framing: Sprite2D
var _buttons: Array[Button] = []
var _anim_tween: Tween
var _is_closing: bool = false
var _transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# above every in-game layer (HUD, arrows, hints), below the black scene transitions
	layer = 50
	
	_bg_rect = get_node_or_null("ColorRect")
	_framing = get_node_or_null("Framing")
	
	_buttons.clear()
	for child in get_children():
		if child is Button:
			_buttons.append(child)
	
	for btn in _buttons:
		ButtonEffects.setup(btn)
	
	# Сигналы уже подключены в .tscn — НЕ дублируем
	
	if _bg_rect:
		_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_bg_rect.offset_left = 0
		_bg_rect.offset_top = 0
		_bg_rect.offset_right = 0
		_bg_rect.offset_bottom = 0
		_bg_rect.modulate.a = 0.0
		_bg_rect.visible = true
		_bg_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if _framing:
		_framing.modulate.a = 0.0
	
	for btn in _buttons:
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.85, 0.85)
		btn.pivot_offset = btn.size / 2.0
	
	_build_fx()
	hide()

func show_menu() -> void:
	_is_closing = false
	show()
	# Принудительно растягиваем фон при каждом показе
	if _bg_rect:
		_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_bg_rect.offset_left = 0
		_bg_rect.offset_top = 0
		_bg_rect.offset_right = 0
		_bg_rect.offset_bottom = 0
		_bg_rect.modulate.a = 0.0
		_bg_rect.visible = true
	if _framing:
		_framing.modulate.a = 0.0
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.modulate = Color(1, 1, 1, 0)
			btn.scale = Vector2(0.85, 0.85)
			btn.pivot_offset = btn.size / 2.0
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			if btn.has_meta("fx_keep_alpha"):
				btn.remove_meta("fx_keep_alpha")
	_animate_in()

func _animate_in() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	
	_anim_tween = create_tween()
	_anim_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_anim_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	if _bg_rect:
		_anim_tween.tween_property(_bg_rect, "modulate:a", 1.0, 0.15)
	if _framing:
		_anim_tween.parallel().tween_property(_framing, "modulate:a", 1.0, 0.2)
	_fx_in()
	
	for i in range(_buttons.size()):
		var btn = _buttons[i]
		if not is_instance_valid(btn):
			continue
		_anim_tween.parallel().tween_property(btn, "modulate:a", 1.0, 0.15).set_delay(0.02 + i * 0.03)
		_anim_tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.2).set_delay(0.02 + i * 0.03).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_menu() -> void:
	if _is_closing:
		return
	_is_closing = true
	
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	
	_anim_tween = create_tween()
	_anim_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_anim_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	for btn in _buttons:
		if is_instance_valid(btn):
			# a hovered button runs its own colour loop (ButtonEffects) that kept it visible a
			# moment longer than the others: stop it, so all of them fade out together
			for m in ["color_tween", "glass_tween"]:
				if btn.has_meta(m):
					var t = btn.get_meta(m)
					if t is Tween and t.is_valid():
						t.kill()
			btn.set_meta("fx_keep_alpha", true)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.release_focus()
			_anim_tween.parallel().tween_property(btn, "modulate", Color(1, 1, 1, 0), 0.2)
			_anim_tween.parallel().tween_property(btn, "scale", Vector2(0.92, 0.92), 0.2)
	
	if _bg_rect:
		_anim_tween.parallel().tween_property(_bg_rect, "modulate:a", 0.0, 0.32)
	if _framing:
		# the rusty frame melts away softly (its shader keeps the node's alpha now)
		_anim_tween.parallel().tween_property(_framing, "modulate:a", 0.0, 0.34)
	_fx_out()
	
	await _anim_tween.finished
	hide()
	# Жёсткий сброс
	if _bg_rect:
		_bg_rect.modulate.a = 0.0
	if _framing:
		_framing.modulate.a = 0.0
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.modulate.a = 0.0
	_is_closing = false

## ---------------------------------------------------------------- pause effects
## Behind the menu the frozen game blurs and goes cold (shader on the screen), dust motes
## (factory) or bubbles (aquarium) drift through the frame, a big "ПАУЗА" title drops in and
## glows, a light line runs across it. The rusty frame does not breathe: a shader slides a
## glint over the metal now and then.
const BACKDROP_SHADER := "res://GameShaders/SharedShaders/Shared_PauseBackdrop_Shader.gdshader"
const RUST_SHADER := "res://GameShaders/SharedShaders/Shared_RustFrame_Shader.gdshader"
const FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
var _fx_rect: ColorRect = null
var _fx_mat: ShaderMaterial = null
var _fx_parts: CPUParticles2D = null
var _fx_title: Label = null
var _fx_line: ColorRect = null
var _fx_tw: Tween = null
var _fx_t: float = 0.0
var _framing_scale: Vector2 = Vector2.ONE

func _build_fx() -> void:
	var aqua = _in_aquarium()
	var accent = Color8(130, 210, 255) if aqua else Color8(255, 168, 60)
	if _framing:
		_framing_scale = _framing.scale
		# the rust shader is only for the factory's rusty frame; the aquarium frame stays as
		# it was drawn (and keeps its slow breathing)
		if not aqua and ResourceLoader.exists(RUST_SHADER):
			var fm = ShaderMaterial.new()
			fm.shader = load(RUST_SHADER)
			_framing.material = fm
	# backdrop
	var sh = load(BACKDROP_SHADER) if ResourceLoader.exists(BACKDROP_SHADER) else null
	if sh:
		_fx_rect = ColorRect.new()
		_fx_rect.name = "PauseBackdrop"
		_fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fx_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fx_mat = ShaderMaterial.new()
		_fx_mat.shader = sh
		_fx_mat.set_shader_parameter("tint", Color(0.45, 0.75, 1.0) if aqua else Color(1.0, 0.62, 0.25))
		_fx_mat.set_shader_parameter("amount", 0.0)
		_fx_rect.material = _fx_mat
		add_child(_fx_rect)
		move_child(_fx_rect, 0)   # under the dark overlay and the buttons
	# drifting motes / bubbles
	_fx_parts = CPUParticles2D.new()
	var img = Image.create(3 if aqua else 2, 3 if aqua else 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	if aqua:
		img.set_pixel(1, 1, Color(1, 1, 1, 0))
	_fx_parts.texture = ImageTexture.create_from_image(img)
	_fx_parts.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fx_parts.amount = 36
	_fx_parts.lifetime = 7.0
	_fx_parts.preprocess = 7.0
	_fx_parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_fx_parts.emission_rect_extents = Vector2(600, 20) if aqua else Vector2(600, 340)
	_fx_parts.position = Vector2(576, 680) if aqua else Vector2(576, 324)
	_fx_parts.direction = Vector2(0, -1) if aqua else Vector2(0.4, -1)
	_fx_parts.spread = 12.0 if aqua else 180.0
	_fx_parts.gravity = Vector2.ZERO
	_fx_parts.initial_velocity_min = 25.0 if aqua else 4.0
	_fx_parts.initial_velocity_max = 60.0 if aqua else 14.0
	_fx_parts.scale_amount_min = 1.0
	_fx_parts.scale_amount_max = 2.0 if aqua else 1.5
	var g = Gradient.new()
	g.set_color(0, Color(accent, 0.0))
	g.add_point(0.3, Color(accent.lerp(Color.WHITE, 0.5), 0.45))
	g.set_color(g.get_point_count() - 1, Color(accent, 0.0))
	_fx_parts.color_ramp = g
	_fx_parts.emitting = false
	add_child(_fx_parts)
	if _bg_rect:
		move_child(_fx_parts, _bg_rect.get_index() + 1)
	# title
	_fx_title = Label.new()
	_fx_title.text = "ПАУЗА"
	_fx_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f = ResourceLoader.load(FONT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
	if f:
		f.fixed_size = 0
		_fx_title.add_theme_font_override("font", f)
	_fx_title.add_theme_font_size_override("font_size", 40)
	_fx_title.add_theme_color_override("font_color", accent)
	_fx_title.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.05))
	_fx_title.add_theme_constant_override("outline_size", 8)
	_fx_title.add_theme_color_override("font_shadow_color", Color(accent, 0.35))
	_fx_title.add_theme_constant_override("shadow_offset_x", 0)
	_fx_title.add_theme_constant_override("shadow_offset_y", 0)
	_fx_title.add_theme_constant_override("shadow_outline_size", 22)
	_fx_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fx_title.size = Vector2(400, 56)
	_fx_title.position = Vector2(376, 108)
	_fx_title.pivot_offset = _fx_title.size * 0.5
	_fx_title.modulate.a = 0.0
	add_child(_fx_title)
	# a light line that runs across under the title
	_fx_line = ColorRect.new()
	_fx_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_line.color = Color(accent, 0.8)
	_fx_line.size = Vector2(0, 3)
	_fx_line.position = Vector2(576, 162)
	add_child(_fx_line)
	set_process(true)

func _fx_in() -> void:
	if _fx_tw and _fx_tw.is_valid():
		_fx_tw.kill()
	_fx_t = 0.0
	if _fx_parts:
		_fx_parts.emitting = true
		_fx_parts.restart()
	_fx_tw = create_tween().set_parallel(true)
	_fx_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if _fx_mat:
		_fx_tw.tween_method(func(v): _fx_mat.set_shader_parameter("amount", v), 0.0, 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _fx_title:
		_fx_title.modulate.a = 0.0
		_fx_title.position.y = 88
		_fx_title.scale = Vector2(1.25, 1.25)
		_fx_tw.tween_property(_fx_title, "modulate:a", 1.0, 0.2).set_delay(0.05)
		_fx_tw.tween_property(_fx_title, "position:y", 108.0, 0.35).set_delay(0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_fx_tw.tween_property(_fx_title, "scale", Vector2.ONE, 0.3).set_delay(0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _fx_line:
		_fx_line.size.x = 0.0
		_fx_line.position.x = 576.0
		_fx_line.modulate.a = 1.0
		_fx_tw.tween_property(_fx_line, "size:x", 220.0, 0.35).set_delay(0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_fx_tw.tween_property(_fx_line, "position:x", 466.0, 0.35).set_delay(0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _fx_out() -> void:
	if _fx_tw and _fx_tw.is_valid():
		_fx_tw.kill()
	if _fx_parts:
		_fx_parts.emitting = false
	_fx_tw = create_tween().set_parallel(true)
	_fx_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if _fx_mat:
		var from = float(_fx_mat.get_shader_parameter("amount"))
		_fx_tw.tween_method(func(v): _fx_mat.set_shader_parameter("amount", v), from, 0.0, 0.32)
	if _fx_title:
		_fx_tw.tween_property(_fx_title, "modulate:a", 0.0, 0.2)
	if _fx_line:
		_fx_tw.tween_property(_fx_line, "modulate:a", 0.0, 0.12)

func _process(delta: float) -> void:
	if not visible:
		return
	_fx_t += delta
	# the title glows and the frame slowly breathes
	if _fx_title and not _is_closing:
		var p = 0.5 + 0.5 * sin(_fx_t * 2.2)
		_fx_title.add_theme_constant_override("shadow_outline_size", int(16 + 10 * p))
	if _framing and not _is_closing and _in_aquarium():
		_framing.scale = _framing_scale * (1.0 + 0.004 * sin(_fx_t * 1.3))

func _input(event: InputEvent) -> void:
	# Opening the pause is the level's job (it knows about inspect mode, journal, death...).
	# While the menu is open the level is paused, so closing it with Esc is handled here.
	if not visible or _transitioning:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		var level = get_tree().current_scene
		if level and level.has_method("_toggle_pause"):
			level._toggle_pause()

func _is_factory_level() -> bool:
	var scene_path = get_tree().current_scene.scene_file_path
	return "Act2" in scene_path or "Act3" in scene_path or "Factory" in scene_path

func _transition_to(scene_path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	UISounds.stop_everything_gameplay()
	
	# Жёсткий сброс перед скрытием
	if _bg_rect:
		_bg_rect.modulate.a = 0.0
	if _framing:
		_framing.modulate.a = 0.0
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.modulate.a = 0.0
	hide()
	
	await get_tree().create_timer(0.05).timeout
	Global.goto_scene(scene_path)

func _on_continue_pressed() -> void:
	UISounds.play_click()
	GlobalMusic.restore_volume()
	UISounds.restore_ambience()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	var level = get_tree().current_scene
	if level and level.has_method("_resume_after_pause"):
		level._resume_after_pause()
	
	hide_menu()

func _on_save_pressed() -> void:
	if _transitioning:
		return
	UISounds.play_click()
	Global.came_from = Global.MenuSource.GAME
	Global.scene_to_save = get_tree().current_scene.scene_file_path
	Global.player_position = Vector2.ZERO
	if _in_aquarium():
		_transition_to("res://GameScenes/MenuScenes/AquariumMenuScenes/AquariumSavesMenuScene/Menu_Aquarium_SavesMenu_Scene.tscn")
	else:
		_transition_to("res://GameScenes/MenuScenes/FactoryMenuScenes/FactorySavesMenuScene/Menu_Factory_SavesMenu_Scene.tscn")

## The aquarium level uses this pause menu too, but with the aquarium look and menus.
func _in_aquarium() -> bool:
	var cur = ""
	if owner and owner.scene_file_path != "":
		cur = owner.scene_file_path
	elif get_tree().current_scene:
		cur = get_tree().current_scene.scene_file_path
	return Global.get_level_number(cur) == 1

func _on_settings_pressed() -> void:
	if _transitioning:
		return
	UISounds.play_click()
	Global.came_from = Global.MenuSource.GAME
	Global.scene_to_save = get_tree().current_scene.scene_file_path
	if _in_aquarium():
		_transition_to("res://GameScenes/MenuScenes/AquariumMenuScenes/AquariumSettingMenuScene/Menu_Aquarium_SettingMenu_Scene.tscn")
	else:
		_transition_to("res://GameScenes/MenuScenes/FactoryMenuScenes/FactorySettingMenuScene/Menu_Factory_SettingMenu_Scene.tscn")

func _on_exit_pressed() -> void:
	if _transitioning:
		return
	UISounds.play_click()
	# the aquarium belongs to the aquarium-styled menu, everything after it to the factory one
	var cur = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	if Global.get_level_number(cur) == 1:
		_transition_to(Global.SCENE_MAIN_MENU_AQUARIUM)
	else:
		_transition_to(Global.SCENE_MAIN_MENU_FACTORY)

func _on_restart_pressed() -> void:
	if _transitioning:
		return
	UISounds.play_click()
	_transitioning = true
	_load_last_save()

func _load_last_save() -> void:
	var save_dir = "user://saves/"
	if not DirAccess.dir_exists_absolute(save_dir):
		_restart_current_scene()
		return
	
	var dir = DirAccess.open(save_dir)
	if not dir:
		_restart_current_scene()
		return
	
	var latest_time = 0
	var latest_path = ""
	# prefer the slot the player is actually playing in
	var own_slot = save_dir + "save_" + str(Global.save_slot) + ".cfg"
	if FileAccess.file_exists(own_slot):
		latest_path = own_slot
		latest_time = 1 << 62
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("save_") and file_name.ends_with(".cfg"):
			var path = save_dir + file_name
			var t = FileAccess.get_modified_time(path)
			if t > latest_time:
				latest_time = t
				latest_path = path
		file_name = dir.get_next()
	dir.list_dir_end()
	
	if latest_path == "":
		_restart_current_scene()
		return
	
	var config = ConfigFile.new()
	if config.load(latest_path) != OK:
		_restart_current_scene()
		return
	
	var scene = config.get_value("save", "scene", "")
	var px = config.get_value("save", "player_x", 0.0)
	var py = config.get_value("save", "player_y", 0.0)
	
	if scene == "":
		_restart_current_scene()
		return
	
	Global.player_position = Vector2(px, py)
	Global.read_factory_state(config)
	Global.chatter_queue_state = config.get_value("save", "chatter_queue", [])
	Global.chatter_current_text = config.get_value("save", "chatter_text", "")
	Global.chatter_char_index = config.get_value("save", "chatter_index", 0)
	
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Global.goto_scene(scene)

func _restart_current_scene() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var current = get_tree().current_scene.scene_file_path
	Global.goto_scene(current)
