extends Node2D

# ==============================
# КОНСТАНТЫ
# ==============================
const TOTAL_OBJECTS: int = 10
const NUM_NPC_FISHES: int = 4
const AUTO_OBJECTS: int = 3

const CONVEYOR_Y: float = 386.0
const FISH_START_X: float = 285.0
const FISH_SPACING: float = 125.0
const PLAYER_TURN_X: float = 156.0
const OBJECT_SPAWN_X: float = 1850.0
const OBJECT_DESPAWN_X: float = -700.0

const OBJECT_SPEED: float = 150.0
const NPC_WALK_SPEED: float = 240.0

const SHIFT_START_HOUR: float = 8.0
const SHIFT_END_HOUR: float = 18.0
const SHIFT_DURATION_HOURS: float = 10.0
const REAL_SHIFT_DURATION: float = 180.0

const GUARD_SHIFTS: Array = [9.0, 13.0, 17.0]
const SNIPER_SHIFTS: Array = [11.0, 13.0, 15.0]

const COLOR_GREEN := Color(0.2, 0.8, 0.3)
const COLOR_RED := Color(0.9, 0.2, 0.2)
const COLOR_YELLOW := Color(1, 0.9, 0.3)
const COLOR_BLUE := Color(0.3, 0.5, 0.8)

const BOX_TEXTURE_PATH := "res://Fish Slaves/Textures/Tiles/Act2Tiles/Act2Box.png"
const ATTACK_ALL_PATH := "res://Fish Slaves/Textures/Characters/Player/PlayerMechaFish/PlayerMechaFishAttack/PlayerMechaFishAttack.png"
const JOGGING_PATH := "res://Fish Slaves/Textures/Characters/Player/PlayerMechaFish/PlayerMechaFishJogging/MechaFishJogging.png"
const ATTACK_FRAMES_PER_SIDE: int = 8
const JOGGING_FRAMES: int = 12

const PLAYER_ZONE_CENTER := Vector2(156.0, 351.0)
const PLAYER_ZONE_SIZE := Vector2(200.0, 100.0)

const ACT2_DISABLED_ACTIONS := ["crouch", "block", "Parry", "inventory"]

# ==============================
# ССЫЛКИ НА УЗЛЫ
# ==============================
@onready var player: CharacterBody2D = $Mecha_Fish
@onready var camera: Camera2D = $Mecha_Fish/MechaFishCamera
@onready var player_sprite: AnimatedSprite2D = $Mecha_Fish/AnimatedSprite2D
@onready var player_gui: CanvasLayer = $Mecha_Fish/GUI
@onready var objects_layer: Node2D = $Objects
@onready var npc_fishes: Array[Node] = [$NPCParent/Fish1, $NPCParent/Fish2, $NPCParent/Fish3, $NPCParent/Fish4]
@onready var guard_rect: ColorRect = $Guard
@onready var sniper_rect: ColorRect = $Sniper
@onready var elevator_door: ColorRect = $Elevator
@onready var guard_door: ColorRect = $GuardDoor

@onready var clock_label: Label = $UI/ClockLabel
@onready var dialog_panel: ColorRect = $UI/DialogPanel
@onready var dialog_label: Label = $UI/DialogPanel/DialogLabel
@onready var progress_bar: HBoxContainer = $UI/ProgressBar
@onready var hint_label: Label = $UI/HintLabel
@onready var escape_hint: Label = $UI/EscapeHint

@onready var fade_rect: ColorRect = $UI/FadeRect

@onready var bind_hint_i: Control = $UI/BindHintI
@onready var bind_hint_j: Control = $UI/BindHintJ

@onready var minigame_panel: Control = $UI/MinigamePanel
@onready var minigame_slider: ColorRect = $UI/MinigamePanel/Track/Slider
@onready var minigame_zone: ColorRect = $UI/MinigamePanel/Track/Zone

@onready var journal_panel: Control = $UI/JournalPanel
@onready var journal_list: VBoxContainer = $UI/JournalPanel/BG/Scroll/JournalList

@onready var inspect_overlay: Control = $UI/InspectOverlay
@onready var inspect_marker: ColorRect = $UI/InspectOverlay/Marker
@onready var inspect_zones: Node2D = $InspectZones

@onready var pausemenu: CanvasLayer = $Pausemenu

# ==============================
# СОСТОЯНИЕ
# ==============================
enum State { INTRO, WORKING, MINIGAME, SHIFT_END, INSPECT, DEAD }
var state: State = State.INTRO

var current_shift: int = 1
var shift_time: float = 0.0
var current_object: Node2D = null
var object_x: float = 0.0
var object_progress: int = 0
var conveyor_paused: bool = false
var current_object_index: int = 0

var finished_boxes: Array = []
var broken_boxes: Array = []

var correct_count: int = 0
var wrong_count: int = 0
var strike_count: int = 0

var slider_pos: float = 0.0
var slider_dir: float = 1.0
var minigame_active: bool = false
const TRACK_WIDTH: float = 400.0
var zone_center: float = 0.5
var zone_width: float = 0.2

var guard_talk_timer: float = 12.0
var intro_timer: float = 0.0

var is_dialog_active: bool = false
var journal_open: bool = false
var inspect_mode: bool = false

var guard_shifts_found: Array = []
var sniper_shifts_found: Array = []
var known_worker_count: bool = false
var known_box_count: bool = false
var known_elevator: bool = false

var visited_zones: Array = []
var selected_zone: String = ""

var guard_changing: bool = false
var sniper_changing: bool = false
var guard_last_checked_hour: float = -1.0
var sniper_last_checked_hour: float = -1.0

# Конвейер
var conveyor_sprites: Array = []
var conveyor_tile_width: float = 0.0
var conveyor_scroll_offset: float = 0.0
var conveyor_base_x: float = 0.0
var conveyor_floor_rect: ColorRect = null

# Пол
var floor_rect: ColorRect = null

# Зона работы
var work_zone_rect: ColorRect = null

# Подсветки мест смены
var zone_highlight_rects: Dictionary = {}

# Уход NPC
var shift_end_npc_timer: float = 0.0

# Режим осмотра
var inspect_camera_offset: Vector2 = Vector2.ZERO
var inspect_vignette: ColorRect = null
var inspect_camera_original_pos: Vector2 = Vector2.ZERO

# Камера охранника
var guard_camera: Camera2D = null

# Блокировка атаки
var attack_lock: bool = false

# ==============================
# READY
# ==============================
func _ready() -> void:
	randomize()
	
	_disable_actions_for_act2()
	
	if player:
		player.dash_cooldown = 999999.0
	
	for i in range(TOTAL_OBJECTS):
		var cell = ColorRect.new()
		cell.name = "Cell" + str(i)
		cell.color = Color(0.2, 0.2, 0.2)
		cell.custom_minimum_size = Vector2(28, 20)
		progress_bar.add_child(cell)
	
	_collect_conveyor_sprites()
	_create_conveyor_floor()
	_create_floor_rect()
	_create_work_zone()
	_create_shift_zone_highlights()
	_create_vignette()
	_setup_npc_animations()
	_setup_guard_camera()
	
	bind_hint_i.visible = false
	bind_hint_j.visible = false
	escape_hint.visible = false
	journal_panel.visible = false
	inspect_overlay.visible = false
	minigame_panel.visible = false
	hint_label.visible = false
	dialog_panel.visible = false
	inspect_marker.visible = false
	fade_rect.visible = false
	fade_rect.color = Color(0, 0, 0, 0)
	pausemenu.visible = false
	
	if player_gui:
		player_gui.visible = false
	
	await get_tree().process_frame
	
	if player and player.has_method("set_movement_blocked"):
		player.set_movement_blocked(true)
	
	if camera:
		camera.enabled = true
		camera.top_level = true
		camera.global_position = player.global_position
	
	if player_sprite and player_sprite.sprite_frames.has_animation("Idle"):
		player_sprite.play("Idle")
	
	intro_timer = 0.0
	state = State.INTRO

func _disable_actions_for_act2() -> void:
	for action in ACT2_DISABLED_ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)

func _restore_actions_on_exit() -> void:
	var defaults := {
		"crouch": KEY_CTRL,
		"block": KEY_Q,
		"inventory": KEY_TAB,
	}
	for action in defaults.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var ev = InputEventKey.new()
		ev.keycode = defaults[action]
		InputMap.action_add_event(action, ev)
	if not InputMap.has_action("Parry"):
		InputMap.add_action("Parry")
	var mouse_ev = InputEventMouseButton.new()
	mouse_ev.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("Parry", mouse_ev)

func _exit_tree() -> void:
	_restore_actions_on_exit()

func _collect_conveyor_sprites() -> void:
	for child in get_children():
		if child is Sprite2D and child.name.begins_with("ConveyorSprite"):
			conveyor_sprites.append(child)
	if conveyor_sprites.is_empty():
		return
	var s: Sprite2D = conveyor_sprites[0]
	if s.texture == null:
		return
	conveyor_tile_width = s.texture.get_width() * abs(s.scale.x)
	conveyor_sprites.sort_custom(func(a, b): return a.position.x < b.position.x)
	conveyor_base_x = conveyor_sprites[0].position.x

func _create_conveyor_floor() -> void:
	conveyor_floor_rect = ColorRect.new()
	conveyor_floor_rect.name = "ConveyorFloor"
	conveyor_floor_rect.color = Color(0.15, 0.15, 0.2, 1)
	conveyor_floor_rect.offset_left = -600.0
	conveyor_floor_rect.offset_top = 416.0
	conveyor_floor_rect.offset_right = 2000.0
	conveyor_floor_rect.offset_bottom = 446.0
	conveyor_floor_rect.z_index = -5
	conveyor_floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(conveyor_floor_rect)

func _create_floor_rect() -> void:
	floor_rect = ColorRect.new()
	floor_rect.name = "FloorRect"
	floor_rect.color = Color(0.3, 0.18, 0.12, 1)
	floor_rect.offset_left = -600.0
	floor_rect.offset_top = 380.0
	floor_rect.offset_right = 2000.0
	floor_rect.offset_bottom = 420.0
	floor_rect.z_index = -4
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_rect)

func _create_work_zone() -> void:
	work_zone_rect = ColorRect.new()
	work_zone_rect.name = "WorkZone"
	work_zone_rect.color = Color(0.2, 0.8, 0.3, 0.15)
	work_zone_rect.offset_left = PLAYER_ZONE_CENTER.x - PLAYER_ZONE_SIZE.x / 2.0
	work_zone_rect.offset_top = PLAYER_ZONE_CENTER.y - PLAYER_ZONE_SIZE.y / 2.0
	work_zone_rect.offset_right = PLAYER_ZONE_CENTER.x + PLAYER_ZONE_SIZE.x / 2.0
	work_zone_rect.offset_bottom = PLAYER_ZONE_CENTER.y + PLAYER_ZONE_SIZE.y / 2.0
	work_zone_rect.z_index = -1
	work_zone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(work_zone_rect)

func _create_shift_zone_highlights() -> void:
	_add_zone_highlight("clock", Vector2(576, 80), Vector2(120, 60))
	_add_zone_highlight("elevator", Vector2(1230, 325), Vector2(100, 120))
	_add_zone_highlight("guard_door", Vector2(-290, 325), Vector2(100, 120))
	_add_zone_highlight("sniper", Vector2(1060, 60), Vector2(120, 80))
	_add_zone_highlight("conveyor", Vector2(400, 400), Vector2(200, 60))

func _add_zone_highlight(id: String, center: Vector2, size: Vector2) -> void:
	var rect = ColorRect.new()
	rect.name = "Highlight_" + id
	rect.color = Color(0.3, 0.6, 1.0, 0.18)
	rect.offset_left = center.x - size.x / 2.0
	rect.offset_top = center.y - size.y / 2.0
	rect.offset_right = center.x + size.x / 2.0
	rect.offset_bottom = center.y + size.y / 2.0
	rect.z_index = -1
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = true
	add_child(rect)
	zone_highlight_rects[id] = rect

func _create_vignette() -> void:
	inspect_vignette = ColorRect.new()
	inspect_vignette.name = "InspectVignette"
	inspect_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	inspect_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspect_vignette.z_index = 50
	inspect_vignette.visible = false
	
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV;
	vec2 dist = abs(uv - 0.5) * 2.0;
	float d = max(dist.x, dist.y);
	float v = smoothstep(0.4, 1.0, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * 0.75);
}
"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	inspect_vignette.material = mat
	
	var canvas = CanvasLayer.new()
	canvas.name = "InspectVignetteLayer"
	canvas.layer = 5
	canvas.add_child(inspect_vignette)
	add_child(canvas)

func _setup_npc_animations() -> void:
	var atk_tex = load(ATTACK_ALL_PATH)
	var jog_tex = load(JOGGING_PATH)
	
	for fish in npc_fishes:
		if fish == null or not fish is AnimatedSprite2D:
			continue
		var frames: SpriteFrames = fish.sprite_frames
		if frames == null:
			continue
		
		if atk_tex:
			_add_attack_frames_from_sheet(frames, "AttackLeft", atk_tex, ATTACK_FRAMES_PER_SIDE, ATTACK_FRAMES_PER_SIDE)
			_add_attack_frames_from_sheet(frames, "AttackRight", atk_tex, 0, ATTACK_FRAMES_PER_SIDE)
		
		if jog_tex:
			_add_jogging_frames(frames, "jogging", jog_tex)

func _add_attack_frames_from_sheet(frames: SpriteFrames, anim_name: String, tex: Texture2D, start_index: int, count: int) -> void:
	if frames.has_animation(anim_name):
		return
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, false)
	frames.set_animation_speed(anim_name, 14.0)
	
	var tex_h = tex.get_height()
	var total_frames = ATTACK_FRAMES_PER_SIDE * 2
	var frame_w = int(tex.get_width() / float(total_frames))
	
	for i in range(count):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2((start_index + i) * frame_w, 0, frame_w, tex_h)
		frames.add_frame(anim_name, atlas)

func _add_jogging_frames(frames: SpriteFrames, anim_name: String, tex: Texture2D) -> void:
	if frames.has_animation(anim_name):
		return
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, true)
	frames.set_animation_speed(anim_name, 12.0)
	
	var tex_h = tex.get_height()
	var frame_w = int(tex.get_width() / float(JOGGING_FRAMES))
	
	for i in range(JOGGING_FRAMES):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_w, 0, frame_w, tex_h)
		frames.add_frame(anim_name, atlas)

func _setup_guard_camera() -> void:
	guard_camera = Camera2D.new()
	guard_camera.name = "GuardCamera"
	guard_camera.enabled = false
	guard_camera.zoom = Vector2(2.5, 2.5)
	add_child(guard_camera)

func _is_player_in_zone() -> bool:
	if player == null:
		return false
	var pos = player.global_position
	var left = PLAYER_ZONE_CENTER.x - PLAYER_ZONE_SIZE.x / 2.0
	var right = PLAYER_ZONE_CENTER.x + PLAYER_ZONE_SIZE.x / 2.0
	var top = PLAYER_ZONE_CENTER.y - PLAYER_ZONE_SIZE.y / 2.0
	var bottom = PLAYER_ZONE_CENTER.y + PLAYER_ZONE_SIZE.y / 2.0
	return pos.x >= left and pos.x <= right and pos.y >= top and pos.y <= bottom

# ==============================
# PROCESS
# ==============================
func _process(delta: float) -> void:
	if state == State.DEAD:
		return
	if get_tree().paused:
		return
	
	_process_clock(delta)
	_process_shift_changes()
	
	if state != State.INSPECT:
		_process_conveyor_scroll(delta)
	
	_process_finished_boxes(delta)
	_process_broken_boxes(delta)
	_process_shift_end_npcs(delta)
	
	if state == State.INSPECT:
		_process_inspect_camera(delta)
	
	match state:
		State.INTRO:
			intro_timer += delta
			if intro_timer >= 0.5:
				state = State.WORKING
				_spawn_next_object()
		State.WORKING:
			_process_working(delta)
		State.MINIGAME:
			_process_minigame(delta)
		State.SHIFT_END:
			pass
		State.INSPECT:
			pass
	
	if not is_dialog_active and state != State.SHIFT_END and state != State.DEAD and state != State.INSPECT:
		_process_guard_talk(delta)

func _process_inspect_camera(delta: float) -> void:
	if camera == null:
		return
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	inspect_camera_offset += dir * 300 * delta
	inspect_camera_offset.x = clamp(inspect_camera_offset.x, -600, 600)
	inspect_camera_offset.y = clamp(inspect_camera_offset.y, -400, 400)
	camera.global_position = inspect_camera_original_pos + inspect_camera_offset

func _process_shift_end_npcs(delta: float) -> void:
	if state != State.SHIFT_END:
		return
	shift_end_npc_timer += delta
	for fish in npc_fishes:
		if fish:
			fish.position.x += NPC_WALK_SPEED * delta
			if fish is AnimatedSprite2D and fish.sprite_frames.has_animation("jogging"):
				if fish.animation != "jogging":
					fish.play("jogging")

func _process_finished_boxes(delta: float) -> void:
	var to_remove: Array = []
	for box in finished_boxes:
		if not is_instance_valid(box):
			to_remove.append(box)
			continue
		box.position.x -= OBJECT_SPEED * delta
		if box.position.x < OBJECT_DESPAWN_X:
			to_remove.append(box)
	for box in to_remove:
		finished_boxes.erase(box)
		if is_instance_valid(box):
			box.queue_free()

func _process_broken_boxes(delta: float) -> void:
	var to_remove: Array = []
	for box in broken_boxes:
		if not is_instance_valid(box):
			to_remove.append(box)
			continue
		box.position.x -= OBJECT_SPEED * delta
		if box.position.x < OBJECT_DESPAWN_X:
			to_remove.append(box)
	for box in to_remove:
		broken_boxes.erase(box)
		if is_instance_valid(box):
			box.queue_free()

func _process_conveyor_scroll(delta: float) -> void:
	if conveyor_paused:
		return
	if conveyor_tile_width <= 0.0 or conveyor_sprites.is_empty():
		return
	conveyor_scroll_offset += OBJECT_SPEED * delta
	if conveyor_scroll_offset >= conveyor_tile_width:
		conveyor_scroll_offset -= conveyor_tile_width
	for i in range(conveyor_sprites.size()):
		var s: Sprite2D = conveyor_sprites[i]
		s.position.x = conveyor_base_x + i * conveyor_tile_width - conveyor_scroll_offset

func _process_clock(delta: float) -> void:
	if state == State.SHIFT_END or state == State.INSPECT:
		return
	shift_time += delta / REAL_SHIFT_DURATION
	shift_time = clamp(shift_time, 0.0, 1.0)
	_update_clock_label()

func _current_hour() -> float:
	return SHIFT_START_HOUR + shift_time * SHIFT_DURATION_HOURS

func _update_clock_label() -> void:
	var hour = _current_hour()
	var h = int(hour)
	if clock_label:
		clock_label.text = "%02d:00" % h

func _process_shift_changes() -> void:
	if state == State.INSPECT:
		return
	var hour = _current_hour()
	for shift_hour in GUARD_SHIFTS:
		if guard_last_checked_hour < shift_hour and hour >= shift_hour:
			_on_guard_shift_change(shift_hour)
	guard_last_checked_hour = hour
	for shift_hour in SNIPER_SHIFTS:
		if sniper_last_checked_hour < shift_hour and hour >= shift_hour:
			_on_sniper_shift_change(shift_hour)
	sniper_last_checked_hour = hour

func _on_guard_shift_change(_hour: float) -> void:
	if guard_changing:
		return
	guard_changing = true
	if guard_rect:
		var tween = create_tween()
		tween.tween_property(guard_rect, "modulate:a", 0.0, 2.5)
		tween.tween_property(guard_rect, "modulate:a", 1.0, 2.5)
	await get_tree().create_timer(5.0).timeout
	guard_changing = false

func _on_sniper_shift_change(_hour: float) -> void:
	if sniper_changing:
		return
	sniper_changing = true
	if sniper_rect:
		var tween = create_tween()
		tween.tween_property(sniper_rect, "modulate:a", 0.0, 2.5)
		tween.tween_property(sniper_rect, "modulate:a", 1.0, 2.5)
	await get_tree().create_timer(5.0).timeout
	sniper_changing = false

func _process_working(delta: float) -> void:
	if current_object == null or conveyor_paused:
		return
	object_x -= OBJECT_SPEED * delta
	current_object.position.x = object_x
	
	if object_progress < NUM_NPC_FISHES:
		var npc_order = NUM_NPC_FISHES - 1 - object_progress
		var fish_x = FISH_START_X + npc_order * FISH_SPACING
		if object_x <= fish_x + 25:
			_reach_fish(npc_order)
			return
	
	if object_x <= PLAYER_TURN_X + 25:
		_reach_player()

func _spawn_next_object() -> void:
	if current_object_index >= TOTAL_OBJECTS:
		_end_shift()
		return
	
	current_object = Node2D.new()
	current_object.name = "Object" + str(current_object_index)
	
	var rect = ColorRect.new()
	rect.name = "Rect"
	rect.color = Color(0.6, 0.4, 0.2)
	rect.size = Vector2(40, 40)
	rect.position = Vector2(-20, -20)
	current_object.add_child(rect)
	
	current_object.position = Vector2(OBJECT_SPAWN_X, CONVEYOR_Y)
	objects_layer.add_child(current_object)
	
	object_x = OBJECT_SPAWN_X
	object_progress = 0
	conveyor_paused = false

func _set_object_color(c: Color) -> void:
	if current_object == null:
		return
	var rect = current_object.get_node_or_null("Rect")
	if rect:
		rect.color = c

func _set_object_texture(path: String) -> void:
	if current_object == null:
		return
	var rect = current_object.get_node_or_null("Rect")
	if rect == null:
		return
	var tex = load(path)
	if tex == null:
		return
	rect.visible = false
	if current_object.has_node("Sprite"):
		return
	var spr = Sprite2D.new()
	spr.name = "Sprite"
	spr.texture = tex
	spr.scale = Vector2(3, 3)
	current_object.add_child(spr)

func _reach_fish(fish_index: int) -> void:
	conveyor_paused = true
	if fish_index < 0 or fish_index >= npc_fishes.size():
		conveyor_paused = false
		return
	var fish = npc_fishes[fish_index]
	_play_npc_attack(fish)
	object_progress += 1
	_set_object_color(Color(0.7, 0.5, 0.2))
	await get_tree().create_timer(0.4).timeout
	conveyor_paused = false

func _play_npc_attack(fish: Node) -> void:
	if fish == null:
		return
	if fish is AnimatedSprite2D:
		if fish.sprite_frames.has_animation("AttackLeft"):
			fish.play("AttackLeft")
			await fish.animation_finished
			if fish.sprite_frames.has_animation("idle"):
				fish.play("idle")

func _play_player_attack() -> void:
	if player_sprite == null:
		return
	var use_left = (randi() % 2 == 0)
	var anim = "AttackLeft" if use_left else "AttackRight"
	if player_sprite.sprite_frames.has_animation(anim):
		player_sprite.play(anim)

func _reach_player() -> void:
	conveyor_paused = true
	
	if current_object_index < AUTO_OBJECTS:
		_play_player_attack()
		await get_tree().create_timer(0.8).timeout
		if player_sprite and player_sprite.sprite_frames.has_animation("Idle"):
			player_sprite.play("Idle")
		
		correct_count += 1
		_mark_progress(current_object_index, true)
		_finish_current_object()
		current_object_index += 1
		await get_tree().create_timer(0.3).timeout
		
		if current_object_index >= TOTAL_OBJECTS:
			_end_shift()
		else:
			state = State.WORKING
			_spawn_next_object()
		return
	
	if current_object_index == AUTO_OBJECTS:
		wrong_count += 1
		_mark_progress(current_object_index, false)
		_handle_strike()
		
		if player_sprite:
			player_sprite.modulate = COLOR_BLUE
			await get_tree().create_timer(2.0).timeout
			player_sprite.modulate = Color(1, 1, 1, 1)
		
		if player and player.has_method("set_movement_blocked"):
			player.set_movement_blocked(false)
		
		_break_current_object()
		current_object_index += 1
		await get_tree().create_timer(0.5).timeout
		if current_object_index >= TOTAL_OBJECTS:
			_end_shift()
		else:
			state = State.WORKING
			_spawn_next_object()
		return
	
	state = State.MINIGAME
	minigame_active = true
	minigame_panel.visible = true
	hint_label.visible = true
	
	zone_center = randf_range(0.3, 0.7)
	zone_width = randf_range(0.12, 0.22)
	
	var zw = TRACK_WIDTH * zone_width
	var zx = TRACK_WIDTH * zone_center - zw / 2
	minigame_zone.size.x = zw
	minigame_zone.position.x = zx
	
	slider_pos = 0.0
	slider_dir = 1.0
	minigame_slider.position.x = 0

func _finish_current_object() -> void:
	if current_object == null or not is_instance_valid(current_object):
		current_object = null
		return
	_set_object_texture(BOX_TEXTURE_PATH)
	finished_boxes.append(current_object)
	current_object = null

func _break_current_object() -> void:
	if current_object == null or not is_instance_valid(current_object):
		current_object = null
		return
	_set_object_color(COLOR_RED)
	broken_boxes.append(current_object)
	current_object = null

func _process_minigame(delta: float) -> void:
	if not minigame_active:
		return
	slider_pos += slider_dir * 0.8 * delta
	if slider_pos >= 1.0:
		slider_pos = 1.0
		slider_dir = -1.0
		_on_minigame_edge_fail()
		return
	elif slider_pos <= 0.0:
		slider_pos = 0.0
		slider_dir = 1.0
		_on_minigame_edge_fail()
		return
	minigame_slider.position.x = slider_pos * TRACK_WIDTH

func _on_minigame_edge_fail() -> void:
	if not minigame_active:
		return
	minigame_active = false
	hint_label.visible = false
	minigame_panel.visible = false
	
	wrong_count += 1
	_mark_progress(current_object_index, false)
	
	_break_current_object()
	_handle_strike()
	
	current_object_index += 1
	await get_tree().create_timer(0.3).timeout
	
	if current_object_index >= TOTAL_OBJECTS:
		_end_shift()
	else:
		state = State.WORKING
		_spawn_next_object()

func _press_button() -> void:
	if attack_lock:
		return
	
	minigame_active = false
	hint_label.visible = false
	minigame_panel.visible = false
	
	_play_player_attack()
	
	if not _is_player_in_zone():
		wrong_count += 1
		_mark_progress(current_object_index, false)
		_break_current_object()
		current_object_index += 1
		await get_tree().create_timer(0.3).timeout
		if current_object_index >= TOTAL_OBJECTS:
			_end_shift()
		else:
			state = State.WORKING
			_spawn_next_object()
		return
	
	var z_min = zone_center - zone_width / 2
	var z_max = zone_center + zone_width / 2
	var is_correct = slider_pos >= z_min and slider_pos <= z_max
	
	if is_correct:
		correct_count += 1
		_mark_progress(current_object_index, true)
		_finish_current_object()
	else:
		wrong_count += 1
		_mark_progress(current_object_index, false)
		_break_current_object()
		_handle_strike()
	
	current_object_index += 1
	await get_tree().create_timer(0.15).timeout
	if player_sprite and player_sprite.sprite_frames.has_animation("Idle"):
		player_sprite.play("Idle")
	
	if current_object_index >= TOTAL_OBJECTS:
		_end_shift()
	else:
		state = State.WORKING
		_spawn_next_object()

func _mark_progress(index: int, correct: bool) -> void:
	if index < 0 or index >= progress_bar.get_child_count():
		return
	var cell = progress_bar.get_child(index) as ColorRect
	if cell:
		cell.color = COLOR_GREEN if correct else COLOR_RED

# ==============================
# МЕХАНИКА КАРЫ
# ==============================
func _handle_strike() -> void:
	strike_count += 1
	if strike_count == 3:
		_show_guard_dialog("ЭЙ, ЧТО С ТОБОЙ НЕ ТАК?!", 2.5)
	elif strike_count >= 5:
		_kill_player()

func _can_punish() -> bool:
	var guard_alive = guard_rect != null and guard_rect.modulate.a > 0.5
	var sniper_alive = sniper_rect != null and sniper_rect.modulate.a > 0.5
	return guard_alive or sniper_alive

func _kill_player() -> void:
	if state == State.DEAD:
		return
	if not _can_punish():
		strike_count = 0
		return
	
	state = State.DEAD
	conveyor_paused = true
	minigame_panel.visible = false
	hint_label.visible = false
	
	_show_guard_dialog("С СУБЪЕКТОМ 7-БЕТА ЧТО-ТО НЕ ТАК, ОБНАРУЖЕНО ДЕВИАНТСКОЕ ПОВЕДЕНИЕ", 3.5)
	
	if sniper_rect:
		var tween = create_tween()
		tween.tween_property(sniper_rect, "color", COLOR_YELLOW, 0.1)
		tween.tween_property(sniper_rect, "color", Color(0.4, 0.4, 0.5), 0.15)
	
	await get_tree().create_timer(3.5).timeout
	if player and player.has_method("die"):
		player.die()

# ==============================
# СМЕНА
# ==============================
func _end_shift() -> void:
	state = State.SHIFT_END
	conveyor_paused = true
	shift_end_npc_timer = 0.0
	_show_dialog("РАБОТА НА СЕГОДНЯ ВЫПОЛНЕНА, ВСЕ НА ТЕХ ОБСЛУЖИВАНИЕ И НАЗАД", 4.0)
	if wrong_count == 0:
		if has_node("/root/Achievements"):
			Achievements.unlock_worker_of_month()
	_fade_and_new_shift()

func _fade_and_new_shift() -> void:
	await get_tree().create_timer(2.0).timeout
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 3.0)
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	_start_new_shift()
	var tween2 = create_tween()
	tween2.tween_property(fade_rect, "color:a", 0.0, 3.0)
	await tween2.finished
	fade_rect.visible = false

func _start_new_shift() -> void:
	current_shift += 1
	current_object_index = 0
	correct_count = 0
	wrong_count = 0
	strike_count = 0
	shift_time = 0.0
	guard_last_checked_hour = -1.0
	sniper_last_checked_hour = -1.0
	shift_end_npc_timer = 0.0
	
	for i in range(progress_bar.get_child_count()):
		var cell = progress_bar.get_child(i) as ColorRect
		if cell:
			cell.color = Color(0.2, 0.2, 0.2)
	
	if npc_fishes.size() >= 4:
		npc_fishes[0].position = Vector2(285, 344)
		npc_fishes[1].position = Vector2(408, 344)
		npc_fishes[2].position = Vector2(530, 344)
		npc_fishes[3].position = Vector2(661, 344)
		for f in npc_fishes:
			if f is AnimatedSprite2D and f.sprite_frames.has_animation("idle"):
				f.play("idle")
	if player:
		player.position = Vector2(PLAYER_TURN_X, 351)
		if player.has_method("set_movement_blocked"):
			player.set_movement_blocked(true)
	
	if player_gui:
		player_gui.visible = false
	
	if current_shift >= 2:
		bind_hint_i.visible = true
		bind_hint_j.visible = true
	else:
		bind_hint_i.visible = false
		bind_hint_j.visible = false
	
	_update_escape_hint()
	state = State.WORKING
	_spawn_next_object()

func _update_escape_hint() -> void:
	if guard_shifts_found.size() < 3 or sniper_shifts_found.size() < 3:
		escape_hint.visible = false
		return
	var hour = _current_hour()
	var next_window = -1.0
	for gh in GUARD_SHIFTS:
		if not SNIPER_SHIFTS.has(gh):
			if gh > hour:
				next_window = gh
				break
			elif next_window < 0:
				next_window = gh
	if next_window < 0:
		escape_hint.visible = false
		return
	if next_window > hour:
		escape_hint.text = "МОЖНО НАЧАТЬ ПОБЕГ СЕГОДНЯ В %02d:00" % int(next_window)
	else:
		escape_hint.text = "МОЖНО НАЧАТЬ ПОБЕГ ЗАВТРА В %02d:00" % int(next_window)
	escape_hint.visible = true

# ==============================
# ОСМОТР / ЖУРНАЛ
# ==============================
func _enter_inspect() -> void:
	if current_shift < 2:
		return
	if state != State.WORKING:
		return
	state = State.INSPECT
	inspect_mode = true
	inspect_overlay.visible = true
	conveyor_paused = true
	selected_zone = ""
	
	inspect_camera_original_pos = player.global_position
	inspect_camera_offset = Vector2.ZERO
	if camera:
		camera.zoom = Vector2(1.5, 1.5)
	
	if inspect_vignette:
		inspect_vignette.visible = true

func _exit_inspect() -> void:
	if state != State.INSPECT:
		return
	state = State.WORKING
	inspect_mode = false
	inspect_overlay.visible = false
	inspect_marker.visible = false
	conveyor_paused = false
	
	if camera:
		camera.zoom = Vector2(2.5, 2.5)
		camera.global_position = player.global_position
	
	if inspect_vignette:
		inspect_vignette.visible = false

func _process_inspect_click(_mouse_pos: Vector2) -> void:
	var zone_map = {
		"ZoneClock": "clock",
		"ZoneElevator": "elevator",
		"ZoneGuardDoor": "guard_door",
		"ZoneSniper": "sniper",
		"ZoneConveyor": "conveyor",
	}
	var world_pos = get_global_mouse_position()
	for zone_name in zone_map.keys():
		var zone = inspect_zones.get_node_or_null(zone_name)
		if zone == null:
			continue
		var d = zone.global_position.distance_to(world_pos)
		if d < 120:
			selected_zone = zone_map[zone_name]
			if not visited_zones.has(selected_zone):
				visited_zones.append(selected_zone)
			inspect_marker.visible = true
			inspect_marker.position = world_pos - Vector2(40, 40)
			inspect_marker.size = Vector2(80, 80)
			return

func _open_journal() -> void:
	if current_shift < 2:
		return
	journal_open = true
	journal_panel.visible = true
	_update_journal_options()

func _on_journal_close() -> void:
	journal_open = false
	journal_panel.visible = false

func _update_journal_options() -> void:
	for c in journal_list.get_children():
		c.queue_free()
	
	_add_journal_line("=== ЗАПИСИ ===", Color.BLACK, 18)
	_add_journal_line("", Color.BLACK, 14)
	_add_journal_line("СМЕНЫ КАРАУЛА:", Color.BLACK, 16)
	if guard_shifts_found.is_empty():
		_add_journal_line("   (нет данных)", Color.DARK_GRAY, 14)
	else:
		for h in guard_shifts_found:
			_add_journal_line("   %02d:00" % int(h), Color.DARK_GREEN, 14)
	_add_journal_line("", Color.BLACK, 14)
	_add_journal_line("СМЕНЫ СНАЙПЕРА:", Color.BLACK, 16)
	if sniper_shifts_found.is_empty():
		_add_journal_line("   (нет данных)", Color.DARK_GRAY, 14)
	else:
		for h in sniper_shifts_found:
			_add_journal_line("   %02d:00" % int(h), Color.DARK_BLUE, 14)
	_add_journal_line("", Color.BLACK, 14)
	_add_journal_line("ПРОЧЕЕ:", Color.BLACK, 16)
	if known_worker_count:
		_add_journal_line("   Работников: " + str(NUM_NPC_FISHES + 1), Color.DARK_GRAY, 14)
	if known_box_count:
		_add_journal_line("   Коробок за смену: " + str(TOTAL_OBJECTS), Color.DARK_GRAY, 14)
	if known_elevator:
		_add_journal_line("   Лифт склада справа", Color.DARK_GRAY, 14)
	_add_journal_line("", Color.BLACK, 14)
	
	for opt in _get_journal_options():
		var btn = Button.new()
		btn.text = "ЗАПИСАТЬ: " + opt["label"]
		btn.custom_minimum_size = Vector2(680, 30)
		btn.pressed.connect(_on_journal_record.bind(opt["id"], opt.get("hour", -1.0)))
		journal_list.add_child(btn)

func _add_journal_line(text: String, color: Color, font_size: int) -> void:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	journal_list.add_child(l)

func _get_journal_options() -> Array:
	var opts: Array = []
	var current_h = _current_hour()
	
	if visited_zones.has("guard_door"):
		for h in GUARD_SHIFTS:
			if not guard_shifts_found.has(h) and current_h >= h:
				opts.append({"id": "guard_shift", "hour": h, "label": "Смена караула в %02d:00" % int(h)})
	
	if visited_zones.has("sniper"):
		for h in SNIPER_SHIFTS:
			if not sniper_shifts_found.has(h) and current_h >= h:
				opts.append({"id": "sniper_shift", "hour": h, "label": "Смена снайпера в %02d:00" % int(h)})
	
	if visited_zones.has("conveyor") and not known_worker_count:
		opts.append({"id": "worker_count", "label": "Количество работников"})
	if visited_zones.has("conveyor") and not known_box_count:
		opts.append({"id": "box_count", "label": "Количество коробок за смену"})
	if visited_zones.has("elevator") and not known_elevator:
		opts.append({"id": "elevator", "label": "Расположение лифта склада"})
	
	return opts

func _on_journal_record(id: String, hour: float) -> void:
	match id:
		"guard_shift":
			if not guard_shifts_found.has(hour):
				guard_shifts_found.append(hour)
		"sniper_shift":
			if not sniper_shifts_found.has(hour):
				sniper_shifts_found.append(hour)
		"worker_count":
			known_worker_count = true
		"box_count":
			known_box_count = true
		"elevator":
			known_elevator = true
	
	if guard_shifts_found.size() >= 3 and sniper_shifts_found.size() >= 3 \
		and known_worker_count and known_box_count and known_elevator:
		if has_node("/root/Achievements"):
			Achievements.unlock_scout()
	
	_update_journal_options()
	_update_escape_hint()

# ==============================
# ДИАЛОГ / ОХРАННИК
# ==============================
func _process_guard_talk(delta: float) -> void:
	guard_talk_timer -= delta
	if guard_talk_timer <= 0.0:
		guard_talk_timer = randf_range(12.0, 22.0)
		var phrases = [
			"я за вами слежу...",
			"работаем, работаем...",
			"не отлынивать!",
			"ещё одна смена, и всё...",
			"не расслабляться.",
		]
		_show_dialog(phrases[randi() % phrases.size()], 2.0)

func _show_dialog(text: String, duration: float) -> void:
	if is_dialog_active:
		return
	is_dialog_active = true
	dialog_panel.visible = true
	dialog_label.text = text
	await get_tree().create_timer(duration).timeout
	dialog_panel.visible = false
	is_dialog_active = false

func _show_guard_dialog(text: String, duration: float) -> void:
	if is_dialog_active:
		return
	is_dialog_active = true
	dialog_panel.visible = true
	dialog_label.text = text
	
	if camera and guard_camera and guard_rect:
		camera.enabled = false
		guard_camera.global_position = guard_rect.global_position + Vector2(150, -50)
		guard_camera.enabled = true
	
	await get_tree().create_timer(duration).timeout
	dialog_panel.visible = false
	is_dialog_active = false
	
	if camera and guard_camera:
		guard_camera.enabled = false
		camera.enabled = true
		camera.global_position = player.global_position

# ==============================
# ПАУЗА
# ==============================
func _toggle_pause() -> void:
	if pausemenu == null:
		return
	if pausemenu.visible:
		if pausemenu.has_method("hide_menu"):
			pausemenu.hide_menu()
		else:
			pausemenu.visible = false
		get_tree().paused = false
	else:
		pausemenu.visible = true
		if pausemenu.has_method("show_menu"):
			pausemenu.show_menu()
		else:
			for child in pausemenu.get_children():
				if child is Button:
					child.modulate.a = 1.0
					child.scale = Vector2.ONE
				elif child is ColorRect:
					child.modulate.a = 0.5
		get_tree().paused = true

func _resume_after_pause() -> void:
	pass

# ==============================
# ВВОД
# ==============================
func _input(event: InputEvent) -> void:
	if state == State.INSPECT:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_process_inspect_click(event.position)
				get_viewport().set_input_as_handled()
				return
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_I or event.keycode == KEY_ESCAPE:
				_exit_inspect()
				get_viewport().set_input_as_handled()
				return
		return
	
	if event.is_action_pressed("interact"):
		if state == State.MINIGAME and minigame_active and not attack_lock:
			_press_button()
			get_viewport().set_input_as_handled()
			return
		if state == State.WORKING and _near_elevator():
			_enter_elevator()
			get_viewport().set_input_as_handled()
			return
	
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			if current_shift < 2:
				return
			if state == State.WORKING:
				_enter_inspect()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_J:
			if current_shift < 2:
				return
			if journal_open:
				_on_journal_close()
			else:
				_open_journal()
			get_viewport().set_input_as_handled()

# ==============================
# ЛИФТ / ПОБЕГ
# ==============================
func _near_elevator() -> bool:
	if player == null or elevator_door == null:
		return false
	return player.global_position.distance_to(elevator_door.global_position) < 150

func _enter_elevator() -> void:
	var hour = _current_hour()
	var in_window = false
	for gh in GUARD_SHIFTS:
		if abs(gh - hour) < 0.2 and not SNIPER_SHIFTS.has(gh):
			in_window = true
			break
	
	if not in_window:
		_show_dialog("ЛИФТ ЗАКРЫТ. НУЖНО ДОЖДАТЬСЯ СМЕНЫ КАРАУЛА.", 2.5)
		return
	
	if guard_shifts_found.size() < 3 or sniper_shifts_found.size() < 3:
		_show_dialog("Я НЕ ЗНАЮ РАСПИСАНИЯ. НУЖНО БОЛЬШЕ РАЗВЕДКИ.", 2.5)
		return
	
	if has_node("/root/Achievements"):
		Achievements.unlock_freedom()
	_show_dialog("ПОБЕГ...", 1.5)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act3HallwayLevel.tscn")
