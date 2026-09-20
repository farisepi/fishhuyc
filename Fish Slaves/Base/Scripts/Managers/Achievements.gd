extends Node

signal achievement_unlocked(id: String)

var coffee_unlocked: bool = false
var flashback_unlocked: bool = false
var pop_star_unlocked: bool = false
var rebel_unlocked: bool = false
var acrobat_unlocked: bool = false
var worker_of_month_unlocked: bool = false
var scout_unlocked: bool = false
var freedom_unlocked: bool = false

func _ready():
	load_achievements()

func load_achievements() -> void:
	var config = ConfigFile.new()
	if config.load("user://achievements.cfg") != OK:
		save_achievements()
		return
	
	coffee_unlocked = config.get_value("achievements", "coffee", false)
	flashback_unlocked = config.get_value("achievements", "flashback", false)
	pop_star_unlocked = config.get_value("achievements", "pop_star", false)
	rebel_unlocked = config.get_value("achievements", "rebel", false)
	acrobat_unlocked = config.get_value("achievements", "acrobat", false)
	worker_of_month_unlocked = config.get_value("achievements", "worker_of_month", false)
	scout_unlocked = config.get_value("achievements", "scout", false)
	freedom_unlocked = config.get_value("achievements", "freedom", false)

func save_achievements() -> void:
	var config = ConfigFile.new()
	config.set_value("achievements", "coffee", coffee_unlocked)
	config.set_value("achievements", "flashback", flashback_unlocked)
	config.set_value("achievements", "pop_star", pop_star_unlocked)
	config.set_value("achievements", "rebel", rebel_unlocked)
	config.set_value("achievements", "acrobat", acrobat_unlocked)
	config.set_value("achievements", "worker_of_month", worker_of_month_unlocked)
	config.set_value("achievements", "scout", scout_unlocked)
	config.set_value("achievements", "freedom", freedom_unlocked)
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

func unlock_pop_star() -> void:
	if pop_star_unlocked:
		return
	pop_star_unlocked = true
	achievement_unlocked.emit("pop_star")
	save_achievements()

func unlock_rebel() -> void:
	if rebel_unlocked:
		return
	rebel_unlocked = true
	achievement_unlocked.emit("rebel")
	save_achievements()

func unlock_acrobat() -> void:
	if acrobat_unlocked:
		return
	acrobat_unlocked = true
	achievement_unlocked.emit("acrobat")
	save_achievements()

func unlock_worker_of_month() -> void:
	if worker_of_month_unlocked:
		return
	worker_of_month_unlocked = true
	achievement_unlocked.emit("worker_of_month")
	if has_node("/root/UISounds"):
		UISounds.play_achievement()
	save_achievements()

func unlock_scout() -> void:
	if scout_unlocked:
		return
	scout_unlocked = true
	achievement_unlocked.emit("scout")
	if has_node("/root/UISounds"):
		UISounds.play_achievement()
	save_achievements()

func unlock_freedom() -> void:
	if freedom_unlocked:
		return
	freedom_unlocked = true
	achievement_unlocked.emit("freedom")
	if has_node("/root/UISounds"):
		UISounds.play_achievement()
	save_achievements()

func reset_all() -> void:
	coffee_unlocked = false
	flashback_unlocked = false
	pop_star_unlocked = false
	rebel_unlocked = false
	acrobat_unlocked = false
	worker_of_month_unlocked = false
	scout_unlocked = false
	freedom_unlocked = false
	save_achievements()
