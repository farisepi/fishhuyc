extends Node2D

@export var bubble_scene: PackedScene

@onready var pause_menu: CanvasLayer = $Pausemenu
@onready var player: CharacterBody2D = $рыбка
@onready var player_camera: Camera2D = $"рыбка/PlayerCamera"

@onready var interact_icon: Sprite2D = $InteractLabel
@onready var dialogue_panel: Panel = $DialoguePanel2
@onready var text_label: RichTextLabel = $DialoguePanel2/TextLabel
@onready var timer: Timer = $DialogueTimer
@onready var cutscene_cam: Camera2D = $CutsceneCamera

@onready var scientist: Sprite2D = $Scientist1
@onready var mechanic: Sprite2D = $Mechanic

@onready var chatter_panel: Panel = $DialoguePanel2
@onready var chatter_label: RichTextLabel = $DialoguePanel2/TextLabel
@onready var chatter_panel_far: Panel = $ChatterCanvas/DialoguePanelFar
@onready var chatter_label_far: RichTextLabel = $ChatterCanvas/DialoguePanelFar/TextLabelFar

@onready var phantom_left: Panel = $ChatterCanvas/PhantomPanelLeft
@onready var phantom_left_label: RichTextLabel = $ChatterCanvas/PhantomPanelLeft/TextLabelLeft
@onready var phantom_right: Panel = $ChatterCanvas/PhantomPanelRight
@onready var phantom_right_label: RichTextLabel = $ChatterCanvas/PhantomPanelRight/TextLabelRight

@onready var fps_label: Label = $FPSCounter

@onready var speaker_icon_far: TextureRect = $ChatterCanvas/DialoguePanelFar/SpeakerIconFar
@onready var speaker_icon_left: TextureRect = $ChatterCanvas/PhantomPanelLeft/SpeakerIconLeft
@onready var speaker_icon_right: TextureRect = $ChatterCanvas/PhantomPanelRight/SpeakerIconRight
@onready var interact_label: Sprite2D = $InteractLabel

@onready var fade_rect: ColorRect = $FadeRect
@onready var level_music: AudioStreamPlayer = $Level1Music

var in_zone: bool = false
var dialogue_done: bool = false
var cutscene_active: bool = false
var cutscene_step: int = 0
var skip_chatter_update: bool = false
var part1: String = ""
var mate: String = ""
var part2: String = ""
var typing_index: int = 0
var typing_speed: float = 0.025
var waiting_for_next: bool = false
var mate_shown: bool = false
var fading_chatter: bool = false
var chatter_char_index: int = 0
var chatter_active: bool = false
var chatter_typing: bool = false
var chatter_full_text: String = ""
var chatter_speaker: String = ""
var chatter_queue: Array[Dictionary] = []
var chatter_segments: Array = []
var chatter_segment_index: int = 0
var chatter_char_in_segment: int = 0
var chatter_panel_height: float = 28.0

var glitch_tween: Tween
var text_glitch_timer: float = 0.0
var current_phantom_offset: float = 0.0
var chatter_silence: bool = false

# Для отслеживания движения камеры
var last_cam_pos: Vector2 = Vector2.ZERO
var last_zoom: Vector2 = Vector2.ONE

var scientist_icon = preload("res://Textures/Characters/Scienist/Scientist_Portrait.png")
var mechanic_icon = preload("res://Textures/Characters/Mechanic/mechanic_portrait.png")

var interact_normal_texture: Texture2D = null

var chatter_phrases: Array[Dictionary] = [
	{"speaker": "mechanic", "text": "Трещина увеличивается с каждым часом...", "height": 56},
	{"speaker": "scientist", "text": "Давление в третьем секторе падает.", "height": 56},
	{"speaker": "mechanic", "text": "Если трещина дойдёт до силового кабеля, будет фейерверк.", "height": 70},
	{"speaker": "scientist", "text": "Герметик не держит, нужно менять весь блок.", "height": 56},
	{"speaker": "mechanic", "text": "В прошлый раз еле залатали, а она снова расходится.", "height": 70},
	{"speaker": "scientist", "text": "Надо бы вызвать инженеров с поверхности.", "height": 56},
	{"speaker": "mechanic", "text": "Погода сегодня хорошая... наверное.", "height": 56},
	{"speaker": "scientist", "text": "А я гнию тут, в этом бетонном мешке.", "height": 56},
	{"speaker": "mechanic", "text": "Кофе бы... горячего, чёрного.", "height": 56},
	{"speaker": "scientist", "text": "Хочу спать. Просто спать часов двенадцать.", "height": 70},
	{"speaker": "mechanic", "text": "Сколько мы уже тут? Месяц? Два?", "height": 42},
	{"speaker": "scientist", "text": "Обещали же перевод в другой сектор.", "height": 56},
	{"speaker": "mechanic", "text": "Скорей бы смена кончилась.", "height": 42},
	{"speaker": "scientist", "text": "Опять этот гул... уже в ушах звенит.", "height": 56},
	{"speaker": "mechanic", "text": "Не наступи на кабель, он искрит.", "height": 56},
	{"speaker": "scientist", "text": "Помнишь, когда трещина в прошлом году дошла до реактора?", "height": 84},
	{"speaker": "mechanic", "text": "Не напоминай. Я тогда чуть не поседел.", "height": 56},
	{"speaker": "scientist", "text": "Надо доложить начальству, но они опять скажут «ждите».", "height": 70},
	{"speaker": "mechanic", "text": "Ждите... вечно мы ждём.", "height": 42},
	{"speaker": "scientist", "text": "А если вода хлынет? Ты об этом подумал?", "height": 56},
	{"speaker": "mechanic", "text": "Вода не хлынет, там тройное стекло.", "height": 56},
	{"speaker": "scientist", "text": "Тройное стекло, которое уже трещит по швам.", "height": 56},
	{"speaker": "mechanic", "text": "Ладно, давай просто закроем эту тему.", "height": 56},
	{"speaker": "scientist", "text": "У тебя сигареты есть? А, точно, мы же под водой.", "height": 56},
	{"speaker": "mechanic", "text": "Ненавижу эту работу.", "height": 42},
	{"speaker": "scientist", "text": "Зато платят хорошо.", "height": 42},
	{"speaker": "mechanic", "text": "Платят? Ты про эти копейки?", "height": 42},
	{"speaker": "scientist", "text": "Ну, на жизнь хватает.", "height": 42},
	{"speaker": "mechanic", "text": "На жизнь... тут не жизнь, а существование.", "height": 56},
	{"speaker": "scientist", "text": "Смотри, опять датчик моргает.", "height": 42},
	{"speaker": "mechanic", "text": "Который? Красный?", "height": 42},
	{"speaker": "scientist", "text": "Ага. Тот самый, что в прошлый раз сбоил.", "height": 56},
	{"speaker": "mechanic", "text": "Может, просто провод отошёл?", "height": 42},
	{"speaker": "scientist", "text": "Провод... ага, конечно. Всё у нас «провод отошёл».", "height": 70},
	{"speaker": "mechanic", "text": "Ну а что ты предлагаешь?", "height": 42},
	{"speaker": "scientist", "text": "Я предлагаю свалить отсюда.", "height": 42},
	{"speaker": "mechanic", "text": "Куда? Кругом вода и бетон.", "height": 42},
	{"speaker": "scientist", "text": "Вода и бетон... и мы тут торчим.", "height": 42},
	{"speaker": "mechanic", "text": "Эх, сейчас бы на пляж...", "height": 42},
	{"speaker": "scientist", "text": "Солнце, песок, коктейль...", "height": 42},
	{"speaker": "mechanic", "text": "Заткнись, а? И так тошно.", "height": 42},
	{"speaker": "scientist", "text": "Ладно, молчу. Работаем.", "height": 42},
	{"speaker": "mechanic", "text": "Трещина-то реально увеличивается.", "height": 56},
	{"speaker": "scientist", "text": "Я заметил. Миллиметра на три с утра.", "height": 56},
	{"speaker": "mechanic", "text": "Три миллиметра — это много?", "height": 42},
	{"speaker": "scientist", "text": "Для этого стекла — критично.", "height": 42},
	{"speaker": "mechanic", "text": "Значит, скоро рванёт?", "height": 42},
	{"speaker": "scientist", "text": "Если главный механик ничего не будет делать — да.", "height": 70},
	{"speaker": "mechanic", "parts": ["БЛЯТЬ", ", ты ", "ЗАЕБАЛ", ". Ходишь тут, строит из себя гения."], "height": 70},
	{"speaker": "scientist", "parts": ["А ты тут ", "НАХУЙ", " вообще нужен? Варить стекло без мозгов?"], "height": 70},
	{"speaker": "mechanic", "parts": ["Да пошёл ты ", "НАХУЙ", ". Без меня твой ", "ЕБАННЫЙ", " реактор — груда металла."], "height": 84},
	{"speaker": "scientist", "text": "Да если бы не я, ты бы дальше харчи с пола ел.", "height": 56},
	{"speaker": "mechanic", "parts": ["Да заткнись ", "НАХУЙ", " уже. Надо меньше ", "ПИЗДЕТЬ", " и работать."], "height": 84},
	{"speaker": "scientist", "text": "...", "height": 42},
]

func _ready() -> void:
	print("=== LEVEL_1 _ready START ===")
	
	GlobalMusic.play_level_music()
	
	_setup_timer()
	_setup_ui()
	_setup_labels()
	_setup_atmosphere()
	_generate_chatter_queue()
	_update_interact_icon()
	
	chatter_panel.visible = false
	chatter_panel_far.visible = false
	phantom_left.visible = false
	phantom_right.visible = false
	
	print("Player exists: ", player != null)
	if player and player.has_node("AnimatedSprite2D"):
		var player_sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
		player_sprite.stop()
		player_sprite.frame = 0
		player_sprite.animation = "wake"
	
	print("Setting player.can_move = false")
	player.can_move = false
	if Global.just_returned_from_settings:
		_on_return_from_settings()
		return
	
	if Global.player_position != Vector2.ZERO:
		player.global_position = Global.player_position
		Global.player_position = Vector2.ZERO
		
		if not Global.chatter_queue_state.is_empty():
			chatter_queue = Global.chatter_queue_state.duplicate()
			chatter_full_text = Global.chatter_current_text
			chatter_char_index = Global.chatter_char_index
			chatter_active = true
			chatter_typing = false
			
			for phrase in chatter_phrases:
				var text = ""
				if phrase.has("text"):
					text = phrase["text"]
				elif phrase.has("parts"):
					for p in phrase["parts"]:
						text += p
				if text == chatter_full_text:
					chatter_speaker = phrase["speaker"]
					chatter_panel_height = phrase.get("height", 28.0)
					_update_speaker_icons()
					break
			
			chatter_label.text = chatter_full_text
			chatter_label_far.text = chatter_full_text
			chatter_panel.visible = true
			chatter_panel.modulate.a = 1.0
			update_chatter_panel()
			timer.start(2.5)
			
			Global.chatter_queue_state = []
			Global.chatter_current_text = ""
			Global.chatter_char_index = 0
	
	if not fade_rect:
		fade_rect = ColorRect.new()
		fade_rect.name = "FadeRect"
		fade_rect.color = Color.BLACK
		fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade_rect.z_index = 100
		add_child(fade_rect)
	
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 1.0
	
	# ==========================================
	# ОБНОВЛЯЕМ КООРДИНАТЫ ШЕЙДЕРОВ
	# ==========================================
	await get_tree().process_frame
	_update_shader_coords()
	
	print("Calling _start_wake_sequence")
	_start_wake_sequence()
	print("=== LEVEL_1 _ready END ===")

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	
	# ==========================================
	# FPS СЧЁТЧИК
	# ==========================================
	if fps_label and fps_label.visible:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
		if player_camera:
			var viewport = get_viewport().get_visible_rect().size
			fps_label.position = player_camera.global_position + Vector2(-viewport.x / 2 + 10, -viewport.y / 2 + 10)
		fps_label.z_index = 999
	
	# ==========================================
	# ЧАТТЕР И ГЛИТЧИ
	# ==========================================
	if chatter_active and not cutscene_active:
		update_chatter_panel()
		_update_glitch(delta)
	else:
		UISounds.set_glitch(0.0)
	
	# ==========================================
	# ОБНОВЛЯЕМ ШЕЙДЕРЫ ПРИ ДВИЖЕНИИ КАМЕРЫ
	# ==========================================
	if player_camera:
		var cam_pos = player_camera.global_position
		var zoom = player_camera.zoom
		
		if cam_pos != last_cam_pos or zoom != last_zoom:
			_update_shader_coords()
			last_cam_pos = cam_pos
			last_zoom = zoom

func _update_shader_coords() -> void:
	var cam = player_camera
	if not cam:
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = cam.zoom.x
	var cam_pos = cam.global_position
	
	var view_width = viewport_size.x / zoom
	var view_height = viewport_size.y / zoom
	var view_left = cam_pos.x - view_width / 2.0
	var view_top = cam_pos.y - view_height / 2.0
	
	# ==========================================
	# ВОДА: x1=300.3, y1=514.8, x2=909.95, y2=191.5
	# ==========================================
	var w_left = 300.3
	var w_right = 909.95
	var w_top = 191.5
	var w_bottom = 514.8
	
	var uv_w_left = clamp((w_left - view_left) / view_width, 0.0, 1.0)
	var uv_w_right = clamp((w_right - view_left) / view_width, 0.0, 1.0)
	var uv_w_top = clamp(1.0 - (w_top - view_top) / view_height, 0.0, 1.0)
	var uv_w_bottom = clamp(1.0 - (w_bottom - view_top) / view_height, 0.0, 1.0)
	
	var water_mat = $WaterShader.material
	if water_mat:
		water_mat.set_shader_parameter("water_left", uv_w_left)
		water_mat.set_shader_parameter("water_right", uv_w_right)
		water_mat.set_shader_parameter("water_top", uv_w_top)
		water_mat.set_shader_parameter("water_bottom", uv_w_bottom)
	
	# ==========================================
	# СТЕКЛО: x1=1011.65, y1=514.8, x2=9.55, y2=530.65
	# ==========================================
	var g_left = 9.55
	var g_right = 1011.65
	var g_top = 514.8
	var g_bottom = 530.65
	
	var uv_g_left = clamp((g_left - view_left) / view_width, 0.0, 1.0)
	var uv_g_right = clamp((g_right - view_left) / view_width, 0.0, 1.0)
	var uv_g_top = clamp(1.0 - (g_top - view_top) / view_height, 0.0, 1.0)
	var uv_g_bottom = clamp(1.0 - (g_bottom - view_top) / view_height, 0.0, 1.0)
	
	var glass_mat = $GlassShader.material
	if glass_mat:
		glass_mat.set_shader_parameter("glass_left", uv_g_left)
		glass_mat.set_shader_parameter("glass_right", uv_g_right)
		glass_mat.set_shader_parameter("glass_top", uv_g_top)
		glass_mat.set_shader_parameter("glass_bottom", uv_g_bottom)
	
	# ==========================================
	# ЛАБА: x1=1011.65, y1=530.65, x2=9.55, y2=692
	# ==========================================
	var l_left = 9.55
	var l_right = 1011.65
	var l_top = 530.65
	var l_bottom = 692.0
	
	var uv_l_left = clamp((l_left - view_left) / view_width, 0.0, 1.0)
	var uv_l_right = clamp((l_right - view_left) / view_width, 0.0, 1.0)
	var uv_l_top = clamp(1.0 - (l_top - view_top) / view_height, 0.0, 1.0)
	var uv_l_bottom = clamp(1.0 - (l_bottom - view_top) / view_height, 0.0, 1.0)
	
	var lab_mat = $LabShader.material
	if lab_mat:
		lab_mat.set_shader_parameter("lab_left", uv_l_left)
		lab_mat.set_shader_parameter("lab_right", uv_l_right)
		lab_mat.set_shader_parameter("lab_top", uv_l_top)
		lab_mat.set_shader_parameter("lab_bottom", uv_l_bottom)

func _start_wake_sequence() -> void:
	print("=== _start_wake_sequence START ===")
	
	print("Waiting 0.2 seconds...")
	await get_tree().create_timer(0.2).timeout
	print("Wait finished")
	
	print("Starting chatter...")
	start_chatter()
	
	print("Spawning bubbles...")
	_spawn_bubbles()
	
	print("Starting wake animation...")
	if player and player.has_node("AnimatedSprite2D"):
		var player_sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
		player_sprite.visible = true
		player_sprite.play("wake")
		player_sprite.speed_scale = 1.0
		player_sprite.frame = 0
		print("Wake animation started")
	
	print("Creating fade tween...")
	var fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	
	print("Looking for all black rectangles...")
	var root = get_tree().root
	var all_black_rects = []
	
	if fade_rect:
		print("Adding FadeRect to fade list")
		all_black_rects.append(fade_rect)
		fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	
	for child in root.get_children():
		if child is ColorRect and (child.color == Color.BLACK or child.color.r < 0.1):
			if child != fade_rect:
				print("Adding root black rect to fade list: ", child.name)
				all_black_rects.append(child)
				fade_tween.tween_property(child, "modulate:a", 0.0, 1.0)
	
	print("Waiting for fade to finish (1.0 seconds)...")
	await fade_tween.finished
	print("All fades FINISHED!")
	
	print("Cleaning up all black rects...")
	for rect in all_black_rects:
		if is_instance_valid(rect):
			print("Queue free: ", rect.name)
			rect.queue_free()
	
	if player and player.has_node("AnimatedSprite2D"):
		var player_sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if player_sprite.is_playing():
			print("Waiting for wake animation to finish...")
			await player_sprite.animation_finished
			print("Wake animation finished!")
		
		player_sprite.speed_scale = 1.0
		player_sprite.play("idle")
	
	print("Waiting 0.5 seconds before giving control...")
	await get_tree().create_timer(0.5).timeout
	print("Setting player.can_move = true")
	player.can_move = true
	
	print("=== _start_wake_sequence END ===")

func _remove_black_nodes(node: Node) -> void:
	for child in node.get_children():
		if child is ColorRect and child.color == Color.BLACK and child != fade_rect:
			child.queue_free()
		_remove_black_nodes(child)

func _spawn_bubbles_with_fade() -> void:
	await get_tree().process_frame
	for i in range(6):
		_make_bubble_with_fade()
		await get_tree().create_timer(0.5).timeout

func _make_bubble_with_fade() -> void:
	if not bubble_scene:
		return
	
	var bubble = bubble_scene.instantiate()
	add_child(bubble)
	
	var spawn_y = randf_range(300, 514)
	bubble.global_position = _get_random_position_with_y_limit(spawn_y)
	
	var bubble_scale = randf_range(0.35, 0.7)
	bubble.scale = Vector2(bubble_scale, bubble_scale)
	
	bubble.modulate.a = 0.0
	
	var direction_x = randf_range(-0.2, 0.2)
	bubble.set_direction(Vector2(direction_x, -1.0))
	
	var appear_tween = create_tween()
	appear_tween.tween_property(bubble, "modulate:a", randf_range(0.1, 0.5), 0.8)
	
	bubble.start_life(randf_range(5.0, 10.0))
	bubble.clickable = false
	
	bubble.body_entered.connect(_on_bubble_body_entered.bind(bubble))
	
	var spawn_timer = get_tree().create_timer(randf_range(1.5, 3.0))
	spawn_timer.timeout.connect(_make_bubble)

func start_chatter_with_fade() -> void:
	if chatter_queue.is_empty():
		_generate_chatter_queue()
	
	chatter_active = true
	chatter_typing = true
	
	chatter_panel.visible = false
	chatter_panel.modulate.a = 0.0
	chatter_panel_far.visible = false
	phantom_left.visible = false
	phantom_left_label.visible = false
	phantom_right.visible = false
	phantom_right_label.visible = false
	current_phantom_offset = 0.0
	
	if chatter_queue.is_empty():
		chatter_queue = chatter_phrases.duplicate()
	
	var data: Dictionary = chatter_queue.pop_front()
	chatter_speaker = data["speaker"]
	_update_speaker_icons()
	
	if data.has("parts"):
		chatter_segments.clear()
		for part in data["parts"]:
			var upper = part.to_upper()
			var swear_list = ["БЛЯТЬ", "ЗАЕБАЛ", "НАХУЙ", "ЕБАННЫЙ", "ПИЗДЕТЬ"]
			var is_swear = upper in swear_list
			chatter_segments.append({"text": part, "swear": is_swear})
		chatter_segment_index = 0
		chatter_char_in_segment = 0
	else:
		chatter_segments.clear()
		chatter_full_text = data.get("text", "")
		chatter_segments.append({"text": chatter_full_text, "swear": false})
		chatter_segment_index = 0
		chatter_char_in_segment = 0
	
	chatter_panel_height = data.get("height", 28.0)
	chatter_label.clear()
	chatter_label_far.clear()
	chatter_label.text = ""
	chatter_label_far.text = ""
	
	await get_tree().create_timer(0.3).timeout
	
	update_chatter_panel()
	
	var fade_tween = create_tween()
	fade_tween.tween_property(chatter_panel, "modulate:a", 1.0, 0.5)
	
	timer.stop()
	timer.wait_time = typing_speed
	timer.start()

func _spawn_bubbles() -> void:
	await get_tree().process_frame
	for i in range(6):
		_make_bubble()
		await get_tree().create_timer(0.5).timeout

func _make_bubble() -> void:
	if not bubble_scene:
		return
	
	var bubble = bubble_scene.instantiate()
	add_child(bubble)
	
	var spawn_y = randf_range(300, 514)
	bubble.global_position = _get_random_position_with_y_limit(spawn_y)
	
	var bubble_scale = randf_range(0.35, 0.7)
	bubble.scale = Vector2(bubble_scale, bubble_scale)
	
	bubble.modulate.a = randf_range(0.01, 0.5)
	
	var direction_x = randf_range(-0.2, 0.2)
	bubble.set_direction(Vector2(direction_x, -1.0))
	
	bubble.start_life(randf_range(5.0, 10.0))
	bubble.clickable = false
	
	bubble.body_entered.connect(_on_bubble_body_entered.bind(bubble))
	
	var spawn_timer = get_tree().create_timer(randf_range(1.5, 3.0))
	spawn_timer.timeout.connect(_make_bubble)

func _on_bubble_body_entered(body: Node2D, bubble: Area2D) -> void:
	if body.name == "рыбка" and not bubble.popped:
		bubble._pop()

func _get_random_position_with_y_limit(max_y: float) -> Vector2:
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	var camera = _get_player_camera()
	
	if not camera:
		return Vector2(randf_range(0, viewport_size.x), randf_range(viewport_size.y - 200, max_y))
	
	var cam_pos = camera.global_position
	var zoom = camera.zoom
	
	var world_width = viewport_size.x / zoom.x
	var world_height = viewport_size.y / zoom.y
	
	var cam_bottom = cam_pos.y + world_height / 2
	
	var spawn_y_min = cam_bottom - 300
	var spawn_y_max = min(cam_bottom - 100, max_y)
	
	return Vector2(
		cam_pos.x - world_width / 2 + randf_range(0, world_width),
		randf_range(spawn_y_min, spawn_y_max)
	)

func _update_interact_icon() -> void:
	if not interact_icon:
		return
	
	var texture = InputRebind.get_key_texture("interact")
	if texture:
		interact_normal_texture = texture
		interact_icon.texture = texture
		interact_icon.modulate = Color(1, 1, 1, 0.8)
		interact_icon.scale = Vector2(0.8, 0.8)

func _show_interact_pressed() -> void:
	if not interact_icon or not interact_normal_texture:
		return
	
	var pressed_texture = InputRebind.get_key_texture_pressed("interact")
	if pressed_texture:
		interact_icon.texture = pressed_texture
		var tween = create_tween()
		tween.tween_property(interact_icon, "scale", Vector2(0.9, 0.9), 0.1)
		await tween.finished
		interact_icon.texture = interact_normal_texture
		tween = create_tween()
		tween.tween_property(interact_icon, "scale", Vector2(0.8, 0.8), 0.1)

func _setup_atmosphere() -> void:
	var aquarium_dark = ColorRect.new()
	aquarium_dark.name = "AquariumDarkness"
	aquarium_dark.position = Vector2(-16, -16)
	aquarium_dark.size = Vector2(992, 544)
	aquarium_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aquarium_dark.z_index = 50
	
	var dark_shader_mat = ShaderMaterial.new()
	var dark_shader = Shader.new()
	dark_shader.code = """shader_type canvas_item;
void fragment() {
	float t = UV.y;
	float fade = smoothstep(0.0, 1.0, t);
	COLOR = vec4(0.01, 0.03, 0.08, (1.0 - fade) * 0.45);
}"""
	dark_shader_mat.shader = dark_shader
	aquarium_dark.material = dark_shader_mat
	add_child(aquarium_dark)
	
	var glow = ColorRect.new()
	glow.name = "GlassGlow"
	glow.position = Vector2(-16, -16)
	glow.size = Vector2(992, 544)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 51
	
	var shader_mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
void fragment() {
	float t = UV.y;
	float fade = smoothstep(0.0, 1.0, t);
	COLOR = vec4(1.0, 0.9, 0.5, (1.0 - fade) * 0.08);
}"""
	shader_mat.shader = shader
	glow.material = shader_mat
	add_child(glow)

func _setup_timer() -> void:
	if not timer:
		return
	timer.one_shot = false
	timer.wait_time = typing_speed
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(_on_timer_timeout)

func _setup_ui() -> void:
	if pause_menu:
		pause_menu.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if interact_icon:
		interact_icon.visible = false
	if dialogue_panel:
		dialogue_panel.visible = false
		dialogue_panel.modulate.a = 0.0
	if cutscene_cam:
		cutscene_cam.enabled = false
	
	if chatter_panel:
		chatter_panel.visible = false
		chatter_panel.modulate.a = 0.0
		chatter_panel.position = Vector2(-1000, -1000)
	
	if chatter_panel_far:
		chatter_panel_far.visible = false
		chatter_panel_far.position = Vector2(-1000, -1000)
	
	if phantom_left:
		phantom_left.visible = false
		phantom_left.modulate.a = 0.0
		phantom_left_label.visible = false
		phantom_left_label.modulate.a = 0.4
	
	if phantom_right:
		phantom_right.visible = false
		phantom_right.modulate.a = 0.0
		phantom_right_label.visible = false
		phantom_right_label.modulate.a = 0.4

func _setup_labels() -> void:
	if chatter_label:
		chatter_label.bbcode_enabled = true
		chatter_label.add_theme_font_size_override("normal_font_size", 10)
		chatter_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		chatter_label.add_theme_color_override("default_color", Color(0.9, 0.95, 1.0))
	
	if chatter_label_far:
		chatter_label_far.bbcode_enabled = true
		chatter_label_far.add_theme_font_size_override("normal_font_size", 18)
		chatter_label_far.autowrap_mode = TextServer.AUTOWRAP_WORD
		chatter_label_far.add_theme_color_override("default_color", Color(0.9, 0.95, 1.0))
	
	if phantom_left_label:
		phantom_left_label.bbcode_enabled = true
		phantom_left_label.add_theme_font_size_override("normal_font_size", 18)
		phantom_left_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		phantom_left_label.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0, 0.4))
	
	if phantom_right_label:
		phantom_right_label.bbcode_enabled = true
		phantom_right_label.add_theme_font_size_override("normal_font_size", 18)
		phantom_right_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		phantom_right_label.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0, 0.4))
	
	if text_label:
		text_label.bbcode_enabled = true
		text_label.add_theme_font_size_override("normal_font_size", 10)
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	if fps_label:
		fps_label.visible = config.get_value("graphics", "show_fps", false)
		fps_label.add_theme_font_size_override("font_size", 14)
		fps_label.add_theme_color_override("font_color", Color.WHITE)
		fps_label.position = Vector2(10, 10)
		fps_label.z_index = 200

func _on_return_from_settings() -> void:
	Global.just_returned_from_settings = false
	
	if Global.player_position != Vector2.ZERO:
		player.global_position = Global.player_position
	
	if pause_menu:
		pause_menu.show()
		get_tree().paused = true
	
	if not Global.chatter_queue_state.is_empty():
		set_chatter_state({
			"queue": Global.chatter_queue_state,
			"current_text": Global.chatter_current_text,
			"char_index": Global.chatter_char_index
		})
	elif not chatter_active:
		chatter_active = true
		chatter_panel.visible = true
		timer.start(2.5)
	
	player.can_move = true

func get_chatter_state():
	return {
		"queue": chatter_queue.duplicate(),
		"current_text": chatter_full_text,
		"char_index": chatter_char_index
	}

func set_chatter_state(state: Dictionary):
	if state.is_empty():
		return
	
	chatter_queue = state["queue"].duplicate()
	chatter_full_text = state["current_text"]
	chatter_char_index = state["char_index"]
	chatter_active = true
	chatter_typing = false
	
	chatter_label.text = chatter_full_text
	chatter_label_far.text = chatter_full_text
	chatter_panel.visible = true
	chatter_panel.modulate.a = 1.0
	
	for phrase in chatter_phrases:
		var text = ""
		if phrase.has("text"):
			text = phrase["text"]
		elif phrase.has("parts"):
			for p in phrase["parts"]:
				text += p
		if text == chatter_full_text:
			chatter_speaker = phrase["speaker"]
			chatter_panel_height = phrase.get("height", 28.0)
			_update_speaker_icons()
			break
	
	update_chatter_panel()
	timer.start(2.5)

func _update_glitch(delta: float) -> void:
	var player_pos = player.global_position
	var safe_zone_min = Vector2(672, 488)
	var safe_zone_max = Vector2(864, 520)
	
	var dist_to_safe_zone = 0.0
	if player_pos.x < safe_zone_min.x:
		dist_to_safe_zone += safe_zone_min.x - player_pos.x
	if player_pos.x > safe_zone_max.x:
		dist_to_safe_zone += player_pos.x - safe_zone_max.x
	if player_pos.y < safe_zone_min.y:
		dist_to_safe_zone += safe_zone_min.y - player_pos.y
	if player_pos.y > safe_zone_max.y:
		dist_to_safe_zone += player_pos.y - safe_zone_max.y
	
	var max_dist = 500.0
	var t = clamp(dist_to_safe_zone / max_dist, 0.0, 1.0)
	var glitch_intensity = clamp(t * t, 0.0, 0.9)
	
	text_glitch_timer += delta
	var interval = clamp(randf_range(0.8, 1.8) - glitch_intensity * 1.2, 0.3, 1.8)
	
	if text_glitch_timer > interval and glitch_intensity > 0.02:
		text_glitch_timer = 0.0
		_apply_text_glitch(glitch_intensity)
	
	if glitch_intensity > 0.1 and randf() < glitch_intensity * 0.6:
		_apply_visual_glitch(glitch_intensity)
	
	UISounds.set_glitch(glitch_intensity)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if cutscene_active:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	
	if get_tree().paused:
		return
	
	if event.is_action_pressed("interact") and in_zone and not dialogue_done and not cutscene_active:
		_show_interact_pressed()
		stop_chatter()
		hit_sequence()

func update_chatter_panel() -> void:
	if fading_chatter:
		return
	
	if not chatter_active:
		chatter_panel.visible = false
		chatter_panel_far.visible = false
		phantom_left.visible = false
		phantom_left_label.visible = false
		phantom_right.visible = false
		phantom_right_label.visible = false
		return
	
	var cam: Camera2D = player_camera
	if not cam:
		return
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var zoom = cam.zoom.x
	
	var cam_left = cam.global_position.x - viewport_size.x / 2.0 / zoom
	var cam_right = cam.global_position.x + viewport_size.x / 2.0 / zoom
	var cam_top = cam.global_position.y - viewport_size.y / 2.0 / zoom
	var cam_bottom = cam.global_position.y + viewport_size.y / 2.0 / zoom
	
	var scientist_x = scientist.global_position.x
	var scientist_y = scientist.global_position.y
	
	var scientist_visible = (scientist_x >= cam_left and scientist_x <= cam_right and 
							 scientist_y >= cam_top and scientist_y <= cam_bottom)
	
	var dist_to_visible = 0.0
	if not scientist_visible:
		var dx = 0.0
		if scientist_x < cam_left:
			dx = cam_left - scientist_x
		if scientist_x > cam_right:
			dx = scientist_x - cam_right
		
		var dy = 0.0
		if scientist_y < cam_top:
			dy = cam_top - scientist_y
		if scientist_y > cam_bottom:
			dy = scientist_y - cam_bottom
		
		dist_to_visible = max(dx, dy)
	
	var fade = clamp(dist_to_visible / 300.0, 0.0, 1.0)
	if scientist_visible:
		fade = 0.0
	
	var phantom_alpha = fade * 0.25
	current_phantom_offset = lerp(current_phantom_offset, fade, 0.03)
	
	if fade < 0.05:
		_show_chatter_near()
	else:
		_show_chatter_far(fade, phantom_alpha, viewport_size)

func _show_chatter_near() -> void:
	chatter_panel_far.visible = false
	phantom_left.visible = false
	phantom_left_label.visible = false
	phantom_right.visible = false
	phantom_right_label.visible = false
	chatter_panel.visible = true
	chatter_panel.z_index = 100
	current_phantom_offset = 0.0
	
	chatter_panel.size = Vector2(100, chatter_panel_height)
	chatter_label.position = Vector2(4, 4)
	chatter_label.size = chatter_panel.size - Vector2(8, 8)
	
	if chatter_speaker == "mechanic":
		chatter_panel.position = mechanic.global_position + Vector2(22, -30)
	else:
		chatter_panel.position = scientist.global_position + Vector2(-120, -25)
	
	_clamp_chatter_to_viewport()

func _show_chatter_far(fade: float, phantom_alpha: float, viewport_size: Vector2) -> void:
	chatter_panel.visible = false
	
	var margin = 20.0
	var panel_width = 400.0
	var panel_height = 80.0
	
	var target_x = viewport_size.x / 2.0 - panel_width / 2.0
	var target_y = viewport_size.y - margin - panel_height
	
	chatter_panel_far.visible = true
	chatter_panel_far.z_index = 100
	chatter_panel_far.size = Vector2(panel_width, panel_height)
	chatter_panel_far.position = Vector2(target_x, target_y)
	chatter_panel_far.modulate.a = fade
	
	chatter_label_far.text = chatter_label.text
	chatter_label_far.position = Vector2(70, 10)
	chatter_label_far.size = chatter_panel_far.size - Vector2(80, 20)
	
	var icon_size = 60.0
	var icon_y = (panel_height - icon_size) / 2.0
	
	if speaker_icon_far:
		speaker_icon_far.position = Vector2(5, icon_y)
		speaker_icon_far.size = Vector2(icon_size, icon_size)
	
	var zoom = player_camera.zoom.x if player_camera else 1.0
	var offset_x_phantom = int(35 * current_phantom_offset) / zoom
	var offset_y_phantom = int(25 * current_phantom_offset) / zoom
	
	phantom_left.visible = true
	phantom_left.size = chatter_panel_far.size
	phantom_left.position = chatter_panel_far.position + Vector2(-offset_x_phantom, offset_y_phantom)
	phantom_left.modulate.a = phantom_alpha
	phantom_left.z_index = 99
	phantom_left_label.visible = true
	phantom_left_label.text = chatter_label.text
	phantom_left_label.position = Vector2(70, 10)
	phantom_left_label.size = phantom_left.size - Vector2(80, 20)
	
	if speaker_icon_left:
		speaker_icon_left.position = Vector2(5, icon_y)
		speaker_icon_left.size = Vector2(icon_size, icon_size)
	
	phantom_right.visible = true
	phantom_right.size = chatter_panel_far.size
	phantom_right.position = chatter_panel_far.position + Vector2(offset_x_phantom, -offset_y_phantom)
	phantom_right.modulate.a = phantom_alpha
	phantom_right.z_index = 99
	phantom_right_label.visible = true
	phantom_right_label.text = chatter_label.text
	phantom_right_label.position = Vector2(70, 10)
	phantom_right_label.size = phantom_right.size - Vector2(80, 20)
	
	if speaker_icon_right:
		speaker_icon_right.position = Vector2(5, icon_y)
		speaker_icon_right.size = Vector2(icon_size, icon_size)

func _clamp_chatter_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var panel_size: Vector2 = chatter_panel.size
	chatter_panel.position.x = clamp(chatter_panel.position.x, 0.0, viewport_size.x - panel_size.x)
	chatter_panel.position.y = clamp(chatter_panel.position.y, 0.0, viewport_size.y - panel_size.y)

func _generate_chatter_queue() -> void:
	chatter_queue.clear()
	for phrase in chatter_phrases:
		chatter_queue.append(phrase)

func _update_speaker_icons() -> void:
	var icon = scientist_icon if chatter_speaker == "scientist" else mechanic_icon
	if speaker_icon_far:
		speaker_icon_far.texture = icon
		speaker_icon_far.modulate = Color(1.0, 1.0, 1.0, 0.8)
	if speaker_icon_left:
		speaker_icon_left.texture = icon
		speaker_icon_left.modulate = Color(1.0, 1.0, 1.0, 0.8)
	if speaker_icon_right:
		speaker_icon_right.texture = icon
		speaker_icon_right.modulate = Color(1.0, 1.0, 1.0, 0.8)

func _show_next_chatter_line() -> void:
	if chatter_silence:
		return
	
	if chatter_queue.is_empty():
		chatter_queue = chatter_phrases.duplicate()
	
	var data: Dictionary = chatter_queue.pop_front()
	chatter_speaker = data["speaker"]
	_update_speaker_icons()
	
	if data.has("parts"):
		chatter_segments.clear()
		for part in data["parts"]:
			var upper = part.to_upper()
			var swear_list = ["БЛЯТЬ", "ЗАЕБАЛ", "НАХУЙ", "ЕБАННЫЙ", "ПИЗДЕТЬ"]
			var is_swear = upper in swear_list
			chatter_segments.append({"text": part, "swear": is_swear})
		chatter_segment_index = 0
		chatter_char_in_segment = 0
		chatter_full_text = ""
		for p in data["parts"]:
			chatter_full_text += p
	else:
		chatter_segments.clear()
		chatter_full_text = data["text"]
		chatter_segments.append({"text": chatter_full_text, "swear": false})
		chatter_segment_index = 0
		chatter_char_in_segment = 0
	
	if chatter_full_text == "...":
		chatter_silence = true
		chatter_panel.visible = false
		chatter_panel_far.visible = false
		phantom_left.visible = false
		phantom_right.visible = false
		stop_chatter()
		Achievements.unlock_coffee()
		UISounds.play_achievement()
		_show_achievement("Кофе бы...")
		return
	
	chatter_panel_height = data.get("height", 28.0)
	
	chatter_label.clear()
	chatter_label_far.clear()
	chatter_label.text = ""
	chatter_label_far.text = ""
	chatter_panel.visible = false
	chatter_panel_far.visible = false
	chatter_typing = true
	update_chatter_panel()
	timer.start(typing_speed)

func start_chatter() -> void:
	if chatter_queue.is_empty():
		_generate_chatter_queue()
	
	chatter_active = true
	chatter_typing = true
	chatter_panel.visible = true
	chatter_panel.modulate.a = 1.0
	chatter_panel_far.visible = false
	phantom_left.visible = false
	phantom_right.visible = false
	current_phantom_offset = 0.0
	
	if chatter_queue.is_empty():
		chatter_queue = chatter_phrases.duplicate()
	
	var data: Dictionary = chatter_queue.pop_front()
	chatter_speaker = data["speaker"]
	_update_speaker_icons()
	
	if data.has("parts"):
		chatter_segments.clear()
		for part in data["parts"]:
			var upper = part.to_upper()
			var swear_list = ["БЛЯТЬ", "ЗАЕБАЛ", "НАХУЙ", "ЕБАННЫЙ", "ПИЗДЕТЬ"]
			var is_swear = upper in swear_list
			chatter_segments.append({"text": part, "swear": is_swear})
		chatter_segment_index = 0
		chatter_char_in_segment = 0
	else:
		chatter_segments.clear()
		chatter_full_text = data.get("text", "")
		chatter_segments.append({"text": chatter_full_text, "swear": false})
		chatter_segment_index = 0
		chatter_char_in_segment = 0
	
	chatter_panel_height = data.get("height", 28.0)
	chatter_label.clear()
	chatter_label_far.clear()
	chatter_label.text = ""
	chatter_label_far.text = ""
	
	update_chatter_panel()
	
	timer.stop()
	timer.wait_time = typing_speed
	timer.start()

func stop_chatter() -> void:
	chatter_active = false
	chatter_typing = false
	chatter_panel.visible = false
	chatter_panel_far.visible = false
	phantom_left.visible = false
	phantom_left_label.visible = false
	phantom_right.visible = false
	phantom_right_label.visible = false
	if glitch_tween and glitch_tween.is_valid():
		glitch_tween.kill()

func _apply_text_glitch(intensity: float) -> void:
	if not chatter_active or cutscene_active or not chatter_label:
		return
	
	var original = chatter_label.text
	if original.length() == 0:
		return
	
	if intensity > 0.03:
		var chars_main = []
		for c in original:
			chars_main.append(c)
		
		var up_count = max(1, int(intensity * chars_main.size() * 0.12))
		for i in range(up_count):
			var pos = randi() % chars_main.size()
			if chars_main[pos] != " ":
				chars_main[pos] = chars_main[pos].to_upper()
		
		var rm_count = max(1, int(intensity * chars_main.size() * 0.08))
		for i in range(rm_count):
			var pos = randi() % chars_main.size()
			if chars_main[pos] != " ":
				chars_main[pos] = ""
		
		var glitched_main = ""
		for c in chars_main:
			glitched_main += c
		
		chatter_label.text = glitched_main
		chatter_label.add_theme_color_override("default_color", Color(1.0, 0.4, 0.4))
		
		if chatter_label_far:
			chatter_label_far.text = glitched_main
			chatter_label_far.add_theme_color_override("default_color", Color(1.0, 0.4, 0.4))
		
		await get_tree().create_timer(0.06).timeout
		
		if chatter_active and not cutscene_active and is_instance_valid(chatter_label):
			chatter_label.text = original
			chatter_label.add_theme_color_override("default_color", Color(0.9, 0.95, 1.0))
			if chatter_label_far:
				chatter_label_far.text = original
				chatter_label_far.add_theme_color_override("default_color", Color(0.9, 0.95, 1.0))

func _apply_visual_glitch(intensity: float) -> void:
	var panels_to_shake: Array[Panel] = []
	
	if chatter_panel_far and chatter_panel_far.visible:
		panels_to_shake.append(chatter_panel_far)
	if phantom_left and phantom_left.visible:
		panels_to_shake.append(phantom_left)
	if phantom_right and phantom_right.visible:
		panels_to_shake.append(phantom_right)
	
	for panel in panels_to_shake:
		var orig = panel.position
		var shake_x = randf_range(-intensity * 6, intensity * 6)
		var shake_y = randf_range(-intensity * 4, intensity * 4)
		
		var gt = create_tween()
		gt.set_loops(randi() % 4 + 2)
		gt.tween_property(panel, "position", orig + Vector2(shake_x, shake_y), 0.02)
		gt.tween_property(panel, "position", orig, 0.04)

func shake_panel() -> void:
	if not dialogue_panel:
		return
	var orig = dialogue_panel.position
	var t = create_tween()
	t.set_loops(3)
	t.tween_property(dialogue_panel, "position:x", orig.x + 5, 0.04)
	t.tween_property(dialogue_panel, "position:x", orig.x - 5, 0.04)
	t.tween_property(dialogue_panel, "position:x", orig.x, 0.04)

func shake_chatter_panel() -> void:
	var tp = chatter_panel if chatter_panel.visible else (chatter_panel_far if chatter_panel_far.visible else null)
	if not tp:
		return
	var orig = tp.position
	var t = create_tween()
	t.set_loops(3)
	t.tween_property(tp, "position:x", orig.x + 5, 0.04)
	t.tween_property(tp, "position:x", orig.x - 5, 0.04)
	t.tween_property(tp, "position:x", orig.x, 0.04)

func scientist_say(p1: String, m: String, p2: String) -> void:
	if not text_label or not dialogue_panel or not scientist or not timer:
		return
	
	UISounds.stop_all_dialog()
	timer.stop()
	dialogue_panel.modulate.a = 1.0
	text_label.text = ""
	
	var full = p1 + m + p2
	var lines = ceil(full.length() / 11.0) + 1
	var h = max(28.0, lines * 15.0)
	
	dialogue_panel.size = Vector2(100, h)
	text_label.size = dialogue_panel.size - Vector2(8, 8)
	text_label.position = Vector2(4, 4)
	dialogue_panel.position = scientist.global_position + Vector2(-120, -25)
	_clamp_panel_to_viewport()
	dialogue_panel.visible = true
	
	part1 = p1
	mate = m
	part2 = p2
	typing_index = 0
	mate_shown = false
	waiting_for_next = false
	timer.start(typing_speed)

func mechanic_say(text: String, h_override: float = 0.0) -> void:
	if not text_label or not dialogue_panel or not mechanic or not timer:
		return
	
	UISounds.stop_all_dialog()
	timer.stop()
	dialogue_panel.modulate.a = 1.0
	text_label.text = ""
	
	var h: float
	if h_override > 0:
		h = h_override
	else:
		var lines = ceil(text.length() / 14.0) + 1
		h = max(28.0, lines * 15.0)
	
	dialogue_panel.size = Vector2(100, h)
	text_label.size = dialogue_panel.size - Vector2(8, 8)
	text_label.position = Vector2(4, 4)
	dialogue_panel.position = mechanic.global_position + Vector2(22, -30)
	_clamp_panel_to_viewport()
	dialogue_panel.visible = true
	
	part1 = text
	mate = ""
	part2 = ""
	typing_index = 0
	mate_shown = false
	waiting_for_next = false
	timer.start(typing_speed)

func _clamp_panel_to_viewport() -> void:
	var vp = get_viewport().get_visible_rect().size
	dialogue_panel.position.x = clamp(dialogue_panel.position.x, 0.0, vp.x - dialogue_panel.size.x)
	dialogue_panel.position.y = clamp(dialogue_panel.position.y, 0.0, vp.y - dialogue_panel.size.y)

func _on_timer_timeout() -> void:
	if get_tree().paused:
		return
	
	if cutscene_active:
		_on_cutscene_timer()
		return
	
	if chatter_active and chatter_typing:
		_on_chatter_typing_timer()
		return
	
	if chatter_active and not chatter_typing:
		_show_next_chatter_line()

func _on_cutscene_timer() -> void:
	if waiting_for_next:
		timer.stop()
		waiting_for_next = false
		_advance_cutscene()
		return
	
	if mate != "" and not mate_shown:
		if typing_index < part1.length():
			text_label.text += part1[typing_index]
			typing_index += 1
			UISounds.play_scientist()
			timer.start(typing_speed)
		else:
			text_label.text += "[color=#FF3333]" + mate + "[/color]"
			mate_shown = true
			shake_panel()
			UISounds.play_scientist()
			timer.start(typing_speed)
		return
	
	if mate != "" and mate_shown:
		if typing_index - part1.length() < part2.length():
			text_label.text += part2[typing_index - part1.length()]
			typing_index += 1
			UISounds.play_scientist()
			timer.start(typing_speed)
		else:
			timer.stop()
			waiting_for_next = true
			timer.start(0.6)
		return
	
	if typing_index < part1.length():
		text_label.text += part1[typing_index]
		typing_index += 1
		UISounds.play_mechanic()
		timer.start(typing_speed)
	else:
		timer.stop()
		waiting_for_next = true
		timer.start(0.6)

func _on_chatter_typing_timer() -> void:
	if chatter_segment_index < chatter_segments.size():
		var seg: Dictionary = chatter_segments[chatter_segment_index]
		if seg["swear"]:
			chatter_label.text += "[color=#FF3333]" + seg["text"] + "[/color]"
			shake_chatter_panel()
			chatter_segment_index += 1
			chatter_char_in_segment = 0
			timer.start(typing_speed * 2)
		else:
			var seg_text = seg["text"]
			if chatter_char_in_segment < seg_text.length():
				chatter_label.text += seg_text[chatter_char_in_segment]
				chatter_char_in_segment += 1
				timer.start(typing_speed)
			else:
				chatter_segment_index += 1
				chatter_char_in_segment = 0
				timer.start(typing_speed)
		if chatter_speaker == "scientist":
			UISounds.play_scientist()
		else:
			UISounds.play_mechanic()
		return
	else:
		chatter_typing = false
		timer.start(2.5)

func _on_dialogue_timer_timeout() -> void:
	pass

func hit_sequence() -> void:
	if interact_icon:
		interact_icon.visible = false
	cutscene_active = true
	if player and player.has_method("hit_glass"):
		player.hit_glass()
	
	await get_tree().create_timer(1.0).timeout
	
	var target_global_pos = cutscene_cam.global_position
	var target_zoom = cutscene_cam.zoom
	
	player_camera.enabled = false
	
	var temp_cam = Camera2D.new()
	temp_cam.name = "CutsceneCameraTemp"
	var viewport_size = get_viewport().get_visible_rect().size
	var offset_x = viewport_size.x / 16.0 - 16.25
	temp_cam.global_position = player.global_position - Vector2(offset_x, 0)
	temp_cam.zoom = player_camera.zoom
	temp_cam.enabled = true
	temp_cam.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(temp_cam)
	
	await get_tree().process_frame
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(temp_cam, "global_position", target_global_pos, 1.5)
	tween.tween_property(temp_cam, "zoom", target_zoom, 1.5)
	
	await get_tree().create_timer(1.8).timeout
	
	temp_cam.enabled = false
	cutscene_cam.enabled = true
	cutscene_cam.global_position = target_global_pos
	cutscene_cam.zoom = target_zoom
	temp_cam.queue_free()
	
	start_cutscene()

func _transition_to_cutscene_camera() -> void:
	if not player_camera or not cutscene_cam:
		return
	
	var target_pos = player.global_position + Vector2(0, -100)
	
	cutscene_cam.global_position = player_camera.global_position
	cutscene_cam.zoom = player_camera.zoom
	cutscene_cam.enabled = true
	player_camera.enabled = false
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(cutscene_cam, "global_position", target_pos, 1.2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cutscene_cam, "zoom", Vector2(1.5, 1.5), 1.2).set_ease(Tween.EASE_IN_OUT)

func start_cutscene() -> void:
	if not player or not interact_icon:
		return
	
	chatter_active = false
	chatter_typing = false
	stop_chatter()
	timer.stop()
	
	cutscene_active = true
	dialogue_done = true
	if interact_icon:
		interact_icon.visible = false
	player.set_physics_process(false)
	player.set_process(false)
	
	cutscene_step = 1
	scientist_say("Проснулся ", "БЛЯТЬ", " наконец...")

func _advance_cutscene() -> void:
	UISounds.stop_all_dialog()
	timer.stop()
	
	match cutscene_step:
		1:
			cutscene_step = 2
			scientist_say("Пол комплекса чуть не ", "РАЗЪЕБАЛ", "")
		2:
			cutscene_step = 3
			mechanic_say("Во-во...", 42.0)
		3:
			cutscene_step = 4
			mechanic_say("А простым работягам это все чинить...", 56.0)
		4:
			cutscene_step = 5
			dialogue_panel.visible = false
			_start_earthquake()

func _wait_for_cutscene_line() -> void:
	while not waiting_for_next:
		await get_tree().create_timer(0.05).timeout
	waiting_for_next = false

func _start_earthquake() -> void:
	UISounds.play_earthquake()
	
	if player_camera:
		player_camera.enabled = false
	cutscene_cam.enabled = true
	cutscene_cam.trauma = 0.8
	
	var quake_tween = create_tween()
	quake_tween.set_loops()
	quake_tween.tween_callback(func(): 
		if is_instance_valid(cutscene_cam):
			cutscene_cam.trauma = 0.8
	)
	quake_tween.tween_interval(0.05)
	
	scientist_say("", "ЕБАНЫЙ", " РОТ, ОПЯТЬ НАЧАЛОСЬ")
	await _wait_dialog()
	
	mechanic_say("ОНО СИЛЬНЕЕ ВСЕХ, ЧТО БЫЛИ ЗА ПОСЛЕДНИЙ ГОД", 85.0)
	await _wait_dialog()
	
	scientist_say("", "БЫСТРЕЕ", " ЭВАКУИРУЙ ПЕРСОНАЛ И ЗАКЛЮЧЕННЫХ")
	await _wait_dialog()
	
	mechanic_say("МЫ НЕ УСПЕ...", 56.0)
	await get_tree().create_timer(0.8).timeout
	
	_knockout_fish()
	_spawn_falling_debris()
	await get_tree().create_timer(0.6).timeout
	
	UISounds.stop_earthquake()
	
	quake_tween.kill()
	
	cutscene_cam.trauma = 0.0
	cutscene_cam.set_external_offset(Vector2.ZERO)
	cutscene_cam.enabled = false
	if player_camera:
		player_camera.enabled = true
	
	_show_blackout_title()

func _knockout_fish() -> void:
	if not player:
		return
	
	player.can_move = false
	player.velocity = Vector2.ZERO
	
	var player_sprite = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not player_sprite:
		return
	
	player_sprite.play("wake")
	player_sprite.speed_scale = -1.0
	player_sprite.frame = player_sprite.sprite_frames.get_frame_count("wake") - 1
	
	var fade_tween = create_tween()
	fade_tween.tween_property(player_sprite, "modulate", Color(0.4, 0.4, 0.5, 1.0), 1.5)
	
	await get_tree().create_timer(1.5).timeout
	player_sprite.pause()

func _spawn_falling_debris() -> void:
	var view_size = get_viewport().get_visible_rect().size
	var debris = Control.new()
	debris.z_index = 200
	debris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(debris)
	
	var body = Polygon2D.new()
	var bw = 340
	var bh = 200
	var tw = 90
	var antialias = 1
	
	body.polygon = PackedVector2Array([
		Vector2(-60, -1500),
		Vector2(view_size.x + 60, -1500),
		Vector2(view_size.x + 60, -bh + antialias),
		Vector2(view_size.x - tw + 60, -bh + antialias),
		Vector2(view_size.x - tw + 60, -tw + antialias),
		Vector2(view_size.x - bw + 60, -tw + antialias),
		Vector2(view_size.x - bw + 60, antialias),
		Vector2(-60, antialias),
	])
	body.color = Color(0.06, 0.06, 0.08)
	body.antialiased = true
	debris.add_child(body)
	
	var crack = Line2D.new()
	crack.width = 2
	crack.default_color = Color(0.15, 0.15, 0.18)
	crack.antialiased = true
	crack.points = [
		Vector2(view_size.x - 80, -bh),
		Vector2(view_size.x - 40, -bh + 50),
		Vector2(view_size.x - 70, -bh + 90),
		Vector2(view_size.x - 120, -bh + 130),
	]
	debris.add_child(crack)
	
	var crack2 = Line2D.new()
	crack2.width = 1.5
	crack2.default_color = Color(0.12, 0.12, 0.15)
	crack2.antialiased = true
	crack2.points = [
		Vector2(view_size.x - bw + 20, -30),
		Vector2(view_size.x - bw + 80, -10),
		Vector2(view_size.x - bw + 60, 0),
	]
	debris.add_child(crack2)
	
	var rebars_data = [
		{"from": Vector2(view_size.x - bw + 60, 0), "to": Vector2(view_size.x - bw + 40, 70)},
		{"from": Vector2(view_size.x - bw + 120, 0), "to": Vector2(view_size.x - bw + 110, 100)},
		{"from": Vector2(view_size.x - bw + 220, 0), "to": Vector2(view_size.x - bw + 240, 80)},
		{"from": Vector2(view_size.x - tw + 60, -tw), "to": Vector2(view_size.x - tw + 120, -tw - 60)},
		{"from": Vector2(view_size.x - 40, -bh), "to": Vector2(view_size.x, -bh - 50)},
	]
	for r in rebars_data:
		var rebar = Line2D.new()
		rebar.width = 4
		rebar.default_color = Color(0.35, 0.25, 0.2)
		rebar.antialiased = true
		rebar.points = [r["from"], r["to"]]
		debris.add_child(rebar)
	
	for i in range(10):
		var chip = ColorRect.new()
		chip.color = Color(0.08, 0.08, 0.1)
		chip.size = Vector2(randf_range(6, 20), randf_range(6, 20))
		chip.position = Vector2(randf_range(60, view_size.x - 60), randf_range(-140, -40))
		debris.add_child(chip)
		
		var ct = create_tween()
		ct.tween_property(chip, "position:y", view_size.y + 40, randf_range(0.4, 0.8))
		ct.tween_callback(chip.queue_free)
	
	var tween = create_tween()
	tween.tween_property(debris, "position:y", view_size.y + 200, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		var overlay = ColorRect.new()
		overlay.color = Color.BLACK
		overlay.size = view_size
		overlay.position = Vector2.ZERO
		overlay.z_index = 201
		add_child(overlay)
	)

func _spawn_falling_blackout() -> void:
	var black_rect = ColorRect.new()
	black_rect.color = Color.BLACK
	black_rect.size = Vector2(get_viewport().get_visible_rect().size.x, 200)
	black_rect.position = Vector2(0, -200)
	black_rect.z_index = 200
	add_child(black_rect)
	
	var tween = create_tween()
	tween.tween_property(black_rect, "position:y", get_viewport().get_visible_rect().size.y, 0.5)
	await tween.finished
	black_rect.queue_free()

func _wait_for_typing_done() -> void:
	while waiting_for_next or typing_index < (part1 + mate + part2).length():
		await get_tree().create_timer(0.05).timeout
		if not cutscene_active:
			return
	await get_tree().create_timer(0.8).timeout

func _show_blackout_title():
	var blackout = CanvasLayer.new()
	blackout.layer = 100
	
	var rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blackout.add_child(rect)
	
	var label = Label.new()
	label.text = "Пару дней назад..."
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.modulate.a = 0.0
	blackout.add_child(label)
	
	add_child(blackout)
	
	var fade_tween = create_tween()
	fade_tween.tween_property(rect, "modulate:a", 1.0, 0.5)
	fade_tween.finished.connect(_on_fade_finished.bind(label, blackout))
	
func _on_fade_finished(label: Label, blackout: CanvasLayer):
	Achievements.unlock_flashback()
	_show_achievement_flashback("Флешбек")
	UISounds.play_achievement()
	
	var title_tween = create_tween()
	title_tween.tween_property(label, "modulate:a", 1.0, 1.0)
	title_tween.finished.connect(_on_title_finished.bind(label, blackout))

func _on_title_finished(label: Label, blackout: CanvasLayer):
	var hide_title = create_tween()
	hide_title.tween_property(label, "modulate:a", 0.0, 0.5)
	hide_title.finished.connect(_on_hide_finished.bind(blackout))

func _on_hide_finished(_blackout: CanvasLayer):
	_save_progress()
	
	cutscene_active = false
	Global.came_from = Global.MenuSource.MAIN_MENU
	Global.prologue1_completed = true
	
	if has_node("/root/Fade"):
		Fade.fade_out()
	else:
		var temp_fade = ColorRect.new()
		temp_fade.color = Color.BLACK
		temp_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		temp_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		temp_fade.z_index = 1000
		add_child(temp_fade)
		var tween_fade = create_tween()
		tween_fade.tween_property(temp_fade, "modulate:a", 1.0, 0.5)
		tween_fade.finished.connect(_change_to_prologue2)

func _change_to_prologue2():
	GlobalMusic.pause_level_music()
	
	get_tree().change_scene_to_file("res://Base/Scripts/Level_2.gd")

func _save_progress():
	GlobalMusic.pause_level_music()
	
	if not has_node("/root/Global"):
		print("Global не найден, сохранение невозможно")
		return
	
	var save_path = "user://saves/save_" + str(Global.save_slot) + ".cfg"
	
	var config = ConfigFile.new()
	
	config.set_value("save", "scene", "res://код/сцены/chase_level.tscn")
	config.set_value("save", "time", Time.get_datetime_string_from_system())
	
	if player:
		config.set_value("save", "player_x", player.global_position.x)
		config.set_value("save", "player_y", player.global_position.y)
	
	var error = config.save(save_path)
	
	if error == OK:
		print("Игра успешно сохранена в слот ", Global.save_slot)
	else:
		print("Ошибка сохранения в слот ", Global.save_slot, ". Ошибка: ", error)

func _show_achievement_flashback(title: String):
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	add_child(canvas)
	
	var ctrl = Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ctrl)
	
	var view_size = get_viewport().get_visible_rect().size
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.2, 0.35, 0.85)
	bg.size = Vector2(320, 60)
	bg.position = Vector2(view_size.x, 10)
	ctrl.add_child(bg)
	
	var icon = Label.new()
	icon.text = "★"
	icon.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	icon.add_theme_font_size_override("font_size", 28)
	icon.position = Vector2(view_size.x + 15, 20)
	icon.size = Vector2(40, 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ctrl.add_child(icon)
	
	var header = Label.new()
	header.text = "ДОСТИЖЕНИЕ"
	header.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.9))
	header.add_theme_font_size_override("font_size", 18)
	header.position = Vector2(view_size.x + 65, 18)
	ctrl.add_child(header)
	
	var l = Label.new()
	l.text = title
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	l.add_theme_font_size_override("font_size", 36)
	l.position = Vector2(view_size.x + 65, 35)
	ctrl.add_child(l)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(bg, "position:x", view_size.x - 330, 0.4)
	tween.parallel().tween_property(icon, "position:x", view_size.x - 305, 0.4)
	tween.parallel().tween_property(header, "position:x", view_size.x - 255, 0.4)
	tween.parallel().tween_property(l, "position:x", view_size.x - 255, 0.4)
	
	await get_tree().create_timer(3.5).timeout
	
	var tween2 = create_tween()
	tween2.set_ease(Tween.EASE_IN)
	tween2.tween_property(bg, "position:x", view_size.x, 0.3)
	tween2.parallel().tween_property(icon, "position:x", view_size.x + 15, 0.3)
	tween2.parallel().tween_property(header, "position:x", view_size.x + 65, 0.3)
	tween2.parallel().tween_property(l, "position:x", view_size.x + 65, 0.3)
	await tween2.finished
	
	canvas.queue_free()

func _wait_dialog() -> void:
	var tree = get_tree()
	if not tree:
		return
	await tree.create_timer(1.25).timeout

func _toggle_pause() -> void:
	if not pause_menu or not player:
		print("PAUSE: нет pause_menu или player")
		return
	
	var anim = player.get_node_or_null("AnimatedSprite2D")
	
	if pause_menu.visible:
		pause_menu.hide()
		get_tree().paused = false
		if not cutscene_active:
			player.set_physics_process(true)
			player.set_process(true)
			if anim: anim.play()
			if scientist: scientist.set_process(true)
			var sa = scientist.get_node_or_null("AnimationPlayer")
			if sa: sa.play()
			if mechanic: mechanic.set_process(true)
			var ma = mechanic.get_node_or_null("AnimationPlayer")
			if ma: ma.play()
	else:
		pause_menu.show()
		get_tree().paused = true
		player.set_physics_process(false)
		player.set_process(false)
		if anim: anim.pause()
		if scientist: scientist.set_process(false)
		var sa2 = scientist.get_node_or_null("AnimationPlayer")
		if sa2: sa2.pause()
		if mechanic: mechanic.set_process(false)
		var ma2 = mechanic.get_node_or_null("AnimationPlayer")
		if ma2: ma2.pause()

func _on_dialogue_zone_body_entered(body: Node2D) -> void:
	if body == player and not dialogue_done:
		in_zone = true
		if interact_label:
			interact_label.visible = true
			interact_label.modulate.a = 0.0
			interact_label.scale = Vector2(0.5, 0.5)
			var tween = create_tween()
			tween.set_parallel(true)
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(interact_label, "modulate:a", 1.0, 0.3)
			tween.tween_property(interact_label, "scale", Vector2.ONE, 0.3)

func _on_dialogue_zone_body_exited(body: Node2D) -> void:
	if body == player:
		in_zone = false
		if interact_label:
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(interact_label, "modulate:a", 0.0, 0.2)
			tween.tween_property(interact_label, "scale", Vector2(0.5, 0.5), 0.2)
			await tween.finished
			interact_label.visible = false

func _show_achievement(title: String):
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	add_child(canvas)
	
	var ctrl = Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ctrl)
	
	var view_size = get_viewport().get_visible_rect().size
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.2, 0.35, 0.85)
	bg.size = Vector2(320, 60)
	bg.position = Vector2(view_size.x, 10)
	ctrl.add_child(bg)
	
	var icon = Label.new()
	icon.text = "★"
	icon.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	icon.add_theme_font_size_override("font_size", 28)
	icon.position = Vector2(view_size.x + 15, 20)
	icon.size = Vector2(40, 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ctrl.add_child(icon)
	
	var header = Label.new()
	header.text = "ДОСТИЖЕНИЕ"
	header.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.9))
	header.add_theme_font_size_override("font_size", 18)
	header.position = Vector2(view_size.x + 65, 18)
	ctrl.add_child(header)
	
	var l = Label.new()
	l.text = title
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	l.add_theme_font_size_override("font_size", 36)
	l.position = Vector2(view_size.x + 65, 35)
	ctrl.add_child(l)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(bg, "position:x", view_size.x - 330, 0.4)
	tween.parallel().tween_property(icon, "position:x", view_size.x - 305, 0.4)
	tween.parallel().tween_property(header, "position:x", view_size.x - 255, 0.4)
	tween.parallel().tween_property(l, "position:x", view_size.x - 255, 0.4)
	
	await get_tree().create_timer(3.5).timeout
	
	var tween2 = create_tween()
	tween2.set_ease(Tween.EASE_IN)
	tween2.tween_property(bg, "position:x", view_size.x, 0.3)
	tween2.parallel().tween_property(icon, "position:x", view_size.x + 15, 0.3)
	tween2.parallel().tween_property(header, "position:x", view_size.x + 65, 0.3)
	tween2.parallel().tween_property(l, "position:x", view_size.x + 65, 0.3)
	await tween2.finished
	
	canvas.queue_free()
	
func _spawn_prologue_bubble() -> void:
	if not bubble_scene:
		return
	
	var bubble = bubble_scene.instantiate()
	add_child(bubble)
	
	bubble.can_pop = false
	
	bubble.global_position = Vector2(
		randf_range(0, 1920),
		randf_range(0, 510)
	)
	
	var bubble_scale = randf_range(0.2, 0.8)
	bubble.scale = Vector2.ONE * bubble_scale
	
	bubble.modulate.a = 0.0
	
	bubble.set_direction(
		Vector2(
			randf_range(-0.2, 0.2),
			-1.0
		)
	)
	
	var tween = create_tween()
	tween.tween_property(
		bubble,
		"modulate:a",
		randf_range(0.1, 0.5),
		0.5
	)
	
	bubble.start_life(randf_range(1.0, 20.0))

func _get_player_camera() -> Camera2D:
	if player and player.has_node("PlayerCamera"):
		return player.get_node("PlayerCamera") as Camera2D
	return get_viewport().get_camera_2d()
