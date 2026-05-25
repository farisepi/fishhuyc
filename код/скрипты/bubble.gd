extends Node2D

@export var rise_speed: float = 35.0
@export var wobble_amount: float = 8.0
@export var wobble_speed: float = 2.5

@onready var static_sprite: Sprite2D = $StaticSprite
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim

var start_x: float
var exploded: bool = false
var is_alive: bool = true
var direction: Vector2 = Vector2.UP

func _ready() -> void:
	start_x = position.x
	set_process(true)

func _process(delta: float) -> void:
	if not is_alive:
		return
	position += direction * rise_speed * delta
	var wobble = sin(Time.get_ticks_msec() * 0.001 * wobble_speed) * wobble_amount
	position.x = start_x + wobble

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func start_life(lifetime: float) -> void:
	is_alive = true
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func explode() -> void:
	if exploded:
		return
	exploded = true
	is_alive = false
	static_sprite.visible = false
	explosion_anim.visible = true
	explosion_anim.play("pop")
	await explosion_anim.animation_finished
	if is_instance_valid(self):
		queue_free()
