extends CanvasLayer
class_name StorageNote

signal closed

var _panel: ColorRect = null
var _open_t: float = 0.0

static func open(parent: Node, title: String, text: String) -> StorageNote:
	var n = StorageNote.new()
	parent.add_child(n)
	n._build(title, text)
	return n

func _build(title: String, text: String) -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.size = Vector2(1152, 648)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_panel = ColorRect.new()
	_panel.color = Color(0.86, 0.82, 0.7)
	_panel.size = Vector2(500, 380)
	_panel.position = Vector2(326, 130)
	_panel.rotation = deg_to_rad(-1.5)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var edge = ColorRect.new()
	edge.color = Color(0.55, 0.5, 0.4)
	edge.size = Vector2(500, 4)
	edge.position = Vector2(0, 376)
	_panel.add_child(edge)
	var t = Label.new()
	t.text = title
	t.position = Vector2(24, 18)
	t.size = Vector2(392, 24)
	t.add_theme_font_size_override("font_size", 14)
	t.add_theme_color_override("font_color", Color(0.25, 0.12, 0.1))
	_panel.add_child(t)
	var body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 9)
	body.add_theme_constant_override("line_spacing", 5)
	body.add_theme_color_override("font_color", Color(0.16, 0.14, 0.12))
	_panel.add_child(body)
	body.position = Vector2(24, 50)
	body.custom_minimum_size = Vector2(452, 0)
	body.size = Vector2(452, 290)
	body.text = text
	var hint = Label.new()
	hint.text = tr("[E] — закрыть")
	hint.position = Vector2(24, 350)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.4, 0.36, 0.3))
	_panel.add_child(hint)
	_panel.modulate.a = 0.0
	_panel.position.y += 30
	var tw = create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.25)
	tw.tween_property(_panel, "position:y", 130.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	get_tree().paused = true

func _process(delta: float) -> void:
	_open_t += delta

func _input(event: InputEvent) -> void:
	if _open_t < 0.3:
		return
	var close = event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton and event.pressed:
		close = true
	if close:
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		closed.emit()
		queue_free()
