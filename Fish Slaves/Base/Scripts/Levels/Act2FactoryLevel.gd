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
const REAL_SHIFT_DURATION: float = 180.0

const GUARD_SHIFTS: Array = [9.0, 13.0, 17.0]
const SNIPER_SHIFTS: Array = [11.0, 13.0, 15.0]

# 15 игровых минут = 0.25 часа
const SHIFT_CHANGE_DURATION_HOURS: float = 0.25

const ESCAPE_WINDOW_HOURS: float = 0.5

const COLOR_GREEN := Color(0.2, 0.8, 0.3)
const COLOR_RED := Color(0.9, 0.2, 0.2)
const COLOR_YELLOW := Color(1, 0.9, 0.3)
const COLOR_BLUE := Color(0.3, 0.5, 0.8)

const GUARD_DOG_COLOR := Color(0.15, 0.35, 0.95)
const GUARD_MONKEY_COLOR := Color(0.2, 0.85, 0.3)
const SHIFT_CHANGE_COLOR := Color(1.0, 0.9, 0.3)

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

var visited_zones: Array = []
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

# Уже сделанные пометки — их ID
var completed_inspect_ids: Array = []

var guard_shift_bar: ProgressBar = null
var sniper_shift_bar: ProgressBar = null
var guard_shift_label: Label = null
var sniper_shift_bar_label: Label = null

var journal_notes: Array = []

func _ready() -> void:
	randomize()
	
	_disable_actions_for_act2()
	
	if player:
		player.dash_cooldown = 999999.0
		player.block_click_attack = true
	
	if guard_rect:
		guard_rect.color = GUARD_DOG_COLOR
	guard_is_dog = true
	
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
	_add_inspect_target("clock", Vector2(576, 80), Vector2(120, 60),
		"Часы", "Сколько я тут?", "Смена длится 10 часов")
	_add_inspect_target("elevator", Vector2(1230, 325), Vector2(100, 120),
		"Лифт", "Стоит попробовать..", "Лифт из которого приходят охранники")
	_add_inspect_target("sniper", Vector2(1060, 60), Vector2(120, 80),
		"Снайпер-Голубь", "Снайпер, который может пристрелить меня когда угодно..",
		"Снайпер-Голубь в меха костюме. Имеет крылья винтовку и пистолет")
	_add_inspect_target("guard_rect", Vector2(-215, 310), Vector2(80, 80),
		"Охранник", "Человекоподобные тоже с ними..",
		"Охранник-Обезьяна в меха костюме. Имеет массивный меха хвост")
	_add_inspect_target("conveyor", Vector2(400, 400), Vector2(200, 60),
		"Конвейер", "Сколько еще таких заводов они построили?",
		str(TOTAL_OBJECTS) + " коробок за смену")
	_add_inspect_target("workers", Vector2(480, 344), Vector2(500, 80),
		"Рабочие", "Такие же как я, делают чёртовы суши..",
		"5 Рабочих-Рыб в меха костюмах")

func _add_inspect_target(id: String, pos: Vector2, size: Vector2, title: String, phrase: String, journal: String) -> void:
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
	}
	
	var hl = ColorRect.new()
	hl.name = "Highlight_" + id
	hl.color = Color(0.3, 0.7, 1.0, 0.25)
	hl.offset_left = pos.x - size.x / 2.0
	hl.offset_top = pos.y - size.y / 2.0
	hl.offset_right = pos.x + size.x / 2.0
	hl.offset_bottom = pos.y + size.y / 2.0
	hl.z_index = 2
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hl.visible = false
	add_child(hl)
	inspect_highlight_rects[area] = hl

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
	inspect_camera_offset += dir * 300 * delta
	inspect_camera_offset.x = clamp(inspect_camera_offset.x, -600, 600)
	inspect_camera_offset.y = clamp(inspect_camera_offset.y, -400, 400)
	camera.global_position = inspect_camera_original_pos + inspect_camera_offset

func _process_shift_end_npcs(delta: float) -> void:
	if state != State.SHIFT_END:
		return
	shift_end_npc_timer += delta
	for i in range(npc_fishes.size()):
		var fish = npc_fishes[i
