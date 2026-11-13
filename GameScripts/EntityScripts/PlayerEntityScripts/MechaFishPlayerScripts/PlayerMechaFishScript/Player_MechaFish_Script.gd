extends CharacterBody2D

@export var speed: float = 240.0
@export var run_speed: float = 245.0
@export var jog_speed_mult: float = 0.5
@export var jump_velocity: float = -300.0
@export var slide_speed: float = 400.0
@export var gravity: float = 980.0
@export var barriers_node: Node2D = null
@export var enemies_node: Node2D = null
@export var item_scene: PackedScene = null
@export var deathzone_scene: PackedScene = null
@export var climb_time: float = 0.45

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

@export var parry_duration: float = 1.0
@export var parry_cooldown_success: float = 0.0
@export var parry_cooldown_fail: float = 2.0
@export var parry_radius: float = 130.0
@export var parry_stamina_restore: float = 100.0
@export var parry_balance_damage: float = 100.0

@export var climb_max_height: float = 400.0
@export var climb_max_side_distance: float = 120.0

@export_group("Climb Settings")
@export var climb_vertical_offset: float = 20.0
@export var climb_horizontal_offset: float = 30.0

var block_click_attack: bool = false
var auto_climb: bool = false

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
var only_basic_moves: bool = false
var minigame_lock: bool = false
var ignore_pause: bool = false
var block_jump: bool = false
var allow_block: bool = true
var allow_parry: bool = true
var is_falling_into_pit: bool = false

var knockback_scale: float = 1.0
var _knock_vx: float = 0.0
var _knock_dir: float = 0.0
const KNOCK_HIT: float = 150.0
const KNOCK_DEATH: float = 230.0
const HURT_SHAKE: float = 0.3
const DEATH_SHAKE: float = 0.45
const DEATH_FISH_SHEET := "res://GameAssets/Sprites/EntitySprites/PlayerSprites/MechaFishPlayerSprites/MechaFishDeathFrames/Player_MechaFish_Death_MechaSuit_SpriteList_Animation.png"
const DEATH_FISH_FRAME: int = 6
var _death_fish: AnimatedSprite2D = null
var _death_fish_v: Vector2 = Vector2.ZERO
var _death_fish_floor: float = 0.0
var _death_fish_bounces: int = 0
var _death_fish_spawned: bool = false
const DEATH_AIR_TIME := 4.5
var _death_air_t: float = -1.0
var _death_air_out: bool = false
var _death_air_bar: AnimatedSprite2D = null
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

var is_parrying: bool = false
var parry_timer: float = 0.0

var was_on_floor_last_frame: bool = true
var is_landing: bool = false

var _current_anim: String = ""
var scripted_anim: bool = false
var _held_last_pos: Vector2 = Vector2.INF

var _slide_triggered: bool = false
var _crouch_was_pressed: bool = false
var _slide_dir: float = 0.0
var _is_getting_up: bool = false

const BLOCK_COLOR: Color = Color(0.55, 0.75, 1.0, 1.0)
const DEFAULT_COLOR: Color = Color(1, 1, 1, 1)
const STUN_COLOR: Color = Color(1.0, 0.4, 0.4, 1.0)
const PARRY_COLOR: Color = Color(1.0, 0.9, 0.3, 1.0)

func _play_anim(anim_name: String, force_restart: bool = false) -> void:
	if sprite == null:
		return
	if not sprite.sprite_frames.has_animation(anim_name):
		return
	if not force_restart and sprite.animation == anim_name and sprite.is_playing():
		return
	if anim_name != "Run" and anim_name != "Jogging":
		sprite.speed_scale = 1.0
	sprite.play(anim_name)
	_current_anim = anim_name

func _await_anim_finished(fallback: float = 1.0) -> void:
	if sprite == null:
		await _safe_timer(fallback)
		return
	if not sprite.is_playing():
		await _safe_timer(0.05)
		return
	var t = 0.0
	while sprite.is_playing() and t < fallback:
		await get_tree().process_frame
		t += get_process_delta_time()
	if not is_inside_tree():
		return

func _safe_timer(duration: float) -> void:
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(_on_safe_timer_timeout)
	await timer.timeout

func _on_safe_timer_timeout() -> void:
	pass

func _ready():
	add_to_group("player")
	hp = 5
	max_hp = 5
	stamina = 100.0
	if sprite:
		sprite.play("Idle")
		_current_anim = "Idle"
		sprite.modulate = DEFAULT_COLOR
	held_icon = Sprite2D.new()
	held_icon.visible = false
	held_icon.scale = Vector2(0.8, 0.8)
	held_icon.z_index = 100
	add_child(held_icon)
	_update_stamina_ui(true)
	_ensure_body_shape()
	floor_snap_length = 14.0
	if sprite:
		for an in ["Fall", "GetUp", "Climb", "Jump", "Landing"]:
			if sprite.sprite_frames.has_animation(an):
				sprite.sprite_frames.set_animation_loop(an, false)
		_build_anim_offsets()
		sprite.frame_changed.connect(_apply_anim_offset)
		sprite.frame_changed.connect(_on_frame_fx)
		sprite.animation_changed.connect(_apply_anim_offset)
		_apply_anim_offset()

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
	if is_dead or is_hurt or is_dying or is_stunned or is_parrying:
		return false
	if is_attacking or is_sliding or is_dashing:
		return false
	if is_vaulting or is_climbing or is_climbing_animation or is_on_ladder:
		return false
	if movement_blocked:
		return false
	if not is_on_floor():
		return false
	return true

func _set_blocking(value: bool) -> void:
	if value == is_blocking:
		return
	if value and not _can_block_now():
		return
	is_blocking = value
	if sprite and not is_parrying:
		if value:
			sprite.modulate = BLOCK_COLOR
		else:
			sprite.modulate = DEFAULT_COLOR
	if value:
		velocity = Vector2.ZERO
		_play_anim("Idle")

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
	if sprite and not is_blocking and not is_parrying:
		sprite.modulate = DEFAULT_COLOR
	_play_anim("Idle")

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

func _start_parry() -> void:
	if is_parrying or is_dead or is_dying or is_hurt or is_stunned:
		return
	if parry_cooldown > 0:
		return
	if is_attacking or is_sliding or is_dashing or is_blocking:
		return
	if not is_on_floor():
		return
	if is_vaulting or is_climbing or is_climbing_animation:
		return
	is_parrying = true
	parry_timer = parry_duration
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate = PARRY_COLOR
		if _stun_tween and _stun_tween.is_valid():
			_stun_tween.kill()
	_apply_parry_pulse()

func _apply_parry_pulse() -> void:
	var hit = false
	var candidates: Array = []
	if enemies_node:
		for e in enemies_node.get_children():
			candidates.append(e)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not candidates.has(e):
			candidates.append(e)
	for e in candidates:
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			continue
		if global_position.distance_to(e.global_position) > parry_radius:
			continue
		hit = true
		_break_balance(e)
	if hit:
		stamina = min(max_stamina, stamina + parry_stamina_restore)
		_update_stamina_ui()
		parry_cooldown = parry_cooldown_success
		if camera and camera.has_method("add_trauma"):
			camera.add_trauma(0.25)

func _break_balance(enemy: Node) -> void:
	if enemy == null:
		return
	if "stamina" in enemy and "_enter_stun" in enemy:
		enemy.stamina = max(0.0, enemy.stamina - parry_balance_damage)
		if enemy.stamina <= 0.0 and enemy.has_method("_enter_stun"):
			enemy._enter_stun()
		return
	if "is_stunned" in enemy:
		enemy.is_stunned = true
		enemy.stun_timer = 1.8
		enemy.velocity.x = 0
		if "sprite" in enemy and enemy.sprite:
			enemy.sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)

func _end_parry() -> void:
	is_parrying = false
	parry_timer = 0.0
	if parry_cooldown <= 0:
		parry_cooldown = parry_cooldown_fail
	if sprite and not is_blocking and not is_stunned:
		sprite.modulate = DEFAULT_COLOR
		_play_anim("Idle")

func _physics_process(delta):
	if is_falling_into_pit:
		return
	if is_on_ladder:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if is_dead:
		velocity.x = _knock_vx
		_knock_vx = move_toward(_knock_vx, 0.0, 700.0 * delta)
		if not is_on_floor():
			velocity.y += gravity * delta
		elif velocity.y > 0.0:
			velocity.y = 0.0
		move_and_slide()
		_update_death_fish(delta)
		return
	if block_jump and not Input.is_action_pressed("jump"):
		block_jump = false
	if get_tree().paused and not ignore_pause:
		return

	if parry_cooldown > 0:
		parry_cooldown -= delta

	if is_parrying:
		parry_timer -= delta
		velocity = Vector2.ZERO
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		if parry_timer <= 0:
			_end_parry()
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
		velocity.x = _knock_vx
		_knock_vx = move_toward(_knock_vx, 0.0, 900.0 * delta)
		if not is_on_floor():
			velocity.y += gravity * delta
		elif velocity.y > 0.0:
			velocity.y = 0.0
		move_and_slide()
		return

	if is_blocking:
		velocity = Vector2.ZERO
		if not _can_block_now():
			_set_blocking(false)
		_play_anim("Idle")
		move_and_slide()
		return

	if is_shift_held:
		shift_held_time += delta
	if dash_cooldown > 0:
		dash_cooldown -= delta
	if is_dashing:
		_process_dash(delta)
		return
	if movement_blocked or minigame_lock:
		velocity.x = move_toward(velocity.x, 0.0, GROUND_DECEL * delta)
		if not is_on_floor() and not is_falling_into_pit:
			velocity.y = min(velocity.y + gravity * FALL_GRAVITY_MULT * delta, MAX_FALL_SPEED)
		else:
			velocity.y = 0.0
		if is_on_floor():
			velocity.x = 0.0
		move_and_slide()
		var moved = global_position.distance_to(_held_last_pos) > 0.3
		_held_last_pos = global_position
		if not scripted_anim and not moved and sprite and (sprite.animation == "Run" or sprite.animation == "Jogging"):
			_play_anim("Idle" if is_on_floor() else "Falling")
		if _slide_phase != "":
			_finish_slide_now()
		return
	if is_vaulting or is_climbing or is_climbing_animation:
		velocity = Vector2.ZERO
		return
	if _slide_phase != "" and not is_sliding and not _is_getting_up:
		_finish_slide_now()

	var on_floor_now = is_on_floor()
	if on_floor_now:
		_coyote_t = COYOTE_TIME
		_jump_cut_done = false
	else:
		_coyote_t = max(0.0, _coyote_t - delta)
	if Input.is_action_just_pressed("jump") and not block_jump:
		_jump_buffer_t = JUMP_BUFFER
	else:
		_jump_buffer_t = max(0.0, _jump_buffer_t - delta)
	_update_step_visual(delta)
	_skid_t = max(0.0, _skid_t - delta)

	var direction = _h_axis()
	if abs(direction) < 0.2:
		direction = 0.0
	var dir_sign = signf(direction)
	if dir_sign != 0.0 and _slide_phase == "":
		facing_direction = int(dir_sign)
	if not is_attacking and _slide_phase == "" and dir_sign != 0.0:
		sprite.scale.x = dir_sign

	if is_attacking:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if not on_floor_now:
			velocity.y = min(velocity.y + gravity * FALL_GRAVITY_MULT * delta, MAX_FALL_SPEED)
		move_and_slide()
		if held_icon.visible:
			held_icon.global_position = global_position + Vector2(0, -60)
		return

	var max_speed = run_speed if _can_sprint() else run_speed * jog_speed_mult

	if not was_on_floor_last_frame and on_floor_now:
		_on_landed(_last_air_vy, direction)
	was_on_floor_last_frame = on_floor_now
	if not on_floor_now:
		_last_air_vy = velocity.y

	var crouch_pressed = Input.is_action_pressed("crouch") and not _is_low_stamina()
	var crouch_just = Input.is_action_just_pressed("crouch") and not _is_low_stamina()
	if _slide_phase == "" and crouch_just and on_floor_now and (abs(velocity.x) > 40.0 or direction != 0.0):
		_start_slide(direction)

	if _slide_phase != "":
		_process_slide(delta, crouch_pressed, direction, max_speed)
	else:
		var target = direction * max_speed
		var accel: float
		if on_floor_now:
			if direction == 0.0:
				accel = GROUND_DECEL
			elif signf(velocity.x) != dir_sign and abs(velocity.x) > 10.0:
				accel = GROUND_ACCEL
				if abs(velocity.x) > 160.0 and _skid_t <= 0.0:
					_skid_t = 0.25
					_dust(global_position + Vector2(signf(velocity.x) * 8.0, FEET_Y), 3, 0.0, 0.7)
					_squash(Vector2(1.06, 0.95))
				velocity.x = dir_sign * min(abs(velocity.x) * 0.3, 70.0)
			else:
				accel = GROUND_ACCEL
		else:
			accel = AIR_ACCEL if direction != 0.0 else AIR_DECEL
		velocity.x = move_toward(velocity.x, target, accel * delta)

	if not on_floor_now:
		var g = gravity
		if velocity.y > 0.0:
			g *= FALL_GRAVITY_MULT
		elif Input.is_action_pressed("jump") and abs(velocity.y) < APEX_RANGE:
			g *= APEX_GRAVITY_MULT
		velocity.y = min(velocity.y + g * delta, MAX_FALL_SPEED)
		if velocity.y < 0.0 and not Input.is_action_pressed("jump") and not _jump_cut_done:
			velocity.y *= JUMP_CUT
			_jump_cut_done = true

	if _jump_buffer_t > 0.0 and _coyote_t > 0.0 and (_slide_phase == "" or (_slide_phase == "slide" and _can_stand())):
		if _slide_phase != "":
			_finish_slide_now()
		velocity.y = jump_velocity
		_jump_buffer_t = 0.0
		_coyote_t = 0.0
		_jump_cut_done = false
		is_landing = false
		on_floor_now = false
		_play_jump()
		_squash(Vector2(0.88, 1.14))
		_dust(global_position + Vector2(0, FEET_Y), 3, 0.0, 0.6)

	if Input.is_action_just_pressed("interact") and not only_basic_moves:
		if not _try_climb_obstacle():
			if nearby_ladder:
				_try_ladder_climb()

	var can_auto = not only_basic_moves and _slide_phase == "" and (barriers_node != null or auto_climb)
	if not on_floor_now and can_auto and _try_ledge_grab(direction):
		return
	if on_floor_now and can_auto and _try_ground_ledge(direction, delta):
		return

	var grounded_look = on_floor_now or (_coyote_t > 0.0 and velocity.y >= 0.0 and velocity.y < 140.0)
	var pushing_wall = on_floor_now and dir_sign != 0.0 and is_on_wall() and get_wall_normal().x * dir_sign < -0.5
	if _slide_phase == "" and not is_hurt and not is_dead and not is_stunned and not is_blocking and not is_parrying:
		if not grounded_look:
			if velocity.y < -20.0:
				if sprite.animation != "Jump":
					_play_jump()
			elif velocity.y > 60.0 or sprite.animation != "Jump":
				if sprite.animation != "Falling":
					_play_anim("Falling", true)
			sprite.speed_scale = 2.4 if (sprite.animation == "Jump" and sprite.frame < 2) else 1.0
		elif is_landing and direction != 0.0:
			is_landing = false
		if grounded_look and not is_landing:
			if not pushing_wall and abs(velocity.x) > 25.0 and (direction != 0.0 or abs(velocity.x) > max_speed * 0.6):
				if not _can_sprint() and sprite.sprite_frames.has_animation("Jogging"):
					_play_anim("Jogging")
				else:
					_play_anim("Run")
				sprite.speed_scale = clamp(abs(velocity.x) / max(1.0, max_speed), 0.6, 1.0) * 0.95
			else:
				_play_anim("Idle")
				sprite.speed_scale = 1.0

	move_and_slide()

	if held_icon.visible:
		held_icon.global_position = global_position + Vector2(0, -60)

var _h_last := 0.0
var _h_frame := -1

func _h_axis() -> float:
	var f = Engine.get_physics_frames()
	if f != _h_frame:
		_h_frame = f
		if Input.is_action_just_pressed("ui_left"):
			_h_last = -1.0
		elif Input.is_action_just_pressed("ui_right"):
			_h_last = 1.0
	var l = Input.get_action_strength("ui_left")
	var r = Input.get_action_strength("ui_right")
	if l > 0.2 and r > 0.2:
		if _h_last == 0.0:
			_h_last = float(facing_direction) if facing_direction != 0 else 1.0
		return _h_last * max(l, r)
	if l > r:
		_h_last = -1.0
	elif r > l:
		_h_last = 1.0
	return r - l

func _play_jump() -> void:
	_play_anim("Jump", true)
	if sprite and sprite.sprite_frames.get_frame_count("Jump") > 2:
		sprite.frame = 1

const GROUND_ACCEL := 1250.0
const GROUND_DECEL := 2100.0
const AIR_ACCEL := 1000.0
const AIR_DECEL := 500.0
const FALL_GRAVITY_MULT := 1.45
const APEX_GRAVITY_MULT := 0.6
const APEX_RANGE := 45.0
const MAX_FALL_SPEED := 760.0
const JUMP_CUT := 0.5
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.13
const DASH_SPEED := 640.0
const DASH_TIME := 0.16
const ROLL_SPEED := 440.0
const ROLL_FRICTION := 520.0
const ROLL_DOWN_T := 0.16
const ROLL_MIN_T := 0.2
const ROLL_MAX_T := 0.55
const ROLL_UP_T := 0.18
const LEDGE_MIN := 14.0
const LEDGE_MAX := 104.0
const STEP_MAX := 34.0
const FEET_Y := 28.0

var _coyote_t: float = 0.0
var _jump_buffer_t: float = 0.0
var _jump_cut_done: bool = false
var _last_air_vy: float = 0.0
var _dash_t: float = 0.0
var _dash_dir: float = 1.0
var _slide_phase: String = ""
var _slide_t: float = 0.0
var _body_shape: CollisionShape2D = null
var _body_shape_pos: Vector2 = Vector2.ZERO
var _body_shape_h: float = 0.0
var _push_t: float = 0.0
var _step_vis: float = 0.0
var _sprite_base: Vector2 = Vector2.INF
var _ghost_t: float = 0.0

func _on_frame_fx() -> void:
	if sprite == null or not is_on_floor():
		return
	var an = String(sprite.animation)
	if (an == "Run" or an == "Jogging") and (sprite.frame == 1 or sprite.frame == 5) and abs(velocity.x) > 120.0:
		_dust(global_position + Vector2(-signf(velocity.x) * 6.0, FEET_Y), 3, -signf(velocity.x), 0.7)

func _dust(at: Vector2, n: int, dirx: float, power: float = 1.0) -> void:
	if get_parent() == null:
		return
	var fx = Node2D.new()
	fx.z_as_relative = false
	fx.z_index = z_index + 1
	get_parent().add_child(fx)
	fx.global_position = at
	var parts: Array = []
	for i in range(n):
		var vx = (dirx * randf_range(20.0, 60.0) if dirx != 0.0 else randf_range(-70.0, 70.0)) * power
		parts.append([Vector2(randf_range(-4, 4), 0), Vector2(vx, randf_range(-28.0, -8.0) * power), randf_range(2.0, 3.5)])
	var st = {"k": 0.0}
	fx.draw.connect(func():
		var k: float = st["k"]
		for p in parts:
			var pos: Vector2 = p[0] + p[1] * k * 0.45 + Vector2(0, 20.0 * k * k * 0.45)
			var sz: float = p[2] * (1.0 + k * 0.6)
			fx.draw_rect(Rect2(pos.round() - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(0.72, 0.7, 0.66, 0.55 * (1.0 - k))))
	var tw = fx.create_tween()
	tw.tween_method(func(v): st["k"] = v; fx.queue_redraw(), 0.0, 1.0, 0.45)
	tw.tween_callback(fx.queue_free)

func _spawn_ghost() -> void:
	if sprite == null or get_parent() == null:
		return
	var tex = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return
	var g = Sprite2D.new()
	g.texture = tex
	g.texture_filter = sprite.texture_filter
	g.offset = sprite.offset
	g.z_index = max(0, sprite.z_index + z_index - 1)
	g.z_as_relative = false
	g.modulate = Color(0.55, 0.8, 1.0, 0.45)
	get_parent().add_child(g)
	g.global_transform = sprite.global_transform
	var tw = g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.2)
	tw.tween_callback(g.queue_free)

func _on_landed(vy: float, direction: float) -> void:
	if _slide_phase != "" or is_vaulting or is_climbing or is_climbing_animation or is_stunned:
		return
	if vy > 120.0:
		var k = clamp(vy / 2600.0, 0.04, 0.2)
		_squash(Vector2(1.0 + k, 1.0 - k))
	if vy > 200.0:
		_dust(global_position + Vector2(0, FEET_Y), 6 if vy > 450.0 else 4, 0.0, clamp(vy / 500.0, 0.6, 1.3))
	if vy > 620.0:
		_shake_camera(0.12)
	if vy < 280.0:
		return
	if direction != 0.0 and abs(velocity.x) > 40.0:
		return
	_play_landing()

func _process_dash(delta: float) -> void:
	_dash_t -= delta
	velocity = Vector2(_dash_dir * DASH_SPEED, 0.0)
	_ghost_t -= delta
	if _ghost_t <= 0.0:
		_ghost_t = 0.035
		_spawn_ghost()
	move_and_slide()
	if _dash_t <= 0.0 or is_on_wall() or is_hurt or is_dead or is_stunned:
		is_dashing = false
		var hold = _h_axis()
		velocity.x = _dash_dir * run_speed * (0.85 if signf(hold) == _dash_dir else 0.35)
		if is_on_wall():
			velocity.x = 0.0

func _start_slide(direction: float) -> void:
	_slide_dir = signf(direction) if direction != 0.0 else signf(velocity.x)
	if _slide_dir == 0.0:
		_slide_dir = float(facing_direction)
	is_sliding = true
	_slide_triggered = true
	_slide_phase = "down"
	_slide_t = 0.0
	is_landing = false
	facing_direction = int(_slide_dir)
	sprite.scale.x = _slide_dir
	velocity.x = _slide_dir * max(abs(velocity.x), ROLL_SPEED)
	_set_low_body(true)
	_dust(global_position + Vector2(0, FEET_Y), 5, -_slide_dir, 1.1)
	_play_anim("Fall", true)
	sprite.speed_scale = _anim_speed_for("Fall", ROLL_DOWN_T)

func _anim_speed_for(anim: String, dur: float) -> float:
	if sprite == null or not sprite.sprite_frames.has_animation(anim):
		return 1.0
	var n = sprite.sprite_frames.get_frame_count(anim)
	var fps = sprite.sprite_frames.get_animation_speed(anim)
	if fps <= 0.0 or dur <= 0.0:
		return 1.0
	return (n / fps) / dur

func _process_slide(delta: float, crouch_pressed: bool, direction: float = 0.0, max_speed: float = 300.0) -> void:
	_slide_t += delta
	match _slide_phase:
		"down":
			velocity.x = move_toward(velocity.x, 0.0, ROLL_FRICTION * 0.4 * delta)
			if _slide_t >= ROLL_DOWN_T:
				_slide_phase = "slide"
				_slide_t = 0.0
				_play_anim("Slide", true)
				sprite.speed_scale = 1.0
		"slide":
			velocity.x = move_toward(velocity.x, _slide_dir * 150.0, ROLL_FRICTION * delta)
			var want_up = _slide_t >= ROLL_MIN_T and (not crouch_pressed or _slide_t >= ROLL_MAX_T)
			if want_up and _can_stand():
				_slide_phase = "up"
				_slide_t = 0.0
				_is_getting_up = true
				_play_anim("GetUp", true)
				sprite.speed_scale = _anim_speed_for("GetUp", ROLL_UP_T)
			elif want_up:
				velocity.x = _slide_dir * max(abs(velocity.x), 150.0)
		"up":
			var keep = signf(direction) == _slide_dir
			var tgt = _slide_dir * max_speed * 0.85 if keep else 0.0
			velocity.x = move_toward(velocity.x, tgt, (900.0 if keep else 1600.0) * delta)
			if _slide_t >= ROLL_UP_T:
				_finish_slide_now()
				if keep and sprite:
					_play_anim("Run")

func _finish_slide_now() -> void:
	_slide_phase = ""
	_slide_t = 0.0
	is_sliding = false
	_is_getting_up = false
	_slide_dir = 0.0
	_set_low_body(false)
	if sprite:
		sprite.speed_scale = 1.0
		if sprite.animation in ["Fall", "Slide", "GetUp"]:
			_play_anim("Idle", true)

func _update_step_visual(delta: float) -> void:
	if sprite == null:
		return
	if _sprite_base == Vector2.INF:
		_sprite_base = sprite.position
	if _step_vis != 0.0:
		_step_vis = move_toward(_step_vis, 0.0, max(240.0, abs(_step_vis) * 10.0) * delta)
	_sq = _sq.lerp(Vector2.ONE, 1.0 - exp(-13.0 * delta))
	if _sq.distance_squared_to(Vector2.ONE) < 0.00002:
		_sq = Vector2.ONE
	var sx = signf(sprite.scale.x) if sprite.scale.x != 0.0 else 1.0
	sprite.scale = Vector2(sx * _sq.x, _sq.y)
	sprite.position = _sprite_base + Vector2(0, _step_vis + 35.0 * (1.0 - _sq.y))

var _sq := Vector2.ONE
var _skid_t := 0.0

func _squash(v: Vector2) -> void:
	_sq = v

func _wall_probe(dir: float, grounded: bool = false) -> Dictionary:
	var space = get_world_2d().direct_space_state
	var feet = global_position.y + FEET_Y
	var hit_x := INF
	for hy in [-30.0, -6.0, 14.0, 24.0]:
		var q = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, hy), global_position + Vector2(dir * 34.0, hy), collision_mask, [get_rid()])
		var r = space.intersect_ray(q)
		if not r.is_empty() and abs(r.normal.x) > 0.7:
			hit_x = min(hit_x, abs(r.position.x - global_position.x))
	if hit_x == INF:
		return {}
	if grounded:
		var ql = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, FEET_Y - 4.0), global_position + Vector2(dir * (hit_x + 4.0), FEET_Y - 4.0), collision_mask, [get_rid()])
		if space.intersect_ray(ql).is_empty():
			return {}
	var wall_x = global_position.x + dir * hit_x
	var probe_x = wall_x + dir * 6.0
	var q2 = PhysicsRayQueryParameters2D.create(Vector2(probe_x, feet - LEDGE_MAX - 4.0), Vector2(probe_x, feet + 4.0), collision_mask, [get_rid()])
	var r2 = space.intersect_ray(q2)
	if r2.is_empty() or r2.normal.y > -0.7:
		return {}
	var top_y: float = r2.position.y
	var end_pos = Vector2(wall_x + dir * 20.0, top_y - FEET_Y - 1.0)
	var xf = Transform2D(0.0, end_pos)
	if test_move(xf, Vector2(0, -2.0)) or test_move(xf, Vector2(dir * 1.0, 0.0)):
		return {}
	return {"wall_x": wall_x, "top_y": top_y, "rise": feet - top_y}

func _try_ground_ledge(direction: float, delta: float) -> bool:
	if direction == 0.0 or has_item or is_landing or is_blocking or is_stunned or is_parrying or is_hurt or is_dead:
		_push_t = 0.0
		return false
	var dir = signf(direction)
	var space = get_world_2d().direct_space_state
	var q = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, FEET_Y - 4.0), global_position + Vector2(dir * 30.0, FEET_Y - 4.0), collision_mask, [get_rid()])
	var r = space.intersect_ray(q)
	if r.is_empty() or abs(r.normal.x) < 0.7:
		_push_t = 0.0
		return false
	var info = _wall_probe(dir, true)
	if info.is_empty():
		_push_t = 0.0
		return false
	var rise: float = info["rise"]
	if rise < 2.0:
		return false
	if rise <= STEP_MAX:
		var old_y = global_position.y
		global_position = Vector2(float(info["wall_x"]) + dir * 2.0, float(info["top_y"]) - FEET_Y - 0.5)
		_step_vis += old_y - global_position.y
		velocity.y = 0.0
		velocity.x = dir * max(abs(velocity.x), run_speed * 0.6)
		was_on_floor_last_frame = true
		_push_t = 0.0
		return false
	if rise > LEDGE_MAX:
		_push_t = 0.0
		return false
	_push_t += delta
	if _push_t < 0.1:
		return false
	_push_t = 0.0
	_ledge_climb(float(info["wall_x"]), float(info["top_y"]), dir)
	return true

func _ensure_body_shape() -> void:
	if _body_shape != null:
		return
	_body_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _body_shape and _body_shape.shape is CapsuleShape2D:
		_body_shape.shape = _body_shape.shape.duplicate()
		_body_shape_pos = _body_shape.position
		_body_shape_h = (_body_shape.shape as CapsuleShape2D).height

func _set_low_body(low: bool) -> void:
	_ensure_body_shape()
	if _body_shape == null or not (_body_shape.shape is CapsuleShape2D):
		return
	var cap: CapsuleShape2D = _body_shape.shape
	if low:
		cap.height = max(cap.radius * 2.0, _body_shape_h - 22.0)
		_body_shape.position = _body_shape_pos + Vector2(0, 11.0)
	else:
		cap.height = _body_shape_h
		_body_shape.position = _body_shape_pos

func _can_stand() -> bool:
	_ensure_body_shape()
	if _body_shape == null:
		return true
	return not test_move(global_transform, Vector2(0, -22.0))

func _try_ledge_grab(direction: float) -> bool:
	if direction == 0.0 or velocity.y < -80.0 or has_item:
		return false
	if is_climbing_animation or is_blocking or is_stunned or is_parrying or is_hurt or is_dead:
		return false
	var dir = signf(direction)
	var info = _wall_probe(dir)
	if info.is_empty():
		return false
	var rise: float = info["rise"]
	if rise < LEDGE_MIN or rise > LEDGE_MAX:
		return false
	_ledge_climb(float(info["wall_x"]), float(info["top_y"]), dir)
	return true

const CLIMB_KEYS := [
	[Vector2(-26.0, 26.0), 0],
	[Vector2(-24.0, 19.0), 1],
	[Vector2(-3.0, -7.0), 2],
	[Vector2(8.0, -31.0), 3],
]
var _climb_manual: bool = false

func _ledge_climb(wall_x: float, top_y: float, dir: float) -> void:
	is_climbing_animation = true
	velocity = Vector2.ZERO
	_push_t = 0.0
	facing_direction = int(dir)
	if _sprite_base == Vector2.INF and sprite:
		_sprite_base = sprite.position
	_step_vis = 0.0
	var base = _sprite_base if _sprite_base != Vector2.INF else Vector2.ZERO
	if sprite:
		sprite.position = base
		sprite.scale.x = dir
		sprite.speed_scale = 1.0
		_play_anim("Climb", true)
		sprite.pause()
		_climb_manual = true
		sprite.offset = Vector2.ZERO
	var corner = Vector2(wall_x, top_y)
	var feet = global_position.y + FEET_Y
	var rise = feet - top_y
	var first := 0
	if rise < 58.0:
		first = 2
	elif rise < 76.0:
		first = 1
	var keys: Array = []
	for i in range(first, CLIMB_KEYS.size()):
		var k = CLIMB_KEYS[i]
		var c = corner + Vector2(k[0].x * dir, k[0].y)
		keys.append([c - base, k[1]])
	var end_pos = Vector2(wall_x + dir * 18.0, top_y - FEET_Y - 0.5)
	keys.append([end_pos, 4])
	var start = global_position
	var durs: Array = []
	var prev = start
	for i in range(keys.size()):
		var dist = prev.distance_to(keys[i][0])
		var dt = clamp(dist / 360.0, 0.06, 0.16)
		if i == 0 and first == 0:
			dt = clamp(dist / 520.0, 0.05, 0.12)
		if keys[i][1] == 2:
			dt += 0.04
		durs.append(dt)
		prev = keys[i][0]
	var tw = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	prev = start
	for i in range(keys.size()):
		var from: Vector2 = prev
		var to: Vector2 = keys[i][0]
		var fr: int = keys[i][1]
		tw.tween_callback(func():
			if sprite and sprite.animation == "Climb":
				sprite.frame = fr
				sprite.offset = Vector2.ZERO)
		tw.tween_method(func(u: float): global_position = from.lerp(to, u), 0.0, 1.0, durs[i]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if i < keys.size() - 1 else Tween.EASE_IN_OUT)
		if fr == 0:
			tw.tween_interval(0.05)
		prev = to
	await tw.finished
	_climb_manual = false
	if not is_inside_tree():
		return
	global_position = end_pos
	is_climbing_animation = false
	velocity = Vector2.ZERO
	was_on_floor_last_frame = true
	is_landing = false
	_coyote_t = COYOTE_TIME
	var hold = signf(_h_axis())
	velocity = Vector2(dir * run_speed * 0.7 if hold == dir else 0.0, 30.0)
	move_and_slide()
	velocity.y = 0.0
	was_on_floor_last_frame = true
	if hold == dir:
		_play_anim("Run")
	else:
		_play_anim("Idle")
	_apply_anim_offset()

const ANIM_ALIGN := {"Idle": "frame", "Run": "anim", "Jogging": "anim", "Landing": "frame", "Hit": "frame",
	"AttackLeft": "frame", "AttackRight": "frame", "Jump": "anim", "Falling": "anim", "Climb": "last",
	"Fall": "fall", "Slide": "fall", "GetUp": "fall"}
static var _anim_offsets: Dictionary = {}

func _frame_metrics(tex: Texture2D) -> Dictionary:
	var img: Image
	if tex is AtlasTexture:
		var at: AtlasTexture = tex
		img = at.atlas.get_image().get_region(Rect2i(at.region))
	else:
		img = tex.get_image()
	if img == null:
		return {}
	if img.is_compressed():
		img.decompress()
	var w = img.get_width()
	var h = img.get_height()
	var miny = -1
	var maxy = -1
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.3:
				if miny < 0:
					miny = y
				maxy = y
				break
	if miny < 0:
		return {}
	var sx := 0.0
	var n := 0
	for y in range(miny, min(h, miny + 12)):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.3:
				sx += x + 0.5
				n += 1
	return {"w": w, "h": h, "maxy": maxy, "head": sx / max(1, n)}

func _build_anim_offsets() -> void:
	if not _anim_offsets.is_empty() or sprite == null or sprite.sprite_frames == null:
		return
	var sf = sprite.sprite_frames
	var cache: Dictionary = {}
	for an in sf.get_animation_names():
		var arr: Array = []
		for i in range(sf.get_frame_count(an)):
			arr.append(_frame_metrics(sf.get_frame_texture(an, i)))
		cache[an] = arr
	for an in ANIM_ALIGN.keys():
		if not cache.has(an):
			continue
		var mode: String = ANIM_ALIGN[an]
		var ms: Array = cache[an]
		var out: Array = []
		var deepest := -1
		var head_sum := 0.0
		var head_n := 0
		for m in ms:
			if not m.is_empty():
				deepest = max(deepest, int(m["maxy"]))
				head_sum += float(m["head"]) - float(m["w"]) * 0.5
				head_n += 1
		var head_avg = head_sum / max(1, head_n)
		for i in range(ms.size()):
			var m: Dictionary = ms[i]
			if m.is_empty():
				out.append(Vector2.ZERO)
				continue
			var ref: Dictionary = m
			if mode == "last":
				ref = ms[ms.size() - 1]
			elif mode == "fall" and cache.has("Fall") and not cache["Fall"].is_empty():
				ref = cache["Fall"][0]
			var w = float(m["w"])
			var h = float(m["h"])
			var bottom = int(ref["maxy"])
			if mode == "anim":
				bottom = deepest
			var ox = w * 0.5 - round(float(ref["head"]))
			if mode == "anim":
				ox = -round(head_avg)
			var oy = h * 0.5 + 35.0 - bottom
			out.append(Vector2(ox, oy))
		_anim_offsets[an] = out

func _apply_anim_offset() -> void:
	if sprite == null:
		return
	if _climb_manual:
		sprite.offset = Vector2.ZERO
		return
	var arr = _anim_offsets.get(String(sprite.animation), null)
	if arr is Array and sprite.frame < arr.size():
		sprite.offset = arr[sprite.frame]
	else:
		sprite.offset = Vector2.ZERO

func _try_climb_obstacle() -> bool:
	if is_climbing_animation or is_climbing or is_vaulting or is_blocking or is_stunned or is_parrying:
		return false
	if barriers_node == null:
		return false

	var player_pos = global_position
	var best = null
	var best_dist = INF
	var best_data = {}

	for o in barriers_node.get_children():
		if not is_instance_valid(o) or o.is_queued_for_deletion():
			continue
		var shapes: Array = []
		_collect_rect_shapes(o, shapes)
		for entry in shapes:
			var col: CollisionShape2D = entry.shape_node
			var rect: RectangleShape2D = entry.rect
			var center: Vector2 = col.global_position
			var half_w = rect.size.x * 0.5
			var half_h = rect.size.y * 0.5
			var left_edge = center.x - half_w
			var right_edge = center.x + half_w
			var top_edge = center.y - half_h

			var height_above = top_edge - player_pos.y
			if height_above < -climb_max_height:
				continue
			if height_above > climb_max_height:
				continue
			var closest_x = clamp(player_pos.x, left_edge, right_edge)
			var dx = abs(player_pos.x - closest_x)
			if dx > climb_max_side_distance:
				continue
			if rect.size.y > climb_max_height * 2.0:
				continue

			var dist = Vector2(player_pos.x - closest_x, height_above).length()
			if dist < best_dist:
				best_dist = dist
				best = o
				best_data = {
					"center": center,
					"left": left_edge,
					"right": right_edge,
					"top": top_edge,
					"height": height_above,
				}

	if best == null:
		return false
	var rise = (player_pos.y + FEET_Y) - float(best_data.top)
	if rise < LEDGE_MIN or rise > LEDGE_MAX + 16.0:
		return false
	var go_right = player_pos.x < float(best_data.center.x)
	var edge = float(best_data.left) if go_right else float(best_data.right)
	if abs(player_pos.x - edge) > 58.0:
		return false
	last_climbed_obstacle = best
	_ledge_climb(edge, float(best_data.top), 1.0 if go_right else -1.0)
	return true

func _collect_rect_shapes(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is CollisionShape2D:
			var s = child.shape
			if s is RectangleShape2D:
				out.append({"shape_node": child, "rect": s})
		else:
			_collect_rect_shapes(child, out)

func _play_landing() -> void:
	if sprite == null:
		return
	if not sprite.sprite_frames.has_animation("Landing"):
		return
	if is_landing or is_hurt or is_dead or is_blocking or is_stunned or is_parrying:
		return
	is_landing = true
	_play_anim("Landing", true)
	await _await_anim_finished(1.0)
	is_landing = false

func _end_slide():
	is_sliding = false
	slide_timer = 0.0

func _input(event: InputEvent) -> void:
	if only_basic_moves:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if allow_parry and is_on_floor():
			_start_parry()
		return

	if event is InputEventKey and event.is_action("block") and not event.echo and allow_block:
		if is_stunned or is_dead or is_dying or is_parrying:
			return
		if not is_on_floor():
			return
		if event.pressed:
			_set_blocking(true)
		else:
			_set_blocking(false)
		return

	if is_blocking or is_parrying:
		return

	if is_stunned:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_dead and not is_hurt and not is_sliding and not _is_getting_up and not is_vaulting and not is_climbing and not is_climbing_animation and not is_landing:
			if is_attacking:
				attack_buffer = true
			else:
				_do_attack()
	if event is InputEventKey and event.is_action("dash"):
		if event.pressed:
			is_shift_held = true
			shift_held_time = 0.0
		else:
			is_shift_held = false
			if shift_held_time < 0.2 and dash_cooldown <= 0 and not is_dashing and not is_sliding and not _is_getting_up and not movement_blocked and not is_hurt and not is_dead and not is_stunned and not is_attacking and not is_parrying:
				if not _is_low_stamina():
					_dash()

const SFX_DIR := "res://GameAssets/Audio/SoundEffects/PlayerSounds/FishPlayerSounds/FishAttackSounds/"
var _combo: int = 0
var _combo_t: float = -10.0
var _sfx_players: Dictionary = {}

func _sfx(file: String, vol: float = -4.0, pitch_var: float = 0.08) -> void:
	var pl: AudioStreamPlayer2D = _sfx_players.get(file, null)
	if pl == null:
		var st = load(SFX_DIR + file)
		if st == null:
			return
		pl = AudioStreamPlayer2D.new()
		pl.stream = st
		pl.max_polyphony = 3
		if AudioServer.get_bus_index("SFX") >= 0:
			pl.bus = "SFX"
		add_child(pl)
		_sfx_players[file] = pl
	pl.volume_db = vol
	pl.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	pl.play()

func _do_attack() -> void:
	if sprite == null:
		return
	if is_dead or is_hurt or is_blocking or is_stunned or is_parrying:
		return
	if not sprite.sprite_frames.has_animation("AttackLeft") or not sprite.sprite_frames.has_animation("AttackRight"):
		return
	if stamina < attack_stamina_cost:
		return
	if not _spend_stamina(attack_stamina_cost, "attack"):
		return
	var now = Time.get_ticks_msec() / 1000.0
	_combo = _combo + 1 if now - _combo_t < 0.55 else 0
	if _combo > 2:
		_combo = 0
	_combo_t = now
	var heavy = _combo == 2
	var hold = _h_axis()
	if abs(hold) > 0.2:
		facing_direction = 1 if hold > 0.0 else -1
	var tgt = _attack_target(abs(hold) <= 0.2)
	if tgt and abs(hold) <= 0.2:
		facing_direction = 1 if tgt.global_position.x >= global_position.x else -1
	var dir = float(facing_direction)
	sprite.scale.x = dir
	if _slide_phase != "":
		_finish_slide_now()
	var use_left = next_attack_is_left
	next_attack_is_left = not next_attack_is_left
	is_attacking = true
	attack_buffer = false
	_hit_done_this_attack = false
	var lunge = 170.0 if heavy else 110.0
	if tgt:
		var gap = abs(tgt.global_position.x - global_position.x) - 58.0
		lunge = clamp(gap * 5.0, lunge, 360.0)
	velocity.x = dir * max(abs(velocity.x) * 0.5, lunge)
	var anim = "AttackLeft" if use_left else "AttackRight"
	_play_anim(anim, true)
	sprite.frame = ATTACK_RESTART_FRAME
	sprite.speed_scale = 1.15 if not heavy else 1.0
	_sfx("Player_Fish_Swing_SoundEffect.wav", -8.0 if not heavy else -5.0, 0.12)
	var hit_frame = min(attack_hit_frame, sprite.sprite_frames.get_frame_count(anim) - 1)
	while sprite.is_playing() and sprite.animation == anim and sprite.frame < hit_frame:
		await get_tree().process_frame
		if is_hurt or is_dead or is_stunned or is_parrying:
			is_attacking = false
			return
	if not _hit_done_this_attack and not is_hurt and not is_dead and not is_stunned:
		_hit_done_this_attack = true
		_deal_attack_damage(heavy)
	if is_hurt or is_dead or is_stunned or is_parrying:
		is_attacking = false
		return
	var t := 0.0
	while sprite.is_playing() and sprite.animation == anim and t < 1.0:
		if attack_buffer and sprite.frame >= hit_frame + 2:
			break
		await get_tree().process_frame
		t += get_process_delta_time()
		if is_hurt or is_dead or is_stunned or is_parrying:
			is_attacking = false
			return
	if not is_inside_tree():
		return
	sprite.speed_scale = 1.0
	_combo_t = Time.get_ticks_msec() / 1000.0
	if attack_buffer:
		attack_buffer = false
		is_attacking = false
		if stamina >= attack_stamina_cost:
			_do_attack()
		else:
			_play_anim("Idle")
		return
	is_attacking = false
	if not is_hurt and not is_dead and not is_blocking and not is_stunned and not is_parrying:
		_play_anim("Idle")

func _enemy_list() -> Array:
	var out: Array = []
	if enemies_node:
		for e in enemies_node.get_children():
			out.append(e)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not out.has(e):
			out.append(e)
	return out.filter(func(e): return is_instance_valid(e) and e is Node2D and not e.is_queued_for_deletion() and e.has_method("take_damage") and not ("is_dead" in e and e.is_dead))

func _attack_target(any_side: bool) -> Node2D:
	var best: Node2D = null
	var bd := 160.0
	for e in _enemy_list():
		var dx = e.global_position.x - global_position.x
		if abs(e.global_position.y - global_position.y) > 80.0:
			continue
		if not any_side and dx * facing_direction < -10.0:
			continue
		if any_side and dx * facing_direction < -10.0 and abs(dx) > 90.0:
			continue
		if abs(dx) < bd:
			bd = abs(dx)
			best = e
	return best

func _deal_attack_damage(heavy: bool = false) -> void:
	var dir = 1.0 if facing_direction > 0 else -1.0
	var origin = global_position + Vector2(dir * attack_range * 0.5, 0)
	var candidates: Array = []
	if enemies_node:
		for e in enemies_node.get_children():
			candidates.append(e)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not candidates.has(e):
			candidates.append(e)
	var hits: Array = []
	var reach = attack_range * (1.3 if heavy else 1.15)
	for e in candidates:
		if not is_instance_valid(e) or e.is_queued_for_deletion() or not (e is Node2D):
			continue
		if not e.has_method("take_damage"):
			continue
		if "is_dead" in e and e.is_dead:
			continue
		var d = origin.distance_to(e.global_position)
		var side_ok = (e.global_position.x - global_position.x) * dir >= -15.0
		if d < reach and side_ok and abs(e.global_position.y - global_position.y) < 90.0:
			hits.append([d, e])
	hits.sort_custom(func(a, b): return a[0] < b[0])
	if hits.is_empty():
		return
	var n := 0
	for h in hits:
		if n >= (3 if heavy else 2):
			break
		var e = h[1]
		e.take_damage(attack_damage)
		if heavy and e.has_method("_knockback") and is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			e._knockback(dir, 26.0, 0.22, 7.0)
		var at = Vector2((global_position.x + e.global_position.x) * 0.5 + dir * 10.0, global_position.y - 12.0)
		_spawn_hit_spark(at, dir, heavy)
		n += 1
	velocity.x = -dir * (60.0 if heavy else 30.0)
	_sfx("Player_Fish_ImpactHeavy_SoundEffect.wav" if heavy else "Player_Fish_Impact_SoundEffect.wav", -3.0 if heavy else -5.0)
	_shake_camera(0.24 if heavy else 0.13)
	_hitstop(0.085 if heavy else 0.045)

func _hitstop(dur: float) -> void:
	if Engine.time_scale < 0.99 or not is_inside_tree():
		return
	Engine.time_scale = 0.04
	await get_tree().create_timer(dur, true, false, true).timeout
	if Engine.time_scale <= 0.05:
		Engine.time_scale = 1.0

func _spawn_hit_spark(at: Vector2, dir: float, heavy: bool) -> void:
	if get_parent() == null:
		return
	var fx = Node2D.new()
	fx.z_as_relative = false
	fx.z_index = 120
	get_parent().add_child(fx)
	fx.global_position = at
	var rays: Array = []
	for i in range(9 if heavy else 6):
		var a = randf_range(-1.1, 1.1) + (0.0 if dir > 0 else PI)
		rays.append([a, randf_range(14.0, 30.0) * (1.4 if heavy else 1.0), randf_range(2.0, 3.0)])
	var st = {"k": 0.0}
	fx.draw.connect(func():
		var k: float = st["k"]
		var fade = 1.0 - k
		var r0 = (10.0 if heavy else 7.0) * (0.6 + k * 0.8)
		fx.draw_circle(Vector2.ZERO, r0 * 1.6, Color(1.0, 0.75, 0.35, 0.25 * fade))
		fx.draw_circle(Vector2.ZERO, r0 * (1.0 - k * 0.6), Color(1.0, 0.96, 0.85, fade))
		for rr in rays:
			var d = Vector2(cos(rr[0]), sin(rr[0]))
			var a0 = d * (r0 + k * rr[1] * 0.4)
			var a1 = d * (r0 + rr[1] * (0.4 + k))
			fx.draw_line(a0, a1, Color(1.0, 0.85, 0.45, fade), rr[2])
		if heavy:
			fx.draw_arc(Vector2.ZERO, r0 + k * 26.0, 0.0, TAU, 24, Color(1.0, 0.9, 0.7, 0.7 * fade), 2.0))
	var tw = fx.create_tween().set_ignore_time_scale(true)
	tw.tween_method(func(v): st["k"] = v; fx.queue_redraw(), 0.0, 1.0, 0.2 if heavy else 0.15)
	tw.tween_callback(fx.queue_free)

func _knock_dir_from(source) -> float:
	var sx = NAN
	if source is Node2D and is_instance_valid(source):
		sx = source.global_position.x
	elif source is Vector2:
		sx = source.x
	if is_nan(sx) or absf(sx - global_position.x) < 1.0:
		return -float(facing_direction)
	return 1.0 if global_position.x > sx else -1.0

func knockback_from(source, power: float = KNOCK_HIT) -> void:
	_knock_dir = _knock_dir_from(source)
	_knock_vx = _knock_dir * power * knockback_scale
	if is_on_floor():
		velocity.y = -70.0 * knockback_scale

func _shake_camera(amount: float) -> void:
	var cam = get_viewport().get_camera_2d() if get_viewport() else null
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(amount)

func take_damage(amount: int, source = null):
	if is_dead or is_dying:
		return
	if hp <= 0:
		return
	if is_stunned:
		return
	if is_parrying:
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
		knockback_from(source, KNOCK_DEATH)
		_shake_camera(DEATH_SHAKE)
		_begin_death()
		return
	knockback_from(source, KNOCK_HIT)
	_shake_camera(HURT_SHAKE)
	if sprite == null:
		return
	_set_blocking(false)
	is_hurt = true
	is_attacking = false
	attack_buffer = false
	_play_anim("Hit", true)
	await _await_anim_finished(1.0)
	is_hurt = false
	if not is_dead and not is_dying and not is_stunned and not is_parrying:
		_play_anim("Idle")

func _begin_death() -> void:
	if is_dead or is_dying:
		return
	is_dying = true
	die()

var _death_anim_started: bool = false

func die():
	if is_dead:
		return
	if not is_dying:
		is_dying = true
	_set_blocking(false)
	is_stunned = false
	is_parrying = false
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

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("Death"):
		if _death_anim_started:
			return
		_death_anim_started = true

		var last_frame = sprite.sprite_frames.get_frame_count("Death") - 1
		sprite.stop()
		sprite.animation = "Death"
		sprite.frame = 0
		sprite.play("Death")
		if not sprite.frame_changed.is_connected(_on_death_frame):
			sprite.frame_changed.connect(_on_death_frame)

		await sprite.animation_finished
		if not is_inside_tree():
			return

		sprite.stop()
		sprite.frame = last_frame
		if not _death_fish_spawned:
			_spawn_death_fish()
		await _safe_timer(0.7)
		if not is_inside_tree():
			return
	else:
		await _safe_timer(1.0)
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
	if is_hurt or is_dead or is_blocking or is_stunned or is_attacking or is_parrying:
		return
	if not _spend_stamina(dash_stamina_cost, "dash"):
		return
	if _slide_phase != "":
		_finish_slide_now()
	is_dashing = true
	dash_cooldown = 1.5
	var hold = _h_axis()
	_dash_dir = signf(hold) if abs(hold) > 0.2 else (-1.0 if facing_direction == -1 else 1.0)
	facing_direction = int(_dash_dir)
	if sprite:
		sprite.scale.x = _dash_dir
	_dash_t = DASH_TIME

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
	_play_anim("Idle")
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
	if is_climbing_animation or is_climbing or is_vaulting or is_blocking or is_stunned or is_parrying:
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
	await _safe_timer(0.3 if high else 0.15)
	is_vaulting = false

func _try_climb():
	return false

func _try_ladder_climb():
	if is_on_ladder:
		return
	if not nearby_ladder:
		return
	if has_item or movement_blocked or is_blocking or is_stunned or is_parrying:
		return
	is_on_ladder = true
	is_climbing = true
	velocity = Vector2.ZERO
	if sprite:
		_play_anim("Idle")
		sprite.scale.x = 1
	while is_on_ladder:
		await get_tree().process_frame
		if not is_inside_tree():
			break
		if not is_instance_valid(nearby_ladder):
			break
		if Input.is_action_just_pressed("jump") and not block_jump:
			is_on_ladder = false
			velocity.y = jump_velocity
			break
		if Input.is_action_just_pressed("interact"):
			is_on_ladder = false
			break
		var vertical = Input.get_axis("ui_up", "ui_down")
		var top = nearby_ladder.get_top_y()
		var bottom = nearby_ladder.get_bottom_y()
		global_position.y += vertical * nearby_ladder.climb_speed * get_process_delta_time()
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
	_play_anim("Idle")

func on_death_zone_entered():
	_begin_death()

func set_hp(value: int):
	hp = clamp(value, 0, max_hp)

func snap_to_floor_now() -> void:
	if is_dead or is_falling_into_pit:
		return
	velocity = Vector2(0, 60)
	move_and_slide()
	velocity = Vector2.ZERO
	was_on_floor_last_frame = true
	is_landing = false
	if sprite and sprite.animation in ["Falling", "Jump", "Landing"]:
		_play_anim("Idle", true)

func fall_into_pit(zone: Node2D = null):
	if is_dead or is_dying or is_falling_into_pit:
		return
	is_falling_into_pit = true
	is_dying = true
	movement_blocked = true
	is_dashing = false
	is_sliding = false
	is_vaulting = false
	is_climbing = false
	is_climbing_animation = false
	is_attacking = false
	is_landing = false
	_set_blocking(false)
	Engine.time_scale = 1.0
	var body_shape = get_node_or_null("CollisionShape2D")
	if body_shape:
		body_shape.set_deferred("disabled", true)

	var pit := Rect2()
	if zone:
		var zc = zone.get_node_or_null("CollisionShape2D")
		if zc and zc.shape is RectangleShape2D:
			var hs = zc.shape.size / 2.0
			pit = Rect2(zc.global_position - hs, zc.shape.size)

	var vx = clamp(velocity.x, -160.0, 160.0)
	var vy = min(velocity.y, 0.0) + 60.0
	if camera and "follow_enabled" in camera:
		camera.follow_enabled = false
	_shake_camera(0.2)
	if sprite:
		_play_anim("Falling", true)
		var spin = create_tween()
		spin.tween_property(sprite, "rotation", deg_to_rad(28.0) * (1.0 if vx >= 0.0 else -1.0), 0.9)
	var dark = create_tween()
	dark.tween_property(self, "modulate", Color(0.05, 0.05, 0.07, 1.0), 0.6).set_delay(0.15)

	var t := 0.0
	while t < 1.0:
		await get_tree().physics_frame
		if not is_inside_tree():
			return
		var d = get_physics_process_delta_time()
		t += d
		vy += gravity * d
		vx = move_toward(vx, 0.0, 260.0 * d)
		var nx = global_position.x + vx * d
		if pit.has_area():
			nx = clamp(nx, pit.position.x + 14.0, pit.end.x - 14.0)
		global_position = Vector2(nx, global_position.y + vy * d)

	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	_show_death_screen()

func set_movement_blocked(blocked: bool):
	movement_blocked = blocked


func _on_death_frame() -> void:
	if sprite == null or sprite.animation != "Death":
		return
	if sprite.frame >= DEATH_FISH_FRAME and not _death_fish_spawned:
		_spawn_death_fish()


func _death_fish_frames() -> SpriteFrames:
	var tex = load(DEATH_FISH_SHEET) as Texture2D
	if tex == null:
		return null
	var img = tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	var f = SpriteFrames.new()
	f.set_animation_loop("default", true)
	f.set_animation_speed("default", 12.0)
	var n = int(tex.get_width() / 160.0)
	for i in range(n):
		var cell = img.get_region(Rect2i(i * 160, 0, 160, tex.get_height()))
		var used = cell.get_used_rect()
		if used.size.x <= 0 or used.size.y <= 0:
			continue
		var at = AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * 160 + used.position.x, used.position.y, used.size.x, used.size.y)
		f.add_frame("default", at)
	return f


func _spawn_death_fish() -> void:
	_death_fish_spawned = true
	if sprite == null or not is_inside_tree():
		return
	var frames = _death_fish_frames()
	if frames == null or frames.get_frame_count("default") == 0:
		return
	var host = get_parent() if get_parent() else self
	_death_fish = AnimatedSprite2D.new()
	_death_fish.sprite_frames = frames
	_death_fish.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_death_fish.z_as_relative = false
	_death_fish.z_index = max(sprite.z_index + z_index + 2, 35)
	var side = signf(sprite.scale.x) if sprite.scale.x != 0.0 else 1.0
	var start = sprite.to_global(Vector2(-46.0, 2.0))
	_death_fish.global_position = start
	_death_fish.scale = sprite.global_scale.abs()
	_death_fish.flip_h = side < 0.0
	host.add_child(_death_fish)
	_death_fish.global_position = start
	_death_fish.play("default")
	var away = -side
	if _knock_dir != 0.0:
		away = _knock_dir
	_death_fish_v = Vector2(away * randf_range(120.0, 150.0), -randf_range(240.0, 275.0))
	_death_fish_floor = sprite.to_global(Vector2(0, 36.0)).y
	_death_fish_bounces = 0
	_start_death_air()
	for i in range(8):
		var d = ColorRect.new()
		d.size = Vector2(2, 2)
		d.color = Color(0.55, 0.85, 1.0, 0.9)
		d.z_as_relative = false
		d.z_index = _death_fish.z_index
		host.add_child(d)
		d.global_position = start
		var to = start + Vector2(randf_range(-26, 26), -randf_range(10, 30))
		var tw = d.create_tween()
		tw.tween_property(d, "global_position", to, 0.25).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "global_position", Vector2(to.x + randf_range(-6, 6), _death_fish_floor), 0.3).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(d, "modulate:a", 0.0, 0.3)
		tw.tween_callback(d.queue_free)


func _start_death_air() -> void:
	_death_air_t = 0.0
	_death_air_out = false
	var gui = get_node_or_null("GUI") as CanvasLayer
	var cont = gui.get_node_or_null("UI_Container") if gui else null
	_death_air_bar = cont.get_node_or_null("Air_Bar") as AnimatedSprite2D if cont else null
	if _death_air_bar == null:
		return
	var shown = gui.visible and cont.visible and cont.modulate.a > 0.99 and _death_air_bar.visible and _death_air_bar.modulate.a > 0.99
	if not (gui.visible and cont.visible):
		cont.modulate.a = 0.0
	gui.visible = true
	cont.visible = true
	_death_air_bar.stop()
	_death_air_bar.animation = &"AirBalloon"
	_death_air_bar.frame = 0
	if shown:
		return
	var lvl = get_tree().current_scene
	if lvl and lvl.has_method("_place_air_bar"):
		lvl._place_air_bar()
	_death_air_bar.visible = true
	var base_scale = _death_air_bar.scale
	_death_air_bar.modulate = Color(1, 1, 1, 0.0)
	_death_air_bar.scale = base_scale * 0.6
	var tw = _death_air_bar.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(_death_air_bar, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(0.15)
	tw.tween_property(_death_air_bar, "scale", base_scale, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.15)
	if cont.modulate.a < 0.99:
		tw.tween_property(cont, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _update_death_air(delta: float) -> void:
	if _death_air_t < 0.0 or _death_air_out:
		return
	_death_air_t += delta
	var k = clamp(_death_air_t / DEATH_AIR_TIME, 0.0, 1.0)
	if _death_air_bar and is_instance_valid(_death_air_bar) and _death_air_bar.sprite_frames:
		var last = _death_air_bar.sprite_frames.get_frame_count(_death_air_bar.animation) - 1
		_death_air_bar.frame = int(round(k * last))
		if k > 0.8:
			var on = int(Time.get_ticks_msec() / 160) % 2 == 0
			_death_air_bar.modulate = Color(1.0, 0.45, 0.45) if on else Color.WHITE
	if _death_fish and is_instance_valid(_death_fish) and _death_fish_bounces >= 4:
		_death_fish.speed_scale = lerp(0.9, 0.15, k)
	if k >= 1.0:
		_death_air_out = true
		if _death_air_bar and is_instance_valid(_death_air_bar):
			_death_air_bar.modulate = Color(1.0, 0.45, 0.45)
		if _death_fish and is_instance_valid(_death_fish):
			var tw = _death_fish.create_tween()
			tw.tween_property(_death_fish, "rotation", 0.12, 0.08)
			tw.tween_property(_death_fish, "rotation", 0.0, 0.18)
			tw.tween_callback(func():
				if is_instance_valid(_death_fish):
					_death_fish.stop()
					_death_fish.frame = 0
					_death_fish.modulate = Color(0.8, 0.8, 0.85))

func _update_death_fish(delta: float) -> void:
	if _death_fish == null or not is_instance_valid(_death_fish):
		return
	_update_death_air(delta)
	if _death_fish_bounces >= 4:
		return
	if _death_fish_bounces == 3:
		var s = signf(_death_fish_v.x)
		_death_fish_v.x = s * maxf(0.0, absf(_death_fish_v.x) - 260.0 * delta)
		_death_fish.global_position.x += _death_fish_v.x * delta
		_death_fish.rotation = lerp_angle(_death_fish.rotation, 0.0, 1.0 - exp(-14.0 * delta))
		if randf() < absf(_death_fish_v.x) / 900.0:
			_death_fish_dust(_death_fish.global_position + Vector2(-s * 6.0, 4.0))
		if absf(_death_fish_v.x) < 4.0:
			_death_fish_bounces = 4
			_death_fish_v = Vector2.ZERO
			_death_fish.rotation = 0.0
			_death_fish.speed_scale = 0.5
		return
	_death_fish_v.y += 760.0 * delta
	_death_fish.global_position += _death_fish_v * delta
	_death_fish.rotation += _death_fish_v.x * 0.045 * delta * (1.4 if _death_fish_v.y < 0.0 else 1.0)
	if _death_fish.global_position.y >= _death_fish_floor and _death_fish_v.y > 0.0:
		_death_fish.global_position.y = _death_fish_floor
		_death_fish_bounces += 1
		_death_fish_dust(_death_fish.global_position + Vector2(0, 4))
		if _death_fish_bounces >= 3 or absf(_death_fish_v.y) < 110.0:
			_death_fish_bounces = 3
			_death_fish_v = Vector2(_death_fish_v.x * 0.9, 0.0)
		else:
			_death_fish_v = Vector2(_death_fish_v.x * 0.8, -_death_fish_v.y * 0.36)
			_death_fish.rotation = lerp_angle(_death_fish.rotation, 0.0, 0.6)

func _death_fish_dust(at: Vector2) -> void:
	var host = _death_fish.get_parent()
	if host == null:
		return
	for i in range(2):
		var d = ColorRect.new()
		d.size = Vector2(2, 2)
		d.color = Color(0.75, 0.75, 0.8, 0.7)
		d.z_as_relative = false
		d.z_index = _death_fish.z_index - 1
		host.add_child(d)
		d.global_position = at + Vector2(randf_range(-3, 3), 0)
		var tw = d.create_tween()
		tw.tween_property(d, "global_position", d.global_position + Vector2(randf_range(-8, 8), -randf_range(3, 8)), 0.35).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(d, "modulate:a", 0.0, 0.35)
		tw.tween_callback(d.queue_free)
