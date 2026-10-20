## Контроллер фонового диалога между персонажами.
## Воспроизводит два режима:
##   NEAR — маленькая панель прямо над спикером
##   FAR  — широкая панель внизу экрана с портретом + фантомы
##
## Путь: res://GameScripts/Dialogue/ChatterController.gd
##
## Добавь в сцену, заполни lines[] в инспекторе, вызови start().
class_name ChatterController
extends Node

# ---------------------------------------------------------------------------
# Сигналы
# ---------------------------------------------------------------------------

signal chatter_started()
signal line_shown(line: ChatterLine, index: int)
signal line_finished(line: ChatterLine, index: int)
signal chatter_stopped()
## Срабатывает на is_silent реплике
signal silent_line_hit(line: ChatterLine, index: int)

# ---------------------------------------------------------------------------
# Инспектор — контент
# ---------------------------------------------------------------------------

@export_group("Lines")
## Список реплик. Заполняется в инспекторе ресурсами ChatterLine.
@export var lines: Array[ChatterLine] = []
## Если true — после последней реплики начать сначала
@export var loop: bool = true

@export_group("Characters")
## Нода учёного (AnimatedSprite2D или Node2D)
@export var scientist_node: NodePath = NodePath()
## Нода механика
@export var mechanic_node: NodePath = NodePath()
## Портрет учёного для far-режима
@export var portrait_scientist: Texture2D = null
## Портрет механика для far-режима
@export var portrait_mechanic: Texture2D = null

@export_group("Camera")
## Камера игрока (для определения near/far)
@export var player_camera: NodePath = NodePath()
## Дистанция (px от края камеры) при которой переключаемся в far-режим
@export_range(0.0, 500.0, 10.0) var far_threshold: float = 50.0

@export_group("Timing")
## Скорость печати (сек/символ)
@export_range(0.01, 0.2, 0.005) var typing_speed: float = 0.025
## Время отображения реплики после окончания печати
@export_range(0.5, 10.0, 0.1) var default_display_time: float = 2.5
## Запустить автоматически при _ready()
@export var autostart: bool = false

@export_group("Near Panel Settings")
## Ширина near-панели
@export var near_panel_width: float = 120.0

## --- Учёный ---
## К какому персонажу привязана near-панель учёного
@export_enum("Scientist", "Mechanic") var scientist_anchor: int = 0
## Сторона панели учёного: LEFT — слева от персонажа, RIGHT — справа
@export_enum("Left", "Right") var scientist_side: int = 0
## Дополнительный оффсет учёного (добавляется поверх автоматического)
@export var scientist_panel_offset: Vector2 = Vector2(0, -50)

## --- Механик ---
## К какому персонажу привязана near-панель механика
@export_enum("Scientist", "Mechanic") var mechanic_anchor: int = 1
## Сторона панели механика: LEFT — слева от персонажа, RIGHT — справа
@export_enum("Left", "Right") var mechanic_side: int = 1
## Дополнительный оффсет механика (добавляется поверх автоматического)
@export var mechanic_panel_offset: Vector2 = Vector2(0, -50)

@export_group("Far Panel Settings")
## Ширина far-панели
@export var far_panel_width: float = 400.0
## Высота far-панели
@export var far_panel_height: float = 80.0
## Отступ от нижнего края экрана
@export var far_panel_margin_bottom: float = 20.0

# ---------------------------------------------------------------------------
# Приватное состояние
# ---------------------------------------------------------------------------

var _lines_queue: Array[ChatterLine] = []
var _current_index: int = -1
var _active: bool = false
var _typing: bool = false

# Сегменты текущей реплики: [{text, swear}]
var _segments: Array[Dictionary] = []
var _seg_index: int = 0
var _seg_char: int = 0
var _typed_text: String = ""   # накопленный BBCode-текст
var _full_text: String = ""    # чистый текст без BBCode

var _timer: Timer = null
var _current_line: ChatterLine = null

# Ноды персонажей и камеры (разрешаются в _ready)
var _scientist: Node2D = null
var _mechanic: Node2D = null
var _camera: Camera2D = null

# ---------------------------------------------------------------------------

func _ready() -> void:
	_scientist = get_node_or_null(scientist_node) as Node2D
	_mechanic  = get_node_or_null(mechanic_node)  as Node2D
	_camera    = get_node_or_null(player_camera)  as Camera2D
	
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_timer.timeout.connect(_on_timer)
	add_child(_timer)
	
	if autostart:
		start()

# ---------------------------------------------------------------------------
# Публичный API
# ---------------------------------------------------------------------------

func start() -> void:
	if lines.is_empty():
		push_warning("ChatterController: lines пустой!")
		return
	_reset_queue()
	_active = true
	_show_next_line()
	chatter_started.emit()

func stop() -> void:
	_active = false
	_typing = false
	_timer.stop()
	chatter_stopped.emit()

func is_active() -> bool:
	return _active

## Вызывается когда уровень ставится на паузу — чтобы не продолжало тикать
func pause_chatter() -> void:
	_timer.stop()

func resume_chatter() -> void:
	if _active and not _typing:
		_timer.start(default_display_time)
	elif _active and _typing:
		_timer.start(typing_speed)

## Получить текущий typed-текст (для отображения в UI)
func get_typed_text() -> String:
	return _typed_text

## Кто сейчас говорит
func get_current_speaker() -> ChatterLine.Speaker:
	if _current_line:
		return _current_line.speaker
	return ChatterLine.Speaker.SCIENTIST

## Позиция панели в near-режиме (world-space).
## Учитывает: к какому персонажу привязана панель (anchor),
## с какой стороны она рисуется (side) и дополнительный оффсет.
func get_near_panel_position() -> Vector2:
	if not _current_line:
		return Vector2.ZERO
	
	var is_mechanic = (_current_line.speaker == ChatterLine.Speaker.MECHANIC)
	var anchor_idx  = mechanic_anchor if is_mechanic else scientist_anchor
	var side        = mechanic_side   if is_mechanic else scientist_side
	var extra       = mechanic_panel_offset if is_mechanic else scientist_panel_offset
	
	# Нода-якорь: 0 = учёный, 1 = механик
	var anchor_node: Node2D = null
	if anchor_idx == 0:
		anchor_node = _scientist
	else:
		anchor_node = _mechanic
	
	if not anchor_node:
		return Vector2.ZERO
	
	# Горизонтальное смещение: LEFT — панель левее персонажа, RIGHT — правее
	var h_offset: float
	if side == 0:  # Left
		h_offset = -near_panel_width - 4.0
	else:           # Right
		h_offset = 4.0
	
	return anchor_node.global_position + Vector2(h_offset, 0.0) + extra

## Портрет текущего спикера
func get_current_portrait() -> Texture2D:
	if not _current_line:
		return null
	if _current_line.speaker == ChatterLine.Speaker.MECHANIC:
		return portrait_mechanic
	return portrait_scientist

## Вычислить режим: true = near, false = far
## Возвращает также fade (0=near, 1=far) для плавного перехода
func compute_display_mode() -> Dictionary:
	if not _camera or not _scientist:
		return {"near": true, "fade": 0.0, "phantom_alpha": 0.0}
	
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = _camera.zoom.x
	var cam_left   = _camera.global_position.x - viewport_size.x * 0.5 / zoom
	var cam_right  = _camera.global_position.x + viewport_size.x * 0.5 / zoom
	var cam_top    = _camera.global_position.y - viewport_size.y * 0.5 / zoom
	var cam_bottom = _camera.global_position.y + viewport_size.y * 0.5 / zoom
	
	# Проверяем учёного (он основной anchor для far/near)
	var sx = _scientist.global_position.x
	var sy = _scientist.global_position.y
	var in_view = (sx >= cam_left and sx <= cam_right and sy >= cam_top and sy <= cam_bottom)
	
	var dist = 0.0
	if not in_view:
		var dx = max(0.0, cam_left - sx) + max(0.0, sx - cam_right)
		var dy = max(0.0, cam_top  - sy) + max(0.0, sy - cam_bottom)
		dist = max(dx, dy)
	
	var fade = clamp(dist / 300.0, 0.0, 1.0) if not in_view else 0.0
	return {
		"near": fade < 0.05,
		"fade": fade,
		"phantom_alpha": fade * 0.25
	}

# ---------------------------------------------------------------------------
# Приватные методы
# ---------------------------------------------------------------------------

func _reset_queue() -> void:
	_lines_queue = lines.duplicate()
	_current_index = -1

func _show_next_line() -> void:
	if not _active:
		return
	
	if _lines_queue.is_empty():
		if loop:
			_reset_queue()
		else:
			stop()
			return
	
	_current_line = _lines_queue.pop_front()
	_current_index += 1
	
	# Немая реплика
	if _current_line.is_silent:
		silent_line_hit.emit(_current_line, _current_index)
		stop()
		return
	
	# Разбить текст на сегменты
	_build_segments(_current_line)
	_typed_text = ""
	_full_text = _current_line.text
	_seg_index = 0
	_seg_char = 0
	_typing = true
	
	line_shown.emit(_current_line, _current_index)
	
	_timer.stop()
	_timer.wait_time = typing_speed
	_timer.start()

func _build_segments(line: ChatterLine) -> void:
	_segments.clear()
	if line.swear_words.is_empty():
		_segments.append({"text": line.text, "swear": false})
		return
	
	# Разбить строку по ругательствам
	var remaining = line.text
	while not remaining.is_empty():
		var earliest_pos = -1
		var earliest_word = ""
		for sw in line.swear_words:
			var pos = remaining.find(sw)
			if pos != -1 and (earliest_pos == -1 or pos < earliest_pos):
				earliest_pos = pos
				earliest_word = sw
		
		if earliest_pos == -1:
			_segments.append({"text": remaining, "swear": false})
			break
		
		if earliest_pos > 0:
			_segments.append({"text": remaining.substr(0, earliest_pos), "swear": false})
		_segments.append({"text": earliest_word, "swear": true})
		remaining = remaining.substr(earliest_pos + earliest_word.length())

func _on_timer() -> void:
	if not _active:
		return
	
	if _typing:
		_tick_typing()
	else:
		# Время показа истекло — следующая реплика
		_show_next_line()

func _tick_typing() -> void:
	if _seg_index >= _segments.size():
		# Печать закончена
		_typing = false
		line_finished.emit(_current_line, _current_index)
		var wait = _current_line.display_time if _current_line.display_time > 0.0 else default_display_time
		_timer.start(wait)
		return
	
	var seg: Dictionary = _segments[_seg_index]
	
	if seg["swear"]:
		# Ругательство — добавляем целиком с цветом, без посимвольной печати
		_typed_text += "[color=#FF3333]" + seg["text"] + "[/color]"
		_seg_index += 1
		_seg_char = 0
		# Небольшая пауза после ругательства
		_timer.start(typing_speed * 3.0)
	else:
		var seg_text: String = seg["text"]
		if _seg_char < seg_text.length():
			_typed_text += seg_text[_seg_char]
			_seg_char += 1
			_timer.start(typing_speed)
		else:
			_seg_index += 1
			_seg_char = 0
			_timer.start(typing_speed)
