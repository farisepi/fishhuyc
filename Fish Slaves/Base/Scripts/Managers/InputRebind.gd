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
	"ui_cancel": "Пауза",
	"parry": "Парирование",
}

var rebinding_action: String = ""
var rebind_delay: float = 0.0
var config = ConfigFile.new()
const SAVE_PATH = "user://keybinds.cfg"

const TEXTURE_NORMAL_PATH = "res://Fish Slaves/Textures/Interface/KeyboardKeys/KeyboardKeysNormal/"
const TEXTURE_PRESSED_PATH = "res://Fish Slaves/Textures/Interface/KeyboardKeys/KeyboardKeysPressed/"

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

func get_key_texture(action: String) -> Texture2D:
	var events = InputMap.action_get_events(action)
	for e in events:
		if e is InputEventKey:
			var key_string = _keycode_to_string(e.keycode)
			var tres_path = TEXTURE_NORMAL_PATH + key_string + "KeyboardKeyNormal.tres"
			var png_path = TEXTURE_NORMAL_PATH + key_string + "KeyboardKeyNormal.png"
			
			if ResourceLoader.exists(tres_path):
				return load(tres_path)
			elif ResourceLoader.exists(png_path):
				return load(png_path)
	return null

func get_key_texture_pressed(action: String) -> Texture2D:
	var events = InputMap.action_get_events(action)
	for e in events:
		if e is InputEventKey:
			var key_string = _keycode_to_string(e.keycode)
			var tres_path = TEXTURE_PRESSED_PATH + key_string + "KeyboardKeyPressed.tres"
			var png_path = TEXTURE_PRESSED_PATH + key_string + "KeyboardKeyPressed.png"
			
			if ResourceLoader.exists(tres_path):
				return load(tres_path)
			elif ResourceLoader.exists(png_path):
				return load(png_path)
	return null

func _keycode_to_string(keycode: Key) -> String:
	match keycode:
		KEY_TAB: return "Tab"
		KEY_ENTER: return "Enter"
		KEY_ESCAPE: return "Esc"
		KEY_SPACE: return "Space"
		KEY_BACKSPACE: return "BackSpace"
		KEY_SHIFT: return "Shift"
		KEY_CTRL: return "Ctrl"
		KEY_ALT: return "Alt"
		KEY_UP: return "ArrowUp"
		KEY_DOWN: return "ArrowDown"
		KEY_LEFT: return "ArrowLeft"
		KEY_RIGHT: return "ArrowRight"
		_:
			var result = OS.get_keycode_string(keycode).to_lower()
			match result:
				"й": return "Q"
				"ц": return "W"
				"у": return "E"
				"к": return "R"
				"е": return "T"
				"н": return "Y"
				"г": return "U"
				"ш": return "I"
				"щ": return "O"
				"з": return "P"
				"х": return "["
				"ъ": return "]"
				"ф": return "A"
				"ы": return "S"
				"в": return "D"
				"а": return "F"
				"п": return "G"
				"р": return "H"
				"о": return "J"
				"л": return "K"
				"д": return "L"
				"ж": return ";"
				"э": return "'"
				"я": return "Z"
				"ч": return "X"
				"с": return "C"
				"м": return "V"
				"и": return "B"
				"т": return "N"
				"ь": return "M"
				"б": return ","
				"ю": return "."
				_: return result

func start_rebind(action: String) -> void:
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
		"Tab": return KEY_TAB
		"Enter": return KEY_ENTER
		"Esc": return KEY_ESCAPE
		"Space": return KEY_SPACE
		"BackSpace": return KEY_BACKSPACE
		"Shift": return KEY_SHIFT
		"Ctrl": return KEY_CTRL
		"Alt": return KEY_ALT
		"ArrowUp": return KEY_UP
		"ArrowDown": return KEY_DOWN
		"ArrowLeft": return KEY_LEFT
		"ArrowRight": return KEY_RIGHT
		_:
			var result = OS.find_keycode_from_string(text)
			if result != KEY_NONE:
				return result
			var ru_map = {
				"Q": "й", "W": "ц", "E": "у", "R": "к", "T": "е",
				"Y": "н", "U": "г", "I": "ш", "O": "щ", "P": "з",
				"A": "ф", "S": "ы", "D": "в", "F": "а", "G": "п",
				"H": "р", "J": "о", "K": "л", "L": "д",
				"Z": "я", "X": "ч", "C": "с", "V": "м", "B": "и",
				"N": "т", "M": "ь"
			}
			var lower_text = text.to_lower()
			for en in ru_map:
				if ru_map[en] == lower_text:
					return OS.find_keycode_from_string(en)
			return KEY_NONE
