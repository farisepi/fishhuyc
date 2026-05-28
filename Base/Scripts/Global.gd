extends Node

# ============================================
# НОВЫЕ ФЛАГИ ДЛЯ СИСТЕМЫ ВСТУПЛЕНИЯ
# ============================================

var save_slot: int = 0
var is_new_game: bool = false
var intro_completed: bool = false
var prologue1_completed: bool = false
var prologue2_completed: bool = false

# ============================================
# СУЩЕСТВУЮЩИЕ ПЕРЕМЕННЫЕ (НЕ ТРОГАЙ)
# ============================================

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

func _ready() -> void:
	var theme = load("res://Textures/Font/Font_Settings.tres")
	get_tree().root.theme = theme
