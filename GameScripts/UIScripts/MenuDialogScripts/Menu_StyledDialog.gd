extends CanvasLayer
## A warning / question window in the style of the menu it is opened from ("factory": dark
## steel plate + hazard buttons, "aquarium": blue glass). Drop-in for the AcceptDialog the
## menus used: title, dialog_text, add_button(text, right, action), custom_action /
## close_requested signals, popup_centered(). Esc or a click outside closes it.

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
var _buttons: Array = []     # [text, action]
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


# the old code styled the AcceptDialog directly; here the style is built in
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
	# contents
	var w := 420.0
	var title_l = _label(title.to_upper(), 18, accent)
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var text_l = _label(dialog_text, 14, text_col)
	text_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bg = NinePatchRect.new()
	bg.texture = load(TEX[style]["panel"])
	bg.patch_margin_left = 6
	bg.patch_margin_right = 6
	bg.patch_margin_top = 6
	bg.patch_margin_bottom = 6
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(bg)
	_panel.add_child(title_l)
	_panel.add_child(text_l)
	title_l.position = Vector2(20, 18)
	title_l.size = Vector2(w - 40, 24)
	text_l.position = Vector2(28, 52)
	text_l.size = Vector2(w - 56, 0)
	text_l.size = Vector2(w - 56, 0)
	var th = max(1, text_l.get_line_count()) * (text_l.get_line_height() + 2)
	# hazard / glass accent line under the title
	var rule = ColorRect.new()
	rule.color = Color(accent, 0.55)
	rule.position = Vector2(60, 44)
	rule.size = Vector2(w - 120, 2)
	_panel.add_child(rule)
	var by = 52.0 + th + 18.0
	var bw := 130.0
	var gap := 16.0
	var total = _buttons.size() * bw + max(0, _buttons.size() - 1) * gap
	var x0 = (w - total) * 0.5
	for i in range(_buttons.size()):
		var b = _make_button(_buttons[i][0], accent)
		b.position = Vector2(x0 + i * (bw + gap), by)
		b.size = Vector2(bw, 36)
		var act: String = _buttons[i][1]
		b.pressed.connect(_on_button.bind(act))
		_panel.add_child(b)
	var h = by + 36.0 + 20.0
	bg.size = Vector2(w, h)
	_panel.size = Vector2(w, h)
	_panel.position = ((vp - _panel.size) * 0.5).round()
	_panel.pivot_offset = _panel.size * 0.5
	# open: dim fades in, the window pops with a little overshoot
	_panel.scale = Vector2(0.85, 0.85)
	_panel.modulate.a = 0.0
	var tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(_dim, "color:a", 0.6, 0.18)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if has_node("/root/UISounds"):
		get_node("/root/UISounds").play_click()


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


func _make_button(text: String, accent: Color) -> Button:
	var b = Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex = load(TEX[style]["button"])
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxTexture.new()
		sb.texture = tex
		sb.texture_margin_left = 5
		sb.texture_margin_right = 5
		sb.texture_margin_top = 5
		sb.texture_margin_bottom = 5
		if st == "hover":
			sb.modulate_color = Color(1.25, 1.25, 1.25)
		elif st == "pressed":
			sb.modulate_color = Color(0.8, 0.8, 0.8)
		b.add_theme_stylebox_override(st, sb)
	if _font:
		b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 14)
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


## Closes with a short fade (the menus call queue_free; this just looks nicer when used).
func close() -> void:
	if _closing:
		return
	_closing = true
	var tw = create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(_dim, "color:a", 0.0, 0.12)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(queue_free)
