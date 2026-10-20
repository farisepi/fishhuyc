extends Node2D

var bubble_scene: PackedScene = preload("res://GameScenes/EntityScenes/BubbleEntityScenes/Bubble_Scene.tscn")

const WATER_RECT: Rect2 = Rect2(363, 103, 551, 288)

@onready var animationtrack = $AnimationPlayer
@onready var scientistsprite = $npc/Scientist/ScientistSprite
@onready var mechanicsprite = $npc/Mechanic/MechanicSprite
@onready var chatter: ChatterController = $ChatterController
#@onready var pause_menu: CanvasLayer = $stuff/Pausemenu
@onready var player: CharacterBody2D = $Player
var scientist_boring_timer: Timer
var mechanic_boring_timer: Timer

const BORING_INTERVAL_MIN: float = 15.0
const BORING_INTERVAL_MAX: float = 20.0

func _ready():
	GlobalMusic.play_level_music()
	animationtrack.play("INTRO")
	
	_setup_character_animations()
	_spawn_bubbles()

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
		
func _spawn_bubbles() -> void:
	await get_tree().process_frame
	for i in range(6):
		_make_bubble()
		await get_tree().create_timer(0.5).timeout

func _make_bubble() -> void:
	if not bubble_scene:
		return
	
	var bubble = bubble_scene.instantiate()
	add_child(bubble)
	
	bubble.global_position = _get_random_position_with_y_limit(0.0)
	
	var bubble_scale = randf_range(0.35, 0.7)
	bubble.scale = Vector2(bubble_scale, bubble_scale)
	
	bubble.modulate.a = 0.0
	
	var direction_x = randf_range(-0.2, 0.2)
	bubble.set_direction(Vector2(direction_x, -1.0))
	
	var appear_tween = create_tween()
	appear_tween.tween_property(bubble, "modulate:a", randf_range(0.1, 0.5), 0.8)
	
	bubble.start_life(randf_range(5.0, 10.0))
	bubble.clickable = false
	
	if bubble.has_signal("body_entered"):
		bubble.body_entered.connect(_on_bubble_body_entered.bind(bubble))
	
	var spawn_timer = get_tree().create_timer(randf_range(1.5, 3.0), false)
	spawn_timer.timeout.connect(_make_bubble)

func _on_bubble_body_entered(body: Node2D, bubble: Area2D) -> void:
	if body == player and not bubble.popped:
		bubble._pop()

func _get_random_position_with_y_limit(_max_y: float) -> Vector2:
	var area: Rect2 = _get_camera_view_rect().intersection(WATER_RECT)
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		area = WATER_RECT
	
	var y_min = area.position.y + area.size.y * 0.3
	var y_max = area.end.y - 8.0
	return Vector2(
		randf_range(area.position.x + 8.0, area.end.x - 8.0),
		randf_range(y_min, y_max)
	)

func _get_camera_view_rect() -> Rect2:
	var camera = _get_player_camera()
	if not camera:
		return WATER_RECT
	var view_size: Vector2 = get_viewport().get_visible_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - view_size / 2.0, view_size)

func _get_player_camera() -> Camera2D:
	if player and player.has_node("PlayerCamera"):
		return player.get_node("PlayerCamera") as Camera2D
	return get_viewport().get_camera_2d()

func _wait_dialog() -> void:
	var tree = get_tree()
	if not tree:
		return
	await tree.create_timer(1.25).timeout
