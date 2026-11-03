## UI-нода диалогового окна. Отрисовывает near и far режимы.
## Путь: res://GameScripts/Dialogue/ChatterBox.gd
##
## Ожидаемая структура нод (все опциональны — если нет, скипается):
##
## ChatterBox [Node2D или CanvasLayer]
## ├── NearPanel      [NinePatchRect]  — маленькая панель у персонажа
## │   └── NearLabel  [RichTextLabel]
## ├── FarCanvas      [CanvasLayer]    — всё дальнее рисуется поверх
## │   ├── FarPanel         [NinePatchRect]
## │   │   ├── FarLabel     [RichTextLabel]
## │   │   └── FarPortrait  [TextureRect]
## │   ├── PhantomLeft      [NinePatchRect]
## │   │   ├── PhantomLeftLabel    [RichTextLabel]
## │   │   └── PhantomLeftPortrait [TextureRect]
## │   └── PhantomRight     [NinePatchRect]
## │       ├── PhantomRightLabel    [RichTextLabel]
## │       └── PhantomRightPortrait [TextureRect]
##
## Имена строго по схеме выше — ищутся через find_child().

class_name ChatterBox
extends Node

@export var controller_path: NodePath = NodePath()

# ---------------------------------------------------------------------------
# Ноды (найдутся автоматически)
# ---------------------------------------------------------------------------

var _near_panel:  NinePatchRect = null
var _near_label:  RichTextLabel = null

var _far_panel:    NinePatchRect = null
var _far_label:    RichTextLabel = null
var _far_portrait: TextureRect   = null

var _phantom_left:         NinePatchRect = null
var _phantom_left_label:   RichTextLabel = null
var _phantom_left_portrait: TextureRect  = null

var _phantom_right:         NinePatchRect = null
var _phantom_right_label:   RichTextLabel = null
var _phantom_right_portrait: TextureRect  = null

var _controller: ChatterController = null

# Плавный переход near <-> far
var _current_phantom_offset: float = 0.0

# Украшения near-панели: тень, хвостик к говорящему, табличка с именем
var _shadow: NinePatchRect = null
var _tail_outline: Polygon2D = null
var _tail_fill: Polygon2D = null
var _name_tag: Label = null
var _pop: float = 1.0
var _shake: float = 0.0
var _time: float = 0.0
const NAME_SCIENTIST := "УЧЁНЫЙ"
const NAME_MECHANIC := "МЕХАНИК"
const COLOR_SCIENTIST := Color(0.45, 0.85, 0.95)
const COLOR_MECHANIC := Color(1.0, 0.68, 0.3)

# ---------------------------------------------------------------------------

func _ready() -> void:
	_near_panel  = find_child("NearPanel",  true, false) as NinePatchRect
	_near_label  = find_child("NearLabel",  true, false) as RichTextLabel

	_far_panel    = find_child("FarPanel",    true, false) as NinePatchRect
	_far_label    = find_child("FarLabel",    true, false) as RichTextLabel
	_far_portrait = find_child("FarPortrait", true, false) as TextureRect

	_phantom_left          = find_child("PhantomLeft",         true, false) as NinePatchRect
	_phantom_left_label    = find_child("PhantomLeftLabel",    true, false) as RichTextLabel
	_phantom_left_portrait = find_child("PhantomLeftPortrait", true, false) as TextureRect

	_phantom_right          = find_child("PhantomRight",         true, false) as NinePatchRect
	_phantom_right_label    = find_child("PhantomRightLabel",    true, false) as RichTextLabel
	_phantom_right_portrait = find_child("PhantomRightPortrait", true, false) as TextureRect

	_make_decorations()
	_hide_all()
	
	if controller_path:
		var node = get_node_or_null(controller_path)
		if node is ChatterController:
			bind(node)

func _process(delta: float) -> void:
	_time += delta
	_pop = move_toward(_pop, 1.0, delta * 7.0)
	_shake = max(0.0, _shake - delta)
	if _controller == null or not _controller.is_active():
		return
	_update_display()


## Тень, хвостик и табличка с именем делаются из той же текстуры, что и панель.
func _make_decorations() -> void:
	if not _near_panel:
		return
	var parent = _near_panel.get_parent()
	_shadow = NinePatchRect.new()
	_shadow.texture = _near_panel.texture
	_shadow.patch_margin_left = _near_panel.patch_margin_left
	_shadow.patch_margin_right = _near_panel.patch_margin_right
	_shadow.patch_margin_top = _near_panel.patch_margin_top
	_shadow.patch_margin_bottom = _near_panel.patch_margin_bottom
	_shadow.modulate = Color(0, 0, 0, 0.35)
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_shadow)
	parent.move_child(_shadow, _near_panel.get_index())
	_tail_outline = Polygon2D.new()
	_tail_outline.color = Color(0.06, 0.07, 0.1)
	parent.add_child(_tail_outline)
	_tail_fill = Polygon2D.new()
	_tail_fill.color = Color(0.96, 0.97, 0.98)
	parent.add_child(_tail_fill)
	_name_tag = Label.new()
	_name_tag.add_theme_font_size_override("font_size", 10)
	_name_tag.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
	_name_tag.add_theme_constant_override("outline_size", 4)
	_name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_name_tag)


func _on_line_shown(_line: ChatterLine, _index: int) -> void:
	_pop = 0.0


func _on_swear() -> void:
	_shake = 0.35

# ---------------------------------------------------------------------------
# Публичный API
# ---------------------------------------------------------------------------

func bind(controller: ChatterController) -> void:
	if _controller:
		_controller.chatter_stopped.disconnect(_on_stopped)
	_controller = controller
	_controller.chatter_stopped.connect(_on_stopped)
	if not _controller.line_shown.is_connected(_on_line_shown):
		_controller.line_shown.connect(_on_line_shown)
	if _controller.has_signal("swear_typed") and not _controller.swear_typed.is_connected(_on_swear):
		_controller.swear_typed.connect(_on_swear)

# ---------------------------------------------------------------------------

func _on_stopped() -> void:
	_hide_all()

func _update_display() -> void:
	var mode = _controller.compute_display_mode()
	var text = _controller.get_typed_text()
	
	_current_phantom_offset = lerp(_current_phantom_offset, mode["fade"], 0.03)
	
	if mode["near"]:
		_show_near(text)
	else:
		_show_far(text, mode["fade"], mode["phantom_alpha"])

# ---------------------------------------------------------------------------
# Near mode
# ---------------------------------------------------------------------------

func _show_near(text: String) -> void:
	_hide_far()
	
	if not _near_panel or not _near_label:
		return
	
	_near_panel.visible = true
	_near_panel.z_index = 100
	_current_phantom_offset = 0.0
	
	_near_panel.position = _controller.get_near_panel_position()
	
	const LABEL_PADDING_X := 4
	const LABEL_PADDING_TOP := 6
	const LABEL_PADDING_BOTTOM := 4
	
	var pw = _controller.near_panel_width
	
	# Автовысота если не задана
	var line = _controller._current_line
	if line and line.panel_height > 0:
		_near_panel.size = Vector2(pw, line.panel_height)
	else:
		# Сначала даём label правильную ширину, чтобы get_content_height() считал перенос строк верно
		_near_label.position = Vector2(LABEL_PADDING_X, LABEL_PADDING_TOP)
		_near_label.size = Vector2(pw - LABEL_PADDING_X * 2, 200)
		if _near_label.text != text:
			_near_label.text = text
		# Ждём один кадр не нужно — get_content_height работает сразу после смены текста
		var content_h = _near_label.get_content_height()
		var auto_h = content_h + LABEL_PADDING_TOP + LABEL_PADDING_BOTTOM
		_near_panel.size = Vector2(pw, max(24.0, auto_h))
	
	_near_label.position = Vector2(LABEL_PADDING_X, LABEL_PADDING_TOP)
	_near_label.size = _near_panel.size - Vector2(LABEL_PADDING_X * 2, LABEL_PADDING_TOP + LABEL_PADDING_BOTTOM)
	
	# Текст мог быть уже установлен выше (в ветке auto-height); ставим если ещё нет
	if _near_label.text != text:
		_near_label.text = text
	_decorate_near()


## Появление с «пружинкой», лёгкое покачивание, тряска на ругательствах,
## тень, хвостик к говорящему и табличка с его именем.
func _decorate_near() -> void:
	var p = _near_panel
	var e = 1.0 - pow(1.0 - _pop, 3.0)
	var base = p.position
	base.y += round(sin(_time * 2.2) * 1.0) - (1.0 - e) * 6.0
	if _shake > 0.0:
		base.x += round(sin(_time * 80.0) * 3.0 * (_shake / 0.35))
	p.position = base
	p.pivot_offset = Vector2(p.size.x * 0.5, p.size.y)
	p.scale = Vector2.ONE * (0.8 + 0.2 * e)
	p.modulate.a = e
	var is_mech = _controller.get_current_speaker() == ChatterLine.Speaker.MECHANIC
	if _shadow:
		_shadow.visible = true
		_shadow.z_index = p.z_index - 1
		_shadow.size = p.size
		_shadow.pivot_offset = p.pivot_offset
		_shadow.scale = p.scale
		_shadow.position = p.position + Vector2(2, 2)
		_shadow.modulate.a = 0.35 * e
	# хвостик к персонажу
	var speaker: Node2D = _controller._mechanic if is_mech else _controller._scientist
	if _tail_fill and _tail_outline:
		var tx = p.size.x * 0.5
		if speaker:
			tx = clamp(speaker.global_position.x - p.position.x, 10.0, p.size.x - 10.0)
		var top = p.position + Vector2(tx, p.size.y - 2.0)
		_tail_outline.polygon = PackedVector2Array([top + Vector2(-6, 0), top + Vector2(6, 0), top + Vector2(0, 8)])
		_tail_fill.polygon = PackedVector2Array([top + Vector2(-4, -1), top + Vector2(4, -1), top + Vector2(0, 5)])
		for t in [_tail_outline, _tail_fill]:
			t.visible = true
			t.z_index = p.z_index
			t.modulate.a = e
	if _name_tag:
		_name_tag.visible = true
		_name_tag.z_index = p.z_index + 1
		_name_tag.text = NAME_MECHANIC if is_mech else NAME_SCIENTIST
		_name_tag.add_theme_color_override("font_color", COLOR_MECHANIC if is_mech else COLOR_SCIENTIST)
		_name_tag.position = p.position + Vector2(4, -13)
		_name_tag.modulate.a = e



# ---------------------------------------------------------------------------
# Far mode
# ---------------------------------------------------------------------------

func _show_far(text: String, fade: float, phantom_alpha: float) -> void:
	if _near_panel:
		_near_panel.visible = false
	_hide_decorations()
	
	if not _far_panel:
		return
	
	var vp = get_viewport().get_visible_rect().size
	var pw = _controller.far_panel_width
	var ph = _controller.far_panel_height
	var margin = _controller.far_panel_margin_bottom
	
	var target_x = vp.x * 0.5 - pw * 0.5
	var target_y = vp.y - margin - ph
	
	_far_panel.visible = true
	_far_panel.z_index = 100
	_far_panel.size = Vector2(pw, ph)
	_far_panel.position = Vector2(target_x, target_y)
	_far_panel.modulate.a = fade
	
	if _far_label:
		if _far_label.text != text:
			_far_label.text = text
		_far_label.position = Vector2(70, 10)
		_far_label.size = Vector2(pw - 80, ph - 20)
	
	var icon_size = 60.0
	var icon_y = (ph - icon_size) * 0.5
	if _far_portrait:
		_far_portrait.texture = _controller.get_current_portrait()
		_far_portrait.position = Vector2(5, icon_y)
		_far_portrait.size = Vector2(icon_size, icon_size)
		_far_portrait.modulate = Color(1, 1, 1, 0.8)
	
	# Фантомы
	var zoom = 1.0
	if _controller._camera:
		zoom = _controller._camera.zoom.x
	var ox = int(35.0 * _current_phantom_offset) / zoom
	var oy = int(25.0 * _current_phantom_offset) / zoom
	
	_update_phantom(_phantom_left, _phantom_left_label, _phantom_left_portrait,
		Vector2(target_x - ox, target_y + oy), pw, ph, phantom_alpha, text, icon_size, icon_y)
	
	_update_phantom(_phantom_right, _phantom_right_label, _phantom_right_portrait,
		Vector2(target_x + ox, target_y - oy), pw, ph, phantom_alpha, text, icon_size, icon_y)

func _update_phantom(panel: NinePatchRect, label: RichTextLabel, portrait: TextureRect,
		pos: Vector2, pw: float, ph: float, alpha: float, text: String,
		icon_size: float, icon_y: float) -> void:
	if not panel:
		return
	panel.visible = true
	panel.size = Vector2(pw, ph)
	panel.position = pos
	panel.modulate.a = alpha
	panel.z_index = 99
	if label:
		label.visible = true
		if label.text != text:
			label.text = text
		label.modulate.a = 0.4
		label.position = Vector2(70, 10)
		label.size = Vector2(pw - 80, ph - 20)
	if portrait:
		portrait.texture = _controller.get_current_portrait()
		portrait.position = Vector2(5, icon_y)
		portrait.size = Vector2(icon_size, icon_size)
		portrait.modulate = Color(1, 1, 1, 0.3)

# ---------------------------------------------------------------------------

func _hide_far() -> void:
	if _far_panel:    _far_panel.visible = false
	if _phantom_left:  _phantom_left.visible = false
	if _phantom_right: _phantom_right.visible = false

func _hide_decorations() -> void:
	for n in [_shadow, _tail_outline, _tail_fill, _name_tag]:
		if n:
			n.visible = false

func _hide_all() -> void:
	if _near_panel:    _near_panel.visible = false
	_hide_decorations()
	_hide_far()

# ---------------------------------------------------------------------------
# Глитч-эффект текста (вызывай извне когда нужен глитч)
# ---------------------------------------------------------------------------

func apply_glitch(intensity: float) -> void:
	if intensity <= 0.03:
		return
	var original = _controller.get_typed_text() if _controller else ""
	if original.is_empty():
		return
	
	var chars = original.split("")
	var up_count = max(1, int(intensity * chars.size() * 0.12))
	for i in range(up_count):
		var pos = randi() % chars.size()
		if chars[pos] != " ":
			chars[pos] = chars[pos].to_upper()
	var rm_count = max(1, int(intensity * chars.size() * 0.08))
	for i in range(rm_count):
		var pos = randi() % chars.size()
		if chars[pos] != " ":
			chars[pos] = ""
	
	var glitched = "".join(chars)
	var red = Color(1.0, 0.4, 0.4)
	
	for lbl in [_near_label, _far_label, _phantom_left_label, _phantom_right_label]:
		if lbl and lbl.visible:
			lbl.text = glitched
			lbl.add_theme_color_override("default_color", red)
	
	await get_tree().create_timer(0.06).timeout
	
	var restored = _controller.get_typed_text() if _controller else ""
	for lbl in [_near_label, _far_label, _phantom_left_label, _phantom_right_label]:
		if lbl and lbl.visible:
			lbl.text = restored
			lbl.remove_theme_color_override("default_color")

# ---------------------------------------------------------------------------
# Встряска панели
# ---------------------------------------------------------------------------

func shake_panel() -> void:
	_shake = 0.35
