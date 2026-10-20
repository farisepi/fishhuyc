extends StorageEnemy

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

enum State { PATROL, ALERT, CHASE, RETREAT, TAIL_JUMP, TAIL_FALL, TAIL_LAND, TAIL_ATTACK, STUN, DEAD }
var state: State = State.PATROL
var jump_timer: float = 0.0
var tail_attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var tail_range: float = 120.0
var retreat_range: float = 160.0
var jump_velocity_y: float = -420.0
var jump_velocity_x: float = 160.0
var attack_cooldown: float = 2.2
var alert_timer: float = 0.0
var alert_duration: float = 0.35
var _damage_dealt_this_attack: bool = false

func _ready() -> void:
	super._ready()
	shard_color = "green"
	max_hp = 5
	hp = 5
	can_be_parried = true
	aggro_range = 380.0
	deaggro_range = 700.0
	min_distance = 70.0
	if detection_area:
		detection_area.body_entered.connect(func(b):
			if b.is_in_group("player") and player == null:
				player = b
		)
	_play_anim("idle")

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
			if dist < tail_range and cooldown_timer <= 0 and is_on_floor():
				state = State.TAIL_JUMP
				jump_timer = 0.0
				_damage_dealt_this_attack = false
				_play_anim("tail_jump")
				velocity.y = jump_velocity_y
				velocity.x = facing_dir * jump_velocity_x
		State.RETREAT:
			velocity.x = -facing_dir * speed * 0.9
			_play_anim("run_fast")
			if dist > retreat_range:
				state = State.CHASE
		State.TAIL_JUMP:
			_play_anim("tail_jump")
			jump_timer += delta
			if jump_timer >= 0.3 and velocity.y > 0:
				state = State.TAIL_FALL
				_play_anim("tail_fall")
		State.TAIL_FALL:
			_play_anim("tail_fall")
			if is_on_floor() and jump_timer >= 0.3:
				state = State.TAIL_LAND
				_play_anim("tail_land")
				tail_attack_timer = 0.0
		State.TAIL_LAND:
			velocity.x = 0
			tail_attack_timer += delta
			if tail_attack_timer >= 0.2:
				state = State.TAIL_ATTACK
				tail_attack_timer = 0.0
				_play_anim("tail_attack")
		State.TAIL_ATTACK:
			velocity.x = 0
			tail_attack_timer += delta
			if not _damage_dealt_this_attack and _is_player_in_attack_zone(tail_range):
				_damage_dealt_this_attack = true
				_hurt_player(1)
			if tail_attack_timer >= 0.4:
				state = State.RETREAT
				cooldown_timer = attack_cooldown
	move_and_slide()

func _play_anim(name: String) -> void:
	if not sprite:
		return
	if not sprite.sprite_frames:
		return
	if sprite.sprite_frames.has_animation(name):
		if sprite.animation != name:
			sprite.play(name)

func _on_hurt() -> void:
	_play_anim("hit")
	state = State.STUN
	is_stunned = true
	stun_timer = 0.4

func _on_death() -> void:
	_play_anim("death")
	state = State.DEAD
