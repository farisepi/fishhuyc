extends StorageEnemy

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var tail_area: Area2D = $TailArea

enum State { IDLE, CHASE, TAIL_JUMP, TAIL_FALL, TAIL_LAND, TAIL_ATTACK, STUN, DEAD }
var state: State = State.IDLE
var jump_timer: float = 0.0
var tail_attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var chase_range: float = 400.0
var tail_range: float = 120.0
var jump_velocity_y: float = -420.0
var jump_velocity_x: float = 160.0
var attack_cooldown: float = 2.0

func _ready() -> void:
	super._ready()
	shard_color = "green"
	max_hp = 3
	hp = 3
	can_be_parried = true
	if detection_area:
		detection_area.body_entered.connect(func(b):
			if b.is_in_group("player") and player == null:
				player = b
		)
	if tail_area:
		tail_area.body_entered.connect(_on_tail_hit)

func _on_tail_hit(body: Node2D) -> void:
	if body.is_in_group("player") and state == State.TAIL_ATTACK:
		if body.get("is_dashing") == true:
			return
		if body.has_method("take_damage"):
			body.take_damage(1)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	super._physics_process(delta)
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			state = State.CHASE
		velocity.x = 0
		move_and_slide()
		return
	if cooldown_timer > 0:
		cooldown_timer -= delta

	if player == null:
		_find_player()
		if player == null:
			velocity.x = 0
			move_and_slide()
			return

	var dist = global_position.distance_to(player.global_position)
	var dir = sign(player.global_position.x - global_position.x)
	if dir != 0:
		facing_dir = dir
	if sprite:
		sprite.scale.x = abs(sprite.scale.x) * (1 if facing_dir > 0 else -1)

	match state:
		State.IDLE:
			velocity.x = 0
			_play_anim("idle")
			if dist < chase_range:
				state = State.CHASE
		State.CHASE:
			velocity.x = facing_dir * speed
			_play_anim("run_fast")
			if dist < tail_range and cooldown_timer <= 0 and is_on_floor():
				state = State.TAIL_JUMP
				jump_timer = 0.0
				_play_anim("tail_jump")
				velocity.y = jump_velocity_y
				velocity.x = facing_dir * jump_velocity_x
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
			if tail_attack_timer >= 0.4:
				state = State.CHASE
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
