extends CharacterBody2D

@export var speed: float = 180.0
@export var run_speed: float = 240.0
@export var jog_speed_mult: float = 0.5
@export var jump_velocity: float = -300.0
@export var slide_speed: float = 400.0
@export var gravity: float = 980.0
@export var barriers_node: Node2D = null
@export var enemies_node: Node2D = null
@export var item_scene: PackedScene = null
@export var deathzone_scene: PackedScene = null
@export var climb_time: float = 0.32

@export var attack_damage: int = 1
@export var attack_range: float = 80.0
@export var attack_hit_frame: int = 3

var block_click_attack: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $MechaFishCamera

var nearby_ladder: Area2D = null
var is_on_ladder: bool = false
var is_dead: bool = false
var hp: int = 5
var max_hp: int = 5
var stamina: float = 100.0
var max_stamina: float = 100.0
var is_blocking: bool = false
var is_vaulting: bool = false
var is_climbing: bool = false
var is_sliding: bool = false
var slide_timer: float = 0.0
var has_item: bool = false
var held_icon: Sprite2D
var held_item_icon: Sprite2D
var can_throw: bool = false
var movement_blocked: bool = false
var dash_cooldown: float = 0.0
var is_dashing: bool = false
var is_shift_held: bool = false
var shift_held_time: float = 0.0
var is_climbing_animation: bool = false
var parry_active: bool = false
var parry_done: bool = false
var parry_enemy: CharacterBody2D = null
var parry_callback: Callable = Callable()
var parry_fade: ColorRect = null
var parry_label: Label = null
var parry_cooldown: float = 0.0
var last_climbed_obstacle: Node = null

var is_attacking: bool = false
var attack_buffer: bool = false
var next_attack_is_left: bool = true
var _hit_done_this_attack: bool = false
var facing_direction: int = 1
const ATTACK_SPEED_MULT: float = 0.6
const ATTACK_CANCEL_FRAME: int = 7
const ATTACK_RESTART_FRAME: int = 1

var was_on_floor_last_frame: bool = true
var is_landing: bool = false
const LANDING_SPEED_MULT: float = 0.2

func _ready():
	add_to_group("player")
	hp = 5
	max_hp = 5
	stamina = 100.0
	if sprite:
		sprite.play("Idle")
	held_icon = Sprite2D.new()
	held_icon.visible = false
	held_icon.scale = Vector2(0.8, 0.8)
	held_icon.z_index = 100
	add_child(held_icon)

func get_hp() -> int:
	return hp

func get_max_hp() -> int:
	return max_hp

func get_stamina() -> float:
	return stamina

func set_nearby_ladder(ladder: Area2D):
	nearby_ladder = ladder

func _is_low_stamina() -> bool:
	return stamina <= 15.0

func _is_low_hp() -> bool:
	return hp <= 2

func _can_sprint() -> bool:
	return not _is_low_stamina() and not _is_low_hp()

func _physics_process(delta):
	if is_on_ladder:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if get_tree().paused:
		return
	if is_shift_held:
		shift_held_time += delta
	if dash_cooldown > 0:
		dash_cooldown -= delta
	if is_dashing or is_blocking or movement_blocked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if is_vaulting or is_climbing or is_climbing_animation:
		velocity.y = 0
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction < 0:
		facing_direction = -1
	elif direction > 0:
		facing_direction = 1
	if not is_attacking and not is_landing and direction != 0:
		sprite.scale.x = 1 if direction > 0 else -1

	var base_speed = run_speed
	if not _can_sprint():
		base_speed = run_speed * jog_speed_mult
	var spd = base_speed
	if is_attacking:
		spd = base_speed * ATTACK_SPEED_MULT
	if is_landing:
		spd = spd * LANDING_SPEED_MULT

	var on_floor_now = is_on_floor()
	if not was_on_floor_last_frame and on_floor_now:
		if not is_attacking and not is_sliding and not is_vaulting and not is_climbing and not is_climbing_animation and not is_landing:
			_play_landing()
	was_on_floor_last_frame = on_floor_now

	var slide_input = Input.is_action_pressed("crouch")
	var slide_tap = Input.is_action_just_pressed("crouch")
	if _is_low_stamina():
		slide_input = false
		slide_tap = false

	if slide_input and (abs(velocity.x) > 10 or is_sliding):
		if not is_sliding:
			is_sliding = true
			slide_timer = 0.0
			sprite.play("Fall")
			await get_tree().create_timer(0.3).timeout
			if is_sliding:
				sprite.play("Slide")
		if is_sliding:
			slide_timer += delta
			var sp = min(slide_timer / 2.0, 2)
			velocity.x = lerp(slide_speed, 0.0, sp) * direction
	elif slide_tap and not is_sliding and abs(velocity.x) > 10:
		is_sliding = true
		slide_timer = 0.0
		sprite.play("Slide")
		slide_timer += delta
		var sp = min(slide_timer / 1.0, 2)
		velocity.x = lerp(slide_speed, 0.0, sp) * direction
	else:
		if is_sliding:
			sprite.play("GetUp")
			await get_tree().create_timer(0.3).timeout
			_end_slide()
			velocity.x = direction * spd
		else:
			velocity.x = direction * spd

	if Input.is_action_just_pressed("jump") and is_on_floor():
		if not _try_vault():
			velocity.y = jump_velocity
			if not is_attacking:
				sprite.play("Jump")

	if Input.is_action_just_pressed("interact"):
		if nearby_ladder:
			_try_ladder_climb()
		elif not is_on_floor() and not has_item:
			_try_climb()

	if not is_attacking and not is_landing and not is_sliding and not is_vaulting and not is_climbing and not is_climbing_animation:
		if not is_on_floor():
			if velocity.y < 0:
				if sprite.animation != "Jump":
					sprite.play("Jump")
			else:
				if sprite.animation != "Falling":
					sprite.play("Falling")
		elif direction != 0:
			if not _can_sprint() and sprite.sprite_frames.has_animation("Jogging"):
				sprite.play("Jogging")
			else:
				sprite.play("Run")
		else:
			sprite.play("Idle")

	move_and_slide()

	if held_icon.visible:
		held_icon.global_position = global_position + Vector2(0, -60)

func _play_landing() -> void:
	if sprite == null:
		return
	if not sprite.sprite_frames.has_animation("Landing"):
		return
	if is_landing:
		return
	is_landing = true
	sprite.play("Landing")
	velocity.x *= LANDING_SPEED_MULT
	await sprite.animation_finished
	is_landing = false

func _end_slide():
	is_sliding = false
	slide_timer = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_dead and not is_sliding and not is_vaulting and not is_climbing and not is_climbing_animation and not is_landing:
			if is_attacking:
				attack_buffer = true
			else:
				_do_attack()
	if event.is_action_pressed("Parry"):
		if parry_active and not parry_done:
			do_parry()
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		if event.pressed:
			is_shift_held = true
			shift_held_time = 0.0
		else:
			is_shift_held = false
			if shift_held_time < 0.2 and dash_cooldown <= 0 and not is_dashing and not is_sliding and not movement_blocked:
				if not _is_low_stamina():
					_dash()

func _do_attack() -> void:
	if sprite == null:
		return
	if not sprite.sprite_frames.has_animation("AttackLeft") or not sprite.sprite_frames.has_animation("AttackRight"):
		return
	var use_left = next_attack_is_left
	next_attack_is_left = not next_attack_is_left
	is_attacking = true
	attack_buffer = false
	_hit_done_this_attack = false
	var anim = "AttackLeft" if use_left else "AttackRight"
	sprite.play(anim)
	sprite.frame = ATTACK_RESTART_FRAME
	var hit_frame = min(attack_hit_frame, sprite.sprite_frames.get_frame_count(anim) - 1)
	while sprite.is_playing() and sprite.frame < hit_frame:
		await get_tree().process_frame
	if not _hit_done_this_attack:
		_hit_done_this_attack = true
		_deal_attack_damage()
	await sprite.animation_finished
	if attack_buffer:
		attack_buffer = false
		is_attacking = false
		_do_attack()
		return
	is_attacking = false
	sprite.play("Idle")

func _deal_attack_damage() -> void:
	var dir = 1 if facing_direction > 0 else -1
	var origin = global_position + Vector2(dir * attack_range * 0.5, 0)
	var candidates: Array = []
	if enemies_node:
		for e in enemies_node.get_children():
			candidates.append(e)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not candidates.has(e):
			candidates.append(e)
	var best = null
	var best_dist = attack_range
	for e in candidates:
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			continue
		if not e.has_method("take_damage"):
			continue
		var d = origin.distance_to(e.global_position)
		var side_ok = (e.global_position.x - global_position.x) * dir >= -15.0
		if d < best_dist and side_ok:
			best_dist = d
			best = e
	if best:
		best.take_damage(attack_damage)
		if camera and camera.has_method("add_trauma"):
			camera.add_trauma(0.08)

func take_damage(amount: int):
	if is_dead:
		return
	hp -= amount
	if hp < 0:
		hp = 0
	if sprite:
		sprite.play("Hit")
		await sprite.animation_finished
		if not is_attacking:
			sprite.play("Idle")
	if hp <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	movement_blocked = true
	velocity = Vector2.ZERO
	if sprite:
		sprite.play("Death")
	await get_tree().create_timer(1.0).timeout
	var death_screen = get_tree().current_scene.get_node_or_null("DeathScreen")
	if death_screen and death_screen.has_method("show_death"):
		death_screen.show_death()

func _dash():
	if is_dashing or dash_cooldown > 0:
		return
	if _is_low_stamina():
		return
	is_dashing = true
	dash_cooldown = 1.5
	var direction = -1 if facing_direction == -1 else 1
	var target_x = global_position.x + direction * 100
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position:x", target_x, 0.25)
	await tween.finished
	is_dashing = false

func do_parry():
	if parry_done or not parry_active:
		return
	parry_done = true
	parry_active = false
	if is_instance_valid(parry_enemy):
		parry_enemy.queue_free()
	if is_instance_valid(parry_label):
		parry_label.queue_free()
	if is_instance_valid(parry_fade):
		parry_fade.queue_free()
	Engine.time_scale = 1.0
	get_tree().paused = false
	if sprite:
		sprite.play("Idle")
	velocity = Vector2.ZERO
	if parry_callback.is_valid():
		parry_callback.call()

func start_parry(enemy: CharacterBody2D, callback: Callable = Callable()):
	if parry_cooldown > 0 or parry_active or parry_done:
		return
	parry_active = true
	parry_done = false
	parry_enemy = enemy
	parry_callback = callback
	Engine.time_scale = 0.0
	parry_fade = ColorRect.new()
	parry_fade.color = Color(0, 0, 0, 0.6)
	parry_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().current_scene.add_child(parry_fade)
	parry_label = Label.new()
	parry_label.text = "ПКМ - ПАРИРУЙ"
	parry_label.add_theme_font_size_override("font_size", 48)
	parry_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	parry_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	parry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parry_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	get_tree().current_scene.add_child(parry_label)

func _try_vault() -> bool:
	if is_climbing_animation or is_climbing or is_vaulting:
		return false
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

func _try_climb():
	return false

func _try_ladder_climb():
	if is_on_ladder:
		return
	if not nearby_ladder:
		return
	if has_item or movement_blocked:
		return
	is_on_ladder = true
	is_climbing = true
	velocity = Vector2.ZERO
	if sprite:
		sprite.play("Idle")
		sprite.scale.x = 1
	while is_on_ladder:
		await get_tree().process_frame
		if not is_inside_tree():
			break
		if not is_instance_valid(nearby_ladder):
			break
		if Input.is_action_just_pressed("jump"):
			is_on_ladder = false
			velocity.y = jump_velocity
			break
		if Input.is_action_just_pressed("interact"):
			is_on_ladder = false
			break
		var vertical = Input.get_axis("ui_up", "ui_down")
		var top = nearby_ladder.get_top_y()
		var bottom = nearby_ladder.get_bottom_y()
		global_position.y += vertical * nearby_ladder.climb_speed * (1.0 / 60.0)
		global_position.x = nearby_ladder.global_position.x
		if global_position.y < top:
			global_position.y = top
			is_on_ladder = false
			break
		if global_position.y > bottom:
			global_position.y = bottom
			is_on_ladder = false
			break
		velocity.y = 0
	is_climbing = false
	if sprite:
		sprite.play("Idle")

func on_death_zone_entered():
	die()

func set_hp(value: int) -> void:
	hp = clamp(value, 0, max_hp)

func set_movement_blocked(blocked: bool) -> void:
	movement_blocked = blocked
