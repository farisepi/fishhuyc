extends Area2D

@export var speed: float = 40.0

var direction: Vector2 = Vector2.UP
var life_time: float = 4.0
var clickable: bool = false
var popped: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	
	# плавное появление
	modulate.a = 0.0
	
	var target_alpha = randf_range(0.01, 0.75)
	
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", target_alpha, 0.6)
	
	# случайный размер БЕЗ растягивания
	var scale_value = randf_range(0.15, 0.5)
	scale = Vector2.ONE * scale_value
	
	# idle анимация
	if sprite:
		sprite.play("idle")
	
	# таймер жизни
	var timer = get_tree().create_timer(life_time)
	timer.timeout.connect(_auto_pop)

func _process(delta: float) -> void:
	if popped:
		return
	
	global_position += direction * speed * delta

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func start_life(time: float) -> void:
	life_time = time

func _on_mouse_entered() -> void:
	if not clickable:
		return
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_pop()

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
	
	if collision:
		collision.disabled = true
	
	# звук только при клике
	var pop_sound = AudioStreamPlayer.new()
	add_child(pop_sound)
	pop_sound.stream = preload("res://Sounds/SFX/Pop.mp3")
	pop_sound.volume_db = -18.0
	pop_sound.pitch_scale = randf_range(0.95, 1.05)
	pop_sound.play()
	
	# анимация взрыва
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
		collision.disabled = true
	
	# авто-лопание БЕЗ звука
	if sprite:
		sprite.play("pop")
		await sprite.animation_finished
	
	queue_free()
