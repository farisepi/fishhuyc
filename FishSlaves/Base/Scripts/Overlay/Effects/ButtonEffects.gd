# button_effects.gd
class_name ButtonEffects
extends Node

static func setup(btn: Button, click_sound_callable: Callable = UISounds.play_click) -> void:
	if not btn:
		return
	
	var original_alpha = btn.modulate.a
	
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(_on_button_hover.bind(btn, original_alpha))
	btn.mouse_exited.connect(_on_button_unhover.bind(btn, original_alpha))
	btn.pressed.connect(click_sound_callable)
	
	_idle_animation(btn)

static func _idle_animation(btn: Button) -> void:
	_kill_meta(btn, "idle_tween")
	var tween = btn.create_tween()
	tween.set_loops()
	tween.tween_property(btn, "scale", Vector2(1.01, 1.01), 2.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(btn, "scale", Vector2(0.99, 0.99), 2.5).set_ease(Tween.EASE_IN_OUT)
	btn.set_meta("idle_tween", tween)

static func _on_button_hover(btn: Button, original_alpha: float) -> void:
	_kill_meta(btn, "idle_tween")
	_kill_meta(btn, "color_tween")
	_kill_meta(btn, "jelly_tween")
	
	var color_tween = btn.create_tween()
	color_tween.set_loops()
	color_tween.tween_property(btn, "modulate", Color(0.75, 0.88, 1.0, original_alpha), 1.2).set_ease(Tween.EASE_IN_OUT)
	color_tween.tween_property(btn, "modulate", Color(0.55, 0.72, 1.0, original_alpha), 1.2).set_ease(Tween.EASE_IN_OUT)
	btn.set_meta("color_tween", color_tween)
	
	if btn.has_meta("no_scale_animation") and btn.get_meta("no_scale_animation"):
		return
	
	# Jelly симметричный — не сдвигается
	var pos = btn.position
	var jelly = btn.create_tween()
	jelly.set_loops()
	jelly.tween_property(btn, "scale", Vector2(1.04, 0.96), 0.4).set_ease(Tween.EASE_IN_OUT)
	jelly.tween_property(btn, "scale", Vector2(0.96, 1.04), 0.4).set_ease(Tween.EASE_IN_OUT)
	btn.set_meta("jelly_tween", jelly)
	
	# Фиксируем позицию
	btn.position = pos
	
	_spawn_bubbles(btn)

static func _on_button_unhover(btn: Button, original_alpha: float) -> void:
	_kill_meta(btn, "color_tween")
	_kill_meta(btn, "jelly_tween")
	
	btn.scale = Vector2.ONE
	
	var settle = btn.create_tween()
	settle.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	settle.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, original_alpha), 0.4)
	
	settle.finished.connect(_idle_animation.bind(btn), ConnectFlags.CONNECT_ONE_SHOT)

static func _spawn_bubbles(btn: Button) -> void:
	var container = btn.get_parent()
	if not container:
		return
	
	var btn_pos = btn.global_position
	var btn_width = btn.size.x
	
	for _i in range(2):
		var bubble = ColorRect.new()
		bubble.color = Color(1.0, 1.0, 1.0, 0.4)
		bubble.size = Vector2(4, 4)
		bubble.position = btn_pos + Vector2(randf_range(5, btn_width - 5), btn.size.y - 5)
		container.add_child(bubble)
		
		var t = btn.create_tween()
		t.set_ease(Tween.EASE_IN_OUT)
		t.tween_property(bubble, "position:y", bubble.position.y - 50, 1.5)
		t.parallel().tween_property(bubble, "position:x", bubble.position.x + randf_range(-8, 8), 1.5)
		t.parallel().tween_property(bubble, "modulate:a", 0.0, 1.5)
		t.parallel().tween_property(bubble, "scale", Vector2(0.5, 0.5), 1.5)
		t.finished.connect(bubble.queue_free)

static func _kill_meta(btn: Button, key: String) -> void:
	if not btn.has_meta(key):
		return
	var t: Tween = btn.get_meta(key)
	if t and t.is_valid():
		t.kill()
