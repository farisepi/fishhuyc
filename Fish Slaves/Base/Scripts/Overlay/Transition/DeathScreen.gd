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
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	
	show()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	ButtonEffects.setup(restart_button)
	ButtonEffects.setup(menu_button)
	ButtonEffects.setup(quit_button)
	
	death_label.modulate = Color(1, 1, 1, 0)
	restart_button.modulate = Color(1, 1, 1, 0)
	menu_button.modulate = Color(1, 1, 1, 0)
	quit_button.modulate = Color(1, 1, 1, 0)
	background.color = Color(0, 0, 0, 0)
	
	set_process(false)
	hide()

func show_death():
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
			var alpha = min(fade_timer / 1.0, 1.0)
			background.color.a = alpha * 0.8
			if fade_timer >= 1.0:
				state = 1
				appear_timer = 0.0
		
		1:
			appear_timer += delta
			
			var label_alpha = min((appear_timer) / 0.8, 1.0)
			death_label.modulate.a = label_alpha
			
			var restart_alpha = min(max((appear_timer - 0.2) / 0.4, 0.0), 1.0)
			restart_button.modulate.a = restart_alpha
			
			var menu_alpha = min(max((appear_timer - 0.5) / 0.4, 0.0), 1.0)
			menu_button.modulate.a = menu_alpha
			
			var quit_alpha = min(max((appear_timer - 0.8) / 0.4, 0.0), 1.0)
			quit_button.modulate.a = quit_alpha
			
			var wave = sin(appear_timer * 1.5) * 0.075 + 0.925
			death_label.modulate.a = death_label.modulate.a * wave
			
			if appear_timer >= 2.0:
				fading_in = false
				can_interact = true
				get_tree().paused = true
				set_process(false)

func _on_restart_button_pressed():
	if not can_interact:
		return
	print("рестарт нажат")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_fade_out_and_reload()

func _on_main_menu_button_pressed():
	if not can_interact:
		return
	print("меню нажато")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_fade_out_and_goto("res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuAquarium.tscn")

func _on_quit_button_pressed():
	if not can_interact:
		return
	print("выход нажат")
	get_tree().paused = false
	get_tree().quit()

func _fade_out_and_reload():
	var canvas = CanvasLayer.new()
	canvas.layer = 500
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(canvas)
	
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	await tween.finished
	
	var current_path = get_tree().current_scene.scene_file_path
	get_tree().paused = false
	get_tree().change_scene_to_file(current_path)

func _fade_out_and_goto(path: String):
	var canvas = CanvasLayer.new()
	canvas.layer = 500
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(canvas)
	
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	await tween.finished
	
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
