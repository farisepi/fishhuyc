extends Node2D

const TOTAL_OBJECTS: int = 25
const NUM_NPC_FISHES: int = 4
const AUTO_OBJECTS: int = 3

const CONVEYOR_Y: float = 386.0
const FISH_START_X: float = 285.0
const FISH_SPACING: float = 125.0
const PLAYER_TURN_X: float = 156.0
const OBJECT_SPAWN_X: float = 900.0
const OBJECT_DESPAWN_X: float = -700.0

const OBJECT_SPEED: float = 187.5
const NPC_WALK_SPEED: float = 240.0
const NPC_WALK_DELAY_MIN: float = 0.5
const NPC_WALK_DELAY_MAX: float = 1.0

const SHIFT_START_HOUR: float = 8.0
const SHIFT_END_HOUR: float = 18.0
const SHIFT_DURATION_HOURS: float = 10.0
const REAL_SHIFT_DURATION: float = 150.0

const SHIFT_CHANGE_HOURS: float = 0.25
const SHIFT_CHANGE_REAL: float = (SHIFT_CHANGE_HOURS / SHIFT_DURATION_HOURS) * REAL_SHIFT_DURATION

const GUARD_SHIFTS: Array = [9.0, 13.0, 17.0]
const SNIPER_SHIFTS: Array = [11.0, 13.0, 15.0]

# Единственное окно побега — 13:00-13:15
const ESCAPE_WINDOW_START: float = 13.0
const ESCAPE_WINDOW_END: float = 13.25

const COLOR_GREEN := Color(0.2, 0.8, 0.3)
const COLOR_RED := Color(0.9, 0.2, 0.2)
const COLOR_YELLOW := Color(1, 0.9, 0.3)
const COLOR_BLUE := Color(0.3, 0.5, 0.8)
const COLOR_HIGHLIGHT_BLUE := Color(0.3, 0.7, 1.0, 0.25)
const COLOR_HIGHLIGHT_YELLOW := Color(1.0, 0.9, 0.3, 0.35)

const GUARD_DOG_COLOR := Color(0.15, 0.35, 0.95)
const GUARD_MONKEY_COLOR := Color(0.2, 0.85, 0.3)
const SNIPER_NORMAL_COLOR := Color(0.4, 0.4, 0.5)

const BOX_TEXTURE_PATH := "res://Fish Slaves/Textures/Tiles/Act2Tiles/Act2Box.png"
const ATTACK_ALL_PATH := "res://Fish Slaves/Textures/Characters/Player/PlayerMechaFish/PlayerMechaFishAttack/PlayerMechaFishAttack.png"
const JOGGING_PATH := "res://Fish Slaves/Textures/Characters/Player/PlayerMechaFish/PlayerMechaFishJogging/MechaFishJogging.png"
const ATTACK_FRAMES_PER_SIDE: int = 8
const JOGGING_FRAMES: int = 12

const PLAYER_ZONE_CENTER := Vector2(156.0, 386.0)
const PLAYER_ZONE_SIZE := Vector2(80.0, 120.0)

const ACT2_DISABLED_ACTIONS := ["crouch", "block", "Parry", "inventory"]

const STRIKE_WARNING: int = 3
const STRIKE_DEATH: int = 5
const STRIKE_DEATH_SHIFT1: int = 4
const ACTION_STRIKE_WARNING: int = 1
const ACTION_STRIKE_DEATH: int = 2
const ACTION_STRIKE_INTERVAL: float = 1.0

const MINIGAME_SLIDER_SPEED: float = 1.0

const PROGRESSBAR_BG_PATH := "res://Fish Slaves/Textures/Interface/MenuButtons/Progressbar/FactoryProgressbar/FactoryProgressbar.png"
const PROGRESSBAR_FILL_PATH := "res://Fish Slaves/Textures/Interface/MenuButtons/Progressbar/FactoryProgressbar/FactoryProgressbarFull.png"

@onready var player: CharacterBody2D = $Mecha_Fish
@onready var camera: Camera2D = $Mecha_Fish/MechaFishCamera
@onready var player_sprite: AnimatedSprite2D = $Mecha_Fish/AnimatedSprite2D
@onready var player_gui: CanvasLayer = $Mecha_Fish/GUI
@onready var objects_layer: Node2D = $Objects
@onready var npc_fishes: Array[Node] = [$NPCParent/Fish1, $NPCParent/Fish2, $NPCParent/Fish3, $NPCParent/Fish4]
@onready var guard_rect: ColorRect = $Guard
@onready var sniper_rect: ColorRect = $Sniper
@onready var elevator_door: ColorRect = $Elevator
@onready var maintenance_door: ColorRect = $MaintenanceRoom

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
var action_strike_count: int = 0
var action_move_timer: float = 0.0

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

var selected_zone: String = ""

var guard_changing: bool = false
var sniper_changing: bool = false
var guard_last_checked_hour: float = -1.0
var sniper_last_checked_hour: float = -1.0
var guard_is_dog: bool = true

var conveyor_sprites: Array = []
var conveyor_tile_width: float = 0.0
var conveyor_scroll_offset: float = 0.0
var conveyor_base_x: float = 0.0
var conveyor_floor_rect: ColorRect = null

var floor_rect: ColorRect = null
var work_zone_rect: ColorRect = null

var shift_end_npc_timer: float = 0.0
var npc_walk_delays: Array = []
var follow_strike_timer: float = 0.0

var inspect_camera_offset: Vector2 = Vector2.ZERO
var inspect_vignette: ColorRect = null
var inspect_camera_original_pos: Vector2 = Vector2.ZERO
var inspect_camera_original_zoom: Vector2 = Vector2(2.5, 2.5)

var guard_camera: Camera2D = null

var inspect_targets: Array = []
var inspect_target_data: Dictionary = {}
var inspect_highlight_rects: Dictionary = {}
var inspect_text_panel: Panel = null
var inspect_text_label: RichTextLabel = null
var inspect_journal_notice: Label = null
var inspect_notice_timer: float = 0.0

var guard_shift_bar: ProgressBar = null
var sniper_shift_bar: ProgressBar = null
var guard_shift_label: Label = null
var sniper_shift_bar_label: Label = null

var journal_notes: Array = []
var journal_notes_full: Dictionary = {}
var elevator_inspected: bool = false

func _ready() -> void:
	randomize()
	
	_disable_actions_for_act2()
	
	if player:
		player.dash_cooldown = 999999.0
		player.block_click_attack = true
	
	if guard_rect:
		guard_rect.color = GUARD_DOG_COLOR
		guard_rect.visible = true
	guard_is_dog = true
	if sniper_rect:
		sniper_rect.color = SNIPER_NORMAL_COLOR
		sniper_rect.visible = true
	
	for i in range(TOTAL_OBJECTS):
		var cell = ColorRect.new()
		cell.name = "Cell" + str(i)
		cell.color = Color(0.2, 0.2, 0.2)
		cell.custom_minimum_size = Vector2(10, 20)
		progress_bar.add_child(cell)
	
	_collect_conveyor_sprites()
	_create_conveyor_floor()
	_create_floor_rect()
	_create_work_zone()
	_create_vignette()
	_create_shift_bars()
	_create_inspect_targets()
	_create_inspect_text_panel()
	_setup_npc_animations()
	_setup_guard_camera()
	_ensure_death_screen()
	
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
		var container = player_gui.get_node_or_null("UI_Container")
		if container and container is Control:
			container.modulate.a = 0.0
	
	await get_tree().process_frame
	
	if player and player.has_method("set_movement_blocked"):
		player.set_movement_blocked(true)
	
	if camera:
		camera.enabled = true
		camera.top_level = true
		camera.global_position = player.global_position
		inspect_camera_original_zoom = camera.zoom
	
	if player_sprite and player_sprite.sprite_frames.has_animation("Idle"):
		player_sprite.play("Idle")
	
	intro_timer = 0.0
	state = State.INTRO

func _ensure_death_screen() -> void:
	var ds = get_node_or_null("DeathScreen")
	if ds == null:
		var death_scene = load("res://Fish Slaves/Base/Scenes/Overlay/Transition/DeathScreen.tscn")
		if death_scene:
			var instance = death_scene.instantiate()
			instance.name = "DeathScreen"
			add_child(instance)
			if instance is CanvasLayer:
				instance.visible = false
			elif instance.has_method("hide_death"):
				instance.hide_death()

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
	work_zone_rect.color = Color(0.2, 0.8, 0.3, 0.35)
	work_zone_rect.offset_left = PLAYER_ZONE_CENTER.x - PLAYER_ZONE_SIZE.x / 2.0
	work_zone_rect.offset_top = PLAYER_ZONE_CENTER.y - PLAYER_ZONE_SIZE.y / 2.0
	work_zone_rect.offset_right = PLAYER_ZONE_CENTER.x + PLAYER_ZONE_SIZE.x / 2.0
	work_zone_rect.offset_bottom = PLAYER_ZONE_CENTER.y + PLAYER_ZONE_SIZE.y / 2.0
	work_zone_rect.z_index = 1
	work_zone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(work_zone_rect)

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
	COLOR = vec4(0.0, 0.0, 0.0, v * 0.6);
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

func _create_shift_bars() -> void:
	var bg_tex = load(PROGRESSBAR_BG_PATH)
	var fill_tex = load(PROGRESSBAR_FILL_PATH)
	
	guard_shift_bar = ProgressBar.new()
	guard_shift_bar.name = "GuardShiftBar"
	guard_shift_bar.position = Vector2(376, 100)
	guard_shift_bar.size = Vector2(400, 12)
	guard_shift_bar.show_percentage = false
	guard_shift_bar.max_value = 3
	guard_shift_bar.value = 0
	if bg_tex:
		var sb = StyleBoxTexture.new()
		sb.texture = bg_tex
		guard_shift_bar.add_theme_stylebox_override("background", sb)
	if fill_tex:
		var sf = StyleBoxTexture.new()
		sf.texture = fill_tex
		guard_shift_bar.add_theme_stylebox_override("fill", sf)
	$UI.add_child(guard_shift_bar)
	
	guard_shift_label = Label.new()
	guard_shift_label.name = "GuardShiftLabel"
	guard_shift_label.position = Vector2(786, 96)
	guard_shift_label.size = Vector2(80, 20)
	guard_shift_label.add_theme_font_size_override("font_size", 16)
	guard_shift_label.add_theme_color_override("font_color", Color.WHITE)
	guard_shift_label.text = "0/3"
	$UI.add_child(guard_shift_label)
	
	sniper_shift_bar = ProgressBar.new()
	sniper_shift_bar.name = "SniperShiftBar"
	sniper_shift_bar.position = Vector2(376, 126)
	sniper_shift_bar.size = Vector2(400, 12)
	sniper_shift_bar.show_percentage = false
	sniper_shift_bar.max_value = 3
	sniper_shift_bar.value = 0
	if bg_tex:
		var sb2 = StyleBoxTexture.new()
		sb2.texture = bg_tex
		sniper_shift_bar.add_theme_stylebox_override("background", sb2)
	if fill_tex:
		var sf2 = StyleBoxTexture.new()
		sf2.texture = fill_tex
		sniper_shift_bar.add_theme_stylebox_override("fill", sf2)
	$UI.add_child(sniper_shift_bar)
	
	sniper_shift_bar_label = Label.new()
	sniper_shift_bar_label.name = "SniperShiftLabel"
	sniper_shift_bar_label.position = Vector2(786, 122)
	sniper_shift_bar_label.size = Vector2(80, 20)
	sniper_shift_bar_label.add_theme_font_size_override("font_size", 16)
	sniper_shift_bar_label.add_theme_color_override("font_color", Color.WHITE)
	sniper_shift_bar_label.text = "0/3"
	$UI.add_child(sniper_shift_bar_label)
	
	guard_shift_bar.visible = false
	guard_shift_label.visible = false
	sniper_shift_bar.visible = false
	sniper_shift_bar_label.visible = false

func _update_shift_bars() -> void:
	if current_shift < 2:
		if guard_shift_bar:
			guard_shift_bar.visible = false
		if guard_shift_label:
			guard_shift_label.visible = false
		if sniper_shift_bar:
			sniper_shift_bar.visible = false
		if sniper_shift_bar_label:
			sniper_shift_bar_label.visible = false
		return
	
	if guard_shift_bar:
		guard_shift_bar.visible = true
		guard_shift_bar.value = guard_shifts_found.size()
	if guard_shift_label:
		guard_shift_label.visible = true
		guard_shift_label.text = str(guard_shifts_found.size()) + "/3"
	
	if current_shift >= 3:
		if sniper_shift_bar:
			sniper_shift_bar.visible = true
			sniper_shift_bar.value = sniper_shifts_found.size()
		if sniper_shift_bar_label:
			sniper_shift_bar_label.visible = true
			sniper_shift_bar_label.text = str(sniper_shifts_found.size()) + "/3"
	else:
		if sniper_shift_bar:
			sniper_shift_bar.visible = false
		if sniper_shift_bar_label:
			sniper_shift_bar_label.visible = false

func _create_inspect_targets() -> void:
	# 8 синих обычных
	_add_inspect_target("clock", Vector2(576, 80), Vector2(120, 60),
		"Часы", "Сколько я тут?", "Смена длится 10 часов",
		COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("elevator", Vector2(-290, 325), Vector2(100, 120),
		"Лифт", "Стоит попробовать..", "Лифт из которого приходят охранники",
		COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("maintenance", Vector2(1230, 325), Vector2(100, 120),
		"Комната техобслуживания", "Туда уходят рабочие в конце смены..",
		"Комната техобслуживания — сюда уходят рабочие после смены",
		COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("sniper", Vector2(1060, 60), Vector2(120, 80),
		"Снайпер-Голубь", "Снайпер, который может пристрелить меня когда угодно..",
		"Снайпер-Голубь в меха костюме. Имеет крылья винтовку и пистолет",
		COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("guard_dog", Vector2(-215, 310), Vector2(80, 80),
		"Охранник-Собака", "Лучший друг человека..",
		"Охранник-Собака в меха костюме. Имеет меха челюсти со смертельной силой сжатия",
		COLOR_HIGHLIGHT_BLUE, "dog")
	_add_inspect_target("guard_monkey", Vector2(-215, 310), Vector2(80, 80),
		"Охранник-Обезьяна", "Человекоподобные тоже с ними..",
		"Охранник-Обезьяна в меха костюме. Имеет массивный меха хвост",
		COLOR_HIGHLIGHT_BLUE, "monkey")
	_add_inspect_target("conveyor", Vector2(400, 400), Vector2(200, 60),
		"Конвейер", "Сколько еще таких заводов они построили?",
		str(TOTAL_OBJECTS) + " коробок за смену",
		COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("workers", Vector2(480, 344), Vector2(500, 80),
		"Рабочие", "Такие же как я, делают чёртовы суши..",
		"5 Рабочих-Рыб в меха костюмах",
		COLOR_HIGHLIGHT_BLUE, "")
	
	# 3 жёлтых смены охраны
	_add_inspect_target("guard_shift_9", Vector2(-215, 310), Vector2(80, 80),
		"Смена охранника", "Охранник сменился.. Нужно записать",
		"Смена охранника в 09:00",
		COLOR_HIGHLIGHT_YELLOW, "guard_shift", 9.0)
	_add_inspect_target("guard_shift_13", Vector2(-215, 310), Vector2(80, 80),
		"Смена охранника", "Охранник сменился.. Нужно записать",
		"Смена охранника в 13:00",
		COLOR_HIGHLIGHT_YELLOW, "guard_shift", 13.0)
	_add_inspect_target("guard_shift_17", Vector2(-215, 310), Vector2(80, 80),
		"Смена охранника", "Охранник сменился.. Нужно записать",
		"Смена охранника в 17:00",
		COLOR_HIGHLIGHT_YELLOW, "guard_shift", 17.0)
	
	# 3 жёлтых смены снайпера
	_add_inspect_target("sniper_shift_11", Vector2(1060, 60), Vector2(120, 80),
		"Смена снайпера", "Снайпер сменился.. Нужно записать",
		"Смена снайпера в 11:00",
		COLOR_HIGHLIGHT_YELLOW, "sniper_shift", 11.0)
	_add_inspect_target("sniper_shift_13", Vector2(1060, 60), Vector2(120, 80),
		"Смена снайпера", "Снайпер сменился.. Нужно записать",
		"Смена снайпера в 13:00",
		COLOR_HIGHLIGHT_YELLOW, "sniper_shift", 13.0)
	_add_inspect_target("sniper_shift_15", Vector2(1060, 60), Vector2(120, 80),
		"Смена снайпера", "Снайпер сменился.. Нужно записать",
		"Смена снайпера в 15:00",
		COLOR_HIGHLIGHT_YELLOW, "sniper_shift", 15.0)

func _add_inspect_target(id: String, pos: Vector2, size: Vector2, title: String, phrase: String, journal: String, color: Color, special_type: String = "", special_hour: float = -1.0) -> void:
	var area = Area2D.new()
	area.name = "InspectTarget_" + id
	area.position = pos
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	area.add_child(col)
	add_child(area)
	
	inspect_targets.append(area)
	inspect_target_data[area] = {
		"id": id,
		"title": title,
		"phrase": phrase,
		"journal": journal,
		"pos": pos,
		"size": size,
		"color": color,
		"special_type": special_type,
		"special_hour": special_hour,
	}
	
	var hl = ColorRect.new()
	hl.name = "Highlight_" + id
	hl.color = color
	hl.offset_left = pos.x - size.x / 2.0
	hl.offset_top = pos.y - size.y / 2.0
	hl.offset_right = pos.x + size.x / 2.0
	hl.offset_bottom = pos.y + size.y / 2.0
	hl.z_index = 2
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hl.visible = false
	add_child(hl)
	inspect_highlight_rects[area] = hl

func _is_inspect_target_visible(area: Area2D) -> bool:
	var data = inspect_target_data.get(area, {})
	if data.is_empty():
		return false
	var id = data.get("id", "")
	var special_type = data.get("special_type", "")
	var special_hour = data.get("special_hour", -1.0)
	
	# Проверка на уже записанную пометку
	if journal_notes.has(id):
		return false
	
	# Синие обычные
	if special_type == "":
		if id == "guard_dog":
			return guard_is_dog
		if id == "guard_monkey":
			return not guard_is_dog
		return true
	
	# Жёлтые смены
	if special_type == "guard_shift" or special_type == "sniper_shift":
		var hour = _current_hour()
		return hour >= special_hour and hour <= special_hour + 0.25
	
	return true

func _update_inspect_highlights() -> void:
	for area in inspect_targets:
		if not is_instance_valid(area):
			continue
		var hl = inspect_highlight_rects.get(area, null)
		if not is_instance_valid(hl):
			continue
		if _is_inspect_target_visible(area):
			hl.visible = true
		else:
			hl.visible = false

func _create_inspect_text_panel() -> void:
	inspect_text_panel = Panel.new()
	inspect_text_panel.name = "InspectTextPanel"
	inspect_text_panel.visible = false
	inspect_text_panel.z_index = 200
	inspect_text_panel.offset_left = 200
	inspect_text_panel.offset_top = 540
	inspect_text_panel.offset_right = 952
	inspect_text_panel.offset_bottom = 610
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.7, 1.0, 0.8)
	inspect_text_panel.add_theme_stylebox_override("panel", style)
	$UI.add_child(inspect_text_panel)
	
	inspect_text_label = RichTextLabel.new()
	inspect_text_label.name = "InspectTextLabel"
	inspect_text_label.bbcode_enabled = true
	inspect_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	inspect_text_label.offset_left = 10
	inspect_text_label.offset_top = 8
	inspect_text_label.offset_right = -10
	inspect_text_label.offset_bottom = -8
	inspect_text_label.add_theme_font_size_override("normal_font_size", 16)
	inspect_text_label.add_theme_color_override("default_color", Color.WHITE)
	inspect_text_panel.add_child(inspect_text_label)
	
	inspect_journal_notice = Label.new()
	inspect_journal_notice.name = "InspectJournalNotice"
	inspect_journal_notice.visible = false
	inspect_journal_notice.z_index = 201
	inspect_journal_notice.offset_left = 200
	inspect_journal_notice.offset_top = 510
	inspect_journal_notice.offset_right = 952
	inspect_journal_notice.offset_bottom = 535
	inspect_journal_notice.add_theme_font_size_override("font_size", 16)
	inspect_journal_notice.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	inspect_journal_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$UI.add_child(inspect_journal_notice)

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

func _process(delta: float) -> void:
	if state == State.DEAD:
		return
	if get_tree().paused:
		return
	
	_process_clock(delta)
	_process_shift_changes()
	_process_conveyor_scroll(delta)
	_process_finished_boxes(delta)
	_process_broken_boxes(delta)
	_process_shift_end_npcs(delta)
	_process_action_penalty(delta)
	_process_follow_penalty(delta)
	_process_inspect_notice(delta)
	
	if state == State.INSPECT:
		_process_inspect_camera(delta)
		_process_working(delta)
		_process_minigame(delta)
		_update_inspect_highlights()
	else:
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
	
	if not is_dialog_active and state != State.SHIFT_END and state != State.DEAD and state != State.INSPECT:
		_process_guard_talk(delta)

func _process_inspect_notice(delta: float) -> void:
	if inspect_notice_timer > 0:
		inspect_notice_timer -= delta
		if inspect_notice_timer <= 0:
			if inspect_journal_notice:
				inspect_journal_notice.visible = false

func _process_action_penalty(delta: float) -> void:
	if state == State.INSPECT:
		return
	if state == State.MINIGAME:
		return
	if state == State.DEAD:
		return
	if state == State.SHIFT_END:
		return
	
	var hour = _current_hour()
	var no_guard = abs(hour - 13.0) < 0.5
	if no_guard:
		action_move_timer = 0.0
		return
	
	var moving = false
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		moving = true
	if Input.is_action_pressed("jump"):
		moving = true
	
	if moving:
		action_move_timer += delta
		if action_move_timer >= ACTION_STRIKE_INTERVAL:
			action_move_timer = 0.0
			action_strike_count += 1
			_handle_action_strike()
	else:
		action_move_timer = 0.0

func _process_follow_penalty(delta: float) -> void:
	if state != State.SHIFT_END:
		follow_strike_timer = 0.0
		return
	if player == null:
		return
	
	if Input.is_action_pressed("ui_right"):
		follow_strike_timer = 0.0
		return
	
	follow_strike_timer += delta
	if follow_strike_timer >= ACTION_STRIKE_INTERVAL:
		follow_strike_timer = 0.0
		action_strike_count += 1
		_handle_action_strike()

func _process_inspect_camera(delta: float) -> void:
	if camera == null:
		return
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	inspect_camera_offset += dir * 375 * delta
	inspect_camera_offset.x = clamp(inspect_camera_offset.x, -1500, 1500)
	inspect_camera_offset.y = clamp(inspect_camera_offset.y, -600, 600)
	camera.global_position = inspect_camera_original_pos + inspect_camera_offset

func _process_shift_end_npcs(delta: float) -> void:
	if state != State.SHIFT_END:
		return
	shift_end_npc_timer += delta
	for i in range(npc_fishes.size()):
		var fish = npc_fishes[i]
		if fish == null:
			continue
		var delay = 0.0
		if i < npc_walk_delays.size():
			delay = npc_walk_delays[i]
		if shift_end_npc_timer >= delay:
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
	if state == State.SHIFT_END:
		return
	shift_time += delta / REAL_SHIFT_DURATION
	shift_time = clamp(shift_time, 0.0, 1.0)
	_update_clock_label()

func _current_hour() -> float:
	return SHIFT_START_HOUR + shift_time * SHIFT_DURATION_HOURS

func _update_clock_label() -> void:
	var hour = _current_hour()
	var h = int(hour)
	var m = int((hour - h) * 60)
	m = int(m / 15) * 15
	if clock_label:
		clock_label.text = "%02d:%02d" % [h, m]

func _process_shift_changes() -> void:
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
		guard_rect.visible = false
	
	await get_tree().create_timer(SHIFT_CHANGE_REAL).timeout
	
	guard_is_dog = not guard_is_dog
	if guard_rect:
		guard_rect.color = GUARD_DOG_COLOR if guard_is_dog else GUARD_MONKEY_COLOR
		guard_rect.visible = true
	
	guard_changing = false

func _on_sniper_shift_change(_hour: float) -> void:
	if sniper_changing:
		return
	sniper_changing = true
	
	if sniper_rect:
		sniper_rect.visible = false
	
	await get_tree().create_timer(SHIFT_CHANGE_REAL).timeout
	
	if sniper_rect:
		sniper_rect.visible = true
	
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
	
	if current_shift == 1 and current_object_index < AUTO_OBJECTS:
		_play_player_attack()
		await get_tree().create_timer(0.5).timeout
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
	
	if current_shift == 1 and current_object_index == AUTO_OBJECTS:
		wrong_count += 1
		_mark_progress(current_object_index, false)
		
		if player_sprite:
			player_sprite.modulate = COLOR_BLUE
			await get_tree().create_timer(2.0).timeout
			player_sprite.modulate = Color(1, 1, 1, 1)
		
		if player and player.has_method("set_movement_blocked"):
			player.set_movement_blocked(false)
		
		_show_gui()
		
		_break_current_object()
		current_object_index += 1
		await get_tree().create_timer(0.5).timeout
		if current_object_index >= TOTAL_OBJECTS:
			_end_shift()
		else:
			state = State.WORKING
			_spawn_next_object()
		return
	
	if not _is_player_in_zone():
		wrong_count += 1
		_mark_progress(current_object_index, false)
		_break_current_object()
		_handle_strike()
		current_object_index += 1
		conveyor_paused = false
		await get_tree().create_timer(0.3).timeout
		if current_object_index >= TOTAL_OBJECTS:
			_end_shift()
		else:
			state = State.WORKING
			_spawn_next_object()
		return
	
	if player_gui and not player_gui.visible:
		_show_gui()
	
	state = State.MINIGAME
	minigame_active = true
	minigame_panel.visible = true
	hint_label.visible = true
	hint_label.text = "НАЖМИ E В ЗЕЛЁНОЙ ЗОНЕ!"
	
	zone_center = randf_range(0.3, 0.7)
	zone_width = randf_range(0.18, 0.28)
	
	var zw = TRACK_WIDTH * zone_width
	var zx = TRACK_WIDTH * zone_center - zw / 2
	minigame_zone.size.x = zw
	minigame_zone.position.x = zx
	
	slider_pos = 0.0
	slider_dir = 1.0
	minigame_slider.position.x = 0

func _show_gui() -> void:
	if player_gui == null:
		return
	player_gui.visible = true
	var container = player_gui.get_node_or_null("UI_Container")
	if container and container is Control:
		container.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(container, "modulate:a", 1.0, 0.5)

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
	slider_pos += slider_dir * MINIGAME_SLIDER_SPEED * delta
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
	conveyor_paused = false
	await get_tree().create_timer(0.3).timeout
	
	if current_object_index >= TOTAL_OBJECTS:
		_end_shift()
	else:
		state = State.WORKING
		_spawn_next_object()

func _press_button() -> void:
	if not minigame_active:
		return
	
	UISounds.play_click()
	
	minigame_active = false
	hint_label.visible = false
	minigame_panel.visible = false
	conveyor_paused = false
	
	_play_player_attack()
	
	if not _is_player_in_zone():
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
	await get_tree().create_timer(0.2).timeout
	
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

func _handle_strike() -> void:
	strike_count += 1
	var death_threshold = STRIKE_DEATH_SHIFT1 if current_shift == 1 else STRIKE_DEATH
	if strike_count == STRIKE_WARNING:
		_show_guard_dialog("ЭЙ, ЧТО С ТОБОЙ НЕ ТАК?!", 2.5)
	elif strike_count >= death_threshold:
		_kill_player()

func _handle_action_strike() -> void:
	if action_strike_count == ACTION_STRIKE_WARNING:
		_show_guard_dialog("ЭЙ! РАБОТАЙ, А НЕ ОТВЛЕКАЙСЯ!", 2.5)
	elif action_strike_count >= ACTION_STRIKE_DEATH:
		_kill_player()

func _can_punish() -> bool:
	var guard_alive = guard_rect != null and not guard_changing
	var sniper_alive = sniper_rect != null and not sniper_changing
	return guard_alive or sniper_alive

func _kill_player() -> void:
	if state == State.DEAD:
		return
	if not _can_punish():
		strike_count = 0
		action_strike_count = 0
		return
	
	state = State.DEAD
	conveyor_paused = true
	minigame_panel.visible = false
	hint_label.visible = false
	
	_show_guard_dialog("С СУБЪЕКТОМ 7-БЕТА ЧТО-ТО НЕ ТАК, ОБНАРУЖЕНО ДЕВИАНТСКОЕ ПОВЕДЕНИЕ", 3.5)
	
	if sniper_rect:
		var tween = create_tween()
		tween.tween_property(sniper_rect, "color", COLOR_YELLOW, 0.1)
		tween.tween_property(sniper_rect, "color", SNIPER_NORMAL_COLOR, 0.15)
	
	await get_tree().create_timer(3.5).timeout
	if player and player.has_method("die"):
		player.die()

func _end_shift() -> void:
	state = State.SHIFT_END
	conveyor_paused = true
	shift_end_npc_timer = 0.0
	follow_strike_timer = 0.0
	npc_walk_delays.clear()
	for i in range(npc_fishes.size()):
		npc_walk_delays.append(randf_range(NPC_WALK_DELAY_MIN, NPC_WALK_DELAY_MAX))
	_show_dialog("РАБОТА НА СЕГОДНЯ ВЫПОЛНЕНА, ВСЕ НА ТЕХ ОБСЛУЖИВАНИЕ И НАЗАД", 4.0)
	
	if wrong_count == 0:
		if has_node("/root/Achievements"):
			var was = Achievements.worker_of_month_unlocked
			Achievements.unlock_worker_of_month()
			if not was:
				_show_worker_of_month_achievement()
	
	_fade_and_new_shift()

func _fade_and_new_shift() -> void:
	await get_tree().create_timer(2.5).timeout
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
	action_strike_count = 0
	action_move_timer = 0.0
	follow_strike_timer = 0.0
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
		if current_shift >= 2:
			if player.has_method("set_movement_blocked"):
				player.set_movement_blocked(false)
		else:
			if player.has_method("set_movement_blocked"):
				player.set_movement_blocked(true)
	
	if current_shift >= 2:
		bind_hint_i.visible = true
		bind_hint_j.visible = true
	else:
		bind_hint_i.visible = false
		bind_hint_j.visible = false
	
	_update_shift_bars()
	_update_escape_hint()
	state = State.WORKING
	_spawn_next_object()

func _update_escape_hint() -> void:
	if guard_shifts_found.size() < 3 or sniper_shifts_found.size() < 3:
		escape_hint.visible = false
		return
	if elevator_inspected:
		escape_hint.text = "13:00 - 13:15 ЕДИНСТВЕННОЕ ВРЕМЯ ДЛЯ ПОБЕГА ЧЕРЕЗ ЛИФТ"
	else:
		escape_hint.text = "13:00 - 13:15 ЕДИНСТВЕННОЕ ВРЕМЯ ДЛЯ ПОБЕГА"
	escape_hint.visible = true

func _enter_inspect() -> void:
	if current_shift < 2:
		return
	if state != State.WORKING:
		return
	state = State.INSPECT
	inspect_mode = true
	inspect_overlay.visible = true
	selected_zone = ""
	
	if player and player.has_method("set_movement_blocked"):
		player.set_movement_blocked(true)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_update_inspect_highlights()
	
	inspect_camera_original_pos = player.global_position
	inspect_camera_offset = Vector2.ZERO
	if camera:
		var tw = create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "zoom", Vector2(1.5, 1.5), 0.5)
	
	if inspect_vignette:
		inspect_vignette.visible = true

func _exit_inspect() -> void:
	if state != State.INSPECT:
		return
	state = State.WORKING
	inspect_mode = false
	inspect_overlay.visible = false
	inspect_marker.visible = false
	
	if player and player.has_method("set_movement_blocked"):
		player.set_movement_blocked(false)
	
	for area in inspect_highlight_rects.keys():
		var hl = inspect_highlight_rects[area]
		if is_instance_valid(hl):
			hl.visible = false
	
	if inspect_text_panel:
		inspect_text_panel.visible = false
	if inspect_journal_notice:
		inspect_journal_notice.visible = false
	inspect_notice_timer = 0.0
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if camera:
		var tw = create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "zoom", inspect_camera_original_zoom, 0.5)
		tw.tween_callback(func():
			camera.global_position = player.global_position
		)
	
	if inspect_vignette:
		inspect_vignette.visible = false

func _process_inspect_click(_mouse_pos: Vector2) -> void:
	var world_pos = get_global_mouse_position()
	for area in inspect_targets:
		if not is_instance_valid(area):
			continue
		if not _is_inspect_target_visible(area):
			continue
		var data = inspect_target_data.get(area, {})
		var size = data.get("size", Vector2(100, 100))
		var pos = data.get("pos", Vector2.ZERO)
		var rect = Rect2(pos - size / 2.0, size)
		if rect.has_point(world_pos):
			var id = data.get("id", "")
			var special_type = data.get("special_type", "")
			
			_show_inspect_text(data.get("title", ""), data.get("phrase", ""), data.get("journal", ""))
			_add_journal_note(id, data.get("title", "") + ": " + data.get("journal", ""))
			
			if id == "elevator":
				elevator_inspected = true
			
			if special_type == "guard_shift":
				var h = data.get("special_hour", 0.0)
				if not guard_shifts_found.has(h):
					guard_shifts_found.append(h)
				_update_shift_bars()
			elif special_type == "sniper_shift":
				var h = data.get("special_hour", 0.0)
				if not sniper_shifts_found.has(h):
					sniper_shifts_found.append(h)
				_update_shift_bars()
			
			var hl = inspect_highlight_rects.get(area, null)
			if is_instance_valid(hl):
				hl.visible = false
			inspect_targets.erase(area)
			return

func _show_inspect_text(title: String, phrase: String, journal: String) -> void:
	if not inspect_text_panel or not inspect_text_label:
		return
	inspect_text_panel.visible = true
	inspect_text_label.text = "[b]" + title + "[/b]\n" + phrase

func _add_journal_note(id: String, text: String) -> void:
	if not journal_notes.has(id):
		journal_notes.append(id)
		journal_notes_full[id] = text
		if inspect_journal_notice:
			inspect_journal_notice.text = "Открылась новая пометка в журнале"
			inspect_journal_notice.visible = true
			inspect_notice_timer = 3.0
		_check_scout_achievement()

func _check_scout_achievement() -> void:
	# Разведчик — все 13 зон осмотра
	if journal_notes.size() >= 13:
		if has_node("/root/Achievements"):
			var was = Achievements.scout_unlocked
			Achievements.unlock_scout()
			if not was:
				_show_scout_achievement()

func _open_journal() -> void:
	if current_shift < 2:
		return
	journal_open = true
	journal_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_update_journal_options()

func _on_journal_close() -> void:
	journal_open = false
	journal_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _update_journal_options() -> void:
	for c in journal_list.get_children():
		c.queue_free()
	
	_add_journal_line("=== ЗАПИСИ ===", Color.BLACK, 18)
	_add_journal_line("", Color.BLACK, 14)
	
	if journal_notes_full.size() > 0:
		_add_journal_line("ОСМОТРЕНО:", Color.BLACK, 16)
		for id in journal_notes_full.keys():
			_add_journal_line("   " + journal_notes_full[id], Color.DARK_GRAY, 14)
		_add_journal_line("", Color.BLACK, 14)
	
	# Если собраны все 6 смен — большая надпись
	if guard_shifts_found.size() >= 3 and sniper_shifts_found.size() >= 3:
		_add_journal_line("", Color.BLACK, 14)
		if elevator_inspected:
			_add_journal_line(">>> 13:00 - 13:15 ЕДИНСТВЕННОЕ ВРЕМЯ ДЛЯ ПОБЕГА ЧЕРЕЗ ЛИФТ <<<",
				Color.DARK_RED, 20)
		else:
			_add_journal_line(">>> 13:00 - 13:15 ЕДИНСТВЕННОЕ ВРЕМЯ ДЛЯ ПОБЕГА <<<",
				Color.DARK_RED, 20)

func _add_journal_line(text: String, color: Color, font_size: int) -> void:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	journal_list.add_child(l)

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
		var target_pos = guard_rect.global_position + Vector2(150, -50)
		if camera.enabled:
			camera.enabled = false
		guard_camera.global_position = player.global_position
		guard_camera.enabled = true
		
		var tw = create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(guard_camera, "global_position", target_pos, 0.5)
	
	await get_tree().create_timer(duration).timeout
	dialog_panel.visible = false
	is_dialog_active = false
	
	if camera and guard_camera:
		var tw2 = create_tween()
		tw2.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tw2.tween_property(guard_camera, "global_position", player.global_position, 0.5)
		await tw2.finished
		guard_camera.enabled = false
		camera.enabled = true
		camera.global_position = player.global_position

func _toggle_pause() -> void:
	if pausemenu == null:
		return
	if pausemenu.visible:
		if pausemenu.has_method("hide_menu"):
			pausemenu.hide_menu()
		else:
			pausemenu.visible = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		pausemenu.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event: InputEvent) -> void:
	if state == State.INSPECT:
		if event.is_action_pressed("interact"):
			if state == State.MINIGAME and minigame_active:
				_press_button()
				get_viewport().set_input_as_handled()
				return
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_process_inspect_click(event.position)
				get_viewport().set_input_as_handled()
				return
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_I or event.keycode == KEY_ESCAPE:
				_exit_inspect()
				get_viewport().set_input_as_handled()
				return
		return
	
	if event.is_action_pressed("interact"):
		if state == State.MINIGAME and minigame_active:
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

func _near_elevator() -> bool:
	if player == null or elevator_door == null:
		return false
	return player.global_position.distance_to(elevator_door.global_position) < 150

func _enter_elevator() -> void:
	var hour = _current_hour()
	var in_window = hour >= ESCAPE_WINDOW_START and hour <= ESCAPE_WINDOW_END
	
	if not in_window:
		_show_dialog("ЛИФТ ЗАКРЫТ. НУЖНО ДОЖДАТЬСЯ 13:00.", 2.5)
		return
	
	if guard_shifts_found.size() < 3 or sniper_shifts_found.size() < 3:
		_show_dialog("Я НЕ ЗНАЮ РАСПИСАНИЯ. НУЖНО БОЛЬШЕ РАЗВЕДКИ.", 2.5)
		return
	
	if has_node("/root/Achievements"):
		var was = Achievements.freedom_unlocked
		Achievements.unlock_freedom()
		if not was:
			_show_freedom_achievement()
	_show_dialog("ПОБЕГ...", 1.5)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act3HallwayLevel.tscn")

func _show_worker_of_month_achievement() -> void:
	_show_achievement_banner("Работник месяца")

func _show_scout_achievement() -> void:
	_show_achievement_banner("Разведчик")

func _show_freedom_achievement() -> void:
	_show_achievement_banner("Свобода")

func _show_achievement_banner(title: String) -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	add_child(canvas)
	
	var ctrl = Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ctrl)
	
	var view_size = get_viewport().get_visible_rect().size
	var bg = ColorRect.new()
	bg.color = Color(0.35, 0.15, 0.1, 0.85)
	bg.size = Vector2(320, 60)
	bg.position = Vector2(view_size.x, 10)
	ctrl.add_child(bg)
	
	var icon = Label.new()
	icon.text = "★"
	icon.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	icon.add_theme_font_size_override("font_size", 28)
	icon.position = Vector2(view_size.x + 15, 20)
	icon.size = Vector2(40, 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ctrl.add_child(icon)
	
	var header = Label.new()
	header.text = "ДОСТИЖЕНИЕ"
	header.add_theme_color_override("font_color", Color(1, 0.7, 0.5, 0.9))
	header.add_theme_font_size_override("font_size", 18)
	header.position = Vector2(view_size.x + 65, 18)
	ctrl.add_child(header)
	
	var l = Label.new()
	l.text = title
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	l.add_theme_font_size_override("font_size", 36)
	l.position = Vector2(view_size.x + 65, 35)
	ctrl.add_child(l)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(bg, "position:x", view_size.x - 330, 0.4)
	tween.parallel().tween_property(icon, "position:x", view_size.x - 305, 0.4)
	tween.parallel().tween_property(header, "position:x", view_size.x - 255, 0.4)
	tween.parallel().tween_property(l, "position:x", view_size.x - 255, 0.4)
	
	await get_tree().create_timer(3.5).timeout
	
	var tween2 = create_tween()
	tween2.set_ease(Tween.EASE_IN)
	tween2.tween_property(bg, "position:x", view_size.x, 0.3)
	tween2.parallel().tween_property(icon, "position:x", view_size.x + 15, 0.3)
	tween2.parallel().tween_property(header, "position:x", view_size.x + 65, 0.3)
	tween2.parallel().tween_property(l, "position:x", view_size.x + 65, 0.3)
	await tween2.finished
	
	canvas.queue_free()
