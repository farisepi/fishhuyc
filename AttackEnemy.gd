extends CharacterBody2D

@export var speed: float = 120.0
@export var gravity: float = 980.0
@export var attack_range: float = 70.0
@export var windup_time: float = 1.0
@export var lunge_distance: float = 50.0
@export var lunge_speed: float = 300.0
@export var knockback_distance: float = 60.0
@export var knockback_duration: float = 0.4
@export var cooldown_time: float = 1.5

enum State { IDLE, CHASING, WINDUP, LUNGE, KNOCKBACK, COOLDOWN }
var state: State = State.IDLE
var player: CharacterBody2D = null
var is_aggro: bool = false
var windup_timer: float = 0.0
var cooldown_timer: float = 0.0

@onready var color_rect: ColorRect = $ColorRect
@onready var detection_area: Area2D = $DetectionArea
@onready var hit_area: Area2D = $HitArea

func _ready():
	add_to_group("enemies")
	color_rect.color = Color(0.2, 0.6, 0.2, 1)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	hit_area.body_entered.connect(_on_hit_area_body_entered)

func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("player") and not is_aggro:
		is_aggro = true
		player = body
		print("враг агрится")

func _on_hit_area_body_entered(body: Node2D):
	if body.is_in_group("player") and state == State.LUNGE:
		if body.has_method("is_blocking") and body.is_blocking():
			print("игрок заблокировал урон")
		elif body.has_method("take_damage"):
			body.take_damage(1)
			print("удар по игроку")
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
	
	var dir = sign(player.global_position.x - global_position.x)
	var dist = global_position.distance_to(player.global_position)
	
	match state:
		State.IDLE:
			velocity.x = 0
			if dist < 300 and cooldown_timer <= 0:
				state = State.CHASING
				print("преследование")
		
		State.CHASING:
			velocity.x = dir * speed
			move_and_slide()
			if dist < attack_range and cooldown_timer <= 0:
				state = State.WINDUP
				windup_timer = 0.0
				color_rect.color = Color(0.8, 0.2, 1.0, 1)
				print("замах")
		
		State.WINDUP:
			velocity.x = 0
			windup_timer += delta
			if windup_timer >= windup_time:
				state = State.LUNGE
				color_rect.color = Color(1, 0.2, 0.2, 1)
				_lunge(dir)
		
		State.LUNGE:
			velocity.x = 0
		
		State.KNOCKBACK:
			velocity.x = 0
		
		State.COOLDOWN:
			velocity.x = 0
			cooldown_timer -= delta
			if cooldown_timer <= 0:
				state = State.CHASING
				color_rect.color = Color(0.2, 0.6, 0.2, 1)
				print("готов к атаке")

func _lunge(dir: int):
	var target_x = global_position.x + dir * lunge_distance
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position:x", target_x, 0.12)
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
		state = State.COOLDOWN
		cooldown_timer = cooldown_time
		color_rect.color = Color(0.4, 0.4, 0.4, 1)
		print("откат")
