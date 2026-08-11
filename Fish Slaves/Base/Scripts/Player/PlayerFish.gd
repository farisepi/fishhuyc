extends CharacterBody2D

var bubble_scene: PackedScene
var speed: float = 200.0
var acceleration: float = 800.0
var tilt_amount: float = 0.3
var tilt_speed: float = 2.0
var float_strength: float = 1.5
var float_speed: float = 2.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var idle_bubble_interval: float = 0.5
var idle_bubble_timer: float = 0.0
var swim_bubble_interval: float = 0.25
var current_tilt: float = 0.0
var current_speed: float = 0.0
var facing_direction: int = -1
var was_moving: bool = false
var last_tilt_sign: int = 0
var bubble_timer: float = 0.0
var shake_amount: float = 0.0
var shake_decay: float = 6.0
var can_move: bool = true

func _ready() -> void:
	if sprite:
		sprite.scale.x = 1.0 if facing_direction == -1 else -1.0
	
	if has_node("PlayerCamera"):
		var cam = $PlayerCamera as Camera2D
		cam.process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(delta: float) -> void:
	if not sprite:
		return
	
	_update_shake(delta)
	_update_float_animation()
	
	if not can_move:
		velocity = Vector2.ZERO
		current_speed = 0.0
		move_and_slide()
		return
	
	var direction_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var is_moving = direction_input.length() > 0.0
	
	if is_moving:
		current_speed = move_toward(current_speed, speed, acceleration * delta)
		_handle_movement(direction_input, delta)
	else:
		current_speed = move_toward(current_speed, 0.0, acceleration * delta)
		_handle_idle(delta)
	
	velocity = direction_input * current_speed
	move_and_slide()
	_clamp_to_viewport()

func _update_shake(delta: float) -> void:
	if shake_amount <= 0:
		return
	
	var cam = get_node_or_null("PlayerCamera") as Camera2D
	if not cam:
		return
	
	var shake_off = Vector2(
		randf_range(-shake_amount, shake_amount),
		randf_range(-shake_amount * 0.6, shake_amount * 0.6)
	)
	
	if cam.has_method("set_external_offset"):
		cam.set_external_offset(shake_off)
	else:
		cam.offset = shake_off
	
	shake_amount = max(shake_amount - shake_decay * delta, 0.0)
	
	if shake_amount == 0.0:
		if cam.has_method("set_external_offset"):
			cam.set_external_offset(Vector2.ZERO)
		else:
			cam.offset = Vector2.ZERO

func _update_float_animation() -> void:
	var float_offset = sin(Time.get_ticks_msec() * 0.001 * float_speed) * float_strength
	sprite.position.y = float_offset

func _handle_movement(direction_input: Vector2, delta: float) -> void:
	if not was_moving:
		sprite.play("walk")
		was_moving = true
		UISounds.start_swim_sound()
		if UISounds.swim_player:
			UISounds.swim_player.pitch_scale = 0.4
	
	if direction_input.x < 0: facing_direction = -1
	elif direction_input.x > 0: facing_direction = 1
	
	if sprite.animation != "hit":
		sprite.scale.x = -1.0 if facing_direction > 0 else 1.0
	
	var target_tilt = direction_input.y * tilt_amount
	if facing_direction == -1: target_tilt = -target_tilt
	
	var target_sign = 1 if target_tilt > 0 else (-1 if target_tilt < 0 else 0)
	if target_sign != 0 and target_sign != last_tilt_sign:
		current_tilt = target_tilt
	else:
		current_tilt = move_toward(current_tilt, target_tilt, tilt_speed * delta)
	
	last_tilt_sign = target_sign
	sprite.rotation = current_tilt
	
	bubble_timer += delta
	if bubble_timer >= swim_bubble_interval:
		bubble_timer = 0.0
		_spawn_bubble()
	
	if UISounds.swim_player:
		var vol = move_toward(UISounds.swim_player.volume_db, -36.0, delta * 24.0)
		UISounds.set_swim_volume(min(vol, -36.0))

func _handle_idle(delta: float) -> void:
	if was_moving:
		sprite.play("idle")
		was_moving = false
	
	last_tilt_sign = 0
	current_tilt = move_toward(current_tilt, 0.0, tilt_speed * 0.5 * delta)
	sprite.rotation = current_tilt
	bubble_timer = swim_bubble_interval * 0.8
	
	idle_bubble_timer += delta
	if idle_bubble_timer >= idle_bubble_interval:
		idle_bubble_timer = 0.0
		if randf() < 0.3:
			_spawn_idle_bubble()
	
	if UISounds.swim_player:
		var vol = move_toward(UISounds.swim_player.volume_db, -80.0, delta * 24.0)
		UISounds.set_swim_volume(vol)
		if vol <= -70.0:
			UISounds.stop_swim_sound()

func _spawn_idle_bubble() -> void:
	if not bubble_scene:
		return
	
	var bubble = bubble_scene.instantiate()
	get_tree().current_scene.add_child(bubble)
	
	var offset_x = randf_range(-8, 8)
	var offset_y = randf_range(-5, 15)
	
	bubble.global_position = global_position + Vector2(offset_x, offset_y)
	
	var bubble_scale = randf_range(0.2, 0.45)
	bubble.scale = Vector2(bubble_scale, bubble_scale)
	
	var move_direction = Vector2(randf_range(-0.2, 0.2), -0.95)
	
	bubble.set_direction(move_direction)
	bubble.modulate.a = randf_range(0.15, 0.4)
	
	var actual_life = randf_range(1.5, 3.0)
	bubble.start_life(actual_life)
	bubble.clickable = false

func _spawn_bubble() -> void:
	if not bubble_scene:
		return
	
	var bubble = bubble_scene.instantiate()
	get_tree().current_scene.add_child(bubble)
	
	var offset_x = randf_range(-5, 15) if facing_direction == -1 else randf_range(-15, 5)
	var offset_y = randf_range(-8, 12)
	
	bubble.global_position = global_position + Vector2(offset_x, offset_y)
	
	var bubble_scale = randf_range(0.2, 0.45)
	bubble.scale = Vector2(bubble_scale, bubble_scale)
	
	var move_direction = Vector2(randf_range(-0.3, 0.3), -0.9)
	
	bubble.set_direction(move_direction)
	bubble.modulate.a = randf_range(0.2, 0.6)
	
	var actual_life = randf_range(1.0, 2.0)
	bubble.start_life(actual_life)
	bubble.clickable = false
	
	var life_timer = get_tree().create_timer(actual_life)
	life_timer.timeout.connect(_cleanup_bubble.bind(bubble), CONNECT_ONE_SHOT)

func _cleanup_bubble(bubble: Variant) -> void:
	if bubble == null:
		return
	if is_instance_valid(bubble) and not bubble.popped:
		bubble._auto_pop()

func _clamp_to_viewport() -> void:
	var margin = float_strength + 5.0
	var viewport_size = get_viewport().get_visible_rect().size
	global_position.x = clamp(global_position.x, margin, viewport_size.x - margin)
	global_position.y = clamp(global_position.y, margin, viewport_size.y - margin)

func hit_glass() -> void:
	if sprite:
		var old_scale = sprite.scale
		sprite.play("hit")
		can_move = false
		velocity = Vector2.ZERO
		current_speed = 0.0
		await get_tree().create_timer(0.3).timeout
		shake_amount = 10.0
		shake_decay = 24.0
		UISounds.play_hit()
		await sprite.animation_finished
		sprite.play("idle")
		sprite.scale = old_scale
		can_move = true
