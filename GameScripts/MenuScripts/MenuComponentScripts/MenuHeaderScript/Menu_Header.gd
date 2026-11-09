extends Control
class_name MenuHeader
## A big menu title like in the pause menu: the word drops in and glows in the accent colour,
## a light line opens under it, and the glow breathes slowly.
##   MenuHeader.attach(self, "НАСТРОЙКИ", MenuHeader.accent_for(self), 14.0)

const FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
const FACTORY_ACCENT := Color8(255, 168, 60)
const AQUA_ACCENT := Color8(130, 210, 255)

var _title: Label = null
var _line: ColorRect = null
var _accent := FACTORY_ACCENT
var _t := 0.0
var _line_w := 220.0

static func accent_for(n: Node) -> Color:
	var p = n.scene_file_path if n.scene_file_path != "" else String(n.get_script().resource_path if n.get_script() else "")
	return AQUA_ACCENT if "Aquarium" in p else FACTORY_ACCENT

static func make_font() -> FontFile:
	var f = ResourceLoader.load(FONT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
	if f:
		f.fixed_size = 0
	return f

static func attach(parent: Node, text: String, accent: Color, y: float, size: int = 36, line_w: float = 220.0) -> MenuHeader:
	var h := MenuHeader.new()
	h._accent = accent
	h._line_w = line_w
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.position = Vector2(0, y)
	h.size = Vector2(1152, size + 24)
	parent.add_child(h)
	h._build(text, size)
	return h

func _build(text: String, fsize: int) -> void:
	_title = Label.new()
	_title.text = text
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f = make_font()
	if f:
		_title.add_theme_font_override("font", f)
	_title.add_theme_font_size_override("font_size", fsize)
	_title.add_theme_color_override("font_color", _accent)
	_title.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.05))
	_title.add_theme_constant_override("outline_size", 8)
	_title.add_theme_color_override("font_shadow_color", Color(_accent, 0.35))
	_title.add_theme_constant_override("shadow_offset_x", 0)
	_title.add_theme_constant_override("shadow_offset_y", 0)
	_title.add_theme_constant_override("shadow_outline_size", 22)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.size = Vector2(600, fsize + 14)
	_title.position = Vector2(276, -20)
	_title.pivot_offset = _title.size * 0.5
	_title.scale = Vector2(1.25, 1.25)
	_title.modulate.a = 0.0
	add_child(_title)
	_line = ColorRect.new()
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.color = Color(_accent, 0.8)
	_line.size = Vector2(0, 3)
	_line.position = Vector2(576, fsize + 16)
	add_child(_line)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(_title, "modulate:a", 1.0, 0.2).set_delay(0.08)
	tw.tween_property(_title, "position:y", 0.0, 0.35).set_delay(0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_title, "scale", Vector2.ONE, 0.3).set_delay(0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_line, "size:x", _line_w, 0.35).set_delay(0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_line, "position:x", 576.0 - _line_w * 0.5, 0.35).set_delay(0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_t += delta
	if _title:
		var k = 0.5 + 0.5 * sin(_t * 1.6)
		_title.add_theme_color_override("font_shadow_color", Color(_accent, 0.22 + 0.2 * k))


## ---- small section header for settings pages: "ЭКРАН ———"
static func section(parent: Control, text: String, accent: Color, pos: Vector2, width: float) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = pos
	c.size = Vector2(width, 22)
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f = make_font()
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", accent)
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.05))
	l.add_theme_constant_override("outline_size", 5)
	l.position = Vector2(0, 0)
	c.add_child(l)
	var tw = 0.0
	if f:
		tw = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var line := ColorRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.color = Color(accent, 0.45)
	line.position = Vector2(tw + 12.0, 11)
	line.size = Vector2(max(0.0, width - tw - 12.0), 2)
	c.add_child(line)
	parent.add_child(c)
	return c


## ---- minimal text tabs: grey words, the active one in the accent colour with a bar under it
static func style_tab(b: Button, accent: Color) -> void:
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(s, empty)
	var f = make_font()
	if f:
		b.add_theme_font_override("font", f)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.05))
	b.add_theme_constant_override("outline_size", 5)
	b.add_theme_color_override("font_hover_color", accent.lerp(Color.WHITE, 0.5))
	b.focus_mode = Control.FOCUS_NONE
	for ch in b.get_children():
		if ch is Sprite2D:
			b.remove_child(ch)   # no rust / seaweed on the plain tabs (gone for good)
			ch.queue_free()

static func set_tab_active(b: Button, on: bool, accent: Color) -> void:
	b.modulate = Color.WHITE
	b.add_theme_color_override("font_color", accent if on else Color(0.55, 0.56, 0.6))
	b.add_theme_color_override("font_pressed_color", accent if on else Color(0.55, 0.56, 0.6))


## ---- a flat, quiet dropdown list
static func dropdown_panel_style(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.055, 0.07, 0.96)
	s.border_color = Color(accent, 0.55)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 2
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	return s
