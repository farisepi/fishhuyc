extends CanvasLayer

signal key_event(ev: InputEvent)

const FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
const SCREEN := Vector2(1152, 648)
const CARD_W := 400.0
const TITLE_SIZE := 16
const BODY_SIZE := 15
const KEY_SIZE := 13

const SHADER_SRC := """shader_type canvas_item;
uniform vec2 screen = vec2(1152.0, 648.0);
uniform vec2 hole_c = vec2(576.0, 324.0);
uniform vec2 hole_r = vec2(80.0, 80.0);
uniform float dark = 0.0;
uniform float flick = 1.0;
uniform float t = 0.0;
float hash(vec2 v) { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 px = floor(UV * screen / 3.0);
	vec2 p = px * 3.0 + 1.5;
	vec2 r = max(hole_r, vec2(1.0));
	float d = length((p - hole_c) / r);
	float spot = 1.0 - smoothstep(0.55, 1.15, d);
	vec2 src = vec2(mix(hole_c.x, screen.x * 0.5, 0.35), -90.0);
	vec2 axis = hole_c - src;
	float len_a = max(length(axis), 1.0);
	vec2 dir = axis / len_a;
	float along = dot(p - src, dir) / len_a;
	float side = abs(dot(p - src, vec2(-dir.y, dir.x)));
	float width = mix(10.0, r.x * 0.95, clamp(along, 0.0, 1.0));
	float beam = (1.0 - smoothstep(width * 0.7, width * 1.05, side)) * smoothstep(0.0, 0.25, along) * (1.0 - smoothstep(0.92, 1.05, along));
	float rays = 0.75 + 0.25 * sin(side / max(width, 1.0) * 9.0 + t * 0.7);
	beam *= 0.55 * rays;
	float light = clamp(max(spot, beam), 0.0, 1.0);
	light = floor(light * 7.0 + 0.5) / 7.0;
	vec2 cell = floor((p + vec2(t * 7.0, -t * 11.0)) / 9.0);
	float h = hash(cell);
	float dust = step(0.985, h) * (0.5 + 0.5 * sin(t * 3.0 + h * 40.0)) * light;
	float a_dark = clamp((1.0 - light) * 0.92, 0.0, 1.0) * dark * flick;
	float a_warm = (light * (0.07 + 0.16 * spot) + beam * 0.12) * dark + dust * 0.6 * dark;
	vec3 warm = vec3(1.0, 0.82, 0.5);
	vec3 shade = vec3(0.01, 0.012, 0.03);
	float a = clamp(a_dark + a_warm, 0.0, 1.0);
	COLOR.rgb = mix(shade, warm, a_warm / max(a, 0.0001));
	COLOR.a = a;
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
var _progress := -1.0
var _done_t := -1.0
var _tag := tr("ОБУЧЕНИЕ")
var dim_outside := true
var block_check: Callable = Callable()
var avoid: Callable = Callable()
const DARK := 0.78
const EDGE_M := 16.0
var dock_beside: bool = false
var fixed_place: bool = true
const DOCK_GAP := 14.0
const DOCK_MAX_W := 420.0
const RIGHT_RESERVE := 40.0

func set_dock_beside(v: bool) -> void:
	dock_beside = v
	_slot = -1
	_locked = false
	_lock_t = 0.0
	_dock_side = 0
	_layout_card()


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


var skippable: bool = false

func show_step(title: String, body: String, keys: Array, target: Callable, dim: bool = true) -> void:
	_target = target
	dim_outside = dim
	_keys = keys.duplicate()
	skippable = false
	card_corner = false
	dock_beside = false
	_card_placed = false
	_slot = -1
	_bad_t = 0.0
	_step_t = 0.0
	_locked = false
	_lock_t = 0.0
	_dock_side = 0
	_title.text = title
	_body.text = body.replace("-", "-⁠")
	_progress = -1.0
	_done_t = -1.0
	_tag = tr("ОБУЧЕНИЕ")
	_dark_to = DARK if dim else 0.0
	_card_to = 1.0
	_layout_card()
	_card.visible = true
	_veil.visible = true
	if _card_a <= 0.01:
		_card.scale = Vector2(0.92, 0.92)
	if is_inside_tree() and has_node("/root/UISounds"):
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

var next_key: String = "E"

func set_skippable(v: bool) -> void:
	if skippable != v:
		skippable = v
		_layout_card()


func done() -> void:
	_done_t = 0.0
	_tag = tr("ГОТОВО")
	if is_inside_tree() and has_node("/root/UISounds"):
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
	var base_w = CARD_W
	var n = _body.text.length()
	if n > 110:
		base_w = 460.0
	if n > 220:
		base_w = 600.0
	var w = clamp(max(base_w, title_w + 40.0, keys_w + 40.0), CARD_W, 640.0)
	if dock_beside:
		w = clamp(max(base_w, title_w + 40.0, keys_w + 40.0), CARD_W, DOCK_MAX_W)
		if _target.is_valid():
			var tr_ = _target.call()
			if tr_ is Rect2:
				var room = SCREEN.x - EDGE_M - RIGHT_RESERVE - (tr_.end.x + DOCK_GAP)
				w = clamp(room, 240.0, w)
	_title.position = Vector2(16, 22)
	_title.size = Vector2(w - 30, 22)
	_body.position = Vector2(16, 46)
	_body.size = Vector2(w - 30, 0)
	_body.size = Vector2(w - 30, 0)
	var hb = 20.0
	if _font:
		var ms = _font.get_multiline_string_size(_body.text, HORIZONTAL_ALIGNMENT_LEFT, w - 36.0, BODY_SIZE)
		var lines = max(1, int(round(ms.y / max(1.0, _font.get_height(BODY_SIZE)))))
		hb = lines * (_font.get_height(BODY_SIZE) + 2.0) + 8.0
	_body.size = Vector2(w - 30, hb)
	var hk = 30.0 if not _keys.is_empty() else 0.0
	_card.size = Vector2(w, 52.0 + hb + hk + 10.0 + (14.0 if skippable else 0.0))
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


var _last_us: int = 0
var _last_dt: float = 0.016
var _card_placed: bool = false
var _step_t: float = 0.0
var _card_xy: Vector2 = Vector2.ZERO
var card_corner: bool = false

func _process(_delta: float) -> void:
	var blocked = block_check.is_valid() and block_check.call()
	visible = not blocked
	if blocked:
		return
	var now = Time.get_ticks_usec()
	var dt = 0.016 if _last_us == 0 else clamp((now - _last_us) / 1000000.0, 0.0, 0.05)
	_last_us = now
	_last_dt = dt
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
		_mat.set_shader_parameter("t", _t)
		_mat.set_shader_parameter("flick", 1.0)
	_veil.visible = _dark > 0.005
	_card.visible = _card_a > 0.01
	if _card.visible:
		_place_card()
		_card.modulate.a = _card_a
		_card.scale = _card.scale.lerp(Vector2.ONE, 1.0 - exp(-14.0 * dt))
		_card.queue_redraw()


func _slots(sz: Vector2) -> Array:
	var W = SCREEN.x
	var H = SCREEN.y
	return [
		Vector2((W - sz.x) * 0.5, H - sz.y - 18.0),
		Vector2(EDGE_M, H - sz.y - 18.0),
		Vector2(W - sz.x - EDGE_M, H - sz.y - 18.0),
		Vector2((W - sz.x) * 0.5, 14.0),
		Vector2(EDGE_M, (H - sz.y) * 0.5),
		Vector2(W - sz.x - EDGE_M, (H - sz.y) * 0.5),
	]

func _overlap(a: Rect2, b: Rect2) -> float:
	var i = a.intersection(b)
	return i.get_area() if a.intersects(b) else 0.0

func _slot_cost(pos: Vector2, sz: Vector2, idx: int) -> float:
	var r = Rect2(pos, sz).grow(6.0)
	var light = Rect2(_hole_c - _hole_r, _hole_r * 2.0)
	var c = _overlap(r, light) * 10.0
	if avoid.is_valid():
		for a in avoid.call():
			if a is Rect2 and a.size.x > 0.0:
				c += _overlap(r, a) * 10.0
	return c + idx * 50.0

var _slot: int = -1
var _dock_anchor: Vector2 = Vector2.ZERO
var _bad_t: float = 0.0
var _locked: bool = false
var _dock_side: int = 0
var _lock_t: float = 0.0

func _dock_pos(sz: Vector2):
	if not _target.is_valid():
		return null
	var t = _target.call()
	if not (t is Rect2):
		return null
	var x = t.end.x + DOCK_GAP
	if _dock_side == 0:
		_dock_side = 1
		if x + sz.x > SCREEN.x - EDGE_M - RIGHT_RESERVE + 1.0:
			_dock_side = -1
			if t.position.x - DOCK_GAP - sz.x < EDGE_M:
				_dock_side = 0
				return null
	if _dock_side < 0:
		x = t.position.x - DOCK_GAP - sz.x
	x = clamp(x, EDGE_M, SCREEN.x - EDGE_M - sz.x)
	var y = clamp(t.position.y, 14.0, SCREEN.y - sz.y - 14.0)
	if x + sz.x > SCREEN.x - 300.0:
		y = max(y, 150.0)
	return Vector2(x, y)

func _place_card() -> void:
	var sz = _card.size
	if _card_to <= 0.0 and _slot != -1:
		return
	_lock_t += _last_dt
	if _locked:
		if _slot != 99 and fixed_place:
			_card_xy.x = (SCREEN.x - sz.x) * 0.5
		_card.position = Vector2(round(_card_xy.x), round(_card_xy.y))
		return
	if dock_beside:
		var d = _dock_pos(sz)
		if d != null or _slot == 99:
			if d != null:
				if _slot != 99:
					_card_xy = d + Vector2(12.0 * float(_dock_side), 0.0)
					_dock_anchor = _card_xy
					_slot = 99
					_locked = true
					_card.position = Vector2(round(_card_xy.x), round(_card_xy.y))
					return
				_dock_anchor = d
			_slot = 99
			_card_xy = _card_xy.lerp(_dock_anchor, 1.0 - exp(-14.0 * _last_dt))
			_card.position = Vector2(round(_card_xy.x), round(_card_xy.y))
			if _lock_t > 0.35:
				_card_xy = _dock_anchor
				_locked = true
			return
	var slots = _slots(sz)
	var want: int
	if fixed_place:
		want = 3
	else:
		var best = 0
		var best_c = INF
		for i in range(slots.size()):
			var c = _slot_cost(slots[i], sz, i)
			if c < best_c:
				best_c = c
				best = i
		want = best
		_step_t += _last_dt
		if _slot >= 0 and _card_placed:
			if want != _slot and _slot_cost(slots[_slot], sz, 0) > 400.0:
				_bad_t += _last_dt
			else:
				_bad_t = 0.0
			if _bad_t < 0.4:
				want = _slot
		if _step_t > 0.45:
			_card_placed = true
	var first = _slot < 0 or _slot == 99
	_slot = want
	var target = slots[want]
	if first:
		_card_xy = target
	else:
		_card_xy = _card_xy.lerp(target, 1.0 - exp(-10.0 * _last_dt))
	if fixed_place and (first or _lock_t > 0.35):
		_card_xy = target
		_locked = true
	_card.position = Vector2(round(_card_xy.x), round(_card_xy.y))

func card_rect() -> Rect2:
	if _card == null or not _card.visible:
		return Rect2()
	return Rect2(_card.position, _card.size)


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
	if skippable and not ok and _font:
		var nx = tr("%s — ДАЛЬШЕ") % next_key
		var nw = _font.get_string_size(nx, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var a2 = 0.6 + 0.4 * sin(_t * 3.0)
		c.draw_rect(Rect2(sz.x - nw - 22.0, sz.y - 22.0, nw + 14.0, 16.0), Color(0.06, 0.07, 0.1, 0.9))
		c.draw_string(_font, Vector2(sz.x - nw - 15.0, sz.y - 10.0), nx, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.95, 0.85, 0.55, a2))
	if false:
		var k2 = 0.5 + 0.5 * sin(_t * 4.0)
		var o = Vector2(sz.x - 36.0, sz.y + 4.0)
		c.draw_rect(Rect2(o + Vector2(0, 2), Vector2(34, 14)), Color(0.06, 0.07, 0.1, 0.9))
		c.draw_rect(Rect2(o + Vector2(2, 0), Vector2(30, 12)), Color(0.06, 0.07, 0.1))
		c.draw_rect(Rect2(o + Vector2(4, 2), Vector2(26, 8)), Color(0.93, 0.94, 0.96))
		c.draw_rect(Rect2(o + Vector2(4, 8), Vector2(26, 2)), Color(0.7, 0.72, 0.78))
		var ink = Color(0.2, 0.24, 0.32).lerp(Color(0.1, 0.45, 0.7), k2)
		c.draw_rect(Rect2(o + Vector2(10, 4), Vector2(2, 4)), ink)
		c.draw_rect(Rect2(o + Vector2(22, 4), Vector2(2, 4)), ink)
		c.draw_rect(Rect2(o + Vector2(10, 6), Vector2(14, 2)), ink)
	if _progress >= 0.0:
		c.draw_rect(Rect2(3, sz.y - 6, sz.x - 6, 3), Color8(36, 40, 50))
		c.draw_rect(Rect2(3, sz.y - 6, (sz.x - 6) * clamp(_progress, 0.0, 1.0), 3), edge)
