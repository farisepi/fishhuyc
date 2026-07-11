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

enum State { INTRO, RUNNING, ELEVATOR_WAIT, ELEVATOR_GO, WIN }
var state: State = State.INTRO
var elevator_timer: float = 0.0
var can_press_button: bool = false
var forklift_activated: bool = false
var shelf_climbed: bool = false

func _ready():
	player.set_physics_process(false)
	prompt.visible = false
	exclamation.visible = false
	game_over_label.visible = false
	forklift.visible = false
	falling_shelf.visible = false
	
	var cam = player.get_node("Camera2D")
	if cam:
		cam.global_position = player.global_position
	
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(false)
			enemy.player = player
	
	forklift_trigger.body_entered.connect(func(body):
		if body == player and not forklift_activated:
			_activate_forklift()
	)
	
	_start_intro()

func _start_intro():
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	player.visible = true
	player.modulate = Color.WHITE
	
	var cam = player.get_node("Camera2D")
	if cam:
		cam.global_position = player.global_position
	
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
	
	forklift.global_position = Vector2(player.global_position.x + 800, player.global_position.y)
	forklift.set("active", true)
	
	falling_shelf.global_position = forklift.global_position + Vector2(0, -100)
	
	var target_x = player.global_position.x + 200
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(forklift, "global_position:x", target_x, 1.0)
	tween.tween_property(falling_shelf, "global_position:x", target_x, 1.0)
	await tween.finished
	
	forklift.set("active", false)

func _process(delta):
	if state == State.RUNNING:
		for enemy in $Enemies.get_children():
			if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
				if enemy.global_position.distance_to(player.global_position) < 40:
					_game_over()
					return
		
		if forklift_activated and not shelf_climbed and falling_shelf.visible:
			if player.global_position.distance_to(falling_shelf.global_position) < 100:
				prompt.text = "Нажми E чтобы взобраться"
				prompt.visible = true
				if Input.is_action_just_pressed("interact"):
					shelf_climbed = true
					prompt.visible = false
					_climb_shelf()
		
		if player.global_position.x > 3200 and not can_press_button:
			can_press_button = true
			prompt.text = "Нажми E чтобы вызвать лифт"
			prompt.visible = true
		
		if can_press_button and Input.is_action_just_pressed("interact"):
			can_press_button = false
			prompt.visible = false
			player.set_physics_process(false)
			elevator_button.modulate = Color.GREEN
			state = State.ELEVATOR_WAIT
			elevator_timer = 3.0
			prompt.text = "Жди лифт..."
			prompt.visible = true
	
	elif state == State.ELEVATOR_WAIT:
		elevator_timer -= delta
		
		if elevator_timer <= 0:
			state = State.ELEVATOR_GO
			prompt.text = "Заходи!"
			elevator.color = Color.GREEN
			
			var tween = create_tween()
			tween.tween_property(player, "global_position:x", elevator.global_position.x + 30, 0.5)
			await tween.finished
			
			player.visible = false
			prompt.visible = false
			
			var lift_tween = create_tween()
			lift_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			lift_tween.tween_property(elevator, "global_position:y", elevator.global_position.y - 400, 1.0)
			await lift_tween.finished
			
			await get_tree().create_timer(0.5).timeout
			_win()
	
	if prompt.visible:
		prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)

func _climb_shelf():
	player.set_physics_process(false)
	
	prompt.text = "ЖМИ W чтобы лезть!"
	prompt.visible = true
	
	var climb_progress = 0.0
	while climb_progress < 1.0:
		await get_tree().process_frame
		if Input.is_action_pressed("ui_up"):
			climb_progress += 0.02
			player.global_position.y -= 2
		prompt.position = Vector2(player.global_position.x - 80, player.global_position.y - 60)
	
	prompt.visible = false
	
	var tween = create_tween()
	tween.tween_property(player, "global_position:x", falling_shelf.global_position.x - 60, 0.3)
	await tween.finished
	
	player.set_physics_process(true)
	falling_shelf.visible = false

func _win():
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Base/Scenes/Main_Menu.tscn")

func _game_over():
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	
	game_over_label.visible = true
	await get_tree().create_timer(2.0).timeout
	game_over_label.visible = false
	
	get_tree().reload_current_scene()
