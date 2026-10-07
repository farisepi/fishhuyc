extends Node2D

var bubble_scene: PackedScene = preload("res://Fish Slaves/Base/Scenes/Overlay/Effects/Bubble.tscn")

const WATER_RECT: Rect2 = Rect2(320, 195, 576, 315)

@onready var pause_menu: CanvasLayer = $Pausemenu
@onready var player: CharacterBody2D = $рыбка
@onready var player_camera: Camera2D = $"рыбка/PlayerCamera"

@onready var interact_icon: Sprite2D = $InteractLabel
@onready var dialogue_panel: Panel = $DialoguePanel2
@onready var text_label: RichTextLabel = $DialoguePanel2/TextLabel
@onready var timer: Timer = $DialogueTimer
@onready var cutscene_cam: Camera2D = $CutsceneCamera

@onready var scientist: AnimatedSprite2D = $Scientist1
@onready var mechanic: AnimatedSprite2D = $Mechanic

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

#шрифт тут ваще по моему нахуй не нужен
const FONT_SIZE_NEAR: int = 5
const FONT_SIZE_FAR: int = 8
const FONT_SIZE_CUTSCENE: int = 6
const PANEL_WIDTH_NEAR: float = 120.0
const PANEL_WIDTH_FAR: float = 400.0
const PANEL_HEIGHT_FAR: float = 80.0

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
var chatter_typed_text: String = ""
var is_glitching: bool = false

var glitch_tween: Tween
var text_glitch_timer: float = 0.0
var current_phantom_offset: float = 0.0
var chatter_silence: bool = false

var scientist_icon = preload("res://Fish Slaves/Textures/Characters/Scientist/ScientistDialogPortrait/ScientistDialogPortrait.png")
var mechanic_icon = preload("res://Fish Slaves/Textures/Characters/Mechanic/MechanicDialogPortrait/MechanicDialogPortrait.png")

var interact_normal_texture: Texture2D = null

const BORING_INTERVAL_MIN: float = 15.0
const BORING_INTERVAL_MAX: float = 20.0
var scientist_boring_timer: Timer
var mechanic_boring_timer: Timer

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
	var root_black: ColorRect = null
	for child in get_tree().root.get_children():
		if child is ColorRect and child.z_index == 4095:
			root_black = child
			break
	
	if root_black:
		var tween = create_tween()
		tween.tween_property(root_black, "modulate:a", 0.0, 0.5)
		await tween.finished
		root_black.queue_free()
	
	GlobalMusic.play_level_music()
	
	_setup_timer()
	_setup_ui()
	_setup_labels()
	_setup_atmosphere()
	_generate_chatter_queue()
	_update_interact_icon()
	_setup_character_animations()
	
	chatter_panel.visible = false
	chatter_panel_far.visible = false
	phantom_left.visible = false
	phantom_right.visible = false
	
	if player and player.has_node("AnimatedSprite2D"):
		var player_sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
		player_sprite.stop()
		player_sprite.frame = 0
		player_sprite.animation = "wake"
	
	player.can_move = false
	if Global.just_returned_from_settings:
		_on_return_from_settings()
		_spawn_bubbles()
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
			chatter_typed_text = chatter_full_text
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
	fade_rect.modulate.a = 0.0
	
	await get_tree().process_frame
	
	var water_shader_mat = $WaterShader.material
	if not water_shader_mat:
		var new_mat = ShaderMaterial.new()
		new_mat.shader = preload("res://Fish Slaves/Base/Shaders/Act1AquariumLevelShaders/Act1AquariumShader.gdshader")
		$WaterShader.material = new_mat
	
	_start_wake_sequence()



func _setup_character_animations() -> void:
	if scientist and scientist.sprite_frames:
		scientist.animation_finished.connect(_on_scientist_animation_finished)
		scientist_boring_timer = _make_boring_timer(_on_scientist_boring_timer)
		scientist.play("idle")
		_schedule_boring(scientist_boring_timer)
	
	if mechanic and mechanic.sprite_frames:
		mechanic.animation_finished.connect(_on_mechanic_animation_finished)
		mechanic_boring_timer = _make_boring_timer(_on_mechanic_boring_timer)
		mechanic.play("idle")
		_schedule_boring(mechanic_boring_timer)

func _make_boring_timer(callback: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.timeout.connect(callback)
	add_child(t)
	return t

func _schedule_boring(t: Timer) -> void:
	if not t or cutscene_active:
		return
	t.start(randf_range(BORING_INTERVAL_MIN, BORING_INTERVAL_MAX))



func _on_scientist_boring_timer() -> void:
	
	if cutscene_active or not scientist or scientist.animation != "idle":
		_schedule_boring(scientist_boring_timer)
		return
	scientist.play("boring")

func _on_scientist_animation_finished() -> void:
	match scientist.animation:
		"boring":
			scientist.play("idle")
			_schedule_boring(scientist_boring_timer)
		"angry":
			
			scientist.play("idle")

func _scientist_play_angry() -> void:
	if not scientist:
		return
	if scientist_boring_timer:
		scientist_boring_timer.stop()
	scientist.play("angry")



func _on_mechanic_boring_timer() -> void:
	
	if cutscene_active or not mechanic or mechanic.animation != "idle":
		_schedule_boring(mechanic_boring_timer)
		return
	mechanic.play("boring")

func _on_mechanic_animation_finished() -> void:
	if mechanic.animation == "boring":
		mechanic.play("idle")
		_schedule_boring(mechanic_boring_timer)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	
	if fps_label and fps_label.visible:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
		if player_camera:
			var viewport = get_viewport().get_visible_rect().size
			fps_label.position = player_camera.global_position + Vector2(-viewport.x / 2 + 10, -viewport.y / 2 + 10)
		fps_label.z_index = 999
	
	if chatter_active and not cutscene_active:
		update_chatter_panel()
		#_update_glitch(delta)
	else:
		UISounds.set_glitch(0.0)

func _start_wake_sequence() -> void:
	await get_tree().create_timer(0.2).timeout
	
	start_chatter()
	
	_spawn_bubbles()
	
	if player and player.has_node("AnimatedSprite2D"):
		var player_sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
		player_sprite.visible = true
		player_sprite.play("wake")
		player_sprite.speed_scale = 1.0
		player_sprite.frame = 0
	
	var fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	
	var root = get_tree().root
	var all_black_rects = []
	
	if fade_rect:
		all_black_rects.append(fade_rect)
		fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	
	for child in root.get_children():
		if child is ColorRect and (child.color == Color.BLACK or child.color.r < 0.1):
			if child != fade_rect:
				all_black_rects.append(child)
				fade_tween.tween_property(child, "modulate:a", 0.0, 1.0)
	
	await fade_tween.finished
	
	for rect in all_black_rects:
		if is_instance_valid(rect):
			rect.queue_free()
	
	if player and player.has_node("AnimatedSprite2D"):
		var player_sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if player_sprite.is_playing():
			await player_sprite.animation_finished
		
		player_sprite.speed_scale = 1.0
		player_sprite.play("idle")
	
	await get_tree().create_timer(0.5).timeout
	player.can_move = true

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
	chatter_typed_text = ""
	
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
	
	bubble.global_position = _get_random_position_with_y_limit(0.0)
	
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
	
	var spawn_timer = get_tree().create_timer(randf_range(1.5, 3.0), false)
	spawn_timer.timeout.connect(_make_bubble)

func _on_bubble_body_entered(body: Node2D, bubble: Area2D) -> void:
	if body.name == "рыбка" and not bubble.popped:
		bubble._pop()

func _get_random_position_with_y_limit(_max_y: float) -> Vector2:
	var area: Rect2 = _get_camera_view_rect().intersection(WATER_RECT)
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		area = WATER_RECT
	

	var y_min = area.position.y + area.size.y * 0.3
	var y_max = area.end.y - 8.0
	return Vector2(
		randf_range(area.position.x + 8.0, area.end.x - 8.0),
		randf_range(y_min, y_max)
	)

func _get_camera_view_rect() -> Rect2:
	var camera = _get_player_camera()
	if not camera:
		return WATER_RECT
	var view_size: Vector2 = get_viewport().get_visible_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - view_size / 2.0, view_size)

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
		chatter_label.add_theme_font_size_override("normal_font_size", FONT_SIZE_NEAR)
		chatter_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		chatter_label.add_theme_color_override("default_color", Color(0.0, 0.0, 0.0, 1.0))
	
	if chatter_label_far:
		chatter_label_far.bbcode_enabled = true
		chatter_label_far.add_theme_font_size_override("normal_font_size", FONT_SIZE_FAR)
		chatter_label_far.autowrap_mode = TextServer.AUTOWRAP_WORD
		chatter_label_far.add_theme_color_override("default_color", Color(0.0, 0.0, 0.0, 1.0))
	
	if phantom_left_label:
		phantom_left_label.bbcode_enabled = true
		phantom_left_label.add_theme_font_size_override("normal_font_size", FONT_SIZE_FAR)
		phantom_left_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		phantom_left_label.add_theme_color_override("default_color", Color(0.0, 0.0, 0.0, 0.4))
	
	if phantom_right_label:
		phantom_right_label.bbcode_enabled = true
		phantom_right_label.add_theme_font_size_override("normal_font_size", FONT_SIZE_FAR)
		phantom_right_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		phantom_right_label.add_theme_color_override("default_color", Color(0.0, 0.0, 0.0, 0.4))
	
	if text_label:
		text_label.bbcode_enabled = true
		text_label.add_theme_font_size_override("normal_font_size", FONT_SIZE_CUTSCENE)
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
		pause_menu.show_menu()
		get_tree().paused = true
		GlobalMusic.lower_volume()
		UISounds.lower_ambience()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if player:
		player.set_physics_process(false)
		player.set_process(false)
		player.can_move = false
	
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

func get_chatter_state():
	return {
		"queue": chatter_queue.duplicate(),
		"current_text": chatter_full_text,
		"char_index": chatter
