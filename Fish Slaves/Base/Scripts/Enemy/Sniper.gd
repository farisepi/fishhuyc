extends CharacterBody2D

signal shot_fired

@export var gravity: float = 980.0
@export var charge_time: float = 1.8
@export var reload_time: float = 2.0
@export var laser_max_width: float = 14.0
@export var laser_min_width: float = 1.5
@export var laser_length: float = 2200.0
@export var damage: int = 1
@export var aim_blink_speed: float = 14.0
@export var start_active: bool = true
@export var bullet_speed: float = 2400.0
@export var bullet_length: float = 26.0
@export var bullet_width: float = 4.0
@export var lock_duration: float = 0.6
@export var lock_blink_speed: float = 40.0
@export var lock_follow_speed: float = 2.5

@onready var sprite: ColorRect = $ColorRect
@onready var aim_line: Line2D = $AimLine
@onready var muzzle: Marker2D = $Muzzle

var player: CharacterBody2D = null
var state: int = 0
var timer: float = 0.0
var active: bool = false
var _dead: bool = false
var _blink_phase: float = 0.0
var _target_dist: float = 0.0

var current_aim_dir: Vector2 = Vector2.RIGHT
var current_aim_origin: Vector2 = Vector2.ZERO
var _slowing: bool = false

var bullet: Line2D = null
var bullet_active: bool = false
var bullet_dir: Vector2 = Vector2.RIGHT
var bullet_origin: Vector2 = Vector2.ZERO
var bullet_traveled: float = 0.0
var bullet_hit_player: bool = false

func _ready():
	add_to_group("snipers")
	print("[Sniper] _ready, pos=", global_position, " start_active=", start_active)
	if aim_line:
		aim_line.visible = false
		aim_line.width = laser_max_width
		aim_line.default_color = Color(1, 0.15, 0.15, 0.85)
		aim_line.z_index = 50
		aim_line.points = PackedVector2Array([Vector2.ZERO, Vector2(laser_length, 0)])

	bullet = Line2D.new()
	bullet.width = bullet_width
	bullet.default_color = Color(1, 0.95, 0.3, 1.0)
	bullet.z_index = 90
	bullet.visible = false
	bullet.points = PackedVector2Array([Vector2(-bullet_length, 0), Vector2.ZERO])
	add_child(bullet)

	if start_active:
		active = true

func activate():
	active = true
	set_process(true)
	print("[Sniper] ACTIVATE")

func deactivate():
	active = false
	state = 0
	timer = 0.0
	_slowing = false
	bullet_active = false
	if aim_line:
		aim_line.visible = false
	if bullet:
		bullet.visible = false
	print("[Sniper] DEACTIVATE")

func _physics_process(delta):
	if _dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
		move_and_slide()

func _process(delta):
	if _dead:
		return

	if bullet_active:
		_update_bullet(delta)

	if not active:
		return

	if player == null or not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			return

	match state:
		0:
			_slowing = false
			_aim_at_player_instant()
			timer += delta
			if timer >= 1.0:
				timer = 0.0
				state = 1
				if aim_line:
					aim_line.visible = true
					aim_line.width = laser_max_width
					aim_line.default_color = Color(1, 0.2, 0.2, 0.5)
		1:
			timer += delta
			var t = clamp(timer / charge_time, 0.0, 1.0)
			var slow_start = max(0.0, charge_time - lock_duration)

			if timer < slow_start:
				# нормальное быстрое слежение
				_slowing = false
				_aim_at_player_instant()
				_blink_phase += delta * aim_blink_speed
				var blink = 0.6 + 0.4 * sin(_blink_phase * TAU)
				if aim_line:
					aim_line.width = lerp(laser_max_width, laser_min_width, t)
					var alpha = lerp(0.45, 1.0, t) * blink
					aim_line.default_color = Color(1, 0.15, 0.15, alpha)
			else:
				# замедленное слежение — прицел ползёт к рыбе
				if not _slowing:
					_slowing = true
					print("[Sniper] 🐢 AIM SLOWING")
				_aim_at_player_slow(delta)
				_blink_phase += delta * lock_blink_speed
				var blink2 = 0.35 + 0.65 * sin(_blink_phase * TAU)
				if aim_line:
					aim_line.width = laser_min_width
					aim_line.default_color = Color(1, 1.0, 1.0, blink2)

			if timer >= charge_time:
				_fire()
		2:
			timer += delta
			if timer >= 0.12:
				timer = 0.0
				state = 3
				_slowing = false
				if aim_line:
					aim_line.visible = false
		3:
			timer += delta
			if timer >= reload_time:
				timer = 0.0
				state = 0

func _aim_at_player_instant():
	if not player or not muzzle or not aim_line:
		return
	var origin = muzzle.global_position
	var target = player.global_position
	var dir = (target - origin).normalized()
	current_aim_origin = origin
	current_aim_dir = dir
	aim_line.global_position = origin
	aim_line.global_rotation = dir.angle()
	var desired_dist = origin.distance_to(target) + 400
	aim_line.points = PackedVector2Array([Vector2.ZERO, Vector2(desired_dist, 0)])

func _aim_at_player_slow(delta):
	if not player or not muzzle or not aim_line:
		return
	var origin = muzzle.global_position
	var target = player.global_position
	var target_dir = (target - origin).normalized()

	# плавно поворачиваем текущее направление к цели
	current_aim_dir = current_aim_dir.lerp(target_dir, lock_follow_speed * delta).normalized()
	current_aim_origin = origin

	aim_line.global_position = origin
	aim_line.global_rotation = current_aim_dir.angle()
	var desired_dist = origin.distance_to(target) + 400
	aim_line.points = PackedVector2Array([Vector2.ZERO, Vector2(desired_dist, 0)])

func _fire():
	state = 2
	timer = 0.0
	shot_fired.emit()

	# стреляем по ТЕКУЩЕМУ направлению прицела, а не по позиции игрока
	var fire_dir = current_aim_dir
	print("[Sniper] >>> FIRE! slowing=", _slowing)

	_compute_hit(fire_dir)

	if muzzle:
		bullet_origin = muzzle.global_position
		bullet_dir = fire_dir
		bullet.global_position = bullet_origin
		bullet.global_rotation = bullet_dir.angle()
		bullet.visible = true
		bullet_traveled = 0.0
		bullet_active = true

func _compute_hit(fire_dir: Vector2):
	if not player or not is_instance_valid(player):
		bullet_hit_player = false
		return
	bullet_hit_player = false

	if player.get("is_blocking") == true:
		return
	if player.get("is_dead") == true:
		return

	var origin = muzzle.global_position
	var to_player = player.global_position - origin
	var dist = to_player.length()

	var projected = to_player.dot(fire_dir)
	if projected < 0.0:
		return
	var perpendicular = (to_player - fire_dir * projected).length()
	if perpendicular <= 22.0 and dist <= laser_length:
		bullet_hit_player = true

func _update_bullet(delta):
	var step = bullet_speed * delta
	bullet_traveled += step
	bullet.global_position = bullet_origin + bullet_dir * bullet_traveled

	if bullet_hit_player and player and is_instance_valid(player):
		var d = bullet.global_position.distance_to(player.global_position)
		if d <= 30.0:
			print("[Sniper] пуля попала в игрока")
			_kill_player()
			_bullet_stop()
			return

	if bullet_traveled >= laser_length:
		_bullet_stop()

func _bullet_stop():
	bullet_active = false
	bullet.visible = false

func _kill_player():
	if player.has_method("die"):
		player.die()
	else:
		get_tree().reload_current_scene()

func die():
	_dead = true
	deactivate()
	queue_free()
