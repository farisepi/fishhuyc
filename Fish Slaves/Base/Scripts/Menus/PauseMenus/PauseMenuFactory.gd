extends CanvasLayer

@onready var continue_btn: Button = $ContinueButton
@onready var settings_btn: Button = $SettingsButton
@onready var save_btn: Button = $SaveButton
@onready var exit_btn: Button = $ExitButton

func _ready() -> void:
	var buttons = [continue_btn, settings_btn, save_btn, exit_btn]
	for btn in buttons:
		ButtonEffects.setup(btn)
	
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	var cr = get_node_or_null("ColorRect")
	if cr:
		cr.modulate.a = 0.5

func _on_continue_pressed() -> void:
	UISounds.play_click()
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_save_pressed() -> void:
	UISounds.play_click()
	Global.came_from = Global.MenuSource.GAME
	get_tree().paused = false
	hide()
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Menus/SaveMenus/SavesMenuFactory.tscn")

func _on_settings_pressed() -> void:
	UISounds.play_click()
	Global.came_from = Global.MenuSource.GAME
	get_tree().paused = false
	hide()
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Menus/SettingMenus/SettingsMenuFactory.tscn")

func _on_exit_pressed() -> void:
	UISounds.play_click()
	get_tree().paused = false
	hide()
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuFactory.tscn")
