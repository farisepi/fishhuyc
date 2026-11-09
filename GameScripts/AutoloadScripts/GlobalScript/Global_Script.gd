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
var intro_active: bool = false
var loading_instance: CanvasLayer = null

var last_save_level: int = 1
var enemy_positions: Dictionary = {}

var seaweed_state: Node = null
var _pending_seaweed_apply: bool = false
var _scene_change_pending: bool = false

# === SHARDS ===
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

## 1 = aquarium, 2 = factory, 3 = hallway, 4 = storage (0 = unknown)
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
		1: return "Аквариум"
		2: return "Завод"
		3: return "Коридор к складовым помещениям"
		4: return "Склад"
	return scene_path.get_file().get_basename()

func format_save_time() -> String:
	var d = Time.get_datetime_dict_from_system()
	return "%02d.%02d.%s %02d:%02d" % [d.day, d.month, str(d.year).substr(2, 2), d.hour, d.minute]

## Factory progress of this save: the shift to start from, what was found out, which tutorial
## parts were done ("tut"), stations worked at ("stations"), the accident seen, ...
var factory_state: Dictionary = {}

func write_factory_state(config: ConfigFile) -> void:
	config.set_value("factory", "state", factory_state)

func read_factory_state(config: ConfigFile) -> void:
	var st = config.get_value("factory", "state", {})
	factory_state = st.duplicate(true) if st is Dictionary else {}

## Saves only the factory part (tutorial flags etc.) into the active slot right away.
func save_factory_state() -> void:
	var save_path = "user://saves/save_" + str(save_slot) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) != OK:
		return
	write_factory_state(config)
	config.save(save_path)

## A new run through the factory (from the aquarium): the shift progress starts over, what
## the player already learned (tutorial, seen accident) stays.
func reset_factory_progress() -> void:
	var keep := {}
	for k in ["tut", "accident_seen"]:
		if factory_state.has(k):
			keep[k] = factory_state[k]
	factory_state = keep

## "Завод - 2 Смена" for the save slots.
func get_save_title(config: ConfigFile) -> String:
	var scene = config.get_value("save", "scene", "???")
	var t = get_location_name(scene)
	if get_level_number(scene) == 2:
		var st = config.get_value("factory", "state", {})
		var sh = int(st.get("shift", 1)) if st is Dictionary else 1
		t += " - " + str(max(1, sh)) + " Смена"
	return t

## The saving sign in the bottom-right corner (do not close the game while it is on).
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

## Writes the current progress into the active save slot (creates the file if needed).
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

## One brightness overlay for the whole game (settings menus reuse it).
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

func apply_brightness(value: float) -> void:
	var layer = ensure_brightness_layer()
	var alpha = lerp(0.75, 0.0, clamp(value, 0.0, 1.0))
	layer.color = Color(0, 0, 0, alpha)
	layer.visible = alpha > 0.001

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_scaling()
	
	print("=== CREATING SEAWEEDSTATE ===")
	var seaweed_path = "res://GameScripts/MenuScripts/MainMenuScripts/MainMenuButtonsAttributesStateScript/Menu_MainMenu_ButtonsAttributesState_Script.gd"
	if FileAccess.file_exists(seaweed_path):
		seaweed_state = load(seaweed_path).new()
		add_child(seaweed_state)
		seaweed_state.name = "SeaweedState"
		print("SeaweedState created from: ", seaweed_path)
	
	var font_path = "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
	
	if FileAccess.file_exists(font_path):
		_font = load(font_path)
		if _font:
			_font.fixed_size = 10
	
	_load_effect_settings()
	_apply_all_settings_from_config()
	
	reapply_theme()
	get_tree().tree_changed.connect(_on_scene_changed)
	
	# Area2D.input_event (clickable boxes and bubbles in menus) only works with physics picking
	get_tree().root.physics_object_picking = true
	get_tree().root.physics_object_picking_sort = true
	get_tree().root.physics_object_picking_first_only = true
	get_tree().node_added.connect(_on_node_added)
	
	var bcfg = ConfigFile.new()
	if bcfg.load("user://settings.cfg") == OK:
		apply_brightness(bcfg.get_value("graphics", "brightness", 1.0))
	
	_detect_last_save_level()
	load_shards_from_slot()

# =============================================================================
# Window / UI scaling
# =============================================================================
## The whole game (world, HUD, menus) is laid out for 1152x648 and scaled to the window:
## every window size and fullscreen look the same, only bigger or smaller; other aspect
## ratios get black bars instead of a stretched or cut interface.
const BASE_SIZE := Vector2i(1152, 648)
## All window sizes the game knows; only the ones that fit the screen are offered.
const RES_CANDIDATES: Array[Vector2i] = [
	Vector2i(3840, 2160), Vector2i(3200, 1800), Vector2i(2560, 1440), Vector2i(2304, 1296),
	Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1366, 768), Vector2i(1280, 720),
	Vector2i(1152, 648), Vector2i(1024, 576), Vector2i(854, 480)]
## the old fixed list (configs saved before used an index into it)
const OLD_RESOLUTIONS: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(854, 480)]
var RESOLUTIONS: Array[Vector2i] = []

## The sizes for the current screen, biggest first (at least one).
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

## The index (in get_resolutions()) of the size saved in the settings.
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
		# nothing saved: the biggest one that leaves room for the taskbar
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

## The refresh rate of the screen the window is on (60 if unknown).
func screen_hz() -> float:
	var w = get_window()
	var hz = DisplayServer.screen_get_refresh_rate(w.current_screen if w else -1)
	return hz if hz > 1.0 else 60.0

var vsync_on: bool = true
## frame-rate limit from the settings: 0 = the monitor's Hz, -1 = none, else that many FPS
var fps_limit: int = 0

## VSync on: frames follow the screen. VSync off: capped at the screen's own Hz (no
## wasted frames above what the monitor can show, no stutter from a wrong fixed cap).
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

## Fullscreen on the screen the window is on (borderless, the screen's own size and Hz).
## Off: back to a normal window of the chosen size, centred.
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
			# the OS needs a frame or two to leave fullscreen before the size sticks
			await get_tree().process_frame
			await get_tree().process_frame
		if res_index < 0:
			var cfg = ConfigFile.new()
			cfg.load("user://settings.cfg")
			res_index = saved_resolution_index(cfg)
		apply_resolution(res_index)
	apply_frame_pacing()

## F11 / Alt+Enter: switch fullscreen anywhere and remember it.
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

## The window moved to another monitor: follow its refresh rate.
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


## Sets the window size from the settings index; a size bigger than the screen is shrunk
## (keeping 16:9) so the window never goes off screen. Always centred.
func apply_resolution(index: int) -> void:
	var w = get_window()
	if w == null:
		return
	if w.mode == Window.MODE_FULLSCREEN or w.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		return
	if w.mode != Window.MODE_WINDOWED:
		w.mode = Window.MODE_WINDOWED   # maximized / minimized: a real window first
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
		# no settings yet: still a window that fits the screen (the bottom of the HUD used to
		# go under the taskbar with the 1920x1080 window on a 1080p screen)
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
	# started from the Godot editor (F5 / F6, debug run): always a normal window
	if is_dev_run():
		_apply_dev_window()
		return
	set_fullscreen(bool(fullscreen), saved_resolution_index(config))


## The game was started from the editor (or is a debug build): no fullscreen, ever.
func is_dev_run() -> bool:
	return OS.has_feature("editor") or OS.has_feature("editor_runtime") or OS.is_debug_build()


## A 1280 x 720 window in the middle of the screen (smaller if the screen is small).
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
	# tree_changed fires for every added/removed node; only react when the scene itself changed
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
		if FileAccess.file_exists(seaweed_path):
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

func _find_decoration_in_node(node: Node) -> Node:
	if not node or not is_instance_valid(node):
		return null
	
	if not node.is_inside_tree():
		return null
	
	for child in node.get_children():
		if not child or not is_instance_valid(child):
			continue
		
		if not child.is_inside_tree():
			continue
		
		if child.name == "Seaweed" or child.name == "Rust":
			return child
	return null

func _force_show_decorations(node: Node) -> void:
	if not node or not is_instance_valid(node):
		return
	
	if not node.is_inside_tree():
		return
	
	for child in node.get_children():
		if not child or not is_instance_valid(child):
			continue
		
		if not child.is_inside_tree():
			continue
		
		if child is Button:
			var decoration = _find_decoration_in_node(child)
			if decoration and decoration.is_inside_tree():
				var path = str(child.get_path())
				var seaweed_state_node = get_node("SeaweedState")
				
				if seaweed_state_node.states.has(path):
					var data = seaweed_state_node.states[path]
					decoration.visible = data["visible"] and interface_attributes_enabled
					
					var original_scale = data.get("scale", Vector2.ONE)
					if data.get("flip", false):
						decoration.scale.x = -abs(original_scale.x)
						decoration.scale.y = abs(original_scale.y)
					else:
						decoration.scale.x = abs(original_scale.x)
						decoration.scale.y = abs(original_scale.y)
					
					if decoration.name == "Rust" and decoration is Sprite2D:
						var tex_data = data.get("texture_data", {})
						if tex_data.has("path") and tex_data["path"] != "":
							var texture = load(tex_data["path"])
							if texture:
								decoration.texture = texture
				else:
					var visible = randf() < 0.25
					var flip = randf() < 0.5
					
					var texture_path = ""
					if decoration is Sprite2D and decoration.texture:
						texture_path = decoration.texture.resource_path
					
					seaweed_state_node.states[path] = {
						"visible": visible,
						"flip": flip,
						"texture_data": {"path": texture_path} if texture_path != "" else {},
						"type": decoration.name,
						"scale": decoration.scale
					}
					
					decoration.visible = visible and interface_attributes_enabled
					if flip:
						decoration.scale.x = -abs(decoration.scale.x)
					else:
						decoration.scale.x = abs(decoration.scale.x)
		
		_force_show_decorations(child)

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

## Pixel font everywhere, default size 10 — but never overwrite a size set in the scene or by code.
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
	
	print(">>> goto_scene: ", scene_path)
	
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
	
	print(">>> сцена сменилась")

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

# === SHARD FUNCTIONS ===

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
