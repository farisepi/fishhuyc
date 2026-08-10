extends Area2D

@export var speed: float = 40.0

var direction: Vector2 = Vector2.UP
var life_time: float = 4.0
var life_timer: float = 0.0
var clickable: bool = false
var popped: bool = false
var ignore_fish_collision: bool = false
var ignore_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	mouse_entered.connect(_on_mouse_entered)
	body_entered.connect(_on_body_entered)
	
	ignore_fish_collision = true
	ignore_timer = 0.3
	
	life_timer = life_time
	
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
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_pop()

func _pop() -> void:
	if popped:
		return
	
	popped = true
	clickable = false
	
	Global.bubbles_popped += 1
	if Global.bubbles_popped == 100:
		Achievements.unlock_pop_star()
		call_deferred("_notify_achievement")
	
	if collision:
		collision.call_deferred("set_disabled", true)
	
	var pop_sound = AudioStreamPlayer.new()
	add_child(pop_sound)
	pop_sound.stream = preload("res://Fish Slaves/Sounds/SFX/OverlaySFX/Pop.mp3")
	pop_sound.volume_db = -24.0
	pop_sound.pitch_scale = randf_range(0.95, 1.05)
	pop_sound.play()
	
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