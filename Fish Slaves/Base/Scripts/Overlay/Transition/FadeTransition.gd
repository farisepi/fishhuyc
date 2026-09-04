extends ColorRect

signal fade_in_finished
signal fade_out_finished

func _ready() -> void:
	color = Color.BLACK
	modulate.a = 0.0
	size = Vector2(10000, 10000)
	position = Vector2.ZERO
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 100

func fade_in() -> void:
	modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	await tw.finished
	emit_signal("fade_in_finished")

func fade_out() -> void:
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
	await tw.finished
	emit_signal("fade_out_finished")
