extends StorageEnemy
## Storage mecha-monkey (green).
## Clever and springy: keeps just outside the fish's reach and pokes with its long mech tail,
## bounces over a blocking fish on the tail and lands behind it (hits from behind break the
## block), slams the floor when it lands, and when things go badly it runs to its forklift,
## climbs in and tries to run the fish over. Smash the forklift: it breaks, the monkey is
## baffled and the airbag knocks it out.

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var placeholder: ColorRect = get_node_or_null("PlaceholderRect")
@onready var detection_area: Area2D = get_node_or_null("DetectionArea")
@onready var forklift: Sprite2D = get_node_or_null("Forklift")

enum State { PATROL, ALERT, SPACING, ATTACK, TAIL_ATTACK, TAIL_JUMP, AIR, LAND, STUN,
	GOTO_FORKLIFT, FORKLIFT_ENTER, DRIVE, FORKLIFT_BRAKE, FORKLIFT_BREAK, DEAD }
var state: State = State.PATROL

var FUR_SOURCE := [Color8(152, 102, 64), Color8(120, 78, 48), Color8(84, 52, 34)]
var FUR_VARIANTS := [
	[Color8(124, 124, 130), Color8(92, 92, 100), Color8(60, 60, 68)],     # grey langur
	[Color8(214, 130, 70), Color8(176, 96, 46), Color8(120, 62, 30)],     # orangutan ginger
	[Color8(70, 62, 60), Color8(48, 42, 42), Color8(30, 26, 28)],         # black
	[Color8(206, 180, 140), Color8(170, 142, 104), Color8(124, 100, 72)], # sandy
]

const FORK_W := 128.0

@export var run_speed: float = 225.0
@export var poke_range: float = 112.0       # tail reach - longer than the fish's fists
@export var punch_range: float = 66.0
@export var keep_distance: float = 100.0
@export var pogo_velocity: float = -540.0
@export var slam_radius: float = 58.0
@export var has_forklift: bool = false
@export var forklift_offset_x: float = 170.0
@export var forklift_hp: int = 7
@export var drive_speed: float = 340.0

var t: float = 0.0
var cooldown: float = 0.0
var tail_cooldown: float = 0.0
var pogo_cooldown: float = 0.8
var hit_done: bool = false
var combo_left: int = 0
var _alerted: bool = false
var _aggro_time: float = 0.0
var _fork_hp: int = 0
var _fork_used: bool = false
var _ram_cooldown: float = 0.0
var _drive_dir: int = 1
var _passed_player: bool = false
var _ko_finish: bool = false
var _pogo_target_x: float = 0.0


func _ready() -> void:
	super._ready()
	shard_color = "green"
	max_hp = 6
	hp = max_hp
	can_be_parried = true
	aggro_range = 420.0
	deaggro_range = 760.0
	if placeholder:
		placeholder.visible = sprite == null or sprite.sprite_frames == null
	if sprite:
		_base_sprite_offset = sprite.offset
		apply_fur_variant(sprite, FUR_SOURCE, FUR_VARIANTS)
	if detection_area:
		detection_area.body_entered.connect(func(b):
			if b.is_in_group("player") and player == null:
				player = b
		)
	_fork_hp = forklift_hp
	_setup_forklift.call_deferred()
	_play("idle")


func _setup_forklift() -> void:
	if forklift == null:
		return
	if not has_forklift:
		forklift.queue_free()
		forklift = null
		return
	# park it on the floor next to the monkey (forklift frame is 80 px, the monkey 75 px);
	# it belongs to the level from now on, so it stays even if the monkey never uses it
	var pos = global_position + Vector2(forklift_offset_x, -(80.0 - 75.0) / 2.0 - 2.0)
	var floor_hit = _ray(pos + Vector2(0, -20), pos + Vector2(0, 200))
	if not floor_hit.is_empty():
		pos.y = floor_hit.position.y - 40.0   # 80 px frame, wheels on the floor
	forklift.reparent(get_parent())
	forklift.global_position = pos
	forklift.z_index = -1
	forklift.visible = true


func _play(anim_name: String, restart: bool = false) -> void:
	_play_on(sprite, anim_name, Vector2.ZERO, restart)
	if sprite:
		sprite.speed_scale = 1.0


# ------------------------------------------------------------------ main loop
func _physics_process(delta: float) -> void:
	if is_dead:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		move_and_slide()
		return
	super._physics_process(delta)
	if player == null:
		_find_player()
	if not _player_ok():
		player = null
		is_aggro = false
	_observe_player(delta)

	if is_stunned and state != State.FORKLIFT_BREAK:
		_stun_logic(delta)
		move_and_slide()
		return

	t += delta
	cooldown = max(0.0, cooldown - delta)
	tail_cooldown = max(0.0, tail_cooldown - delta)
	pogo_cooldown = max(0.0, pogo_cooldown - delta)
	_ram_cooldown = max(0.0, _ram_cooldown - delta)

	var dx := 0.0
	var dy := 0.0
	var dist := 99999.0
	if _player_ok():
		dx = player.global_position.x - global_position.x
		dy = player.global_position.y - global_position.y
		dist = abs(dx)
		_update_aggro(global_position.distance_to(player.global_position))
	if is_aggro:
		_aggro_time += delta

	match state:
		State.PATROL: _patrol(delta)
		State.ALERT: _alert_logic(dx)
		State.SPACING: _spacing_logic(dist, dx, dy)
		State.ATTACK: _attack_logic(dist)
		State.TAIL_ATTACK: _tail_attack_logic()
		State.TAIL_JUMP: _tail_jump_logic()
		State.AIR: _air_logic()
		State.LAND: _land_logic()
		State.GOTO_FORKLIFT: _goto_forklift_logic()
		State.FORKLIFT_ENTER: _forklift_enter_logic()
		State.DRIVE: _drive_logic(dist, dx, dy)
		State.FORKLIFT_BRAKE: _brake_logic(delta)
		State.FORKLIFT_BREAK: _forklift_break_logic()

	if sprite:
		sprite.scale.x = abs(sprite.scale.x) * (1 if facing_dir > 0 else -1)
	move_and_slide()


func _face(dx: float) -> void:
	if dx != 0.0:
		facing_dir = 1 if dx > 0 else -1


func _go(s: State) -> void:
	state = s
	t = 0.0
	hit_done = false


# ------------------------------------------------------------------ on foot
func _patrol(delta: float) -> void:
	if is_aggro:
		velocity.x = 0
		_go(State.ALERT)
		return
	if _ledge_ahead(patrol_dir) or _wall_ahead(patrol_dir):
		patrol_dir = -patrol_dir
	_patrol_step(delta)
	_play("run_fast" if abs(velocity.x) > 5 else "idle")
	if sprite and abs(velocity.x) > 5:
		sprite.speed_scale = 0.5


func _alert_logic(dx: float) -> void:
	velocity.x = 0
	_face(dx)
	_play("idle")
	if not _alerted:
		_alerted = true
		_alert_allies()
	if t > 0.3:
		_go(State.SPACING)


## The monkey's brain: stay just outside the fish's reach and choose the right trick.
func _spacing_logic(dist: float, dx: float, dy: float) -> void:
	if not is_aggro:
		_release_token()
		_go(State.PATROL)
		return
	_face(dx)
	# time for the forklift?
	if _should_use_forklift():
		_release_token()
		_go(State.GOTO_FORKLIFT)
		return
	var on_floor = is_on_floor()
	# fish swings at us: bounce away on the tail (or over it when cornered)
	if on_floor and pogo_cooldown <= 0.0 and _player_threatens(105.0) and randf() < 0.6:
		var behind_free = not _ledge_ahead(-facing_dir, 60.0) and not _wall_ahead(-facing_dir, 70.0)
		_start_pogo(not behind_free)
		return
	# a blocking fish gets jumped over: hits from behind go through the block
	if on_floor and pogo_cooldown <= 0.0 and (_player_flag("is_blocking") or player_block_habit > 0.4) and dist < 220.0 and abs(dy) < 70.0:
		_start_pogo(true)
		return
	# whiff punish
	if _whiff_window > 0.0 and cooldown <= 0.0 and dist < poke_range and _request_token():
		if dist < punch_range + 10.0:
			_start_combo()
		else:
			_start_tail()
		return
	# keep the sweet spot: inside tail reach, outside fist reach
	var want = keep_distance
	var move = 0.0
	if dist > want + 18.0:
		move = 1.0
	elif dist < want - 22.0:
		move = -1.0
	var dir = int(sign(dx)) * int(move)
	if dir != 0 and (_ledge_ahead(dir) or _wall_ahead(dir)):
		dir = 0
		# cornered at a ledge with the fish close: go over it
		if move < 0.0 and pogo_cooldown <= 0.0 and dist < 90.0:
			_start_pogo(true)
			return
	velocity.x = dir * run_speed * (0.65 if move < 0.0 else 1.0) + _separation() * 120.0
	_play("run_fast" if abs(velocity.x) > 10 else "idle")
	if cooldown > 0.0 or abs(dy) > 70.0 or not on_floor:
		return
	if not _request_token():
		return
	if dist < punch_range and not _player_flag("is_parrying"):
		_start_combo()
	elif dist < poke_range and tail_cooldown <= 0.0:
		_start_tail()
	elif dist < 260.0 and dist > 150.0 and pogo_cooldown <= 0.0 and randf() < 0.012:
		_start_pogo(true)   # surprise leap over the fish


func _start_combo() -> void:
	combo_left = 2 if randf() < 0.5 else 1
	_go(State.ATTACK)
	_play("attack_right", true)


func _attack_logic(dist: float) -> void:
	velocity.x = 0
	if not hit_done and t >= 0.22:
		hit_done = true
		if dist < punch_range + 14.0 and _same_level():
			_hurt_player_smart(1)
	if t >= 0.52:
		combo_left -= 1
		if combo_left > 0 and dist < punch_range + 16.0:
			_go(State.ATTACK)
			_play("attack_left", true)
			return
		cooldown = randf_range(0.5, 0.9)
		_release_token()
		_go(State.SPACING)


func _start_tail() -> void:
	tail_cooldown = randf_range(1.6, 2.4)
	_go(State.TAIL_ATTACK)
	_play("tail_attack", true)


func _tail_attack_logic() -> void:
	velocity.x = 0
	# the tail sweeps through frames 3-5
	if not hit_done and t >= 0.2:
		hit_done = true
		if _player_ok() and _same_level():
			var rel = player.global_position.x - global_position.x
			if rel * facing_dir > -20.0 and abs(rel) < poke_range + 8.0:
				_hurt_player_smart(2)
				_shake(0.12)
	if t >= _anim_length(sprite, "tail_attack"):
		cooldown = 0.45
		_release_token()
		_go(State.SPACING)


func _same_level() -> bool:
	return _player_ok() and abs(player.global_position.y - global_position.y) < 60.0


# ------------------------------------------------------------------ tail pogo
## over = true: land on the far side of the fish; false: bounce back away from it.
func _start_pogo(over: bool) -> void:
	pogo_cooldown = randf_range(2.2, 3.2)
	_go(State.TAIL_JUMP)
	velocity.x = 0
	_play("tail_jump", true)
	if _player_ok():
		var px = _predict_player(0.6).x
		if over:
			_pogo_target_x = px + facing_dir * 70.0
		else:
			_pogo_target_x = global_position.x - facing_dir * 170.0
	else:
		_pogo_target_x = global_position.x - facing_dir * 120.0


func _tail_jump_logic() -> void:
	# crouch + coil, then launch on the 4th frame
	if t < 0.22:
		velocity.x = 0
		return
	if not hit_done:
		hit_done = true
		var air_time = 2.0 * abs(pogo_velocity) / gravity
		velocity.y = pogo_velocity
		velocity.x = clamp((_pogo_target_x - global_position.x) / air_time, -420.0, 420.0)
	if t > 0.42:
		_go(State.AIR)
		_play("fall", true)


func _air_logic() -> void:
	# turn toward the fish in the air so it lands facing it
	if _player_ok():
		_face(player.global_position.x - global_position.x)
	if is_on_floor() and t > 0.08:
		_go(State.LAND)
		_play("land", true)
		_slam()
	elif t > 2.5:
		_go(State.LAND)


func _slam() -> void:
	velocity.x = 0
	_shake(0.1)
	if _player_ok() and global_position.distance_to(player.global_position) < slam_radius and player.is_on_floor():
		_hurt_player_smart(1)


func _land_logic() -> void:
	velocity.x = move_toward(velocity.x, 0.0, 40.0)
	if t >= 0.3:
		# landed behind a fish that was guarding: punish its back right away
		if _player_ok() and abs(player.global_position.x - global_position.x) < poke_range and tail_cooldown <= 0.0 and _request_token():
			_face(player.global_position.x - global_position.x)
			_start_tail()
			return
		_go(State.SPACING)


func _stun_logic(delta: float) -> void:
	stun_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
	if stun_timer <= 0.0:
		is_stunned = false
		if sprite:
			sprite.modulate = Color.WHITE
		if state in [State.DRIVE, State.FORKLIFT_BRAKE]:
			_play("forklift_drive")
			return
		cooldown = 0.2
		_go(State.SPACING if is_aggro else State.PATROL)


# ------------------------------------------------------------------ forklift
func _should_use_forklift() -> bool:
	if forklift == null or _fork_used or not is_instance_valid(forklift):
		return false
	if abs(forklift.global_position.y - global_position.y) > 70.0:
		return false
	if abs(forklift.global_position.x - global_position.x) > 900.0:
		return false
	# hurt, or the fight drags on
	return hp <= max_hp - 2 or _aggro_time > 7.0


func _goto_forklift_logic() -> void:
	if forklift == null or not is_instance_valid(forklift):
		_go(State.SPACING)
		return
	var dx = forklift.global_position.x - global_position.x
	_face(dx)
	if abs(dx) < 10.0:
		velocity.x = 0
		_fork_used = true
		global_position.x = forklift.global_position.x
		forklift.visible = false
		if _player_ok():
			_face(player.global_position.x - global_position.x)
		_go(State.FORKLIFT_ENTER)
		_play("forklift_enter", true)
		return
	var dir = int(sign(dx))
	if _ledge_ahead(dir) or _wall_ahead(dir):
		_fork_used = true
		_go(State.SPACING)
		return
	velocity.x = dir * run_speed * 1.15
	_play("run_fast")


func _forklift_enter_logic() -> void:
	velocity.x = 0
	if t >= _anim_length(sprite, "forklift_enter"):
		_fork_hp = forklift_hp
		_go(State.DRIVE)
		_drive_dir = facing_dir
		_passed_player = false
		_play("forklift_drive", true)
		_shake(0.08)


func _drive_logic(_dist: float, dx: float, dy: float) -> void:
	facing_dir = _drive_dir
	_play("forklift_drive")
	# ledge / wall in front: brake and turn around
	if _ledge_ahead(_drive_dir, 64.0) or _wall_ahead(_drive_dir, 70.0):
		_go(State.FORKLIFT_BRAKE)
		return
	velocity.x = move_toward(velocity.x, _drive_dir * drive_speed, 18.0)
	if not _player_ok():
		return
	# ram the fish with the forks
	var rel = dx * _drive_dir
	if rel > -10.0 and rel < 70.0 and abs(dy) < 60.0 and _ram_cooldown <= 0.0:
		_ram_cooldown = 0.9
		if _hurt_player_smart(2):
			_shake(0.3)
			player.velocity.x = _drive_dir * 320.0
	# overshot the fish: brake and come back
	if rel < -140.0:
		_go(State.FORKLIFT_BRAKE)


func _brake_logic(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_play("forklift_drive")
	if sprite:
		sprite.speed_scale = 0.4
	if t > 0.45:
		_drive_dir = -_drive_dir
		if _player_ok():
			var want = int(sign(player.global_position.x - global_position.x))
			if want != 0:
				_drive_dir = want
		# never drive back off the same ledge
		if _ledge_ahead(_drive_dir, 64.0) or _wall_ahead(_drive_dir, 70.0):
			_drive_dir = -_drive_dir
		_go(State.DRIVE)


func _forklift_break_logic() -> void:
	velocity.x = move_toward(velocity.x, 0.0, 30.0)
	if t >= _anim_length(sprite, "forklift_break") + 0.3:
		_leave_wreck()
		_ko_finish = true
		hp = 0
		die()


func _leave_wreck() -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("forklift_break"):
		return
	var n = sprite.sprite_frames.get_frame_count("forklift_break")
	var w = Sprite2D.new()
	w.texture = sprite.sprite_frames.get_frame_texture("forklift_break", n - 1)
	w.flip_h = facing_dir < 0
	w.global_position = global_position + Vector2(0, sprite.offset.y)
	w.modulate = Color(0.75, 0.75, 0.78)
	w.z_index = -1
	get_parent().add_child(w)
	sprite.visible = false


# ------------------------------------------------------------------ damage
func take_damage(amount: int) -> void:
	if is_dead:
		return
	if state in [State.FORKLIFT_ENTER, State.FORKLIFT_BREAK]:
		return
	if state in [State.DRIVE, State.FORKLIFT_BRAKE]:
		# the forklift takes the hits for the monkey
		_fork_hp -= amount
		_play("forklift_shake", true)
		_flash_damage()
		_shake(0.06)
		if _fork_hp <= 0:
			velocity.x *= 0.3
			_go(State.FORKLIFT_BREAK)
			_play("forklift_break", true)
		else:
			_shake_then_drive()
		return
	super.take_damage(amount)


func _shake_then_drive() -> void:
	await get_tree().create_timer(_anim_length(sprite, "forklift_shake"), false).timeout
	if is_instance_valid(self) and not is_dead and state in [State.DRIVE, State.FORKLIFT_BRAKE]:
		_play("forklift_drive", true)


func _on_hurt() -> void:
	# springy: often bounces out instead of taking a combo
	if is_on_floor() and pogo_cooldown <= 0.0 and randf() < 0.4:
		_start_pogo(randf() < 0.3)
		return
	_release_token()
	state = State.STUN
	is_stunned = true
	stun_timer = 0.28
	if _player_ok():
		var away = sign(global_position.x - player.global_position.x)
		velocity.x = (away if away != 0 else float(-facing_dir)) * 150.0
	_play("hit", true)


func _on_death() -> void:
	state = State.DEAD
	collision_layer = 0
	if detection_area:
		detection_area.set_deferred("monitoring", false)
	var anim_len := 0.6
	if not _ko_finish and sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.modulate = Color.WHITE
		_play("death", true)
		anim_len = _anim_length(sprite, "death")
	elif sprite:
		sprite.stop()
	death_free_delay = anim_len + 1.4
	if sprite and sprite.visible:
		var tw = create_tween()
		tw.tween_interval(anim_len + 0.6)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.7)
