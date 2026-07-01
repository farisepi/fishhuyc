extends Node2D

@onready var player: CharacterBody2D = $Mecha_Fish
@onready var prompt: Label = $UI/PromptLabel
@onready var elevator: ColorRect = $Elevator
@onready var elevator_button: Area2D = $ElevatorButton
@onready var exclamation: Label = $UI/ExclamationLabel

enum State { INTRO, RUNNING, ELEVATOR_WAIT, ELEVATOR_GO, WIN }
var state: State = State.INTRO
var elevator_timer: float = 0.0
var can_press_button: bool = false

func _ready():
	player.set_physics_process(false)
	prompt.visible = false
	exclamation.visible = false
	
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(false)
	
	_start_intro()

func _start_intro():
	# Ставим рыбу на пол
	player.global_position = Vector2(100, 300)
	player.velocity = Vector2.ZERO
	player.visible = true
	player.modulate = Color.WHITE
	
	# Выбегает — твин только по X
	var tween = create_tween()
	tween.tween_property(player, "global_position:x", 200, 0.4)
	await tween.finished
	
	# Хватают — краснеет
	player.modulate = Color.RED
	prompt.text = "ЖМИ E! 6"
	prompt.visible = true
	
	var qte = 0
	while qte < 6:
		await get_tree().process_frame
		prompt.position = Vector2(player.global_position.x - 80, 300 - 60)
		if Input.is_action_just_pressed("interact"):
			qte += 1
			prompt.text = "ЖМИ E! " + str(6 - qte)
	
	prompt.visible = false
	player.modulate = Color.WHITE
	
	exclamation.position = Vector2(player.global_position.x - 20, 300 - 50)
	exclamation.visible = true
	await get_tree().create_timer(1.0).timeout
	exclamation.visible = false
	
	state = State.RUNNING
	player.set_physics_process(true)
	
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(true)

func _process(delta):
	if state == State.RUNNING:
		for enemy in $Enemies.get_children():
			if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
				if enemy.global_position.distance_to(player.global_position) < 40:
					_game_over()
					return
		
		if player.global_position.x > 3200 and not can_press_button:
			can_press_button = true
			prompt.text = "Нажми E чтобы вызвать лифт"
			prompt.visible = true
		
		if can_press_button and Input.is_action_just_pressed("interact"):
			can_press_button = false
			prompt.visible = false
			player.set_physics_process(false)  # Блокируем движение
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
		prompt.position = player.global_position + Vector2(100, -2)

func _win():
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Base/Scenes/Main_Menu.tscn")

func _game_over():
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.z_index = 1000
	black.modulate.a = 0.0
	add_child(black)
	
	var t = create_tween()
	t.tween_property(black, "modulate:a", 1.0, 1.0)
	await t.finished
	
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Base/Scenes/Level_3.tscn")
