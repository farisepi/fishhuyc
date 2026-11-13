extends Node

@onready var bg: ColorRect = $Canvas/BG
@onready var loading_label: Label = $Canvas/LoadingLabel

const INTRO_DURATION: float = 3.5
const DOT_INTERVAL: float = 0.4

var _dots: int = 0
var _dot_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dots = 0
	_dot_timer = 0.0
	loading_label.text = "загрузка"

	loading_label.modulate.a = 0.0
	bg.modulate.a = 1.0

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(loading_label, "modulate:a", 1.0, 0.4)
	_make_save_notice()


	var level = Global.last_save_level
	var target = ""
	if level >= 2:
		target = "res://GameScenes/MenuScenes/FactoryMenuScenes/FactoryMainMenuScene/Menu_Factory_MainMenu_Scene.tscn"
	else:
		target = "res://GameScenes/MenuScenes/AquariumMenuScenes/AquariumMainMenuScene/Menu_Aquarium_MainMenu_Scene.tscn"


	ResourceLoader.load_threaded_request(target)


	await get_tree().create_timer(INTRO_DURATION).timeout


	while true:
		var status = ResourceLoader.load_threaded_get_status(target)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("BootLoader: не удалось загрузить " + target)
			return
		await get_tree().process_frame

	var packed = ResourceLoader.load_threaded_get(target)
	var scene_instance = packed.instantiate()

	var tree = get_tree()
	var old_scene = tree.current_scene

	tree.root.add_child(scene_instance)
	tree.current_scene = scene_instance

	if old_scene and old_scene != scene_instance:
		old_scene.queue_free()

	await tree.process_frame
	await tree.process_frame
	await tree.process_frame

	var fade = create_tween()
	fade.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	fade.tween_property(bg, "modulate:a", 0.0, 0.8)
	fade.parallel().tween_property(loading_label, "modulate:a", 0.0, 0.8)
	if _notice:
		fade.parallel().tween_property(_notice, "modulate:a", 0.0, 0.5)
	await fade.finished

	queue_free()

func _process(_delta: float) -> void:
	pass

const SAVE_ICON := preload("res://GameScripts/UIScripts/SaveIconScripts/Save_Icon.gd")
var _notice: Control = null

func _make_save_notice() -> void:
	_notice = Control.new()
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice.size = Vector2(1152, 648)
	$Canvas.add_child(_notice)
	var icon = SAVE_ICON.new()
	_notice.add_child(icon)
	icon.position = Vector2(576 - icon.size.x * 0.5, 230)
	var l = Label.new()
	l.text = "Когда в углу экрана появляется этот знак,\nигра сохраняется. Не закрывайте её в это время."
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.85, 0.88, 0.94))
	l.add_theme_constant_override("line_spacing", 6)
	l.size = Vector2(900, 60)
	l.position = Vector2(126, 320)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice.add_child(l)
	_notice.modulate.a = 0.0
	var tw = _notice.create_tween()
	tw.tween_property(_notice, "modulate:a", 1.0, 0.5)
