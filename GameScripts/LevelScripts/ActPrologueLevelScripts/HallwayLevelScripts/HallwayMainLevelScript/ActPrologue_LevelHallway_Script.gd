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
const INTRO_RUN_TIME: float = 6.5     # больше не используется: рыба бежит с катсценной скоростью (run_speed * FL_FISH_SPEED_MULT)
const INTRO_CAM_LEAD: float = 60.0    # камера чуть впереди рыбы, но погоня сзади остаётся в кадре
const INTRO_CAM_ZOOM: float = 0.85    # как в катсцене с погрузчиком
const INTRO_QTE_ZOOM: float = 0.92    # на захвате камера слегка наезжает на рыбу (сильнее — плашка E уходит под полосу)
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
var _intro_start_zoom: Vector2 = Vector2.ONE
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
	_setup_hints_and_arena()
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
	# Катсцена в стиле остальных: полосы, камера отцеплена от игрока и мягко ведёт рыбу
	# с небольшим упреждением и отдалением, кадр опущен на CUTSCENE_CAM_DROP.
	# Рыба бежит с той же скоростью, что в катсцене с погрузчиком.
	if _intro_started:
		return
	_intro_started = true
	state = State.INTRO_RUN

	if player.sprite:
		player.sprite.stop()
		player.sprite.play("Run")
		player.sprite.scale.x = 1

	var intro_speed = player.run_speed * FL_FISH_SPEED_MULT
	var fade_delay = (INTRO_FADE_X - INTRO_START_X) / intro_speed
	_start_fade_after(fade_delay)

	if camera:
		var cam_from = _get_camera_target()
		_disable_camera_for_cutscene()
		_intro_start_zoom = camera.zoom
		_cam_track = player
		_cam_track_offset = Vector2(INTRO_CAM_LEAD, cam_from.y - player.global_position.y + CUTSCENE_CAM_DROP)
		camera.global_position = player.global_position + _cam_track_offset
		camera.zoom = _intro_start_zoom * INTRO_CAM_ZOOM
		camera.reset_smoothing()
		# экран ещё чёрный — полосы ставим сразу
		_show_cutscene_bars(0.01)

	while player.global_position.x < INTRO_CAPTURE_X:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		player.global_position.x = min(player.global_position.x + intro_speed * get_process_delta_time(), INTRO_CAPTURE_X)

	if player.sprite:
		player.sprite.stop()
		player.sprite.play("Idle")

	if camera:
		# захват: камера чуть наезжает на рыбу
		var zt = create_tween()
		zt.set_ignore_time_scale(true)
		zt.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		zt.tween_property(camera, "zoom", _intro_start_zoom * INTRO_QTE_ZOOM, 0.6)
		var ot = create_tween()
		ot.set_ignore_time_scale(true)
		ot.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ot.tween_property(self, "_cam_track_offset:x", 0.0, 0.6)

	_start_qte_grab()

func _end_intro_camera() -> void:
	# возвращаем обычную камеру так же, как после погрузчика
	if not camera:
		return
	_cam_track = null
	if "look_offset" in camera:
		camera.look_offset = Vector2.ZERO
	_cam_tween(_get_camera_target(), _intro_start_zoom, 0.8)
	_hide_cutscene_bars(0.7)
	await _wait(0.8)
	if not is_inside_tree():
		return
	_cam_original_position = _get_camera_target()
	_cam_original_zoom = _intro_start_zoom
	_cam_original_offset = _cam_base_offset
	_restore_camera_after_cutscene()

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

	var success = await _run_e_button_qte_at(player.global_position + Vector2(0, -72))

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

		await _end_intro_camera()
		if not is_inside_tree():
			return

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
		_update_hints_and_arena(delta)

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
			_play_elevator_exit()



# Лифт никуда не едет: двери открываются, рыба заходит, двери закрываются,
# лёгкая тряска «поехали» и затемнение — дальше следующий уровень.
func _play_elevator_exit() -> void:
	if elevator.sprite_frames.has_animation("Open"):
		await _play_elevator_anim("Open")
		if not is_inside_tree(): return
	else:
		elevator.modulate = Color.GREEN

	await _wait(0.25)
	if not is_inside_tree(): return

	# рыба заходит внутрь
	var to_x = elevator.global_position.x
	if player.sprite:
		player.sprite.scale.x = 1 if to_x >= player.global_position.x else -1
		player.sprite.play("Run")
	var dist = abs(to_x - player.global_position.x)
	var t = create_tween()
	t.tween_property(player, "global_position:x", to_x, clamp(dist / (player.run_speed * 0.6), 0.25, 1.2))
	await t.finished
	if not is_inside_tree(): return
	if player.sprite:
		player.sprite.play("Idle")
	# в глубину кабины: рыба темнеет и пропадает
	var dim = create_tween()
	dim.tween_property(player, "modulate", Color(0.25, 0.25, 0.3, 0.0), 0.35)
	await dim.finished
	if not is_inside_tree(): return
	player.visible = false

	await _wait(0.2)
	if not is_inside_tree(): return
	if elevator.sprite_frames.has_animation("Close"):
		await _play_elevator_anim("Close")
		if not is_inside_tree(): return

	# «поехали»: лифт стоит на месте, только лёгкая тряска и затемнение
	await _wait(0.3)
	if not is_inside_tree(): return
	_add_shake(0.35)
	var canvas = CanvasLayer.new()
	canvas.layer = 95
	add_child(canvas)
	var black = ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(black)
	var ft = create_tween()
	ft.tween_property(black, "color:a", 1.0, 1.2).set_delay(0.4)
	await ft.finished
	if not is_inside_tree(): return
	await _wait(0.3)
	if not is_inside_tree(): return
	_win()

# проигрывает анимацию лифта один раз (в сцене они зациклены) и оставляет последний кадр
func _play_elevator_anim(anim: String) -> void:
	var frames: SpriteFrames = elevator.sprite_frames
	if frames.get_animation_loop(anim):
		frames = frames.duplicate()
		frames.set_animation_loop(anim, false)
		elevator.sprite_frames = frames
	elevator.play(anim)
	var fps = max(frames.get_animation_speed(anim) * abs(elevator.speed_scale), 0.01)
	var dur = 0.0
	for i in frames.get_frame_count(anim):
		dur += frames.get_frame_duration(anim, i) / fps
	await _wait(dur + 0.05)

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

# =====================================================================
#                  ПОДСКАЗКИ + БОЕВЫЕ ЗОНЫ
# Подсказка «залезть по E» — у первого ящика после катсцены со снайпером.
# Зона 1 (между Obstacle2 и Obstacle3): 2–3 наземных врага по очереди, лазание выключено.
# Зона 2 (после прохода и Obstacle9, большая): собака и обезьяна по одному на полу,
#   а на балконе второго этажа — голубь-снайпер. Луч замер — рывок (SHIFT). Под балконом
#   пули не достают, наверх — по E. Камера на время боя отдаляется.
# Пока идёт бой: впереди лазерные ворота, снайпер коридора молчит.
# Враги — готовые сцены из папок проекта (собака, обезьяна, голубь со склада).
# =====================================================================

const TUTORIAL_HINTS_SCRIPT := preload("res://GameScripts/UIScripts/TutorialScripts/Tutorial_Hints.gd")
const ARENA_DOG := preload("res://GameScenes/EntityScenes/EnemyEntityScenes/MechaDogScenes/Enemy_MechaDog_Storage_Scene.tscn")
const ARENA_MONKEY := preload("res://GameScenes/EntityScenes/EnemyEntityScenes/MechaMonkeyScenes/Enemy_MechaMonkey_Storage_Scene.tscn")
const ARENA_PIGEON := preload("res://GameScenes/EntityScenes/EnemyEntityScenes/MechaPigeonScenes/Enemy_MechaPigeon_Storage_Scene.tscn")

const ARENA_ENEMY_HP: int = 3            # в прологе враги слабее, чем на складе (там 5)
const ARENA_SPAWN_GAP: float = 3.5       # следующий наземный враг выходит через столько секунд…
const ARENA_HEAL: int = 2                # награда за зачистку

# «не такие буйные»: вход в зону с паузой, предупреждение перед каждым врагом,
# враги медленнее, после каждого попадания по рыбе — передышка
const ARENA_INTRO_DELAY: float = 1.3     # ворота закрылись — пауза до первого врага
const ARENA_DROP_WARN: float = 0.8       # красная метка на полу до того, как враг спрыгнет
const ARENA_LANDING_STUN: float = 1.0    # приземлился — секунду приходит в себя
const ARENA_SPEED_MULT: float = 0.74     # бег и рывки врагов медленнее, чем на складе
const ARENA_HIT_BREATHER: float = 1.6    # после попадания по рыбе враги ждут перед новой атакой

# предметы во второй зоне: паллет можно взять (E) и бросить во врага (E) — оглушение
const ITEM_SCENE := preload("res://GameScenes/LevelScenes/ActPrologueLevelScenes/HallwayLevelScenes/HallwayEntityScenes/HallwayGrabbableItemScene/ActPrologue_LevelHallway_GrabbableItem_Scene.tscn")
const ITEM_PICK_RADIUS: float = 46.0
const ITEM_STUN_TIME: float = 2.0
const ITEM_THROW_SPEED: float = 620.0
const ITEM_THROW_RANGE: float = 650.0
const ITEM_RESPAWN_TIME: float = 7.0

# зона 1 (между Obstacle2 и Obstacle3)
const ARENA1_MIN_ENEMIES: int = 2
const ARENA1_MAX_ENEMIES: int = 3
const ARENA1_MAX_ALIVE: int = 2          # живых наземных одновременно

# зона 2 (после прохода и Obstacle9): трое на полу по очереди, голубь-снайпер на балконе (не в счёт, неубиваемый)
const ARENA2_GAP_AFTER_O9: float = 140.0 # отступ от Obstacle9
const ARENA2_WIDTH: float = 1100.0
const ARENA2_MAX_ALIVE: int = 1          # наземные выходят строго по одному — голубь и так давит
const BALCONY_ABOVE_TILES: float = 20.0  # балкон на столько пикселей выше самого высокого тайла (стеллажей)
const BALCONY_WIDTH: float = 230.0
const BALCONY_X_FROM_LEFT: float = 640.0 # центр балкона от левого края зоны
# голубь на балконе — обычный складской, без послаблений, и в счёт врагов не входит.
# Когда трое на полу убиты, ему звонят: бубнит в трубку (диалоговое окно) и уходит в дверь.
const CHATTER_SCENE := preload("res://GameScenes/UIScenes/ChatterScenes/DialogueNode.tscn")
const SNIPER_CALL_LINES := [
	"...Алло? Да, шеф. На позиции.",
	"Какая пересменка? Уже?! Я ж её почти снял...",
	"Да понял я, понял. Иду.",
]
const SNIPER_RING_TIME: float = 1.6     # сколько звонит телефон, прежде чем голубь ответит
const ARENA2_VIEW_MARGIN_TOP: float = 80.0   # сколько места над балконом держать в кадре (голубь)
const ARENA2_VIEW_MARGIN_BOTTOM: float = 30.0

enum Arena { WAITING, FIGHT, CLEARED }
var _arenas: Array = []
var _hints: CanvasLayer = null
var _climb_hint_queued: bool = false
var _arena_node: Node2D = null
var _arena_counter: Label = null
var _arena_counter_layer: CanvasLayer = null
var _balcony: StaticBody2D = null
var _balcony_rect: Rect2 = Rect2()
var _balcony_h: float = 0.0
## только для тестов: принудительный состав наземных врагов первой зоны
var arena_debug_queue: Array = []

var _player_barriers: Node = null
var _items: Array = []            # [{node, spot, respawn}]
var _item_arena: Dictionary = {}
var _held_item_tex: Texture2D = null
var _item_hint: Label = null
var _thrown_once: bool = false

func _setup_hints_and_arena():
	_hints = TUTORIAL_HINTS_SCRIPT.new()
	_hints.name = "TutorialHints"
	add_child(_hints)

	_arena_node = Node2D.new()
	_arena_node.name = "ArenaEnemies"
	add_child(_arena_node)
	if "barriers_node" in player:
		_player_barriers = player.barriers_node

	var o2 = get_node_or_null("Barriers/Obstacle2")
	var o3 = get_node_or_null("Barriers/Obstacle3")
	if o2 and o3:
		var n = randi_range(ARENA1_MIN_ENEMIES, ARENA1_MAX_ENEMIES)
		var ground = [ARENA_DOG, ARENA_MONKEY, ARENA_DOG] if n >= 3 else [ARENA_DOG, [ARENA_DOG, ARENA_MONKEY].pick_random()]
		var left = _node_rect(o2).end.x
		var right = _node_rect(o3).position.x
		_arenas.append(_new_arena("arena1", left, right, ground, ARENA1_MAX_ALIVE,
			[right - 80.0, right - 170.0, left + 60.0], true, false))

	var o9 = get_node_or_null("Barriers/Obstacle9")
	var btn = elevator_button
	if o9:
		var left2 = _node_rect(o9).end.x + ARENA2_GAP_AFTER_O9
		var right2 = left2 + ARENA2_WIDTH
		if btn:
			right2 = min(right2, btn.global_position.x + 268.0 - 220.0)
		_build_balcony(left2 + BALCONY_X_FROM_LEFT)
		# на полу трое по очереди (голубь на балконе не в счёт)
		_arenas.append(_new_arena("arena2", left2, right2, [ARENA_DOG, ARENA_MONKEY, ARENA_DOG], ARENA2_MAX_ALIVE,
			[right2 - 90.0, left2 + 60.0, right2 - 160.0], false, true))

func _new_arena(id: String, left: float, right: float, ground: Array, max_alive: int,
		spots: Array, block_climb: bool, with_balcony_sniper: bool) -> Dictionary:
	return {
		"id": id, "left": left, "right": right, "ground": ground.duplicate(),
		"max_alive": max_alive, "spots": spots, "block_climb": block_climb,
		"sniper": with_balcony_sniper, "state": Arena.WAITING, "enemies": [],
		"queue": [], "total": 0, "killed": 0, "next_timer": 0.0, "spawn_i": 0,
		"saved_barriers": null, "gate": null, "wall": null, "zoom": Vector2.ZERO,
		"intro_t": 0.0, "pending": 0, "last_hp": -1, "items": with_balcony_sniper,
		"sniper_leaving": false,
	}

func _node_rect(o: Node) -> Rect2:
	var out := Rect2()
	for c in o.get_children():
		if c is CollisionShape2D and c.shape is RectangleShape2D:
			var h: Vector2 = c.shape.size / 2.0
			var r := Rect2(c.global_position - h, c.shape.size)
			out = r if not out.has_area() else out.merge(r)
	return out

## Вызывается каждый кадр в RUNNING.
func _update_hints_and_arena(delta: float):
	if not _climb_hint_queued and _hints and sniper_cutscene_played:
		var o1 = get_node_or_null("Barriers/Obstacle")
		if o1 and player.global_position.x > _node_rect(o1).position.x - 260.0:
			_climb_hint_queued = true
			var past_x = _arenas[0]["left"] if _arenas.size() > 0 else INF
			_hints.hint("climb", "ЗАЛЕЗТЬ|Встань вплотную к ящику — рыба вскарабкается наверх", ["interact"],
				func(): return player.is_climbing_animation or player.global_position.x > past_x, 1.5, 9.0)

	for a in _arenas:
		match a["state"]:
			Arena.WAITING:
				if player.global_position.x > a["left"] + 70.0 and player.global_position.x < a["right"] \
						and player.is_on_floor() and not player.is_dead:
					_start_arena(a)
			Arena.FIGHT:
				_update_arena(a, delta)

func _start_arena(a: Dictionary):
	a["state"] = Arena.FIGHT
	a["queue"] = a["ground"].duplicate()
	if a["id"] == "arena1" and not arena_debug_queue.is_empty():
		a["queue"] = arena_debug_queue.duplicate()
	a["total"] = a["queue"].size()   # голубь-снайпер в счёт не входит
	a["killed"] = 0
	a["enemies"] = []
	a["spawn_i"] = 0

	_deactivate_sniper()
	if a["block_climb"] and "barriers_node" in player:
		a["saved_barriers"] = player.barriers_node
		player.barriers_node = null
	_make_arena_gate(a)
	_make_arena_counter()
	_add_shake(0.25)

	if a["sniper"]:
		_arena_spawn_balcony_sniper(a)
		if _hints:
			_hints.hint("throw", "БРОСОК|Подбери паллет и швырни во врага — он оглушён на 2 секунды", ["interact"],
				func(): return _thrown_once or a["state"] == Arena.CLEARED, 2.0, 10.0)
		if camera:
			_frame_camera_for_balcony(a)
		if _hints:
			_hints.hint("balcony", "СНАЙПЕР НА БАЛКОНЕ|Его не достать. Луч замер — жми рывок, под балконом пули не долетят", ["Run"],
				func(): return a["state"] == Arena.CLEARED, 2.5, 11.0)
	elif _hints:
		_hints.hint("fight", "ДРАТЬСЯ|Враги перекрыли путь. ЛКМ — удар, SHIFT — увернуться", ["ЛКМ"],
			func(): return a["state"] == Arena.CLEARED, 2.0, 10.0)

	if a["items"]:
		_start_items(a)
	# сначала пауза: ворота закрылись, рыба осматривается — враги чуть позже
	a["intro_t"] = ARENA_INTRO_DELAY
	a["next_timer"] = ARENA_SPAWN_GAP
	a["last_hp"] = player.hp if "hp" in player else -1

## Камера отдаляется и поднимается так, чтобы в кадре были и пол, и голубь на балконе.
func _frame_camera_for_balcony(a: Dictionary):
	var floor_top = _floor_top_y()
	if is_nan(floor_top) or not _balcony_rect.has_area():
		return
	a["zoom"] = camera.zoom
	var view_top = _balcony_rect.position.y - ARENA2_VIEW_MARGIN_TOP
	var view_bottom = floor_top + ARENA2_VIEW_MARGIN_BOTTOM
	var half_h = (view_bottom - view_top) * 0.5
	var vp = get_viewport_rect().size
	var z = clamp(vp.y * 0.5 / half_h, 0.8, camera.zoom.x)
	var zt = create_tween().set_parallel(true)
	zt.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	zt.tween_property(camera, "zoom", Vector2(z, z), 0.9)
	if "camera_offset" in camera:
		a["cam_offset"] = camera.camera_offset
		var center_y = (view_top + view_bottom) * 0.5
		var fish_floor_y = player.global_position.y
		zt.tween_property(camera, "camera_offset", Vector2(camera.camera_offset.x, center_y - fish_floor_y), 0.9)

func _setup_arena_enemy(e: Node, a: Dictionary):
	if "max_hp" in e:
		e.max_hp = ARENA_ENEMY_HP
	if "hp" in e:
		e.hp = ARENA_ENEMY_HP
	# спокойнее, чем на складе
	for k in ["run_speed", "quad_speed", "speed"]:
		if k in e:
			e.set(k, e.get(k) * ARENA_SPEED_MULT)
	if "quad_cooldown" in e:
		e.quad_cooldown = 4.0
	if e.has_method("hear_alert"):
		e.hear_alert(player)
	a["enemies"].append(e)

## Следующий враг: сначала красная метка на полу, через ARENA_DROP_WARN он спрыгивает
## и ещё секунду приходит в себя.
func _arena_spawn_next(a: Dictionary):
	if a["queue"].is_empty() or not is_inside_tree():
		return
	var spots: Array = a["spots"]
	var x = clamp(spots[min(a["spawn_i"], spots.size() - 1)], a["left"] + 40.0, a["right"] - 40.0)
	a["spawn_i"] += 1
	var scene: PackedScene = a["queue"].pop_front()
	var floor_top = _floor_top_y()
	if is_nan(floor_top):
		floor_top = player.global_position.y + 28.0
	a["pending"] += 1
	var marker = _drop_marker(Vector2(x, floor_top))
	await get_tree().create_timer(ARENA_DROP_WARN).timeout
	if is_instance_valid(marker):
		marker.queue_free()
	if not is_inside_tree() or a["state"] != Arena.FIGHT:
		a["pending"] -= 1
		return
	var e = scene.instantiate()
	_arena_node.add_child(e)
	e.global_position = Vector2(x, floor_top - 150.0)
	if "patrol_range" in e:
		e.patrol_range = 60.0
	_setup_arena_enemy(e, a)
	if e.has_method("stun"):
		e.stun(ARENA_LANDING_STUN)
	a["pending"] -= 1
	_spawn_sparks(Vector2(x, floor_top), Color(0.7, 0.68, 0.65, 0.9), 10)
	_update_arena_counter(a)

func _drop_marker(at: Vector2) -> Node2D:
	var m = Node2D.new()
	m.z_index = 55
	add_child(m)
	m.global_position = at
	var bar = ColorRect.new()
	bar.color = Color(1, 0.2, 0.15, 0.8)
	bar.position = Vector2(-20, -3)
	bar.size = Vector2(40, 3)
	m.add_child(bar)
	var arrow = Polygon2D.new()
	arrow.color = Color(1, 0.25, 0.2, 0.95)
	arrow.polygon = PackedVector2Array([Vector2(-7, -30), Vector2(7, -30), Vector2(0, -20)])
	m.add_child(arrow)
	var t = create_tween().set_loops()
	t.bind_node(m)
	t.tween_property(m, "modulate:a", 0.35, 0.12)
	t.tween_property(m, "modulate:a", 1.0, 0.12)
	return m

func _arena_spawn_balcony_sniper(a: Dictionary):
	var e = ARENA_PIGEON.instantiate()
	e.set_meta("arena_sniper", true)
	_arena_node.add_child(e)
	e.global_position = Vector2(_balcony_rect.get_center().x + 50.0, _balcony_rect.position.y - 60.0)
	# голубь стоит на балконе: края балкона — невидимые бортики только для него
	e.collision_mask |= 16
	if "patrol_range" in e:
		e.patrol_range = 30.0
	if "pistol_keep_min" in e:
		e.pistol_keep_min = 0.0       # не пытается отходить — некуда
	# обычный складской голубь: урон, прицел, HP и скорость — как в его сцене
	if e.has_method("hear_alert"):
		e.hear_alert(player)
	# его не убить: удары рыбы ищут цели в группе "enemies" — голубя там нет,
	# и паллетом в него тоже не целимся. Уйдёт сам после звонка.
	if e.is_in_group("enemies"):
		e.remove_from_group("enemies")
	a["enemies"].append(e)
	_spawn_sparks(e.global_position, Color(0.6, 0.85, 1.0, 0.9), 8)

## Трое на полу убиты — голубю звонят. Он перестаёт стрелять, бубнит в трубку
## (диалоговое окно из ChatterScenes) и уходит «в дверь» в глубине балкона. Потом зона открыта.
var _call_cam_on: bool = false
var _call_start_zoom: Vector2 = Vector2.ONE

func _sniper_phone_call(a: Dictionary, e: Node) -> void:
	_sniper_stand_down(e)
	await _call_cam_begin(e)
	if not is_inside_tree():
		return
	# звонок: «дзынь» над головой, голубь подрагивает
	var ring = _ring_label(e)
	var t_ring := 0.0
	while t_ring < SNIPER_RING_TIME:
		await get_tree().process_frame
		if not is_inside_tree() or not is_instance_valid(e):
			_finish_sniper_leave(a, ring)
			return
		var d = get_process_delta_time()
		t_ring += d
		if is_instance_valid(ring):
			ring.global_position = e.global_position + Vector2(-ring.size.x * 0.5 + randf_range(-1.5, 1.5), -62.0 + randf_range(-1.0, 1.0))
		if e.sprite:
			e.sprite.position.x = randf_range(-0.8, 0.8) if fmod(t_ring, 0.5) < 0.3 else 0.0
	if is_instance_valid(ring):
		ring.queue_free()
	if e.sprite:
		e.sprite.position.x = 0.0

	# бубнит себе под нос
	var chatter = CHATTER_SCENE.instantiate()
	chatter.name = "SniperCallChatter"
	var lines: Array[ChatterLine] = []
	for txt in SNIPER_CALL_LINES:
		var l = ChatterLine.new()
		l.speaker = ChatterLine.Speaker.SCIENTIST
		l.text = txt
		l.display_time = 1.1
		lines.append(l)
	chatter.lines = lines
	chatter.loop = false
	chatter.typing_speed = 0.035
	chatter.scientist_node = (e.sprite if e.sprite else e).get_path()
	add_child(chatter)
	# окно диалога считает позиции в мировых координатах, а корень уровня сдвинут по Y
	if chatter is Node2D:
		chatter.global_position = Vector2.ZERO
	var box = chatter.find_child("ChatterBox", true, false)
	if box:
		if "force_near" in box:
			box.force_near = true
		if "bubble_scale" in box:
			box.bubble_scale = 0.85
	chatter.start()
	var tmax := 14.0
	while chatter.is_active() and tmax > 0.0:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		tmax -= get_process_delta_time()
		if not is_instance_valid(e):
			break
	chatter.stop()
	chatter.queue_free()
	if not is_instance_valid(e):
		_finish_sniper_leave(a, null)
		return

	await _sniper_exit_through_door(e)
	_finish_sniper_leave(a, null)

func _finish_sniper_leave(a: Dictionary, ring: Node) -> void:
	if ring and is_instance_valid(ring):
		ring.queue_free()
	await _call_cam_end()
	if not is_inside_tree():
		return
	if a["state"] == Arena.FIGHT:
		_clear_arena(a)

## Мини-катсцена звонка: полосы, рыба стоит, камера берёт в кадр рыбу, голубя и «дверь».
func _call_cam_begin(e: Node) -> void:
	# сначала даём рыбе приземлиться, если она в прыжке
	var tw := 0.0
	while not player.is_on_floor() and tw < 1.5:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		tw += get_process_delta_time()
	_lock_player_input(true)
	if player.sprite:
		player.sprite.play("Idle")
	if not camera:
		return
	_call_cam_on = true
	_call_start_zoom = camera.zoom
	var from = _get_camera_target()
	_disable_camera_for_cutscene()
	camera.global_position = from
	camera.reset_smoothing()
	_show_cutscene_bars(0.6)
	# камера поднимается к голубю на балкон (как в катсцене со снайпером в начале):
	# полосы большие, рыба и балкон в один кадр не помещаются
	var left = min(e.global_position.x - 110.0, _balcony_rect.position.x)
	var right = _balcony_rect.end.x + 40.0
	var top = _balcony_rect.position.y - 80.0
	var bottom = _balcony_rect.position.y + 50.0
	var vp = get_viewport_rect().size
	var usable_h = vp.y - CUTSCENE_BARS_HEIGHT * 2.0 - 16.0
	var z = min(vp.x * 0.9 / max(right - left, 1.0), usable_h / max(bottom - top, 1.0))
	z = clamp(z, 1.2, 2.3)
	var center = Vector2((left + right) * 0.5, (top + bottom) * 0.5)
	_cam_tween(center, Vector2(z, z), 0.9)
	await _wait(0.9)

func _call_cam_end() -> void:
	if not _call_cam_on:
		if _input_locked and state == State.RUNNING:
			_lock_player_input(false)
		return
	_call_cam_on = false
	if "look_offset" in camera:
		camera.look_offset = Vector2.ZERO
	_cam_tween(_get_camera_target(), _call_start_zoom, 0.8)
	_hide_cutscene_bars(0.7)
	await _wait(0.8)
	if not is_inside_tree():
		return
	_cam_original_position = _get_camera_target()
	_cam_original_zoom = _call_start_zoom
	_cam_original_offset = _cam_base_offset
	_restore_camera_after_cutscene()
	_lock_player_input(false)

## Голубь больше не воюет: лазер и пули убраны, его не задеть.
func _sniper_stand_down(e: Node) -> void:
	e.set_physics_process(false)
	if e.has_method("_hide_aim"):
		e._hide_aim()
	if "_bullets" in e:
		for b in e._bullets:
			if b is Dictionary and b.has("node") and is_instance_valid(b["node"]):
				b["node"].queue_free()
		e._bullets.clear()
	e.velocity = Vector2.ZERO
	if e.is_in_group("enemies"):
		e.remove_from_group("enemies")
	e.collision_layer = 0
	# замирает с «трубкой» у головы
	if e.sprite:
		if e.sprite.sprite_frames and e.sprite.sprite_frames.has_animation("idle_aim"):
			e.sprite.play("idle_aim")
			e.sprite.pause()

func _ring_label(e: Node) -> Label:
	var l = Label.new()
	l.text = "♪ дзынь-дзынь ♪"
	l.z_index = 60
	if ResourceLoader.exists(HINT_FONT_PATH):
		l.add_theme_font_override("font", load(HINT_FONT_PATH))
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.07))
	l.add_theme_constant_override("outline_size", 4)
	add_child(l)
	l.reset_size()
	l.global_position = e.global_position + Vector2(-l.size.x * 0.5, -62.0)
	var t = create_tween().set_loops(4)
	t.bind_node(l)
	t.tween_property(l, "modulate:a", 0.35, 0.18)
	t.tween_property(l, "modulate:a", 1.0, 0.18)
	return l

## «Дверь» без спрайтов: в глубине балкона приоткрывается полоска света, голубь уходит
## в неё, темнеет и пропадает, полоска схлопывается.
func _sniper_exit_through_door(e: Node) -> void:
	var door_x = _balcony_rect.end.x - 26.0
	var floor_y = _balcony_rect.position.y
	var door = Node2D.new()
	door.z_index = 2   # за перилами балкона (у них 3), но перед стеной
	add_child(door)
	door.global_position = Vector2(door_x, floor_y)
	var frame = ColorRect.new()
	frame.color = Color(0.03, 0.03, 0.05, 0.95)
	frame.size = Vector2(0, 48)
	frame.position = Vector2(0, -48)
	door.add_child(frame)
	var glow = ColorRect.new()
	glow.color = Color(1.0, 0.78, 0.45, 0.55)
	glow.size = Vector2(0, 46)
	glow.position = Vector2(0, -47)
	door.add_child(glow)
	var open = create_tween().set_parallel(true)
	open.tween_property(frame, "size:x", 24.0, 0.35)
	open.tween_property(frame, "position:x", -12.0, 0.35)
	open.tween_property(glow, "size:x", 18.0, 0.35)
	open.tween_property(glow, "position:x", -9.0, 0.35)
	await open.finished
	if not is_instance_valid(e):
		door.queue_free()
		return

	if e.sprite:
		e.sprite.scale.x = abs(e.sprite.scale.x) * (-1.0 if door_x < e.global_position.x else 1.0)
		if e.sprite.sprite_frames and e.sprite.sprite_frames.has_animation("run_fast"):
			e.sprite.play("run_fast")
	var dist = abs(door_x - e.global_position.x)
	var walk = create_tween()
	walk.tween_property(e, "global_position:x", door_x, clamp(dist / 110.0, 0.3, 2.5))
	await walk.finished
	if not is_instance_valid(e):
		door.queue_free()
		return
	var fade = create_tween()
	fade.tween_property(e, "modulate", Color(0.15, 0.15, 0.2, 0.0), 0.45)
	await fade.finished
	if is_instance_valid(e):
		e.queue_free()
	var close = create_tween().set_parallel(true)
	close.tween_property(glow, "size:x", 0.0, 0.25)
	close.tween_property(glow, "position:x", 0.0, 0.25)
	close.tween_property(frame, "size:x", 0.0, 0.3)
	close.tween_property(frame, "position:x", 0.0, 0.3)
	await close.finished
	door.queue_free()

func _update_arena(a: Dictionary, delta: float):
	if a["items"] and not a["sniper_leaving"]:
		_update_items(a, delta)
	# передышка: рыбу ударили — все враги зоны отходят на секунду-другую
	if "hp" in player:
		if a["last_hp"] >= 0 and player.hp < a["last_hp"]:
			for e in a["enemies"]:
				if is_instance_valid(e) and not e.get("is_dead") and not e.has_meta("arena_sniper"):
					if "cooldown" in e:
						e.cooldown = max(e.cooldown, ARENA_HIT_BREATHER)
					if "quad_cooldown" in e:
						e.quad_cooldown = max(e.quad_cooldown, ARENA_HIT_BREATHER * 2.0)
		a["last_hp"] = player.hp
	if a["intro_t"] > 0.0:
		a["intro_t"] -= delta
		if a["intro_t"] <= 0.0:
			_arena_spawn_next(a)
			a["next_timer"] = ARENA_SPAWN_GAP
		return
	var alive_ground: int = a["pending"]
	var ground_spawned := 0
	var pigeon: Node = null
	for e in a["enemies"]:
		var is_sniper = is_instance_valid(e) and e.has_meta("arena_sniper")
		if is_sniper:
			if not e.get("is_dead"):
				pigeon = e
			continue
		ground_spawned += 1
		if is_instance_valid(e) and not e.get("is_dead"):
			alive_ground += 1
	a["killed"] = ground_spawned - (alive_ground - a["pending"])
	_update_arena_counter(a)
	if a["sniper_leaving"]:
		return

	if not a["queue"].is_empty():
		a["next_timer"] -= delta
		if alive_ground == 0 or (a["next_timer"] <= 0.0 and alive_ground < a["max_alive"]):
			_arena_spawn_next(a)
			a["next_timer"] = ARENA_SPAWN_GAP
		return

	if alive_ground == 0 and a["pending"] == 0 and ground_spawned > 0:
		if pigeon:
			a["sniper_leaving"] = true
			_sniper_phone_call(a, pigeon)
		else:
			_clear_arena(a)

func _clear_arena(a: Dictionary):
	a["state"] = Arena.CLEARED
	if a["items"]:
		_stop_items()
	if a["block_climb"] and "barriers_node" in player and a["saved_barriers"]:
		player.barriers_node = a["saved_barriers"]
	if player.has_method("set_hp") and "hp" in player:
		player.set_hp(player.hp + ARENA_HEAL)
	_flash(Color(0.6, 1.0, 0.6, 0.12), 0.4)
	if a["wall"] and is_instance_valid(a["wall"]):
		a["wall"].queue_free()
	var gate = a["gate"]
	if gate and is_instance_valid(gate):
		var t = create_tween()
		for i in 3:
			t.tween_property(gate, "modulate:a", 0.15, 0.06)
			t.tween_property(gate, "modulate:a", 1.0, 0.06)
		t.tween_property(gate, "modulate:a", 0.0, 0.2)
		t.tween_callback(gate.queue_free)
	if a["zoom"] != Vector2.ZERO and camera:
		var zt = create_tween().set_parallel(true)
		zt.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		zt.tween_property(camera, "zoom", a["zoom"], 1.0)
		if "camera_offset" in camera and a.has("cam_offset"):
			zt.tween_property(camera, "camera_offset", a["cam_offset"], 1.0)
	if _arena_counter:
		_arena_counter.text = "ПУТЬ СВОБОДЕН"
		_arena_counter.reset_size()
		_center_counter()
		var t2 = create_tween()
		t2.tween_interval(1.4)
		t2.tween_property(_arena_counter, "modulate:a", 0.0, 0.4)
	# снайпер коридора снова на позиции, пока рыба не ушла дальше
	if sniper and is_instance_valid(sniper) and player.global_position.x < escape_sniper_x:
		sniper.set_process(true)
		if sniper.has_method("activate"):
			sniper.activate()
		sniper_active = true

## Лазерные ворота на правой границе зоны. Первая зона — над Obstacle3 (дальше не залезть,
## лазание выключено), вторая — на полу + невидимая стена.
func _make_arena_gate(a: Dictionary):
	var gx: float = a["right"]
	var bottom = _floor_top_y()
	if is_nan(bottom):
		bottom = player.global_position.y + 28.0
	var height := 200.0
	var beams := 4
	var span := 40.0
	if a["id"] == "arena1":
		var o3 = get_node_or_null("Barriers/Obstacle3")
		if o3:
			var r = _node_rect(o3)
			gx = r.get_center().x
			bottom = r.position.y
			height = 170.0
			beams = 3
			span = r.size.x - 20.0
	var gate = Node2D.new()
	gate.z_index = 50
	add_child(gate)
	for i in beams:
		var x = gx - span * 0.5 + i * span / float(beams - 1)
		var l = Line2D.new()
		l.width = 2.0
		l.default_color = Color(1, 0.2, 0.15, 0.85)
		l.points = PackedVector2Array([to_local(Vector2(x, bottom - height)), to_local(Vector2(x, bottom))])
		gate.add_child(l)
		var cap = ColorRect.new()
		cap.color = Color(0.12, 0.12, 0.14)
		cap.size = Vector2(8, 5)
		cap.position = to_local(Vector2(x - 4, bottom - height - 4.0))
		gate.add_child(cap)
	var pulse = create_tween().set_loops()
	pulse.bind_node(gate)
	pulse.tween_property(gate, "modulate:a", 0.6, 0.25)
	pulse.tween_property(gate, "modulate:a", 1.0, 0.25)
	a["gate"] = gate
	if a["id"] != "arena1":
		var wall = StaticBody2D.new()
		var cs = CollisionShape2D.new()
		var rs = RectangleShape2D.new()
		rs.size = Vector2(16, 420)
		cs.shape = rs
		wall.add_child(cs)
		add_child(wall)
		wall.global_position = Vector2(gx, bottom - 210.0)
		a["wall"] = wall

## Балкон второго этажа: платформа (в Barriers — на неё можно залезть по E), опоры, перила.
func _build_balcony(cx: float):
	var floor_top = _floor_top_y()
	if is_nan(floor_top):
		return
	var barriers = get_node_or_null("Barriers")
	if barriers == null:
		return
	var thick := 12.0
	var top = min(_tiles_top_y() - BALCONY_ABOVE_TILES, floor_top - 100.0)
	_balcony_h = floor_top - top
	_balcony_rect = Rect2(Vector2(cx - BALCONY_WIDTH * 0.5, top), Vector2(BALCONY_WIDTH, thick))

	_balcony = StaticBody2D.new()
	_balcony.name = "Balcony2F"
	barriers.add_child(_balcony)
	_balcony.global_position = _balcony_rect.get_center()
	var cs = CollisionShape2D.new()
	var rs = RectangleShape2D.new()
	rs.size = _balcony_rect.size
	cs.shape = rs
	_balcony.add_child(cs)

	# вид: металлический настил, полоса опасности, опоры до пола и перила
	var vis = Node2D.new()
	vis.z_index = 3
	_balcony.add_child(vis)
	var w = BALCONY_WIDTH
	var deck = ColorRect.new()
	deck.color = Color(0.26, 0.27, 0.31)
	deck.position = Vector2(-w * 0.5, -thick * 0.5)
	deck.size = Vector2(w, thick)
	vis.add_child(deck)
	var lip = ColorRect.new()
	lip.color = Color(0.55, 0.57, 0.62)
	lip.position = Vector2(-w * 0.5, -thick * 0.5)
	lip.size = Vector2(w, 2)
	vis.add_child(lip)
	var n_stripes = int(w / 16.0)
	for i in n_stripes:
		var st = ColorRect.new()
		st.color = Color(0.85, 0.62, 0.12) if i % 2 == 0 else Color(0.08, 0.08, 0.09)
		st.position = Vector2(-w * 0.5 + i * 16.0, thick * 0.5 - 4.0)
		st.size = Vector2(16, 3)
		vis.add_child(st)
	for sx in [-w * 0.5 + 8.0, w * 0.5 - 14.0]:
		var post = ColorRect.new()
		post.color = Color(0.2, 0.21, 0.24)
		post.position = Vector2(sx, thick * 0.5)
		post.size = Vector2(6, _balcony_h - thick)
		vis.add_child(post)
	var rail_h := 22.0
	var rail = Line2D.new()
	rail.width = 2.0
	rail.default_color = Color(0.6, 0.62, 0.68)
	rail.points = PackedVector2Array([Vector2(-w * 0.5 + 2, -thick * 0.5), Vector2(-w * 0.5 + 2, -thick * 0.5 - rail_h),
		Vector2(w * 0.5 - 2, -thick * 0.5 - rail_h), Vector2(w * 0.5 - 2, -thick * 0.5)])
	vis.add_child(rail)
	var x = -w * 0.5 + 20.0
	while x < w * 0.5 - 10.0:
		var bar = Line2D.new()
		bar.width = 1.0
		bar.default_color = Color(0.45, 0.47, 0.52)
		bar.points = PackedVector2Array([Vector2(x, -thick * 0.5), Vector2(x, -thick * 0.5 - rail_h)])
		vis.add_child(bar)
		x += 18.0

	# бортики по краям — только для голубя (слой 16, рыба его не видит),
	# не внутри Barriers, чтобы рыба не пыталась на них лазить
	for ex in [_balcony_rect.position.x - 4.0, _balcony_rect.end.x + 4.0]:
		var edge = StaticBody2D.new()
		edge.collision_layer = 16
		edge.collision_mask = 0
		var ecs = CollisionShape2D.new()
		var ers = RectangleShape2D.new()
		ers.size = Vector2(8, 80)
		ecs.shape = ers
		edge.add_child(ecs)
		add_child(edge)
		edge.global_position = Vector2(ex, top - 40.0)

## Верхний край самого высокого тайла во всех TileMapLayer уровня (глобальная Y).
func _tiles_top_y() -> float:
	var best := INF
	for n in get_children():
		if n is TileMapLayer and n.visible:
			var half = Vector2(n.tile_set.tile_size) * 0.5 if n.tile_set else Vector2(8, 8)
			for c in n.get_used_cells():
				var y = n.to_global(n.map_to_local(c) - half).y
				if y < best:
					best = y
	return best

func _make_arena_counter():
	if _arena_counter_layer == null:
		_arena_counter_layer = CanvasLayer.new()
		_arena_counter_layer.layer = 25
		add_child(_arena_counter_layer)
		_arena_counter = _make_world_hint("")
		_arena_counter.get_parent().remove_child(_arena_counter)
		_arena_counter_layer.add_child(_arena_counter)
		_arena_counter.add_theme_font_size_override("font_size", 13)
	_arena_counter.modulate.a = 1.0

func _update_arena_counter(a: Dictionary):
	if _arena_counter == null or a["state"] != Arena.FIGHT:
		return
	var txt = "ВРАГИ  %d / %d" % [a["killed"], a["total"]]
	if _arena_counter.text != txt:
		_arena_counter.text = txt
		_arena_counter.reset_size()
	_center_counter()

func _center_counter():
	var vp = get_viewport_rect().size
	_arena_counter.position = Vector2(round((vp.x - _arena_counter.size.x) * 0.5), 18.0)

# ---------- предметы: взять / бросить ----------

func _start_items(a: Dictionary):
	_item_arena = a
	_items.clear()
	var floor_top = _floor_top_y()
	if is_nan(floor_top):
		return
	var xs = [a["left"] + 160.0, a["left"] + 360.0, a["right"] - 170.0]
	for x in xs:
		var en = {"node": null, "spot": Vector2(x, floor_top - 9.25), "respawn": 0.0}
		_items.append(en)
		_spawn_item(en)

func _spawn_item(en: Dictionary):
	var it = ITEM_SCENE.instantiate()
	if it is RigidBody2D:
		it.freeze = true
	if it is CollisionObject2D:
		it.collision_layer = 0
		it.collision_mask = 0
	add_child(it)
	it.global_position = en["spot"] - Vector2(24, 6)
	en["node"] = it
	it.scale = Vector2(0.2, 0.2)
	var t = create_tween()
	t.tween_property(it, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _item_texture(it: Node) -> Texture2D:
	var spr = it.get_node_or_null("Sprite2D")
	return spr.texture if spr else null

func _update_items(_a: Dictionary, delta: float):
	for en in _items:
		if en["node"] == null:
			en["respawn"] -= delta
			if en["respawn"] <= 0.0:
				_spawn_item(en)
	var holding: bool = player.has_item
	var near = null
	if not holding and player.is_on_floor():
		var best = ITEM_PICK_RADIUS
		for en in _items:
			if en["node"] and is_instance_valid(en["node"]):
				var d = (player.global_position + Vector2(0, 20)).distance_to(en["spot"])
				if d < best:
					best = d
					near = en
	# рядом с паллетом или с паллетом в руках E — это «взять/бросить», а не «залезть»
	if "barriers_node" in player:
		player.barriers_node = null if (near != null or holding) else _player_barriers
	_set_item_hint(near != null or holding, tr("E — бросить") if holding else tr("E — взять"))
	if Input.is_action_just_pressed("interact") and not player.is_dead and not player.movement_blocked:
		if holding:
			_throw_item()
		elif near != null:
			_pick_item(near)

func _pick_item(en: Dictionary):
	var it = en["node"]
	_held_item_tex = _item_texture(it)
	it.queue_free()
	en["node"] = null
	en["respawn"] = ITEM_RESPAWN_TIME
	player.has_item = true
	if player.held_icon:
		player.held_icon.texture = _held_item_tex
		player.held_icon.visible = true

func _throw_target(dir: int) -> Node2D:
	var best: Node2D = null
	var best_d := ITEM_THROW_RANGE
	var fallback: Node2D = null
	var fb_d := ITEM_THROW_RANGE
	for e in _item_arena.get("enemies", []):
		if not is_instance_valid(e) or e.get("is_dead") or e.has_meta("arena_sniper"):
			continue
		var d = player.global_position.distance_to(e.global_position)
		if (e.global_position.x - player.global_position.x) * dir > -10.0:
			if d < best_d:
				best_d = d
				best = e
		elif d < fb_d:
			fb_d = d
			fallback = e
	return best if best else fallback

func _throw_item():
	player.has_item = false
	if player.held_icon:
		player.held_icon.visible = false
	_thrown_once = true
	var dir: int = 1 if player.facing_direction >= 0 else -1
	var from = player.global_position + Vector2(dir * 10.0, -40.0)
	var target = _throw_target(dir)
	var to = target.global_position + Vector2(0, -12) if target else from + Vector2(dir * 340.0, 60.0)
	var proj = Sprite2D.new()
	proj.texture = _held_item_tex
	proj.z_index = 60
	add_child(proj)
	proj.global_position = from
	var dist = from.distance_to(to)
	var dur = clamp(dist / ITEM_THROW_SPEED, 0.18, 0.7)
	var lift = min(80.0, dist * 0.25)
	var t = create_tween()
	# самонаведение: летит дугой в ТЕКУЩУЮ позицию цели, даже если та сместилась
	t.tween_method(_proj_move.bind(proj, from, lift, target, to), 0.0, 1.0, dur)
	t.parallel().tween_property(proj, "rotation", dir * TAU * 1.5, dur)
	await t.finished
	if not is_inside_tree():
		return
	var hit_pos = proj.global_position
	proj.queue_free()
	_spawn_sparks(hit_pos, Color(0.62, 0.45, 0.28, 0.95), 14)
	if target and is_instance_valid(target) and not target.get("is_dead"):
		if target.has_method("stun"):
			target.stun(ITEM_STUN_TIME)
		# видно, что оглушён: останавливается, играет «удар», отдаёт очередь на атаку
		if "velocity" in target:
			target.velocity.x = 0.0
		if target.has_method("_release_token"):
			target._release_token()
		if target.has_method("_play"):
			target._play("hit", true)
		_stun_stars(target, ITEM_STUN_TIME)
		_add_shake(0.2)

func _proj_move(k: float, proj: Sprite2D, a: Vector2, lift: float, target, fallback: Vector2) -> void:
	if not is_instance_valid(proj):
		return
	var c = fallback
	if target and is_instance_valid(target):
		c = target.global_position + Vector2(0, -12)
	var b = (a + c) * 0.5 + Vector2(0, -lift)
	proj.global_position = a.lerp(b, k).lerp(b.lerp(c, k), k)

## Звёздочки над оглушённым врагом
func _stun_stars(e: Node2D, time: float):
	var holder = Node2D.new()
	holder.z_index = 70
	holder.position = Vector2(0, -52)
	e.add_child(holder)
	for i in 3:
		var star = Polygon2D.new()
		star.color = Color(1.0, 0.9, 0.3)
		star.polygon = PackedVector2Array([Vector2(0, -3), Vector2(1, -1), Vector2(3, 0), Vector2(1, 1), Vector2(0, 3), Vector2(-1, 1), Vector2(-3, 0), Vector2(-1, -1)])
		star.position = Vector2(14, 0).rotated(TAU * i / 3.0)
		holder.add_child(star)
	var spin = create_tween().set_loops()
	spin.bind_node(holder)
	spin.tween_property(holder, "rotation", TAU, 0.6).from(0.0)
	get_tree().create_timer(time).timeout.connect(func():
		if is_instance_valid(holder):
			holder.queue_free())

func _set_item_hint(on: bool, text: String):
	if _item_hint == null:
		if not on:
			return
		_item_hint = _make_world_hint(text)
	if _item_hint.text != text:
		_item_hint.text = text
		_item_hint.reset_size()
	if on:
		_item_hint.position = to_local(player.global_position + Vector2(-_item_hint.size.x * 0.5, -86))
	_item_hint.modulate.a = move_toward(_item_hint.modulate.a, 1.0 if on else 0.0, 0.15)

func _stop_items():
	for en in _items:
		if en["node"] and is_instance_valid(en["node"]):
			en["node"].queue_free()
	_items.clear()
	if player.has_item:
		player.has_item = false
		if player.held_icon:
			player.held_icon.visible = false
	if "barriers_node" in player:
		player.barriers_node = _player_barriers
	_set_item_hint(false, "")
	if _item_hint:
		_item_hint.modulate.a = 0.0
