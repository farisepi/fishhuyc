extends StorageEnemy

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var aim_line: Line2D = get_node_or_null("AimLine")
@onready var muzzle: Marker2D = get_node_or_null("Muzzle")
@onready var pistol_muzzle: Marker2D = get_node_or_null("PistolMuzzle")
@onready var detection_area: Area2D = get_node_or_null("DetectionArea")

enum State { PATROL, ALERT, AIM, FIRE, REPOSITION, DROP_FLYBACK, PISTOL, FLYBACK, GET_RIFLE, STUN, DEAD }
var state: State = State.PATROL

var FUR_SOURCE := [Color8(190, 198, 218), Color8(146, 156, 184), Color8(104, 112, 140)]
var FUR_VARIANTS := [
	[Color8(226, 226, 230), Color8(196, 196, 204), Color8(150, 150, 160)],
	[Color8(170, 140, 120), Color8(136, 106, 90), Color8(96, 72, 62)],
	[Color8(120, 120, 128), Color8(86, 86, 96), Color8(56, 56, 66)],
]
const RIFLE_TEX := "res://GameAssets/Sprites/EntitySprites/EnemySprites/MechaPigeonSprites/MechaPigeonRifleTextures/Enemy_MechaPigeon_Rifle_Texture.png"

@export var sniper_min_range: float = 170.0
@export var sniper_max_range: float = 760.0
@export var aim_time: float = 1.15
@export var aim_lock_time: float = 0.3
@export var aim_turn_speed: float = 3.2
@export var rifle_damage: int = 2
@export var rifle_bullet_speed: float = 1900.0
@export var pistol_damage: int = 1
@export var pistol_bullet_speed: float = 600.0
@export var pistol_keep_min: float = 150.0
@export var pistol_keep_max: float = 320.0

var t: float = 0.0
var has_rifle: bool = true
var _rifle_prop: Sprite2D = null
var _aim_dir: Vector2 = Vector2.RIGHT
var _no_los_time: float = 0.0
var _fly_cooldown: float = 0.0
var _burst_left: int = 0
var _shot_timer: float = 0.0
var _alerted: bool = false
var _bullets: Array = []
var _fired: bool = false
var _burst_armed: bool = false


func _ready() -> void:
	super._ready()
	shard_color = "cyan"
	max_hp = 5
	hp = max_hp
	can_be_parried = false
	aggro_range = 820.0
	deaggro_range = 1200.0
	if sprite:
		_base_sprite_offset = sprite.offset
		apply_fur_variant(sprite, FUR_SOURCE, FUR_VARIANTS)
	if detection_area:
		detection_area.body_entered.connect(func(b):
			if b.is_in_group("player") and player == null:
				player = b
		)
	if aim_line:
		aim_line.visible = false
		aim_line.top_level = true
	var ph = get_node_or_null("PlaceholderRect")
	if ph:
		ph.visible = false
	_play("idle_aim")


func _play(anim_name: String, restart: bool = false) -> void:
	_play_on(sprite, anim_name, Vector2.ZERO, restart)


func _physics_process(delta: float) -> void:
	_update_bullets(delta)
	if is_dead:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		move_and_slide()
		return
	if state in [State.DROP_FLYBACK, State.FLYBACK] and velocity.y > 0.0:
		velocity.y -= gravity * 0.6 * delta
	super._physics_process(delta)
	if player == null:
		_find_player()
	if not _player_ok():
		player = null
		is_aggro = false
	_observe_player(delta)

	if is_stunned:
		stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
		_hide_aim()
		if stun_timer <= 0.0:
			is_stunned = false
			if sprite:
				sprite.modulate = Color.WHITE
			_go(State.AIM if has_rifle else State.PISTOL)
		move_and_slide()
		return

	t += delta
	_fly_cooldown = max(0.0, _fly_cooldown - delta)

	var dist := 99999.0
	var dx := 0.0
	if _player_ok():
		dx = player.global_position.x - global_position.x
		dist = global_position.distance_to(player.global_position)
		_update_aggro(dist)

	match state:
		State.PATROL: _patrol_logic()
		State.ALERT: _alert_logic(dx)
		State.AIM: _aim_logic(delta, dist, dx)
		State.FIRE: _fire_logic(dist)
		State.REPOSITION: _reposition_logic(dist, dx)
		State.DROP_FLYBACK: _drop_flyback_logic()
		State.PISTOL: _pistol_logic(delta, dist, dx)
		State.FLYBACK: _flyback_logic()
		State.GET_RIFLE: _get_rifle_logic(dist)

	if sprite:
		sprite.scale.x = abs(sprite.scale.x) * (1 if facing_dir > 0 else -1)
	_sync_markers()
	move_and_slide()


func _go(s: State) -> void:
	if s != State.PISTOL:
		_clear_telegraph()
		_burst_armed = false
	state = s
	t = 0.0
	_fired = false


func _face(dx: float) -> void:
	if dx != 0.0:
		facing_dir = 1 if dx > 0 else -1


func _sync_markers() -> void:
	if muzzle:
		muzzle.position.x = abs(muzzle.position.x) * facing_dir
	if pistol_muzzle:
		pistol_muzzle.position.x = abs(pistol_muzzle.position.x) * facing_dir


func _eye() -> Vector2:
	return global_position + Vector2(0, -22)


func _player_center() -> Vector2:
	return player.global_position + Vector2(0, -8)


func _sees_player() -> bool:
	return _player_ok() and _has_line_of_sight(_eye(), _player_center())


func _patrol_logic() -> void:
	velocity.x = 0
	_play("idle_aim" if has_rifle else "pistol_fire")
	if is_aggro and _sees_player():
		_go(State.ALERT)


func _alert_logic(dx: float) -> void:
	velocity.x = 0
	_face(dx)
	if not _alerted:
		_alerted = true
		_alert_allies(700.0)
	if t > 0.3:
		if has_rifle:
			_start_aim()
		else:
			_go(State.PISTOL)


func _start_aim() -> void:
	_go(State.AIM)
	_play("idle_aim")
	if _player_ok() and muzzle:
		_aim_dir = (_player_center() - muzzle.global_position).normalized()


func _aim_logic(delta: float, dist: float, dx: float) -> void:
	velocity.x = 0
	if not is_aggro:
		_hide_aim()
		_go(State.PATROL)
		return
	_face(dx)
	_play("idle_aim")
	if dist < sniper_min_range:
		_start_drop_flyback()
		return
	if not _sees_player():
		_no_los_time += delta
		_hide_aim()
		if _no_los_time > 0.6:
			_go(State.REPOSITION)
		return
	_no_los_time = 0.0
	var origin = muzzle.global_position if muzzle else _eye()
	var locked = t >= aim_time - aim_lock_time
	if not locked:
		var lead = dist / rifle_bullet_speed
		var want = (_predict_player(lead) + Vector2(0, -8) - origin).normalized()
		var ang = _aim_dir.angle()
		var diff = wrapf(want.angle() - ang, -PI, PI)
		ang += clamp(diff, -aim_turn_speed * delta, aim_turn_speed * delta)
		_aim_dir = Vector2.from_angle(ang)
	_show_aim(origin, locked)
	if t >= aim_time:
		_shoot_rifle(origin)


func _show_aim(origin: Vector2, locked: bool) -> void:
	if aim_line == null:
		return
	aim_line.visible = true
	aim_line.global_position = origin
	aim_line.rotation = _aim_dir.angle()
	var hit = _ray(origin, origin + _aim_dir * 1600.0)
	var length = 1600.0 if hit.is_empty() else origin.distance_to(hit.position)
	aim_line.points = PackedVector2Array([Vector2.ZERO, Vector2(length, 0)])
	if locked:
		var blink = int(t * 20.0) % 2 == 0
		aim_line.default_color = Color(1, 0.15, 0.1, 0.95 if blink else 0.35)
		aim_line.width = 2.0
	else:
		aim_line.default_color = Color(1, 0.2, 0.2, 0.45)
		aim_line.width = 1.0


func _hide_aim() -> void:
	if aim_line:
		aim_line.visible = false


func _shoot_rifle(origin: Vector2) -> void:
	_hide_aim()
	_go(State.FIRE)
	_play("aim_fire_reload", true)
	_spawn_bullet(origin, _aim_dir, rifle_bullet_speed, rifle_damage, 3.0, Color(1, 0.95, 0.5))
	_shake(0.05)


func _fire_logic(dist: float) -> void:
	velocity.x = 0
	if dist < sniper_min_range * 0.8 and t > 0.3:
		_start_drop_flyback()
		return
	if t >= _anim_length(sprite, "aim_fire_reload"):
		_start_aim()


func _reposition_logic(dist: float, dx: float) -> void:
	if not is_aggro:
		_go(State.PATROL)
		return
	var dir = int(sign(dx))
	if dist < 360.0:
		dir = -dir
	if _ledge_ahead(dir) or _wall_ahead(dir):
		dir = -dir
	if _ledge_ahead(dir) or _wall_ahead(dir):
		dir = 0
	velocity.x = dir * speed * 1.6
	if dir != 0:
		_face(float(dir))
	else:
		_face(dx)
	_play("run_fast" if dir != 0 else ("idle_aim" if has_rifle else "pistol_fire"))
	if _sees_player() and t > 0.25:
		_no_los_time = 0.0
		if has_rifle:
			_start_aim()
		else:
			_go(State.PISTOL)
	elif t > 2.2:
		_go(State.PATROL)


func _start_drop_flyback() -> void:
	_hide_aim()
	_go(State.DROP_FLYBACK)
	_play("drop_rifle_flyback", true)
	if has_rifle:
		has_rifle = false
		_drop_rifle()
	velocity = Vector2(-facing_dir * 260.0, -260.0)
	_fly_cooldown = 1.2


func _drop_rifle() -> void:
	var tex = load(RIFLE_TEX)
	if tex == null:
		return
	_rifle_prop = Sprite2D.new()
	_rifle_prop.texture = tex
	_rifle_prop.flip_h = facing_dir < 0
	_rifle_prop.z_index = -1
	get_parent().add_child(_rifle_prop)
	_rifle_prop.global_position = global_position + Vector2(facing_dir * 10.0, 30.0 - tex.get_height() / 2.0)


func _drop_flyback_logic() -> void:
	if _player_ok():
		_face(player.global_position.x - global_position.x)
	velocity.x = move_toward(velocity.x, 0.0, 6.0)
	if t >= _anim_length(sprite, "drop_rifle_flyback") and is_on_floor():
		_go(State.PISTOL)
		_shot_timer = 0.6
		_burst_left = 0
	elif t > 2.0:
		_go(State.PISTOL)


func _pistol_logic(delta: float, dist: float, dx: float) -> void:
	if not is_aggro:
		_go(State.PATROL)
		return
	_face(dx)
	var cornered = _wall_ahead(-facing_dir, 60.0)
	if dist < pistol_keep_min and _fly_cooldown <= 0.0 and not cornered:
		_go(State.FLYBACK)
		_play("flyback", true)
		velocity = Vector2(-facing_dir * 300.0, -230.0)
		_fly_cooldown = 1.4
		return
	if dist > 420.0 and _rifle_prop and is_instance_valid(_rifle_prop) \
			and abs(_rifle_prop.global_position.y - global_position.y) < 60.0:
		_go(State.GET_RIFLE)
		return
	var move = 0
	if dist > pistol_keep_max:
		move = int(sign(dx))
	elif dist < pistol_keep_min + 20.0:
		move = -int(sign(dx))
	if move != 0 and (_ledge_ahead(move) or _wall_ahead(move)):
		move = 0
	if move != 0 and move != facing_dir:
		move = 0
		if is_on_floor() and _backstep(190.0):
			_play("flyback", true)
	if is_on_floor():
		velocity.x = move * speed * 1.4
	_shot_timer -= delta
	if not _sees_player():
		_play("run_fast" if move != 0 else "pistol_fire")
		if sprite and move == 0:
			sprite.pause()
		_no_los_time += delta
		if _no_los_time > 0.8:
			_go(State.REPOSITION)
		return
	_no_los_time = 0.0
	if _shot_timer <= 0.0:
		if _burst_left <= 0 and not _burst_armed:
			_burst_armed = true
			_shot_timer = 0.45
			velocity.x = 0.0
			_play("pistol_fire", true)
			if sprite:
				sprite.pause()
				sprite.frame = 0
			_telegraph(sprite, 0.45, Vector2(14, -36))
			return
		if _burst_left <= 0:
			_burst_armed = false
			_clear_telegraph()
			_burst_left = 2 if cornered else 1
		_burst_left -= 1
		_shot_timer = 0.38 if _burst_left > 0 else randf_range(1.1, 1.5)
		_play("pistol_fire", true)
		var origin = pistol_muzzle.global_position if pistol_muzzle else _eye()
		var lead = global_position.distance_to(player.global_position) / pistol_bullet_speed
		var aim = (_predict_player(lead * 0.2) + Vector2(0, -8) - origin).normalized()
		aim = aim.rotated(randf_range(-0.045, 0.045))
		_spawn_bullet(origin, aim, pistol_bullet_speed, pistol_damage, 1.2, Color(1, 0.8, 0.35), 13.0)
	elif move != 0 and (sprite == null or sprite.animation != "pistol_fire" or not sprite.is_playing()):
		_play("run_fast")


func _flyback_logic() -> void:
	velocity.x = move_toward(velocity.x, 0.0, 5.0)
	if not _fired and t > 0.25 and _sees_player() and randf() < 0.35:
		_fired = true
		var origin = pistol_muzzle.global_position if pistol_muzzle else _eye()
		_spawn_bullet(origin, (_player_center() - origin).normalized().rotated(randf_range(-0.1, 0.1)), pistol_bullet_speed, pistol_damage, 1.2, Color(1, 0.8, 0.35), 13.0)
	elif not _fired and t > 0.25:
		_fired = true
	if is_on_floor() and t > 0.2:
		_go(State.PISTOL)
		_shot_timer = 0.7
	elif t > 2.0:
		_go(State.PISTOL)


func _get_rifle_logic(dist: float) -> void:
	if _rifle_prop == null or not is_instance_valid(_rifle_prop):
		_go(State.PISTOL)
		return
	if dist < pistol_keep_min:
		_go(State.PISTOL)
		return
	var dx = _rifle_prop.global_position.x - global_position.x
	if abs(dx) < 12.0:
		_rifle_prop.queue_free()
		_rifle_prop = null
		has_rifle = true
		velocity.x = 0
		_start_aim()
		return
	var dir = int(sign(dx))
	if _ledge_ahead(dir) or _wall_ahead(dir):
		_go(State.PISTOL)
		return
	_face(dx)
	velocity.x = dir * speed * 1.8
	_play("run_fast")


func _spawn_bullet(origin: Vector2, dir: Vector2, spd: float, dmg: int, life: float, col: Color, hit_r: float = 18.0) -> void:
	var line = Line2D.new()
	line.width = 2.0
	line.default_color = col
	line.z_index = 90
	line.top_level = true
	line.points = PackedVector2Array([Vector2(-14, 0), Vector2.ZERO])
	line.global_position = origin
	line.rotation = dir.angle()
	add_child(line)
	_bullets.append({"node": line, "dir": dir, "speed": spd, "dmg": dmg, "life": life, "r": hit_r})


func _update_bullets(delta: float) -> void:
	var keep: Array = []
	for b in _bullets:
		var n: Line2D = b["node"]
		if not is_instance_valid(n):
			continue
		var from = n.global_position
		var to = from + b["dir"] * b["speed"] * delta
		b["life"] -= delta
		var done = b["life"] <= 0.0
		if not done and _player_ok():
			var c = _player_center()
			var closest = Geometry2D.get_closest_point_to_segment(c, from, to)
			if closest.distance_to(c) < b["r"]:
				done = true
				_hurt_player_smart(b["dmg"])
		if not done:
			var hit = _ray(from, to)
			if not hit.is_empty() and not (hit.collider is Node and hit.collider.is_in_group("player")):
				done = true
		if done:
			n.queue_free()
		else:
			n.global_position = to
			keep.append(b)
	_bullets = keep


func _on_hurt() -> void:
	_hide_aim()
	_clear_telegraph()
	_burst_armed = false
	if _player_ok() and global_position.distance_to(player.global_position) < 120.0 and _fly_cooldown <= 0.0:
		if has_rifle:
			_start_drop_flyback()
		else:
			_go(State.FLYBACK)
			_play("flyback", true)
			velocity = Vector2(-facing_dir * 300.0, -230.0)
			_fly_cooldown = 1.4
		return
	state = State.STUN
	is_stunned = true
	stun_timer = 0.3
	_play("hit", true)


func _on_death() -> void:
	_hide_aim()
	state = State.DEAD
	collision_layer = 0
	if detection_area:
		detection_area.set_deferred("monitoring", false)
	var anim_len := 0.6
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.modulate = Color.WHITE
		_play("death", true)
		anim_len = _anim_length(sprite, "death")
	death_free_delay = anim_len + 1.4
	if sprite:
		var tw = create_tween()
		tw.tween_interval(anim_len + 0.6)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.7)
