extends Area2D

@export var object_color: Color = Color(0.6, 0.4, 0.2)

var is_destroyed: bool = false

@onready var rect: ColorRect = $ColorRect

func _ready() -> void:
	if rect:
		rect.color = object_color

func set_object_color(c: Color) -> void:
	object_color = c
	if rect:
		rect.color = c

func destroy_with_flash() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.size = Vector2(60, 60)
	flash.position = Vector2(-30, -30)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 100
	add_child(flash)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 0.7), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	queue_free()
