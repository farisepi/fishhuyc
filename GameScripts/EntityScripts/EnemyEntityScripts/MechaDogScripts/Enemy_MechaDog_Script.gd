extends StorageEnemy

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

enum State { PATROL, ALERT, CHASE, RETREAT, QUAD_RUN, BITE, ATTACK, STUN, DEAD }
var state: State = State.PATROL
var windup_timer: float = 0.0
var attack_windup: float = 0.4
var quad_run_speed: float = 200.0
var bite_range: float = 80.0
var attack_range: float = 90.0
var retreat_range: float = 150.0
var cooldown_timer: float = 0.0
var cooldown: float = 1.6
var bite_cooldown: float = 2.6
var alert_timer: float = 0.0
var alert_duration: float = 0.35

var is_attacking: bool = false
var attack_buffer: bool = false
var _damage_dealt_this_attack: bool = false
const ATTACK_CANCEL_FRAME: int = 7
const ATTACK_RESTART_FRAME: int = 1

func _ready() -> void:
	super._ready()
	shard_color = "blue"
	max_hp = 5
	hp = 5
	can_be_parried = true
	aggro_range = 380.0
	deaggro_range = 700.0
	min_distance = 70.0
	if detection_area:
		detection_area.body_entered.connect(_on_detection)
	_play_anim("idle")

func _on_detection(body: Node2D) -> void:
	if body.is_in_group("player") and player == null:
		player = body

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	super._physics_process(delta)
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			state = State.CHASE if is_aggro else State.PATROL
		velocity.x = 0
		move_and_slide()
		return
	if cooldown_timer > 0:
		cooldown_timer -= delta

	if player == null:
		_find_player()

	var dist = 99999.0
	if player != null:
		dist = global_position.distance_to(player.global_position)
		_update_aggro(dist)

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
			if not is_aggro:
				state = State.PATROL
				return
			_clamp_facing_to_player()
			if _is_player_too_close(55.0):
				state = State.RETREAT
				return
			velocity.x = facing_dir * speed
			_play_anim("run_fast")
			if dist < bite_range and cooldown_timer <= 0:
				state = State.QUAD_RUN
				windup_timer = 0.0
			elif dist < attack_range and cooldown_timer <= 0:
				_start_attack()
		State.RETREAT:
			velocity.x = -facing_dir * speed * 0.9
			_play_anim("run_fast")
			if dist > retreat_range:
				state = State.CHASE
		State.QUAD_RUN:
			_play_anim("quad_run")
			velocity.x = facing_dir * quad_run_speed
			windup_timer += delta
			if windup_timer >= 0.25:
				state = State.BITE
				windup_timer = 0.0
				_play_anim("quad_bite")
				_damage_dealt_this_attack = false
		State.BITE:
			velocity.x = 0
			windup_timer += delta
			if not _damage_dealt_this_attack and _is_player_in_attack_zone(bite_range):
				_damage_dealt_this_attack = true
				_hurt_player(2)
			if windup_timer >= 0.45:
				state = State.RETREAT
				cooldown_timer = bite_cooldown
		State.ATTACK:
			velocity.x = 0
			if not is_attacking:
				state = State.RETREAT
				cooldown_timer = cooldown
	move_and_slide()

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
	# ждём 3-й кадр — момент удара
	var hit_frame = 3
	while sprite.is_playing() and sprite.frame < hit_frame:
		await get_tree().process_frame
	if not _damage_dealt_this_attack and _is_player_in_attack_zone(attack_range):
		_damage_dealt_this_attack = true
		_hurt_player(1)
	await sprite.animation_finished
	if attack_buffer:
		attack_buffer = false
		is_attacking = false
		_start_attack()
		return
	is_attacking = false
	state = State.RETREAT
	cooldown_timer = cooldown

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

func _on_hurt() -> void:
	_cancel_attack_early()
	is_attacking = false
	attack_buffer = false
	_play_anim("hit")
	state = State.STUN
	is_stunned = true
	stun_timer = 0.4

func _on_death() -> void:
	_play_anim("death")
	state = State.DEAD
	is_attacking = false
	attack_buffer = false
