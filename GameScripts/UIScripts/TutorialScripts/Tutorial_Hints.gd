extends CanvasLayer
## Small contextual tutorial hints (one at a time, bottom of the screen). Each hint is shown
## once (remembered in user://tutorial.cfg), stays at least `min_time`, and goes away when its
## condition is met (or after `max_time`). Two looks: "factory" (steel + hazard stripe) and
## "aquarium" (deep blue glass).
##   hints.hint("move", "ХОДИТЬ И ПРЫГАТЬ", ["ui_left", "ui_right", "jump"], func(): return moved)

const FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
const SAVE_PATH := "user://tutorial.cfg"
const W_MAX := 560.0

var style := "factory"
var _queue: Array = []
var _cur: Dictionary = {}
var _t := 0.0
var _done_t := -1.0
var _panel: Control = null
var _label: Label = null
var _title: Label = null
var _font: FontFile = null
var _cfg := ConfigFile.new()
var _keys: Array = []          # key cap texts of the current hint
var _key_w := 0.0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cfg.load(SAVE_PATH)
	_font = ResourceLoader.load(FONT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
	if _font:
		_font.fixed_size = 0
	_panel = Control.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	_panel.draw.connect(_draw_panel)
	add_child(_panel)
	_title = _make_label(12)
	_panel.add_child(_title)
	_label = _make_label(16)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_label)


func _make_label(size: int) -> Label:
	var l = Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _font:
		l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 2)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return l


func seen(id: String) -> bool:
	return bool(_cfg.get_value("seen", id, false))


## Queue a hint (ignored if it was already shown once).
func hint(id: String, text: String, keys: Array = [], done: Callable = Callable(), min_time: float = 2.2, max_time: float = 10.0) -> void:
	if seen(id) or (_cur.get("id", "") == id):
		return
	for q in _queue:
		if q["id"] == id:
			return
	_queue.append({"id": id, "text": text, "keys": keys, "done": done, "min": min_time, "max": max_time})


## Close the current hint early if it is this one (e.g. the situation is over).
func dismiss(id: String) -> void:
	if _cur.get("id", "") == id and _done_t < 0.0:
		_done_t = 0.0
	for q in _queue.duplicate():
		if q["id"] == id:
			_queue.erase(q)


func _process(delta: float) -> void:
	var dt = delta / max(0.05, Engine.time_scale)   # real time, also in slow motion
	if get_tree().paused:
		_panel.modulate.a = 0.0
		return
	if _cur.is_empty():
		if _queue.is_empty():
			return
		_start(_queue.pop_front())
		return
	_t += dt
	if _done_t < 0.0:
		var ok = false
		var cond: Callable = _cur["done"]
		if cond.is_valid():
			ok = bool(cond.call())
		if (ok and _t >= _cur["min"]) or _t >= _cur["max"]:
			_done_t = 0.0
			_cur["ok"] = ok
	else:
		_done_t += dt
		if _done_t >= 0.55:
			_cur = {}
			_panel.visible = false
			return
	# slide in, hold, slide out
	var a_in = clamp(_t / 0.25, 0.0, 1.0)
	var a_out = 1.0 - clamp(_done_t / 0.45, 0.0, 1.0) if _done_t >= 0.0 else 1.0
	var e = 1.0 - pow(1.0 - a_in, 3.0)
	_panel.modulate.a = e * a_out
	var vp = get_viewport().get_visible_rect().size
	var slide = (1.0 - e) * 14.0 + (1.0 - a_out) * 10.0
	if style == "aquarium":
		# the lab with the two people is at the bottom of the aquarium screen: hints go on top
		_panel.position = Vector2(round((vp.x - _panel.size.x) * 0.5), round(22.0 - slide))
	else:
		_panel.position = Vector2(round((vp.x - _panel.size.x) * 0.5), round(vp.y - _panel.size.y - 26.0 + slide))
	_panel.queue_redraw()


func _start(h: Dictionary) -> void:
	_cur = h
	_t = 0.0
	_done_t = -1.0
	_cfg.set_value("seen", h["id"], true)
	_cfg.save(SAVE_PATH)
	_keys.clear()
	for k in h["keys"]:
		_keys.append(_key_text(k))
	_title.text = "ПОДСКАЗКА" if style == "factory" else "ПОДСКАЗКА"
	_label.text = h["text"]
	# size: key caps on the left, text on the right
	_key_w = 0.0
	for k in _keys:
		_key_w += _cap_w(k) + 6.0
	if _key_w > 0.0:
		_key_w += 8.0
	var tw = 0.0
	if _font:
		tw = _font.get_string_size(h["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var text_w = clamp(tw + 6.0, 140.0, W_MAX - _key_w - 36.0)
	_label.position = Vector2(18.0 + _key_w, 24.0)
	_label.size = Vector2(text_w, 0)
	_label.size = Vector2(text_w, 0)
	var lines = max(1, _label.get_line_count())
	var text_h = lines * _label.get_line_height() + (lines - 1) * 2
	_panel.size = Vector2(18.0 + _key_w + text_w + 18.0, max(text_h + 36.0, 56.0))
	_title.position = Vector2(18.0, 6.0)
	_title.size = Vector2(_panel.size.x - 36.0, 14)
	var accent = _accent()
	_title.add_theme_color_override("font_color", accent)
	_label.add_theme_color_override("font_color", Color(0.93, 0.94, 0.96))
	_panel.visible = true
	_panel.modulate.a = 0.0
	if has_node("/root/UISounds"):
		get_node("/root/UISounds").play_switch_on()


func _accent() -> Color:
	return Color8(255, 168, 60) if style == "factory" else Color8(120, 220, 255)


func _key_text(k: String) -> String:
	if InputMap.has_action(k):
		var t = ""
		if has_node("/root/InputRebind"):
			t = get_node("/root/InputRebind").get_key_text(k)
		if t == "" or t == "Не назначено":
			for e in InputMap.action_get_events(k):
				if e is InputEventKey:
					t = OS.get_keycode_string(e.physical_keycode if e.keycode == 0 else e.keycode)
					break
		return {"Left": "←", "Right": "→", "Up": "↑", "Down": "↓", "Space": "ПРОБЕЛ", "Escape": "ESC"}.get(t, t)
	return k


func _cap_w(k: String) -> float:
	var w = 22.0
	if _font:
		w = max(22.0, _font.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 12.0)
	return w


func _draw_panel() -> void:
	var c = _panel
	var sz = c.size
	var accent = _accent()
	var t = Time.get_ticks_msec() / 1000.0
	if style == "factory":
		c.draw_rect(Rect2(Vector2.ZERO, sz), Color.BLACK)
		c.draw_rect(Rect2(2, 2, sz.x - 4, sz.y - 4), Color8(58, 62, 72))
		c.draw_rect(Rect2(2, 2, sz.x - 4, 2), Color8(104, 110, 124))
		c.draw_rect(Rect2(4, 4, sz.x - 8, sz.y - 8), Color8(22, 24, 30))
		# hazard stripe on the left edge
		for y in range(4, int(sz.y) - 4, 6):
			c.draw_rect(Rect2(4, y, 6, 3), accent if (y / 6) % 2 == 0 else Color8(30, 24, 16))
		for p in [Vector2(sz.x - 9, 7), Vector2(sz.x - 9, sz.y - 10)]:
			c.draw_rect(Rect2(p, Vector2(3, 3)), Color8(104, 110, 124))
	else:
		c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.01, 0.04, 0.09, 0.92))
		c.draw_rect(Rect2(1, 1, sz.x - 2, sz.y - 2), Color(accent, 0.55), false, 2.0)
		c.draw_rect(Rect2(4, 4, sz.x - 8, 3), Color(accent, 0.18))
		# little rising bubbles on the right
		for i in range(3):
			var by = sz.y - 6.0 - fmod(t * 14.0 + i * 11.0, sz.y - 10.0)
			c.draw_arc(Vector2(sz.x - 10 - i * 5, by), 1.5 + i * 0.5, 0, TAU, 8, Color(accent, 0.5), 1.0)
	# key caps
	var x = 18.0
	var cy = 24.0 + (_label.get_line_height() if _label else 16.0) * 0.5 + 1.0
	var press = int(t * 2.0) % 2 == 0
	for k in _keys:
		var w = _cap_w(k)
		var top = cy - 11.0 + (1.0 if press else 0.0)
		c.draw_rect(Rect2(x, cy - 11.0 + 3.0, w, 22.0), Color.BLACK)
		c.draw_rect(Rect2(x, top, w, 20.0), Color8(225, 228, 236))
		c.draw_rect(Rect2(x + 1, top + 1, w - 2, 15.0), Color8(250, 251, 255))
		if _font:
			c.draw_string(_font, Vector2(x + 6, top + 14.0), k, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(30, 32, 40))
		x += w + 6.0
	# progress / done check
	if _done_t >= 0.0 and _cur.get("ok", false):
		var k2 = clamp(_done_t / 0.25, 0.0, 1.0)
		var ctr = Vector2(sz.x - 16.0, 14.0)
		c.draw_polyline(PackedVector2Array([ctr + Vector2(-5, 0), ctr + Vector2(-1, 4), ctr + Vector2(6, -5)]), Color(0.5, 1.0, 0.55, k2), 2.0)
	else:
		var blink = 0.5 + 0.5 * sin(t * 4.0)
		c.draw_rect(Rect2(sz.x - 20.0, 10.0, 6, 6), Color(accent, 0.4 + 0.6 * blink))
