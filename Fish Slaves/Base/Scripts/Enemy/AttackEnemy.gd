extends CharacterBody2D

@export var speed: float = 140.0
@export var gravity: float = 980.0
@export var attack_range: float = 70.0
@export var windup_time: float = 1.0
@export var lunge_distance: float = 55.0
@export var knockback_distance: float = 80.0
@export var knockback_duration: float = 0.25
@export var block_duration: float = 1.5
@export var cooldown_time: float = 1.8

enum State { IDLE, CHASING, WINDUP, LUNGE, KNOCKBACK, BLOCK, COOLDOWN }
var state: State = State.IDLE
var player: CharacterBody2D = null
var is_aggro: bool = false
var windup_timer: float = 0.0
var cooldown_timer: float = 0.0
var block_timer: float = 0.0
var facing_dir: int = 1
var is_vaulting: bool = false

@onready var color_rect: ColorRect = $ColorRect
@onready var detection_area: Area2D = $DetectionArea
@onready var hit_area: Area2D = $HitArea

const COLOR_NORMAL: Color = Color(0.2, 0.6, 0.2, 1)
const COLOR_WINDUP: Color = Color(0.8, 0.2, 1.0, 1)
const COLOR_ATTACK: Color = Color(1, 0.2, 0.2, 1)
const COLOR_BLOCK: Color = Color(0.2, 0.5, 1.0, 1)
const COLOR_COOLDOWN: Color = Color(0.4, 0.4, 0.4, 1)

func _ready():
	add_to_group("enemies")
	collision_mask = 1
	collision_layer = 2
	color_rect.color = COLOR_NORMAL
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	hit_area.body_entered.connect(_on_hit_area_body_entered)

func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("player") and not is_aggro:
		is_aggro = true
		player = body

func _on_hit_area_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return
	if state != State.LUNGE:
		return

	if body.has_method("take_damage"):
		body.take_damage(1)

	state = State.KNOCKBACK
	_knockback()

func _physics_process(delta):
	if not is_aggro:
		velocity.x = 0
		move_and_slide()
		return

	if not player:
		is_aggro = false
		state = State.IDLE
		return

	var dir_to_player = sign(player.global_position.x - global_position.x)
	if dir_to_player != 0:
		facing_dir = dir_to_player
		if color_rect:
			color_rect.scale.x = facing_dir

	var target_scale_x = 1.0 if facing_dir > 0 else -1.0
	scale.x = target_scale_x

	var dist = global_position.distance_to(player.global_position)

	match state:
		State.IDLE:
			velocity.x = 0
			if dist < 350:
				state = State.CHASING

		State.CHASING:
			velocity.x = facing_dir * speed
			move_and_slide()
			if dist < attack_range:
				state = State.WINDUP
				windup_timer = 0.0
				color_rect.color = COLOR_WINDUP

		State.WINDUP:
			velocity.x = facing_dir * speed * 0.2
			move_and_slide()
			windup_timer += delta
			if windup_timer >= windup_time:
				state = State.LUNGE
				color_rect.color = COLOR_ATTACK
				_lunge()

		State.LUNGE:
			velocity.x = 0

		State.KNOCKBACK:
			velocity.x = 0

		State.BLOCK:
			velocity.x = 0
			move_and_slide()
			block_timer -= delta
			if block_timer <= 0:
				state = State.COOLDOWN
				cooldown_timer = cooldown_time
				color_rect.color = COLOR_COOLDOWN

		State.COOLDOWN:
			velocity.x = 0
			move_and_slide()
			cooldown_timer -= delta
			if cooldown_timer <= 0:
				state = State.CHASING
				color_rect.color = COLOR_NORMAL

func _lunge():
	var target_x = global_position.x + facing_dir * lunge_distance
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position:x", target_x, 0.1)
	await tween.finished

	if state == State.LUNGE:
		state = State.KNOCKBACK
		_knockback()

func _knockback():
	if not player:
		return
	var dir = -1 if player.global_position.x > global_position.x else 1
	var target_x = global_position.x + dir * knockback_distance
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position:x", target_x, knockback_duration)
	await tween.finished

	if state == State.KNOCKBACK:
		state = State.BLOCK
		block_timer = block_duration
		color_rect.color = COLOR_BLOCK
