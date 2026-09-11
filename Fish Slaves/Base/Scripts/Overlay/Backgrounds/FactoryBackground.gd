extends Node2D

@export var layer3_speed: float = 30.0
@export var box_scene: PackedScene = preload("res://Fish Slaves/Base/Scenes/Overlay/Effects/Box.tscn")
@export var box_spawn_interval: float = 3.0
@export var box_spawn_chance: float = 0.75
@export var box_spawn_position: Vector2 = Vector2(1393.0, 405.0)

@onready var layer3: Sprite2D = $Layer3
@onready var layer3_clone: Sprite2D = $Layer3Clone
@onready var layer3_clone2: Sprite2D = $Layer3Clone2

var layer_width: float = 0.0
var start_x: float = 576.0
var spawn_timer: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	
	print("FactoryBackground ready")
	print("box_scene = ", box_scene)
	print("layer3 = ", layer3)
	
	if not layer3 or not layer3_clone or not layer3_clone2 or not layer3.texture:
		print("FactoryBackground: отсутствуют ноды или текстура!")
		return
	
	layer_width = layer3.texture.get_width() * abs(layer3.scale.x)
	start_x = layer3.position.x
	
	print("FactoryBackground: layer_width = ", layer_width)
	print("FactoryBackground: start_x = ", start_x)
	
	layer3_clone.position.x = start_x + layer_width
	layer3_clone2.position.x = start_x + layer_width * 2.0
	
	spawn_timer = box_spawn_interval

func _process(delta: float) -> void:
	if layer_width <= 0.0:
		return
	
	var move = layer3_speed * delta
	for spr in [layer3, layer3_clone, layer3_clone2]:
		if not spr:
			continue
		spr.position.x -= move
		if spr.position.x <= start_x - layer_width:
			spr.position.x += layer_width * 3.0
	
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = box_spawn_interval
		if rng.randf() < box_spawn_chance:
			_spawn_box()

func _spawn_box() -> void:
	if not box_scene:
		print("box_scene is NULL")
		return
	
	var box = box_scene.instantiate()
	add_child(box)
	
	box.global_position = to_global(box_spawn_position)
	box.rotation = rng.randf_range(-0.2, 0.2)
	box.conveyor_speed = layer3_speed
	
	print("Box spawned at ", box.global_position)
