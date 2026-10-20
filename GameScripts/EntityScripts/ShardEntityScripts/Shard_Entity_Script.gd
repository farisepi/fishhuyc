extends Area2D

@export var shard_color: String = "blue"
@export var shard_texture: Texture2D = null
@export var float_amplitude: float = 3.0
@export var float_speed: float = 3.0
@export var pickup_radius: float = 40.0
@export var pickup_speed: float = 0.3
@export var pickup_delay: float = 0.5

var base_y: float = 0.0
var time: float = 0.0
var collected: bool = false
var spawn_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("shards")
	base_y = global_position.y
	spawn_timer = pickup_delay
	if shard_texture and sprite:
		sprite.texture = shard_texture
		sprite.scale = Vector2(1.5, 1.5)
	if collision and collision.shape is CircleShape2D:
		collision.shape.radius = pickup_radius
	if sprite:
		sprite.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

func _process(delta: float) -> void:
	if collected:
		return
	if spawn_timer > 0:
		spawn_timer -= delta
	time += delta
	global_position.y = base_y + sin(time * float_speed) * float_amplitude
	if sprite:
		sprite.rotation = sin(time * 1.5) * 0.2
	if spawn_timer > 0:
		return
	var bodies = get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("player"):
			_try_pickup(b)
			return

func _on_body_entered(body: Node2D) -> void:
	if collected or spawn_timer > 0:
		return
	if body.is_in_group("player"):
		_try_pickup(body)

func _try_pickup(body: Node2D) -> void:
	if collected or spawn_timer > 0:
		return
	collected = true
	if collision:
		collision.set_deferred("disabled", true)
	Global.add_shard(shard_color, 1)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", body.global_position, pickup_speed)
	if sprite:
		tween.tween_property(sprite, "scale", Vector2.ZERO, pickup_speed)
		tween.tween_property(sprite, "modulate:a", 0.0, pickup_speed)
	await tween.finished
	queue_free()
