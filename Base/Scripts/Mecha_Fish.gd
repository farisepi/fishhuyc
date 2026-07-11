extends CharacterBody2D

@export var speed: float = 200.0
@export var run_speed: float = 350.0
@export var jump_velocity: float = -300.0
@export var slide_speed: float = 500.0
@export var gravity: float = 980.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var is_crouching: bool = false
var is_vaulting: bool = false
var is_climbing: bool = false
var is_sliding: bool = false
var slide_timer: float = 0.0
var has_item: bool = false
var held_texture: Texture2D
var held_icon: Sprite2D

func _ready():
	sprite.play("Idle")
	
	held_icon = Sprite2D.new()
	held_icon.visible = false
	held_icon.scale = Vector2(0.3, 0.3)
	held_icon.z_index = 10
	add_child(held_icon)
	
	if camera:
		camera.zoom = Vector2(1.5, 1.5)
		camera.limit_left = 0
		camera.limit_right = 3335
		camera.limit_top = 0
		camera.limit_bottom = 360

func _physics_process(delta):
	if is_vaulting or is_climbing:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	var running = Input.is_action_pressed("Run")
	
	sprite.scale.x = 1 if direction > 0 else -1 if direction < 0 else sprite.scale.x
	var spd = run_speed if running else speed
	
	if is_crouching and running and abs(velocity.x) > 100:
		if not is_sliding:
			is_sliding = true
			slide_timer = 0.0
			sprite.scale.y = 0.3
			sprite.position.y = 15
			$CollisionShape2D.scale.y = 0.3
			$CollisionShape2D.position.y = 10
		
		slide_timer += delta
		
		if slide_timer < 0.25:
			velocity.x = direction * slide_speed
		elif slide_timer < 0.5:
			velocity.x = direction * speed * 0.7
		else:
			velocity.x = direction * speed * 0.3
	elif is_crouching and not running:
		velocity.x = direction * speed * 0.3
		sprite.scale.y = 0.6
		sprite.position.y = 5
	else:
		if is_sliding:
			sprite.scale.y = 1.0
			sprite.position.y = 0
			$CollisionShape2D.scale.y = 1.0
			$CollisionShape2D.position.y = 0
		is_sliding = false
		slide_timer = 0.0
		velocity.x = direction * spd
		sprite.scale.y = 1.0
		sprite.position.y = 0
		$CollisionShape2D.scale.y = 1.0
		$CollisionShape2D.position.y = 0
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		if not _try_vault():
			velocity.y = jump_velocity
	
	if Input.is_action_just_pressed("interact") and not is_on_floor() and not has_item:
		_try_climb()
	
	is_crouching = Input.is_action_pressed("crouch")
	move_and_slide()
	
	if camera:
		camera.global_position = global_position
	
	if held_icon.visible:
		held_icon.global_position = global_position + Vector2(0, -50)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if has_item:
			_throw_item()
		else:
			_grab_item()

func _grab_item():
	for body in $GrabArea.get_overlapping_areas():
		if body.is_in_group("grabbable"):
			has_item = true
			held_texture = body.item_texture
			held_icon.texture = held_texture
			held_icon.visible = true
			body.queue_free()
			break

func _throw_item():
	if not has_item:
		return
	
	has_item = false
	held_icon.visible = false
	
	var thrown = Sprite2D.new()
	thrown.texture = held_texture
	thrown.scale = Vector2(0.4, 0.4)
	thrown.global_position = global_position + Vector2(0, -20)
	thrown.z_index = 5
	get_parent().add_child(thrown)
	
	var dir = 1 if sprite.scale.x > 0 else -1
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(thrown, "position:x", thrown.position.x + dir * 300, 0.3)
	t.tween_property(thrown, "position:y", thrown.position.y - 50, 0.15)
	t.tween_property(thrown, "position:y", global_position.y, 0.15).set_delay(0.15)
	t = create_tween()
	t.tween_property(thrown, "rotation", dir * 10, 0.3)
	
	await get_tree().create_timer(0.2).timeout
	
	var enemies = get_parent().get_node_or_null("Enemies")
	if enemies:
		for enemy in enemies.get_children():
			if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
				if enemy.global_position.distance_to(thrown.global_position) < 80:
					if enemy.has_method("stun"):
						enemy.stun()
					break
	
	await get_tree().create_timer(0.1).timeout
	thrown.queue_free()

func _try_vault() -> bool:
	var c = get_parent().get_node_or_null("Barriers")
	if not c: return false
	for o in c.get_children():
		if o is StaticBody2D and global_position.distance_to(o.global_position) < 80:
			var s = o.get_node("CollisionShape2D").shape
			if s is RectangleShape2D:
				if s.size.y > 60: return false
				_jump_over(o, s.size.y >= 30)
				return true
	return false

func _jump_over(o: StaticBody2D, high: bool):
	is_vaulting = true
	velocity = Vector2.ZERO
	var d = 1 if sprite.scale.x > 0 else -1
	var t = global_position
	t.x = o.global_position.x + d * 80
	t.y = o.global_position.y - 60 if high else global_position.y
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(self, "global_position", t, 0.3 if high else 0.15)
	await get_tree().create_timer(0.3 if high else 0.15).timeout
	is_vaulting = false
	velocity.x = speed * d

func _try_climb():
	var c = get_parent().get_node_or_null("Barriers")
	if not c: return
	for o in c.get_children():
		if o is StaticBody2D and global_position.distance_to(o.global_position) < 80:
			var s = o.get_node("CollisionShape2D").shape
			if s is RectangleShape2D and s.size.y > 60:
				is_climbing = true
				velocity = Vector2.ZERO
				var d = 1 if sprite.scale.x > 0 else -1
				var land = Vector2(o.global_position.x + d * 80, o.global_position.y - s.size.y - 20)
				var t = create_tween()
				t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				t.tween_property(self, "global_position", land, 0.5)
				await t.finished
				is_climbing = false
				velocity.x = speed * d
				return
