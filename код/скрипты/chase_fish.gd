extends CharacterBody2D

@export var run_speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var slide_speed: float = 500.0
@export var slide_duration: float = 0.5
@export var gravity: float = 980.0

@onready var sprite: Sprite2D = $Sprite2D
var is_sliding: bool = false
var slide_timer: float = 0.0
var has_item: bool = false
var is_crouching: bool = false
var is_vaulting: bool = false
var normal_color = Color(0.3, 0.5, 1.0)

func _physics_process(delta: float) -> void:
	if is_vaulting:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = run_speed
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_sliding and not is_crouching:
		velocity.y = jump_velocity
	
	if Input.is_action_pressed("crouch") and is_on_floor():
		if not is_sliding and not is_crouching:
			if abs(velocity.x) > 200:
				_start_slide()
			else:
				_start_crouch()
	
	if Input.is_action_just_released("crouch"):
		if is_sliding:
			_end_slide()
		if is_crouching:
			_end_crouch()
	
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0 and not Input.is_action_pressed("crouch"):
			_end_slide()
	
	# Проверка Vault — автоматически перелезаем
	if is_on_floor() and not is_sliding and not is_vaulting:
		_check_vault()
	
	move_and_slide()

func _check_vault():
	var vaults = get_parent().get_node_or_null("Vaults")
	if not vaults:
		return
	
	for vault in vaults.get_children():
		if vault is StaticBody2D:
			var rect = Rect2(vault.global_position - Vector2(20, 25), Vector2(40, 50))
			var player_rect = Rect2(global_position - Vector2(15, 25), Vector2(30, 50))
			if rect.intersects(player_rect):
				_start_vault(vault.global_position)
				break

func _start_vault(vault_pos: Vector2):
	is_vaulting = true
	velocity = Vector2.ZERO
	sprite.modulate = Color(1.0, 1.0, 0.2)  # Жёлтый — перелезает
	
	# Перелезаем через препятствие
	var tween = create_tween()
	tween.tween_property(self, "global_position:x", vault_pos.x + 60, 0.3)
	tween.parallel().tween_property(self, "global_position:y", vault_pos.y - 50, 0.3)
	tween.tween_property(self, "global_position:y", vault_pos.y - 20, 0.3).set_delay(0.3)
	await tween.finished
	
	is_vaulting = false
	velocity.x = run_speed
	sprite.modulate = normal_color

func _start_slide():
	is_sliding = true
	is_crouching = false
	slide_timer = slide_duration
	velocity.x = slide_speed
	sprite.modulate = Color(0.2, 0.3, 0.8)
	$CollisionShape2D.scale.y = 0.3
	$CollisionShape2D.position.y = 10

func _end_slide():
	is_sliding = false
	velocity.x = run_speed
	sprite.modulate = normal_color
	$CollisionShape2D.scale.y = 1.0
	$CollisionShape2D.position.y = 0

func _start_crouch():
	is_crouching = true
	sprite.modulate = Color(0.4, 0.5, 0.7)
	$CollisionShape2D.scale.y = 0.6
	$CollisionShape2D.position.y = 10

func _end_crouch():
	is_crouching = false
	sprite.modulate = normal_color
	$CollisionShape2D.scale.y = 1.0
	$CollisionShape2D.position.y = 0

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
			sprite.modulate = Color(1.0, 0.8, 0.2)
			body.queue_free()
			break

func _throw_item():
	has_item = false
	get_parent().first_item_taken = true
	sprite.modulate = normal_color
	
	var target_pos = global_position + Vector2(-300, 0)
	var enemies = get_parent().get_node_or_null("Enemies")
	if enemies:
		var closest_dist = 9999.0
		for enemy in enemies.get_children():
			if enemy is Node2D and not enemy.is_queued_for_deletion():
				var dist = enemy.global_position.distance_to(global_position)
				if dist < closest_dist:
					closest_dist = dist
					target_pos = enemy.global_position
	
	var thrown = ColorRect.new()
	thrown.color = Color(0.8, 0.5, 0.2)
	thrown.size = Vector2(20, 20)
	thrown.position = global_position + Vector2(0, -20)
	get_parent().add_child(thrown)
	
	var tween = create_tween()
	tween.tween_property(thrown, "global_position", target_pos, 0.2)
	tween.finished.connect(thrown.queue_free)
	
	await get_tree().create_timer(0.15).timeout
	get_parent()._hit_enemy(thrown.global_position)
