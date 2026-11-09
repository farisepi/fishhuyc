extends Area2D

@export var speed: float = 40.0
@export var clickable: bool = false

var direction: Vector2 = Vector2.UP
var life_time: float = 4.0
var life_timer: float = 0.0
var popped: bool = false
var ignore_fish_collision: bool = false
var ignore_timer: float = 0.0
## >= 0: the bubble is carried over from another aquarium menu (keeps its look, no fade-in)
var restored_alpha: float = -1.0

## The background bubbles are the same in every aquarium menu (like the boxes on the factory
## belt): switching main menu <-> settings / saves / achievements keeps them where they were
## instead of spawning a new set. They can only be popped in the main menu.
static var _menu_saved: Array = []
static var _menu_saved_t: int = 0

static func save_menu_bubbles(parent: Node) -> void:
	var arr: Array = []
	for c in parent.get_children():
		if is_instance_valid(c) and c.has_meta("menu_bg") and not c.popped:
			arr.append([c.global_position, c.scale, c.speed, c.direction, c.modulate.a, c.life_timer])
	_menu_saved = arr
	_menu_saved_t = Time.get_ticks_msec()

## Puts the saved bubbles back (moved on by the time the menus were switching).
## Returns false when there was nothing to restore.
static func restore_menu_bubbles(parent: Node, scene: PackedScene, can_click: bool) -> bool:
	if _menu_saved.is_empty() or scene == null:
		return false
	var gone = clamp((Time.get_ticks_msec() - _menu_saved_t) / 1000.0, 0.0, 3.0)
	var saved = _menu_saved
	_menu_saved = []
	var n := 0
	for b in saved:
		var life = float(b[5]) - gone
		if life <= 0.2:
			continue
		var bubble = scene.instantiate()
		bubble.set_meta("menu_bg", true)
		bubble.restored_alpha = float(b[4])
		parent.add_child(bubble)
		if not is_instance_valid(bubble) or bubble.is_queued_for_deletion():
			continue
		bubble.z_index = -10
		bubble.scale = b[1]
		bubble.speed = b[2]
		bubble.direction = b[3]
		bubble.global_position = b[0] + b[3] * b[2] * gone
		bubble.life_timer = life
		bubble.clickable = can_click
		n += 1
	return n > 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

const POP_SOUND_PREFIX = "res://GameAssets/Audio/SoundEffects/UserInterfaceSounds/PopUpOptionSounds/Menu_Aquarium_MainMenu_Pop_Option"
const POP_SOUND_SUFFIX = "_SoundEffect.mp3"
const ACT1_POP_SOUND = "res://GameAssets/Audio/SoundEffects/LevelAmbienceSounds/ActPrologueAquariumAmbienceSounds/PopAmbienceSounds/ActPrologue_LevelAquarium_Pop_SoundEffect.mp3"

func _ready() -> void:
	if not Global.atmospheric_effects_enabled:
		queue_free()
		return

	process_mode = Node.PROCESS_MODE_PAUSABLE

	mouse_entered.connect(_on_mouse_entered)
	body_entered.connect(_on_body_entered)

	ignore_fish_collision = true
	ignore_timer = 0.3

	life_timer = life_time

	if restored_alpha >= 0.0:
		modulate.a = restored_alpha
	else:
		modulate.a = 0.0

		var target_alpha = randf_range(0.01, 0.75)

		var fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate:a", target_alpha, 0.6)

		var scale_value = randf_range(0.15, 0.5)
		scale = Vector2.ONE * scale_value

	if sprite:
		sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if popped:
		return

	if ignore_fish_collision:
		return

	if body.name == "рыбка":
		_pop()

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	if popped:
		return

	if not Global.atmospheric_effects_enabled:
		queue_free()
		return

	if ignore_fish_collision:
		ignore_timer -= delta
		if ignore_timer <= 0:
			ignore_fish_collision = false

	global_position += direction * speed * delta

	life_timer -= delta
	if life_timer <= 0:
		_auto_pop()

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func start_life(time: float) -> void:
	life_time = time

func _on_mouse_entered() -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	if popped:
		return

	var check_node = area
	while check_node:
		if check_node.name == "рыбка":
			_pop()
			return
		check_node = check_node.get_parent()

func _input_event(_viewport, event, _shape_idx) -> void:
	if not clickable:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_pop()

func _pop() -> void:
	if popped:
		return

	popped = true
	clickable = false

	Global.bubbles_popped += 1
	if Global.bubbles_popped >= 100 and not Achievements.pop_star_unlocked:
		Achievements.unlock_pop_star()
		call_deferred("_notify_achievement")   # the big-bubble effect plays only the once

	if collision:
		collision.call_deferred("set_disabled", true)

	var is_act1 = get_tree().current_scene and get_tree().current_scene.scene_file_path.contains("Act1")

	if is_act1:
		_play_act1_pop_sound()
	else:
		_play_random_pop_sound()

	if sprite:
		sprite.play("pop")
		await sprite.animation_finished

	queue_free()

func _auto_pop() -> void:
	if popped:
		return

	popped = true
	clickable = false

	if collision:
		collision.call_deferred("set_disabled", true)

	if sprite:
		sprite.play("pop")
		await sprite.animation_finished

	queue_free()

func _notify_achievement():
	var main_menu = get_tree().current_scene
	if main_menu and main_menu.has_method("_show_pop_star_achievement"):
		main_menu._show_pop_star_achievement()

func _play_random_pop_sound() -> void:
	var random_index = randi() % 12 + 1
	var sound_path = POP_SOUND_PREFIX + str(random_index) + POP_SOUND_SUFFIX

	var sound_stream = load(sound_path)
	if sound_stream == null:
		return

	var pop_sound = AudioStreamPlayer.new()
	pop_sound.bus = "SFX"
	add_child(pop_sound)
	pop_sound.stream = sound_stream
	pop_sound.volume_db = -8.0
	pop_sound.pitch_scale = randf_range(0.95, 1.05)
	pop_sound.play()

func _play_act1_pop_sound() -> void:
	var sound_stream = load(ACT1_POP_SOUND)
	if sound_stream == null:
		return

	var pop_sound = AudioStreamPlayer.new()
	pop_sound.bus = "SFX"
	add_child(pop_sound)
	pop_sound.stream = sound_stream
	pop_sound.volume_db = -8.0
	pop_sound.pitch_scale = randf_range(0.95, 1.05)
	pop_sound.play()

func _on_animated_sprite_2d_animation_finished() -> void:
	pass

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
