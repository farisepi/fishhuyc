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


## Factory menus: a screen-wide grade over the whole menu (background + buttons + logo) so the
## interface blends into the room. Adds a top CanvasLayer with a full-screen shader rect.
const MENU_GRADE_SHADER := "res://GameShaders/SharedShaders/Shared_MenuGrade_Shader.gdshader"

static func attach_grade(host: Node) -> void:
	if host == null or not ResourceLoader.exists(MENU_GRADE_SHADER):
		return
	if host.has_node("MenuGradeLayer"):
		return
	var layer = CanvasLayer.new()
	layer.name = "MenuGradeLayer"
	layer.layer = 100
	var r = ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	var m = ShaderMaterial.new()
	m.shader = load(MENU_GRADE_SHADER)
	r.material = m
	layer.add_child(r)
	host.add_child(layer)
	# buttons and the logo a little dimmer, so they don't shine out of the dark room
	var dim = func():
		if not is_instance_valid(host):
			return
		_dim_controls(host)
		var lg = host.get_node_or_null("LogoArea/LogoAnimation")
		if lg is CanvasItem:
			lg.self_modulate = Color(0.8, 0.8, 0.82)
	if host.is_inside_tree():
		host.get_tree().process_frame.connect(dim, CONNECT_ONE_SHOT)

static func _dim_controls(n: Node) -> void:
	for c in n.get_children():
		if c is BaseButton:
			c.self_modulate = Color(0.82, 0.82, 0.84)
		if not (c is CanvasLayer and c.name == "MenuGradeLayer"):
			_dim_controls(c)


## ---------------------------------------------------------------- scroll bars
## Every list that scrolls (settings, saves, achievements, the journal, dropdowns) uses the
## game's own scroll line + scroller textures (factory or aquarium), drawn at 2x, pixel-sharp.
const SCROLL_TEX := {
	false: ["res://GameAssets/Sprites/UserInterfaceSprites/FactoryMenuSprites/ScrollerTextures/Menu_Factory_ScrollLine_Texture.png",
			"res://GameAssets/Sprites/UserInterfaceSprites/FactoryMenuSprites/ScrollerTextures/Menu_Factory_Scroller_Texture.png"],
	true: ["res://GameAssets/Sprites/UserInterfaceSprites/AquariumMenuUITextures/ScrollerTextures/Menu_Aquarium_ScrollLine_Texture.png",
			"res://GameAssets/Sprites/UserInterfaceSprites/AquariumMenuUITextures/ScrollerTextures/Menu_Aquarium_Scroller_Texture.png"],
}
const SCROLL_PX := 2
static var _scroll_themes: Dictionary = {}

static func _px_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var t = load(path) as Texture2D
	if t == null:
		return null
	var img = t.get_image()
	if img == null:
		return t
	if img.is_compressed():
		img.decompress()
	img.resize(img.get_width() * SCROLL_PX, img.get_height() * SCROLL_PX, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)

static func _scroll_box(tex: Texture2D, cap: int, tint: Color = Color.WHITE, cap_bottom: int = -1) -> StyleBoxTexture:
	var sb = StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_top = cap * SCROLL_PX
	sb.texture_margin_bottom = (cap if cap_bottom < 0 else cap_bottom) * SCROLL_PX
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.modulate_color = tint
	sb.content_margin_left = tex.get_width() * 0.5 if tex else 5.0
	sb.content_margin_right = tex.get_width() * 0.5 if tex else 5.0
	return sb

static func scroll_theme(aqua: bool) -> Theme:
	if _scroll_themes.has(aqua):
		return _scroll_themes[aqua]
	var th = Theme.new()
	var line = _px_tex(SCROLL_TEX[aqua][0])
	var grab = _px_tex(SCROLL_TEX[aqua][1])
	if line and grab:
		var bg = _scroll_box(line, 4)
		th.set_stylebox("scroll", "VScrollBar", bg)
		th.set_stylebox("scroll_focus", "VScrollBar", bg)
		# the middle 4 rows repeat evenly (stripe, gap, stripe, gap); the last stripe joins the cap
		th.set_stylebox("grabber", "VScrollBar", _scroll_box(grab, 2, Color.WHITE, 3))
		th.set_stylebox("grabber_highlight", "VScrollBar", _scroll_box(grab, 2, Color(1.15, 1.15, 1.15), 3))
		th.set_stylebox("grabber_pressed", "VScrollBar", _scroll_box(grab, 2, Color(0.85, 0.85, 0.85), 3))
		for icon in ["increment", "increment_highlight", "increment_pressed", "decrement", "decrement_highlight", "decrement_pressed"]:
			th.set_icon(icon, "VScrollBar", ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8)))
	_scroll_themes[aqua] = th
	return th

## Gives every scroll bar under `root` the game's scroll textures (now and for lists built later).
## edge = true (menus): the scroll bar of a list is moved out to the right edge of the screen
## instead of sticking to the list's side.
static func style_scrolls(root: Node, aqua: bool, edge: bool = false) -> void:
	if root == null:
		return
	var th = scroll_theme(aqua)
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is ScrollContainer or n is RichTextLabel or n is ItemList or n is TextEdit or n is Tree:
			n.theme = th
			n.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if edge and n is ScrollContainer:
				_edge_scrollbar(n, th)
		elif n is OptionButton:
			n.get_popup().theme = th
		elif n is PopupMenu:
			n.theme = th
		for c in n.get_children():
			stack.append(c)
	if not root.child_entered_tree.is_connected(_on_scroll_child.bind(aqua, edge)):
		root.child_entered_tree.connect(_on_scroll_child.bind(aqua, edge))

static func _on_scroll_child(n: Node, aqua: bool, edge: bool) -> void:
	if n is ScrollContainer or n is OptionButton or n is RichTextLabel or n is ItemList:
		style_scrolls(n, aqua, edge)

const EDGE_SCROLL_MARGIN := 26.0

## Hides the list's own bar and puts a twin at the right screen edge, sharing its range (wheel,
## drag and clicks move the same list). It follows the list's height and shows only when the
## list is longer than its view.
static func _edge_scrollbar(sc: ScrollContainer, th: Theme) -> void:
	if sc.has_meta("edge_bar"):
		return
	var inner = sc.get_v_scroll_bar()
	if inner == null:
		return
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var bar = VScrollBar.new()
	bar.name = "EdgeScrollBar"
	bar.theme = th
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar.top_level = true
	bar.share(inner)
	sc.set_meta("edge_bar", bar)
	sc.add_child(bar, false, Node.INTERNAL_MODE_BACK)
	var upd = func():
		if not is_instance_valid(bar) or not is_instance_valid(sc):
			return
		var r = sc.get_global_rect()
		var vp = sc.get_viewport_rect().size
		var w = max(bar.get_combined_minimum_size().x, 10.0)
		bar.global_position = Vector2(vp.x - EDGE_SCROLL_MARGIN - w, r.position.y)
		bar.size = Vector2(w, r.size.y)
		bar.visible = sc.is_visible_in_tree() and (inner.max_value - inner.min_value) > inner.page + 0.5
		bar.modulate = Color(1, 1, 1, _alpha_chain(sc))   # fades with the menu
	sc.get_tree().process_frame.connect(upd)
	sc.tree_exiting.connect(func():
		if sc.get_tree() and sc.get_tree().process_frame.is_connected(upd):
			sc.get_tree().process_frame.disconnect(upd))

static func _alpha_chain(n: Node) -> float:
	var a := 1.0
	var c = n
	while c != null and c is CanvasItem:
		a *= c.modulate.a * c.self_modulate.a
		c = c.get_parent()
	return a
