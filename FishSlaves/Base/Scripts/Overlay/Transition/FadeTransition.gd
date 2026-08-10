extends ColorRect

# ============================================
# СИГНАЛЫ (для ожидания завершения анимации)
# ============================================

signal fade_in_finished
signal fade_out_finished

# ============================================
# _ready()
# ============================================

func _ready() -> void:
	color = Color.BLACK
	modulate.a = 0.0
	size = get_viewport().get_visible_rect().size
	position = Vector2.ZERO
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 100

# ============================================
# fade_in() - плавное появление из темноты
# ============================================

func fade_in() -> void:
	modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	await tw.finished
	emit_signal("fade_in_finished")  # <-- ДОБАВЛЕНО

# ============================================
# fade_out() - плавное затемнение
# ============================================

func fade_out() -> void:
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
	await tw.finished
	emit_signal("fade_out_finished")  # <-- ДОБАВЛЕНО
