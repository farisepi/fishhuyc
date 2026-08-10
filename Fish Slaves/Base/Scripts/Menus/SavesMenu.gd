extends Node2D

@onready var back_btn: Button = $BackButton
@onready var grid: GridContainer = $ScrollContainer/SaveGrid

const SAVE_DIR = "user://saves/"

var current_popup: AcceptDialog = null
var intro_active: bool = false
var intro_instance: CanvasLayer = null

var custom_font: FontFile

func _ready() -> void:
	custom_font = load("res://Fish Slaves/Textures/Font/Font.ttf")
	if custom_font:
		custom_font.fixed_size = 10
	
	if is_instance_valid(Fade):
		Fade.fade_in()
	
	GlobalMusic.play_menu_music()
	
	ButtonEffects.setup(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	
	if custom_font and back_btn:
		back_btn.add_theme_font_override("font", custom_font)
		back_btn.add_theme_font_size_override("font_size", 16)
	
	var scroll = $ScrollContainer
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.clip_contents = true
	scroll.follow_focus = false
	scroll.scroll_vertical = 0
	
	grid.columns = 1
	DirAccess.make_dir_absolute(SAVE_DIR)
	
	for i in range(grid.get_child_count()):
		var slot = grid.get_child(i) as Button
		if slot:
			slot.set_meta("no_scale_animation", true)
			ButtonEffects.setup(slot)
			slot.pressed.connect(_on_slot_pressed.bind(i))
			
			if custom_font:
				slot.add_theme_font_override("font", custom_font)
				slot.add_theme_font_size_override("font_size", 18)
			
			_update_slot_text(slot, i)
	
	var title = $TitleLabel
	if custom_font and title:
		title.add_theme_font_override("font", custom_font)
		title.add_theme_font_size_override("font_size", 18)

func _update_slot_text(slot: Button, index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		var scene = config.get_value("save", "scene", "???")
		var time = config.get_value("save", "time", "???")
		var location = ""
		if "Act1" in scene or "Level_1" in scene:
			location = "Аквариум"
		elif "Act2" in scene or "Level_2" in scene:
			location = "Завод"
		elif "Act3" in scene or "chase_level" in scene or "Level_3" in scene:
			location = "Коридор к складовым помещениям"
		else:
			location = scene
		slot.text = location + "\n" + time
		slot.add_theme_color_override("font_color", Color(0.831, 0.643, 0.09))
	else:
		slot.text = "— Пусто —"
		slot.add_theme_color_override("font_color", Color(0.5, 0.7, 0.6))

func _close_current_popup() -> void:
	if current_popup and is_instance_valid(current_popup):
		current_popup.hide()
		current_popup.queue_free()
		current_popup = null

func _on_slot_pressed(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	var save_exists = config.load(save_path) == OK
	
	if Global.came_from == Global.MenuSource.GAME:
		if save_exists:
			_show_load_or_overwrite(index)
		else:
			_save_game(index, Global.scene_to_save)
	else:
		if save_exists:
			_show_load_or_delete(index)
		else:
			Global.is_new_game = false
			if is_instance_valid(Fade):
				Fade.fade_out()
				await get_tree().create_timer(0.3).timeout
			
			# Запускаем интро
			intro_instance = load("res://Fish Slaves/Base/Scripts/Levels/Intro.gd").new()
			add_child(intro_instance)
			intro_active = true
			
			if is_instance_valid(Fade):
				Fade.fade_in()

func _skip_intro():
	intro_active = false
	
	if intro_instance and is_instance_valid(intro_instance):
		intro_instance._skip_intro()
		intro_instance = null
	
	# === ПРЯМОЙ ПЕРЕХОД БЕЗ ЗАГРУЗОЧНОГО ЭКРАНА ===
	if is_instance_valid(Fade):
		Fade.fade_out()
		await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act1AquariumLevel.tscn")

func _show_load_or_overwrite(index: int):
	_close_current_popup()
	
	var menu = AcceptDialog.new()
	menu.title = "Сохранение " + str(index + 1)
	menu.dialog_text = "Загрузить или перезаписать?"
	menu.add_button("Загрузить", true, "load")
	menu.add_button("Перезаписать", true, "overwrite")
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	
	if custom_font:
		menu.add_theme_font_override("font", custom_font)
		menu.add_theme_font_size_override("font_size", 14)
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(120, 40)
			if custom_font:
				child.add_theme_font_override("font", custom_font)
				child.add_theme_font_size_override("font_size", 14)
	
	menu.custom_action.connect(func(action):
		_close_current_popup()
		if action == "load":
			_load_game(index)
		elif action == "overwrite":
			_save_game(index, Global.scene_to_save)
	)
	menu.close_requested.connect(_close_current_popup)
	
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

func _show_load_or_delete(index: int):
	_close_current_popup()
	
	var menu = AcceptDialog.new()
	menu.title = "Сохранение " + str(index + 1)
	menu.dialog_text = "Загрузить или удалить?"
	menu.add_button("Загрузить", true, "load")
	menu.add_button("Удалить", true, "delete")
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	
	if custom_font:
		menu.add_theme_font_override("font", custom_font)
		menu.add_theme_font_size_override("font_size", 14)
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(100, 40)
			if custom_font:
				child.add_theme_font_override("font", custom_font)
				child.add_theme_font_size_override("font_size", 14)
	
	menu.custom_action.connect(func(action):
		_close_current_popup()
		if action == "load":
			_load_game(index)
		elif action == "delete":
			_show_delete_confirm(index)
	)
	menu.close_requested.connect(_close_current_popup)
	
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

func _show_delete_confirm(index: int):
	_close_current_popup()
	
	var menu = AcceptDialog.new()
	menu.title = "Удаление"
	menu.dialog_text = "Удалить сохранение " + str(index + 1) + "?"
	menu.add_button("Да", true, "yes")
	menu.add_button("Нет", true, "no")
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	
	if custom_font:
		menu.add_theme_font_override("font", custom_font)
		menu.add_theme_font_size_override("font_size", 14)
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(100, 40)
			if custom_font:
				child.add_theme_font_override("font", custom_font)
				child.add_theme_font_size_override("font_size", 14)
	
	menu.custom_action.connect(func(action):
		if action == "yes":
			_delete_save(index)
		_close_current_popup()
	)
	menu.close_requested.connect(_close_current_popup)
	
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

func _save_game(index: int, scene_path: String = ""):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	
	var current_scene = scene_path
	if current_scene == "":
		current_scene = get_tree().current_scene.scene_file_path
	
	var datetime = Time.get_datetime_dict_from_system()
	var month = "%02d" % datetime.month
	var day = "%02d" % datetime.day
	var hour = "%02d" % datetime.hour
	var minute = "%02d" % datetime.minute
	var year = str(datetime.year).substr(2, 2)
	var time = day + "." + month + "." + year + " " + hour + ":" + minute
	
	config.set_value("save", "scene", current_scene)
	config.set_value("save", "time", time)
	
	if Global.player_position != Vector2.ZERO:
		config.set_value("save", "player_x", Global.player_position.x)
		config.set_value("save", "player_y", Global.player_position.y)
	
	config.set_value("save", "chatter_queue", Global.chatter_queue_state)
	config.set_value("save", "chatter_text", Global.chatter_current_text)
	config.set_value("save", "chatter_index", Global.chatter_char_index)
	
	config.save(save_path)
	var slot = grid.get_child(index) as Button
	if slot: _update_slot_text(slot, index)

func _load_game(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		var scene = config.get_value("save", "scene", "")
		if scene != "":
			var player_x = config.get_value("save", "player_x", 0.0)
			var player_y = config.get_value("save", "player_y", 0.0)
			if player_x != 0.0 or player_y != 0.0:
				Global.player_position = Vector2(player_x, player_y)
			
			Global.chatter_queue_state = config.get_value("save", "chatter_queue", [])
			Global.chatter_current_text = config.get_value("save", "chatter_text", "")
			Global.chatter_char_index = config.get_value("save", "chatter_index", 0)
			
			Global.goto_scene(scene)

func _delete_save(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	DirAccess.remove_absolute(save_path)
	var slot = grid.get_child(index) as Button
	if slot: _update_slot_text(slot, index)

func _on_back_pressed() -> void:
	if Global.came_from == Global.MenuSource.GAME:
		Global.just_returned_from_settings = true
		GlobalMusic.resume_level_music()
		Global.goto_scene("res://Fish Slaves/Base/Scenes/Levels/Act1AquariumLevel.tscn")
		return
	
	if is_instance_valid(Fade):
		Fade.fade_out()
		await get_tree().create_timer(0.3).timeout
	Global.goto_scene("res://Fish Slaves/Base/Scenes/Menus/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_popup:
			_close_current_popup()
			get_viewport().set_input_as_handled()
		else:
			_on_back_pressed()