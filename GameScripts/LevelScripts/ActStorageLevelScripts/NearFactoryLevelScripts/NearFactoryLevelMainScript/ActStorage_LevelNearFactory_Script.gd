extends Node2D

const DOG_SCENE = preload("res://GameScenes/EntityScenes/EnemyEntityScenes/MechaDogScenes/Enemy_MechaDog_Storage_Scene.tscn")
const MONKEY_SCENE = preload("res://GameScenes/EntityScenes/EnemyEntityScenes/MechaMonkeyScenes/Enemy_MechaMonkey_Storage_Scene.tscn")
const PIGEON_SCENE = preload("res://GameScenes/EntityScenes/EnemyEntityScenes/MechaPigeonScenes/Enemy_MechaPigeon_Storage_Scene.tscn")
const HUD_SCENE = preload("res://GameScenes/UIScenes/ScreenScenes/HUDScenes/ActStorage_ShardHUD_Scene.tscn")
const INVENTORY_SCENE = preload("res://GameScenes/UIScenes/ScreenScenes/HUDScenes/ActStorage_ShardInventory_Scene.tscn")
const TITLE_SCENE = preload("res://GameScenes/UIScenes/ScreenScenes/HUDScenes/ActStorage_TitleCard_Scene.tscn")

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var camera: Camera2D = player.get_node_or_null("MechaFishCameraFactory") if player else null
@onready var enemies_parent: Node2D = $Enemies
@onready var death_screen: Node = $DeathScreen
@onready var pausemenu: CanvasLayer = $Pausemenu
@onready var spawn_points: Node2D = $SpawnPoints

var hud_instance: CanvasLayer = null
var inventory_instance: CanvasLayer = null
var title_instance: CanvasLayer = null
var _level_finished: bool = false

const EXIT_POSITION: Vector2 = Vector2(8000, 940)
const EXIT_SIZE: Vector2 = Vector2(140, 140)

func _ready() -> void:
	randomize()
	if is_instance_valid(Fade) and Fade.has_method("fade_in"):
		Fade.fade_in()

	UISounds.stop_everything_gameplay()
	GlobalMusic.play_level_music()

	_spawn_hud()
	_spawn_inventory()
	_show_title()
	_spawn_enemies()
	_create_exit_trigger()

	if death_screen and death_screen.has_method("hide_death"):
		death_screen.hide_death()
	if pausemenu:
		pausemenu.visible = false

	Global.load_shards_from_slot()

func _spawn_hud() -> void:
	if HUD_SCENE == null:
		return
	hud_instance = HUD_SCENE.instantiate()
	add_child(hud_instance)

func _spawn_inventory() -> void:
	if INVENTORY_SCENE == null:
		return
	inventory_instance = INVENTORY_SCENE.instantiate()
	add_child(inventory_instance)

func _show_title() -> void:
	if TITLE_SCENE == null:
		return
	title_instance = TITLE_SCENE.instantiate()
	add_child(title_instance)
	await get_tree().process_frame
	if title_instance and title_instance.has_method("show_title"):
		title_instance.show_title(tr("АКТ 1. СКЛАД."))

func _spawn_enemies() -> void:
	if not spawn_points:
		return
	for point in spawn_points.get_children():
		if not point is Marker2D:
			continue
		var enemy_type = point.get_meta("enemy_type", "dog")
		var scene = null
		match enemy_type:
			"dog": scene = DOG_SCENE
			"monkey": scene = MONKEY_SCENE
			"pigeon": scene = PIGEON_SCENE
		if scene == null:
			continue
		var enemy = scene.instantiate()
		for key in point.get_meta_list():
			if key != "enemy_type" and key in enemy:
				enemy.set(key, point.get_meta(key))
		enemy.global_position = point.global_position
		enemies_parent.add_child(enemy)

func _process(_delta: float) -> void:
	pass

func _create_exit_trigger() -> void:
	var area = Area2D.new()
	area.name = "ExitTrigger"
	area.position = EXIT_POSITION
	area.collision_layer = 0
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = EXIT_SIZE
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_exit_entered)

func _on_exit_entered(body: Node) -> void:
	if _level_finished or body != player:
		return
	if player and "is_dead" in player and player.is_dead:
		return
	_level_finished = true
	if player.has_method("set_movement_blocked"):
		player.set_movement_blocked(true)
	player.velocity = Vector2.ZERO
	Global.autosave(scene_file_path, player.global_position)
	var card = TITLE_SCENE.instantiate()
	add_child(card)
	await get_tree().process_frame
	if card.has_method("show_title"):
		card.show_title(tr("ПРОДОЛЖЕНИЕ СЛЕДУЕТ"), tr("склад ещё не закончен"), 3.0)
	await get_tree().create_timer(4.2).timeout
	if not is_inside_tree():
		return
	get_tree().paused = false
	Global.goto_scene(Global.SCENE_MAIN_MENU_FACTORY)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _level_finished:
			return
		if player and "is_dead" in player and player.is_dead:
			return
		_toggle_pause()

func _toggle_pause() -> void:
	if not pausemenu:
		return
	if get_tree().paused:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		GlobalMusic.restore_volume()
		UISounds.restore_ambience()
		if pausemenu.has_method("hide_menu"):
			pausemenu.hide_menu()
		else:
			pausemenu.visible = false
		if player:
			player.set_physics_process(true)
			player.set_process(true)
	else:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GlobalMusic.lower_volume()
		UISounds.lower_ambience()
		if pausemenu.has_method("show_menu"):
			pausemenu.show_menu()
		else:
			pausemenu.visible = true
		if player:
			player.set_physics_process(false)
			player.set_process(false)

func _resume_after_pause() -> void:
	if not player:
		return
	player.set_physics_process(true)
	player.set_process(true)

func _exit_tree() -> void:
	if hud_instance and is_instance_valid(hud_instance):
		hud_instance.queue_free()
	if inventory_instance and is_instance_valid(inventory_instance):
		inventory_instance.queue_free()
