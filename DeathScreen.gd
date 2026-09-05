extends CanvasLayer

signal restart_pressed
signal menu_pressed
signal quit_pressed

@onready var death_label: Label = $DeathLabel
@onready var restart_button: Button = $RestartButton
@onready var menu_button: Button = $MainMenuButton
@onready var quit_button: Button = $QuitButton
@onready var background: ColorRect = $Background

var fade_timer: float = 0.0
var appear_timer: float = 0.0
var state: int = 0
var fading_in: bool = false
var can_interact: bool = false

func _ready():
	hide()
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	death_label.modulate = Color(1, 1, 1, 0)
	restart_button.modulate = Color(1, 1, 1, 0)
	menu_button.modulate = Color(1, 1, 1, 0)
	quit_button.modulate = Color(1, 1, 1, 0)
	background.color = Color(0, 0, 0, 0)
	
	set_process(false)

func show_death():
	print("show_death() вызван")
	show()
	state = 0
	fade_timer = 0.0
	appear_timer = 0.0
	fading_in = true
	can_interact = false
	set_process(true)

func _process(delta):
	if not fading_in:
		return
	
	match state:
		0:
			fade_timer += delta
			var alpha = min(fade_timer / 2.5, 1.0)
			background.color.a = alpha * 0.8
			if fade_timer >= 2.5:
				state = 1
				appear_timer = 0.0
		
		1:
			appear_timer += delta
			
			var label_alpha = min((appear_timer) / 1.5, 1.0)
			death_label.modulate.a = label_alpha
			
			var restart_alpha = min(max((appear_timer - 0.5) / 0.8, 0.0), 1.0)
			restart_button.modulate.a = restart_alpha
			
			var menu_alpha = min(max((appear_timer - 0.7) / 0.8, 0.0), 1.0)
			menu_button.modulate.a = menu_alpha
			
			var quit_alpha = min(max((appear_timer - 0.9) / 0.8, 0.0), 1.0)
			quit_button.modulate.a = quit_alpha
			
			var wave = sin(appear_timer * 1.5) * 0.075 + 0.925
			death_label.modulate.a = death_label.modulate.a * wave
			
			if appear_timer >= 3.0:
				fading_in = false
				can_interact = true
				get_tree().paused = true
				set_process(false)

func _on_restart_pressed():
	if not can_interact:
		return
	print("рестарт нажат")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed():
	if not can_interact:
		return
	print("меню нажато")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuAquarium.tscn")

func _on_quit_pressed():
	if not can_interact:
		return
	print("выход нажат")
	get_tree().paused = false
	get_tree().quit()
