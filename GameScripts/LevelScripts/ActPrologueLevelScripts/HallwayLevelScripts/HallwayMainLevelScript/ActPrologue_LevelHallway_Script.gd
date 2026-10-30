extends Node2D

@onready var player: CharacterBody2D = $Mecha_Fish
@onready var elevator: ColorRect = $EndAct/Elevator
@onready var elevator_button: Area2D = $EndAct/ElevatorButton
@onready var forklift: CharacterBody2D = $ForkliftScene/Forklift
@onready var falling_shelf: StaticBody2D = $ForkliftScene/FallingShelf
@onready var forklift_trigger: Area2D = $ForkliftTrigger
@onready var death_zone: Area2D = $DeathZone
@onready var death_zone2: Area2D = $DeathZone2
@onready var camera: Camera2D = $Mecha_Fish/MechaFishCamera
@onready var pause_menu: CanvasLayer = $Pausemenu
@onready var shift_tutorial: CanvasLayer = $ShiftTutorial
@onready var shift_qte: CanvasLayer = $ShiftQTE
@onready var qte_button: CanvasLayer = $QTEButton

@export var sniper_scene: PackedScene = null
@export var sniper_spawn_position: Vector2 = Vector2(-1410, 462)
@export var escape_sniper_x: float = 3050.0
@export var sniper_trigger_x: float = 517.0
@export var sniper_trigger_y: float = 340.0

const INTRO_START_X: float = -1400.0
const INTRO_FADE_X: float = -1100.0
const INTRO_CAPTURE_X: float = -150.0
const INTRO_FADE_TIME: float = 3.5
const INTRO_RUN_TIME: float = 6.5
const ENEMY_MIN_GAP: float = 100.0
const ENEMY_SPACING: float = 55.0
const ENEMY_CATCHUP: float = 0.14
const FORKLIFT_PLAYER_TARGET_X: float = 4000.0
const FORKLIFT_TARGET_X: float = 7500.0

const CUTSCENE_BARS_HEIGHT: float = 140.0

enum State { INTRO_RUN, QTE_GRAB, RUNNING, SNIPER_CUTSCENE, FORKLIFT_CUTSCENE, FORKLIFT_QTE, ELEVATOR_WAIT, ELEVATOR_GO, WIN, GAMEOVER }
var state: State = State.INTRO_RUN
var elevator_timer: float = 0.0
var can_press_button: bool = false
var forklift_activated: bool = false
var shelf_climbed: bool = false
var _shelf_climbing: bool = false
var is_game_over: bool = false
var check_timer: Timer

var forklift_ready_for_throw: bool = false
var forklift_stopped: bool = false
var forklift_charging: bool = false

var parry_done: bool = false
var parry_trigger: Area2D = null

var sniper: Node = null
var sniper_active: bool = false
var sniper_cutscene_played: bool = false

var fade_overlay: ColorRect = null
var _intro_enemies: Array = []
var _intro_enemy_y_offsets: Array = []
var _intro_started: bool = false

var sniper_trigger: Area2D = null
var _input_locked: bool = false

var _bar_top: ColorRect = null
var _bar_bottom: ColorRect = null
var _cutscene_canvas: CanvasLayer = null

var _cam_was_processing: bool = false
var _cam_was_physics_processing: bool = false
var _cam_original_position: Vector2 = Vector2.ZERO
var _cam_original_zoom: Vector2 = Vector2.ONE
var _cam_original_offset: Vector2 = Vector2.ZERO

var _forklift_player_tween: Tween = null
var _forklift_tween: Tween = null
var _qte_throw_dir: int = 1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	player.global_position.x = INTRO_START_X
	_lock_player_input(true)
	player.velocity = Vector2.ZERO
	player.is_dead = false
	player.movement_blocked = false
	player.is_vaulting = false
	player.is_climbing = false
	player.is_climbing_animation = false
	player.is_sliding = false
	player.is_dashing = false
	player.is_blocking = false
	player.is_attacking = false
	player.is_landing = false
	player.modulate = Color.WHITE
	if player.sprite:
		player.sprite.modulate = Color.WHITE
		player.sprite.stop()
		player.sprite.play("Idle")

	forklift.visible = false
	falling_shelf.visible = false

	_intro_enemies.clear()
	_intro_enemy_y_offsets.clear()
	var px = player.global_position.x
	var py = player.global_position.y
	var idx = 0
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(false)
			enemy.set_process(false)
			enemy.player = player
			enemy.visible = true
			var y_off = enemy.global_position.y - py
			_intro_enemy_y_offsets.append(y_off)
			enemy.global_position = Vector2(
				px - ENEMY_MIN_GAP - idx * ENEMY_SPACING,
				py + y_off
			)
			_intro_enemies.append(enemy)
			idx += 1

	check_timer = Timer.new()
	check_timer.wait_time = 0.05
	check_timer.autostart = true
	check_timer.timeout.connect(_check_enemy_collision)
	add_child(check_timer)

	forklift_trigger.body_entered.connect(_on_forklift_trigger_entered)

	death_zone.body_entered.connect(func(body):
		if body == player and not is_game_over and state == State.RUNNING:
			is_game_over = true
			state = State.GAMEOVER
			_stop_all_world()
	)
	death_zone2.body_entered.connect(func(body):
		if body == player and not is_game_over and state == State.RUNNING:
			is_game_over = true
			state = State.GAMEOVER
			_stop_all_world()
	)

	_create_sniper_trigger()
	_create_cutscene_bars()

	_setup_parry_scene()
	_setup_entrance_gate()

	if pause_menu:
		pause_menu.hide()

	await get_tree().process_frame
	if is_instance_valid(camera):
		if camera.has_method("snap_to_target"):
			camera.snap_to_target()
		else:
			camera.global_position = player.global_position
		camera.reset_smoothing()

	_start_intro()

func _create_cutscene_bars():
	_cutscene_canvas = CanvasLayer.new()
	_cutscene_canvas.layer = 90
	add_child(_cutscene_canvas)

	_bar_top = ColorRect.new()
	_bar_top.color = Color.BLACK
	_bar_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_top.anchor_left = 0.0
	_bar_top.anchor_right = 1.0
	_bar_top.anchor_top = 0.0
	_bar_top.anchor_bottom = 0.0
	_bar_top.offset_top = -CUTSCENE_BARS_HEIGHT
	_bar_top.offset_bottom = 0.0
	_cutscene_canvas.add_child(_bar_top)

	_bar_bottom = ColorRect.new()
	_bar_bottom.color = Color.BLACK
	_bar_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_bottom.anchor_left = 0.0
	_bar_bottom.anchor_right = 1.0
	_bar_bottom.anchor_top = 1.0
	_bar_bottom.anchor_bottom = 1.0
	_bar_bottom.offset_top = 0.0
	_bar_bottom.offset_bottom = CUTSCENE_BARS_HEIGHT
	_cutscene_canvas.add_child(_bar_bottom)

func _show_cutscene_bars(duration: float = 0.5):
	var t = create_tween().set_parallel(true)
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_bar_top, "offset_top", 0.0, duration)
	t.tween_property(_bar_top, "offset_bottom", CUTSCENE_BARS_HEIGHT, duration)
	t.tween_property(_bar_bottom, "offset_top", -CUTSCENE_BARS_HEIGHT, duration)
	t.tween_property(_bar_bottom, "offset_bottom", 0.0, duration)

func _hide_cutscene_bars(duration: float = 0.5):
	var t = create_tween().set_parallel(true)
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_bar_top, "offset_top", -CUTSCENE_BARS_HEIGHT, duration)
	t.tween_property(_bar_top, "offset_bottom", 0.0, duration)
	t.tween_property(_bar_bottom, "offset_top", 0.0, duration)
	t.tween_property(_bar_bottom, "offset_bottom", CUTSCENE_BARS_HEIGHT, duration)

func _lock_player_input(locked: bool):
	_input_locked = locked
	if locked:
		player.set_physics_process(false)
		player.set_process(false)
		player.set_process_input(false)
		player.set_process_unhandled_input(false)
		if "block_click_attack" in player:
			player.block_click_attack = true
		player.is_dashing = false
		player.is_sliding = false
		player.is_blocking = false
		player.is_attacking = false
		player.is_vaulting = false
		player.is_climbing = false
		player.is_climbing_animation = false
		player.is_landing = false
		player.movement_blocked = true
		player.velocity = Vector2.ZERO
	else:
		player.set_physics_process(true)
		player.set_process(true)
		player.set_process_input(true)
		player.set_process_unhandled_input(true)
		if "block_click_attack" in player:
			player.block_click_attack = false
		player.movement_blocked = false
		player.is_dashing = false
		player.is_sliding = false
		player.is_blocking = false
		player.is_attacking = false
		player.is_landing = false

func _stop_all_world():
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(false)
			enemy.set_process(false)
			enemy.velocity = Vector2.ZERO
	if sniper and is_instance_valid(sniper):
		sniper.set_physics_process(false)
	forklift.set_physics_process(false)
	forklift.velocity = Vector2.ZERO

func _resume_all_world():
	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(true)
			enemy.set_process(true)
	forklift.set_physics_process(true)

func _create_sniper_trigger():
	sniper_trigger = Area2D.new()
	sniper_trigger.name = "SniperTriggerScript"
	sniper_trigger.position = Vector2(sniper_trigger_x, sniper_trigger_y)
	sniper_trigger.collision_layer = 0
	sniper_trigger.collision_mask = 1
	sniper_trigger.monitoring = true

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(120, 500)
	shape.shape = rect
	sniper_trigger.add_child(shape)

	add_child(sniper_trigger)
	sniper_trigger.body_entered.connect(_on_sniper_trigger_entered)

func _on_sniper_trigger_entered(body):
	if body != player:
		return
	if state != State.RUNNING:
		return
	if sniper_cutscene_played:
		return
	sniper_trigger.set_deferred("monitoring", false)
	sniper_cutscene_played = true
	call_deferred("_spawn_sniper_deferred", true)

func _spawn_sniper_deferred(with_cutscene: bool):
	_spawn_sniper(with_cutscene)

func _setup_parry_scene():
	var parrying_scene = get_node_or_null("ParryingScene")
	if not parrying_scene:
		return
	parry_trigger = parrying_scene.get_node_or_null("ParryTrigger")
	var enemy = parrying_scene.get_node_or_null("AttackParry")
	if parry_trigger and enemy:
		enemy.visible = false
		enemy.set_physics_process(false)
		enemy.set_process(false)
		enemy.collision_layer = 0
		enemy.collision_mask = 0
		var col = enemy.get_node_or_null("CollisionShape2D")
		if col:
			col.disabled = true
		parry_trigger.body_entered.connect(func(body):
			if not is_inside_tree():
				return
			if body == player and not parry_done:
				player.start_parry(enemy, _on_parry_complete)
				parry_trigger.set_deferred("monitoring", false)
		)

func _setup_entrance_gate():
	var entrance_gate = $EntranceGate
	var entrance_trigger = $EntranceTrigger
	var passage_trigger = $TightPassageTrigger
	if entrance_gate and entrance_trigger and passage_trigger:
		var col = entrance_gate.get_node_or_null("CollisionShape2D")
		if col:
			col.disabled = false

func _start_intro():
	if _intro_started:
		return
	_intro_started = true
	state = State.INTRO_RUN

	if player.sprite:
		player.sprite.stop()
		player.sprite.play("Run")
		player.sprite.scale.x = 1

	var total_time = INTRO_RUN_TIME
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(player, "global_position:x", INTRO_CAPTURE_X, total_time)

	var fade_delay = total_time * ((INTRO_FADE_X - INTRO_START_X) / (INTRO_CAPTURE_X - INTRO_START_X))
	_start_fade_after(fade_delay)

	await tween.finished
	if not is_inside_tree():
		return

	if player.sprite:
		player.sprite.stop()
		player.sprite.play("Idle")

	_start_qte_grab()

func _start_fade_after(delay: float):
	var canvas = CanvasLayer.new()
	canvas.layer = 50
	add_child(canvas)

	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade_overlay)

	await get_tree().create_timer(delay).timeout
	if not is_inside_tree():
		return

	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, INTRO_FADE_TIME)
	await tween.finished
	if not is_inside_tree():
		return

	if fade_overlay and is_instance_valid(fade_overlay):
		fade_overlay.queue_free()
		fade_overlay = null

func _update_intro_enemies():
	if not is_instance_valid(player):
		return

	if player.sprite and player.sprite.animation != "Run" and player.sprite.animation != "Idle":
		if state == State.INTRO_RUN:
			player.sprite.play("Run")
		elif state == State.QTE_GRAB:
			player.sprite.play("Idle")

	var px = player.global_position.x
	var py = player.global_position.y

	for i in _intro_enemies.size():
		var enemy = _intro_enemies[i]
		if not is_instance_valid(enemy):
			continue

		var y_off = _intro_enemy_y_offsets[i] if i < _intro_enemy_y_offsets.size() else 0.0

		var desired_x = px - ENEMY_MIN_GAP - i * ENEMY_SPACING
		var max_x = px - ENEMY_MIN_GAP

		if enemy.global_position.x > max_x:
			enemy.global_position.x = max_x - i * ENEMY_SPACING
		else:
			var new_x = enemy.global_position.x
			if new_x > max_x:
				new_x = max_x
			enemy.global_position.x = new_x

		enemy.global_position.y = py + y_off

func _start_qte_grab():
	state = State.QTE_GRAB
	player.modulate = Color(1, 0.5, 0.5, 1)
	_lock_player_input(true)

	var success = await _run_e_button_qte_at(player.global_position + Vector2(0, -120))

	if not is_inside_tree():
		return

	player.modulate = Color.WHITE

	if success:
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree():
			return

		for enemy in _intro_enemies:
			if not is_instance_valid(enemy):
				continue
			var target = enemy.global_position + Vector2(-250.0, 0)
			var t = create_tween()
			t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			t.tween_property(enemy, "global_position:x", target.x, 0.35)

		await get_tree().create_timer(0.35).timeout
		if not is_inside_tree():
			return

		player.is_dead = false
		player.is_vaulting = false
		player.is_climbing = false
		player.is_climbing_animation = false
		player.is_sliding = false
		player.is_dashing = false
		player.is_blocking = false
		player.is_attacking = false
		player.is_landing = false
		player.velocity = Vector2.ZERO
		player.movement_blocked = false
		player.modulate = Color.WHITE
		if player.sprite:
			player.sprite.stop()
			player.sprite.modulate = Color.WHITE
			player.sprite.play("Idle")

		state = State.RUNNING
		_lock_player_input(false)

		for enemy in _intro_enemies:
			if is_instance_valid(enemy):
				enemy.set_physics_process(true)
				enemy.set_process(true)
	else:
		player.die()

func _spawn_sniper(with_cutscene: bool = false):
	if sniper or sniper_active:
		return
	if not sniper_scene:
		return

	sniper = sniper_scene.instantiate()
	if "start_active" in sniper:
		sniper.start_active = false
	if "gravity" in sniper:
		sniper.gravity = 0.0

	get_tree().current_scene.add_child(sniper)
	sniper.global_position = sniper_spawn_position
	sniper.visible = false
	sniper.set_physics_process(false)
	sniper.set_process(false)
	sniper.velocity = Vector2.ZERO

	sniper_active = true

	if with_cutscene:
		_play_sniper_cutscene()

func _get_camera_target() -> Vector2:
	if camera and camera.has_method("get_follow_target"):
		return camera.get_follow_target()
	if camera:
		return camera.global_position
	return player.global_position

func _save_camera_state():
	_cam_was_processing = camera.is_processing()
	_cam_was_physics_processing = camera.is_physics_processing()
	_cam_original_position = _get_camera_target()
	_cam_original_zoom = camera.zoom
	_cam_original_offset = camera.offset

func _disable_camera_for_cutscene():
	_save_camera_state()
	camera.set_process(false)
	camera.set_physics_process(false)
	if "follow_enabled" in camera:
		camera.follow_enabled = false
	if "look_offset" in camera:
		camera.look_offset = Vector2.ZERO
	camera.position_smoothing_enabled = false
	camera.rotation_smoothing_enabled = false

func _restore_camera_after_cutscene():
	camera.global_position = _cam_original_position
	camera.zoom = _cam_original_zoom
	camera.offset = _cam_original_offset
	if "follow_enabled" in camera:
		camera.follow_enabled = true
	camera.position_smoothing_enabled = true
	camera.rotation_smoothing_enabled = true
	camera.set_process(_cam_was_processing)
	camera.set_physics_process(_cam_was_physics_processing)
	camera.reset_smoothing()

func _play_sniper_cutscene():
	state = State.SNIPER_CUTSCENE

	_lock_player_input(true)
	_stop_all_world()

	if player.sprite:
		player.sprite.stop()
		player.sprite.play("Idle")
		player.sprite.scale.x = 1

	_show_cutscene_bars(0.6)

	var player_cam_pos = _get_camera_target()

	_disable_camera_for_cutscene()

	var sniper_pos = sniper.global_position
	var start_zoom = camera.zoom

	camera.global_position = player_cam_pos
	camera.reset_smoothing()

	var t1 = create_tween().set_parallel(true)
	t1.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(camera, "global_position", sniper_pos, 1.6)
	t1.tween_property(camera, "zoom", Vector2(1.4, 1.4), 1.6)
	await t1.finished
	if not is_inside_tree():
		return

	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return

	if is_instance_valid(sniper):
		sniper.visible = true

	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return

	var t2 = create_tween().set_parallel(true)
	t2.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t2.tween_property(camera, "global_position", player_cam_pos, 1.4)
	t2.tween_property(camera, "zoom", start_zoom, 1.4)
	await t2.finished
	if not is_inside_tree():
		return

	_hide_cutscene_bars(0.6)

	_restore_camera_after_cutscene()

	if shift_tutorial and shift_tutorial.has_method("show_tutorial"):
		shift_tutorial.show_tutorial()
		while shift_tutorial.is_active:
			await get_tree().process_frame
			if not is_inside_tree():
				return

	if sniper and is_instance_valid(sniper):
		sniper.set_process(true)
		sniper.set_physics_process(false)
		if sniper.has_method("activate"):
			sniper.activate()

	_resume_all_world()
	_lock_player_input(false)
	state = State.RUNNING

func _deactivate_sniper():
	if sniper and is_instance_valid(sniper):
		if sniper.has_method("deactivate"):
			sniper.deactivate()
	sniper_active = false

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	if state == State.INTRO_RUN or state == State.QTE_GRAB:
		_update_intro_enemies()
		return

	if state == State.SNIPER_CUTSCENE or state == State.FORKLIFT_QTE:
		return

	if state == State.FORKLIFT_CUTSCENE:
		if is_instance_valid(player) and not player.is_dashing:
			player.velocity.x = 400.0
		return

	if state == State.RUNNING and not is_game_over:
		if sniper_active and player.global_position.x >= escape_sniper_x:
			_deactivate_sniper()

	_process_gameplay(delta)

func _process_gameplay(delta):
	if not is_inside_tree():
		return
	if get_tree().paused or state == State.GAMEOVER:
		return
	if state == State.SNIPER_CUTSCENE or state == State.FORKLIFT_CUTSCENE or state == State.FORKLIFT_QTE:
		return

	if state == State.RUNNING:
		_check_enemy_collision()

		if forklift_activated and not shelf_climbed and falling_shelf.visible:
			var dist = player.global_position.distance_to(falling_shelf.global_position)
			if dist < 150 and Input.is_action_just_pressed("interact"):
				shelf_climbed = true
				_climb_shelf()

		if forklift_ready_for_throw and not forklift_stopped:
			var dist = player.global_position.distance_to(forklift.global_position)
			if dist < 260 and player.has_item:
				player.set_can_throw(true)
				if Input.is_action_just_pressed("interact"):
					_throw_item_at_forklift()
			else:
				player.set_can_throw(false)

		if player.global_position.x > 4200 and parry_done:
			if not can_press_button:
				can_press_button = true
			elif Input.is_action_just_pressed("interact"):
				can_press_button = false
				_lock_player_input(true)
				state = State.ELEVATOR_WAIT
				elevator_timer = 3.0

	elif state == State.ELEVATOR_WAIT:
		elevator_timer -= delta
		if elevator_timer <= 0:
			state = State.ELEVATOR_GO
			elevator.color = Color.GREEN
			var t = create_tween()
			t.tween_property(player, "global_position:x", elevator.global_position.x + 30, 0.5)
			await t.finished
			if not is_inside_tree():
				return
			player.visible = false
			var lt = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			lt.tween_property(elevator, "global_position:y", elevator.global_position.y - 400, 1.0)
			await lt.finished
			if not is_inside_tree():
				return
			await get_tree().create_timer(0.5).timeout
			if not is_inside_tree():
				return
			_win()

	if _shelf_climbing:
		if Input.is_action_pressed("ui_up"):
			player.global_position.y -= 2

		var shelf_top = falling_shelf.global_position.y - falling_shelf.get_node("CollisionShape2D").shape.size.y + 10

		if player.global_position.y <= shelf_top:
			player.global_position.y = shelf_top
			_shelf_climbing = false
			_lock_player_input(false)

func _check_enemy_collision():
	if state != State.RUNNING:
		return
	if is_game_over:
		return
	if player.is_dead:
		return

	var player_pos = player.global_position

	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			var dist = enemy.global_position.distance_to(player_pos)
			if dist < 45:
				is_game_over = true
				state = State.GAMEOVER
				_stop_all_world()
				if player.has_method("die"):
					player.die()
				return

func _on_forklift_trigger_entered(body):
	if not is_inside_tree():
		return
	if body == player and not forklift_activated:
		_activate_forklift()

func _activate_forklift():
	if not is_inside_tree():
		return
	if forklift_activated:
		return
	forklift_activated = true
	_play_forklift_cutscene()

func _play_forklift_cutscene():
	state = State.FORKLIFT_CUTSCENE

	_lock_player_input(true)
	_stop_all_world()

	if player.sprite:
		player.sprite.stop()
		player.sprite.play("Run")
		player.sprite.scale.x = 1

	_show_cutscene_bars(0.6)

	var player_cam_pos = _get_camera_target()
	var cam_y = player_cam_pos.y

	_disable_camera_for_cutscene()

	var start_zoom = camera.zoom

	camera.global_position = player_cam_pos
	camera.reset_smoothing()

	var t0 = create_tween().set_parallel(true)
	t0.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t0.tween_property(camera, "global_position", Vector2(7000.0, cam_y), 1.4)
	t0.tween_property(camera, "zoom", Vector2(1.4, 1.4), 1.4)
	await t0.finished
	if not is_inside_tree():
		return

	forklift.visible = true
	falling_shelf.visible = true

	var forklift_y = forklift.global_position.y
	forklift.global_position = Vector2(8300.0, forklift_y)
	falling_shelf.global_position = Vector2(8360.0, forklift_y)
	forklift.set("active", true)
	if "direction" in forklift:
		forklift.direction = -1
	if "move_dir" in forklift:
		forklift.move_dir = -1
	if "speed" in forklift:
		forklift.speed = abs(forklift.speed)

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return

	var t1 = create_tween().set_parallel(true)
	t1.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(camera, "global_position", Vector2(player.global_position.x, cam_y), 1.2)
	t1.tween_property(camera, "zoom", start_zoom, 1.2)
	await t1.finished
	if not is_inside_tree():
		return

	_restore_camera_after_cutscene()

	if player.sprite:
		player.sprite.play("Run")

	forklift.set_physics_process(true)

	var bullet = _spawn_fake_bullet()
	if bullet == null:
		_hide_cutscene_bars(0.4)
		_resume_all_world()
		_lock_player_input(false)
		state = State.RUNNING
		return

	var bullet_speed = 2200.0
	var bullet_start_x = bullet.global_position.x
	var player_x = player.global_position.x
	var hit_dist = abs(player_x - bullet_start_x)
	var hit_time = hit_dist / bullet_speed

	var qte_lead = 1.2
	var qte_delay = max(hit_time - qte_lead, 0.15)

	await get_tree().create_timer(qte_delay).timeout
	if not is_inside_tree():
		if is_instance_valid(bullet):
			bullet.queue_free()
		return

	if shift_qte and shift_qte.has_signal("qte_hit"):
		shift_qte.qte_hit.connect(_force_dash, CONNECT_ONE_SHOT)

	var qte_success = await _run_forklift_shift_qte()

	if not is_inside_tree():
		if is_instance_valid(bullet):
			bullet.queue_free()
		return

	if qte_success:
		if is_instance_valid(bullet):
			var forklift_x = forklift.global_position.x
			var remain_dist = abs(forklift_x - bullet.global_position.x)
			var remain_time = remain_dist / bullet_speed
			if remain_time < 0.05:
				remain_time = 0.05
			var bt = create_tween()
			bt.set_trans(Tween.TRANS_LINEAR)
			bt.tween_property(bullet, "global_position:x", forklift_x, remain_time)
			await bt.finished
			if not is_inside_tree():
				if is_instance_valid(bullet):
					bullet.queue_free()
				return
			if is_instance_valid(bullet):
				bullet.queue_free()

		forklift.velocity = Vector2.ZERO
		forklift_stopped = true
		forklift.set("active", false)
		forklift.set_physics_process(false)

		var flash = ColorRect.new()
		flash.color = Color(1, 1, 1, 0.7)
		flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var flash_layer = CanvasLayer.new()
		flash_layer.layer = 80
		add_child(flash_layer)
		flash_layer.add_child(flash)
		var ft = create_tween()
		ft.tween_property(flash, "modulate:a", 0.0, 0.3)
		await ft.finished
		if not is_inside_tree():
			return
		flash_layer.queue_free()

		if player.has_method("_play_anim"):
			player._play_anim("Run", true)

		var tilt = create_tween().set_parallel(true)
		tilt.tween_property(falling_shelf, "rotation", deg_to_rad(75), 0.6)
		tilt.tween_property(falling_shelf, "global_position:y", falling_shelf.global_position.y + 40.0, 0.6)
		await tilt.finished
		if not is_inside_tree():
			return

		await get_tree().create_timer(0.4).timeout
		if not is_inside_tree():
			return
	else:
		if is_instance_valid(bullet):
			bullet.queue_free()
		if shift_qte and shift_qte.has_signal("qte_hit") and shift_qte.qte_hit.is_connected(_force_dash):
			shift_qte.qte_hit.disconnect(_force_dash)
		_hide_cutscene_bars(0.4)
		_restore_camera_after_cutscene()
		_resume_all_world()
		_lock_player_input(false)
		player.die()
		state = State.RUNNING
		return

	_hide_cutscene_bars(0.6)

	if player.sprite:
		player.sprite.stop()
		player.sprite.play("Idle")

	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree():
		return

	_resume_all_world()
	_lock_player_input(false)

	state = State.RUNNING
func _spawn_fake_bullet() -> Node2D:
	var bullet = Node2D.new()
	bullet.name = "FakeBullet"
	bullet.z_index = 60

	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-30, -8), Vector2(30, -8),
		Vector2(30, 8), Vector2(-30, 8)
	])
	glow.color = Color(1, 1, 0.6, 0.35)
	bullet.add_child(glow)

	var core = Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(-18, -4), Vector2(18, -4),
		Vector2(18, 4), Vector2(-18, 4)
	])
	core.color = Color(1, 0.95, 0.3, 1.0)
	bullet.add_child(core)

	var tip = Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(18, -4), Vector2(28, 0), Vector2(18, 4)
	])
	tip.color = Color(1, 1, 0.8, 1.0)
	bullet.add_child(tip)

	get_tree().current_scene.add_child(bullet)

	var start_x = sniper_spawn_position.x
	var start_y = player.global_position.y

	if sniper and is_instance_valid(sniper):
		start_x = sniper.global_position.x
		start_y = sniper.global_position.y

	bullet.global_position = Vector2(start_x, start_y)

	var dir_x = player.global_position.x - start_x
	var dir_y = player.global_position.y - start_y
	bullet.rotation = atan2(dir_y, dir_x)

	return bullet

func _run_forklift_shift_qte() -> bool:
	if not shift_qte or not shift_qte.has_method("show_qte"):
		await get_tree().create_timer(1.2).timeout
		return true

	shift_qte.show_qte()

	var result: bool = false
	var received: bool = false

	var callback = func(success: bool):
		result = success
		received = true

	if not shift_qte.qte_result.is_connected(callback):
		shift_qte.qte_result.connect(callback)

	while not received:
		await get_tree().process_frame
		if not is_inside_tree():
			if shift_qte.qte_result.is_connected(callback):
				shift_qte.qte_result.disconnect(callback)
			return false

	if shift_qte.qte_result.is_connected(callback):
		shift_qte.qte_result.disconnect(callback)

	return result

func _force_dash():
	if not player:
		return
	player.is_dashing = false
	player.dash_cooldown = 0.0
	if player.has_method("_dash"):
		player._dash()

func _run_shift_qte_cutscene() -> bool:
	if not shift_qte or not shift_qte.has_method("show_qte"):
		await get_tree().create_timer(1.2).timeout
		return true

	shift_qte.show_qte()

	var result: bool = false
	var received: bool = false

	var callback = func(success: bool):
		result = success
		received = true

	if not shift_qte.qte_result.is_connected(callback):
		shift_qte.qte_result.connect(callback)

	await get_tree().process_frame

	var qte_started = false
	if shift_qte.has_signal("qte_started"):
		shift_qte.qte_started.connect(func(): qte_started = true, CONNECT_ONE_SHOT)
		await get_tree().create_timer(0.1).timeout
		if not qte_started:
			qte_started = true
	
	if qte_started:
		var p_target_x = player.global_position.x + _qte_throw_dir * 600.0
		var f_target_x = forklift.global_position.x - _qte_throw_dir * 600.0

		if player.has_method("_play_anim"):
			player._play_anim("Run", true)

		_forklift_player_tween = create_tween()
		_forklift_player_tween.set_trans(Tween.TRANS_LINEAR)
		_forklift_player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_forklift_player_tween.tween_property(player, "global_position:x", p_target_x, 1.5)

		_forklift_tween = create_tween()
		_forklift_tween.set_trans(Tween.TRANS_LINEAR)
		_forklift_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_forklift_tween.tween_property(forklift, "global_position:x", f_target_x, 1.5)

	while not received:
		await get_tree().process_frame
		if not is_inside_tree():
			return false

	if shift_qte.qte_result.is_connected(callback):
		shift_qte.qte_result.disconnect(callback)

	if received:
		var stop_tweens = get_tree().get_processed_tweens()
		for t in stop_tweens:
			t.kill()

		var f_y = forklift.global_position.y
		var p_y = player.global_position.y
		
		if result:
			forklift.global_position = Vector2(player.global_position.x + 150, f_y)
			player.global_position = Vector2(forklift.global_position.x - 350, p_y)
		else:
			forklift.global_position = Vector2(player.global_position.x, f_y)
			
		if player.has_method("_play_anim"):
			player._play_anim("Idle", true)

	return result

func _throw_item_at_forklift():
	if not player.has_item or forklift_stopped:
		return

	forklift_stopped = true
	forklift_ready_for_throw = false
	forklift_charging = false

	player.has_item = false
	if player.held_icon:
		player.held_icon.visible = false
	if player.held_item_icon and is_instance_valid(player.held_item_icon):
		player.held_item_icon.queue_free()
		player.held_item_icon = null
	player.set_can_throw(false)

	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.6)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 100
	add_child(flash)
	var ft = create_tween()
	ft.tween_property(flash, "modulate:a", 0.0, 0.2)
	await ft.finished
	if not is_inside_tree():
		return
	flash.queue_free()

	forklift.modulate = Color(0.4, 0.4, 0.4, 1)

	if falling_shelf:
		var t = create_tween()
		t.tween_property(falling_shelf, "global_position:y", falling_shelf.global_position.y + 150, 0.6)
		t.parallel().tween_property(falling_shelf, "rotation", 0.3, 0.6)

	forklift_trigger.monitoring = false

func _climb_shelf():
	_lock_player_input(true)
	_shelf_climbing = true

func _on_parry_complete():
	parry_done = true
	if is_instance_valid(player):
		_lock_player_input(false)
		player.is_vaulting = false
		player.is_climbing = false
		player.is_sliding = false
		player.is_crouching = false

func _game_over():
	if is_game_over or state == State.GAMEOVER:
		return
	is_game_over = true
	state = State.GAMEOVER

	_deactivate_sniper()
	_stop_all_world()
	_lock_player_input(true)
	player.velocity = Vector2.ZERO

	if not player.is_dead and player.has_method("die"):
		player.die()

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
	if not is_inside_tree():
		return

	if player:
		Global.player_position = player.global_position
	var config = ConfigFile.new()
	var save_path = "user://saves/save_" + str(Global.save_slot) + ".cfg"
	if config.load(save_path) == OK:
		config.set_value("save", "scene", "res://GameScenes/LevelScenes/ActStorageLevelScenes/NearFactoryLevelScenes/NearFactoryLevelMainScene/ActStorage_LevelNearFactory_Scene.tscn")
		config.set_value("save", "time", Time.get_datetime_string_from_system())
		if player:
			config.set_value("save", "player_x", player.global_position.x)
			config.set_value("save", "player_y", player.global_position.y)
		config.save(save_path)

	GlobalMusic.stop_music()
	get_tree().change_scene_to_file("res://GameScenes/LevelScenes/ActStorageLevelScenes/NearFactoryLevelScenes/NearFactoryLevelMainScene/ActStorage_LevelNearFactory_Scene.tscn")

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	if _input_locked:
		if state == State.QTE_GRAB and event.is_action_pressed("interact"):
			return
		if event.is_action_pressed("interact") \
		or event.is_action_pressed("jump") \
		or event.is_action_pressed("Run") \
		or event.is_action_pressed("crouch") \
		or event.is_action_pressed("block") \
		or event.is_action_pressed("Parry"):
			get_viewport().set_input_as_handled()
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_viewport().set_input_as_handled()
		return

	if state != State.RUNNING and state != State.ELEVATOR_WAIT and state != State.ELEVATOR_GO:
		return

	if event.is_action_pressed("interact"):
		var entrance_trigger = get_node_or_null("EntranceTrigger")
		var passage_trigger = get_node_or_null("TightPassageTrigger")

		if entrance_trigger:
			var bodies = entrance_trigger.get_overlapping_bodies()
			if bodies.has(player) and passage_trigger and not passage_trigger.is_active:
				var col = $EntranceGate.get_node_or_null("CollisionShape2D")
				if col:
					col.set_deferred("disabled", true)
				player.global_position.x += 10
				passage_trigger.activate(player)
				return

		if player.has_method("set_movement_blocked") and player.movement_blocked:
			player.set_movement_blocked(false)
			return

func _toggle_pause():
	if state == State.GAMEOVER or state == State.WIN or state == State.INTRO_RUN or state == State.QTE_GRAB or state == State.SNIPER_CUTSCENE:
		return
	if not pause_menu:
		return
	if pause_menu.visible:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		GlobalMusic.restore_volume()
		UISounds.restore_ambience()
		pause_menu.hide_menu()
	else:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GlobalMusic.lower_volume()
		UISounds.lower_ambience()
		pause_menu.show_menu()

func _resume_after_pause() -> void:
	if not player:
		return
	player.set_physics_process(true)
	player.set_process(true)

func _on_continue_pressed():
	pass

func _run_e_button_qte_at(world_pos: Vector2) -> bool:
	if not qte_button or not qte_button.has_method("show_qte_at"):
		await get_tree().create_timer(8.0).timeout
		return true

	qte_button.show_qte_at(world_pos)

	var state_dict = {"result": false, "received": false}

	var callback = func(success: bool):
		state_dict["result"] = success
		state_dict["received"] = true

	if not qte_button.qte_result.is_connected(callback):
		qte_button.qte_result.connect(callback)

	while not state_dict["received"]:
		await get_tree().process_frame
		if not is_inside_tree():
			return false

	if qte_button.qte_result.is_connected(callback):
		qte_button.qte_result.disconnect(callback)

	return state_dict["result"]

func _run_forklift_qte_motion():
	var ts = Engine.time_scale
	if ts <= 0.0:
		ts = 1.0

	var dur = 1.5

	var player_t = create_tween()
	player_t.set_trans(Tween.TRANS_LINEAR)
	player_t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	player_t.tween_property(player, "global_position:x", 4700.0, dur * ts)

	var forklift_t = create_tween()
	forklift_t.set_trans(Tween.TRANS_LINEAR)
	forklift_t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	forklift_t.tween_property(forklift, "global_position:x", 6380.0, dur * ts)
