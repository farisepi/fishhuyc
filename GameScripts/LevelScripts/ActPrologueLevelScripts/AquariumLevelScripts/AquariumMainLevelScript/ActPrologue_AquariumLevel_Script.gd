extends Node2D

@onready var animationtrack = $AnimationPlayer
@onready var scientistsprite = $npc/Scientist/ScientistSprite
@onready var mechanicsprite = $npc/Mechanic/MechanicSprite
@onready var chatter: ChatterController = $ChatterController
var scientist_boring_timer: Timer
var mechanic_boring_timer: Timer

const BORING_INTERVAL_MIN: float = 15.0
const BORING_INTERVAL_MAX: float = 20.0

func _ready():
	GlobalMusic.play_level_music()
	#animationtrack.play("INTRO")
	chatter.start()
	
	_setup_character_animations()
	

func _schedule_boring(t: Timer) -> void:
	t.start(randf_range(BORING_INTERVAL_MIN, BORING_INTERVAL_MAX))

func _setup_character_animations() -> void:
	if scientistsprite and scientistsprite.sprite_frames:
		scientistsprite.animation_finished.connect(_on_scientist_animation_finished)
		scientist_boring_timer = _make_boring_timer(_on_scientist_boring_timer)
		scientistsprite.play("idle")
		_schedule_boring(scientist_boring_timer)
	
	if mechanicsprite and mechanicsprite.sprite_frames:
		mechanicsprite.animation_finished.connect(_on_mechanic_animation_finished)
		mechanic_boring_timer = _make_boring_timer(_on_mechanic_boring_timer)
		mechanicsprite.play("idle")
		_schedule_boring(mechanic_boring_timer)

func _make_boring_timer(callback: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.timeout.connect(callback)
	add_child(t)
	return t

func _on_scientist_boring_timer() -> void:
	
	#if cutscene_active or not scientistsprite or scientistsprite.animation != "idle":
		#_schedule_boring(scientist_boring_timer)
		#return
	scientistsprite.play("boring")

func _on_scientist_animation_finished() -> void:
	match scientistsprite.animation:
		"boring":
			scientistsprite.play("idle")
			_schedule_boring(scientist_boring_timer)
		"angry":
			
			scientistsprite.play("idle")
			
func _on_mechanic_boring_timer() -> void:
	
	if not mechanicsprite or mechanicsprite.animation != "idle":
		_schedule_boring(mechanic_boring_timer)
		return
	mechanicsprite.play("boring")

func _on_mechanic_animation_finished() -> void:
	if mechanicsprite.animation == "boring":
		mechanicsprite.play("idle")
		_schedule_boring(mechanic_boring_timer)
