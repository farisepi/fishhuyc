extends Node

signal keybinds_updated

var action_names = {
	"ui_up": tr("Вверх"),
	"ui_down": tr("Вниз"),
	"ui_left": tr("Влево"),
	"ui_right": tr("Вправо"),
	"interact": tr("Взаимодействие"),
	"jump": tr("Прыжок"),
	"inventory": tr("Инвентарь"),
	"ui_cancel": tr("Пауза"),
	"parry": tr("Парирование"),
	"inspect": tr("Осмотреться"),
	"journal": tr("Журнал"),
	"dash": tr("Рывок"),
	"block": tr("Блок"),
}

var rebinding_action: String = ""
var rebind_delay: float = 0.0
var config = ConfigFile.new()
const SAVE_PATH = "user://keybinds.cfg"

const TEXTURE_NORMAL_PATH = "res://Fish Slaves/Textures/Interface/KeyboardKeys/KeyboardKeysNormal/"
const TEXTURE_PRESSED_PATH = "res://Fish Slaves/Textures/Interface/KeyboardKeys/KeyboardKeysPressed/"

func _ready() -> void:
	_ensure_default_actions()
	load_keybinds()

func _ensure_default_actions() -> void:
	if not InputMap.has_action("inspect"):
		InputMap.add_action("inspect")
		var ev = InputEventKey.new()
		ev.keycode = KEY_I
		InputMap.action_add_event("inspect", ev)
	if not InputMap.has_action("journal"):
		InputMap.add_action("journal")
		var ev2 = InputEventKey.new()
		ev2.keycode = KEY_J
		InputMap.action_add_event("journal", ev2)

	for pair in [["dash", KEY_SHIFT], ["block", KEY_F]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
		if InputMap.action_get_events(pair[0]).is_empty():
			var ev3 = InputEventKey.new()
			ev3.keycode = pair[1]
			InputMap.action_add_event(pair[0], ev3)
	if not FileAccess.file_exists(SAVE_PATH):
		_apply_first_launch_defaults()

func _apply_first_launch_defaults() -> void:
	var defaults = {
		"ui_up": KEY_W, "ui_down": KEY_S, "ui_left": KEY_A, "ui_right": KEY_D,
		"interact": KEY_E, "jump": KEY_SPACE, "inventory": KEY_TAB, "ui_cancel": KEY_ESCAPE,
		"inspect": KEY_I, "journal": KEY_J, "dash": KEY_SHIFT, "block": KEY_F
	}
	for action in defaults.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for e in InputMap.action_get_events(action).duplicate():
			if e is InputEventKey:
				InputMap.action_erase_event(action, e)
		var ev = InputEventKey.new()
		ev.keycode = defaults[action]
		InputMap.action_add_event(action, ev)
	save_keybinds()

func _process(delta: float) -> void:
	if rebind_delay > 0:
		rebind_delay -= delta

func get_key_text(action: String) -> String:
	var events = InputMap.action_get_events(action)
	for e in events:
		if e is InputEventKey:
			return _keycode_to_string(_code_of(e))
		if e is InputEventMouseButton:
			return e.as_text()
	return tr("Не назначено")

func get_key_texture(action: String) -> Texture2D:
	var events = InputMap.action_get_events(action)
	for e in events:
		if e is InputEventKey:
			var key_string = _keycode_to_string(_code_of(e))
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
			var key_string = _keycode_to_string(_code_of(e))
			var tres_path = TEXTURE_PRESSED_PATH + key_string + "KeyboardKeyPressed.tres"
			var png_path = TEXTURE_PRESSED_PATH + key_string + "KeyboardKeyPressed.png"
			if ResourceLoader.exists(tres_path):
				return load(tres_path)
			elif ResourceLoader.exists(png_path):
				return load(png_path)
	return null

func _code_of(e: InputEventKey) -> Key:
	return e.keycode if e.keycode != KEY_NONE else e.physical_keycode

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
			var result = OS.get_keycode_string(keycode)
			if result.length() == 1:
				return result.to_upper()
			return result

signal rebind_started(action: String)
signal rebind_finished(action: String)

func start_rebind(action: String) -> void:
	rebinding_action = action
	rebind_delay = 0.0
	rebind_started.emit(action)

func cancel_rebind() -> void:
	var a = rebinding_action
	rebinding_action = ""
	if a != "":
		rebind_finished.emit(a)
		keybinds_updated.emit()

func _input(event: InputEvent) -> void:
	if rebinding_action.is_empty():
		return
	if not (event is InputEventKey):
		return
	get_viewport().set_input_as_handled()
	if not event.pressed or event.echo:
		return
	var code: Key = event.keycode
	if code == KEY_NONE:
		code = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
	if code == KEY_NONE:
		return
	var action = rebinding_action
	if code == KEY_ESCAPE and action != "ui_cancel":
		cancel_rebind()
		return
	var old_code: Key = KEY_NONE
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			old_code = _code_of(e)
			break
	for other in action_names.keys():
		if other == action or not InputMap.has_action(other):
			continue
		for e in InputMap.action_get_events(other):
			if e is InputEventKey and _code_of(e) == code:
				_clear_action(other)
				if old_code != KEY_NONE:
					var swap = InputEventKey.new()
					swap.keycode = old_code
					InputMap.action_add_event(other, swap)
				break
	_clear_action(action)
	var new_event = InputEventKey.new()
	new_event.keycode = code
	InputMap.action_add_event(action, new_event)
	rebinding_action = ""
	save_keybinds()
	rebind_finished.emit(action)

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
				key_texts.append(_keycode_to_string(_code_of(e)))
		config.set_value("keybinds", action, key_texts)
	config.set_value("meta", "version", 2)
	config.save(SAVE_PATH)
	keybinds_updated.emit()

func load_keybinds() -> void:
	if config.load(SAVE_PATH) != OK:
		return
	if int(config.get_value("meta", "version", 1)) < 2:
		if config.get_value("keybinds", "interact", []) == ["F"]:
			config.set_value("keybinds", "interact", ["E"])
		config.set_value("meta", "version", 2)
		config.save(SAVE_PATH)

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
			return KEY_NONE
