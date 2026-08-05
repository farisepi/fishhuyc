extends Node

var first_run: bool = true
var seaweed_states: Dictionary = {}  # Запоминаем состояние водорослей

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().tree_changed.connect(_on_tree_changed)

func _on_tree_changed() -> void:
	# Проверяем что дерево живо
	if not is_inside_tree():
		return
	
	var tree = get_tree()
	if not tree:
		return
	
	await tree.process_frame
	
	var scene = tree.current_scene
	if not scene:
		return
	
	# Только при первом запуске рандомим водоросли
	if first_run:
		first_run = false
		_generate_seaweed_states(scene)
	
	_apply_seaweed_states(scene)

func _generate_seaweed_states(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var seaweed = child.get_node_or_null("Seaweed")
			if seaweed is Sprite2D:
				# Запоминаем состояние для этой кнопки
				var path = str(child.get_path())
				seaweed_states[path] = randf() < 0.25
		_generate_seaweed_states(child)

func _apply_seaweed_states(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var seaweed = child.get_node_or_null("Seaweed")
			if seaweed is Sprite2D:
				var path = str(child.get_path())
				if seaweed_states.has(path):
					seaweed.visible = seaweed_states[path]
		_apply_seaweed_states(child)
