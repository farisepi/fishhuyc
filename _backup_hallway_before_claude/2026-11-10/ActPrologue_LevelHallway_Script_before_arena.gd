extends Node2D

@onready var player: CharacterBody2D = $Mecha_Fish
@onready var elevator: AnimatedSprite2D = $EndAct/Elevator
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
const CUTSCENE_CAM_DROP: float = 45.0   # насколько опускать камеру в катсценах, чтобы рыбу не резали полосы

const DEATH_SCREEN_SCENE: PackedScene = preload("res://GameScenes/MenuScenes/FactoryMenuScenes/FactoryDeathScreenScene/Menu_Factory_DeathScreen_Scene.tscn")

# --- катсцена погрузчика ---
const FL_SPAWN_AHEAD: float = 1200.0    # где появляется погрузчик (центр, от рыбы)
const FL_SPEED: float = 220.0           # скорость погрузчика
const FL_FISH_SPEED_MULT: float = 0.75  # рыба в катсцене бежит чуть медленнее обычного
const FL_QTE_GAP: float = 520.0         # расстояние рыба<->погрузчик, когда начинается QTE
const FL_SLOWMO: float = 0.15           # slow-mo во время QTE
const FL_SLOWMO_RAMP: float = 0.5       # за сколько секунд плавно входим в slow-mo
const FL_QTE_TIME: float = 2.0          # реальные секунды на QTE SHIFT
const FL_DASH_DIST: float = 100.0       # длина рывка-уклонения
const FL_DASH_TIME: float = 0.28        # длительность рывка (реальные секунды)

# Парирование и блок пока рано показывать — вернуть на следующем уровне
const ENABLE_PARRY_SCENE: bool = false
const ALLOW_BLOCK_AND_PARRY: bool = false

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
var passage_done: bool = false

var _shake: float = 0.0
var _shake_floor: float = 0.0
var _was_shaking: bool = false
var _last_ticks: int = 0
var _cam_base_offset: Vector2 = Vector2.ZERO
var _cam_track: Node2D = null
var _cam_track_offset: Vector2 = Vector2.ZERO
var _aim_active: bool = false
var _aim_width: float = 10.0
var _aim_blink: float = 0.0
var _vignette: ColorRect = null
var _flash_rect: ColorRect = null
var _shelf_hint: Label = null
var _elevator_hint: Label = null
var _cutscene_running: bool = false
var _shelf_dx: float = 0.0
var _bullet: Line2D = null
var _bullet_active: bool = false
var _bullet_from: Vector2 = Vector2.ZERO
var _bullet_pos: Vector2 = Vector2.ZERO

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

	# ямы: падение и экран смерти делает сам игрок (fall_into_pit), уровень только останавливает мир
	for dz in get_children():
		if dz is Area2D and dz.has_signal("player_died") and dz.has_method("reset"):
			dz.player_died.connect(_on_pit_fall)

	if "allow_block" in player:
		player.allow_block = ALLOW_BLOCK_AND_PARRY
	if "allow_parry" in player:
		player.allow_parry = ALLOW_BLOCK_AND_PARRY

	_ensure_death_screen()
	_create_sniper_trigger()
	_create_cutscene_bars()
	_create_fx_layer()

	_setup_parry_scene()
	_setup_entrance_gate()
	_last_ticks = Time.get_ticks_msec()
	if camera:
		_cam_base_offset = camera.offset

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
		# после катсцены рыба «не знала», что стоит на полу, и проигрывала падение+приземление
		if player.has_method("snap_to_floor_now"):
			player.snap_to_floor_now()

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

func _ensure_death_screen():
	# В сцене Hallway нет ноды DeathScreen — поэтому экран смерти не появлялся.
	if get_node_or_null("DeathScreen") == null:
		var ds = DEATH_SCREEN_SCENE.instantiate()
		ds.name = "DeathScreen"
		add_child(ds)

func _on_pit_fall():
	if is_game_over:
		return
	is_game_over = true
	state = State.GAMEOVER
	_deactivate_sniper()
	_stop_all_world()

func _setup_parry_scene():
	# Парирование пока рано показывать игроку (вернуть: ENABLE_PARRY_SCENE = true)
	var parrying_scene = get_node_or_null("ParryingScene")
	if not parrying_scene or ENABLE_PARRY_SCENE:
		return
	parrying_scene.visible = false
	parrying_scene.process_mode = Node.PROCESS_MODE_DISABLED
	var trig = parrying_scene.get_node_or_null("ParryTrigger")
	if trig:
		trig.set_deferred("monitoring", false)
	var enemy = parrying_scene.get_node_or_null("AttackParry")
	if enemy:
		enemy.collision_layer = 0
		enemy.collision_mask = 0

func _setup_entrance_gate():
	var entrance_gate = get_node_or_null("EntranceGate")
	var entrance_trigger = get_node_or_null("EntranceTrigger")
	var passage_trigger = get_node_or_null("TightPassageTrigger")
	if entrance_gate:
		var col = entrance_gate.get_node_or_null("CollisionShape2D")
		if col:
			col.disabled = false
	if passage_trigger and passage_trigger.has_signal("passage_completed"):
		passage_trigger.passage_completed.connect(_on_passage_completed)
	# в проход заходим автоматически, как только упёрлись в стеллажи
	if entrance_trigger:
		entrance_trigger.body_entered.connect(_on_entrance_entered)

func _on_entrance_entered(_body):
	pass

# в проход входим по E, стоя у стеллажей (над рыбой подсказка)
func _update_passage_entry():
	var entrance_trigger = get_node_or_null("EntranceTrigger")
	var passage_trigger = get_node_or_null("TightPassageTrigger")
	var can_enter = entrance_trigger != null and passage_trigger != null \
		and not passage_trigger.is_active and entrance_trigger.overlaps_body(player)
	_set_passage_hint(can_enter)
	if can_enter and Input.is_action_just_pressed("interact"):
		_set_passage_hint(false)
		var gate = get_node_or_null("EntranceGate")
		if gate:
			var col = gate.get_node_or_null("CollisionShape2D")
			if col:
				col.set_deferred("disabled", true)
		passage_trigger.call_deferred("activate", player)

var _passage_hint: Label = null

func _set_passage_hint(on: bool):
	if _passage_hint == null:
		if not on:
			return
		_passage_hint = _make_world_hint("E — протиснуться")
	if on:
		_passage_hint.position = to_local(player.global_position + Vector2(-_passage_hint.size.x * 0.5, -80))
	_passage_hint.modulate.a = move_toward(_passage_hint.modulate.a, 1.0 if on else 0.0, 0.12)

func _on_passage_completed():
	passage_done = true

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

		var _desired_x = px - ENEMY_MIN_GAP - i * ENEMY_SPACING
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
	# Рыба бежит — на ней загорается красная точка лазера. Рыба оборачивается, камера
	# скользит по лучу к снайперу, бликует оптика. Камера резко возвращается, и снайпер
	# делает предупредительный выстрел в пол у её ног. Затем — подсказка про SHIFT.
	state = State.SNIPER_CUTSCENE

	_lock_player_input(true)
	_stop_all_world()

	if player.sprite:
		player.sprite.stop()
		player.sprite.play("Idle")
		player.sprite.scale.x = 1

	_show_cutscene_bars(0.6)

	var player_cam_pos = _get_camera_target()
	var restore_pos = player_cam_pos
	_disable_camera_for_cutscene()
	var start_zoom = camera.zoom
	camera.global_position = player_cam_pos
	camera.reset_smoothing()
	# кадр чуть ниже, чтобы рыба не пряталась за нижней полосой
	player_cam_pos += Vector2(0, CUTSCENE_CAM_DROP)
	var drop = create_tween()
	drop.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drop.tween_property(camera, "global_position", player_cam_pos, 0.6)

	if is_instance_valid(sniper):
		sniper.visible = true

	# 1) лазер нашёл рыбу
	_start_sniper_aim()
	await _wait(0.7)
	if not is_inside_tree():
		return
	# рыба оборачивается на свет
	if player.sprite:
		player.sprite.scale.x = -1
	await _wait(0.45)
	if not is_inside_tree():
		return

	# 2) камера скользит вдоль луча к снайперу
	var sniper_pos = _sniper_muzzle_pos()
	var t1 = create_tween().set_parallel(true)
	t1.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# снайпер у левого края кадра — за краем уровня пустота, её не показываем
	t1.tween_property(camera, "global_position", sniper_pos + Vector2(285, 0), 1.5)
	t1.tween_property(camera, "zoom", start_zoom * 0.8, 1.5)
	await t1.finished
	if not is_inside_tree():
		return
	_scope_glint(sniper_pos)
	await _wait(1.0)
	if not is_inside_tree():
		return

	# 3) резко обратно к рыбе
	var t2 = create_tween().set_parallel(true)
	t2.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
	t2.tween_property(camera, "global_position", player_cam_pos, 0.8)
	t2.tween_property(camera, "zoom", start_zoom, 0.8)
	await t2.finished
	if not is_inside_tree():
		return

	# 4) предупредительный выстрел в пол за спиной рыбы
	_stop_sniper_aim()
	var floor_top = _floor_top_y()
	var hit = Vector2(player.global_position.x - 34.0, floor_top if not is_nan(floor_top) else player.global_position.y + 26.0)
	_start_bullet()
	await _bullet_fly_to(hit, 0.12)
	if not is_inside_tree():
		return
	_spawn_sparks(hit, Color(1, 0.75, 0.3), 18)
	_add_shake(0.35)
	_flash(Color(1, 1, 1, 0.15), 0.15)
	# рыба вздрагивает
	if player.sprite:
		player.sprite.play("Jump")
	var base_y = player.global_position.y
	var hop = create_tween()
	hop.tween_property(player, "global_position:y", base_y - 14.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(player, "global_position:y", base_y, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await hop.finished
	if not is_inside_tree():
		return
	if player.sprite:
		player.sprite.play("Idle")
	await _wait(0.5)
	if not is_inside_tree():
		return
	if player.sprite:
		player.sprite.scale.x = 1

	var back = create_tween()
	back.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(camera, "global_position", restore_pos, 0.6)
	_hide_cutscene_bars(0.6)
	await back.finished
	if not is_inside_tree():
		return
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

func _real_delta() -> float:
	var now = Time.get_ticks_msec()
	var d = (now - _last_ticks) / 1000.0
	_last_ticks = now
	return clamp(d, 0.0, 0.1)

func _process(delta: float) -> void:
	var rd = _real_delta()
	_update_fx(rd)
	if get_tree().paused:
		return
	_update_cutscene_motion(delta)

	if state == State.INTRO_RUN or state == State.QTE_GRAB:
		_update_intro_enemies()
		return

	if state == State.SNIPER_CUTSCENE or state == State.FORKLIFT_CUTSCENE or state == State.FORKLIFT_QTE:
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

		_update_shelf_hint()
		_update_passage_entry()

		if forklift_ready_for_throw and not forklift_stopped:
			var dist = player.global_position.distance_to(forklift.global_position)
			if dist < 260 and player.has_item:
				player.set_can_throw(true)
				if Input.is_action_just_pressed("interact"):
					_throw_item_at_forklift()
			else:
				player.set_can_throw(false)

		# лифт: после узкого прохода, рядом с кнопкой, по E
		var btn_pos = elevator_button.global_position + Vector2(268, 12) if elevator_button else Vector2.INF
		var near_button = passage_done and player.global_position.distance_to(btn_pos) < 70.0
		can_press_button = near_button
		_set_elevator_hint(near_button)
		if near_button and Input.is_action_just_pressed("interact"):
			can_press_button = false
			_set_elevator_hint(false)
			_lock_player_input(true)
			state = State.ELEVATOR_WAIT
			elevator_timer = 1.5
			if player.sprite:
				player.sprite.play("Idle")

	elif state == State.ELEVATOR_WAIT:
		elevator_timer -= delta
		if elevator_timer <= 0:
			state = State.ELEVATOR_GO
			
			if elevator.sprite_frames.has_animation("Open"):
				elevator.play("Open")
			else:
				elevator.modulate = Color.GREEN
				
			var t = create_tween()
			t.tween_property(player, "global_position:x", elevator.global_position.x, 0.5)
			await t.finished
			if not is_inside_tree(): return
			
			player.visible = false
			
			if elevator.sprite_frames.has_animation("Close"):
				elevator.play("Close")
			
			await get_tree().create_timer(0.5).timeout
			if not is_inside_tree(): return
			
			var lt = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			lt.tween_property(elevator, "global_position:y", elevator.global_position.y - 400, 1.5)
			# тёмный ColorRect внутри лифта уезжает вместе с ним
			var interior = get_node_or_null("EndAct/ColorRect")
			if interior:
				lt.parallel().tween_property(interior, "position:y", interior.position.y - 400, 1.5)
			await lt.finished
			if not is_inside_tree(): return
			
			await get_tree().create_timer(0.5).timeout
			if not is_inside_tree(): return
			_win()


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
	# из коллбэка физики нельзя создавать тела (снайпер) — запускаем кадром позже
	_play_forklift_cutscene.call_deferred()

# =====================================================================
#                       КАТСЦЕНА С ПОГРУЗЧИКОМ
# Шот 1  — рыба бежит, камера ведёт с упреждением, нарастает гул.
# Шот 2  — резкий перевод камеры на погрузчик: вспышка фар, тряска, он несётся со стеллажом на вилах.
# Шот 3  — общий план «рыба <-> погрузчик», из-за края экрана тянется лазер снайпера.
# Шот 4  — slow-mo, наезд камеры, QTE SHIFT.
#   Успех: рыба выпрыгивает вверх, пуля снайпера проходит под ней и бьёт в погрузчик ->
#          хит-стоп, искры, погрузчик глохнет, стеллаж падает поперёк коридора
#          (теперь его надо перелезть — ПРОБЕЛ).
#   Провал: пуля попадает в рыбу.
# =====================================================================

func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout

func _cam_tween(pos: Vector2, zoom: Vector2, dur: float, trans_type: Tween.TransitionType = Tween.TRANS_SINE, ease_type: Tween.EaseType = Tween.EASE_IN_OUT) -> Tween:
	var t = create_tween().set_parallel(true)
	t.set_ignore_time_scale(true)
	t.set_trans(trans_type).set_ease(ease_type)
	t.tween_property(camera, "global_position", pos, dur)
	t.tween_property(camera, "zoom", zoom, dur)
	return t

func _time_scale_to(target: float, dur: float) -> Tween:
	var t = create_tween()
	t.set_ignore_time_scale(true)
	t.tween_method(_set_time_scale, Engine.time_scale, target, dur)
	return t

func _set_time_scale(v: float) -> void:
	Engine.time_scale = v

func _fit_zoom(a: Vector2, b: Vector2, max_zoom: float) -> Vector2:
	var vp = get_viewport_rect().size
	var dist = max(abs(a.x - b.x), 1.0)
	var z = clamp(vp.x * 0.7 / dist, 0.6, max_zoom)
	return Vector2(z, z)

func _floor_top_y() -> float:
	var col = get_node_or_null("Floor/CollisionShape2D")
	if col and col.shape is RectangleShape2D:
		return col.global_position.y - col.shape.size.y / 2.0
	return NAN

func _forklift_center() -> Vector2:
	var col = forklift.get_node_or_null("CollisionShape2D")
	if col:
		return col.global_position
	return forklift.global_position + Vector2(90, 50)

var _shelf_base_y: float = 0.0

func _play_forklift_cutscene():
	# Спокойная версия: камера просто ведёт рыбу, рыба бежит по полу навстречу погрузчику,
	# снайпер стреляет в спину, slow-mo + QTE SHIFT. Успех: рывок вперёд — пуля проходит
	# мимо и попадает в погрузчик, он ломается, стеллаж падает с вил (его надо перелезть).
	state = State.FORKLIFT_CUTSCENE
	_lock_player_input(true)
	_stop_all_world()
	if not camera:
		return

	var cam_from = _get_camera_target()
	_disable_camera_for_cutscene()
	camera.global_position = cam_from
	camera.reset_smoothing()
	var start_zoom: Vector2 = camera.zoom
	_show_cutscene_bars(0.7)

	# рыба могла влететь в триггер в прыжке — сначала аккуратно опускаем её на пол
	await _ground_player()
	if not is_inside_tree():
		return

	if not sniper or not is_instance_valid(sniper):
		_spawn_sniper(false)
	if sniper and is_instance_valid(sniper):
		if sniper.has_method("deactivate"):
			sniper.deactivate()
		sniper.visible = true

	# --- погрузчик со стеллажом на вилах, на полу, справа
	forklift_stopped = false
	forklift.modulate = Color.WHITE
	forklift.rotation = 0.0
	forklift.collision_layer = 0
	forklift.collision_mask = 0
	var fc_off = _forklift_center() - forklift.global_position
	forklift.global_position.x = player.global_position.x + FL_SPAWN_AHEAD - fc_off.x
	_prepare_shelf_on_forks()
	forklift.visible = true
	falling_shelf.visible = true

	# --- камера мягко ведёт рыбу с упреждением и чуть отдаляется
	_cam_track = player
	_cam_track_offset = Vector2(120.0, cam_from.y - player.global_position.y + CUTSCENE_CAM_DROP)
	var zt = create_tween()
	zt.set_ignore_time_scale(true)
	zt.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	zt.tween_property(camera, "zoom", start_zoom * 0.85, 1.4)

	# --- рыба бежит, погрузчик едет навстречу
	if player.sprite:
		player.sprite.scale.x = 1
		player.sprite.play("Run")
	_cutscene_running = true
	_shake_floor = 0.05

	while _forklift_center().x - player.global_position.x > FL_QTE_GAP:
		await get_tree().process_frame
		if not is_inside_tree():
			return

	# --- снайпер целится, slow-mo, QTE
	state = State.FORKLIFT_QTE
	_start_sniper_aim()
	_time_scale_to(FL_SLOWMO, FL_SLOWMO_RAMP)
	_start_bullet()
	var success = await _run_shift_qte_cutscene()
	if not is_inside_tree():
		return
	_stop_sniper_aim()
	_shake_floor = 0.0

	if success:
		await _forklift_success(start_zoom)
	else:
		await _forklift_fail()

func _ground_player() -> void:
	var floor_top = _floor_top_y()
	if is_nan(floor_top):
		return
	var feet = player.get("_feet_off")
	if feet == null:
		feet = 28.0
	var target_y = floor_top - feet
	var dy = target_y - player.global_position.y
	if abs(dy) < 1.5:
		player.global_position.y = target_y
		return
	if player.sprite:
		player.sprite.play("Falling")
	var t = create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(player, "global_position:y", target_y, clamp(abs(dy) / 500.0, 0.08, 0.35))
	await t.finished
	if player.sprite and player.sprite.sprite_frames.has_animation("Landing"):
		player.sprite.play("Landing")
		await _wait(0.2)

func _update_cutscene_motion(delta: float):
	if not _cutscene_running:
		return
	player.global_position.x += player.run_speed * FL_FISH_SPEED_MULT * delta
	if not forklift_stopped:
		forklift.global_position.x -= FL_SPEED * delta
		_attach_shelf_to_forklift()

func _prepare_shelf_on_forks():
	# ставим стеллаж на пол и вплотную перед погрузчиком
	falling_shelf.rotation = 0.0
	var floor_top = _floor_top_y()
	if not is_nan(floor_top):
		falling_shelf.global_position.y += floor_top - _shelf_rect().end.y
	_shelf_base_y = falling_shelf.global_position.y
	var radius = 38.0
	var col = forklift.get_node_or_null("CollisionShape2D")
	if col and col.shape is CapsuleShape2D:
		radius = col.shape.radius
	var front_x = _forklift_center().x - radius - 4.0
	falling_shelf.global_position.x += front_x - _shelf_rect().end.x
	_shelf_dx = falling_shelf.global_position.x - forklift.global_position.x
	_attach_shelf_to_forklift()
	var shelf_col = falling_shelf.get_node_or_null("CollisionShape2D")
	if shelf_col:
		shelf_col.set_deferred("disabled", true)

func _attach_shelf_to_forklift():
	falling_shelf.rotation = 0.0
	falling_shelf.global_position = Vector2(forklift.global_position.x + _shelf_dx, _shelf_base_y - 10.0)

# ---------- пуля ----------

func _start_bullet():
	if _bullet == null:
		_bullet = Line2D.new()
		_bullet.width = 3.0
		_bullet.default_color = Color(1, 0.95, 0.6, 1)
		_bullet.z_index = 90
		add_child(_bullet)
	_bullet.modulate.a = 1.0
	_bullet.visible = true
	# стартуем с левого края экрана на линии «снайпер -> рыба», чтобы пулю было видно
	var muzzle = _sniper_muzzle_pos()
	var chest = player.global_position + Vector2(0, -6)
	var vp = get_viewport_rect().size
	var left_x = camera.global_position.x - vp.x / (2.0 * camera.zoom.x) - 40.0
	var dir = (chest - muzzle).normalized()
	var k = (left_x - muzzle.x) / dir.x if abs(dir.x) > 0.01 else 0.0
	_bullet_from = muzzle + dir * max(k, 0.0)
	_bullet_pos = _bullet_from
	_bullet_active = true
	_draw_bullet()

func _update_bullet_qte():
	if not _bullet_active or not shift_qte:
		return
	var dur = shift_qte.get("_duration")
	var tm = shift_qte.get("qte_timer")
	if dur == null or tm == null:
		return
	# пуля долетает до рыбы к концу окна нажатия
	var k = clamp(tm / (dur * 0.9), 0.0, 1.0)
	var chest = player.global_position + Vector2(0, -6)
	_bullet_pos = _bullet_from.lerp(chest, k)
	_draw_bullet()

func _draw_bullet():
	var dir = (_bullet_pos - _bullet_from).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var tail = _bullet_pos - dir * 70.0
	_bullet.points = PackedVector2Array([to_local(tail), to_local(_bullet_pos)])

func _bullet_lerp(k: float, from: Vector2, target: Vector2) -> void:
	_bullet_pos = from.lerp(target, k)
	_draw_bullet()

func _bullet_fly_to(target: Vector2, dur: float) -> void:
	var from = _bullet_pos
	var t = create_tween()
	t.set_ignore_time_scale(true)
	t.tween_method(_bullet_lerp.bind(from, target), 0.0, 1.0, dur)
	await t.finished
	_bullet_active = false
	var f = create_tween()
	f.set_ignore_time_scale(true)
	f.tween_property(_bullet, "modulate:a", 0.0, 0.15)

# ---------- исходы ----------

func _forklift_success(start_zoom: Vector2) -> void:
	_cutscene_running = false
	_bullet_active = false

	# рывок вперёд, к погрузчику — пуля проходит мимо
	await _fish_dash(FL_DASH_DIST, FL_DASH_TIME)
	_time_scale_to(1.0, 0.6)
	if player.sprite:
		player.sprite.play("Idle")

	# пуля летит дальше и попадает в погрузчик
	await _bullet_fly_to(_forklift_center(), 0.35)
	if not is_inside_tree():
		return
	_forklift_break()
	await _drop_shelf()
	if not is_inside_tree():
		return
	_deactivate_sniper()
	_show_shelf_hint(_shelf_rect())
	await _wait(1.2)
	if not is_inside_tree():
		return

	# возвращаем камеру
	_cam_track = null
	if "look_offset" in camera:
		camera.look_offset = Vector2.ZERO
	_cam_tween(_get_camera_target(), start_zoom, 1.0)
	_hide_cutscene_bars(0.9)
	await _wait(1.0)
	if not is_inside_tree():
		return
	_cam_original_position = _get_camera_target()
	_cam_original_zoom = start_zoom
	_cam_original_offset = _cam_base_offset
	_restore_camera_after_cutscene()
	_resume_all_world()
	_lock_player_input(false)
	state = State.RUNNING

func _forklift_fail() -> void:
	_cutscene_running = false
	_bullet_active = false
	Engine.time_scale = 1.0
	await _bullet_fly_to(player.global_position + Vector2(0, -6), 0.05)
	if not is_inside_tree():
		return
	_flash(Color(1, 0.2, 0.15, 0.4), 0.3)
	_add_shake(0.4)
	_spawn_sparks(player.global_position, Color(1, 0.35, 0.3), 14)
	_cam_track = null
	is_game_over = true
	state = State.GAMEOVER
	_deactivate_sniper()
	_stop_all_world()
	player.die()

func _fish_dash(dist: float, dur: float) -> void:
	if player.sprite:
		player.sprite.play("Run")
	var t = create_tween()
	t.set_ignore_time_scale(true)
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(player, "global_position:x", player.global_position.x + dist, dur)
	# шлейф — по таймерам, не блокируя; ждём только сам рывок
	for i in 4:
		get_tree().create_timer(dur * i / 4.0, true, false, true).timeout.connect(_spawn_ghost)
	await t.finished

func _spawn_ghost():
	var spr: AnimatedSprite2D = player.sprite
	if spr == null or spr.sprite_frames == null:
		return
	var tex = spr.sprite_frames.get_frame_texture(spr.animation, spr.frame)
	if tex == null:
		return
	var g = Sprite2D.new()
	g.texture = tex
	g.flip_h = spr.flip_h
	g.z_index = 40
	add_child(g)
	g.global_position = spr.global_position
	g.global_scale = spr.global_scale
	g.modulate = Color(0.6, 0.85, 1.0, 0.55)
	var t = create_tween()
	t.set_ignore_time_scale(true)
	t.tween_property(g, "modulate:a", 0.0, 0.4)
	t.tween_callback(g.queue_free)

func _forklift_break():
	forklift_stopped = true
	_flash(Color(1, 1, 1, 0.3), 0.2)
	_add_shake(0.5)
	_spawn_sparks(_forklift_center(), Color(1, 0.75, 0.3), 28)
	var t = create_tween().set_parallel(true)
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(forklift, "global_position:x", forklift.global_position.x + 30.0, 0.6)
	t.tween_property(forklift, "rotation", deg_to_rad(-5.0), 0.6)
	t.tween_property(forklift, "modulate", Color(0.4, 0.38, 0.38, 1), 0.5)

func _drop_shelf() -> void:
	# стеллаж соскальзывает с вил на пол, чуть качнувшись
	var t = create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(falling_shelf, "global_position:y", _shelf_base_y, 0.3)
	t.parallel().tween_property(falling_shelf, "rotation", deg_to_rad(-4.0), 0.3)
	t.tween_property(falling_shelf, "rotation", deg_to_rad(2.0), 0.18)
	t.tween_property(falling_shelf, "rotation", 0.0, 0.18)
	await t.finished
	_add_shake(0.3)
	var col = falling_shelf.get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", false)
	falling_shelf.add_to_group("climbable")
	# лазание рыбы (E) ищет препятствия в Barriers — кладём стеллаж туда
	var barriers = get_node_or_null("Barriers")
	if barriers and falling_shelf.get_parent() != barriers:
		falling_shelf.reparent(barriers)
	shelf_climbed = false

func _shelf_rect() -> Rect2:
	var col = falling_shelf.get_node_or_null("CollisionShape2D")
	if col == null or not (col.shape is RectangleShape2D):
		return Rect2(falling_shelf.global_position, Vector2(60, 60))
	var h: Vector2 = col.shape.size / 2.0
	var xf: Transform2D = col.global_transform
	var r := Rect2(xf * Vector2(-h.x, -h.y), Vector2.ZERO)
	for p in [Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]:
		r = r.expand(xf * p)
	return r

# ---------- снайпер в катсцене ----------

func _sniper_muzzle_pos() -> Vector2:
	if sniper and is_instance_valid(sniper):
		var m = sniper.get_node_or_null("Muzzle")
		if m:
			return m.global_position
		return sniper.global_position
	# снайпера нет — стреляем «из-за кадра» слева
	return player.global_position + Vector2(-1400, -60)

func _start_sniper_aim():
	_aim_active = true
	_aim_width = 10.0
	_aim_blink = 0.0
	var w = create_tween()
	w.set_ignore_time_scale(true)
	w.tween_property(self, "_aim_width", 1.5, 0.5 + FL_QTE_TIME)

func _stop_sniper_aim():
	_aim_active = false
	if sniper and is_instance_valid(sniper) and sniper.get("aim_line"):
		sniper.aim_line.visible = false

func _update_sniper_aim(rd: float):
	if not _aim_active or not sniper or not is_instance_valid(sniper):
		return
	var line: Line2D = sniper.get("aim_line")
	if line == null:
		return
	_aim_blink += rd * lerp(6.0, 22.0, clamp((10.0 - _aim_width) / 8.5, 0.0, 1.0))
	var origin = _sniper_muzzle_pos()
	var dir = (player.global_position - origin).normalized()
	line.visible = true
	line.global_position = origin
	line.global_rotation = dir.angle()
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(100000, 0)])
	line.width = _aim_width
	var blink = 0.55 + 0.45 * sin(_aim_blink * TAU)
	line.default_color = Color(1, 0.15, 0.15, blink)

# ---------- эффекты ----------

func _create_fx_layer():
	_vignette = ColorRect.new()
	_vignette.color = Color(0.8, 0.0, 0.0, 0.0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cutscene_canvas.add_child(_vignette)
	_cutscene_canvas.move_child(_vignette, 0)

	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cutscene_canvas.add_child(_flash_rect)

func _flash(col: Color, dur: float):
	if not _flash_rect:
		return
	_flash_rect.color = col
	var t = create_tween()
	t.set_ignore_time_scale(true)
	t.tween_property(_flash_rect, "color:a", 0.0, dur)

func _set_vignette(alpha: float, dur: float):
	if not _vignette:
		return
	var t = create_tween()
	t.set_ignore_time_scale(true)
	t.tween_property(_vignette, "color:a", alpha, dur)

func _add_shake(amount: float):
	_shake = clamp(max(_shake, amount), 0.0, 1.2)

func _update_fx(rd: float):
	_update_sniper_aim(rd)
	_update_bullet_qte()
	if camera:
		if _cam_track and is_instance_valid(_cam_track):
			camera.global_position = camera.global_position.lerp(_cam_track.global_position + _cam_track_offset, clamp(rd * 10.0, 0.0, 1.0))
		_shake = move_toward(_shake, 0.0, rd * 1.6)
		var s = max(_shake, _shake_floor)
		var amp = s * s * 14.0
		if amp > 0.05:
			camera.offset = _cam_base_offset + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * amp
			_was_shaking = true
		elif _was_shaking:
			camera.offset = _cam_base_offset
			_was_shaking = false

# блик оптики: крестик-звёздочка, вспыхивает и гаснет
func _scope_glint(pos: Vector2):
	var g = Node2D.new()
	g.z_index = 95
	add_child(g)
	g.global_position = pos
	for ang in [0.0, PI / 2.0, PI / 4.0, -PI / 4.0]:
		var l = Line2D.new()
		var ln = 16.0 if is_equal_approx(fmod(ang, PI / 2.0), 0.0) else 8.0
		l.points = PackedVector2Array([Vector2(-ln, 0).rotated(ang), Vector2(ln, 0).rotated(ang)])
		l.width = 2.0
		l.default_color = Color(1, 1, 0.9, 1)
		g.add_child(l)
	g.scale = Vector2.ZERO
	var t = create_tween()
	t.set_ignore_time_scale(true)
	t.tween_property(g, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(g, "rotation", PI / 4.0, 0.5)
	t.tween_property(g, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(g.queue_free)

func _spawn_sparks(pos: Vector2, col: Color, amount: int):
	var p = CPUParticles2D.new()
	p.z_index = 80
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.7
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 380.0
	p.gravity = Vector2(0, 700)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = col
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.5, true, false, true).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)

# ---------- подсказки в мире ----------

const HINT_FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
var _hint_font: FontFile = null

# подсказка в мире в стиле фабрики: тёмная плашка, янтарная полоска слева, пиксельный шрифт
func _make_world_hint(text: String) -> Label:
	if _hint_font == null:
		_hint_font = ResourceLoader.load(HINT_FONT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
		if _hint_font:
			_hint_font.fixed_size = 0
	var l = Label.new()
	l.text = text
	l.z_index = 60
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _hint_font:
		l.add_theme_font_override("font", _hint_font)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.09, 0.96)
	sb.border_color = Color(0.97, 0.76, 0.26)
	sb.border_width_left = 3
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.content_margin_left = 7
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(1, 2)
	l.add_theme_stylebox_override("normal", sb)
	l.size = Vector2(120, 16)
	l.modulate.a = 0.0
	add_child(l)
	l.reset_size()
	return l

func _show_shelf_hint(r: Rect2):
	if _shelf_hint == null:
		_shelf_hint = _make_world_hint("E — залезть")
	_shelf_hint.position = to_local(Vector2(r.get_center().x - _shelf_hint.size.x * 0.5, r.position.y - 30.0))
	var t = create_tween()
	t.tween_property(_shelf_hint, "modulate:a", 1.0, 0.3)

func _update_shelf_hint():
	if _shelf_hint == null or _shelf_hint.modulate.a <= 0.0:
		return
	var r = _shelf_rect()
	if player.global_position.x > r.position.x + 10.0 or player.global_position.y < r.position.y:
		var t = create_tween()
		t.tween_property(_shelf_hint, "modulate:a", 0.0, 0.25)
		shelf_climbed = true

func _set_elevator_hint(on: bool):
	if _elevator_hint == null:
		if not on:
			return
		_elevator_hint = _make_world_hint("E — вызвать лифт")
	if on:
		_elevator_hint.position = to_local(elevator_button.global_position + Vector2(268 - _elevator_hint.size.x * 0.5, -40))
	var target = 1.0 if on else 0.0
	if abs(_elevator_hint.modulate.a - target) > 0.01:
		_elevator_hint.modulate.a = move_toward(_elevator_hint.modulate.a, target, 0.1)

func _force_dash():
	if not player:
		return
	player.is_dashing = false
	player.dash_cooldown = 0.0
	if player.has_method("_dash"):
		player._dash()


func _run_shift_qte_cutscene() -> bool:
	if not shift_qte or not shift_qte.has_method("show_qte"):
		await get_tree().create_timer(1.2, true, false, true).timeout
		return true

	shift_qte.show_qte(FL_QTE_TIME, false)

	# (лямбда не может менять внешние локальные переменные — поэтому Dictionary)
	var st = {"result": false, "received": false}
	var callback = func(success: bool):
		st["result"] = success
		st["received"] = true
	if not shift_qte.qte_result.is_connected(callback):
		shift_qte.qte_result.connect(callback)

	while not st["received"]:
		await get_tree().process_frame
		if not is_inside_tree():
			return false

	if shift_qte.qte_result.is_connected(callback):
		shift_qte.qte_result.disconnect(callback)
	return st["result"]

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

	if player:
		Global.player_position = player.global_position
	# progress is kept even if the player never saved manually
	Global.autosave(Global.SCENE_STORAGE)

	# the prologue is over: the fish got out of the hallway (Hallway -> NearFactory)
	if has_node("/root/Achievements"):
		Achievements.unlock_chase()
	GlobalMusic.stop_music()
	Global.goto_scene(Global.SCENE_STORAGE)

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	# the pause menu only closes itself; opening it is up to the level
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_toggle_pause()
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
		if player.has_method("set_movement_blocked") and player.movement_blocked:
			player.set_movement_blocked(false)
			return

func _toggle_pause():
	if state == State.GAMEOVER or state == State.WIN or state == State.INTRO_RUN or state == State.QTE_GRAB or state == State.SNIPER_CUTSCENE \
	or state == State.FORKLIFT_CUTSCENE or state == State.FORKLIFT_QTE:
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
