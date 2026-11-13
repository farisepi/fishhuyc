extends Button

func _on_play_button_pressed() -> void:
	UISounds.play_click()

	var music = get_node_or_null("/root/MainMenu/MenuMusic")
	if music:
		music.stop()

	Global.goto_scene("res://GameScenes/LevelScenes/ActPrologueLevelScenes/AquariumLevelScenes/AquariumMainLevelScene/ActPrologue_LevelAquarium_Scene.tscn")
