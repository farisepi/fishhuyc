extends Node

signal achievement_unlocked(id: String)

var coffee_unlocked: bool = false
var flashback_unlocked: bool = false

func _ready():
	load_achievements()

func load_achievements() -> void:
	var config = ConfigFile.new()
	if config.load("user://achievements.cfg") != OK:
		save_achievements()
		return
	
	coffee_unlocked = config.get_value("achievements", "coffee", false)
	flashback_unlocked = config.get_value("achievements", "flashback", false)

func save_achievements() -> void:
	var config = ConfigFile.new()
	config.set_value("achievements", "coffee", coffee_unlocked)
	config.set_value("achievements", "flashback", flashback_unlocked)
	config.save("user://achievements.cfg")

func unlock_coffee() -> void:
	if coffee_unlocked:
		return
	coffee_unlocked = true
	achievement_unlocked.emit("coffee")
	save_achievements()

func unlock_flashback() -> void:
	if flashback_unlocked:
		return
	flashback_unlocked = true
	achievement_unlocked.emit("flashback")
	save_achievements()

func reset_all() -> void:
	coffee_unlocked = false
	flashback_unlocked = false
	save_achievements()
