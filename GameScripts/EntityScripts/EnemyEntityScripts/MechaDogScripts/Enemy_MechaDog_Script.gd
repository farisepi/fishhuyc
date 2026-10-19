extends StorageEnemy

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var bite_area: Area2D = $BiteArea
@onready var hit_area: Area2D = $HitArea

enum State { IDLE, CHASE, QUAD_RUN, BITE, ATTACK, STUN, DEAD }
var state: State = State.IDLE
var windup_timer: float = 0.0
var bite_windup: float = 0.3
var attack_windup: float = 0.4
var quad_run_speed: float = 220.0
var chase_range: float = 350.0
var bite_range: float = 60.0
var attack_range: float = 70.0
var cooldown_timer: float = 0.0
var cooldown: float = 1.5
var bite_cooldown: float = 2.5

func _ready() -> void:
	super._ready()
	shard_color = "blue"
	max_hp = 3
	hp = 3
	can_be_parried = true
	if detection_area:
		detection_area.body_entered.connect(_on_detection)
	if bite_area:
		bite_area.body_entered.connect(_on_bite_hit)
	if hit_area:
		hit_area.body_entered.connect(_on_hit_area)

func _on_detection(body: Node2D) -> void:
	if body.is_in_group("player") and player == null:
		player = body

func _on_hit_area(body: Node2D) -> void:
	if body.is_in_group("player") and state == State.ATTACK:
		if body.get("is_dashing") == true:
			return
		if body.has_method("take_damage"):
			body.take_damage(1)

func _on_bite_hit(body: Node2D) -> void:
	if body.is_in_group("player") and state == State.BITE:
		if body.get("is_dashing") == true:
			return
		if body.has_method("take_damage"):
			body.take_damage(2)

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
			state = State.IDLE
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
			if dist < bite_range and cooldown_timer <= 0:
				state = State.QUAD_RUN
				windup_timer = 0.0
			elif dist < attack_range and cooldown_timer <= 0:
				state = State.ATTACK
				windup_timer = 0.0
				_play_anim("attack_" + ("right" if facing_dir > 0 else "left"))
		State.QUAD_RUN:
			_play_anim("quad_run")
			velocity.x = facing_dir * quad_run_speed
			windup_timer += delta
			if windup_timer >= bite_windup:
				state = State.BITE
				windup_timer = 0.0
				_play_anim("quad_bite")
		State.BITE:
			velocity.x = 0
			windup_timer += delta
			if windup_timer >= 0.5:
				state = State.CHASE
				cooldown_timer = bite_cooldown
		State.ATTACK:
			velocity.x = 0
			windup_timer += delta
			if windup_timer >= attack_windup:
				state = State.CHASE
				cooldown_timer = cooldown
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
