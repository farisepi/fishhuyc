extends CanvasLayer

@onready var death_label: Label = $DeathLabel
@onready var restart_button: Button = $RestartButton
@onready var menu_button: Button = $MainMenuButton
@onready var quit_button: Button = $QuitButton
@onready var background: ColorRect = $Background

var fade_timer: float = 0.0
var appear_timer: float = 0.0
var state: int = 0
var fading_in: bool = false
var can_interact: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_button.process_mode = Node.PROCESS_MODE_ALWAYS

	hide()

	await get_tree().process_frame
	await get_tree().process_frame

	death_label.modulate = Color(1, 1, 1, 0)
	restart_button.modulate = Color(1, 1, 1, 0)
	menu_button.modulate = Color(1, 1, 1, 0)
	quit_button.modulate = Color(1, 1, 1, 0)
	background.color = Color(0, 0, 0, 0)
	_build_fx()

	set_process(false)
	hide()

func show_death():
	_fill_sub()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	state = 0
	fade_timer = 0.0
	appear_timer = 0.0
	fading_in = true
	can_interact = false
	set_process(true)
	_fx_start()

func hide_death():
	_pause_pending = false
	_fx_t = -1.0
	hide()
	can_interact = false
	fading_in = false
	set_process(false)

var _pause_pending: bool = false

func _air_still_draining() -> bool:
	var scene = get_tree().current_scene
	var p = scene.get_node_or_null("Mecha_Fish") if scene else null
	if p == null or not ("_death_air_out" in p):
		return false
	return p._death_fish_spawned and not p._death_air_out

func _process(delta):
	_fx_process(delta)
	if _pause_pending and not _air_still_draining():
		_pause_pending = false
		get_tree().paused = true
	if not fading_in:
		return

	match state:
		0:
			fade_timer += delta
			var alpha = min(fade_timer / 0.8, 1.0)
			background.color.a = alpha * 0.86
			if fade_timer >= 0.8:
				state = 1
				appear_timer = 0.0

		1:
			appear_timer += delta

			var label_alpha = min((appear_timer) / 0.8, 1.0)
			death_label.modulate.a = label_alpha

			var bi := 0
			for b in [restart_button, menu_button, quit_button]:
				var k = clamp((appear_timer - 0.35 - bi * 0.12) / 0.35, 0.0, 1.0)
				var e = 1.0 - pow(1.0 - k, 3.0)
				b.modulate.a = e
				if _btn_base.has(b):
					b.position = _btn_base[b] + Vector2(0, 18.0 * (1.0 - e))
				bi += 1
			if _sub:
				_sub.modulate.a = clamp((appear_timer - 0.25) / 0.5, 0.0, 1.0)
			if appear_timer >= 0.6 and not can_interact:
				can_interact = true

			var wave = sin(appear_timer * 1.5) * 0.075 + 0.925
			death_label.modulate.a = death_label.modulate.a * wave

			if appear_timer >= 1.2:
				fading_in = false
				can_interact = true
				_pause_pending = true

func _on_restart_button_pressed():
	if not can_interact:
		return
	can_interact = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_fade_out_and_reload()

func _on_main_menu_button_pressed():
	if not can_interact:
		return
	can_interact = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_fade_out_and_goto(Global.SCENE_MAIN_MENU_FACTORY)

func _on_quit_button_pressed():
	if not can_interact:
		return
	get_tree().paused = false
	get_tree().quit()

func _fade_out_and_reload():
	var canvas = CanvasLayer.new()
	canvas.layer = 500
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(canvas)

	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade)

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	await tween.finished

	var current_path = get_tree().current_scene.scene_file_path
	_release_overlay_after_change(canvas, fade)
	get_tree().paused = false
	get_tree().change_scene_to_file(current_path)

func _fade_out_and_goto(path: String):
	var canvas = CanvasLayer.new()
	canvas.layer = 500
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(canvas)

	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade)

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	await tween.finished

	_release_overlay_after_change(canvas, fade)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

func _release_overlay_after_change(canvas: CanvasLayer, fade: ColorRect) -> void:
	var t = canvas.create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_interval(0.25)
	t.tween_property(fade, "color:a", 0.0, 0.4)
	t.tween_callback(canvas.queue_free)


const BACKDROP_SHADER := "res://GameShaders/SharedShaders/Shared_PauseBackdrop_Shader.gdshader"
const RED := Color(0.86, 0.12, 0.1)
var _fx_t: float = -1.0
var _fx_back: ColorRect = null
var _fx_mat: ShaderMaterial = null
var _fx_flash: ColorRect = null
var _fx_vig: ColorRect = null
var _fx_vig_mat: ShaderMaterial = null
var _fx_ecg: Control = null
var _fx_ash: CPUParticles2D = null
var _fx_ghosts: Array = []
var _label_base_pos: Vector2 = Vector2.ZERO
var _label_base_scale: Vector2 = Vector2.ONE

const VIG_SRC := """shader_type canvas_item;
uniform float power = 0.0;
void fragment() {
	vec2 cc = UV - 0.5;
	float d = length(cc * vec2(1.3, 1.0));
	float v = smoothstep(0.25, 0.85, d);
	COLOR = vec4(0.55, 0.0, 0.02, v * power);
}
"""

func _build_fx() -> void:
	var vp = Vector2(1152, 648)
	if death_label:
		var centre = death_label.position + death_label.pivot_offset + (death_label.size * 0.5 - death_label.pivot_offset) * death_label.scale
		death_label.pivot_offset = death_label.size * 0.5
		death_label.position = centre - death_label.size * 0.5
		_label_base_pos = death_label.position + Vector2(0, 8)
		_label_base_scale = death_label.scale * 1.3
		death_label.add_theme_color_override("font_color", Color(0.95, 0.2, 0.16))
		death_label.add_theme_color_override("font_outline_color", Color(0.08, 0.0, 0.0))
		death_label.add_theme_constant_override("outline_size", 3)
		for col in [Color(0.2, 0.9, 1.0, 0.0), Color(1.0, 0.1, 0.4, 0.0)]:
			var g = death_label.duplicate(0) as Label
			g.add_theme_color_override("font_color", col)
			g.add_theme_constant_override("outline_size", 0)
			g.modulate = Color(1, 1, 1, 0)
			add_child(g)
			move_child(g, death_label.get_index())
			_fx_ghosts.append(g)
	var sh = load(BACKDROP_SHADER) if ResourceLoader.exists(BACKDROP_SHADER) else null
	if sh:
		_fx_back = ColorRect.new()
		_fx_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fx_back.size = vp
		_fx_mat = ShaderMaterial.new()
		_fx_mat.shader = sh
		_fx_mat.set_shader_parameter("tint", Color(1.0, 0.3, 0.25))
		_fx_mat.set_shader_parameter("amount", 0.0)
		_fx_mat.set_shader_parameter("blur_px", 3.0)
		_fx_back.material = _fx_mat
		add_child(_fx_back)
		move_child(_fx_back, 0)
	_fx_vig = ColorRect.new()
	_fx_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_vig.size = vp
	var vs = Shader.new()
	vs.code = VIG_SRC
	_fx_vig_mat = ShaderMaterial.new()
	_fx_vig_mat.shader = vs
	_fx_vig.material = _fx_vig_mat
	add_child(_fx_vig)
	if background:
		move_child(_fx_vig, background.get_index() + 1)
	_fx_ash = CPUParticles2D.new()
	var img = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_fx_ash.texture = ImageTexture.create_from_image(img)
	_fx_ash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fx_ash.amount = 50
	_fx_ash.lifetime = 6.0
	_fx_ash.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_fx_ash.emission_rect_extents = Vector2(620, 10)
	_fx_ash.position = Vector2(576, -10)
	_fx_ash.direction = Vector2(0.2, 1)
	_fx_ash.spread = 25.0
	_fx_ash.gravity = Vector2(0, 6)
	_fx_ash.initial_velocity_min = 20.0
	_fx_ash.initial_velocity_max = 55.0
	_fx_ash.scale_amount_min = 1.0
	_fx_ash.scale_amount_max = 2.0
	var g2 = Gradient.new()
	g2.set_color(0, Color(0.6, 0.55, 0.55, 0.0))
	g2.add_point(0.2, Color(0.75, 0.7, 0.7, 0.55))
	g2.add_point(0.6, Color(1.0, 0.35, 0.2, 0.5))
	g2.set_color(g2.get_point_count() - 1, Color(0.4, 0.1, 0.1, 0.0))
	_fx_ash.color_ramp = g2
	_fx_ash.emitting = false
	add_child(_fx_ash)
	if background:
		move_child(_fx_ash, background.get_index() + 2)
	_fx_ecg = Control.new()
	_fx_ecg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_ecg.size = vp
	_fx_ecg.draw.connect(_draw_ecg)
	add_child(_fx_ecg)
	if background:
		move_child(_fx_ecg, background.get_index() + 3)
	_fx_flash = ColorRect.new()
	_fx_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_flash.size = vp
	_fx_flash.color = Color(1.0, 0.25, 0.2, 0.0)
	add_child(_fx_flash)
	_style_buttons()

var _sub: Label = null
var _btn_base: Dictionary = {}

func _fill_sub() -> void:
	if _sub == null:
		return
	var sc = get_tree().current_scene
	var parts: Array = []
	if sc and "current_shift" in sc:
		parts.append(tr("СМЕНА ") + str(sc.current_shift))
	if sc and "_clock_text" in sc and String(sc._clock_text) != "":
		parts.append(String(sc._clock_text))
	_sub.text = "  ·  ".join(parts)
	_sub.modulate.a = 0.0

func _style_buttons() -> void:
	var f = death_label.get_theme_font("font") if death_label else null
	var ys = [318.0, 382.0, 446.0]
	var i := 0
	for b in [restart_button, menu_button, quit_button]:
		if b == null:
			continue
		b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(300, 50)
		b.position = Vector2(576 - 150, ys[i])
		b.pivot_offset = b.size * 0.5
		_btn_base[b] = b.position
		var looks = {"normal": [Color(0.07, 0.02, 0.02, 0.92), Color(0.4, 0.07, 0.05)],
			"hover": [Color(0.24, 0.04, 0.03, 0.96), Color(1.0, 0.32, 0.22)],
			"pressed": [Color(0.4, 0.06, 0.04, 1.0), Color(1.0, 0.5, 0.4)]}
		for k in looks.keys():
			var sb = StyleBoxFlat.new()
			sb.bg_color = looks[k][0]
			sb.border_color = looks[k][1]
			sb.set_border_width_all(2)
			sb.border_width_left = 6 if k != "normal" else 2
			sb.shadow_color = Color(0, 0, 0, 0.5)
			sb.shadow_size = 4
			sb.shadow_offset = Vector2(0, 3)
			b.add_theme_stylebox_override(k, sb)
		b.add_theme_stylebox_override("hover_pressed", b.get_theme_stylebox("pressed"))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		if f:
			b.add_theme_font_override("font", f)
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", Color(0.92, 0.8, 0.76))
		b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		b.add_theme_color_override("font_pressed_color", Color(1, 0.9, 0.85))
		b.add_theme_color_override("font_hover_pressed_color", Color(1, 0.9, 0.85))
		b.mouse_entered.connect(func():
			var tw = b.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(b, "scale", Vector2(1.04, 1.04), 0.08))
		b.mouse_exited.connect(func():
			var tw = b.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(b, "scale", Vector2.ONE, 0.1))
		i += 1
	_sub = Label.new()
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.size = Vector2(600, 24)
	_sub.position = Vector2(576 - 300, 196)
	if f:
		_sub.add_theme_font_override("font", f)
	_sub.add_theme_font_size_override("font_size", 16)
	_sub.add_theme_color_override("font_color", Color(0.85, 0.55, 0.5))
	_sub.add_theme_color_override("font_outline_color", Color(0.05, 0, 0))
	_sub.add_theme_constant_override("outline_size", 4)
	_sub.modulate.a = 0.0
	add_child(_sub)
	for k in range(2):
		var rule = ColorRect.new()
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rule.color = Color(0.85, 0.15, 0.12, 0.8) if k == 0 else Color(0.85, 0.15, 0.12, 0.25)
		rule.size = Vector2(420 if k == 0 else 520, 2)
		rule.position = Vector2(576 - rule.size.x * 0.5, 180 + k * 4)
		_sub.add_child(rule)
		rule.position -= _sub.position
	var fr = get_node_or_null("Framing") as CanvasItem
	if fr:
		fr.modulate = Color(0.6, 0.2, 0.17)

func _fx_start() -> void:
	_fx_t = 0.0
	if _fx_flash:
		_fx_flash.color.a = 0.75
	if _fx_ash:
		_fx_ash.emitting = true
		_fx_ash.restart()
	if death_label:
		death_label.scale = _label_base_scale * 2.2

func _fx_process(delta: float) -> void:
	if _fx_t < 0.0:
		return
	_fx_t += delta
	var t = _fx_t
	if _fx_flash:
		_fx_flash.color.a = max(0.0, 0.75 - t * 2.2)
	if _fx_mat:
		_fx_mat.set_shader_parameter("amount", clamp(t / 0.8, 0.0, 1.0))
	if _fx_vig_mat:
		var beat = 0.0
		for b in [[0.15, 1.0], [0.42, 0.7], [1.15, 0.8], [1.42, 0.5], [2.3, 0.35]]:
			var k = t - b[0]
			if k > 0.0:
				beat = max(beat, b[1] * exp(-k * 7.0))
		_fx_vig_mat.set_shader_parameter("power", clamp(0.35 + 0.65 * beat, 0.0, 1.0) * clamp(t / 0.3, 0.0, 1.0))
	if death_label and state >= 1:
		var k2 = clamp(appear_timer / 0.35, 0.0, 1.0)
		var e = 1.0 - pow(1.0 - k2, 3.0)
		death_label.scale = _label_base_scale * lerp(2.2, 1.0, e)
		var glitch = (k2 < 1.0) or (fmod(t, 2.6) < 0.12)
		var off = Vector2(randf_range(3.0, 7.0), 0) if glitch else Vector2(1.5, 0)
		var jitter = Vector2(randf_range(-2, 2), 0) if glitch else Vector2.ZERO
		death_label.position = _label_base_pos + jitter
		for i in range(_fx_ghosts.size()):
			var gl: Label = _fx_ghosts[i]
			gl.scale = death_label.scale
			gl.pivot_offset = death_label.pivot_offset
			gl.position = death_label.position + (off if i == 0 else -off)
			gl.modulate.a = death_label.modulate.a * (0.55 if glitch else 0.25)
	if _fx_ecg:
		_fx_ecg.queue_redraw()

func _draw_ecg() -> void:
	if _fx_t < 0.0:
		return
	var c = _fx_ecg
	var y0 = 262.0
	var x0 = 140.0
	var x1 = 1012.0
	var speed = 520.0
	var head = x0 + _fx_t * speed
	var span = x1 - x0
	var pulses = [[0.12, 1.0], [0.33, 0.75], [0.62, 0.45], [0.86, 0.15]]
	var pts = PackedVector2Array()
	var end_x = min(head, x1)
	var x = x0
	while x <= end_x:
		var u = (x - x0) / span
		var y = y0
		for p in pulses:
			var d = (u - p[0]) * span
			if absf(d) < 22.0:
				if d < -8.0:
					y -= (d + 22.0) * 0.5 * p[1]
				elif d < 4.0:
					y += -7.0 * p[1] + (d + 8.0) * 5.0 * p[1]
				else:
					y += (22.0 - d) * 3.0 * p[1] - 6.0 * p[1]
		pts.append(Vector2(x, round(y0 - (y - y0))))
		x += 3.0
	if pts.size() >= 2:
		var fade = clamp(1.0 - (_fx_t - 2.4) / 1.5, 0.35, 1.0)
		c.draw_polyline(pts, Color(RED, 0.35 * fade), 6.0)
		c.draw_polyline(pts, Color(1.0, 0.35, 0.3, 0.95 * fade), 2.0)
		if head < x1:
			c.draw_circle(pts[pts.size() - 1], 4.0, Color(1.0, 0.8, 0.7, 0.9))
