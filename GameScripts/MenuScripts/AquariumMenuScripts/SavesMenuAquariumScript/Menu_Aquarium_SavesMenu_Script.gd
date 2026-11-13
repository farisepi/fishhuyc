extends Node2D
const STYLED_DIALOG := preload("res://GameScripts/UIScripts/MenuDialogScripts/Menu_StyledDialog.gd")

@onready var back_btn: Button = $BackButton
@onready var grid: GridContainer = $ScrollContainer/SaveGrid

const SAVE_DIR = "user://saves/"

const EMPTY_NORMAL = "res://GameAssets/SharedMaterials/UIMaterials/SaveMenuMaterials/AquariumSaveMenuMaterials/Menu_SaveMenu_Aquarium_Button_Huge_Empty_Normal_Material.tres"
const EMPTY_HOVER = "res://GameAssets/SharedMaterials/UIMaterials/SaveMenuMaterials/AquariumSaveMenuMaterials/Menu_SaveMenu_Aquarium_Button_Huge_Empty_Hover_Material.tres"
const EMPTY_PRESSED = "res://GameAssets/SharedMaterials/UIMaterials/SaveMenuMaterials/AquariumSaveMenuMaterials/Menu_SaveMenu_Aquarium_Button_Huge_Empty_Pressed_Material.tres"

const FULL_NORMAL = "res://GameAssets/SharedMaterials/UIMaterials/SaveMenuMaterials/AquariumSaveMenuMaterials/Menu_SaveMenu_Aquarium_Button_Huge_Fullness_Normal_Material.tres"
const FULL_HOVER = "res://GameAssets/SharedMaterials/UIMaterials/SaveMenuMaterials/AquariumSaveMenuMaterials/Menu_SaveMenu_Aquarium_Button_Huge_Fullness_Hover_Material.tres"
const FULL_PRESSED = "res://GameAssets/SharedMaterials/UIMaterials/SaveMenuMaterials/AquariumSaveMenuMaterials/Menu_SaveMenu_Aquarium_Button_Huge_Fullness_Pressed_Material.tres"

var current_popup = null
var intro_active: bool = false
var intro_instance: CanvasLayer = null

var custom_font: FontFile

const BubbleScript = preload("res://GameScripts/EntityScripts/BubbleEntityScripts/Bubble_Script.gd")
var bubble_scene: PackedScene = preload("res://GameScenes/EntityScenes/BubbleEntityScenes/Bubble_Scene.tscn")

func _ready() -> void:
	MenuHeader.style_scrolls.call_deferred(self, true, true)
	call_deferred("_add_header")
	custom_font = load("res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf")
	if custom_font:
		custom_font.fixed_size = 10

	if not has_meta("overlay"):
		if is_instance_valid(Fade) and Fade.has_method("fade_in"):
			Fade.fade_in()
		UISounds.stop_everything_gameplay()

	if has_meta("overlay"):
		pass
	elif Global.came_from == Global.MenuSource.GAME:
		pass
	else:
		GlobalMusic.play_menu_music()

	ButtonEffects.setup(back_btn)
	if not back_btn.pressed.is_connected(_on_back_pressed):
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

	call_deferred("_apply_seaweed_deferred")
	call_deferred("_start_background_bubbles")

func _apply_seaweed_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var global = get_node("/root/Global")
	if global and global.has_method("_force_apply_seaweed"):
		global._force_apply_seaweed(self)

func _update_slot_text(slot: Button, index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		var time = config.get_value("save", "time", "???")
		var location = Global.get_save_title(config)
		slot.text = location + "\n" + time
		slot.add_theme_color_override("font_color", Color(0.831, 0.643, 0.09))

		slot.add_theme_stylebox_override("normal", load(FULL_NORMAL))
		slot.add_theme_stylebox_override("hover", load(FULL_HOVER))
		slot.add_theme_stylebox_override("pressed", load(FULL_PRESSED))
	else:
		slot.text = "— Пусто —"
		slot.add_theme_color_override("font_color", Color(0.5, 0.7, 0.6))

		slot.add_theme_stylebox_override("normal", load(EMPTY_NORMAL))
		slot.add_theme_stylebox_override("hover", load(EMPTY_HOVER))
		slot.add_theme_stylebox_override("pressed", load(EMPTY_PRESSED))

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
			Global.save_slot = index
			Global.shards_blue = 0
			Global.shards_green = 0
			Global.shards_cyan = 0
			DirAccess.remove_absolute("user://tutorial_%d.cfg" % index)
			Global.autosave(Global.SCENE_AQUARIUM)
			var new_slot = grid.get_child(index) as Button
			if new_slot: _update_slot_text(new_slot, index)
			if is_instance_valid(Fade):
				Fade.fade_out()
				await get_tree().create_timer(0.3).timeout

			var intro_scene = load("res://GameScenes/IntroScenes/IntroScene/Intro_Scene.tscn")
			if intro_scene:
				intro_instance = intro_scene.instantiate()
				add_child(intro_instance)
				intro_active = true
			else:
				intro_instance = CanvasLayer.new()
				var script = load("res://GameScripts/IntroScripts/IntroScript/Intro_Script.gd")
				if script:
					intro_instance.set_script(script)
					add_child(intro_instance)
					intro_active = true

			if is_instance_valid(Fade):
				Fade.fade_in()

func _skip_intro():
	intro_active = false

	if intro_instance and is_instance_valid(intro_instance):
		if intro_instance.has_method("_skip_intro"):
			intro_instance._skip_intro()
		intro_instance.queue_free()
		intro_instance = null

	Global.goto_scene(Global.SCENE_AQUARIUM)

func _show_load_or_overwrite(index: int):
	_close_current_popup()

	var menu = STYLED_DIALOG.new()
	menu.style = "aquarium"
	menu.title = tr("Сохранение ") + str(index + 1)
	menu.dialog_text = tr("Загрузить или перезаписать?")
	menu.add_button(tr("Загрузить"), true, "load")
	menu.add_button(tr("Перезаписать"), true, "overwrite")
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

	var menu = STYLED_DIALOG.new()
	menu.style = "aquarium"
	menu.title = tr("Сохранение ") + str(index + 1)
	menu.dialog_text = tr("Загрузить или удалить?")
	menu.add_button(tr("Загрузить"), true, "load")
	menu.add_button(tr("Удалить"), true, "delete")
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

	var menu = STYLED_DIALOG.new()
	menu.style = "aquarium"
	menu.title = tr("Удаление")
	menu.dialog_text = tr("Удалить сохранение ") + str(index + 1) + "?"
	menu.add_button(tr("Да"), true, "yes")
	menu.add_button(tr("Нет"), true, "no")
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
	if current_scene == "" or "SavesMenu" in current_scene:
		current_scene = Global.SCENE_AQUARIUM

	var time = Global.format_save_time()

	config.set_value("save", "scene", current_scene)
	config.set_value("save", "time", time)

	var px = Global.player_position.x
	var py = Global.player_position.y
	if px == 0.0 and py == 0.0:
		config.set_value("save", "player_x", 605.0)
		config.set_value("save", "player_y", 224.0)
	else:
		config.set_value("save", "player_x", px)
		config.set_value("save", "player_y", py)

	config.set_value("save", "chatter_queue", Global.chatter_queue_state)
	config.set_value("save", "chatter_text", Global.chatter_current_text)
	config.set_value("save", "chatter_index", Global.chatter_char_index)

	config.set_value("shards", "blue", Global.shards_blue)
	config.set_value("shards", "green", Global.shards_green)
	config.set_value("shards", "cyan", Global.shards_cyan)
	if Global.came_from == Global.MenuSource.GAME:
		Global.write_factory_state(config)

	config.save(save_path)
	var slot = grid.get_child(index) as Button
	if slot: _update_slot_text(slot, index)

	Global.last_save_level = max(1, Global.get_level_number(current_scene))

	if Global.came_from == Global.MenuSource.GAME and has_meta("overlay"):
		Global.save_slot = index
		Global.save_shards_to_slot()
		_close_overlay()
		return
	if Global.came_from == Global.MenuSource.GAME:
		Global.just_returned_from_settings = true
		Global.save_slot = index
		Global.save_shards_to_slot()
		var target = Global.scene_to_save
		if target == "" or "SavesMenu" in target:
			target = Global.SCENE_AQUARIUM
		if is_instance_valid(Fade):
			Fade.fade_out()
			await get_tree().create_timer(0.3).timeout
		Global.goto_scene(target)
		return

func _load_game(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		var scene = config.get_value("save", "scene", "")
		if scene != "":
			var player_x = config.get_value("save", "player_x", 0.0)
			var player_y = config.get_value("save", "player_y", 0.0)
			Global.player_position = Vector2(player_x, player_y)

			Global.chatter_queue_state = config.get_value("save", "chatter_queue", [])
			Global.chatter_current_text = config.get_value("save", "chatter_text", "")
			Global.chatter_char_index = config.get_value("save", "chatter_index", 0)
			Global.read_factory_state(config)

			Global.last_save_level = max(1, Global.get_level_number(scene))

			Global.save_slot = index
			Global.load_shards_from_slot()

			if has_meta("overlay"):
				_drop_overlay_for_scene_change()
			Global.goto_scene(scene)

func _delete_save(index: int):
	var save_path = SAVE_DIR + "save_" + str(index) + ".cfg"
	DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute("user://tutorial_%d.cfg" % index)
	var slot = grid.get_child(index) as Button
	if slot: _update_slot_text(slot, index)

func _close_overlay() -> void:
	var host = get_parent()
	if host is CanvasLayer:
		host.queue_free()
	else:
		queue_free()

func _drop_overlay_for_scene_change() -> void:
	get_tree().paused = false
	var host = get_parent()
	if host is CanvasLayer:
		for c in host.tree_exited.get_connections():
			host.tree_exited.disconnect(c["callable"])
		host.queue_free()

var _leaving: bool = false

func _on_back_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	if has_meta("overlay"):
		_close_overlay()
		return
	if Global.came_from == Global.MenuSource.GAME:
		Global.just_returned_from_settings = true
		var target = Global.scene_to_save
		if target == "" or "SavesMenu" in target:
			target = Global.SCENE_AQUARIUM
		if is_instance_valid(Fade):
			Fade.fade_out()
			await get_tree().create_timer(0.3).timeout
		Global.goto_scene(target)
		return

	if is_instance_valid(Fade):
		Fade.fade_out()
		await get_tree().create_timer(0.3).timeout
	Global.goto_scene("res://GameScenes/MenuScenes/AquariumMenuScenes/AquariumMainMenuScene/Menu_Aquarium_MainMenu_Scene.tscn")

func _input(event: InputEvent) -> void:
	if intro_active:
		return
	if event.is_action_pressed("ui_cancel"):
		if current_popup:
			_close_current_popup()
			get_viewport().set_input_as_handled()
		else:
			_on_back_pressed()


func _start_background_bubbles() -> void:
	if not BubbleScript.restore_menu_bubbles(self, bubble_scene, false):
		for i in range(randi_range(3, 6)):
			_make_menu_bubble()
	_spawn_next_bubble()

func _exit_tree() -> void:
	BubbleScript.save_menu_bubbles(self)

func _spawn_next_bubble() -> void:
	if not bubble_scene:
		return
	if not is_inside_tree():
		return
	var timer = get_tree().create_timer(randf_range(0.15, 0.35))
	timer.timeout.connect(_on_bubble_spawn_timer)

func _on_bubble_spawn_timer() -> void:
	if not is_inside_tree():
		return
	for i in range(randi_range(1, 2)):
		_make_menu_bubble()
	_spawn_next_bubble()

func _make_menu_bubble() -> void:
	if not bubble_scene:
		return
	var viewport = get_viewport()
	if not viewport:
		return
	var viewport_size = viewport.get_visible_rect().size
	var bubble = bubble_scene.instantiate()
	add_child(bubble)
	bubble.set_meta("menu_bg", true)
	bubble.z_index = -10
	bubble.global_position = Vector2(randf_range(0, viewport_size.x), randf_range(0, viewport_size.y))
	bubble.scale = Vector2.ONE * randf_range(0.5, 1.4)
	bubble.speed = randf_range(10.0, 25.0)
	bubble.clickable = false
	bubble.modulate.a = 0.0
	var alpha_tween = create_tween()
	alpha_tween.tween_property(bubble, "modulate:a", randf_range(0.01, 0.75), 1.0)
	bubble.set_direction(Vector2(randf_range(-0.3, 0.3), randf_range(-1.0, -0.2)))
	bubble.start_life(randf_range(6.0, 15.0))

func _add_header() -> void:
	var acc = MenuHeader.accent_for(self)
	var old_c := -1.0
	for n in ["Title", "TitleLabel"]:
		var t = get_node_or_null(n) as Control
		if t:
			t.visible = false
			old_c = t.position.y + t.size.y * 0.5
	MenuHeader.attach(self, tr("СОХРАНЕНИЯ"), acc, (old_c - 23.0) if old_c >= 0.0 else 30.0, 32)
	for n in ["DividingLine1", "DividingLine2"]:
		var d = get_node_or_null(n) as ColorRect
		if d:
			d.color = Color(acc, 0.35)
