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

var _font: FontFile
var intro_active: bool = false
var loading_instance: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var font_path = "res://Fish Slaves/Textures/Font/Font.ttf"
	
	if FileAccess.file_exists(font_path):
		_font = load(font_path)
		if _font:
			_font.fixed_size = 10
	
	reapply_theme()
	get_tree().tree_changed.connect(_on_scene_changed)

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

func _apply_font(node: Node) -> void:
	if not _font:
		return
	
	if not is_instance_valid(node):
		return
	
	for child in node.get_children():
		if not is_instance_valid(child):
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
	
	var loading_scene = load("res://Fish Slaves/Base/Scenes/Overlay/Transition/LoadingScreen.tscn")
	if loading_scene:
		loading_instance = loading_scene.instantiate()
		get_tree().root.add_child(loading_instance)
		
		if loading_instance and loading_instance.has_method("start_loading"):
			loading_instance.start_loading(scene_path)

func _cleanup_loading() -> void:
	if loading_instance and is_instance_valid(loading_instance):
		loading_instance.queue_free()
		loading_instance = null
