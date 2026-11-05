class_name ButtonEffects
extends Node

static func setup(btn: Control, click_sound_callable: Callable = UISounds.play_click) -> void:
	if not btn or not is_instance_valid(btn):
		return
	
	stabilize_text(btn)
	complete_styles(btn)
	add_shimmer(btn)
	# buttons are always fully opaque at rest (the alpha used to be taken from the moment of
	# setup - if a menu was still fading in, the button stayed half transparent / invisible)
	var original_alpha = 1.0
	if btn.modulate.a < 0.99 and not btn.has_meta("fx_keep_alpha"):
		btn.modulate.a = 1.0
	
	if btn is Button:
		btn.pivot_offset = btn.size / 2.0
		if click_sound_callable.is_valid() and not btn.pressed.is_connected(click_sound_callable):
			btn.pressed.connect(click_sound_callable)
	
	if not btn.mouse_entered.is_connected(_on_hover.bind(btn, original_alpha)):
		btn.mouse_entered.connect(_on_hover.bind(btn, original_alpha))
	if not btn.mouse_exited.is_connected(_on_unhover.bind(btn, original_alpha)):
		btn.mouse_exited.connect(_on_unhover.bind(btn, original_alpha))

## A light band sweeps over the menu buttons now and then (buttons further down the screen
## get it a bit later, so it runs down the menu like a wave).
static func add_shimmer(btn: Control) -> void:
	if btn.material != null or not Global.button_effects_enabled:
		return
	var sh = load("res://GameShaders/SharedShaders/Shared_UIShimmer_Shader.gdshader")
	if sh == null:
		return
	var m = ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("rect_min", Vector2.ZERO)
	m.set_shader_parameter("rect_size", btn.size if btn.size.x > 1.0 else Vector2(200, 40))
	m.set_shader_parameter("pixel", 2.0)
	m.set_shader_parameter("period", 11.0)
	m.set_shader_parameter("strength", 0.07)
	m.set_shader_parameter("band", 0.07)
	m.set_shader_parameter("phase", -clamp(btn.global_position.y / 2000.0, 0.0, 0.4))
	btn.material = m
	if not btn.resized.is_connected(_on_shimmer_resized.bind(btn)):
		btn.resized.connect(_on_shimmer_resized.bind(btn))


static func _on_shimmer_resized(btn: Control) -> void:
	if is_instance_valid(btn) and btn.material is ShaderMaterial:
		btn.material.set_shader_parameter("rect_size", btn.size)


## A button only had normal / hover / pressed boxes: in the other states (keyboard focus,
## hovered while pressed, disabled) Godot fell back to the default grey theme box, so the
## button suddenly "lost" its look. Every state now has a box from the button's own set.
static func complete_styles(btn: Control) -> void:
	if not (btn is Button):
		return
	var b: Button = btn
	if not b.has_theme_stylebox_override("normal"):
		return
	var normal = b.get_theme_stylebox("normal")
	var hover = b.get_theme_stylebox("hover") if b.has_theme_stylebox_override("hover") else normal
	var pressed = b.get_theme_stylebox("pressed") if b.has_theme_stylebox_override("pressed") else hover
	if not b.has_theme_stylebox_override("hover"):
		b.add_theme_stylebox_override("hover", normal)
	if not b.has_theme_stylebox_override("pressed"):
		b.add_theme_stylebox_override("pressed", hover)
	if not b.has_theme_stylebox_override("hover_pressed"):
		b.add_theme_stylebox_override("hover_pressed", pressed)
	if not b.has_theme_stylebox_override("disabled"):
		b.add_theme_stylebox_override("disabled", normal)
	if not b.has_theme_stylebox_override("focus"):
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# same text colour in every state unless the scene set its own
	if b.has_theme_color_override("font_color"):
		var c = b.get_theme_color("font_color")
		for k in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			if not b.has_theme_color_override(k):
				b.add_theme_color_override(k, c)


## Menu text sometimes vanished: the glyph cache of the dynamic font was rebuilt (window
## resize / resolution change re-rasterizes glyphs at a new oversampling) and some glyphs
## came back empty. Fixed oversampling keeps one stable glyph cache. Also: no stray
## line breaks in button texts and no odd per-button system font.
static func stabilize_text(btn: Control) -> void:
	if btn is Button:
		var t: String = btn.text.strip_edges()
		if t != btn.text:
			btn.text = t
		if btn.has_theme_font_override("font"):
			var own = btn.get_theme_font("font")
			if own is SystemFont and (own as SystemFont).font_names.is_empty():
				btn.remove_theme_font_override("font")
	fix_font(btn.get_theme_font("font"))


static func fix_font(f: Font) -> void:
	if f == null:
		return
	if f is FontVariation and (f as FontVariation).base_font:
		fix_font((f as FontVariation).base_font)
		return
	if "oversampling" in f and float(f.get("oversampling")) == 0.0:
		f.set("oversampling", 2.0)


static func _on_hover(control: Control, original_alpha: float) -> void:
	if not control or not is_instance_valid(control):
		return
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
	if not control or not is_instance_valid(control):
		return
	_kill_meta(control, "color_tween")
	_kill_meta(control, "glass_tween")
	
	_remove_glass_effect(control)
	
	var settle = control.create_tween()
	settle.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	settle.tween_property(control, "modulate", Color(1.0, 1.0, 1.0, original_alpha), 0.4)

static func _apply_glass_effect(control: Control) -> void:
	if not control or not is_instance_valid(control):
		return
	var glass = control.get_node_or_null("GlassOverlay")
	if not glass:
		glass = ColorRect.new()
		glass.name = "GlassOverlay"
		glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glass.color = Color(1.0, 1.0, 1.0, 0.0)
		glass.z_index = 5
		control.add_child(glass)
		glass.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var glow = control.get_node_or_null("GlassGlow")
	if not glow:
		glow = ColorRect.new()
		glow.name = "GlassGlow"
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.color = Color(0.6, 0.85, 1.0, 0.0)
		glow.z_index = 4
		control.add_child(glow)
		glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var glass_tween = control.create_tween()
	glass_tween.set_parallel(true)
	glass_tween.tween_property(glass, "color:a", 0.15, 0.3).set_ease(Tween.EASE_OUT)
	glass_tween.tween_property(glow, "color:a", 0.08, 0.3).set_ease(Tween.EASE_OUT)
	control.set_meta("glass_tween", glass_tween)

static func _remove_glass_effect(control: Control) -> void:
	if not control or not is_instance_valid(control):
		return
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
	if not control or not is_instance_valid(control):
		return

	var root = control.get_tree().current_scene
	if not root or not is_instance_valid(root):
		return

	var btn_global_pos = control.global_position
	var btn_width = control.size.x
	var btn_height = control.size.y

	for _i in range(2):
		var bubble = ColorRect.new()
		bubble.color = Color(1.0, 1.0, 1.0, 0.4)
		bubble.size = Vector2(4, 4)
		bubble.z_index = 50
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bubble.position = btn_global_pos + Vector2(randf_range(5, btn_width - 5), btn_height - 5) #сука блять
		root.add_child(bubble)

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
	if not control or not is_instance_valid(control):
		return
	if not control.has_meta(key):
		return
	var t: Tween = control.get_meta(key)
	if t and t.is_valid():
		t.kill()
