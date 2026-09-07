extends Node2D

@onready var player: CharacterBody2D = $"../Mecha_Fish"
@onready var cutscene_camera: Camera2D = $"../CutsceneCamera"
@onready var fade_rect: ColorRect = $"../FadeRect"
@onready var stamps: Node2D = $"../Stamps"
@onready var neighbor: ColorRect = $"../Neighbors/Neighbor"
@onready var boss: CharacterBody2D = $"../Boss"
@onready var interaction_area: Area2D = $"../InteractionArea"
@onready var dialogue_panel: Panel = $"../DialogCanvas/DialoguePanel"
@onready var text_label: RichTextLabel = $"../DialogCanvas/DialoguePanel/TextLabel"
@onready var exclamation: Label = $"../Exclamation"
@onready var stamp_timer: Timer = $"../StampTimer"

var can_interact: bool = false
var sequence_started: bool = false
var stamp_index: int = 0
var qte_active: bool = false
var qte_success: bool = false
var dialogue_started: bool = false

func _ready():
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	
	fade_rect.visible = true
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 1.0
	
	exclamation.visible = false
	stamp_timer.timeout.connect(_on_stamp_timer_timeout)
	stamp_timer.stop()
	
	dialogue_panel.visible = false
	
	var stamp_list = stamps.get_children()
	for i in range(stamp_list.size()):
		var stamp = stamp_list[i]
		stamp.color = Color(0.8, 0.4, 0.1)

func _input(event: InputEvent):
	if event.is_action_pressed("interact") and can_interact and not sequence_started:
		start_sequence()
	
	if event.is_action_pressed("interact") and qte_active:
		qte_success = true

func _on_interaction_area_body_entered(body: Node2D):
	if body == player and not sequence_started:
		can_interact = true

func start_sequence():
	sequence_started = true
	can_interact = false
	
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	
	cutscene_camera.enabled = true
	var player_camera = player.get_node_or_null("MechaFishCamera")
	if player_camera:
		player_camera.enabled = false
	cutscene_camera.global_position = player.global_position + Vector2(0, -50)
	
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 2.0).set_ease(Tween.EASE_IN_OUT)
	await fade_tween.finished
	fade_rect.visible = false
	
	await get_tree().create_timer(0.5).timeout
	
	_start_qte_loop()

func _start_qte_loop():
	stamp_index = 0
	stamp_timer.start(4.0)
	_activate_next_stamp()

func _activate_next_stamp():
	if stamp_index >= 9:
		_show_dialog("Все штампы активированы!")
		await get_tree().create_timer(1.5).timeout
		_neighbor_dialogue()
		return
	
	var stamp_list = stamps.get_children()
	var stamp = stamp_list[stamp_index]
	stamp.color = Color(1.0, 0.8, 0.1)
	
	_show_dialog("Нажми E чтобы активировать штамп " + str(stamp_index + 1) + "/9")
	
	qte_active = true
	qte_success = false
	
	var wait_time: float = 0.0
	while wait_time < 4.0:
		await get_tree().process_frame
		wait_time += get_process_delta_time()
		
		if qte_success:
			qte_active = false
			stamp.color = Color(0.2, 0.8, 0.2)
			stamp_index += 1
			_show_dialog("Штамп " + str(stamp_index) + " активирован!")
			await get_tree().create_timer(0.5).timeout
			stamp_timer.start(4.0)
			return
	
	if not qte_success:
		qte_active = false
		_show_dialog("Ты не нажал! Штамп пропущен")
		stamp.color = Color(0.8, 0.2, 0.1)
		stamp_index += 1
		await get_tree().create_timer(1.5).timeout
		stamp_timer.start(4.0)

func _on_stamp_timer_timeout():
	_activate_next_stamp()

func _neighbor_dialogue():
	stamp_timer.stop()
	dialogue_started = true
	
	cutscene_camera.global_position = player.global_position + Vector2(-150, -50)
	await get_tree().create_timer(0.5).timeout
	
	neighbor.modulate.a = 1.0
	
	var cam_tween = create_tween()
	cam_tween.tween_property(cutscene_camera, "global_position", neighbor.global_position + Vector2(-100, -50), 1.5).set_ease(Tween.EASE_IN_OUT)
	await cam_tween.finished
	
	_show_dialog("бля какой нахуй пред эксплоатировать нас когда технологии позволяют делать это за нас, так ещё и животных..")
	await get_tree().create_timer(4.0).timeout
	
	cam_tween = create_tween()
	cam_tween.tween_property(cutscene_camera, "global_position", player.global_position + Vector2(150, -50), 1.5).set_ease(Tween.EASE_IN_OUT)
	await cam_tween.finished
	
	_show_dialog("...")
	await get_tree().create_timer(2.0).timeout
	
	_boss_enters()

func _boss_enters():
	exclamation.visible = true
	exclamation.global_position = player.global_position + Vector2(0, -100)
	
	var exclamation_tween = create_tween()
	exclamation_tween.set_loops(3)
	exclamation_tween.tween_property(exclamation, "scale", Vector2(1.5, 1.5), 0.2)
	exclamation_tween.tween_property(exclamation, "scale", Vector2(1.0, 1.0), 0.2)
	
	await get_tree().create_timer(0.5).timeout
	
	boss.get_node("ColorRect").modulate.a = 1.0
	
	var cam_tween = create_tween()
	cam_tween.tween_property(cutscene_camera, "global_position", boss.global_position + Vector2(-200, -50), 1.0).set_ease(Tween.EASE_IN)
	await cam_tween.finished
	
	_show_dialog("Что здесь происходит?!")
	await get_tree().create_timer(2.0).timeout
	
	cam_tween = create_tween()
	cam_tween.tween_property(cutscene_camera, "global_position", player.global_position + Vector2(150, -50), 2.0).set_ease(Tween.EASE_IN_OUT)
	await cam_tween.finished
	
	_show_dialog("...")
	await get_tree().create_timer(1.0).timeout
	
	_show_dialog("Я за вами слежу...")
	await get_tree().create_timer(2.0).timeout
	
	_cutscene_end()

func _show_dialog(text: String):
	dialogue_panel.visible = true
	text_label.text = "[center]" + text + "[/center]"

func _hide_dialog():
	dialogue_panel.visible = false

func _cutscene_end():
	_hide_dialog()
	exclamation.visible = false
	stamp_timer.stop()
	
	player.set_physics_process(true)
	var player_camera = player.get_node_or_null("MechaFishCamera")
	if player_camera:
		player_camera.enabled = true
	cutscene_camera.enabled = false
