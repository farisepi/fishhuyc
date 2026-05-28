extends Node

@onready var player_camera: Camera2D = $"../рыбка/PlayerCamera"
@onready var cutscene_camera: Camera2D = $"../CutsceneCamera"
@onready var dialog: Node = $"/root/levelprolog/DialogCanvas/DialogController"
@onready var interaction_area: Area2D = $"../InteractionArea"
@onready var player: CharacterBody2D = $"../рыбка"
@onready var scientist: Sprite2D = $"../Scientist1"
@onready var mechanic: Sprite2D = $"../Mechanic"

var can_interact: bool = false
var sequence_started: bool = false
var background_dialog_played: bool = false

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and can_interact and not sequence_started:
		start_hit_sequence()

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body == player and not background_dialog_played:
		background_dialog_played = true

func start_hit_sequence() -> void:
	sequence_started = true
	
	if player_camera:
		player_camera.enabled = false
	if cutscene_camera:
		cutscene_camera.enabled = true
		if cutscene_camera.has_method("add_trauma"):
			cutscene_camera.add_trauma(0.3)
	
	await get_tree().create_timer(0.3).timeout
	
	if dialog: dialog.show_dialog("scientist")
	await get_tree().create_timer(1.5).timeout
	
	if dialog: dialog.next_line()
	await get_tree().create_timer(1.5).timeout
	
	if dialog: dialog.show_dialog("mechanic")
	await get_tree().create_timer(1.5).timeout
	
	if player_camera: player_camera.enabled = true
	if cutscene_camera: cutscene_camera.enabled = false
	
	if player: player.velocity = Vector2(-50, 0)
	
	await get_tree().create_timer(2.0).timeout
	
	UISounds.stop_factory_ambience()
	Fade.fade_out()
	await Fade.fade_out
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://Base/Scenes/Main_Menu.tscn")

func _on_interaction_available(available: bool) -> void:
	can_interact = available
