extends Area2D

@export var item_texture: Texture2D
@export var throw_speed: float = 500.0

var is_held: bool = false
var target: Node2D = null

func _ready():
	add_to_group("grabbable")

func grab():
	is_held = true
	queue_free()

func throw_at_target(enemy: Node2D):
	if not enemy:
		return
	
	target = enemy
	var throw_icon = Sprite2D.new()
	throw_icon.texture = item_texture
	throw_icon.scale = Vector2(0.3, 0.3)
	throw_icon.modulate = Color(0.2, 0.2, 0.2, 1)
	throw_icon.global_position = global_position
	get_tree().current_scene.add_child(throw_icon)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(throw_icon, "global_position", enemy.global_position, 0.3)
	await tween.finished
	
	if enemy.has_method("stun"):
		enemy.stun()
	
	throw_icon.queue_free()
