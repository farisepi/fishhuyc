extends CanvasLayer

const FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
var SAVE_PATH: String = "user://tutorial.cfg"
const CARD_W := 300.0
const TITLE_SIZE := 15
const BODY_SIZE := 12
const KEY_SIZE := 13

var style := "factory"
var anchor := Vector2(-1, -1)

var _queue: Array = []
var _cur: Dictionary = {}
var _t := 0.0
var _done_t := -1.0
var _panel: Control = null
var _title: Label = null
var _body: Label = null
var _font: FontFile = null
var _cfg := ConfigFile.new()
var _keys: Array = []
var _keys_w := 0.0
var _shown_count := 0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var slot = Global.save_slot if has_node("/root/Global") else 0
	SAVE_PATH = "user://tutorial_%d.cfg" % slot
	_cfg.load(SAVE_PATH)
	_font = ResourceLoader.load(FONT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
	if _font:
		_font.fixed_size = 0
	_panel = Control.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	_panel.draw.connect(_draw_panel)
	add_child(_panel)
	_title = _make_label(TITLE_SIZE)
	_panel.add_child(_title)
	_body = _make_label(BODY_SIZE)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_body)


func _make_label(size: int) -> Label:
	var l = Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _font:
		l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("outline_size", 3)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return l


func seen(id: String) -> bool:
	return bool(_cfg.get_value("seen", id, false))


func hint(id: String, text: String, keys: Array = [], done: Callable = Callable(), min_time: float = 2.2, max_time: float = 10.0) -> void:
	if seen(id) or (_cur.get("id", "") == id):
		return
	for q in _queue:
		if q["id"] == id:
			return
	_queue.append({"id": id, "text": text, "keys": keys, "done": done, "min": min_time, "max": max_time})


func dismiss(id: String) -> void:
	if _cur.get("id", "") == id and _done_t < 0.0:
		_done_t = 0.0
	for q in _queue.duplicate():
		if q["id"] == id:
			_queue.erase(q)


func _process(delta: float) -> void:
	var dt = delta / max(0.05, Engine.time_scale) if Engine.time_scale > 0.0 else 1.0 / 60.0
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
			if ok and has_node("/root/UISounds"):
				get_node("/root/UISounds").play_click()
	else:
		_done_t += dt
		if _done_t >= 0.9:
			_cur = {}
			_panel.visible = false
			return
	var a_in = clamp(_t / 0.3, 0.0, 1.0)
	var e_in = 1.0 - pow(1.0 - a_in, 3.0)
	var out_k = 0.0
	if _done_t >= 0.0:
		out_k = clamp((_done_t - 0.45) / 0.4, 0.0, 1.0)
	var e_out = out_k * out_k
	_panel.modulate.a = min(e_in, 1.0 - e_out)
	var base = _anchor_pos()
	var sd = 1.0 if (style == "aquarium" and anchor.x < 0.0) else -1.0
	_panel.position = Vector2(round(base.x + sd * ((1.0 - e_in) * 40.0 + e_out * 40.0)), round(base.y))
	_panel.queue_redraw()


func _anchor_pos() -> Vector2:
	if anchor.x >= 0.0:
		return anchor
	if style == "aquarium":
		return Vector2(1152.0 - _panel.size.x - 16.0, 648.0 - _panel.size.y - 18.0)
	return Vector2(16.0, 648.0 - _panel.size.y - 18.0)

func panel_rect() -> Rect2:
	if _panel == null or not _panel.visible or _panel.modulate.a < 0.05:
		return Rect2()
	return Rect2(_panel.position, _panel.size)


func _start(h: Dictionary) -> void:
	_cur = h
	_t = 0.0
	_done_t = -1.0
	_shown_count += 1
	_cfg.set_value("seen", h["id"], true)
	_cfg.save(SAVE_PATH)
	_keys.clear()
	for k in h["keys"]:
		_keys.append(_key_text(k))
	var parts = String(h["text"]).split("|", false, 1)
	var title = parts[0].strip_edges()
	var body = parts[1].strip_edges() if parts.size() > 1 else ""
	_title.text = title
	_body.text = body
	_body.visible = body != ""
	_keys_w = 0.0
	for k in _keys:
		_keys_w += _cap_w(k) + 4.0
	if _keys_w > 0.0:
		_keys_w += 6.0
	var title_w = 0.0
	if _font:
		title_w = _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE).x
	var w = clamp(max(CARD_W, 30.0 + _keys_w + title_w + 22.0), CARD_W, 470.0)
	var x0 = 16.0
	_title.position = Vector2(x0 + _keys_w, 20.0)
	_title.size = Vector2(w - x0 - _keys_w - 12.0, 20)
	var h_body = 0.0
	if body != "":
		_body.position = Vector2(x0, 44.0)
		_body.size = Vector2(w - x0 - 14.0, 0)
		_body.size = Vector2(w - x0 - 14.0, 0)
		var lines = max(1, _body.get_line_count())
		h_body = lines * _body.get_line_height() + 4.0
	_panel.size = Vector2(w, 48.0 + h_body + 6.0)
	_title.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94))
	_body.add_theme_color_override("font_color", Color(0.78, 0.8, 0.86) if style == "factory" else Color(0.75, 0.88, 0.95))
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
		if t == "" or t == tr("Не назначено"):
			for e in InputMap.action_get_events(k):
				if e is InputEventKey:
					t = OS.get_keycode_string(e.physical_keycode if e.keycode == 0 else e.keycode)
					break
		return {"Left": "←", "Right": "→", "Up": "↑", "Down": "↓", "Space": tr("ПРОБЕЛ"), "Escape": "ESC"}.get(t, t)
	return k


func _cap_w(k: String) -> float:
	var w = 22.0
	if _font:
		w = max(22.0, _font.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_SIZE).x + 12.0)
	return w


func _draw_panel() -> void:
	var c = _panel
	var sz = c.size
	var accent = _accent()
	var t = Time.get_ticks_msec() / 1000.0
	var ok = _done_t >= 0.0 and _cur.get("ok", false)
	var good = Color8(120, 230, 120)
	var edge = good if ok else accent
	if style == "factory":
		c.draw_rect(Rect2(Vector2(2, 3), sz), Color(0, 0, 0, 0.45))
		c.draw_rect(Rect2(Vector2.ZERO, sz), Color8(8, 9, 12))
		c.draw_rect(Rect2(2, 2, sz.x - 4, sz.y - 4), Color8(46, 50, 60))
		c.draw_rect(Rect2(2, 2, sz.x - 4, 1), Color8(96, 102, 116))
		c.draw_rect(Rect2(3, 3, sz.x - 6, sz.y - 6), Color8(20, 22, 28, 245))
	else:
		c.draw_rect(Rect2(Vector2(2, 3), sz), Color(0, 0, 0, 0.35))
		c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.01, 0.05, 0.1, 0.9))
		c.draw_rect(Rect2(1, 1, sz.x - 2, sz.y - 2), Color(accent, 0.45), false, 1.0)
		for i in range(3):
			var by = sz.y - 6.0 - fmod(t * 12.0 + i * 13.0, sz.y - 10.0)
			c.draw_arc(Vector2(sz.x - 10 - i * 5, by), 1.5 + i * 0.5, 0, TAU, 8, Color(accent, 0.45), 1.0)
	c.draw_rect(Rect2(0, 0, 4, sz.y), edge)
	if ok:
		var fl = 1.0 - clamp(_done_t / 0.35, 0.0, 1.0)
		c.draw_rect(Rect2(4, 0, sz.x - 4, sz.y), Color(good, 0.18 * fl))
	var tag = tr("ГОТОВО") if ok else tr("ОБУЧЕНИЕ")
	if _font:
		c.draw_string(_font, Vector2(16, 14), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(edge, 0.95))
	var x = 16.0
	var cy = 30.0
	var press = fmod(t, 1.2) > 0.95
	for k in _keys:
		var w = _cap_w(k)
		var dip = 2.0 if press else 0.0
		c.draw_rect(Rect2(x, cy - 10.0 + 2.0, w, 20.0), Color.BLACK)
		c.draw_rect(Rect2(x, cy - 10.0 + dip, w, 18.0), Color8(200, 204, 214))
		c.draw_rect(Rect2(x + 1, cy - 9.0 + dip, w - 2, 13.0), Color8(244, 246, 252))
		if _font:
			var kw = _font.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_SIZE).x
			c.draw_string(_font, Vector2(x + (w - kw) * 0.5, cy + 3.0 + dip), k, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_SIZE, Color8(28, 30, 38))
		x += w + 4.0
	var ctr = Vector2(sz.x - 16.0, 12.0)
	if ok:
		var k2 = clamp(_done_t / 0.2, 0.0, 1.0)
		var p1 = ctr + Vector2(-5, 0)
		var p2 = ctr + Vector2(-1, 4)
		var p3 = ctr + Vector2(6, -5)
		c.draw_polyline(PackedVector2Array([p1, p1.lerp(p2, min(1.0, k2 * 2.0)), p2.lerp(p3, max(0.0, k2 * 2.0 - 1.0))]), good, 2.0)
	else:
		var blink = 0.5 + 0.5 * sin(t * 4.0)
		c.draw_rect(Rect2(ctr.x - 3, ctr.y - 3, 6, 6), Color(accent, 0.35 + 0.65 * blink))
	if not ok and _cur.has("max"):
		var left = 1.0 - clamp(_t / max(0.1, float(_cur["max"])), 0.0, 1.0)
		c.draw_rect(Rect2(4, sz.y - 2, (sz.x - 4) * left, 2), Color(accent, 0.55))
