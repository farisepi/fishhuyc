extends Control

const P := 2.0

const STYLES := {
	"factory": {
		"off": Color(0.15, 0.135, 0.125), "on": Color(0.78, 0.52, 0.16), "edge": Color(0.04, 0.045, 0.07),
		"hover": Color(1.0, 0.78, 0.36), "knob": Color(0.6, 0.58, 0.56), "knob_hi": Color(0.86, 0.84, 0.8),
		"knob_lo": Color(0.34, 0.32, 0.31), "led_on": Color(0.5, 1.0, 0.55), "led_off": Color(0.38, 0.1, 0.09),
		"mark": Color(1.0, 0.92, 0.7),
	},
	"aquarium": {
		"off": Color(0.1, 0.16, 0.27), "on": Color(0.22, 0.6, 0.78), "edge": Color(0.03, 0.05, 0.1),
		"hover": Color(0.55, 0.88, 1.0), "knob": Color(0.56, 0.7, 0.84), "knob_hi": Color(0.82, 0.92, 1.0),
		"knob_lo": Color(0.3, 0.4, 0.55), "led_on": Color(0.6, 1.0, 0.95), "led_off": Color(0.16, 0.22, 0.34),
		"mark": Color(0.85, 0.97, 1.0),
	},
}

var cb: CheckButton = null
var st: Dictionary = {}
var k := 0.0
var h := 0.0
var squash := 0.0
var _target := false
var _tw: Tween = null

static func attach(button: CheckButton, style: String = "factory") -> void:
	if button == null or button.get_node_or_null("PixelSwitch"):
		return
	var sw = load("res://GameScripts/MenuScripts/MenuComponentScripts/PixelSwitchScript/Menu_PixelSwitch_Script.gd").new()
	sw.name = "PixelSwitch"
	sw.cb = button
	sw.st = STYLES.get(style, STYLES["factory"])
	var img = Image.create(48, 26, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var blank = ImageTexture.create_from_image(img)
	for n in ["checked", "unchecked", "checked_disabled", "unchecked_disabled", "checked_mirrored", "unchecked_mirrored"]:
		button.add_theme_icon_override(n, blank)
	button.add_child(sw)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cb.resized.connect(queue_redraw)
	_target = cb.button_pressed
	k = 1.0 if _target else 0.0
	cb.toggled.connect(func(_on): _sync())
	cb.draw.connect(_sync)
	cb.mouse_entered.connect(func(): _hover(true))
	cb.mouse_exited.connect(func(): _hover(false))
	cb.focus_entered.connect(func(): _hover(true))
	cb.focus_exited.connect(func(): _hover(false))

func _sync() -> void:
	if cb.button_pressed == _target:
		return
	_target = cb.button_pressed
	if _tw and _tw.is_valid():
		_tw.kill()
	_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw.tween_method(func(v): k = v; queue_redraw(), k, 1.0 if _target else 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var sq = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	sq.tween_method(func(v): squash = v; queue_redraw(), 0.0, 1.0, 0.08)
	sq.tween_method(func(v): squash = v; queue_redraw(), 1.0, 0.0, 0.16)

func _hover(on: bool) -> void:
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(func(v): h = v; queue_redraw(), h, 1.0 if on else 0.0, 0.12)

func _r(x: float, y: float, w: float, hh: float, c: Color) -> void:
	draw_rect(Rect2(Vector2(x, y).round(), Vector2(w, hh).round()), c)

func _draw() -> void:
	var W := 48.0
	var H := 26.0
	var sz = cb.size
	var o = ((sz - Vector2(W, H)) * 0.5).round()
	var x0 = o.x
	var y0 = o.y
	var kk = clamp(k, -0.1, 1.1)
	var on_t = clamp(k, 0.0, 1.0)
	var fill: Color = st["off"].lerp(st["on"], on_t)
	var edge: Color = st["edge"].lerp(st["hover"], h * 0.85)
	_r(x0 + P, y0, W - 2 * P, H, edge)
	_r(x0, y0 + P, W, H - 2 * P, edge)
	_r(x0 + P, y0 + P, W - 2 * P, H - 2 * P, fill.darkened(0.25))
	_r(x0 + 2 * P, y0 + 2 * P, W - 4 * P, H - 4 * P, fill)
	_r(x0 + 2 * P, y0 + 2 * P, W - 4 * P, P, fill.darkened(0.35))
	_r(x0 + 2 * P, y0 + H - 3 * P, W - 4 * P, P, fill.lightened(0.18))
	var mk: Color = st["mark"]
	_r(x0 + 5 * P, y0 + 4 * P, P, H - 8 * P, Color(mk, 0.85 * on_t))
	var ox = x0 + W - 8 * P
	var oy = y0 + 4 * P
	var oc = Color(mk, 0.35 * (1.0 - on_t))
	_r(ox, oy, 3 * P, P, oc)
	_r(ox, oy + H - 9 * P, 3 * P, P, oc)
	_r(ox - P, oy + P, P, H - 10 * P, oc)
	_r(ox + 3 * P, oy + P, P, H - 10 * P, oc)
	var kw = 11.0 * P + squash * 2.0 * P
	var kh = H - 2 * P
	var kx = x0 + P + (W - 2 * P - kw) * kk
	var ky = y0 + P
	var face: Color = st["knob"].lightened(0.12 * h)
	_r(kx, ky, kw, kh, st["edge"])
	_r(kx + P, ky + P, kw - 2 * P, kh - 2 * P, face)
	_r(kx + P, ky + P, kw - 2 * P, P, st["knob_hi"])
	_r(kx + P, ky + P, P, kh - 2 * P, st["knob_hi"])
	_r(kx + P, ky + kh - 2 * P, kw - 2 * P, P, st["knob_lo"])
	_r(kx + kw - 2 * P, ky + P, P, kh - 2 * P, st["knob_lo"])
	for i in range(3):
		_r(kx + 3 * P + i * 2 * P, ky + kh - 6 * P, P, 3 * P, st["knob_lo"])
	var led: Color = st["led_off"].lerp(st["led_on"], on_t)
	var lx = kx + round(kw * 0.5 / P) * P - 2 * P
	var ly = ky + 3 * P
	if on_t > 0.05:
		draw_rect(Rect2(Vector2(lx - 2 * P, ly - 2 * P).round(), Vector2(7 * P, 7 * P)), Color(st["led_on"], 0.18 * on_t))
	_r(lx, ly, 3 * P, 3 * P, st["edge"])
	_r(lx + P * 0.5, ly + P * 0.5, 2 * P, 2 * P, led)
	_r(lx + P * 0.5, ly + P * 0.5, P, P, led.lightened(0.55 * on_t))
