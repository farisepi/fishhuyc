extends Node

func _ready() -> void:
	await get_tree().process_frame
	var scene = get_tree().current_scene
	if scene:
		SeaweedState.scan_and_apply(scene)
