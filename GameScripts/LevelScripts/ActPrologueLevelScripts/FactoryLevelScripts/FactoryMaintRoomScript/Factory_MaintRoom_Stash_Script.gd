extends CanvasLayer

signal closed

const ACC := Color8(255, 168, 60)
const NEW_C := Color(0.45, 0.8, 1.0)
const OK_C := Color(0.45, 0.95, 0.55)
const BG := Color(0.05, 0.06, 0.09, 0.97)
const EDGE := Color(0.02, 0.02, 0.03)
const WIN := Vector2(780, 440)
const NICHE := Vector2(300, 392)
const SND_DIR := "res://GameAssets/Audio/SoundEffects/UserInterfaceSounds/"
const SND_OPEN := SND_DIR + "ButtonClickSounds/Menu_Click_FallingButton_Open_SoundEffect.mp3"
const SND_CLOSE := SND_DIR + "ButtonClickSounds/Menu_Click_FallingButton_Close_SoundEffect.mp3"
const SND_PICK := SND_DIR + "ButtonClickSounds/Menu_Click_Button_SoundEffect.mp3"
const SND_POP := SND_DIR + "PopUpOptionSounds/Menu_Aquarium_MainMenu_Pop_Option4_SoundEffect.mp3"

var L = null
var _box: Dictionary = {}
var _open := false
var _closing := false
var _t := 0.0
var _mouse_was := Input.MOUSE_MODE_VISIBLE
var _blocked_was := false

var _dim: ColorRect = null
var _win: Control = null
var _niche: Control = null
var _art: TextureRect = null
var _art_scale := 8.0
var _items: Array = []
var _sel := -1
var _title: Label = null
var _text: RichTextLabel = null
var _list: VBoxContainer = null
var _count: Label = null
var _notice: Label = null
var _tab_l: Label = null
var _tab: Panel = null
var _hint: Label = null
var _dust: Array = []
var _text_tw: Tween = null
var _sfx: AudioStreamPlayer = null
var _locked := false
var _wsize := WIN

func setup(level) -> void:
	L = level
	layer = 75
	visible = false
	set_process(false)

func is_open() -> bool:
	return _open

func _font() -> Font:
	var g = get_node_or_null("/root/Global")
	if g and g.get("_font_free"):
		return g._font_free
	return L._bubble_font() if L else null

func _lbl(text: String, size: int, col: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f = _font()
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _frame(c: Control, bg: Color, inner: Color, outer_w: int = 3, inner_w: int = 2) -> void:
	var st = StyleBoxFlat.new()
	st.bg_color = bg
	st.set_border_width_all(outer_w)
	st.border_color = EDGE
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 8
	var p = Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_theme_stylebox_override("panel", st)
	c.add_child(p)
	var p2 = Panel.new()
	p2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p2.set_anchors_preset(Control.PRESET_FULL_RECT)
	p2.offset_left = outer_w
	p2.offset_top = outer_w
	p2.offset_right = -outer_w
	p2.offset_bottom = -outer_w
	var st2 = StyleBoxFlat.new()
	st2.bg_color = Color(0, 0, 0, 0)
	st2.set_border_width_all(inner_w)
	st2.border_color = inner
	p2.add_theme_stylebox_override("panel", st2)
	c.add_child(p2)

func _play(path: String, vol: float = -6.0, pitch: float = 1.0) -> void:
	if not ResourceLoader.exists(path):
		return
	if _sfx == null:
		_sfx = AudioStreamPlayer.new()
		_sfx.bus = "SFX"
		_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_sfx)
	var p = AudioStreamPlayer.new()
	p.stream = load(path)
	p.bus = "SFX"
	p.volume_db = vol
	p.pitch_scale = pitch
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func open(box: Dictionary) -> void:
	if _open:
		return
	_box = box
	_locked = bool(box.get("locked", false))
	_wsize = Vector2(NICHE.x + 32.0, WIN.y) if _locked else WIN
	_open = true
	_closing = false
	_sel = -1
	_t = 0.0
	_dust.clear()
	_items.clear()
	for c in get_children():
		if c != _sfx:
			c.queue_free()
	_mouse_was = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if L.player and "movement_blocked" in L.player:
		_blocked_was = L.player.movement_blocked
		L.player.set_movement_blocked(true)
		L.player.velocity = Vector2.ZERO
	_build()
	visible = true
	set_process(true)
	_play(SND_POP, -10.0, 0.9)
	_dim.color.a = 0.0
	_win.modulate.a = 0.0
	_win.scale = Vector2(0.86, 0.86)
	var tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(_dim, "color:a", 0.66, 0.22)
	tw.tween_property(_win, "modulate:a", 1.0, 0.16)
	tw.tween_property(_win, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not _locked:
		_show_box_text()
	var seq = create_tween().set_ignore_time_scale(true)
	seq.tween_interval(0.3)
	seq.tween_callback(_swing_open)

func _swing_open() -> void:
	if not _open:
		return
	var base = _art.position
	_art.pivot_offset = Vector2(_art.size.x * 0.5, _art.size.y)
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(_art, "scale", Vector2(1.06, 0.94), 0.07)
	tw.tween_callback(func():
		_art.texture = load(_box["open_tex"])
		_play(SND_OPEN, -4.0, randf_range(0.92, 1.05))
		_puff())
	tw.tween_property(_art, "scale", Vector2(0.97, 1.03), 0.08)
	tw.tween_property(_art, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var sh = create_tween().set_ignore_time_scale(true)
	sh.tween_interval(0.07)
	for k in range(4):
		sh.tween_property(_art, "position", base + Vector2(randf_range(-3, 3), randf_range(-2, 1)), 0.03)
	sh.tween_property(_art, "position", base, 0.04)
	for i in range(_items.size()):
		var r: TextureRect = _items[i]["rect"]
		var to = r.position
		r.position = to - Vector2(0, 14)
		var it = create_tween().set_ignore_time_scale(true)
		it.tween_interval(0.22 + i * 0.12)
		it.tween_callback(func():
			r.visible = true
			_play(SND_POP, -14.0, 1.2 + i * 0.08))
		it.set_parallel(true)
		it.tween_property(r, "modulate:a", 1.0, 0.12)
		it.tween_property(r, "position", to, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func close() -> void:
	if not _open or _closing:
		return
	_closing = true
	_play(SND_CLOSE, -6.0, randf_range(0.95, 1.05))
	var tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(_dim, "color:a", 0.0, 0.18)
	tw.tween_property(_win, "modulate:a", 0.0, 0.16)
	tw.tween_property(_win, "scale", Vector2(0.9, 0.9), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished
	visible = false
	set_process(false)
	_open = false
	_closing = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if L.state == L.State.INSPECT else _mouse_was)
	if L.player and "movement_blocked" in L.player:
		L.player.set_movement_blocked(_blocked_was)
	closed.emit()

func _build() -> void:
	var vp = Vector2(1152, 648)
	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.02, 0.0)
	_dim.size = vp
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(_dim)
	_win = Control.new()
	_win.size = _wsize
	_win.position = ((vp - _wsize) * 0.5).round() + Vector2(0, 8)
	_win.pivot_offset = _wsize * 0.5
	_win.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_win)
	_win.add_child(load("res://GameScripts/UIScripts/CardFrameScripts/UI_CardFrame.gd").make(ACC))
	_tab = Panel.new()
	_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ts = StyleBoxFlat.new()
	ts.bg_color = ACC
	ts.set_border_width_all(3)
	ts.border_color = EDGE
	_tab.add_theme_stylebox_override("panel", ts)
	_tab_l = _lbl(_box.get("kind_title", ""), 16, Color(0.06, 0.05, 0.03))
	_tab_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var f = _font()
	var tw = (f.get_string_size(_tab_l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x if f else 80.0) + 28.0
	_tab.size = Vector2(ceil(tw), 30)
	_tab.position = Vector2(18, -20)
	_tab_l.size = _tab.size
	_tab.add_child(_tab_l)
	_win.add_child(_tab)
	_niche = Control.new()
	_niche.position = Vector2(16, 24)
	_niche.size = NICHE
	_niche.clip_contents = true
	_niche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var niche_ref = _niche
	_niche.draw.connect(func(): _draw_niche(niche_ref))
	_win.add_child(_niche)
	var s: float = _box.get("scale", 8.0)
	_art_scale = s
	var ct: Texture2D = load(_box["closed_tex"])
	_art = TextureRect.new()
	_art.texture = ct
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.size = ct.get_size() * s
	_art.position = Vector2(round((NICHE.x - _art.size.x) * 0.5), NICHE.y - 26.0 - _art.size.y + s)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_niche.add_child(_art)
	var fr = Panel.new()
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.set_anchors_preset(Control.PRESET_FULL_RECT)
	var fs = StyleBoxFlat.new()
	fs.bg_color = Color(0, 0, 0, 0)
	fs.set_border_width_all(2)
	fs.border_color = Color(0.2, 0.22, 0.28)
	fr.add_theme_stylebox_override("panel", fs)
	_niche.add_child(fr)
	if _locked:
		_build_items(s, 0.0)
		_hint = _lbl(tr("%s / Esc — закрыть") % L._key_name("interact"), 13, Color(0.55, 0.58, 0.66))
		_hint.position = Vector2(0, _wsize.y + 10.0)
		_hint.size = Vector2(_wsize.x, 20)
		_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_win.add_child(_hint)
		return
	var x0 = NICHE.x + 40.0
	var cw = WIN.x - x0 - 22.0
	_title = _lbl("", 22, ACC.lightened(0.15))
	_title.position = Vector2(x0, 26)
	_title.size = Vector2(cw, 30)
	_title.clip_text = true
	_win.add_child(_title)
	_text = RichTextLabel.new()
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.scroll_active = false
	_text.fit_content = true
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if f:
		_text.add_theme_font_override("normal_font", f)
	_text.add_theme_font_size_override("normal_font_size", 16)
	_text.add_theme_constant_override("line_separation", 3)
	_text.add_theme_color_override("default_color", Color(0.9, 0.92, 0.98))
	_text.position = Vector2(x0, 62)
	_text.size = Vector2(cw, 0)
	_text.custom_minimum_size = Vector2(cw, 0)
	_win.add_child(_text)
	var ly = 222.0
	var rule = ColorRect.new()
	rule.color = Color(ACC, 0.35)
	rule.position = Vector2(x0, ly - 8)
	rule.size = Vector2(cw, 2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_win.add_child(rule)
	var head = _lbl(tr("ВНУТРИ"), 15, ACC)
	head.position = Vector2(x0, ly)
	_win.add_child(head)
	_count = _lbl("", 13, Color(0.6, 0.64, 0.72))
	_count.position = Vector2(x0, ly + 2)
	_count.size = Vector2(cw, 20)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_win.add_child(_count)
	_list = VBoxContainer.new()
	_list.position = Vector2(x0, ly + 28)
	_list.size = Vector2(cw, 120)
	_list.add_theme_constant_override("separation", 6)
	_win.add_child(_list)
	_build_items(s, cw)
	_notice = _lbl("", 14, OK_C)
	_notice.position = Vector2(x0, WIN.y - 60)
	_notice.size = Vector2(cw, 20)
	_notice.modulate.a = 0.0
	_win.add_child(_notice)
	_hint = _lbl(tr("%s / Esc — закрыть") % L._key_name("interact"), 13, Color(0.55, 0.58, 0.66))
	_hint.position = Vector2(x0, WIN.y - 34)
	_hint.size = Vector2(cw, 20)
	_hint.clip_text = true
	_win.add_child(_hint)
	_refresh_rows()

func _build_items(s: float, cw: float) -> void:
	var items: Array = _box.get("items", [])
	for i in range(items.size()):
		var d = items[i]
		var tex: Texture2D = load(d["tex"])
		var r = TextureRect.new()
		r.texture = tex
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.size = tex.get_size() * s
		r.position = _art.position + d["origin"] * s
		r.pivot_offset = r.size * 0.5
		r.flip_h = bool(d.get("flip", false))
		r.visible = false
		r.modulate.a = 0.0
		if _locked:
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_niche.add_child(r)
			_items.append({"data": d, "rect": r, "row": null, "hover": false})
			continue
		r.mouse_filter = Control.MOUSE_FILTER_STOP
		r.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		L._ensure_outline(r, NEW_C)
		if r.material is ShaderMaterial:
			r.material.set_shader_parameter("width", 2.5 / s)
			r.material.set_shader_parameter("glow", 0.05)
		r.mouse_entered.connect(_hover.bind(i, true))
		r.mouse_exited.connect(_hover.bind(i, false))
		r.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_pick(i))
		_niche.add_child(r)
		var row = _make_row(i, d, cw)
		_list.add_child(row)
		_items.append({"data": d, "rect": r, "row": row, "hover": false})

func _make_row(i: int, d: Dictionary, cw: float) -> Control:
	var row = Panel.new()
	row.custom_minimum_size = Vector2(cw, 34)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.09, 0.1, 0.14)
	st.set_border_width_all(2)
	st.border_color = Color(0.16, 0.18, 0.24)
	row.add_theme_stylebox_override("panel", st)
	row.set_meta("st", st)
	var ic = TextureRect.new()
	ic.texture = load(d["tex"])
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.position = Vector2(6, 3)
	ic.size = Vector2(40, 28)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ic)
	var nm = _lbl(tr(d["title"]), 16, Color(0.92, 0.93, 0.97))
	nm.position = Vector2(54, 0)
	nm.size = Vector2(cw - 54 - 96, 34)
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.clip_text = true
	row.add_child(nm)
	var stamp = _lbl("", 13, NEW_C)
	stamp.position = Vector2(cw - 96, 0)
	stamp.size = Vector2(86, 34)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(stamp)
	row.set_meta("stamp", stamp)
	var tick = Control.new()
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tick.position = Vector2(cw - 34, 9)
	tick.size = Vector2(20, 16)
	tick.draw.connect(func():
		var c = OK_C
		for k in range(3):
			tick.draw_rect(Rect2(2 + k * 2, 7 + k * 2, 3, 3), c)
		for k in range(5):
			tick.draw_rect(Rect2(8 + k * 2, 9 - k * 2, 3, 3), c))
	row.add_child(tick)
	row.set_meta("tick", tick)
	row.mouse_entered.connect(_hover.bind(i, true))
	row.mouse_exited.connect(_hover.bind(i, false))
	row.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_pick(i))
	return row

func _seen(id: String) -> bool:
	return L.journal_notes.has(id)

func _refresh_rows() -> void:
	if _locked:
		return
	var n_seen := 0
	for i in range(_items.size()):
		var it = _items[i]
		var d = it["data"]
		var seen = _seen(d["id"])
		if seen:
			n_seen += 1
		var row: Panel = it["row"]
		var st: StyleBoxFlat = row.get_meta("st")
		var on = it["hover"] or i == _sel
		st.bg_color = Color(0.16, 0.13, 0.08) if i == _sel else (Color(0.12, 0.13, 0.18) if on else Color(0.09, 0.1, 0.14))
		st.border_color = ACC if i == _sel else (Color(ACC, 0.6) if on else Color(0.16, 0.18, 0.24))
		var stamp: Label = row.get_meta("stamp")
		stamp.text = "" if seen else tr("НОВОЕ")
		row.get_meta("tick").visible = seen
		stamp.add_theme_color_override("font_color", OK_C if seen else NEW_C)
		var r: TextureRect = it["rect"]
		if r.material is ShaderMaterial:
			var col = ACC if (on) else NEW_C
			r.material.set_shader_parameter("outline_color", Color(col.r, col.g, col.b, 1.0))
			r.material.set_shader_parameter("active", 1.0 if (on or not seen) else 0.0)
	_count.text = "%d / %d" % [n_seen, _items.size()]

func _hover(i: int, on: bool) -> void:
	if _locked or i < 0 or i >= _items.size():
		return
	_items[i]["hover"] = on
	var r: TextureRect = _items[i]["rect"]
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(r, "scale", Vector2(1.08, 1.08) if on else Vector2.ONE, 0.1)
	_refresh_rows()

func _type(title: String, text: String) -> void:
	_title.text = title
	_text.text = text
	for fs in [16, 15, 14, 13]:
		_text.add_theme_font_size_override("normal_font_size", fs)
		if _text.get_content_height() <= 146.0:
			break
	_text.visible_characters = 0
	if _text_tw and _text_tw.is_valid():
		_text_tw.kill()
	var n = _text.get_total_character_count()
	_text_tw = create_tween().set_ignore_time_scale(true)
	_text_tw.tween_property(_text, "visible_characters", n, max(0.2, n / 60.0))
	_title.modulate.a = 0.0
	_title.position.x = NICHE.x + 52.0
	var t2 = create_tween().set_parallel(true).set_ignore_time_scale(true)
	t2.tween_property(_title, "modulate:a", 1.0, 0.15)
	t2.tween_property(_title, "position:x", NICHE.x + 40.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _show_box_text() -> void:
	_type(_box.get("title", ""), _box.get("text", ""))

func _pick(i: int) -> void:
	if _locked or i < 0 or i >= _items.size() or _closing:
		return
	var d = _items[i]["data"]
	_sel = i
	_play(SND_PICK, -8.0, randf_range(0.95, 1.1))
	_type(tr(d["title"]), tr(d["phrase"]))
	if not _seen(d["id"]):
		L._add_journal_note(d["id"], tr(d["title"]) + ": " + tr(d["journal"]))
		_flash_notice(tr("+ запись в журнале"))
	var r: TextureRect = _items[i]["rect"]
	var y0 = r.position.y
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(r, "position:y", y0 - 8.0, 0.09).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "position:y", y0, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_refresh_rows()

func _flash_notice(t: String) -> void:
	_notice.text = t
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(_notice, "modulate:a", 1.0, 0.12)
	tw.tween_interval(1.6)
	tw.tween_property(_notice, "modulate:a", 0.0, 0.4)

func _puff() -> void:
	var c = _art.position + Vector2(_art.size.x * 0.5, _art.size.y * 0.45)
	for k in range(22):
		var a = randf() * TAU
		var sp = randf_range(30.0, 110.0)
		_dust.append([c + Vector2(randf_range(-_art.size.x * 0.4, _art.size.x * 0.4), randf_range(-_art.size.y * 0.35, _art.size.y * 0.35)),
			Vector2(cos(a), sin(a) * 0.6 - 0.4) * sp, randf_range(0.5, 1.1), randf_range(2.0, 4.0)])

func _draw_niche(n: Control) -> void:
	if n != _niche:
		return
	n.draw_rect(Rect2(Vector2.ZERO, NICHE), Color(0.025, 0.03, 0.045))
	var y := 0.0
	while y < NICHE.y:
		n.draw_rect(Rect2(0, y, NICHE.x, 2), Color(0.05, 0.06, 0.08))
		for x in range(14, int(NICHE.x), 62):
			n.draw_rect(Rect2(x, y + 8, 3, 3), Color(0.09, 0.1, 0.13))
		y += 58.0
	var fl = 0.9 + 0.1 * sin(_t * 1.9) * sin(_t * 0.53 + 1.0)
	var lc = Vector2(NICHE.x * 0.5, -30)
	for i in range(7):
		n.draw_circle(lc, 300.0 - i * 38.0, Color(ACC, 0.022 * fl))
	var fy = NICHE.y - 26.0
	n.draw_rect(Rect2(0, fy, NICHE.x, 26), Color(0.07, 0.075, 0.09))
	n.draw_rect(Rect2(0, fy, NICHE.x, 2), Color(0.14, 0.15, 0.19))
	if _art:
		var cx = _art.position.x + _art.size.x * 0.5
		for i in range(4):
			var w = _art.size.x * (0.62 - i * 0.08)
			n.draw_rect(Rect2(cx - w * 0.5 - 6, fy + 2 + i * 2, w + 12, 6 - i), Color(0, 0, 0, 0.22))
	for d in _dust:
		var a = clamp(d[2], 0.0, 1.0) * 0.55
		n.draw_rect(Rect2(d[0].round(), Vector2(d[3], d[3])), Color(0.75, 0.72, 0.65, a))

func _process(delta: float) -> void:
	_t += delta
	for d in _dust:
		d[0] += d[1] * delta
		d[1] *= 0.92
		d[1].y += 30.0 * delta
		d[2] -= delta
	_dust = _dust.filter(func(d): return d[2] > 0.0)
	if _niche:
		_niche.queue_redraw()
	for i in range(_items.size()):
		var r: TextureRect = _items[i]["rect"]
		if i == _sel and not _items[i]["hover"]:
			var k = 1.0 + 0.03 * sin(_t * 4.0)
			r.scale = Vector2(k, k)

func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			close()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action("interact") or event.keycode == KEY_ESCAPE or event.is_action("ui_cancel"):
			close()
		elif event.keycode in [KEY_DOWN, KEY_S, KEY_RIGHT, KEY_D] and _items.size() > 0:
			_pick((_sel + 1) % _items.size())
		elif event.keycode in [KEY_UP, KEY_W, KEY_LEFT, KEY_A] and _items.size() > 0:
			_pick((_sel - 1 + _items.size()) % _items.size() if _sel >= 0 else _items.size() - 1)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
