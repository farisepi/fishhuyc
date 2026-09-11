class_name ButtonEffects
extends Node

static func setup(btn: Control, click_sound_callable: Callable = UISounds.play_click) -> void:
	if not btn:
		return
	
	var original_alpha = btn.modulate.a
	
	if btn is Button:
		btn.pivot_offset = btn.size / 2.0
		btn.pressed.connect(click_sound_callable)
	
	btn.mouse_entered.connect(_on_hover.bind(btn, original_alpha))
	btn.mouse_exited.connect(_on_unhover.bind(btn, original_alpha))

static func _on_hover(control: Control, original_alpha: float) -> void:
	_kill_meta(control, "color_tween")
	_kill_meta(control, "glass_tween")
	
	var color_tween = control.create_tween()
	color_tween.set_loops()
	color_tween.tween_property(control, "modulate", Color(0.75, 0.88, 1.0, original_alpha), 1.2).set_ease(Tween.EASE_IN_OUT)
	color_tween.tween_property(control, "modulate", Color(0.55, 0.72, 1.0, original_alpha), 1.2).set_ease(Tween.EASE_IN_OUT)
	control.set_meta("color_tween", color_tween)
	
	_apply_glass_effect(control)
	_spawn_bubbles(control)

static func _on_unhover(control: Control, original_alpha: float) -> void:
	_kill_meta(control, "color_tween")
	_kill_meta(control, "glass_tween")
	
	_remove_glass_effect(control)
	
	var settle = control.create_tween()
	settle.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	settle.tween_property(control, "modulate", Color(1.0, 1.0, 1.0, original_alpha), 0.4)

static func _apply_glass_effect(control: Control) -> void:
	var glass = control.get_node_or_null("GlassOverlay")
	if not glass:
		glass = ColorRect.new()
		glass.name = "GlassOverlay"
		glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glass.color = Color(1.0, 1.0, 1.0, 0.0)
		glass.z_index = 5
		control.add_child(glass)
	
	glass.set_anchors_preset(Control.PRESET_FULL_RECT)
	glass.offset_left = 0
	glass.offset_right = 0
	glass.offset_top = 0
	glass.offset_bottom = 0
	
	var glow = control.get_node_or_null("GlassGlow")
	if not glow:
		glow = ColorRect.new()
		glow.name = "GlassGlow"
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.color = Color(0.6, 0.85, 1.0, 0.0)
		glow.z_index = 4
		control.add_child(glow)
	
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.offset_left = 0
	glow.offset_right = 0
	glow.offset_top = 0
	glow.offset_bottom = 0
	
	var glass_tween = control.create_tween()
	glass_tween.set_parallel(true)
	glass_tween.tween_property(glass, "color:a", 0.15, 0.3).set_ease(Tween.EASE_OUT)
	glass_tween.tween_property(glow, "color:a", 0.08, 0.3).set_ease(Tween.EASE_OUT)
	control.set_meta("glass_tween", glass_tween)

static func _remove_glass_effect(control: Control) -> void:
	var glass = control.get_node_or_null("GlassOverlay")
	var glow = control.get_node_or_null("GlassGlow")
	
	var glass_tween = control.create_tween()
	glass_tween.set_parallel(true)
	if glass:
		glass_tween.tween_property(glass, "color:a", 0.0, 0.3).set_ease(Tween.EASE_OUT)
	if glow:
		glass_tween.tween_property(glow, "color:a", 0.0, 0.3).set_ease(Tween.EASE_OUT)
	control.set_meta("glass_tween", glass_tween)

static func _spawn_bubbles(control: Control) -> void:
	if not Global.button_effects_enabled:
		return
	
	var container = control.get_parent()
	if not container:
		return
	
	var btn_pos = control.position
	var btn_width = control.size.x
	var btn_height = control.size.y
	
	for _i in range(2):
		var bubble = ColorRect.new()
		bubble.color = Color(1.0, 1.0, 1.0, 0.4)
		bubble.size = Vector2(4, 4)
		bubble.z_index = 50
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bubble.position = btn_pos + Vector2(randf_range(5, btn_width - 5), btn_height - 5)
		container.add_child(bubble)
		
		var start_pos = bubble.position
		var t = bubble.create_tween()
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.set_ease(Tween.EASE_IN_OUT)
		t.tween_property(bubble, "position:y", start_pos.y - 50, 1.5)
		t.parallel().tween_property(bubble, "position:x", start_pos.x + randf_range(-8, 8), 1.5)
		t.parallel().tween_property(bubble, "modulate:a", 0.0, 1.5)
		t.parallel().tween_property(bubble, "scale", Vector2(0.5, 0.5), 1.5)
		t.finished.connect(bubble.queue_free)

static func _kill_meta(control: Control, key: String) -> void:
	if not control.has_meta(key):
		return
	var t: Tween = control.get_meta(key)
	if t and t.is_valid():
		t.kill()
