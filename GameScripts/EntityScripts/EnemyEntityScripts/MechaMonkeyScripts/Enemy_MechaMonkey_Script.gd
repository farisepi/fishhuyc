extends StorageEnemy

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var placeholder: ColorRect = get_node_or_null("PlaceholderRect")
@onready var detection_area: Area2D = get_node_or_null("DetectionArea")
@onready var tail_area: Area2D = get_node_or_null("TailArea")

enum State { PATROL, ALERT, CHASE, RETREAT, TAIL_JUMP, FLIP_TAIL, FALL, LAND, TAIL_ATTACK, STUN, DEAD }
var state: State = State.PATROL

var run_speed: float = 215.0
var jump_velocity: float = -400.0
var alert_timer: float = 0.0
var alert_duration: float = 0.3
var tail_cooldown: float = 0.0
var tail_cooldown_max: float = 2.6
var tail_damage: int = 2
var tail_range: float = 85.0
var jump_range: float = 230.0
var flip_range: float = 160.0
var flip_cooldown: float = 0.0
var flip_cooldown_max: float = 3.4
var flip_duration: float = 0.45
var flip_hit_time: float = 0.18
var flip_jump_velocity: float = -330.0
var flip_triangle_width_mult: float = 0.7
var show_flip_zone: bool = false
var vertical_tolerance: float = 70.0
var fall_grace: float = 0.05
var attack_windup: float = 0.12
var attack_recover: float = 0.20
var attack_decision_cooldown: float = 0.0
var attack_decision_gap: float = 0.45
var retreat_distance: float = 55.0
var retreat_speed_mult: float = 0.9
var leap_cancel_mult: float = 1.8
var hurt_stun_time: float = 0.22
var retreat_after_stun_time: float = 0.4

var _base_y: float = 0.0
var _air_timer: float = 0.0
var _attack_timer: float = 0.0
var _flip_timer: float = 0.0
var _flip_hit_done: bool = false
var _jump_tween: Tween = null
var _attack_tween: Tween = null
var _flip_tween: Tween = null
var _damage_dealt_this_attack: bool = false
var _is_attacking: bool = false
var _attack_buffer: bool = false
var _retreat_after_stun: bool = false
var _player_prev_pos: Vector2 = Vector2.ZERO
var _player_velocity_est: Vector2 = Vector2.ZERO
var _flip_zone_node: Polygon2D = null
var _last_attack_kind: String = ""

const BODY_COLOR: Color = Color(0.2, 0.9, 0.3, 1.0)
const ALERT_COLOR: Color = Color(1.0, 0.85, 0.2, 1.0)
const JUMP_COLOR: Color = Color(0.4, 0.7, 1.0, 1.0)
const FLIP_COLOR: Color = Color(0.8, 0.4, 1.0, 1.0)
const ATTACK_COLOR: Color = Color(1.0, 0.35, 0.2, 1.0)
const STUN_COLOR: Color = Color(1.0, 0.2, 0.2, 1.0)
const DEAD_COLOR: Color = Color(0.3, 0.3, 0.3, 1.0)
const RETREAT_COLOR: Color = Color(0.9, 0.75, 0.4, 1.0)
const FLIP_ZONE_COLOR: Color = Color(0.8, 0.4, 1.0, 0.35)


func _ready() -> void:
	super._ready()
	_base_y = position.y
	shard_color = "blue"
	max_hp = 6
	hp = 6
	can_be_parried = true
	aggro_range = 400.0
	deaggro_range = 700.0
	min_distance = 60.0
	if detection_area:
		detection_area.body_entered.connect(_on_detection)
		detection_area.body_exited.connect(_on_detection_exit)
	if placeholder:
		placeholder.color = BODY_COLOR
	_play_anim("idle")


func _on_detection(body: Node2D) -> void:
	if body.is_in_group("player") and player == null:
		player = body
		_player_prev_pos = player.global_position


func _on_detection_exit(body: Node2D) -> void:
	if body == player and body.is_in_group("player"):
		player = null


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	super._physics_process(delta)

	if is_stunned:
		stun_timer -= delta
		velocity.x = 0
		_apply_gravity(delta)
		move_and_slide()
		if stun_timer <= 0:
			is_stunned = false
			_on_stun_end()
		return

	if tail_cooldown > 0:
		tail_cooldown -= delta
	if flip_cooldown > 0:
		flip_cooldown -= delta
	if attack_decision_cooldown > 0:
		attack_decision_cooldown -= delta

	if player == null:
		_find_player()
	elif player.is_queued_for_deletion():
		player = null

	var dist = 99999.0
	var vertical_diff = 0.0
	if player != null:
		dist = global_position.distance_to(player.global_position)
		vertical_diff = abs(player.global_position.y - global_position.y)
		_update_aggro(dist)
		_update_player_velocity(delta)

	_sync_tail_area()
	if sprite and sprite.visible:
		sprite.scale.x = abs(sprite.scale.x) * (1 if facing_dir > 0 else -1)

	match state:
		State.PATROL:
			if is_aggro:
				state = State.ALERT
				alert_timer = 0.0
				velocity.x = 0
				_set_color(ALERT_COLOR)
			else:
				_patrol_step(delta)
				_apply_gravity(delta)
				move_and_slide()
				return
		State.ALERT:
			alert_timer += delta
			velocity.x = 0
			_clamp_facing_to_player()
			if alert_timer >= alert_duration:
				_set_color(BODY_COLOR)
				state = State.CHASE
		State.CHASE:
			_chase_logic(dist, vertical_diff)
		State.RETREAT:
			_retreat_logic(dist, delta)
		State.TAIL_JUMP:
			_tail_jump_logic(delta, dist)
		State.FLIP_TAIL:
			_flip_tail_logic(delta, dist)
		State.FALL:
			_fall_logic(delta)
		State.LAND:
			velocity.x = 0
			if is_on_floor() and _air_timer <= 0:
				_set_color(BODY_COLOR)
				state = State.CHASE
		State.TAIL_ATTACK:
			_tail_attack_logic(delta)
		State.DEAD:
			velocity.x = 0

	_apply_gravity(delta)
	move_and_slide()


func _on_stun_end() -> void:
	if is_dead:
		return
	if _retreat_after_stun:
		_retreat_after_stun = false
		state = State.RETREAT
		attack_decision_cooldown = retreat_after_stun_time
		_set_color(RETREAT_COLOR)
		return
	_set_color(BODY_COLOR)
	state = State.CHASE if is_aggro else State.PATROL


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _sync_tail_area() -> void:
	if tail_area:
		tail_area.position.x = abs(tail_area.position.x) * facing_dir


func _chase_logic(dist: float, vertical_diff: float) -> void:
	if not is_aggro:
		state = State.PATROL
		return
	_clamp_facing_to_player()

	if _is_attacking:
		return

	if dist < retreat_distance:
		state = State.RETREAT
		_set_color(RETREAT_COLOR)
		velocity.x = 0
		return

	if vertical_diff > vertical_tolerance * 2.0:
		velocity.x = facing_dir * run_speed * 0.7
		return

	velocity.x = facing_dir * run_speed

	if vertical_diff > vertical_tolerance:
		return

	if attack_decision_cooldown > 0:
		return

	if is_on_floor():
		if dist < tail_range and tail_cooldown <= 0 and _last_attack_kind != "tail":
			_start_tail_attack()
			return
		if dist < flip_range and flip_cooldown <= 0 and _last_attack_kind != "flip":
			_start_flip_tail()
			return
		if dist < jump_range:
			_start_tail_jump()
			return
		if dist < tail_range and tail_cooldown <= 0:
			_start_tail_attack()
			return
		if dist < flip_range and flip_cooldown <= 0:
			_start_flip_tail()
			return


func _retreat_logic(dist: float, delta: float) -> void:
	if player == null:
		state = State.CHASE
		return
	var away = -1 if facing_dir > 0 else 1
	velocity.x = away * run_speed * retreat_speed_mult
	if dist > retreat_distance * 2.0:
		_set_color(BODY_COLOR)
		state = State.CHASE


func _start_flip_tail() -> void:
	if _is_attacking:
		_attack_buffer = true
		return
	_is_attacking = true
	_attack_buffer = false
	_last_attack_kind = "flip"
	state = State.FLIP_TAIL
	_flip_timer = 0.0
	_flip_hit_done = false
	flip_cooldown = flip_cooldown_max
	velocity.y = flip_jump_velocity
	velocity.x = facing_dir * run_speed * 0.4
	_set_color(FLIP_COLOR)
	_play_anim("flip")
	if placeholder:
		_kill_flip_tween()
		placeholder.rotation = 0.0
		_flip_tween = create_tween()
		_flip_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_flip_tween.tween_property(placeholder, "rotation", TAU * facing_dir, flip_duration)
	if show_flip_zone:
		_spawn_flip_zone()


func _flip_tail_logic(delta: float, dist: float) -> void:
	_flip_timer += delta
	if dist > jump_range * leap_cancel_mult:
		_end_flip_tail()
		return
	if not _flip_hit_done and _flip_timer >= flip_hit_time:
		_flip_hit_done = true
		_apply_triangle_damage()
	if _flip_timer >= flip_duration:
		_end_flip_tail()


func _end_flip_tail() -> void:
	_is_attacking = false
	_flip_timer = 0.0
	if placeholder:
		placeholder.rotation = 0.0
		placeholder.scale = Vector2(1, 1)
	_despawn_flip_zone()
	_set_color(BODY_COLOR)
	_play_anim("idle")
	if is_stunned:
		return
	if _attack_buffer:
		_attack_buffer = false
		_start_tail_attack()
		return
	state = State.FALL


func _get_triangle_points() -> PackedVector2Array:
	var forward = Vector2(facing_dir, 0)
	var up = Vector2(0, -1)
	var tip = global_position + forward * (tail_range * 0.2) + up * 8.0
	var base_center = global_position + forward * tail_range
	var half_width = tail_range * flip_triangle_width_mult * 0.5
	var left = base_center + up * half_width
	var right = base_center - up * half_width
	return PackedVector2Array([tip, left, right])


func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 = (p - a).cross(b - a)
	var d2 = (p - b).cross(c - b)
	var d3 = (p - c).cross(a - c)
	var has_neg = d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var has_pos = d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (has_neg and has_pos)


func _apply_triangle_damage() -> void:
	if player == null:
		return
	var predicted = _predict_player_pos()
	var tri = _get_triangle_points()
	if _point_in_triangle(predicted, tri[0], tri[1], tri[2]):
		_hurt_player(tail_damage)
	elif _point_in_triangle(player.global_position, tri[0], tri[1], tri[2]):
		_hurt_player(tail_damage)


func _spawn_flip_zone() -> void:
	_despawn_flip_zone()
	var poly = Polygon2D.new()
	poly.polygon = _get_triangle_points()
	poly.color = FLIP_ZONE_COLOR
	poly.z_index = -1
	get_parent().add_child(poly)
	_flip_zone_node = poly


func _despawn_flip_zone() -> void:
	if _flip_zone_node and is_instance_valid(_flip_zone_node):
		_flip_zone_node.queue_free()
	_flip_zone_node = null


func _start_tail_jump() -> void:
	if _is_attacking:
		return
	_is_attacking = true
	_last_attack_kind = "jump"
	state = State.TAIL_JUMP
	_air_timer = 0.0
	velocity.y = jump_velocity
	velocity.x = facing_dir * run_speed * 0.9
	_set_color(JUMP_COLOR)
	_play_anim("jump")
	if placeholder:
		_kill_jump_tween()
		_jump_tween = create_tween()
		_jump_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_jump_tween.tween_property(placeholder, "scale", Vector2(0.85, 1.15), 0.12)
		_jump_tween.set_ease(Tween.EASE_IN)
		_jump_tween.tween_property(placeholder, "scale", Vector2(1, 1), 0.18)


func _tail_jump_logic(delta: float, dist: float) -> void:
	_air_timer += delta
	if dist > jump_range * leap_cancel_mult:
		_is_attacking = false
		state = State.FALL
		return
	if velocity.y >= 0.0 or _air_timer > 0.6:
		state = State.FALL
		_play_anim("fall")
		if placeholder:
			_kill_jump_tween()
			_jump_tween = create_tween()
			_jump_tween.tween_property(placeholder, "scale", Vector2(1.1, 0.9), 0.15)


func _fall_logic(delta: float) -> void:
	_air_timer += delta
	if is_on_floor() and _air_timer >= fall_grace:
		_start_land()
		return
	if _air_timer > 2.0:
		_start_land()


func _start_land() -> void:
	state = State.LAND
	_air_timer = 0.0
	_is_attacking = false
	velocity.x = 0
	_set_color(BODY_COLOR)
	_play_anim("land")
	if placeholder:
		_kill_jump_tween()
		_jump_tween = create_tween()
		_jump_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_jump_tween.tween_property(placeholder, "scale", Vector2(1.2, 0.8), 0.08)
		_jump_tween.tween_property(placeholder, "scale", Vector2(1, 1), 0.14)


func _start_tail_attack() -> void:
	if _is_attacking:
		_attack_buffer = true
		return
	_is_attacking = true
	_attack_buffer = false
	_last_attack_kind = "tail"
	state = State.TAIL_ATTACK
	_attack_timer = 0.0
	_damage_dealt_this_attack = false
	tail_cooldown = tail_cooldown_max
	attack_decision_cooldown = attack_decision_gap
	velocity.x = 0
	_set_color(ATTACK_COLOR)
	_play_anim("tail_attack")
	if placeholder:
		var base_scale = Vector2(1, 1)
		_kill_attack_tween()
		_attack_tween = create_tween()
		_attack_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_attack_tween.tween_property(placeholder, "scale", Vector2(1.3, 0.85), 0.08)
		_attack_tween.tween_property(placeholder, "scale", base_scale, 0.15)
	if tail_area:
		tail_area.monitoring = true


func _tail_attack_logic(delta: float) -> void:
	velocity.x = 0
	_attack_timer += delta
	if not _damage_dealt_this_attack and _attack_timer >= attack_windup:
		_damage_dealt_this_attack = true
		if _is_player_in_tail_zone():
			_hurt_player(tail_damage)
	if _attack_timer >= attack_windup + attack_recover:
		_end_tail_attack()


func _end_tail_attack() -> void:
	_is_attacking = false
	_attack_timer = 0.0
	_set_color(BODY_COLOR)
	_play_anim("idle")
	if is_stunned:
		return
	if _attack_buffer:
		_attack_buffer = false
		if tail_cooldown <= 0:
			_start_tail_attack()
			return
	state = State.CHASE


func _is_player_in_tail_zone() -> bool:
	if player == null:
		return false
	var tail_origin = global_position + Vector2(facing_dir * tail_range * 0.5, 0)
	return tail_origin.distance_to(player.global_position) < tail_range


func _update_player_velocity(delta: float) -> void:
	if player == null:
		return
	var current = player.global_position
	if delta > 0.0:
		_player_velocity_est = (current - _player_prev_pos) / delta
	_player_prev_pos = current


func _predict_player_pos() -> Vector2:
	if player == null:
		return global_position
	return player.global_position + _player_velocity_est * 0.2


func _set_color(c: Color) -> void:
	if placeholder:
		placeholder.color = c
	if sprite:
		sprite.modulate = c


func _kill_jump_tween() -> void:
	if _jump_tween and _jump_tween.is_valid():
		_jump_tween.kill()


func _kill_attack_tween() -> void:
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()


func _kill_flip_tween() -> void:
	if _flip_tween and _flip_tween.is_valid():
		_flip_tween.kill()


func _play_anim(name: String) -> void:
	if not sprite:
		return
	if not sprite.sprite_frames:
		return
	if sprite.sprite_frames.has_animation(name):
		if sprite.animation != name:
			sprite.play(name)


func _on_hurt() -> void:
	_kill_jump_tween()
	_kill_attack_tween()
	_kill_flip_tween()
	_despawn_flip_zone()
	if placeholder:
		placeholder.scale = Vector2(1, 1)
		placeholder.rotation = 0.0
	_is_attacking = false
	_attack_buffer = false
	_attack_timer = 0.0
	_flip_timer = 0.0
	_retreat_after_stun = true
	state = State.STUN
	is_stunned = true
	stun_timer = hurt_stun_time
	_set_color(STUN_COLOR)
	if sprite:
		_play_anim("hit")


func _on_death() -> void:
	_kill_jump_tween()
	_kill_attack_tween()
	_kill_flip_tween()
	_despawn_flip_zone()
	if placeholder:
		placeholder.scale = Vector2(1, 1)
		placeholder.rotation = 0.0
	state = State.DEAD
	is_stunned = false
	_is_attacking = false
	_attack_buffer = false
	_set_color(DEAD_COLOR)
	_play_anim("death")
