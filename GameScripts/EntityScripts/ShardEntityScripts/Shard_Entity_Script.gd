extends Area2D

@export var shard_color: String = "blue"
@export var shard_texture: Texture2D = null
@export var float_amplitude: float = 4.0
@export var float_speed: float = 3.0
@export var pickup_radius: float = 30.0
@export var pickup_speed: float = 0.3

var base_y: float = 0.0
var time: float = 0.0
var collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("shards")
	body_entered.connect(_on_body_entered)
	base_y = global_position.y
	if shard_texture and sprite:
		sprite.texture = shard_texture
	sprite.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

func _process(delta: float) -> void:
	if collected:
		return
	time += delta
	global_position.y = base_y + sin(time * float_speed) * float_amplitude
	if sprite:
		sprite.rotation = sin(time * 1.5) * 0.2

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	if not body.is_in_group("player"):
		return
	if body.global_position.distance_to(global_position) > pickup_radius + 30.0:
		return
	collected = true
	if collision:
		collision.set_deferred("disabled", true)
	Global.add_shard(shard_color, 1)
	if has_node("/root/UISounds"):
		UISounds.play_achievement()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", body.global_position, pickup_speed)
	tween.tween_property(sprite, "scale", Vector2.ZERO, pickup_speed)
	tween.tween_property(sprite, "modulate:a", 0.0, pickup_speed)
	await tween.finished
	queue_free()
