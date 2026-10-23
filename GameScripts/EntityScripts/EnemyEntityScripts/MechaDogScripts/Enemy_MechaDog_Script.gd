extends StorageEnemy

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = get_node_or_null("DetectionArea")
@onready var bite_area: Area2D = get_node_or_null("BiteArea")
@onready var hit_area: Area2D = get_node_or_null("HitArea")
@onready var flash_rect: ColorRect = get_node_or_null("FlashRect")

enum State { PATROL, ALERT, CHASE, RETREAT, QUAD_RUN, JUMP_BITE, BITE, ATTACK, STUN, DEAD }
var state: State = State.PATROL

var run_speed: float = 260.0
var quad_run_speed: float = 420.0
var bite_range: float = 80.0
var attack_range: float = 95.0
var retreat_range: float = 150.0
var cooldown_timer: float = 0.0
var cooldown: float = 1.4
var bite_cooldown: float = 2.2
var alert_timer: float = 0.0
var alert_duration: float = 0.3
var windup_timer: float = 0.0
var hurt_stun_time: float = 0.2
var retreat_after_stun_time: float = 0.45
var retreat_after_stun_grace: float = 0.0

var is_attacking: bool = false
var attack_buffer: bool = false
var _damage_dealt_this_attack: bool = false
var _retreat_after_stun: bool = false
const ATTACK_CANCEL_FRAME: int = 7
const ATTACK_RESTART_FRAME: int = 1

var _base_y: float = 0.0
var _jump_tween: Tween = null
var _player_last_pos: Vector2 = Vector2.ZERO
var _player_prev_pos: Vector2 = Vector2.ZERO
var _player_velocity_est: Vector2 = Vector2.ZERO
var _detect_vertical_tolerance: float = 70.0


func _ready() -> void:
	super._ready()
	_base_y = position.y
	shard_color = "blue"
	max_hp = 5
	hp = 5
	can_be_parried = true
	aggro_range = 380.0
	deaggro_range = 700.0
	min_distance = 70.0
	if detection_area:
		detection_area.body_entered.connect(_on_detection)
		detection_area.body_exited.connect(_on_detection_exit)
	if flash_rect:
		flash_rect.modulate.a = 0.0
	_play_anim("idle")


func _on_detection(body: Node2D) -> void:
	if body.is_in_group("player") and player == null:
		player = body
		_player_last_pos = player.global_position
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
		move_and_slide()
		if stun_timer <= 0:
			is_stunned = false
			_on_stun_end()
		return

	if cooldown_timer > 0:
		cooldown_timer -= delta

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

	if sprite:
		sprite.scale.x = abs(sprite.scale.x) * (1 if facing_dir > 0 else -1)

	match state:
		State.PATROL:
			_play_anim("idle")
			if is_aggro:
				state = State.ALERT
				alert_timer = 0.0
				velocity.x = 0
			else:
				_patrol_step(delta)
				return
		State.ALERT:
			alert_timer += delta
			velocity.x = 0
			_clamp_facing_to_player()
			if alert_timer >= alert_duration:
				state = State.CHASE
		State.CHASE:
			_chase_logic(dist, vertical_diff)
		State.RETREAT:
			velocity.x = -facing_dir * run_speed * 0.9
			_play_anim("run_fast")
			if dist > retreat_range:
				state = State.CHASE
		State.QUAD_RUN:
			_quad_run_logic(delta, dist, vertical_diff)
		State.JUMP_BITE:
			_jump_bite_logic(delta, dist)
		State.BITE:
			_bite_logic(delta, dist)
		State.ATTACK:
			velocity.x = 0
			if not is_attacking:
				state = State.RETREAT
				cooldown_timer = cooldown
	move_and_slide()


func _on_stun_end() -> void:
	if is_dead:
		return
	if _retreat_after_stun:
		_retreat_after_stun = false
		state = State.RETREAT
		cooldown_timer = 0.3
		return
	state = State.CHASE if is_aggro else State.PATROL


func _chase_logic(dist: float, vertical_diff: float) -> void:
	if not is_aggro:
		state = State.PATROL
		return
	_clamp_facing_to_player()

	if vertical_diff > _detect_vertical_tolerance * 2.0:
		velocity.x = facing_dir * run_speed * 0.7
		_play_anim("run_fast")
		return

	if _is_player_too_close(55.0):
		state = State.RETREAT
		return

	velocity.x = facing_dir * run_speed
	_play_anim("run_fast")

	if cooldown_timer <= 0:
		if vertical_diff > _detect_vertical_tolerance:
			return
		if dist < bite_range:
			_start_bite()
		elif dist < attack_range:
			_start_attack()
		elif dist < 200.0:
			_start_quad_run()


func _quad_run_logic(delta: float, dist: float, vertical_diff: float) -> void:
	_play_anim("run_fast")
	velocity.x = facing_dir * quad_run_speed
	windup_timer += delta

	if sprite:
		var t = clamp(windup_timer / 0.24, 0.0, 1.0)
		sprite.modulate = Color(1.0, 1.0 - t * 0.25, 1.0 - t * 0.25)

	if vertical_diff > _detect_vertical_tolerance:
		_reset_quad_visual()
		state = State.CHASE
		return

	if global_position.distance_to(player.global_position) > attack_range * 1.8:
		_reset_quad_visual()
		state = State.CHASE
		return

	if windup_timer >= 0.18:
		_start_jump_bite()


func _jump_bite_logic(delta: float, dist: float) -> void:
	velocity.x = facing_dir * quad_run_speed * 0.55
	windup_timer += delta
	if windup_timer >= 0.10 and not _damage_dealt_this_attack:
		_damage_dealt_this_attack = true
		_snap_jaw_effect()
		if _is_player_in_attack_zone(bite_range):
			_hurt_player(2)
	if windup_timer >= 0.32:
		_reset_quad_visual()
		cooldown_timer = bite_cooldown
		state = State.RETREAT


func _bite_logic(delta: float, dist: float) -> void:
	velocity.x = 0
	windup_timer += delta
	if not _damage_dealt_this_attack and _is_player_in_attack_zone(bite_range):
		_damage_dealt_this_attack = true
		_snap_jaw_effect()
		_hurt_player(2)
	if windup_timer >= 0.40:
		cooldown_timer = bite_cooldown
		state = State.RETREAT


func _start_quad_run() -> void:
	state = State.QUAD_RUN
	windup_timer = 0.0
	velocity.x = 0


func _start_jump_bite() -> void:
	state = State.JUMP_BITE
	windup_timer = 0.0
	_damage_dealt_this_attack = false
	if _jump_tween and _jump_tween.is_valid():
		_jump_tween.kill()
	_jump_tween = create_tween()
	_jump_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_jump_tween.tween_property(self, "position:y", _base_y - 18.0, 0.12)
	_jump_tween.set_ease(Tween.EASE_IN)
	_jump_tween.tween_property(self, "position:y", _base_y, 0.16)


func _start_bite() -> void:
	state = State.BITE
	windup_timer = 0.0
	_damage_dealt_this_attack = false
	_snap_jaw_effect()


func _start_attack() -> void:
	if is_attacking:
		attack_buffer = true
		return
	state = State.ATTACK
	is_attacking = true
	attack_buffer = false
	_damage_dealt_this_attack = false
	var anim = "attack_right" if facing_dir > 0 else "attack_left"
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
		sprite.frame = ATTACK_RESTART_FRAME
	else:
		is_attacking = false
		state = State.CHASE
		return
	await _wait_for_attack_hit_frame(3)
	if not _damage_dealt_this_attack and _is_player_in_attack_zone(attack_range):
		_damage_dealt_this_attack = true
		_snap_jaw_effect()
		_hurt_player(1)
	if not sprite or not sprite.is_playing():
		is_attacking = false
		cooldown_timer = cooldown
		state = State.RETREAT
		return
	await sprite.animation_finished
	if attack_buffer:
		attack_buffer = false
		is_attacking = false
		_start_attack()
		return
	is_attacking = false
	cooldown_timer = cooldown
	state = State.RETREAT


func _wait_for_attack_hit_frame(hit_frame: int) -> void:
	while sprite and sprite.is_playing() and sprite.frame < hit_frame:
		await get_tree().process_frame
		if not is_attacking:
			return


func _cancel_attack_early() -> void:
	if not is_attacking or sprite == null:
		return
	if not sprite.sprite_frames:
		return
	if not sprite.sprite_frames.has_animation(sprite.animation):
		return
	var total = sprite.sprite_frames.get_frame_count(sprite.animation)
	if ATTACK_CANCEL_FRAME < total:
		sprite.frame = ATTACK_CANCEL_FRAME
		sprite.stop()
	else:
		sprite.frame = total - 1
		sprite.stop()


func _play_anim(name: String) -> void:
	if not sprite:
		return
	if not sprite.sprite_frames:
		return
	if sprite.sprite_frames.has_animation(name):
		if sprite.animation != name:
			sprite.play(name)


func _reset_quad_visual() -> void:
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)
	if _jump_tween and _jump_tween.is_valid():
		_jump_tween.kill()
	position.y = _base_y


func _snap_jaw_effect() -> void:
	if flash_rect:
		flash_rect.modulate = Color(1.0, 0.85, 0.4, 0.55)
		var t = create_tween()
		t.tween_property(flash_rect, "modulate:a", 0.0, 0.18)
	if sprite:
		var base_scale = Vector2(abs(sprite.scale.x), abs(sprite.scale.y))
		var s = create_tween()
		s.tween_property(sprite, "scale", base_scale * Vector2(1.08, 0.92), 0.06)
		s.tween_property(sprite, "scale", base_scale, 0.10)


func _update_player_velocity(delta: float) -> void:
	if player == null:
		return
	_player_prev_pos = _player_last_pos
	_player_last_pos = player.global_position
	if delta > 0.0:
		_player_velocity_est = (_player_last_pos - _player_prev_pos) / delta


func _predict_player_pos() -> Vector2:
	if player == null:
		return global_position
	return player.global_position + _player_velocity_est * 0.2


func _on_hurt() -> void:
	_cancel_attack_early()
	_reset_quad_visual()
	is_attacking = false
	attack_buffer = false
	_retreat_after_stun = true
	state = State.STUN
	is_stunned = true
	stun_timer = hurt_stun_time
	if sprite:
		var t = create_tween()
		t.tween_property(sprite, "modulate", Color(1.5, 0.6, 0.6, 1.0), 0.05)
		t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.15)


func _on_death() -> void:
	_reset_quad_visual()
	state = State.DEAD
	is_attacking = false
	attack_buffer = false
	_play_anim("death")
