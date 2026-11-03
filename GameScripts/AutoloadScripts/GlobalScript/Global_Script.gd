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
	config.save(save_path)
	last_save_level = max(1, get_level_number(scene_path))

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

func _apply_all_settings_from_config(apply_window: bool = true) -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
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
	
	var vsync_enabled = config.get_value("graphics", "vsync", true)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)
	
	var fullscreen = config.get_value("graphics", "fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	var resolution = config.get_value("graphics", "resolution", 0)
	match resolution:
		0: DisplayServer.window_set_size(Vector2i(1920, 1080))
		1: DisplayServer.window_set_size(Vector2i(1280, 720))
		2: DisplayServer.window_set_size(Vector2i(854, 480))
	
	if not fullscreen:
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var window_size: Vector2i = DisplayServer.window_get_size()
		DisplayServer.window_set_position(DisplayServer.screen_get_position() + (screen_size - window_size) / 2)

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
