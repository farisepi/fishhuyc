extends CharacterBody2D
class_name StorageEnemy

signal died(shard_color: String)

@export var max_hp: int = 5
@export var speed: float = 110.0
@export var gravity: float = 980.0
@export var shard_color: String = "blue"
@export var shard_scene: PackedScene = preload("res://GameScenes/EntityScenes/ShardEntityScenes/Shard_Entity_Scene.tscn")

@export var aggro_range: float = 380.0
@export var deaggro_range: float = 700.0
@export var min_distance: float = 60.0
@export var patrol_range: float = 180.0
@export var patrol_speed_mult: float = 0.35

var hp: int = 5
var player: CharacterBody2D = null
var is_dead: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0
var facing_dir: int = 1
var can_be_parried: bool = true
var is_aggro: bool = false

var patrol_origin: Vector2 = Vector2.ZERO
var patrol_dir: int = 1
var repath_timer: float = 0.0
var death_free_delay: float = 0.5

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	patrol_origin = global_position

static var _enemy_cache: Array = []
static var _enemy_cache_frame: int = -1

func _enemies() -> Array:
	var f = Engine.get_physics_frames()
	if f != _enemy_cache_frame:
		_enemy_cache_frame = f
		_enemy_cache = get_tree().get_nodes_in_group("enemies")
	return _enemy_cache


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	if repath_timer > 0:
		repath_timer -= delta
	_slide_off_heads()
	if _climb_jump and is_on_floor() and velocity.y >= 0.0:
		_climb_jump = false
	_poise = max(0.0, _poise - delta * POISE_DECAY)
	_hop_cd = max(0.0, _hop_cd - delta)
	_think_t -= delta

func take_damage(amount: int) -> void:
	if is_dead:
		return
	_poise += 1.0
	hp -= amount
	_flash_damage()
	var dir = 1.0
	if player and is_instance_valid(player):
		dir = 1.0 if global_position.x >= player.global_position.x else -1.0
	if hp <= 0:
		_knockback(dir, 34.0, 0.3, 10.0)
		die()
	else:
		_knockback(dir, 12.0, 0.14, 3.0)
		_on_hurt()


func _knockback(dir: float, dist: float, time: float, hop: float) -> void:
	var spr: Node2D = null
	for c in get_children():
		if c is AnimatedSprite2D or c is Sprite2D:
			spr = c
			break
	if spr and hop > 0.0:
		var base_y = spr.position.y
		var ht = create_tween()
		ht.tween_property(spr, "position:y", base_y - hop, time * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ht.tween_property(spr, "position:y", base_y, time * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var moved := 0.0
	var t := 0.0
	while t < time and is_inside_tree():
		await get_tree().physics_frame
		if not is_inside_tree():
			return
		var dt = get_physics_process_delta_time()
		t += dt
		var k = 1.0 - pow(1.0 - clamp(t / time, 0.0, 1.0), 2.0)
		var step = dist * k - moved
		moved += step
		if move_and_collide(Vector2(step * dir, 0.0)):
			return

func _flash_damage() -> void:
	var target = null
	for child in get_children():
		if child is AnimatedSprite2D or child is Sprite2D or child is ColorRect:
			target = child
			break
	if target == null:
		return
	var original = target.modulate
	target.modulate = Color(1, 0.3, 0.3, 1)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(target):
		target.modulate = original

func _on_hurt() -> void:
	pass

func stun(duration: float = 2.0) -> void:
	if is_dead:
		return
	is_stunned = true
	stun_timer = duration

func die() -> void:
	if is_dead:
		return
	is_dead = true
	holding_token = false
	velocity = Vector2.ZERO
	_on_death()
	_drop_shard()
	await get_tree().create_timer(death_free_delay).timeout
	queue_free()

func _on_death() -> void:
	pass

func _drop_shard() -> void:
	if not shard_scene:
		return
	var count = randi_range(1, 5)
	for i in range(count):
		var shard = shard_scene.instantiate()
		shard.shard_color = shard_color
		match shard_color:
			"blue":
				shard.shard_texture = preload("res://GameAssets/Sprites/EntitySprites/EnemySprites/EnemyShardTextures/Shard_MechaDog_Texture.png")
			"green":
				shard.shard_texture = preload("res://GameAssets/Sprites/EntitySprites/EnemySprites/EnemyShardTextures/Shard_MechaMonkey_Texture.png")
			"cyan":
				shard.shard_texture = preload("res://GameAssets/Sprites/EntitySprites/EnemySprites/EnemyShardTextures/Shard_MechaPigeon_Texture.png")
		var offset = Vector2(randf_range(-30, 30), randf_range(-20, 20))
		shard.global_position = global_position + Vector2(0, 15) + offset
		get_tree().current_scene.add_child(shard)
	died.emit(shard_color)

func _update_aggro(dist: float) -> void:
	if not is_aggro:
		if dist <= aggro_range:
			is_aggro = true
	else:
		if dist > deaggro_range:
			is_aggro = false

func _patrol_step(_delta: float) -> void:
	velocity.x = patrol_dir * speed * patrol_speed_mult
	if global_position.x > patrol_origin.x + patrol_range:
		patrol_dir = -1
	elif global_position.x < patrol_origin.x - patrol_range:
		patrol_dir = 1
	facing_dir = patrol_dir
	move_and_slide()

func _clamp_facing_to_player() -> void:
	if player == null:
		return
	var dir = sign(player.global_position.x - global_position.x)
	if dir != 0:
		facing_dir = dir

func _is_player_in_attack_zone(reach: float, height: float = 80.0) -> bool:
	if player == null:
		return false
	var dx = player.global_position.x - global_position.x
	var dy = player.global_position.y - global_position.y
	if abs(dy) > height:
		return false
	if facing_dir > 0:
		return dx >= -10.0 and dx <= reach
	else:
		return dx <= 10.0 and dx >= -reach

func _is_player_too_close(threshold: float) -> bool:
	if player == null:
		return false
	return abs(player.global_position.x - global_position.x) < threshold and abs(player.global_position.y - global_position.y) < 70.0

func _hurt_player(amount: int) -> void:
	if player == null:
		return
	if player.get("is_dashing") == true:
		return
	if player.has_method("take_damage"):
		player.take_damage(amount, self)


const FUR_SHADER_PATH := "res://GameShaders/SharedShaders/Shared_FurPalette_Shader.gdshader"
const MAX_ATTACK_TOKENS: int = 2
const WORLD_MASK: int = 1

@export var fur_variant: int = -1

var holding_token: bool = false
var _base_sprite_offset: Vector2 = Vector2.ZERO
var _player_prev_x: float = 0.0
var _player_vel: Vector2 = Vector2.ZERO
var _player_was_attacking: bool = false
var player_block_habit: float = 0.0
var player_parry_habit: float = 0.0
var player_dash_habit: float = 0.0
var _whiff_window: float = 0.0


func apply_fur_variant(spr: CanvasItem, source: Array, variants: Array) -> void:
	if spr == null or source.is_empty() or variants.is_empty():
		return
	var v = fur_variant
	if v < 0:
		v = randi() % (variants.size() + 1)
	if v == 0 or v > variants.size():
		return
	var shader = load(FUR_SHADER_PATH)
	if shader == null:
		return
	var target: Array = variants[v - 1]
	var mat = ShaderMaterial.new()
	mat.shader = shader
	for i in range(min(6, source.size())):
		mat.set_shader_parameter("src%d" % i, source[i])
		mat.set_shader_parameter("dst%d" % i, target[i] if i < target.size() else source[i])
	spr.material = mat


func _player_ok() -> bool:
	return player != null and is_instance_valid(player) and not player.is_queued_for_deletion() and not bool(player.get("is_dead"))


func _player_flag(flag: String) -> bool:
	return _player_ok() and bool(player.get(flag))


func _observe_player(delta: float) -> void:
	if not _player_ok() or delta <= 0.0:
		return
	var pos = player.global_position
	if _player_prev_x == 0.0:
		_player_prev_x = pos.x
	var vx = clamp((pos.x - _player_prev_x) / delta, -900.0, 900.0)
	_player_vel = _player_vel.lerp(Vector2(vx, 0.0), 0.25)
	_player_prev_x = pos.x
	var near = global_position.distance_to(pos) < 260.0
	if near:
		player_block_habit = lerp(player_block_habit, 1.0 if _player_flag("is_blocking") else 0.0, delta * 0.6)
		player_parry_habit = lerp(player_parry_habit, 1.0 if _player_flag("is_parrying") else 0.0, delta * 0.6)
		player_dash_habit = lerp(player_dash_habit, 1.0 if _player_flag("is_dashing") else 0.0, delta * 0.8)
	var atk = _player_flag("is_attacking")
	if _player_was_attacking and not atk:
		_whiff_window = 0.45
	_player_was_attacking = atk
	if _whiff_window > 0.0:
		_whiff_window -= delta


func _predict_player(t: float) -> Vector2:
	if not _player_ok():
		return global_position
	return player.global_position + _player_vel * t


func _player_threatens(reach: float = 95.0) -> bool:
	if not _player_flag("is_attacking"):
		return false
	var dx = global_position.x - player.global_position.x
	var pf = int(player.get("facing_direction")) if player.get("facing_direction") != null else 1
	return abs(dx) < reach and sign(dx) == sign(pf) and abs(global_position.y - player.global_position.y) < 60.0


func _alert_allies(radius: float = 520.0) -> void:
	if not _player_ok():
		return
	for e in _enemies():
		if e == self or not is_instance_valid(e):
			continue
		if e.global_position.distance_to(global_position) > radius:
			continue
		if e.has_method("hear_alert"):
			e.hear_alert(player)


func hear_alert(p: Node) -> void:
	if is_dead or is_aggro or p == null:
		return
	player = p
	is_aggro = true


func _request_token() -> bool:
	if holding_token:
		return true
	var used := 0
	for e in _enemies():
		if e != self and is_instance_valid(e) and bool(e.get("holding_token")) and not bool(e.get("is_dead")):
			used += 1
	if used >= MAX_ATTACK_TOKENS:
		return false
	holding_token = true
	return true


func _release_token() -> void:
	holding_token = false


func _separation(radius: float = 42.0) -> float:
	var push := 0.0
	for e in _enemies():
		if e == self or not is_instance_valid(e) or bool(e.get("is_dead")):
			continue
		var d = global_position.x - e.global_position.x
		if abs(d) < radius and abs(global_position.y - e.global_position.y) < 40.0:
			push += sign(d if d != 0.0 else randf() - 0.5) * (radius - abs(d)) / radius
	return push


func _ray(from: Vector2, to: Vector2) -> Dictionary:
	var q = PhysicsRayQueryParameters2D.create(from, to, WORLD_MASK)
	q.exclude = [get_rid()]
	q.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(q)


func _ledge_ahead(dir: int, ahead: float = 28.0, depth: float = 70.0) -> bool:
	if not is_on_floor():
		return false
	var from = global_position + Vector2(dir * ahead, 0)
	return _ray(from, from + Vector2(0, depth)).is_empty()


func _wall_ahead(dir: int, ahead: float = 34.0) -> bool:
	var from = global_position + Vector2(0, -6)
	return not _ray(from, from + Vector2(dir * ahead, 0)).is_empty()


func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var d = to - from
	if d.length() > 36.0:
		to = from + d - d.normalized() * 30.0
	return _ray(from, to).is_empty()


func _hurt_player_smart(amount: int) -> bool:
	if not _player_ok():
		return false
	if _player_flag("is_dashing") or _player_flag("is_parrying"):
		return false
	if _player_flag("is_blocking"):
		var pf = int(player.get("facing_direction")) if player.get("facing_direction") != null else 1
		var from_behind = sign(global_position.x - player.global_position.x) != sign(pf)
		if from_behind and player.has_method("_set_blocking"):
			player._set_blocking(false)
	if player.has_method("take_damage"):
		player.take_damage(amount, self)
	return true


func _shake(amount: float) -> void:
	if not _player_ok():
		return
	for c in player.get_children():
		if c is Camera2D and c.has_method("add_trauma"):
			c.add_trauma(amount)
			return


func _play_on(spr: AnimatedSprite2D, anim_name: String, extra_offset: Vector2 = Vector2.ZERO, restart: bool = false) -> void:
	if spr == null or spr.sprite_frames == null or not spr.sprite_frames.has_animation(anim_name):
		return
	if spr.animation != anim_name or restart or not spr.is_playing():
		spr.play(anim_name)
	var tex = spr.sprite_frames.get_frame_texture(anim_name, 0)
	var h: float = float(tex.get_height()) if tex else 75.0
	spr.offset = _base_sprite_offset + extra_offset + Vector2(0, -(h - 75.0) / 2.0)


func _anim_length(spr: AnimatedSprite2D, anim_name: String) -> float:
	if spr == null or spr.sprite_frames == null or not spr.sprite_frames.has_animation(anim_name):
		return 0.3
	var spd = max(spr.sprite_frames.get_animation_speed(anim_name), 0.01)
	var total := 0.0
	for i in range(spr.sprite_frames.get_frame_count(anim_name)):
		total += spr.sprite_frames.get_frame_duration(anim_name, i)
	return total / spd


const ESFX_DIR := "res://GameAssets/Audio/SoundEffects/EnemySounds/EnemyAttackSounds/"
const POISE_DECAY := 0.7
const POISE_BREAK := 2.6

var _poise: float = 0.0
var _hop_cd: float = 0.0
var _think_t: float = 0.0
var _turn_hold: float = 0.0
var _tele_tw: Tween = null
var _tele_spr: CanvasItem = null
static var _esfx_cache: Dictionary = {}


func _esfx(file: String, vol: float = -6.0, pitch: float = 1.0) -> void:
	var st = _esfx_cache.get(file)
	if st == null:
		st = load(ESFX_DIR + file)
		_esfx_cache[file] = st
	if st == null or not is_inside_tree():
		return
	var p = AudioStreamPlayer2D.new()
	p.stream = st
	p.volume_db = vol
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.max_distance = 1400.0
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _telegraph(spr: CanvasItem, dur: float, head: Vector2 = Vector2(0, -44)) -> void:
	if spr == null:
		return
	_clear_telegraph()
	_tele_spr = spr
	spr.self_modulate = Color.WHITE
	_tele_tw = create_tween()
	_tele_tw.tween_property(spr, "self_modulate", Color(2.1, 1.7, 1.25), max(0.05, dur * 0.4)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tele_tw.tween_property(spr, "self_modulate", Color(1.35, 1.2, 1.05), max(0.05, dur * 0.6))
	_glint(head)
	_esfx("Enemy_Windup_SoundEffect.wav", -9.0, 1.0 + randf_range(-0.05, 0.05))


func _clear_telegraph() -> void:
	if _tele_tw and _tele_tw.is_valid():
		_tele_tw.kill()
	_tele_tw = null
	if _tele_spr and is_instance_valid(_tele_spr):
		_tele_spr.self_modulate = Color.WHITE
	_tele_spr = null


func _glint(at: Vector2) -> void:
	var g = Node2D.new()
	g.z_index = 60
	g.position = Vector2(at.x * facing_dir, at.y)
	add_child(g)
	g.draw.connect(func():
		var c = Color(1.0, 0.92, 0.55)
		g.draw_rect(Rect2(-1, -7, 2, 14), c)
		g.draw_rect(Rect2(-7, -1, 14, 2), c)
		g.draw_rect(Rect2(-2, -2, 4, 4), Color(1, 1, 1)))
	g.scale = Vector2(0.2, 0.2)
	var tw = g.create_tween()
	tw.tween_property(g, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(g, "scale", Vector2(0.6, 0.6), 0.16)
	tw.parallel().tween_property(g, "modulate:a", 0.0, 0.16)
	tw.tween_callback(g.queue_free)


func _turn_to(dx: float, delta: float, delay: float = 0.14) -> void:
	if abs(dx) < 6.0:
		_turn_hold = 0.0
		return
	var want = 1 if dx > 0.0 else -1
	if want == facing_dir:
		_turn_hold = 0.0
		return
	_turn_hold += delta
	if _turn_hold >= delay:
		facing_dir = want
		_turn_hold = 0.0


func _backstep(power: float = 230.0) -> bool:
	if _hop_cd > 0.0 or not is_on_floor():
		return false
	if _ledge_ahead(-facing_dir, 50.0) or _wall_ahead(-facing_dir, 50.0):
		return false
	_hop_cd = 0.9
	velocity.x = -facing_dir * power
	velocity.y = -150.0
	return true


func _poise_broken() -> bool:
	if _poise >= POISE_BREAK:
		_poise = 0.0
		return true
	return false


func _dust_puff(at: Vector2, n: int = 4) -> void:
	var parent = get_parent()
	if parent == null:
		return
	for i in range(n):
		var d = ColorRect.new()
		d.size = Vector2(3, 3)
		d.color = Color(0.75, 0.72, 0.68, 0.8)
		d.z_index = 40
		parent.add_child(d)
		d.global_position = at + Vector2(randf_range(-10, 10), randf_range(-3, 1))
		var tw = d.create_tween()
		tw.tween_property(d, "global_position", d.global_position + Vector2(randf_range(-26, 26), randf_range(-14, -4)), 0.35).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(d, "modulate:a", 0.0, 0.35)
		tw.tween_callback(d.queue_free)


func _hop_over(dir: int, speed_x: float, max_h: float = 110.0) -> bool:
	if dir == 0 or not is_on_floor() or not _wall_ahead(dir):
		return false
	var h := 0.0
	var clear_at := -1.0
	while h <= max_h:
		h += 16.0
		var from = global_position + Vector2(0, -6.0 - h)
		if _ray(from, from + Vector2(dir * 40.0, 0)).is_empty():
			clear_at = h
			break
	if clear_at < 0.0:
		return false
	if not _ray(global_position + Vector2(0, -20), global_position + Vector2(0, -40.0 - clear_at)).is_empty():
		return false
	_climb_jump = true
	velocity.y = -sqrt(2.0 * gravity * (clear_at + 26.0))
	velocity.x = dir * max(speed_x, 140.0)
	_dust_puff(global_position + Vector2(0, 30), 3)
	return true


var _on_head: bool = false
var _climb_jump: bool = false

func _slide_off_heads() -> void:
	_on_head = false
	for i in range(get_slide_collision_count()):
		var c = get_slide_collision(i)
		var o = c.get_collider()
		if o is Node and (o.is_in_group("player") or o.is_in_group("enemies")) and c.get_normal().y < -0.5:
			var away = sign(global_position.x - o.global_position.x)
			if away == 0:
				away = -facing_dir
			velocity.x = away * 240.0
			velocity.y = -140.0
			_on_head = true
			return
