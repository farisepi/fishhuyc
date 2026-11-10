extends CanvasLayer

# QTE "быстро жми E" в стиле фабрики/склада (как подсказки Tutorial_Hints и табличка лифта):
# тёмная пиксельная плашка, янтарная полоска слева, кейкап клавиши, который «проседает»
# при нажатии, сегментная шкала нажатий и тонкая полоса времени снизу.
# Старые ButtonBG / ProgressRing / ELabel из сцены скрываются — всё рисуется кодом.

signal qte_result(success: bool)

@onready var backdrop: ColorRect = $Root/Backdrop
@onready var button_bg: ColorRect = $Root/ButtonBG
@onready var progress_ring: TextureProgressBar = $Root/ProgressRing
@onready var e_label: Label = $Root/ELabel

const FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"

const REQUIRED_PRESSES: int = 8
const TIME_LIMIT: float = 5.0          # реальные секунды (не зависят от slow-mo)
const SLOWMO_SCALE: float = 0.4
const TITLE_TEXT := "ВЫРВАТЬСЯ"

# палитра фабричного UI
const C_SHADOW := Color(0, 0, 0, 0.5)
const C_OUTER := Color8(8, 9, 12)
const C_BEVEL := Color8(46, 50, 60)
const C_BEVEL_HI := Color8(96, 102, 116)
const C_FILL := Color8(20, 22, 28, 245)
const C_ACCENT := Color8(255, 168, 60)
const C_GOOD := Color8(120, 230, 120)
const C_BAD := Color8(235, 80, 70)
const C_TITLE := Color(0.98, 0.97, 0.94)
const C_CAP_SIDE := Color8(200, 204, 214)
const C_CAP_FACE := Color8(244, 246, 252)
const C_CAP_TEXT := Color8(28, 30, 38)
const C_SEG_EMPTY := Color8(46, 50, 60)

const PLATE_W := 168.0
const PLATE_H := 62.0

var is_active: bool = false
var can_press: bool = false
var press_count: int = 0
var qte_timer: float = 0.0
var result_sent: bool = false

var pressed_callback: Callable = Callable()

var _world_pos: Vector2 = Vector2.ZERO
var _center: Vector2 = Vector2.ZERO
var _shake: Vector2 = Vector2.ZERO
var _dip: float = 0.0
var _appear: float = 0.0
var _alpha: float = 1.0
var _result: int = 0           # 0 — идёт, 1 — успех, -1 — провал
var _result_t: float = 0.0
var _last_ticks: int = 0
var _font: FontFile = null
var _canvas: Control = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	hide()
	set_process(false)
	set_process_input(false)

	for n in [button_bg, progress_ring, e_label]:
		if n:
			n.visible = false
	if backdrop:
		backdrop.visible = false

	_font = ResourceLoader.load(FONT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
	if _font:
		_font.fixed_size = 0

	_canvas = Control.new()
	_canvas.name = "PlateCanvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.draw.connect(_on_canvas_draw)
	$Root.add_child(_canvas)

func set_pressed_callback(cb: Callable):
	pressed_callback = cb

func show_qte_at(world_pos: Vector2):
	visible = true
	show()
	is_active = true
	can_press = false
	press_count = 0
	qte_timer = 0.0
	result_sent = false
	_world_pos = world_pos
	_shake = Vector2.ZERO
	_dip = 0.0
	_appear = 0.0
	_alpha = 1.0
	_result = 0
	_result_t = 0.0
	_last_ticks = Time.get_ticks_msec()
	_update_center()

	Engine.time_scale = SLOWMO_SCALE

	can_press = true
	set_process(true)
	set_process_input(true)
	if has_node("/root/UISounds") and get_node("/root/UISounds").has_method("play_switch_on"):
		get_node("/root/UISounds").play_switch_on()

func _update_center():
	_center = get_viewport().get_canvas_transform() * _world_pos

func hide_qte():
	visible = false
	hide()
	is_active = false
	can_press = false
	result_sent = false
	Engine.time_scale = 1.0
	set_process(false)
	set_process_input(false)

func _real_delta() -> float:
	var now = Time.get_ticks_msec()
	var d = (now - _last_ticks) / 1000.0
	_last_ticks = now
	return clamp(d, 0.0, 0.1)

func _process(_delta):
	var rd = _real_delta()
	_appear += rd
	_dip = move_toward(_dip, 0.0, rd * 10.0)
	_shake = _shake.move_toward(Vector2.ZERO, rd * 60.0)
	if _result != 0:
		_result_t += rd

	if is_active and not result_sent:
		qte_timer += rd
		if qte_timer >= TIME_LIMIT:
			_finish(false)

	_update_center()
	_canvas.queue_redraw()

func _input(event):
	if not is_active or not can_press or result_sent:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		press_count += 1
		_dip = 1.0
		_shake = Vector2(randf_range(-1, 1), randf_range(-0.5, 0.5)).normalized() * 3.0
		if pressed_callback.is_valid():
			pressed_callback.call()
		if press_count >= REQUIRED_PRESSES:
			_finish(true)

func _key_text() -> String:
	if has_node("/root/InputRebind"):
		var t = get_node("/root/InputRebind").get_key_text("interact")
		if t != "" and t != tr("Не назначено"):
			return t
	return "E"

func _on_canvas_draw():
	if not visible:
		return
	var c = _canvas
	# появление: выезжает снизу и проявляется
	var k_in = clamp(_appear / 0.22, 0.0, 1.0)
	var e_in = 1.0 - pow(1.0 - k_in, 3.0)
	var a = _alpha * e_in
	if a <= 0.01:
		return
	var sz = Vector2(PLATE_W, PLATE_H)
	var pos = (_center - Vector2(sz.x * 0.5, sz.y) + _shake + Vector2(0, (1.0 - e_in) * 10.0)).round()

	var edge = C_ACCENT
	if _result == 1:
		edge = C_GOOD
	elif _result == -1:
		edge = C_BAD
	var t = Time.get_ticks_msec() / 1000.0

	# плашка (как у Tutorial_Hints, стиль factory)
	c.draw_rect(Rect2(pos + Vector2(2, 3), sz), Color(C_SHADOW, C_SHADOW.a * a))
	c.draw_rect(Rect2(pos, sz), Color(C_OUTER, a))
	c.draw_rect(Rect2(pos + Vector2(2, 2), sz - Vector2(4, 4)), Color(C_BEVEL, a))
	c.draw_rect(Rect2(pos + Vector2(2, 2), Vector2(sz.x - 4, 1)), Color(C_BEVEL_HI, a))
	c.draw_rect(Rect2(pos + Vector2(3, 3), sz - Vector2(6, 6)), Color(C_FILL, C_FILL.a * a))
	c.draw_rect(Rect2(pos, Vector2(4, sz.y)), Color(edge, a))
	if _result != 0:
		var fl = 1.0 - clamp(_result_t / 0.35, 0.0, 1.0)
		c.draw_rect(Rect2(pos + Vector2(4, 0), Vector2(sz.x - 4, sz.y)), Color(edge, 0.18 * fl * a))

	# хвостик-указатель вниз, к рыбе
	var tip = PackedVector2Array([pos + Vector2(sz.x * 0.5 - 6, sz.y), pos + Vector2(sz.x * 0.5 + 6, sz.y), pos + Vector2(sz.x * 0.5, sz.y + 7)])
	c.draw_colored_polygon(tip, Color(C_OUTER, a))

	# метка сверху
	var tag = tr("БЫСТРО!")
	if _result == 1:
		tag = tr("ГОТОВО")
	elif _result == -1:
		tag = tr("НЕ УСПЕЛ")
	if _font:
		c.draw_string(_font, pos + Vector2(14, 14), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(edge, 0.95 * a))
	# мигающий квадратик справа сверху
	if _result == 0:
		var blink = 0.5 + 0.5 * sin(t * 8.0)
		c.draw_rect(Rect2(pos + Vector2(sz.x - 14, 7), Vector2(6, 6)), Color(edge, (0.35 + 0.65 * blink) * a))

	# кейкап клавиши
	var key = _key_text()
	var cap_w = 30.0
	if _font:
		cap_w = max(30.0, _font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 14.0)
	var cap_h = 24.0
	var cap_pos = pos + Vector2(14, 20)
	var dip = round(_dip * 3.0)
	c.draw_rect(Rect2(cap_pos + Vector2(0, 3), Vector2(cap_w, cap_h)), Color(0, 0, 0, a))
	c.draw_rect(Rect2(cap_pos + Vector2(0, dip), Vector2(cap_w, cap_h)), Color(C_CAP_SIDE, a))
	c.draw_rect(Rect2(cap_pos + Vector2(1, 1 + dip), Vector2(cap_w - 2, cap_h - 6)), Color(C_CAP_FACE, a))
	if _font:
		var kw = _font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		c.draw_string(_font, cap_pos + Vector2((cap_w - kw) * 0.5, 15 + dip), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(C_CAP_TEXT, a))

	# заголовок действия
	if _font:
		c.draw_string(_font, cap_pos + Vector2(cap_w + 10, 15), tr(TITLE_TEXT), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(C_TITLE, a))

	# сегментная шкала нажатий
	var seg_y = pos.y + sz.y - 14.0
	var seg_x0 = pos.x + 14.0
	var seg_total = sz.x - 28.0
	var gap = 3.0
	var seg_w = floor((seg_total - gap * (REQUIRED_PRESSES - 1)) / REQUIRED_PRESSES)
	for i in REQUIRED_PRESSES:
		var r = Rect2(Vector2(seg_x0 + i * (seg_w + gap), seg_y), Vector2(seg_w, 5))
		var filled = i < press_count
		var col = (C_GOOD if _result == 1 else C_ACCENT) if filled else C_SEG_EMPTY
		c.draw_rect(r, Color(col, a))
		if filled:
			c.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(1, 1, 1, 0.35 * a))

	# сколько осталось времени — тонкая полоса по низу
	if _result == 0:
		var left = clamp(1.0 - qte_timer / TIME_LIMIT, 0.0, 1.0)
		var tcol = C_ACCENT if left > 0.3 else C_BAD
		c.draw_rect(Rect2(pos + Vector2(4, sz.y - 2), Vector2((sz.x - 4) * left, 2)), Color(tcol, 0.7 * a))

func _finish(success: bool):
	if result_sent:
		return
	result_sent = true
	can_press = false
	set_process_input(false)
	_result = 1 if success else -1
	_result_t = 0.0
	_dip = 1.0

	Engine.time_scale = 1.0
	is_active = false
	qte_result.emit(success)
	if success and has_node("/root/UISounds") and get_node("/root/UISounds").has_method("play_click"):
		get_node("/root/UISounds").play_click()

	var fade = create_tween()
	fade.set_ignore_time_scale(true)
	fade.tween_property(self, "_alpha", 0.0, 0.3).set_delay(0.45)
	await fade.finished

	set_process(false)
	visible = false
	hide()
