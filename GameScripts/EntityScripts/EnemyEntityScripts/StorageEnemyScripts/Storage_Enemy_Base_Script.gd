extends CharacterBody2D
class_name StorageEnemy

signal died(shard_color: String)

@export var max_hp: int = 3
@export var speed: float = 120.0
@export var gravity: float = 980.0
@export var shard_color: String = "blue"
@export var shard_scene: PackedScene = preload("res://GameScenes/EntityScenes/ShardEntityScenes/Shard_Entity_Scene.tscn")

var hp: int = 3
var player: CharacterBody2D = null
var is_dead: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0
var facing_dir: int = 1
var can_be_parried: bool = true

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta

func take_damage(amount: int) -> void:
	if is_dead:
		return
	hp -= amount
	_flash_damage()
	if hp <= 0:
		die()
	else:
		_on_hurt()

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
	_on_death()
	_drop_shard()
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_death() -> void:
	pass

func _drop_shard() -> void:
	if not shard_scene:
		return
	var shard = shard_scene.instantiate()
	shard.shard_color = shard_color
	match shard_color:
		"blue":
			shard.shard_texture = preload("res://GameAssets/Sprites/EntitySprites/EnemySprites/EnemyShardTextures/Shard_MechaDog_Texture.png")
		"green":
			shard.shard_texture = preload("res://GameAssets/Sprites/EntitySprites/EnemySprites/EnemyShardTextures/Shard_MechaMonkey_Texture.png")
		"cyan":
			shard.shard_texture = preload("res://GameAssets/Sprites/EntitySprites/EnemySprites/EnemyShardTextures/Shard_MechaPigeon_Texture.png")
	shard.global_position = global_position + Vector2(0, -20)
	get_tree().current_scene.add_child(shard)
	died.emit(shard_color)
