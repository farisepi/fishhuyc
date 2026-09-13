extends Node

@onready var bg: ColorRect = $Canvas/BG
@onready var loading_label: Label = $Canvas/LoadingLabel
@onready var title: Label = $Canvas/Center/Title
@onready var name1: Label = $Canvas/NamesRow/Name1
@onready var separator: Label = $Canvas/NamesRow/Separator
@onready var name2: Label = $Canvas/NamesRow/Name2

const INTRO_DURATION: float = 3.5
const DOT_INTERVAL: float = 0.4

var _dots: int = 0
var _dot_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dots = 0
	_dot_timer = 0.0
	loading_label.text = "загрузка"
	
	title.modulate.a = 0.0
	name1.modulate.a = 0.0
	separator.modulate.a = 0.0
	name2.modulate.a = 0.0
	loading_label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(loading_label, "modulate:a", 1.0, 0.4)
	tween.tween_property(title, "modulate:a", 1.0, 0.6)
	tween.tween_property(name1, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(separator, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(name2, "modulate:a", 1.0, 0.5)
	
	# Определяем целевую сцену
	var level = Global.last_save_level
	var target = ""
	if level >= 2:
		target = "res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuFactory.tscn"
	else:
		target = "res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuAquarium.tscn"
	
	# Параллельно грузим сцену в фоне
	ResourceLoader.load_threaded_request(target)
	
	# Ждём интро
	await get_tree().create_timer(INTRO_DURATION).timeout
	
	# Ждём загрузку ресурса
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
	
	# Добавляем меню в корень, но НЕ активируем (current_scene не меняем сразу)
	tree.root.add_child(scene_instance)
	tree.current_scene = scene_instance
	
	# Удаляем старую сцену (BootLoader сам — автолоад, не current_scene, но на всякий)
	if old_scene and old_scene != scene_instance:
		old_scene.queue_free()
	
	# Небольшая пауза чтобы меню прогрузилось под бутлоадером
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame
	
	# Плавно гасим бутлоадер
	var fade = create_tween()
	fade.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	fade.tween_property(bg, "modulate:a", 0.0, 0.8)
	fade.parallel().tween_property(loading_label, "modulate:a", 0.0, 0.8)
	fade.parallel().tween_property(title, "modulate:a", 0.0, 0.8)
	fade.parallel().tween_property(name1, "modulate:a", 0.0, 0.8)
	fade.parallel().tween_property(separator, "modulate:a", 0.0, 0.8)
	fade.parallel().tween_property(name2, "modulate:a", 0.0, 0.8)
	await fade.finished
	
	# Удаляем бутлоадер полностью
	queue_free()

func _process(delta: float) -> void:
	_dot_timer += delta
	if _dot_timer >= DOT_INTERVAL:
		_dot_timer = 0.0
		_dots = (_dots + 1) % 4
		var dots_str = ""
		for i in range(_dots):
			dots_str += "."
		loading_label.text = "загрузка" + dots_str
