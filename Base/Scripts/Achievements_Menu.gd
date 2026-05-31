extends Control

@onready var back_btn: Button = $BackButton
@onready var reset_btn: Button = $ResetButton
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Label = $ProgressLabel

@onready var coffee_achievement: Control = $CoffeeAchievement
@onready var coffee_icon: TextureRect = $CoffeeAchievement/Icon
@onready var coffee_check: TextureRect = $CoffeeAchievement/Check
@onready var coffee_name: Label = $CoffeeAchievement/NameLabel
@onready var coffee_desc: Label = $CoffeeAchievement/DescLabel

@onready var flashback_achievement: Control = $FlashbackAchievement
@onready var flashback_icon: TextureRect = $FlashbackAchievement/Icon
@onready var flashback_check: TextureRect = $FlashbackAchievement/Check
@onready var flashback_name: Label = $FlashbackAchievement/NameLabel

@onready var pop_star_achievement: Control = $PopStarAchievement
@onready var pop_star_icon: TextureRect = $PopStarAchievement/Icon
@onready var pop_star_check: TextureRect = $PopStarAchievement/Check
@onready var pop_star_name: Label = $PopStarAchievement/NameLabel
@onready var pop_star_desc: Label = $PopStarAchievement/DescLabel

var total_achievements: int = 3
var unlocked_count: int = 0

func _ready() -> void:
	Fade.fade_in()

	#if not GlobalMusic.music_player or not GlobalMusic.music_player.playing:
		#GlobalMusic.play_music(preload("res://музыка/Fish Slaves - main menu.mp3"))

	ButtonEffects.setup(back_btn)
	ButtonEffects.setup(reset_btn)

	if not reset_btn.pressed.is_connected(_on_reset_pressed):
		reset_btn.pressed.connect(_on_reset_pressed)
	if not back_btn.pressed.is_connected(_on_back_button_pressed):
		back_btn.pressed.connect(_on_back_button_pressed)

	_setup_progress_bar()
	update_achievements()

func _setup_progress_bar() -> void:
	if progress_bar:
		progress_bar.max_value = total_achievements
		progress_bar.value = 0
	if progress_label:
		progress_label.text = "0/" + str(total_achievements)

func update_achievements() -> void:
	unlocked_count = 0

	if Achievements.coffee_unlocked:
		unlocked_count += 1
		_set_achievement_bright(coffee_achievement, coffee_icon, coffee_check, coffee_name)
		coffee_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_achievement_gray(coffee_achievement, coffee_icon, coffee_check, coffee_name)
		coffee_desc.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

	if Achievements.flashback_unlocked:
		unlocked_count += 1
		_set_achievement_bright(flashback_achievement, flashback_icon, flashback_check, flashback_name)
	else:
		_set_achievement_gray(flashback_achievement, flashback_icon, flashback_check, flashback_name)

	if Achievements.pop_star_unlocked:
		unlocked_count += 1
		_set_achievement_bright(pop_star_achievement, pop_star_icon, pop_star_check, pop_star_name)
		pop_star_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_achievement_gray(pop_star_achievement, pop_star_icon, pop_star_check, pop_star_name)
		pop_star_desc.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

	if progress_bar:
		progress_bar.value = unlocked_count
	if progress_label:
		progress_label.text = str(unlocked_count) + "/" + str(total_achievements)

func _set_achievement_bright(ach: Control, icon: TextureRect, check: TextureRect, name_label: Label) -> void:
	if ach: ach.modulate = Color.WHITE
	if icon: icon.modulate = Color.WHITE
	if check: check.visible = true
	if name_label: name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))

func _set_achievement_gray(ach: Control, icon: TextureRect, check: TextureRect, name_label: Label) -> void:
	if ach: ach.modulate = Color(0.3, 0.3, 0.3, 1.0)
	if icon: icon.modulate = Color(0.3, 0.3, 0.3, 1.0)
	if check: check.visible = false
	if name_label: name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

func _on_reset_pressed() -> void:
	if not Achievements.coffee_unlocked and not Achievements.flashback_unlocked and not Achievements.pop_star_unlocked:
		return

	var menu = AcceptDialog.new()
	menu.title = "Сброс достижений"
	menu.dialog_text = "Весь прогресс достижений будет сброшен. Восстановить нельзя. Придётся начинать сначала."
	menu.add_button("Да", true, "yes")
	menu.add_cancel_button("Нет")
	var ok = menu.get_ok_button()
	if ok: ok.visible = false

	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(100, 40)

	menu.custom_action.connect(func(action):
		if action == "yes":
			Achievements.reset_all()
			Global.bubbles_popped = 0
			update_achievements()
		menu.hide()
		menu.queue_free()
	)

	add_child(menu)
	menu.popup_centered()

func _on_back_button_pressed() -> void:
	Fade.fade_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://Base/Scenes/Main_Menu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
