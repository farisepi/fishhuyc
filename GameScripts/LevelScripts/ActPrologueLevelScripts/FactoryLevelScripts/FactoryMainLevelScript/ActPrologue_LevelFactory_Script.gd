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
const Z_GUARD_WALK: int = 14    # the guard walking past: behind the presses (16) and the food
const COLOR_BROKEN_TINT := Color(1.0, 0.45, 0.4)
var _sushi_textures: Array = []
var _sushi_broken_textures: Array = []

const OBJECT_SPEED: float = 375.0
const NPC_WALK_SPEED: float = 205.0
const SAFE_ZONE_CENTER_X: float = 1230.0
const NPC_WALK_DELAY_MIN: float = 0.5
const NPC_WALK_DELAY_MAX: float = 1.0

const SHIFT_START_HOUR: float = 8.0
const SHIFT_END_HOUR: float = 18.0
const SHIFT_DURATION_HOURS: float = 10.0
const REAL_SHIFT_DURATION: float = 150.0   # ~25 boxes; only used for the guard / sniper change pauses now

const SHIFT_CHANGE_HOURS: float = 0.25
const SHIFT_CHANGE_REAL: float = (SHIFT_CHANGE_HOURS / SHIFT_DURATION_HOURS) * REAL_SHIFT_DURATION

const GUARD_SHIFTS: Array = [9.0, 13.0, 15.5, 17.0]
const SNIPER_SHIFTS: Array = [11.0, 13.0, 15.0]

const ESCAPE_WINDOW_START: float = 13.0
const ESCAPE_WINDOW_END: float = 13.25
const ESCAPE_WINDOW_REAL: float = 12.0   # the 15 minutes 13:00 - 13:15 last 12 seconds

const COLOR_GREEN := Color(0.2, 0.8, 0.3)
const COLOR_RED := Color(0.9, 0.2, 0.2)
const COLOR_YELLOW := Color(1, 0.9, 0.3)
const COLOR_BLUE := Color(0.3, 0.5, 0.8)
const COLOR_HIGHLIGHT_BLUE := Color(0.3, 0.7, 1.0, 0.25)
const COLOR_HIGHLIGHT_YELLOW := Color(1.0, 0.9, 0.3, 0.35)

const GUARD_DOG_COLOR := Color(0.4, 0.6, 1.0)
const GUARD_MONKEY_COLOR := Color(0.5, 1.0, 0.5)
const SNIPER_NORMAL_COLOR := Color(0.7, 0.85, 1.0)

const GUARD_POSITION := Vector2(-215, 339)   # feet on the same floor line as the fish
const GUARD_LIFT_POSITION := Vector2(-290, 325)
const SNIPER_POSITION := Vector2(1060, 60)
const GUARD_WALK_SPEED: float = 380.0

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
	20: 0.75,
	40: 2.5,
	60: 5.0,
	80: 12.5,
	100: 25.0,
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
		"journal": "Рабочий-Рыба в меха костюме. Илистый Прыгун. Носит дебильную шапку. Учёные почему-то зовут его Никита",
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
const SPAWN_EVERY: int = 1   # a new sushi every step: the belt is full, no gaps
const TOTAL_CYCLES: int = (TOTAL_OBJECTS - 1) * SPAWN_EVERY + BELT_PACK_SLOT   # the 25th box is packed in the last cycle
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
## ---- grading and streak ----
const PERFECT_Q: float = 0.6          # how close to the centre of the window counts as "ИДЕАЛЬНО"
const STREAK_REWARD: int = 5          # every 5 good jobs in a row: a reward
var _streak: int = 0
var _best_streak: int = 0
var _last_quality: float = 0.5
var _streak_label: Label = null
## ---- guard inspections ----
var _inspection_cycles: Array = []
var _inspection_active: bool = false
var _inspection_jobs_left: int = 0
var _inspection_bad: int = 0
## who is being checked: -1 = the player, else the station of the fish being checked
var _insp_station: int = -1
signal inspection_finished
## Before the accident on the 4th box (first shift) the fish can not do anything at all:
## no walking, no jumping, no attacks, no blocking, no dashing.
var _pre_accident_lock: bool = true
## incidents at the fish's press (see _roll_incident)
const MGE_NONE: int = 0
const MGE_FIRE: int = 1
const MGE_SHORT: int = 2
const MGE_STUCK: int = 3
const INCIDENT_CHANCE: float = 0.05
const STK_ZONE_W := [0.19, 0.16, 0.13]   # green zone of the stuck button, per punch
var _inc_canvas: Control = null
var _inc_active: bool = false
var _inc_kind: int = 0
var _inc_t: float = 0.0
var _inc_time: float = 1.0
var _inc_pressed: bool = false
var _inc_flash: float = 0.0
var _inc_flash_good: bool = true
var _inc_result: int = 0          # 0 running, 1 handled, -1 failed
var _fire_lv: Array = [0.0, 0.0, 0.0]
var _fire_tank: float = 1.0
var _fire_dry: bool = false
var _fire_spray: bool = false
var _fire_nozzle: float = 0.5
var _fire_phase: float = 0.0
var _fuse_charge: Array = [-1.0, -1.0, -1.0]
var _fuse_sel: float = 0.0
var _fuse_dir: float = 1.0
var _fuse_need: int = 4
var _fuse_left: int = 4
var _fuse_next: float = 0.0
var _fuse_speed: float = 1.15
var _stk_power: float = 0.0
var _stk_hits: int = 0
var _stk_need: int = 3
var _stk_tired: float = 0.0
var _stk_btn: float = 0.0
var _stk_was_held: bool = false
var _stk_zone: Vector2 = Vector2(0.62, 0.78)
var _halt: int = 0                 # > 0: somebody messed up - production and the clock stand still
var _clock_speed: float = 0.0      # (old) shift fraction per second for the current cycle
var _cycle_real_avg: float = 3.4
var _cycle_game_t: float = 0.0
var _clock_v: float = 0.0
## seconds one belt step takes (measured over the last shift, halts included)
var _shift_pace: float = 3.0
var _pace_sum: float = 0.0
var _pace_n: int = 0
const CLOCK_PACE_MIN: float = 2.2
const CLOCK_PACE_MAX: float = 6.0          # current, smoothed clock speed (shift fraction per second)
var _cycle_avg: float = 3.0        # how long a cycle usually takes (real seconds, without halts)
var _cycle_t0: int = 0
var _cycle_halted: float = 0.0
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
const BUBBLE_MAX_W: float = 140.0
const TYPEIN_EFFECT := preload("res://GameScripts/UIScripts/DialogScripts/Dialog_TypeIn_Effect.gd")
const BUBBLE_FONT: int = 8
const BUBBLE_CPS: float = 38.0
const BUBBLE_SCALE: float = 0.9
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
const CUT_TOL: float = 0.07
const RING_TOL: float = 10.0   # the roll: how far from the target ring still counts
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
const SAFE_ZONE_SHADER := "res://GameShaders/SharedShaders/Shared_SafeAura_Shader.gdshader"
const ZONE_FLOOR_Y: float = 381.0
const ZONE_AURA_H: float = 84.0
const ZONE_UNDER: float = 7.0
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
var conveyor_legs: Array = []   # static lower part of the conveyor (legs / frame)
const CONVEYOR_BELT_ROWS: int = 126   # texture rows 0..125 = the moving belt, below = the legs
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
var _clock_hands: Array = []   # [hour_hand, minute_hand]
var _hud_on: bool = true
var _hud_nodes: Array = []
var _clock_lcd: Control = null
var _clock_text: String = ""
var _wall_clock_hour: float = -1.0
var _stress_shown: float = 0.0
var _outline_nodes: Dictionary = {}
var _outlines_off: bool = false   # inspect area -> Array of CanvasItems with the outline shader
var _guard_frames_dog: SpriteFrames = null
var _guard_frames_monkey: SpriteFrames = null

var npc_identities: Dictionary = {}
var escape_info_shift: int = -1

var player_zone_center: Vector2 = PLAYER_ZONE_CENTER
var player_turn_x: float = PLAYER_TURN_X

const TUTORIAL := preload("res://GameScripts/UIScripts/TutorialScripts/Tutorial_Hints.gd")
var _tut = null
const FACTORY_FX := preload("res://GameScripts/LevelScripts/ActPrologueLevelScripts/FactoryLevelScripts/FactoryFXScript/Factory_Ambient_FX.gd")
var _fx = null
var _tut_out_zone := 0.0
var _tut_work_t := 0.0
var _tut_was_inspect := false


## ======================================================================== TUTORIAL (flashlight)
## A slow step-by-step lesson the first time (remembered in the save):
##  shift 1, after the accident (time stops): moving -> the safe zone -> (time goes) the first
##  job (can't fail) -> (time stops) stress -> (time goes) the guard's check;
##  later the first incident of each kind and the first job at a new station can't fail either;
##  shift 2, at the first guard change: inspect mode -> note the change -> the journal.
const SPOTLIGHT := preload("res://GameScripts/UIScripts/TutorialScripts/Tutorial_Spotlight.gd")
var _spot = null
var _tut_flags: Dictionary = {}
var _tut_stage: String = ""
var _tut_no_penalty: bool = false
var _tut_wait_guard_note: bool = false
var _tut_frozen: bool = false
var _tut_prev_ts: float = 1.0
var _tut_wait_key: String = ""
var _tut_key_hit: bool = false
var _shift_fade_lock: bool = false

func _tut_done(id: String) -> bool:
	return bool(_tut_flags.get(id, false))

func _tut_mark(id: String) -> void:
	if _tut_done(id):
		return
	_tut_flags[id] = true
	Global.factory_state["tut"] = _tut_flags.duplicate()
	Global.save_factory_state()

func _setup_spotlight() -> void:
	_spot = SPOTLIGHT.new()
	add_child(_spot)
	_spot.key_event.connect(_on_spot_key)

func _spot_show(title: String, body: String, keys: Array, target: Callable, dim: bool = true) -> void:
	if _spot:
		_spot.show_step(title, body, keys, target, dim)

func _on_spot_key(ev: InputEvent) -> void:
	if not _tut_frozen:
		return
	if ev is InputEventKey:
		if ev.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			return
		if _tut_wait_key != "" and _is_action_key(ev, _tut_wait_key):
			_tut_key_hit = true
			get_viewport().set_input_as_handled()

## Time slows down and stops (the tree is paused). Only the fish can move if player_moves.
func _tut_freeze(player_moves: bool = false) -> void:
	if _tut_frozen:
		return
	_tut_prev_ts = Engine.time_scale if Engine.time_scale > 0.05 else 1.0
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(Engine, "time_scale", max(0.04, _tut_prev_ts * 0.08), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	if not is_inside_tree():
		return
	_tut_frozen = true
	if player and player_moves:
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		if "ignore_pause" in player:
			player.ignore_pause = true
	_tree().paused = true
	Engine.time_scale = 1.0

func _tut_unfreeze() -> void:
	if not _tut_frozen:
		return
	_tut_frozen = false
	_tree().paused = false
	if player:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		if "ignore_pause" in player:
			player.ignore_pause = false
	Engine.time_scale = max(0.04, _tut_prev_ts * 0.08)
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(Engine, "time_scale", _tut_prev_ts, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished

func _tut_wait(t: float, progress: bool = false) -> void:
	var w := 0.0
	while w < t:
		await _tree().process_frame
		if not is_inside_tree():
			return
		w += get_process_delta_time() / max(0.05, Engine.time_scale) if not _tut_frozen else get_process_delta_time()
		if progress and _spot:
			_spot.set_progress(w / t)

func _tut_wait_for_key(action: String) -> void:
	_tut_wait_key = action
	_tut_key_hit = false
	while not _tut_key_hit and is_inside_tree():
		await _tree().process_frame
	_tut_wait_key = ""

# ---------------------------------------------------------------- screen rects for the light
func _world_to_screen(r: Rect2) -> Rect2:
	var xf = get_viewport().get_canvas_transform()
	var a = xf * r.position
	var b = xf * r.end
	return Rect2(Vector2(min(a.x, b.x), min(a.y, b.y)), (b - a).abs())

func _player_screen_rect() -> Rect2:
	if player == null:
		return Rect2(556, 300, 40, 40)
	return _world_to_screen(Rect2(player.global_position + Vector2(-26, -66), Vector2(52, 74)))

func _zone_screen_rect() -> Rect2:
	if work_zone_rect == null:
		return _player_screen_rect()
	return _world_to_screen(Rect2(work_zone_rect.offset_left, work_zone_rect.offset_top, work_zone_rect.offset_right - work_zone_rect.offset_left, work_zone_rect.offset_bottom - work_zone_rect.offset_top))

func _mg_screen_rect() -> Rect2:
	if mg_kind == MG.SLIDER and minigame_panel and minigame_panel.visible:
		return minigame_panel.get_global_rect().grow(6)
	if _mg_canvas:
		var w = 120.0 if mg_kind == MG.GAUGE else 200.0
		var h = 110.0 if mg_kind == MG.CUT else 200.0
		return Rect2(_mg_canvas.position + Vector2((200.0 - w) / 2.0, (200.0 - h) / 2.0 - 30.0), Vector2(w, h + 30.0))
	return Rect2(476, 214, 200, 200)

func _inc_screen_rect() -> Rect2:
	return Rect2(_inc_canvas.position + Vector2(0, -30), Vector2(200, 230)) if _inc_canvas else Rect2(476, 214, 200, 200)

func _stress_screen_rect() -> Rect2:
	if _hud_panel == null:
		return Rect2(900, 60, 200, 30)
	return Rect2(_hud_panel.position + Vector2(2, 24) * HUD_PX, Vector2(HUD_W - 4, 9) * HUD_PX)

func _guard_screen_rect() -> Rect2:
	if guard_sprite == null or not guard_sprite.visible:
		return _world_to_screen(Rect2(GUARD_POSITION + Vector2(-30, -50), Vector2(60, 70)))
	var r = _sprite_screen_rect(guard_sprite)
	if r.size == Vector2.ZERO:
		return _world_to_screen(Rect2(guard_sprite.global_position + Vector2(-30, -50), Vector2(60, 70)))
	return _world_to_screen(r)

func _guard_or_post_rect() -> Rect2:
	return _guard_screen_rect() if (guard_sprite and guard_sprite.visible) else _post_screen_rect()

func _post_screen_rect() -> Rect2:
	return _world_to_screen(Rect2(GUARD_POSITION + Vector2(-34, -54), Vector2(68, 76)))

func _act_screen_rect(right: bool) -> Rect2:
	if _act_strip == null:
		return Rect2(900, 120, 120, 40)
	var hw = _act_half_w() * HUD_PX
	return Rect2(_act_strip.position + Vector2(hw if right else 0.0, 0), Vector2(hw if not right else _act_strip.size.x - hw, _act_strip.size.y))

# ---------------------------------------------------------------- shift 1: the basics
## Right after the accident: time stops; learn to move, then the safe zone.
func _tut_basics_intro() -> void:
	await _tut_wait(2.4)   # the guard's line first
	if not is_inside_tree():
		return
	await _tut_freeze(true)
	if not is_inside_tree():
		return
	_spot_show("ДВИЖЕНИЕ", "Ты очнулся. Сейчас тебе нужно заново научиться двигаться: пройди влево или вправо, или подпрыгни.", ["A", "D", "ПРОБЕЛ"], _player_screen_rect)
	while is_inside_tree() and not _player_moving():
		await _tree().process_frame
	if not is_inside_tree():
		return
	_spot.done()
	await _tut_wait(0.9)
	if not is_inside_tree():
		return
	if player:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		if "ignore_pause" in player:
			player.ignore_pause = false
	_spot_show("БЕЗОПАСНАЯ ЗОНА", "Это безопасная зона. Если выйдешь из неё во время работы, охранник начнёт ругаться — так что лучше не выходи.", [], _zone_screen_rect)
	await _tut_wait(5.0, true)
	if not is_inside_tree():
		return
	_spot.hide_step()
	await _tut_unfreeze()

## The first job is done: time stops on the stress meter, then the guard comes for a check.
func _tut_after_first_job() -> void:
	_tut_stage = "stress"
	if _spot:
		_spot.done()
	await player_job_finished
	if not is_inside_tree():
		return
	await _tut_wait(0.4)
	if not is_inside_tree() or state == State.DEAD:
		return
	_spot.hide_step()
	await _tut_freeze(false)
	if not is_inside_tree():
		return
	_spot_show("СТРЕСС", "Чем выше уровень стресса, тем сильнее трясутся руки и тем больше шанс промахнуться, даже если нажал вовремя. Каждый удар охранника добавляет стресса.", [], _stress_screen_rect)
	await _tut_wait(5.0, true)
	if not is_inside_tree():
		return
	_spot.hide_step()
	await _tut_unfreeze()
	if not is_inside_tree():
		return
	_tut_stage = "check"
	_tut_no_penalty = false
	await _guard_wait_free()
	if not is_inside_tree() or state == State.DEAD or state == State.SHIFT_END:
		return
	_start_inspection(true)
	_spot_show("ПРОВЕРКА", "Охранник пришёл с проверкой: он смотрит две твои работы. Пройдёшь хорошо — стресс снизится. Покажешь себя плохо — тебе несдобровать.", [], _guard_screen_rect)
	var t := 0.0
	while is_inside_tree() and t < 5.0 and not minigame_active and _inspection_active:
		await _tree().process_frame
		t += get_process_delta_time()
	if _spot:
		_spot.hide_step()
	if _inspection_active:
		await inspection_finished
	if not is_inside_tree():
		return
	_tut_mark("basics")
	_tut_stage = ""

# ---------------------------------------------------------------- shift 2: inspect + journal
func _tut_inspect_flow() -> void:
	_halt += 1   # the belt and the clock wait for the lesson
	# let a running job finish first
	while is_inside_tree() and (minigame_active or _inc_active or state == State.MINIGAME or state == State.DEAD):
		await _tree().process_frame
	if not is_inside_tree() or state == State.DEAD or state == State.SHIFT_END:
		return
	if journal_open:
		_on_journal_close()
	if state == State.INSPECT:
		_exit_inspect()
	await _tut_wait(0.3)
	await _tut_freeze(false)
	if not is_inside_tree():
		return
	_spot_show("ОСМОТР", "Сейчас охранник уйдёт на пересменку. Включи режим осмотра: время замедлится, а всё интересное подсветится — его можно изучить мышкой.", [_key_name("inspect")], _act_screen_rect.bind(false))
	await _tut_wait_for_key("inspect")
	if not is_inside_tree():
		return
	_spot.done()
	await _tut_unfreeze()
	if not is_inside_tree():
		return
	_enter_inspect()
	_tut_wait_guard_note = true
	_guard_shift_sequence()
	var gh: float = GUARD_SHIFTS[0]
	_spot_show("ПЕРЕСМЕНКА", "Охранник уходит. Нажми на него мышкой (или на опустевший пост), чтобы записать время пересменки. Пока не запишешь — смены не будет.", [], _guard_or_post_rect, false)
	var hinted_out := false
	while is_inside_tree() and not guard_shifts_found.has(gh) and state != State.DEAD:
		if state != State.INSPECT and not hinted_out:
			hinted_out = true
			_spot.set_text("ПЕРЕСМЕНКА", "Сначала включи режим осмотра, потом нажми на охранника или на пустой пост.", [_key_name("inspect")])
		elif state == State.INSPECT and hinted_out:
			hinted_out = false
			_spot.set_text("ПЕРЕСМЕНКА", "Нажми мышкой на охранника или на опустевший пост, чтобы записать время пересменки.", [])
		await _tree().process_frame
	_tut_wait_guard_note = false
	if not is_inside_tree() or state == State.DEAD:
		return
	_spot.done()
	await _tut_wait(1.2)
	if not is_inside_tree():
		return
	await _tut_freeze(false)
	if not is_inside_tree():
		return
	_spot_show("ЖУРНАЛ", "Всё, что ты узнал, записывается в журнал: время пересменок охраны и снайпера и то, что ты осмотрел. Открой его.", [_key_name("journal")], _act_screen_rect.bind(true))
	await _tut_wait_for_key("journal")
	if not is_inside_tree():
		return
	_spot.hide_step()
	await _tut_unfreeze()
	if not is_inside_tree():
		return
	_open_journal()
	while is_inside_tree() and journal_open:
		await _tree().process_frame
	_tut_mark("inspect")
	_halt = max(0, _halt - 1)

# ---------------------------------------------------------------- the accident cutscene skip
## When the accident has been seen in this save: "ЗАЖМИ — ПРОПУСТИТЬ" in the corner (like the
## intro). Holding the mouse button fast-forwards (behind a black screen) to the end of it.
var _skip_layer: CanvasLayer = null
var _skip_ui: Control = null
var _skip_hold: float = 0.0
var _skip_t: float = 0.0
var _skipping: bool = false
const SKIP_HOLD_TIME := 1.0

func _setup_accident_skip() -> void:
	if not bool(Global.factory_state.get("accident_seen", false)) or current_shift != 1:
		return
	_skip_layer = CanvasLayer.new()
	_skip_layer.layer = 65
	add_child(_skip_layer)
	_skip_ui = Control.new()
	_skip_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_ui.size = Vector2(300, 44)
	_skip_ui.position = Vector2(1152 - 300 - 8, 8)
	_skip_ui.modulate.a = 0.0
	_skip_ui.draw.connect(_draw_skip_ui)
	_skip_layer.add_child(_skip_ui)
	_skip_process()

func _skip_process() -> void:
	while is_inside_tree() and _skip_ui and is_instance_valid(_skip_ui) and _pre_accident_lock and not _skipping:
		var dt = get_process_delta_time() / max(0.05, Engine.time_scale)
		_skip_t += dt
		var held = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _tree().paused
		_skip_hold = clamp(_skip_hold + (dt if held else -dt * 2.0) / SKIP_HOLD_TIME, 0.0, 1.0)
		var want = held or _skip_hold > 0.0 or (_skip_t > 0.3 and _skip_t < 3.0)
		_skip_ui.modulate.a = move_toward(_skip_ui.modulate.a, 1.0 if want else 0.0, dt * (2.5 if want else 1.6))
		_skip_ui.queue_redraw()
		if _skip_hold >= 1.0:
			_start_accident_skip()
			break
		await _tree().process_frame
	if _skip_ui and is_instance_valid(_skip_ui) and not _skipping:
		var tw = _skip_ui.create_tween()
		tw.tween_property(_skip_ui, "modulate:a", 0.0, 0.3)

func _draw_skip_ui() -> void:
	var c = _skip_ui
	var f = _bubble_font()
	var r = 13.0
	var ctr = Vector2(c.size.x - 22, 22)
	c.draw_arc(ctr, r, 0, TAU, 32, Color(1, 1, 1, 0.25), 3.0)
	if _skip_hold > 0.0:
		c.draw_arc(ctr, r, -PI / 2.0, -PI / 2.0 + TAU * _skip_hold, 32, Color(1.0, 0.75, 0.35), 3.0)
	if f:
		var kw = f.get_string_size("ЛКМ", HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		c.draw_string(f, ctr + Vector2(-kw * 0.5, 3), "ЛКМ", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.9))
		var txt = "ПРОПУСКАЮ..." if _skip_hold > 0.0 else "ЗАЖМИ — ПРОПУСТИТЬ"
		var tw = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		c.draw_string(f, Vector2(ctr.x - r - 10 - tw, 27), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.92, 0.93, 0.96, 0.9))

func _start_accident_skip() -> void:
	_skipping = true
	if fade_rect:
		fade_rect.visible = true
		fade_rect.color = Color(0, 0, 0, 0)
		var tw = create_tween()
		tw.tween_property(fade_rect, "color:a", 1.0, 0.3)
		await tw.finished
	if not is_inside_tree():
		return
	if _skip_ui and is_instance_valid(_skip_ui):
		_skip_ui.modulate.a = 0.0
	AudioServer.set_bus_mute(0, true)
	Engine.time_scale = 8.0

## The accident happened: back to normal speed and out of the black.
func _end_accident_skip() -> void:
	if not _skipping:
		if _skip_ui and is_instance_valid(_skip_ui):
			_skip_ui.queue_free()
			_skip_ui = null
		return
	_skipping = false
	Engine.time_scale = 1.0
	AudioServer.set_bus_mute(0, false)
	if _skip_ui and is_instance_valid(_skip_ui):
		_skip_ui.queue_free()
		_skip_ui = null
	if fade_rect:
		var tw = create_tween()
		tw.tween_property(fade_rect, "color:a", 0.0, 0.5)
		tw.tween_callback(func(): fade_rect.visible = false)

func _mark_accident_seen() -> void:
	if not bool(Global.factory_state.get("accident_seen", false)):
		Global.factory_state["accident_seen"] = true
		Global.save_factory_state()

# ---------------------------------------------------------------- save state (every shift)
func _load_factory_state() -> void:
	var fs: Dictionary = Global.factory_state
	_tut_flags = (fs.get("tut", {}) as Dictionary).duplicate() if fs.get("tut", {}) is Dictionary else {}

## Puts what is known into Global and autosaves at the start of a shift.
func _save_shift_state() -> void:
	var fs: Dictionary = Global.factory_state
	fs["shift"] = current_shift
	fs["guard_found"] = guard_shifts_found.duplicate()
	fs["sniper_found"] = sniper_shifts_found.duplicate()
	fs["notes"] = journal_notes.duplicate()
	fs["notes_full"] = journal_notes_full.duplicate()
	fs["elevator_inspected"] = elevator_inspected
	fs["escape_info_shift"] = escape_info_shift
	fs["tut"] = _tut_flags.duplicate()
	Global.factory_state = fs
	Global.autosave(Global.SCENE_FACTORY)

## Restart after a death / a loaded save: the run starts again at the saved shift.
func _restore_shift_progress() -> bool:
	var fs: Dictionary = Global.factory_state
	var sh = int(fs.get("shift", 1))
	if sh < 2:
		return false
	guard_shifts_found = (fs.get("guard_found", []) as Array).duplicate()
	sniper_shifts_found = (fs.get("sniper_found", []) as Array).duplicate()
	journal_notes = (fs.get("notes", []) as Array).duplicate()
	journal_notes_full = (fs.get("notes_full", {}) as Dictionary).duplicate()
	elevator_inspected = bool(fs.get("elevator_inspected", false))
	escape_info_shift = int(fs.get("escape_info_shift", -1))
	current_shift = sh - 1
	_pre_accident_lock = false
	if player:
		player.set_process_input(true)
	return true

## "Разнорабочий": all five stations in ONE save.
func _mark_station_worked(st: int) -> void:
	var arr: Array = Global.factory_state.get("stations", [])
	if st in arr:
		return
	arr.append(st)
	Global.factory_state["stations"] = arr
	Global.save_factory_state()
	if arr.size() >= NUM_NPC_FISHES + 1 and has_node("/root/Achievements") and Achievements.has_method("unlock_handyman"):
		Achievements.unlock_handyman()

## The SceneTree even while this node is being taken out of it (restart from the death
## screen): coroutines that wake up then must not crash on get_tree() == null.
func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

func _ready() -> void:
	randomize()
	_load_factory_state()
	_setup_spotlight()
	_tut = TUTORIAL.new()
	_tut.style = "factory"
	add_child(_tut)
	_fx = FACTORY_FX.new()
	add_child(_fx)
	_fx.setup(self)
	
	if is_instance_valid(Fade) and Fade.has_method("fade_in"):
		Fade.fade_in()
	
	_disable_actions_for_act2()
	
	if player:
		player.dash_cooldown = 999999.0
		player.block_click_attack = true
		# the tired "Jogging" of the fish has the same speed as the other fish walking
		if "jog_speed_mult" in player and "run_speed" in player and player.run_speed > 0.0:
			player.jog_speed_mult = NPC_WALK_SPEED / player.run_speed
	
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
	
	await _tree().process_frame
	if not is_inside_tree():
		return
	
	if player and "only_basic_moves" in player:
		player.only_basic_moves = true   # in the factory: walk, jump and attack only
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
	# a restart / a loaded save: straight into the saved shift
	if _restore_shift_progress():
		_start_new_shift()
	else:
		_setup_accident_skip()

## Where the food stops: right under the centre of the press foot (the part that comes down).
## The foot is texture columns 3..21 of the 44 px wide press frame.
const PRESS_FOOT_CX: float = 12.5

func _get_stop_zone_x(index: int) -> float:
	if index >= 0 and index < presses.size() and presses[index] != null:
		var p: AnimatedSprite2D = presses[index]
		var off = (PRESS_FOOT_CX - 22.0) * abs(p.scale.x)
		return p.global_position.x + (-off if p.flip_h else off)
	if index < 0 or index >= stop_zones.size():
		return FISH_START_X + index * FISH_SPACING
	var z = stop_zones[index]
	if z == null:
		return FISH_START_X + index * FISH_SPACING
	return z.global_position.x

func _is_box_in_zone(index: int, box_pos: Vector2, _box_size: Vector2) -> bool:
	if _box_processed_zones.has(index):
		return false
	if index < 0 or index >= stop_zones.size():
		return false
	var z = stop_zones[index]
	if z == null:
		return false
	var zone_pos = z.global_position
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
		await _tree().create_timer(13.0 / 14.0).timeout
		if not is_inside_tree():
			return

var _guard_tween: Tween = null
var _guard_walk_id: int = 0
var _guard_walking: bool = false

## The guard is not doing anything else and stands at his place (a fish only slips up then).
func _guard_free_at_post() -> bool:
	if guard_sprite == null or not guard_sprite.visible or guard_changing or _guard_busy or _guard_walking:
		return false
	if _guard_hits_queued > 0 or _halt > 0:
		return false
	return guard_sprite.position.distance_to(_guard_home()) <= 6.0

## Where the guard belongs right now: behind the player during an inspection, else his post.
func _guard_home() -> Vector2:
	if _inspection_active:
		return Vector2(_inspection_x() - 64.0, GUARD_POSITION.y)
	return GUARD_POSITION

## x of whoever is being checked right now.
func _inspection_x() -> float:
	if _insp_station >= 0:
		var f = _station_fish(_insp_station)
		if f and is_instance_valid(f):
			return f.global_position.x
	return player_turn_x

## Safety net: if the guard is left standing somewhere after a hit (two things moved him at
## once, a tween got cut...), he walks back to his place by himself.
func _guard_watchdog() -> void:
	if guard_sprite == null or not guard_sprite.visible or guard_changing or _guard_busy or _guard_walking:
		return
	if state == State.DEAD or state == State.SHIFT_END:
		return
	if guard_sprite.position.distance_to(_guard_home()) > 6.0:
		_guard_busy = true
		await _guard_walk_to(_guard_home())
		if guard_sprite.sprite_frames and guard_sprite.sprite_frames.has_animation("idle"):
			guard_sprite.play("idle")
		_guard_busy = false

func _guard_walk_to(target: Vector2) -> void:
	if guard_sprite == null:
		return
	# only one walk at a time: a new one replaces the old one (they used to fight)
	# (the old walk's await gives up as soon as the id changes - no tween stepping from
	# inside another tween's step any more)
	_guard_walk_id += 1
	var my_id = _guard_walk_id
	if _guard_tween and _guard_tween.is_valid():
		_guard_tween.kill()
	if target.x < guard_sprite.position.x:
		guard_sprite.scale.x = -abs(guard_sprite.scale.x)
	elif target.x > guard_sprite.position.x:
		guard_sprite.scale.x = abs(guard_sprite.scale.x)
	if guard_sprite.sprite_frames.has_animation("jogging"):
		guard_sprite.play("jogging")
	else:
		guard_sprite.play("idle")
	var dist = absf(guard_sprite.position.x - target.x) + absf(guard_sprite.position.y - GUARD_POSITION.y)
	var duration = dist / GUARD_WALK_SPEED
	if duration < 0.1:
		duration = 0.1
	target.y = GUARD_POSITION.y   # always on the floor, like the fish
	var tween = create_tween()
	_guard_tween = tween
	_guard_walking = true
	# on the way he goes behind the presses and the food (he used to hide the sushi);
	# when he stops (to hit or to watch) he is at the fish's level again
	if dist > 40.0:
		guard_sprite.z_index = Z_GUARD_WALK
	tween.tween_property(guard_sprite, "position", target, duration)
	while my_id == _guard_walk_id and tween.is_valid() and tween.is_running():
		await _tree().process_frame
		if not is_inside_tree():
			return
	if my_id == _guard_walk_id:
		_guard_walking = false
		guard_sprite.z_index = Z_CHARACTERS

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
	_reset_slowmo_now()

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
	var tex_sz = s.texture.get_size()
	var belt_h = min(float(CONVEYOR_BELT_ROWS), tex_sz.y)
	for i in range(conveyor_sprites.size()):
		var sp: Sprite2D = conveyor_sprites[i]
		sp.z_index = 30
		# the legs: a still copy of the lower part, on the tile's original place
		var legs = Sprite2D.new()
		legs.name = "ConveyorLegs%d" % i
		legs.texture = sp.texture
		legs.texture_filter = sp.texture_filter
		legs.scale = sp.scale
		legs.position = Vector2(conveyor_base_x + i * conveyor_tile_width, sp.position.y)
		legs.z_index = 30
		legs.centered = false
		legs.region_enabled = true
		legs.region_rect = Rect2(0, belt_h, tex_sz.x, tex_sz.y - belt_h)
		legs.offset = Vector2(-tex_sz.x * 0.5, belt_h - tex_sz.y * 0.5)
		add_child(legs)
		conveyor_legs.append(legs)
		# the belt itself: only the upper rows, it keeps scrolling
		sp.centered = false
		sp.region_enabled = true
		sp.region_rect = Rect2(0, 0, tex_sz.x, belt_h)
		sp.offset = -tex_sz * 0.5

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
	maintenance_safe_zone_rect.z_index = 31   # light: over the belt, under the food
	maintenance_safe_zone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# an aura rising from the floor, with particles drifting up (like the aquarium glass)
	var w = 170.0
	maintenance_safe_zone_rect.offset_left = SAFE_ZONE_CENTER_X - w / 2.0
	maintenance_safe_zone_rect.offset_top = ZONE_FLOOR_Y - ZONE_AURA_H
	maintenance_safe_zone_rect.offset_right = SAFE_ZONE_CENTER_X + w / 2.0
	maintenance_safe_zone_rect.offset_bottom = ZONE_FLOOR_Y + ZONE_UNDER
	_apply_zone_shader(maintenance_safe_zone_rect)
	add_child(maintenance_safe_zone_rect)
	_add_zone_particles(maintenance_safe_zone_rect, Color(0.45, 1.0, 0.6))

func _create_work_zone() -> void:
	work_zone_rect = ColorRect.new()
	work_zone_rect.name = "WorkZone"
	work_zone_rect.color = Color(0.3, 0.75, 1.0, 0.8)
	work_zone_rect.z_index = 31
	work_zone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_zone_shader(work_zone_rect)
	add_child(work_zone_rect)
	_update_work_zone_position()
	_add_zone_particles(work_zone_rect, Color(0.5, 0.85, 1.0))


func _apply_zone_shader(rect: ColorRect) -> void:
	var sh = load(SAFE_ZONE_SHADER)
	if sh == null:
		return
	var m = ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("strength", 1.0)
	m.set_shader_parameter("floor_h", ZONE_UNDER)
	rect.material = m
	var sz = Vector2(rect.offset_right - rect.offset_left, rect.offset_bottom - rect.offset_top)
	if sz.x > 0.0 and sz.y > 0.0:
		m.set_shader_parameter("rect_size", sz)
	rect.resized.connect(func():
		m.set_shader_parameter("rect_size", rect.size)
	)

## Little light motes that rise out of a zone's floor.
func _add_zone_particles(rect: ColorRect, col: Color) -> void:
	var p = CPUParticles2D.new()
	p.name = "AuraParticles"
	var img = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	p.texture = ImageTexture.create_from_image(img)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var w = rect.offset_right - rect.offset_left
	var h = rect.offset_bottom - rect.offset_top
	p.position = Vector2(w / 2.0, h - ZONE_UNDER)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(w * 0.42, 1.0)
	p.amount = 14
	p.lifetime = 2.2
	p.preprocess = 2.2
	p.direction = Vector2(0, -1)
	p.spread = 6.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 30.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var g = Gradient.new()
	g.set_color(0, Color(col, 0.0))
	g.add_point(0.15, Color(col, 0.9))
	g.set_color(1, Color(col, 0.0))
	p.color_ramp = g
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.use_parent_material = false
	rect.add_child(p)

func _update_work_zone_position() -> void:
	if work_zone_rect == null:
		return
	# the same floor aura under the player's spot (a bit lower)
	var h = ZONE_AURA_H * 0.7 + ZONE_UNDER
	var w = PLAYER_ZONE_SIZE.x + 30.0
	work_zone_rect.offset_left = player_zone_center.x - w / 2.0
	work_zone_rect.offset_top = ZONE_FLOOR_Y - ZONE_AURA_H * 0.7
	work_zone_rect.offset_right = player_zone_center.x + w / 2.0
	work_zone_rect.offset_bottom = ZONE_FLOOR_Y + ZONE_UNDER
	if work_zone_rect.material:
		work_zone_rect.material.set_shader_parameter("rect_size", Vector2(w, h))
	var parts = work_zone_rect.get_node_or_null("AuraParticles") as CPUParticles2D
	if parts:
		parts.position = Vector2(w / 2.0, h - ZONE_UNDER)
		parts.emission_rect_extents = Vector2(w * 0.42, 1.0)

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
	# exactly the aquarium's 1 HP glow (the fish HUD's red edge glow): same shader, same numbers
	var pulse_shader = Shader.new()
	pulse_shader.code = """
shader_type canvas_item;
uniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.0, 0.17);
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 dist = abs(UV - 0.5) * 2.0;
	float d = max(dist.x, dist.y);
	COLOR = vec4(glow_color.rgb, smoothstep(0.5, 1.0, d) * glow_color.a * pulse);
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
	# the fish HUD has its own copy of this glow; here it is drawn by the level instead (so it
	# also stays while the HUD is hidden) - the HUD one is switched off to not double it
	if player_gui and "glow_disabled" in player_gui:
		player_gui.glow_disabled = true
	if player_gui and "glow" in player_gui and player_gui.glow and player_gui.glow.visible:
		player_gui.glow.visible = false
	if hp <= 1 and hp > 0:
		low_hp_vignette.visible = true
		low_hp_vignette.modulate.a = 1.0
		_low_hp_pulse_time += delta
		(low_hp_vignette.material as ShaderMaterial).set_shader_parameter("pulse", 0.5 + 0.35 * sin(_low_hp_pulse_time * 2.4))
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
			var blink = int(Time.get_ticks_msec() / 500.0) % 2 == 0
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
	_inc_canvas = Control.new()
	_inc_canvas.name = "IncidentCanvas"
	_inc_canvas.position = Vector2(476, 214)
	_inc_canvas.size = Vector2(200, 200)
	_inc_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inc_canvas.visible = false
	_inc_canvas.draw.connect(_draw_incident)
	$UI.add_child(_inc_canvas)
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
		# a dark plate behind the minigame hint so it reads over the belt
		var hb = StyleBoxFlat.new()
		hb.bg_color = Color(0.02, 0.03, 0.06, 0.78)
		hb.border_color = Color(0.2, 0.23, 0.3, 0.9)
		hb.set_border_width_all(1)
		hb.content_margin_left = 10
		hb.content_margin_right = 10
		hb.content_margin_top = 4
		hb.content_margin_bottom = 4
		hint_label.add_theme_stylebox_override("normal", hb)
		hint_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
		hint_label.add_theme_constant_override("outline_size", 4)
	_mg_title.visible = false
	_mg_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the title sits on a small steel plate with an orange edge (it used to float bare)
	var tb = StyleBoxFlat.new()
	tb.bg_color = Color8(20, 22, 28, 240)
	tb.border_color = Color8(86, 96, 112)
	tb.set_border_width_all(2)
	tb.border_width_bottom = 4
	tb.shadow_color = Color(0, 0, 0, 0.45)
	tb.shadow_size = 3
	tb.shadow_offset = Vector2(2, 3)
	tb.content_margin_left = 14
	tb.content_margin_right = 14
	tb.content_margin_top = 3
	tb.content_margin_bottom = 4
	_mg_title.add_theme_stylebox_override("normal", tb)
	_mg_title.size = Vector2(0, 0)
	_mg_title.resized.connect(func(): _center_mg_title())
	$UI.add_child(_mg_title)
	if minigame_slider:
		minigame_slider.z_index = 1
		minigame_slider.size.x = 9.0   # thin needle (3 texture pixels at 3x)


## The title plate hugs its text and stays centred over the window.
func _center_mg_title() -> void:
	if _mg_title == null:
		return
	var cx = 576.0
	_mg_title.position.x = round(cx - _mg_title.size.x * 0.5)
	var sb = _mg_title.get_theme_stylebox("normal") as StyleBoxFlat
	if sb:
		sb.border_color = Color8(86, 96, 112)

## Mini tutorial: short hints the first time something new happens.
func _tutorial_tick(delta: float) -> void:
	# (the old short hints are replaced by the step-by-step tutorial with the flashlight)
	if true:
		return
	if _tut == null or state == State.DEAD:
		return
	var dt = delta / max(0.05, Engine.time_scale)
	var working = state == State.WORKING or state == State.MINIGAME
	if current_shift == 1 and _pre_accident_lock:
		return
	# moving (right after the accident)
	_tut.hint("f_move", "ХОДИТЬ И ПРЫГАТЬ|Только далеко от своего пресса не уходи", ["ui_left", "ui_right", "jump"],
		func(): return _player_moving(), 2.5, 9.0)
	# the shift panel, once a few boxes are through
	if _hud_on and _box_fill >= AUTO_OBJECTS + 2:
		_tut.hint("f_hud", "ПАНЕЛЬ СМЕНЫ|Справа сверху: время, коробки и стресс. Красные клетки — твои ошибки", [], Callable(), 5.0, 7.0)
	# walked away from the press
	if working and not _is_player_in_zone():
		_tut_out_zone += dt
	else:
		_tut_out_zone = 0.0
	if _tut_out_zone > 0.6:
		_tut.hint("f_zone", "ВЕРНИСЬ К ПРЕССУ|Охрана следит, кто отлынивает от работы", [], func(): return _is_player_in_zone(), 1.5, 8.0)
	# inspect mode and the journal (from the 2nd shift)
	if current_shift >= 2:
		if working:
			_tut_work_t += dt
		if _tut_work_t > 3.0:
			_tut.hint("f_inspect", "ОСМОТР|Время замедляется. Подсвеченное можно изучить мышкой", [_key_name("inspect")],
				func(): return state == State.INSPECT, 2.5, 14.0)
		if _tut_was_inspect and state != State.INSPECT:
			_tut.hint("f_journal", "ЖУРНАЛ|Здесь всё, что ты узнал, и время пересменок", [_key_name("journal")],
				func(): return journal_open, 2.0, 10.0)
		if state == State.INSPECT:
			_tut_was_inspect = true
		if guard_changing or sniper_changing:
			_tut.hint("f_shiftchange", "ПЕРЕСМЕНКА!|Зайди в осмотр и нажми на жёлтую цель — запишешь время", [_key_name("inspect")],
				func(): return not guard_shifts_found.is_empty() or not sniper_shifts_found.is_empty() or not (guard_changing or sniper_changing), 2.5, 12.0)


## Picks a minigame variant for this box and shows it.
var _mg_forgive: bool = false

func _start_minigame(station: int = STATION_PACK, forgive: bool = false) -> void:
	_mg_forgive = forgive
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
			mg_hits_need = 2
			mg_ring_speed = 52.0 + 5.0 * current_shift
			mg_ring_r = 86.0
			hint_label.text = key + " — КОГДА КОЛЬЦО СОВПАДЁТ (2 РАЗА)"
			hint_label.position = Vector2(326, 418)
		MG.CUT:
			_mg_title.text = STATION_TITLE.get(station, "НАРЕЗКА")
			_mg_title.position = Vector2(376, 236)
			mg_knife = 0.0
			mg_marks.clear()
			var n = 2
			for i in range(n):
				mg_marks.append(0.32 + i * 0.36 + randf_range(-0.05, 0.05))
			mg_hits = 0
			mg_hits_need = n
			mg_speed = 0.36 + 0.025 * current_shift
			hint_label.text = key + " — РЕЖЬ ПО МЕТКАМ"
			hint_label.position = Vector2(326, 368)
	_mg_title.size = Vector2.ZERO
	_mg_title.reset_size()
	_center_mg_title()
	# the window pops in instead of just appearing
	if mg_kind == MG.SLIDER:
		_pop_in(minigame_panel, 0.85)
	else:
		_pop_in(_mg_canvas, 0.85)
	_update_minigame_fill()
	_mg_canvas.queue_redraw()


## 0..1: how close to the centre of the green the hit was (1 = dead centre).
func _mg_quality() -> float:
	match mg_kind:
		MG.LOCK:
			if mg_pin_index >= mg_pins.size():
				return 0.0
			return 1.0 - clamp(abs(wrapf(mg_angle - mg_pins[mg_pin_index], -PI, PI)) / max(0.01, mg_pin_half), 0.0, 1.0)
		MG.GAUGE:
			var c = (mg_band.x + mg_band.y) * 0.5
			return 1.0 - clamp(abs(mg_level - c) / max(0.01, (mg_band.y - mg_band.x) * 0.5), 0.0, 1.0)
		MG.RING:
			return 1.0 - clamp(abs(mg_ring_r - RING_TARGET) / RING_TOL, 0.0, 1.0)
		MG.CUT:
			if mg_hits >= mg_marks.size():
				return 0.0
			return 1.0 - clamp(abs(mg_knife - mg_marks[mg_hits]) / CUT_TOL, 0.0, 1.0)
	var px = TRACK_X0 + slider_pos * TRACK_WIDTH
	var zc = minigame_zone.position.x + minigame_zone.size.x * 0.5
	return 1.0 - clamp(abs(px - zc) / max(1.0, minigame_zone.size.x * 0.5), 0.0, 1.0)


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
			return abs(mg_ring_r - RING_TARGET) <= RING_TOL
		MG.CUT:
			if mg_hits >= mg_marks.size():
				return false
			return abs(mg_knife - mg_marks[mg_hits]) <= CUT_TOL
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
	c.draw_rect(Rect2(x0 + 4, y0 + 5, w, h), Color(0, 0, 0, 0.45))          # drop shadow
	c.draw_rect(Rect2(x0, y0, w, h), Color.BLACK)
	c.draw_rect(Rect2(x0 + 4, y0 + 4, w - 8, h - 8), rim)
	c.draw_rect(Rect2(x0 + 4, y0 + 4, w - 8, 2), rim.lightened(0.35))          # lit top edge
	c.draw_rect(Rect2(x0 + 4, y0 + h - 6, w - 8, 2), rim.darkened(0.35))
	c.draw_rect(Rect2(x0 + 8, y0 + 8, w - 16, h - 16), dark)
	# a soft vertical gradient inside + scanlines
	for k in range(int((h - 16) / 4.0)):
		c.draw_rect(Rect2(x0 + 8, y0 + 8 + k * 4, w - 16, 1), Color(1, 1, 1, 0.025))
	# rivets
	for p in [Vector2(x0 + 6, y0 + 6), Vector2(x0 + w - 8, y0 + 6), Vector2(x0 + 6, y0 + h - 8), Vector2(x0 + w - 8, y0 + h - 8)]:
		c.draw_rect(Rect2(p, Vector2(2, 2)), rim.lightened(0.5))
	if _mg_flash > 0.0:
		var fc = green if _mg_flash_good else Color8(230, 70, 60)
		c.draw_rect(Rect2(x0 + 8, y0 + 8, w - 16, h - 16), Color(fc.r, fc.g, fc.b, 0.35 * _mg_flash))
	if mg_kind == MG.RING:
		var ctr = Vector2(100, 104)
		var pulse = 0.75 + 0.25 * sin(mg_time * 10.0)
		c.draw_arc(ctr, RING_TARGET, 0, TAU, 48, green_d, RING_TOL * 2.0)
		c.draw_arc(ctr, RING_TARGET, 0, TAU, 48, Color(green, pulse), RING_TOL)
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
			if i == mg_hits:
				# the cut window is shown, so it is easy to see when to press
				c.draw_rect(Rect2(mx - CUT_TOL * roll.size.x, roll.position.y - 6, CUT_TOL * 2.0 * roll.size.x, roll.size.y + 12), Color(green, 0.22))
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

var _stress_relief: int = 0
var _relief_hp: int = 99
func _update_stress_from_hp() -> void:
	if player == null:
		return
	var hp = 0
	if player.has_method("get_hp"):
		hp = player.get_hp()
	else:
		hp = player.hp
	_relief_hp = hp
	# a hit adds its 20% on top of what it is now (the relief from a good check stays)
	_stress_relief = clamp(_stress_relief, 0, STRESS_BY_HP.get(hp, 0))
	stress_level = max(0, STRESS_BY_HP.get(hp, 0) - _stress_relief)
	_update_stress_bar()

func _get_miss_chance() -> float:
	if _mg_forgive:
		return 0.0
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
const HUD_C_SKIP := Color8(110, 114, 124)

var _hud_panel: Control = null
var _box_states: Array = []
var _box_fill: int = 0   # next free cell of the shift progress bar (cells fill in order)


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
var _hud_dirty: bool = true
var _hud_text_state: Dictionary = {}

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
	# only touch the label when something changed (theme overrides force a relayout)
	var sig = [text, x_px, y_px, w_px, align, col]
	if _hud_text_state.get(key, []) == sig:
		return
	_hud_text_state[key] = sig
	l.text = text
	l.position = Vector2(x_px, y_px)
	l.size = Vector2(w_px, 18)
	l.horizontal_alignment = align as HorizontalAlignment
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
	# sweeping light over the panel, like the HP bar shimmer
	var sh = load("res://GameShaders/SharedShaders/Shared_UIShimmer_Shader.gdshader")
	if sh:
		var m = ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("pixel", HUD_PX)
		m.set_shader_parameter("phase", 0.6)
		m.set_shader_parameter("strength", 0.22)
		_hud_panel.material = m
	_hud_nodes.append(_hud_panel)
	_create_action_strip()
	_layout_hud()


## ---------------------------------------------------------------- action strip
## Two pixel "buttons" right under the shift panel: [I] ОСМОТР  [J] ЖУРНАЛ. The one in use is
## lit, the journal blinks a "!" after a new note. Shown from the 2nd shift, inside the view.
const ACT_H: int = 13
var _act_strip: Control = null
var _act_labels: Dictionary = {}
var _act_sig: Array = []
var _act_note_t: float = 0.0

func _create_action_strip() -> void:
	_act_strip = Control.new()
	_act_strip.name = "ActionStrip"
	_act_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_act_strip.visible = false
	_act_strip.draw.connect(_draw_action_strip)
	$UI.add_child(_act_strip)
	if _hud_panel and _hud_panel.material is ShaderMaterial:
		var m = (_hud_panel.material as ShaderMaterial).duplicate()
		m.set_shader_parameter("phase", 0.95)
		_act_strip.material = m
	for k in ["key_i", "txt_i", "key_j", "txt_j"]:
		var l = Label.new()
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if k.begins_with("key") else HORIZONTAL_ALIGNMENT_LEFT
		l.add_theme_font_size_override("font_size", 12 if k.begins_with("key") else 13)
		l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
		l.add_theme_constant_override("outline_size", 0 if k.begins_with("key") else 4)
		_act_strip.add_child(l)
		_act_labels[k] = l

func _act_half_w() -> int:
	return int(HUD_W / 2.0)

func _update_action_strip(delta: float) -> void:
	if _act_strip == null:
		return
	var want_show = current_shift >= 2 and _hud_on and state != State.DEAD
	if _act_strip.visible != want_show:
		_act_strip.visible = want_show
		if want_show:
			_act_strip.modulate.a = 0.0
			_act_strip.create_tween().tween_property(_act_strip, "modulate:a", 1.0, 0.5)
	if not want_show:
		return
	if inspect_journal_notice and inspect_journal_notice.visible:
		_act_note_t = 4.0
	if journal_open:
		_act_note_t = 0.0
	var dt = delta / max(0.05, Engine.time_scale) if Engine.time_scale > 0.0 else 0.016
	_act_note_t = max(0.0, _act_note_t - dt)
	var blink = _act_note_t > 0.0 and int(Time.get_ticks_msec() / 250.0) % 2 == 0
	var sig = [state == State.INSPECT, journal_open, blink, _key_name("inspect"), _key_name("journal")]
	if sig == _act_sig:
		return
	_act_sig = sig
	var hw = _act_half_w()
	var cap = 9
	for side in [["i", 0, "ОСМОТР", sig[0], sig[3]], ["j", hw, "ЖУРНАЛ", sig[1], sig[4]]]:
		var x0: int = side[1]
		var on: bool = side[3]
		var kl: Label = _act_labels["key_" + side[0]]
		var tl: Label = _act_labels["txt_" + side[0]]
		var ktxt: String = side[4]
		if ktxt.length() > 3:
			ktxt = ktxt.substr(0, 3)
		kl.text = ktxt
		kl.position = Vector2((x0 + 4) * HUD_PX, (3 + (1 if on else 0)) * HUD_PX)
		kl.size = Vector2(cap * HUD_PX, (cap - 1) * HUD_PX)
		kl.add_theme_color_override("font_color", Color8(24, 26, 34))
		tl.text = side[2]
		tl.position = Vector2((x0 + 4 + cap + 3) * HUD_PX, 2 * HUD_PX)
		tl.size = Vector2((hw - cap - 10) * HUD_PX, (ACT_H - 4) * HUD_PX)
		tl.add_theme_color_override("font_color", HUD_C_ORANGE.lightened(0.25) if on else HUD_C_TEXT)
	_act_strip.queue_redraw()

func _draw_action_strip() -> void:
	var c = _act_strip
	if c == null:
		return
	var W = HUD_W
	var H = ACT_H
	_hud_rect(c, 0, 0, W, H, Color.BLACK)
	_hud_rect(c, 1, 1, W - 2, H - 2, HUD_C_EDGE)
	_hud_rect(c, 2, 1, W - 4, 1, HUD_C_EDGE_HI)
	_hud_rect(c, 2, 2, W - 4, H - 4, HUD_C_BG)
	var hw = _act_half_w()
	# divider between the two buttons
	_hud_rect(c, hw, 2, 1, H - 4, Color.BLACK)
	_hud_rect(c, hw + 1, 2, 1, H - 4, HUD_C_DIM)
	var states = [_act_sig[0] if _act_sig.size() > 0 else false, _act_sig[1] if _act_sig.size() > 1 else false]
	for i in range(2):
		var x0 = 0 if i == 0 else hw
		var on: bool = states[i]
		if on:
			_hud_rect(c, x0 + 2, 2, hw - 2 if i == 0 else W - hw - 2, H - 4, Color(HUD_C_ORANGE, 0.22))
			_hud_rect(c, x0 + 2, H - 3, hw - 2 if i == 0 else W - hw - 2, 1, HUD_C_ORANGE)
		# key cap (9 x 9), pushed down while that mode is on
		var ky = 2 + (1 if on else 0)
		_hud_rect(c, x0 + 4, 2 + 1, 9, 9, Color.BLACK)
		_hud_rect(c, x0 + 4, ky, 9, 8, Color8(180, 186, 200) if not on else HUD_C_ORANGE)
		_hud_rect(c, x0 + 5, ky + 1, 7, 5, Color8(232, 236, 244) if not on else HUD_C_ORANGE.lightened(0.35))
	# "!" on the journal after a new note
	if _act_sig.size() > 2 and _act_sig[2]:
		var bx = W - 6
		_hud_rect(c, bx - 1, 2, 4, 9, Color.BLACK)
		_hud_rect(c, bx, 3, 2, 4, HUD_C_ORANGE)
		_hud_rect(c, bx, 8, 2, 2, HUD_C_ORANGE)

func _hud_rows() -> int:
	return 4 if current_shift >= 2 else 3


func _layout_hud() -> void:
	if _hud_panel == null:
		return
	var h = 9 + _hud_rows() * 9
	_hud_panel.size = Vector2(HUD_W, h) * HUD_PX
	if _hud_panel.material is ShaderMaterial:
		_hud_panel.material.set_shader_parameter("rect_size", _hud_panel.size)
	var vp = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1152, 648)
	_hud_panel.position = Vector2(vp.x - _hud_panel.size.x - HUD_MARGIN, HUD_MARGIN)
	if _act_strip:
		_act_strip.size = Vector2(HUD_W, ACT_H) * HUD_PX
		_act_strip.position = _hud_panel.position + Vector2(0, _hud_panel.size.y + 2.0 * HUD_PX)
		if _act_strip.material is ShaderMaterial:
			_act_strip.material.set_shader_parameter("rect_size", _act_strip.size)


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
			if int((x + y) / 2.0) % 2 == 0:
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
			var blink = int(Time.get_ticks_msec() / 500.0) % 2 == 0
			_hud_rect(c, dx, y + 2, 1, 1, on if blink else off)
			_hud_rect(c, dx, y + 4, 1, 1, on if blink else off)
			dx += 2

	# row 2: packed / ruined boxes
	y += 10
	var cells_w = TOTAL_OBJECTS * 3 - 1
	var cx0 = int((W - cells_w) / 2.0)
	for i in range(TOTAL_OBJECTS):
		var st = _box_states[i] if i < _box_states.size() else 0
		var col = HUD_C_DIM if st == 0 else (HUD_C_GOOD if st == 1 else (HUD_C_BAD if st == 2 else HUD_C_SKIP))
		_hud_rect(c, cx0 + i * 3, y, 2, 5, col)
		if st != 0:
			_hud_rect(c, cx0 + i * 3, y, 2, 1, col.lightened(0.35))

	# row 3: stress
	y += 9
	var _pct = str(stress_level) + "%"
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
		for i in range(GUARD_SHIFTS.size()):
			_hud_rect(c, gx + i * 5, y, 4, 5, Color.BLACK)
			_hud_rect(c, gx + i * 5 + 1, y + 1, 2, 3, HUD_C_GOOD if i < guard_shifts_found.size() else HUD_C_DIM)
		if current_shift >= 3:
			var px = W - 4 - 14
			for i in range(SNIPER_SHIFTS.size()):
				_hud_rect(c, px + i * 5, y, 4, 5, Color.BLACK)
				_hud_rect(c, px + i * 5 + 1, y + 1, 2, 3, HUD_C_GOOD if i < sniper_shifts_found.size() else HUD_C_DIM)


func _create_shift_bars() -> void:
	pass


func _create_stress_bar() -> void:
	pass


func _update_stress_bar() -> void:
	# called every frame: does nothing unless the stress value moves or the HUD was marked dirty
	var target = float(stress_level)
	if is_equal_approx(_stress_shown, target) and not _hud_dirty:
		return
	_stress_shown = move_toward(_stress_shown, target, 60.0 * get_process_delta_time())
	_hud_dirty = false
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
	_hud_dirty = true
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
	_add_inspect_target("guard_dog", GUARD_POSITION, Vector2(80, 80),
		"Охранник-Собака", "Лучший друг человека..",
		"Охранник-Собака в меха костюме. Имеет меха челюсти со смертельной силой сжатия", COLOR_HIGHLIGHT_BLUE, "dog")
	_add_inspect_target("guard_monkey", GUARD_POSITION, Vector2(80, 80),
		"Охранник-Обезьяна", "Человекоподобные тоже с ними..",
		"Охранник-Обезьяна в меха костюме. Имеет массивный меха хвост", COLOR_HIGHLIGHT_BLUE, "monkey")
	for fish in npc_fishes:
		if fish == null:
			continue
		var identity = npc_identities.get(fish, "")
		var info = NPC_IDENTITY_DATA.get(identity, {})
		if info.is_empty():
			continue
		_add_inspect_target("npc_" + identity, fish.position, Vector2(70, 90),
			info.get("title", ""), info.get("phrase", ""), info.get("journal", ""), COLOR_HIGHLIGHT_BLUE, "")
	# the belt itself (added after the fish, so clicking a fish still opens the fish)
	_add_inspect_target("conveyor", Vector2(380, 368), Vector2(1240, 56),
		"Конвейер", "Сколько еще таких заводов они построили?",
		str(TOTAL_OBJECTS) + " коробок за смену", COLOR_HIGHLIGHT_BLUE, "")
	_add_inspect_target("guard_shift_9", GUARD_POSITION, Vector2(80, 80),
		"Смена охранника", "Охранник сменился.. Нужно записать", "Смена охранника в 09:00",
		COLOR_HIGHLIGHT_YELLOW, "guard_shift", 9.0)
	_add_inspect_target("guard_shift_13", GUARD_POSITION, Vector2(80, 80),
		"Смена охранника", "Охранник сменился.. Нужно записать", "Смена охранника в 13:00",
		COLOR_HIGHLIGHT_YELLOW, "guard_shift", 13.0)
	_add_inspect_target("guard_shift_15_5", GUARD_POSITION, Vector2(80, 80),
		"Смена охранника", "Охранник сменился.. Нужно записать", "Смена охранника в 15:30",
		COLOR_HIGHLIGHT_YELLOW, "guard_shift", 15.5)
	_add_inspect_target("guard_shift_17", GUARD_POSITION, Vector2(80, 80),
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
	if not (id in _all_target_ids):
		_all_target_ids.append(id)
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
	if nodes.is_empty() or id in ["clock", "maintenance", "elevator"]:
		# no sprite, or a sprite that fills its whole frame (the outline would have no room):
		# pulsing corner brackets around it (plus the glow on the sprite itself)
		hl.color = Color(color.r, color.g, color.b, 0.0)
		for n in nodes:
			_ensure_outline(n, color)
		if not nodes.is_empty():
			_outline_nodes[area] = nodes
		_add_frame_outline(area, nodes, pos, size)
	else:
		hl.self_modulate.a = 0.0
		for n in nodes:
			_ensure_outline(n, color)
		_outline_nodes[area] = nodes

## A pixel frame around objects that fill their whole sprite (the elevator, the maintenance
## door, the clock): the sprite outline has no room there, so the frame goes around it - the
## same colour and pulse as the outlines of the others.
var _frame_outlines: Dictionary = {}   # area -> Node2D

func _add_frame_outline(area: Area2D, nodes: Array, pos: Vector2, size: Vector2) -> void:
	var fr = Node2D.new()
	fr.name = "FrameOutline"
	fr.z_as_relative = false
	fr.z_index = 60
	fr.visible = false
	add_child(fr)
	var r = Rect2(pos - size * 0.5, size)
	if not nodes.is_empty():
		var u = Rect2()
		var first = true
		for n in nodes:
			var lr = _node_local_rect(n)
			if lr.size == Vector2.ZERO:
				continue
			var gt: Transform2D = n.get_global_transform()
			var a = gt * lr.position
			var b = gt * (lr.position + lr.size)
			var nr = Rect2(Vector2(min(a.x, b.x), min(a.y, b.y)), (b - a).abs())
			u = nr if first else u.merge(nr)
			first = false
		if not first:
			r = u
	fr.set_meta("rect", r.grow(2.0))
	fr.draw.connect(func():
		var rr: Rect2 = fr.get_meta("rect")
		var data = inspect_target_data.get(area, {})
		var col: Color = data.get("color", COLOR_HIGHLIGHT_BLUE)
		var pulse = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 1000.0 * 5.0)
		var c = Color(col.r * (1.6 + 0.8 * pulse), col.g * (1.6 + 0.8 * pulse), col.b * (1.6 + 0.8 * pulse), 0.75 + 0.25 * pulse)
		var k = 2.0
		fr.draw_rect(Rect2(rr.position, Vector2(rr.size.x, k)), c)
		fr.draw_rect(Rect2(rr.position + Vector2(0, rr.size.y - k), Vector2(rr.size.x, k)), c)
		fr.draw_rect(Rect2(rr.position, Vector2(k, rr.size.y)), c)
		fr.draw_rect(Rect2(rr.position + Vector2(rr.size.x - k, 0), Vector2(k, rr.size.y)), c)
		# corner ticks
		for cc in [rr.position, rr.position + Vector2(rr.size.x, 0), rr.end, rr.position + Vector2(0, rr.size.y)]:
			fr.draw_rect(Rect2(cc - Vector2(3, 3), Vector2(6, 6)), Color(c, 0.9)))
	_frame_outlines[area] = fr

func _node_local_rect(n: Node) -> Rect2:
	if n is Sprite2D:
		return n.get_rect()
	if n is AnimatedSprite2D and n.sprite_frames and n.sprite_frames.has_animation(n.animation):
		var tex = n.sprite_frames.get_frame_texture(n.animation, n.frame)
		if tex:
			var s = tex.get_size()
			return Rect2((-s * 0.5 if n.centered else Vector2.ZERO) + n.offset, s)
	if n is Control:
		return Rect2(Vector2.ZERO, n.size)
	return Rect2()

func _update_frame_outlines() -> void:
	for area in _frame_outlines.keys():
		var fr: Node2D = _frame_outlines[area]
		if not is_instance_valid(fr):
			continue
		var hl = inspect_highlight_rects.get(area, null)
		var on = state == State.INSPECT and is_instance_valid(area) and inspect_targets.has(area) and is_instance_valid(hl) and hl.visible
		fr.visible = on
		if on:
			fr.queue_redraw()

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
	# the guard on duty decides which one can be looked at
	if id == "guard_dog":
		return guard_is_dog and not guard_changing and guard_sprite != null and guard_sprite.visible
	if id == "guard_monkey":
		return not guard_is_dog and not guard_changing and guard_sprite != null and guard_sprite.visible
	if special_type == "":
		return true
	if special_type == "guard_shift" and current_shift < 2:
		return false   # nobody changes in the first shift
	if special_type == "sniper_shift" and current_shift < 3:
		return false   # the pigeon starts changing from the third shift
	if special_type == "guard_shift" or special_type == "sniper_shift":
		var hour = _current_hour()
		if hour >= special_hour and hour <= special_hour + 0.25:
			return true
		# the guard / sniper is leaving or coming back right now: he is marked in yellow
		var changing = guard_changing if special_type == "guard_shift" else sniper_changing
		return changing and hour >= special_hour - 0.05 and hour <= special_hour + 0.75
	return true

func _update_inspect_highlights() -> void:
	for area in inspect_targets:
		if not is_instance_valid(area):
			continue
		var hl = inspect_highlight_rects.get(area, null)
		if not is_instance_valid(hl):
			continue
		_follow_inspect_target(area, hl)
		hl.visible = _is_inspect_target_visible(area)
	_update_shift_marker()
	_update_frame_outlines()


## The guard and the sniper move (runs, shift changes): their click zones move with them.
func _follow_inspect_target(area: Area2D, hl: Control) -> void:
	var data = inspect_target_data.get(area, {})
	var id: String = data.get("id", "")
	var pos = data.get("pos", area.position)
	if id.begins_with("guard"):
		if guard_sprite and guard_sprite.visible:
			pos = guard_sprite.global_position
		elif id.begins_with("guard_shift"):
			pos = GUARD_POSITION   # nobody at the post: the empty post itself is the target
	elif id.begins_with("sniper") and sniper_sprite:
		if sniper_sprite.visible and sniper_sprite.modulate.a > 0.5:
			pos = sniper_sprite.global_position
		elif id.begins_with("sniper_shift"):
			pos = SNIPER_POSITION   # gone: the empty post is clicked
	else:
		return
	if pos == data.get("pos", Vector2.INF):
		return
	area.position = pos
	data["pos"] = pos
	inspect_target_data[area] = data
	var size = data.get("size", Vector2(80, 80))
	hl.offset_left = pos.x - size.x / 2.0
	hl.offset_top = pos.y - size.y / 2.0
	hl.offset_right = pos.x + size.x / 2.0
	hl.offset_bottom = pos.y + size.y / 2.0


## A bobbing yellow marker over the guard / sniper while his shift change can be noted.
var _shift_marker: Node2D = null
var _shift_marker_targets: Array = []

func _update_shift_marker() -> void:
	_shift_marker_targets.clear()
	if state == State.INSPECT:
		for area in inspect_targets:
			if not is_instance_valid(area):
				continue
			var data = inspect_target_data.get(area, {})
			var st = data.get("special_type", "")
			if (st == "guard_shift" or st == "sniper_shift") and _is_inspect_target_visible(area):
				var p: Vector2 = data.get("pos", area.position)
				var who: AnimatedSprite2D = guard_sprite if st == "guard_shift" else sniper_sprite
				var empty = who == null or not who.visible or who.modulate.a < 0.5
				_shift_marker_targets.append({"p": p + Vector2(30, -data.get("size", Vector2(80, 80)).y * 0.5 + 4.0),
					"post": GUARD_POSITION if st == "guard_shift" else SNIPER_POSITION, "empty": empty, "who": who})
	if _shift_marker == null:
		_shift_marker = Node2D.new()
		_shift_marker.z_as_relative = false
		_shift_marker.z_index = 205
		_shift_marker.draw.connect(_draw_shift_marker)
		add_child(_shift_marker)
	_shift_marker.visible = not _shift_marker_targets.is_empty()
	if _shift_marker.visible:
		_shift_marker.queue_redraw()


func _draw_shift_marker() -> void:
	var t = Time.get_ticks_msec() / 1000.0
	var yel = Color8(255, 214, 60)
	for m in _shift_marker_targets:
		var p: Vector2 = m["p"]
		if m["empty"]:
			_draw_empty_post(m["post"], m["who"], t, yel)
			p = m["post"] + Vector2(0, -60)
		var c: Vector2 = p + Vector2(0, round(sin(t * 5.0) * 3.0))
		var pts = PackedVector2Array([c + Vector2(0, -9), c + Vector2(7, 0), c + Vector2(0, 9), c + Vector2(-7, 0)])
		_shift_marker.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -11), c + Vector2(9, 0), c + Vector2(0, 11), c + Vector2(-9, 0)]), Color(0.08, 0.06, 0.02))
		_shift_marker.draw_colored_polygon(pts, yel)
		_shift_marker.draw_rect(Rect2(c.x - 1, c.y - 5, 2, 6), Color(0.1, 0.07, 0.02))
		_shift_marker.draw_rect(Rect2(c.x - 1, c.y + 3, 2, 2), Color(0.1, 0.07, 0.02))
		# pulse ring
		var k = fmod(t * 1.4, 1.0)
		_shift_marker.draw_arc(c, 10.0 + k * 12.0, 0, TAU, 20, Color(yel, 0.7 * (1.0 - k)), 1.5)

## Nobody at the post right now: a dashed yellow ghost of whoever stands there, with
## "ПОСТ ПУСТ" - clicking it notes the change just the same.
func _draw_empty_post(post: Vector2, who: AnimatedSprite2D, t: float, yel: Color) -> void:
	var m = _shift_marker
	var pulse = 0.5 + 0.5 * sin(t * 4.0)
	if who and who.sprite_frames and who.sprite_frames.has_animation("idle"):
		var tex = who.sprite_frames.get_frame_texture("idle", int(t * 6.0) % max(1, who.sprite_frames.get_frame_count("idle")))
		if tex:
			var sz = tex.get_size() * who.global_scale.abs()
			var flip = who.scale.x < 0.0 or who.flip_h
			var r = Rect2(post - sz / 2.0 + who.offset * who.global_scale.abs(), sz)
			if flip:
				m.draw_set_transform(Vector2(post.x * 2.0, 0), 0.0, Vector2(-1, 1))
			m.draw_texture_rect(tex, r, false, Color(yel.r * 1.3, yel.g * 1.3, yel.b, 0.32 + 0.2 * pulse))
			m.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# dashed frame around the empty spot
	var box = Rect2(post - Vector2(26, 34), Vector2(52, 68))
	m.draw_rect(box, Color(yel, 0.06 + 0.05 * pulse))
	var dash = 4.0
	var off = fmod(t * 10.0, dash * 2.0)
	var col = Color(yel, 0.65 + 0.35 * pulse)
	var x = box.position.x - off
	while x < box.end.x:
		var x0 = max(x, box.position.x)
		var x1 = min(x + dash, box.end.x)
		if x1 > x0:
			m.draw_rect(Rect2(x0, box.position.y, x1 - x0, 1.5), col)
			m.draw_rect(Rect2(x0, box.end.y - 1.5, x1 - x0, 1.5), col)
		x += dash * 2.0
	var y = box.position.y - off
	while y < box.end.y:
		var y0 = max(y, box.position.y)
		var y1 = min(y + dash, box.end.y)
		if y1 > y0:
			m.draw_rect(Rect2(box.position.x, y0, 1.5, y1 - y0), col)
			m.draw_rect(Rect2(box.end.x - 1.5, y0, 1.5, y1 - y0), col)
		y += dash * 2.0
	var f = _bubble_font()
	if f:
		var txt = "ПОСТ ПУСТ"
		var tw = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var tp = Vector2(round(post.x - tw / 2.0), round(box.position.y - 4.0))
		m.draw_string_outline(f, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0.08, 0.06, 0.02))
		m.draw_string(f, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)


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
		for c in conveyor_legs:
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
var _outline_state: Dictionary = {}

func _sync_inspect_outlines() -> void:
	if state != State.INSPECT and _outlines_off:
		return
	_outlines_off = state != State.INSPECT
	var on_nodes: Dictionary = {}   # node -> color (yellow beats blue)
	if state == State.INSPECT:
		for area in _outline_nodes.keys():
			var hl = inspect_highlight_rects.get(area, null)
			if not (is_instance_valid(area) and is_instance_valid(hl) and hl.visible):
				continue
			if not inspect_targets.has(area):
				continue
			var data = inspect_target_data.get(area, {})
			var col: Color = data.get("color", COLOR_HIGHLIGHT_BLUE)
			for n in _area_outline_nodes(area):
				if not is_instance_valid(n):
					continue
				if on_nodes.has(n) and on_nodes[n] == COLOR_HIGHLIGHT_YELLOW:
					continue
				on_nodes[n] = col
	var all_nodes: Dictionary = {}
	for area in _outline_nodes.keys():
		for n in _outline_nodes[area]:
			all_nodes[n] = true
	for n in on_nodes.keys():
		all_nodes[n] = true
	for n in all_nodes.keys():
		if not is_instance_valid(n):
			continue
		if not (n.material is ShaderMaterial):
			if not on_nodes.has(n):
				continue
			_ensure_outline(n, on_nodes[n])
		var v = 1.0 if on_nodes.has(n) else 0.0
		var col: Color = on_nodes.get(n, Color.WHITE)
		var key = [v, col]
		if _outline_state.get(n, []) != key:
			_outline_state[n] = key
			n.material.set_shader_parameter("active", v)
			if v > 0.0:
				n.material.set_shader_parameter("outline_color", Color(col.r, col.g, col.b, 1.0))


## Which sprites light up for an inspect zone right now (the shift-change zones follow the
## guard / sniper, or the elevator while the guard rides in it).
func _area_outline_nodes(area: Area2D) -> Array:
	var data = inspect_target_data.get(area, {})
	var st = data.get("special_type", "")
	if st == "guard_shift":
		if guard_sprite and guard_sprite.visible:
			return [guard_sprite]
		return []   # nobody at the post: only the dashed "ПОСТ ПУСТ" mark
	if st == "sniper_shift":
		if sniper_sprite and sniper_sprite.visible and sniper_sprite.modulate.a > 0.5:
			return [sniper_sprite]
		return []   # gone: the dashed "ПОСТ ПУСТ" mark is clicked
	return _outline_nodes.get(area, [])

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
	_apply_pre_accident_lock()
	# the fish stands still at its press while a minigame / incident is running
	if player and "minigame_lock" in player:
		player.minigame_lock = minigame_active or _inc_active or (state == State.MINIGAME)
	if _slowmo_on and state != State.INSPECT:
		_set_slowmo(false)
	if state == State.DEAD:
		if Engine.time_scale != 1.0:
			_reset_slowmo_now()
		return
	if _tree().paused:
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
	_guard_watchdog()
	_tutorial_tick(delta)
	_update_action_strip(delta)
	# the shift HUD must stay on screen once it was switched on
	if _hud_on and _hud_panel and is_instance_valid(_hud_panel) and not _hud_panel.visible:
		_hud_panel.visible = true
		_hud_panel.modulate.a = 1.0

# ---------------------------------------------------------------- streak / grades
## Minigame speed: +3.5% per job in the streak (up to +28%), +10% while the guard inspects.
func _mg_pace() -> float:
	return 1.0 + min(_streak, 8) * 0.035 + (0.1 if (_inspection_active and _insp_station < 0) else 0.0)


func _register_success(q: float) -> void:
	var perfect = q >= PERFECT_Q
	_streak += 1
	_best_streak = max(_best_streak, _streak)
	var txt = ("ИДЕАЛЬНО!" if perfect else "ХОРОШО") + ("  x" + str(_streak) if _streak >= 2 else "")
	_float_text(txt, Color(1.0, 0.86, 0.35) if perfect else Color(0.6, 1.0, 0.6))
	if camera and camera.has_method("add_trauma") and perfect:
		camera.add_trauma(0.06)
	if _inspection_active and _insp_station < 0:
		_inspection_step()
	_update_streak_label()


func _register_fail() -> void:
	if _streak >= 3:
		_float_text("СЕРИЯ ПРЕРВАНА", Color(1.0, 0.45, 0.4))
	_streak = 0
	if _inspection_active and _insp_station < 0:
		_inspection_bad += 1
		_inspection_step()
	_update_streak_label()


## Every 5 good jobs in a row: the suit repairs itself a bit (+1 HP), at full HP the guard
## forgets one violation instead.
func _streak_reward() -> void:
	var hp = player.get_hp() if player and player.has_method("get_hp") else 5
	if hp < 5 and player.has_method("set_hp"):
		player.set_hp(hp + 1)
		_float_text("+1 ПРОЧНОСТЬ", Color(0.45, 1.0, 0.55), -14.0)
		_update_stress_from_hp()
	else:
		_float_text("ОТЛИЧНЫЙ ТЕМП!", Color(1.0, 0.86, 0.35), -14.0)
	UISounds.play_switch_on()


func _update_streak_label() -> void:
	if _hud_panel == null:
		return
	if _streak_label == null:
		_streak_label = Label.new()
		_streak_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_streak_label.add_theme_font_size_override("font_size", 13)
		_streak_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
		_streak_label.add_theme_constant_override("outline_size", 4)
		_hud_panel.add_child(_streak_label)
	_streak_label.size = Vector2(_hud_panel.size.x - 6, 18)
	# under the [I] ОСМОТР / [J] ЖУРНАЛ strip when it is shown
	var below = _hud_panel.size.y + 2
	if _act_strip and current_shift >= 2:
		below = _act_strip.position.y + _act_strip.size.y - _hud_panel.position.y + 3
	_streak_label.position = Vector2(0, below)
	_streak_label.visible = _streak >= 2
	var my_check = _inspection_active and _insp_station < 0
	_streak_label.text = "СЕРИЯ x" + str(_streak) + ("   ПРОВЕРКА!" if my_check else "")
	var hot = _streak >= STREAK_REWARD
	_streak_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35) if hot else Color(0.8, 0.9, 1.0))
	if my_check:
		_streak_label.visible = true


## A short text rising over the player's head.
func _float_text(t: String, col: Color, dy: float = 0.0) -> void:
	if player == null:
		return
	var l = Label.new()
	l.text = t
	var f = load(DIALOG_FONT_PATH)
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
	l.add_theme_constant_override("outline_size", 3)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_as_relative = false
	l.z_index = 210
	add_child(l)
	var w = (f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x if f else 60.0)
	l.position = (player.global_position + Vector2(-w * 0.5, -78 + dy)).round()
	l.scale = Vector2(0.6, 0.6)
	l.pivot_offset = Vector2(w * 0.5, 4)
	var tw = create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position:y", l.position.y - 18.0, 1.1).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tw.tween_callback(l.queue_free)


# ---------------------------------------------------------------- guard inspections
## From the 2nd shift the guard comes twice a shift to stand behind the player and watch
## the next 3 jobs. The minigames are a bit faster meanwhile. All 3 done right: +1 HP and
## praise; any mistake: a second, extra hit when he leaves.
func _maybe_start_inspection() -> void:
	if current_shift < 2 or _inspection_active or guard_changing or _guard_busy:
		return
	if not (_cycles_done in _inspection_cycles):
		return
	_inspection_cycles.erase(_cycles_done)
	_start_inspection()


func _start_inspection(force_player: bool = false) -> void:
	_inspection_active = true
	_inspection_jobs_left = INSPECTION_JOBS
	_inspection_bad = 0
	# the other fish get checked too (about every second check)
	_insp_station = -1
	if not force_player and randf() < 0.5:
		var options: Array = []
		for st in range(NUM_NPC_FISHES + 1):
			if st != player_station and _station_fish(st) != null:
				options.append(st)
		if not options.is_empty():
			_insp_station = options[randi() % options.size()]
	_update_streak_label()
	if _insp_station < 0:
		_show_guard_dialog(["ПРОВЕРКА! ПОСМОТРИМ, КАК ТЫ РАБОТАЕШЬ.", "ТАК, ПОКАЖИ-КА МНЕ СВОЮ РАБОТУ.", "НЕ ОТВЛЕКАТЬСЯ. Я СМОТРЮ."][randi() % 3], 2.2)
	else:
		_show_guard_dialog(["ПРОВЕРКА! А НУ, ЧЕШУЙЧАТЫЙ, ПОКАЖИ РАБОТУ.", "ТАК, ТЕПЕРЬ ТЫ. Я СМОТРЮ.", "ЭЙ, ТЫ! РАБОТАЙ ПОКАЗАТЕЛЬНО."][randi() % 3], 2.2)
	_guard_busy = true
	await _guard_walk_to(Vector2(_inspection_x() - 64.0, GUARD_POSITION.y))
	if guard_sprite:
		guard_sprite.scale.x = abs(guard_sprite.scale.x)   # looks at the player
		if guard_sprite.sprite_frames and guard_sprite.sprite_frames.has_animation("idle"):
			guard_sprite.play("idle")
	_guard_busy = false


const INSPECTION_JOBS: int = 2

func _inspection_step() -> void:
	_inspection_jobs_left -= 1
	if _inspection_jobs_left <= 0:
		_end_inspection()


func _end_inspection() -> void:
	if not _inspection_active:
		return
	_inspection_active = false
	var checked_station = _insp_station
	_insp_station = -1
	_update_streak_label()
	inspection_finished.emit()
	if state == State.DEAD or state == State.SHIFT_END:
		return
	if checked_station >= 0:
		# a fish was checked: its mistakes were punished on the spot already
		_show_guard_dialog("НЕПЛОХО. РАБОТАЙ ДАЛЬШЕ." if _inspection_bad == 0 else "ПЛОХО. ЕЩЁ РАЗ — И ПОЖАЛЕЕШЬ.", 2.0)
	elif _inspection_bad == 1:
		# one of two done right: nothing happens
		_show_guard_dialog("СОЙДЁТ. НО Я ЗА ТОБОЙ ПРИСМАТРИВАЮ.", 2.0)
	elif _inspection_bad == 0:
		_show_guard_dialog("НЕПЛОХО. ТАК И ПРОДОЛЖАЙ.", 2.0)
		# the check went fine: the fish calms down a bit
		var hp_now = player.get_hp() if player and player.has_method("get_hp") else 5
		if STRESS_BY_HP.get(hp_now, 0) - _stress_relief > 0:
			_stress_relief += 20
			_relief_hp = hp_now
			_update_stress_from_hp()
			_float_text("СТРЕСС -20%", Color(0.55, 0.85, 1.0), -14.0)
			UISounds.play_switch_on()
	else:
		# both wrong: one more hit on top, right where he stands
		_guard_extra_hit_pending = true
		_show_guard_dialog("ПЛОХО РАБОТАЕШЬ. ЭТО ТЕБЕ НА ПАМЯТЬ.", 2.0)
		await _tree().create_timer(0.6, false).timeout
		if not is_inside_tree():
			return
		_guard_extra_hit_pending = false
		await _guard_hit_player()
	if guard_changing or state == State.DEAD:
		return
	_guard_busy = true
	await _guard_walk_to(GUARD_POSITION)
	if guard_sprite and guard_sprite.sprite_frames and guard_sprite.sprite_frames.has_animation("idle"):
		guard_sprite.play("idle")
	_guard_busy = false


func _apply_pre_accident_lock() -> void:
	if player == null:
		return
	var lock = _pre_accident_lock and current_shift == 1 and state != State.DEAD
	if lock:
		if player.has_method("set_movement_blocked"):
			player.set_movement_blocked(true)
		if "velocity" in player:
			player.velocity = Vector2.ZERO
	# the player's own input handler does attacks, blocking, parry and dash
	if lock and player.is_processing_input():
		player.set_process_input(false)


func _unlock_player_after_accident() -> void:
	_pre_accident_lock = false
	if player:
		player.set_process_input(true)
		if player.has_method("set_movement_blocked"):
			player.set_movement_blocked(false)


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


## Breaking the rules has a fixed course (it is the same while working and after the shift):
## the first 2 seconds the guard yells, in the 3rd he comes over and hits, in the 4th the
## sniper shoots. Stop breaking them and it is over (after a short moment of good behaviour).
## While working: walking around OUTSIDE your station (and outside the maintenance area);
## inside the zone you can move freely; around 13:00 nobody watches.
## After the shift: standing still (or walking away from the maintenance room).
const VIOL_YELL_2: float = 1.1
const VIOL_GUARD: float = 2.0
const VIOL_AIM: float = 3.0
const VIOL_SHOOT: float = 3.75
var _viol_t: float = 0.0
var _viol_ok_t: float = 0.0
var _viol_stage: int = 0
var _laser: Node2D = null

func _process_action_penalty(delta: float) -> void:
	if state == State.SHIFT_END or state == State.DEAD:
		return
	if state == State.INSPECT or state == State.INTRO or _tut_no_penalty:
		_violation_tick(false, delta, false)
		return
	if current_shift == 1 and _pre_accident_lock:
		_violation_tick(false, delta, false)
		return
	var hour = _current_hour()
	var bad = false
	if not (abs(hour - 13.0) < 0.5 or _is_player_in_zone() or _is_player_near_maintenance()):
		bad = _player_moving()
	_violation_tick(bad, delta, false)

func _process_follow_penalty(delta: float) -> void:
	if state != State.SHIFT_END:
		return
	if player == null or _is_player_near_maintenance() or _shift_fade_lock:
		_violation_tick(false, delta, true)
		return
	if fade_rect and fade_rect.visible and fade_rect.color.a > 0.2:
		_violation_tick(false, delta, true)
		return   # the screen is already going dark
	var going = false
	if _player_moving():
		var v = player.get("velocity")
		var dir_x = 1.0
		if maintenance_door:
			dir_x = sign(maintenance_door.global_position.x - player.global_position.x)
		going = not (v is Vector2) or sign(v.x) == dir_x or dir_x == 0.0
	_violation_tick(not going, delta, true)

func _violation_tick(bad: bool, delta: float, after_shift: bool) -> void:
	# real seconds (the inspect / journal slow motion does not stretch the warning)
	var dt = delta / max(0.05, Engine.time_scale)
	if not bad:
		if _viol_t > 0.0:
			_viol_ok_t += dt
			if _viol_ok_t >= 0.45:
				_viol_reset()
		return
	_viol_ok_t = 0.0
	_viol_t += dt
	if _viol_stage == 0:
		_viol_stage = 1
		if after_shift:
			_show_guard_dialog("ЧЕГО ВСТАЛ?! БЕГОМ НА ТЕХОБСЛУЖИВАНИЕ!", 2.0)
		else:
			_show_guard_dialog("ЭЙ! А НУ ВЕРНУЛСЯ К ПРЕССУ!", 2.0)
	elif _viol_stage == 1 and _viol_t >= VIOL_YELL_2:
		_viol_stage = 2
		_show_guard_dialog("Я КОМУ СКАЗАЛ?!" if not after_shift else "ОГЛОХ?! ШЕВЕЛИСЬ!", 1.6)
	elif _viol_stage == 2 and _viol_t >= VIOL_GUARD:
		_viol_stage = 3
		if guard_sprite and guard_sprite.visible and not guard_changing:
			_guard_hit_player()
	elif _viol_stage == 3 and _viol_t >= VIOL_AIM:
		_viol_stage = 4
		_laser_on()
	elif _viol_stage == 4 and _viol_t >= VIOL_SHOOT:
		_viol_stage = 5
		_sniper_kill_player()

func _viol_reset() -> void:
	_viol_t = 0.0
	_viol_ok_t = 0.0
	_viol_stage = 0
	_laser_off()

func _add_strike() -> void:
	# (old strike system) - now one step of the course above
	_viol_t = max(_viol_t, VIOL_GUARD)

func _sniper_muzzle() -> Vector2:
	var sp = sniper_sprite.global_position if sniper_sprite else SNIPER_POSITION
	return sp + Vector2(-22, 8)

## The sniper takes aim: a thin red beam from the roof and a dot on the fish.
func _laser_on() -> void:
	if _laser and is_instance_valid(_laser):
		return
	if sniper_sprite == null or not sniper_sprite.visible:
		return
	_laser = Node2D.new()
	_laser.z_as_relative = false
	_laser.z_index = 120
	add_child(_laser)
	var beam = Line2D.new()
	beam.name = "Beam"
	beam.width = 1.0
	beam.default_color = Color(1.0, 0.15, 0.1, 0.55)
	beam.add_point(Vector2.ZERO)
	beam.add_point(Vector2.ZERO)
	_laser.add_child(beam)
	var dot = Polygon2D.new()
	dot.name = "Dot"
	dot.color = Color(1.0, 0.2, 0.15, 0.95)
	var pts = PackedVector2Array()
	for k in range(8):
		pts.append(Vector2.from_angle(k * TAU / 8.0) * 2.5)
	dot.polygon = pts
	_laser.add_child(dot)
	UISounds.play_switch_on()
	_laser_follow()

func _laser_follow() -> void:
	while _laser and is_instance_valid(_laser) and is_inside_tree():
		var from = _sniper_muzzle()
		var to = (player.global_position + Vector2(0, -22)) if player else from
		var beam = _laser.get_node("Beam") as Line2D
		beam.set_point_position(0, from)
		beam.set_point_position(1, to)
		var flick = 0.45 + 0.25 * sin(Time.get_ticks_msec() / 40.0)
		beam.default_color.a = flick
		var dot = _laser.get_node("Dot") as Polygon2D
		dot.position = to + Vector2(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6))
		dot.scale = Vector2.ONE * (1.0 + 0.35 * sin(Time.get_ticks_msec() / 60.0))
		await _tree().process_frame

func _laser_off() -> void:
	if _laser and is_instance_valid(_laser):
		_laser.queue_free()
	_laser = null

func _process_inspect_camera(delta: float) -> void:
	if camera == null:
		return
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	inspect_camera_offset += dir * 375 * delta / max(0.05, Engine.time_scale)   # camera keeps real speed
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
			# everybody runs to the maintenance safe zone on the right and waits there
			var stop_x = SAFE_ZONE_CENTER_X - 66.0 + i * 40.0
			if fish.position.x < stop_x - 1.0:
				fish.position.x = min(stop_x, fish.position.x + NPC_WALK_SPEED * delta)
				if fish is AnimatedSprite2D:
					fish.flip_h = false
				if fish is AnimatedSprite2D and fish.sprite_frames.has_animation("jogging"):
					if fish.animation != "jogging":
						fish.play("jogging")
			elif fish is AnimatedSprite2D:
				fish.flip_h = true   # look back at the hall
				if fish.sprite_frames.has_animation("idle") and fish.animation != "idle":
					fish.play("idle")

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

## The shift clock: 25 boxes are spread over 8:00 - 18:00 (the 25th one is packed exactly
## at 18:00). Inside one belt step the clock runs at a steady speed (from the average step
## length), it slows down softly near the end of the step instead of jumping, and it stands
## still while the guard is punishing somebody.
## The clock is the boss now: one belt step has a fixed slot of CYCLE_SLOT seconds and the
## belt waits for the slot if the work went faster, so the last box always lands at 18:00.
## The clock runs at one steady speed, except in a few stretched periods: the escape window
## 13:00 - 13:15 lasts 12 s, every other guard / sniper change lasts 6 s. On a mistake it
## stands still until the guard is back at his place.
const CYCLE_SLOT: float = 2.8
const CHANGE_REAL: float = 6.0
var _shift_elapsed: float = 0.0   # running (not held) time of this shift

## [start_hour, end_hour, real_seconds] of the stretched periods of this shift.
func _slow_periods() -> Array:
	var p: Array = [[ESCAPE_WINDOW_START, ESCAPE_WINDOW_END, ESCAPE_WINDOW_REAL]]
	var hours: Array = []
	if current_shift >= 2:
		hours.append_array(GUARD_SHIFTS)
	if current_shift >= 3:
		hours.append_array(SNIPER_SHIFTS)
	for h in hours:
		if h >= ESCAPE_WINDOW_START and h < ESCAPE_WINDOW_END:
			continue
		var dup = false
		for q in p:
			if is_equal_approx(q[0], h):
				dup = true
		if not dup:
			p.append([h, h + SHIFT_CHANGE_HOURS, CHANGE_REAL])
	return p

func _process_clock(delta: float) -> void:
	if state == State.DEAD or state == State.INTRO:
		return
	_cycle_game_t += delta
	var held = state != State.SHIFT_END and _clock_on_hold()
	if held:
		_cycle_halted += delta
		return   # somebody made a mistake: everything waits for the guard
	_shift_elapsed += delta
	var periods = _slow_periods()
	if _clock_v <= 0.0:
		var slow_f := 0.0
		var slow_s := 0.0
		for q in periods:
			slow_f += (q[1] - q[0]) / SHIFT_DURATION_HOURS
			slow_s += q[2]
		_clock_v = (1.0 - slow_f) / max(20.0, float(TOTAL_CYCLES) * CYCLE_SLOT - slow_s)
	# 18:00 only comes with the last box (if the work is late the clock waits at 17:59)
	var cap = 1.0 if state == State.SHIFT_END else 0.998
	if shift_time >= cap:
		return
	var v = _clock_v
	var hour = _current_hour()
	for q in periods:
		if hour >= q[0] and hour < q[1]:
			v = (q[1] - q[0]) / SHIFT_DURATION_HOURS / q[2]
			break
	shift_time = min(shift_time + v * delta, cap)
	_update_clock_label()
	_update_wall_clock()


var _hold_after_error: bool = false

func _clock_on_hold() -> bool:
	if _halt > 0:
		_hold_after_error = true
		return true
	if _hold_after_error:
		# the punishment is over: wait until the guard stands at his place again
		var away = guard_sprite != null and guard_sprite.visible and not guard_changing \
			and guard_sprite.position.distance_to(_guard_home()) > 6.0
		if away and not guard_changing:
			return true
		_hold_after_error = false
	return false

func _begin_clock_cycle() -> void:
	_cycle_t0 = Time.get_ticks_msec()
	_cycle_halted = 0.0
	var boundary = float(_cycles_done + 1) / float(TOTAL_CYCLES)
	var nominal = (1.0 / float(TOTAL_CYCLES)) / max(0.8, _cycle_avg)
	_clock_speed = clamp(max(0.0, boundary - shift_time) / max(0.8, _cycle_avg), 0.0, nominal * 2.5)


func _end_clock_cycle() -> void:
	var dur = float(Time.get_ticks_msec() - _cycle_t0) / 1000.0 - _cycle_halted
	_cycle_avg = lerp(_cycle_avg, clamp(dur, 0.8, 12.0), 0.35)
	# game time of the whole cycle, halts included (this is what the clock has to cover)
	_cycle_real_avg = lerp(_cycle_real_avg, clamp(_cycle_game_t, 0.8, 15.0), 0.25)
	_pace_sum += max(0.0, _cycle_game_t - _cycle_halted)   # without the stops for mistakes
	_pace_n += 1
	_cycle_game_t = 0.0

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
	if absf(hour - _wall_clock_hour) < 0.004:
		return
	_wall_clock_hour = hour
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
	var txt = "%02d:%02d" % [h, m]
	if txt == _clock_text:
		return   # the clock only changes every 15 game minutes
	if clock_label:
		clock_label.text = txt
	_clock_text = txt
	if _hud_panel:
		_hud_panel.queue_redraw()

func _process_shift_changes() -> void:
	var hour = _current_hour()
	for shift_hour in GUARD_SHIFTS:
		if guard_last_checked_hour < shift_hour and hour >= shift_hour and current_shift >= 2:
			_on_guard_shift_change(shift_hour)
	guard_last_checked_hour = hour
	for shift_hour in SNIPER_SHIFTS:
		if sniper_last_checked_hour < shift_hour and hour >= shift_hour and current_shift >= 3:
			_on_sniper_shift_change(shift_hour)
	sniper_last_checked_hour = hour

signal guard_leave_spoken
signal guard_arrive_spoken

func _guard_return_lock() -> bool:
	return _tut_wait_guard_note

func _on_guard_shift_change(_hour: float) -> void:
	if guard_changing:
		return
	guard_changing = true
	if not _tut_done("inspect") and is_equal_approx(_hour, GUARD_SHIFTS[0]):
		_tut_inspect_flow()
		return
	_guard_shift_sequence()

const GUARD_LEAVE_LINES := [
	"ВСЁ, МОЯ СМЕНА КОНЧИЛАСЬ. НЕ СКУЧАЙТЕ, РЫБКИ.",
	"ПОЙДУ ПОЖРУ. СМЕНЩИК ВАС БЫСТРО ПОСТРОИТ.",
	"СМЕНА! КТО ДЁРНЕТСЯ — ПОЖАЛЕЕТ.",
	"ЛИФТ ЖДЁТ. А ВЫ ЖДИТЕ МЕНЯ, ХЕ-ХЕ.",
]
const GUARD_ARRIVE_LINES := [
	"ТАК, КТО ТУТ БЕЗ МЕНЯ РАССЛАБИЛСЯ?",
	"НОВАЯ СМЕНА — СТАРЫЕ ПРАВИЛА. РАБОТАТЬ!",
	"Я НА МЕСТЕ. ГЛАЗА У МЕНЯ ВЕЗДЕ.",
]
const SNIPER_LEAVE_LINES := [
	"УХОЖУ НА ПЕРЕКУР. ПРИЦЕЛ ОСТАЁТСЯ ТЁПЛЫМ.",
	"СМЕНА. НЕ РАДУЙТЕСЬ — Я ВЕРНУСЬ.",
	"ГЛАЗА УСТАЛИ... СМЕНЩИК УЖЕ НА КРЫШЕ.",
]
const SNIPER_ARRIVE_LINES := [
	"НА ПОЗИЦИИ. ВАС ВСЕХ ВИДНО.",
	"СНАЙПЕР НА ПОСТУ. ОДИН ШАГ НЕ ТУДА — И ВСЁ.",
]
const NAME_SNIPER := "СНАЙПЕР"
const COLOR_NAME_SNIPER := Color(0.75, 0.85, 1.0)

func _guard_shift_sequence() -> void:
	if guard_sprite == null:
		guard_changing = false
		return
	_inspection_active = false
	_insp_station = -1
	_update_streak_label()
	var w := 0.0
	while _guard_busy and w < 8.0:
		await _tree().create_timer(0.1, false).timeout
		if not is_inside_tree():
			return
		w += 0.1
	_guard_busy = true
	_show_guard_dialog(GUARD_LEAVE_LINES[randi() % GUARD_LEAVE_LINES.size()], 2.0)
	guard_leave_spoken.emit()
	await _guard_walk_to(elevator_button.position if elevator_button else GUARD_POSITION)
	await _tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	await _await_elevator_anim("open")
	await _guard_walk_to(GUARD_LIFT_POSITION)
	guard_sprite.visible = false
	await _await_elevator_anim("close")
	await _tree().create_timer(SHIFT_CHANGE_REAL, false).timeout
	if not is_inside_tree():
		return
	# (tutorial) he does not come back before the player has noted the change
	while _guard_return_lock() and is_inside_tree():
		await _tree().process_frame
	if not is_inside_tree():
		return
	guard_is_dog = not guard_is_dog
	_apply_guard_frames()
	guard_sprite.position = GUARD_LIFT_POSITION
	await _await_elevator_anim("open")
	guard_sprite.visible = true
	_show_guard_dialog(GUARD_ARRIVE_LINES[randi() % GUARD_ARRIVE_LINES.size()], 2.0)
	guard_arrive_spoken.emit()
	await _guard_walk_to(GUARD_POSITION)
	await _await_elevator_anim("close")
	if guard_sprite.sprite_frames.has_animation("idle"):
		guard_sprite.play("idle")
	_guard_busy = false
	guard_changing = false

## Waits for a signal of the level, but not longer than max_t seconds.
func _await_signal_or(sig: Signal, max_t: float) -> void:
	var got := {"v": false}
	var cb = func(_a = null, _b = null): got["v"] = true
	sig.connect(cb, CONNECT_ONE_SHOT)
	var t := 0.0
	while not got["v"] and t < max_t:
		await _tree().process_frame
		if not is_inside_tree():
			return
		t += get_process_delta_time()
	if sig.is_connected(cb):
		sig.disconnect(cb)

func _on_sniper_shift_change(_hour: float) -> void:
	if sniper_changing:
		return
	sniper_changing = true
	# at 13:00 the guard changes too: both say their line at the same moment (own bubbles)
	var with_guard = is_equal_approx(_hour, 13.0) and current_shift >= 2 and (guard_changing or GUARD_SHIFTS.has(13.0))
	if with_guard:
		await _await_signal_or(guard_leave_spoken, 9.0)
		if not is_inside_tree():
			return
	_speech(sniper_sprite, NAME_SNIPER, COLOR_NAME_SNIPER, SNIPER_LEAVE_LINES[randi() % SNIPER_LEAVE_LINES.size()], 1.6, true, "sniper")
	await _tree().create_timer(2.2, false).timeout
	if not is_inside_tree():
		return
	if sniper_sprite:
		var tw = create_tween()
		tw.tween_property(sniper_sprite, "modulate:a", 0.0, 0.4)
		await tw.finished
		sniper_sprite.visible = false
		sniper_sprite.modulate.a = 1.0
	if with_guard:
		# comes back together with the guard
		await _await_signal_or(guard_arrive_spoken, 25.0)
	else:
		await _tree().create_timer(SHIFT_CHANGE_REAL, false).timeout
	if not is_inside_tree():
		return
	if sniper_sprite:
		sniper_sprite.modulate.a = 0.0
		sniper_sprite.visible = true
		var tw2 = create_tween()
		tw2.tween_property(sniper_sprite, "modulate:a", 1.0, 0.4)
	_speech(sniper_sprite, NAME_SNIPER, COLOR_NAME_SNIPER, SNIPER_ARRIVE_LINES[randi() % SNIPER_ARRIVE_LINES.size()], 1.6, true, "sniper")
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
	_streak = 0
	_inspection_active = false
	_insp_station = -1
	_inspection_cycles = [randi_range(4, 8), randi_range(11, 16), randi_range(19, 24)] if current_shift >= 2 else []
	_update_streak_label()
	while _resolved < TOTAL_OBJECTS:
		if _belt_stopped(gen):
			return
		# the belt keeps the clock's rhythm: the next step starts at its time slot
		while _shift_elapsed < float(_cycles_done) * CYCLE_SLOT and not _belt_stopped(gen):
			await _tree().process_frame
			if not is_inside_tree():
				return
		if _belt_stopped(gen):
			return
		if _spawned < TOTAL_OBJECTS and _cycles_done % SPAWN_EVERY == 0:
			_spawn_item()
		_begin_clock_cycle()
		_maybe_start_inspection()
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
		_end_clock_cycle()
		_cycles_done += 1
		await _tree().create_timer(0.12, false).timeout
		if not is_inside_tree():
			return
	if _belt_stopped(gen):
		return
	# the last box can be done a few steps early (ruined ones drop out sooner): the shift
	# still ends at 18:00 - the clock just keeps its pace until then
	while shift_time < 0.997 and not _belt_stopped(gen):
		await _tree().process_frame
		if not is_inside_tree():
			return
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
	var mistake = randf() < NPC_MISTAKE_CHANCE and _guard_free_at_post()
	var node = it["node"]
	var checked = _inspection_active and _insp_station == st
	if mistake:
		_halt += 1
		await _play_press(st, func(): _break_item(it, st == STATION_PACK, false, false), node)
		if fish and state != State.DEAD and state != State.SHIFT_END:
			await _guard_hit_npc(fish)
		_halt = max(0, _halt - 1)
	else:
		await _play_press(st, func(): _advance_item(it), node)
	if checked and _inspection_active and _insp_station == st:
		if mistake:
			_inspection_bad += 1
		_inspection_step()


## The player's press: tutorial boxes go by themselves, the 4th one is the accident (the
## press shorts out and shocks the fish), after that it is the station's minigame - and
## sometimes something goes wrong with it (fire, jammed belt, stuck button).
func _job_player(it: Dictionary) -> void:
	_player_item = it
	var idx: int = it["index"]
	if current_shift == 1 and idx < AUTO_OBJECTS:
		await _player_press_result(true, false)
		return
	if current_shift == 1 and idx == AUTO_OBJECTS:
		await _electric_accident(it)
		return
	if not _is_player_in_zone() and _tut_stage == "first_job":
		# (tutorial) walked away while learning to move: back to the press first
		_spot_show("НАЗАД К ПРЕССУ", "Работа приехала! Вернись в безопасную зону у своего пресса.", ["A", "D"], _zone_screen_rect, false)
		while is_inside_tree() and not _is_player_in_zone() and state != State.DEAD:
			await _tree().process_frame
		if not is_inside_tree() or state == State.DEAD:
			return
	if not _is_player_in_zone():
		await _player_press_result(false)
		return
	if state == State.INSPECT:
		_exit_inspect(true)   # thrown out of the slow motion: work!
	if journal_open:
		_kick_out_of_journal()
	if player_gui and not player_gui.visible:
		_show_gui()
	# 5%: instead of the usual job something breaks at the press (fire / short / stuck).
	# Never while the basics are being taught.
	var incident = MGE_NONE
	if _tut_stage == "" and _tut_done("basics"):
		incident = _roll_incident()
	if incident != MGE_NONE:
		var first = not _tut_done("inc_%d" % incident)
		var ok = await _run_incident(incident, first)
		if not is_inside_tree():
			return
		if ok and first:
			_tut_mark("inc_%d" % incident)
		if state == State.DEAD or state == State.SHIFT_END:
			_player_item = null
			player_job_finished.emit()
			return
		_last_quality = 1.0 if ok else 0.0
		await _player_press_result(ok)
		return
	# the very first job (tutorial) and the first job at a new station can't go wrong
	var forgive = _tut_stage == "first_job" or (_tut_done("basics") and not _tut_done("st_%d" % player_station))
	_start_minigame(player_station, forgive)
	if _tut_stage == "first_job":
		_spot_show("РАБОТА", "Ты работаешь на заводе. Нажми " + _key_name("interact") + ", когда ползунок в ЗЕЛЁНОЙ зоне — так выполняется работа.", [_key_name("interact")], _mg_screen_rect)
	elif forgive:
		_spot_show("НОВЫЙ СТАНОК: " + String(STATION_TITLE.get(player_station, "")), "Здесь другая работа. Пока учишься — промахи не считаются, просто попробуй ещё раз.", [_key_name("interact")], _mg_screen_rect, false)
	await player_job_finished
	if forgive and _spot and _spot.is_shown() and _tut_stage != "first_job":
		_spot.hide_step()


## The 4th box of the first shift: the fish punches the button, the press shorts out and
## the current goes through the fish. The food burns, the HUD switches on.
func _electric_accident(it: Dictionary) -> void:
	_halt += 1
	_player_item = null
	await _player_punch()
	_press_button_light(player_station)
	var press: Node2D = presses[player_station] if player_station < presses.size() else null
	var src = press.to_global(PRESS_BUTTON_LOCAL) if press else Vector2(_get_stop_zone_x(player_station), 300)
	var bolts: Array = []
	for i in range(3):
		var l = Line2D.new()
		l.width = 2.5 if i == 0 else 1.0
		l.default_color = Color(0.55, 0.85, 1.0, 0.9) if i == 0 else Color(1, 1, 1, 1)
		l.z_as_relative = false
		l.z_index = 150
		add_child(l)
		bolts.append(l)
	var flash = ColorRect.new()
	flash.color = Color(0.75, 0.9, 1.0, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(flash)
	UISounds.play_hit()
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.55)
	_spawn_sparks(src, 14)
	var t := 0.0
	var k := 0
	while t < 1.0:
		var dst = (player.global_position + Vector2(randf_range(-6, 6), randf_range(-30, -8))) if player else src + Vector2(30, 40)
		for i in range(bolts.size()):
			var pts = PackedVector2Array()
			var seg = 7
			for s in range(seg + 1):
				var p = src.lerp(dst, float(s) / seg)
				if s > 0 and s < seg:
					p += Vector2(randf_range(-7, 7), randf_range(-7, 7))
				pts.append(p)
			bolts[i].points = pts
			bolts[i].visible = randf() < 0.85
		if player_sprite:
			player_sprite.modulate = Color(0.6, 0.95, 2.2) if k % 2 == 0 else Color(1.6, 1.6, 1.6)
		flash.color.a = 0.35 if k % 3 == 0 else 0.0
		if k % 4 == 0:
			_spawn_sparks(src, 4)
			if camera and camera.has_method("add_trauma"):
				camera.add_trauma(0.12)
		k += 1
		await _tree().create_timer(0.05, false).timeout
		if not is_inside_tree():
			return
		t += 0.05
	for b in bolts:
		b.queue_free()
	flash.queue_free()
	if player_sprite:
		player_sprite.modulate = Color.WHITE
	_break_item(it, player_station == STATION_PACK, true, true)   # counts as our mistake (red)
	var obj: Node2D = it["node"]
	if is_instance_valid(obj):
		var spr = obj.get_node_or_null("Sprite") as Sprite2D
		if spr:
			spr.modulate = Color(0.35, 0.3, 0.3)   # burnt
	if player and player.has_method("take_damage"):
		player.take_damage(1)
	_update_stress_from_hp()
	_unlock_player_after_accident()
	_set_hud_visible(true)
	_show_gui()
	_show_guard_dialog("ЧТО, ТОКОМ ДЁРНУЛО? НИЧЕГО, РАБОТАЙ ДАЛЬШЕ!", 2.5)
	_mark_accident_seen()
	_end_accident_skip()
	if not _tut_done("basics"):
		_tut_no_penalty = true
		await _tut_basics_intro()
		if not is_inside_tree():
			return
		_tut_stage = "first_job"
	else:
		await _tree().create_timer(0.8, false).timeout
		if not is_inside_tree():
			return
	_halt = max(0, _halt - 1)


func _spawn_sparks(at: Vector2, count: int) -> void:
	for i in range(count):
		var s = ColorRect.new()
		s.size = Vector2(2, 2)
		s.color = Color(1.0, 0.95, 0.55) if randf() < 0.6 else Color(0.6, 0.9, 1.0)
		s.position = at
		s.z_as_relative = false
		s.z_index = 151
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(s)
		var dir = Vector2.from_angle(randf_range(-PI, 0.3)) * randf_range(14, 40)
		var tw = s.create_tween()
		tw.tween_property(s, "position", at + dir + Vector2(0, 18), randf_range(0.25, 0.5)).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.45)
		tw.tween_callback(s.queue_free)


## ---------------------------------------------------------------- incidents
## From the first shift (right after the accident) every job of the fish has a 5% chance that
## something breaks at its press in the middle of the work: a FIRE on the belt, the press
## SHORTS out, or its button gets STUCK. Each one is a small minigame of its own (only the
## interact key). Handled -> the box goes through (green). Failed -> our mistake (red).
func _roll_incident() -> int:
	if randf() >= INCIDENT_CHANCE:
		return MGE_NONE
	return [MGE_FIRE, MGE_SHORT, MGE_STUCK][randi() % 3]


## Waits a random moment into the normal minigame, then breaks into it with the incident.
func _incident_during_job(kind: int, it: Dictionary) -> void:
	var delay = randf_range(0.15, 0.55)
	var t := 0.0
	while t < delay:
		await _tree().process_frame
		if not is_inside_tree():
			return
		if not _tree().paused:
			t += get_process_delta_time()
	# the fish was quicker - nothing broke this time
	if not minigame_active or state != State.MINIGAME or _player_item != it:
		return
	minigame_active = false
	for n in [minigame_panel, _mg_canvas]:
		if n:
			n.visible = false
	var ok = await _run_incident(kind)
	if state == State.DEAD or state == State.SHIFT_END:
		player_job_finished.emit()
		return
	_last_quality = 1.0 if ok else 0.0
	await _player_press_result(ok)


## The alarm before an incident: the screen edges blink red twice and the incident window
## pops in (instead of breaking into a job that is already running).
func _incident_alarm() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var edge = ColorRect.new()
	edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh = Shader.new()
	sh.code = """shader_type canvas_item;
uniform float a = 0.0;
void fragment() {
	vec2 cc = UV - 0.5;
	float v = smoothstep(0.32, 0.75, length(cc * vec2(1.25, 1.0)));
	COLOR = vec4(0.95, 0.35, 0.08, v * 0.55 * a);
}
"""
	var em = ShaderMaterial.new()
	em.shader = sh
	edge.material = em
	layer.add_child(edge)
	var tw = create_tween()
	for i in range(2):
		tw.tween_method(func(v): em.set_shader_parameter("a", v), 0.0, 1.0, 0.12)
		tw.tween_method(func(v): em.set_shader_parameter("a", v), 1.0, 0.0, 0.22)
	tw.tween_callback(layer.queue_free)

func _pop_in(n: Control, from_scale: float = 0.6) -> void:
	if n == null:
		return
	n.pivot_offset = n.size * 0.5
	n.scale = Vector2.ONE * from_scale
	n.modulate.a = 0.0
	var tw = n.create_tween().set_parallel(true)
	tw.tween_property(n, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "modulate:a", 1.0, 0.18)

func _run_incident(kind: int, forgive: bool = false) -> bool:
	state = State.MINIGAME
	_inc_kind = kind
	_inc_active = true
	_inc_t = 0.0
	_inc_pressed = false
	_inc_flash = 0.0
	_inc_result = 0
	var key = _key_name("interact")
	var press: Node2D = presses[player_station] if player_station < presses.size() else null
	var btn = press.to_global(PRESS_BUTTON_LOCAL) if press else Vector2(_get_stop_zone_x(player_station), 300)
	var belt = Vector2(_get_stop_zone_x(player_station), BELT_SURFACE_Y)
	var hard = clamp(current_shift - 1, 0, 3)
	# it starts smoothly: an alarm blink, then the window pops in
	UISounds.play_switch_off()
	_incident_alarm()
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.12)
	await _tree().create_timer(0.45, false).timeout
	if not is_inside_tree():
		return false
	UISounds.play_hit()
	_mg_title.position = Vector2(376, 186)
	_mg_title.modulate = Color.WHITE
	_mg_title.visible = true
	hint_label.position = Vector2(326, 418)
	hint_label.visible = not forgive
	var fire: Node2D = null
	var explain := ""
	_incident_setup(kind, hard)
	match kind:
		MGE_FIRE:
			_mg_title.text = "ПОЖАР НА КОНВЕЙЕРЕ!"
			hint_label.text = "Искра из пресса подожгла товар!\nДЕРЖИ " + key + " — пена. Потуши все очаги"
			explain = "Искра подожгла товар. Брандспойт качается сам. Когда он над огнём — ДЕРЖИ " + key + ", пена тушит. Пена кончается — отпусти, бак наполнится. Потуши все три очага."
			fire = _make_world_fire(belt)
		MGE_SHORT:
			_mg_title.text = "ЗАМЫКАНИЕ ПРЕССА!"
			hint_label.text = "Пресс коротнуло — предохранители искрят!\n" + key + " — сбрось тот, что искрит"
			explain = "Предохранители заряжаются искрами. Огонёк бегает по ним — нажми " + key + ", когда он на ИСКРЯЩЕМ, и он сбросится. Не жми на спокойные."
			_spawn_sparks(btn, 16)
		MGE_STUCK:
			_mg_title.text = "КНОПКУ ЗАКЛИНИЛО!"
			hint_label.text = "Кнопка застряла в корпусе — пресс встал.\nДЕРЖИ " + key + " — замах, ОТПУСТИ в зелёной зоне. Нужно 3 сильных удара"
			explain = "Кнопка застряла. ДЕРЖИ " + key + " — шкала замаха растёт. ОТПУСТИ, когда она в зелёной зоне. Нужно 3 таких удара."
	_inc_canvas.modulate = Color.WHITE
	_inc_canvas.visible = true
	_pop_in(_inc_canvas)
	_mg_title.reset_size()
	_center_mg_title()
	if forgive:
		_spot_show("АВАРИЯ: ЧТО ДЕЛАТЬ", explain + " Пока учишься — неудача не считается.", [key], _inc_screen_rect, false)
	var spark_t := 0.0
	var ok := false
	while true:
		while _inc_result == 0 and state != State.DEAD and state != State.SHIFT_END:
			await _tree().process_frame
			if not is_inside_tree():
				return false
			if _tree().paused:
				continue
			var dt = get_process_delta_time()
			_inc_t += dt
			_inc_flash = max(0.0, _inc_flash - dt * 3.0)
			match kind:
				MGE_FIRE:
					_fire_step(dt, hard)
					_update_world_fire(fire, dt)
					if _fire_spray and randf() < 0.35:
						_inc_puff(belt + Vector2(randf_range(-16, 16), -6), Color(0.85, 0.92, 1.0, 0.8))
					var power = (_fire_lv[0] + _fire_lv[1] + _fire_lv[2]) / 3.0
					if randf() < 0.1 * power and camera and camera.has_method("add_trauma"):
						camera.add_trauma(0.03)
				MGE_SHORT:
					_short_step(dt)
					spark_t -= dt
					if spark_t <= 0.0:
						spark_t = randf_range(0.12, 0.35)
						var hot = 0
						for c in _fuse_charge:
							if c >= 0.0:
								hot += 1
						if hot > 0:
							_spawn_sparks(btn, 2 + hot)
				MGE_STUCK:
					_stuck_step(dt)
			if _inc_t >= _inc_time and _inc_result == 0:
				_inc_result = -1
			_mg_title.modulate = Color(1.0, 0.5 + 0.4 * abs(sin(_inc_t * 8.0)), 0.35)
			_inc_canvas.queue_redraw()
		ok = _inc_result > 0
		if ok or not forgive or state == State.DEAD or state == State.SHIFT_END:
			break
		# learning: a failure does not count - the same incident once more
		_inc_flash = 1.0
		_inc_flash_good = false
		UISounds.play_switch_off()
		_mg_title.text = "НЕ ВЫШЛО — ЕЩЁ РАЗ!"
		await _tree().create_timer(0.9, false).timeout
		if not is_inside_tree():
			return false
		_incident_setup(kind, hard)
		_mg_title.text = {MGE_FIRE: "ПОЖАР НА КОНВЕЙЕРЕ!", MGE_SHORT: "ЗАМЫКАНИЕ ПРЕССА!", MGE_STUCK: "КНОПКУ ЗАКЛИНИЛО!"}.get(kind, "")
	if forgive and _spot:
		_spot.hide_step()
	_inc_active = false
	_inc_flash = 1.0
	_inc_flash_good = ok
	_inc_canvas.queue_redraw()
	_mg_title.modulate = Color.WHITE
	_mg_title.text = ("ЛИКВИДИРОВАНО!" if ok else ("ТОВАР СГОРЕЛ!" if kind == MGE_FIRE else ("ПРОБКИ ВЫБИЛО!" if kind == MGE_SHORT else "НЕ УСПЕЛ!")))
	hint_label.visible = false
	if not ok:
		UISounds.play_switch_off()
	var tw = _inc_canvas.create_tween()
	_inc_canvas.modulate = Color(0.6, 1.6, 0.6) if ok else Color(1.8, 0.5, 0.5)
	tw.tween_property(_inc_canvas, "modulate", Color(1, 1, 1, 0), 0.4).set_delay(0.35)
	tw.tween_callback(func(): _inc_canvas.visible = false)
	var tw2 = _mg_title.create_tween()
	tw2.tween_property(_mg_title, "modulate:a", 0.0, 0.4).set_delay(0.35)
	tw2.tween_callback(func():
		_mg_title.visible = false
		_mg_title.modulate = Color.WHITE
	)
	if fire:
		_put_out_world_fire(fire, belt)
	if kind == MGE_SHORT and not ok:
		_spawn_sparks(btn, 20)
		if camera and camera.has_method("add_trauma"):
			camera.add_trauma(0.35)
	await _tree().create_timer(0.35, false).timeout
	if not is_inside_tree():
		return false
	if state == State.MINIGAME:
		state = State.WORKING
	return ok


## ---------------------------------------------------------------- the fire on the belt
## Three flames (each a few layered tongues: dark red outside, orange, a yellow-white core)
## that grow with the fire level, a warm glow on the floor, embers flying up and smoke.
func _make_world_fire(at: Vector2) -> Node2D:
	var fire = Node2D.new()
	fire.z_as_relative = false
	fire.z_index = 45
	fire.position = at
	add_child(fire)
	# glow
	var glow = Sprite2D.new()
	glow.name = "Glow"
	var gt = GradientTexture2D.new()
	gt.width = 64
	gt.height = 64
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var g = Gradient.new()
	g.set_color(0, Color(1.0, 0.6, 0.2, 0.55))
	g.set_color(1, Color(1.0, 0.4, 0.1, 0.0))
	gt.gradient = g
	glow.texture = gt
	glow.scale = Vector2(2.2, 1.4)
	glow.position = Vector2(0, -10)
	var am = CanvasItemMaterial.new()
	am.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = am
	fire.add_child(glow)
	# flames: 3 spots x 3 layers
	for i in range(3):
		for L in range(3):
			var p = Polygon2D.new()
			p.name = "F%d_%d" % [i, L]
			p.color = [Color8(200, 46, 26), Color8(255, 130, 36), Color8(255, 226, 120)][L]
			p.position = Vector2(-14 + i * 14, 0)
			fire.add_child(p)
	# embers
	var em = CPUParticles2D.new()
	em.name = "Embers"
	var img = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	em.texture = ImageTexture.create_from_image(img)
	em.amount = 18
	em.lifetime = 0.9
	em.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	em.emission_rect_extents = Vector2(18, 2)
	em.position = Vector2(0, -6)
	em.direction = Vector2(0, -1)
	em.spread = 25.0
	em.gravity = Vector2(0, -20)
	em.initial_velocity_min = 25.0
	em.initial_velocity_max = 60.0
	em.scale_amount_min = 0.5
	em.scale_amount_max = 1.0
	var eg = Gradient.new()
	eg.set_color(0, Color(1.0, 0.9, 0.5, 1.0))
	eg.set_color(1, Color(1.0, 0.3, 0.1, 0.0))
	em.color_ramp = eg
	em.material = am
	fire.add_child(em)
	# smoke
	var sm = CPUParticles2D.new()
	sm.name = "Smoke"
	sm.texture = em.texture
	sm.amount = 14
	sm.lifetime = 1.6
	sm.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sm.emission_rect_extents = Vector2(14, 2)
	sm.position = Vector2(0, -26)
	sm.direction = Vector2(0, -1)
	sm.spread = 15.0
	sm.gravity = Vector2(4, -10)
	sm.initial_velocity_min = 12.0
	sm.initial_velocity_max = 24.0
	sm.scale_amount_min = 2.0
	sm.scale_amount_max = 4.0
	var sg = Gradient.new()
	sg.set_color(0, Color(0.25, 0.24, 0.24, 0.0))
	sg.add_point(0.25, Color(0.3, 0.29, 0.29, 0.55))
	sg.set_color(sg.get_point_count() - 1, Color(0.4, 0.4, 0.42, 0.0))
	sm.color_ramp = sg
	fire.add_child(sm)
	fire.set_meta("t", 0.0)
	_update_world_fire(fire, 0.0)
	return fire

func _update_world_fire(fire: Node2D, dt: float) -> void:
	if fire == null or not is_instance_valid(fire):
		return
	var t: float = fire.get_meta("t") + dt
	fire.set_meta("t", t)
	var power = (_fire_lv[0] + _fire_lv[1] + _fire_lv[2]) / 3.0
	for i in range(3):
		var lv: float = _fire_lv[i]
		for L in range(3):
			var p = fire.get_node_or_null("F%d_%d" % [i, L]) as Polygon2D
			if p == null:
				continue
			p.visible = lv > 0.02
			if not p.visible:
				continue
			var s = [1.0, 0.7, 0.4][L]
			var h = (8.0 + 30.0 * lv) * s * (0.85 + 0.15 * sin(t * 17.0 + i * 1.9 + L))
			var w = (4.0 + 5.0 * lv) * s
			var sway = sin(t * 9.0 + i * 2.3) * 2.5 * s
			# a flame: wide round bottom, a curling tip
			var pts = PackedVector2Array()
			for k in range(9):
				var a = PI * k / 8.0
				pts.append(Vector2(-cos(a) * w, -sin(a) * w * 0.7))
			pts.append(Vector2(w * 0.55 + sway * 0.4, -h * 0.45))
			pts.append(Vector2(sway, -h))
			pts.append(Vector2(-w * 0.6 + sway * 0.5, -h * 0.5))
			p.polygon = pts
	var glow = fire.get_node_or_null("Glow") as Sprite2D
	if glow:
		glow.modulate.a = clamp(power * 1.4, 0.0, 1.0) * (0.8 + 0.2 * sin(t * 23.0))
	var em = fire.get_node_or_null("Embers") as CPUParticles2D
	if em:
		em.emitting = power > 0.05
	var sm = fire.get_node_or_null("Smoke") as CPUParticles2D
	if sm:
		sm.emitting = power > 0.02

func _put_out_world_fire(fire: Node2D, belt: Vector2) -> void:
	if fire == null or not is_instance_valid(fire):
		return
	for i in range(8):
		_inc_puff(belt + Vector2(randf_range(-14, 14), -6), Color(0.55, 0.55, 0.58, 0.8))
	for n in fire.get_children():
		if n is CPUParticles2D:
			n.emitting = false
		elif n is Polygon2D or n is Sprite2D:
			n.visible = false
	var tw = fire.create_tween()
	tw.tween_interval(1.8)
	tw.tween_callback(fire.queue_free)


## Starting numbers of an incident (hard = 0 on the first shifts, up to 3 later).
func _incident_setup(kind: int, hard: int) -> void:
	_inc_kind = kind
	_inc_t = 0.0
	_inc_result = 0
	_inc_pressed = false
	match kind:
		MGE_FIRE:
			_inc_time = 8.0 - 0.3 * hard
			_fire_lv = [randf_range(0.45, 0.62), randf_range(0.52, 0.7), randf_range(0.45, 0.62)]
			_fire_tank = 1.0
			_fire_dry = false
			_fire_spray = false
			_fire_phase = randf() * 2.4
		MGE_SHORT:
			_inc_time = 12.0
			_fuse_charge = [-1.0, -1.0, -1.0]
			_fuse_sel = 0.0
			_fuse_dir = 1.0
			_fuse_need = 4
			_fuse_left = _fuse_need
			_fuse_next = 0.25
			_fuse_speed = 1.15 + 0.05 * hard
		MGE_STUCK:
			_inc_time = 9.0 - 0.3 * hard
			_stk_power = 0.0
			_stk_hits = 0
			_stk_need = 3
			_stk_tired = 0.0
			_stk_btn = 0.0
			_stk_was_held = Input.is_action_pressed("interact")
			_stk_new_zone(STK_ZONE_W[0])


func _inc_puff(at: Vector2, col: Color) -> void:
	var puff = ColorRect.new()
	puff.size = Vector2(4, 4)
	puff.color = col
	puff.position = at
	puff.z_as_relative = false
	puff.z_index = 46
	puff.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(puff)
	var tw = puff.create_tween()
	tw.tween_property(puff, "position", at + Vector2(randf_range(-6, 6), -randf_range(18, 34)), 0.8)
	tw.parallel().tween_property(puff, "modulate:a", 0.0, 0.8)
	tw.tween_callback(puff.queue_free)


## FIRE: three flames on the box. The foam nozzle swings over them by itself while the key is
## free; holding the key braces the hose (it nearly stops) and sprays foam where it points.
## The tank runs dry while spraying (refills when released) and the flames grow back - let it
## swing to a burning flame, spray it, let go, catch the next one.
func _fire_step(dt: float, hard: int) -> void:
	var held = Input.is_action_pressed("interact")
	_fire_phase += dt * (0.08 if (held and not _fire_dry) else 1.0)
	_fire_nozzle = 0.5 + 0.47 * sin(_fire_phase * TAU / 2.4)
	if _fire_dry and _fire_tank >= 0.35:
		_fire_dry = false
	_fire_spray = held and not _fire_dry and _fire_tank > 0.0
	if _fire_spray:
		_fire_tank = max(0.0, _fire_tank - 0.42 * dt)
		if _fire_tank <= 0.0:
			_fire_dry = true
			UISounds.play_switch_off()
	else:
		_fire_tank = min(1.0, _fire_tank + 0.28 * dt)
	var out := 0
	for i in range(3):
		var lv: float = _fire_lv[i]
		if lv <= 0.0:
			out += 1
			continue
		var centre = (i + 0.5) / 3.0
		var hit = clamp(1.0 - (abs(_fire_nozzle - centre) - 0.08) / 0.09, 0.0, 1.0)
		if _fire_spray and hit > 0.0:
			lv -= 1.5 * hit * dt
		else:
			lv += (0.07 + 0.015 * hard) * dt
		if lv <= 0.02:
			lv = 0.0
			UISounds.play_click()
		_fire_lv[i] = lv
		if lv >= 1.0:
			_inc_result = -1
			return
	if out >= 3:
		_inc_result = 1


## SHORT CIRCUIT: sparks jump onto the three fuses and charge them up. A selector light keeps
## running over the fuses; press when it is on a sparking one to reset it before it blows.
## A click on a calm fuse makes the others spark harder.
func _short_step(dt: float) -> void:
	_fuse_sel += _fuse_dir * _fuse_speed * dt
	if _fuse_sel >= 1.0:
		_fuse_sel = 1.0
		_fuse_dir = -1.0
	elif _fuse_sel <= 0.0:
		_fuse_sel = 0.0
		_fuse_dir = 1.0
	var active := 0
	for c in _fuse_charge:
		if c >= 0.0:
			active += 1
	_fuse_next -= dt
	if _fuse_next <= 0.0 and active < min(2, _fuse_left):
		var calm: Array = []
		for i in range(3):
			if _fuse_charge[i] < 0.0:
				calm.append(i)
		if not calm.is_empty():
			_fuse_charge[calm[randi() % calm.size()]] = 0.0
			UISounds.play_switch_off()
		_fuse_next = randf_range(0.55, 1.05)
	for i in range(3):
		if _fuse_charge[i] >= 0.0:
			_fuse_charge[i] += dt / 2.6
			if _fuse_charge[i] >= 1.0:
				_inc_result = -1
				return
	if _inc_pressed:
		_inc_pressed = false
		var slot = _fuse_slot()
		if _fuse_charge[slot] >= 0.0:
			_fuse_charge[slot] = -1.0
			_fuse_left -= 1
			_inc_flash = 0.8
			_inc_flash_good = true
			UISounds.play_switch_on()
			if camera and camera.has_method("add_trauma"):
				camera.add_trauma(0.08)
			if _fuse_left <= 0:
				_inc_result = 1
		else:
			for i in range(3):
				if _fuse_charge[i] >= 0.0:
					_fuse_charge[i] = min(0.97, _fuse_charge[i] + 0.18)
			_inc_flash = 0.7
			_inc_flash_good = false
			UISounds.play_switch_off()
			if camera and camera.has_method("add_trauma"):
				camera.add_trauma(0.05)


func _fuse_slot() -> int:
	return clamp(int(_fuse_sel * 3.0), 0, 2)


## STUCK BUTTON: hold the key to wind up a punch (it speeds up near the top), let go in the
## green zone. Past the top the arm overswings and needs a moment. 3 strong punches knock the
## button loose; a weak one just rattles it.
func _stuck_step(dt: float) -> void:
	var held = Input.is_action_pressed("interact")
	_inc_pressed = false
	if _stk_tired > 0.0:
		_stk_tired = max(0.0, _stk_tired - dt)
		_stk_power = move_toward(_stk_power, 0.0, dt * 3.0)
		_stk_was_held = held
		return
	if held:
		_stk_power += (0.34 + 1.1 * _stk_power) * dt
		if _stk_power >= 1.0:
			_stk_power = 0.0
			_stk_tired = 0.45
			_inc_flash = 0.7
			_inc_flash_good = false
			UISounds.play_switch_off()
			_float_text("ПЕРЕБОР!", Color(1.0, 0.5, 0.4), -14.0)
	elif _stk_was_held and _stk_power > 0.12:
		_player_punch()
		if _stk_power >= _stk_zone.x and _stk_power <= _stk_zone.y:
			_stk_hits += 1
			_stk_btn = float(_stk_hits) / float(_stk_need)
			_inc_flash = 1.0
			_inc_flash_good = true
			UISounds.play_hit()
			if camera and camera.has_method("add_trauma"):
				camera.add_trauma(0.18)
			if _stk_hits >= _stk_need:
				_inc_result = 1
			else:
				_stk_new_zone(STK_ZONE_W[min(_stk_hits, STK_ZONE_W.size() - 1)])
		else:
			_inc_flash = 0.5
			_inc_flash_good = false
			UISounds.play_click()
			if camera and camera.has_method("add_trauma"):
				camera.add_trauma(0.05)
			_float_text("СЛАБО!" if _stk_power < _stk_zone.x else "МИМО!", Color(1.0, 0.7, 0.4), -14.0)
		_stk_power = 0.0
	else:
		_stk_power = move_toward(_stk_power, 0.0, dt * 2.0)
	_stk_was_held = held


func _stk_new_zone(width: float) -> void:
	var lo = randf_range(0.5, 0.92 - width)
	_stk_zone = Vector2(lo, lo + width)


## The incident panel (same pixel window as the other minigames).
func _draw_incident() -> void:
	var c = _inc_canvas
	if c == null:
		return
	var dark = Color8(19, 31, 52)
	var rim = Color8(30, 50, 82)
	var green = Color8(166, 204, 52)
	var green_d = Color8(81, 136, 34)
	var blue = Color8(103, 154, 190)
	var red = Color8(230, 70, 60)
	c.draw_rect(Rect2(0, 0, 200, 200), Color.BLACK)
	# hazard rim: the window itself warns that something broke
	for k in range(25):
		c.draw_rect(Rect2(k * 8, 0, 4, 4), Color8(240, 170, 40) if int(_inc_t * 6.0) % 2 == 0 else Color8(60, 40, 20))
		c.draw_rect(Rect2(k * 8 + 4, 196, 4, 4), Color8(240, 170, 40) if int(_inc_t * 6.0) % 2 == 0 else Color8(60, 40, 20))
	c.draw_rect(Rect2(4, 4, 192, 192), rim)
	c.draw_rect(Rect2(8, 8, 184, 184), dark)
	if _inc_flash > 0.0:
		var fc = green if _inc_flash_good else red
		c.draw_rect(Rect2(8, 8, 184, 184), Color(fc.r, fc.g, fc.b, 0.35 * _inc_flash))
	# time left
	var left = clamp(1.0 - _inc_t / max(0.01, _inc_time), 0.0, 1.0)
	match _inc_kind:
		MGE_FIRE:
			_draw_fire_mg(c, green, blue, red, rim)
			c.draw_rect(Rect2(20, 182, 160, 6), Color.BLACK)
			c.draw_rect(Rect2(21, 183, 158 * left, 4), blue if left > 0.3 else red)
		MGE_SHORT:
			_draw_short_mg(c, green, green_d, blue, red, rim)
		MGE_STUCK:
			_draw_stuck_mg(c, green, green_d, blue, red, rim)
			c.draw_rect(Rect2(20, 182, 160, 6), Color.BLACK)
			c.draw_rect(Rect2(21, 183, 158 * left, 4), blue if left > 0.3 else red)


func _draw_fire_mg(c: Control, _green: Color, blue: Color, red: Color, _rim: Color) -> void:
	# the box on the belt
	c.draw_rect(Rect2(22, 150, 156, 4), Color8(40, 46, 58))
	c.draw_rect(Rect2(30, 128, 140, 24), Color.BLACK)
	c.draw_rect(Rect2(32, 130, 136, 20), Color8(150, 112, 72))
	c.draw_rect(Rect2(32, 130, 136, 3), Color8(186, 146, 98))
	for k in range(3):
		var cx = 20.0 + 160.0 * (k + 0.5) / 3.0
		var lv: float = _fire_lv[k]
		if lv <= 0.0:
			# put out: a thin wisp of smoke
			for j in range(3):
				var sy = 120.0 - fmod(_inc_t * 30.0 + j * 14.0, 42.0)
				c.draw_rect(Rect2(cx - 2 + sin(_inc_t * 4.0 + j) * 3.0, sy, 4, 4), Color(0.6, 0.62, 0.66, 0.45))
			continue
		var h = 12.0 + 92.0 * lv
		var w = 12.0 + 16.0 * lv
		# warm glow behind the flame
		for g in range(4):
			c.draw_circle(Vector2(cx, 128 - h * 0.35), w * (1.6 - g * 0.3) + h * 0.15, Color(1.0, 0.45, 0.1, 0.05 + 0.03 * g))
		var layers = [[Color8(170, 34, 22), 1.0], [Color8(240, 90, 30), 0.82], [Color8(255, 160, 50), 0.6], [Color8(255, 236, 150), 0.34]]
		for L in layers:
			var col: Color = L[0]
			var s: float = L[1]
			var fl = 1.0 + 0.14 * sin(_inc_t * 15.0 + k * 2.1 + s * 5.0)
			var sway = sin(_inc_t * 8.0 + k * 1.3 + s * 2.0) * 6.0 * s
			# a real flame outline: round belly, two side licks, a curling tip
			var pts = PackedVector2Array()
			var steps = 14
			for i2 in range(steps + 1):
				var u = float(i2) / steps                       # 0 = bottom left, 1 = bottom right (around the top)
				var ang = PI * (1.0 - u)
				var rx = cos(ang) * w * s
				var top = sin(ang)
				var hh = h * s * fl * pow(top, 0.65)
				var lick = sin(u * 9.0 + _inc_t * 12.0 + k) * 2.5 * s * top
				pts.append(Vector2(cx + rx * (1.0 - 0.55 * top) + sway * top * top + lick, 131.0 - hh))
			c.draw_colored_polygon(pts, col)
		# sparks flying up out of it
		for e in range(4):
			var ph = fmod(_inc_t * (1.1 + e * 0.2) + k * 0.37 + e * 0.29, 1.0)
			var ex = cx + sin(e * 2.7 + _inc_t * 3.0 + k) * (w * 0.6) + ph * 6.0
			var ey = 128.0 - h * 0.5 - ph * (40.0 + 30.0 * lv)
			c.draw_rect(Rect2(ex, ey, 2, 2), Color(1.0, 0.85 - ph * 0.5, 0.3, 1.0 - ph))
		# how big it is
		c.draw_rect(Rect2(cx - 16, 160, 32, 5), Color.BLACK)
		c.draw_rect(Rect2(cx - 15, 161, 30 * lv, 3), red if lv > 0.75 else Color8(255, 150, 50))
	# nozzle + foam
	var nx = 20.0 + 160.0 * _fire_nozzle
	if _fire_spray:
		for j in range(14):
			var fy = 34.0 + fmod(_inc_t * 260.0 + j * 13.0, 96.0)
			var fx = nx + sin(j * 2.3 + _inc_t * 20.0) * (2.0 + (fy - 34.0) * 0.12)
			c.draw_rect(Rect2(fx - 2, fy, 4, 4), Color(0.92, 0.97, 1.0, 0.9))
	c.draw_rect(Rect2(nx - 7, 14, 14, 14), Color.BLACK)
	c.draw_rect(Rect2(nx - 5, 16, 10, 10), Color8(210, 60, 50))
	c.draw_rect(Rect2(nx - 3, 26, 6, 8), Color.BLACK)
	c.draw_rect(Rect2(nx - 2, 27, 4, 6), Color8(60, 64, 72))
	# foam tank (right edge)
	var tank_h = 104.0
	c.draw_rect(Rect2(178, 30, 10, tank_h + 4), Color.BLACK)
	var tcol = blue if not _fire_dry else (red if int(_inc_t * 8.0) % 2 == 0 else Color8(90, 30, 30))
	c.draw_rect(Rect2(180, 32 + tank_h * (1.0 - _fire_tank), 6, tank_h * _fire_tank), tcol)


func _draw_short_mg(c: Control, green: Color, green_d: Color, _blue: Color, red: Color, _rim: Color) -> void:
	# sparks still to kill
	for i in range(_fuse_need):
		var r = Rect2(100 - _fuse_need * 9 + i * 18, 14, 12, 8)
		c.draw_rect(r, Color.BLACK)
		c.draw_rect(r.grow(-2), green if i < _fuse_need - _fuse_left else green_d.darkened(0.5))
	var slot = _fuse_slot()
	for i in range(3):
		var cx = 40.0 + i * 60.0
		var ch: float = _fuse_charge[i]
		var on = ch >= 0.0
		# selector frame
		if i == slot:
			var sc = Color8(250, 240, 160) if on else Color8(120, 140, 170)
			c.draw_rect(Rect2(cx - 25, 38, 50, 122), sc)
			c.draw_rect(Rect2(cx - 23, 40, 46, 118), Color8(19, 31, 52))
		# fuse body
		c.draw_rect(Rect2(cx - 14, 52, 28, 82), Color.BLACK)
		c.draw_rect(Rect2(cx - 12, 54, 24, 8), Color8(170, 170, 160))
		c.draw_rect(Rect2(cx - 12, 124, 24, 8), Color8(170, 170, 160))
		var glass = Color8(40, 60, 70)
		if on:
			glass = Color8(255, 200, 80).lerp(Color8(230, 245, 255), ch)
			glass = glass.lerp(Color8(255, 255, 255), 0.3 * abs(sin(_inc_t * (10.0 + 20.0 * ch))))
		c.draw_rect(Rect2(cx - 10, 62, 20, 62), glass)
		c.draw_rect(Rect2(cx - 1, 64, 2, 58), Color8(60, 50, 40) if not on else Color8(120, 60, 30))
		# arcs around a sparking fuse
		if on:
			for a in range(2 + int(ch * 3.0)):
				var pts = PackedVector2Array()
				var y = 60.0 + randf() * 64.0
				var x0 = cx + (16.0 if a % 2 == 0 else -16.0)
				pts.append(Vector2(x0, y))
				for s in range(4):
					pts.append(Vector2(x0 + (s + 1) * (4.0 if a % 2 == 0 else -4.0), y + randf_range(-6, 6)))
				c.draw_polyline(pts, Color8(200, 235, 255), 2.0)
		# charge bar
		c.draw_rect(Rect2(cx - 20, 142, 40, 8), Color.BLACK)
		if on:
			c.draw_rect(Rect2(cx - 19, 143, 38 * ch, 6), Color8(255, 190, 60).lerp(red, ch))
		# LED
		var led = green if not on else (red if int(_inc_t * (6.0 + 14.0 * ch)) % 2 == 0 else Color8(90, 30, 30))
		c.draw_rect(Rect2(cx - 3, 166, 6, 6), Color.BLACK)
		c.draw_rect(Rect2(cx - 2, 167, 4, 4), led)
	# the running selector light
	var sx = 16.0 + 168.0 * _fuse_sel
	c.draw_colored_polygon(PackedVector2Array([Vector2(sx - 6, 178), Vector2(sx + 6, 178), Vector2(sx, 186)]), Color8(250, 240, 160))


## Text inside the incident window (outlined, centred on x).
func _inc_text(c: Control, txt: String, cx: float, y: float, size: int, col: Color) -> void:
	var f = _bubble_font()
	if f == null:
		return
	var w = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p = Vector2(round(cx - w / 2.0), round(y))
	c.draw_string_outline(f, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0.02, 0.03, 0.06))
	c.draw_string(f, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _draw_stuck_mg(c: Control, green: Color, green_d: Color, blue: Color, red: Color, _rim: Color) -> void:
	# how many strong punches are still needed
	_inc_text(c, "ВЫБЕЙ КНОПКУ  " + str(_stk_hits) + "/" + str(_stk_need), 100, 22, 11, Color(0.92, 0.94, 0.98))
	for i in range(_stk_need):
		var r = Rect2(100 - _stk_need * 9 + i * 18, 27, 12, 6)
		c.draw_rect(r, Color.BLACK)
		c.draw_rect(r.grow(-1), green if i < _stk_hits else green_d.darkened(0.5))
	# the stuck button in its housing; every strong punch knocks it a bit further out
	var ctr = Vector2(100, 78)
	var shake = Vector2(sin(_inc_t * 70.0), cos(_inc_t * 63.0)) * 2.0 * _stk_power if _stk_power > 0.6 else Vector2.ZERO
	c.draw_rect(Rect2(ctr.x - 44, ctr.y - 30, 88, 64), Color.BLACK)
	c.draw_rect(Rect2(ctr.x - 42, ctr.y - 28, 84, 60), Color8(70, 76, 90))
	c.draw_rect(Rect2(ctr.x - 42, ctr.y - 28, 84, 4), Color8(110, 118, 136))
	for k in range(6):
		c.draw_rect(Rect2(ctr.x - 40 + k * 14, ctr.y + 24, 7, 4), Color8(240, 170, 40))
	var sink = 12.0 * (1.0 - _stk_btn)
	var cap = Rect2(ctr.x - 24, ctr.y - 18 + sink, 48, 30 - sink * 0.5)
	cap.position += shake
	c.draw_rect(cap.grow(2), Color.BLACK)
	var capc = Color8(150, 40, 36).lerp(Color8(230, 60, 50), _stk_btn)
	c.draw_rect(cap, capc)
	c.draw_rect(Rect2(cap.position.x, cap.position.y, cap.size.x, 4), capc.lightened(0.35))
	# cracks in the jammed rim
	if _stk_btn < 1.0:
		c.draw_line(ctr + Vector2(-30, -26), ctr + Vector2(-22, -14), Color8(30, 30, 36), 2)
		c.draw_line(ctr + Vector2(30, 30), ctr + Vector2(24, 18), Color8(30, 30, 36), 2)
	# power meter
	var bar = Rect2(20, 132, 160, 16)
	_inc_text(c, "СИЛА ЗАМАХА", 100, 125, 9, Color(0.7, 0.76, 0.86))
	c.draw_rect(bar.grow(2), Color.BLACK)
	c.draw_rect(bar, Color(0.03, 0.05, 0.09))
	var zx0 = bar.position.x + bar.size.x * _stk_zone.x
	var zx1 = bar.position.x + bar.size.x * _stk_zone.y
	c.draw_rect(Rect2(zx0, bar.position.y, zx1 - zx0, bar.size.y), green_d)
	c.draw_rect(Rect2(zx0 + 2, bar.position.y + 2, zx1 - zx0 - 4, bar.size.y - 4), Color(green, 0.75 + 0.25 * sin(_inc_t * 8.0)))
	# overswing end
	for k in range(4):
		c.draw_rect(Rect2(bar.end.x - 12 + k * 3, bar.position.y, 2, bar.size.y), red if k % 2 == 0 else Color8(60, 20, 20))
	var fx = bar.position.x + bar.size.x * clamp(_stk_power, 0.0, 1.0)
	var in_zone = _stk_power >= _stk_zone.x and _stk_power <= _stk_zone.y
	var pcol = Color8(230, 240, 255) if in_zone else (blue if _stk_tired <= 0.0 else red)
	c.draw_rect(Rect2(bar.position.x, bar.position.y + 5, fx - bar.position.x, 8), Color(pcol, 0.55))
	c.draw_rect(Rect2(fx - 2, bar.position.y - 4, 4, bar.size.y + 8), Color.BLACK)
	c.draw_rect(Rect2(fx - 1, bar.position.y - 3, 2, bar.size.y + 6), pcol)
	# a small arrow over the green part: release here
	var zc = (zx0 + zx1) * 0.5
	var bob = round(sin(_inc_t * 6.0) * 1.5)
	c.draw_colored_polygon(PackedVector2Array([Vector2(zc - 4, bar.position.y - 7 + bob), Vector2(zc + 4, bar.position.y - 7 + bob), Vector2(zc, bar.position.y - 2 + bob)]), green)
	# what to do RIGHT NOW
	var held = Input.is_action_pressed("interact")
	var key = _key_name("interact")
	var msg = ""
	var mcol = Color(0.92, 0.94, 0.98)
	if _stk_tired > 0.0:
		msg = "ПЕРЕБОР! ПОДОЖДИ..."
		mcol = red.lightened(0.2)
	elif in_zone and held:
		msg = "ОТПУСТИ!"
		mcol = green.lightened(0.3) if int(_inc_t * 10.0) % 2 == 0 else Color.WHITE
	elif held:
		msg = "ДЕРЖИ... ЗАМАХ"
		mcol = blue.lightened(0.3)
	else:
		msg = "ЗАЖМИ " + key
		mcol = Color(1.0, 0.86, 0.4) if int(_inc_t * 3.0) % 2 == 0 else Color(0.92, 0.94, 0.98)
	_inc_text(c, msg, 100, 170, 13 if msg == "ОТПУСТИ!" else 11, mcol)


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


## by_player = false: somebody else ruined it (a fish, an accident) - the box is just
## skipped: a grey cell, neither right nor wrong for the player.
func _break_item(it: Dictionary, packing: bool = false, animate: bool = true, by_player: bool = true) -> void:
	if it["broken"] or it["done"]:
		return
	it["broken"] = true
	if by_player:
		wrong_count += 1
		_mark_progress(it["index"], false)
	else:
		_mark_skipped(it["index"])
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


func _apply_stage(obj, stage: int, pop: bool = true) -> void:
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
		await _tree().create_timer(0.25, false).timeout
		if not is_inside_tree():
			return
		return
	spr.play(anim)
	var dur := 0.35
	if not spr.sprite_frames.get_animation_loop(anim):
		var spd = max(spr.sprite_frames.get_animation_speed(anim) * abs(spr.speed_scale), 0.01)
		var total := 0.0
		for i in range(spr.sprite_frames.get_frame_count(anim)):
			total += spr.sprite_frames.get_frame_duration(anim, i)
		dur = total / spd
	await _tree().create_timer(clamp(dur, 0.05, max_time), false).timeout
	if not is_inside_tree():
		return

## The press comes down, covers the sushi, and only while it is down `on_impact` is called
## (that is where the sushi changes). Then the foot lifts and the sushi springs back up.
func _play_press(press_index: int, on_impact: Callable = Callable(), target = null) -> void:
	var press: AnimatedSprite2D = null
	if press_index >= 0 and press_index < presses.size():
		press = presses[press_index]
	var obj = target if (target != null and is_instance_valid(target)) else current_object
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
	_press_shake()
	if _fx:
		var fx_x = _get_stop_zone_x(press_index)
		_fx.press_impact(Vector2(fx_x, BELT_SURFACE_Y - 2.0), Vector2(fx_x, press.global_position.y - 46.0), 11.0 * press.global_scale.x)
	if on_impact.is_valid():
		on_impact.call()
	await _tree().create_timer(PRESS_HOLD_TIME, false).timeout
	if not is_inside_tree():
		return
	if press.sprite_frames.has_animation("press_up"):
		press.play("press_up")
	if obj and is_instance_valid(obj):
		obj.visible = true
		var tw = create_tween()
		tw.tween_property(obj, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _play_and_wait(press, "press_up", 1.2)
	if obj and is_instance_valid(obj):
		obj.z_index = Z_FOOD

## Every press that comes down shakes the screen a little - the same for all of them, and
## presses landing together do not stack into a big jolt.
const PRESS_SHAKE := 0.17
func _press_shake() -> void:
	if camera and "trauma" in camera:
		camera.trauma = max(camera.trauma, PRESS_SHAKE)
	elif camera and camera.has_method("add_trauma"):
		camera.add_trauma(PRESS_SHAKE)

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
			await _tree().create_timer(total * 0.4, false).timeout
			if not is_inside_tree():
				return
			_press_button_light(press_index)
			await _tree().create_timer(total * 0.6, false).timeout
			if not is_inside_tree():
				return
			if is_instance_valid(fish) and fish.sprite_frames.has_animation("idle"):
				fish.play("idle")
			return
	_press_button_light(press_index)
	await _tree().create_timer(0.3, false).timeout
	if not is_inside_tree():
		return


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
	b.color = Color(1.6, 1.5, 1.1, 1.0)   # over-bright: it really flashes
	var tw = b.create_tween()
	tw.tween_property(b, "color", Color(1.0, 0.3, 0.25, 0.0), 0.5)
	tw.parallel().tween_property(b, "position", PRESS_BUTTON_LOCAL, 0.12).set_delay(0.12)
	_button_glow(presses[press_index].to_global(PRESS_BUTTON_LOCAL))

## The pressed button lights the press around it for a moment (a real light in the dark
## hall) and spits a few pixel sparks - no soft circles.
var _btn_light_tex: Texture2D = null
func _button_glow(at: Vector2) -> void:
	if _btn_light_tex == null:
		var gt = GradientTexture2D.new()
		gt.width = 64
		gt.height = 64
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		var gr = Gradient.new()
		gr.set_color(0, Color(1, 1, 1, 1))
		gr.set_color(1, Color(1, 1, 1, 0))
		gt.gradient = gr
		_btn_light_tex = gt
	var l = PointLight2D.new()
	l.texture = _btn_light_tex
	l.color = Color(1.0, 0.42, 0.25)
	l.energy = 2.2
	l.texture_scale = 0.9
	l.global_position = at
	add_child(l)
	var lt = l.create_tween()
	lt.tween_property(l, "energy", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lt.tween_callback(l.queue_free)
	# pixel sparks: 2x2 squares that hop out on a pixel grid and fade
	for i in range(5):
		var sp = ColorRect.new()
		sp.size = Vector2(2, 2)
		sp.color = [Color(1.0, 0.9, 0.6), Color(1.0, 0.55, 0.3)][i % 2]
		sp.z_as_relative = false
		sp.z_index = 60
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sp)
		var a = -PI * 0.5 + randf_range(-1.3, 1.3)
		var d = randf_range(6.0, 13.0)
		sp.global_position = (at - Vector2.ONE).round()
		var to = (at + Vector2(cos(a), sin(a)) * d).round()
		var st = sp.create_tween()
		st.tween_property(sp, "global_position", to, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		st.tween_property(sp, "global_position", to + Vector2(0, 4), 0.18)
		st.parallel().tween_property(sp, "modulate:a", 0.0, 0.18)
		st.tween_callback(sp.queue_free)

func _button_glow_old(at: Vector2) -> void:
	var g = Node2D.new()
	g.z_as_relative = false
	g.z_index = 60
	g.global_position = at
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	g.material = mat
	add_child(g)
	var state_r := {"t": 0.0}
	var drawer = func():
		var k = clamp(state_r["t"] / 0.45, 0.0, 1.0)
		var a = 1.0 - k
		for i in range(4):
			g.draw_circle(Vector2.ZERO, 6.0 + i * 4.0 + k * 6.0, Color(1.0, 0.45, 0.3, 0.16 * a))
		g.draw_arc(Vector2.ZERO, 4.0 + k * 22.0, 0, TAU, 24, Color(1.0, 0.85, 0.6, 0.8 * a), 1.5)
		g.draw_circle(Vector2.ZERO, 3.0 * a + 1.0, Color(1.0, 0.95, 0.8, a))
	g.draw.connect(drawer)
	var stepper = func(v):
		state_r["t"] = v
		g.queue_redraw()
	var tw = g.create_tween()
	tw.tween_method(stepper, 0.0, 0.45, 0.45)
	tw.tween_callback(g.queue_free)

func _play_player_attack() -> void:
	_player_punch()


## Work punch: the mech fish hits the press button. It does not use the combat attack
## (that one needs stamina and is refused while hurt), so it ALWAYS plays.
## Returns when the fist reaches the button.
func _player_punch() -> void:
	if player == null or player_sprite == null or player_sprite.sprite_frames == null:
		await _tree().create_timer(0.18, false).timeout
		if not is_inside_tree():
			return
		return
	_face_player_to_press()
	var anim = "AttackLeft" if (randi() % 2 == 0) else "AttackRight"
	if not player_sprite.sprite_frames.has_animation(anim):
		await _tree().create_timer(0.18, false).timeout
		if not is_inside_tree():
			return
		return
	if "is_attacking" in player:
		player.set("is_attacking", true)   # keeps the player state machine off the animation
	player_sprite.play(anim)
	var total = _anim_time(player_sprite, anim)
	_finish_player_punch(anim, total)
	await _tree().create_timer(total * 0.4, false).timeout
	if not is_inside_tree():
		return


func _finish_player_punch(anim: String, total: float) -> void:
	await _tree().create_timer(total, false).timeout
	if not is_inside_tree():
		return
	if player and "is_attacking" in player:
		player.set("is_attacking", false)
	if player_sprite and player_sprite.animation == anim and player_sprite.sprite_frames.has_animation("Idle"):
		player_sprite.play("Idle")

## Player's station result: the job is done (or failed) -> the fish punches the button ->
## the press comes down and at the moment of impact the step is done (or the food is ruined).
## A mistake stops production until the guard has dealt with the player.
func _player_press_result(success: bool, punish: bool = true) -> void:
	var it = _player_item
	_player_item = null
	var st = player_station
	if state == State.MINIGAME:
		state = State.WORKING
	if it == null or not is_instance_valid(it["node"]):
		player_job_finished.emit()
		return
	if not (current_shift == 1 and _pre_accident_lock):
		if success:
			_register_success(_last_quality)
		else:
			_register_fail()
	_last_quality = 0.5
	if success and not (current_shift == 1 and _pre_accident_lock):
		_tut_mark("st_%d" % st)
		_mark_station_worked(st)
		if _tut_stage == "first_job":
			_tut_after_first_job()
	if _is_player_in_zone():
		await _player_punch()
	else:
		await _tree().create_timer(0.18, false).timeout
		if not is_inside_tree():
			return
	_press_button_light(st)
	var node = it["node"]
	if success:
		await _play_press(st, func(): _advance_item(it), node)
	else:
		_halt += 1
		await _play_press(st, func(): _break_item(it, st == STATION_PACK, false), node)
		if punish and state != State.DEAD and state != State.SHIFT_END:
			await _guard_hit_player()
		_halt = max(0, _halt - 1)
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
	delta *= _mg_pace()
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
			if mg_ring_r < RING_TARGET - RING_TOL - 5.0:
				_on_minigame_edge_fail()
				return
		MG.CUT:
			mg_knife += mg_speed * delta
			# passed a mark without cutting it
			if mg_hits < mg_marks.size() and mg_knife > mg_marks[mg_hits] + CUT_TOL + 0.02:
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
	if _mg_forgive:
		_mg_forgive_retry()
		return
	await _player_press_result(false)

## A forgiving job (tutorial / new station) that went wrong: nothing is counted, the same job
## simply starts again.
func _mg_forgive_retry() -> void:
	minigame_active = false
	hint_label.visible = false
	_float_text("МИМО! ЕЩЁ РАЗ", Color(1.0, 0.75, 0.4))
	UISounds.play_switch_off()
	await _tree().create_timer(0.75, false).timeout
	if not is_inside_tree():
		return
	if state == State.DEAD or state == State.SHIFT_END or _player_item == null:
		player_job_finished.emit()
		return
	_start_minigame(_mg_station, true)

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
				mg_ring_speed *= 1.06
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
	_last_quality = _mg_quality() if hit else 0.0
	var missed = randf() * 100.0 < _get_miss_chance() and not _mg_forgive
	if _mg_forgive and not hit:
		_flash_minigame(false)
		_mg_forgive_retry()
		return
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
		await _tree().create_timer(0.5).timeout
		if not is_inside_tree():
			return
		_mg_canvas.position = p0
		return
	var original_pos = minigame_panel.position
	var tween = create_tween()
	tween.set_loops(4)
	tween.tween_property(minigame_panel, "position:x", original_pos.x + 8, 0.04)
	tween.tween_property(minigame_panel, "position:x", original_pos.x - 8, 0.04)
	tween.tween_property(minigame_panel, "position:x", original_pos.x, 0.04)
	await _tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	minigame_panel.position = original_pos

var _guard_hits_queued: int = 0
var _guard_extra_hit_pending: bool = false

func _guard_hit_player() -> void:
	if player == null or guard_sprite == null:
		return
	if guard_changing:
		return
	_guard_hits_queued += 1
	await _guard_wait_free()
	_guard_hits_queued = max(0, _guard_hits_queued - 1)
	_guard_busy = true
	var _orig_pos = guard_sprite.position
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
	await _tree().create_timer(0.15).timeout
	if not is_inside_tree():
		return
	UISounds.play_hit()
	var was_in_zone = _is_player_in_zone()
	if player.has_method("take_damage"):
		player.take_damage(1, guard_sprite)   # knocks the fish back a little + small shake
	if was_in_zone and state != State.SHIFT_END:
		_keep_in_zone_after_hit()
	await _tree().create_timer(0.35, false).timeout
	if not is_inside_tree():
		return
	# another hit is coming (the extra one after a bad check): he stays right here
	if not guard_changing and _guard_hits_queued == 0 and not _guard_extra_hit_pending:
		await _guard_walk_to(_guard_home())
		guard_sprite.scale.x = orig_flip if not _inspection_active else abs(guard_sprite.scale.x)
	if guard_sprite.sprite_frames.has_animation("idle"):
		guard_sprite.play("idle")
	_guard_busy = false
	_update_stress_from_hp()
	if player.has_method("get_hp"):
		if player.get_hp() <= 0:
			player.die()

## The knock back of a hit must not throw the fish out of its work zone (the next job would
## fail by itself): if it lands outside, it slides back to the edge of the zone.
func _keep_in_zone_after_hit() -> void:
	await _tree().create_timer(0.35, false).timeout
	if not is_inside_tree() or player == null or state == State.DEAD:
		return
	if _is_player_in_zone():
		return
	var lim = PLAYER_ZONE_SIZE.x / 2.0 - 8.0
	var tx = clamp(player.global_position.x, player_zone_center.x - lim, player_zone_center.x + lim)
	var tw = create_tween()
	tw.tween_property(player, "global_position:x", tx, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Guard hits are queued: one at a time, so two tweens never fight over his position.
func _guard_wait_free() -> void:
	var waited := 0.0
	while (_guard_busy or guard_changing) and waited < 15.0:
		await _tree().create_timer(0.1, false).timeout
		if not is_inside_tree():
			return
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
	var _orig_pos = guard_sprite.position
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
	await _tree().create_timer(0.15).timeout
	if not is_inside_tree():
		return
	UISounds.play_hit()
	if fish is AnimatedSprite2D:
		# a small knock back from the guard, then the fish steps back to its press
		var home = fish.position
		var kdir = 1.0 if fish.global_position.x >= guard_sprite.global_position.x else -1.0
		var kt = create_tween()
		kt.tween_property(fish, "position", home + Vector2(9.0 * kdir, -4.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		kt.tween_property(fish, "position", home + Vector2(11.0 * kdir, 0.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		kt.tween_property(fish, "position", home, 0.35).set_delay(0.25)
		var tw = create_tween()
		tw.tween_property(fish, "modulate", Color(1, 0.4, 0.4), 0.1)
		tw.tween_property(fish, "modulate", Color(1, 1, 1, 1), 0.25)
		if fish.sprite_frames and fish.sprite_frames.has_animation("hit"):
			await _play_and_wait(fish, "hit", 1.0)
			if is_instance_valid(fish) and fish.sprite_frames.has_animation("idle"):
				fish.play("idle")
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.1)
	await _tree().create_timer(0.35, false).timeout
	if not is_inside_tree():
		return
	if not guard_changing:
		await _guard_walk_to(_guard_home())
		guard_sprite.scale.x = orig_flip if not _inspection_active else abs(guard_sprite.scale.x)
	if guard_sprite.sprite_frames.has_animation("idle"):
		guard_sprite.play("idle")
	_guard_busy = false

## The shift bar fills strictly in order, whatever box was finished: green = the box went
## through, red = our fish failed it (the accident counts too), grey = another fish failed it.
func _push_result(kind: int) -> void:
	var index = _box_fill
	_box_fill += 1
	if index < progress_bar.get_child_count():
		var cell = progress_bar.get_child(index) as ColorRect
		if cell:
			cell.color = COLOR_GREEN if kind == 1 else (COLOR_RED if kind == 2 else Color(0.45, 0.45, 0.45))
	if index < _box_states.size():
		_box_states[index] = kind
	if _hud_panel:
		_hud_panel.queue_redraw()

func _mark_progress(_index: int, correct: bool) -> void:
	_push_result(1 if correct else 2)

func _mark_skipped(_index: int) -> void:
	_push_result(3)

## "Работник месяца": every box of the shift is green or grey, not a single red one.
func _is_progress_bar_perfect() -> bool:
	if _box_states.is_empty():
		return false
	for st in _box_states:
		if st != 1 and st != 3:
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
	if _laser == null or not is_instance_valid(_laser):
		_laser_on()
		await _tree().create_timer(0.35).timeout
		if not is_inside_tree():
			return
	if sniper_sprite and sniper_sprite.sprite_frames and sniper_sprite.sprite_frames.has_animation("fire"):
		sniper_sprite.play("fire")
	var from = _sniper_muzzle()
	var to = (player.global_position + Vector2(0, -22)) if player else from + Vector2(-400, 300)
	_laser_off()
	var fx = Node2D.new()
	fx.z_as_relative = false
	fx.z_index = 130
	add_child(fx)
	# muzzle flash: a white-hot star with an orange halo
	var flash = Polygon2D.new()
	var star = PackedVector2Array()
	for k in range(10):
		star.append(Vector2.from_angle(k * TAU / 10.0) * (11.0 if k % 2 == 0 else 4.0))
	flash.polygon = star
	flash.color = Color(1.0, 0.97, 0.8)
	flash.position = from
	fx.add_child(flash)
	var halo = Polygon2D.new()
	var hp = PackedVector2Array()
	for k in range(16):
		hp.append(Vector2.from_angle(k * TAU / 16.0) * 18.0)
	halo.polygon = hp
	halo.color = Color(1.0, 0.6, 0.2, 0.45)
	halo.position = from
	fx.add_child(halo)
	# the tracer: a glowing orange core with a white-hot centre, from the roof to the fish
	var glow = Line2D.new()
	glow.width = 7.0
	glow.default_color = Color(1.0, 0.55, 0.15, 0.4)
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	fx.add_child(glow)
	var core = Line2D.new()
	core.width = 2.0
	core.default_color = Color(1.0, 0.98, 0.85)
	fx.add_child(core)
	UISounds.play_hit()
	var t := 0.0
	var fly = clamp(from.distance_to(to) / 2600.0, 0.08, 0.2)
	while t < fly:
		var k = t / fly
		var head = from.lerp(to, k)
		var tail = from.lerp(to, max(0.0, k - 0.45))
		glow.points = PackedVector2Array([tail, head])
		core.points = PackedVector2Array([from.lerp(to, max(0.0, k - 0.25)), head])
		flash.scale = Vector2.ONE * (1.0 + k)
		flash.modulate.a = 1.0 - k
		await _tree().process_frame
		if not is_inside_tree():
			return
		t += get_process_delta_time()
	glow.points = PackedVector2Array([from, to])
	core.points = PackedVector2Array([from.lerp(to, 0.6), to])
	flash.visible = false
	# impact: hit-stop, a white frame, sparks and a shock ring on the fish
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.75)
	_spawn_sparks(to, 22)
	var ring = Line2D.new()
	ring.width = 2.0
	ring.default_color = Color(1.0, 0.9, 0.6, 0.9)
	ring.closed = true
	var rp = PackedVector2Array()
	for k in range(20):
		rp.append(Vector2.from_angle(k * TAU / 20.0) * 6.0)
	ring.points = rp
	ring.position = to
	fx.add_child(ring)
	var layer = CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var white = ColorRect.new()
	white.set_anchors_preset(Control.PRESET_FULL_RECT)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	white.color = Color(1, 0.95, 0.9, 0.55)
	layer.add_child(white)
	Engine.time_scale = 0.05
	await _tree().create_timer(0.07, true, false, true).timeout
	Engine.time_scale = 1.0
	if not is_inside_tree():
		return
	var tw = create_tween().set_parallel(true)
	tw.tween_property(white, "color:a", 0.0, 0.25)
	tw.tween_property(ring, "scale", Vector2(5, 5), 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, 0.3)
	tw.tween_property(glow, "modulate:a", 0.0, 0.35)
	tw.tween_property(core, "modulate:a", 0.0, 0.2)
	tw.tween_property(halo, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(func():
		fx.queue_free()
		layer.queue_free())
	if player and player.has_method("knockback_from"):
		player.knockback_from(from, player.KNOCK_DEATH)
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
	_halt = 0
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
	await _tree().create_timer(2.5).timeout
	if not is_inside_tree():
		return
	_shift_fade_lock = true
	if fade_rect:
		fade_rect.visible = true
		fade_rect.color = Color(0, 0, 0, 0)
		var tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
	await _tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	_start_new_shift()
	# nobody moves before the screen is clear again
	if player and player.has_method("set_movement_blocked"):
		player.set_movement_blocked(true)
	if fade_rect:
		var tween2 = create_tween()
		tween2.tween_property(fade_rect, "color:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween2.finished
		fade_rect.visible = false
	if not is_inside_tree():
		return
	_shift_fade_lock = false
	if player and player.has_method("set_movement_blocked") and state != State.INSPECT and current_shift >= 2:
		player.set_movement_blocked(false)

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
	_box_fill = 0
	action_strike_count = 0
	action_move_timer = 0.0
	follow_strike_timer = 0.0
	_strike_forgive = 0.0
	_halt = 0
	_cycle_avg = 3.0
	# this shift's clock speed comes from the pace of the previous one (fixed for the shift)
	if _pace_n >= 6:
		_shift_pace = clamp(_pace_sum / float(_pace_n) * 1.05, CLOCK_PACE_MIN, CLOCK_PACE_MAX)
	_pace_sum = 0.0
	_pace_n = 0
	_clock_v = 0.0
	_shift_elapsed = 0.0
	_hold_after_error = false
	_cycle_game_t = 0.0
	_stress_relief = 0
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
			_unlock_player_after_accident()
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
	# the old bottom-left key hints are replaced by the action strip under the shift panel
	bind_hint_i.visible = false
	bind_hint_j.visible = false
	if current_shift >= 2:
		_set_hud_visible(true)
		_show_gui()
		_refresh_bind_hints()
	_update_shift_bars()
	_update_stress_from_hp()
	_update_escape_hint()
	_viol_reset()
	state = State.WORKING
	_save_shift_state()
	_spawn_next_object()

## Every guard and every sniper change has been written down.
func _schedule_known() -> bool:
	return guard_shifts_found.size() >= GUARD_SHIFTS.size() and sniper_shifts_found.size() >= SNIPER_SHIFTS.size()

func _check_escape_info_ready() -> void:
	if escape_info_shift == -1 and _schedule_known():
		escape_info_shift = current_shift

## The escape plan as a banner at the top: a dark steel plate with hazard ends, a small
## "ПЛАН ПОБЕГА" tag, the main line big, the second one under it; it drops in and its edge
## glows slowly.
var _esc_banner: Control = null
var _esc_lines: Array = ["", ""]

func _escape_banner(main: String, sub: String) -> void:
	escape_hint.visible = false
	var fresh = _esc_banner == null
	if fresh:
		_esc_banner = Control.new()
		_esc_banner.name = "EscapeBanner"
		_esc_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_esc_banner.draw.connect(_draw_escape_banner)
		$UI.add_child(_esc_banner)
		var f = _bubble_font()
		for i in range(3):
			var l = Label.new()
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if f:
				l.add_theme_font_override("font", f)
			l.add_theme_font_size_override("font_size", [10, 18, 12][i])
			l.add_theme_color_override("font_color", [HUD_C_ORANGE, Color(1.0, 0.93, 0.85), Color(0.95, 0.45, 0.4)][i])
			l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
			l.add_theme_constant_override("outline_size", 4)
			_esc_banner.add_child(l)
	if _esc_lines == [main, sub] and _esc_banner.visible:
		return
	_esc_lines = [main, sub]
	var labels = _esc_banner.get_children()
	labels[0].text = "ПЛАН ПОБЕГА"
	labels[1].text = main
	labels[2].text = sub
	var w = 460.0
	var bf = _bubble_font()
	if bf:
		for i in range(3):
			var tw_ = bf.get_string_size(labels[i].text, HORIZONTAL_ALIGNMENT_LEFT, -1, [10, 18, 12][i]).x
			w = max(w, ceil(tw_) + 76.0)
	_esc_banner.size = Vector2(w, 66)
	for i in range(3):
		labels[i].size = Vector2(w - 40, 20)
		labels[i].position = Vector2(20, [5, 18, 42][i])
	var vp = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1152, 648)
	var x = round((vp.x - w) * 0.5)
	_esc_banner.visible = true
	_esc_banner.position = Vector2(x, -70)
	_esc_banner.modulate.a = 0.0
	var tw = _esc_banner.create_tween().set_parallel(true)
	tw.tween_property(_esc_banner, "position:y", 12.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_esc_banner, "modulate:a", 1.0, 0.25)
	UISounds.play_switch_on()

func _draw_escape_banner() -> void:
	var c = _esc_banner
	var sz = c.size
	var t = Time.get_ticks_msec() / 1000.0
	var glow = 0.5 + 0.5 * sin(t * 2.2)
	c.draw_rect(Rect2(Vector2(3, 4), sz), Color(0, 0, 0, 0.45))
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color.BLACK)
	c.draw_rect(Rect2(2, 2, sz.x - 4, sz.y - 4), HUD_C_EDGE)
	c.draw_rect(Rect2(3, 2, sz.x - 6, 2), HUD_C_EDGE_HI)
	c.draw_rect(Rect2(5, 5, sz.x - 10, sz.y - 10), HUD_C_BG)
	# hazard stripes on both ends
	for side in [0, 1]:
		var x0 = 5.0 if side == 0 else sz.x - 17.0
		for y in range(5, int(sz.y) - 5, 6):
			c.draw_rect(Rect2(x0, y, 12, 3), HUD_C_ORANGE if y % 12 < 6 else Color8(30, 24, 16))
	# glowing frame
	c.draw_rect(Rect2(Vector2(1, 1), sz - Vector2(2, 2)), Color(HUD_C_ORANGE, 0.25 + 0.35 * glow), false, 2.0)
	# a thin divider under the tag
	c.draw_rect(Rect2(sz.x * 0.5 - 60, 17, 120, 1), Color(HUD_C_ORANGE, 0.5))

func _update_escape_hint() -> void:
	if _esc_banner:
		_esc_banner.queue_redraw()
	if not _schedule_known():
		escape_hint.visible = false
		if _esc_banner:
			_esc_banner.visible = false
		return
	if escape_info_shift == current_shift:
		_escape_banner("ДОЖДАТЬСЯ СМЕНЫ НА УПАКОВКЕ", "ПОБЕГ В ОКНО 13:00 - 13:15")
		return
	if elevator_inspected:
		_escape_banner("13:00 - 13:15", "ЕДИНСТВЕННОЕ ВРЕМЯ ДЛЯ ПОБЕГА ЧЕРЕЗ ЛИФТ")
	else:
		_escape_banner("13:00 - 13:15", "ЕДИНСТВЕННОЕ ВРЕМЯ ДЛЯ ПОБЕГА")

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
		_zoom_camera(Vector2(1.5, 1.5), 0.5)
	if inspect_vignette:
		inspect_vignette.visible = true
	_set_slowmo(true)

var _cam_zoom_tw: Tween = null

func _zoom_camera(z: Vector2, t: float) -> void:
	if camera == null:
		return
	if _cam_zoom_tw and _cam_zoom_tw.is_valid():
		_cam_zoom_tw.kill()
	_cam_zoom_tw = create_tween().set_ignore_time_scale(true)
	_cam_zoom_tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_cam_zoom_tw.tween_property(camera, "zoom", z, t)

func _exit_inspect(forced: bool = false) -> void:
	if state != State.INSPECT:
		return
	for fr in _frame_outlines.values():
		if is_instance_valid(fr):
			fr.visible = false
	if forced:
		_inspect_kick_fx()
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
		_zoom_camera(inspect_camera_original_zoom, 0.3)
		if player and camera.has_method("smooth_to"):
			camera.smooth_to(player.global_position, 0.2)
		elif player:
			camera.global_position = player.global_position
	if inspect_vignette:
		inspect_vignette.visible = false
	_set_slowmo(false, 0.09 if forced else 0.25)

## ---------------------------------------------------------------- inspect slow motion
## The world runs at half speed while the fish looks around: colours drain, the edges get a
## colour fringe and a cold tint, the sound drops lower. Everything snaps back on leaving.
const SLOWMO_SCALE: float = 0.25
var _slowmo_on: bool = false
var _slowmo_tw: Tween = null
var _post_base: Dictionary = {}

func _set_slowmo(on: bool, out_time: float = 0.25) -> void:
	if on == _slowmo_on:
		return
	_slowmo_on = on
	if _slowmo_tw and _slowmo_tw.is_valid():
		_slowmo_tw.kill()
	var post = get_node_or_null("PostFX") as ColorRect
	var pm: ShaderMaterial = post.material as ShaderMaterial if post else null
	if pm and _post_base.is_empty():
		for k in ["saturation", "aberration", "vignette_strength", "grade_amount"]:
			_post_base[k] = pm.get_shader_parameter(k)
			if _post_base[k] == null:
				_post_base[k] = {"saturation": 0.92, "aberration": 0.0016, "vignette_strength": 0.55, "grade_amount": 0.55}[k]
	_slowmo_tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	_slowmo_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var d = 0.35 if on else out_time
	_slowmo_tw.tween_property(Engine, "time_scale", SLOWMO_SCALE if on else 1.0, d)
	_slowmo_tw.tween_property(AudioServer, "playback_speed_scale", 0.6 if on else 1.0, d)
	if pm:
		var target = {
			"saturation": 0.6 if on else _post_base["saturation"],
			"aberration": 0.0065 if on else _post_base["aberration"],
			"vignette_strength": 0.8 if on else _post_base["vignette_strength"],
			"grade_amount": 0.85 if on else _post_base["grade_amount"],
		}
		for k in target.keys():
			var from = pm.get_shader_parameter(k)
			if from == null:
				from = _post_base[k]
			_slowmo_tw.tween_method(_set_post_param.bind(pm, k), from, target[k], d)
	if on:
		_slowmo_whoosh()


func _set_post_param(v: float, pm: ShaderMaterial, k: String) -> void:
	pm.set_shader_parameter(k, v)

## A thin flash ring at the start of slow motion.
func _slowmo_whoosh() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var r = ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.color = Color(0.75, 0.88, 1.0, 0.22)
	layer.add_child(r)
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(r, "color:a", 0.0, 0.35)
	tw.tween_callback(layer.queue_free)


## Work came while looking around: the slow motion is ripped away - a hard snap back to full
## speed, a jolt, a white-hot flash with red edges, a squeezed zoom and "ЗА РАБОТУ!".
func _inspect_kick_fx() -> void:
	UISounds.play_hit()
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.32)
	if camera:
		camera.zoom = inspect_camera_original_zoom * 1.12   # the exit tween then eases it back
	var layer = CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1.0, 0.95, 0.85, 0.55)
	layer.add_child(flash)
	var edge = ColorRect.new()
	edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh = Shader.new()
	sh.code = """shader_type canvas_item;
uniform float a = 1.0;
void fragment() {
	vec2 cc = UV - 0.5;
	float v = smoothstep(0.3, 0.75, length(cc * vec2(1.25, 1.0)));
	COLOR = vec4(0.9, 0.12, 0.08, v * 0.6 * a);
}
"""
	var em = ShaderMaterial.new()
	em.shader = sh
	edge.material = em
	layer.add_child(edge)
	var lbl = Label.new()
	lbl.text = "ЗА РАБОТУ!"
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f = _bubble_font()
	if f:
		lbl.add_theme_font_override("font", f)
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.02, 0.0))
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(500, 50)
	lbl.position = Vector2(326, 120)
	lbl.pivot_offset = lbl.size * 0.5
	lbl.scale = Vector2(1.8, 1.8)
	layer.add_child(lbl)
	var tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(flash, "color:a", 0.0, 0.22)
	tw.tween_method(func(v): em.set_shader_parameter("a", v), 1.0, 0.0, 0.6)
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.3).set_delay(0.55)
	tw.chain().tween_callback(layer.queue_free)


## Never leave the game slowed down (death, pause, leaving the level).
func _reset_slowmo_now() -> void:
	_slowmo_on = false
	if _slowmo_tw and _slowmo_tw.is_valid():
		_slowmo_tw.kill()
	if _journal_slow_tw and _journal_slow_tw.is_valid():
		_journal_slow_tw.kill()
	Engine.time_scale = 1.0
	AudioServer.playback_speed_scale = 1.0
	var post = get_node_or_null("PostFX") as ColorRect
	if post and post.material is ShaderMaterial and not _post_base.is_empty():
		for k in _post_base.keys():
			post.material.set_shader_parameter(k, _post_base[k])

## Click in inspect mode: only what is highlighted right now can be looked at, and only
## where it really is - the pixels of its sprite (overlapping boxes used to let you inspect
## the elevator through the guard, the belt through a press, things already noted...).
var _hit_img_cache: Dictionary = {}

func _tex_alpha(tex: Texture2D, px: Vector2) -> float:
	if tex == null:
		return 0.0
	var img: Image = _hit_img_cache.get(tex, null)
	if img == null:
		img = tex.get_image()
		if img == null:
			return 1.0
		if img.is_compressed():
			img.decompress()
		_hit_img_cache[tex] = img
	var ix = int(px.x)
	var iy = int(px.y)
	if ix < 0 or iy < 0 or ix >= img.get_width() or iy >= img.get_height():
		return 0.0
	return img.get_pixel(ix, iy).a

## -1 = not hit, else a score (bigger = in front / smaller target).
func _node_hit(n: CanvasItem, wp: Vector2) -> float:
	if n == null or not is_instance_valid(n) or not n.is_visible_in_tree():
		return -1.0
	var z = float(n.z_index) if n.z_as_relative == false else float(n.z_index)
	if n is Sprite2D:
		var s2: Sprite2D = n
		var lp = s2.to_local(wp)
		if not s2.get_rect().has_point(lp):
			return -1.0
		return z if s2.is_pixel_opaque(lp) else -1.0
	if n is AnimatedSprite2D:
		var a2: AnimatedSprite2D = n
		if a2.sprite_frames == null or not a2.sprite_frames.has_animation(a2.animation):
			return -1.0
		var tex = a2.sprite_frames.get_frame_texture(a2.animation, a2.frame)
		if tex == null:
			return -1.0
		var sz = tex.get_size()
		var lp = a2.to_local(wp) - a2.offset
		if a2.centered:
			lp += sz * 0.5
		if a2.flip_h:
			lp.x = sz.x - lp.x
		if a2.flip_v:
			lp.y = sz.y - lp.y
		if lp.x < 0 or lp.y < 0 or lp.x >= sz.x or lp.y >= sz.y:
			return -1.0
		# a couple of pixels of slack around thin parts
		for o in [Vector2.ZERO, Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			if _tex_alpha(tex, lp + o) > 0.3:
				return z
		return -1.0
	if n is Control:
		return z if (n as Control).get_global_rect().has_point(wp) else -1.0
	return -1.0

func _process_inspect_click(_mouse_pos: Vector2) -> void:
	var best_area = _inspect_pick(get_global_mouse_position())
	if best_area == null:
		return
	_inspect_area(best_area)

## The highlighted target under this world point (null = nothing).
func _inspect_pick(world_pos: Vector2) -> Area2D:
	var best_area: Area2D = null
	var best_score := -INF
	for area in inspect_targets:
		if not is_instance_valid(area):
			continue
		if not _is_inspect_target_visible(area):
			continue
		var d0 = inspect_target_data.get(area, {})
		var nodes = _area_outline_nodes(area)
		var score := -INF
		if nodes.is_empty():
			# no sprite (the empty post): its box
			var sz0 = d0.get("size", Vector2(80, 80))
			if Rect2(d0.get("pos", Vector2.ZERO) - sz0 / 2.0, sz0).has_point(world_pos):
				score = 100.0
		else:
			for n in nodes:
				var h = _node_hit(n, world_pos)
				if h >= 0.0:
					score = max(score, h)
			# big static things (doors, clock, belt) also count by their box - but anything
			# with real pixels in front of them wins
			var sid: String = d0.get("id", "")
			if score == -INF and sid in ["elevator", "maintenance", "clock", "conveyor"]:
				var sz1 = d0.get("size", Vector2(80, 80))
				if Rect2(d0.get("pos", Vector2.ZERO) - sz1 / 2.0, sz1).has_point(world_pos):
					score = -100.0
		if score == -INF:
			continue
		# shift notes beat everything, then whatever is drawn in front
		if d0.get("special_type", "") != "":
			score += 1000.0
		if score > best_score:
			best_score = score
			best_area = area
	return best_area

func _inspect_area(area: Area2D) -> void:
	if true:
		var data = inspect_target_data.get(area, {})
		if true:
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
	inspect_text_label.fit_content = true
	inspect_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspect_text_label.text = "[b]" + title + "[/b]\n" + phrase.replace("-", "-\u2060")
	# the panel is as tall as the text needs (it grows upward from the bottom edge)
	var inner_w = (inspect_text_panel.offset_right - inspect_text_panel.offset_left) - 20.0
	inspect_text_label.size = Vector2(inner_w, 0)
	var h = max(54.0, inspect_text_label.get_content_height() + 20.0)
	inspect_text_panel.offset_bottom = 618.0
	inspect_text_panel.offset_top = 618.0 - h
	if inspect_journal_notice:
		inspect_journal_notice.offset_top = inspect_text_panel.offset_top - 28.0
		inspect_journal_notice.offset_bottom = inspect_text_panel.offset_top - 3.0

func _add_journal_note(id: String, text: String) -> void:
	if not journal_notes.has(id):
		journal_notes.append(id)
		journal_notes_full[id] = text
		if inspect_journal_notice:
			inspect_journal_notice.text = "Открылась новая пометка в журнале"
			inspect_journal_notice.visible = true
			inspect_notice_timer = 3.0
		_check_scout_achievement()

var _all_target_ids: Array = []

## Everything = every object, every fish, every guard change and every sniper change.
func _everything_inspected() -> bool:
	for id in _all_target_ids:
		if not journal_notes.has(id):
			return false
	return not _all_target_ids.is_empty()

## All the objects (the shift changes are not objects).
func _all_objects_inspected() -> bool:
	for id in _all_target_ids:
		if id.begins_with("guard_shift") or id.begins_with("sniper_shift"):
			continue
		if not journal_notes.has(id):
			return false
	return not _all_target_ids.is_empty()

func _check_scout_achievement() -> void:
	if _everything_inspected():
		if has_node("/root/Achievements"):
			var was = Achievements.scout_unlocked
			Achievements.unlock_scout()
			if not was:
				_show_scout_achievement()

## ---------------------------------------------------------------- journal (notepad)
## The journal is the old notepad sheet: a handwritten-looking page with sections, the shift
## changes as tick boxes and the escape conclusion in red ink once everything is known.
const NOTEPAD_TEX := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryNotepadTextures/ActPrologue_LevelFactory_NotePadWindow_Texture.png"
const INK := Color(0.2, 0.13, 0.08)
const INK_SOFT := Color(0.36, 0.27, 0.18)
const INK_RED := Color(0.62, 0.12, 0.08)
const INK_BLUE := Color(0.12, 0.22, 0.5)
const JOURNAL_SIZE := Vector2(760, 570)
var _journal_built: bool = false
var _journal_paper: TextureRect = null
var _journal_title: Label = null
var _journal_hint: Label = null
var _journal_tw: Tween = null

func _build_journal() -> void:
	if _journal_built:
		return
	_journal_built = true
	var bg = journal_panel.get_node_or_null("BG") as ColorRect
	journal_panel.position = ((Vector2(1152, 648) - JOURNAL_SIZE) * 0.5).round()
	journal_panel.size = JOURNAL_SIZE
	journal_panel.pivot_offset = JOURNAL_SIZE * 0.5
	# darken the game behind the sheet
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.position = -journal_panel.position - Vector2(40, 40)
	dim.size = Vector2(1152, 648) + Vector2(80, 80)
	dim.show_behind_parent = true
	journal_panel.add_child(dim)
	journal_panel.move_child(dim, 0)
	_journal_paper = TextureRect.new()
	_journal_paper.texture = load(NOTEPAD_TEX)
	_journal_paper.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_journal_paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_journal_paper.stretch_mode = TextureRect.STRETCH_SCALE
	_journal_paper.size = JOURNAL_SIZE
	_journal_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journal_panel.add_child(_journal_paper)
	journal_panel.move_child(_journal_paper, 1)
	if bg:
		bg.color = Color(0, 0, 0, 0)
		bg.size = JOURNAL_SIZE
		journal_panel.move_child(bg, journal_panel.get_child_count() - 1)
		var title = bg.get_node_or_null("Title") as Label
		if title:
			title.visible = false
		var scroll = bg.get_node_or_null("Scroll") as ScrollContainer
		if scroll:
			scroll.position = Vector2(84, 112)
			scroll.size = Vector2(JOURNAL_SIZE.x - 168, 330)
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		journal_list.custom_minimum_size = Vector2(JOURNAL_SIZE.x - 184, 0)
		journal_list.add_theme_constant_override("separation", 6)
		var close = bg.get_node_or_null("CloseButton") as Button
		if close:
			close.text = "НАЗАД"
			close.flat = true
			close.focus_mode = Control.FOCUS_NONE
			close.position = Vector2(JOURNAL_SIZE.x * 0.5 - 70, 452)
			close.size = Vector2(140, 30)
			_journal_style(close, 16, INK_RED)
			close.add_theme_color_override("font_hover_color", Color(0.85, 0.2, 0.1))
			close.add_theme_color_override("font_pressed_color", INK)
		_journal_title = _journal_label("ЖУРНАЛ НАБЛЮДЕНИЙ", 24, INK)
		_journal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_journal_title.position = Vector2(60, 50)
		_journal_title.size = Vector2(JOURNAL_SIZE.x - 120, 30)
		bg.add_child(_journal_title)
		var rule = ColorRect.new()
		rule.color = Color(INK_SOFT, 0.6)
		rule.position = Vector2(110, 90)
		rule.size = Vector2(JOURNAL_SIZE.x - 220, 2)
		bg.add_child(rule)
		_journal_hint = _journal_label("", 12, INK_SOFT)
		_journal_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_journal_hint.position = Vector2(60, 482)
		_journal_hint.size = Vector2(JOURNAL_SIZE.x - 120, 20)
		bg.add_child(_journal_hint)


## The food is about to stop under the player's press (the belt is moving it there now).
func _job_imminent() -> bool:
	if _belt_move_left <= 0.0 or _belt_move_left > FISH_SPACING * 0.6:
		return false
	for it in belt_items:
		if it["slot"] + 1 >= 1 and it["slot"] + 1 <= BELT_PACK_SLOT and SLOT_STATION.get(it["slot"] + 1, -1) == player_station and not it["broken"] and not it["done"]:
			return true
	return false

func _journal_style(c: Control, size: int, col: Color) -> void:
	var f = _bubble_font()
	if f:
		c.add_theme_font_override("font", f)
	c.add_theme_font_size_override("font_size", size)
	c.add_theme_color_override("font_color", col)
	c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _journal_label(text: String, size: int, col: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_journal_style(l, size, col)
	return l


## Work came while the journal is open: the same "ЗА РАБОТУ!" jolt as in inspect mode.
func _kick_out_of_journal() -> void:
	_on_journal_close()
	_inspect_kick_fx()
	if camera:
		_zoom_camera(inspect_camera_original_zoom, 0.3)

func _open_journal() -> void:
	if current_shift < 2:
		return
	# no reading in the middle of a job (or right before one)
	if minigame_active or _inc_active or state == State.MINIGAME or _job_imminent():
		_inspect_kick_fx()
		if camera:
			_zoom_camera(inspect_camera_original_zoom, 0.3)
		return
	_build_journal()
	journal_open = true
	journal_panel.get_parent().move_child(journal_panel, -1)   # over the HUD as well
	journal_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_update_journal_options()
	if _journal_hint:
		_journal_hint.text = _key_name("journal") + " / ESC"
	# the sheet slides up and settles with a little tilt
	if _journal_tw and _journal_tw.is_valid():
		_journal_tw.kill()
	journal_panel.modulate.a = 0.0
	journal_panel.scale = Vector2(0.92, 0.92)
	journal_panel.rotation = -0.035
	_journal_tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	_journal_tw.tween_property(journal_panel, "modulate:a", 1.0, 0.18)
	_journal_tw.tween_property(journal_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_journal_tw.tween_property(journal_panel, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	UISounds.play_click()
	# while the journal is open the game almost stands still (x0.125)
	_journal_freeze = true
	_set_journal_slow(true)

var _journal_freeze: bool = false

const JOURNAL_SCALE: float = 0.125
var _journal_slow_tw: Tween = null

## Smoothly slows the game down to x0.125 under the open journal (and back).
func _set_journal_slow(on: bool) -> void:
	if _slowmo_tw and _slowmo_tw.is_valid():
		_slowmo_tw.kill()
	if _journal_slow_tw and _journal_slow_tw.is_valid():
		_journal_slow_tw.kill()
	var to = JOURNAL_SCALE if on else (SLOWMO_SCALE if (_slowmo_on and state == State.INSPECT) else 1.0)
	_journal_slow_tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	_journal_slow_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_journal_slow_tw.tween_property(Engine, "time_scale", to, 0.25 if on else 0.2)
	_journal_slow_tw.tween_property(AudioServer, "playback_speed_scale", 0.6 if on else (0.6 if to < 1.0 else 1.0), 0.25)

func _on_journal_close() -> void:
	journal_open = false
	if _journal_freeze:
		_journal_freeze = false
		_set_journal_slow(false)
	if _journal_tw and _journal_tw.is_valid():
		_journal_tw.kill()
	_journal_tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	_journal_tw.tween_property(journal_panel, "modulate:a", 0.0, 0.14)
	_journal_tw.tween_property(journal_panel, "scale", Vector2(0.95, 0.95), 0.14)
	_journal_tw.chain().tween_callback(func(): journal_panel.visible = journal_open)
	if state != State.INSPECT:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _update_journal_options() -> void:
	for c in journal_list.get_children():
		c.queue_free()
	# shift changes: tick boxes for every time you can find out
	_journal_header("ПЕРЕСМЕНКИ")
	_journal_ticks("Охрана", GUARD_SHIFTS, guard_shifts_found)
	_journal_ticks("Снайпер", SNIPER_SHIFTS, sniper_shifts_found)
	_journal_header("ОСМОТРЕНО")
	if journal_notes_full.is_empty():
		_journal_entry("Пока ничего. Нажми " + _key_name("inspect") + ", чтобы осмотреться.", INK_SOFT, false)
	else:
		for id in journal_notes_full.keys():
			_journal_entry(journal_notes_full[id], INK, true)
	if _schedule_known():
		_journal_header("ВЫВОД")
		var t = "13:00 - 13:15 — единственное время для побега"
		if elevator_inspected:
			t += " через лифт"
		_journal_entry(t + "!", INK_RED, false, 18)

func _journal_header(text: String) -> void:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	var l = _journal_label(text, 18, INK_RED)
	box.add_child(l)
	var rule = ColorRect.new()
	rule.color = Color(INK_RED, 0.45)
	rule.custom_minimum_size = Vector2(0, 2)
	box.add_child(rule)
	if journal_list.get_child_count() > 0:
		var gap = Control.new()
		gap.custom_minimum_size = Vector2(0, 6)
		journal_list.add_child(gap)
	journal_list.add_child(box)

func _journal_entry(text: String, col: Color, bullet: bool, size: int = 14) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	if bullet:
		var b = _journal_label("•", size, INK_SOFT)
		b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(b)
	var l = _journal_label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(JOURNAL_SIZE.x - 210, 0)
	row.add_child(l)
	if bullet and journal_list.get_child_count() > 0 and journal_list.get_child(journal_list.get_child_count() - 1) is HBoxContainer:
		# a thin dotted line between two notes
		var sep = Control.new()
		sep.custom_minimum_size = Vector2(0, 7)
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sep.draw.connect(func():
			var w = sep.size.x
			var x := 18.0
			while x < w - 10.0:
				sep.draw_rect(Rect2(x, 3, 4, 1), Color(INK_SOFT, 0.45))
				x += 9.0)
		journal_list.add_child(sep)
	journal_list.add_child(row)

func _journal_ticks(who: String, hours: Array, found: Array) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var name_l = _journal_label(who + ":", 14, INK)
	name_l.custom_minimum_size = Vector2(110, 0)
	row.add_child(name_l)
	# the time is only written down once it was noted; the empty boxes just wait
	var sorted_found = found.duplicate()
	sorted_found.sort()
	for i in range(hours.size()):
		var got = i < sorted_found.size()
		var txt = ("[x] " + _hhmm(sorted_found[i])) if got else "[  ] --:--"
		var l = _journal_label(txt, 14, INK_BLUE if got else INK_SOFT)
		row.add_child(l)
	journal_list.add_child(row)

func _hhmm(h: float) -> String:
	return "%02d:%02d" % [int(h), int(round(fmod(h, 1.0) * 60.0))]

func _add_journal_line(text: String, color: Color, font_size: int) -> void:
	_journal_entry(text, color, false, font_size)

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
var _chan_bubbles: Dictionary = {}   # channel -> [node, gen]

func _speech(speaker: Node2D, who: String, who_color: Color, text: String, duration: float, guard_voice: bool, channel: String = "main") -> void:
	# lines only break between whole words: no break after a hyphen either ("ХЕ-ХЕ")
	text = text.replace("-", "-\u2060")
	_bubble_gen += 1
	var gen = _bubble_gen
	if channel == "main":
		if _bubble and is_instance_valid(_bubble):
			_bubble.queue_free()
	else:
		var old = _chan_bubbles.get(channel, [])
		if old.size() > 0 and is_instance_valid(old[0]):
			old[0].queue_free()
	if dialog_panel:
		dialog_panel.visible = false
	if channel == "main":
		is_dialog_active = true
	var font: Font = _bubble_font()
	var box_tex: Texture2D = load(DIALOG_BOX_PATH)
	var pad = Vector2(6, 6)
	var name_h = 0.0   # no names in the bubbles
	# The box is sized by the label itself (same font, same wrapping), so the text can never
	# end up bigger than the box. Short lines get a narrow box, long ones wrap at BUBBLE_MAX_W.
	var max_inner = BUBBLE_MAX_W - pad.x * 2.0
	var inner_w = max_inner
	if font:
		# never narrower than the longest word, so no word is ever cut in two
		var longest := 0.0
		for w in text.split(" ", false):
			longest = max(longest, font.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, BUBBLE_FONT).x)
		max_inner = max(max_inner, ceil(longest) + 6.0)
		var one_line = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BUBBLE_FONT).x + 6.0
		inner_w = clamp(ceil(one_line), 34.0, max_inner)
	var meas = Label.new()
	meas.text = text
	meas.autowrap_mode = TextServer.AUTOWRAP_WORD
	if font:
		meas.add_theme_font_override("font", font)
	meas.add_theme_font_size_override("font_size", BUBBLE_FONT)
	meas.add_theme_constant_override("line_spacing", 1)
	meas.visible = false
	add_child(meas)
	meas.size = Vector2(inner_w, 0)   # only after wrapping + font are set and it is in the tree
	meas.size = Vector2(inner_w, 0)
	var line_count = max(1, meas.get_line_count())
	var text_h = line_count * meas.get_line_height() + (line_count - 1) * 1 + 2
	meas.queue_free()
	var sz = Vector2(inner_w + pad.x * 2.0, text_h + pad.y * 2.0).round()

	var b = Node2D.new()
	b.name = "SpeechBubble"
	b.z_as_relative = false
	b.z_index = 200
	add_child(b)
	if channel == "main":
		_bubble = b
	else:
		_chan_bubbles[channel] = [b, gen]
	var my_chan = channel
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
	# rich text: the type-in effect drops every letter in as it is printed; the whole line is
	# laid out from the start, so words never jump to the next line while typing
	var lbl = RichTextLabel.new()
	var typein = TYPEIN_EFFECT.new()
	lbl.custom_effects = [typein]
	lbl.bbcode_enabled = true
	lbl.scroll_active = false
	lbl.text = "[typein]" + text.replace("[", "[lb]") + "[/typein]"
	lbl.position = pad + Vector2(0, name_h)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	if font:
		lbl.add_theme_font_override("normal_font", font)
	lbl.add_theme_font_size_override("normal_font_size", BUBBLE_FONT)
	lbl.add_theme_color_override("default_color", Color(0.05, 0.05, 0.08))
	lbl.add_theme_constant_override("line_separation", 1)
	lbl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.clip_contents = false
	panel.add_child(lbl)
	# twice: Godot clamps the height to the label's minimum for the *old* width, so the width
	# has to be right before the final size is set
	lbl.size = Vector2(sz.x - pad.x * 2.0, 0)
	lbl.size = sz - pad * 2.0 - Vector2(0, name_h)
	var tag = Label.new()
	tag.text = who
	tag.position = pad + Vector2(0, -1)
	if font:
		tag.add_theme_font_override("font", font)
	tag.add_theme_font_size_override("font_size", BUBBLE_FONT)
	tag.add_theme_color_override("font_color", who_color.darkened(0.45))
	tag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.visible = false
	panel.add_child(tag)

	# pop in
	root.scale = Vector2(0.6, 0.6) * BUBBLE_SCALE
	root.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(root, "scale", Vector2.ONE * BUBBLE_SCALE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(root, "modulate:a", 1.0, 0.12)

	var total = text.length()
	var life = duration + float(total) / BUBBLE_CPS
	var t := 0.0
	var shown := 0
	var shake := 0.0
	while t < life:
		_place_bubble(b, sz, speaker, tail_o, tail_f, t, shake)
		await _tree().process_frame
		if not is_inside_tree():
			return
		if not is_instance_valid(b):
			return
		if my_chan == "main" and gen != _bubble_gen and b != _bubble:
			return
		if _tree().paused:
			continue
		var dt = get_process_delta_time()
		t += dt
		shake = max(0.0, shake - dt)
		var n = min(total, int(t * BUBBLE_CPS))
		if n > shown:
			var ch = text[n - 1]
			if ch != " " and int(n / 2.0) != int(shown / 2.0):
				if guard_voice:
					UISounds.play_mechanic()
				else:
					UISounds.play_scientist()
			if ch == "!":
				shake = 0.25
			shown = n
			typein.grow_to(n)
	var out = create_tween()
	out.tween_property(root, "modulate:a", 0.0, 0.25)
	out.parallel().tween_property(root, "scale", Vector2(0.9, 0.9) * BUBBLE_SCALE, 0.25)
	await out.finished
	if is_instance_valid(b):
		b.queue_free()
	if my_chan == "main":
		if _bubble == b or not is_instance_valid(_bubble):
			_bubble = null
			is_dialog_active = false


## The bubbles get their own copy of the pixel font. The shared one is switched to a fixed
## size (10) by Global for the menus, so it draws bigger than it measures - then no box fits.
var _bubble_font_res: FontFile = null

func _bubble_font() -> Font:
	if _bubble_font_res == null:
		_bubble_font_res = ResourceLoader.load(DIALOG_FONT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
		if _bubble_font_res:
			_bubble_font_res.fixed_size = 0
	return _bubble_font_res

## Keeps the bubble over its speaker, inside the camera view; the tail always points at him.
func _place_bubble(b: Node2D, sz: Vector2, speaker: Node2D, tail_o: Polygon2D, tail_f: Polygon2D, t: float, shake: float) -> void:
	var anchor = Vector2(_get_stop_zone_x(STATION_PACK), 300)
	var feet = anchor + Vector2(0, 40)
	if speaker and is_instance_valid(speaker):
		anchor = speaker.global_position + Vector2(0, -34)
		feet = speaker.global_position + Vector2(0, 26)
	var pos = anchor - Vector2(sz.x * 0.5, sz.y + 12.0)
	var cam = get_viewport().get_camera_2d()
	if cam:
		var half = get_viewport().get_visible_rect().size / cam.zoom / 2.0
		var c = cam.get_screen_center_position()
		var lo = Vector2(c.x - half.x + 6.0, c.y - half.y + 14.0)
		var hi = Vector2(c.x + half.x - sz.x - 6.0, c.y + half.y - sz.y - 14.0)
		pos = pos.clamp(lo, hi)
		# no room above the speaker (the sniper up on the roof): the bubble goes under him
		if pos.y + sz.y > anchor.y + 6.0:
			pos.y = clamp(feet.y + 10.0, lo.y, hi.y)
		# the HUD (shift panel, HP / suit indicators) is drawn over the world: keep out of it
		for r in _ui_avoid_rects():
			if not Rect2(pos, sz).intersects(r):
				continue
			var options: Array = []
			var lx = r.position.x - sz.x - 4.0
			var rx = r.end.x + 4.0
			var by = r.end.y + 4.0
			if lx >= lo.x:
				options.append(Vector2(lx, pos.y))
			if rx <= hi.x:
				options.append(Vector2(rx, pos.y))
			if by <= hi.y:
				options.append(Vector2(pos.x, by))
			var best = pos
			var best_d = INF
			for o in options:
				var d = o.distance_to(pos)
				if d < best_d:
					best_d = d
					best = o
			pos = best
	pos.y += round(sin(t * 2.2) * 1.0)
	if shake > 0.0:
		pos.x += round(sin(t * 80.0) * 2.0)
	b.global_position = pos.round()
	_bubble_tail(pos.round(), sz, anchor, feet, tail_o, tail_f)


## The little tail always points at the speaker: down from the bottom edge when the box is
## above him, up from the top edge when it is under him, from a side when it is beside him.
func _bubble_tail(pos: Vector2, sz: Vector2, anchor: Vector2, feet: Vector2, tail_o: Polygon2D, tail_f: Polygon2D) -> void:
	var la = anchor - pos   # speaker in box coordinates
	var lf = feet - pos
	var base: Vector2
	var dir: Vector2
	if la.y >= sz.y - 2.0:
		base = Vector2(clamp(la.x, 9.0, sz.x - 9.0), sz.y - 2.0)
		dir = Vector2(0, 1)
	elif lf.y <= 2.0:
		base = Vector2(clamp(la.x, 9.0, sz.x - 9.0), 2.0)
		dir = Vector2(0, -1)
	elif la.x < 0.0:
		base = Vector2(2.0, clamp(la.y, 7.0, sz.y - 7.0))
		dir = Vector2(-1, 0)
	else:
		base = Vector2(sz.x - 2.0, clamp(la.y, 7.0, sz.y - 7.0))
		dir = Vector2(1, 0)
	var side = Vector2(-dir.y, dir.x)
	# lean the tip a little toward the speaker
	var lean = clamp((la - base).dot(side) * 0.15, -4.0, 4.0)
	tail_o.polygon = PackedVector2Array([base + side * 6.0, base - side * 6.0, base + dir * 9.0 + side * lean])
	tail_f.polygon = PackedVector2Array([base + side * 4.0 - dir, base - side * 4.0 - dir, base + dir * 6.0 + side * lean * 0.7])


## Screen parts drawn on top of the world, in world coordinates: the shift panel (+ streak
## line) and the fish HUD sprites (hearts / HP bar / stamina / suit indicator).
func _ui_avoid_rects() -> Array:
	var out: Array = []
	var inv = get_viewport().get_canvas_transform().affine_inverse()
	var to_world = func(r: Rect2) -> Rect2:
		return Rect2(inv * r.position, Vector2.ZERO).expand(inv * r.end)
	if _hud_panel and _hud_panel.is_visible_in_tree():
		out.append(to_world.call(_hud_panel.get_global_rect().grow_individual(6, 6, 6, 24)))
	if player_gui and player_gui.visible:
		var cont = player_gui.get_node_or_null("UI_Container") as Control
		if cont and cont.is_visible_in_tree() and cont.modulate.a > 0.05:
			for n in cont.get_children():
				var rr = _sprite_screen_rect(n)
				if rr.size != Vector2.ZERO:
					out.append(to_world.call(rr.grow(6)))
	return out


func _sprite_screen_rect(n: Node) -> Rect2:
	var tex: Texture2D = null
	if n is Sprite2D and n.visible:
		tex = n.texture
	elif n is AnimatedSprite2D and n.visible and n.sprite_frames and n.sprite_frames.has_animation(n.animation):
		tex = n.sprite_frames.get_frame_texture(n.animation, n.frame)
	if tex == null:
		return Rect2()
	var sz = tex.get_size()
	var xf: Transform2D = n.get_global_transform()
	var r = Rect2(xf * (-sz * 0.5), Vector2.ZERO).expand(xf * (sz * 0.5))
	return r

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
		if journal_open:
			Engine.time_scale = JOURNAL_SCALE
			AudioServer.playback_speed_scale = 0.6
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif _slowmo_on:
			Engine.time_scale = SLOWMO_SCALE
			AudioServer.playback_speed_scale = 0.6
			if state == State.INSPECT:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		# the pause menu itself always runs at normal speed
		Engine.time_scale = 1.0
		AudioServer.playback_speed_scale = 1.0
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
	if journal_open:
		Engine.time_scale = JOURNAL_SCALE
		AudioServer.playback_speed_scale = 0.6
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif _slowmo_on:
		Engine.time_scale = SLOWMO_SCALE
		AudioServer.playback_speed_scale = 0.6
		if state == State.INSPECT:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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
		if _inc_active:
			_inc_pressed = true
			get_viewport().set_input_as_handled()
			return
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
	var hour = _current_hour()
	var in_window = hour >= ESCAPE_WINDOW_START and hour <= ESCAPE_WINDOW_END
	if not in_window:
		_show_dialog("ЛИФТ ЗАКРЫТ. НУЖНО ДОЖДАТЬСЯ 13:00.", 2.5)
		return
	if not _schedule_known():
		_show_dialog("Я НЕ ЗНАЮ РАСПИСАНИЯ. НУЖНО БОЛЬШЕ РАЗВЕДКИ.", 2.5)
		return
	if has_node("/root/Achievements"):
		var was = Achievements.freedom_unlocked
		Achievements.unlock_freedom()
		if not was:
			_show_freedom_achievement()
	_show_dialog("ПОБЕГ...", 1.5)
	await _await_elevator_anim("open")
	await _tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	Global.autosave(Global.SCENE_HALLWAY)
	Global.goto_scene(Global.SCENE_HALLWAY)

func _show_worker_of_month_achievement() -> void:
	_show_achievement_banner("Работник месяца")

func _show_scout_achievement() -> void:
	_show_achievement_banner("Разведчик")

func _show_freedom_achievement() -> void:
	_show_achievement_banner("Свобода")

## The popup itself now comes from the Achievements autoload (one pretty style everywhere).
func _show_achievement_banner(_title: String) -> void:
	pass
