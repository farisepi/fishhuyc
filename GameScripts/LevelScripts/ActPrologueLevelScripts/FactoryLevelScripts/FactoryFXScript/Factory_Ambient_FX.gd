extends Node2D
## Factory atmosphere (added by the level script):
##  - the ceiling lamps hum and now and then stutter; the "bad" lamp sparks and dims,
##  - dust specks drift through the light,
##  - every press stroke: a hiss of hydraulic steam at the top, crumbs + a dust ring at the foot,
##  - the conveyor drops tiny glints on the rollers.

var level: Node2D = null
var _lamps: Array = []        # PointLight2D
var _lamp_base: Array = []
var _beams: Array = []        # beam ColorRects (shader "intensity")
var _beam_base: Array = []
var _t := 0.0
var _acc := 0.0
var _blink := -1
var _blink_t := 0.0
var _next_blink := 3.0
var _bad_lamp := 3
var _next_spark := 2.0
var _dot: ImageTexture = null
var _soft: ImageTexture = null


func setup(lvl: Node2D) -> void:
	level = lvl
	z_as_relative = false
	z_index = 27
	_dot = _make_dot(2)
	_soft = _make_soft(12)
	for i in range(12):
		var l = lvl.get_node_or_null("LampLight%d" % i) as PointLight2D
		if l == null:
			continue
		_lamps.append(l)
		_lamp_base.append(l.energy)
		var b = lvl.get_node_or_null("LampBeam%d" % i) as CanvasItem
		_beams.append(b)
		var v = 0.24
		if b and b.material is ShaderMaterial:
			var got = (b.material as ShaderMaterial).get_shader_parameter("intensity")
			if got != null:
				v = got
		_beam_base.append(v)
	_bad_lamp = min(3, _lamps.size() - 1)
	_add_dust()


func _make_dot(n: int) -> ImageTexture:
	var img = Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)


func _make_soft(n: int) -> ImageTexture:
	var img = Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c = Vector2(n, n) * 0.5
	for y in range(n):
		for x in range(n):
			var d = (Vector2(x + 0.5, y + 0.5) - c).length() / (n * 0.5)
			var a = clamp(1.0 - d, 0.0, 1.0)
			# pixel-stepped falloff
			a = floor(a * 4.0) / 4.0
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


## Slow dust specks over the whole hall (they show up mostly inside the light cones).
func _add_dust() -> void:
	var p = CPUParticles2D.new()
	p.texture = _dot
	p.amount = 90
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1300, 170)
	p.position = Vector2(700, 230)
	p.direction = Vector2(1, -0.2)
	p.spread = 180.0
	p.gravity = Vector2(0, 2)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 7.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	p.color = Color(1.0, 0.86, 0.6, 0.35)
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.2, Color(1, 1, 1, 1))
	g.add_point(0.8, Color(1, 1, 1, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = g
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(p)


func _process(delta: float) -> void:
	if get_tree().paused or _lamps.is_empty():
		return
	_t += delta
	_acc += delta
	if _acc < 1.0 / 30.0:
		return
	var dt = _acc
	_acc = 0.0
	_next_blink -= dt
	if _next_blink <= 0.0:
		_next_blink = randf_range(3.0, 8.0)
		_blink = randi() % _lamps.size()
		_blink_t = randf_range(0.15, 0.4)
	if _blink_t > 0.0:
		_blink_t -= dt
		if _blink_t <= 0.0:
			_blink = -1
	# the bad lamp: sparks from the socket and a hard flicker
	_next_spark -= dt
	var spark_now = false
	if _next_spark <= 0.0:
		_next_spark = randf_range(4.0, 11.0)
		spark_now = true
	for i in range(_lamps.size()):
		var hum = 1.0 + 0.04 * sin(_t * 7.1 + i * 1.7) + 0.025 * sin(_t * 16.3 + i * 3.9)
		if i == _blink:
			hum *= 0.3 if randf() < 0.5 else randf_range(0.6, 1.05)
		if i == _bad_lamp and spark_now:
			hum = 1.8
		var l: PointLight2D = _lamps[i]
		if is_instance_valid(l):
			l.energy = _lamp_base[i] * hum
		var b = _beams[i]
		if b and is_instance_valid(b) and b.material is ShaderMaterial:
			(b.material as ShaderMaterial).set_shader_parameter("intensity", _beam_base[i] * hum)
	if spark_now and _bad_lamp >= 0:
		var l2: PointLight2D = _lamps[_bad_lamp]
		if is_instance_valid(l2):
			sparks(l2.global_position + Vector2(0, -4), 10, true)


## Falling sparks (lamp socket) or a short burst (press).
func sparks(at: Vector2, count: int, falling: bool) -> void:
	var p = CPUParticles2D.new()
	p.texture = _dot
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = count
	p.lifetime = 0.9 if falling else 0.45
	p.position = at
	p.direction = Vector2(0, 1) if falling else Vector2(0, -1)
	p.spread = 70.0 if falling else 80.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0, 260)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var g = Gradient.new()
	g.set_color(0, Color(1.0, 0.98, 0.8, 1))
	g.set_color(1, Color(1.0, 0.45, 0.15, 0))
	p.color_ramp = g
	p.z_as_relative = false
	p.z_index = 60
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.4, false).timeout.connect(p.queue_free)


## One press stroke: steam hiss from the cylinder top, crumbs and a dust ring at the foot.
func press_impact(foot: Vector2, top: Vector2) -> void:
	# steam
	var s = CPUParticles2D.new()
	s.texture = _soft
	s.one_shot = true
	s.explosiveness = 0.7
	s.amount = 16
	s.lifetime = 1.1
	s.position = top
	s.direction = Vector2(0, -1)
	s.spread = 35.0
	s.initial_velocity_min = 14.0
	s.initial_velocity_max = 34.0
	s.gravity = Vector2(0, -8)
	s.damping_min = 6.0
	s.damping_max = 12.0
	s.scale_amount_min = 0.6
	s.scale_amount_max = 1.6
	var sc = Curve.new()
	sc.add_point(Vector2(0, 0.5))
	sc.add_point(Vector2(1, 1.6))
	s.scale_amount_curve = sc
	var g = Gradient.new()
	g.set_color(0, Color(0.9, 0.92, 0.96, 0.8))
	g.set_color(1, Color(0.7, 0.72, 0.78, 0.0))
	s.color_ramp = g
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_as_relative = false
	s.z_index = 17
	add_child(s)
	s.emitting = true
	get_tree().create_timer(1.6, false).timeout.connect(s.queue_free)
	# crumbs / dust ring at the foot
	var d = CPUParticles2D.new()
	d.texture = _dot
	d.one_shot = true
	d.explosiveness = 1.0
	d.amount = 14
	d.lifetime = 0.5
	d.position = foot
	d.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	d.emission_rect_extents = Vector2(16, 1)
	d.direction = Vector2(0, -1)
	d.spread = 75.0
	d.initial_velocity_min = 20.0
	d.initial_velocity_max = 55.0
	d.gravity = Vector2(0, 220)
	var g2 = Gradient.new()
	g2.set_color(0, Color(0.92, 0.88, 0.78, 0.9))
	g2.set_color(1, Color(0.6, 0.55, 0.5, 0.0))
	d.color_ramp = g2
	d.z_as_relative = false
	d.z_index = 45
	add_child(d)
	d.emitting = true
	get_tree().create_timer(0.9, false).timeout.connect(d.queue_free)
