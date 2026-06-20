extends CharacterBody2D

@export var speed: float = 200.0
@export var run_speed: float = 350.0
@export var jump_velocity: float = -300.0
@export var slide_speed: float = 420.0
@export var gravity: float = 980.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var is_crouching: bool = false
var is_vaulting: bool = false
var is_running: bool = false
var has_item: bool = false
var item_type: String = ""

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if has_item:
			_throw_item()
		else:
			_grab_item()

func _grab_item():
	var grab_area = $GrabArea
	if not grab_area:
		return
	
	for body in grab_area.get_overlapping_areas():
		if body.is_in_group("grabbable"):
			has_item = true
			item_type = body.item_name
			body.queue_free()
			sprite.modulate = Color(1.0, 0.8, 0.2)
			break

func _throw_item():
	has_item = false
	sprite.modulate = Color.WHITE
	
	var thrown = ColorRect.new()
	thrown.color = Color(0.8, 0.5, 0.2)
	thrown.size = Vector2(20, 20)
	thrown.position = global_position + Vector2(0, -20)
	get_parent().add_child(thrown)
	
	var dir = 1 if sprite.scale.x > 0 else -1
	var tween = create_tween()
	tween.tween_property(thrown, "position:x", thrown.position.x + dir * 300, 0.3)
	tween.parallel().tween_property(thrown, "position:y", thrown.position.y - 50, 0.15)
	tween.tween_property(thrown, "position:y", 340, 0.15).set_delay(0.15)
	tween.finished.connect(thrown.queue_free)

func _ready():
	sprite.play("idle")
	if camera:
		camera.zoom = Vector2(1.5, 1.5)
		camera.limit_left = 0
		camera.limit_right = 2857
		camera.limit_top = 0
		camera.limit_bottom = 360
		camera.global_position = global_position

func _physics_process(delta):
	if is_vaulting:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	is_running = Input.is_action_pressed("Run")
	
	if direction > 0:
		sprite.scale.x = 1
	elif direction < 0:
		sprite.scale.x = -1
	
	var current_speed = run_speed if is_running else speed
	
	if is_crouching and not is_running:
		# Скрытное передвижение
		velocity.x = direction * speed * 0.3
		sprite.scale.y = 0.6
	elif is_crouching and is_running:
		# Скольжение на бегу
		sprite.scale.y = 0.3
		$CollisionShape2D.scale.y = 0.3
		velocity.x = direction * slide_speed
	else:
		velocity.x = direction * current_speed
		sprite.scale.y = 1.0
		$CollisionShape2D.scale.y = 1.0
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		if not _try_vault():
			velocity.y = jump_velocity
	
	is_crouching = Input.is_action_pressed("crouch")
	
	move_and_slide()
	
	if camera:
		camera.global_position = global_position

func _try_vault() -> bool:
	var container = get_parent().get_node_or_null("Barriers")
	if not container:
		return false
	
	for obs in container.get_children():
		if obs is StaticBody2D:
			var dist = global_position.distance_to(obs.global_position)
			if dist < 80:
				_vault(obs)
				return true
	
	return false

func _vault(obs: StaticBody2D):
	is_vaulting = true
	velocity = Vector2.ZERO
	
	var moving_right = velocity.x > 0 || (velocity.x == 0 && sprite.scale.x > 0)
	var target = global_position
	
	if moving_right:
		target.x = obs.global_position.x + 80
	else:
		target.x = obs.global_position.x - 80
	
	target.y = obs.global_position.y - 60
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", target, 0.4)
	await tween.finished
	
	is_vaulting = false
	velocity.x = run_speed if moving_right else -run_speed
