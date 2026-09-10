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
var show_fps: bool = false
var pending_save: bool = false
var scene_to_save: String = ""

# НАСТРОЙКИ ЭФФЕКТОВ
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# СОЗДАЕМ SEAWEEDSTATE С ПРАВИЛЬНЫМ ПУТЕМ
	print("=== CREATING SEAWEEDSTATE ===")
	var seaweed_path = "res://Fish Slaves/Base/Scripts/Managers/MainMenuButtonAttributesState.gd"
	if FileAccess.file_exists(seaweed_path):
		seaweed_state = load(seaweed_path).new()
		add_child(seaweed_state)
		seaweed_state.name = "SeaweedState"
		print("SeaweedState created from: ", seaweed_path)
	else:
		print("ERROR: SeaweedState not found at: ", seaweed_path)
		var alt_path = "res://Fish Slaves/Base/Scripts/Managers/MainMenuButtonAttributesState.gd"
		if FileAccess.file_exists(alt_path):
			seaweed_state = load(alt_path).new()
			add_child(seaweed_state)
			seaweed_state.name = "SeaweedState"
			print("SeaweedState created from alt path: ", alt_path)
	
	var font_path = "res://Fish Slaves/Textures/Font/Font.ttf"
	
	if FileAccess.file_exists(font_path):
		_font = load(font_path)
		if _font:
			_font.fixed_size = 10
	
	# ЗАГРУЖАЕМ НАСТРОЙКИ ЭФФЕКТОВ И АТРИБУТОВ
	_load_effect_settings()
	
	reapply_theme()
	get_tree().tree_changed.connect(_on_scene_changed)
	
	_detect_last_save_level()

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
					var level = 1
					if "Act2" in scene or "Level_2" in scene:
						level = 2
					elif "Act3" in scene or "chase_level" in scene or "Level_3" in scene:
						level = 3
					
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

func _on_scene_changed() -> void:
	if intro_active:
		return
	
	if not _font:
		return
	if not is_inside_tree():
		return
	
	var tree = get_tree()
	if not tree:
		return
	
	await tree.process_frame
	
	if intro_active:
		return
	
	reapply_theme()
	
	var scene = tree.current_scene
	if scene:
		_apply_font(scene)
		
		# Если есть ожидающее применение - применяем
		if _pending_seaweed_apply:
			_pending_seaweed_apply = false
			_force_apply_seaweed(scene)
		else:
			# Иначе применяем с задержкой
			_apply_seaweed_with_delay(scene)
		
		# ПРИМЕНЯЕМ НАСТРОЙКИ ЭФФЕКТОВ И АТРИБУТОВ К НОВОЙ СЦЕНЕ
		_apply_effect_settings_to_scene(scene)

func _apply_effect_settings_to_scene(scene: Node) -> void:
	if not scene or not is_instance_valid(scene):
		return
	
	# Если атмосферные эффекты выключены - удаляем все пузыри
	if not atmospheric_effects_enabled:
		_remove_all_bubbles_recursive(scene)
	
	# Если атрибуты интерфейса выключены - скрываем водоросли/ржавчину
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
		print("Сцена не в дереве, пропускаем")
		return
	
	_force_apply_seaweed(scene)

func _force_apply_seaweed(scene: Node) -> void:
	print("=== FORCE APPLY SEAWEED to: ", scene.name if scene else "null")
	
	if not scene or not is_instance_valid(scene):
		return
	
	if not has_node("SeaweedState"):
		print("ERROR: SeaweedState not found! Creating new one...")
		var seaweed_path = "res://Fish Slaves/Base/Scripts/Managers/MainMenuButtonAttributesState.gd"
		if FileAccess.file_exists(seaweed_path):
			seaweed_state = load(seaweed_path).new()
			add_child(seaweed_state)
			seaweed_state.name = "SeaweedState"
			print("SeaweedState recreated!")
		else:
			print("ERROR: Cannot find SeaweedState file!")
			return
	
	var seaweed_state_node = get_node("SeaweedState")
	
	var found_count = 0
	_find_all_decorations(scene, found_count)
	print("Found decorations (Seaweed/Rust): ", found_count)
	
	seaweed_state_node.scan_and_apply(scene)
	
	_force_show_decorations(scene)
	
	print("=== FORCE APPLY FINISHED ===")

func _find_all_decorations(node: Node, found: Variant) -> void:
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
			if decoration:
				found += 1
				print("Found decoration: ", child.name, " -> ", decoration.name)
		_find_all_decorations(child, found)

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
		
		if child is Label:
			child.add_theme_font_override("font", _font)
			child.add_theme_font_size_override("font_size", 10)
		elif child is Button:
			child.add_theme_font_override("font", _font)
			child.add_theme_font_size_override("font_size", 10)
		elif child is RichTextLabel:
			child.add_theme_font_override("normal_font", _font)
			child.add_theme_font_size_override("normal_font_size", 10)
		
		_apply_font(child)

func goto_scene(scene_path: String) -> void:
	_cleanup_loading()
	
	_pending_seaweed_apply = true
	
	var loading_scene = load("res://Fish Slaves/Base/Scenes/Overlay/Transition/LoadingScreen.tscn")
	if loading_scene:
		loading_instance = loading_scene.instantiate()
		get_tree().root.add_child(loading_instance)
		
		if loading_instance and loading_instance.has_method("start_loading"):
			if loading_instance.has_signal("scene_loaded"):
				if loading_instance.scene_loaded.is_connected(_on_scene_loaded):
					loading_instance.scene_loaded.disconnect(_on_scene_loaded)
				loading_instance.scene_loaded.connect(_on_scene_loaded)
			loading_instance.start_loading(scene_path)

func _on_scene_loaded() -> void:
	print("=== SCENE LOADED SIGNAL ===")
	var scene = get_tree().current_scene
	if scene:
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		_force_apply_seaweed(scene)
		_apply_effect_settings_to_scene(scene)

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
		print("Seaweed states reset")
