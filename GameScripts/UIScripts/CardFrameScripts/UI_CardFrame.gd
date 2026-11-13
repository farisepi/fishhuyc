extends Control

const ACCENT := Color8(255, 168, 60)

var accent: Color = ACCENT

static func make(acc: Color = ACCENT) -> Control:
	var f = load("res://GameScripts/UIScripts/CardFrameScripts/UI_CardFrame.gd").new()
	f.accent = acc
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.show_behind_parent = true
	return f

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

static func paint(c: CanvasItem, sz: Vector2, acc: Color) -> void:
	c.draw_rect(Rect2(Vector2(3, 4), sz), Color(0, 0, 0, 0.5))
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color8(8, 9, 12))
	c.draw_rect(Rect2(2, 2, sz.x - 4, sz.y - 4), Color8(46, 50, 60))
	c.draw_rect(Rect2(2, 2, sz.x - 4, 1), Color8(110, 116, 130))
	c.draw_rect(Rect2(3, 3, sz.x - 6, sz.y - 6), Color8(20, 22, 28))
	var x := 3.0
	var k := 0
	while x < sz.x - 3.0:
		var w = min(6.0, sz.x - 3.0 - x)
		c.draw_rect(Rect2(x, 3, w, 3), acc if k % 2 == 0 else Color8(30, 24, 16))
		x += 6.0
		k += 1

func _draw() -> void:
	var sz = size
	if sz.x < 2.0 and get_parent() is Control:
		sz = get_parent().size
	paint(self, sz, accent)
