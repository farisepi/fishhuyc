extends Node2D

@onready var back_btn: Button = $BackButton
@onready var grid: GridContainer = $ScrollContainer/SaveGrid

const SAVE_DIR = "user://saves/"

var current_popup: AcceptDialog = null
var skip_fill: ColorRect = null
var skip_timer: float = 0.0
var skip_duration: float = 1.5
var intro_active: bool = false

func _ready() -> void:
	Fade.fade_in()
	
	ButtonEffects.setup(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	
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
			_update_slot_text(slot, i)

func _update_slot_text(slot: Button, index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		var scene = config.get_value("save", "scene", "???")
		var time = config.get_value("save", "time", "???")
		slot.text = "■ " + scene + "\n" + time
		slot.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
	else:
		slot.text = "— Пусто —"
		slot.add_theme_color_override("font_color", Color(0.5, 0.7, 0.6))

func _close_current_popup() -> void:
	if current_popup and is_instance_valid(current_popup):
		current_popup.hide()
		current_popup.queue_free()
		current_popup = null

func _on_slot_pressed(index: int):
	if Global.came_from != Global.MenuSource.GAME and not Global.is_new_game:
		return
	
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	
	if config.load(save_path) == OK:
		_show_load_or_delete(index)
	else:
		if Global.is_new_game:
			Global.is_new_game = false
			Fade.fade_out()
			await get_tree().create_timer(0.3).timeout
			var intro = load("res://Base/Scripts/Intro.gd").new()
			add_child(intro)
			_add_skip_ui()
			intro_active = true
			Fade.fade_in()
		elif Global.came_from == Global.MenuSource.GAME:
			_save_game(index)

func _add_skip_ui():
	var canvas = CanvasLayer.new()
	canvas.name = "SkipCanvas"
	canvas.layer = 300
	add_child(canvas)
	
	var view_size = get_viewport().get_visible_rect().size
	
	var skip_bg = ColorRect.new()
	skip_bg.color = Color(0, 0, 0, 0.5)
	skip_bg.size = Vector2(140, 30)
	skip_bg.position = Vector2(view_size.x - 150, 10)
	canvas.add_child(skip_bg)
	
	skip_fill = ColorRect.new()
	skip_fill.color = Color.WHITE
	skip_fill.size = Vector2(0, 30)
	skip_fill.position = Vector2(view_size.x - 150, 10)
	canvas.add_child(skip_fill)
	
	var label = Label.new()
	label.text = "ПРОПУСТИТЬ"
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 14)
	label.position = Vector2(view_size.x - 145, 15)
	canvas.add_child(label)

func _process(delta):
	if not intro_active or not skip_fill:
		return
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		skip_timer += delta
		var progress = skip_timer / skip_duration
		skip_fill.size.x = 130 * progress
		skip_fill.color = Color.GREEN if progress >= 1.0 else Color.WHITE
		if skip_timer >= skip_duration:
			_skip_intro()
	else:
		skip_timer = 0.0
		skip_fill.size.x = 0
		skip_fill.color = Color.WHITE

func _skip_intro():
	intro_active = false
	skip_fill = null
	
	# Останавливаем всё в intro если есть
	var intro = get_node_or_null("Intro")
	if intro and intro.has_method("stop"):
		intro.stop()
	
	Fade.fade_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://Base/Scenes/Level_1.tscn")

func _show_load_or_overwrite(index: int):
	_close_current_popup()
	
	var menu = AcceptDialog.new()
	menu.title = "Сохранение " + str(index + 1)
	menu.dialog_text = "Загрузить или перезаписать?"
	menu.add_button("Загрузить", true, "load")
	menu.add_button("Перезаписать", true, "overwrite")
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(120, 40)
	
	menu.custom_action.connect(func(action):
		_close_current_popup()
		if action == "load":
			_load_game(index)
		elif action == "overwrite":
			_save_game(index)
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
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(100, 40)
	
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
	menu.add_button("Удалить", true, "yes")
	menu.add_button("Нет", true, "no")
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(100, 40)
	
	menu.custom_action.connect(func(action):
		if action == "yes":
			_delete_save(index)
		_close_current_popup()
	)
	menu.close_requested.connect(_close_current_popup)
	
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

func _save_game(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	config.set_value("save", "scene", get_tree().current_scene.scene_file_path)
	config.set_value("save", "time", Time.get_datetime_string_from_system())
	config.save(save_path)
	var slot = grid.get_child(index) as Button
	if slot: _update_slot_text(slot, index)

func _load_game(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		var scene = config.get_value("save", "scene", "")
		if scene != "":
			Fade.fade_out()
			await get_tree().create_timer(0.3).timeout
			get_tree().change_scene_to_file(scene)

func _delete_save(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	DirAccess.remove_absolute(save_path)
	var slot = grid.get_child(index) as Button
	if slot: _update_slot_text(slot, index)

func _show_overwrite_confirm(index: int):
	_close_current_popup()
	
	var menu = AcceptDialog.new()
	menu.title = "Сохранение существует"
	menu.dialog_text = "Слот " + str(index + 1) + " уже занят.\nПерезаписать?"
	menu.add_button("Перезаписать", true, "overwrite")
	menu.add_button("Отмена", true, "cancel")
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(150, 40)
	
	menu.custom_action.connect(func(action):
		_close_current_popup()
		if action == "overwrite":
			Global.is_new_game = false
			Global.save_slot = index
			Fade.fade_out()
			await get_tree().create_timer(0.3).timeout
			var intro = load("res://код/скрипты/intro_simple.gd").new()
			add_child(intro)
			_add_skip_ui()
			intro_active = true
			Fade.fade_in()
	)
	menu.close_requested.connect(_close_current_popup)
	
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

func _on_back_pressed() -> void:
	if Global.came_from == Global.MenuSource.GAME:
		Global.just_returned_from_settings = true
		get_tree().change_scene_to_file("res://Base/Scenes/Level_1.tscn")
		return
	
	Fade.fade_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://Base/Scenes/Main_Menu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_popup:
			_close_current_popup()
			get_viewport().set_input_as_handled()
		else:
			_on_back_pressed()
