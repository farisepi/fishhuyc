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
	# Проверяем существует ли файл шрифта
	if FileAccess.file_exists("res://Textures/Font/Bitcell_Font.ttf"):
		var font_file = load("res://Textures/Font/Bitcell_Font.ttf")
		if font_file:
			var theme = Theme.new()
			var font = FontFile.new()
			# В Godot 4.6 FontFile напрямую использует данные шрифта
			theme.set_default_font(font)
			get_tree().root.theme = theme
	else:
		print("Шрифт не найден: res://Textures/Font/Bitcell_Font.ttf")
