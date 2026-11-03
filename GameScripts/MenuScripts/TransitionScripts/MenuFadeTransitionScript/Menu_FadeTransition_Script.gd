extends ColorRect
## Global screen fade (autoload "Fade").
## The black overlay lives on its own top CanvasLayer, so it covers the whole screen in
## every scene - world, UI and menus - no matter where the camera is.
## After any scene change it fades back in by itself, so every transition in the game
## is a smooth fade-out -> fade-in.

signal fade_in_finished
signal fade_out_finished

const OUT_TIME := 0.45
const IN_TIME := 0.6

var _tw: Tween = null
var _layer: CanvasLayer = null
var _rect: ColorRect = null
var _last_scene_id: int = 0
var _auto_in_pending: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# the autoload node itself stays invisible; the real overlay is on a CanvasLayer
	color = Color(0, 0, 0, 0)
	mouse_filter = MOUSE_FILTER_IGNORE
	size = Vector2.ZERO
	_layer = CanvasLayer.new()
	_layer.layer = 1024
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	_layer.add_child(_rect)

func _process(_delta: float) -> void:
	var scene = get_tree().current_scene
	var id = scene.get_instance_id() if scene else 0
	if id != _last_scene_id:
		_last_scene_id = id
		if _rect and _rect.modulate.a > 0.01 and not _auto_in_pending:
			_auto_in_pending = true
			_auto_fade_in()

func _auto_fade_in() -> void:
	# let the new scene build its first frames under the black
	await get_tree().process_frame
	await get_tree().process_frame
	_auto_in_pending = false
	fade_in()

func _kill() -> void:
	if _tw and _tw.is_valid():
		_tw.kill()

func is_dark() -> bool:
	return _rect != null and _rect.modulate.a > 0.5

## Fades from the current darkness back to the picture (no-op if already clear).
func fade_in() -> void:
	_kill()
	if _rect == null or _rect.modulate.a <= 0.001:
		fade_in_finished.emit()
		return
	_rect.mouse_filter = MOUSE_FILTER_IGNORE
	_tw = create_tween()
	_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tw.tween_property(_rect, "modulate:a", 0.0, IN_TIME * _rect.modulate.a)
	await _tw.finished
	fade_in_finished.emit()

func fade_out() -> void:
	_kill()
	if _rect == null:
		fade_out_finished.emit()
		return
	# block clicks while the screen goes dark
	_rect.mouse_filter = MOUSE_FILTER_STOP
	_tw = create_tween()
	_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tw.tween_property(_rect, "modulate:a", 1.0, OUT_TIME * (1.0 - _rect.modulate.a) + 0.01)
	await _tw.finished
	fade_out_finished.emit()
