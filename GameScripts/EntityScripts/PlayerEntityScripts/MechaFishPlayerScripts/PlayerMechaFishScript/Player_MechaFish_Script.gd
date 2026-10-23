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

@export var block_cost_per_hit: float = 25.0
@export var stamina_regen: float = 35.0
@export var stamina_regen_after_dash: float = 12.0
@export var stamina_regen_delay: float = 0.05
@export var stamina_regen_delay_dash: float = 0.25
@export var stun_duration: float = 1.5

@export var attack_stamina_cost: float = 2.0
@export var dash_stamina_cost: float = 25.0

var block_click_attack: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $MechaFishCamera
@onready var stamina_ui: AnimatedSprite2D = get_node_or_null("GUI/UI_Container/Stamina")

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
const ATTACK_CANCEL_FRAME: int = 7
const ATTACK_RESTART_FRAME: int = 1

var is_hurt: bool = false
var is_dying: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0
var _stamina_regen_timer: float = 0.0
var _stun_tween: Tween = null
var _last_stamina_action: String = "none"
var _last_stamina_ui_frame: int = -1

var was_on_floor_last_frame: bool = true
var is_landing: bool = false
const LANDING_SPEED_MULT: float = 0.2

const BLOCK_COLOR: Color = Color(0.55, 0.75, 1.0, 1.0)
const DEFAULT_COLOR: Color = Color(1, 1, 1, 1)
const STUN_COLOR: Color = Color(1.0, 0.4, 0.4, 1.0)

func _ready():
	add_to_group("player")
	hp = 5
	max_hp = 5
	stamina = 100.0
	if sprite:
		sprite.play("Idle")
		sprite.modulate = DEFAULT_COLOR
	held_icon = Sprite2D.new()
	held_icon.visible = false
	held_icon.scale = Vector2(0.8, 0.8)
	held_icon.z_index = 100
	add_child(held_icon)
	_update_stamina_ui(true)

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

func _can_block_now() -> bool:
	if is_dead or is_hurt or is_dying or is_stunned:
		return false
	if is_attacking or is_sliding or is_dashing:
		return false
	if is_vaulting or is_climbing or is_climbing_animation or is_on_ladder:
		return false
	if movement_blocked:
		return false
	return true

func _set_blocking(value: bool) -> void:
	if value == is_blocking:
		return
	if value and not _can_block_now():
		return
	is_blocking = value
	if sprite:
		if value:
			sprite.modulate = BLOCK_COLOR
		else:
			sprite.modulate = DEFAULT_COLOR
	if value:
		velocity = Vector2.ZERO
		if sprite and sprite.animation != "Idle" and sprite.sprite_frames.has_animation("Idle"):
			sprite.play("Idle")

func _enter_stun() -> void:
	if is_stunned or is_dead:
		return
	is_stunned = true
	stun_timer = stun_duration
	_set_blocking(false)
	is_attacking = false
	attack_buffer = false
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate = STUN_COLOR
		if _stun_tween and _stun_tween.is_valid():
			_stun_tween.kill()
		_stun_tween = create_tween().set_loops()
		_stun_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)
		_stun_tween.tween_property(sprite, "modulate", STUN_COLOR, 0.12)

func _end_stun() -> void:
	is_stunned = false
	stun_timer = 0.0
	if _stun_tween and _stun_tween.is_valid():
		_stun_tween.kill()
	if sprite and not is_blocking:
		sprite.modulate = DEFAULT_COLOR
	if not is_dead and sprite and sprite.sprite_frames.has_animation("Idle"):
		sprite.play("Idle")

func _update_stamina_ui(force: bool = false) -> void:
	if stamina_ui == null:
		return
	if stamina_ui.sprite_frames == null:
		return
	var anim_name = stamina_ui.animation
	if not stamina_ui.sprite_frames.has_animation(anim_name):
		return
	var count = stamina_ui.sprite_frames.get_frame_count(anim_name)
	if count <= 1:
		return
	var ratio = clamp(stamina / max_stamina, 0.0, 1.0)
	var frame = int(round(ratio * float(count - 1)))
	frame = clamp(frame, 0, count - 1)
	if force or frame != _last_stamina_ui_frame:
		_last_stamina_ui_frame = frame
		stamina_ui.frame = frame

func _spend_stamina(amount: float, action: String) -> bool:
	if stamina < amount:
		return false
	stamina = max(0.0, stamina - amount)
	_last_stamina_action = action
	if action == "dash":
		_stamina_regen_timer = stamina_regen_delay_dash
	else:
		_stamina_regen_timer = stamina_regen_delay
	_update_stamina_ui()
	return true

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

	if not is_blocking and not is_stunned and not is_hurt:
		if _stamina_regen_timer > 0:
			_stamina_regen_timer -= delta
		else:
			var regen = stamina_regen_after_dash if _last_stamina_action == "dash" else stamina_regen
			if _last_stamina_action == "dash" and stamina >= max_stamina:
				_last_stamina_action = "none"
			stamina = min(max_stamina, stamina + regen * delta)
			_update_stamina_ui()

	if is_stunned:
		stun_timer -= delta
		velocity = Vector2.ZERO
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		if stun_timer <= 0:
			_end_stun()
		return

	if is_hurt:
		velocity = Vector2.ZERO
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	if is_blocking:
		velocity = Vector2.ZERO
		if not _can_block_now():
			_set_blocking(false)
		if sprite and sprite.animation != "Idle" and sprite.sprite_frames.has_animation("Idle"):
			sprite.play("Idle")
		move_and_slide()
		return

	if is_shift_held:
		shift_held_time += delta
	if dash_cooldown > 0:
		dash_cooldown -= delta
	if is_dashing or movement_blocked:
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

	if is_attacking:
		velocity.x = 0
		move_and_slide()
		if held_icon.visible:
			held_icon.global_position = global_position + Vector2(0, -60)
		return

	var base_speed = run_speed
	if not _can_sprint():
		base_speed = run_speed * jog_speed_mult
	var spd = base_speed
	if is_landing:
		spd = spd * LANDING_SPEED_MULT

	var on_floor_now = is_on_floor()
	if not was_on_floor_last_frame and on_floor_now:
		if not is_sliding and not is_vaulting and not is_climbing and not is_climbing_animation and not is_landing and not is_stunned:
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
			sprite.play("Jump")

	if Input.is_action_just_pressed("interact"):
		if nearby_ladder:
			_try_ladder_climb()
		elif not is_on_floor() and not has_item:
			_try_climb()

	if not is_landing and not is_sliding and not is_vaulting and not is_climbing and not is_climbing_animation and not is_hurt and not is_dead and not is_stunned and not is_blocking:
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
	if is_landing or is_hurt or is_dead or is_blocking or is_stunned:
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
	if event is InputEventKey and event.keycode == KEY_F and not event.echo:
		if is_stunned or is_dead or is_dying:
			return
		if event.pressed:
			_set_blocking(true)
		else:
			_set_blocking(false)
		return

	if is_blocking:
		return

	if is_stunned:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_dead and not is_hurt and not is_sliding and not is_vaulting and not is_climbing and not is_climbing_animation and not is_landing:
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
			if shift_held_time < 0.2 and dash_cooldown <= 0 and not is_dashing and not is_sliding and not movement_blocked and not is_hurt and not is_dead and not is_stunned and not is_attacking:
				if not _is_low_stamina():
					_dash()

func _do_attack() -> void:
	if sprite == null:
		return
	if is_dead or is_hurt or is_blocking or is_stunned:
		return
	if not sprite.sprite_frames.has_animation("AttackLeft") or not sprite.sprite_frames.has_animation("AttackRight"):
		return
	if stamina < attack_stamina_cost:
		return
	if not _spend_stamina(attack_stamina_cost, "attack"):
		return
	var use_left = next_attack_is_left
	next_attack_is_left = not next_attack_is_left
	is_attacking = true
	attack_buffer = false
	_hit_done_this_attack = false
	velocity.x = 0
	var anim = "AttackLeft" if use_left else "AttackRight"
	sprite.play(anim)
	sprite.frame = ATTACK_RESTART_FRAME
	var hit_frame = min(attack_hit_frame, sprite.sprite_frames.get_frame_count(anim) - 1)
	while sprite.is_playing() and sprite.frame < hit_frame:
		await get_tree().process_frame
		if is_hurt or is_dead or is_stunned:
			is_attacking = false
			return
	if not _hit_done_this_attack and not is_hurt and not is_dead and not is_stunned:
		_hit_done_this_attack = true
		_deal_attack_damage()
	if is_hurt or is_dead or is_stunned:
		is_attacking = false
		return
	await sprite.animation_finished
	if is_hurt or is_dead or is_stunned:
		is_attacking = false
		return
	if attack_buffer:
		attack_buffer = false
		is_attacking = false
		if stamina >= attack_stamina_cost:
			_do_attack()
		else:
			sprite.play("Idle")
		return
	is_attacking = false
	if not is_hurt and not is_dead and not is_blocking and not is_stunned:
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
	if is_dead or is_dying:
		return
	if hp <= 0:
		return
	if is_stunned:
		return

	if is_blocking:
		if stamina > 0.0:
			stamina = max(0.0, stamina - block_cost_per_hit)
			_stamina_regen_timer = stamina_regen_delay_dash
			_last_stamina_action = "block"
			_update_stamina_ui()
			if stamina <= 0.0:
				_enter_stun()
			return
		else:
			_enter_stun()
			return

	hp -= amount
	if hp < 0:
		hp = 0
	if hp <= 0:
		_begin_death()
		return
	if sprite == null:
		return
	_set_blocking(false)
	is_hurt = true
	is_attacking = false
	attack_buffer = false
	if sprite.sprite_frames.has_animation("Hit"):
		sprite.play("Hit")
		await sprite.animation_finished
	is_hurt = false
	if not is_dead and not is_dying and not is_stunned:
		if sprite:
			sprite.play("Idle")

func _begin_death() -> void:
	if is_dead or is_dying:
		return
	is_dying = true
	die()

func die():
	if is_dead:
		return
	if not is_dying:
		is_dying = true
	_set_blocking(false)
	is_stunned = false
	stun_timer = 0.0
	if _stun_tween and _stun_tween.is_valid():
		_stun_tween.kill()
	if sprite:
		sprite.modulate = DEFAULT_COLOR
	is_hurt = false
	is_attacking = false
	attack_buffer = false
	is_dead = true
	movement_blocked = true
	velocity = Vector2.ZERO
	if sprite:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("Death"):
			sprite.play("Death")
			if sprite.is_playing():
				await sprite.animation_finished
			if is_instance_valid(sprite):
				sprite.stop()
				if sprite.sprite_frames.has_animation("Death"):
					var last_frame = sprite.sprite_frames.get_frame_count("Death") - 1
					sprite.frame = last_frame
		else:
			await get_tree().create_timer(1.0).timeout
	else:
		await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	_show_death_screen()

func _find_death_screen() -> Node:
	var scene = get_tree().current_scene
	if scene:
		var direct = scene.get_node_or_null("DeathScreen")
		if direct:
			return direct
	var by_group = get_tree().get_first_node_in_group("death_screen")
	if by_group:
		return by_group
	var root = get_tree().root
	if root:
		var found = _find_death_screen_recursive(root)
		if found:
			return found
	return null

func _find_death_screen_recursive(node: Node) -> Node:
	if node.name == "DeathScreen":
		return node
	for child in node.get_children():
		var r = _find_death_screen_recursive(child)
		if r:
			return r
	return null

func _show_death_screen() -> void:
	var screen = _find_death_screen()
	if screen == null:
		return
	if not screen.has_method("show_death"):
		return
	screen.show_death.call_deferred()

func _dash():
	if is_dashing or dash_cooldown > 0:
		return
	if is_hurt or is_dead or is_blocking or is_stunned or is_attacking:
		return
	if not _spend_stamina(dash_stamina_cost, "dash"):
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
	if is_climbing_animation or is_climbing or is_vaulting or is_blocking or is_stunned:
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
	if has_item or movement_blocked or is_blocking or is_stunned:
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
	_begin_death()

func set_hp(value: int) -> void:
	hp = clamp(value, 0, max_hp)

func set_movement_blocked(blocked: bool) -> void:
	movement_blocked = blocked
