extends Node

var states: Dictionary = {}
var initialized: bool = false

func scan_and_apply(scene: Node) -> void:
	if not scene or not is_instance_valid(scene) or not scene.is_inside_tree():
		return
	var fresh: Array = []
	_scan(scene, scene, fresh)
	if fresh.size() > 1:
		var any := false
		for k in fresh:
			if states[k]["visible"]:
				any = true
		if not any:
			states[fresh[randi() % fresh.size()]]["visible"] = true
	initialized = true
	_apply(scene, scene)

func _key(scene: Node, button: Node, decoration: Node) -> String:
	return "%s|%s|%s" % [scene.scene_file_path, str(scene.get_path_to(button)), decoration.name]

func _orig_scale(decoration: Node2D) -> Vector2:
	if not decoration.has_meta("attr_orig_scale"):
		decoration.set_meta("attr_orig_scale", decoration.scale.abs())
	return decoration.get_meta("attr_orig_scale")

func _scan(scene: Node, node: Node, fresh: Array) -> void:
	for child in node.get_children():
		if not is_instance_valid(child) or not child.is_inside_tree():
			continue
		if child is Button:
			var decoration = _find_decoration(child)
			if decoration:
				var key = _key(scene, child, decoration)
				if not states.has(key):
					var texture_data = {}
					if decoration is Sprite2D and decoration.texture:
						texture_data["path"] = decoration.texture.resource_path
					states[key] = {
						"visible": randf() < 0.25,
						"flip": randf() < 0.5,
						"texture_data": texture_data,
					}
					fresh.append(key)
		_scan(scene, child, fresh)

func _apply(scene: Node, node: Node) -> void:
	for child in node.get_children():
		if not is_instance_valid(child) or not child.is_inside_tree():
			continue
		if child is Button:
			var decoration = _find_decoration(child)
			if decoration:
				var key = _key(scene, child, decoration)
				if states.has(key):
					var data = states[key]
					decoration.visible = data["visible"]
					if decoration is Node2D:
						var s = _orig_scale(decoration)
						decoration.scale = Vector2(-s.x if data.get("flip", false) else s.x, s.y)
					if decoration.name == "Rust" and decoration is Sprite2D:
						var tex_data = data.get("texture_data", {})
						if tex_data.get("path", "") != "" and ResourceLoader.exists(tex_data["path"]):
							decoration.texture = load(tex_data["path"])
		_apply(scene, child)

func _find_decoration(node: Node) -> Node:
	for child in node.get_children():
		if is_instance_valid(child) and (child.name == "Seaweed" or child.name == "Rust"):
			return child
	return null

func reset() -> void:
	states.clear()
	initialized = false
