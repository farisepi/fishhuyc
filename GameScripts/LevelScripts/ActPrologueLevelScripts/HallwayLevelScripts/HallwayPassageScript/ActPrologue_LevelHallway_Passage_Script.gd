extends Area2D


signal passage_completed

@export var required_presses: int = 6
@export var move_distance: float = 36.0
@export var step_time: float = 0.12
@export var exit_margin: float = 26.0
@export var key_button: TextureRect = null
@export var progress_ring: TextureProgressBar = null

const RADIUS: float = 26.0

var press_count: int = 0
var is_active: bool = false
var player: CharacterBody2D = null
var press_cooldown: float = 0.0

var _start_x: float = 0.0
var _exit_x: float = 0.0
var _target_x: float = 0.0
var _idle_time: float = 0.0
var _punch: float = 0.0
var _pulse_t: float = 0.0
var _alpha: float = 0.0
var _progress: float = 0.0
var _chevron_t: float = 0.0

var _ui_layer: CanvasLayer = null
var _canvas: Control = null
var _label: Label = null

func _ready():
	var canvas_layer = get_parent().get_node_or_null("CanvasLayer")
	if canvas_layer:
		var ui = canvas_layer.get_node_or_null("TightPassageUI")
		if ui:
			ui.visible = false

	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 20
	add_child(_ui_layer)

	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_on_canvas_draw)
	_ui_layer.add_child(_canvas)

	_label = Label.new()
	_label.text = "D"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size = Vector2(52, 52)
	_label.pivot_offset = Vector2(26, 26)
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 6)
	_ui_layer.add_child(_label)

	_ui_layer.visible = false
	set_process(false)

func _get_zone_right_x() -> float:
	var col = get_node_or_null("CollisionShape2D")
	if col and col.shape is RectangleShape2D:
		return col.global_position.x + col.shape.size.x / 2.0
	return global_position.x + 120.0

func activate(player_node: CharacterBody2D):
	if is_active:
		return

	player = player_node
	is_active = true
	press_count = 0
	press_cooldown = 0.0
	_idle_time = 0.0
	_alpha = 0.0
	_progress = 0.0

	_start_x = player.global_position.x
	_target_x = _start_x
	_exit_x = _get_zone_right_x() + exit_margin

	if player.has_method("set_movement_blocked"):
		player.set_movement_blocked(true)
	player.velocity = Vector2.ZERO
	if player.sprite:
		player.sprite.scale.x = 1
		player.sprite.play("Jogging" if player.sprite.sprite_frames.has_animation("Jogging") else "Run")
		player.sprite.pause()

	_ui_layer.visible = true
	set_process(true)

func _process(delta):
	if not is_active or not player or not is_instance_valid(player):
		return

	_pulse_t += delta
	_punch = move_toward(_punch, 0.0, delta * 6.0)
	_alpha = move_toward(_alpha, 1.0, delta * 5.0)
	_chevron_t += delta

	if press_cooldown > 0:
		press_cooldown -= delta

	if Input.is_action_just_pressed("ui_right") and press_cooldown <= 0:
		_step()
	else:
		_idle_time += delta
		if _idle_time > 0.22 and player.sprite and player.sprite.is_playing():
			player.sprite.pause()

	_progress = clamp((player.global_position.x - _start_x) / max(_exit_x - _start_x, 1.0), 0.0, 1.0)

	if player.global_position.x >= _exit_x - 0.5:
		_complete_passage()
		return

	_update_label()
	_canvas.queue_redraw()

func _step():
	press_count += 1
	press_cooldown = 0.06
	_idle_time = 0.0
	_punch = 1.0

	_target_x = min(_target_x + move_distance, _exit_x)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position:x", _target_x, step_time)

	if player.sprite:
		if not player.sprite.is_playing():
			player.sprite.play()
		var sq = create_tween()
		sq.tween_property(player.sprite, "scale", Vector2(0.86, 1.08), 0.05)
		sq.tween_property(player.sprite, "scale", Vector2(1.0, 1.0), 0.09)

func _screen_center() -> Vector2:
	var world = player.global_position + Vector2(0, -70)
	return get_viewport().get_canvas_transform() * world

func _update_label():
	var c = _screen_center()
	_label.position = c - _label.size / 2.0
	var k = 1.0 + _punch * 0.2
	_label.scale = Vector2(k, k)
	_label.modulate = Color(1, 1, 1, _alpha)

func _on_canvas_draw():
	if not is_active or not player or not is_instance_valid(player):
		return
	var c = _screen_center()
	var a = _alpha
	var r = RADIUS * (1.0 + _punch * 0.2)

	var pulse = 0.5 + 0.5 * sin(_pulse_t * 7.0)
	_canvas.draw_arc(c, r + 6.0 + pulse * 5.0, 0, TAU, 64, Color(1, 0.85, 0.4, (0.1 + 0.2 * pulse) * a), 3.0, true)
	_canvas.draw_circle(c, r, Color(0.07, 0.07, 0.09, 0.88 * a))
	if _punch > 0.0:
		_canvas.draw_circle(c, r, Color(0.5, 0.8, 1.0, 0.35 * _punch * a))
	_canvas.draw_arc(c, r - 4.0, 0, TAU, 64, Color(1, 1, 1, 0.18 * a), 4.0, true)
	if _progress > 0.001:
		_canvas.draw_arc(c, r - 4.0, -PI / 2.0, -PI / 2.0 + TAU * _progress, 64, Color(1.0, 0.78, 0.25, a), 4.0, true)

	for i in 3:
		var ph = fmod(_chevron_t * 2.2 + i * 0.33, 1.0)
		var x = c.x + r + 10.0 + ph * 22.0
		var ca = sin(ph * PI) * 0.8 * a
		var p1 = Vector2(x, c.y - 6)
		var p2 = Vector2(x + 6, c.y)
		var p3 = Vector2(x, c.y + 6)
		_canvas.draw_polyline(PackedVector2Array([p1, p2, p3]), Color(1, 1, 1, ca), 2.0, true)

func _complete_passage():
	is_active = false
	set_process(false)

	if player and is_instance_valid(player):
		if player.sprite:
			player.sprite.scale = Vector2(1, 1)
			player.sprite.play("Idle")
		if player.has_method("set_movement_blocked"):
			player.set_movement_blocked(false)

	var t = create_tween().set_parallel(true)
	t.tween_property(_label, "modulate:a", 0.0, 0.2)
	t.tween_property(_label, "scale", Vector2(1.5, 1.5), 0.2)
	await t.finished

	passage_completed.emit()
	queue_free()
