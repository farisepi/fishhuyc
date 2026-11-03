extends Camera2D

var decay_speed: float = 0.3
var max_offset: Vector2 = Vector2(25, 15)
var trauma: float = 0.0
var external_offset: Vector2 = Vector2.ZERO
## Shake strength multiplier (the earthquake sets 3).
var shake_mult: float = 1.0
## The shake may reach this far (e.g. the edge of the background) - a bit beyond the limits,
## so a camera standing at a limit still shakes. Empty = the limits.
var shake_bounds: Rect2 = Rect2()

var target_offset: Vector2 = Vector2.ZERO
var smooth_offset: Vector2 = Vector2.ZERO
var look_amount: float = 30.0
var look_speed: float = 4.0

## The camera follows its parent itself (smoothly, clamped to the limits), so smoothing,
## limits and offsets always agree - no more twitching at the edges of the location.
## A cutscene turns this off and moves the camera by itself.
var follow_enabled: bool = true
var follow_speed: float = 5.0
var _follow: Node2D = null
var _pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_follow = get_parent() as Node2D
	_pos = global_position
	if _follow:
		_pos = _follow.global_position
		position_smoothing_enabled = false
		top_level = true
		global_position = _pos

## Cutscene start: the camera stops exactly where it is on screen right now (the
## look-around offset is baked into its position instead of sliding back to zero),
## stops following the fish and from now on only moves when the cutscene moves it.
func begin_cutscene() -> void:
	var half = get_viewport_rect().size / zoom / 2.0
	var base = global_position
	if _has_limits():
		base.x = _clamp_axis(base.x, limit_left, limit_right, half.x)
		base.y = _clamp_axis(base.y, limit_top, limit_bottom, half.y)
	var center = base + _clamp_offset(external_offset + smooth_offset)
	follow_enabled = false
	look_amount = 0.0
	smooth_offset = Vector2.ZERO
	target_offset = Vector2.ZERO
	external_offset = Vector2.ZERO
	global_position = center
	_pos = center


func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

func set_external_offset(off: Vector2) -> void:
	external_offset = off

func _process(delta: float) -> void:
	var trauma_offset = Vector2.ZERO
	if trauma > 0:
		var shake = trauma * trauma
		trauma_offset = Vector2(
			randf_range(-shake * max_offset.x, shake * max_offset.x),
			randf_range(-shake * max_offset.y, shake * max_offset.y)
		) * shake_mult
		trauma = max(trauma - decay_speed * delta, 0.0)
	
	var parent = get_parent()
	if parent:
		var input_dir = Vector2.ZERO
		input_dir.x = Input.get_axis("ui_left", "ui_right")
		input_dir.y = Input.get_axis("ui_up", "ui_down")
		target_offset = input_dir * look_amount
		smooth_offset = smooth_offset.lerp(target_offset, look_speed * delta)
	
	_fit_zoom()
	if follow_enabled and _follow and is_instance_valid(_follow) and not get_tree().paused:
		var k = 1.0 - exp(-follow_speed * delta)
		_pos = _pos.lerp(_follow.global_position, k)
		if _has_limits():
			var half = get_viewport_rect().size / zoom / 2.0
			_pos.x = _clamp_axis(_pos.x, limit_left, limit_right, half.x)
			_pos.y = _clamp_axis(_pos.y, limit_top, limit_bottom, half.y)
		global_position = _pos
	elif not follow_enabled:
		_pos = global_position
	var calm = _clamp_offset(external_offset + smooth_offset)
	offset = _clamp_shake(calm, trauma_offset)


## The camera never shows anything outside its limits (outside the location):
## - on a wide window the view is wider than the location -> zoom in just enough;
## - offset (look-around, shake, cutscene pans) is not limited by Camera2D itself -> clamp it.
func _has_limits() -> bool:
	return limit_left > -100000 and limit_right < 100000 and limit_top > -100000 and limit_bottom < 100000


func _fit_zoom() -> void:
	if not _has_limits():
		return
	var vp = get_viewport_rect().size
	var need = max(vp.x / float(max(1, limit_right - limit_left)), vp.y / float(max(1, limit_bottom - limit_top)))
	if zoom.x < need or zoom.y < need:
		zoom = Vector2(max(zoom.x, need), max(zoom.y, need))


func _clamp_axis(v: float, lo: float, hi: float, half: float) -> float:
	if hi - lo <= half * 2.0:
		return (lo + hi) * 0.5
	return clamp(v, lo + half, hi - half)


func _clamp_shake(calm: Vector2, shake: Vector2) -> Vector2:
	if shake == Vector2.ZERO or not _has_limits():
		return calm + shake
	var b = shake_bounds
	if b.size == Vector2.ZERO:
		b = Rect2(limit_left, limit_top, limit_right - limit_left, limit_bottom - limit_top)
	var half = get_viewport_rect().size / zoom / 2.0
	var base = global_position
	base.x = _clamp_axis(base.x, limit_left, limit_right, half.x)
	base.y = _clamp_axis(base.y, limit_top, limit_bottom, half.y)
	# the shake may use the limits AND the extra bounds
	b = b.merge(Rect2(limit_left, limit_top, limit_right - limit_left, limit_bottom - limit_top))
	var c = base + calm
	# symmetric: as much room down as up (and left as right), so a camera standing at
	# an edge does not drift away from it on average while shaking
	var room_lo = c - (b.position + half)
	var room_hi = (b.end - half) - c
	var mx = max(0.0, min(room_lo.x, room_hi.x))
	var my = max(0.0, min(room_lo.y, room_hi.y))
	shake.x = clamp(shake.x, -mx, mx)
	shake.y = clamp(shake.y, -my, my)
	return calm + shake


func _clamp_offset(off: Vector2) -> Vector2:
	if not _has_limits():
		return off
	var half = get_viewport_rect().size / zoom / 2.0
	var base = global_position
	base.x = _clamp_axis(base.x, limit_left, limit_right, half.x)
	base.y = _clamp_axis(base.y, limit_top, limit_bottom, half.y)
	var want = base + off
	want.x = _clamp_axis(want.x, limit_left, limit_right, half.x)
	want.y = _clamp_axis(want.y, limit_top, limit_bottom, half.y)
	return want - base
