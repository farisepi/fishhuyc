extends Node2D

# ==============================
# КОНСТАНТЫ
# ==============================
const TOTAL_OBJECTS: int = 25
const NUM_NPC_FISHES: int = 4

const CONVEYOR_Y: float = 450.0
const FISH_START_X: float = 400.0
const FISH_SPACING: float = 400.0
const PLAYER_TURN_X: float = -200.0
const OBJECT_SPAWN_X: float = 2500.0

const OBJECT_SPEED: float = 400.0

const SHIFT_START_HOUR: float = 8.0
const SHIFT_END_HOUR: float = 18.0
const SHIFT_DURATION_HOURS: float = 10.0
const REAL_SHIFT_DURATION: float = 180.0

const GUARD_SHIFTS: Array = [9.0, 13.0, 17.0]
const SNIPER_SHIFTS: Array = [11.0, 13.0, 15.0]

const COLOR_GREEN := Color(0.2, 0.8, 0.3)
const COLOR_RED := Color(0.9, 0.2, 0.2)
const COLOR_YELLOW := Color(1, 0.9, 0.3)

const OBJECT_COLORS := [
	Color(0.6, 0.4, 0.2),
	Color(0.7, 0.5, 0.2),
	Color(0.8, 0.6, 0.2),
	Color(0.7, 0.7, 0.7),
	Color(0.3, 0.5, 0.8),
]

# ==============================
# ССЫЛКИ НА УЗЛЫ
# ==============================
@onready var player: CharacterBody2D = $Mecha_Fish
@onready var camera: Camera2D = $Mecha_Fish/MechaFishCamera
@onready var objects_layer: Node2D = $Objects
@onready var npc_fishes: Array[Node] = [$NPCParent/Fish1, $NPCParent/Fish2, $NPCParent/Fish3, $NPCParent/Fish4]
@onready var guard_rect: ColorRect = $Guard
@onready var sniper_rect: ColorRect = $Sniper
@onready var elevator_door: ColorRect = $Elevator

@onready var clock_label: Label = $UI/ClockLabel
@onready var dialog_panel: ColorRect = $UI/DialogPanel
@onready var dialog_label: Label = $UI/DialogPanel/DialogLabel
@onready var progress_bar: HBoxContainer = $UI/ProgressBar
@onready var hint_label: Label = $UI/HintLabel
@onready var escape_hint: Label = $UI/EscapeHint

@onready var inspect_btn: Button = $UI/InspectButton
@onready var journal_btn: Button = $UI/JournalButton

@onready var minigame_panel: Control = $UI/MinigamePanel
@onready var minigame_slider: ColorRect = $UI/MinigamePanel/Track/Slider
@onready var minigame_zone: ColorRect = $UI/MinigamePanel/Track/Zone

@onready var journal_panel: Control = $UI/JournalPanel
@onready var journal_list: VBoxContainer = $UI/JournalPanel/BG/Scroll/JournalList

@onready var inspect_overlay: Control = $UI/InspectOverlay

# ==============================
# СОСТОЯНИЕ
# ==============================
enum State { INTRO, WORKING, MINIGAME, SHIFT_END, INSPECT, DEAD }
var state: State = State.INTRO

var current_shift: int = 1
var shift_time: float = 0.0
var current_object: ColorRect = null
var object_x: float = 0.0
var object_progress: int = 0
var conveyor_paused: bool = false
var current_object_index: int = 0

var correct_count: int = 0
var wrong_count: int = 0
var strike_count: int = 0

var slider_pos: float = 0.0
var slider_dir: float = 1.0
var minigame_active: bool = false
const TRACK_WIDTH: float = 400.0
var zone_center: float = 0.5
var zone_width: float = 0.2

var guard_talk_timer: float = 12.0
var intro_timer: float = 0.0
var shift_end_timer: float = 0.0

var is_dialog_active: bool = false
var journal_open: bool = false
var inspect_mode: bool = false

var guard_shifts_found: Array = []
var sniper_shifts_found: Array = []
var known_worker_count: bool = false
var known_box_count: bool = false
var known_elevator: bool = false

var guard_changing: bool = false
var sniper_changing: bool = false
var guard_last_checked_hour: float = -1.0
var sniper_last_checked_hour: float = -1.0

# ==============================
# READY
# ==============================
func _ready() -> void:
	randomize()
	
	for i in range(TOTAL_OBJECTS):
		var cell = ColorRect.new()
		cell.name = "Cell" + str(i)
		cell.color = Color(0.2, 0.2, 0.2)
		cell.custom_minimum_size = Vector2(28, 20)
		progress_bar.add_child(cell)
	
	await get_tree().process_frame
	if player and player.has_method("set_movement_blocked"):
		player.set_movement_blocked(true)
	
	if camera:
		camera.enabled = true
		camera.top_level = true
		camera.global_position = player.global_position
	
	inspect_btn.visible = false
	journal_btn.visible = false
	escape_hint.visible = false
	journal_panel.visible = false
	inspect_overlay.visible = false
	minigame_panel.visible = false
	hint_label.visible = false
	dialog_panel.visible = false
	
	inspect_btn.pressed.connect(_on_inspect_pressed)
	journal_btn.pressed.connect(_on_journal_pressed)
	
	intro_timer = 0.0
	state = State.INTRO

# ==============================
# PROCESS
# ==============================
func _process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	_process_clock(delta)
	_process_shift_changes()
	
	match state:
		State.INTRO:
			intro_timer += delta
			if intro_timer >= 1.0:
				state = State.WORKING
				_spawn_next_object()
		State.WORKING:
			_process_working(delta)
		State.MINIGAME:
			_process_minigame(delta)
		State.SHIFT_END:
			_process_shift_end(delta)
		State.INSPECT:
			pass
	
	if not is_dialog_active and state != State.SHIFT_END and state != State.DEAD:
		_process_guard_talk(delta)

func _process_clock(delta: float) -> void:
	if state == State.SHIFT_END:
		return
	shift_time += delta / REAL_SHIFT_DURATION
	shift_time = clamp(shift_time, 0.0, 1.0)
	_update_clock_label()

func _current_hour() -> float:
	return SHIFT_START_HOUR + shift_time * SHIFT_DURATION_HOURS

func _update_clock_label() -> void:
	var hour = _current_hour()
	var h = int(hour)
	var m = int((hour - h) * 60)
	if m < 15:
		m = 0
	elif m < 45:
		m = 30
	else:
		m = 0
		h += 1
		if h > int(SHIFT_END_HOUR):
			h = int(SHIFT_END_HOUR)
	if clock_label:
		clock_label.text = "%02d:%02d" % [h, m]

func _process_shift_changes() -> void:
	var hour = _current_hour()
	for shift_hour in GUARD_SHIFTS:
		if guard_last_checked_hour < shift_hour and hour >= shift_hour:
			_on_guard_shift_change(shift_hour)
	guard_last_checked_hour = hour
	for shift_hour in SNIPER_SHIFTS:
		if sniper_last_checked_hour < shift_hour and hour >= shift_hour:
			_on_sniper_shift_change(shift_hour)
	sniper_last_checked_hour = hour

func _on_guard_shift_change(hour: float) -> void:
	if guard_changing:
		return
	guard_changing = true
	if guard_rect:
		var tween = create_tween()
		tween.tween_property(guard_rect, "modulate:a", 0.0, 2.5)
		tween.tween_property(guard_rect, "modulate:a", 1.0, 2.5)
	await get_tree().create_timer(5.0).timeout
	guard_changing = false

func _on_sniper_shift_change(hour: float) -> void:
	if sniper_changing:
		return
	sniper_changing = true
	if sniper_rect:
		var tween = create_tween()
		tween.tween_property(sniper_rect, "modulate:a", 0.0, 2.5)
		tween.tween_property(sniper_rect, "modulate:a", 1.0, 2.5)
	await get_tree().create_timer(5.0).timeout
	sniper_changing = false

func _process_working(delta: float) -> void:
	if current_object == null or conveyor_paused:
		return
	# Коробки едут справа налево
	object_x -= OBJECT_SPEED * delta
	current_object.position.x = object_x
	
	if object_progress < NUM_NPC_FISHES:
		# NPC-рыбки от последней к первой: 4-я (правая) ближе к спавну
		var npc_order = NUM_NPC_FISHES - 1 - object_progress
		var fish_x = FISH_START_X + npc_order * FISH_SPACING
		if object_x <= fish_x + 25:
			_reach_fish(npc_order)
			return
	
	if object_x <= PLAYER_TURN_X + 25:
		_reach_player()

func _spawn_next_object() -> void:
	if current_object_index >= TOTAL_OBJECTS:
		_end_shift()
		return
	
	current_object = ColorRect.new()
	current_object.name = "Object" + str(current_object_index)
	current_object.color = OBJECT_COLORS[0]
	current_object.size = Vector2(40, 40)
	current_object.position = Vector2(OBJECT_SPAWN_X, CONVEYOR_Y - 20)
	objects_layer.add_child(current_object)
	
	object_x = OBJECT_SPAWN_X
	object_progress = 0
	conveyor_paused = false

func _reach_fish(fish_index: int) -> void:
	conveyor_paused = true
	if fish_index < 0 or fish_index >= npc_fishes.size():
		conveyor_paused = false
		return
	var fish = npc_fishes[fish_index]
	
	if fish is ColorRect:
		var orig_color = fish.color
		var tween = create_tween()
		tween.tween_property(fish, "color", COLOR_YELLOW, 0.08)
		tween.tween_property(fish, "color", orig_color, 0.08)
		tween.tween_property(fish, "color", COLOR_YELLOW, 0.08)
		tween.tween_property(fish, "color", orig_color, 0.08)
	
	object_progress += 1
	var idx = clamp(object_progress, 0, OBJECT_COLORS.size() - 1)
	if current_object:
		current_object.color = OBJECT_COLORS[idx]
	
	await get_tree().create_timer(0.3).timeout
	conveyor_paused = false

func _reach_player() -> void:
	conveyor_paused = true
	state = State.MINIGAME
	minigame_active = true
	minigame_panel.visible = true
	hint_label.visible = true
	
	zone_center = randf_range(0.3, 0.7)
	zone_width = randf_range(0.12, 0.22)
	
	var zw = TRACK_WIDTH * zone_width
	var zx = TRACK_WIDTH * zone_center - zw / 2
	minigame_zone.size.x = zw
	minigame_zone.position.x = zx
	
	slider_pos = 0.0
	slider_dir = 1.0
	minigame_slider.position.x = 0

func _process_minigame(delta: float) -> void:
	if not minigame_active:
		return
	# Ползунок теперь медленнее: 0.8 вместо 1.6
	slider_pos += slider_dir * 0.8 * delta
	if slider_pos >= 1.0:
		slider_pos = 1.0
		slider_dir = -1.0
	elif slider_pos <= 0.0:
		slider_pos = 0.0
		slider_dir = 1.0
	minigame_slider.position.x = slider_pos * TRACK_WIDTH

func _process_shift_end(delta: float) -> void:
	shift_end_timer += delta
	for fish in npc_fishes:
		fish.position.x += 150 * delta
	if player:
		player.position.x += 150 * delta
	if shift_end_timer >= 8.0:
		_start_new_shift()

func _process_guard_talk(delta: float) -> void:
	guard_talk_timer -= delta
	if guard_talk_timer <= 0.0:
		guard_talk_timer = randf_range(12.0, 22.0)
		var phrases = [
			"я за вами слежу...",
			"работаем, работаем...",
			"не отлынивать!",
			"ещё одна смена, и всё...",
			"не расслабляться.",
		]
		_show_dialog(phrases[randi() % phrases.size()], 2.0)

func _show_dialog(text: String, duration: float) -> void:
	if is_dialog_active:
		return
	is_dialog_active = true
	dialog_panel.visible = true
	dialog_label.text = text
	await get_tree().create_timer(duration).timeout
	dialog_panel.visible = false
	is_dialog_active = false

# ==============================
# ВВОД
# ==============================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if state == State.MINIGAME and minigame_active:
			_press_button()
			get_viewport().set_input_as_handled()
			return
		if state == State.WORKING and _near_elevator():
			_enter_elevator()
			get_viewport().set_input_as_handled()
			return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			# Осмотр только со второй смены
			if current_shift < 2:
				return
			if state == State.INSPECT:
				_exit_inspect()
			elif state == State.WORKING:
				_enter_inspect()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_J:
			# Журнал только со второй смены
			if current_shift < 2:
				return
			if journal_open:
				_on_journal_close()
			else:
				_open_journal()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if journal_open:
				_on_journal_close()
			elif state == State.INSPECT:
				_exit_inspect()
			get_viewport().set_input_as_handled()

func _press_button() -> void:
	minigame_active = false
	hint_label.visible = false
	minigame_panel.visible = false
	
	var z_min = zone_center - zone_width / 2
	var z_max = zone_center + zone_width / 2
	var is_correct = slider_pos >= z_min and slider_pos <= z_max
	
	if is_correct:
		correct_count += 1
		_mark_progress(current_object_index, true)
		if current_object:
			current_object.color = OBJECT_COLORS[OBJECT_COLORS.size() - 1]
	else:
		wrong_count += 1
		_mark_progress(current_object_index, false)
		if current_object:
			current_object.color = COLOR_RED
		_handle_strike()
	
	current_object_index += 1
	
	await get_tree().create_timer(0.25).timeout
	if current_object and is_instance_valid(current_object):
		var flash = ColorRect.new()
		flash.color = Color(1, 1, 1, 0.9)
		flash.size = Vector2(60, 60)
		flash.position = current_object.position - Vector2(30, 30)
		flash.z_index = 100
		objects_layer.add_child(flash)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(current_object, "scale", Vector2(1.3, 0.7), 0.2)
		tween.tween_property(current_object, "modulate:a", 0.0, 0.2)
		tween.tween_property(flash, "modulate:a", 0.0, 0.2)
		await tween.finished
		
		if is_instance_valid(current_object):
			current_object.queue_free()
		if is_instance_valid(flash):
			flash.queue_free()
		current_object = null
	
	if current_object_index >= TOTAL_OBJECTS:
		_end_shift()
	else:
		state = State.WORKING
		_spawn_next_object()

func _mark_progress(index: int, correct: bool) -> void:
	if index < 0 or index >= progress_bar.get_child_count():
		return
	var cell = progress_bar.get_child(index) as ColorRect
	if cell:
		cell.color = COLOR_GREEN if correct else COLOR_RED

# ==============================
# МЕХАНИКА КАРЫ
# ==============================
func _handle_strike() -> void:
	strike_count += 1
	if strike_count == 3:
		_show_dialog("ЭЙ, ЧТО С ТОБОЙ НЕ ТАК?!", 2.5)
	elif strike_count >= 5:
		_kill_player()

func _can_punish() -> bool:
	var guard_alive = guard_rect != null and guard_rect.modulate.a > 0.5
	var sniper_alive = sniper_rect != null and sniper_rect.modulate.a > 0.5
	return guard_alive or sniper_alive

func _kill_player() -> void:
	if state == State.DEAD:
		return
	if not _can_punish():
		strike_count = 0
		return
	
	state = State.DEAD
	conveyor_paused = true
	minigame_panel.visible = false
	hint_label.visible = false
	
	_show_dialog("С СУБЪЕКТОМ 7-БЕТА ЧТО-ТО НЕ ТАК, ОБНАРУЖЕНО ДЕВИАНТСКОЕ ПОВЕДЕНИЕ", 3.5)
	
	if sniper_rect:
		var tween = create_tween()
		tween.tween_property(sniper_rect, "color", COLOR_YELLOW, 0.1)
		tween.tween_property(sniper_rect, "color", Color(0.4, 0.4, 0.5), 0.15)
	
	await get_tree().create_timer(3.5).timeout
	if player and player.has_method("die"):
		player.die()

# ==============================
# СМЕНА
# ==============================
func _end_shift() -> void:
	state = State.SHIFT_END
	shift_end_timer = 0.0
	conveyor_paused = true
	_show_dialog("РАБОТА НА СЕГОДНЯ ВЫПОЛНЕНА, ВСЕ НА ТЕХ ОБСЛУЖИВАНИЕ И НАЗАД", 4.0)
	if wrong_count == 0:
		if has_node("/root/Achievements"):
			Achievements.unlock_worker_of_month()

func _start_new_shift() -> void:
	current_shift += 1
	current_object_index = 0
	correct_count = 0
	wrong_count = 0
	strike_count = 0
	shift_time = 0.0
	guard_last_checked_hour = -1.0
	sniper_last_checked_hour = -1.0
	
	for i in range(progress_bar.get_child_count()):
		var cell = progress_bar.get_child(i) as ColorRect
		if cell:
			cell.color = Color(0.2, 0.2, 0.2)
	
	for i in range(npc_fishes.size()):
		npc_fishes[i].position.x = FISH_START_X + i * FISH_SPACING - 25
	if player:
		player.position.x = PLAYER_TURN_X
	
	# Кнопки и журнал — только со второй смены
	if current_shift >= 2:
		inspect_btn.visible = true
		journal_btn.visible = true
	else:
		inspect_btn.visible = false
		journal_btn.visible = false
	
	_update_escape_hint()
	state = State.WORKING
	_spawn_next_object()

func _update_escape_hint() -> void:
	if guard_shifts_found.size() < 3 or sniper_shifts_found.size() < 3:
		escape_hint.visible = false
		return
	var hour = _current_hour()
	var next_window = -1.0
	for gh in GUARD_SHIFTS:
		if not SNIPER_SHIFTS.has(gh):
			if gh > hour:
				next_window = gh
				break
			elif next_window < 0:
				next_window = gh
	if next_window < 0:
		escape_hint.visible = false
		return
	if next_window > hour:
		escape_hint.text = "МОЖНО НАЧАТЬ ПОБЕГ СЕГОДНЯ В %02d:00" % int(next_window)
	else:
		escape_hint.text = "МОЖНО НАЧАТЬ ПОБЕГ ЗАВТРА В %02d:00" % int(next_window)
	escape_hint.visible = true

# ==============================
# ОСМОТР
# ==============================
func _on_inspect_pressed() -> void:
	if current_shift < 2:
		return
	if state == State.INSPECT:
		_exit_inspect()
	else:
		_enter_inspect()

func _enter_inspect() -> void:
	if current_shift < 2:
		return
	if state != State.WORKING:
		return
	state = State.INSPECT
	inspect_mode = true
	inspect_overlay.visible = true
	conveyor_paused = true
	_update_journal_options()

func _exit_inspect() -> void:
	if state != State.INSPECT:
		return
	state = State.WORKING
	inspect_mode = false
	inspect_overlay.visible = false
	conveyor_paused = false

# ==============================
# ЖУРНАЛ
# ==============================
func _on_journal_pressed() -> void:
	if current_shift < 2:
		return
	if journal_open:
		_on_journal_close()
	else:
		_open_journal()

func _open_journal() -> void:
	if current_shift < 2:
		return
	journal_open = true
	journal_panel.visible = true
	_update_journal_options()

func _on_journal_close() -> void:
	journal_open = false
	journal_panel.visible = false

func _update_journal_options() -> void:
	for c in journal_list.get_children():
		c.queue_free()
	
	_add_journal_line("=== ЗАПИСИ ===", Color.BLACK, 18)
	_add_journal_line("", Color.BLACK, 14)
	_add_journal_line("СМЕНЫ КАРАУЛА:", Color.BLACK, 16)
	if guard_shifts_found.is_empty():
		_add_journal_line("   (нет данных)", Color.DARK_GRAY, 14)
	else:
		for h in guard_shifts_found:
			_add_journal_line("   %02d:00" % int(h), Color.DARK_GREEN, 14)
	_add_journal_line("", Color.BLACK, 14)
	_add_journal_line("СМЕНЫ СНАЙПЕРА:", Color.BLACK, 16)
	if sniper_shifts_found.is_empty():
		_add_journal_line("   (нет данных)", Color.DARK_GRAY, 14)
	else:
		for h in sniper_shifts_found:
			_add_journal_line("   %02d:00" % int(h), Color.DARK_BLUE, 14)
	_add_journal_line("", Color.BLACK, 14)
	_add_journal_line("ПРОЧЕЕ:", Color.BLACK, 16)
	if known_worker_count:
		_add_journal_line("   Работников: " + str(NUM_NPC_FISHES + 1), Color.DARK_GRAY, 14)
	if known_box_count:
		_add_journal_line("   Коробок за смену: " + str(TOTAL_OBJECTS), Color.DARK_GRAY, 14)
	if known_elevator:
		_add_journal_line("   Лифт склада справа", Color.DARK_GRAY, 14)
	_add_journal_line("", Color.BLACK, 14)
	
	for opt in _get_journal_options():
		var btn = Button.new()
		btn.text = "ЗАПИСАТЬ: " + opt["label"]
		btn.custom_minimum_size = Vector2(680, 30)
		btn.pressed.connect(_on_journal_record.bind(opt["id"], opt.get("hour", -1.0)))
		journal_list.add_child(btn)

func _add_journal_line(text: String, color: Color, font_size: int) -> void:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	journal_list.add_child(l)

func _get_journal_options() -> Array:
	var opts: Array = []
	var current_h = _current_hour()
	for h in GUARD_SHIFTS:
		if not guard_shifts_found.has(h) and current_h >= h:
			opts.append({"id": "guard_shift", "hour": h, "label": "Смена караула в %02d:00" % int(h)})
	for h in SNIPER_SHIFTS:
		if not sniper_shifts_found.has(h) and current_h >= h:
			opts.append({"id": "sniper_shift", "hour": h, "label": "Смена снайпера в %02d:00" % int(h)})
	if not known_worker_count:
		opts.append({"id": "worker_count", "label": "Количество работников"})
	if not known_box_count:
		opts.append({"id": "box_count", "label": "Количество коробок за смену"})
	if not known_elevator:
		opts.append({"id": "elevator", "label": "Расположение лифта склада"})
	return opts

func _on_journal_record(id: String, hour: float) -> void:
	match id:
		"guard_shift":
			if not guard_shifts_found.has(hour):
				guard_shifts_found.append(hour)
		"sniper_shift":
			if not sniper_shifts_found.has(hour):
				sniper_shifts_found.append(hour)
		"worker_count":
			known_worker_count = true
		"box_count":
			known_box_count = true
		"elevator":
			known_elevator = true
	
	if guard_shifts_found.size() >= 3 and sniper_shifts_found.size() >= 3 \
		and known_worker_count and known_box_count and known_elevator:
		if has_node("/root/Achievements"):
			Achievements.unlock_scout()
	
	_update_journal_options()
	_update_escape_hint()

# ==============================
# ЛИФТ / ПОБЕГ
# ==============================
func _near_elevator() -> bool:
	if player == null or elevator_door == null:
		return false
	return player.global_position.distance_to(elevator_door.global_position) < 150

func _enter_elevator() -> void:
	var hour = _current_hour()
	var in_window = false
	for gh in GUARD_SHIFTS:
		if abs(gh - hour) < 0.2 and not SNIPER_SHIFTS.has(gh):
			in_window = true
			break
	
	if not in_window:
		_show_dialog("ЛИФТ ЗАКРЫТ. НУЖНО ДОЖДАТЬСЯ СМЕНЫ КАРАУЛА.", 2.5)
		return
	
	if guard_shifts_found.size() < 3 or sniper_shifts_found.size() < 3:
		_show_dialog("Я НЕ ЗНАЮ РАСПИСАНИЯ. НУЖНО БОЛЬШЕ РАЗВЕДКИ.", 2.5)
		return
	
	if has_node("/root/Achievements"):
		Achievements.unlock_freedom()
	_show_dialog("ПОБЕГ...", 1.5)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act3HallwayLevel.tscn")
