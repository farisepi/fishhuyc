extends Node

signal keybinds_updated

var action_names = {
	"ui_up": "Вверх",
	"ui_down": "Вниз",
	"ui_left": "Влево",
	"ui_right": "Вправо",
	"interact": "Взаимодействие",
	"jump": "Прыжок",
	"inventory": "Инвентарь",
	"ui_cancel": "Пауза"
}

var rebinding_action: String = ""
var rebind_delay: float = 0.0
var config = ConfigFile.new()
const SAVE_PATH = "user://keybinds.cfg"

const TEXTURE_NORMAL_PATH = "res://Textures/Interface/Keyboard/Normal/"
const TEXTURE_PRESSED_PATH = "res://Textures/Interface/Keyboard/Pressed/"

func _ready() -> void:
	load_keybinds()

func _process(delta: float) -> void:
	if rebind_delay > 0:
		rebind_delay -= delta

func get_key_text(action: String) -> String:
	var events = InputMap.action_get_events(action)
	for e in events:
		if e is InputEventKey:
			return _keycode_to_string(e.keycode)
		if e is InputEventMouseButton:
			return e.as_text()
	return "Не назначено"

# Функция получения текстуры клавиши
# Проверяет существование файла .tres и .png
func get_key_texture(action: String) -> Texture2D:
	var events = InputMap.action_get_events(action)
	for e in events:
		if e is InputEventKey:
			var key_string = _keycode_to_string(e.keycode)
			var tres_path = TEXTURE_NORMAL_PATH + key_string + ".tres"
			var png_path = TEXTURE_NORMAL_PATH + key_string + ".png"
			
			print("Ищу текстуру для: ", key_string)
			print("  Проверяю: ", tres_path, " -> ", ResourceLoader.exists(tres_path))
			print("  Проверяю: ", png_path, " -> ", ResourceLoader.exists(png_path))
			
			if ResourceLoader.exists(tres_path):
				return load(tres_path)
			elif ResourceLoader.exists(png_path):
				return load(png_path)
			else:
				print("Текстура не найдена: ", key_string)
	return null

func get_key_texture_pressed(action: String) -> Texture2D:
	var events = InputMap.action_get_events(action)
	for e in events:
		if e is InputEventKey:
			var key_string = _keycode_to_string(e.keycode)
			var tres_path = TEXTURE_PRESSED_PATH + key_string + "_p.tres"
			var png_path = TEXTURE_PRESSED_PATH + key_string + "_p.png"
			
			if ResourceLoader.exists(tres_path):
				return load(tres_path)
			elif ResourceLoader.exists(png_path):
				return load(png_path)
			else:
				print("Текстура нажатия не найдена: ", key_string)
	return null

func _keycode_to_string(keycode: Key) -> String:
	match keycode:
		KEY_TAB: return "tab"
		KEY_ENTER: return "enter"
		KEY_ESCAPE: return "esc"
		KEY_SPACE: return "space"
		KEY_BACKSPACE: return "backspace"
		KEY_SHIFT: return "shift"
		KEY_CTRL: return "ctrl"
		KEY_ALT: return "alt"
		_: return OS.get_keycode_string(keycode).to_lower()

func start_rebind(action: String) -> void:
	print("start_rebind called with action: ", action)
	rebinding_action = action
	rebind_delay = 0.2

func _input(event: InputEvent) -> void:
	if rebinding_action.is_empty():
		return
	
	if event is InputEventKey and event.pressed:
		if rebind_delay > 0:
			return
		
		_clear_action(rebinding_action)
		var new_event = InputEventKey.new()
		new_event.keycode = event.keycode
		InputMap.action_add_event(rebinding_action, new_event)
		rebinding_action = ""
		save_keybinds()
		keybinds_updated.emit()
		get_viewport().set_input_as_handled()

func _clear_action(action: String) -> void:
	var events = InputMap.action_get_events(action).duplicate()
	for e in events:
		if e is InputEventKey:
			InputMap.action_erase_event(action, e)

func save_keybinds() -> void:
	for action in action_names.keys():
		var events = InputMap.action_get_events(action)
		var key_texts = []
		for e in events:
			if e is InputEventKey:
				key_texts.append(_keycode_to_string(e.keycode))
		config.set_value("keybinds", action, key_texts)
	config.save(SAVE_PATH)
	keybinds_updated.emit()

func load_keybinds() -> void:
	if config.load(SAVE_PATH) != OK:
		return
	
	for action in action_names.keys():
		var key_texts = config.get_value("keybinds", action, [])
		if key_texts.is_empty():
			continue
		
		_clear_action(action)
		
		for key_text in key_texts:
			var key = _string_to_keycode(key_text)
			if key != KEY_NONE:
				var key_event = InputEventKey.new()
				key_event.keycode = key
				InputMap.action_add_event(action, key_event)
	keybinds_updated.emit()

func _string_to_keycode(text: String) -> Key:
	match text:
		"tab": return KEY_TAB
		"enter": return KEY_ENTER
		"esc": return KEY_ESCAPE
		"space": return KEY_SPACE
		"backspace": return KEY_BACKSPACE
		"shift": return KEY_SHIFT
		"ctrl": return KEY_CTRL
		"alt": return KEY_ALT
		_: return OS.find_keycode_from_string(text)
