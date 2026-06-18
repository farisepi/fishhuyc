extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var prompt: Label = $UI/PromptLabel
@onready var enemies_label: Label = $UI/EnemiesLabel
@onready var forklift: CharacterBody2D = $ForkliftScene/Forklift
@onready var moving_shelf: StaticBody2D = $ForkliftScene/MovingShelf
@onready var elevator: ColorRect = $Elevator
@onready var elevator_button: Area2D = $ElevatorButton
@onready var exclamation: Label = $ExclamationLabel

enum State { INTRO, RUNNING, FORKLIFT, ELEVATOR_WAIT, ELEVATOR_GO, WIN }
var state: State = State.INTRO
var enemies_alive: int = 5
var qte_count: int = 0
var qte_needed: int = 6
var elevator_timer: float = 0.0
var can_press_button: bool = false

func _ready():
	player.set_physics_process(false)
	forklift.set_physics_process(false)
	forklift.visible = false
	moving_shelf.visible = false
	enemies_label.text = "Врагов: 5"
	prompt.visible = false
	
	_start_intro()

func _start_intro():
	prompt.text = "ЖМИ E!"
	prompt.visible = true
	prompt.position = player.global_position + Vector2(-80, -60)
	
	# Ждём 6 нажатий E
	while qte_count < qte_needed:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact"):
			qte_count += 1
			prompt.text = "ЖМИ E! " + str(qte_needed - qte_count)
			if qte_count >= qte_needed:
				break
	
	prompt.visible = false
	
	# Восклицательный знак
	exclamation.position = player.global_position + Vector2(-20, -50)
	exclamation.visible = true
	await get_tree().create_timer(1.0).timeout
	exclamation.visible = false
	
	# Рыба бежит
	player.set_physics_process(true)
	state = State.RUNNING

func _process(delta):
	if state == State.RUNNING:
		_process_running(delta)
	elif state == State.FORKLIFT:
		_process_forklift(delta)
	elif state == State.ELEVATOR_WAIT:
		_process_elevator_wait(delta)

func _process_running(delta):
	# Враги бегут за рыбой
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			enemy.global_position.x -= 60 * delta
			if enemy.global_position.distance_to(player.global_position) < 30:
				_game_over()
				return
	
	# Погрузчик появляется когда рыба на X < 900
	if player.global_position.x < 900 and state == State.RUNNING:
		_start_forklift_sequence()
	
	# Кнопка лифта
	if player.global_position.x < 150 and not can_press_button:
		can_press_button = true
		prompt.text = "Нажми E чтобы вызвать лифт"
		prompt.visible = true
		prompt.position = player.global_position + Vector2(-80, -60)
	
	if can_press_button and Input.is_action_just_pressed("interact"):
		can_press_button = false
		prompt.visible = false
		elevator_button.modulate = Color.GREEN
		state = State.ELEVATOR_WAIT
		elevator_timer = 3.0
		prompt.text = "Жди лифт..."
		prompt.visible = true
		prompt.position = player.global_position + Vector2(-80, -60)
	
	# Подсказка у предметов
	_check_items()

func _start_forklift_sequence():
	state = State.FORKLIFT
	forklift.visible = true
	moving_shelf.visible = true
	forklift.set_physics_process(true)
	
	# Стеллаж выезжает
	var tween = create_tween()
	tween.tween_property(moving_shelf, "modulate", Color.WHITE, 0.5)
	tween.parallel().tween_property(moving_shelf, "global_position:x", 650, 0.5)
	await tween.finished
	
	# Подсказка — запрыгнуть
	prompt.text = "Нажми E чтобы взобраться"
	prompt.visible = true
	prompt.position = player.global_position + Vector2(-80, -60)

func _process_forklift(delta):
	if state != State.FORKLIFT:
		return
	
	if Input.is_action_just_pressed("interact") and player.global_position.distance_to(moving_shelf.global_position) < 80:
		_climb_shelf()

func _climb_shelf():
	prompt.visible = false
	player.set_physics_process(false)
	
	# Рыба взбирается
	var tween = create_tween()
	tween.tween_property(player, "global_position", moving_shelf.global_position + Vector2(0, -60), 0.3)
	await tween.finished
	
	# Стеллаж падает
	var fall_tween = create_tween()
	fall_tween.tween_property(moving_shelf, "rotation", 90, 0.5)
	fall_tween.parallel().tween_property(moving_shelf, "global_position:y", 350, 0.5)
	await fall_tween.finished
	
	# Враги задерживаются
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			enemy.global_position.x += 200  # Отбрасывает назад
	
	moving_shelf.visible = false
	forklift.visible = false
	
	player.set_physics_process(true)
	state = State.RUNNING

func _process_elevator_wait(delta):
	elevator_timer -= delta
	prompt.position = player.global_position + Vector2(-80, -60)
	
	if elevator_timer <= 0:
		state = State.ELEVATOR_GO
		prompt.text = "Заходи!"
		elevator.color = Color.GREEN
		
		# Рыба заходит в лифт
		player.set_physics_process(false)
		var tween = create_tween()
		tween.tween_property(player, "global_position", elevator.global_position + Vector2(30, 20), 0.5)
		await tween.finished
		
		player.visible = false
		prompt.visible = false
		await get_tree().create_timer(0.5).timeout
		
		# Враги подбегают к лифту но поздно
		_win()

func _check_items():
	for item in $Items.get_children():
		if item is Area2D and not item.is_queued_for_deletion():
			var dist = item.global_position.distance_to(player.global_position)
			if dist < 60:
				prompt.text = "Нажми E чтобы взять"
				prompt.visible = true
				prompt.position = player.global_position + Vector2(-80, -60)
				if Input.is_action_just_pressed("interact"):
					_grab_item(item)
				return
	
	if not can_press_button:
		prompt.visible = false

func _grab_item(item: Area2D):
	item.queue_free()
	prompt.text = "Нажми E чтобы кинуть"
	
	# Ждём бросок
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact"):
			break
	
	# Кидаем в ближайшего врага
	var target_pos = player.global_position + Vector2(300, 0)
	var closest_dist = 9999.0
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			var d = enemy.global_position.distance_to(player.global_position)
			if d < closest_dist:
				closest_dist = d
				target_pos = enemy.global_position
	
	# Анимация полёта
	var thrown = ColorRect.new()
	thrown.color = Color(0.8, 0.5, 0.2)
	thrown.size = Vector2(20, 20)
	thrown.position = player.global_position + Vector2(0, -20)
	add_child(thrown)
	
	var tween = create_tween()
	tween.tween_property(thrown, "global_position", target_pos, 0.2)
	tween.finished.connect(thrown.queue_free)
	
	await get_tree().create_timer(0.15).timeout
	_hit_enemy(target_pos)
	prompt.visible = false

func _hit_enemy(pos: Vector2):
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			if enemy.global_position.distance_to(pos) < 80:
				enemy.queue_free()
				enemies_alive -= 1
				enemies_label.text = "Врагов: " + str(enemies_alive)
				break

func _win():
	enemies_label.text = "СВОБОДА!"
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Base/Scenes/Main_Menu.tscn")

func _game_over():
	player.set_physics_process(false)
	enemies_label.text = "ПОЙМАЛИ!"
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Base/Scenes/Level_3.tscn")
