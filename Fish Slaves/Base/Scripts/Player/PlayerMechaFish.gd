extends CharacterBody2D

@export var speed: float = 200.0
@export var run_speed: float = 350.0
@export var jump_velocity: float = -300.0
@export var slide_speed: float = 650.0
@export var gravity: float = 980.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $"../MechaFishCamera"

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

# ==========================================
# ПАРИРОВАНИЕ
# ==========================================
var parry_active: bool = false
var parry_done: bool = false
var parry_enemy: CharacterBody2D = null
var parry_callback: Callable = Callable()
var parry_fade: ColorRect = null
var parry_label: Label = null
var parry_cooldown: float = 0.0
var parry_cooldown_time: float = 3.0

func _ready():
	sprite.play("Idle")
	
	held_icon = Sprite2D.new()
	held_icon.visible = false
	held_icon.scale = Vector2(0.5, 0.5)
	held_icon.z_index = 100
	add_child(held_icon)

func _physics_process(delta):
	# БЛОКИРОВКА ДВИЖЕНИЯ ДЛЯ УЗКОГО ПРОХОДА
	if movement_blocked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if get_tree().paused:
		return
	
	# Обновляем КД
	if parry_cooldown > 0:
		parry_cooldown -= delta
	
	if is_vaulting or is_climbing:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	var running = Input.is_action_pressed("Run")
	
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
	
	if held_icon.visible:
		held_icon.global_position = global_position + Vector2(0, -60)
		held_icon.modulate = Color.RED if can_throw else Color.WHITE
	
	# ==========================================
	# ПАРИРОВАНИЕ - ПРОВЕРКА КНОПКИ
	# ==========================================
	if parry_active and not parry_done:
		if Input.is_action_just_pressed("Parry"):
			do_parry()

func _end_slide():
	is_sliding = false
	slide_timer = 0.0
	$CollisionShape2D.scale.y = 1.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if has_item:
			_throw_item()
		else:
			_grab_item()
	
	# Парирование по кнопке Parry
	if event.is_action_pressed("Parry"):
		if parry_active and not parry_done:
			do_parry()

func _grab_item():
	if has_item:
		return
	
	for body in $GrabArea.get_overlapping_areas():
		if body.is_in_group("grabbable"):
			has_item = true
			held_texture = body.item_texture
			held_icon.texture = held_texture
			held_icon.visible = true
			held_icon.modulate = Color.WHITE
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
	thrown.modulate = Color.RED
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

func set_can_throw(value: bool):
	can_throw = value

func set_movement_blocked(blocked: bool):
	movement_blocked = blocked

# ==========================================
# ПАРИРОВАНИЕ - ФУНКЦИИ
# ==========================================

func start_parry(enemy: CharacterBody2D, callback: Callable = Callable()):
	if parry_cooldown > 0:
		print("⏳ ПАРИРОВАНИЕ НА КД! Осталось: ", parry_cooldown)
		return
	
	if parry_active or parry_done:
		return
	
	print("🔥 ПАРИРОВАНИЕ ЗАПУЩЕНО!")
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
	get_parent().add_child(parry_fade)
	
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
	get_parent().add_child(parry_label)

func do_parry():
	if parry_done or not parry_active:
		return
	
	print("🔥 ПАРИРОВАНИЕ УСПЕШНО!")
	parry_done = true
	parry_active = false
	
	# УДАЛЯЕМ ВРАГА
	if is_instance_valid(parry_enemy):
		parry_enemy.queue_free()
		parry_enemy = null
		print("✅ Враг удалён!")
	
	# УБИРАЕМ НАДПИСЬ
	if is_instance_valid(parry_label):
		parry_label.queue_free()
		parry_label = null
	
	# УБИРАЕМ ЗАТЕМНЕНИЕ
	if is_instance_valid(parry_fade):
		parry_fade.queue_free()
		parry_fade = null
	
	# ВОЗВРАЩАЕМ ВРЕМЯ
	Engine.time_scale = 1.0
	get_tree().paused = false
	
	# ВКЛЮЧАЕМ ИГРОКА
	set_physics_process(true)
	set_process(true)
	is_vaulting = false
	is_climbing = false
	is_sliding = false
	is_crouching = false
	
	# АНИМАЦИЯ
	if sprite:
		sprite.play("Idle")
	
	velocity = Vector2.ZERO
	
	print("✅ ИГРОК ВКЛЮЧЁН!")
	
	if parry_callback != null:
		parry_callback.call()

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
	if is_on_floor():
		return
	if has_item:
		return
	
	var c = get_parent().get_node_or_null("Barriers")
	if not c:
		return
	
	for o in c.get_children():
		if o is StaticBody2D:
			var dist = global_position.distance_to(o.global_position)
			if dist < 100:
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
