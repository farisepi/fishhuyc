extends Node

var states: Dictionary = {}

func scan_and_apply(scene: Node) -> void:
	_scan(scene)
	_apply(scene)

func _scan(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var seaweed = child.get_node_or_null("Seaweed")
			if seaweed:
				var path = str(child.get_path())
				if not states.has(path):
					states[path] = {
						"visible": randf() < 0.25,
						"flip": randf() < 0.5
					}
		_scan(child)

func _apply(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var seaweed = child.get_node_or_null("Seaweed")
			if seaweed:
				var path = str(child.get_path())
				if states.has(path):
					var data = states[path]
					seaweed.visible = data["visible"]
					if data["flip"]:
						seaweed.scale.x = -abs(seaweed.scale.x)
					else:
						seaweed.scale.x = abs(seaweed.scale.x)
		_apply(child)
