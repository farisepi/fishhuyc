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
			var decoration = _find_decoration(child)
			if decoration:
				var path = str(child.get_path())
				if not states.has(path):
					var visible = randf() < 0.25
					var flip = randf() < 0.5
					
					# Сохраняем текстуру для Rust
					var texture_data = {}
					if decoration is Sprite2D and decoration.texture:
						texture_data["path"] = decoration.texture.resource_path
					
					states[path] = {
						"visible": visible,
						"flip": flip,
						"texture_data": texture_data,
						"type": decoration.name,
						"scale": decoration.scale
					}
					print("  Created state for: ", child.name, " (", decoration.name, ") visible=", visible)
		_scan(child)

func _apply(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var decoration = _find_decoration(child)
			if decoration:
				var path = str(child.get_path())
				if states.has(path):
					var data = states[path]
					decoration.visible = data["visible"]
					
					# Применяем флип с сохранением масштаба
					var original_scale = data.get("scale", Vector2.ONE)
					if data.get("flip", false):
						decoration.scale.x = -abs(original_scale.x)
						decoration.scale.y = abs(original_scale.y)
					else:
						decoration.scale.x = abs(original_scale.x)
						decoration.scale.y = abs(original_scale.y)
					
					# Восстанавливаем текстуру для Rust
					if decoration.name == "Rust" and decoration is Sprite2D:
						var tex_data = data.get("texture_data", {})
						if tex_data.has("path") and tex_data["path"] != "":
							var texture = load(tex_data["path"])
							if texture:
								decoration.texture = texture
		_apply(child)

func _find_decoration(node: Node) -> Node:
	for child in node.get_children():
		if child.name == "Seaweed" or child.name == "Rust":
			return child
	return null

func reset() -> void:
	print("SeaweedState: RESET")
	states.clear()
	initialized = false
