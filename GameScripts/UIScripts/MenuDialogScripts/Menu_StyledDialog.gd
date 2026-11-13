extends CanvasLayer

signal custom_action(action: String)
signal close_requested

const FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
const TEX := {
	"factory": {
		"panel": "res://GameAssets/Sprites/UserInterfaceSprites/FactoryMenuSprites/FactoryMenuUITextures/FactoryMiniMenuTextures/Menu_Factory_MiniMenu_Texture.png",
		"button": "res://GameAssets/Sprites/UserInterfaceSprites/FactoryMenuSprites/FactoryMenuButtonTextures/SmallButtonTextures/Menu_Factory_Button_Small_Texture.png",
	},
	"aquarium": {
		"panel": "res://GameAssets/Sprites/UserInterfaceSprites/AquariumMenuUITextures/AquariumMiniMenuTextures/Menu_Aquarium_MiniMenu_Texture.png",
		"button": "res://GameAssets/Sprites/UserInterfaceSprites/AquariumMenuSprites/AquariumMenuButtonTextures/SmallButtonTextures/Menu_Aquarium_Button_Small_Texture.png",
	},
}

var style := "factory"
var title := ""
var dialog_text := ""
var _buttons: Array = []
var _dim: ColorRect = null
var _panel: Control = null
var _font: FontFile = null
var _closing := false


func add_button(text: String, _right: bool = true, action: String = "") -> void:
	_buttons.append([text, action])


func add_cancel_button(text: String) -> void:
	_buttons.append([text, "__cancel"])


func get_ok_button() -> Button:
	return null


func add_theme_font_override(_n, _f) -> void:
	pass


func add_theme_font_size_override(_n, _s) -> void:
	pass


func popup_centered(_size = Vector2i.ZERO) -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = ResourceLoader.load(FONT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
	if _font:
		_font.fixed_size = 0
		var g = get_node_or_null("/root/Global")
		if g and g.get("_font") and g._font:
			_font.fallbacks = g._font.fallbacks
	if not TEX.has(style):
		style = "factory"
	var vp = Vector2(1152, 648)
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.0)
	_dim.size = vp
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)
	_panel = Control.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var accent = Color8(255, 168, 60) if style == "factory" else Color8(140, 215, 255)
	var text_col = Color(0.92, 0.93, 0.95)
	var pad := 30.0
	var bw := 138.0
	var btn_fs := 15
	if _font:
		for b in _buttons:
			bw = max(bw, _font.get_string_size(String(b[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, btn_fs).x + 30.0)
	bw = ceil(bw / PX) * PX
	var w := 450.0
	w = max(w, _buttons.size() * bw + max(0, _buttons.size() - 1) * 18.0 + pad * 2.0)
	if _font:
		w = max(w, min(900.0, _font.get_string_size(title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + pad * 2.0 + 10.0))
	w = min(round(w / PX) * PX, 1050.0)
	while _font and btn_fs > 9 and _buttons.size() * bw + max(0, _buttons.size() - 1) * 18.0 + pad * 2.0 > w:
		btn_fs -= 1
		bw = 138.0
		for b in _buttons:
			bw = max(bw, _font.get_string_size(String(b[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, btn_fs).x + 30.0)
	var title_l = _label(title.to_upper(), 20, accent)
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var text_l = _label(dialog_text, 15, text_col)
	text_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_l.add_theme_constant_override("line_spacing", 4)
	var bg = _nine(TEX[style]["panel"], 4)
	_panel.add_child(bg)
	_panel.add_child(title_l)
	_panel.add_child(text_l)
	title_l.position = Vector2(pad, 24)
	title_l.size = Vector2(w - pad * 2.0, 26)
	_fit(title_l, 20)
	for side in [-1.0, 1.0]:
		var rule = ColorRect.new()
		rule.color = Color(accent, 0.6)
		rule.size = Vector2(w * 0.5 - pad - 18.0, PX)
		rule.position = Vector2(w * 0.5 + (12.0 if side > 0 else -12.0 - rule.size.x), 57)
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel.add_child(rule)
	var dia = Polygon2D.new()
	dia.color = accent
	dia.polygon = PackedVector2Array([Vector2(0, -6), Vector2(6, 0), Vector2(0, 6), Vector2(-6, 0)])
	dia.position = Vector2(w * 0.5, 58.5)
	_panel.add_child(dia)
	text_l.position = Vector2(pad, 74)
	text_l.size = Vector2(w - pad * 2.0, 0)
	text_l.size = Vector2(w - pad * 2.0, 0)
	var th = 20.0
	if _font:
		var ms = _font.get_multiline_string_size(dialog_text, HORIZONTAL_ALIGNMENT_CENTER, w - pad * 2.0, 15)
		var lines = max(1, int(round(ms.y / max(1.0, _font.get_height(15)))))
		th = lines * (_font.get_height(15) + 4.0)
	text_l.size = Vector2(w - pad * 2.0, th)
	var by = round((74.0 + th + 26.0) / PX) * PX
	var bh := 42.0
	var gap := 18.0
	var total = _buttons.size() * bw + max(0, _buttons.size() - 1) * gap
	var x0 = round((w - total) * 0.5 / PX) * PX
	for i in range(_buttons.size()):
		var b = _make_button(_buttons[i][0], accent, Vector2(bw, bh))
		b.add_theme_font_size_override("font_size", btn_fs)
		b.position = Vector2(x0 + i * (bw + gap), by)
		var act: String = _buttons[i][1]
		b.pressed.connect(_on_button.bind(act))
		_panel.add_child(b)
	var h = round((by + bh + 26.0) / PX) * PX
	bg.size = Vector2(w, h) / PX
	_panel.size = Vector2(w, h)
	_panel.position = ((vp - _panel.size) * 0.5).round()
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.85, 0.85)
	_panel.modulate.a = 0.0
	var tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(_dim, "color:a", 0.6, 0.18)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if has_node("/root/UISounds"):
		get_node("/root/UISounds").play_click()


func _fit(l: Label, base: int) -> void:
	if _font == null:
		return
	var sz = base
	while sz > 9 and _font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + 6.0 > l.size.x:
		sz -= 1
	l.add_theme_font_size_override("font_size", sz)


func _label(text: String, size: int, col: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _font:
		l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("outline_size", 3)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return l


const PX := 3.0

func _nine(path: String, margin: int) -> NinePatchRect:
	var n = NinePatchRect.new()
	n.texture = load(path)
	n.patch_margin_left = margin
	n.patch_margin_right = margin
	n.patch_margin_top = margin
	n.patch_margin_bottom = margin
	n.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	n.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	n.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.scale = Vector2(PX, PX)
	return n


func _make_button(text: String, accent: Color, sz: Vector2) -> Button:
	var b = Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.size = sz
	b.custom_minimum_size = sz
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var face = _nine(TEX[style]["button"], 5)
	face.size = sz / PX
	face.show_behind_parent = true
	b.add_child(face)
	b.mouse_entered.connect(func():
		face.modulate = Color(1.3, 1.3, 1.3)
		ButtonEffects._apply_glass_effect(b))
	b.mouse_exited.connect(func():
		face.modulate = Color.WHITE
		ButtonEffects._remove_glass_effect(b))
	b.button_down.connect(func(): face.modulate = Color(0.8, 0.8, 0.8))
	b.button_up.connect(func(): face.modulate = Color(1.3, 1.3, 1.3) if b.is_hovered() else Color.WHITE)
	if _font:
		b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color(0.92, 0.93, 0.95))
	b.add_theme_color_override("font_hover_color", accent)
	b.add_theme_color_override("font_pressed_color", accent.darkened(0.2))
	b.mouse_entered.connect(func():
		b.pivot_offset = b.size * 0.5
		var t = b.create_tween()
		t.tween_property(b, "scale", Vector2(1.06, 1.06), 0.08)
		if has_node("/root/UISounds") and get_node("/root/UISounds").has_method("play_hover"):
			get_node("/root/UISounds").play_hover()
	)
	b.mouse_exited.connect(func():
		var t = b.create_tween()
		t.tween_property(b, "scale", Vector2.ONE, 0.1)
	)
	return b


func _on_button(action: String) -> void:
	if _closing:
		return
	if has_node("/root/UISounds"):
		get_node("/root/UISounds").play_click()
	if action == "__cancel":
		_request_close()
		return
	custom_action.emit(action)


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_request_close()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_request_close()


func _request_close() -> void:
	close_requested.emit()
	if is_instance_valid(self) and not is_queued_for_deletion():
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	var tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(_dim, "color:a", 0.0, 0.12)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(queue_free)
