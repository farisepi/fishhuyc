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

enum State { INTRO, RUNNING, ELEVATOR_WAIT, ELEVATOR_GO, WIN }
var state: State = State.INTRO
var elevator_timer: float = 0.0
var can_press_button: bool = false
var forklift_activated: bool = false
var shelf_climbed: bool = false
var _shelf_climbing: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	player.set_physics_process(false)
	prompt.visible = false
	exclamation.visible = false
	game_over_label.visible = false
	forklift.visible = false
	falling_shelf.visible = false
	
	camera.zoom = Vector2(1.8, 1.8)
	camera.limit_left = -1205
	camera.limit_right = 3525
	camera.limit_top = -1000
	camera.limit_bottom = 500
	
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(false)
			enemy.player = player
	
	forklift_trigger.body_entered.connect(func(body):
		if body == player and not forklift_activated:
			_activate_forklift()
	)
	
	death_zone.body_entered.connect(func(body):
		if body == player:
			_game_over()
	)
	
	death_zone2.body_entered.connect(func(body):
		if body == player:
			_game_over()
	)
	
	_start_intro()

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

func _process(delta):
	if camera:
		camera.global_position = player.global_position
	
	if get_tree().paused:
		return
	
	if state == State.RUNNING:
		for enemy in $Enemies.get_children():
			if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
				if enemy.global_position.distance_to(player.global_position) < 40:
					_game_over()
					return
		
		if forklift_activated and not shelf_climbed and falling_shelf.visible:
			var dist = player.global_position.distance_to(falling_shelf.global_position)
			if dist < 150 and Input.is_action_just_pressed("interact"):
				shelf_climbed = true
				_climb_shelf()
			elif dist < 150:
				prompt.text = "Нажми E чтобы взобраться"
				prompt.visible = true
		
		if player.global_position.x > 3200:
			if not can_press_button:
				can_press_button = true
				prompt.text = "Нажми E чтобы вызвать лифт"
				prompt.visible = true
			elif Input.is_action_just_pressed("interact"):
				can_press_button = false
				prompt.visible = false
				player.set_physics_process(false)
				state = State.ELEVATOR_WAIT
				elevator_timer = 3.0
				prompt.text = "Жди лифт..."
				prompt.visible = true
	
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
	
	if prompt.visible:
		prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)

func _climb_shelf():
	player.set_physics_process(false)
	_shelf_climbing = true
	prompt.text = "ЖМИ W чтобы лезть!"
	prompt.visible = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if has_node("PauseMenu"):
			$PauseMenu.visible = true
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _win():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Base/Scenes/Main_Menu.tscn")

func _game_over():
	player.set_physics_process(false)
	game_over_label.visible = true
	await get_tree().create_timer(2.0).timeout
	game_over_label.visible = false
	get_tree().reload_current_scene()
