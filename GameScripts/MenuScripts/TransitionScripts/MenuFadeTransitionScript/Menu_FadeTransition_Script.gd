extends ColorRect

signal fade_in_finished
signal fade_out_finished

var _tw: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color.BLACK
	modulate.a = 0.0
	size = Vector2(10000, 10000)
	position = Vector2.ZERO
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 100

func _kill() -> void:
	if _tw and _tw.is_valid():
		_tw.kill()

## Fades from the current darkness back to the picture (no-op if already clear).
func fade_in() -> void:
	_kill()
	if modulate.a <= 0.001:
		fade_in_finished.emit()
		return
	_tw = create_tween()
	_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw.tween_property(self, "modulate:a", 0.0, 0.3)
	await _tw.finished
	fade_in_finished.emit()

func fade_out() -> void:
	_kill()
	_tw = create_tween()
	_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw.tween_property(self, "modulate:a", 1.0, 0.3)
	await _tw.finished
	fade_out_finished.emit()
