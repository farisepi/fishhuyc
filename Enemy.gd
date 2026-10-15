extends CharacterBody2D

@export var speed: float = 120.0
@export var gravity: float = 980.0
@export var stun_duration: float = 2.0

var player: CharacterBody2D = null
var is_stunned: bool = false
var stun_timer: float = 0.0
var is_dead: bool = false
var original_color: Color = Color(1, 0, 0, 1)

@onready var sprite: ColorRect = $ColorRect
@onready var detection_area: Area2D = $DetectionArea

func _ready():
	add_to_group("enemies")
	if sprite:
		original_color = sprite.color
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
	else:
		print("❌ DetectionArea не найден! Создай его в сцене врага.")

func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("player") and not is_stunned and not is_dead:
		print("🔴 ВРАГ КОСНУЛСЯ ИГРОКА!")
		if body.has_method("die"):
			body.die()

func _physics_process(delta):
	if is_dead:
		return
	
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			if sprite:
				sprite.color = original_color
		return
	
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var dir = sign(player.global_position.x - global_position.x)
	velocity.x = dir * speed
	
	move_and_slide()

func stun():
	if is_stunned or is_dead:
		return
	is_stunned = true
	stun_timer = stun_duration
	if sprite:
		sprite.color = Color(0.2, 0.5, 1.0, 1)
