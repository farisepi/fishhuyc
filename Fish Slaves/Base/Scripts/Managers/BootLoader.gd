extends Node

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	var level = Global.last_save_level
	
	var target = ""
	if level >= 2:
		target = "res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuFactory.tscn"
	else:
		target = "res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuAquarium.tscn"
	
	Global.goto_scene(target)
