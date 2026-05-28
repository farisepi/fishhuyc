extends Node2D

@onready var back_btn: Button = $BackButton
@onready var grid: GridContainer = $ScrollContainer/SaveGrid

const SAVE_DIR = "user://saves/"

var current_popup: AcceptDialog = null

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

# ============================================
# ГЛАВНАЯ ФУНКЦИЯ - ВЫБОР СЛОТА
# ============================================

func _on_slot_pressed(index: int):
	# Если это не новая игра и не из игры - выходим
	if Global.came_from != Global.MenuSource.GAME and not Global.is_new_game:
		return
	
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	
	# Если сохранение существует
	if config.load(save_path) == OK:
		if Global.is_new_game:
			# Новая игра, но слот занят - спрашиваем перезапись
			_show_overwrite_confirm(index)
		elif Global.came_from == Global.MenuSource.GAME:
			# В игре - показываем меню загрузки/удаления
			_show_load_or_delete(index)
	else:
		# Сохранения НЕТ (пустой слот)
		if Global.is_new_game:
			# НОВАЯ ИГРА - запускаем вступление!
			Global.is_new_game = false
			Global.save_slot = index
			
			# Затемняем экран
			Fade.fade_out()
			await get_tree().create_timer(0.3).timeout
			
			# Загружаем вступление
			var intro = load("res://код/скрипты/intro_simple.gd").new()
			add_child(intro)
			
			# Светлеем
			Fade.fade_in()
			
			# Вступление само перейдёт в пролог через 37 секунд
			# (сигнал intro_finished больше не используется)
			
		elif Global.came_from == Global.MenuSource.GAME:
			# В игре, слот пуст - сохраняемся
			_save_game(index)

# ============================================
# ЗАВЕРШЕНИЕ ВСТУПЛЕНИЯ - ПЕРЕХОД В ПРОЛОГ
# ============================================

func _on_intro_finished() -> void:
	print("=== INTRO FINISHED, transitioning directly to prologue ===")
	
	# Удаляем intro-сцену (она уже вызвала queue_free)
	# Просто переходим в пролог
	get_tree().change_scene_to_file("res://код/сцены/пролог.tscn")

# ============================================
# СОХРАНЕНИЕ ИГРЫ
# ============================================

func _save_game(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	config.set_value("save", "scene", get_tree().current_scene.scene_file_path)
	config.set_value("save", "time", Time.get_datetime_string_from_system())
	config.save(save_path)
	var slot = grid.get_child(index) as Button
	if slot: _update_slot_text(slot, index)

# ============================================
# МЕНЮ ЗАГРУЗКИ/УДАЛЕНИЯ (для существующих сохранений)
# ============================================

func _show_load_or_delete(index: int):
	_close_current_popup()
	
	var menu = AcceptDialog.new()
	menu.title = "Сохранение " + str(index + 1)
	menu.dialog_text = "Загрузить или удалить?"
	menu.add_button("Загрузить", true, "load")
	menu.add_button("Удалить", true, "delete")
	menu.add_cancel_button("Отмена")
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
	menu.canceled.connect(_close_current_popup)
	
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

# ============================================
# ПОДТВЕРЖДЕНИЕ УДАЛЕНИЯ
# ============================================

func _show_delete_confirm(index: int):
	_close_current_popup()
	
	var menu = AcceptDialog.new()
	menu.title = "Удаление"
	menu.dialog_text = "Удалить сохранение " + str(index + 1) + "?"
	menu.add_button("Удалить", true, "yes")
	menu.add_cancel_button("Отмена")
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
	menu.canceled.connect(_close_current_popup)
	
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

# ============================================
# ЗАГРУЗКА ИГРЫ
# ============================================

func _load_game(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		var scene = config.get_value("save", "scene", "")
		if scene != "":
			Fade.fade_out()
			await get_tree().create_timer(0.3).timeout
			get_tree().change_scene_to_file(scene)

# ============================================
# УДАЛЕНИЕ СОХРАНЕНИЯ
# ============================================

func _delete_save(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	DirAccess.remove_absolute(save_path)
	var slot = grid.get_child(index) as Button
	if slot: _update_slot_text(slot, index)

# ============================================
# ПЕРЕЗАПИСЬ СУЩЕСТВУЮЩЕГО СОХРАНЕНИЯ
# ============================================

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
			# Перезаписываем и запускаем вступление
			Global.is_new_game = false
			Global.save_slot = index
			
			Fade.fade_out()
			await get_tree().create_timer(0.3).timeout
			
			# Запускаем вступление
			var intro = load("res://код/скрипты/intro_simple.gd").new()
			add_child(intro)
			intro.intro_finished.connect(_on_intro_finished)
			Fade.fade_in()
	)
	menu.close_requested.connect(_close_current_popup)
	menu.canceled.connect(_close_current_popup)
	
	current_popup = menu
	add_child(menu)
	menu.popup_centered()

# ============================================
# КНОПКА НАЗАД
# ============================================

func _on_back_pressed() -> void:
	if Global.came_from == Global.MenuSource.GAME:
		Global.just_returned_from_settings = true
		get_tree().change_scene_to_file("res://код/сцены/пролог.tscn")
		return
	
	Fade.fade_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://код/сцены/main_menu.tscn")

# ============================================
# ОБРАБОТКА НАЖАТИЯ ESCAPE
# ============================================

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_popup:
			_close_current_popup()
			get_viewport().set_input_as_handled()
		else:
			_on_back_pressed()
