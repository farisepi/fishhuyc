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

	_hide_all()
	
	if controller_path:
		var node = get_node_or_null(controller_path)
		if node is ChatterController:
			bind(node)

func _process(_delta: float) -> void:
	if _controller == null or not _controller.is_active():
		return
	_update_display()

# ---------------------------------------------------------------------------
# Публичный API
# ---------------------------------------------------------------------------

func bind(controller: ChatterController) -> void:
	if _controller:
		_controller.chatter_stopped.disconnect(_on_stopped)
	_controller = controller
	_controller.chatter_stopped.connect(_on_stopped)

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
	
	# Автовысота если не задана
	var line = _controller._current_line
	if line and line.panel_height > 0:
		_near_panel.size = Vector2(_controller.near_panel_width, line.panel_height)
	else:
		# Авто: ~15px на строку
		var auto_h = max(28.0, ceil(text.length() / 11.0) * 15.0 + 15.0)
		_near_panel.size = Vector2(_controller.near_panel_width, auto_h)
	
	_near_label.position = Vector2(4, 4)
	_near_label.size = _near_panel.size - Vector2(8, 8)
	
	if _near_label.text != text:
		_near_label.text = text



# ---------------------------------------------------------------------------
# Far mode
# ---------------------------------------------------------------------------

func _show_far(text: String, fade: float, phantom_alpha: float) -> void:
	if _near_panel:
		_near_panel.visible = false
	
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

func _hide_all() -> void:
	if _near_panel:    _near_panel.visible = false
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
	var panel = _near_panel if (_near_panel and _near_panel.visible) \
		else (_far_panel if (_far_panel and _far_panel.visible) else null)
	if not panel:
		return
	var orig = panel.position
	var t = create_tween()
	t.set_loops(3)
	t.tween_property(panel, "position:x", orig.x + 5, 0.04)
	t.tween_property(panel, "position:x", orig.x - 5, 0.04)
	t.tween_property(panel, "position:x", orig.x,     0.04)
