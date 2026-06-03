extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var finish_line: Area2D = $FinishLine
@onready var prompt: Label = $UI/PromptLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var slow_overlay: ColorRect = $UI/SlowOverlay
@onready var player_fake: ColorRect = $IntroCutscene/PlayerFake
@onready var door: ColorRect = $IntroCutscene/Door
@onready var guard1: ColorRect = $IntroCutscene/Guard1
@onready var other_guards: ColorRect = $IntroCutscene/OtherGuards
@onready var exclamation_label: Label = $IntroCutscene/ExclamationLabel
@onready var elevator: ColorRect = $Elevator
@onready var forklift: CharacterBody2D = $ForkliftScene/Forklift
@onready var moving_shelf: StaticBody2D = $ForkliftScene/MovingShelf
@onready var falling_shelf: StaticBody2D = $ForkliftScene/FallingShelf
@onready var elevator_button: Area2D = $ElevatorButton
@onready var ambush_enemy: CharacterBody2D = $AmbushEnemy

var enemies_alive: int = 11
var game_ended: bool = false
var is_slowed: bool = false
var slow_used: bool = false
var first_item_taken: bool = false
var stuck_timer: float = 0.0
const STUCK_TIME: float = 2.0
var at_elevator: bool = false
var intro_done: bool = false
var ambush_active: bool = false
var ambush_done: bool = false
var has_tool: bool = false
var shelf_climbing: bool = false
var elevator_ready: bool = false

func _ready():
	player.visible = false
	player.set_physics_process(false)
	if forklift:
		forklift.visible = false
		forklift.set_physics_process(false)
	if moving_shelf:
		moving_shelf.visible = false
	if falling_shelf:
		falling_shelf.visible = false
	if ambush_enemy:
		ambush_enemy.set_physics_process(false)
	
	finish_line.body_entered.connect(func(body):
		if body == player and not game_ended:
			_arrive_at_elevator()
	)
	
	if has_node("AmbushTrigger"):
		$AmbushTrigger.body_entered.connect(func(body):
			if body == player and not ambush_done:
				_start_ambush()
		)
	
	if game_over_label:
		game_over_label.set_anchors_preset(Control.PRESET_CENTER)
		game_over_label.position = Vector2(0, 0)
	
	_start_intro_cutscene()

func _start_intro_cutscene():
	if player_fake:
		player_fake.visible = true
	if door:
		door.visible = true
	if guard1:
		guard1.visible = true
	if other_guards:
		other_guards.visible = true
	
	if player_fake:
		player_fake.position = Vector2(2150, 278)
	if guard1:
		guard1.position = Vector2(2130, 278)
	if other_guards:
		other_guards.position = Vector2(2080, 278)
	
	await get_tree().create_timer(0.3).timeout
	
	if player_fake:
		var tween = create_tween()
		tween.tween_property(player_fake, "position", Vector2(2130, 278), 0.3)
		await tween.finished
	
	if guard1 and player_fake:
		guard1.position = player_fake.position + Vector2(-15, 0)
	await get_tree().create_timer(0.2).timeout
	
	if player_fake:
		player_fake.modulate = Color.RED
	await get_tree().create_timer(0.15).timeout
	
	if guard1 and other_guards:
		var throw_tween = create_tween()
		throw_tween.tween_property(guard1, "position", other_guards.position, 0.3)
	if player_fake:
		player_fake.modulate = Color(0.3, 0.5, 1.0)
	await get_tree().create_timer(0.3).timeout
	
	if exclamation_label and player_fake:
		exclamation_label.position = player_fake.position + Vector2(-10, -45)
		exclamation_label.visible = true
		await get_tree().create_timer(0.6).timeout
		exclamation_label.visible = false
	
	if player_fake:
		var run_tween = create_tween()
		run_tween.tween_property(player_fake, "position", Vector2(2000, 278), 0.5)
		await run_tween.finished
	
	$IntroCutscene.visible = false
	player.visible = true
	player.set_physics_process(true)
	player.global_position = Vector2(2000, 278)
	intro_done = true

func _start_ambush():
	ambush_active = true
	if ambush_enemy:
		ambush_enemy.set_physics_process(false)
	Engine.time_scale = 0.05
	if slow_overlay:
		slow_overlay.color = Color(0, 0, 0, 0.5)
	if prompt:
		prompt.text = "ПКМ — парировать"
		prompt.visible = true
		prompt.position = player.global_position + Vector2(-80, -60)

func _parry_success():
	Engine.time_scale = 1.0
	if slow_overlay:
		slow_overlay.color = Color(0, 0, 0, 0)
	if prompt:
		prompt.visible = false
	ambush_active = false
	ambush_done = true
	
	if ambush_enemy:
		var tween = create_tween()
		tween.tween_property(ambush_enemy, "global_position", Vector2(1000, 290), 0.3)
		ambush_enemy.modulate = Color.RED
		await tween.finished
		_spawn_blood(ambush_enemy.global_position)
		ambush_enemy.queue_free()

func _spawn_blood(pos: Vector2):
	for i in range(8):
		var drop = ColorRect.new()
		drop.color = Color(0.8, 0.1, 0.1)
		drop.size = Vector2(randf_range(3, 8), randf_range(3, 8))
		drop.position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		add_child(drop)
		var tween = create_tween()
		tween.tween_property(drop, "position:y", drop.position.y + randf_range(20, 60), 0.5)
		tween.parallel().tween_property(drop, "modulate:a", 0.0, 0.5)
		tween.finished.connect(drop.queue_free)

func _start_shelf_climb():
	shelf_climbing = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	if prompt:
		prompt.visible = false
	
	if moving_shelf:
		var tween = create_tween()
		tween.tween_property(player, "global_position", moving_shelf.global_position + Vector2(0, -60), 0.5)
		await tween.finished
	
	if prompt:
		prompt.text = "Нажми E чтобы взять инструмент"
		prompt.visible = true
		prompt.position = player.global_position + Vector2(-80, -60)

func _arrive_at_elevator():
	at_elevator = true
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	
	if not elevator_ready:
		if prompt:
			prompt.text = "Нужно нажать кнопку!"
			prompt.visible = true
		await get_tree().create_timer(1.5).timeout
		if prompt:
			prompt.visible = false
		player.set_physics_process(true)
		at_elevator = false
		return
	
	if elevator:
		elevator.color = Color.GREEN
	await get_tree().create_timer(1.0).timeout
	
	if elevator:
		var tween = create_tween()
		tween.tween_property(player, "global_position", Vector2(elevator.global_position.x + 30, player.global_position.y), 0.5)
		await tween.finished
	
	player.visible = false
	await get_tree().create_timer(1.0).timeout
	_win()

func _process(delta):
	if game_ended:
		return
	
	if at_elevator:
		return
	
	if ambush_active:
		if Input.is_action_just_pressed("parry"):
			_parry_success()
		return
	
	if shelf_climbing:
		return
	
	if forklift and forklift.visible and forklift.is_physics_processing():
		if forklift.global_position.distance_to(player.global_position) < 50:
			_game_over()
	
	if has_tool and elevator_button and elevator_button.get_overlapping_bodies().has(player):
		if Input.is_action_just_pressed("interact"):
			_activate_elevator()
	
	if moving_shelf and moving_shelf.visible and not shelf_climbing:
		var dist = player.global_position.distance_to(moving_shelf.global_position)
		if dist < 60 and Input.is_action_just_pressed("interact"):
			has_tool = true
			if prompt:
				prompt.text = "Нажми E чтобы кинуть в кнопку"
				prompt.visible = true
			_shelf_collapse()
	
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			if enemy.global_position.distance_to(player.global_position) < 30:
				_game_over()
				return
	
	var stuck = false
	
	if has_node("Vaults"):
		for vault in $Vaults.get_children():
			if vault is StaticBody2D:
				var rect = Rect2(vault.global_position - Vector2(20, 25), Vector2(40, 50))
				var player_rect = Rect2(player.global_position - Vector2(15, 25), Vector2(30, 50))
				if rect.intersects(player_rect) and player.is_on_floor():
					stuck = true
	
	if has_node("Slides"):
		for slide in $Slides.get_children():
			if slide is StaticBody2D:
				var rect = Rect2(slide.global_position - Vector2(30, 5), Vector2(60, 10))
				var player_rect = Rect2(player.global_position - Vector2(15, 25), Vector2(30, 50))
				if rect.intersects(player_rect) and not player.is_sliding:
					stuck = true
	
	if stuck:
		stuck_timer += delta
		if stuck_timer >= STUCK_TIME:
			_game_over()
	else:
		stuck_timer = 0.0
	
	if prompt:
		prompt.position = player.global_position + Vector2(-80, -60)
	_check_near_items()

func _shelf_collapse():
	if falling_shelf:
		falling_shelf.visible = true
		var tween = create_tween()
		tween.tween_property(falling_shelf, "rotation", 90, 0.5)
		tween.parallel().tween_property(falling_shelf, "global_position", falling_shelf.global_position + Vector2(50, 100), 0.5)
		await tween.finished
	
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			if falling_shelf:
				var dist = enemy.global_position.distance_to(falling_shelf.global_position)
				if dist < 80:
					enemy.queue_free()
					_spawn_blood(enemy.global_position)
	
	shelf_climbing = false
	player.set_physics_process(true)

func _activate_elevator():
	elevator_ready = true
	has_tool = false
	if elevator_button:
		elevator_button.modulate = Color.GREEN
	if prompt:
		prompt.visible = false

func _check_near_items():
	if game_ended:
		return
	
	if player.has_item:
		if not first_item_taken:
			_slow_time(true)
			if prompt:
				prompt.text = "Нажми E чтобы кинуть"
				prompt.visible = true
		else:
			_slow_time(false)
			if prompt:
				prompt.visible = false
		return
	
	if slow_used:
		_slow_time(false)
	
	if has_node("Items"):
		for item in $Items.get_children():
			if item is Area2D and not item.is_queued_for_deletion():
				var dist = item.global_position.distance_to(player.global_position)
				if dist < 80:
					if not slow_used:
						_slow_time(true)
						slow_used = true
					if prompt:
						prompt.text = "Нажми E чтобы взять"
						prompt.visible = true
					return
	
	if prompt:
		prompt.visible = false

func _slow_time(enable: bool):
	if enable:
		Engine.time_scale = 0.3
		if slow_overlay:
			slow_overlay.color = Color(0, 0, 0, 0.3)
		is_slowed = true
	else:
		Engine.time_scale = 1.0
		if slow_overlay:
			slow_overlay.color = Color(0, 0, 0, 0)
		is_slowed = false

func _hit_enemy(pos: Vector2):
	if game_ended:
		return
	if has_node("Enemies"):
		for enemy in $Enemies.get_children():
			if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
				var dist = enemy.global_position.distance_to(pos)
				if dist < 80:
					enemy.queue_free()
					break

func _win():
	game_ended = true
	Engine.time_scale = 1.0
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://код/сцены/main_menu.tscn")

func _game_over():
	if game_ended:
		return
	game_ended = true
	Engine.time_scale = 1.0
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	if game_over_label:
		game_over_label.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://код/сцены/Level_3.tscn")
