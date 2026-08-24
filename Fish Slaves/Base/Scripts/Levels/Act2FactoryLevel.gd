extends Node2D

@onready var player: CharacterBody2D = $Mecha_Fish
@onready var camera: Camera2D = $MechaFishCamera
@onready var skill_check_ui: Control = $UI/SkillCheckWidget

enum LevelState { CUTSCENE_INTRO, WAITING_SKILL_1, CUTSCENE_ALARM, CUTSCENE_GUARD, PLAYER_CONTROL, WAITING_SKILL_2, LEVEL_END }
var state: LevelState = LevelState.CUTSCENE_INTRO

var skill_check_success: bool = false
var guard_appeared: bool = false

func _ready():
	player.set_physics_process(false)
	player.set_process(false)
	player.movement_blocked = true
	
	camera.zoom = Vector2(2.2, 2.2)
	camera.offset = Vector2(0, -50)
	
	$FadeRect.color = Color.BLACK
	var tween = create_tween()
	tween.tween_property($FadeRect, "modulate:a", 0.0, 2.0)
	await tween.finished
	
	_start_skill_check_1()

func _start_skill_check_1():
	state = LevelState.WAITING_SKILL_1
	print("🔴 [СЦЕНА] Появись рычаг! Нажми E в тайминг!")
	skill_check_ui.show_skill_check()

func _input(event: InputEvent):
	if event.is_action_pressed("interact"):
		if state == LevelState.WAITING_SKILL_1:
			if skill_check_ui.check_success():
				_on_skill_1_success()
			else:
				_on_skill_1_fail()
		
		elif state == LevelState.WAITING_SKILL_2:
			if skill_check_ui.check_success():
				_on_skill_2_success()
			else:
				_on_skill_2_fail()
		
		elif state == LevelState.PLAYER_CONTROL:
			var lever = $Lever
			if player.global_position.distance_to(lever.global_position) < 100:
				state = LevelState.WAITING_SKILL_2
				skill_check_ui.show_skill_check()
				print("🔴 [СЦЕНА] Финальный рычаг!")

func _on_skill_1_success():
	print("✅ [ТАЙМИНГ 1] УСПЕШНО!")
	skill_check_ui.hide_skill_check()
	$Lever/LeverSprite.modulate = Color.GREEN
	await get_tree().create_timer(1.0).timeout
	_trigger_alarm()

func _on_skill_1_fail():
	print("❌ [ТАЙМИНГ 1] ПРОВАЛ!")
	skill_check_ui.hide_skill_check()
	player.sprite.play("Hit")
	await get_tree().create_timer(1.0).timeout
	player.sprite.play("Idle")
	_start_skill_check_1()

func _trigger_alarm():
	print("🚨 [СЦЕНА] АВАРИЯ! ТРЯСКА И СВЕТ!")
	state = LevelState.CUTSCENE_ALARM
	camera.add_trauma(0.5)
	$FadeRect.color = Color.RED
	var tween = create_tween()
	tween.tween_property($FadeRect, "modulate:a", 0.3, 0.2)
	await get_tree().create_timer(0.5).timeout
	tween = create_tween()
	tween.tween_property($FadeRect, "modulate:a", 0.0, 0.5)
	await tween.finished
	camera.add_trauma(0.0)
	_spawn_guard()

func _spawn_guard():
	print("👮 [СЦЕНА] ОХРАННИК ПРИШЁЛ!")
	state = LevelState.CUTSCENE_GUARD
	var guard = $Guard
	guard.visible = true
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(guard, "global_position:x", guard.global_position.x - 200, 3.0)
	await tween.finished
	
	_show_guard_text("Эй, ты! Что за шум?")
	await get_tree().create_timer(2.0).timeout
	_show_guard_text("Опять этот старый рычаг...")
	await get_tree().create_timer(2.0).timeout
	_show_guard_text("Ладно, смотри, чтобы не повторилось.")
	await get_tree().create_timer(2.0).timeout
	
	$UI/Dots.visible = true
	await get_tree().create_timer(2.0).timeout
	$UI/Dots.visible = false
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(guard, "global_position:x", guard.global_position.x + 400, 3.0)
	await tween.finished
	guard.visible = false
	
	_give_control()

func _show_guard_text(text: String):
	$UI/GuardLabel.text = text
	$UI/GuardLabel.visible = true
	await get_tree().create_timer(2.0).timeout
	$UI/GuardLabel.visible = false

func _give_control():
	print("🎮 [СЦЕНА] УПРАВЛЕНИЕ ВКЛЮЧЕНО!")
	state = LevelState.PLAYER_CONTROL
	player.set_physics_process(true)
	player.set_process(true)
	player.movement_blocked = false
	$UI/PromptLabel.text = "Подойди к рычагу и нажми E"
	$UI/PromptLabel.visible = true

func _on_skill_2_success():
	print("✅ [ТАЙМИНГ 2] УСПЕШНО! СМЕНА ЗАВЕРШЕНА!")
	skill_check_ui.hide_skill_check()
	$UI/PromptLabel.visible = false
	state = LevelState.LEVEL_END
	await get_tree().create_timer(1.0).timeout
	_win()

func _on_skill_2_fail():
	print("❌ [ТАЙМИНГ 2] ПРОВАЛ!")
	skill_check_ui.hide_skill_check()
	$UI/PromptLabel.text = "Попробуй снова, нажми E у рычага"
	$UI/PromptLabel.visible = true
	state = LevelState.PLAYER_CONTROL

func _win():
	print("🏆 УРОВЕНЬ ПРОЙДЕН!")
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuFactory.tscn")
