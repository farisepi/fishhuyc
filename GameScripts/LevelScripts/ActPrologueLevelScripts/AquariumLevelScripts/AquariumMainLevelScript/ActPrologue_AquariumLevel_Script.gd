extends Node2D

var bubble_scene: PackedScene = preload("res://GameScenes/EntityScenes/BubbleEntityScenes/Bubble_Scene.tscn")

const WATER_RECT: Rect2 = Rect2(363, 103, 551, 288)

@onready var animationtrack = $AnimationPlayer
@onready var scientistsprite = $npc/Scientist/ScientistSprite
@onready var mechanicsprite = $npc/Mechanic/MechanicSprite
@onready var chatter: ChatterController = $ChatterController
@onready var pausemenu: CanvasLayer = get_node_or_null("Pausemenu")
@onready var player: CharacterBody2D = $Player
@onready var lights_root: Node = get_node_or_null("Visual/Light")
@onready var fade_rect: CanvasItem = get_node_or_null("Visual/stuff/Fade")
var _ending: bool = false

## Background talk of the scientist and the mechanic (from the old aquarium script).
const CHATTER_PHRASES: Array = [
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

## The glass-hit cutscene (same lines as in the old script).
const CUTSCENE_LINES: Array = [
	{"speaker": "scientist", "parts": ["Проснулся ", "БЛЯТЬ", " наконец..."], "swear": ["БЛЯТЬ"], "time": 1.2},
	{"speaker": "scientist", "parts": ["Пол комплекса чуть не ", "РАЗЪЕБАЛ"], "swear": ["РАЗЪЕБАЛ"], "time": 1.2},
	{"speaker": "mechanic", "text": "Во-во...", "time": 1.0},
	{"speaker": "mechanic", "text": "А простым работягам это все чинить...", "time": 1.4},
]
const QUAKE_LINES: Array = [
	{"speaker": "scientist", "parts": ["ЕБАНЫЙ", " РОТ, ОПЯТЬ НАЧАЛОСЬ"], "swear": ["ЕБАНЫЙ"], "time": 0.9},
	{"speaker": "mechanic", "text": "ОНО СИЛЬНЕЕ ВСЕХ, ЧТО БЫЛИ ЗА ПОСЛЕДНИЙ ГОД", "time": 0.9},
	{"speaker": "scientist", "parts": ["БЫСТРЕЕ", " ЭВАКУИРУЙ ПЕРСОНАЛ И ЗАКЛЮЧЕННЫХ"], "swear": ["БЫСТРЕЕ"], "time": 0.9},
	{"speaker": "mechanic", "text": "МЫ НЕ УСПЕ...", "time": 0.5},
]
## Where the fish has to be to hit the glass (bottom of the tank, in front of the two).
const GLASS_ZONE: Rect2 = Rect2(560, 320, 240, 72)

var _in_glass_zone: bool = false
var _cutscene: bool = false
var _hint: Label = null

const QUAKE_DELAY: float = 1.5
const QUAKE_DURATION: float = 4.5
var scientist_boring_timer: Timer
var mechanic_boring_timer: Timer

const BORING_INTERVAL_MIN: float = 15.0
const BORING_INTERVAL_MAX: float = 20.0

func _ready():
	GlobalMusic.play_level_music()
	animationtrack.play("INTRO")
	
	_setup_character_animations()
	_spawn_bubbles()
	UISounds.start_factory_ambience()
	if pausemenu:
		pausemenu.visible = false
	# background talk loops until the fish hits the glass
	_start_background_chatter()
	_make_glass_hint()

func _schedule_boring(t: Timer) -> void:
	t.start(randf_range(BORING_INTERVAL_MIN, BORING_INTERVAL_MAX))

func _setup_character_animations() -> void:
	if scientistsprite and scientistsprite.sprite_frames:
		scientistsprite.animation_finished.connect(_on_scientist_animation_finished)
		scientist_boring_timer = _make_boring_timer(_on_scientist_boring_timer)
		scientistsprite.play("idle")
		_schedule_boring(scientist_boring_timer)
	
	if mechanicsprite and mechanicsprite.sprite_frames:
		mechanicsprite.animation_finished.connect(_on_mechanic_animation_finished)
		mechanic_boring_timer = _make_boring_timer(_on_mechanic_boring_timer)
		mechanicsprite.play("idle")
		_schedule_boring(mechanic_boring_timer)

func _make_boring_timer(callback: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.timeout.connect(callback)
	add_child(t)
	return t

func _on_scientist_boring_timer() -> void:
	
	#if cutscene_active or not scientistsprite or scientistsprite.animation != "idle":
		#_schedule_boring(scientist_boring_timer)
		#return
	scientistsprite.play("boring")

func _on_scientist_animation_finished() -> void:
	match scientistsprite.animation:
		"boring":
			scientistsprite.play("idle")
			_schedule_boring(scientist_boring_timer)
		"angry":
			
			scientistsprite.play("idle")
			
func _on_mechanic_boring_timer() -> void:
	
	if not mechanicsprite or mechanicsprite.animation != "idle":
		_schedule_boring(mechanic_boring_timer)
		return
	mechanicsprite.play("boring")

func _on_mechanic_animation_finished() -> void:
	if mechanicsprite.animation == "boring":
		mechanicsprite.play("idle")
		_schedule_boring(mechanic_boring_timer)
		
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
	
	if bubble.has_signal("body_entered"):
		bubble.body_entered.connect(_on_bubble_body_entered.bind(bubble))
	
	var spawn_timer = get_tree().create_timer(randf_range(1.5, 3.0), false)
	spawn_timer.timeout.connect(_make_bubble)

func _on_bubble_body_entered(body: Node2D, bubble: Area2D) -> void:
	if body == player and not bubble.popped:
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

func _get_player_camera() -> Camera2D:
	if player and player.has_node("PlayerCamera"):
		return player.get_node("PlayerCamera") as Camera2D
	return get_viewport().get_camera_2d()

func _wait_dialog() -> void:
	var tree = get_tree()
	if not tree:
		return
	await tree.create_timer(1.25).timeout


# ---------------------------------------------------------------------------
# Chatter
# ---------------------------------------------------------------------------

func _make_line(d: Dictionary) -> ChatterLine:
	var l := ChatterLine.new()
	l.speaker = ChatterLine.Speaker.MECHANIC if d.get("speaker", "") == "mechanic" else ChatterLine.Speaker.SCIENTIST
	if d.has("parts"):
		var text := ""
		var swears: Array[String] = []
		for p in d["parts"]:
			text += p
			if d.has("swear"):
				continue
			# old chatter: the words written in CAPS are the swears
			var letters = p.strip_edges().replace(",", "").replace(".", "").replace(" ", "")
			if letters.length() > 1 and letters == letters.to_upper() and letters != letters.to_lower():
				swears.append(p)
		if d.has("swear"):
			for w in d["swear"]:
				swears.append(w)
		l.text = text
		l.swear_words = swears
	else:
		l.text = d.get("text", "")
	l.display_time = float(d.get("time", 0.0))
	return l


func _lines_from(arr: Array) -> Array[ChatterLine]:
	var out: Array[ChatterLine] = []
	for d in arr:
		out.append(_make_line(d))
	return out


func _start_background_chatter() -> void:
	if chatter == null:
		return
	if chatter.is_active():
		chatter.stop()
	chatter.lines = _lines_from(CHATTER_PHRASES)
	chatter.loop = true
	chatter.start()


## Plays a list of lines through the same chatter boxes and waits until they are done.
func _say_lines(arr: Array) -> void:
	if chatter == null:
		return
	if chatter.is_active():
		chatter.stop()
	chatter.lines = _lines_from(arr)
	chatter.loop = false
	chatter.start()
	while chatter.is_active():
		# angry scientist on the lines that ask for it
		await get_tree().process_frame
		if not is_inside_tree():
			return


# ---------------------------------------------------------------------------
# Hitting the glass
# ---------------------------------------------------------------------------

func _make_glass_hint() -> void:
	_hint = Label.new()
	_hint.text = "[E]"
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	_hint.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
	_hint.add_theme_constant_override("outline_size", 4)
	_hint.z_index = 120
	_hint.visible = false
	add_child(_hint)


func _process(_delta: float) -> void:
	if player == null or _cutscene:
		if _hint:
			_hint.visible = false
		return
	_in_glass_zone = GLASS_ZONE.has_point(player.global_position)
	if _hint:
		_hint.visible = _in_glass_zone
		if _in_glass_zone:
			var bob = sin(Time.get_ticks_msec() / 180.0) * 2.0
			_hint.position = player.global_position + Vector2(-10, -34 + bob)


func _start_glass_cutscene() -> void:
	if _cutscene or _ending:
		return
	_cutscene = true
	_ending = true
	if _hint:
		_hint.visible = false
	if player and player.has_method("hit_glass"):
		player.hit_glass()
	if player and "can_move" in player:
		player.can_move = false
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	# camera slides down to the two of them
	var cam = _get_player_camera()
	if cam:
		var npc_pos = (scientistsprite.global_position + mechanicsprite.global_position) * 0.5 if scientistsprite and mechanicsprite else cam.global_position
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(cam, "offset", (npc_pos - cam.global_position) * 0.6, 1.4)
	if scientistsprite and scientistsprite.sprite_frames and scientistsprite.sprite_frames.has_animation("angry"):
		scientistsprite.play("angry")
	await _say_lines(CUTSCENE_LINES)
	if not is_inside_tree():
		return
	_play_earthquake()


# ---------------------------------------------------------------------------
# Earthquake -> blackout -> the story continues at the factory
# ---------------------------------------------------------------------------

func _quake_shake(duration: float, lights: Array, base_energy: Array) -> void:
	var t := 0.0
	var flicker_timer := 0.0
	var cam = _get_player_camera()
	while t < duration:
		var dt = get_process_delta_time()
		t += dt
		var k = clamp(t / duration, 0.0, 1.0)
		if player and "shake_amount" in player:
			player.shake_amount = lerp(1.5, 7.0, k)
		if cam:
			cam.rotation = randf_range(-1.0, 1.0) * 0.01 * k
		UISounds.set_glitch(k)
		flicker_timer -= dt
		if flicker_timer <= 0.0:
			flicker_timer = randf_range(0.04, 0.18)
			for i in range(lights.size()):
				var on = randf() > lerp(0.1, 0.65, k)
				lights[i].energy = base_energy[i] * (randf_range(0.7, 1.25) if on else 0.05)
		await get_tree().process_frame
		if not is_inside_tree():
			return
	if cam:
		cam.rotation = 0.0


func _play_earthquake() -> void:
	UISounds.play_earthquake()
	var lights: Array = []
	var base_energy: Array = []
	if lights_root:
		for l in lights_root.get_children():
			if l is PointLight2D:
				lights.append(l)
				base_energy.append(l.energy)
	_quake_shake(QUAKE_DURATION + 2.0, lights, base_energy)
	await _say_lines(QUAKE_LINES)
	if not is_inside_tree():
		return
	_knockout_fish()
	_spawn_falling_debris()
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return
	# blackout
	for l in lights:
		l.energy = 0.0
	if fade_rect:
		fade_rect.visible = true
		var tw = create_tween()
		tw.tween_property(fade_rect, "modulate:a", 1.0, 1.4)
		await tw.finished
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		return
	UISounds.stop_earthquake()
	await _show_flashback_title()
	if not is_inside_tree():
		return
	UISounds.set_glitch(0.0)
	UISounds.stop_factory_ambience()
	Global.prologue1_completed = true
	Global.autosave(Global.SCENE_FACTORY)
	Global.goto_scene(Global.SCENE_FACTORY)

func _knockout_fish() -> void:
	if player == null:
		return
	if "can_move" in player:
		player.can_move = false
	player.velocity = Vector2.ZERO
	var spr = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null or spr.sprite_frames == null:
		return
	if spr.sprite_frames.has_animation("wake"):
		spr.play("wake")
		spr.speed_scale = -1.0
		spr.frame = spr.sprite_frames.get_frame_count("wake") - 1
	var tw = create_tween()
	tw.tween_property(spr, "modulate", Color(0.4, 0.4, 0.5, 1.0), 1.2)


## A slab of the ceiling falls over the screen (from the old script).
func _spawn_falling_debris() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	var vp = get_viewport().get_visible_rect().size
	var debris = Node2D.new()
	layer.add_child(debris)
	var bw = 340.0
	var bh = 200.0
	var tw_ = 90.0
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-60, -1500), Vector2(vp.x + 60, -1500), Vector2(vp.x + 60, -bh),
		Vector2(vp.x - tw_ + 60, -bh), Vector2(vp.x - tw_ + 60, -tw_), Vector2(vp.x - bw + 60, -tw_),
		Vector2(vp.x - bw + 60, 0), Vector2(-60, 0)])
	body.color = Color(0.06, 0.06, 0.08)
	debris.add_child(body)
	for r in [[Vector2(vp.x - bw + 60, 0), Vector2(vp.x - bw + 40, 70)], [Vector2(vp.x - bw + 120, 0), Vector2(vp.x - bw + 110, 100)],
			[Vector2(vp.x - bw + 220, 0), Vector2(vp.x - bw + 240, 80)], [Vector2(vp.x - tw_ + 60, -tw_), Vector2(vp.x - tw_ + 120, -tw_ - 60)]]:
		var rebar = Line2D.new()
		rebar.width = 4
		rebar.default_color = Color(0.35, 0.25, 0.2)
		rebar.points = PackedVector2Array(r)
		debris.add_child(rebar)
	for i in range(10):
		var chip = ColorRect.new()
		chip.color = Color(0.08, 0.08, 0.1)
		chip.size = Vector2(randf_range(6, 20), randf_range(6, 20))
		chip.position = Vector2(randf_range(60, vp.x - 60), randf_range(-140, -40))
		layer.add_child(chip)
		var ct = create_tween()
		ct.tween_property(chip, "position:y", vp.y + 40, randf_range(0.4, 0.8))
		ct.tween_callback(chip.queue_free)
	var tw = create_tween()
	tw.tween_property(debris, "position:y", vp.y + 200, 0.6).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		var black = ColorRect.new()
		black.color = Color.BLACK
		black.size = vp
		layer.add_child(black)
	)
	var cam = _get_player_camera()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.8)


## "Пару дней назад..." over black (from the old script), with the Flashback achievement.
func _show_flashback_title() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	var label = Label.new()
	label.text = "Пару дней назад..."
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.modulate.a = 0.0
	layer.add_child(label)
	if has_node("/root/Achievements") and Achievements.has_method("unlock_flashback"):
		Achievements.unlock_flashback()
	UISounds.play_achievement()
	var tw = create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 1.0)
	tw.tween_interval(1.4)
	tw.tween_property(label, "modulate:a", 0.0, 0.6)
	await tw.finished


# ---------------------------------------------------------------------------
# Pause
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_toggle_pause()
		return
	if _in_glass_zone and not _cutscene and (event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E)):
		get_viewport().set_input_as_handled()
		_start_glass_cutscene()

func _toggle_pause() -> void:
	if pausemenu == null or _ending:
		return
	if get_tree().paused:
		get_tree().paused = false
		GlobalMusic.restore_volume()
		UISounds.restore_ambience()
		if chatter:
			chatter.resume_chatter()
		if pausemenu.has_method("hide_menu"):
			pausemenu.hide_menu()
		else:
			pausemenu.visible = false
	else:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GlobalMusic.lower_volume()
		UISounds.lower_ambience()
		if chatter:
			chatter.pause_chatter()
		if pausemenu.has_method("show_menu"):
			pausemenu.show_menu()
		else:
			pausemenu.visible = true

func _resume_after_pause() -> void:
	if chatter:
		chatter.resume_chatter()
