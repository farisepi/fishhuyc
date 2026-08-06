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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func apply_font(scene: Node) -> void:
	var font_path = "res://Textures/Font/Bitcell_Font.ttf"
	
	if not FileAccess.file_exists(font_path):
		return
	
	var font: FontFile = load(font_path)
	if not font:
		return
	
	font.fixed_size = 10
	
	if scene is Control:
		var theme = Theme.new()
		theme.set_default_font(font)
		theme.set_font("font", "Label", font)
		theme.set_font_size("font_size", "Label", 10)
		theme.set_font("font", "Button", font)
		theme.set_font_size("font_size", "Button", 10)
		theme.set_font("normal_font", "RichTextLabel", font)
		theme.set_font_size("normal_font_size", "RichTextLabel", 10)
		scene.theme = theme
	else:
		_apply_font_to_children(scene, font)

func _apply_font_to_children(node: Node, font: FontFile) -> void:
	for child in node.get_children():
		if child is Label:
			child.add_theme_font_override("font", font)
			child.add_theme_font_size_override("font_size", 10)
		elif child is Button:
			child.add_theme_font_override("font", font)
			child.add_theme_font_size_override("font_size", 10)
		elif child is RichTextLabel:
			child.add_theme_font_override("normal_font", font)
			child.add_theme_font_size_override("normal_font_size", 10)
		_apply_font_to_children(child, font)
