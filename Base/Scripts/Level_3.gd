extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var finish_line: Area2D = $FinishLine
@onready var prompt: Label = $UI/PromptLabel
@onready var enemies_label: Label = $UI/EnemiesLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var slow_overlay: ColorRect = $UI/SlowOverlay
@onready var wait_label: Label = $UI/WaitLabel
@onready var player_fake: ColorRect = $IntroCutscene/PlayerFake
@onready var door: ColorRect = $IntroCutscene/Door
@onready var guard1: ColorRect = $IntroCutscene/Guard1
@onready var other_guards: ColorRect = $IntroCutscene/OtherGuards
@onready var exclamation_label: Label = $IntroCutscene/ExclamationLabel
@onready var elevator: ColorRect = $Elevator
@onready var forklift: CharacterBody2D = $Forklift

var enemies_alive: int = 11
var game_ended: bool = false
var is_slowed: bool = false
var slow_used: bool = false
var first_item_taken: bool = false
var stuck_timer: float = 0.0
const STUCK_TIME: float = 2.0
var at_elevator: bool = false
var intro_done: bool = false
var forklift_hits: int = 0
var wave1_done: bool = false
var wave2_done: bool = false
var wave3_done: bool = false

func _ready():
	player.visible = false
	player.set_physics_process(false)
	forklift.visible = false
	forklift.set_physics_process(false)
	finish_line.body_entered.connect(func(body):
		if body == player and not game_ended:
			_arrive_at_elevator()
	)
	_setup_wave_triggers()
	_setup_falling_boxes()
	enemies_alive = $Enemies.get_child_count() + 1
	_update_ui()
	game_over_label.set_anchors_preset(Control.PRESET_CENTER)
	game_over_label.position = Vector2(0, 0)
	wait_label.set_anchors_preset(Control.PRESET_CENTER)
	wait_label.position = Vector2(0, 80)
	_start_intro_cutscene()

func _setup_wave_triggers():
	for trigger in $WaveTriggers.get_children():
		if trigger is Area2D:
			trigger.body_entered.connect(func(body):
				if body == player:
					_spawn_wave(trigger.name)
			)

func _setup_falling_boxes():
	for box in $FallingBoxes.get_children():
		if box is StaticBody2D:
			_start_falling_box(box)

func _start_falling_box(box: StaticBody2D):
	var start_y = box.position.y
	while not game_ended:
		await get_tree().create_timer(randf_range(4.0, 7.0))
		if game_ended:
			break
		box.position.y = start_y
		var tween = create_tween()
		tween.tween_property(box, "position:y", 340, 0.8)
		await tween.finished
		var dist = box.global_position.distance_to(player.global_position)
		if dist < 50:
			player.velocity.x *= 0.5
			await get_tree().create_timer(1.0).timeout
			player.velocity.x = player.run_speed * -1
		for enemy in $Enemies.get_children():
			if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
				var e_dist = box.global_position.distance_to(enemy.global_position)
				if e_dist < 50:
					enemy.queue_free()
					enemies_alive -= 1
					_update_ui()
		box.position.y = start_y

func _spawn_wave(name: String):
	match name:
		"WaveTrigger1":
			if wave1_done:
				return
			wave1_done = true
			_spawn_enemy_at(1550, 290)
			_spawn_enemy_at(1500, 290)
			_spawn_enemy_at(1450, 290)
		"WaveTrigger2":
			if wave2_done:
				return
			wave2_done = true
			_spawn_enemy_at(1050, 290)
			_spawn_enemy_at(1000, 290)
			forklift.visible = true
			forklift.global_position = Vector2(1400, 270)
			forklift.set_physics_process(false)
			var tween = create_tween()
			tween.tween_property(forklift, "global_position", Vector2(1350, 270), 0.5)
			await tween.finished
			await get_tree().create_timer(0.5).timeout
			forklift.set_physics_process(true)
		"WaveTrigger3":
			if wave3_done:
				return
			wave3_done = true
			_spawn_enemy_at(550, 290)
			_spawn_enemy_at(500, 290)
			_spawn_enemy_at(450, 290)

func _spawn_enemy_at(x: float, y: float):
	var enemy_scene = load("res://код/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.global_position = Vector2(x, y)
	$Enemies.add_child(enemy)

func _start_intro_cutscene():
	player_fake.visible = true
	door.visible = true
	guard1.visible = true
	other_guards.visible = true
	
	door.position = Vector2(2157, 278)
	player_fake.position = Vector2(2150, 278)
	guard1.position = Vector2(2130, 278)
	other_guards.position = Vector2(2080, 278)
	
	await get_tree().create_timer(0.3).timeout
	
	var tween = create_tween()
	tween.tween_property(player_fake, "position", Vector2(2130, 278), 0.3)
	await tween.finished
	
	guard1.position = player_fake.position + Vector2(-15, 0)
	await get_tree().create_timer(0.2).timeout
	
	player_fake.modulate = Color.RED
	await get_tree().create_timer(0.15).timeout
	
	var throw_tween = create_tween()
	throw_tween.tween_property(guard1, "position", other_guards.position, 0.3)
	player_fake.modulate = Color(0.3, 0.5, 1.0)
	await throw_tween.finished
	
	exclamation_label.position = player_fake.position + Vector2(-10, -45)
	exclamation_label.visible = true
	await get_tree().create_timer(0.6).timeout
	exclamation_label.visible = false
	
	var run_tween = create_tween()
	run_tween.tween_property(player_fake, "position", Vector2(2000, 278), 0.5)
	await run_tween.finished
	
	$IntroCutscene.visible = false
	player.visible = true
	player.set_physics_process(true)
	player.global_position = Vector2(2000, 278)
	intro_done = true

func _arrive_at_elevator():
	at_elevator = true
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	wait_label.text = "Жди лифт..."
	wait_label.visible = true
	
	await get_tree().create_timer(2.0).timeout
	elevator.color = Color.GREEN
	wait_label.text = "Заходи!"
	await get_tree().create_timer(0.5).timeout
	
	var tween = create_tween()
	tween.tween_property(player, "global_position", Vector2(elevator.global_position.x + 30, player.global_position.y), 0.5)
	await tween.finished
	
	wait_label.text = ""
	player.visible = false
	await get_tree().create_timer(1.0).timeout
	_win()

func _process(delta):
	if game_ended:
		return
	
	if at_elevator:
		return
	
	if forklift.visible and forklift.is_physics_processing():
		if forklift.global_position.distance_to(player.global_position) < 50:
			_game_over()
	
	if $ConveyorBelt.get_node("CollisionShape2D"):
		var conv_rect = Rect2($ConveyorBelt.global_position - Vector2(100, 5), Vector2(200, 10))
		var player_rect = Rect2(player.global_position - Vector2(15, 25), Vector2(30, 50))
		if conv_rect.intersects(player_rect):
			player.velocity.x = player.run_speed * -0.3
	
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			if enemy.global_position.distance_to(player.global_position) < 30:
				_game_over()
				return
	
	var stuck = false
	
	for vault in $Vaults.get_children():
		if vault is StaticBody2D:
			var rect = Rect2(vault.global_position - Vector2(20, 25), Vector2(40, 50))
			var player_rect = Rect2(player.global_position - Vector2(15, 25), Vector2(30, 50))
			if rect.intersects(player_rect) and player.is_on_floor():
				stuck = true
	
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
	
	prompt.position = player.global_position + Vector2(-80, -60)
	_check_near_items()

func _check_near_items():
	if game_ended:
		return
	
	if player.has_item:
		if not first_item_taken:
			_slow_time(true)
			prompt.text = "Нажми E чтобы кинуть"
			prompt.visible = true
		else:
			_slow_time(false)
			prompt.visible = false
		return
	
	if slow_used:
		_slow_time(false)
	
	for item in $Items.get_children():
		if item is Area2D and not item.is_queued_for_deletion():
			var dist = item.global_position.distance_to(player.global_position)
			if dist < 80:
				if not slow_used:
					_slow_time(true)
					slow_used = true
				prompt.text = "Нажми E чтобы взять"
				prompt.visible = true
				return
	
	prompt.visible = false

func _slow_time(enable: bool):
	if enable:
		Engine.time_scale = 0.3
		slow_overlay.color = Color(0, 0, 0, 0.3)
		is_slowed = true
	else:
		Engine.time_scale = 1.0
		slow_overlay.color = Color(0, 0, 0, 0)
		is_slowed = false

func _hit_enemy(pos: Vector2):
	if game_ended:
		return
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			var dist = enemy.global_position.distance_to(pos)
			if dist < 80:
				enemy.queue_free()
				enemies_alive -= 1
				_update_ui()
				break
	if forklift.visible:
		var dist = forklift.global_position.distance_to(pos)
		if dist < 80:
			forklift_hits += 1
			if forklift_hits >= 2:
				forklift.queue_free()
				enemies_alive -= 1
				_update_ui()

func _update_ui():
	enemies_label.text = "Врагов: " + str(enemies_alive)
	if enemies_alive <= 0:
		enemies_label.text = "ВСЕ УБИТЫ! Беги к лифту!"

func _win():
	game_ended = true
	Engine.time_scale = 1.0
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	enemies_label.text = "СВОБОДА!"
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://код/сцены/main_menu.tscn")

func _game_over():
	if game_ended:
		return
	game_ended = true
	Engine.time_scale = 1.0
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	game_over_label.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://код/сцены/chase_level_.tscn")
