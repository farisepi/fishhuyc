extends Node

var save_slot: int = 0
var is_new_game: bool = false
var intro_completed: bool = false
var prologue1_completed: bool = false
var prologue2_completed: bool = false

enum MenuSource { MAIN_MENU, GAME }

var came_from: MenuSource = MenuSource.MAIN_MENU
var just_returned_from_settings: bool = false
var player_position: Vector2 = Vector2.ZERO
var camera_position: Vector2 = Vector2.ZERO
var chatter_queue_state: Array = []
var chatter_current_text: String = ""
var chatter_char_index: int = 0
var camera_sensitivity: float = 0.0
var prologue_completed: bool = false
var bubbles_popped: int = 0
var boxes_thrown: int = 0
var show_fps: bool = false
var pending_save: bool = false
var scene_to_save: String = ""

var atmospheric_effects_enabled: bool = true
var interface_attributes_enabled: bool = true
var button_effects_enabled: bool = true

var _font: FontFile
var _font_free: FontFile = null
var intro_active: bool = false
var loading_instance: CanvasLayer = null

var last_save_level: int = 1
var enemy_positions: Dictionary = {}

var seaweed_state: Node = null
var _pending_seaweed_apply: bool = false
var _scene_change_pending: bool = false

var shards_blue: int = 0
var shards_green: int = 0
var shards_cyan: int = 0

signal shards_changed(blue: int, green: int, cyan: int)

const SCENE_AQUARIUM := "res://GameScenes/LevelScenes/ActPrologueLevelScenes/AquariumLevelScenes/AquariumMainLevelScene/ActPrologue_LevelAquarium_Scene.tscn"
const SCENE_FACTORY := "res://GameScenes/LevelScenes/ActPrologueLevelScenes/FactoryLevelScenes/FactoryMainLevelScene/ActPrologue_LevelFactory_Scene.tscn"
const SCENE_HALLWAY := "res://GameScenes/LevelScenes/ActPrologueLevelScenes/HallwayLevelScenes/HallwayMainLevelScene/ActPrologue_LevelHallway_Scene.tscn"
const SCENE_STORAGE := "res://GameScenes/LevelScenes/ActStorageLevelScenes/NearFactoryLevelScenes/NearFactoryLevelMainScene/ActStorage_LevelNearFactory_Scene.tscn"
const SCENE_MAIN_MENU_FACTORY := "res://GameScenes/MenuScenes/FactoryMenuScenes/FactoryMainMenuScene/Menu_Factory_MainMenu_Scene.tscn"
const SCENE_MAIN_MENU_AQUARIUM := "res://GameScenes/MenuScenes/AquariumMenuScenes/AquariumMainMenuScene/Menu_Aquarium_MainMenu_Scene.tscn"

var _brightness_layer: ColorRect = null
var _last_scene_id: int = 0

func get_level_number(scene_path: String) -> int:
	if scene_path.contains("LevelAquarium") or scene_path.contains("Act1") or scene_path.contains("Level_1"):
		return 1
	if scene_path.contains("LevelFactory") or scene_path.contains("Act2") or scene_path.contains("Level_2"):
		return 2
	if scene_path.contains("LevelHallway") or scene_path.contains("Act3") or scene_path.contains("chase_level") or scene_path.contains("Level_3"):
		return 3
	if scene_path.contains("ActStorage") or scene_path.contains("Storage"):
		return 4
	return 0

func get_location_name(scene_path: String) -> String:
	match get_level_number(scene_path):
		1: return tr("Аквариум")
		2: return tr("Завод")
		3: return tr("Коридор к складовым помещениям")
		4: return tr("Склад")
	return scene_path.get_file().get_basename()

func format_save_time() -> String:
	var d = Time.get_datetime_dict_from_system()
	return "%02d.%02d.%s %02d:%02d" % [d.day, d.month, str(d.year).substr(2, 2), d.hour, d.minute]

var factory_state: Dictionary = {}
var storage_state: Dictionary = {}

func write_factory_state(config: ConfigFile) -> void:
	config.set_value("factory", "state", factory_state)
	config.set_value("storage", "state", storage_state)

func read_factory_state(config: ConfigFile) -> void:
	var st = config.get_value("factory", "state", {})
	factory_state = st.duplicate(true) if st is Dictionary else {}
	var ss = config.get_value("storage", "state", {})
	storage_state = ss.duplicate(true) if ss is Dictionary else {}

func save_factory_state() -> void:
	var save_path = "user://saves/save_" + str(save_slot) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) != OK:
		return
	write_factory_state(config)
	config.save(save_path)

func reset_factory_progress() -> void:
	var keep := {}
	for k in ["tut", "accident_seen"]:
		if factory_state.has(k):
			keep[k] = factory_state[k]
	factory_state = keep

func get_save_title(config: ConfigFile) -> String:
	var scene = config.get_value("save", "scene", "???")
	var t = get_location_name(scene)
	if get_level_number(scene) == 2:
		var st = config.get_value("factory", "state", {})
		var sh = int(st.get("shift", 1)) if st is Dictionary else 1
		t += " - " + str(max(1, sh)) + tr(" Смена")
	return t

var _save_icon_layer: CanvasLayer = null
const SAVE_ICON := preload("res://GameScripts/UIScripts/SaveIconScripts/Save_Icon.gd")

func show_save_icon(time: float = 1.8) -> void:
	if _save_icon_layer and is_instance_valid(_save_icon_layer):
		_save_icon_layer.set_meta("until", Time.get_ticks_msec() + int(time * 1000.0))
		return
	var layer = CanvasLayer.new()
	layer.layer = 120
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.set_meta("until", Time.get_ticks_msec() + int(time * 1000.0))
	get_tree().root.add_child(layer)
	_save_icon_layer = layer
	var icon = SAVE_ICON.new()
	layer.add_child(icon)
	var vp = Vector2(BASE_SIZE)
	icon.position = vp - icon.size - Vector2(18, 16)
	icon.modulate.a = 0.0
	var tw = icon.create_tween()
	tw.tween_property(icon, "modulate:a", 1.0, 0.25)
	while is_instance_valid(layer) and Time.get_ticks_msec() < int(layer.get_meta("until")):
		await get_tree().process_frame
	if not is_instance_valid(layer):
		return
	var tw2 = icon.create_tween()
	tw2.tween_property(icon, "modulate:a", 0.0, 0.35)
	await tw2.finished
	if is_instance_valid(layer):
		layer.queue_free()
	_save_icon_layer = null

func autosave(scene_path: String, player_pos: Vector2 = Vector2.ZERO) -> void:
	DirAccess.make_dir_absolute("user://saves/")
	var save_path = "user://saves/save_" + str(save_slot) + ".cfg"
	var config = ConfigFile.new()
	config.load(save_path)
	config.set_value("save", "scene", scene_path)
	config.set_value("save", "time", format_save_time())
	config.set_value("save", "player_x", player_pos.x)
	config.set_value("save", "player_y", player_pos.y)
	config.set_value("shards", "blue", shards_blue)
	config.set_value("shards", "green", shards_green)
	config.set_value("shards", "cyan", shards_cyan)
	write_factory_state(config)
	config.save(save_path)
	last_save_level = max(1, get_level_number(scene_path))
	show_save_icon()

func ensure_brightness_layer() -> ColorRect:
	if _brightness_layer and is_instance_valid(_brightness_layer):
		return _brightness_layer
	var existing = get_tree().root.get_node_or_null("BrightnessCanvas")
	if existing and existing.get_child_count() > 0:
		_brightness_layer = existing.get_child(0) as ColorRect
		return _brightness_layer
	var canvas = CanvasLayer.new()
	canvas.name = "BrightnessCanvas"
	canvas.layer = 100
	_brightness_layer = ColorRect.new()
	_brightness_layer.name = "BrightnessLayer"
	_brightness_layer.color = Color(0, 0, 0, 0)
	_brightness_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brightness_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_brightness_layer.visible = false
	canvas.add_child(_brightness_layer)
	get_tree().root.add_child.call_deferred(canvas)
	return _brightness_layer

const CJK_FONTS := {
	"zh_CN": "res://GameAssets/Fonts/CJKFont/FontFiles/CJK_ZH_CN_Font.otf",
	"ja": "res://GameAssets/Fonts/CJKFont/FontFiles/CJK_JA_Font.otf",
	"ko": "res://GameAssets/Fonts/CJKFont/FontFiles/CJK_KO_Font.otf",
}
var _cjk_loaded: Dictionary = {}
const CJK_SCALE := 1.22
const CJK_EXTRA_ADVANCE := 3

func _apply_cjk_fallbacks() -> void:
	if _font == null:
		return
	var loc = TranslationServer.get_locale()
	var order: Array = ["zh_CN", "ja", "ko"]
	for code in order.duplicate():
		if loc.begins_with(code.substr(0, 2)):
			order.erase(code)
			order.push_front(code)
	var fb: Array[Font] = []
	for code in order:
		if not _cjk_loaded.has(code) and ResourceLoader.exists(CJK_FONTS[code]):
			var v = FontVariation.new()
			v.base_font = load(CJK_FONTS[code])
			v.variation_transform = Transform2D().scaled(Vector2(CJK_SCALE, CJK_SCALE))
			v.spacing_glyph = CJK_EXTRA_ADVANCE
			_cjk_loaded[code] = v
		if _cjk_loaded.has(code):
			fb.append(_cjk_loaded[code])
	_font.fallbacks = fb
	if _font_free:
		_font_free.fallbacks = fb

func fit_label(l: Label, base_size: int, min_size: int = 7, width: float = -1.0) -> void:
	if l == null or not is_instance_valid(l):
		return
	var room_w: float = width if width > 0.0 else l.size.x
	var f: Font = l.get_theme_font("font")
	if f == null:
		return
	var txt = l.tr(l.text) if l.auto_translate_mode != Node.AUTO_TRANSLATE_MODE_DISABLED else l.text
	if f == _font or (l.has_meta("fit_swapped") and _font_free):
		var ow = l.get_theme_constant("outline_size")
		var fits: bool
		if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
			fits = _font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, room_w, 10).y <= l.size.y + 1.0
		else:
			fits = _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + ow <= room_w + 1.0
		if fits or _font_free == null:
			if l.has_meta("fit_swapped"):
				l.add_theme_font_override("font", _font)
				l.remove_meta("fit_swapped")
			return
		l.add_theme_font_override("font", _font_free)
		l.set_meta("fit_swapped", true)
		f = _font_free
		base_size = min(base_size, 10)
	var outline = l.get_theme_constant("outline_size")
	var wrap = l.autowrap_mode != TextServer.AUTOWRAP_OFF
	var s = base_size
	while s > min_size:
		if wrap:
			var h = f.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, room_w, s).y
			if h <= l.size.y + 1.0:
				break
		else:
			var w = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x + outline
			if w <= room_w + 1.0:
				break
		s -= 1
	l.add_theme_font_size_override("font_size", s)

func unify_labels(labels: Array) -> void:
	var min_sz := 999
	var any_swapped := false
	for l in labels:
		if l == null or not is_instance_valid(l) or not l.visible:
			continue
		if l.has_meta("fit_swapped"):
			any_swapped = true
			min_sz = min(min_sz, l.get_theme_font_size("font_size"))
	if not any_swapped or _font_free == null:
		return
	for l in labels:
		if l == null or not is_instance_valid(l):
			continue
		l.add_theme_font_override("font", _font_free)
		l.set_meta("fit_swapped", true)
		l.add_theme_font_size_override("font_size", min_sz)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_apply_cjk_fallbacks()
		if is_inside_tree() and get_tree().current_scene:
			_fit_texts_later(get_tree().current_scene)

func apply_brightness(value: float) -> void:
	var layer = ensure_brightness_layer()
	var alpha = lerp(0.75, 0.0, clamp(value, 0.0, 1.0))
	layer.color = Color(0, 0, 0, alpha)
	layer.visible = alpha > 0.001

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	preload("res://GameScripts/AutoloadScripts/LocalizationScript/Localization_EN.gd").install()
	setup_scaling()

	var seaweed_path = "res://GameScripts/MenuScripts/MainMenuScripts/MainMenuButtonsAttributesStateScript/Menu_MainMenu_ButtonsAttributesState_Script.gd"
	if ResourceLoader.exists(seaweed_path):
		seaweed_state = load(seaweed_path).new()
		add_child(seaweed_state)
		seaweed_state.name = "SeaweedState"

	var font_path = "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"

	if ResourceLoader.exists(font_path):
		_font = load(font_path)
		if _font:
			_font.fixed_size = 10
		_font_free = ResourceLoader.load(font_path, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
		if _font_free:
			_font_free.fixed_size = 0
	_apply_cjk_fallbacks()

	_load_effect_settings()
	_apply_all_settings_from_config()

	reapply_theme()
	get_tree().tree_changed.connect(_on_scene_changed)

	get_tree().root.physics_object_picking = true
	get_tree().root.physics_object_picking_sort = true
	get_tree().root.physics_object_picking_first_only = true
	get_tree().node_added.connect(_on_node_added)

	var bcfg = ConfigFile.new()
	if bcfg.load("user://settings.cfg") == OK:
		apply_brightness(bcfg.get_value("graphics", "brightness", 1.0))

	_detect_last_save_level()
	load_shards_from_slot()

const BASE_SIZE := Vector2i(1152, 648)
const RES_CANDIDATES: Array[Vector2i] = [
	Vector2i(3840, 2160), Vector2i(3200, 1800), Vector2i(2560, 1440), Vector2i(2304, 1296),
	Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1366, 768), Vector2i(1280, 720),
	Vector2i(1152, 648), Vector2i(1024, 576), Vector2i(854, 480)]
const OLD_RESOLUTIONS: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(854, 480)]
var RESOLUTIONS: Array[Vector2i] = []

func get_resolutions() -> Array[Vector2i]:
	var scr := _screen_size()
	var out: Array[Vector2i] = []
	for r in RES_CANDIDATES:
		if scr.x <= 0 or (r.x <= scr.x and r.y <= scr.y):
			out.append(r)
	if out.is_empty():
		out.append(Vector2i(854, 480))
	RESOLUTIONS = out
	return out

func resolution_names() -> Array[String]:
	var out: Array[String] = []
	var scr := _screen_size()
	for r in get_resolutions():
		out.append("%dx%d%s" % [r.x, r.y, " ★" if r == scr else ""])
	return out

func saved_resolution_index(config: ConfigFile) -> int:
	var list = get_resolutions()
	var want := Vector2i.ZERO
	var s = String(config.get_value("graphics", "resolution_size", ""))
	if "x" in s:
		want = Vector2i(int(s.get_slice("x", 0)), int(s.get_slice("x", 1)))
	elif config.has_section_key("graphics", "resolution"):
		want = OLD_RESOLUTIONS[clampi(int(config.get_value("graphics", "resolution", 0)), 0, OLD_RESOLUTIONS.size() - 1)]
	return _closest_resolution(want, list)

func _closest_resolution(want: Vector2i, list: Array[Vector2i]) -> int:
	if want == Vector2i.ZERO:
		var us := _usable_size()
		for i in range(list.size()):
			if list[i].x <= us.x * 0.96 and list[i].y <= us.y * 0.92:
				return i
		return list.size() - 1
	var best := 0
	var best_d := INF
	for i in range(list.size()):
		var d = abs(list[i].x - want.x) + abs(list[i].y - want.y)
		if d < best_d:
			best_d = d
			best = i
	return best

func resolution_size_text(index: int) -> String:
	var list = RESOLUTIONS if not RESOLUTIONS.is_empty() else get_resolutions()
	var r = list[clampi(index, 0, list.size() - 1)]
	return "%dx%d" % [r.x, r.y]

func _screen_size() -> Vector2i:
	var w = get_window()
	return DisplayServer.screen_get_size(w.current_screen if w else -1)

func _usable_size() -> Vector2i:
	var w = get_window()
	var u = DisplayServer.screen_get_usable_rect(w.current_screen if w else -1).size
	return u if u.x > 0 else _screen_size()

func screen_hz() -> float:
	var w = get_window()
	var hz = DisplayServer.screen_get_refresh_rate(w.current_screen if w else -1)
	return hz if hz > 1.0 else 60.0

var vsync_on: bool = true
var fps_limit: int = 0

func apply_frame_pacing() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_on else DisplayServer.VSYNC_DISABLED)
	var hz = int(round(screen_hz()))
	if fps_limit > 0:
		Engine.max_fps = fps_limit if (not vsync_on or fps_limit < hz) else 0
	elif fps_limit < 0:
		Engine.max_fps = 0
	else:
		Engine.max_fps = 0 if vsync_on else hz

func set_vsync(on: bool) -> void:
	vsync_on = on
	apply_frame_pacing()

func is_fullscreen() -> bool:
	var w = get_window()
	return w != null and (w.mode == Window.MODE_FULLSCREEN or w.mode == Window.MODE_EXCLUSIVE_FULLSCREEN)

func set_fullscreen(on: bool, res_index: int = -1) -> void:
	var w = get_window()
	if w == null:
		return
	if on:
		if not is_fullscreen():
			w.borderless = false
			w.mode = Window.MODE_FULLSCREEN
	else:
		if w.mode != Window.MODE_WINDOWED:
			w.mode = Window.MODE_WINDOWED
			w.borderless = false
			await get_tree().process_frame
			await get_tree().process_frame
		if res_index < 0:
			var cfg = ConfigFile.new()
			cfg.load("user://settings.cfg")
			res_index = saved_resolution_index(cfg)
		apply_resolution(res_index)
	apply_frame_pacing()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			get_viewport().set_input_as_handled()
			var on = not is_fullscreen()
			set_fullscreen(on)
			var cfg = ConfigFile.new()
			cfg.load("user://settings.cfg")
			cfg.set_value("graphics", "fullscreen", on)
			cfg.save("user://settings.cfg")
			fullscreen_changed.emit(on)

signal fullscreen_changed(on: bool)

var _hz_check_t: float = 0.0
var _last_screen: int = -1
func _process(delta: float) -> void:
	_hz_check_t += delta
	if _hz_check_t < 1.0:
		return
	_hz_check_t = 0.0
	var w = get_window()
	if w and w.current_screen != _last_screen:
		_last_screen = w.current_screen
		apply_frame_pacing()

func setup_scaling() -> void:
	var w = get_window()
	if w == null:
		return
	w.content_scale_size = BASE_SIZE
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	w.min_size = Vector2i(640, 360)


func apply_resolution(index: int) -> void:
	var w = get_window()
	if w == null:
		return
	if w.mode == Window.MODE_FULLSCREEN or w.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		return
	if w.mode != Window.MODE_WINDOWED:
		w.mode = Window.MODE_WINDOWED
	var list = get_resolutions()
	var want: Vector2i = list[clampi(index, 0, list.size() - 1)]
	var usable: Vector2i = DisplayServer.screen_get_usable_rect(w.current_screen).size
	if usable.x > 0 and usable.y > 0:
		var k = min(1.0, min(float(usable.x) * 0.96 / want.x, float(usable.y) * 0.92 / want.y))
		if k < 1.0:
			want = Vector2i(int(want.x * k), int(want.y * k))
	if w.size != want:
		w.size = want
		w.move_to_center()


func _apply_all_settings_from_config(apply_window: bool = true) -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		if apply_window:
			if is_dev_run():
				_apply_dev_window()
			else:
				apply_resolution(_closest_resolution(Vector2i.ZERO, get_resolutions()))
			apply_frame_pacing()
		return

	_apply_audio_bus("Master", config.get_value("audio", "master_volume", 1.0))
	_apply_audio_bus("Music", config.get_value("audio", "music_volume", 1.0))
	_apply_audio_bus("SFX", config.get_value("audio", "sfx_volume", 1.0))
	_apply_audio_bus("Ambience", config.get_value("audio", "ambience_volume", 1.0))
	_apply_audio_bus("UI", config.get_value("audio", "ui_volume", 1.0))

	var locale_early = config.get_value("language", "locale", "ru")
	TranslationServer.set_locale(locale_early)
	camera_sensitivity = config.get_value("camera", "sensitivity", 0.0)
	atmospheric_effects_enabled = config.get_value("graphics", "effects", true)
	interface_attributes_enabled = config.get_value("graphics", "interface_attributes", true)
	button_effects_enabled = interface_attributes_enabled
	show_fps = config.get_value("graphics", "show_fps", false)
	if not apply_window:
		return

	vsync_on = bool(config.get_value("graphics", "vsync", true))
	fps_limit = int(config.get_value("graphics", "fps_limit", 0))
	apply_frame_pacing()

	var fullscreen = config.get_value("graphics", "fullscreen", false)
	if is_dev_run():
		_apply_dev_window()
		return
	set_fullscreen(bool(fullscreen), saved_resolution_index(config))


func is_dev_run() -> bool:
	return OS.has_feature("editor") or OS.has_feature("editor_runtime") or OS.is_debug_build()


func _apply_dev_window() -> void:
	var w = get_window()
	if w == null:
		return
	if w.mode != Window.MODE_WINDOWED:
		w.mode = Window.MODE_WINDOWED
	w.borderless = false
	var want = Vector2i(1280, 720)
	var usable: Vector2i = DisplayServer.screen_get_usable_rect(w.current_screen).size
	if usable.x > 0 and usable.y > 0:
		var k = min(1.0, min(float(usable.x) * 0.9 / want.x, float(usable.y) * 0.85 / want.y))
		want = Vector2i(int(want.x * k), int(want.y * k))
	w.size = want
	w.move_to_center()

func _apply_audio_bus(bus_name: String, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	if value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		return
	else:
		AudioServer.set_bus_mute(bus_index, false)

	var db: float
	if value < 0.01:
		db = -60.0
	else:
		db = linear_to_db(value)

	AudioServer.set_bus_volume_db(bus_index, db)

func _load_effect_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		atmospheric_effects_enabled = config.get_value("graphics", "effects", true)
		interface_attributes_enabled = config.get_value("graphics", "interface_attributes", true)
		button_effects_enabled = interface_attributes_enabled

func _detect_last_save_level() -> void:
	last_save_level = 1
	var save_dir = "user://saves/"
	if not DirAccess.dir_exists_absolute(save_dir):
		return

	var dir = DirAccess.open(save_dir)
	if not dir:
		return

	var latest_time = 0

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("save_") and file_name.ends_with(".cfg"):
			var path = save_dir + file_name
			var config = ConfigFile.new()
			if config.load(path) == OK:
				var scene = config.get_value("save", "scene", "")

				if scene != "":
					var level = max(1, get_level_number(scene))

					var file_time = FileAccess.get_modified_time(path)
					if file_time > latest_time:
						latest_time = file_time
						last_save_level = level
		file_name = dir.get_next()
	dir.list_dir_end()

func reapply_theme() -> void:
	if not _font:
		return
	if intro_active:
		return

	var theme = Theme.new()
	theme.set_default_font(_font)
	get_tree().root.theme = theme

func _on_node_added(node: Node) -> void:
	if intro_active or not _font:
		return
	if node is Label or node is Button or node is RichTextLabel:
		_apply_font_to(node)

func _on_scene_changed() -> void:
	if intro_active:
		return

	if not _font:
		return
	if not is_inside_tree():
		return
	if _scene_change_pending:
		return
	var cs = get_tree().current_scene
	if cs == null or cs.get_instance_id() == _last_scene_id:
		return

	_scene_change_pending = true

	var tree = get_tree()
	if not tree:
		_scene_change_pending = false
		return

	await tree.process_frame

	_scene_change_pending = false

	if intro_active:
		return
	if not is_inside_tree():
		return

	reapply_theme()

	var scene = tree.current_scene
	if scene:
		_last_scene_id = scene.get_instance_id()
		_apply_font(scene)

		if _pending_seaweed_apply:
			_pending_seaweed_apply = false
			_force_apply_seaweed(scene)
		else:
			_apply_seaweed_with_delay(scene)

		_apply_effect_settings_to_scene(scene)
		_fit_texts_later(scene)

func _fit_texts_later(scene: Node) -> void:
	for i in 3:
		await get_tree().process_frame
	if is_instance_valid(scene) and scene.is_inside_tree():
		fit_buttons(scene)

func continue_children(n: Node) -> void:
	fit_buttons(n)

func fit_buttons(n: Node) -> void:
	for c in n.get_children():
		if c is Button and not (c is CheckBox or c is CheckButton) and c.text.strip_edges() != "" and c.is_visible_in_tree():
			var f: Font = c.get_theme_font("font")
			if f == _font and _font_free:
				var t0 = c.tr(c.text) if c.auto_translate_mode != Node.AUTO_TRANSLATE_MODE_DISABLED else c.text
				var room0 = (c.custom_minimum_size.x if c.custom_minimum_size.x > 0.0 else c.size.x) - 14.0
				if _font.get_string_size(t0, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x > room0:
					c.add_theme_font_override("font", _font_free)
					c.set_meta("fit_swapped", true)
					c.set_meta("fit_base", 10)
					f = _font_free
				else:
					continue_children(c)
					continue
			if f:
				if not c.has_meta("fit_base"):
					c.set_meta("fit_base", c.get_theme_font_size("font_size"))
				var base: int = c.get_meta("fit_base")
				var txt = c.tr(c.text) if c.auto_translate_mode != Node.AUTO_TRANSLATE_MODE_DISABLED else c.text
				var room = (c.custom_minimum_size.x if c.custom_minimum_size.x > 0.0 else c.size.x) - 14.0
				var sz = base
				while sz > 7 and f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > room:
					sz -= 1
				if sz != c.get_theme_font_size("font_size"):
					c.add_theme_font_size_override("font_size", sz)
		fit_buttons(c)

func _apply_effect_settings_to_scene(scene: Node) -> void:
	if not scene or not is_instance_valid(scene):
		return

	if not atmospheric_effects_enabled:
		_remove_all_bubbles_recursive(scene)

	if not interface_attributes_enabled:
		_hide_all_decorations_recursive(scene, true)

func _remove_all_bubbles_recursive(node: Node) -> void:
	if not node or not is_instance_valid(node):
		return

	for child in node.get_children():
		if not child or not is_instance_valid(child):
			continue

		if child.name.to_lower().contains("bubble"):
			child.queue_free()
		else:
			_remove_all_bubbles_recursive(child)

func _hide_all_decorations_recursive(node: Node, hide: bool) -> void:
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
			_hide_all_decorations_recursive(child, hide)

func _apply_seaweed_with_delay(scene: Node) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	if not is_instance_valid(scene):
		return

	if not scene.is_inside_tree():
		return

	_force_apply_seaweed(scene)

func _force_apply_seaweed(scene: Node) -> void:
	if not scene or not is_instance_valid(scene):
		return
	if not scene.is_inside_tree():
		return

	if not has_node("SeaweedState"):
		var seaweed_path = "res://GameScripts/MenuScripts/MainMenuScripts/MainMenuButtonsAttributesStateScript/Menu_MainMenu_ButtonsAttributesState_Script.gd"
		if ResourceLoader.exists(seaweed_path):
			seaweed_state = load(seaweed_path).new()
			add_child(seaweed_state)
			seaweed_state.name = "SeaweedState"
		else:
			return

	var seaweed_state_node = get_node("SeaweedState")
	if not is_instance_valid(seaweed_state_node):
		return
	seaweed_state_node.scan_and_apply(scene)
	_force_show_decorations(scene)

func _force_show_decorations(node: Node) -> void:
	if not node or not is_instance_valid(node):
		return
	if not interface_attributes_enabled:
		_hide_all_decorations_recursive(node, true)

func _apply_font(node: Node) -> void:
	if not _font:
		return

	if not is_instance_valid(node):
		return

	if not node.is_inside_tree():
		return

	for child in node.get_children():
		if not is_instance_valid(child):
			continue

		if not child.is_inside_tree():
			continue

		if child is Label or child is Button or child is RichTextLabel:
			_apply_font_to(child)

		_apply_font(child)

func _apply_font_to(c: Control) -> void:
	if c is RichTextLabel:
		if not c.has_theme_font_override("normal_font"):
			c.add_theme_font_override("normal_font", _font)
		if not c.has_theme_font_size_override("normal_font_size"):
			c.add_theme_font_size_override("normal_font_size", 10)
		return
	if not c.has_theme_font_override("font"):
		c.add_theme_font_override("font", _font)
	if not c.has_theme_font_size_override("font_size"):
		c.add_theme_font_size_override("font_size", 10)


func goto_scene(scene_path: String) -> void:
	_cleanup_loading()
	_pending_seaweed_apply = true


	if is_instance_valid(Fade) and Fade.has_method("fade_out"):
		await Fade.fade_out()

	get_tree().change_scene_to_file(scene_path)

	await get_tree().process_frame
	await get_tree().process_frame

	if is_instance_valid(Fade) and Fade.has_method("fade_in"):
		Fade.fade_in()

	for child in get_tree().root.get_children():
		if child == get_tree().current_scene:
			continue
		if child is CanvasLayer and child.name == "Loading":
			child.queue_free()


func _on_scene_loaded() -> void:
	var tree = get_tree()
	if not tree:
		return
	var scene = tree.current_scene
	if scene:
		await tree.process_frame
		await tree.process_frame
		if not is_instance_valid(scene):
			return
		if not scene.is_inside_tree():
			return
		_force_apply_seaweed(scene)
		_apply_effect_settings_to_scene(scene)
		call_deferred("_apply_all_settings_from_config", false)

func _cleanup_loading() -> void:
	if loading_instance and is_instance_valid(loading_instance):
		if loading_instance.has_signal("scene_loaded"):
			if loading_instance.scene_loaded.is_connected(_on_scene_loaded):
				loading_instance.scene_loaded.disconnect(_on_scene_loaded)
		loading_instance.queue_free()
		loading_instance = null

func reset_seaweed() -> void:
	if has_node("SeaweedState"):
		get_node("SeaweedState").reset()


func add_shard(color: String, amount: int = 1) -> void:
	match color:
		"blue": shards_blue += amount
		"green": shards_green += amount
		"cyan": shards_cyan += amount
		_: return
	shards_changed.emit(shards_blue, shards_green, shards_cyan)
	save_shards_to_slot()

func get_shards(color: String) -> int:
	match color:
		"blue": return shards_blue
		"green": return shards_green
		"cyan": return shards_cyan
	return 0

func get_total_shards() -> int:
	return shards_blue + shards_green + shards_cyan

func save_shards_to_slot() -> void:
	var save_path = "user://saves/save_" + str(save_slot) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) != OK:
		return
	config.set_value("shards", "blue", shards_blue)
	config.set_value("shards", "green", shards_green)
	config.set_value("shards", "cyan", shards_cyan)
	config.save(save_path)

func load_shards_from_slot() -> void:
	var save_path = "user://saves/save_" + str(save_slot) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) != OK:
		shards_blue = 0
		shards_green = 0
		shards_cyan = 0
		return
	shards_blue = config.get_value("shards", "blue", 0)
	shards_green = config.get_value("shards", "green", 0)
	shards_cyan = config.get_value("shards", "cyan", 0)
