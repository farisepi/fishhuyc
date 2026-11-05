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
## How long the body stays on screen after death (subclasses with a death animation raise it).
var death_free_delay: float = 0.5

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	patrol_origin = global_position

## All enemies, fetched once per physics frame and shared by every enemy (separation,
## attack tokens and alerts used to build this list several times per enemy per frame).
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

func take_damage(amount: int) -> void:
	if is_dead:
		return
	hp -= amount
	_flash_damage()
	# pushed away from the player: a little on a hit, more when it is the killing blow
	var dir = 1.0
	if player and is_instance_valid(player):
		dir = 1.0 if global_position.x >= player.global_position.x else -1.0
	if hp <= 0:
		_knockback(dir, 34.0, 0.3, 10.0)
		die()
	else:
		_knockback(dir, 12.0, 0.14, 3.0)
		_on_hurt()


## Slides the body `dist` px sideways (stops at walls) and hops the sprites a bit.
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
		# fast at first, then easing out
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


# =====================================================================
#  "Smart enemy" toolkit shared by the storage dog / monkey / pigeon.
#  Everything below is additive: older enemies that extend this class keep working.
# =====================================================================

const FUR_SHADER_PATH := "res://GameShaders/SharedShaders/Shared_FurPalette_Shader.gdshader"
## Max melee enemies that may attack the player at the same time (the rest wait / circle).
const MAX_ATTACK_TOKENS: int = 2
const WORLD_MASK: int = 1

## -1 = random fur colour variant, 0 = the colours drawn in the sheet, 1.. = recoloured variants.
@export var fur_variant: int = -1

var holding_token: bool = false
var _base_sprite_offset: Vector2 = Vector2.ZERO
var _player_prev_x: float = 0.0
var _player_vel: Vector2 = Vector2.ZERO
var _player_was_attacking: bool = false
## Short memory of what the player tends to do - enemies adapt to it.
var player_block_habit: float = 0.0
var player_parry_habit: float = 0.0
var player_dash_habit: float = 0.0
var _whiff_window: float = 0.0


## --- fur colour variants -----------------------------------------------------------
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


## --- player reading ----------------------------------------------------------------
func _player_ok() -> bool:
	return player != null and is_instance_valid(player) and not player.is_queued_for_deletion() and not bool(player.get("is_dead"))


func _player_flag(flag: String) -> bool:
	return _player_ok() and bool(player.get(flag))


## Call every physics frame: velocity estimate + habits + "the player just whiffed" window.
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
		_whiff_window = 0.45   # the player's swing just ended: punish now
	_player_was_attacking = atk
	if _whiff_window > 0.0:
		_whiff_window -= delta


func _predict_player(t: float) -> Vector2:
	if not _player_ok():
		return global_position
	return player.global_position + _player_vel * t


## True when the player is swinging toward us and close enough to land it.
func _player_threatens(reach: float = 95.0) -> bool:
	if not _player_flag("is_attacking"):
		return false
	var dx = global_position.x - player.global_position.x
	var pf = int(player.get("facing_direction")) if player.get("facing_direction") != null else 1
	return abs(dx) < reach and sign(dx) == sign(pf) and abs(global_position.y - player.global_position.y) < 60.0


## --- squad -------------------------------------------------------------------------
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


## Another enemy spotted the player and shouted.
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


## Pushes enemies apart so they do not stack into one blob.
func _separation(radius: float = 42.0) -> float:
	var push := 0.0
	for e in _enemies():
		if e == self or not is_instance_valid(e) or bool(e.get("is_dead")):
			continue
		var d = global_position.x - e.global_position.x
		if abs(d) < radius and abs(global_position.y - e.global_position.y) < 40.0:
			push += sign(d if d != 0.0 else randf() - 0.5) * (radius - abs(d)) / radius
	return push


## --- world queries -----------------------------------------------------------------
func _ray(from: Vector2, to: Vector2) -> Dictionary:
	var q = PhysicsRayQueryParameters2D.create(from, to, WORLD_MASK)
	q.exclude = [get_rid()]
	q.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(q)


## No floor a little in front of us (in direction dir)?
func _ledge_ahead(dir: int, ahead: float = 28.0, depth: float = 70.0) -> bool:
	if not is_on_floor():
		return false
	var from = global_position + Vector2(dir * ahead, 0)
	return _ray(from, from + Vector2(0, depth)).is_empty()


func _wall_ahead(dir: int, ahead: float = 34.0) -> bool:
	var from = global_position + Vector2(0, -6)
	return not _ray(from, from + Vector2(dir * ahead, 0)).is_empty()


func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	# stop short of the target so the target's own body does not count as a wall
	var d = to - from
	if d.length() > 36.0:
		to = from + d - d.normalized() * 30.0
	return _ray(from, to).is_empty()


## --- damage helpers ----------------------------------------------------------------
## Hits from behind go through the player's block (smart enemies flank).
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


## --- animation helpers -------------------------------------------------------------
## Plays an animation and keeps the feet on the floor for frames that are taller than 75 px.
## extra_offset is in sprite space (it flips together with the sprite).
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
