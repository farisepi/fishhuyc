extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

const Z_ON_CONVEYOR: int = -3
const Z_HELD: int = 100

var held: bool = false
var thrown: bool = false
var fall_gravity: float = 1200.0
var conveyor_speed: float = 30.0

var velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var swing_amplitude: float = 0.0
var swing_phase: float = 0.0

var mouse_offset: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO
var smooth_mouse_velocity: Vector2 = Vector2.ZERO

signal thrown_out

func _ready() -> void:
	input_pickable = true
	z_index = Z_ON_CONVEYOR
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	last_mouse_pos = get_global_mouse_position()

func _input(event: InputEvent) -> void:
	if held and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_release()

func _process(delta: float) -> void:
	var current_mouse = get_global_mouse_position()
	var raw_vel = (current_mouse - last_mouse_pos) / max(delta, 0.001)
	smooth_mouse_velocity = smooth_mouse_velocity.lerp(raw_vel, 0.3)
	last_mouse_pos = current_mouse
	
	if thrown:
		velocity.y += fall_gravity * delta
		position += velocity * delta
		rotation += angular_velocity * delta
		if global_position.y > get_viewport().get_visible_rect().size.y + 200.0:
			queue_free()
		return
	
	if held:
		var mouse_pos = get_global_mouse_position()
		position = position.lerp(mouse_pos + mouse_offset, 0.35)
		
		var target_amp = clamp(smooth_mouse_velocity.x * 0.0008, -0.35, 0.35)
		swing_amplitude = lerp(swing_amplitude, target_amp, 0.08)
		swing_phase += delta * 3.5
		rotation = sin(swing_phase) * swing_amplitude
		return
	
	position.x -= conveyor_speed * delta
	swing_phase += delta * 1.5
	rotation = sin(swing_phase) * 0.03

func _on_mouse_entered() -> void:
	if not held and not thrown:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	if not held and not thrown:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if thrown:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_grab()

func _grab() -> void:
	if held or thrown:
		return
	held = true
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	mouse_offset = global_position - get_global_mouse_position()
	velocity = Vector2.ZERO
	angular_velocity = 0.0
	swing_amplitude = 0.0
	swing_phase = 0.0
	z_index = Z_HELD

func _release() -> void:
	if not held:
		return
	held = false
	thrown = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	velocity.x = smooth_mouse_velocity.x * 0.6 + swing_amplitude * 600.0
	velocity.y = smooth_mouse_velocity.y * 0.4
	
	if abs(velocity.x) < 50.0:
		velocity.x = randf_range(-150.0, 150.0)
	if abs(velocity.y) < 50.0:
		velocity.y = -200.0
	
	angular_velocity = randf_range(-8.0, 8.0)
	
	if collision:
		collision.set_deferred("disabled", true)
	
	thrown_out.emit()
	Global.boxes_thrown += 1
	if Global.boxes_thrown >= 50:
		Achievements.unlock_rebel()
		call_deferred("_notify_achievement")

func _notify_achievement() -> void:
	var scene = get_tree().current_scene
	if scene and scene.has_method("_show_rebel_achievement"):
		scene._show_rebel_achievement()
