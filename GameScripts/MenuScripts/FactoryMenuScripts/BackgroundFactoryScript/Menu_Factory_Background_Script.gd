extends Node2D

@export var layer3_speed: float = 30.0
@export var box_scene: PackedScene = preload("res://GameScenes/LevelScenes/ActPrologueLevelScenes/FactoryLevelScenes/FactoryEntityScenes/FactoryBoxScene/ActPrologue_LevelFactory_Box_Scene.tscn")
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
## The belt and its boxes are the same in every factory menu: moving from the main menu to
## the settings (and back) keeps them where they were instead of starting over. Boxes can only
## be grabbed in the main menu.
static var _saved: Dictionary = {}
var draggable: bool = true

func _ready() -> void:
	rng.randomize()
	
	
	if not layer3 or not layer3_clone or not layer3_clone2 or not layer3.texture:
		print("FactoryBackground: отсутствуют ноды или текстура!")
		return
	
	layer_width = layer3.texture.get_width() * abs(layer3.scale.x)
	start_x = layer3.position.x
	
	
	layer3_clone.position.x = start_x + layer_width
	layer3_clone2.position.x = start_x + layer_width * 2.0
	
	spawn_timer = box_spawn_interval
	var host = owner if owner else get_parent()
	draggable = host != null and String(host.scene_file_path).contains("MainMenu")
	_restore_state()

func _restore_state() -> void:
	if _saved.is_empty():
		return
	# the time the menus were switching: everything moved on meanwhile
	var gone = clamp((Time.get_ticks_msec() - int(_saved.get("t", 0))) / 1000.0, 0.0, 5.0)
	var offs: Array = _saved.get("layers", [])
	var sprs = [layer3, layer3_clone, layer3_clone2]
	for i in range(min(offs.size(), sprs.size())):
		sprs[i].position.x = offs[i]
	spawn_timer = float(_saved.get("spawn", box_spawn_interval))
	for b in _saved.get("boxes", []):
		var box = box_scene.instantiate()
		add_child(box)
		box.position = b[0] - Vector2(layer3_speed * gone, 0)
		box.rotation = b[1]
		box.conveyor_speed = layer3_speed
		if "swing_phase" in box:
			box.swing_phase = b[2]
		box.input_pickable = draggable
	if gone > 0.0:
		_process(gone)

func _exit_tree() -> void:
	var boxes: Array = []
	for c in get_children():
		if c is Area2D and "held" in c and not c.held and not c.thrown:
			boxes.append([c.position, c.rotation, c.swing_phase])
	_saved = {
		"t": Time.get_ticks_msec(),
		"layers": [layer3.position.x, layer3_clone.position.x, layer3_clone2.position.x] if layer3 else [],
		"spawn": spawn_timer,
		"boxes": boxes,
	}

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
	box.input_pickable = draggable
	
