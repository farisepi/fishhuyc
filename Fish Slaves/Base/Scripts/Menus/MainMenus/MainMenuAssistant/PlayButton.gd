extends Button

func _on_play_button_pressed() -> void:
	UISounds.play_click()
	
	var music = get_node_or_null("/root/MainMenu/MenuMusic")
	if music:
		music.stop()
	
	await Fade.fade_out()
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act1AquariumLevel.tscn")
