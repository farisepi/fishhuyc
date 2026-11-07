extends CanvasLayer
## Factory tutorial "flashlight": everything goes dark except a soft round spot of light on
## what is being explained, plus a card with the explanation next to the spot.
##   spot.show_step("ДВИЖЕНИЕ", "Ты очнулся...", ["A", "D", "ПРОБЕЛ"], func(): return rect)
## The target callable returns a Rect2 in screen (UI) pixels every frame, so the light follows
## moving things. Runs while the tree is paused (the tutorial stops time).

signal key_event(ev: InputEvent)

const FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
const SCREEN := Vector2(1152, 648)
const CARD_W := 340.0
const TITLE_SIZE := 16
const BODY_SIZE := 13
const KEY_SIZE := 13

const SHADER_SRC := """shader_type canvas_item;
uniform vec2 screen = vec2(1152.0, 648.0);
uniform vec2 hole_c = vec2(576.0, 324.0);
uniform vec2 hole_r = vec2(80.0, 80.0);
uniform float dark = 0.0;
uniform float flick = 1.0;
void fragment() {
	vec2 p = floor(UV * screen / 3.0) * 3.0 + 1.5;   // chunky pixels, like the art
	vec2 q = (p - hole_c) / max(hole_r, vec2(1.0));
	float d = length(q);
	float a = smoothstep(0.9, 1.25, d);
	a = floor(a * 6.0 + 0.5) / 6.0;                  // stepped falloff
	// darkness outside, a warm rim of light around the spot
	vec3 warm = vec3(1.0, 0.8, 0.45);
	float ring = 1.0 - smoothstep(0.0, 0.06, abs(d - 0.97));
	ring = floor(ring * 3.0 + 0.5) / 3.0;
	COLOR.rgb = mix(vec3(0.0, 0.0, 0.02), warm, ring);
	COLOR.a = max(a * dark * flick, ring * 0.45 * dark);
}
"""

var _veil: ColorRect = null
var _mat: ShaderMaterial = null
var _card: Control = null
var _title: Label = null
var _body: Label = null
var _font: FontFile = null
var _keys: Array = []
var _target: Callable = Callable()
var _hole_c := SCREEN * 0.5
var _hole_r := Vector2(900, 900)
var _dark := 0.0
var _dark_to := 0.0
var _card_a := 0.0
var _card_to := 0.0
var _t := 0.0
var _progress := -1.0      # 0..1 bar at the bottom of the card (timed steps), <0 = none
var _done_t := -1.0
var _tag := "ОБУЧЕНИЕ"
var dim_outside := true    # false: only the card, no darkness (the minigame needs the view)


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = ResourceLoader.load(FONT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
	if _font:
		_font.fixed_size = 0
	_veil = ColorRect.new()
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.size = SCREEN
	var sh = Shader.new()
	sh.code = SHADER_SRC
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_veil.material = _mat
	add_child(_veil)
	_card = Control.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.draw.connect(_draw_card)
	add_child(_card)
	_title = _label(TITLE_SIZE)
	_card.add_child(_title)
	_body = _label(BODY_SIZE)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card.add_child(_body)
	_card.visible = false
	_veil.visible = false


func _label(size: int) -> Label:
	var l = Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _font:
		l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
	l.add_theme_constant_override("outline_size", 3)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return l


## Shows a step. keys: texts of the key caps ("A", "ПРОБЕЛ", ...).
func show_step(title: String, body: String, keys: Array, target: Callable, dim: bool = true) -> void:
	_target = target
	dim_outside = dim
	_keys = keys.duplicate()
	_title.text = title
	_body.text = body.replace("-", "-⁠")
	_progress = -1.0
	_done_t = -1.0
	_tag = "ОБУЧЕНИЕ"
	_dark_to = 0.82 if dim else 0.0
	_card_to = 1.0
	_layout_card()
	_card.visible = true
	_veil.visible = true
	if _card_a <= 0.01:
		_card.scale = Vector2(0.92, 0.92)
	if has_node("/root/UISounds"):
		get_node("/root/UISounds").play_switch_on()


func set_target(target: Callable) -> void:
	_target = target


func set_text(title: String, body: String, keys: Array = []) -> void:
	_title.text = title
	_body.text = body.replace("-", "-⁠")
	_keys = keys.duplicate()
	_layout_card()


func set_progress(v: float) -> void:
	_progress = v


## A green "ГОТОВО" for a moment.
func done() -> void:
	_done_t = 0.0
	_tag = "ГОТОВО"
	if has_node("/root/UISounds"):
		get_node("/root/UISounds").play_click()


func hide_step() -> void:
	_dark_to = 0.0
	_card_to = 0.0
	_target = Callable()


func is_shown() -> bool:
	return _card_to > 0.0


func _layout_card() -> void:
	var keys_w = 0.0
	for k in _keys:
		keys_w += _cap_w(k) + 4.0
	var title_w = 0.0
	if _font:
		title_w = _font.get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE).x
	var w = clamp(max(CARD_W, title_w + 40.0, keys_w + 40.0), CARD_W, 520.0)
	_title.position = Vector2(16, 22)
	_title.size = Vector2(w - 30, 22)
	_body.position = Vector2(16, 46)
	_body.size = Vector2(w - 30, 0)
	_body.size = Vector2(w - 30, 0)
	var hb = 20.0
	if _font:
		# measured with the font itself (the label may not be laid out yet), with some slack
		var ms = _font.get_multiline_string_size(_body.text, HORIZONTAL_ALIGNMENT_LEFT, w - 36.0, BODY_SIZE)
		var lines = max(1, int(round(ms.y / max(1.0, _font.get_height(BODY_SIZE)))))
		hb = lines * (_font.get_height(BODY_SIZE) + 2.0) + 8.0
	_body.size = Vector2(w - 30, hb)
	var hk = 30.0 if not _keys.is_empty() else 0.0
	_card.size = Vector2(w, 52.0 + hb + hk + 10.0)
	_card.pivot_offset = _card.size * 0.5
	_title.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94))
	_body.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))


func _cap_w(k: String) -> float:
	var w = 24.0
	if _font:
		w = max(24.0, _font.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_SIZE).x + 14.0)
	return w


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed() and not event.is_echo():
			key_event.emit(event)


func _process(delta: float) -> void:
	var dt = min(delta, 0.05)
	_t += dt
	if _done_t >= 0.0:
		_done_t += dt
	_dark = move_toward(_dark, _dark_to, dt * 2.4)
	_card_a = move_toward(_card_a, _card_to, dt * 4.0)
	var want_c = SCREEN * 0.5
	var want_r = Vector2(900, 900)
	if _target.is_valid():
		var r = _target.call()
		if r is Rect2:
			want_c = r.get_center()
			want_r = r.size * 0.5 * 1.25 + Vector2(26, 26)
	_hole_c = _hole_c.lerp(want_c, 1.0 - exp(-10.0 * dt))
	_hole_r = _hole_r.lerp(want_r, 1.0 - exp(-8.0 * dt))
	if _mat:
		_mat.set_shader_parameter("hole_c", _hole_c)
		_mat.set_shader_parameter("hole_r", _hole_r)
		_mat.set_shader_parameter("dark", _dark)
		# the light trembles a little, like a real flashlight
		_mat.set_shader_parameter("flick", 0.97 + 0.03 * sin(_t * 23.0) * sin(_t * 7.0))
	_veil.visible = _dark > 0.005
	_card.visible = _card_a > 0.01
	if _card.visible:
		_place_card()
		_card.modulate.a = _card_a
		_card.scale = _card.scale.lerp(Vector2.ONE, 1.0 - exp(-14.0 * dt))
		_card.queue_redraw()


## The card goes under the spot if there is room, else over it; it never covers the spot.
func _place_card() -> void:
	var sz = _card.size
	var x = clamp(_hole_c.x - sz.x * 0.5, 14.0, SCREEN.x - sz.x - 14.0)
	var below = _hole_c.y + _hole_r.y + 14.0
	var above = _hole_c.y - _hole_r.y - 14.0 - sz.y
	var y: float
	if below + sz.y < SCREEN.y - 10.0:
		y = below
	elif above > 10.0:
		y = above
	else:
		# no room above or below: beside it
		y = clamp(_hole_c.y - sz.y * 0.5, 10.0, SCREEN.y - sz.y - 10.0)
		if _hole_c.x > SCREEN.x * 0.5:
			x = clamp(_hole_c.x - _hole_r.x - sz.x - 14.0, 14.0, SCREEN.x - sz.x - 14.0)
		else:
			x = clamp(_hole_c.x + _hole_r.x + 14.0, 14.0, SCREEN.x - sz.x - 14.0)
	_card.position = Vector2(round(x), round(y + sin(_t * 2.2) * 1.5))


func _draw_card() -> void:
	var c = _card
	var sz = c.size
	var accent = Color8(255, 168, 60)
	var good = Color8(120, 230, 120)
	var ok = _done_t >= 0.0
	var edge = good if ok else accent
	c.draw_rect(Rect2(Vector2(3, 4), sz), Color(0, 0, 0, 0.5))
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color8(8, 9, 12))
	c.draw_rect(Rect2(2, 2, sz.x - 4, sz.y - 4), Color8(46, 50, 60))
	c.draw_rect(Rect2(2, 2, sz.x - 4, 1), Color8(110, 116, 130))
	c.draw_rect(Rect2(3, 3, sz.x - 6, sz.y - 6), Color8(20, 22, 28))
	# hazard stripe on top
	var x := 3.0
	var k := 0
	while x < sz.x - 3.0:
		var w = min(6.0, sz.x - 3.0 - x)
		c.draw_rect(Rect2(x, 3, w, 3), edge if k % 2 == 0 else Color8(30, 24, 16))
		x += 6.0
		k += 1
	if ok:
		var fl = 1.0 - clamp(_done_t / 0.4, 0.0, 1.0)
		c.draw_rect(Rect2(3, 6, sz.x - 6, sz.y - 9), Color(good, 0.2 * fl))
	if _font:
		c.draw_string(_font, Vector2(16, 18), _tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(edge, 0.95))
	# key caps at the bottom
	if not _keys.is_empty():
		var kx = 16.0
		var ky = sz.y - 36.0
		var press = fmod(_t, 1.2) > 0.95
		for key in _keys:
			var kw = _cap_w(key)
			var dip = 2.0 if press else 0.0
			c.draw_rect(Rect2(kx, ky + 2.0, kw, 22.0), Color.BLACK)
			c.draw_rect(Rect2(kx, ky + dip, kw, 20.0), Color8(200, 204, 214))
			c.draw_rect(Rect2(kx + 1, ky + 1.0 + dip, kw - 2, 15.0), Color8(244, 246, 252))
			if _font:
				var tw = _font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_SIZE).x
				c.draw_string(_font, Vector2(kx + (kw - tw) * 0.5, ky + 14.0 + dip), key, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_SIZE, Color8(28, 30, 38))
			kx += kw + 4.0
	# time bar
	if _progress >= 0.0:
		c.draw_rect(Rect2(3, sz.y - 6, sz.x - 6, 3), Color8(36, 40, 50))
		c.draw_rect(Rect2(3, sz.y - 6, (sz.x - 6) * clamp(_progress, 0.0, 1.0), 3), edge)
