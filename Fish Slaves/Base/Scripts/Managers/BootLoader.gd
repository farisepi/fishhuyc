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
	
	
	var level = Global.last_save_level
	var target = ""
	if level >= 2:
		target = "res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuFactory.tscn"
	else:
		target = "res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuAquarium.tscn"
	
	
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
	await fade.finished
	
	queue_free()

func _process(_delta: float) -> void:
	pass
