extends CharacterBody2D

@export var speed: float = 140.0
@export var gravity: float = 980.0
@export var attack_range: float = 70.0
@export var windup_time: float = 1.0
@export var lunge_distance: float = 55.0
@export var knockback_distance: float = 80.0
@export var knockback_duration: float = 0.25
@export var cooldown_time: float = 1.8

enum State { IDLE, CHASING, WINDUP, LUNGE, KNOCKBACK, COOLDOWN }
var state: State = State.IDLE
var player: CharacterBody2D = null
var is_aggro: bool = false
var windup_timer: float = 0.0
var cooldown_timer: float = 0.0
var facing_dir: int = 1
var is_vaulting: bool = false

@onready var color_rect: ColorRect = $ColorRect
@onready var detection_area: Area2D = $DetectionArea
@onready var hit_area: Area2D = $HitArea

func _ready():
	add_to_group("enemies")
	collision_mask = 1
	collision_layer = 2
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
		if body.has_method("take_damage"):
			body.take_damage(1)
			print("удар по игроку")
			print("удар по игроку (1 сердце)")
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
	
	var dist = global_position.distance_to(player.global_position)
	
	match state:
		State.IDLE:
			velocity.x = 0
			if dist < 350:
				state = State.CHASING
				print("преследование")
		
		State.CHASING:
			velocity.x = facing_dir * speed
			move_and_slide()
			if dist < attack_range:
				state = State.WINDUP
				windup_timer = 0.0
				color_rect.color = Color(0.8, 0.2, 1.0, 1)
				print("замах")
		
		State.WINDUP:
			velocity.x = facing_dir * speed * 0.2
			move_and_slide()
			windup_timer += delta
			if windup_timer >= windup_time:
				state = State.LUNGE
				color_rect.color = Color(1, 0.2, 0.2, 1)
				_lunge()
		
		State.LUNGE:
			velocity.x = 0
		
		State.KNOCKBACK:
			velocity.x = 0
		
		State.COOLDOWN:
			velocity.x = 0
			move_and_slide()
			cooldown_timer -= delta
			if cooldown_timer <= 0:
				state = State.CHASING
				color_rect.color = Color(0.2, 0.6, 0.2, 1)
				print("готов к атаке")
	
	_try_vault()

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
		state = State.COOLDOWN
		cooldown_timer = cooldown_time
		color_rect.color = Color(0.4, 0.4, 0.4, 1)
		print("откат")

func _try_vault():
	if is_vaulting:
		return
	var barriers = get_tree().current_scene.get_node_or_null("Barriers")
	if not barriers:
		return
	for obstacle in barriers.get_children():
		if obstacle is StaticBody2D:
			var dist = global_position.distance_to(obstacle.global_position)
			if dist < 60:
				var shape = obstacle.get_node("CollisionShape2D").shape
				if shape is RectangleShape2D and shape.size.y > 30:
					var top_y = obstacle.global_position.y - shape.size.y
					var target = Vector2(
						obstacle.global_position.x + facing_dir * 50,
						top_y - 5
					)
					is_vaulting = true
					var tween = create_tween()
					tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					tween.tween_property(self, "global_position", target, 0.3)
					await tween.finished
					is_vaulting = false
					return
