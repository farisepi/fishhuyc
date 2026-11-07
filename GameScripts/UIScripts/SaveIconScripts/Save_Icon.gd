extends Control
## The "saving" sign: a little air bubble with our fish swimming round inside it, a few tiny
## bubbles rising and a ring of dots running around the bubble. Pixel art drawn in code
## (1 art pixel = PX screen pixels). Used in the corner while the game saves and on the boot
## screen ("do not close the game while you see this sign").

const PX := 3.0
const N := 24            # art pixels across
var t := 0.0

const C_RING := Color8(150, 220, 255)
const C_RING_D := Color8(60, 120, 170)
const C_WATER := Color8(16, 48, 78)
const C_FISH := Color8(84, 150, 222)
const C_FISH_D := Color8(40, 84, 150)
const C_BELLY := Color8(226, 90, 74)
const C_EYE := Color8(250, 250, 250)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(N, N) * PX
	size = custom_minimum_size
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _px(x: float, y: float, col: Color, w: float = 1.0, h: float = 1.0) -> void:
	draw_rect(Rect2(floor(x) * PX, floor(y) * PX, w * PX, h * PX), col)


func _draw() -> void:
	var c = Vector2(N, N) * 0.5
	var r = 8.0
	# water inside the bubble + its rim (a pixel circle)
	for y in range(N):
		for x in range(N):
			var d = Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= r - 0.6:
				_px(x, y, C_WATER)
			elif d <= r + 0.4:
				var lit = (x + 0.5 - c.x) + (y + 0.5 - c.y) < -2.0
				_px(x, y, C_RING if lit else C_RING_D)
	# glare
	_px(c.x - 5, c.y - 5, Color(1, 1, 1, 0.85))
	_px(c.x - 6, c.y - 3, Color(1, 1, 1, 0.6))
	# the fish swims around inside
	var a = t * 2.4
	var fp = c + Vector2(cos(a), sin(a) * 0.55) * 3.6
	var dir = 1.0 if -sin(a) >= 0.0 else -1.0
	var bob = round(sin(t * 9.0) * 0.4)
	fp = fp.round()
	fp.y += bob
	# body 5x3, tail 2, eye
	_px(fp.x - 2, fp.y - 1, C_FISH, 5, 3)
	_px(fp.x - 1, fp.y - 2, C_FISH_D, 3, 1)
	_px(fp.x - 2, fp.y + 1, C_BELLY, 4, 1)
	var tail_x = fp.x - 3 if dir > 0.0 else fp.x + 3
	var wag = 1 if int(t * 10.0) % 2 == 0 else 0
	_px(tail_x, fp.y - 1 + wag, C_FISH_D, 1, 2)
	var eye_x = fp.x + 1 if dir > 0.0 else fp.x - 1
	_px(eye_x, fp.y - 1, C_EYE)
	# tiny bubbles rising inside
	for i in range(3):
		var k = fmod(t * 0.9 + i * 0.33, 1.0)
		var bx = c.x - 3 + i * 3 + round(sin(t * 3.0 + i) * 0.6)
		var by = c.y + 5 - k * 10.0
		if Vector2(bx, by).distance_to(c) < r - 1.5:
			_px(bx, by, Color(0.75, 0.92, 1.0, 1.0 - k * 0.7))
	# the running ring of dots around the bubble (8 places, a fading trail)
	for i in range(8):
		var ang = i * TAU / 8.0 - PI / 2.0
		var pos = c + Vector2(cos(ang), sin(ang)) * (r + 2.6)
		var head = fmod(t * 8.0, 8.0)
		var behind = fposmod(head - i, 8.0)
		var alpha = clamp(1.0 - behind / 4.0, 0.15, 1.0)
		var col = Color8(255, 196, 80) if behind < 1.0 else Color(C_RING, alpha)
		_px(round(pos.x - 0.5), round(pos.y - 0.5), col)
