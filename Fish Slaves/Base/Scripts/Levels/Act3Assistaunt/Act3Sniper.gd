extends CharacterBody2D

@export var detection_range: float = 600.0
@export var aim_duration: float = 2.5
@export var shoot_delay: float = 1.0
@export var reload_time: float = 2.0
@export var damage: int = 50

var player: CharacterBody2D = null
var is_aiming: bool = false
var is_shooting: bool = false
var is_reloading: bool = false
var is_active: bool = true
var is_triggered: bool = false

var aim_timer: float = 0.0
var shoot_timer: float = 0.0
var reload_timer: float = 0.0

@onready var laser_line: Line2D = $LaserLine
@onready var visual_rect: ColorRect = $ColorRect

func _ready():
	laser_line.visible = false
	if visual_rect:
		visual_rect.color = Color(0.3, 0.3, 0.3, 1)
	
	var check_timer = Timer.new()
	check_timer.wait_time = 0.3
	check_timer.autostart = true
	check_timer.timeout.connect(_check_player)
	add_child(check_timer)

func _check_player():
	if not is_active:
		return
	
	if is_triggered:
		return
	
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			print("🎯 СНАЙПЕР НАШЁЛ ИГРОКА!")
			_start_aiming()
		return
	
	if player.is_in_group("in_tight_passage"):
		return
	
	if not is_aiming and not is_shooting and not is_reloading:
		_start_aiming()

func _start_aiming():
	if is_aiming or is_shooting or is_reloading:
		return
	if not is_active:
		return
	
	print("🔴 СНАЙПЕР ПРИЦЕЛИВАЕТСЯ!")
	is_aiming = true
	aim_timer = 0.0
	laser_line.visible = true
	laser_line.modulate = Color(1, 1, 1, 1)
	
	if visual_rect:
		visual_rect.color = Color(1, 0.8, 0.2, 1)
	
	laser_line.width = 10
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(laser_line, "width", 2.0, aim_duration)
	
	set_process(true)

func _process(delta):
	if not is_active or not player:
		return
	
	if laser_line.visible:
		var start = global_position
		var end = player.global_position + Vector2(0, -20)
		laser_line.points = [start, end]
	
	if is_aiming:
		aim_timer += delta
		if aim_timer >= aim_duration:
			_on_aim_timeout()
	
	if is_shooting:
		shoot_timer += delta
		if shoot_timer >= shoot_delay:
			_shoot()
	
	if is_reloading:
		reload_timer += delta
		if reload_timer >= reload_time:
			_on_reload_finished()

func _on_aim_timeout():
	print("🔴 ЛАЗЕР СТАЛ КРАСНЫМ! СЕЙЧАС БУДЕТ ВЫСТРЕЛ!")
	is_aiming = false
	is_shooting = true
	shoot_timer = 0.0
	
	if visual_rect:
		visual_rect.color = Color(1, 0, 0, 1)
	
	laser_line.modulate = Color(1, 0, 0, 1)
	
	var blink_tween = create_tween()
	blink_tween.set_loops(4)
	blink_tween.tween_property(laser_line, "modulate:a", 0.0, 0.15)
	blink_tween.tween_property(laser_line, "modulate:a", 1.0, 0.15)

func _shoot():
	print("💥 ВЫСТРЕЛ!")
	is_shooting = false
	
	if player and player.has_method("is_blocking") and player.is_blocking():
		print("🛡️ ИГРОК ЗАБЛОКИРОВАЛ ВЫСТРЕЛ!")
		_start_reload()
		return
	
	if player and player.has_method("take_damage"):
		player.take_damage(damage)
		print("💔 ИГРОК ПОЛУЧИЛ УРОН: ", damage)
		
		if player.hp <= 0:
			player.die()
			return
	
	_start_reload()

func _start_reload():
	print("🔄 ПЕРЕЗАРЯДКА...")
	is_reloading = true
	reload_timer = 0.0
	laser_line.visible = false
	
	if visual_rect:
		visual_rect.color = Color(0.2, 0.2, 0.5, 1)

func _on_reload_finished():
	print("🔄 ПЕРЕЗАРЯДКА ЗАВЕРШЕНА!")
	is_reloading = false
	
	if player and not player.is_in_group("in_tight_passage") and is_active:
		_start_aiming()

# ВЫЗЫВАЕТСЯ, КОГДА ИГРОК В МИНИ-ИГРЕ (PAUSE)
func pause_sniper():
	is_active = false
	laser_line.visible = false
	is_aiming = false
	is_shooting = false
	is_reloading = false
	aim_timer = 0.0
	shoot_timer = 0.0
	reload_timer = 0.0
	
	if visual_rect:
		visual_rect.color = Color(0.3, 0.3, 0.3, 1)

# ВЫЗЫВАЕТСЯ, КОГДА ИГРОК ВЫШЕЛ ИЗ МИНИ-ИГРЫ
func resume_sniper():
	if is_active:
		return
	is_active = true
	if player and not player.is_in_group("in_tight_passage"):
		_start_aiming()

# ВЫЗЫВАЕТСЯ, КОГДА ПОГРУЗЧИК ВЗОРВАЛСЯ (ШИФТ)
func disable_sniper():
	print("🔴 СНАЙПЕР ОТКЛЮЧЁН!")
	is_active = false
	is_triggered = true
	laser_line.visible = false
	is_aiming = false
	is_shooting = false
	is_reloading = false
	
	if visual_rect:
		visual_rect.color = Color(0.3, 0.3, 0.3, 1)
	
	# УДАЛЯЕМ СНАЙПЕРА ЧЕРЕЗ 2 СЕКУНДЫ
	await get_tree().create_timer(2.0).timeout
	queue_free()
