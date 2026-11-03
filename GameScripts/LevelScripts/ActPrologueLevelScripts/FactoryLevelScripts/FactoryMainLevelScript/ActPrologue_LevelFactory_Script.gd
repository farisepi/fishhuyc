extends Node2D

const TOTAL_OBJECTS: int = 25
const NUM_NPC_FISHES: int = 4
const AUTO_OBJECTS: int = 3

const CONVEYOR_Y: float = 386.0
const FISH_START_X: float = 326.0
const FISH_SPACING: float = 170.0
## NPC workers stand this far left of their stop zone, so the press foot (above the box) does not overlap them.
## Each fish stands right of its press and punches the red button on the press cabinet.
const NPC_PRESS_OFFSET_X: float = 80.5
## Red button on the press cabinet, in press texture pixels from the sprite centre.
const PRESS_BUTTON_LOCAL := Vector2(6, 4.5)
const PLAYER_TURN_X: float = 236.5   # player stop 156 + 80.5: at the button of the press
const OBJECT_SPAWN_X: float = 1000.0
const OBJECT_DESPAWN_X: float = -700.0
## y of the conveyor belt surface (objects stand on it, the press foot comes down to OBJECT top)
const BELT_SURFACE_Y: float = 345.0
const OBJECT_SIZE: Vector2 = Vector2(30.0, 24.0)

## Sushi line: every press adds one step, the player's press packs the set into a box.
##   0 bamboo mat on a board -> 1 nori -> 2 rice -> 3 rolled -> 4 cut -> 5 boxed
const SUSHI_TEXTURE_DIR := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactorySushiTextures/"
const SUSHI_STAGES: Array = ["Stage0_Mat", "Stage1_Nori", "Stage2_Rice", "Stage3_Roll", "Stage4_Cut", "Stage5_Box"]
const SUSHI_STAGE_PACKED: int = 5
const SUSHI_SCALE: float = 2.0
const PRESS_HOLD_TIME: float = 0.16
const Z_FOOD: int = 40          # food is drawn above everything...
const Z_FOOD_UNDER_PRESS: int = 15   # ...except while a press is moving over it
const Z_CHARACTERS: int = 25
const COLOR_BROKEN_TINT := Color(1.0, 0.45, 0.4)
var _sushi_textures: Array = []
var _sushi_broken_textures: Array = []

const OBJECT_SPEED: float = 375.0
const NPC_WALK_SPEED: float = 240.0
const NPC_WALK_DELAY_MIN: float = 0.5
const NPC_WALK_DELAY_MAX: float = 1.0

const SHIFT_START_HOUR: float = 8.0
const SHIFT_END_HOUR: float = 18.0
const SHIFT_DURATION_HOURS: float = 10.0
const REAL_SHIFT_DURATION: float = 150.0   # ~25 boxes; only used for the guard / sniper change pauses now

const SHIFT_CHANGE_HOURS: float = 0.25
const SHIFT_CHANGE_REAL: float = (SHIFT_CHANGE_HOURS / SHIFT_DURATION_HOURS) * REAL_SHIFT_DURATION

const GUARD_SHIFTS: Array = [9.0, 13.0, 17.0]
const SNIPER_SHIFTS: Array = [11.0, 13.0, 15.0]

const ESCAPE_WINDOW_START: float = 13.0
const ESCAPE_WINDOW_END: float = 13.25

const COLOR_GREEN := Color(0.2, 0.8, 0.3)
const COLOR_RED := Color(0.9, 0.2, 0.2)
const COLOR_YELLOW := Color(1, 0.9, 0.3)
const COLOR_BLUE := Color(0.3, 0.5, 0.8)
const COLOR_HIGHLIGHT_BLUE := Color(0.3, 0.7, 1.0, 0.25)
const COLOR_HIGHLIGHT_YELLOW := Color(1.0, 0.9, 0.3, 0.35)

const GUARD_DOG_COLOR := Color(0.4, 0.6, 1.0)
const GUARD_MONKEY_COLOR := Color(0.5, 1.0, 0.5)
const SNIPER_NORMAL_COLOR := Color(0.7, 0.85, 1.0)

const GUARD_POSITION := Vector2(-215, 310)
const GUARD_LIFT_POSITION := Vector2(-290, 325)
const SNIPER_POSITION := Vector2(1060, 60)
const GUARD_WALK_SPEED: float = 200.0

const BOX_TEXTURE_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryTilesetTextures/ActPrologue_LevelFactory_TileSet_Box_Texture.png"

const PLAYER_ZONE_CENTER := Vector2(236.5, 386.0)
const PLAYER_ZONE_SIZE := Vector2(80.0, 120.0)

const ACT2_DISABLED_ACTIONS := ["crouch", "block", "Parry", "inventory"]

const ACTION_STRIKE_WARNING: int = 1
const ACTION_STRIKE_DEATH: int = 2
const ACTION_STRIKE_INTERVAL: float = 1.0

const MINIGAME_SLIDER_SPEED: float = 1.0

const PROGRESSBAR_BG_PATH := "res://GameAssets/Sprites/UserInterfaceSprites/FactoryMenuSprites/FactoryMenuUITextures/FactoryProgressbarTextures/Menu_Factory_Progressbar_Empty_Texture.png"
const PROGRESSBAR_FILL_PATH := "res://GameAssets/Sprites/UserInterfaceSprites/FactoryMenuSprites/FactoryMenuUITextures/FactoryProgressbarTextures/Menu_Factory_Progressbar_Fullness_Texture.png"

const STRESS_BY_HP: Dictionary = {
	5: 0,
	4: 20,
	3: 40,
	2: 60,
	1: 80,
	0: 100,
}

const MISS_CHANCE_BY_STRESS: Dictionary = {
	0: 0.0,
	20: 1.5,
	40: 5.0,
	60: 10.0,
	80: 25.0,
	100: 50.0,
}

const NPC_MISTAKE_CHANCE: float = 0.015

const STAGE_COLORS: Array = [
	Color(0.75, 0.55, 0.25),
	Color(0.80, 0.65, 0.30),
	Color(0.85, 0.75, 0.35),
	Color(0.90, 0.85, 0.40),
]

const NPC_EYE_IDLE_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/BigEyesMechaFishFrames/NPC_MechaFish_WithBigEyes_Idle_SpriteList_Animation.png"
const NPC_EYE_JOG_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/BigEyesMechaFishFrames/NPC_MechaFish_WithBigEyes_Jogging_SpriteList_Animation.png"
const NPC_EYE_ATK_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/BigEyesMechaFishFrames/NPC_MechaFish_WithBigEyes_Attack_SpriteList_Animation.png"
const NPC_EYE_HIT_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/BigEyesMechaFishFrames/NPC_MechaFish_WithBigEyes_Hit_SpriteList_Animation.png"

const NPC_HAT_IDLE_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/FunnyHatMechaFishFrames/NPC_MechaFish_WithFunnyHat_Idle_SpriteList_Animation.png"
const NPC_HAT_JOG_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/FunnyHatMechaFishFrames/NPC_MechaFish_WithFannyHat_Jogging_SpriteList_Animation.png"
const NPC_HAT_ATK_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/FunnyHatMechaFishFrames/NPC_MechaFish_WithFunnyHat_Attack_SpriteList_Animation.png"
const NPC_HAT_HIT_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/FunnyHatMechaFishFrames/NPC_MechaFish_WithFunnyHat_Hit_SpriteList_Animation.png"

const NPC_SCAR_IDLE_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/ScarMechaFishFrames/NPC_MechaFish_WithScar_Idle_SpriteList_Animation.png"
const NPC_SCAR_JOG_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/ScarMechaFishFrames/NPC_MechaFish_WithScar_Jogging_SpriteList_Animation.png"
const NPC_SCAR_ATK_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/ScarMechaFishFrames/NPC_MechaFish_WithScar_Attack_SpriteList_Animation.png"
const NPC_SCAR_HIT_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/ScarMechaFishFrames/NPC_MechaFish_WithScar_Hit_SpriteList_Animation.png"

const NPC_NOHAND_IDLE_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/WithOutHandMechaFishFrames/NPC_MechaFish_WithOutHand_Idle_SpriteList_Animation.png"
const NPC_NOHAND_JOG_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/WithOutHandMechaFishFrames/NPC_MechaFish_WithOutHand_Jogging_SpriteList_Animation.png"
const NPC_NOHAND_ATK_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/WithOutHandMechaFishFrames/NPC_MechaFish_WithOutHand_Attack_SpriteList_Animation.png"
const NPC_NOHAND_HIT_PATH := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/WithOutHandMechaFishFrames/NPC_MechaFish_WithOutHand_Hit_SpriteList_Animation.png"

const NPC_IDLE_FRAMES: int = 16
const NPC_JOG_FRAMES: int = 12
const NPC_ATK_FRAMES_PER_SIDE: int = 8
const NPC_ATK_FRAMES_NOHAND: int = 8
const NPC_HIT_FRAMES: int = 10

const NPC_IDENTITY_ORDER: Array = ["hat", "scar", "eye", "nohand"]

const NPC_IDENTITY_DATA: Dictionary = {
	"hat": {
		"title": "Рабочий-Рыба (Шапка)",
		"phrase": "Он туповат. Никогда не снимает свою шапку. Ученые зовут его Никита, интересно, почему?",
		"journal": "Рабочий-Рыба в меха костюме. Илистый Прыгун. Носит дебильную шапку",
	},
	"scar": {
		"title": "Рабочий-Рыба (Шрам)",
		"phrase": "Интересно, как он получил свой шрам?",
		"journal": "Рабочий-Рыба в меха костюме. Илистый Прыгун. Имеет шрам около глаза",
	},
	"eye": {
		"title": "Рабочий-Рыба (Глаза)",
		"phrase": "Он выглядит забавно",
		"journal": "Рабочий-Рыба в меха костюме. Илистый Прыгун. Имеет большие глаза",
	},
	"nohand": {
		"title": "Рабочий-Рыба (Без руки)",
		"phrase": "Бедолага..",
		"journal": "Рабочий-Рыба в меха костюме. Илистый Прыгун. Без руки.",
	},
}

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var camera: Camera2D = player.get_node_or_null("MechaFishCameraFactory") if player else null
@onready var player_sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") if player else null
@onready var player_gui: CanvasLayer = player.get_node_or_null("GUI") if player else null
@onready var objects_layer: Node2D = $Objects
@onready var npc_fishes: Array[Node] = [$NPCParent/Fish1, $NPCParent/Fish2, $NPCParent/Fish3, $NPCParent/Fish4]
@onready var elevator_door: ColorRect = $Elevator
@onready var maintenance_door: ColorRect = $MaintenanceRoom

@onready var stop_zones: Array[Area2D] = [$StopZone1, $StopZone2, $StopZone3, $StopZone4, $StopZonePlayer]

@onready var elevator_button: Sprite2D = $ElevatorButton
@onready var elevator_back: AnimatedSprite2D = $ElevatorBack
@onready var elevator_front: AnimatedSprite2D = $ElevatorFront
@onready var guard_sprite: AnimatedSprite2D = $GuardSprite
@onready var sniper_sprite: AnimatedSprite2D = $SniperSprite
@onready var presses: Array[AnimatedSprite2D] = [$Press1, $Press2, $Press3, $Press4, $PressPlayer]

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
@onready var minigame_slider: TextureRect = $UI/MinigamePanel/Track/Slider
@onready var minigame_zone: Control = $UI/MinigamePanel/Track/Zone

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
var _guard_busy: bool = false
var current_object_index: int = 0
var _box_processed_zones: Array = []

var finished_boxes: Array = []
var broken_boxes: Array = []

## ---- belt pipeline: several sushi ride the belt at once ----
## The belt moves one press forward, stops, every press with food on it works at the same
## time, then the belt moves on. Slot 0 = just spawned, 1..4 = presses, 5 = packing.
const BELT_PACK_SLOT: int = 5
const TOTAL_CYCLES: int = TOTAL_OBJECTS + BELT_PACK_SLOT - 1   # the 25th box is packed in the last cycle
const SLOT_STATION := {1: 3, 2: 2, 3: 1, 4: 0, 5: 4}
var belt_items: Array = []        # Dictionaries: node, index, slot, broken, done
var _belt_gen: int = 0
var _belt_move_left: float = 0.0
var _cycles_done: int = 0
var _spawned: int = 0
var _resolved: int = 0
var _jobs_left: int = 0
var _jobs_total: int = 0
var _player_item = null
signal belt_moved
signal jobs_done
signal player_job_finished

## ---- movement penalty ----
const PENALTY_MOVE_TIME: float = 0.9      # walking away from the station this long = strike
const PENALTY_IDLE_TIME: float = 1.3      # standing still after the shift this long = strike
const STRIKE_FORGIVE_TIME: float = 30.0   # a clean half minute forgives one strike
var _strike_forgive: float = 0.0

## ---- speech bubbles (same look as the aquarium dialogs) ----
const DIALOG_BOX_PATH := "res://GameAssets/Sprites/UserInterfaceSprites/AquariumMenuUITextures/DialogBoxTextures/DialogBox_NinePath_Texture.png"
const DIALOG_FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
const BUBBLE_MAX_W: float = 150.0
const BUBBLE_FONT: int = 8
const BUBBLE_CPS: float = 38.0
const NAME_GUARD := "ОХРАНА"
const NAME_PLAYER := "ТЫ"
const COLOR_NAME_GUARD := Color(1.0, 0.45, 0.35)
const COLOR_NAME_PLAYER := Color(0.45, 0.85, 0.95)
var _bubble: Node2D = null
var _bubble_gen: int = 0

var correct_count: int = 0
var wrong_count: int = 0
var action_strike_count: int = 0
var action_move_timer: float = 0.0

var slider_pos: float = 0.0
var slider_dir: float = 1.0
var minigame_active: bool = false
## Station the player works at this shift: 0..3 = presses 1..4 (nori, rice, roll, cut ...
## in belt order 3,2,1,0), 4 = packing. The fish of that press goes to packing instead.
const STATION_PACK: int = 4
const RING_TARGET: float = 30.0
var player_station: int = STATION_PACK
var _mg_station: int = STATION_PACK
enum MG { SLIDER, LOCK, GAUGE, RING, CUT }
## station -> minigame: press 4 lays nori, 3 doses rice, 2 rolls, 1 cuts, packing = slider
const STATION_MINIGAME := {3: MG.LOCK, 2: MG.GAUGE, 1: MG.RING, 0: MG.CUT, 4: MG.SLIDER}
const STATION_TITLE := {3: "НОРИ: ЗАМОК ПОДАЧИ", 2: "РИС: ДАВЛЕНИЕ", 1: "СКРУТКА РОЛЛА", 0: "НАРЕЗКА", 4: "УПАКОВКА"}
var mg_ring_r: float = 80.0
var mg_ring_speed: float = 60.0
var mg_hits: int = 0
var mg_hits_need: int = 3
var mg_knife: float = 0.0
var mg_marks: Array = []
var mg_kind: int = MG.SLIDER
var mg_time: float = 0.0
var mg_angle: float = 0.0
var mg_dir: float = 1.0
var mg_speed: float = 2.6
var mg_pins: Array = []
var mg_pin_half: float = 0.3
var mg_pin_index: int = 0
var mg_timeout: float = 6.0
var mg_level: float = 0.0
var mg_vel: float = 0.0
var mg_band: Vector2 = Vector2(0.6, 0.75)
var _mg_canvas: Control = null
var _mg_title: Label = null
var _mg_flash: float = 0.0
var _mg_flash_good: bool = true
var _mg_trail: Array = []
## Minigame window (own textures): 40x10 window drawn 8x, the green zone and the slider move
## inside its 36 px wide inner area.
const MG_SCALE: float = 5.0
const TRACK_X0: float = 10.0
const TRACK_WIDTH: float = 180.0
const MG_WINDOW_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryMiniGameTextures/ActPrologue_LevelFactory_MiniGame_Window_Texture.png"
const MG_ZONE_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryMiniGameTextures/ActPrologue_LevelFactory_MiniGame_Zone_Texture.png"
const MG_SLIDER_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryMiniGameTextures/ActPrologue_LevelFactory_MiniGame_Slider_Texture.png"
## HUD: done / failed boxes, stress and shift counters are all segmented bars made of the
## level's progressbar textures (hazard frame + green / red segments).
const BAR_GOOD_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryProgressbarTextures/ActPrologue_LevelFactory_Progressbar_Fullness_Good_Texture.png"
const BAR_BAD_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryProgressbarTextures/ActPrologue_LevelFactory_Progressbar_Fullness_Bad_Texture.png"
const SMALL_FRAME_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryProgressbarTextures/ActPrologue_LevelFactory_Progressbar_Small_Empty_Texture.png"
const BAR_CALM_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryProgressbarTextures/ActPrologue_LevelFactory_Progressbar_Fullness_Calm_Texture.png"
const BAR_ALARM_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryProgressbarTextures/ActPrologue_LevelFactory_Progressbar_Fullness_Alarm_Texture.png"
const BAR_INFO_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryProgressbarTextures/ActPrologue_LevelFactory_Progressbar_Fullness_Info_Texture.png"
const CLOCK_FRAME_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryProgressbarTextures/ActPrologue_LevelFactory_HUD_ClockFrame_Texture.png"
const STRESS_FRAME_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryProgressbarTextures/ActPrologue_LevelFactory_Progressbar_Stress_Empty_Texture.png"
const STRESS_FILL_PATH := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryProgressbarTextures/ActPrologue_LevelFactory_Progressbar_Stress_Fullness_Texture.png"
const HUD_SCALE: float = 1.5
const HUD_CELL: float = 12.0
const HUD_X0: float = 346.0
const HUD_FONT := 13
const ZONE_LIGHT_H: float = 26.0
const SAFE_ZONE_SHADER := "res://GameShaders/SharedShaders/Shared_SafeZone_Shader.gdshader"
const OUTLINE_SHADER := "res://GameShaders/SharedShaders/Shared_Outline_Shader.gdshader"
## Enemy placeholder sheets (guard = mecha dog / mecha monkey, sniper = mecha pigeon)
const EN_DIR := "res://GameAssets/Sprites/EntitySprites/EnemySprites/"
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
var maintenance_safe_zone_rect: ColorRect = null

var shift_end_npc_timer: float = 0.0
var npc_walk_delays: Array = []
var follow_strike_timer: float = 0.0

var inspect_camera_offset: Vector2 = Vector2.ZERO
var inspect_vignette: ColorRect = null
var low_hp_vignette: ColorRect = null
var _low_hp_pulse_time: float = 0.0
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

var guard_shift_bar: Control = null
var sniper_shift_bar: Control = null
var guard_shift_label: Label = null
var sniper_shift_bar_label: Label = null

var journal_notes: Array = []
var journal_notes_full: Dictionary = {}
var elevator_inspected: bool = false

var stress_level: int = 0
var stress_bar: Control = null
var stress_label: Label = null
var stress_title: Label = null
var _stress_pulse_time: float = 0.0
var _progress_cells: Control = null
var _hud_labels: Array = []
var _clock_hands: Array = []   # [hour_hand, minute_hand]
var _hud_on: bool = true
var _hud_nodes: Array = []
var _clock_lcd: Control = null
var _clock_text: String = "08:00"
var _stress_shown: float = 0.0
var _outline_nodes: Dictionary = {}   # inspect area -> Array of CanvasItems with the outline shader
var _guard_frames_dog: SpriteFrames = null
var _guard_frames_monkey: SpriteFrames = null

var npc_identities: Dictionary = {}
var escape_info_shift: int = -1

var player_zone_center: Vector2 = PLAYER_ZONE_CENTER
var player_turn_x: float = PLAYER_TURN_X

func _ready() -> void:
	randomize()
	
	if is_instance_valid(Fade) and Fade.has_method("fade_in"):
		Fade.fade_in()
	
	_disable_actions_for_act2()
	
	if player:
		player.dash_cooldown = 999999.0
		player.block_click_attack = true
	
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
	_create_maintenance_safe_zone()
	_create_vignette()
	_create_hud()
	_create_shift_bars()
	_create_stress_bar()
	_build_minigame_bar()
	_setup_wall_clock()
	_setup_press_buttons()
	# shift 1: no interface until the accident on the 4th box
	_set_hud_visible(false)
	if player:
		player.position.x = PLAYER_TURN_X
		_face_player_to_press()
	_setup_enemy_sprites()
	# draw order: presses 16 < fish / player / guard 25 < conveyor 30 < food 40
	# (the food drops to 15 - behind the press - only while a press is moving)
	if player:
		player.z_index = Z_CHARACTERS
	if guard_sprite:
		guard_sprite.z_index = Z_CHARACTERS
	for f in npc_fishes:
		if f:
			f.z_index = Z_CHARACTERS
	_assign_npc_identities()
	_create_inspect_targets()
	_create_inspect_text_panel()
	_setup_guard_camera()
	_ensure_death_screen()
	
	for z in stop_zones:
		if z:
			z.visible = false
	
	for press in presses:
		if press and press.sprite_frames and press.sprite_frames.has_animation("press_down"):
			# first frame of press_down = the press fully raised
			press.stop()
			press.animation = "press_down"
			press.frame = 0
			press.stop()
	
	if elevator_back and elevator_back.sprite_frames and elevator_back.sprite_frames.has_animation("close"):
		elevator_back.animation = "close"
		elevator_back.frame = elevator_back.sprite_frames.get_frame_count("close") - 1
		elevator_back.stop()
	if elevator_front and elevator_front.sprite_frames and elevator_front.sprite_frames.has_animation("close"):
		elevator_front.animation = "close"
		elevator_front.frame = elevator_front.sprite_frames.get_frame_count("close") - 1
		elevator_front.stop()
	
	bind_hint_i.visible = false
	bind_hint_j.visible = false
	escape_hint.visible = false
	journal_panel.visible = false
	inspect_overlay.visible = false
	minigame_panel.visible = false
	hint_label.visible = false
	dialog_panel.visible = false
	inspect_marker.visible = false
	
	if fade_rect:
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
	
	if player:
		for child in player.get_children():
			if child is Camera2D:
				child.enabled = (child == camera)
	
	if camera:
		camera.enabled = true
		camera.top_level = true
		camera.global_position = player.global_position if player else Vector2.ZERO
		camera.offset = Vector2.ZERO
		inspect_camera_original_zoom = camera.zoom
	
	if player_sprite and player_sprite.sprite_frames.has_animation("Idle"):
		player_sprite.play("Idle")
	
	intro_timer = 0.0
	state = State.INTRO

func _get_stop_zone_x(index: int) -> float:
	if index < 0 or index >= stop_zones.size():
		return FISH_START_X + index * FISH_SPACING
	var z = stop_zones[index]
	if z == null:
		return FISH_START_X + index * FISH_SPACING
	return z.global_position.x

func _is_box_in_zone(index: int, box_pos: Vector2, box_size: Vector2) -> bool:
	if _box_processed_zones.has(index):
		return false
	if index < 0 or index >= stop_zones.size():
		return false
	var z = stop_zones[index]
	if z == null:
		return false
	var zone_pos = z.global_position
	var zone_size = Vector2(40, 40)
	var col = z.get_node_or_null("CollisionShape2D")
	if col and col.shape is RectangleShape2D:
		zone_size = col.shape.size * col.scale
	# objects move left along the belt: the box has arrived once its centre reaches the zone centre
	return box_pos.x <= zone_pos.x

func _add_sliced_frames(frames: SpriteFrames, anim_name: String, tex: Texture2D, total_in_sheet: int, start_index: int, count: int, loop: bool, speed: float) -> void:
	if frames.has_animation(anim_name):
		return
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)
	var fw = tex.get_width() / float(total_in_sheet)
	var fh = tex.get_height()
	for i in range(count):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2((start_index + i) * fw, 0, fw, fh)
		frames.add_frame(anim_name, atlas)

func _npc_identity_paths(identity: String) -> Dictionary:
	match identity:
		"eye":
			return {"idle": NPC_EYE_IDLE_PATH, "jog": NPC_EYE_JOG_PATH, "atk": NPC_EYE_ATK_PATH, "hit": NPC_EYE_HIT_PATH, "atk_total": NPC_ATK_FRAMES_PER_SIDE * 2}
		"hat":
			return {"idle": NPC_HAT_IDLE_PATH, "jog": NPC_HAT_JOG_PATH, "atk": NPC_HAT_ATK_PATH, "hit": NPC_HAT_HIT_PATH, "atk_total": NPC_ATK_FRAMES_PER_SIDE * 2}
		"scar":
			return {"idle": NPC_SCAR_IDLE_PATH, "jog": NPC_SCAR_JOG_PATH, "atk": NPC_SCAR_ATK_PATH, "hit": NPC_SCAR_HIT_PATH, "atk_total": NPC_ATK_FRAMES_PER_SIDE * 2}
		"nohand":
			return {"idle": NPC_NOHAND_IDLE_PATH, "jog": NPC_NOHAND_JOG_PATH, "atk": NPC_NOHAND_ATK_PATH, "hit": NPC_NOHAND_HIT_PATH, "atk_total": NPC_ATK_FRAMES_NOHAND}
		_:
			return {}

func _build_npc_identity_frames(identity: String) -> SpriteFrames:
	var frames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var paths = _npc_identity_paths(identity)
	if paths.is_empty():
		return frames
	var idle_tex = load(paths["idle"])
	if idle_tex:
		_add_sliced_frames(frames, "idle", idle_tex, NPC_IDLE_FRAMES, 0, NPC_IDLE_FRAMES, true, 10.0)
	var jog_tex = load(paths["jog"])
	if jog_tex:
		_add_sliced_frames(frames, "jogging", jog_tex, NPC_JOG_FRAMES, 0, NPC_JOG_FRAMES, true, 12.0)
	var atk_tex = load(paths["atk"])
	if atk_tex:
		var atk_total = int(paths["atk_total"])
		if identity == "nohand":
			_add_sliced_frames(frames, "AttackLeft", atk_tex, atk_total, 0, atk_total, false, 14.0)
		else:
			_add_sliced_frames(frames, "AttackRight", atk_tex, atk_total, 0, NPC_ATK_FRAMES_PER_SIDE, false, 14.0)
			_add_sliced_frames(frames, "AttackLeft", atk_tex, atk_total, NPC_ATK_FRAMES_PER_SIDE, NPC_ATK_FRAMES_PER_SIDE, false, 14.0)
	if paths.has("hit"):
		var hit_tex = load(paths["hit"])
		if hit_tex:
			_add_sliced_frames(frames, "hit", hit_tex, NPC_HIT_FRAMES, 0, NPC_HIT_FRAMES, false, 14.0)
	return frames

func _assign_npc_identities() -> void:
	npc_identities.clear()
	for i in range(npc_fishes.size()):
		var fish = npc_fishes[i]
		if fish == null:
			continue
		var identity = NPC_IDENTITY_ORDER[i % NPC_IDENTITY_ORDER.size()]
		npc_identities[fish] = identity
		if fish is AnimatedSprite2D:
			var frames = _build_npc_identity_frames(identity)
			fish.sprite_frames = frames
			if frames.has_animation("idle"):
				fish.play("idle")

## ---------------------------------------------------------------- guard / sniper sprites
func _sheet_frames(frames: SpriteFrames, anim_name: String, path: String, count: int, loop: bool, speed: float, start: int = 0, total: int = -1) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex = load(path)
	if tex == null:
		return
	_add_sliced_frames(frames, anim_name, tex, total if total > 0 else count, start, count, loop, speed)


func _build_guard_frames(dog: bool) -> SpriteFrames:
	var f = SpriteFrames.new()
	if f.has_animation("default"):
		f.remove_animation("default")
	var sp = "MechaDog" if dog else "MechaMonkey"
	_sheet_frames(f, "idle", EN_DIR + sp + "Sprites/" + sp + "IdleFrames/Enemy_" + sp + "_Idle_SpriteList_Animation.png", 16, true, 10.0)
	_sheet_frames(f, "jogging", EN_DIR + sp + "Sprites/" + sp + "RunFrames/Enemy_" + sp + "_Run_SpriteList_Animation.png", 8, true, 14.0)
	_sheet_frames(f, "attack_right", EN_DIR + sp + "Sprites/" + sp + "AttackFrames/Enemy_" + sp + "_Attack_SpriteList_Animation.png", 8, false, 16.0, 0, 16)
	_sheet_frames(f, "attack_left", EN_DIR + sp + "Sprites/" + sp + "AttackFrames/Enemy_" + sp + "_Attack_SpriteList_Animation.png", 8, false, 16.0, 8, 16)
	return f


func _setup_enemy_sprites() -> void:
	_guard_frames_dog = _build_guard_frames(true)
	_guard_frames_monkey = _build_guard_frames(false)
	_apply_guard_frames()
	if sniper_sprite:
		var f = SpriteFrames.new()
		if f.has_animation("default"):
			f.remove_animation("default")
		var p = EN_DIR + "MechaPigeonSprites/MechaPigeon"
		_sheet_frames(f, "idle", p + "IdleAimFrames/Enemy_MechaPigeon_IdleAim_SpriteList_Animation.png", 16, true, 10.0)
		_sheet_frames(f, "fire", p + "AimFireReloadFrames/Enemy_MechaPigeon_AimFireReload_SpriteList_Animation.png", 12, false, 12.0)
		if f.has_animation("idle"):
			sniper_sprite.sprite_frames = f
			sniper_sprite.flip_h = true   # the balcony sniper looks left, at the workers
			sniper_sprite.modulate = Color.WHITE
			sniper_sprite.play("idle")


func _apply_guard_frames() -> void:
	if guard_sprite == null:
		return
	var f = _guard_frames_dog if guard_is_dog else _guard_frames_monkey
	if f == null or not f.has_animation("idle"):
		return
	guard_sprite.sprite_frames = f
	guard_sprite.modulate = Color.WHITE
	guard_sprite.play("idle")

func _elevator_play(anim_name: String) -> void:
	if elevator_back:
		elevator_back.play(anim_name)
	if elevator_front:
		elevator_front.play(anim_name)

func _await_elevator_anim(anim_name: String) -> void:
	_elevator_play(anim_name)
	if elevator_back and elevator_back.sprite_frames and elevator_back.sprite_frames.has_animation(anim_name):
		await elevator_back.animation_finished
	else:
		await get_tree().create_timer(13.0 / 14.0).timeout

func _guard_walk_to(target: Vector2) -> void:
	if guard_sprite == null:
		return
	if target.x < guard_sprite.position.x:
		guard_sprite.scale.x = -abs(guard_sprite.scale.x)
	elif target.x > guard_sprite.position.x:
		guard_sprite.scale.x = abs(guard_sprite.scale.x)
	if guard_sprite.sprite_frames.has_animation("jogging"):
		guard_sprite.play("jogging")
	else:
		guard_sprite.play("idle")
	var dist = guard_sprite.position.distance_to(target)
	var duration = dist / GUARD_WALK_SPEED
	if duration < 0.1:
		duration = 0.1
	var tween = create_tween()
	tween.tween_property(guard_sprite, "position", target, duration)
	await tween.finished

func _ensure_death_screen() -> void:
	var ds = get_node_or_null("DeathScreen")
	if ds == null:
		var death_scene = load("res://GameScenes/MenuScenes/FactoryMenuScenes/FactoryDeathScreenScene/Menu_Factory_DeathScreen_Scene.tscn")
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
	for sp in conveyor_sprites:
		sp.z_index = 30

func _create_conveyor_floor() -> void:
	conveyor_floor_rect = ColorRect.new()
	conveyor_floor_rect.name = "ConveyorFloor"
	conveyor_floor_rect.color = Color(0.15, 0.15, 0.2, 1)
	conveyor_floor_rect.offset_left = -600.0
	conveyor_floor_rect.offset_top = 416.0
	conveyor_floor_rect.offset_right = 2000.0
	conveyor_floor_rect.offset_bottom = 446.0
	conveyor_floor_rect.z_index = 25
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

func _create_maintenance_safe_zone() -> void:
	maintenance_safe_zone_rect = ColorRect.new()
	maintenance_safe_zone_rect.name = "MaintenanceSafeZone"
	maintenance_safe_zone_rect.color = Color(0.25, 1.0, 0.45, 0.8)
	maintenance_safe_zone_rect.z_index = 1
	maintenance_safe_zone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center = Vector2(1230, 325)
	var size = Vector2(170, ZONE_LIGHT_H)
	# a light pool on the floor (y 380), nothing above it
	maintenance_safe_zone_rect.offset_left = center.x - size.x / 2.0
	maintenance_safe_zone_rect.offset_top = 380.0 - size.y / 2.0
	maintenance_safe_zone_rect.offset_right = center.x + size.x / 2.0
	maintenance_safe_zone_rect.offset_bottom = 380.0 + size.y / 2.0
	_apply_zone_shader(maintenance_safe_zone_rect)
	add_child(maintenance_safe_zone_rect)

func _create_work_zone() -> void:
	work_zone_rect = ColorRect.new()
	work_zone_rect.name = "WorkZone"
	work_zone_rect.color = Color(0.3, 0.75, 1.0, 0.8)
	work_zone_rect.z_index = 1
	work_zone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_zone_shader(work_zone_rect)
	add_child(work_zone_rect)
	_update_work_zone_position()


func _apply_zone_shader(rect: ColorRect) -> void:
	var sh = load(SAFE_ZONE_SHADER)
	if sh == null:
		return
	var m = ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("strength", 0.55)
	rect.material = m
	var sz = Vector2(rect.offset_right - rect.offset_left, rect.offset_bottom - rect.offset_top)
	if sz.x > 0.0 and sz.y > 0.0:
		m.set_shader_parameter("rect_size", sz)
	rect.resized.connect(func():
		m.set_shader_parameter("rect_size", rect.size)
	)

func _update_work_zone_position() -> void:
	if work_zone_rect == null:
		return
	# a light pool on the floor under the player's spot
	var h = ZONE_LIGHT_H
	var w = PLAYER_ZONE_SIZE.x + 30.0
	work_zone_rect.offset_left = player_zone_center.x - w / 2.0
	work_zone_rect.offset_top = 380.0 - h / 2.0
	work_zone_rect.offset_right = player_zone_center.x + w / 2.0
	work_zone_rect.offset_bottom = 380.0 + h / 2.0
	if work_zone_rect.material:
		work_zone_rect.material.set_shader_parameter("rect_size", Vector2(w, h))

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
	
	low_hp_vignette = ColorRect.new()
	low_hp_vignette.name = "LowHpVignette"
	low_hp_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	low_hp_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	low_hp_vignette.z_index = 51
	low_hp_vignette.visible = false
	var pulse_shader = Shader.new()
	pulse_shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV;
	vec2 d = abs(uv - 0.5) * 2.0;
	float edge = smoothstep(0.55, 1.0, max(d.x, d.y));
	COLOR = vec4(1.0, 0.0, 0.0, edge * 0.55);
}
"""
	var pulse_mat = ShaderMaterial.new()
	pulse_mat.shader = pulse_shader
	low_hp_vignette.material = pulse_mat
	var pulse_canvas = CanvasLayer.new()
	pulse_canvas.name = "LowHpVignetteLayer"
	pulse_canvas.layer = 6
	pulse_canvas.add_child(low_hp_vignette)
	add_child(pulse_canvas)

func _update_low_hp_pulse(delta: float) -> void:
	if low_hp_vignette == null or player == null:
		return
	var hp = 0
	if player.has_method("get_hp"):
		hp = player.get_hp()
	else:
		hp = player.hp
	if hp <= 1 and hp > 0:
		low_hp_vignette.visible = true
		_low_hp_pulse_time += delta * 3.0
		var pulse = 0.5 + 0.5 * sin(_low_hp_pulse_time * PI * 2.0)
		low_hp_vignette.modulate.a = 0.12 + pulse * 0.16
	else:
		low_hp_vignette.visible = false
		_low_hp_pulse_time = 0.0

## Shows / hides the whole factory HUD (clock, box progress, stress, shift counters).
func _set_hud_visible(v: bool) -> void:
	var was = _hud_on
	_hud_on = v
	for n in _hud_nodes:
		if is_instance_valid(n):
			if v and not was:
				n.visible = true
				n.modulate.a = 0.0
				var tw = n.create_tween()
				tw.tween_property(n, "modulate:a", 1.0, 0.5)
			else:
				n.visible = v
	if clock_label:
		clock_label.visible = false   # the LCD draws the time
	_update_shift_bars()


## 7-segment LED clock: lit segments over dim "88:88" ghosts, blinking colon.
const SEG_MAP := {
	"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
	"5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg",
}

func _draw_clock_lcd() -> void:
	var c = _clock_lcd
	if c == null:
		return
	var sz = c.size
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.03, 0.035, 0.03))
	var on = Color(1.0, 0.32, 0.18)
	var glow = Color(1.0, 0.3, 0.15, 0.22)
	var off = Color(0.22, 0.07, 0.05, 0.55)
	var dh = sz.y - 6.0
	var dw = dh * 0.55
	var t = max(2.0, round(dh / 7.0))
	var gap = dw * 0.45
	var colon_w = dw * 0.5
	var total = dw * 4.0 + gap * 2.0 + colon_w + gap
	var x = (sz.x - total) / 2.0
	var y = 3.0
	var digits = _clock_text.replace(":", "")
	for i in range(4):
		var ch = digits[i] if i < digits.length() else "8"
		_draw_seg_digit(c, Vector2(x, y), dw, dh, t, "abcdefg", off, Color(0, 0, 0, 0))
		_draw_seg_digit(c, Vector2(x, y), dw, dh, t, SEG_MAP.get(ch, ""), on, glow)
		x += dw + gap * (0.5 if i != 1 else 0.5)
		if i == 1:
			var blink = int(Time.get_ticks_msec() / 500) % 2 == 0
			var col = on if blink else off
			c.draw_rect(Rect2(x + colon_w * 0.25, y + dh * 0.28, t, t), col)
			c.draw_rect(Rect2(x + colon_w * 0.25, y + dh * 0.64, t, t), col)
			x += colon_w + gap * 0.5
	# glass reflection
	c.draw_rect(Rect2(0, 0, sz.x, 2), Color(1, 1, 1, 0.05))


func _draw_seg_digit(c: Control, p: Vector2, w: float, h: float, t: float, segs: String, col: Color, glow: Color) -> void:
	var half = h / 2.0
	var rects = {
		"a": Rect2(p.x + t, p.y, w - 2 * t, t),
		"b": Rect2(p.x + w - t, p.y + t, t, half - t * 1.5),
		"c": Rect2(p.x + w - t, p.y + half + t * 0.5, t, half - t * 1.5),
		"d": Rect2(p.x + t, p.y + h - t, w - 2 * t, t),
		"e": Rect2(p.x, p.y + half + t * 0.5, t, half - t * 1.5),
		"f": Rect2(p.x, p.y + t, t, half - t * 1.5),
		"g": Rect2(p.x + t, p.y + half - t * 0.5, w - 2 * t, t),
	}
	for k in segs:
		if not rects.has(k):
			continue
		var r: Rect2 = rects[k]
		if glow.a > 0.0:
			c.draw_rect(r.grow(1.5), glow)
		c.draw_rect(r, col)


## ---------------------------------------------------------------- HUD
func _hud_label(text: String, pos: Vector2, w: float, align: int = HORIZONTAL_ALIGNMENT_LEFT, size: int = HUD_FONT) -> Label:
	var l = Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(w, 18)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.86, 0.88, 0.92))
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(l)
	return l


## A segmented bar: hazard frame + `cells` slots, each slot can be empty / good / bad.
func _make_cell_bar(bar_name: String, pos: Vector2, cells: int, frame_path: String = PROGRESSBAR_BG_PATH, tex1: String = BAR_GOOD_PATH, tex2: String = BAR_BAD_PATH) -> Control:
	var root = Control.new()
	root.name = bar_name
	root.position = pos
	root.scale = Vector2(HUD_SCALE, HUD_SCALE)
	root.size = Vector2(cells * HUD_CELL + 6.0, 12.0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.set_meta("tex1", tex1)
	root.set_meta("tex2", tex2)
	var frame = NinePatchRect.new()
	frame.texture = load(frame_path)
	frame.patch_margin_left = 3
	frame.patch_margin_right = 3
	frame.patch_margin_top = 3
	frame.patch_margin_bottom = 3
	frame.size = root.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)
	for i in range(cells):
		var c = TextureRect.new()
		c.name = "Cell%d" % i
		c.position = Vector2(3.0 + i * HUD_CELL, 3.0)
		c.size = Vector2(HUD_CELL, 6.0)
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_SCALE
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.visible = false
		root.add_child(c)
	$UI.add_child(root)
	return root


var _cell_tex_cache: Dictionary = {}

func _cell_texture(path: String) -> Texture2D:
	if _cell_tex_cache.has(path):
		return _cell_tex_cache[path]
	var a = AtlasTexture.new()
	a.atlas = load(path)
	a.region = Rect2(23, 3, HUD_CELL, 6)   # one whole segment of the strip
	_cell_tex_cache[path] = a
	return a

func _set_cell(bar: Control, index: int, kind: int) -> void:
	if bar == null:
		return
	var c = bar.get_node_or_null("Cell%d" % index) as TextureRect
	if c == null:
		return
	if int(c.get_meta("kind", 0)) == kind:
		return
	c.set_meta("kind", kind)
	c.visible = kind != 0
	if kind != 0:
		c.texture = _cell_texture(String(bar.get_meta("tex1" if kind == 1 else "tex2", BAR_GOOD_PATH)))
		c.pivot_offset = c.size / 2.0
		c.scale = Vector2(1.0, 1.6)
		var tw = c.create_tween()
		tw.tween_property(c, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fill_cells(bar: Control, count: int, cells: int, good: bool) -> void:
	for i in range(cells):
		_set_cell(bar, i, (1 if good else 2) if i < count else 0)


func _bar_width(cells: int) -> float:
	return (cells * HUD_CELL + 6.0) * HUD_SCALE


func _stress_color(level: int) -> Color:
	if level >= 60:
		return Color(1.0, 0.35, 0.3)
	if level >= 40:
		return Color(1.0, 0.8, 0.25)
	return Color(0.6, 1.0, 0.4)


func _build_minigame_bar() -> void:
	if minigame_panel == null:
		return
	var track = minigame_panel.get_node_or_null("Track") as Control
	if track:
		track.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	minigame_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# canvas for the lock and the pressure gauge variants (drawn in code)
	_mg_canvas = Control.new()
	_mg_canvas.name = "MinigameCanvas"
	_mg_canvas.position = Vector2(476, 214)
	_mg_canvas.size = Vector2(200, 200)
	_mg_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mg_canvas.visible = false
	_mg_canvas.draw.connect(_draw_minigame)
	$UI.add_child(_mg_canvas)
	_mg_title = Label.new()
	_mg_title.name = "MinigameTitle"
	_mg_title.size = Vector2(400, 24)
	_mg_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mg_title.add_theme_font_size_override("font_size", 16)
	_mg_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	_mg_title.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
	_mg_title.add_theme_constant_override("outline_size", 4)
	if hint_label:
		hint_label.add_theme_font_size_override("font_size", 16)
		hint_label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.92))
		hint_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
		hint_label.add_theme_constant_override("outline_size", 4)
	_mg_title.visible = false
	_mg_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(_mg_title)
	if minigame_slider:
		minigame_slider.z_index = 1
		minigame_slider.size.x = 9.0   # thin needle (3 texture pixels at 3x)


## Picks a minigame variant for this box and shows it.
func _start_minigame(station: int = STATION_PACK) -> void:
	state = State.MINIGAME
	minigame_active = true
	mg_time = 0.0
	_mg_flash = 0.0
	_mg_trail.clear()
	_mg_station = station
	mg_kind = STATION_MINIGAME.get(station, MG.SLIDER)
	mg_hits = 0
	minigame_panel.modulate = Color.WHITE
	_mg_canvas.modulate = Color.WHITE
	_mg_title.modulate = Color.WHITE
	minigame_panel.visible = mg_kind == MG.SLIDER
	_mg_canvas.visible = mg_kind != MG.SLIDER
	_mg_title.visible = true
	hint_label.visible = true
	var key = _key_name("interact")
	match mg_kind:
		MG.SLIDER:
			_mg_title.text = STATION_TITLE.get(station, "УПАКОВКА")
			_mg_title.position = Vector2(376, 246)
			hint_label.text = "НАЖМИ " + key + " В ЗЕЛЁНОЙ ЗОНЕ!"
			hint_label.position = Vector2(326, 324)
			zone_center = randf_range(0.3, 0.7)
			zone_width = randf_range(0.32, 0.42)
			var zw = round(TRACK_WIDTH * zone_width / MG_SCALE) * MG_SCALE
			var zx = round((TRACK_WIDTH * zone_center - zw / 2) / MG_SCALE) * MG_SCALE
			minigame_zone.size.x = zw
			minigame_zone.position.x = TRACK_X0 + zx
			slider_pos = 0.0
			slider_dir = 1.0
			minigame_slider.position.x = TRACK_X0 - minigame_slider.size.x / 2.0
		MG.LOCK:
			_mg_title.text = STATION_TITLE.get(station, "ЗАМОК")
			_mg_title.position = Vector2(376, 186)
			var pins = 2 if current_shift == 2 else 3
			mg_pins.clear()
			var a = randf() * TAU
			for i in range(pins):
				a += randf_range(1.2, 2.6) * (1 if i % 2 == 0 else -1)
				mg_pins.append(fposmod(a, TAU))
			mg_pin_index = 0
			mg_angle = -PI / 2.0
			mg_dir = 1.0 if randf() < 0.5 else -1.0
			mg_speed = 2.5 + 0.15 * current_shift
			mg_pin_half = 0.3
			mg_timeout = 3.2 * pins
			hint_label.text = key + " — КОГДА СТРЕЛКА В ЗЕЛЁНОМ"
			hint_label.position = Vector2(326, 418)
		MG.GAUGE:
			_mg_title.text = STATION_TITLE.get(station, "ДАВЛЕНИЕ")
			_mg_title.position = Vector2(376, 186)
			mg_level = 0.0
			mg_vel = 0.12
			var lo = randf_range(0.5, 0.74)
			mg_band = Vector2(lo, lo + 0.13)
			hint_label.text = key + " — ОСТАНОВИ В ЗЕЛЁНОМ!"
			hint_label.position = Vector2(326, 418)
		MG.RING:
			_mg_title.text = STATION_TITLE.get(station, "СКРУТКА")
			_mg_title.position = Vector2(376, 186)
			mg_hits_need = 3
			mg_ring_speed = 70.0 + 6.0 * current_shift
			mg_ring_r = 86.0
			hint_label.text = key + " — КОГДА КОЛЬЦО СОВПАДЁТ (3 РАЗА)"
			hint_label.position = Vector2(326, 418)
		MG.CUT:
			_mg_title.text = STATION_TITLE.get(station, "НАРЕЗКА")
			_mg_title.position = Vector2(376, 236)
			mg_knife = 0.0
			mg_marks.clear()
			var n = 3
			for i in range(n):
				mg_marks.append(0.22 + i * 0.26 + randf_range(-0.06, 0.06))
			mg_hits = 0
			mg_hits_need = n
			mg_speed = 0.42 + 0.03 * current_shift
			hint_label.text = key + " — РЕЖЬ ПО МЕТКАМ"
			hint_label.position = Vector2(326, 368)
	_update_minigame_fill()
	_mg_canvas.queue_redraw()


## Is the pointer / level in the green right now?
func _mg_hit_now() -> bool:
	match mg_kind:
		MG.LOCK:
			if mg_pin_index >= mg_pins.size():
				return false
			var d = abs(wrapf(mg_angle - mg_pins[mg_pin_index], -PI, PI))
			return d <= mg_pin_half
		MG.GAUGE:
			return mg_level >= mg_band.x and mg_level <= mg_band.y
		MG.RING:
			return abs(mg_ring_r - RING_TARGET) <= 7.0
		MG.CUT:
			if mg_hits >= mg_marks.size():
				return false
			return abs(mg_knife - mg_marks[mg_hits]) <= 0.045
	var px = TRACK_X0 + slider_pos * TRACK_WIDTH
	return px >= minigame_zone.position.x and px <= minigame_zone.position.x + minigame_zone.size.x


func _draw_minigame() -> void:
	var c = _mg_canvas
	if c == null:
		return
	var dark = Color8(19, 31, 52)
	var rim = Color8(30, 50, 82)
	var green = Color8(166, 204, 52)
	var green_d = Color8(81, 136, 34)
	var blue = Color8(103, 154, 190)
	var blue_d = Color8(52, 94, 125)
	# panel in the style of the minigame window texture
	var w = 120.0 if mg_kind == MG.GAUGE else 200.0
	var h = 110.0 if mg_kind == MG.CUT else 200.0
	var x0 = (200.0 - w) / 2.0
	var y0 = (200.0 - h) / 2.0
	c.draw_rect(Rect2(x0, y0, w, h), Color.BLACK)
	c.draw_rect(Rect2(x0 + 4, y0 + 4, w - 8, h - 8), rim)
	c.draw_rect(Rect2(x0 + 8, y0 + 8, w - 16, h - 16), dark)
	if _mg_flash > 0.0:
		var fc = green if _mg_flash_good else Color8(230, 70, 60)
		c.draw_rect(Rect2(x0 + 8, y0 + 8, w - 16, h - 16), Color(fc.r, fc.g, fc.b, 0.35 * _mg_flash))
	if mg_kind == MG.RING:
		var ctr = Vector2(100, 104)
		var pulse = 0.75 + 0.25 * sin(mg_time * 10.0)
		c.draw_arc(ctr, RING_TARGET, 0, TAU, 48, green_d, 12)
		c.draw_arc(ctr, RING_TARGET, 0, TAU, 48, Color(green, pulse), 6)
		c.draw_circle(ctr, RING_TARGET - 9, Color8(236, 236, 228))       # rice
		c.draw_circle(ctr, RING_TARGET - 15, Color8(230, 120, 90))       # filling
		c.draw_arc(ctr, RING_TARGET - 9, 0, TAU, 32, Color8(30, 46, 30), 3) # nori
		var close = clamp(1.0 - abs(mg_ring_r - RING_TARGET) / 40.0, 0.0, 1.0)
		c.draw_arc(ctr, mg_ring_r, 0, TAU, 64, Color.BLACK, 7)
		c.draw_arc(ctr, mg_ring_r, 0, TAU, 64, blue.lerp(Color8(220, 236, 250), close), 4)
		for i in range(mg_hits_need):
			var r = Rect2(100 - mg_hits_need * 9 + i * 18, 14, 12, 8)
			c.draw_rect(r, Color.BLACK)
			c.draw_rect(r.grow(-2), green if i < mg_hits else green_d.darkened(0.5))
	elif mg_kind == MG.CUT:
		var roll = Rect2(22, 82, 156, 34)
		c.draw_rect(roll.grow(2), Color.BLACK)
		c.draw_rect(roll, Color8(28, 44, 30))                              # nori
		c.draw_rect(Rect2(roll.position.x, roll.position.y + 4, roll.size.x, roll.size.y - 8), Color8(232, 232, 224))  # rice
		c.draw_rect(Rect2(roll.position.x, roll.position.y + 13, roll.size.x, 8), Color8(232, 120, 88))  # filling
		var cut_x = func(v): return roll.position.x + v * roll.size.x
		for i in range(mg_marks.size()):
			var mx = cut_x.call(mg_marks[i])
			var done = i < mg_hits
			var col = Color(green, 0.9) if i == mg_hits else (Color8(20, 24, 30) if done else Color(green_d, 0.7))
			if done:
				c.draw_rect(Rect2(mx - 1, roll.position.y - 2, 3, roll.size.y + 4), col)
			else:
				for k in range(5):
					c.draw_rect(Rect2(mx - 1, roll.position.y - 6 + k * 9, 3, 5), col)
		var kx = cut_x.call(mg_knife)
		c.draw_rect(Rect2(kx - 2, 62, 5, 18), Color.BLACK)
		c.draw_rect(Rect2(kx - 1, 63, 3, 16), Color8(210, 220, 232))       # blade
		c.draw_rect(Rect2(kx - 3, 56, 7, 7), Color8(96, 70, 46))           # handle
		for i in range(mg_hits_need):
			var r = Rect2(100 - mg_hits_need * 9 + i * 18, 58 - 6, 12, 8)
			c.draw_rect(r, Color.BLACK)
			c.draw_rect(r.grow(-2), green if i < mg_hits else green_d.darkened(0.5))
	if mg_kind == MG.LOCK:
		var ctr = Vector2(100, 104)
		var R = 62.0
		c.draw_arc(ctr, R, 0, TAU, 64, Color(0.04, 0.07, 0.12), 16)
		c.draw_arc(ctr, R + 9, 0, TAU, 64, rim, 2)
		c.draw_arc(ctr, R - 9, 0, TAU, 64, rim, 2)
		for k in range(12):
			var a = k * TAU / 12.0
			c.draw_line(ctr + Vector2.from_angle(a) * (R - 6), ctr + Vector2.from_angle(a) * (R + 6), Color(rim, 0.9), 2)
		var pulse = 0.75 + 0.25 * sin(mg_time * 10.0)
		for i in range(mg_pins.size()):
			var p = mg_pins[i]
			if i < mg_pin_index:
				c.draw_arc(ctr, R, p - mg_pin_half, p + mg_pin_half, 10, Color(green, 0.35), 12)
			elif i == mg_pin_index:
				c.draw_arc(ctr, R, p - mg_pin_half, p + mg_pin_half, 12, green_d, 16)
				c.draw_arc(ctr, R, p - mg_pin_half + 0.04, p + mg_pin_half - 0.04, 12, Color(green, pulse), 10)
			else:
				c.draw_arc(ctr, R, p - mg_pin_half, p + mg_pin_half, 10, Color(green_d, 0.55), 6)
		# needle with a motion trail
		for t in range(6):
			var back = mg_angle - mg_dir * 0.07 * (t + 1)
			c.draw_line(ctr, ctr + Vector2.from_angle(back) * (R + 4), Color(blue, 0.18 - t * 0.025), 6)
		var tip = ctr + Vector2.from_angle(mg_angle) * (R + 8)
		c.draw_line(ctr, tip, Color.BLACK, 7)
		c.draw_line(ctr, tip, blue, 4)
		c.draw_circle(tip, 4, Color8(220, 236, 250))
		c.draw_circle(ctr, 12, Color.BLACK)
		c.draw_circle(ctr, 10, blue_d)
		c.draw_circle(ctr, 4, blue)
		# pins solved
		var n = mg_pins.size()
		for i in range(n):
			var r = Rect2(100 - n * 9 + i * 18, 14, 12, 8)
			c.draw_rect(r, Color.BLACK)
			c.draw_rect(r.grow(-2), green if i < mg_pin_index else green_d.darkened(0.5))
		# time left
		var left = clamp(1.0 - mg_time / mg_timeout, 0.0, 1.0)
		c.draw_rect(Rect2(20, 182, 160, 6), Color.BLACK)
		c.draw_rect(Rect2(21, 183, 158 * left, 4), blue if left > 0.3 else Color8(230, 90, 60))
	elif mg_kind == MG.GAUGE:
		var tube = Rect2(80, 20, 40, 164)
		c.draw_rect(tube.grow(4), Color.BLACK)
		c.draw_rect(tube.grow(2), rim)
		c.draw_rect(tube, Color(0.03, 0.05, 0.09))
		# overpressure stripes at the top
		for k in range(4):
			c.draw_rect(Rect2(80, 20 + k * 6, 40, 3), Color8(200, 60, 50) if k % 2 == 0 else Color8(60, 20, 20))
		var y_of = func(v): return tube.end.y - v * tube.size.y
		var b0 = y_of.call(mg_band.y)
		var b1 = y_of.call(mg_band.x)
		c.draw_rect(Rect2(80, b0, 40, b1 - b0), green_d)
		c.draw_rect(Rect2(82, b0 + 2, 36, b1 - b0 - 4), Color(green, 0.75 + 0.25 * sin(mg_time * 8.0)))
		var lv = y_of.call(mg_level)
		var hot = clamp((mg_level - 0.6) / 0.4, 0.0, 1.0)
		var fill_col = blue.lerp(Color8(240, 140, 50), hot)
		c.draw_rect(Rect2(84, lv, 32, tube.end.y - lv), Color(fill_col, 0.85))
		var wob = sin(mg_time * 18.0) * 2.0
		c.draw_line(Vector2(84, lv + wob), Vector2(116, lv - wob), Color8(230, 240, 255), 2)
		for k in range(9):
			var ty = tube.position.y + k * tube.size.y / 8.0
			c.draw_line(Vector2(70, ty), Vector2(78, ty), rim, 2)
		# pointer
		c.draw_colored_polygon(PackedVector2Array([Vector2(126, lv), Vector2(136, lv - 6), Vector2(136, lv + 6)]), Color8(220, 236, 250))


## Hides the minigame after a short green / red flash.
func _hide_minigame_ui(good: bool) -> void:
	_mg_flash = 1.0
	_mg_flash_good = good
	for n in [minigame_panel, _mg_canvas, _mg_title]:
		if n == null or not n.visible:
			continue
		n.modulate = Color(0.6, 1.6, 0.6) if good else Color(1.8, 0.5, 0.5)
		var tw = n.create_tween()
		tw.tween_property(n, "modulate", Color(1, 1, 1, 0), 0.35).set_delay(0.18)
		var node = n
		tw.tween_callback(func():
			node.visible = false
			node.modulate = Color.WHITE
		)

func _update_minigame_fill() -> void:
	if minigame_zone == null or minigame_slider == null:
		return
	var px = TRACK_X0 + clamp(slider_pos, 0.0, 1.0) * TRACK_WIDTH
	var in_zone = px >= minigame_zone.position.x and px <= minigame_zone.position.x + minigame_zone.size.x
	minigame_slider.modulate = Color(0.8, 1.6, 0.8) if in_zone else Color.WHITE

func _update_stress_from_hp() -> void:
	if player == null:
		return
	var hp = 0
	if player.has_method("get_hp"):
		hp = player.get_hp()
	else:
		hp = player.hp
	stress_level = STRESS_BY_HP.get(hp, 0)
	_update_stress_bar()

func _get_miss_chance() -> float:
	return MISS_CHANCE_BY_STRESS.get(stress_level, 0.0)

## ---------------------------------------------------------------- pixel HUD (top-right)
## Everything is drawn on a pixel grid (1 art pixel = HUD_PX screen pixels) with a tiny
## pixel font, so the whole level HUD reads as one piece of pixel art.
const HUD_PX: float = 3.0
const HUD_W: int = 92
const HUD_MARGIN: float = 10.0
const PIX_FONT := {
	"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
	"С": ["111", "100", "100", "100", "111"], "Т": ["111", "010", "010", "010", "010"],
	"Р": ["111", "101", "111", "100", "100"], "Е": ["111", "100", "110", "100", "111"],
	"О": ["010", "101", "101", "101", "010"], "Х": ["101", "101", "010", "101", "101"],
	"А": ["010", "101", "111", "101", "101"], "Н": ["101", "101", "111", "101", "101"],
	"П": ["111", "101", "101", "101", "101"], "М": ["10001", "11011", "10101", "10001", "10001"],
	"Й": ["0110", "1001", "1011", "1101", "1001"], "И": ["1001", "1001", "1011", "1101", "1001"],
	"К": ["101", "110", "100", "110", "101"], "Л": ["011", "101", "101", "101", "101"], "Ы": ["10001", "10001", "11101", "10101", "11101"],
	":": ["0", "1", "0", "1", "0"], "%": ["101", "001", "010", "100", "101"],
	"/": ["001", "001", "010", "100", "100"], " ": ["00", "00", "00", "00", "00"],
}
const HUD_C_BG := Color8(14, 16, 22)
const HUD_C_EDGE := Color8(86, 96, 112)
const HUD_C_EDGE_HI := Color8(140, 152, 170)
const HUD_C_TEXT := Color8(196, 202, 214)
const HUD_C_DIM := Color8(40, 44, 54)
const HUD_C_GOOD := Color8(130, 204, 66)
const HUD_C_BAD := Color8(214, 72, 60)
const HUD_C_ORANGE := Color8(232, 150, 48)

var _hud_panel: Control = null
var _box_states: Array = []


func _hud_rect(c: Control, x: float, y: float, w: float, h: float, col: Color) -> void:
	c.draw_rect(Rect2(x * HUD_PX, y * HUD_PX, w * HUD_PX, h * HUD_PX), col)


func _pix_text_width(t: String) -> int:
	var w = 0
	for ch in t:
		var g = PIX_FONT.get(ch, PIX_FONT[" "])
		w += g[0].length() + 1
	return max(0, w - 1)


func _pix_text(c: Control, t: String, x: int, y: int, col: Color, shadow: bool = true) -> void:
	var cx = x
	for ch in t:
		var g: Array = PIX_FONT.get(ch, PIX_FONT[" "])
		for row in range(5):
			var line: String = g[row]
			for k in range(line.length()):
				if line[k] == "1":
					if shadow:
						_hud_rect(c, cx + k, y + row + 1, 1, 1, Color(0, 0, 0, 0.8))
					_hud_rect(c, cx + k, y + row, 1, 1, col)
		cx += g[0].length() + 1


## Big 7-segment digit, 4 x 7 art pixels.
func _pix_seg_digit(c: Control, ch: String, x: int, y: int, on: Color, off: Color) -> void:
	var segs = {"a": [1, 0, 2, 1], "b": [3, 1, 1, 2], "c": [3, 4, 1, 2], "d": [1, 6, 2, 1],
		"e": [0, 4, 1, 2], "f": [0, 1, 1, 2], "g": [1, 3, 2, 1]}
	var lit: String = SEG_MAP.get(ch, "")
	for k in segs.keys():
		var r = segs[k]
		_hud_rect(c, x + r[0], y + r[1], r[2], r[3], on if lit.find(k) >= 0 else off)


var _hud_texts: Dictionary = {}

## Real text (the game's font) on top of the pixel panel.
func _hud_text(key: String, text: String, x_px: float, y_px: float, w_px: float, align: int, col: Color, size: int = 13) -> void:
	var l: Label = _hud_texts.get(key, null)
	if l == null:
		l = Label.new()
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", size)
		l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
		l.add_theme_constant_override("outline_size", 4)
		_hud_panel.add_child(l)
		_hud_texts[key] = l
	l.visible = true
	l.text = text
	l.position = Vector2(x_px, y_px)
	l.size = Vector2(w_px, 18)
	l.horizontal_alignment = align
	l.add_theme_color_override("font_color", col)


func _create_hud() -> void:
	progress_bar.visible = false   # kept only as the data model of the shift result
	clock_label.visible = false
	_box_states.clear()
	for i in range(TOTAL_OBJECTS):
		_box_states.append(0)
	_hud_panel = Control.new()
	_hud_panel.name = "LevelHUD"
	_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_panel.draw.connect(_draw_hud)
	$UI.add_child(_hud_panel)
	_hud_nodes.append(_hud_panel)
	_layout_hud()


func _hud_rows() -> int:
	return 4 if current_shift >= 2 else 3


func _layout_hud() -> void:
	if _hud_panel == null:
		return
	var h = 9 + _hud_rows() * 9
	_hud_panel.size = Vector2(HUD_W, h) * HUD_PX
	var vp = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1152, 648)
	_hud_panel.position = Vector2(vp.x - _hud_panel.size.x - HUD_MARGIN, HUD_MARGIN)


func _draw_hud() -> void:
	var c = _hud_panel
	if c == null:
		return
	var W = HUD_W
	var H = int(c.size.y / HUD_PX)
	# frame: black outline, steel rim with a light top edge, dark plate
	_hud_rect(c, 0, 0, W, H, Color.BLACK)
	_hud_rect(c, 1, 1, W - 2, H - 2, HUD_C_EDGE)
	_hud_rect(c, 2, 1, W - 4, 1, HUD_C_EDGE_HI)
	_hud_rect(c, 2, 2, W - 4, H - 4, HUD_C_BG)
	# hazard stripe along the top
	for x in range(2, W - 2):
		for y in range(2, 4):
			if int((x + y) / 2) % 2 == 0:
				_hud_rect(c, x, y, 1, 1, HUD_C_ORANGE)
			else:
				_hud_rect(c, x, y, 1, 1, Color8(24, 20, 16))
	# corner rivets
	for p in [Vector2(2, H - 3), Vector2(W - 3, H - 3)]:
		_hud_rect(c, p.x, p.y, 1, 1, HUD_C_EDGE_HI)

	# row 1: shift + LCD clock
	var y = 6
	var lcd_w = 4 * 4 + 3 + 2 + 4
	var lx = W - 4 - lcd_w
	_hud_rect(c, lx - 2, y - 1, lcd_w + 4, 9, Color.BLACK)
	_hud_rect(c, lx - 1, y - 0, lcd_w + 2, 7, Color8(8, 10, 8))
	var on = Color8(255, 86, 50)
	var off = Color8(46, 16, 12)
	var digits = _clock_text.replace(":", "")
	var dx = lx
	for i in range(4):
		var ch = digits[i] if i < digits.length() else "8"
		_pix_seg_digit(c, ch, dx, y, on, off)
		dx += 5
		if i == 1:
			var blink = int(Time.get_ticks_msec() / 500) % 2 == 0
			_hud_rect(c, dx, y + 2, 1, 1, on if blink else off)
			_hud_rect(c, dx, y + 4, 1, 1, on if blink else off)
			dx += 2

	# row 2: packed / ruined boxes
	y += 10
	var cells_w = TOTAL_OBJECTS * 3 - 1
	var cx0 = int((W - cells_w) / 2)
	for i in range(TOTAL_OBJECTS):
		var st = _box_states[i] if i < _box_states.size() else 0
		var col = HUD_C_DIM if st == 0 else (HUD_C_GOOD if st == 1 else HUD_C_BAD)
		_hud_rect(c, cx0 + i * 3, y, 2, 5, col)
		if st != 0:
			_hud_rect(c, cx0 + i * 3, y, 2, 1, col.lightened(0.35))

	# row 3: stress
	y += 9
	var pct = str(stress_level) + "%"
	var bx = 25
	var bw = W - 4 - 13 - bx
	_hud_rect(c, bx - 1, y - 1, bw + 2, 7, Color.BLACK)
	_hud_rect(c, bx, y, bw, 5, HUD_C_DIM)
	var fill = int(round(bw * clamp(_stress_shown / 100.0, 0.0, 1.0)))
	var scol = Color8(120, 200, 230).lerp(HUD_C_BAD, clamp((_stress_shown - 20.0) / 50.0, 0.0, 1.0))
	if stress_level >= 60:
		var p = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
		scol = scol.lightened(0.25 * p)
	if fill > 0:
		_hud_rect(c, bx, y, fill, 5, scol)
		_hud_rect(c, bx, y, fill, 1, scol.lightened(0.35))

	# row 4: shift notes (from shift 2)
	if _hud_rows() >= 4:
		y += 9
		var gx = 25
		for i in range(3):
			_hud_rect(c, gx + i * 5, y, 4, 5, Color.BLACK)
			_hud_rect(c, gx + i * 5 + 1, y + 1, 2, 3, HUD_C_GOOD if i < guard_shifts_found.size() else HUD_C_DIM)
		if current_shift >= 3:
			var px = W - 4 - 14
			for i in range(3):
				_hud_rect(c, px + i * 5, y, 4, 5, Color.BLACK)
				_hud_rect(c, px + i * 5 + 1, y + 1, 2, 3, HUD_C_GOOD if i < sniper_shifts_found.size() else HUD_C_DIM)


func _create_shift_bars() -> void:
	pass


func _create_stress_bar() -> void:
	pass


func _update_stress_bar() -> void:
	_stress_shown = move_toward(_stress_shown, float(stress_level), 60.0 * get_process_delta_time())
	if _hud_panel:
		_update_hud_texts()
		_hud_panel.queue_redraw()


## Labels (game font) placed on the rows of the pixel panel.
func _update_hud_texts() -> void:
	var W = HUD_W
	var L = HORIZONTAL_ALIGNMENT_LEFT
	var R = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_text("shift", "СМЕНА " + str(current_shift), 4 * HUD_PX, 5 * HUD_PX, 140, L, HUD_C_TEXT)
	_hud_text("stress", "СТРЕСС", 4 * HUD_PX, 24 * HUD_PX, 70, L, HUD_C_TEXT)
	_hud_text("pct", str(stress_level) + "%", (W - 4 - 12) * HUD_PX, 24 * HUD_PX, 12 * HUD_PX, R, _stress_color(stress_level))
	if _hud_rows() >= 4:
		_hud_text("guard", "ОХРАНА", 4 * HUD_PX, 33 * HUD_PX, 70, L, HUD_C_TEXT)
		if current_shift >= 3:
			_hud_text("sniper", "СНАЙПЕР", (W - 4 - 14 - 3 - 28) * HUD_PX, 33 * HUD_PX, 28 * HUD_PX, R, HUD_C_TEXT)
		elif _hud_texts.has("sniper"):
			_hud_texts["sniper"].visible = false
	else:
		for key in ["guard", "sniper"]:
			if _hud_texts.has(key):
				_hud_texts[key].visible = false


func _process_stress_pulse(_delta: float) -> void:
	pass

func _update_shift_bars() -> void:
	_layout_hud()
	if _hud_panel:
		_hud_panel.queue_redraw()

func _create_inspect_targets() -> void:
	_add_inspect_target("clock", Vector2(576, 80), Vector2(120, 60),
		"Часы", "Сколько я тут?", "Смена длится 10 часов", COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("elevator", Vector2(-290, 325), Vector2(100, 120),
		"Лифт", "Стоит попробовать..", "Лифт из которого приходят охранники", COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("maintenance", Vector2(1230, 325), Vector2(100, 120),
		"Комната техобслуживания", "Туда уходят рабочие в конце смены..",
		"Комната техобслуживания — сюда уходят рабочие после смены", COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("sniper", Vector2(1060, 60), Vector2(120, 80),
		"Снайпер-Голубь", "Снайпер, который может пристрелить меня когда угодно..",
		"Снайпер-Голубь в меха костюме. Имеет крылья винтовку и пистолет", COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("guard_dog", Vector2(-215, 310), Vector2(80, 80),
		"Охранник-Собака", "Лучший друг человека..",
		"Охранник-Собака в меха костюме. Имеет меха челюсти со смертельной силой сжатия", COLOR_HIGHLIGHT_BLUE, "dog")
	_add_inspect_target("guard_monkey", Vector2(-215, 310), Vector2(80, 80),
		"Охранник-Обезьяна", "Человекоподобные тоже с ними..",
		"Охранник-Обезьяна в меха костюме. Имеет массивный меха хвост", COLOR_HIGHLIGHT_BLUE, "monkey")
	var conv_center_x = (OBJECT_SPAWN_X + OBJECT_DESPAWN_X) / 2.0
	var conv_width = OBJECT_SPAWN_X - OBJECT_DESPAWN_X
	_add_inspect_target("conveyor", Vector2(conv_center_x, 400), Vector2(conv_width, 80),
		"Конвейер", "Сколько еще таких заводов они построили?",
		str(TOTAL_OBJECTS) + " коробок за смену", COLOR_HIGHLIGHT_BLUE, "")
	for fish in npc_fishes:
		if fish == null:
			continue
		var identity = npc_identities.get(fish, "")
		var info = NPC_IDENTITY_DATA.get(identity, {})
		if info.is_empty():
			continue
		_add_inspect_target("npc_" + identity, fish.position, Vector2(70, 90),
			info.get("title", ""), info.get("phrase", ""), info.get("journal", ""), COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("guard_shift_9", Vector2(-215, 310), Vector2(80, 80),
		"Смена охранника", "Охранник сменился.. Нужно записать", "Смена охранника в 09:00",
		COLOR_HIGHLIGHT_YELLOW, "guard_shift", 9.0)
	_add_inspect_target("guard_shift_13", Vector2(-215, 310), Vector2(80, 80),
		"Смена охранника", "Охранник сменился.. Нужно записать", "Смена охранника в 13:00",
		COLOR_HIGHLIGHT_YELLOW, "guard_shift", 13.0)
	_add_inspect_target("guard_shift_17", Vector2(-215, 310), Vector2(80, 80),
		"Смена охранника", "Охранник сменился.. Нужно записать", "Смена охранника в 17:00",
		COLOR_HIGHLIGHT_YELLOW, "guard_shift", 17.0)
	_add_inspect_target("sniper_shift_11", Vector2(1060, 60), Vector2(120, 80),
		"Смена снайпера", "Снайпер сменился.. Нужно записать", "Смена снайпера в 11:00",
		COLOR_HIGHLIGHT_YELLOW, "sniper_shift", 11.0)
	_add_inspect_target("sniper_shift_13", Vector2(1060, 60), Vector2(120, 80),
		"Смена снайпера", "Снайпер сменился.. Нужно записать", "Смена снайпера в 13:00",
		COLOR_HIGHLIGHT_YELLOW, "sniper_shift", 13.0)
	_add_inspect_target("sniper_shift_15", Vector2(1060, 60), Vector2(120, 80),
		"Смена снайпера", "Снайпер сменился.. Нужно записать", "Смена снайпера в 15:00",
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
		"id": id, "title": title, "phrase": phrase, "journal": journal,
		"pos": pos, "size": size, "color": color,
		"special_type": special_type, "special_hour": special_hour,
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
	# the highlight is drawn as an outline around the object's own pixels;
	# the rect stays only as an invisible "is highlighted" flag (or as corner brackets
	# for targets without a sprite)
	var nodes = _outline_targets_for(id)
	if nodes.is_empty():
		hl.color = Color(color.r, color.g, color.b, 0.9)
		_apply_zone_shader(hl)
	else:
		hl.self_modulate.a = 0.0
		for n in nodes:
			_ensure_outline(n, color)
		_outline_nodes[area] = nodes

func _update_npc_inspect_position(identity: String, pos: Vector2) -> void:
	var target_id = "npc_" + identity
	for area in inspect_targets:
		if not is_instance_valid(area):
			continue
		var data = inspect_target_data.get(area, {})
		if data.get("id", "") != target_id:
			continue
		area.position = pos
		data["pos"] = pos
		inspect_target_data[area] = data
		var size = data.get("size", Vector2(70, 90))
		var hl = inspect_highlight_rects.get(area, null)
		if is_instance_valid(hl):
			hl.offset_left = pos.x - size.x / 2.0
			hl.offset_top = pos.y - size.y / 2.0
			hl.offset_right = pos.x + size.x / 2.0
			hl.offset_bottom = pos.y + size.y / 2.0
		return

func _is_inspect_target_visible(area: Area2D) -> bool:
	var data = inspect_target_data.get(area, {})
	if data.is_empty():
		return false
	var id = data.get("id", "")
	var special_type = data.get("special_type", "")
	var special_hour = data.get("special_hour", -1.0)
	if journal_notes.has(id):
		return false
	if special_type == "":
		if id == "guard_dog":
			return guard_is_dog and not guard_changing
		if id == "guard_monkey":
			return not guard_is_dog and not guard_changing
		return true
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
		hl.visible = _is_inspect_target_visible(area)

## ---------------------------------------------------------------- inspect outlines
func _outline_targets_for(id: String) -> Array:
	var out: Array = []
	if id == "clock":
		var wc = get_node_or_null("Decor/WallClock")
		if wc:
			out.append(wc)
	elif id == "elevator":
		for n in [elevator_front, elevator_back]:
			if n:
				out.append(n)
	elif id == "maintenance":
		var d = get_node_or_null("Decor/MaintenanceDoor")
		if d:
			out.append(d)
	elif id.begins_with("sniper"):
		if sniper_sprite:
			out.append(sniper_sprite)
	elif id.begins_with("guard"):
		if guard_sprite:
			out.append(guard_sprite)
	elif id == "conveyor":
		for c in conveyor_sprites:
			out.append(c)
	elif id.begins_with("npc_"):
		var identity = id.substr(4)
		for f in npc_fishes:
			if f and npc_identities.get(f, "") == identity:
				out.append(f)
	return out


func _ensure_outline(node: CanvasItem, color: Color) -> void:
	if node == null:
		return
	if node.material is ShaderMaterial and node.material.shader and node.material.shader.resource_path == OUTLINE_SHADER:
		return
	var sh = load(OUTLINE_SHADER)
	if sh == null:
		return
	var m = ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("outline_color", Color(color.r, color.g, color.b, 1.0))
	m.set_shader_parameter("active", 0.0)
	node.material = m


## Turns the sprite outlines on/off to match the (invisible) highlight flags.
func _sync_inspect_outlines() -> void:
	var on_nodes: Dictionary = {}
	for area in _outline_nodes.keys():
		var hl = inspect_highlight_rects.get(area, null)
		var on = is_instance_valid(area) and is_instance_valid(hl) and hl.visible and state == State.INSPECT
		for n in _outline_nodes[area]:
			if is_instance_valid(n) and on:
				on_nodes[n] = true
	for area in _outline_nodes.keys():
		for n in _outline_nodes[area]:
			if is_instance_valid(n) and n.material is ShaderMaterial:
				n.material.set_shader_parameter("active", 1.0 if on_nodes.has(n) else 0.0)

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
	var left = player_zone_center.x - PLAYER_ZONE_SIZE.x / 2.0
	var right = player_zone_center.x + PLAYER_ZONE_SIZE.x / 2.0
	var top = player_zone_center.y - PLAYER_ZONE_SIZE.y / 2.0
	var bottom = player_zone_center.y + PLAYER_ZONE_SIZE.y / 2.0
	return pos.x >= left and pos.x <= right and pos.y >= top and pos.y <= bottom

func _process(delta: float) -> void:
	if state == State.DEAD:
		return
	if get_tree().paused:
		return
	_process_clock(delta)
	_process_shift_changes()
	_process_conveyor_scroll(delta)
	_process_stress_pulse(delta)
	_sync_inspect_outlines()
	_process_finished_boxes(delta)
	_process_broken_boxes(delta)
	_process_shift_end_npcs(delta)
	_process_action_penalty(delta)
	_process_follow_penalty(delta)
	_process_inspect_notice(delta)
	_update_stress_from_hp()
	_update_low_hp_pulse(delta)
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

## Is the player really walking / jumping right now (not just holding a key against a wall)?
func _player_moving() -> bool:
	if player == null:
		return false
	var v = player.get("velocity")
	if v is Vector2:
		return abs(v.x) > 25.0 or v.y < -60.0
	return Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") or Input.is_action_pressed("jump")


func _add_strike() -> void:
	action_strike_count += 1
	_strike_forgive = 0.0
	_handle_action_strike()


## During work: walking around OUTSIDE your station (and outside the maintenance area) is
## punished; inside the zone you can move freely. Around 13:00 nobody watches.
func _process_action_penalty(delta: float) -> void:
	if state == State.SHIFT_END or state == State.DEAD:
		return
	if action_strike_count > 0:
		_strike_forgive += delta
		if _strike_forgive >= STRIKE_FORGIVE_TIME:
			_strike_forgive = 0.0
			action_strike_count -= 1
	if state == State.INSPECT or state == State.INTRO:
		action_move_timer = 0.0
		return
	if current_shift == 1 and _resolved <= AUTO_OBJECTS:
		action_move_timer = 0.0   # tutorial: the player is still being shown the work
		return
	var hour = _current_hour()
	if abs(hour - 13.0) < 0.5 or _is_player_in_zone() or _is_player_near_maintenance():
		action_move_timer = max(0.0, action_move_timer - delta * 2.0)
		return
	if _player_moving():
		action_move_timer += delta
		if action_move_timer >= PENALTY_MOVE_TIME:
			action_move_timer = 0.0
			_add_strike()
	else:
		action_move_timer = max(0.0, action_move_timer - delta)

## After the shift it is the other way round: everybody runs to maintenance, so standing still
## (or walking away from it) is punished. Once you are there - nothing.
func _process_follow_penalty(delta: float) -> void:
	if state != State.SHIFT_END:
		follow_strike_timer = 0.0
		return
	if player == null or _is_player_near_maintenance():
		follow_strike_timer = 0.0
		return
	if fade_rect and fade_rect.visible and fade_rect.color.a > 0.2:
		return   # the screen is already going dark
	var going = false
	if _player_moving():
		var v = player.get("velocity")
		var dir_x = 1.0
		if maintenance_door:
			dir_x = sign(maintenance_door.global_position.x - player.global_position.x)
		going = not (v is Vector2) or sign(v.x) == dir_x or dir_x == 0.0
	if going:
		follow_strike_timer = 0.0
		return
	follow_strike_timer += delta
	if follow_strike_timer >= PENALTY_IDLE_TIME:
		follow_strike_timer = 0.0
		_add_strike()

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
			if fish is AnimatedSprite2D:
				fish.flip_h = false
			if fish is AnimatedSprite2D and fish.sprite_frames.has_animation("jogging"):
				if fish.animation != "jogging":
					fish.play("jogging")

## After the shift the food that is still on the belt rides off to the left.
func _process_finished_boxes(delta: float) -> void:
	if state != State.SHIFT_END:
		return
	for it in belt_items.duplicate():
		var n = it["node"]
		if not is_instance_valid(n):
			belt_items.erase(it)
			continue
		n.position.x -= OBJECT_SPEED * delta
		if n.position.x < OBJECT_DESPAWN_X:
			n.queue_free()
			belt_items.erase(it)

func _process_broken_boxes(_delta: float) -> void:
	pass

func _process_conveyor_scroll(delta: float) -> void:
	if conveyor_paused:
		return
	if conveyor_tile_width <= 0.0 or conveyor_sprites.is_empty():
		return
	conveyor_scroll_offset += OBJECT_SPEED * 0.5 * delta
	if conveyor_scroll_offset >= conveyor_tile_width:
		conveyor_scroll_offset -= conveyor_tile_width
	for i in range(conveyor_sprites.size()):
		var s: Sprite2D = conveyor_sprites[i]
		s.position.x = conveyor_base_x + i * conveyor_tile_width - conveyor_scroll_offset

## The shift clock follows the work: 25 boxes are spread over 8:00 - 18:00, so the time
## shown is where the shift really is (the 25th box is packed exactly at 18:00).
func _process_clock(delta: float) -> void:
	if state == State.SHIFT_END:
		return
	var target = _work_progress()
	var rate = 1.0 / 40.0
	var hour = _current_hour()
	if target > shift_time:
		var speed = max(rate, (target - shift_time) * 1.5)
		# the escape window 13:00 - 13:15 always lasts long enough to reach the elevator
		if hour >= ESCAPE_WINDOW_START - 0.02 and hour <= ESCAPE_WINDOW_END:
			speed = min(speed, (ESCAPE_WINDOW_END - ESCAPE_WINDOW_START) / SHIFT_DURATION_HOURS / 18.0)
		shift_time = move_toward(shift_time, target, speed * delta)
	shift_time = clamp(shift_time, 0.0, 0.999)
	_update_clock_label()
	_update_wall_clock()

func _work_progress() -> float:
	var part = 0.0
	if _belt_move_left > 0.0:
		part = 0.3 * (1.0 - _belt_move_left / FISH_SPACING)
	elif _jobs_total > 0:
		part = 0.3 + 0.65 * float(_jobs_total - _jobs_left) / float(_jobs_total)
	return clamp((float(_cycles_done) + part) / float(TOTAL_CYCLES), 0.0, 1.0)

func _setup_wall_clock() -> void:
	var wc = get_node_or_null("Decor/WallClock") as Sprite2D
	if wc == null:
		return
	_clock_hands.clear()
	var hub = wc.position + Vector2(-0.5, -0.5) * wc.scale
	for spec in [[2.6, 3.0], [4.4, 3.0]]:   # hour hand, minute hand (length in texture px, width)
		var hand = Line2D.new()
		hand.width = spec[1]
		hand.default_color = Color(0.04, 0.06, 0.12)
		hand.points = PackedVector2Array([Vector2.ZERO, Vector2(0, -spec[0] * wc.scale.y)])
		hand.position = hub
		hand.z_index = wc.z_index
		hand.antialiased = false
		wc.get_parent().add_child(hand)
		wc.get_parent().move_child(hand, wc.get_index() + 1)
		_clock_hands.append(hand)
	_update_wall_clock()


func _update_wall_clock() -> void:
	if _clock_hands.size() < 2:
		return
	var hour = _current_hour()
	var minutes = (hour - floor(hour)) * 60.0
	_clock_hands[0].rotation = TAU * fmod(hour, 12.0) / 12.0
	_clock_hands[1].rotation = TAU * minutes / 60.0

func _current_hour() -> float:
	return SHIFT_START_HOUR + shift_time * SHIFT_DURATION_HOURS

func _update_clock_label() -> void:
	var hour = _current_hour()
	var h = int(hour)
	var m = int((hour - h) * 60)
	m = int(floor(float(m) / 15.0)) * 15
	if clock_label:
		clock_label.text = "%02d:%02d" % [h, m]
	_clock_text = "%02d:%02d" % [h, m]
	if _hud_panel:
		_hud_panel.queue_redraw()

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
	_guard_shift_sequence()

func _guard_shift_sequence() -> void:
	if guard_sprite == null:
		guard_changing = false
		return
	await _guard_walk_to(elevator_button.position if elevator_button else GUARD_POSITION)
	await get_tree().create_timer(0.5).timeout
	await _await_elevator_anim("open")
	await _guard_walk_to(GUARD_LIFT_POSITION)
	guard_sprite.visible = false
	await _await_elevator_anim("close")
	await get_tree().create_timer(SHIFT_CHANGE_REAL).timeout
	guard_is_dog = not guard_is_dog
	_apply_guard_frames()
	guard_sprite.position = GUARD_LIFT_POSITION
	await _await_elevator_anim("open")
	guard_sprite.visible = true
	await _guard_walk_to(GUARD_POSITION)
	await _await_elevator_anim("close")
	if guard_sprite.sprite_frames.has_animation("idle"):
		guard_sprite.play("idle")
	guard_changing = false

func _on_sniper_shift_change(_hour: float) -> void:
	if sniper_changing:
		return
	sniper_changing = true
	if sniper_sprite:
		sniper_sprite.visible = false
	await get_tree().create_timer(SHIFT_CHANGE_REAL).timeout
	if sniper_sprite:
		sniper_sprite.visible = true
	sniper_changing = false

func _process_working(delta: float) -> void:
	if _belt_move_left <= 0.0:
		return
	var step = min(OBJECT_SPEED * delta, _belt_move_left)
	_belt_move_left -= step
	for it in belt_items:
		var n = it["node"]
		if is_instance_valid(n):
			n.position.x -= step
	if _belt_move_left <= 0.0:
		_belt_move_left = 0.0
		belt_moved.emit()

func _slot_x(slot: int) -> float:
	if SLOT_STATION.has(slot):
		return _get_stop_zone_x(SLOT_STATION[slot])
	var pack_x = _get_stop_zone_x(STATION_PACK)
	return pack_x + float(BELT_PACK_SLOT - slot) * FISH_SPACING


func _clear_belt() -> void:
	for it in belt_items:
		if is_instance_valid(it["node"]):
			it["node"].queue_free()
	belt_items.clear()
	for b in finished_boxes + broken_boxes:
		if is_instance_valid(b):
			b.queue_free()
	finished_boxes.clear()
	broken_boxes.clear()
	current_object = null
	_player_item = null


func _belt_stopped(gen: int) -> bool:
	return gen != _belt_gen or state == State.DEAD or state == State.SHIFT_END


## Runs a whole shift: spawn, move one press forward, all presses work together, repeat.
func _start_belt() -> void:
	_belt_gen += 1
	var gen = _belt_gen
	_clear_belt()
	_cycles_done = 0
	_spawned = 0
	_resolved = 0
	_jobs_left = 0
	_jobs_total = 0
	_belt_move_left = 0.0
	current_object_index = 0
	conveyor_paused = true
	while _resolved < TOTAL_OBJECTS:
		if _belt_stopped(gen):
			return
		if _spawned < TOTAL_OBJECTS:
			_spawn_item()
		# the belt moves one press forward
		_jobs_total = 0
		conveyor_paused = false
		_belt_move_left = FISH_SPACING
		await belt_moved
		if _belt_stopped(gen):
			return
		conveyor_paused = true
		var gone: Array = []
		for it in belt_items:
			it["slot"] += 1
			var n = it["node"]
			if is_instance_valid(n):
				n.position.x = _slot_x(it["slot"])
			if it["slot"] > BELT_PACK_SLOT + 3:
				gone.append(it)
		for it in gone:
			belt_items.erase(it)
			if is_instance_valid(it["node"]):
				it["node"].queue_free()
		# every press with food under it works at the same time
		var work: Array = []
		for it in belt_items:
			if it["slot"] >= 1 and it["slot"] <= BELT_PACK_SLOT and not it["broken"] and not it["done"]:
				work.append(it)
		_jobs_total = work.size()
		_jobs_left = work.size()
		for it in work:
			_run_job(it, gen)
		if _jobs_left > 0:
			await jobs_done
		if _belt_stopped(gen):
			return
		_cycles_done += 1
		await get_tree().create_timer(0.12, false).timeout
	if _belt_stopped(gen):
		return
	_end_shift()


func _spawn_item() -> void:
	var node = Node2D.new()
	node.name = "Sushi" + str(_spawned)
	var spr = Sprite2D.new()
	spr.name = "Sprite"
	spr.centered = false
	spr.scale = Vector2(SUSHI_SCALE, SUSHI_SCALE)
	node.add_child(spr)
	node.set_meta("sushi_stage", -1)
	node.z_index = Z_FOOD
	node.position = Vector2(_slot_x(0), BELT_SURFACE_Y)
	objects_layer.add_child(node)
	_apply_stage(node, 0, false)
	belt_items.append({"node": node, "index": _spawned, "slot": 0, "broken": false, "done": false})
	_spawned += 1


func _run_job(it: Dictionary, gen: int) -> void:
	var st = SLOT_STATION.get(it["slot"], STATION_PACK)
	if st == player_station:
		await _job_player(it)
	else:
		await _job_fish(it, st, _station_fish(st))
	if gen != _belt_gen:
		return
	_jobs_left -= 1
	if _jobs_left <= 0:
		_jobs_left = 0
		jobs_done.emit()


## A fish hits the button, the press comes down, under it the food changes (rarely: ruined).
func _job_fish(it: Dictionary, st: int, fish: Node) -> void:
	await _play_npc_attack(fish, st)
	if state == State.DEAD or state == State.SHIFT_END:
		return
	var mistake = randf() < NPC_MISTAKE_CHANCE
	var node = it["node"]
	if mistake:
		await _play_press(st, func(): _break_item(it, st == STATION_PACK, false), node)
		if fish and state != State.DEAD and state != State.SHIFT_END:
			await _guard_hit_npc(fish)
	else:
		await _play_press(st, func(): _advance_item(it), node)


## The player's press: tutorial boxes go by themselves, the 4th one is the accident,
## after that it is the station's minigame.
func _job_player(it: Dictionary) -> void:
	_player_item = it
	var idx: int = it["index"]
	if current_shift == 1 and idx < AUTO_OBJECTS:
		_play_player_attack()
		await get_tree().create_timer(0.35, false).timeout
		if player_sprite and player_sprite.sprite_frames.has_animation("Idle"):
			player_sprite.play("Idle")
		await _player_press_result(true, false)
		return
	if current_shift == 1 and idx == AUTO_OBJECTS:
		if player and player.has_method("set_movement_blocked"):
			player.set_movement_blocked(false)
		await _player_press_result(false)
		_set_hud_visible(true)
		_show_gui()
		return
	if not _is_player_in_zone():
		await _player_press_result(false)
		return
	if state == State.INSPECT:
		_exit_inspect()
	if player_gui and not player_gui.visible:
		_show_gui()
	_start_minigame(player_station)
	await player_job_finished


## One step of the food is done (at the packing press: it is packed).
func _advance_item(it: Dictionary) -> void:
	var node = it["node"]
	if it["slot"] >= BELT_PACK_SLOT:
		_apply_stage(node, SUSHI_STAGE_PACKED, false)
		it["done"] = true
		correct_count += 1
		_mark_progress(it["index"], true)
		_resolved += 1
		current_object_index = _resolved
	else:
		_apply_stage(node, it["slot"], false)


func _break_item(it: Dictionary, packing: bool = false, animate: bool = true) -> void:
	if it["broken"] or it["done"]:
		return
	it["broken"] = true
	wrong_count += 1
	_mark_progress(it["index"], false)
	_resolved += 1
	current_object_index = _resolved
	var obj: Node2D = it["node"]
	if not is_instance_valid(obj):
		return
	_load_sushi_textures()
	var stage = SUSHI_STAGE_PACKED if packing else clamp(int(obj.get_meta("sushi_stage", 0)), 0, SUSHI_STAGES.size() - 1)
	var spr = obj.get_node_or_null("Sprite") as Sprite2D
	var tex: Texture2D = _sushi_broken_textures[stage] if stage < _sushi_broken_textures.size() else null
	if spr and tex:
		spr.texture = tex
		spr.position = Vector2(-tex.get_width() * SUSHI_SCALE / 2.0, -tex.get_height() * SUSHI_SCALE)
		obj.set_meta("sushi_stage", stage)
		obj.set_meta("sushi_broken", true)
		spr.modulate = Color(1.0, 0.55, 0.5)
		var tw = create_tween()
		if animate:
			tw.tween_property(obj, "scale", Vector2(1.2, 0.8), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(obj, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(spr, "modulate", Color(1, 0.85, 0.82), 0.4)
	elif spr:
		spr.modulate = COLOR_BROKEN_TINT
		var tw2 = create_tween()
		tw2.tween_property(obj, "scale", Vector2(1.25, 0.6), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw2.parallel().tween_property(obj, "rotation", randf_range(-0.25, 0.25), 0.12)

func _spawn_next_object() -> void:
	_start_belt()

func _load_sushi_textures() -> void:
	if not _sushi_textures.is_empty():
		return
	for n in SUSHI_STAGES:
		var path = SUSHI_TEXTURE_DIR + "Factory_Sushi_" + n + "_Texture.png"
		_sushi_textures.append(load(path) if ResourceLoader.exists(path) else null)
		var bpath = SUSHI_TEXTURE_DIR + "Factory_Sushi_" + n + "_Broken_Texture.png"
		_sushi_broken_textures.append(load(bpath) if ResourceLoader.exists(bpath) else null)

## Shows the given step of the sushi on the current object (with a small squash "pop").
func _set_object_stage(stage: int, pop: bool = true) -> void:
	_apply_stage(current_object, stage, pop)


func _apply_stage(obj: Node2D, stage: int, pop: bool = true) -> void:
	if obj == null or not is_instance_valid(obj):
		return
	_load_sushi_textures()
	stage = clamp(stage, 0, SUSHI_STAGES.size() - 1)
	if int(obj.get_meta("sushi_stage", -1)) == stage:
		return
	obj.set_meta("sushi_stage", stage)
	var spr = obj.get_node_or_null("Sprite") as Sprite2D
	if spr == null:
		return
	var tex: Texture2D = _sushi_textures[stage]
	if tex == null:
		return
	spr.texture = tex
	# bottom centre of the sprite sits on the belt
	spr.position = Vector2(-tex.get_width() * SUSHI_SCALE / 2.0, -tex.get_height() * SUSHI_SCALE)
	if pop:
		obj.scale = Vector2(1.18, 0.82)
		var tw = create_tween()
		tw.tween_property(obj, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_object_color(c: Color) -> void:
	if current_object == null:
		return
	var rect = current_object.get_node_or_null("Rect")
	if rect:
		rect.color = c
	var spr = current_object.get_node_or_null("Sprite")
	if spr:
		spr.modulate = c

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
	for n in ["Outline", "Shine"]:
		var part = current_object.get_node_or_null(n)
		if part:
			part.visible = false
	if current_object.has_node("Sprite"):
		return
	var spr = Sprite2D.new()
	spr.name = "Sprite"
	spr.texture = tex
	spr.scale = Vector2(2, 2)
	spr.centered = false
	spr.position = Vector2(-tex.get_width(), -tex.get_height() * 2.0)
	current_object.add_child(spr)
	# little "pop" when the blank becomes a finished box
	spr.scale = Vector2(2.3, 1.7)
	var tw = create_tween()
	tw.tween_property(spr, "scale", Vector2(2, 2), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Safe "play and wait": waits by a timer computed from the animation length, so a looping
## or missing animation can never freeze the caller (this used to stop the belt / the guard).
func _play_and_wait(spr: AnimatedSprite2D, anim: StringName, max_time: float = 2.0) -> void:
	if spr == null or not is_instance_valid(spr) or spr.sprite_frames == null:
		return
	if not spr.sprite_frames.has_animation(anim):
		await get_tree().create_timer(0.25, false).timeout
		return
	spr.play(anim)
	var dur := 0.35
	if not spr.sprite_frames.get_animation_loop(anim):
		var spd = max(spr.sprite_frames.get_animation_speed(anim) * abs(spr.speed_scale), 0.01)
		var total := 0.0
		for i in range(spr.sprite_frames.get_frame_count(anim)):
			total += spr.sprite_frames.get_frame_duration(anim, i)
		dur = total / spd
	await get_tree().create_timer(clamp(dur, 0.05, max_time), false).timeout

## The press comes down, covers the sushi, and only while it is down `on_impact` is called
## (that is where the sushi changes). Then the foot lifts and the sushi springs back up.
func _play_press(press_index: int, on_impact: Callable = Callable(), target: Node2D = null) -> void:
	var press: AnimatedSprite2D = null
	if press_index >= 0 and press_index < presses.size():
		press = presses[press_index]
	var obj = target if target != null else current_object
	if press == null or press.sprite_frames == null or not press.sprite_frames.has_animation("press_down"):
		if on_impact.is_valid():
			on_impact.call()
		return
	if obj and is_instance_valid(obj):
		obj.z_index = Z_FOOD_UNDER_PRESS
	await _play_and_wait(press, "press_down", 1.2)
	if state == State.DEAD:
		return
	# foot is down: flatten the sushi under it and change it while it is hidden
	if obj and is_instance_valid(obj):
		obj.scale = Vector2(1.2, 0.5)
		obj.visible = false   # fully under the foot while it changes
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.06)
	if on_impact.is_valid():
		on_impact.call()
	await get_tree().create_timer(PRESS_HOLD_TIME, false).timeout
	if press.sprite_frames.has_animation("press_up"):
		press.play("press_up")
	if obj and is_instance_valid(obj):
		obj.visible = true
		var tw = create_tween()
		tw.tween_property(obj, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _play_and_wait(press, "press_up", 1.2)
	if obj and is_instance_valid(obj):
		obj.z_index = Z_FOOD

func _play_npc_attack(fish: Node, press_index: int = -1) -> void:
	if fish == null or not is_instance_valid(fish):
		return
	if fish is AnimatedSprite2D and fish.sprite_frames:
		fish.flip_h = true
		var has_left = fish.sprite_frames.has_animation("AttackLeft")
		var has_right = fish.sprite_frames.has_animation("AttackRight")
		var anim = ""
		if has_left and has_right:
			anim = "AttackLeft" if (randi() % 2 == 0) else "AttackRight"
		elif has_left:
			anim = "AttackLeft"
		elif has_right:
			anim = "AttackRight"
		if anim != "":
			fish.play(anim)
			# the fist reaches the button about 40% into the punch
			var total = _anim_time(fish, anim)
			await get_tree().create_timer(total * 0.4, false).timeout
			_press_button_light(press_index)
			await get_tree().create_timer(total * 0.6, false).timeout
			if is_instance_valid(fish) and fish.sprite_frames.has_animation("idle"):
				fish.play("idle")
			return
	_press_button_light(press_index)
	await get_tree().create_timer(0.3, false).timeout


func _anim_time(spr: AnimatedSprite2D, anim: StringName) -> float:
	if spr == null or spr.sprite_frames == null or not spr.sprite_frames.has_animation(anim):
		return 0.3
	var spd = max(spr.sprite_frames.get_animation_speed(anim) * abs(spr.speed_scale), 0.01)
	var total := 0.0
	for i in range(spr.sprite_frames.get_frame_count(anim)):
		total += spr.sprite_frames.get_frame_duration(anim, i)
	return clamp(total / spd, 0.1, 1.5)


## Little light on the press cabinet button: it is pushed (dips) and glows.
func _setup_press_buttons() -> void:
	for p in presses:
		if p == null:
			continue
		var b = ColorRect.new()
		b.name = "ButtonLight"
		b.color = Color(1.0, 0.95, 0.7, 0.0)
		b.position = PRESS_BUTTON_LOCAL
		b.size = Vector2(2, 2)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(b)


func _press_button_light(press_index: int) -> void:
	if press_index < 0 or press_index >= presses.size() or presses[press_index] == null:
		return
	var b = presses[press_index].get_node_or_null("ButtonLight") as ColorRect
	if b == null:
		return
	b.position = PRESS_BUTTON_LOCAL + Vector2(0, 0.5)
	b.color = Color(1.0, 0.95, 0.7, 1.0)
	var tw = b.create_tween()
	tw.tween_property(b, "color", Color(1.0, 0.3, 0.25, 0.0), 0.35)
	tw.parallel().tween_property(b, "position", PRESS_BUTTON_LOCAL, 0.12).set_delay(0.12)

func _play_player_attack() -> void:
	if player == null or player_sprite == null:
		return
	_face_player_to_press()
	# use the player's own attack so its state machine does not override the animation
	if player.has_method("_do_attack") and not bool(player.get("is_attacking")):
		player._do_attack()
		return
	var anim = "AttackLeft" if (randi() % 2 == 0) else "AttackRight"
	if player_sprite.sprite_frames.has_animation(anim):
		player_sprite.play(anim)

## Player's station result: right after the minigame the fish punches the button, the press
## comes down and at the moment of impact the step is done (or the food is ruined).
func _player_press_result(success: bool, punish: bool = true) -> void:
	var it = _player_item
	_player_item = null
	var st = player_station
	if state == State.MINIGAME:
		state = State.WORKING
	if it == null or not is_instance_valid(it["node"]):
		player_job_finished.emit()
		return
	await get_tree().create_timer(0.18, false).timeout   # the fist reaches the button
	_press_button_light(st)
	var node = it["node"]
	if success:
		await _play_press(st, func(): _advance_item(it), node)
	else:
		await _play_press(st, func(): _break_item(it, st == STATION_PACK, false), node)
		if punish and state != State.DEAD and state != State.SHIFT_END:
			_guard_hit_player()
	player_job_finished.emit()

func _show_gui() -> void:
	if player_gui == null:
		return
	player_gui.visible = true
	var container = player_gui.get_node_or_null("UI_Container")
	if container and container is Control:
		# the container is hidden in the Mecha_Fish scene itself
		container.visible = true
		var air = container.get_node_or_null("Air_Bar")
		if air:
			air.visible = false   # no air meter inside the mech
		container.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(container, "modulate:a", 1.0, 0.5)
	_update_stress_bar()

func _process_minigame(delta: float) -> void:
	if _mg_flash > 0.0:
		_mg_flash = max(0.0, _mg_flash - delta * 3.0)
		if _mg_canvas:
			_mg_canvas.queue_redraw()
	if not minigame_active:
		return
	mg_time += delta
	match mg_kind:
		MG.SLIDER:
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
			# the slider moves in whole texture pixels, like the rest of the pixel art
			var sx = TRACK_X0 + slider_pos * TRACK_WIDTH - minigame_slider.size.x / 2.0
			minigame_slider.position.x = round(sx / (MG_SCALE / 2.0)) * (MG_SCALE / 2.0)
			_update_minigame_fill()
		MG.LOCK:
			mg_angle = fposmod(mg_angle + mg_dir * mg_speed * delta, TAU)
			if mg_time >= mg_timeout:
				_on_minigame_edge_fail()
				return
		MG.RING:
			mg_ring_r -= mg_ring_speed * delta
			if mg_ring_r < RING_TARGET - 12.0:
				_on_minigame_edge_fail()
				return
		MG.CUT:
			mg_knife += mg_speed * delta
			# passed a mark without cutting it
			if mg_hits < mg_marks.size() and mg_knife > mg_marks[mg_hits] + 0.06:
				_on_minigame_edge_fail()
				return
			if mg_knife >= 1.0:
				_on_minigame_edge_fail()
				return
		MG.GAUGE:
			# pressure keeps building and wobbles; past the top it bursts
			mg_vel += (0.22 + 0.5 * mg_level) * delta
			var wobble = sin(mg_time * 6.5) * 0.18 * delta
			mg_level = clamp(mg_level + mg_vel * delta + wobble, 0.0, 1.0)
			if mg_level >= 1.0:
				_on_minigame_edge_fail()
				return
	if _mg_canvas and _mg_canvas.visible:
		_mg_canvas.queue_redraw()

func _on_minigame_edge_fail() -> void:
	if not minigame_active:
		return
	minigame_active = false
	hint_label.visible = false
	_flash_minigame(false)
	await _player_press_result(false)

func _press_button() -> void:
	if not minigame_active:
		return
	UISounds.play_click()
	var hit = _mg_hit_now()
	# ring / cut: several hits in a row
	if (mg_kind == MG.RING or mg_kind == MG.CUT) and hit and mg_hits < mg_hits_need - 1:
		if randf() * 100.0 >= _get_miss_chance():
			mg_hits += 1
			_mg_flash = 1.0
			_mg_flash_good = true
			if mg_kind == MG.RING:
				mg_ring_r = 86.0
				mg_ring_speed *= 1.12
			if camera and camera.has_method("add_trauma"):
				camera.add_trauma(0.04)
			_mg_canvas.queue_redraw()
			return
		hit = false
	# lock: every pin is a separate press; only the last one finishes the minigame
	if mg_kind == MG.LOCK and hit and mg_pin_index < mg_pins.size() - 1:
		if randf() * 100.0 < _get_miss_chance():
			hit = false
		else:
			mg_pin_index += 1
			mg_dir = -mg_dir
			mg_speed *= 1.15
			_mg_flash = 1.0
			_mg_flash_good = true
			if camera and camera.has_method("add_trauma"):
				camera.add_trauma(0.05)
			_mg_canvas.queue_redraw()
			return
	minigame_active = false
	hint_label.visible = false
	_play_player_attack()
	var missed = randf() * 100.0 < _get_miss_chance()
	if missed:
		# stress: the fin slips even if the timing was right
		await _stress_miss_effect()
		_flash_minigame(false)
		await _player_press_result(false)
		return
	if not _is_player_in_zone():
		_flash_minigame(false)
		await _player_press_result(false)
		return
	_flash_minigame(hit)
	await _player_press_result(hit)

## Hides the minigame after a short green / red flash.
func _flash_minigame(good: bool) -> void:
	_hide_minigame_ui(good)

func _stress_miss_effect() -> void:
	if mg_kind != MG.SLIDER and _mg_canvas:
		var p0 = _mg_canvas.position
		var t2 = create_tween()
		t2.set_loops(4)
		t2.tween_property(_mg_canvas, "position:x", p0.x + 8, 0.04)
		t2.tween_property(_mg_canvas, "position:x", p0.x - 8, 0.04)
		t2.tween_property(_mg_canvas, "position:x", p0.x, 0.04)
		await get_tree().create_timer(0.5).timeout
		_mg_canvas.position = p0
		return
	var original_pos = minigame_panel.position
	var tween = create_tween()
	tween.set_loops(4)
	tween.tween_property(minigame_panel, "position:x", original_pos.x + 8, 0.04)
	tween.tween_property(minigame_panel, "position:x", original_pos.x - 8, 0.04)
	tween.tween_property(minigame_panel, "position:x", original_pos.x, 0.04)
	await get_tree().create_timer(0.5).timeout
	minigame_panel.position = original_pos

func _guard_hit_player() -> void:
	if player == null or guard_sprite == null:
		return
	if guard_changing:
		return
	await _guard_wait_free()
	_guard_busy = true
	var orig_pos = guard_sprite.position
	var orig_flip = guard_sprite.scale.x
	var target = player.global_position + Vector2(-40, -20)
	await _guard_walk_to(target)
	if player.global_position.x > guard_sprite.position.x:
		if guard_sprite.sprite_frames.has_animation("attack_right"):
			guard_sprite.play("attack_right")
		guard_sprite.scale.x = abs(guard_sprite.scale.x)
	else:
		if guard_sprite.sprite_frames.has_animation("attack_left"):
			guard_sprite.play("attack_left")
		guard_sprite.scale.x = -abs(guard_sprite.scale.x)
	_guard_lunge()
	await get_tree().create_timer(0.15).timeout
	UISounds.play_hit()
	if player.has_method("take_damage"):
		player.take_damage(1)
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.15)
	await get_tree().create_timer(0.35, false).timeout
	await _guard_walk_to(orig_pos)
	guard_sprite.scale.x = orig_flip
	if guard_sprite.sprite_frames.has_animation("idle"):
		guard_sprite.play("idle")
	_guard_busy = false
	_update_stress_from_hp()
	if player.has_method("get_hp"):
		if player.get_hp() <= 0:
			player.die()

## Guard hits are queued: one at a time, so two tweens never fight over his position.
func _guard_wait_free() -> void:
	var waited := 0.0
	while _guard_busy and waited < 4.0:
		await get_tree().create_timer(0.1, false).timeout
		waited += 0.1
	_guard_busy = false

## The guard has no attack sheet, so the hit is a quick lunge toward the facing side.
func _guard_lunge() -> void:
	if guard_sprite == null:
		return
	var base = guard_sprite.position
	var dir = sign(guard_sprite.scale.x)
	if dir == 0:
		dir = 1
	var tw = create_tween()
	tw.tween_property(guard_sprite, "position:x", base.x + 12.0 * dir, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(guard_sprite, "position:x", base.x, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _guard_hit_npc(fish: Node) -> void:
	if fish == null or guard_sprite == null:
		return
	if guard_changing:
		return
	if not is_instance_valid(fish):
		return
	await _guard_wait_free()
	_guard_busy = true
	var orig_pos = guard_sprite.position
	var orig_flip = guard_sprite.scale.x
	var fish_pos = fish.global_position
	var target = fish_pos + Vector2(-30, -10)
	await _guard_walk_to(target)
	if fish_pos.x > guard_sprite.position.x:
		if guard_sprite.sprite_frames.has_animation("attack_right"):
			guard_sprite.play("attack_right")
		guard_sprite.scale.x = abs(guard_sprite.scale.x)
	else:
		if guard_sprite.sprite_frames.has_animation("attack_left"):
			guard_sprite.play("attack_left")
		guard_sprite.scale.x = -abs(guard_sprite.scale.x)
	_guard_lunge()
	await get_tree().create_timer(0.15).timeout
	UISounds.play_hit()
	if fish is AnimatedSprite2D:
		var tw = create_tween()
		tw.tween_property(fish, "modulate", Color(1, 0.4, 0.4), 0.1)
		tw.tween_property(fish, "modulate", Color(1, 1, 1, 1), 0.25)
		if fish.sprite_frames and fish.sprite_frames.has_animation("hit"):
			await _play_and_wait(fish, "hit", 1.0)
			if is_instance_valid(fish) and fish.sprite_frames.has_animation("idle"):
				fish.play("idle")
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.1)
	await get_tree().create_timer(0.35, false).timeout
	await _guard_walk_to(orig_pos)
	guard_sprite.scale.x = orig_flip
	if guard_sprite.sprite_frames.has_animation("idle"):
		guard_sprite.play("idle")
	_guard_busy = false

func _mark_progress(index: int, correct: bool) -> void:
	if index < 0 or index >= progress_bar.get_child_count():
		return
	var cell = progress_bar.get_child(index) as ColorRect
	if cell:
		cell.color = COLOR_GREEN if correct else COLOR_RED
	if index < _box_states.size():
		_box_states[index] = 1 if correct else 2
	if _hud_panel:
		_hud_panel.queue_redraw()

func _is_progress_bar_perfect() -> bool:
	for i in range(progress_bar.get_child_count()):
		var cell = progress_bar.get_child(i) as ColorRect
		if cell and cell.color.is_equal_approx(COLOR_RED):
			return false
	return true

func _handle_action_strike() -> void:
	if action_strike_count == ACTION_STRIKE_WARNING:
		if state == State.SHIFT_END:
			_show_guard_dialog("ЧЕГО ВСТАЛ?! БЕГОМ НА ТЕХОБСЛУЖИВАНИЕ!", 2.5)
		else:
			_show_guard_dialog("ЭЙ! РАБОТАЙ, А НЕ ОТВЛЕКАЙСЯ!", 2.5)
	elif action_strike_count >= ACTION_STRIKE_DEATH:
		_sniper_kill_player()

func _sniper_kill_player() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	conveyor_paused = true
	minigame_panel.visible = false
	if _mg_canvas:
		_mg_canvas.visible = false
	if _mg_title:
		_mg_title.visible = false
	hint_label.visible = false
	if sniper_sprite and sniper_sprite.sprite_frames and sniper_sprite.sprite_frames.has_animation("fire"):
		sniper_sprite.play("fire")
	var sniper_pos = sniper_sprite.global_position if sniper_sprite else Vector2(1060, 60)
	var player_pos = player.global_position + Vector2(0, -20) if player else Vector2.ZERO
	var tracer = Line2D.new()
	tracer.width = 2.0
	tracer.default_color = Color(1, 1, 1, 1)
	tracer.add_point(sniper_pos)
	tracer.add_point(player_pos)
	tracer.z_index = 100
	add_child(tracer)
	var bullet = ColorRect.new()
	bullet.color = Color(1, 1, 0.2, 1)
	bullet.size = Vector2(8, 8)
	bullet.position = sniper_pos - bullet.size / 2.0
	bullet.z_index = 101
	add_child(bullet)
	var dist = sniper_pos.distance_to(player_pos)
	var fly_time = clamp(dist / 3000.0, 0.2, 0.5)
	var tween = create_tween()
	tween.tween_property(bullet, "position", player_pos - bullet.size / 2.0, fly_time)
	await tween.finished
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.6)
	if is_instance_valid(tracer):
		var fade = create_tween()
		fade.tween_property(tracer, "modulate:a", 0.0, 0.2)
	if is_instance_valid(bullet):
		var fade2 = create_tween()
		fade2.tween_property(bullet, "modulate:a", 0.0, 0.2)
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(tracer):
		tracer.queue_free()
	if is_instance_valid(bullet):
		bullet.queue_free()
	if player and player.has_method("die"):
		player.die()

func _end_shift() -> void:
	if state == State.DEAD or state == State.SHIFT_END:
		return
	if state == State.INSPECT:
		_exit_inspect()
	if journal_open:
		_on_journal_close()
	state = State.SHIFT_END
	shift_time = 1.0
	_update_clock_label()
	_update_wall_clock()
	conveyor_paused = true
	shift_end_npc_timer = 0.0
	follow_strike_timer = 0.0
	npc_walk_delays.clear()
	for i in range(npc_fishes.size()):
		npc_walk_delays.append(randf_range(NPC_WALK_DELAY_MIN, NPC_WALK_DELAY_MAX))
	_show_guard_dialog("РАБОТА НА СЕГОДНЯ ВЫПОЛНЕНА! ВСЕ НА ТЕХОБСЛУЖИВАНИЕ И НАЗАД!", 3.0)
	if _is_progress_bar_perfect():
		if has_node("/root/Achievements"):
			var was = Achievements.worker_of_month_unlocked
			Achievements.unlock_worker_of_month()
			if not was:
				_show_worker_of_month_achievement()
	_fade_and_new_shift()

func _fade_and_new_shift() -> void:
	await get_tree().create_timer(2.5).timeout
	if fade_rect:
		fade_rect.visible = true
		fade_rect.color = Color(0, 0, 0, 0)
		var tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
	await get_tree().create_timer(0.5).timeout
	_start_new_shift()
	if fade_rect:
		var tween2 = create_tween()
		tween2.tween_property(fade_rect, "color:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween2.finished
		fade_rect.visible = false

func _randomize_npc_positions() -> void:
	for i in range(npc_fishes.size()):
		var fish = npc_fishes[i]
		if fish == null:
			continue
		var x: float = _get_stop_zone_x(i) + NPC_PRESS_OFFSET_X
		var y: float = CONVEYOR_Y - 42.0
		fish.position = Vector2(x, y)
		if fish is AnimatedSprite2D:
			fish.flip_h = true   # faces the button on its press
		if fish is AnimatedSprite2D and fish.sprite_frames and fish.sprite_frames.has_animation("idle"):
			fish.play("idle")
		var identity = npc_identities.get(fish, "")
		if identity != "":
			_update_npc_inspect_position(identity, fish.position)

func _get_player_shift_spawn() -> Vector2:
	# 50%: packing (the usual place); otherwise one of the 4 presses - its fish goes to packing
	if current_shift >= 2 and randf() >= 0.5:
		player_station = randi() % NUM_NPC_FISHES
	else:
		player_station = STATION_PACK
	_place_station_workers()
	var spawn = Vector2(_get_stop_zone_x(player_station) + NPC_PRESS_OFFSET_X, 351)
	player_turn_x = spawn.x
	player_zone_center = Vector2(spawn.x, PLAYER_ZONE_CENTER.y)
	_update_work_zone_position()
	return spawn


## Fish stand at their presses; when the player took a press, its fish works the packing press.
func _place_station_workers() -> void:
	if player_station == STATION_PACK:
		return
	var fish = npc_fishes[player_station] if player_station < npc_fishes.size() else null
	if fish == null:
		return
	fish.position = Vector2(_get_stop_zone_x(STATION_PACK) + NPC_PRESS_OFFSET_X, CONVEYOR_Y - 42.0)
	var identity = npc_identities.get(fish, "")
	if identity != "":
		_update_npc_inspect_position(identity, fish.position)


## Who works station st: the player or a fish node.
func _station_fish(st: int) -> Node:
	if st == player_station:
		return null
	if st == STATION_PACK:
		return npc_fishes[player_station] if player_station < npc_fishes.size() else null
	return npc_fishes[st] if st < npc_fishes.size() else null

func _face_player_to_press() -> void:
	if player == null:
		return
	if "facing_direction" in player:
		player.facing_direction = -1
	if player_sprite:
		player_sprite.scale.x = -abs(player_sprite.scale.x)

func _start_new_shift() -> void:
	current_shift += 1
	current_object_index = 0
	correct_count = 0
	wrong_count = 0
	action_strike_count = 0
	action_move_timer = 0.0
	follow_strike_timer = 0.0
	_strike_forgive = 0.0
	shift_time = 0.0
	guard_last_checked_hour = -1.0
	sniper_last_checked_hour = -1.0
	shift_end_npc_timer = 0.0
	if player and player.has_method("set_hp"):
		player.set_hp(5)
	elif player and "hp" in player:
		player.hp = 5
	for i in range(progress_bar.get_child_count()):
		var cell = progress_bar.get_child(i) as ColorRect
		if cell:
			cell.color = Color(0.2, 0.2, 0.2)
		if i < _box_states.size():
			_box_states[i] = 0
	_randomize_npc_positions()
	if player:
		player.position = _get_player_shift_spawn()
		_face_player_to_press()
		if current_shift >= 2:
			if player.has_method("set_movement_blocked"):
				player.set_movement_blocked(false)
		else:
			if player.has_method("set_movement_blocked"):
				player.set_movement_blocked(true)
	if guard_sprite:
		guard_sprite.position = GUARD_POSITION
		guard_sprite.visible = true
		if guard_sprite.sprite_frames.has_animation("idle"):
			guard_sprite.play("idle")
	if sniper_sprite:
		sniper_sprite.position = SNIPER_POSITION
		sniper_sprite.visible = true
		if sniper_sprite.sprite_frames.has_animation("idle"):
			sniper_sprite.play("idle")
	if elevator_back and elevator_back.sprite_frames and elevator_back.sprite_frames.has_animation("close"):
		elevator_back.animation = "close"
		elevator_back.frame = elevator_back.sprite_frames.get_frame_count("close") - 1
		elevator_back.stop()
	if elevator_front and elevator_front.sprite_frames and elevator_front.sprite_frames.has_animation("close"):
		elevator_front.animation = "close"
		elevator_front.frame = elevator_front.sprite_frames.get_frame_count("close") - 1
		elevator_front.stop()
	if current_shift >= 2:
		_set_hud_visible(true)
		_show_gui()
		_refresh_bind_hints()
		bind_hint_i.visible = true
		bind_hint_j.visible = true
	else:
		bind_hint_i.visible = false
		bind_hint_j.visible = false
	_update_shift_bars()
	_update_stress_from_hp()
	_update_escape_hint()
	state = State.WORKING
	_spawn_next_object()

func _check_escape_info_ready() -> void:
	if escape_info_shift == -1 and guard_shifts_found.size() >= 3 and sniper_shifts_found.size() >= 3:
		escape_info_shift = current_shift

func _update_escape_hint() -> void:
	if guard_shifts_found.size() < 3 or sniper_shifts_found.size() < 3:
		escape_hint.visible = false
		return
	if escape_info_shift == current_shift:
		escape_hint.text = "ДОЖДАТЬСЯ СМЕНЫ НА КОРОБКАХ. ПОБЕГ В ОКНО 13:00 - 13:15"
		escape_hint.visible = true
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
	inspect_camera_original_pos = player.global_position if player else Vector2.ZERO
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
		tw.tween_property(camera, "zoom", inspect_camera_original_zoom, 0.3)
		if player and camera.has_method("smooth_to"):
			camera.smooth_to(player.global_position, 0.2)
		elif player:
			camera.global_position = player.global_position
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
				_check_escape_info_ready()
				_update_escape_hint()
			elif special_type == "sniper_shift":
				var h = data.get("special_hour", 0.0)
				if not sniper_shifts_found.has(h):
					sniper_shifts_found.append(h)
				_update_shift_bars()
				_check_escape_info_ready()
				_update_escape_hint()
			var hl = inspect_highlight_rects.get(area, null)
			if is_instance_valid(hl):
				hl.visible = false
			inspect_targets.erase(area)
			return

func _show_inspect_text(title: String, phrase: String, _journal: String) -> void:
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
	if guard_shifts_found.size() >= 3 and sniper_shifts_found.size() >= 3:
		_add_journal_line("", Color.BLACK, 14)
		if elevator_inspected:
			_add_journal_line(">>> 13:00 - 13:15 ЕДИНСТВЕННОЕ ВРЕМЯ ДЛЯ ПОБЕГА ЧЕРЕЗ ЛИФТ <<<", Color.DARK_RED, 20)
		else:
			_add_journal_line(">>> 13:00 - 13:15 ЕДИНСТВЕННОЕ ВРЕМЯ ДЛЯ ПОБЕГА <<<", Color.DARK_RED, 20)

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
		_show_guard_dialog(phrases[randi() % phrases.size()], 2.0)

## The player's own line (elevator, escape): a bubble over the mech fish.
func _show_dialog(text: String, duration: float) -> void:
	_speech(player, NAME_PLAYER, COLOR_NAME_PLAYER, text, duration, false)

## The guard talks: a bubble over the guard (kept on screen with its tail pointing at him).
func _show_guard_dialog(text: String, duration: float) -> void:
	_speech(guard_sprite, NAME_GUARD, COLOR_NAME_GUARD, text, duration, true)


## Aquarium-style speech bubble in the world: the same nine-patch box, a shadow, a tail to
## the speaker, a name tag, pop-in, typewriter text with voice blips and a soft fade out.
func _speech(speaker: Node2D, who: String, who_color: Color, text: String, duration: float, guard_voice: bool) -> void:
	_bubble_gen += 1
	var gen = _bubble_gen
	if _bubble and is_instance_valid(_bubble):
		_bubble.queue_free()
	if dialog_panel:
		dialog_panel.visible = false
	is_dialog_active = true
	var font: Font = load(DIALOG_FONT_PATH)
	var box_tex: Texture2D = load(DIALOG_BOX_PATH)
	var pad = Vector2(7, 6)
	var ts = Vector2(60, 10)
	if font:
		ts = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, BUBBLE_MAX_W - pad.x * 2.0, BUBBLE_FONT)
	var sz = Vector2(max(ts.x + pad.x * 2.0 + 1.0, 46.0), ts.y + pad.y * 2.0 + 2.0).round()

	var b = Node2D.new()
	b.name = "SpeechBubble"
	b.z_as_relative = false
	b.z_index = 200
	add_child(b)
	_bubble = b
	var root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size = sz
	root.pivot_offset = Vector2(sz.x * 0.5, sz.y)
	b.add_child(root)
	var shadow = NinePatchRect.new()
	var panel = NinePatchRect.new()
	for np in [shadow, panel]:
		np.texture = box_tex
		np.patch_margin_left = 10
		np.patch_margin_right = 10
		np.patch_margin_top = 10
		np.patch_margin_bottom = 10
		np.size = sz
		np.mouse_filter = Control.MOUSE_FILTER_IGNORE
		np.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow.position = Vector2(2, 2)
	shadow.modulate = Color(0, 0, 0, 0.35)
	root.add_child(shadow)
	var tail_o = Polygon2D.new()
	tail_o.color = Color(0.06, 0.07, 0.1)
	root.add_child(tail_o)
	root.add_child(panel)
	var tail_f = Polygon2D.new()
	tail_f.color = Color(0.96, 0.97, 0.98)
	root.add_child(tail_f)
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pad
	lbl.size = sz - pad * 2.0
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.visible_characters = 0
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", BUBBLE_FONT)
	lbl.add_theme_color_override("font_color", Color(0.05, 0.05, 0.08))
	lbl.add_theme_constant_override("line_spacing", 1)
	lbl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)
	var tag = Label.new()
	tag.text = who
	tag.position = Vector2(5, -10)
	if font:
		tag.add_theme_font_override("font", font)
	tag.add_theme_font_size_override("font_size", BUBBLE_FONT)
	tag.add_theme_color_override("font_color", who_color)
	tag.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
	tag.add_theme_constant_override("outline_size", 3)
	tag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tag)

	# pop in
	root.scale = Vector2(0.6, 0.6)
	root.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(root, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(root, "modulate:a", 1.0, 0.12)

	var total = text.length()
	var life = duration + float(total) / BUBBLE_CPS
	var t := 0.0
	var shown := 0
	var shake := 0.0
	while t < life:
		_place_bubble(b, sz, speaker, tail_o, tail_f, t, shake)
		await get_tree().process_frame
		if gen != _bubble_gen or not is_instance_valid(b):
			return
		if get_tree().paused:
			continue
		var dt = get_process_delta_time()
		t += dt
		shake = max(0.0, shake - dt)
		var n = min(total, int(t * BUBBLE_CPS))
		if n > shown:
			var ch = text[n - 1]
			if ch != " " and (n / 2) != (shown / 2):
				if guard_voice:
					UISounds.play_mechanic()
				else:
					UISounds.play_scientist()
			if ch == "!":
				shake = 0.25
			shown = n
			lbl.visible_characters = n
	var out = create_tween()
	out.tween_property(root, "modulate:a", 0.0, 0.25)
	out.parallel().tween_property(root, "scale", Vector2(0.9, 0.9), 0.25)
	await out.finished
	if is_instance_valid(b):
		b.queue_free()
	if gen == _bubble_gen:
		_bubble = null
		is_dialog_active = false


## Keeps the bubble over its speaker, inside the camera view; the tail always points at him.
func _place_bubble(b: Node2D, sz: Vector2, speaker: Node2D, tail_o: Polygon2D, tail_f: Polygon2D, t: float, shake: float) -> void:
	var anchor = Vector2(_get_stop_zone_x(STATION_PACK), 300)
	if speaker and is_instance_valid(speaker):
		anchor = speaker.global_position + Vector2(0, -34)
	var pos = anchor - Vector2(sz.x * 0.5, sz.y + 12.0)
	var cam = get_viewport().get_camera_2d()
	if cam:
		var half = get_viewport().get_visible_rect().size / cam.zoom / 2.0
		var c = cam.get_screen_center_position()
		pos.x = clamp(pos.x, c.x - half.x + 6.0, c.x + half.x - sz.x - 6.0)
		pos.y = clamp(pos.y, c.y - half.y + 14.0, c.y + half.y - sz.y - 14.0)
	pos.y += round(sin(t * 2.2) * 1.0)
	if shake > 0.0:
		pos.x += round(sin(t * 80.0) * 2.0)
	b.global_position = pos.round()
	var tx = clamp(anchor.x - pos.x, 9.0, sz.x - 9.0)
	var top = Vector2(tx, sz.y - 2.0)
	tail_o.polygon = PackedVector2Array([top + Vector2(-6, 0), top + Vector2(6, 0), top + Vector2(0, 9)])
	tail_f.polygon = PackedVector2Array([top + Vector2(-4, -1), top + Vector2(4, -1), top + Vector2(0, 6)])

func _toggle_pause() -> void:
	if pausemenu == null or state == State.DEAD:
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
			if _is_action_key(event, "inspect") or event.keycode == KEY_ESCAPE:
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
		get_viewport().set_input_as_handled()
		if journal_open:
			_on_journal_close()
			return
		if state == State.DEAD:
			return
		_toggle_pause()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _is_action_key(event, "inspect"):
			if current_shift < 2:
				return
			if state == State.WORKING:
				_enter_inspect()
			get_viewport().set_input_as_handled()
		elif _is_action_key(event, "journal"):
			if current_shift < 2:
				return
			if journal_open:
				_on_journal_close()
			else:
				_open_journal()
			get_viewport().set_input_as_handled()

## Works with rebinds (InputRebind) and falls back to the default keys.
func _is_action_key(event: InputEventKey, action: String) -> bool:
	if InputMap.has_action(action) and event.is_action(action):
		return true
	match action:
		"inspect": return event.keycode == KEY_I and not InputMap.has_action(action)
		"journal": return event.keycode == KEY_J and not InputMap.has_action(action)
	return false

func _key_name(action: String) -> String:
	if has_node("/root/InputRebind"):
		var t = InputRebind.get_key_text(action)
		if t != "" and t != "Не назначено":
			return t
	return "E" if action == "interact" else action.to_upper()

func _refresh_bind_hints() -> void:
	var li = bind_hint_i.get_node_or_null("KeyButton/KeyLabel")
	if li:
		li.text = _key_name("inspect")
	var lj = bind_hint_j.get_node_or_null("KeyButton/KeyLabel")
	if lj:
		lj.text = _key_name("journal")

func _is_player_near_maintenance() -> bool:
	if player == null or maintenance_door == null:
		return false
	return player.global_position.distance_to(maintenance_door.global_position) < 150

func _near_elevator() -> bool:
	if player == null or elevator_door == null:
		return false
	return player.global_position.distance_to(elevator_door.global_position) < 150

func _enter_elevator() -> void:
	if guard_changing:
		_show_dialog("ЛИФТ ЗАНЯТ. ПОДОЖДИ.", 2.0)
		return
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
	await _await_elevator_anim("open")
	await get_tree().create_timer(1.0).timeout
	Global.autosave(Global.SCENE_HALLWAY)
	Global.goto_scene(Global.SCENE_HALLWAY)

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
