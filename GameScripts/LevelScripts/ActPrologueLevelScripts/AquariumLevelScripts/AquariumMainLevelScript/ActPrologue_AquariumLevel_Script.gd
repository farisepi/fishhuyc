extends Node2D

var bubble_scene: PackedScene = preload("res://GameScenes/EntityScenes/BubbleEntityScenes/Bubble_Scene.tscn")

const WATER_RECT: Rect2 = Rect2(363, 103, 551, 288)

@onready var animationtrack = $AnimationPlayer
@onready var scientistsprite = $npc/Scientist/ScientistSprite
@onready var mechanicsprite = $npc/Mechanic/MechanicSprite
@onready var chatter: ChatterController = $ChatterController
@onready var pausemenu: CanvasLayer = get_node_or_null("Pausemenu")
@onready var player: CharacterBody2D = $Player
@onready var lights_root: Node = get_node_or_null("Visual/Light")
@onready var fade_rect: CanvasItem = get_node_or_null("Visual/stuff/Fade")
var _ending: bool = false

const QUAKE_DELAY: float = 1.5
const QUAKE_DURATION: float = 4.5
var scientist_boring_timer: Timer
var mechanic_boring_timer: Timer

const BORING_INTERVAL_MIN: float = 15.0
const BORING_INTERVAL_MAX: float = 20.0

func _ready():
	GlobalMusic.play_level_music()
	animationtrack.play("INTRO")
	
	_setup_character_animations()
	_spawn_bubbles()
	UISounds.start_factory_ambience()
	if pausemenu:
		pausemenu.visible = false
	# when the scientist and the mechanic are done talking the complex starts shaking
	if chatter and not chatter.chatter_stopped.is_connected(_on_chatter_finished):
		chatter.chatter_stopped.connect(_on_chatter_finished)

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


# ---------------------------------------------------------------------------
# Earthquake -> blackout -> the story continues at the factory
# ---------------------------------------------------------------------------

func _on_chatter_finished() -> void:
	if _ending:
		return
	_ending = true
	_play_earthquake()

func _play_earthquake() -> void:
	await get_tree().create_timer(QUAKE_DELAY).timeout
	if not is_inside_tree():
		return
	UISounds.play_earthquake()
	var lights: Array = []
	var base_energy: Array = []
	if lights_root:
		for l in lights_root.get_children():
			if l is PointLight2D:
				lights.append(l)
				base_energy.append(l.energy)
	var t := 0.0
	var flicker_timer := 0.0
	while t < QUAKE_DURATION:
		var dt = get_process_delta_time()
		t += dt
		var k = clamp(t / QUAKE_DURATION, 0.0, 1.0)
		if player and "shake_amount" in player:
			player.shake_amount = lerp(1.5, 7.0, k)
		UISounds.set_glitch(k)
		flicker_timer -= dt
		if flicker_timer <= 0.0:
			flicker_timer = randf_range(0.04, 0.18)
			for i in range(lights.size()):
				var on = randf() > lerp(0.1, 0.65, k)
				lights[i].energy = base_energy[i] * (randf_range(0.7, 1.25) if on else 0.05)
		await get_tree().process_frame
		if not is_inside_tree():
			return
	# blackout
	for l in lights:
		l.energy = 0.0
	if fade_rect:
		fade_rect.visible = true
		var tw = create_tween()
		tw.tween_property(fade_rect, "modulate:a", 1.0, 1.4)
		await tw.finished
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	UISounds.stop_earthquake()
	UISounds.set_glitch(0.0)
	UISounds.stop_factory_ambience()
	Global.prologue1_completed = true
	Global.autosave(Global.SCENE_FACTORY)
	Global.goto_scene(Global.SCENE_FACTORY)

# ---------------------------------------------------------------------------
# Pause
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_toggle_pause()

func _toggle_pause() -> void:
	if pausemenu == null or _ending:
		return
	if get_tree().paused:
		get_tree().paused = false
		GlobalMusic.restore_volume()
		UISounds.restore_ambience()
		if chatter:
			chatter.resume_chatter()
		if pausemenu.has_method("hide_menu"):
			pausemenu.hide_menu()
		else:
			pausemenu.visible = false
	else:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GlobalMusic.lower_volume()
		UISounds.lower_ambience()
		if chatter:
			chatter.pause_chatter()
		if pausemenu.has_method("show_menu"):
			pausemenu.show_menu()
		else:
			pausemenu.visible = true

func _resume_after_pause() -> void:
	if chatter:
		chatter.resume_chatter()
