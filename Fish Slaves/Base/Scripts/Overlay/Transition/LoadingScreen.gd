extends CanvasLayer

var dot_timer: Timer
var dot_count: int = 0
var loading_text: String = "Загрузка"
var color_rect: ColorRect
var label: Label
var is_showing: bool = false
var is_finished: bool = false
var target_scene: String = ""

func _ready() -> void:
	color_rect = $ColorRect
	label = $Label
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var font = load("res://Fish Slaves/Textures/Font/Font.ttf")
	if font:
		font.fixed_size = 10
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 64)
	
	color_rect.modulate = Color(1, 1, 1, 0)
	label.modulate = Color(1, 1, 1, 0)
	
	dot_timer = Timer.new()
	dot_timer.wait_time = 0.4
	dot_timer.one_shot = false
	dot_timer.timeout.connect(_update_dots)
	add_child(dot_timer)
	dot_timer.start()

func _update_dots() -> void:
	if not is_showing:
		return
	dot_count = (dot_count + 1) % 4
	var dots = ""
	match dot_count:
		0: dots = ""
		1: dots = "."
		2: dots = ".."
		3: dots = "..."
	label.text = loading_text + dots

func start_loading(scene_path: String) -> void:
	target_scene = scene_path
	
	await get_tree().create_timer(0.5).timeout
	
	var tree = get_tree()
	if tree and tree.current_scene and tree.current_scene.scene_file_path == target_scene:
		queue_free()
		return
	
	show_loading()
	
	get_tree().change_scene_to_file(target_scene)
	
	while true:
		await get_tree().process_frame
		tree = get_tree()
		if tree and tree.current_scene:
			if tree.current_scene.scene_file_path == target_scene:
				break
		if not is_instance_valid(self):
			return
	
	hide_loading()
	await get_tree().create_timer(0.2).timeout
	queue_free()

func show_loading() -> void:
	if is_showing:
		return
	is_showing = true
	
	var tween = create_tween()
	tween.parallel().tween_property(color_rect, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.15)
	await tween.finished
	
	label.text = loading_text

func hide_loading() -> void:
	if not is_showing:
		return
	is_showing = false
	
	var tween = create_tween()
	tween.parallel().tween_property(color_rect, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.2)
	await tween.finished