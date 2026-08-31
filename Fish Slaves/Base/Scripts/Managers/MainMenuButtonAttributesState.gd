extends Node

var states: Dictionary = {}
var initialized: bool = false

func scan_and_apply(scene: Node) -> void:
	print("=== SeaweedState: scan_and_apply for: ", scene.name, " initialized: ", initialized)
	
	if initialized:
		print("Applying existing states")
		_apply(scene)
		return
	
	print("First time - scanning for seaweed/rust")
	states.clear()
	_scan(scene)
	initialized = true
	_apply(scene)
	print("Found ", states.size(), " seaweed/rust states")

func _scan(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var decoration = _find_seaweed_or_rust(child)
			if decoration:
				var path = str(child.get_path())
				if not states.has(path):
					var visible = randf() < 0.25
					var flip = randf() < 0.5
					
					# Сохраняем текстуру если это Sprite2D
					var texture_path = ""
					if decoration is Sprite2D and decoration.texture:
						texture_path = decoration.texture.resource_path
					
					states[path] = {
						"visible": visible,
						"flip": flip,
						"texture": texture_path,  # Сохраняем путь к текстуре
						"type": decoration.name   # Сохраняем тип (Seaweed или Rust)
					}
					print("  Created state for: ", child.name, " (", decoration.name, ") texture: ", texture_path.get_file(), " visible=", visible)
		_scan(child)

func _apply(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var decoration = _find_seaweed_or_rust(child)
			if decoration:
				var path = str(child.get_path())
				if states.has(path):
					var data = states[path]
					
					# Применяем видимость
					decoration.visible = data["visible"]
					
					# Применяем флип
					if data["flip"]:
						decoration.scale.x = -abs(decoration.scale.x)
					else:
						decoration.scale.x = abs(decoration.scale.x)
					
					# Восстанавливаем текстуру если она сохранена и это Sprite2D
					if decoration is Sprite2D and data["texture"] != "":
						var texture = load(data["texture"])
						if texture:
							decoration.texture = texture
		_apply(child)

func _find_seaweed_or_rust(node: Node) -> Node:
	for child in node.get_children():
		if child.name == "Seaweed" or child.name == "Rust":
			return child
	return null

func reset() -> void:
	print("SeaweedState: RESET")
	states.clear()
	initialized = false
