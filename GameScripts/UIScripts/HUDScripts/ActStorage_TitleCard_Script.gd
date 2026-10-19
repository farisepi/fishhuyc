extends CanvasLayer

@onready var label: Label = $Label
@onready var bg: ColorRect = $BG

func show_title(title: String, subtitle: String = "", hold_time: float = 2.5) -> void:
	label.text = title
	if subtitle != "":
		label.text += "\n" + subtitle
	label.modulate.a = 0.0
	bg.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(bg, "modulate:a", 1.0, 0.6)
	tween.tween_property(label, "modulate:a", 1.0, 0.6)
	await get_tree().create_timer(hold_time).timeout
	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(bg, "modulate:a", 0.0, 1.0)
	tween2.tween_property(label, "modulate:a", 0.0, 1.0)
	await tween2.finished
	queue_free()
