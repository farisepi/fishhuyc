extends CharacterBody2D

@export var speed: float = 200.0
@export var run_speed: float = 350.0
@export var jump_velocity: float = -300.0
@export var slide_speed: float = 650.0
@export var gravity: float = 980.0
@export var barriers_node: Node2D = null
@export var enemies_node: Node2D = null
@export var item_scene: PackedScene = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $MechaFishCamera

var is_dead: bool = false
var original_color: Color = Color(1, 1, 1, 1)
var block_color: Color = Color(0.5, 0.8, 1.0, 1)
var hp: int = 100
var is_blocking: bool = false
var is_crouching: bool = false
var is_vaulting: bool = false
var is_climbing: bool = false
var is_sliding: bool = false
var slide_timer: float = 0.0
var has_item: bool = false
var held_texture: Texture2D
var held_icon: Sprite2D
var can_throw: bool = false
var movement_blocked: bool = false
var dash_cooldown: float = 0.0
var is_dashing: bool = false
var is_shift_held: bool = false
var shift_held_time: float = 0.0

var parry_active: bool = false
var parry_done: bool = false
var parry_enemy: CharacterBody2D = null
var parry_callback: Callable = Callable()
var parry_fade: ColorRect = null
var parry_label: Label = null
var parry_cooldown: float = 0.0
var parry_cooldown_time: float = 3.0

func _ready():
	add_to_group("player")
	sprite.play("Idle")
	held_icon = Sprite2D.new()
	held_icon.visible = false
	held_icon.scale = Vector2(0.8, 0.8)
	held_icon.z_index = 100
	add_child(held_icon)
func _physics_process(delta):
	if is_shift_held:
		shift_held_time += delta
	if dash_cooldown > 0:
		dash_cooldown -= delta
	if is_dashing:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if is_blocking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if movement_blocked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if is_shift_held:
		shift_pressed_time += delta
	if get_tree().paused:
		return
	if parry_cooldown > 0:
		parry_cooldown -= delta
	if is_vaulting or is_climbing:
		return
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction = Input.get_axis("ui_left", "ui_right")
	var running = Input.is_action_pressed("Run")

	if direction < 0:
		facing_direction = -1
	elif direction > 0:
		facing_direction = 1

	sprite.scale.x = 1 if direction > 0 else -1 if direction < 0 else sprite.scale.x
	var spd = run_speed if running else speed

	if not is_sliding and not is_vaulting and not is_climbing:
		if direction != 0 and running:
			sprite.play("Run")
		else:
			sprite.play("Idle")

	if is_crouching and running and (abs(velocity.x) > 10 or is_sliding):
		if not is_sliding:
			is_sliding = true
			slide_timer = 0.0
			sprite.play("Fall")
			await get_tree().create_timer(0.3).timeout
			sprite.play("Slide")
			$CollisionShape2D.scale.y = 0.6
		slide_timer += delta
		var sp = min(slide_timer / 1, 2)
		velocity.x = lerp(slide_speed, 0.0, sp) * direction
	elif is_crouching and running:
		velocity.x = 0
	elif is_crouching and not running:
		velocity.x = direction * speed * 0.3
		sprite.scale.y = 0.6
	else:
		if is_sliding:
			sprite.play("GetUp")
			await get_tree().create_timer(0.3).timeout
			_end_slide()
			velocity.x = direction * spd
		else:
			velocity.x = direction * spd
			sprite.scale.y = 1.0
			$CollisionShape2D.scale.y = 1.0

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		if not _try_vault():
			velocity.y = jump_velocity

	if Input.is_action_just_pressed("interact") and not is_on_floor() and not has_item:
		_try_climb()

	is_crouching = Input.is_action_pressed("crouch")
	move_and_slide()

	if is_sliding and is_on_wall():
		global_position.y += 3

	if camera:
		camera.global_position = global_position

	if held_item_icon:
		held_item_icon.global_position = global_position + Vector2(0, -60)

	if held_icon.visible:
		held_icon.global_position = global_position + Vector2(0, -60)
		held_icon.modulate = Color.RED if can_throw else Color.WHITE

	if parry_active and not parry_done:
		if Input.is_action_just_pressed("Parry"):
			do_parry()

func _end_slide():
	is_sliding = false
	slide_timer = 0.0
	$CollisionShape2D.scale.y = 1.0

var shift_pressed_time: float = 0.0
var shift_just_pressed: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("block"):
		is_blocking = true
		if sprite:
			sprite.modulate = Color(0.5, 0.8, 1.0, 1)
	if event.is_action_released("block"):
		is_blocking = false
		if sprite:
			sprite.modulate = Color(1, 1, 1, 1)
	
	if event.is_action_pressed("interact"):
		if has_item:
			_throw_item()
		else:
			_grab_item()
	
	if event.is_action_pressed("Parry"):
		if parry_active and not parry_done:
			do_parry()
	
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		if event.pressed:
			is_shift_held = true
			shift_held_time = 0.0
		else:
			is_shift_held = false
			if shift_held_time < 0.3 and dash_cooldown <= 0 and not is_dashing and not is_sliding and not movement_blocked:
				_dash()

var held_item: Node2D = null
var held_item_icon: Sprite2D = null
var held_item_texture: Texture2D = null
var item_thrown: bool = false
var facing_direction: int = 1

func _grab_item():
	if has_item:
		return
	item_thrown = false
	for body in $GrabArea.get_overlapping_areas():
		if body.is_in_group("grabbable"):
			var parent = body.get_parent()
			if parent:
				has_item = true
				held_item = parent
				held_item_texture = body.item_texture

				if held_item_icon:
					held_item_icon.queue_free()

				held_item_icon = Sprite2D.new()
				held_item_icon.texture = held_item_texture
				held_item_icon.scale = Vector2(0.8, 0.8)
				held_item_icon.global_position = global_position + Vector2(0, -60)
				held_item_icon.z_index = 10
				get_tree().current_scene.add_child(held_item_icon)

				parent.queue_free()
				break

func _throw_item():
	if not has_item:
		return
	print("_throw_item вызван, facing_direction = ", facing_direction)
	has_item = false
	item_thrown = false

	if held_item_icon:
		held_item_icon.queue_free()
		held_item_icon = null

	if held_item_texture:
		var enemy = _find_nearest_enemy()
		if enemy and global_position.distance_to(enemy.global_position) < 500:
			print("бросаю во врага")
			_throw_item_at_target(enemy, held_item_texture)
		else:
			print("бросаю по дуге")
			_throw_item_physics(held_item_texture)
	else:
		print("нет текстуры предмета")

	held_item = null
	held_item_texture = null
	held_icon.visible = false
func _throw_item_physics(texture: Texture2D):
	print("бросаю предмет по дуге")
	if not item_scene:
		print("нет сцены предмета")
		return

	var thrown = item_scene.instantiate()
	thrown.global_position = global_position + Vector2(0, -20)
	get_tree().current_scene.add_child(thrown)

	if thrown is RigidBody2D:
		thrown.collision_layer = 3
		thrown.collision_mask = 3
		thrown.gravity_scale = 2.0
		thrown.freeze = false
		var dir = -1 if facing_direction == -1 else 1
		thrown.apply_impulse(Vector2(dir * 300, -150), Vector2.ZERO)

		var pickup = thrown.get_node_or_null("PickupArea")
		if pickup:
			pickup.monitoring = false
			pickup.monitorable = false
			pickup.queue_free()

		await get_tree().create_timer(0.5).timeout

		var tween = create_tween()
		tween.tween_property(thrown, "modulate:a", 0.0, 0.8)
		await tween.finished
		thrown.queue_free()
		print("предмет разрушен")

func _throw_item_at_target(enemy: Node2D, texture: Texture2D):
	print("бросаю предмет во врага")
	if not item_scene:
		return

	var thrown = item_scene.instantiate()
	thrown.global_position = global_position + Vector2(0, -20)
	get_tree().current_scene.add_child(thrown)

	if thrown is RigidBody2D:
		thrown.collision_layer = 3
		thrown.collision_mask = 3
		thrown.gravity_scale = 0.5
		thrown.freeze = false
		var dir = -1 if facing_direction == -1 else 1
		var target_pos = enemy.global_position + Vector2(0, -20)
		var distance = global_position.distance_to(target_pos)
		var force = min(distance * 1.2, 500)
		thrown.apply_impulse(Vector2(dir * force, -50), Vector2.ZERO)

		var pickup = thrown.get_node_or_null("PickupArea")
		if pickup:
			pickup.monitoring = false
			pickup.monitorable = false
			pickup.queue_free()

		await get_tree().create_timer(0.3).timeout
		thrown.queue_free()
		if enemy.has_method("stun"):
			enemy.stun()
		print("враг оглушен")

func _find_nearest_enemy():
	if not enemies_node:
		print("enemies_node = null")
		return null
	var nearest = null
	var min_dist = 9999
	for enemy in enemies_node.get_children():
		if enemy is CharacterBody2D and not enemy.is_queued_for_deletion():
			var dist = global_position.distance_to(enemy.global_position)
			print("враг: ", enemy.name, " дистанция: ", dist)
			if dist < min_dist:
				min_dist = dist
				nearest = enemy
	if nearest:
		print("ближайший враг: ", nearest.name, " дистанция: ", min_dist)
	else:
		print("врагов нет")
	return nearest
func set_can_throw(value: bool):
	can_throw = value

func set_movement_blocked(blocked: bool):
	movement_blocked = blocked

func start_parry(enemy: CharacterBody2D, callback: Callable = Callable()):
	if parry_cooldown > 0:
		print("ПАРИРОВАНИЕ НА КД Осталось: ", parry_cooldown)
		return
	if parry_active or parry_done:
		return
	print("ПАРИРОВАНИЕ ЗАПУЩЕНО!")
	parry_active = true
	parry_done = false
	parry_enemy = enemy
	parry_callback = callback
	if parry_enemy:
		parry_enemy.visible = true
		parry_enemy.modulate = Color(1, 1, 1, 1)
		var start_x = parry_enemy.global_position.x - 100
		parry_enemy.global_position.x = start_x
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(parry_enemy, "global_position:x", start_x + 100, 0.3)
		await tween.finished
	Engine.time_scale = 0.0
	parry_fade = ColorRect.new()
	parry_fade.color = Color(0, 0, 0, 0)
	parry_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	parry_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parry_fade.z_index = 100
	get_tree().current_scene.add_child(parry_fade)
	var fade_tween = create_tween()
	fade_tween.tween_property(parry_fade, "color:a", 0.6, 0.3)
	await fade_tween.finished
	parry_label = Label.new()
	parry_label.text = "ПКМ - ПАРИРУЙ"
	parry_label.add_theme_font_size_override("font_size", 48)
	parry_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	parry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parry_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parry_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	parry_label.z_index = 101
	parry_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().current_scene.add_child(parry_label)

func do_parry():
	if parry_done or not parry_active:
		return
	print("ПАРИРОВАНИЕ УСПЕШНО!")
	parry_done = true
	parry_active = false
	if is_instance_valid(parry_enemy):
		parry_enemy.queue_free()
		parry_enemy = null
		print("Враг удалён!")
	if is_instance_valid(parry_label):
		parry_label.queue_free()
		parry_label = null
	if is_instance_valid(parry_fade):
		parry_fade.queue_free()
		parry_fade = null
	Engine.time_scale = 1.0
	get_tree().paused = false
	set_physics_process(true)
	set_process(true)
	is_vaulting = false
	is_climbing = false
	is_sliding = false
	is_crouching = false
	if sprite:
		sprite.play("Idle")
	velocity = Vector2.ZERO
	print("ИГРОК ВКЛЮЧЁН!")
	if parry_callback != null:
		parry_callback.call()

func _try_vault() -> bool:
	if not barriers_node:
		return false
	for o in barriers_node.get_children():
		if o is StaticBody2D and global_position.distance_to(o.global_position) < 60:
			var s = o.get_node("CollisionShape2D").shape
			if s is RectangleShape2D:
				if s.size.y > 60:
					return false
				_jump_over(o, s.size.y >= 30)
				return true
	return false

func _jump_over(o: StaticBody2D, high: bool):
	is_vaulting = true
	velocity = Vector2.ZERO
	var d = 1 if sprite.scale.x > 0 else -1
	var t = global_position
	t.x = o.global_position.x + d * 50
	t.y = o.global_position.y - 30 if high else global_position.y
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(self, "global_position", t, 0.3 if high else 0.15)
	await get_tree().create_timer(0.3 if high else 0.15).timeout
	is_vaulting = false
	velocity.x = speed * d

func _try_climb():
	if is_on_floor():
		return
	if has_item:
		return
	if movement_blocked:
		return
	if not barriers_node:
		return
	for o in barriers_node.get_children():
		if o is StaticBody2D:
			var dist = global_position.distance_to(o.global_position)
			if dist < 100:
				var s = o.get_node("CollisionShape2D").shape
				if s is RectangleShape2D and s.size.y > 60:
					is_climbing = true
					velocity = Vector2.ZERO
					var d = 1 if sprite.scale.x > 0 else -1
					var target = Vector2(
						o.global_position.x + d * 5,
						o.global_position.y - s.size.y - 5
					)
					var t = create_tween()
					t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					t.tween_property(self, "global_position", target, 0.3)
					await t.finished
					is_climbing = false
					velocity.x = speed * d
					return

func die():
	if is_dead:
		return
	is_dead = true
	print("смерть игрока")
	if sprite:
		sprite.play("Death")
		await sprite.animation_finished
		sprite.stop()
		sprite.frame = sprite.sprite_frames.get_frame_count("Death") - 1
		await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func take_damage(amount: int):
	hp -= amount
	if hp < 0:
		hp = 0
	print("урон, хп: ", hp)
	if sprite:
		sprite.play("Hit")
		await sprite.animation_finished
		sprite.play("Idle")
	if hp <= 0:
		die()

func _dash():
	if is_dashing or dash_cooldown > 0:
		return
	print("рывок")
	is_dashing = true
	dash_cooldown = 1.5
	var direction = -1 if facing_direction == -1 else 1
	var target_x = global_position.x + direction * 120
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position:x", target_x, 0.25)
	await tween.finished
	is_dashing = false
