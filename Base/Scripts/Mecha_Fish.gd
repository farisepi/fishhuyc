extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var slide_speed: float = 350.0
@export var gravity: float = 980.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var is_crouching: bool = false
var is_vaulting: bool = false
var is_sliding: bool = false

func _ready():
	sprite.play("idle")
	if camera:
		camera.zoom = Vector2(1.5, 1.5)
		camera.limit_left = 0
		camera.limit_right = 1920
		camera.limit_top = 0
		camera.limit_bottom = 360

func _physics_process(delta):
	if is_vaulting:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction > 0:
		sprite.scale.x = 1
	elif direction < 0:
		sprite.scale.x = -1
	
	if is_crouching:
		velocity.x = direction * speed * 0.3
		sprite.scale.y = 0.6
	else:
		velocity.x = direction * speed
		sprite.scale.y = 1.0
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		if not _try_vault():
			velocity.y = jump_velocity
	
	is_crouching = Input.is_action_pressed("crouch")
	
	if is_crouching and abs(velocity.x) > 100:
		sprite.scale.y = 0.3
		$CollisionShape2D.scale.y = 0.3
		velocity.x = direction * speed
	else:
		sprite.scale.y = 0.6 if is_crouching else 1.0
		$CollisionShape2D.scale.y = 1.0
	
	move_and_slide()

func _try_vault() -> bool:
	var container = get_parent().get_node_or_null("Barriers")
	if not container:
		return false
	
	for obs in container.get_children():
		if obs is StaticBody2D:
			var dist = global_position.distance_to(obs.global_position)
			if dist < 150:
				_vault(obs)
				return true
	
	return false

func _vault(obs: StaticBody2D):
	is_vaulting = true
	velocity = Vector2.ZERO
	
	var dir = 1 if sprite.scale.x > 0 else -1
	var target = Vector2(obs.global_position.x + dir * 60, obs.global_position.y - 60)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", target, 0.4)
	await tween.finished
	
	is_vaulting = false
	velocity.x = dir * speed

func _start_slide(direction: float):
	is_sliding = true
	sprite.scale.y = 0.3
	$CollisionShape2D.scale.y = 0.3
	
	var dir = 1 if direction >= 0 else -1
	velocity.x = dir * slide_speed
	
	await get_tree().create_timer(0.4).timeout
	
	sprite.scale.y = 1.0
	$CollisionShape2D.scale.y = 1.0
	is_sliding = false

func _try_vault_or_jump():
	var container = get_parent().get_node_or_null("Barriers")
	
	if container:
		for obs in container.get_children():
			if obs is StaticBody2D:
				var dist = global_position.distance_to(obs.global_position)
				if dist < 150:
					_vault(obs)
					return
	
	velocity.y = jump_velocity
