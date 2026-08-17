extends Node2D

@onready var player: CharacterBody2D = $Mecha_Fish
@onready var prompt: Label = $UI/PromptLabel
@onready var elevator: ColorRect = $Elevator
@onready var elevator_button: Area2D = $ElevatorButton
@onready var exclamation: Label = $UI/ExclamationLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var forklift: CharacterBody2D = $ForkliftScene/Forklift
@onready var falling_shelf: StaticBody2D = $ForkliftScene/FallingShelf
@onready var forklift_trigger: Area2D = $ForkliftTrigger
@onready var death_zone: Area2D = $DeathZone
@onready var death_zone2: Area2D = $DeathZone2
@onready var camera: Camera2D = $MechaFishCamera
@onready var pause_menu: CanvasLayer = $Pausemenu

enum State { INTRO, RUNNING, ELEVATOR_WAIT, ELEVATOR_GO, WIN, GAMEOVER }
var state: State = State.INTRO
var elevator_timer: float = 0.0
var can_press_button: bool = false
var forklift_activated: bool = false
var shelf_climbed: bool = false
var _shelf_climbing: bool = false
var is_game_over: bool = false
var check_timer: Timer

var forklift_ready_for_throw: bool = false
var forklift_stopped: bool = false

var parry_done: bool = false
var parry_trigger: Area2D = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	player.set_physics_process(false)
	prompt.visible = false
	exclamation.visible = false
	game_over_label.visible = false
	forklift.visible = false
	falling_shelf.visible = false
	
	camera.zoom = Vector2(1.8, 1.8)
	camera.limit_left = -5000
	camera.limit_right = 5000
	camera.limit_top = -5000
	camera.limit_bottom = 5000
	
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(false)
			enemy.player = player
	
	check_timer = Timer.new()
	check_timer.wait_time = 0.05
	check_timer.autostart = true
	check_timer.timeout.connect(_check_enemy_collision)
	add_child(check_timer)
	
	forklift_trigger.body_entered.connect(func(body):
		if body == player and not forklift_activated:
			_activate_forklift()
	)
	
	death_zone.body_entered.connect(func(body):
		if body == player and not is_game_over:
			_game_over()
	)
	
	death_zone2.body_entered.connect(func(body):
		if body == player and not is_game_over:
			_game_over()
	)
	
	# Парирование
	var parrying_scene = get_node_or_null("ParryingScene")
	if parrying_scene:
		parry_trigger = parrying_scene.get_node_or_null("ParryTrigger")
		var enemy = parrying_scene.get_node_or_null("AttackParry")
		
		if parry_trigger and enemy:
			print("✅ Триггер и враг найдены!")
			enemy.visible = false
			enemy.set_physics_process(false)
			enemy.set_process(false)
			enemy.collision_layer = 0
			enemy.collision_mask = 0
			
			var col = enemy.get_node_or_null("CollisionShape2D")
			if col:
				col.disabled = true
			
			parry_trigger.body_entered.connect(func(body):
				if body == player and not player.parry_done:
					print("🔔 ТРИГГЕР СРАБОТАЛ!")
					player.start_parry(enemy, _on_parry_complete)
					parry_trigger.set_deferred("monitoring", false)
			)
	
	if pause_menu:
		pause_menu.visible = false
		var continue_btn = pause_menu.get_node_or_null("ContinueButton")
		if continue_btn:
			continue_btn.pressed.connect(_on_continue_pressed)
	
	_start_intro()

func _on_parry_complete():
	print("✅ ПАРИРОВАНИЕ ЗАВЕРШЕНО!")
	parry_done = true
	
	if is_instance_valid(player):
		player.set_physics_process(true)
		player.set_process(true)
		player.is_vaulting = false
		player.is_climbing = false
		player.is_sliding = false
		player.is_crouching = false

func _start_intro():
	player.modulate = Color.RED
	prompt.text = "ЖМИ E! 6"
	prompt.visible = true
	
	var qte = 0
	while qte < 6:
		await get_tree().process_frame
		prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)
		if Input.is_action_just_pressed("interact"):
			qte += 1
			if qte < 6:
				prompt.text = "ЖМИ E! " + str(6 - qte)
	
	prompt.visible = false
	player.modulate = Color.WHITE
	
	exclamation.position = Vector2(player.global_position.x - 20, player.global_position.y - 50)
	exclamation.visible = true
	await get_tree().create_timer(1.0).timeout
	exclamation.visible = false
	
	state = State.RUNNING
	player.set_physics_process(true)
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(true)

func _check_enemy_collision():
	if state != State.RUNNING or is_game_over:
		return
	
	var player_pos = player.global_position
	
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			var dist = enemy.global_position.distance_to(player_pos)
			if dist < 45:
				_game_over()
				return

func _activate_forklift():
	forklift_activated = true
	forklift.visible = true
	falling_shelf.visible = true
	
	var shelf_y = falling_shelf.global_position.y
	var fork_y = forklift.global_position.y
	
	falling_shelf.global_position = Vector2(player.global_position.x + 1200, shelf_y)
	forklift.global_position = Vector2(player.global_position.x + 1300, fork_y)
	forklift.set("active", true)
	
	var t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_parallel(true)
	t.tween_property(falling_shelf, "global_position:x", player.global_position.x + 150, 3.0)
	t.tween_property(forklift, "global_position:x", player.global_position.x + 250, 3.0)
	await t.finished
	
	forklift.set("active", false)
	forklift.set_physics_process(false)
	forklift.velocity = Vector2.ZERO
	
	forklift_ready_for_throw = true
	
	prompt.text = "Кинь предмет в погрузчик!"
	prompt.visible = true

func _process(delta):
	if get_tree().paused or state == State.GAMEOVER:
		return
	
	if camera:
		camera.global_position = player.global_position
	
	if state == State.RUNNING:
		_check_enemy_collision()
		
		if forklift_activated and not shelf_climbed and falling_shelf.visible:
			var dist = player.global_position.distance_to(falling_shelf.global_position)
			if dist < 150 and Input.is_action_just_pressed("interact"):
				shelf_climbed = true
				_climb_shelf()
			elif dist < 150:
				prompt.text = "Нажми E чтобы взобраться"
				prompt.visible = true
				prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)
			else:
				prompt.visible = false
		
		if forklift_ready_for_throw and not forklift_stopped:
			var dist = player.global_position.distance_to(forklift.global_position)
			if dist < 200 and player.has_item:
				player.set_can_throw(true)
				prompt.text = "Нажми E чтобы кинуть предмет в погрузчик"
				prompt.visible = true
				prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)
				
				if Input.is_action_just_pressed("interact"):
					_throw_item_at_forklift()
			else:
				player.set_can_throw(false)
				if prompt.text != "Кинь предмет в погрузчик!":
					prompt.visible = false
		
		# ЛИФТ - ТОЛЬКО ПОСЛЕ ПАРИРОВАНИЯ
		if player.global_position.x > 3200 and parry_done:
			if not can_press_button:
				can_press_button = true
				prompt.text = "Нажми E чтобы вызвать лифт"
				prompt.visible = true
				prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)
			elif Input.is_action_just_pressed("interact"):
				can_press_button = false
				prompt.visible = false
				player.set_physics_process(false)
				state = State.ELEVATOR_WAIT
				elevator_timer = 3.0
				prompt.text = "Жди лифт..."
				prompt.visible = true
				prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)
		
		if prompt.visible and state == State.RUNNING:
			if not prompt.text.contains("Кинь") and not prompt.text.contains("Нажми E чтобы взобраться"):
				prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)
	
	elif state == State.ELEVATOR_WAIT:
		elevator_timer -= delta
		if elevator_timer <= 0:
			state = State.ELEVATOR_GO
			elevator.color = Color.GREEN
			var t = create_tween()
			t.tween_property(player, "global_position:x", elevator.global_position.x + 30, 0.5)
			await t.finished
			player.visible = false
			prompt.visible = false
			var lt = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			lt.tween_property(elevator, "global_position:y", elevator.global_position.y - 400, 1.0)
			await lt.finished
			await get_tree().create_timer(0.5).timeout
			_win()
	
	if _shelf_climbing:
		prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)
		
		if Input.is_action_pressed("ui_up"):
			player.global_position.y -= 2
		
		var shelf_top = falling_shelf.global_position.y - falling_shelf.get_node("CollisionShape2D").shape.size.y + 10
		
		if player.global_position.y <= shelf_top:
			player.global_position.y = shelf_top
			_shelf_climbing = false
			prompt.visible = false
			player.set_physics_process(true)

func _climb_shelf():
	player.set_physics_process(false)
	_shelf_climbing = true
	prompt.text = "ЖМИ W чтобы лезть!"
	prompt.visible = true
	prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)

func _throw_item_at_forklift():
	if not player.has_item or forklift_stopped:
		return
	
	forklift_stopped = true
	forklift_ready_for_throw = false
	
	player.has_item = false
	player.held_icon.visible = false
	player.set_can_throw(false)
	prompt.visible = false
	
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.6)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 100
	add_child(flash)
	var ft = create_tween()
	ft.tween_property(flash, "modulate:a", 0.0, 0.2)
	await ft.finished
	flash.queue_free()
	
	forklift.modulate = Color(0.4, 0.4, 0.4, 1)
	
	if falling_shelf:
		var t = create_tween()
		t.tween_property(falling_shelf, "global_position:y", falling_shelf.global_position.y + 150, 0.6)
		t.parallel().tween_property(falling_shelf, "rotation", 0.3, 0.6)
	
	forklift_trigger.monitoring = false
	
	prompt.text = "Погрузчик остановлен!"
	prompt.visible = true
	await get_tree().create_timer(2.0).timeout
	prompt.visible = false

func _game_over():
	if is_game_over or state == State.GAMEOVER:
		return
	
	is_game_over = true
	state = State.GAMEOVER
	
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(false)
	
	var overlay = ColorRect.new()
	overlay.color = Color(1, 0, 0, 0.3)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	add_child(overlay)
	
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(1.0)
	
	game_over_label.visible = true
	game_over_label.text = "ТЕБЯ СХВАТИЛИ!"
	game_over_label.modulate = Color.RED
	game_over_label.position = Vector2(player.global_position.x - 150, player.global_position.y - 50)
	game_over_label.z_index = 101
	
	Engine.time_scale = 0.3
	await get_tree().create_timer(0.5).timeout
	Engine.time_scale = 1.0
	
	var fade_tween = create_tween()
	fade_tween.tween_property(overlay, "modulate:a", 0.0, 0.5)
	await fade_tween.finished
	overlay.queue_free()
	
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.z_index = 200
	add_child(black)
	
	var black_tween = create_tween()
	black_tween.tween_property(black, "modulate:a", 1.0, 0.5)
	await black_tween.finished
	
	get_tree().reload_current_scene()

func _win():
	state = State.WIN
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.z_index = 200
	add_child(black)
	
	var tween = create_tween()
	tween.tween_property(black, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuFactory.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var passage_trigger = $TightPassageTrigger
		
		# Если игрок рядом с триггером и триггер ещё не активен
		if passage_trigger and not passage_trigger.is_active:
			var bodies = passage_trigger.get_overlapping_bodies()
			if bodies.has(player):
				print("🔴 НАЖАТА Е! ВХОД В ПРОХОД!")
				
				# СДВИГАЕМ ИГРОКА ВПЕРЁД НА 5 ПИКСЕЛЕЙ
				player.global_position.x += 5
				
				# АКТИВИРУЕМ МИНИ-ИГРУ
				passage_trigger.activate(player)
				return
		
		# ОСВОБОЖДЕНИЕ В НАЧАЛЕ (если нужно)
		if player.has_method("set_movement_blocked") and player.movement_blocked:
			player.set_movement_blocked(false)
			print("🔓 ИГРОК ОСВОБОЖДЁН!")
			return
	
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause():
	if state == State.GAMEOVER or state == State.WIN:
		return
	
	if not pause_menu:
		return
	
	if pause_menu.visible:
		pause_menu.visible = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		pause_menu.visible = true
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_continue_pressed():
	if pause_menu:
		pause_menu.visible = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
