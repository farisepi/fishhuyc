class_name ChatterController
extends Node


signal chatter_started()
signal line_shown(line: ChatterLine, index: int)
signal line_finished(line: ChatterLine, index: int)
signal chatter_stopped()
signal silent_line_hit(line: ChatterLine, index: int)
signal swear_typed()


@export_group("Lines")
@export var lines: Array[ChatterLine] = []
@export var loop: bool = true

@export_group("Characters")
@export var scientist_node: NodePath = NodePath()
@export var mechanic_node: NodePath = NodePath()
@export var portrait_scientist: Texture2D = null
@export var portrait_mechanic: Texture2D = null

@export_group("Sound")
@export var sound_manager: Node = null

@export_group("Camera")
@export var player_camera: NodePath = NodePath()
@export_range(0.0, 500.0, 10.0) var far_threshold: float = 50.0

@export_group("Timing")
@export_range(0.01, 0.2, 0.005) var typing_speed: float = 0.025
@export_range(0.5, 10.0, 0.1) var default_display_time: float = 2.5
@export var autostart: bool = false

@export_group("Near Panel Settings")
@export var near_panel_width: float = 120.0

@export_enum("Scientist", "Mechanic") var scientist_anchor: int = 0
@export_enum("Left", "Right") var scientist_side: int = 0
@export var scientist_panel_offset: Vector2 = Vector2(0, -50)

@export_enum("Scientist", "Mechanic") var mechanic_anchor: int = 1
@export_enum("Left", "Right") var mechanic_side: int = 1
@export var mechanic_panel_offset: Vector2 = Vector2(0, -50)

@export_group("Far Panel Settings")
@export var far_panel_width: float = 400.0
@export var far_panel_height: float = 80.0
@export var far_panel_margin_bottom: float = 20.0


var _lines_queue: Array[ChatterLine] = []
var _current_index: int = -1
var _active: bool = false
var _typing: bool = false

var _segments: Array[Dictionary] = []
var _seg_index: int = 0
var _seg_char: int = 0
var _typed_text: String = ""
var _full_text: String = ""

var _sound_manager: Node = null
var _timer: Timer = null
var _current_line: ChatterLine = null

var _scientist: Node2D = null
var _mechanic: Node2D = null
var _camera: Camera2D = null


func _ready() -> void:
	_scientist     = get_node_or_null(scientist_node) as Node2D
	_mechanic      = get_node_or_null(mechanic_node)  as Node2D
	_camera        = get_node_or_null(player_camera)  as Camera2D
	_sound_manager = sound_manager


	_timer = Timer.new()
	_timer.one_shot = false
	_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_timer.timeout.connect(_on_timer)
	add_child(_timer)

	if autostart:
		start()


func start() -> void:
	_interrupted = false
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

func pause_chatter() -> void:
	_timer.stop()

func resume_chatter() -> void:
	if _active and not _typing:
		_timer.start(default_display_time)
	elif _active and _typing:
		_timer.start(typing_speed)

var skippable: bool = false

func skip_line() -> void:
	if not _active or _current_line == null:
		return
	if _typing:
		while _seg_index < _segments.size():
			var seg: Dictionary = _segments[_seg_index]
			var rest: String = seg["text"].substr(_seg_char) if not seg["swear"] else seg["text"]
			if seg["swear"]:
				_typed_text += "[color=#FF3333]" + rest + "[/color]"
			else:
				_typed_text += rest
			_seg_index += 1
			_seg_char = 0
		_typing = false
		line_finished.emit(_current_line, _current_index)
		_timer.stop()
		var wait = _current_line.display_time if _current_line.display_time > 0.0 else default_display_time
		_timer.start(max(0.6, wait))
	else:
		_timer.stop()
		_show_next_line()

func interrupt() -> void:
	if not _active or _current_line == null:
		return
	_timer.stop()
	if _typing:
		_typed_text = _typed_text.rstrip(" ,") + "..."
		_typing = false
		_seg_index = _segments.size()
	_interrupted = true

var _interrupted: bool = false

func get_typed_text() -> String:
	return _typed_text

func get_current_speaker() -> ChatterLine.Speaker:
	if _current_line:
		return _current_line.speaker
	return ChatterLine.Speaker.SCIENTIST

func get_near_panel_position() -> Vector2:
	if not _current_line:
		return Vector2.ZERO

	var is_mechanic = (_current_line.speaker == ChatterLine.Speaker.MECHANIC)
	var anchor_idx  = mechanic_anchor if is_mechanic else scientist_anchor
	var side        = mechanic_side   if is_mechanic else scientist_side
	var extra       = mechanic_panel_offset if is_mechanic else scientist_panel_offset

	var anchor_node: Node2D = null
	if anchor_idx == 0:
		anchor_node = _scientist
	else:
		anchor_node = _mechanic

	if not anchor_node:
		return Vector2.ZERO

	var h_offset: float
	if side == 0:
		h_offset = -near_panel_width - 4.0
	else:
		h_offset = 4.0

	return anchor_node.global_position + Vector2(h_offset, 0.0) + extra

func get_current_portrait() -> Texture2D:
	if not _current_line:
		return null
	if _current_line.speaker == ChatterLine.Speaker.MECHANIC:
		return portrait_mechanic
	return portrait_scientist

func compute_display_mode() -> Dictionary:
	if not _camera or not _scientist:
		return {"near": true, "fade": 0.0, "phantom_alpha": 0.0}

	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = _camera.zoom.x
	var cam_left   = _camera.global_position.x - viewport_size.x * 0.5 / zoom
	var cam_right  = _camera.global_position.x + viewport_size.x * 0.5 / zoom
	var cam_top    = _camera.global_position.y - viewport_size.y * 0.5 / zoom
	var cam_bottom = _camera.global_position.y + viewport_size.y * 0.5 / zoom

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

	if _current_line.is_silent:
		silent_line_hit.emit(_current_line, _current_index)
		stop()
		return

	_build_segments(_current_line)
	_typed_text = ""
	_full_text = tr(_current_line.text)
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
		_segments.append({"text": tr(line.text), "swear": false})
		return

	var remaining = tr(line.text)
	while not remaining.is_empty():
		var earliest_pos = -1
		var earliest_word = ""
		for sw0 in line.swear_words:
			var sw = tr(sw0)
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
	if not _active or _interrupted:
		return

	if _typing:
		_tick_typing()
	else:
		_show_next_line()

func _play_typing_sound() -> void:
	if not _current_line or not _sound_manager:
		return
	if _current_line.speaker == ChatterLine.Speaker.MECHANIC:
		_sound_manager.play_mechanic()
	else:
		_sound_manager.play_scientist()

func _tick_typing() -> void:
	if _seg_index >= _segments.size():
		_typing = false
		line_finished.emit(_current_line, _current_index)
		var wait = _current_line.display_time if _current_line.display_time > 0.0 else default_display_time
		_timer.start(wait)
		return

	var seg: Dictionary = _segments[_seg_index]

	if seg["swear"]:
		_typed_text += "[color=#FF3333]" + seg["text"] + "[/color]"
		swear_typed.emit()
		_seg_index += 1
		_seg_char = 0
		_timer.start(typing_speed * 3.0)
	else:
		var seg_text: String = seg["text"]
		if _seg_char < seg_text.length():
			_typed_text += seg_text[_seg_char]
			if seg_text[_seg_char] != " " and seg_text[_seg_char] != "\n":
				_play_typing_sound()
			_seg_char += 1
			_timer.start(typing_speed)
		else:
			_seg_index += 1
			_seg_char = 0
			_timer.start(typing_speed)
