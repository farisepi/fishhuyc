extends CanvasLayer

@onready var continue_btn: Button = $ContinueButton
@onready var settings_btn: Button = $SettingsButton
@onready var save_btn: Button = $SaveButton
@onready var restart_btn: Button = $RestartButton
@onready var exit_btn: Button = $ExitButton

func _ready() -> void:
	var buttons = [continue_btn, settings_btn, save_btn, restart_btn, exit_btn]
	for btn in buttons:
		ButtonEffects.setup(btn)
	
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	var cr = get_node_or_null("ColorRect")
	if cr:
		cr.modulate.a = 0.5

func _resume_all_actors() -> void:
	var player = get_tree().current_scene.get_node_or_null("рыбка") as CharacterBody2D
	if player:
		player.set_physics_process(true)
		player.set_process(true)
		var anim = player.get_node_or_null("AnimatedSprite2D")
		if anim: anim.play()
	
	var scientist = get_tree().current_scene.get_node_or_null("Scientist1")
	if scientist:
		scientist.set_process(true)
		var s_anim = scientist.get_node_or_null("AnimationPlayer")
		if s_anim: s_anim.play()
	
	var mechanic = get_tree().current_scene.get_node_or_null("Mechanic")
	if mechanic:
		mechanic.set_process(true)
		var m_anim = mechanic.get_node_or_null("AnimationPlayer")
		if m_anim: m_anim.play()

func _on_continue_pressed() -> void:
	UISounds.play_click()
	hide()
	get_tree().paused = false
	_resume_all_actors()
	
	var player = get_tree().current_scene.get_node_or_null("рыбка") as CharacterBody2D
	if player:
		player.can_move = true

func _on_save_pressed() -> void:
	UISounds.play_click()
	Global.came_from = Global.MenuSource.GAME
	
	var player = get_tree().current_scene.get_node_or_null("рыбка") as CharacterBody2D
	if player:
		Global.player_position = player.global_position
		var camera: Camera2D = player.get_node_or_null("PlayerCamera")
		if camera: Global.camera_position = camera.global_position
	
	var prolog = get_tree().current_scene
	if prolog and prolog.has_method("get_chatter_state"):
		var state = prolog.get_chatter_state()
		Global.chatter_queue_state = state["queue"]
		Global.chatter_current_text = state["current_text"]
		Global.chatter_char_index = state["char_index"]
	
	Global.scene_to_save = get_tree().current_scene.scene_file_path
	
	get_tree().paused = false
	hide()
	
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://Base/Scenes/Save_Menu.tscn")

func _on_settings_pressed() -> void:
	UISounds.play_click()
	Global.came_from = Global.MenuSource.GAME
	
	var player = get_tree().current_scene.get_node_or_null("рыбка") as CharacterBody2D
	if player:
		Global.player_position = player.global_position
		var camera: Camera2D = player.get_node_or_null("PlayerCamera")
		if camera: Global.camera_position = camera.global_position
	
	var prolog = get_tree().current_scene
	if prolog and prolog.has_method("get_chatter_state"):
		var state = prolog.get_chatter_state()
		Global.chatter_queue_state = state["queue"]
		Global.chatter_current_text = state["current_text"]
		Global.chatter_char_index = state["char_index"]
	
	get_tree().paused = false
	hide()
	
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://Base/Scenes/Settings_Menu.tscn")

func _on_restart_pressed() -> void:
	UISounds.play_click()
	get_tree().paused = false
	hide()
	Global.player_position = Vector2.ZERO
	Global.chatter_queue_state = []
	Global.chatter_current_text = ""
	Global.chatter_char_index = 0
	
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://Base/Scenes/Level_1.tscn")

func _on_exit_pressed() -> void:
	UISounds.play_click()
	get_tree().paused = false
	hide()
	
	if is_instance_valid(Fade):
		Fade.fade_out()
		await get_tree().create_timer(0.3).timeout
	
	get_tree().change_scene_to_file("res://Base/Scenes/Main_Menu.tscn")
