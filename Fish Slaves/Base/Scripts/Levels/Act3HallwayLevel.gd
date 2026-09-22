extends Node2D

@onready var player: CharacterBody2D = $MechaFish
@onready var elevator: ColorRect = $EndAct/Elevator
@onready var elevator_button: Area2D = $EndAct/ElevatorButton
@onready var forklift: CharacterBody2D = $ForkliftScene/Forklift
@onready var falling_shelf: StaticBody2D = $ForkliftScene/FallingShelf
@onready var forklift_trigger: Area2D = $ForkliftTrigger
@onready var death_zone: Area2D = $DeathZone
@onready var death_zone2: Area2D = $DeathZone2
@onready var camera: Camera2D = $MechaFish/MechaFishCamera
@onready var pause_menu: CanvasLayer = $Pausemenu

@export var sniper_scene: PackedScene = null
@export var sniper_spawn_position: Vector2 = Vector2(-50.26, 320.0)
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

const CUTSCENE_BARS_HEIGHT: float = 140.0

enum State { INTRO_RUN, QTE_GRAB, RUNNING, SNIPER_CUTSCENE, ELEVATOR_WAIT, ELEVATOR_GO, WIN, GAMEOVER }
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

	camera.zoom = Vector2(2.3, 2.3)
	camera.limit_left = -5000
	camera.limit_right = 6000
	camera.limit_top = -5000
	camera.limit_bottom = 5000
	camera.enabled = true
	camera.global_position = player.global_position


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
			_game_over()
	)
	death_zone2.body_entered.connect(func(body):
		if body == player and not is_game_over and state == State.RUNNING:
			_game_over()
	)

	_create_sniper_trigger()
	_create_cutscene_bars()

	_setup_parry_scene()
	_setup_entrance_gate()

	if pause_menu:
		pause_menu.hide()

	print("[Level] _ready завершён, старт катсцены 1")
	_start_intro()

# ===================== РАМКИ КИНО =====================

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

# ===================== БЛОКИРОВКА ВВОДА =====================

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
		print("[Level] 🔒 ВВОД ИГРОКА ЗАБЛОКИРОВАН")
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
		print("[Level] 🔓 ВВОД ИГРОКА РАЗБЛОКИРОВАН")

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

	print("[Trigger] создан на world=", sniper_trigger.global_position,
		" local=", sniper_trigger.position,
		" player.world_y=", player.global_position.y)

func _on_sniper_trigger_entered(body):
	if body != player:
		return
	if state != State.RUNNING:
		return
	if sniper_cutscene_played:
		return
	print("[Trigger] >>> сработал, запуск катсцены 2")
	sniper_trigger.set_deferred("monitoring", false)
	sniper_cutscene_played = true
	call_deferred("_spawn_sniper_deferred", true)

func _spawn_sniper_deferred(with_cutscene: bool):
	_spawn_sniper(with_cutscene)

# ===================== SETUP =====================

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

# ===================== ИНТРО-КАТСЦЕНА =====================

func _start_intro():
	if _intro_started:
		return
	_intro_started = true
	state = State.INTRO_RUN
	print("[Level] >>> КАТСЦЕНА 1: интро-побег началась")

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
			var new_x = lerp(enemy.global_position.x, desired_x, ENEMY_CATCHUP)
			if new_x > max_x:
				new_x = max_x
			enemy.global_position.x = new_x

		enemy.global_position.y = py + y_off

func _start_qte_grab():
	state = State.QTE_GRAB
	player.modulate = Color(1, 0.5, 0.5, 1)
	_lock_player_input(true)

	var qte = 0
	while qte < 6:
		if not is_inside_tree():
			return
		await get_tree().process_frame
		if not is_inside_tree():
			return
		if not is_instance_valid(player):
			return
		if Input.is_action_just_pressed("interact"):
			qte += 1
			print("[Level] QTE: ", qte, "/6")

	if not is_inside_tree():
		return
	player.modulate = Color.WHITE

	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return

	for enemy in _intro_enemies:
		if not is_instance_valid(enemy):
			continue
		var target = enemy.global_position + Vector2(-140.0, 0)
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
	player.modulate = Color.WHITE
	if player.sprite:
		player.sprite.stop()
		player.sprite.modulate = Color.WHITE
		player.sprite.play("Idle")

	state = State.RUNNING
	_lock_player_input(false)

	for enemy in _intro_enemies:
		await get_tree().create_timer(3).timeout
	if not is_inside_tree():
		return
	if is_instance_valid(sniper):
		sniper.visible = true
		print("[Level] снайпер показан")

	print("[Level] >>> КАТСЦЕНА 1 закончилась, управление у игрока")

# ===================== СНАЙПЕР =====================

func _spawn_sniper(with_cutscene: bool = false):
	if sniper or sniper_active:
		return
	if not sniper_scene:
		print("[Level] ❌ sniper_scene не назначена в @export")
		return

	print("[Level] >>> СПАВН СНАЙПЕРА на ", sniper_spawn_position)
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

	# физику выключаем НАВСЕГДА — снайпер висит где поставили
	sniper.set_physics_process(false)
	sniper.set_process(false)

	print("[Sniper] зафиксирован на ", sniper.global_position)
	sniper_active = true

	if with_cutscene:
		_play_sniper_cutscene()

func _play_sniper_cutscene():
	state = State.SNIPER_CUTSCENE
	print("[Level] >>> КАТСЦЕНА 2 началась")

	# 1) СТОП ВСЕМУ
	_lock_player_input(true)
	_stop_all_world()

	if player.sprite:
		player.sprite.stop()
		player.sprite.play("Idle")
		player.sprite.scale.x = 1

	_show_cutscene_bars(0.6)

	# 2) ГОТОВИМ КАМЕРУ
	var cam = camera
	if not cam:
		print("[Cam] ❌ camera = null")
		return

	# отключаем автофоллоу камеры за рыбой
	if "follow_enabled" in cam:
		cam.follow_enabled = false
	if "look_offset" in cam:
		cam.look_offset = Vector2.ZERO
	cam.position_smoothing_enabled = false
	cam.rotation_smoothing_enabled = false

	var player_pos = player.global_position
	var sniper_pos = sniper.global_position
	var start_zoom = cam.zoom

	# жёстко ставим камеру на игрока как старт
	cam.global_position = player_pos

	print("[Cam] старт pos=", cam.global_position, " zoom=", start_zoom)
	print("[Cam] цель pos=", sniper_pos, " zoom=(1.4, 1.4)")

	# 3) ЕДЕМ К СНАЙПЕРУ
	var t1 = create_tween().set_parallel(true)
	t1.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(cam, "global_position", sniper_pos, 1.6)
	t1.tween_property(cam, "zoom", Vector2(1.4, 1.4), 1.6)
	await t1.finished
	if not is_inside_tree():
		return

	print("[Cam] у снайпера pos=", cam.global_position)

	# 4) ПОКАЗЫВАЕМ СНАЙПЕРА
	if is_instance_valid(sniper):
		sniper.visible = true
		print("[Level] снайпер показан")

	# 5) СТОИМ 3 СЕКУНДЫ У СНАЙПЕРА
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return

	print("[Cam] 3 сек у снайпера прошло, pos=", cam.global_position)

	# 6) ЕДЕМ ОБРАТНО К ИГРОКУ
	var t2 = create_tween().set_parallel(true)
	t2.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t2.tween_property(cam, "global_position", player_pos, 1.4)
	t2.tween_property(cam, "zoom", start_zoom, 1.4)
	await t2.finished
	if not is_inside_tree():
		return

	print("[Cam] вернулись к игроку pos=", cam.global_position)

	# 7) УБИРАЕМ РАМКИ
	_hide_cutscene_bars(0.6)

		# 8) АКТИВИРУЕМ СНАЙПЕРА
	if sniper and is_instance_valid(sniper):
		sniper.set_process(true)          # ← включает стрельбу
		sniper.set_physics_process(false) # ← гравитация остаётся ВЫКЛЮЧЕНА
		if sniper.has_method("activate"):
			sniper.activate()
			print("[Level] снайпер активирован на ", sniper.global_position)

	# 9) ЖЁСТКО СТАВИМ КАМЕРУ НА ИГРОКА ПЕРЕД ВОЗВРАТОМ ФОЛЛОУ
	cam.global_position = player_pos
	cam.zoom = start_zoom

	# возвращаем автофоллоу
	if "follow_enabled" in cam:
		cam.follow_enabled = true

	# 10) ВОЗВРАЩАЕМ ВСЁ
	_resume_all_world()
	_lock_player_input(false)

	state = State.RUNNING
	print("[Level] >>> КАТСЦЕНА 2 закончилась, управление у игрока")

func _deactivate_sniper():
	if sniper and is_instance_valid(sniper):
		if sniper.has_method("deactivate"):
			sniper.deactivate()
	sniper_active = false
	print("[Level] снайпер деактивирован")

# ===================== ОБРАБОТКА КАДРА =====================

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	if state == State.INTRO_RUN or state == State.QTE_GRAB:
		_update_intro_enemies()
		if camera:
			camera.global_position = player.global_position
		return

	if state == State.SNIPER_CUTSCENE:
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
	if state == State.SNIPER_CUTSCENE:
		return

	if camera and (state == State.RUNNING or state == State.ELEVATOR_WAIT or state == State.ELEVATOR_GO):
		camera.global_position = player.global_position

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
				if player.has_method("die"):
					player.die()
				else:
					_game_over()
				return

# ===================== ПОГРУЗЧИК =====================

func _on_forklift_trigger_entered(body):
	if not is_inside_tree():
		return
	if body == player and not forklift_activated:
		_activate_forklift()

func _activate_forklift():
	if not is_inside_tree():
		return

	forklift_activated = true
	forklift.visible = true
	falling_shelf.visible = true
	forklift_charging = true

	var shelf_y = falling_shelf.global_position.y
	var fork_y = forklift.global_position.y

	falling_shelf.global_position = Vector2(player.global_position.x + 900, shelf_y)
	forklift.global_position = Vector2(player.global_position.x + 1000, fork_y)
	forklift.set("active", true)

	_forklift_charge_tween()

func _forklift_charge_tween():
	if not is_inside_tree():
		return

	var target_x = player.global_position.x + 60

	var t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_parallel(true)
	t.tween_property(falling_shelf, "global_position:x", target_x + 100, 2.6)
	t.tween_property(forklift, "global_position:x", target_x, 2.6)
	await t.finished

	if not is_inside_tree():
		return

	if forklift_stopped:
		return

	forklift.set("active", false)
	forklift.set_physics_process(false)
	forklift.velocity = Vector2.ZERO
	forklift_charging = false

	if player.has_method("die"):
		player.die()
	else:
		_game_over()

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

# ===================== ПАРИРОВАНИЕ / WIN / GAMEOVER =====================

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

	_lock_player_input(true)
	player.velocity = Vector2.ZERO

	for enemy in $Enemies.get_children():
		if enemy is CharacterBody2D:
			enemy.set_physics_process(false)

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

	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuFactory.tscn")

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	if _input_locked:
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
