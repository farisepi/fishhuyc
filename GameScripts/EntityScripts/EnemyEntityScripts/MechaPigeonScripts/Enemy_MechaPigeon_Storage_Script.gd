extends StorageEnemy

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aim_line: Line2D = $AimLine
@onready var muzzle: Marker2D = $Muzzle
@onready var pistol_muzzle: Marker2D = $PistolMuzzle
@onready var detection_area: Area2D = $DetectionArea

enum State { PATROL, ALERT, AIM, FIRE, RELOAD, FLYBACK, PISTOL, RETREAT, STUN, DEAD }
var state: State = State.PATROL
var timer: float = 0.0
var cooldown_timer: float = 0.0
var fire_range: float = 800.0
var close_range: float = 200.0
var aim_time: float = 1.2
var reload_time: float = 1.5
var alert_timer: float = 0.0
var alert_duration: float = 0.3
var retreat_range: float = 400.0
var current_aim_dir: Vector2 = Vector2.RIGHT
var bullet_active: bool = false
var bullet_dir: Vector2 = Vector2.RIGHT
var bullet_origin: Vector2 = Vector2.ZERO
var bullet_traveled: float = 0.0
var bullet_speed: float = 2500.0
var bullet_max: float = 2000.0
var bullet: Line2D = null

func _ready() -> void:
	super._ready()
	shard_color = "cyan"
	max_hp = 5
	hp = 5
	can_be_parried = false
	aggro_range = 800.0
	deaggro_range = 1200.0
	if detection_area:
		detection_area.body_entered.connect(func(b):
			if b.is_in_group("player") and player == null:
				player = b
		)
	if aim_line:
		aim_line.visible = false
	bullet = Line2D.new()
	bullet.width = 3
	bullet.default_color = Color(1, 0.95, 0.3, 1)
	bullet.z_index = 90
	bullet.visible = false
	bullet.points = PackedVector2Array([Vector2(-16, 0), Vector2.ZERO])
	add_child(bullet)
	_play_anim("idle_aim")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	super._physics_process(delta)
	if bullet_active:
		_update_bullet(delta)

	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			state = State.PATROL if not is_aggro else State.AIM
		velocity.x = 0
		move_and_slide()
		return

	if cooldown_timer > 0:
		cooldown_timer -= delta

	if player == null:
		_find_player()

	var dist = 99999.0
	if player != null:
		dist = global_position.distance_to(player.global_position)
		_update_aggro(dist)

	if sprite:
		sprite.scale.x = abs(sprite.scale.x) * (1 if facing_dir > 0 else -1)

	match state:
		State.PATROL:
			_play_anim("idle_aim")
			velocity.x = 0
			if is_aggro:
				state = State.ALERT
				alert_timer = 0.0
		State.ALERT:
			alert_timer += delta
			_clamp_facing_to_player()
			if alert_timer >= alert_duration:
				state = State.AIM
				timer = 0.0
				if aim_line:
					aim_line.visible = true
		State.AIM:
			timer += delta
			_aim_at_player()
			if dist < close_range:
				state = State.FLYBACK
				timer = 0.0
				if aim_line:
					aim_line.visible = false
				_play_anim("drop_rifle_flyback")
			elif timer >= aim_time:
				_fire()
		State.FIRE:
			timer += delta
			if timer >= 0.15:
				state = State.RELOAD
				timer = 0.0
				_play_anim("reload")
		State.RELOAD:
			timer += delta
			if timer >= reload_time:
				if dist < close_range:
					state = State.FLYBACK
					timer = 0.0
					_play_anim("drop_rifle_flyback")
				else:
					state = State.AIM
					timer = 0.0
					if aim_line:
						aim_line.visible = true
		State.FLYBACK:
			timer += delta
			velocity.x = -facing_dir * 220.0
			move_and_slide()
			if timer >= 0.6:
				state = State.PISTOL
				timer = 0.0
				velocity.x = 0
				_play_anim("pistol_fire")
				_fire_pistol()
		State.PISTOL:
			timer += delta
			if timer >= 1.0:
				if dist > retreat_range:
					state = State.AIM
					timer = 0.0
					if aim_line:
						aim_line.visible = true
				else:
					state = State.RETREAT
					timer = 0.0
		State.RETREAT:
			velocity.x = -facing_dir * speed
			_play_anim("run_fast")
			timer += delta
			if dist > retreat_range or timer >= 1.5:
				state = State.AIM
				timer = 0.0
				if aim_line:
					aim_line.visible = true
	move_and_slide()

func _aim_at_player() -> void:
	if not player or not muzzle or not aim_line:
		return
	var origin = muzzle.global_position
	var target = player.global_position
	var dir = (target - origin).normalized()
	current_aim_dir = dir
	aim_line.global_position = origin
	aim_line.global_rotation = dir.angle()
	aim_line.points = PackedVector2Array([Vector2.ZERO, Vector2(bullet_max, 0)])

func _fire() -> void:
	state = State.FIRE
	timer = 0.0
	if aim_line:
		aim_line.visible = false
	_play_anim("aim_fire_reload")
	if not muzzle:
		return
	var origin = muzzle.global_position
	bullet_origin = origin
	bullet_dir = current_aim_dir
	bullet.global_position = origin
	bullet.global_rotation = bullet_dir.angle()
	bullet.visible = true
	bullet_traveled = 0.0
	bullet_active = true

func _fire_pistol() -> void:
	if not player or not pistol_muzzle:
		return
	var origin = pistol_muzzle.global_position
	if player.global_position.distance_to(origin) < 400.0:
		if player.has_method("take_damage"):
			player.take_damage(1)

func _update_bullet(delta: float) -> void:
	var step = bullet_speed * delta
	bullet_traveled += step
	bullet.global_position = bullet_origin + bullet_dir * bullet_traveled
	if player and is_instance_valid(player):
		var d = bullet.global_position.distance_to(player.global_position)
		if d <= 24.0:
			if player.get("is_dashing") != true:
				if player.has_method("take_damage"):
					player.take_damage(1)
			_bullet_stop()
			return
	if bullet_traveled >= bullet_max:
		_bullet_stop()

func _bullet_stop() -> void:
	bullet_active = false
	if bullet:
		bullet.visible = false

func _play_anim(name: String) -> void:
	if not sprite:
		return
	if not sprite.sprite_frames:
		return
	if sprite.sprite_frames.has_animation(name):
		if sprite.animation != name:
			sprite.play(name)

func _on_hurt() -> void:
	_play_anim("hit")
	state = State.STUN
	is_stunned = true
	stun_timer = 0.4
	if aim_line:
		aim_line.visible = false

func _on_death() -> void:
	_play_anim("death")
	state = State.DEAD
	if aim_line:
		aim_line.visible = false
	_bullet_stop()
