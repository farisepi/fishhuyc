extends Node

var states: Dictionary = {}
var initialized: bool = false

func scan_and_apply(scene: Node) -> void:
	print("=== SeaweedState: scan_and_apply for: ", scene.name, " initialized: ", initialized)
	
	if initialized:
		print("Applying existing states")
		_apply(scene)
		return
	
	print("First time - scanning for seaweed")
	states.clear()
	_scan(scene)
	initialized = true
	_apply(scene)
	print("Found ", states.size(), " seaweed states")

func _scan(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var seaweed = _find_seaweed(child)
			if seaweed:
				var path = str(child.get_path())
				if not states.has(path):
					var visible = randf() < 0.25
					var flip = randf() < 0.5
					states[path] = {
						"visible": visible,
						"flip": flip
					}
					print("  Created state for: ", child.name, " visible=", visible)
		_scan(child)

func _apply(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			var seaweed = _find_seaweed(child)
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

func _find_seaweed(node: Node) -> Node:
	for child in node.get_children():
		if child.name == "Seaweed":
			return child
	return null

func reset() -> void:
	print("SeaweedState: RESET")
	states.clear()
	initialized = false
